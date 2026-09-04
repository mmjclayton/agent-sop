#!/usr/bin/env bash
#
# Shared helpers for the agent-sop user-scope hooks. Sourced, not executed.
#
# Design constraints (P97):
#   - Every hook is silent unless a deterministic fact holds. A hook that
#     speaks when it has nothing to say is the nag the design rejects.
#   - Fail open. `set -u` only; no `-e`, no `pipefail` — a git command that
#     exits 128 in an odd directory must not turn into a blocking error.
#     Every path that cannot decide returns "no fact" and the caller exits 0.
#   - Resolve the repo from the hook's `cwd` input field, never from the
#     launch directory. Project-scope hooks only load from the directory
#     Claude Code was launched in, which is why ship-sop's Stop hook never ran
#     on this machine: sessions are launched from ~ and cd into the project.
#   - Two consumers share one rule: everything the Stop hook and the push
#     gate check is computed here, so they cannot disagree (cross-layer-rules
#     Tier A).

set -u

SOP_INPUT=""

sop_have_jq() { command -v jq >/dev/null 2>&1; }

# Read the hook input JSON from stdin once. Empty stdin is tolerated.
sop_read_input() {
    SOP_INPUT=$(cat 2>/dev/null || true)
    [ -n "$SOP_INPUT" ] || SOP_INPUT='{}'
}

# sop_field <jq-expr> — prints the field or empty. Never errors.
sop_field() {
    sop_have_jq || { printf ''; return; }
    printf '%s' "$SOP_INPUT" | jq -r "$1 // empty" 2>/dev/null || printf ''
}

sop_state_dir() {
    printf '%s' "${AGENT_SOP_STATE_DIR:-${TMPDIR:-/tmp}/agent-sop-hooks}"
}

sop_sha256() {
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 | awk '{print $1}'
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum | awk '{print $1}'
    else
        cksum | awk '{print $1}'
    fi
}

# sop_repo_root <cwd> — git toplevel for cwd, or empty.
sop_repo_root() {
    local cwd="$1"
    [ -d "$cwd" ] || { printf ''; return; }
    git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || printf ''
}

# sop_is_sop_repo <root> — the file set every hook keys on. The home
# directory is refused even when it is a git repo: nothing project-scoped
# can be derived there (P96).
sop_is_sop_repo() {
    local root="$1"
    [ -n "$root" ] || return 1
    [ "$root" != "${HOME:-/nonexistent}" ] || return 1
    [ -f "$root/Backlog.md" ] || return 1
    [ -f "$root/docs/sop/claude-agent-sop.md" ] || return 1
    return 0
}

sop_repo_key() {
    printf '%s' "$1" | sop_sha256 | cut -c1-12
}

