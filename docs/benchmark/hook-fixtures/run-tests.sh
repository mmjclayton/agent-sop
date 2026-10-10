#!/usr/bin/env bash
#
# Test harness for the user-scope hook scripts under `scripts/hooks/`:
#
#   sop-session-context.sh   SessionStart + UserPromptSubmit — prints context once per (session, repo)
#   sop-stop-drift.sh        Stop — exit 2 with a reason only when a deterministic drift fact holds
#   sop-push-gate.sh         PreToolUse(Bash) — refuses `git push` / `gh pr create` when ship-sop
#                            auto-mode is on and no gate report covers HEAD
#   sop-project-type.sh      prints code|non-code — the one rule the ship gate, the context
#                            block and the slash commands all read (P102)
#   sop-memory-index.sh      PostToolUse(Write|Edit) — reports a harness memory index that is
#                            near its load limit, once per size reached (P113)
#   ../install-hooks.sh      registers the hooks in a settings.json idempotently
#
# Fixtures are real repositories with a bare origin, built in a temp dir, so
# default-branch detection and merge-base behave as in production. State is
# redirected via AGENT_SOP_STATE_DIR and HOME so the suite never touches the
# machine's real markers or resume files.
#
# Every hook must be silent (exit 0, empty stderr) whenever its condition does
# not hold — a hook that speaks when it has nothing to say is the nag the P97
# design rejected. Reporting contract matches the other suites: PASS/FAIL per
# case, summary line, exit 1 on any failure.
#
# Run from repo root: bash docs/benchmark/hook-fixtures/run-tests.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
HOOKS_DIR="${HOOKS_DIR:-$REPO_ROOT/scripts/hooks}"
INSTALLER="${INSTALLER:-$REPO_ROOT/scripts/install-hooks.sh}"

CTX="$HOOKS_DIR/sop-session-context.sh"
STOP="$HOOKS_DIR/sop-stop-drift.sh"
PUSH="$HOOKS_DIR/sop-push-gate.sh"
PTYPE="$HOOKS_DIR/sop-project-type.sh"
MEMIDX="$HOOKS_DIR/sop-memory-index.sh"

for f in "$CTX" "$STOP" "$PUSH" "$PTYPE" "$MEMIDX" "$INSTALLER"; do
    if [ ! -f "$f" ]; then
        echo "Missing: $f" >&2
        exit 2
    fi
done

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

export HOME="$TMP/home"
export AGENT_SOP_STATE_DIR="$TMP/state"
mkdir -p "$HOME" "$AGENT_SOP_STATE_DIR"
unset CLAUDE_AGENT_ID

GIT="git -c user.email=t@t -c user.name=t -c commit.gpgsign=false"

pass=0
fail=0
failed=""

ok()   { echo "PASS: $1"; pass=$((pass + 1)); }
bad()  { echo "FAIL: $1 — $2"; fail=$((fail + 1)); failed="$failed $1"; }

# ── Fixture builders ──────────────────────────────────────────────────────────

# Test receipt builder: successful reviewers for this fixture's configured policy.
make_receipt() (
    . "$HOOKS_DIR/sop-lib.sh"
    # Optional third argument: a JSON array of reviewer names to include; null
    # (the default) writes every enabled reviewer.
    local root="$1" output="$2" names="${3:-null}" head
    head=$(git -C "$root" rev-parse HEAD)
    jq -n --arg head "$head" --arg base "$(sop_range_base "$root")" \
      --arg tree "$(git -C "$root" rev-parse 'HEAD^{tree}')" \
      --arg policy "$(sop_policy_digest "$root/ship-sop.config.json")" \
      --slurpfile cfg "$root/ship-sop.config.json" --argjson names "$names" \
      '{schema_version:1,head:$head,base:$base,tree:$tree,policy_sha256:$policy,
        tests:{status:"PASS",evidence:"fixture tests"},
        reviewers:[$cfg[0].agents|to_entries[]|select(.value.enabled)|
          . as $e|select($names == null or ($names | index($e.key)) != null)|
          {name:.key,version:"fixture-v1",model:"fixture",verdict:"PASS",findings:[]}]}' > "$output"
)

# make_repo <dir> [with-sop|with-code]
# Creates a bare origin at <dir>.git, clones it to <dir>, makes an initial
# commit on main and pushes so origin/main exists. With "with-sop", installs
# the minimal SOP file set the hooks key on, plus the repo's own resolver so
# agent-id / resume paths follow production rules. That set carries no
# manifest and no declaration, so by the project-type rule it is a NON-CODE
# project; "with-code" adds a package.json so the ship gate applies (P102).
make_repo() {
    local dir="$1" sop="${2:-}"
    $GIT init -q --bare -b main "$dir.git"
    $GIT clone -q "$dir.git" "$dir" 2>/dev/null
    (
        cd "$dir" || exit 1
        echo "# app" > README.md
        [ "$sop" = "with-code" ] && echo '{ "name": "fixture", "private": true }' > package.json
        if [ "$sop" = "with-sop" ] || [ "$sop" = "with-code" ]; then
            mkdir -p docs/sop docs/recent-work docs/agent-memory/in-flight docs/reviews scripts
            printf '# Backlog\n\n### P1 — First thing\n`[OPEN] [Feature]`\n\nbody\n\n---\n' > Backlog.md
            echo "# SOP" > docs/sop/claude-agent-sop.md
            printf '# CLAUDE\n' > CLAUDE.md
            printf '# Recent Work\n\n<!-- recent-work-rollup:start -->\n*No entries yet.*\n<!-- recent-work-rollup:end -->\n' > docs/RECENT-WORK.md
            cp "$REPO_ROOT/scripts/resolve-resume-path.sh" scripts/
        fi
        $GIT add -A >/dev/null
        $GIT commit -q -m "init"
        $GIT push -q -u origin main 2>/dev/null
    )
}

# commit_code <dir> <msg>  — adds a code change (non-doc) and commits
commit_code() {
    local dir="$1" msg="$2"
    (
        cd "$dir" || exit 1
        for i in $(seq 1 12); do echo "line $RANDOM $i" >> src.js; done
        $GIT add -A >/dev/null
        $GIT commit -q -m "$msg"
    )
}

# commit_record <dir> <slug> — writes a recent-work entry and commits it
commit_record() {
    local dir="$1" slug="$2"
    (
        cd "$dir" || exit 1
        # git drops an empty directory on branch switch; recreate it so the
        # record lands (a fixture on a fresh branch used to lose it silently).
        mkdir -p docs/recent-work
        printf '# %s\n\n**Date:** 2026-09-04\n**Agent:** solo\n' "$slug" > "docs/recent-work/2026-09-04_solo_$slug.md"
        $GIT add -A >/dev/null
        $GIT commit -q -m "docs: session end housekeeping — $slug"
    )
}

# run_hook <script> <cwd> <json-extra> [env VAR=val ...]
# Feeds the hook a synthesised input JSON; captures exit, stdout, stderr.
run_hook() {
    local script="$1" cwd="$2" extra="$3"; shift 3
    local json
    json=$(printf '{"session_id":"%s","cwd":"%s"%s}' "${SESSION_ID:-s1}" "$cwd" "$extra")
    HOOK_OUT="$TMP/out"; HOOK_ERR="$TMP/err"
    ( cd "$cwd" 2>/dev/null || cd "$TMP" || exit 1; env "$@" bash "$script" >"$HOOK_OUT" 2>"$HOOK_ERR" <<<"$json" )
    HOOK_EXIT=$?
}

head_of() { git -C "$1" rev-parse HEAD; }

# push_json <command> — the PreToolUse(Bash) fields for a push-gate case.
# Defined with the other helpers: a case that calls it before its definition
# feeds the hook a JSON with no command, and the hook is then silent for the
# wrong reason (found when the first P102 push cases passed vacuously).
push_json() { printf ',"tool_name":"Bash","tool_input":{"command":"%s"}' "$1"; }

# write_json <tool> <file-path> — the PostToolUse fields for a memory-index case.
write_json() { printf ',"tool_name":"%s","tool_input":{"file_path":"%s"}' "$1" "$2"; }

# make_index <path> <entries> <hook-bytes> — an index of <entries> one-line
# entries, each carrying a hook of <hook-bytes> bytes.
make_index() {
    mkdir -p "$(dirname "$1")"
    awk -v n="$2" -v w="$3" 'BEGIN { h = sprintf("%" w "s", ""); gsub(/ /, "x", h)
        for (i = 1; i <= n; i++) printf "- [Entry %d](feedback_%d.md) - %s\n", i, i, h }' > "$1"
}

# ── Stop hook ─────────────────────────────────────────────────────────────────

NOTREPO="$TMP/notrepo"; mkdir -p "$NOTREPO"
run_hook "$STOP" "$NOTREPO" ''
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "stop-not-a-repo-silent"; else bad "stop-not-a-repo-silent" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi

PLAIN="$TMP/plain"; make_repo "$PLAIN"
commit_code "$PLAIN" "feat: something"
run_hook "$STOP" "$PLAIN" ''
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "stop-repo-without-sop-silent"; else bad "stop-repo-without-sop-silent" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi

# The drift fixtures run on a code repo: since P103 the Stop hook is silent on
# non-code projects entirely, and that silence has its own cases below.
SOP="$TMP/sop"; make_repo "$SOP" with-code
commit_record "$SOP" "first-session"
run_hook "$STOP" "$SOP" ''
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "stop-no-drift-silent"; else bad "stop-no-drift-silent" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi

commit_code "$SOP" "feat: unrecorded work"
SHORT=$(git -C "$SOP" rev-parse --short HEAD)
run_hook "$STOP" "$SOP" ''
if [ "$HOOK_EXIT" = 2 ] && grep -q "no session record" "$HOOK_ERR" && grep -q "$SHORT" "$HOOK_ERR"; then ok "stop-drift-fires-exit-2"; else bad "stop-drift-fires-exit-2" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi

run_hook "$STOP" "$SOP" ''
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "stop-same-state-throttled"; else bad "stop-same-state-throttled" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi

commit_code "$SOP" "feat: more unrecorded work"
run_hook "$STOP" "$SOP" ''
if [ "$HOOK_EXIT" = 2 ]; then ok "stop-refires-on-new-commit"; else bad "stop-refires-on-new-commit" "exit $HOOK_EXIT"; fi

run_hook "$STOP" "$SOP" ',"stop_hook_active":true'
if [ "$HOOK_EXIT" = 0 ]; then ok "stop-hook-active-guard"; else bad "stop-hook-active-guard" "exit $HOOK_EXIT"; fi

