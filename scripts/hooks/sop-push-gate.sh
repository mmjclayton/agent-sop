#!/usr/bin/env bash
#
# agent-sop PreToolUse(Bash) hook — the one gate that can actually refuse.
#
# Refuses `git push` and `gh pr create` (exit 2, reason on stderr) when all of:
#   - the repo under `cwd` carries the SOP file set
#   - ship-sop.config.json has trigger.mode "auto"
#   - the code diff vs the default branch is at or over min_diff_lines
#   - no docs/reviews/*-ship-auto.md names HEAD
#
# That is ship-sop P20's design: gate on "no gate run covers HEAD", a fact a
# script can check, rather than on "are there findings", a model judgement.
#
# Session-record drift is deliberately NOT push-gated. Pushing early is the
# protection against sibling-worktree wipes; the Stop hook handles records.
#
# Bypass: prefix the command with SOP_SKIP_GATE=1. Every bypass is appended
# to .ship/bypass.log with the HEAD it skipped, so it is greppable later.

set -u
. "$(dirname "${BASH_SOURCE[0]}")/sop-lib.sh"

sop_have_jq || exit 0
sop_read_input

[ "$(sop_field '.tool_name')" = "Bash" ] || exit 0
CMD=$(sop_field '.tool_input.command')
[ -n "$CMD" ] || exit 0

# Match a push or PR-create that would actually execute: as a simple command
# (start, after a separator, after a leading VAR=val assignment), inside the
# quoted body of a `bash -c` / `sh -c` / `eval` wrapper, but not inside prose
# quoted as an argument. Rule lives in sop-lib.sh so the fixture suite and
# any future consumer test the same implementation.
sop_is_push_command "$CMD" || exit 0

CWD=$(sop_field '.cwd')
[ -n "$CWD" ] || CWD="$PWD"
ROOT=$(sop_repo_root "$CWD")
sop_is_sop_repo "$ROOT" || exit 0

HEAD=$(git -C "$ROOT" rev-parse HEAD 2>/dev/null) || exit 0

if printf '%s' "$CMD" | grep -q 'SOP_SKIP_GATE=1'; then
    mkdir -p "$ROOT/.ship" 2>/dev/null
    printf '%s %s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$HEAD" "$CMD" >> "$ROOT/.ship/bypass.log" 2>/dev/null
    exit 0
fi

GATE=$(sop_shipsop_gate "$ROOT")
[ -n "$GATE" ] || exit 0

{
    printf '[agent-sop] push refused — %s\n' "$GATE"
    printf 'Write that report, then push again. To bypass once (recorded in .ship/bypass.log): SOP_SKIP_GATE=1 %s\n' "$CMD"
} >&2

exit 2
