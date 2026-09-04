#!/usr/bin/env bash
#
# Test harness for the user-scope hook scripts under `scripts/hooks/`:
#
#   sop-session-context.sh   SessionStart + UserPromptSubmit — prints context once per (session, repo)
#   sop-stop-drift.sh        Stop — exit 2 with a reason only when a deterministic drift fact holds
#   sop-push-gate.sh         PreToolUse(Bash) — refuses `git push` / `gh pr create` when ship-sop
#                            auto-mode is on and no gate report covers HEAD
#   ../install-hooks.sh      registers the three in a settings.json idempotently
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

for f in "$CTX" "$STOP" "$PUSH" "$INSTALLER"; do
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

# make_repo <dir> [with-sop]
# Creates a bare origin at <dir>.git, clones it to <dir>, makes an initial
# commit on main and pushes so origin/main exists. With "with-sop", installs
# the minimal SOP file set the hooks key on, plus the repo's own resolver so
# agent-id / resume paths follow production rules.
make_repo() {
    local dir="$1" sop="${2:-}"
    $GIT init -q --bare -b main "$dir.git"
    $GIT clone -q "$dir.git" "$dir" 2>/dev/null
    (
        cd "$dir" || exit 1
        echo "# app" > README.md
        if [ "$sop" = "with-sop" ]; then
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

# ── Stop hook ─────────────────────────────────────────────────────────────────

NOTREPO="$TMP/notrepo"; mkdir -p "$NOTREPO"
run_hook "$STOP" "$NOTREPO" ''
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "stop-not-a-repo-silent"; else bad "stop-not-a-repo-silent" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi

PLAIN="$TMP/plain"; make_repo "$PLAIN"
commit_code "$PLAIN" "feat: something"
run_hook "$STOP" "$PLAIN" ''
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "stop-repo-without-sop-silent"; else bad "stop-repo-without-sop-silent" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi

SOP="$TMP/sop"; make_repo "$SOP" with-sop
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
SHIP="$TMP/ship"; make_repo "$SHIP" with-sop
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
(cd "$SHIP" && $GIT add -A >/dev/null && $GIT commit -q -m "docs: ship report")
run_hook "$STOP" "$SHIP" ''
# The report commit is itself a commit after the last session record — so the
# hook may legitimately fire for that — but it must no longer demand the gates.
if ! grep -q "@security-reviewer" "$HOOK_ERR"; then ok "stop-shipsop-gate-satisfied-by-covering-report"; else bad "stop-shipsop-gate-satisfied-by-covering-report" "stderr='$(cat "$HOOK_ERR")'"; fi

DOCS="$TMP/docsonly"; make_repo "$DOCS" with-sop
cp "$SHIP/ship-sop.config.json" "$DOCS/"
(cd "$DOCS" && $GIT add -A >/dev/null && $GIT commit -q -m "chore: config" && $GIT push -q origin main 2>/dev/null)
git -C "$DOCS" checkout -q -b feat/docs
(cd "$DOCS" && for i in $(seq 1 20); do echo "para $i" >> notes.md; done && $GIT add -A >/dev/null && $GIT commit -q -m "docs: notes")
commit_record "$DOCS" "recorded"
run_hook "$STOP" "$DOCS" ''
if ! grep -q "@security-reviewer" "$HOOK_ERR"; then ok "stop-shipsop-docs-only-no-gate"; else bad "stop-shipsop-docs-only-no-gate" "stderr='$(cat "$HOOK_ERR")'"; fi

# ── Push gate ─────────────────────────────────────────────────────────────────

push_json() { printf ',"tool_name":"Bash","tool_input":{"command":"%s"}' "$1"; }

run_hook "$PUSH" "$SOP" "$(push_json 'ls -la')"
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "push-non-push-command-silent"; else bad "push-non-push-command-silent" "exit $HOOK_EXIT"; fi

run_hook "$PUSH" "$SOP" "$(push_json 'git push origin main')"
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "push-no-shipsop-allowed"; else bad "push-no-shipsop-allowed" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi

GATED="$TMP/gated"; make_repo "$GATED" with-sop
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
run_hook "$PUSH" "$GATED" "$(push_json "git commit -m 'then git push'")"
if [ "$HOOK_EXIT" = 0 ] && [ ! -s "$HOOK_ERR" ]; then ok "push-verb-in-commit-message-silent"; else bad "push-verb-in-commit-message-silent" "exit $HOOK_EXIT stderr='$(cat "$HOOK_ERR")'"; fi

printf '# report\n\nCovers: %s\n' "$(head_of "$GATED")" > "$GATED/docs/reviews/20260904-110000-ship-auto.md"
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

# Legacy ship-sop directive is called out as superseded.
mkdir -p "$SOP/.ship" && echo "# stale" > "$SOP/.ship/.pending-auto-fire.md"
SESSION_ID=ctx-4 run_hook "$CTX" "$SOP" ''
if grep -qi "legacy ship-sop directive" "$HOOK_OUT"; then ok "ctx-legacy-directive-flagged"; else bad "ctx-legacy-directive-flagged" "out='$(cat "$HOOK_OUT")'"; fi

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
   && [ "$(count Stop 'existing-stop')" = 1 ] \
   && [ "$(count PreToolUse 'existing-pre')" = 1 ] \
   && [ "$(jq -r .model "$SETTINGS")" = x ] \
   && [ -x "$DEST/sop-stop-drift.sh" ] \
   && ls "$SETTINGS".bak-* >/dev/null 2>&1; then
    ok "installer-idempotent-and-preserving"
else
    bad "installer-idempotent-and-preserving" "exits $INST1/$INST2; stop=$(count Stop 'sop-stop-drift') ss=$(count SessionStart 'sop-session-context') ups=$(count UserPromptSubmit 'sop-session-context') pre=$(count PreToolUse 'sop-push-gate') keep=$(count Stop 'existing-stop')/$(count PreToolUse 'existing-pre'); err='$(cat "$TMP/inst-err")'"
fi

# A user's unrelated hook that merely shares a filename must survive uninstall (review finding, LOW).
jq '.hooks.Stop += [ { "matcher": "*", "hooks": [ { "type": "command", "command": "node /other-tool/sop-stop-drift.sh" } ] } ]' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
bash "$INSTALLER" --settings "$SETTINGS" --dest "$DEST" --uninstall >/dev/null 2>&1
if [ "$(count Stop "bash .$DEST/sop-stop-drift")" = 0 ] && [ "$(count Stop 'existing-stop')" = 1 ] && [ "$(count Stop 'other-tool/sop-stop-drift')" = 1 ] && [ "$(count PreToolUse 'sop-push-gate')" = 0 ] && [ "$(jq '.hooks.UserPromptSubmit // [] | length' "$SETTINGS")" = 0 ]; then
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

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "hook-fixtures: $pass passed, $fail failed"
[ "$fail" -gt 0 ] && echo "Failed:$failed" && exit 1
exit 0