commit_record "$SOP" "second-session"
run_hook "$STOP" "$SOP" ''
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "stop-housekeeping-commit-clears"; else bad "stop-housekeeping-commit-clears" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi

# A PR merge commit after the branch's own housekeeping commit is not drift:
# the merge introduces no work, and the record already covers the branch (P99,
# found on the hook's first live firing).
(
    cd "$SOP" || exit 1
    git checkout -q -b feat/merged
    for i in $(seq 1 12); do echo "merged $i" >> merged.js; done
    $GIT add -A >/dev/null && $GIT commit -q -m "feat: work on branch"
    printf '# merged\n\n**Date:** 2026-09-04\n**Agent:** solo\n' > docs/recent-work/2026-09-04_solo_merged.md
    $GIT add -A >/dev/null && $GIT commit -q -m "docs: session end housekeeping — merged"
    git checkout -q main
    $GIT merge -q --no-ff -m "Merge pull request #1 from feat/merged" feat/merged
)
run_hook "$STOP" "$SOP" ''
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "stop-merge-commit-after-record-silent"; else bad "stop-merge-commit-after-record-silent" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi

echo "### P2 — Second thing" >> "$SOP/Backlog.md"
run_hook "$STOP" "$SOP" ''
if [ "$HOOK_EXIT" = 2 ] && grep -qi "uncommitted" "$HOOK_ERR" && grep -q "Backlog.md" "$HOOK_ERR"; then ok "stop-dirty-tracker-fires"; else bad "stop-dirty-tracker-fires" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi
run_hook "$STOP" "$SOP" ''
if [ "$HOOK_EXIT" = 0 ]; then ok "stop-dirty-tracker-throttled"; else bad "stop-dirty-tracker-throttled" "exit $HOOK_EXIT"; fi
git -C "$SOP" checkout -q -- Backlog.md

# ship-sop fold: gate demanded on a code diff vs origin/main with no covering report
SHIP="$TMP/ship"; make_repo "$SHIP" with-code
commit_record "$SHIP" "first-session"
git -C "$SHIP" push -q origin main 2>/dev/null
cat > "$SHIP/ship-sop.config.json" <<'JSON'
{ "trigger": { "mode": "auto", "throttle": { "min_diff_lines": 10, "skip_docs_only": true, "skip_branch_patterns": ["^wip/"] } },
  "agents": { "security-reviewer": { "enabled": true, "block_on": "CRITICAL" },
              "code-reviewer": { "enabled": true, "block_on": "HIGH" },
              "diagram-builder": { "enabled": false, "block_on": "never" } } }
JSON
(cd "$SHIP" && $GIT add -A >/dev/null && $GIT commit -q -m "chore: ship-sop config" && $GIT push -q origin main 2>/dev/null)
git -C "$SHIP" checkout -q -b feat/thing
commit_code "$SHIP" "feat: gated work"
commit_record "$SHIP" "recorded"          # session record present, so only the gate remains
run_hook "$STOP" "$SHIP" ''
if [ "$HOOK_EXIT" = 2 ] && grep -q "@security-reviewer" "$HOOK_ERR" && grep -q "@code-reviewer" "$HOOK_ERR" && ! grep -q "diagram-builder" "$HOOK_ERR" && grep -q "ship-auto.md" "$HOOK_ERR"; then ok "stop-shipsop-gate-demanded"; else bad "stop-shipsop-gate-demanded" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi

HEADSHA=$(head_of "$SHIP")
printf '# ship report\n\nCovers: %s\n' "$HEADSHA" > "$SHIP/docs/reviews/20260904-100000-ship-auto.md"
make_receipt "$SHIP" "$SHIP/docs/reviews/20260904-100000-ship-auto.json"
(cd "$SHIP" && $GIT add -A >/dev/null && $GIT commit -q -m "docs: ship report")
run_hook "$STOP" "$SHIP" ''
# The report commit is itself a commit after the last session record — so the
# hook may legitimately fire for that — but it must no longer demand the gates.
if ! grep -q "@security-reviewer" "$HOOK_ERR"; then ok "stop-shipsop-gate-satisfied-by-covering-report"; else bad "stop-shipsop-gate-satisfied-by-covering-report" "stderr='$(cat "$HOOK_ERR")'"; fi

DOCS="$TMP/docsonly"; make_repo "$DOCS" with-code
cp "$SHIP/ship-sop.config.json" "$DOCS/"
(cd "$DOCS" && $GIT add -A >/dev/null && $GIT commit -q -m "chore: config" && $GIT push -q origin main 2>/dev/null)
git -C "$DOCS" checkout -q -b feat/docs
(cd "$DOCS" && for i in $(seq 1 20); do echo "para $i" >> notes.md; done && $GIT add -A >/dev/null && $GIT commit -q -m "docs: notes")
commit_record "$DOCS" "recorded"
run_hook "$STOP" "$DOCS" ''
if ! grep -q "@security-reviewer" "$HOOK_ERR"; then ok "stop-shipsop-docs-only-no-gate"; else bad "stop-shipsop-docs-only-no-gate" "stderr='$(cat "$HOOK_ERR")'"; fi

# ── Reviewer scope by path (ship-sop P33 / agent-sop P111) ───────────────────
# An enabled reviewer with `paths` joins the gate only when the range touches
# a matching file; the demand, the receipt validator and the push gate read
# the same rule. Each case fails against the pre-P111 library, which keyed on
# `enabled` alone.
SCOPED="$TMP/scoped"; make_repo "$SCOPED" with-code
cat > "$SCOPED/ship-sop.config.json" <<'JSON'
{ "trigger": { "mode": "auto", "throttle": { "min_diff_lines": 10, "skip_branch_patterns": ["^wip/"] } },
  "agents": { "security-reviewer": { "enabled": true, "block_on": "CRITICAL", "paths": ["^scripts/", "\\.sh$"] },
              "code-reviewer": { "enabled": true, "block_on": "HIGH" } } }
JSON
(cd "$SCOPED" && $GIT add -A >/dev/null && $GIT commit -q -m "chore: scoped config" && $GIT push -q origin main 2>/dev/null)
git -C "$SCOPED" checkout -q -b feat/js-only
commit_code "$SCOPED" "feat: js work"
commit_record "$SCOPED" "recorded"
run_hook "$STOP" "$SCOPED" ''
if [ "$HOOK_EXIT" = 2 ] && grep -q "@code-reviewer" "$HOOK_ERR" && ! grep -q "security-reviewer" "$HOOK_ERR"; then ok "stop-shipsop-scoped-agent-out-of-scope-not-demanded"; else bad "stop-shipsop-scoped-agent-out-of-scope-not-demanded" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi

# A receipt from the in-scope reviewer alone covers the branch.
make_receipt "$SCOPED" "$SCOPED/docs/reviews/20260924-100000-ship-auto.json" '["code-reviewer"]'
(cd "$SCOPED" && $GIT add -A >/dev/null && $GIT commit -q -m "docs: ship report")
run_hook "$STOP" "$SCOPED" ''
if ! grep -q "@code-reviewer" "$HOOK_ERR"; then ok "stop-shipsop-scoped-receipt-without-out-of-scope-agent-covers"; else bad "stop-shipsop-scoped-receipt-without-out-of-scope-agent-covers" "stderr='$(cat "$HOOK_ERR")'"; fi

# A shell script enters the range: the scoped reviewer is demanded, a receipt
# that lacks it does not cover, and one that carries it does.
(cd "$SCOPED" && mkdir -p scripts && for i in $(seq 1 12); do echo "echo $i" >> scripts/run.sh; done && $GIT add -A >/dev/null && $GIT commit -q -m "feat: shell work")
commit_record "$SCOPED" "recorded-again"
run_hook "$STOP" "$SCOPED" ''
if [ "$HOOK_EXIT" = 2 ] && grep -q "@security-reviewer" "$HOOK_ERR" && grep -q "@code-reviewer" "$HOOK_ERR"; then ok "stop-shipsop-scoped-agent-in-scope-demanded"; else bad "stop-shipsop-scoped-agent-in-scope-demanded" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi
make_receipt "$SCOPED" "$SCOPED/docs/reviews/20260924-110000-ship-auto.json" '["code-reviewer"]'
(cd "$SCOPED" && $GIT add -A >/dev/null && $GIT commit -q -m "docs: partial ship report")
run_hook "$STOP" "$SCOPED" ''
if grep -q "@security-reviewer" "$HOOK_ERR"; then ok "stop-shipsop-scoped-receipt-missing-in-scope-agent-does-not-cover"; else bad "stop-shipsop-scoped-receipt-missing-in-scope-agent-does-not-cover" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi
make_receipt "$SCOPED" "$SCOPED/docs/reviews/20260924-120000-ship-auto.json"
(cd "$SCOPED" && $GIT add -A >/dev/null && $GIT commit -q -m "docs: full ship report")
run_hook "$STOP" "$SCOPED" ''
if ! grep -q "@security-reviewer" "$HOOK_ERR"; then ok "stop-shipsop-scoped-full-receipt-covers"; else bad "stop-shipsop-scoped-full-receipt-covers" "stderr='$(cat "$HOOK_ERR")'"; fi

# Every enabled reviewer out of scope: no gate at stop, and the push proceeds.
NOSCOPE="$TMP/noscope"; make_repo "$NOSCOPE" with-code
jq '.agents |= with_entries(.value.paths = ["^scripts/"])' "$SCOPED/ship-sop.config.json" > "$NOSCOPE/ship-sop.config.json"
(cd "$NOSCOPE" && $GIT add -A >/dev/null && $GIT commit -q -m "chore: config" && $GIT push -q origin main 2>/dev/null)
git -C "$NOSCOPE" checkout -q -b feat/js
commit_code "$NOSCOPE" "feat: js work"
commit_record "$NOSCOPE" "recorded"
run_hook "$STOP" "$NOSCOPE" ''
if ! grep -q "ship-sop gate" "$HOOK_ERR"; then ok "stop-shipsop-every-agent-out-of-scope-silent"; else bad "stop-shipsop-every-agent-out-of-scope-silent" "stderr='$(cat "$HOOK_ERR")'"; fi
run_hook "$PUSH" "$NOSCOPE" "$(push_json 'git push -u origin feat/js')"
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "push-shipsop-every-agent-out-of-scope-allowed"; else bad "push-shipsop-every-agent-out-of-scope-allowed" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi

# A malformed scope is an invalid policy, not a silent skip: `paths` must be an
# array of patterns that compile.
for badcase in 'paths-not-array:"^scripts/"' 'paths-bad-regex:["("]'; do
    BADNAME=${badcase%%:*}; BADVAL=${badcase#*:}
    BAD="$TMP/$BADNAME"; make_repo "$BAD" with-code
    jq --argjson v "$BADVAL" '.agents["security-reviewer"].paths = $v' "$SCOPED/ship-sop.config.json" > "$BAD/ship-sop.config.json"
    (cd "$BAD" && $GIT add -A >/dev/null && $GIT commit -q -m "chore: config" && $GIT push -q origin main 2>/dev/null)
    git -C "$BAD" checkout -q -b feat/js
    commit_code "$BAD" "feat: js work"
    commit_record "$BAD" "recorded"
    run_hook "$STOP" "$BAD" ''
    if [ "$HOOK_EXIT" = 2 ] && grep -q "configuration invalid" "$HOOK_ERR"; then ok "stop-shipsop-$BADNAME-invalid"; else bad "stop-shipsop-$BADNAME-invalid" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi
done

# ── Receipt run counts (ship-sop P34 / agent-sop P112) ───────────────────────
# A version-2 receipt carries launches, rechecks and block_rounds per reviewer;
# version 1 stays valid. Each case fails against the pre-P112 validator, which
# accepted version 1 only.
V2="$TMP/v2"; make_repo "$V2" with-code
cp "$SHIP/ship-sop.config.json" "$V2/"
(cd "$V2" && $GIT add -A >/dev/null && $GIT commit -q -m "chore: config" && $GIT push -q origin main 2>/dev/null)
git -C "$V2" checkout -q -b feat/counted
commit_code "$V2" "feat: counted work"
commit_record "$V2" "recorded"
make_receipt "$V2" "$TMP/v2-base.json"
jq '.schema_version = 2' "$TMP/v2-base.json" > "$V2/docs/reviews/20260924-130000-ship-auto.json"
(cd "$V2" && $GIT add -A >/dev/null && $GIT commit -q -m "docs: v2 receipt without counts")
run_hook "$STOP" "$V2" ''
if grep -q "@security-reviewer" "$HOOK_ERR"; then ok "stop-shipsop-v2-receipt-without-counts-does-not-cover"; else bad "stop-shipsop-v2-receipt-without-counts-does-not-cover" "stderr='$(cat "$HOOK_ERR")'"; fi
make_receipt "$V2" "$TMP/v2-base.json"
jq '.schema_version = 2 | .reviewers |= map(. + {launches: 1, rechecks: 2, block_rounds: 4, usage: null})' "$TMP/v2-base.json" > "$V2/docs/reviews/20260924-131000-ship-auto.json"
(cd "$V2" && $GIT add -A >/dev/null && $GIT commit -q -m "docs: v2 receipt with impossible rounds")
run_hook "$STOP" "$V2" ''
if grep -q "@security-reviewer" "$HOOK_ERR"; then ok "stop-shipsop-v2-receipt-more-block-rounds-than-runs-does-not-cover"; else bad "stop-shipsop-v2-receipt-more-block-rounds-than-runs-does-not-cover" "stderr='$(cat "$HOOK_ERR")'"; fi
make_receipt "$V2" "$TMP/v2-base.json"
jq '.schema_version = 2 | .reviewers |= map(. + {launches: 1, rechecks: 2, block_rounds: 2, usage: null})' "$TMP/v2-base.json" > "$V2/docs/reviews/20260924-132000-ship-auto.json"
(cd "$V2" && $GIT add -A >/dev/null && $GIT commit -q -m "docs: v2 receipt with counts")
run_hook "$STOP" "$V2" ''
if ! grep -q "@security-reviewer" "$HOOK_ERR"; then ok "stop-shipsop-v2-receipt-with-counts-covers"; else bad "stop-shipsop-v2-receipt-with-counts-covers" "stderr='$(cat "$HOOK_ERR")'"; fi

# ── Project type (P102) ──────────────────────────────────────────────────────
# The operator's rule: ship-sop fires for coding and for nothing else. One
# function decides what "coding" is; these cases pin it.

ptype() { bash "$PTYPE" "$1" 2>/dev/null; }

PLAINSOP="$TMP/plainsop"; make_repo "$PLAINSOP" with-sop
if [ "$(ptype "$PLAINSOP")" = "non-code" ]; then ok "type-plain-sop-is-non-code"; else bad "type-plain-sop-is-non-code" "got '$(ptype "$PLAINSOP")'"; fi
if [ "$(ptype "$SHIP")" = "code" ]; then ok "type-manifest-is-code"; else bad "type-manifest-is-code" "got '$(ptype "$SHIP")'"; fi
if [ "$(ptype "$TMP/notrepo")" = "non-code" ]; then ok "type-not-a-repo-is-non-code"; else bad "type-not-a-repo-is-non-code" "got '$(ptype "$TMP/notrepo")'"; fi

TYPED="$TMP/typed"; mkdir -p "$TYPED"
echo '{}' > "$TYPED/package.json"
printf '# X\n\n**Project type:** non-code\n' > "$TYPED/CLAUDE.md"
if [ "$(ptype "$TYPED")" = "non-code" ]; then ok "type-declaration-overrides-manifest"; else bad "type-declaration-overrides-manifest" "got '$(ptype "$TYPED")'"; fi
rm -f "$TYPED/package.json"
printf '# X\n\nProject type: Code\n' > "$TYPED/CLAUDE.md"
if [ "$(ptype "$TYPED")" = "code" ]; then ok "type-declaration-code-without-manifest"; else bad "type-declaration-code-without-manifest" "got '$(ptype "$TYPED")'"; fi
printf '# X\n\n## Auth\n\nsupabase\n' > "$TYPED/CLAUDE.md"
if [ "$(ptype "$TYPED")" = "code" ]; then ok "type-auth-heading-is-code"; else bad "type-auth-heading-is-code" "got '$(ptype "$TYPED")'"; fi
printf '# X\n\nStarted from claude-md-template-code.md\n' > "$TYPED/CLAUDE.md"
if [ "$(ptype "$TYPED")" = "code" ]; then ok "type-code-template-reference-is-code"; else bad "type-code-template-reference-is-code" "got '$(ptype "$TYPED")'"; fi
printf '# X\n\n## Key Commands\n\n```bash\nnpm test\n```\n\n## Other\n' > "$TYPED/CLAUDE.md"
if [ "$(ptype "$TYPED")" = "code" ]; then ok "type-key-commands-test-is-code"; else bad "type-key-commands-test-is-code" "got '$(ptype "$TYPED")'"; fi
printf '# X\n\n## Key Commands\n\n```bash\npython3 check-invariants.py   # the test suite for the prose\n```\n\n## Other\n\nnpm test is not run here.\n' > "$TYPED/CLAUDE.md"
if [ "$(ptype "$TYPED")" = "non-code" ]; then ok "type-test-word-in-prose-is-non-code"; else bad "type-test-word-in-prose-is-non-code" "got '$(ptype "$TYPED")'"; fi

# A prose repo carrying an auto config gets no gate anywhere: not at stop, not
# at push, and the context block says why. Each of the three fails against the
# pre-P102 library, which keyed on the config alone.
PROSE="$TMP/prose"; make_repo "$PROSE" with-sop
cp "$SHIP/ship-sop.config.json" "$PROSE/"
(cd "$PROSE" && $GIT add -A >/dev/null && $GIT commit -q -m "chore: config" && $GIT push -q origin main 2>/dev/null)
git -C "$PROSE" checkout -q -b feat/prose
commit_code "$PROSE" "feat: a script in a prose repo"
commit_record "$PROSE" "recorded"
run_hook "$STOP" "$PROSE" ''
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "stop-shipsop-non-code-project-no-gate"; else bad "stop-shipsop-non-code-project-no-gate" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi
run_hook "$PUSH" "$PROSE" "$(push_json 'git push -u origin feat/prose')"
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "push-shipsop-non-code-project-allowed"; else bad "push-shipsop-non-code-project-allowed" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi
SESSION_ID=ctx-prose run_hook "$CTX" "$PROSE" ''
if grep -q "non-code project) ---" "$HOOK_OUT" && grep -q "^Ship gate: none — non-code project" "$HOOK_OUT"; then ok "ctx-non-code-project-says-why"; else bad "ctx-non-code-project-says-why" "out='$(grep -E 'Agent SOP context|Ship gate' "$HOOK_OUT")'"; fi

# P103: the drift half is code-only too. Unrecorded commit and dirty tracker
# on a non-code SOP repo leave the Stop hook silent; the context block still
# shows the facts and says nothing is enforced. Both fail against the P102
# library, which demanded the record.
run_hook "$STOP" "$PLAINSOP" ''
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "stop-non-code-initial-silent"; else bad "stop-non-code-initial-silent" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi
commit_code "$PLAINSOP" "feat: unrecorded work in a prose repo"
run_hook "$STOP" "$PLAINSOP" ''
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "stop-non-code-unrecorded-commit-silent"; else bad "stop-non-code-unrecorded-commit-silent" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi
echo "### P9 — Prose item" >> "$PLAINSOP/Backlog.md"
run_hook "$STOP" "$PLAINSOP" ''
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "stop-non-code-dirty-tracker-silent"; else bad "stop-non-code-dirty-tracker-silent" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi
SESSION_ID=ctx-plainsop run_hook "$CTX" "$PLAINSOP" ''
if grep -Eq "^Drift: [0-9]+ commit\(s\) since the last session record" "$HOOK_OUT" && grep -q "^Uncommitted tracker files: Backlog.md" "$HOOK_OUT" && grep -q "Non-code project: the Stop hook enforces nothing here" "$HOOK_OUT"; then ok "ctx-non-code-shows-drift-says-not-enforced"; else bad "ctx-non-code-shows-drift-says-not-enforced" "out='$(grep -E '^(Drift|Uncommitted|This replaces|Non-code)' "$HOOK_OUT")'"; fi
git -C "$PLAINSOP" checkout -q -- Backlog.md
SESSION_ID=ctx-sopcode run_hook "$CTX" "$SOP" ''
if grep -qx "This replaces /restart-sop Steps 0-4. Read the Backlog.md item for the task before starting it." "$HOOK_OUT"; then ok "ctx-code-closing-line"; else bad "ctx-code-closing-line" "out='$(tail -2 "$HOOK_OUT")'"; fi
# A legacy project_resume.md that says SUPERSEDED on its first line is not
# served as the resume snapshot (cost audit, 2026-09-05).
SUPER="$TMP/super"; make_repo "$SUPER" with-code
SUPER_DIR=$(dirname "$(bash "$SUPER/scripts/resolve-resume-path.sh" --root "$(git -C "$SUPER" rev-parse --show-toplevel)" --home "$HOME")")
mkdir -p "$SUPER_DIR" && printf '**SUPERSEDED - 2026-08-07.** Use the per-agent file.\n\n## What is next\n- stale\n' > "$SUPER_DIR/project_resume.md"
SESSION_ID=ctx-super run_hook "$CTX" "$SUPER" ''
if grep -q "^Resume snapshot: .*marked superseded" "$HOOK_OUT" && ! grep -q "^- stale$" "$HOOK_OUT"; then ok "ctx-superseded-legacy-resume-not-served"; else bad "ctx-superseded-legacy-resume-not-served" "out='$(grep -A1 'Resume snapshot' "$HOOK_OUT" | head -2)'"; fi

# The notice's own "carry on" instruction — add a line to the in-flight file —
# must not re-fire it (seen live on the first P103 run); any other tracker
# edit is a new state and does.
commit_code "$SOP" "feat: throttle probe"
run_hook "$STOP" "$SOP" ''
if [ "$HOOK_EXIT" = 2 ]; then ok "stop-fires-on-new-commit-before-inflight-probe"; else bad "stop-fires-on-new-commit-before-inflight-probe" "exit $HOOK_EXIT"; fi
printf '(2026-09-05): probe\n' >> "$SOP/docs/agent-memory/in-flight/solo.md"
run_hook "$STOP" "$SOP" ''
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "stop-inflight-edit-does-not-refire"; else bad "stop-inflight-edit-does-not-refire" "exit $HOOK_EXIT stderr='$(head -3 "$HOOK_ERR")'"; fi
echo "### P3 — Third thing" >> "$SOP/Backlog.md"
run_hook "$STOP" "$SOP" ''
if [ "$HOOK_EXIT" = 2 ] && grep -q "in-flight/solo.md" "$HOOK_ERR"; then ok "stop-other-tracker-edit-refires-and-lists-inflight"; else bad "stop-other-tracker-edit-refires-and-lists-inflight" "exit $HOOK_EXIT stderr='$(head -3 "$HOOK_ERR")'"; fi
git -C "$SOP" checkout -q -- Backlog.md && rm -f "$SOP/docs/agent-memory/in-flight/solo.md"

# The declaration opts a manifest-less repo in: same tree, one line added.
printf '\n**Project type:** code\n' >> "$PROSE/CLAUDE.md"
run_hook "$PUSH" "$PROSE" "$(push_json 'git push -u origin feat/prose')"
if [ "$HOOK_EXIT" = 2 ] && grep -q "ship-auto.md" "$HOOK_ERR"; then ok "push-shipsop-declared-code-refused"; else bad "push-shipsop-declared-code-refused" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi
# ...and the drift half follows the declaration too (P103): an unrecorded
# commit on the declared-code, manifest-less repo gets the Stop notice.
commit_code "$PROSE" "feat: unrecorded under a code declaration"
SHORT=$(git -C "$PROSE" rev-parse --short HEAD)
run_hook "$STOP" "$PROSE" ''
if [ "$HOOK_EXIT" = 2 ] && grep -q "no session record" "$HOOK_ERR" && grep -q "$SHORT" "$HOOK_ERR"; then ok "stop-declared-code-without-manifest-fires"; else bad "stop-declared-code-without-manifest-fires" "exit $HOOK_EXIT stderr='$(head -3 "$HOOK_ERR")'"; fi
git -C "$PROSE" reset -q --hard HEAD~1

# Code lines only, whatever the config says: a docs-only branch in a code
# project with skip_docs_only=false still gets no gate. Does not fail against
# the pre-P102 library — its `jq // true` default already swallowed an
# explicit false — so this pins the rule rather than the fix.
LOOSE="$TMP/loose"; make_repo "$LOOSE" with-code
jq '.trigger.throttle.skip_docs_only = false' "$SHIP/ship-sop.config.json" > "$LOOSE/ship-sop.config.json"
(cd "$LOOSE" && $GIT add -A >/dev/null && $GIT commit -q -m "chore: config" && $GIT push -q origin main 2>/dev/null)
git -C "$LOOSE" checkout -q -b feat/prose-in-code
(cd "$LOOSE" && for i in $(seq 1 20); do echo "para $i" >> notes.md; done && $GIT add -A >/dev/null && $GIT commit -q -m "docs: notes")
commit_record "$LOOSE" "recorded"
run_hook "$STOP" "$LOOSE" ''
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "stop-shipsop-skip-docs-false-still-code-only"; else bad "stop-shipsop-skip-docs-false-still-code-only" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi
SESSION_ID=ctx-ship run_hook "$CTX" "$SHIP" ''
if grep -q "code project) ---" "$HOOK_OUT" && ! grep -q "non-code project) ---" "$HOOK_OUT"; then ok "ctx-code-project-named-in-header"; else bad "ctx-code-project-named-in-header" "out='$(head -1 "$HOOK_OUT")'"; fi

# Review fixes (P102, reviewer turn). Declaration parsing: a fenced example is
# not a declaration; a bulleted declaration is. A `non-code` declaration over
# real code signals is honoured and named in the context block; the old block
# printed the plain non-code line (security HIGH).
printf '# X\n\nHow to declare:\n\n```\n**Project type:** code\n```\n\nProse only here.\n' > "$TYPED/CLAUDE.md"
if [ "$(ptype "$TYPED")" = "non-code" ]; then ok "type-fenced-example-is-not-a-declaration"; else bad "type-fenced-example-is-not-a-declaration" "got '$(ptype "$TYPED")'"; fi
printf '# X\n\n- **Project type:** code\n' > "$TYPED/CLAUDE.md"
if [ "$(ptype "$TYPED")" = "code" ]; then ok "type-bulleted-declaration-counts"; else bad "type-bulleted-declaration-counts" "got '$(ptype "$TYPED")'"; fi
printf '# X\n\n**Project type:** code\r\n' > "$TYPED/CLAUDE.md"
if [ "$(ptype "$TYPED")" = "code" ]; then ok "type-crlf-declaration-counts"; else bad "type-crlf-declaration-counts" "got '$(ptype "$TYPED")'"; fi
printf '# X\n\n## Key Commands\n\n```bash\nnpm test\n```\n' > "$TYPED/CLAUDE.md"
if [ "$(ptype "$TYPED")" = "code" ]; then ok "type-key-commands-last-section-counts"; else bad "type-key-commands-last-section-counts" "got '$(ptype "$TYPED")'"; fi
rm -f "$TYPED/CLAUDE.md"; mkdir -p "$TYPED/packages/app" && echo '{}' > "$TYPED/packages/app/package.json"
if [ "$(ptype "$TYPED")" = "non-code" ]; then ok "type-manifest-in-subdirectory-only-is-non-code"; else bad "type-manifest-in-subdirectory-only-is-non-code" "got '$(ptype "$TYPED")'"; fi
rm -rf "$TYPED/packages"
# The real templates carry the declaration; feed the actual files through.
cp "$REPO_ROOT/docs/templates/claude-md-template.md" "$TYPED/CLAUDE.md"
if [ "$(ptype "$TYPED")" = "non-code" ]; then ok "type-base-template-is-non-code"; else bad "type-base-template-is-non-code" "got '$(ptype "$TYPED")'"; fi
cp "$REPO_ROOT/docs/templates/claude-md-template-code.md" "$TYPED/CLAUDE.md"
if [ "$(ptype "$TYPED")" = "code" ]; then ok "type-code-template-is-code"; else bad "type-code-template-is-code" "got '$(ptype "$TYPED")'"; fi

# One invalid byte in CLAUDE.md must not blank the whole parse (BSD grep in a
# UTF-8 locale aborts the file; the library now runs in the C locale).
printf '# X\n\npasted quote: \xff\xfe\n\n**Project type:** code\n' > "$TYPED/CLAUDE.md"
if [ "$(ptype "$TYPED")" = "code" ]; then ok "type-invalid-byte-does-not-blank-declaration"; else bad "type-invalid-byte-does-not-blank-declaration" "got '$(ptype "$TYPED")'"; fi
printf '# X\n\n\xff\n## Auth\n' > "$TYPED/CLAUDE.md"
if [ "$(ptype "$TYPED")" = "code" ]; then ok "type-invalid-byte-does-not-blank-heuristics"; else bad "type-invalid-byte-does-not-blank-heuristics" "got '$(ptype "$TYPED")'"; fi
# A dangling CLAUDE.md symlink reads as missing and the context block says so.
DANGLE="$TMP/dangle"; make_repo "$DANGLE" with-sop
rm -f "$DANGLE/CLAUDE.md" && ln -s ../nowhere/CLAUDE.md "$DANGLE/CLAUDE.md"
SESSION_ID=ctx-dangle run_hook "$CTX" "$DANGLE" ''
if grep -q "^Project type: non-code — CLAUDE.md is a symlink whose target is missing" "$HOOK_OUT"; then ok "ctx-dangling-claude-md-named"; else bad "ctx-dangling-claude-md-named" "out='$(grep -E 'Project type' "$HOOK_OUT")'"; fi

# Silent-failure review: heuristics are case-insensitive like the declaration;
# a hyphen after the declared value is not part of the value.
printf '# X\n\n## AUTH\n\nx\n' > "$TYPED/CLAUDE.md"
if [ "$(ptype "$TYPED")" = "code" ]; then ok "type-heading-case-insensitive"; else bad "type-heading-case-insensitive" "got '$(ptype "$TYPED")'"; fi
printf '# X\n\n## Key commands\n\n```\nNPM TEST\n```\n' > "$TYPED/CLAUDE.md"
if [ "$(ptype "$TYPED")" = "code" ]; then ok "type-key-commands-case-insensitive"; else bad "type-key-commands-case-insensitive" "got '$(ptype "$TYPED")'"; fi
printf '# X\n\n**Project type:** code-focused rewrite\n' > "$TYPED/CLAUDE.md"
if [ "$(ptype "$TYPED")" = "code" ]; then ok "type-declaration-followed-by-hyphen"; else bad "type-declaration-followed-by-hyphen" "got '$(ptype "$TYPED")'"; fi

# A documentation file renamed into a code file, with logic added, is code:
# numstat reports `old => new` and whitespace splitting read the old name
# (silent-failure review, CRITICAL). Trigger and coverage both use the count.
RENAME="$TMP/rename"; make_repo "$RENAME" with-code
cp "$SHIP/ship-sop.config.json" "$RENAME/"
(cd "$RENAME" && for i in $(seq 1 30); do echo "prose line $i" >> notes.md; done && $GIT add -A >/dev/null && $GIT commit -q -m "chore: config + notes" && $GIT push -q origin main 2>/dev/null)
git -C "$RENAME" checkout -q -b feat/rename
(cd "$RENAME" && git mv notes.md gen.js && for i in $(seq 1 12); do echo "code($i);" >> gen.js; done && $GIT add -A >/dev/null && $GIT commit -q -m "feat: notes become code")
commit_record "$RENAME" "recorded"
NUMSTAT=$(git -C "$RENAME" diff --numstat origin/main..HEAD | grep -c '=>')
run_hook "$STOP" "$RENAME" ''
if [ "$NUMSTAT" -ge 1 ] && [ "$HOOK_EXIT" = 2 ] && grep -q "@security-reviewer" "$HOOK_ERR"; then ok "stop-rename-doc-to-code-counts"; else bad "stop-rename-doc-to-code-counts" "renames=$NUMSTAT exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi
# The gate demand tells the session how to run the agents and never to file
# findings to Backlog.md (operator rule; the old text said the opposite).
run_hook "$PUSH" "$RENAME" "$(push_json 'git push -u origin feat/rename')"
if [ "$HOOK_EXIT" = 2 ] && grep -q 'isolation: "worktree"' "$HOOK_ERR" && grep -q "file nothing to Backlog.md" "$HOOK_ERR" && ! grep -q "filed to Backlog" "$HOOK_ERR"; then ok "push-gate-demand-no-backlog-filing"; else bad "push-gate-demand-no-backlog-filing" "exit $HOOK_EXIT stderr='$(grep -i 'backlog\|isolation' "$HOOK_ERR")'"; fi

CONTRA="$TMP/contra"; make_repo "$CONTRA" with-code
cp "$SHIP/ship-sop.config.json" "$CONTRA/"
printf '# CLAUDE\n\n**Project type:** non-code\n' > "$CONTRA/CLAUDE.md"
(cd "$CONTRA" && $GIT add -A >/dev/null && $GIT commit -q -m "chore: declare non-code" && $GIT push -q origin main 2>/dev/null)
SESSION_ID=ctx-contra run_hook "$CTX" "$CONTRA" ''
if grep -q "non-code project) ---" "$HOOK_OUT" && grep -q "^Project type: non-code — CLAUDE.md declares non-code, but package.json say code" "$HOOK_OUT" && grep -q "^Project type:.*the Stop hook enforces nothing here" "$HOOK_OUT"; then ok "ctx-declared-non-code-over-manifest-named"; else bad "ctx-declared-non-code-over-manifest-named" "out='$(grep -E 'Agent SOP context|Project type|Ship gate' "$HOOK_OUT")'"; fi
# The same contradiction with no ship-sop config at all is still named (the
# gate line does not print there, and the Stop hook's silence rides on this).
rm -f "$CONTRA/ship-sop.config.json"
SESSION_ID=ctx-contra-nocfg run_hook "$CTX" "$CONTRA" ''
if grep -q "^Project type: non-code — CLAUDE.md declares non-code, but package.json say code" "$HOOK_OUT" && ! grep -q "^Ship gate:" "$HOOK_OUT"; then ok "ctx-contradiction-named-without-config"; else bad "ctx-contradiction-named-without-config" "out='$(grep -E 'Project type|Ship gate' "$HOOK_OUT")'"; fi
git -C "$CONTRA" checkout -q -- ship-sop.config.json
git -C "$CONTRA" checkout -q -b feat/c
commit_code "$CONTRA" "feat: code under a non-code declaration"
commit_record "$CONTRA" "recorded"
run_hook "$STOP" "$CONTRA" ''
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "stop-declared-non-code-honoured"; else bad "stop-declared-non-code-honoured" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi
# All three facts at once on the declared-non-code repo — unrecorded commit,
# dirty tracker, auto config with a code diff — and still silence, with no
# throttle marker written (the type check precedes the facts and the marker).
commit_code "$CONTRA" "feat: unrecorded under a non-code declaration"
echo "### P4 — Fourth thing" >> "$CONTRA/Backlog.md"
run_hook "$STOP" "$CONTRA" ''
CONTRA_KEY=$(printf '%s' "$(git -C "$CONTRA" rev-parse --show-toplevel)" | shasum -a 256 | cut -c1-12)
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ] && [ ! -e "$AGENT_SOP_STATE_DIR/repos/$CONTRA_KEY/stop.marker" ]; then ok "stop-declared-non-code-all-facts-silent-no-marker"; else bad "stop-declared-non-code-all-facts-silent-no-marker" "exit $HOOK_EXIT marker=$([ -e "$AGENT_SOP_STATE_DIR/repos/$CONTRA_KEY/stop.marker" ] && echo yes || echo no) stderr='$(head -2 "$HOOK_ERR")'"; fi
git -C "$CONTRA" checkout -q -- Backlog.md

