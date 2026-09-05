#!/usr/bin/env bash
#
# Test harness for `scripts/resolve-resume-path.sh`.
#
# The resolver is a pure function of (repo root, HOME, agent-id), so fixtures
# are built in a temp directory via --root/--home overrides rather than stored
# as files. Cases are table-driven; the reporting contract matches the other
# suites (PASS/FAIL per case, summary line, exit 1 on any failure).
#
# RESOLVER is overridable so the suite can be pointed at a deliberately broken
# resolver to prove the cases actually discriminate — a suite that passes
# against a stub is not testing anything. Matches drift-fixtures/run-tests.sh:19.
#
# Run from repo root: bash docs/benchmark/resume-path-fixtures/run-tests.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RESOLVER="${RESOLVER:-$REPO_ROOT/scripts/resolve-resume-path.sh}"

if [ ! -f "$RESOLVER" ]; then
    echo "Resolver not found: $RESOLVER" >&2
    exit 2
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

FAKE_HOME="$TMP/home"
PROJ_A="$TMP/home/Projects/alpha"
PROJ_B="$TMP/home/Projects/beta"
mkdir -p "$FAKE_HOME" "$PROJ_A" "$PROJ_B"

# Both fixtures are real single-worktree repositories, not bare directories.
# Production only ever passes a root that came from `git rev-parse
# --show-toplevel`, and agent-id resolution counts worktrees — so a plain
# directory would exercise the undetermined-count path and report a hash where
# a real single-worktree project reports `solo`. Testing against a shape
# production cannot produce is how a suite passes while the rule is wrong.
for repo in "$PROJ_A" "$PROJ_B"; do
    (
        cd "$repo" || exit 1
        git init -q . 2>/dev/null
        git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init 2>/dev/null
    )
done

MEM_A="$FAKE_HOME/.claude/projects/-$TMP-home-Projects-alpha/memory"
MEM_A=$(printf '%s' "$PROJ_A" | sed 's|[^a-zA-Z0-9-]|-|g' | sed 's|--*|-|g' | sed 's|^-||')
MEM_A="$FAKE_HOME/.claude/projects/-$MEM_A/memory"
MEM_B=$(printf '%s' "$PROJ_B" | sed 's|[^a-zA-Z0-9-]|-|g' | sed 's|--*|-|g' | sed 's|^-||')
MEM_B="$FAKE_HOME/.claude/projects/-$MEM_B/memory"
mkdir -p "$MEM_A" "$MEM_B"

pass=0
fail=0
failed=""

# run <name> <expected-exit> <expected-stdout-or-empty> -- <resolver args...>
run() {
    local name="$1" want_exit="$2" want_out="$3"
    shift 4  # name, exit, out, and the literal --
    local out actual
    out=$(env -u CLAUDE_AGENT_ID bash "$RESOLVER" --home "$FAKE_HOME" "$@" 2>/dev/null)
    actual=$?

    if [ "$actual" != "$want_exit" ]; then
        echo "FAIL: $name — expected exit $want_exit, got $actual"
        echo "  output: $out"
        fail=$((fail + 1)); failed="$failed $name"; return
    fi
    if [ -n "$want_out" ] && [ "$out" != "$want_out" ]; then
        echo "FAIL: $name — exit correct, but path mismatch"
        echo "  expected: $want_out"
        echo "  actual:   $out"
        fail=$((fail + 1)); failed="$failed $name"; return
    fi
    echo "PASS: $name (exit $actual)"
    pass=$((pass + 1))
}

# --- Write target is project-scoped, per-agent, and independent of session cwd.
run "write-target-is-project-scoped" 0 "$MEM_A/project_resume_solo.md" -- --root "$PROJ_A"

# The regression P96 fixes: two single-worktree projects both resolve agent-id
# `solo`, so only the directory keeps their resume files apart. If the write
# target ever stops depending on the repo root, these two collapse onto one path.
run "sibling-project-write-target-differs" 0 "$MEM_B/project_resume_solo.md" -- --root "$PROJ_B"

# --- Trailing slash must not produce a second, different directory.
run "trailing-slash-normalised" 0 "$MEM_A/project_resume_solo.md" -- --root "$PROJ_A/"

# --- Directory and agent-id accessors.
run "dir-accessor" 0 "$MEM_A" -- --root "$PROJ_A" --dir
run "agent-id-defaults-to-solo" 0 "solo" -- --root "$PROJ_A" --agent-id

# --- Refusals.
run "home-root-refused" 2 "" -- --root "$FAKE_HOME"

# No --root override and a cwd outside any git repo: the resolver must refuse
# rather than guess a directory. Run from a temp dir, which is not under any
# working tree, so `git rev-parse --show-toplevel` genuinely fails.
mkdir -p "$TMP/notarepo"
out=$(cd "$TMP/notarepo" && env -u CLAUDE_AGENT_ID bash "$RESOLVER" --home "$FAKE_HOME" 2>/dev/null)
actual=$?
if [ "$actual" = "1" ] && [ -z "$out" ]; then
    echo "PASS: non-repo-refused (exit 1)"; pass=$((pass + 1))
else
    echo "FAIL: non-repo-refused — expected exit 1 and empty stdout, got exit $actual / '$out'"
    fail=$((fail + 1)); failed="$failed non-repo-refused"
fi

# --- Read target: absent, per-agent, legacy fallback, and precedence.
run "read-none-present-exits-1" 1 "" -- --root "$PROJ_A" --read