# sop_default_branch <root> — "origin/main" style ref, or empty.
# Same rule as /update-sop Step 0a and ship-sop's hook.
sop_default_branch() {
    local root="$1" ref cand
    ref=$(git -C "$root" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/@@')
    if [ -z "$ref" ]; then
        for cand in origin/main origin/master origin/develop; do
            if git -C "$root" rev-parse --verify "$cand" >/dev/null 2>&1; then
                ref="$cand"
                break
            fi
        done
    fi
    printf '%s' "$ref"
}

# sop_range_base <root> — merge-base of default branch and HEAD when the
# branch has diverged; empty when on the default branch or no origin.
sop_range_base() {
    local root="$1" ref base head
    ref=$(sop_default_branch "$root")
    [ -n "$ref" ] || { printf ''; return; }
    base=$(git -C "$root" merge-base "$ref" HEAD 2>/dev/null)
    head=$(git -C "$root" rev-parse HEAD 2>/dev/null)
    if [ -z "$base" ] || [ "$base" = "$head" ]; then
        printf ''
    else
        printf '%s' "$base"
    fi
}

# sop_agent_id <root> — via the project's resolver when present (one rule,
# P96), else the solo default. No fourth inline copy of the precedence.
sop_agent_id() {
    local root="$1" id=""
    if [ -f "$root/scripts/resolve-resume-path.sh" ]; then
        id=$(bash "$root/scripts/resolve-resume-path.sh" --agent-id --root "$root" --home "${HOME:-}" 2>/dev/null)
    fi
    [ -n "$id" ] || id="${CLAUDE_AGENT_ID:-solo}"
    printf '%s' "$id"
}

# sop_last_record_commit <root> — newest commit touching a session record.
# The directory README does not count: setup.sh commits it before any
# session has run.
sop_last_record_commit() {
    git -C "$1" log -1 --format=%H -- 'docs/recent-work' ':(exclude)docs/recent-work/README.md' 2>/dev/null || printf ''
}

# sop_drift_commits <root> — one line per commit since the last session
# record (or since the beginning when none), newest first. Empty = no drift.
sop_drift_commits() {
    local root="$1" last
    last=$(sop_last_record_commit "$root")
    if [ -n "$last" ]; then
        git -C "$root" log --format='%h %s' "$last..HEAD" 2>/dev/null
    else
        git -C "$root" log --format='%h %s' HEAD 2>/dev/null
    fi
}

# sop_tracker_dirty <root> — paths of modified tracker files, one per line.
# Porcelain v1 is "XY <path>" (or "XY <old> -> <new>" for renames); take the
# path after the status columns so names with spaces survive intact.
sop_tracker_dirty() {
    git -C "$1" status --porcelain --untracked-files=all -- \
        Backlog.md CLAUDE.md docs/RECENT-WORK.md docs/feature-map.md docs/agent-memory.md \
        docs/recent-work docs/agent-memory docs/build-plans docs/reviews 2>/dev/null \
        | sed -E 's/^.{3}//; s/^.* -> //; s/^"(.*)"$/\1/'
}

# sop_cmd_matches_push <text> — the bare pattern: a `git ... push` or
# `gh pr create` simple command at the start of the text or after a
# separator (; & | ( backtick or whitespace).
sop_cmd_matches_push() {
    printf '%s' "$1" | grep -Eq '(^|[;&|(`]|[[:space:]])(git[[:space:]]+(-[^[:space:]]+[[:space:]]+)*push|gh[[:space:]]+pr[[:space:]]+create)([[:space:];&|)`]|$)'
}

# sop_is_push_command <command> [depth] — true when the command would run a
# push or PR-create. Two things the bare pattern gets wrong, both found in
# review: `bash -c 'git push'` hides the verb behind a quote, and
# `echo "remember to git push"` shows the verb inside prose. So: recurse into
# the quoted body of a shell wrapper (`bash|sh|zsh|dash|ksh -c` and `eval`),
# then strip every remaining quoted string and match only the residue —
# what the shell would actually execute, not what an argument says.
sop_is_push_command() {
    local cmd="$1" depth="${2:-0}" rest body stripped
    [ "$depth" -le 3 ] || return 1

    local re_sh="(bash|sh|zsh|dash|ksh)[[:space:]]+-[A-Za-z]*c[A-Za-z]*[[:space:]]+('([^']*)'|\"([^\"]*)\")"
    rest="$cmd"
    while [[ "$rest" =~ $re_sh ]]; do
        body="${BASH_REMATCH[3]}${BASH_REMATCH[4]}"
        sop_is_push_command "$body" $((depth + 1)) && return 0
        rest="${rest#*"${BASH_REMATCH[0]}"}"
    done

    local re_eval="eval[[:space:]]+('([^']*)'|\"([^\"]*)\")"
    rest="$cmd"
    while [[ "$rest" =~ $re_eval ]]; do
        body="${BASH_REMATCH[2]}${BASH_REMATCH[3]}"
        sop_is_push_command "$body" $((depth + 1)) && return 0
        rest="${rest#*"${BASH_REMATCH[0]}"}"
    done

    stripped=$(printf '%s' "$cmd" | sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g")
    sop_cmd_matches_push "$stripped"
}

# sop_code_lines <root> <from> <to> <skip-docs> — added+deleted lines in the
# range, excluding documentation extensions when skip-docs is "true".
# Binary files report "-" and count 0.
sop_code_lines() {
    git -C "$1" diff --numstat "$2..$3" 2>/dev/null | awk -v skip="$4" '
        {
            if (skip == "true" && $3 ~ /\.(md|markdown|txt|rst)$/) next
            a = ($1 == "-") ? 0 : $1
            d = ($2 == "-") ? 0 : $2
            t += a + d
        }
        END { print t + 0 }'
}

# sop_shipsop_covered <root> <head> <skip-docs> — true when some
# docs/reviews/*-ship-auto.md carries `Covers: <sha>` for an ancestor of
# HEAD with zero code lines between it and HEAD.
sop_shipsop_covered() {
    local root="$1" head="$2" skip="$3" sha
    for sha in $(cat "$root"/docs/reviews/*-ship-auto.md 2>/dev/null | grep -oE 'Covers: [0-9a-f]{7,40}' | awk '{print $2}' | sort -u); do
        git -C "$root" merge-base --is-ancestor "$sha" "$head" 2>/dev/null || continue
        [ "$(sop_code_lines "$root" "$sha" "$head" "$skip")" = "0" ] && return 0
    done
    return 1
}

# sop_shipsop_gate <root> — prints the gate demand when ship-sop auto-mode
# applies to this branch and no gate report covers HEAD; empty otherwise.
#
# Folds ship-sop's Stop hook into agent-sop's: same config file, same
# throttle keys, same agent list. The one behavioural change is how the
# demand reaches the model — exit 2 on Stop, which Claude Code feeds back,
# instead of stdout, which it discards for Stop hooks.
sop_shipsop_gate() {
    local root="$1" cfg mode branch pat base head lines min skip_docs report agents
    cfg="$root/ship-sop.config.json"
    [ -f "$cfg" ] || { printf ''; return; }
    sop_have_jq || { printf ''; return; }

    mode=$(jq -r '.trigger.mode // "manual"' "$cfg" 2>/dev/null)
    [ "$mode" = "auto" ] || { printf ''; return; }

    branch=$(git -C "$root" branch --show-current 2>/dev/null)
    for pat in $(jq -r '.trigger.throttle.skip_branch_patterns[]? // empty' "$cfg" 2>/dev/null); do
        if printf '%s' "$branch" | grep -Eq "$pat"; then printf ''; return; fi
    done

    base=$(sop_range_base "$root")
    [ -n "$base" ] || { printf ''; return; }
    head=$(git -C "$root" rev-parse HEAD 2>/dev/null)

    min=$(jq -r '.trigger.throttle.min_diff_lines // 10' "$cfg" 2>/dev/null)
    skip_docs=$(jq -r '.trigger.throttle.skip_docs_only // true' "$cfg" 2>/dev/null)

    # With skip_docs_only, documentation extensions are excluded from the count
    # so a docs-heavy branch does not summon reviewers for prose.
    lines=$(sop_code_lines "$root" "$base" "$head" "$skip_docs")
    [ "${lines:-0}" -ge "${min:-10}" ] 2>/dev/null || { printf ''; return; }

    # Coverage is a fact, not a stamp: a report names a commit that is an
    # ancestor of HEAD with no code change since. "No code change" uses the
    # same docs filter as the trigger, so committing the report itself — or
    # any later docs-only commit — does not un-cover the branch.
    if sop_shipsop_covered "$root" "$head" "$skip_docs"; then
        printf ''
        return
    fi

    agents=$(jq -r '.agents | to_entries[] | select(.value.enabled == true) | "  - @\(.key) (block_on: \(.value.block_on // "CRITICAL"))"' "$cfg" 2>/dev/null)
    report="docs/reviews/$(date +%Y%m%d-%H%M%S)-ship-auto.md"

    printf 'ship-sop gate (auto-mode per ship-sop.config.json): %s code lines on %s vs %s (%s..%s) have no gate report.\n' \
        "$lines" "${branch:-HEAD}" "$(sop_default_branch "$root")" "$(printf '%s' "$base" | cut -c1-7)" "$(printf '%s' "$head" | cut -c1-7)"
    printf '  Run these agents against that range, collect every result (they run in the background), then write %s containing the line `Covers: %s`:\n' "$report" "$head"
    printf '%s\n' "$agents"
    printf '  Auto-mode rules: do not halt on findings; CRITICAL goes at the top of your next reply with file:line; HIGH/MEDIUM are filed to Backlog.md if it exists; LOW stays in the report.\n'
}