# Coverage uses the same code-only count as the trigger: a covered code
# branch stays covered through a later docs-only commit even with
# skip_docs_only=false in the config (the dropped parameter's only branch).
git -C "$LOOSE" checkout -q main && git -C "$LOOSE" checkout -q -b feat/covered
commit_code "$LOOSE" "feat: code to cover"
commit_record "$LOOSE" "recorded"
printf '# report\n\nCovers: %s\n' "$(head_of "$LOOSE")" > "$LOOSE/docs/reviews/20260904-120000-ship-auto.md"
make_receipt "$LOOSE" "$LOOSE/docs/reviews/20260904-120000-ship-auto.json"
(cd "$LOOSE" && $GIT add -A >/dev/null && $GIT commit -q -m "docs: ship report")
(cd "$LOOSE" && for i in $(seq 1 20); do echo "more $i" >> notes.md; done && $GIT add -A >/dev/null && $GIT commit -q -m "docs: more notes")
run_hook "$PUSH" "$LOOSE" "$(push_json 'git push -u origin feat/covered')"
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "push-covered-survives-docs-commit-skip-docs-false"; else bad "push-covered-survives-docs-commit-skip-docs-false" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi
SESSION_ID=ctx-loose run_hook "$CTX" "$LOOSE" ''
if ! grep -q "^Ship gate:" "$HOOK_OUT"; then ok "ctx-covered-gate-line-absent"; else bad "ctx-covered-gate-line-absent" "out='$(grep 'Ship gate' "$HOOK_OUT")'"; fi