printf '# legacy\n' > "$MEM_A/project_resume.md"
run "read-falls-back-to-legacy" 0 "$MEM_A/project_resume.md" -- --root "$PROJ_A" --read

# A legacy file that /update-sop marked superseded is not a resume (cost
# audit 2026-09-05 saw one served); the match is anchored to the marker, so a
# first line that merely contains the word still resolves.
printf '**SUPERSEDED - 2026-08-07.** Use the per-agent file.\n' > "$MEM_A/project_resume.md"
run "read-skips-superseded-legacy" 1 "" -- --root "$PROJ_A" --read
printf '# Resume (the old plan was superseded in April)\n' > "$MEM_A/project_resume.md"
run "read-serves-legacy-mentioning-superseded-in-prose" 0 "$MEM_A/project_resume.md" -- --root "$PROJ_A" --read
printf '\n**SUPERSEDED - 2026-08-07.** Use the per-agent file.\n' > "$MEM_A/project_resume.md"
run "read-skips-superseded-after-leading-blank-line" 1 "" -- --root "$PROJ_A" --read
printf '**SUPERSEDED - 2026-08-07.**\r\nUse the per-agent file.\r\n' > "$MEM_A/project_resume.md"
run "read-skips-superseded-crlf" 1 "" -- --root "$PROJ_A" --read
printf '\xEF\xBB\xBF**SUPERSEDED - 2026-08-07.**\n' > "$MEM_A/project_resume.md"
run "read-skips-superseded-with-bom" 1 "" -- --root "$PROJ_A" --read
printf '# legacy\n' > "$MEM_A/project_resume.md"

printf '# per-agent\n' > "$MEM_A/project_resume_solo.md"
run "read-prefers-per-agent" 0 "$MEM_A/project_resume_solo.md" -- --root "$PROJ_A" --read

# The legacy fallback must stay inside this project's directory. Project B has
# no resume file of its own; before P96 an agent could land on A's file.
run "legacy-fallback-does-not-cross-projects" 1 "" -- --root "$PROJ_B" --read

# --- Agent-id overrides.
out=$(CLAUDE_AGENT_ID=worker2 bash "$RESOLVER" --home "$FAKE_HOME" --root "$PROJ_A" 2>/dev/null)
if [ "$out" = "$MEM_A/project_resume_worker2.md" ]; then
    echo "PASS: env-agent-id-override (exit 0)"; pass=$((pass + 1))
else
    echo "FAIL: env-agent-id-override — got $out"; fail=$((fail + 1)); failed="$failed env-agent-id-override"
fi

printf 'worker3\n' > "$PROJ_A/.sop-agent-id"
run "sop-agent-id-file-override" 0 "$MEM_A/project_resume_worker3.md" -- --root "$PROJ_A"
rm -f "$PROJ_A/.sop-agent-id"

# --- Hash-derived agent-id branch (real git repo with a second worktree).
#
# This branch is what keeps parallel agents from colliding, and nothing else in
# the repo exercises it. It needs a real repository: the count comes from
# `git worktree list`, so --root against a plain directory cannot reach it.
# Skipped rather than failed where git is unavailable, so the suite stays
# runnable in minimal environments.
if command -v git >/dev/null 2>&1; then
    REPO="$TMP/home/Projects/multi"
    mkdir -p "$REPO"
    (
        cd "$REPO" || exit 1
        git init -q . 2>/dev/null
        git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init 2>/dev/null
        git worktree add -q -b sibling "$TMP/home/Projects/multi-sibling" 2>/dev/null
    )

    if [ -d "$TMP/home/Projects/multi-sibling" ]; then
        expected_hash=$(printf '%s' "$REPO" | { shasum -a 256 2>/dev/null || sha256sum; } | cut -c1-6)
        got=$(env -u CLAUDE_AGENT_ID bash "$RESOLVER" --home "$FAKE_HOME" --root "$REPO" --agent-id 2>/dev/null)
        if [ "$got" = "$expected_hash" ]; then
            echo "PASS: multi-worktree-agent-id-is-path-hash (exit 0)"; pass=$((pass + 1))
        else
            echo "FAIL: multi-worktree-agent-id-is-path-hash — expected $expected_hash, got $got"
            fail=$((fail + 1)); failed="$failed multi-worktree-agent-id-is-path-hash"
        fi

        # Two worktrees of one repo are different agents AND different projects:
        # each has its own root, so each gets its own directory and its own id.
        sib_id=$(env -u CLAUDE_AGENT_ID bash "$RESOLVER" --home "$FAKE_HOME" --root "$TMP/home/Projects/multi-sibling" --agent-id 2>/dev/null)
        if [ -n "$sib_id" ] && [ "$sib_id" != "$got" ] && [ "$sib_id" != "solo" ]; then
            echo "PASS: sibling-worktree-gets-distinct-agent-id (exit 0)"; pass=$((pass + 1))
        else
            echo "FAIL: sibling-worktree-gets-distinct-agent-id — main=$got sibling=$sib_id"
            fail=$((fail + 1)); failed="$failed sibling-worktree-gets-distinct-agent-id"
        fi
    else
        echo "SKIP: multi-worktree cases — could not create a worktree in this environment"
    fi
else
    echo "SKIP: multi-worktree cases — git not available"
fi

echo ""
echo "Results: $pass passed, $fail failed"
[ "$fail" -gt 0 ] && echo "Failed:$failed" && exit 1
exit 0
