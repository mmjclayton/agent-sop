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

for f in "$CTX" "$STOP" "$PUSH" "$PTYPE" "$INSTALLER"; do
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
if grep -q "Read the Backlog.md item for the task" "$HOOK_OUT" && ! grep -q "enforces nothing here" "$HOOK_OUT"; then ok "ctx-code-closing-line"; else bad "ctx-code-closing-line" "out='$(tail -2 "$HOOK_OUT")'"; fi
# A legacy project_resume.md that says SUPERSEDED on its first line is not
# served as the resume snapshot (cost audit, 2026-09-05).
SUPER="$TMP/super"; make_repo "$SUPER" with-code
SUPER_DIR=$(dirname "$(bash "$SUPER/scripts/resolve-resume-path.sh" --root "$(git -C "$SUPER" rev-parse --show-toplevel)" --home "$HOME")")
mkdir -p "$SUPER_DIR" && printf '**SUPERSEDED - 2026-08-07.** Use the per-agent file.\n\n## What is next\n- stale\n' > "$SUPER_DIR/project_resume.md"
SESSION_ID=ctx-super run_hook "$CTX" "$SUPER" ''
if grep -q "^Resume snapshot: (none found" "$HOOK_OUT" && ! grep -q "SUPERSEDED" "$HOOK_OUT"; then ok "ctx-superseded-legacy-resume-not-served"; else bad "ctx-superseded-legacy-resume-not-served" "out='$(grep -A1 'Resume snapshot' "$HOOK_OUT" | head -2)'"; fi

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