# ── Push gate ─────────────────────────────────────────────────────────────────

run_hook "$PUSH" "$SOP" "$(push_json 'ls -la')"
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "push-non-push-command-silent"; else bad "push-non-push-command-silent" "exit $HOOK_EXIT"; fi

run_hook "$PUSH" "$SOP" "$(push_json 'git push origin main')"
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "push-no-shipsop-allowed"; else bad "push-no-shipsop-allowed" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi

GATED="$TMP/gated"; make_repo "$GATED" with-code
cp "$SHIP/ship-sop.config.json" "$GATED/"
(cd "$GATED" && $GIT add -A >/dev/null && $GIT commit -q -m "chore: config" && $GIT push -q origin main 2>/dev/null)
git -C "$GATED" checkout -q -b feat/push
commit_code "$GATED" "feat: needs review"
run_hook "$PUSH" "$GATED" "$(push_json 'git push -u origin feat/push')"
if [ "$HOOK_EXIT" = 2 ] && grep -q "SOP_SKIP_GATE=1" "$HOOK_ERR" && grep -q "ship-auto.md" "$HOOK_ERR"; then ok "push-shipsop-uncovered-refused"; else bad "push-shipsop-uncovered-refused" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi

run_hook "$PUSH" "$GATED" "$(push_json 'gh pr create --fill')"
if [ "$HOOK_EXIT" = 2 ]; then ok "push-gh-pr-create-refused"; else bad "push-gh-pr-create-refused" "exit $HOOK_EXIT"; fi

run_hook "$PUSH" "$GATED" "$(push_json 'SOP_SKIP_GATE=1 git push -u origin feat/push')"
if [ "$HOOK_EXIT" = 0 ] && [ -s "$GATED/.ship/bypass.log" ] && grep -q "$(head_of "$GATED")" "$GATED/.ship/bypass.log"; then ok "push-skip-env-allowed-and-logged"; else bad "push-skip-env-allowed-and-logged" "exit $HOOK_EXIT log='$(cat "$GATED/.ship/bypass.log" 2>/dev/null)'"; fi

# Shell-wrapped invocations must still be caught (review finding, HIGH), and
# a push verb inside quoted prose must not trip the gate (MEDIUM).
run_hook "$PUSH" "$GATED" "$(push_json "bash -c 'git push origin feat/push'")"
if [ "$HOOK_EXIT" = 2 ]; then ok "push-bash-c-wrapper-refused"; else bad "push-bash-c-wrapper-refused" "exit $HOOK_EXIT"; fi
run_hook "$PUSH" "$GATED" "$(push_json 'sh -c \"gh pr create --fill\"')"
if [ "$HOOK_EXIT" = 2 ]; then ok "push-sh-c-double-quoted-refused"; else bad "push-sh-c-double-quoted-refused" "exit $HOOK_EXIT"; fi
run_hook "$PUSH" "$GATED" "$(push_json "eval 'git push'")"
if [ "$HOOK_EXIT" = 2 ]; then ok "push-eval-wrapper-refused"; else bad "push-eval-wrapper-refused" "exit $HOOK_EXIT"; fi
run_hook "$PUSH" "$GATED" "$(push_json 'echo done && `git push`')"
if [ "$HOOK_EXIT" = 2 ]; then ok "push-backtick-refused"; else bad "push-backtick-refused" "exit $HOOK_EXIT"; fi
run_hook "$PUSH" "$GATED" "$(push_json 'echo \"remember to run git push after this\"')"
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "push-verb-in-quoted-prose-silent"; else bad "push-verb-in-quoted-prose-silent" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi
run_hook "$PUSH" "$GATED" "$(push_json "cat > notes.md <<EOF\nRemember to run git push and then gh pr create.\nEOF")"
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "push-verb-in-heredoc-body-silent"; else bad "push-verb-in-heredoc-body-silent" "exit $HOOK_EXIT stderr='$(head -1 "$HOOK_ERR")'"; fi
run_hook "$PUSH" "$GATED" "$(push_json "cat > notes.md <<EOF\nplain notes\nEOF\ngit push -u origin feat/push")"
if [ "$HOOK_EXIT" = 2 ]; then ok "push-after-heredoc-still-refused"; else bad "push-after-heredoc-still-refused" "exit $HOOK_EXIT"; fi
run_hook "$PUSH" "$GATED" "$(push_json "git commit -m 'then git push'")"
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "push-verb-in-commit-message-silent"; else bad "push-verb-in-commit-message-silent" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi

printf '# report\n\nCovers: %s\n' "$(head_of "$GATED")" > "$GATED/docs/reviews/20260904-110000-ship-auto.md"
make_receipt "$GATED" "$GATED/docs/reviews/20260904-110000-ship-auto.json"
run_hook "$PUSH" "$GATED" "$(push_json 'git push -u origin feat/push')"
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "push-shipsop-covered-allowed"; else bad "push-shipsop-covered-allowed" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi

# Tracker paths with spaces survive the dirty listing intact (review finding, LOW).
touch "$SOP/docs/reviews/with space.md"
run_hook "$STOP" "$SOP" ''
if grep -q 'with space.md' "$HOOK_ERR"; then ok "stop-dirty-path-with-space-intact"; else bad "stop-dirty-path-with-space-intact" "stderr='$(cat "$HOOK_ERR")'"; fi
rm -f "$SOP/docs/reviews/with space.md"

# ── Session context hook ──────────────────────────────────────────────────────

run_hook "$CTX" "$PLAIN" ',"source":"startup"'
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_OUT" ]; then ok "ctx-non-sop-repo-silent"; else bad "ctx-non-sop-repo-silent" "exit $HOOK_EXIT out='$(head -c 200 "$HOOK_OUT")'"; fi

# Give the SOP repo a resume file at the production-derived path and an in-flight line.
# The root must be git's own toplevel: on macOS mktemp paths pass through a
# symlink, and the derivation is a function of the exact path string — every
# production caller feeds it `git rev-parse --show-toplevel`, so the test must too.
RESUME_PATH=$(bash "$SOP/scripts/resolve-resume-path.sh" --root "$(git -C "$SOP" rev-parse --show-toplevel)" --home "$HOME")
mkdir -p "$(dirname "$RESUME_PATH")"
printf '# Session Resume — sop — Agent solo\n\n## What is next\n- finish P1\n' > "$RESUME_PATH"
printf '(2026-09-04): P1 half done\n' > "$SOP/docs/agent-memory/in-flight/solo.md"
sed -i.bak 's/\[OPEN\] \[Feature\]/[IN PROGRESS] [Feature]/' "$SOP/Backlog.md" && rm -f "$SOP/Backlog.md.bak"
# A shipped entry whose body quotes the tag in prose must not be listed (P100,
# found on the context hook's first live run).
printf '\n### P2 — Shipped thing\n`[SHIPPED - 2026-09-04] [Feature]`\n\nThe validator rejects `[OPEN]` -> `[SHIPPED]` with no `[IN PROGRESS]` intermediate.\n\n---\n' >> "$SOP/Backlog.md"
commit_code "$SOP" "feat: drift for ctx"

SESSION_ID=ctx-1 run_hook "$CTX" "$SOP" ',"source":"startup"'
if [ "$HOOK_EXIT" = 0 ] && grep -q "Agent SOP context" "$HOOK_OUT" && grep -q "finish P1" "$HOOK_OUT" && grep -q "P1 half done" "$HOOK_OUT" && grep -q "P1 — First thing" "$HOOK_OUT" && ! grep -q "P2 — Shipped thing" "$HOOK_OUT" && grep -qi "session record" "$HOOK_OUT"; then ok "ctx-first-load-prints-bundle"; else bad "ctx-first-load-prints-bundle" "exit $HOOK_EXIT out='$(cat "$HOOK_OUT")'"; fi

SESSION_ID=ctx-1 run_hook "$CTX" "$SOP" ''
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_OUT" ]; then ok "ctx-same-session-silent"; else bad "ctx-same-session-silent" "out='$(head -c 200 "$HOOK_OUT")'"; fi

SESSION_ID=ctx-2 run_hook "$CTX" "$SOP" ''
if grep -q "Agent SOP context" "$HOOK_OUT"; then ok "ctx-new-session-prints-again"; else bad "ctx-new-session-prints-again" "out='$(head -c 200 "$HOOK_OUT")'"; fi

SESSION_ID=ctx-2 run_hook "$CTX" "$SOP" ',"source":"compact"'
if grep -q "Agent SOP context" "$HOOK_OUT"; then ok "ctx-compact-reprints"; else bad "ctx-compact-reprints" "out='$(head -c 200 "$HOOK_OUT")'"; fi

# Sibling worktree with uncommitted edits is surfaced.
git -C "$SOP" worktree add -q "$TMP/sop-sibling" -b sibling 2>/dev/null
echo "wip" >> "$TMP/sop-sibling/README.md"
SESSION_ID=ctx-3 run_hook "$CTX" "$SOP" ''
if grep -qi "sibling" "$HOOK_OUT" && grep -q "sop-sibling" "$HOOK_OUT"; then ok "ctx-dirty-sibling-worktree-surfaced"; else bad "ctx-dirty-sibling-worktree-surfaced" "out='$(cat "$HOOK_OUT")'"; fi

# Ship gate state is shown at prompt time, not only at stop (P101). GATED has
# a config and a report covering its current HEAD; one more code commit leaves
# the gate outstanding. SOP has no config, so no line at all.
SESSION_ID=ctx-gate-1 run_hook "$CTX" "$GATED" ''
if ! grep -q "^Ship gate:" "$HOOK_OUT"; then ok "ctx-covered-gate-line-absent-on-gated"; else bad "ctx-covered-gate-line-absent-on-gated" "out='$(grep 'Ship gate' "$HOOK_OUT")'"; fi
# A clean code repo (record covers HEAD, nothing dirty, one worktree, no
# config) prints none of the default-state lines (P104).
CLEAN="$TMP/clean"; make_repo "$CLEAN" with-code
commit_record "$CLEAN" "first-session"
SESSION_ID=ctx-clean run_hook "$CTX" "$CLEAN" ''
if grep -q "Agent SOP context" "$HOOK_OUT" && ! grep -qE "^(Ship gate|Drift|Uncommitted tracker|Worktrees|In-flight|In progress|SOP sync)" "$HOOK_OUT"; then ok "ctx-clean-repo-prints-no-default-facts"; else bad "ctx-clean-repo-prints-no-default-facts" "out='$(grep -E '^(Ship gate|Drift|Uncommitted|Worktrees|In-flight|In progress|SOP sync)' "$HOOK_OUT")'"; fi
commit_code "$GATED" "feat: uncovered again"
SESSION_ID=ctx-gate-2 run_hook "$CTX" "$GATED" ''
if grep -q "^Ship gate: outstanding" "$HOOK_OUT" && grep -q "code lines" "$HOOK_OUT"; then ok "ctx-ship-gate-outstanding-shown"; else bad "ctx-ship-gate-outstanding-shown" "out='$(grep -i 'ship gate' "$HOOK_OUT")'"; fi
SESSION_ID=ctx-gate-3 run_hook "$CTX" "$SOP" ''
if ! grep -q "^Ship gate:" "$HOOK_OUT"; then ok "ctx-ship-gate-absent-without-config"; else bad "ctx-ship-gate-absent-without-config" "out='$(grep -i 'ship gate' "$HOOK_OUT")'"; fi

# SOP sync line prints only when stale (P104): a fresh check is silent, an old one is named.
mkdir -p "$HOME/.claude"
printf '{ "last_update_check": "2026-01-01", "update_reminder": "weekly" }\n' > "$HOME/.claude/agent-sop.config.json"
SESSION_ID=ctx-stale run_hook "$CTX" "$SOP" ''
if grep -q "^SOP sync: .*stale" "$HOOK_OUT"; then ok "ctx-stale-sync-named"; else bad "ctx-stale-sync-named" "out='$(grep 'SOP sync' "$HOOK_OUT")'"; fi
printf '{ "last_update_check": "%s", "update_reminder": "weekly" }\n' "$(date +%Y-%m-%d)" > "$HOME/.claude/agent-sop.config.json"
SESSION_ID=ctx-fresh run_hook "$CTX" "$SOP" ''
if ! grep -q "^SOP sync:" "$HOOK_OUT"; then ok "ctx-fresh-sync-silent"; else bad "ctx-fresh-sync-silent" "out='$(grep 'SOP sync' "$HOOK_OUT")'"; fi
rm -f "$HOME/.claude/agent-sop.config.json"

# Legacy ship-sop directive is called out as superseded.
mkdir -p "$SOP/.ship" && echo "# stale" > "$SOP/.ship/.pending-auto-fire.md"
SESSION_ID=ctx-4 run_hook "$CTX" "$SOP" ''
if grep -qi "legacy ship-sop directive" "$HOOK_OUT"; then ok "ctx-legacy-directive-flagged"; else bad "ctx-legacy-directive-flagged" "out='$(cat "$HOOK_OUT")'"; fi

# ── Memory index (P113) ───────────────────────────────────────────────────────
# The limits are the harness's: the index loads its first 200 lines or 25,000
# bytes. The hook speaks from 80 per cent of either.

MEM="$TMP/claude/projects/-home/memory"
MEMSTATE="AGENT_SOP_STATE_DIR=$TMP/state-mem"

make_index "$MEM/MEMORY.md" 40 100
SESSION_ID=m1 run_hook "$MEMIDX" "$TMP" "$(write_json Write "$MEM/MEMORY.md")" "$MEMSTATE"
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ] && [ ! -s "$HOOK_OUT" ]; then ok "memory-index-silent-under-threshold"; else bad "memory-index-silent-under-threshold" "exit $HOOK_EXIT: $(cat "$HOOK_ERR")"; fi

# 100 entries of about 210 bytes: over 20,000 bytes, under 160 lines.
make_index "$MEM/MEMORY.md" 100 180
BYTES=$(wc -c < "$MEM/MEMORY.md" | tr -d ' ')
SESSION_ID=m2 run_hook "$MEMIDX" "$TMP" "$(write_json Edit "$MEM/MEMORY.md")" "$MEMSTATE"
if [ "$HOOK_EXIT" = 2 ] && grep -q "$BYTES of 25000 bytes" "$HOOK_ERR" && grep -q '100 of 200 lines' "$HOOK_ERR"; then ok "memory-index-reports-near-byte-limit"; else bad "memory-index-reports-near-byte-limit" "exit $HOOK_EXIT bytes $BYTES: $(cat "$HOOK_ERR")"; fi
if grep -q '100 lines over 200 bytes' "$HOOK_ERR" && [ "$(grep -cE '^  line [0-9]+ \([0-9]+ bytes\): - \[Entry' "$HOOK_ERR")" = 5 ]; then ok "memory-index-lists-long-lines"; else bad "memory-index-lists-long-lines" "$(cat "$HOOK_ERR")"; fi

# Same session, same size: said once, not again. A larger index is a new fact.
SESSION_ID=m2 run_hook "$MEMIDX" "$TMP" "$(write_json Edit "$MEM/MEMORY.md")" "$MEMSTATE"
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "memory-index-silent-when-size-unchanged"; else bad "memory-index-silent-when-size-unchanged" "exit $HOOK_EXIT: $(cat "$HOOK_ERR")"; fi
make_index "$MEM/MEMORY.md" 101 180
SESSION_ID=m2 run_hook "$MEMIDX" "$TMP" "$(write_json Edit "$MEM/MEMORY.md")" "$MEMSTATE"
if [ "$HOOK_EXIT" = 2 ] && grep -q '101 of 200 lines' "$HOOK_ERR"; then ok "memory-index-reports-again-when-larger"; else bad "memory-index-reports-again-when-larger" "exit $HOOK_EXIT: $(cat "$HOOK_ERR")"; fi

# 170 short entries: under 20,000 bytes, over 160 lines.
make_index "$MEM/MEMORY.md" 170 20
SESSION_ID=m3 run_hook "$MEMIDX" "$TMP" "$(write_json Write "$MEM/MEMORY.md")" "$MEMSTATE"
if [ "$HOOK_EXIT" = 2 ] && grep -q '170 of 200 lines' "$HOOK_ERR" && ! grep -q 'lines over 200 bytes' "$HOOK_ERR"; then ok "memory-index-reports-near-line-limit"; else bad "memory-index-reports-near-line-limit" "exit $HOOK_EXIT: $(cat "$HOOK_ERR")"; fi

# Only the index: a topic file beside it, an index outside a memory directory
# and a Bash call are all someone else's business.
make_index "$MEM/MEMORY.md" 100 180
make_index "$MEM/feedback_big.md" 100 180
make_index "$TMP/docs/MEMORY.md" 100 180
SESSION_ID='m4' run_hook "$MEMIDX" "$TMP" "$(write_json Write "$MEM/feedback_big.md")" "$MEMSTATE"; E1=$HOOK_EXIT
SESSION_ID='m4' run_hook "$MEMIDX" "$TMP" "$(write_json Write "$TMP/docs/MEMORY.md")" "$MEMSTATE"; E2=$HOOK_EXIT
SESSION_ID='m4' run_hook "$MEMIDX" "$TMP" "$(push_json "cat $MEM/MEMORY.md")" "$MEMSTATE"; E3=$HOOK_EXIT
SESSION_ID='m4' run_hook "$MEMIDX" "$TMP" "$(write_json Write "$TMP/none/memory/MEMORY.md")" "$MEMSTATE"; E4=$HOOK_EXIT
if [ "$E1$E2$E3$E4" = 0000 ]; then ok "memory-index-ignores-everything-but-the-index"; else bad "memory-index-ignores-everything-but-the-index" "exits $E1 $E2 $E3 $E4"; fi

# The thresholds are inclusive: 160 lines and 20,000 bytes report, one less does not.
make_index "$MEM/MEMORY.md" 159 20
SESSION_ID=m5 run_hook "$MEMIDX" "$TMP" "$(write_json Write "$MEM/MEMORY.md")" "$MEMSTATE"; B1=$HOOK_EXIT
make_index "$MEM/MEMORY.md" 160 20
SESSION_ID=m5 run_hook "$MEMIDX" "$TMP" "$(write_json Write "$MEM/MEMORY.md")" "$MEMSTATE"; B2=$HOOK_EXIT
head -c 19999 /dev/zero | tr '\0' 'x' > "$MEM/MEMORY.md"
SESSION_ID=m6 run_hook "$MEMIDX" "$TMP" "$(write_json Write "$MEM/MEMORY.md")" "$MEMSTATE"; B3=$HOOK_EXIT
head -c 20000 /dev/zero | tr '\0' 'x' > "$MEM/MEMORY.md"
SESSION_ID=m6 run_hook "$MEMIDX" "$TMP" "$(write_json Write "$MEM/MEMORY.md")" "$MEMSTATE"; B4=$HOOK_EXIT
if [ "$B1$B2$B3$B4" = 0202 ] && grep -q '20000 of 25000 bytes' "$HOOK_ERR" && grep -q '1 of 200 lines' "$HOOK_ERR"; then ok "memory-index-thresholds-are-inclusive"; else bad "memory-index-thresholds-are-inclusive" "exits $B1 $B2 $B3 $B4: $(cat "$HOOK_ERR")"; fi

# An empty index is silent; a path with spaces is read like any other.
: > "$MEM/MEMORY.md"
SESSION_ID=m7 run_hook "$MEMIDX" "$TMP" "$(write_json Write "$MEM/MEMORY.md")" "$MEMSTATE"; S1=$HOOK_EXIT
SPACED="$TMP/with space/memory/MEMORY.md"
make_index "$SPACED" 170 20
SESSION_ID=m7 run_hook "$MEMIDX" "$TMP" "$(write_json Write "$SPACED")" "$MEMSTATE"
if [ "$S1" = 0 ] && [ "$HOOK_EXIT" = 2 ] && grep -q '170 of 200 lines' "$HOOK_ERR"; then ok "memory-index-empty-file-and-spaced-path"; else bad "memory-index-empty-file-and-spaced-path" "exits $S1 $HOOK_EXIT: $(cat "$HOOK_ERR")"; fi

# MultiEdit reaches the hook: the script accepts it and the installer matches it.
make_index "$MEM/MEMORY.md" 170 20
SESSION_ID=m8 run_hook "$MEMIDX" "$TMP" "$(write_json MultiEdit "$MEM/MEMORY.md")" "$MEMSTATE"
if [ "$HOOK_EXIT" = 2 ]; then ok "memory-index-reports-on-multiedit"; else bad "memory-index-reports-on-multiedit" "exit $HOOK_EXIT"; fi

# An index that exists and cannot be read is said, never passed over (review finding, HIGH).
if [ "$(id -u)" != 0 ]; then
    chmod 000 "$MEM/MEMORY.md"
    SESSION_ID=m9 run_hook "$MEMIDX" "$TMP" "$(write_json Write "$MEM/MEMORY.md")" "$MEMSTATE"
    chmod 644 "$MEM/MEMORY.md"
    if [ "$HOOK_EXIT" = 2 ] && grep -q 'cannot read' "$HOOK_ERR"; then ok "memory-index-unreadable-is-reported"; else bad "memory-index-unreadable-is-reported" "exit $HOOK_EXIT: $(cat "$HOOK_ERR")"; fi
else
    ok "memory-index-unreadable-is-reported (skipped as root: every file is readable)"
fi

# No session id: nothing to key a marker on, so it reports each time and writes no marker.
NOSESS="$TMP/state-nosess"
printf '{"cwd":"%s","tool_name":"Write","tool_input":{"file_path":"%s"}}' "$TMP" "$MEM/MEMORY.md" > "$TMP/nosess.json"
AGENT_SOP_STATE_DIR="$NOSESS" bash "$MEMIDX" < "$TMP/nosess.json" >/dev/null 2>&1; N1=$?
AGENT_SOP_STATE_DIR="$NOSESS" bash "$MEMIDX" < "$TMP/nosess.json" >/dev/null 2>&1; N2=$?
if [ "$N1$N2" = 22 ] && [ -z "$(find "$NOSESS" -type f 2>/dev/null)" ]; then ok "memory-index-no-session-id-reports-each-time"; else bad "memory-index-no-session-id-reports-each-time" "exits $N1 $N2; files: $(find "$NOSESS" -type f 2>/dev/null)"; fi

# A session id is a directory name, never a path (review finding, MEDIUM).
ESCAPE="$TMP/state-escape"
SESSION_ID='../../escaped' run_hook "$MEMIDX" "$TMP" "$(write_json Write "$MEM/MEMORY.md")" "AGENT_SOP_STATE_DIR=$ESCAPE/a/b"
if [ "$HOOK_EXIT" = 2 ] && [ ! -e "$ESCAPE/escaped" ] && [ ! -e "$ESCAPE/a/escaped" ] && [ -n "$(find "$ESCAPE/a/b/sessions" -type f 2>/dev/null)" ]; then ok "memory-index-session-id-cannot-leave-state-dir"; else bad "memory-index-session-id-cannot-leave-state-dir" "exit $HOOK_EXIT; $(find "$ESCAPE" 2>/dev/null | tr '\n' ' ')"; fi

# A marker that is not two numbers suppresses nothing.
CORRUPT="$TMP/state-corrupt"
SESSION_ID=m10 run_hook "$MEMIDX" "$TMP" "$(write_json Write "$MEM/MEMORY.md")" "AGENT_SOP_STATE_DIR=$CORRUPT"
for m in "$CORRUPT"/sessions/m10/memory-index-*; do echo 'not numbers' > "$m"; done
SESSION_ID=m10 run_hook "$MEMIDX" "$TMP" "$(write_json Write "$MEM/MEMORY.md")" "AGENT_SOP_STATE_DIR=$CORRUPT"
if [ "$HOOK_EXIT" = 2 ]; then ok "memory-index-corrupt-marker-does-not-suppress"; else bad "memory-index-corrupt-marker-does-not-suppress" "exit $HOOK_EXIT: $(cat "$HOOK_ERR")"; fi

# A state directory that cannot be written is named in the report.
BLOCKED="$TMP/state-blocked"; : > "$BLOCKED"
SESSION_ID=m11 run_hook "$MEMIDX" "$TMP" "$(write_json Write "$MEM/MEMORY.md")" "AGENT_SOP_STATE_DIR=$BLOCKED"
if [ "$HOOK_EXIT" = 2 ] && grep -q 'will repeat' "$HOOK_ERR" && grep -q "$BLOCKED" "$HOOK_ERR"; then ok "memory-index-unwritable-state-is-named"; else bad "memory-index-unwritable-state-is-named" "exit $HOOK_EXIT: $(cat "$HOOK_ERR")"; fi

# Text echoed from the index carries no control bytes into the report.
make_index "$MEM/MEMORY.md" 100 180
printf -- '- [Bad\033[31m\007](x.md) - %0250d\n' 0 >> "$MEM/MEMORY.md"
SESSION_ID=m12 run_hook "$MEMIDX" "$TMP" "$(write_json Write "$MEM/MEMORY.md")" "$MEMSTATE"
if [ "$HOOK_EXIT" = 2 ] && grep -q 'line 101' "$HOOK_ERR" && ! LC_ALL=C grep -q "$(printf '[\033\007]')" "$HOOK_ERR"; then ok "memory-index-report-strips-control-bytes"; else bad "memory-index-report-strips-control-bytes" "exit $HOOK_EXIT"; fi

# Without jq the hook cannot read its input; it says so rather than going quiet.
NOJQ="$TMP/nojq-bin"; mkdir -p "$NOJQ"
for t in bash cat dirname awk wc tr sort head mkdir date shasum sha256sum cksum git sed grep; do
    src=$(command -v "$t" 2>/dev/null) && ln -sf "$src" "$NOJQ/$t"
done
printf '{"session_id":"m13","cwd":"%s","tool_name":"Write","tool_input":{"file_path":"%s"}}' "$TMP" "$MEM/MEMORY.md" > "$TMP/nojq.json"
NOJQ_ERR=$(PATH="$NOJQ" AGENT_SOP_STATE_DIR="$TMP/state-mem" "$NOJQ/bash" "$MEMIDX" < "$TMP/nojq.json" 2>&1 >/dev/null); NOJQ_EXIT=$?
if [ "$NOJQ_EXIT" = 1 ] && printf '%s' "$NOJQ_ERR" | grep -q 'jq'; then ok "memory-index-says-when-jq-is-missing"; else bad "memory-index-says-when-jq-is-missing" "exit $NOJQ_EXIT: $NOJQ_ERR"; fi

# Run by hand it always reports, and never fails the caller.
make_index "$MEM/MEMORY.md" 40 100
MANUAL=$(bash "$MEMIDX" --file "$MEM/MEMORY.md" 2>&1); MEXIT=$?
if [ "$MEXIT" = 0 ] && printf '%s' "$MANUAL" | grep -q '40 of 200 lines'; then ok "memory-index-manual-report"; else bad "memory-index-manual-report" "exit $MEXIT: $MANUAL"; fi

# ── Installer ─────────────────────────────────────────────────────────────────

SETTINGS="$TMP/settings.json"
cat > "$SETTINGS" <<'JSON'
{ "model": "x",
  "hooks": {
    "Stop": [ { "matcher": "*", "hooks": [ { "type": "command", "command": "node existing-stop.js" } ] } ],
    "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "node existing-pre.js" } ] } ]
  } }
JSON
DEST="$TMP/dest"
bash "$INSTALLER" --settings "$SETTINGS" --dest "$DEST" >/dev/null 2>"$TMP/inst-err"; INST1=$?
bash "$INSTALLER" --settings "$SETTINGS" --dest "$DEST" >/dev/null 2>>"$TMP/inst-err"; INST2=$?
count() { jq "[.hooks.$1[]?.hooks[]?.command | select(test(\"$2\"))] | length" "$SETTINGS"; }
if [ "$INST1" = 0 ] && [ "$INST2" = 0 ] \
   && [ "$(count Stop 'sop-stop-drift')" = 1 ] \
   && [ "$(count SessionStart 'sop-session-context')" = 1 ] \
   && [ "$(count UserPromptSubmit 'sop-session-context')" = 1 ] \
   && [ "$(count PreToolUse 'sop-push-gate')" = 1 ] \
   && [ "$(count PostToolUse 'sop-memory-index')" = 1 ] \
   && [ "$(jq -r '[.hooks.PostToolUse[]? | select(any(.hooks[]?; (.command // "") | test("sop-memory-index"))) | .matcher] | join(",")' "$SETTINGS")" = 'Write|Edit|MultiEdit' ] \
   && [ -x "$DEST/sop-memory-index.sh" ] \
   && [ "$(count Stop 'existing-stop')" = 1 ] \
   && [ "$(count PreToolUse 'existing-pre')" = 1 ] \
   && [ "$(jq -r .model "$SETTINGS")" = x ] \
   && [ -x "$DEST/sop-stop-drift.sh" ] \
   && [ -x "$DEST/sop-project-type.sh" ] \
   && ls "$SETTINGS".bak-* >/dev/null 2>&1; then
    ok "installer-idempotent-and-preserving"
else
    bad "installer-idempotent-and-preserving" "exits $INST1/$INST2; stop=$(count Stop 'sop-stop-drift') ss=$(count SessionStart 'sop-session-context') ups=$(count UserPromptSubmit 'sop-session-context') pre=$(count PreToolUse 'sop-push-gate') keep=$(count Stop 'existing-stop')/$(count PreToolUse 'existing-pre'); err='$(cat "$TMP/inst-err")'"
fi

# Upgrading an install that predates sop-project-type.sh copies it in (review finding, P102).
OLDDEST="$TMP/olddest"; mkdir -p "$OLDDEST"
for f in sop-lib.sh sop-session-context.sh sop-stop-drift.sh sop-push-gate.sh; do echo "# old" > "$OLDDEST/$f"; done
echo '{}' > "$TMP/settings-upgrade.json"
bash "$INSTALLER" --settings "$TMP/settings-upgrade.json" --dest "$OLDDEST" >/dev/null 2>&1
if [ -x "$OLDDEST/sop-project-type.sh" ] && ! grep -q '^# old$' "$OLDDEST/sop-lib.sh"; then ok "installer-upgrade-adds-project-type-script"; else bad "installer-upgrade-adds-project-type-script" "$(ls "$OLDDEST")"; fi

# A user's unrelated hook that merely shares a filename must survive uninstall (review finding, LOW).
jq '.hooks.Stop += [ { "matcher": "*", "hooks": [ { "type": "command", "command": "node /other-tool/sop-stop-drift.sh" } ] } ]' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
bash "$INSTALLER" --settings "$SETTINGS" --dest "$DEST" --uninstall >/dev/null 2>&1
if [ "$(count Stop "bash .$DEST/sop-stop-drift")" = 0 ] && [ "$(count Stop 'existing-stop')" = 1 ] && [ "$(count Stop 'other-tool/sop-stop-drift')" = 1 ] && [ "$(count PreToolUse 'sop-push-gate')" = 0 ] && [ "$(count PostToolUse 'sop-memory-index')" = 0 ] && [ "$(jq '.hooks.UserPromptSubmit // [] | length' "$SETTINGS")" = 0 ]; then
    ok "installer-uninstall-removes-only-ours"
else
    bad "installer-uninstall-removes-only-ours" "$(jq -c .hooks "$SETTINGS")"
fi

# A symlinked settings.json keeps its link; the target receives the write (review finding, MEDIUM).
REAL="$TMP/dotfiles/settings.json"; LINK="$TMP/home2/settings.json"
mkdir -p "$TMP/dotfiles" "$TMP/home2" && echo '{ "model": "y" }' > "$REAL" && ln -s ../dotfiles/settings.json "$LINK"
bash "$INSTALLER" --settings "$LINK" --dest "$TMP/dest2" >/dev/null 2>&1
if [ -L "$LINK" ] && [ "$(jq '[.hooks.Stop[]?.hooks[]?.command | select(test("sop-stop-drift"))] | length' "$REAL")" = 1 ] && [ "$(jq -r .model "$REAL")" = y ]; then
    ok "installer-preserves-symlinked-settings"
else
    bad "installer-preserves-symlinked-settings" "link=$([ -L "$LINK" ] && echo yes || echo no) real=$(jq -c '.hooks // {} | keys' "$REAL" 2>/dev/null)"
fi

# --dry-run writes nothing: no settings file, no settings directory, no scripts (independent review, P118).
DRYSET="$TMP/dry-home/settings.json"; DRYDEST="$TMP/dry-dest"
bash "$INSTALLER" --settings "$DRYSET" --dest "$DRYDEST" --dry-run > "$TMP/dry-out" 2>&1; DRY=$?
if [ "$DRY" = 0 ] && [ ! -e "$TMP/dry-home" ] && [ ! -e "$DRYDEST" ] \
   && [ "$(jq '[.hooks.Stop[]?.hooks[]?.command | select(test("sop-stop-drift"))] | length' "$TMP/dry-out")" = 1 ]; then
    ok "installer-dry-run-writes-nothing"
else
    bad "installer-dry-run-writes-nothing" "exit=$DRY home=$([ -e "$TMP/dry-home" ] && echo created || echo absent) dest=$([ -e "$DRYDEST" ] && echo created || echo absent) out='$(head -3 "$TMP/dry-out")'"
fi

# Dry-run leaves an existing settings file byte-identical (review finding, P118).
DRYEX="$TMP/dry-existing.json"; printf '{ "model": "z" }\n' > "$DRYEX"; cp "$DRYEX" "$TMP/dry-existing.orig"
bash "$INSTALLER" --settings "$DRYEX" --dest "$TMP/dry-dest2" --dry-run >/dev/null 2>&1
if cmp -s "$DRYEX" "$TMP/dry-existing.orig" && ! ls "$DRYEX".bak-* >/dev/null 2>&1 && [ ! -e "$TMP/dry-dest2" ]; then ok "installer-dry-run-keeps-existing-settings"; else bad "installer-dry-run-keeps-existing-settings" "$(cat "$DRYEX")"; fi

# A settings path that is a directory is refused, not reported as registered (review finding, P118).
mkdir -p "$TMP/settings-dir.json"
if bash "$INSTALLER" --settings "$TMP/settings-dir.json" --dest "$TMP/dest-dir" >/dev/null 2>"$TMP/dir-err"; then
    bad "installer-refuses-directory-settings" "exit 0; contents: $(ls "$TMP/settings-dir.json")"
elif grep -q 'not a regular file' "$TMP/dir-err" && [ -z "$(ls -A "$TMP/settings-dir.json")" ]; then ok "installer-refuses-directory-settings"
else bad "installer-refuses-directory-settings" "$(cat "$TMP/dir-err")"; fi

# An empty settings file is treated as {} and registers the hooks (review finding, P118).
: > "$TMP/settings-empty.json"
bash "$INSTALLER" --settings "$TMP/settings-empty.json" --dest "$TMP/dest-empty" >/dev/null 2>&1; EMPTY=$?
if [ "$EMPTY" = 0 ] && [ "$(jq '[.hooks.Stop[]?.hooks[]?.command | select(test("sop-stop-drift"))] | length' "$TMP/settings-empty.json" 2>/dev/null)" = 1 ]; then ok "installer-empty-settings-registers"; else bad "installer-empty-settings-registers" "exit=$EMPTY size=$(wc -c < "$TMP/settings-empty.json")"; fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "hook-fixtures: $pass passed, $fail failed"
[ "$fail" -gt 0 ] && echo "Failed:$failed" && exit 1
exit 0
