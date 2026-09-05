#!/usr/bin/env bash
#
# agent-sop Stop hook — session-end drift, enforced by a fact a script can check.
#
# Fires (exit 2, reason on stderr — Claude Code feeds stderr back to the model
# and continues the turn) only when at least one of these holds for the repo
# under the hook's `cwd`:
#
#   1. commits exist after the newest commit touching docs/recent-work/
#      (or any commits at all when no session record has ever been written)
#   2. tracker files are modified and uncommitted
#   3. ship-sop auto-mode applies and no gate report names HEAD
#
# Everything else is exit 0 with no output. The notice is throttled to once
# per (HEAD, dirty-tracker set, gate state): it does not repeat until the
# facts change, so a session that ignores it pays one extra turn per commit
# state, never a loop.
#
# Code projects only (P102 for the gate, P103 for the drift half): the
# operator's rule is that agent-sop must not slow down prose projects, so a
# non-code repository with SOP scaffolding gets no Stop notice at all and
# /update-sop stays its deliberate close. The context block still shows the
# drift facts there; it is read once and demands nothing. Note the
# compounding: sop_project_type fails open to "non-code", so an environment
# that cannot classify (no jq, unreadable CLAUDE.md) silences this hook and
# the ship gate together — one rule, one failure mode.
#
# This replaces the need to type /update-sop for the minimum record. The full
# checklist remains available and is still what a deliberate session end runs.
#
# Wiring: registered user-scope by scripts/install-hooks.sh. Hook input JSON
# on stdin; `stop_hook_active` is honoured as a belt-and-braces loop guard.

set -u
. "$(dirname "${BASH_SOURCE[0]}")/sop-lib.sh"

sop_have_jq || exit 0
sop_read_input

[ "$(sop_field '.stop_hook_active')" = "true" ] && exit 0

CWD=$(sop_field '.cwd')
[ -n "$CWD" ] || CWD="$PWD"
ROOT=$(sop_repo_root "$CWD")
sop_is_sop_repo "$ROOT" || exit 0
sop_is_code_repo "$ROOT" || exit 0

HEAD=$(git -C "$ROOT" rev-parse HEAD 2>/dev/null) || exit 0
[ -n "$HEAD" ] || exit 0

DRIFT=$(sop_drift_commits "$ROOT")
DIRTY=$(sop_tracker_dirty "$ROOT")
GATE=$(sop_shipsop_gate "$ROOT")

[ -n "$DRIFT$DIRTY$GATE" ] || exit 0

# ── Throttle ──────────────────────────────────────────────────────────────────
# The in-flight file is left out of the signature: adding a line there is the
# "work is still in progress" path this notice itself prescribes, and on the
# first live P103 run that edit re-fired the notice as a new dirty set. The
# fact still prints; it just does not count as a new state.
GATE_FLAG="nogate"; [ -n "$GATE" ] && GATE_FLAG="gate"
DIRTY_SIG=$(printf '%s\n' "$DIRTY" | grep -v -e '^docs/agent-memory/in-flight/' -e '^$' | sop_sha256)
SIG=$(printf '%s|%s|%s' "$HEAD" "$DIRTY_SIG" "$GATE_FLAG")
MARKER_DIR="$(sop_state_dir)/repos/$(sop_repo_key "$ROOT")"
MARKER="$MARKER_DIR/stop.marker"
if [ -f "$MARKER" ] && [ "$(cat "$MARKER" 2>/dev/null)" = "$SIG" ]; then
    exit 0
fi
mkdir -p "$MARKER_DIR" 2>/dev/null && printf '%s' "$SIG" > "$MARKER" 2>/dev/null

# ── Compose the reason ────────────────────────────────────────────────────────
NAME=$(basename "$ROOT")
BRANCH=$(git -C "$ROOT" branch --show-current 2>/dev/null)
AGENT=$(sop_agent_id "$ROOT")
LAST=$(sop_last_record_commit "$ROOT")
LAST_LABEL="the start of history"
[ -n "$LAST" ] && LAST_LABEL="the last session record ($(printf '%s' "$LAST" | cut -c1-7))"

{
    printf '[agent-sop] Session-end drift in %s (branch %s, agent-id %s):\n' "$NAME" "${BRANCH:-detached}" "$AGENT"
    if [ -n "$DRIFT" ]; then
        n=$(printf '%s\n' "$DRIFT" | grep -c .)
        printf -- '- %s commit(s) with no session record in docs/recent-work/ since %s:\n' "$n" "$LAST_LABEL"
        printf '%s\n' "$DRIFT" | head -5 | sed 's/^/    /'
        [ "$n" -gt 5 ] && printf '    ... and %s more\n' "$((n - 5))"
    fi
    if [ -n "$DIRTY" ]; then
        printf -- '- Uncommitted tracker files: %s\n' "$(printf '%s\n' "$DIRTY" | tr '\n' ' ')"
    fi
    if [ -n "$GATE" ]; then
        printf -- '- %s\n' "$GATE"
    fi
    printf 'If this piece of work is complete: do the minimum session-end now — update Backlog.md status tags, write docs/recent-work/%s_%s_<slug>.md, overwrite the resume snapshot at the path `bash scripts/resolve-resume-path.sh` prints, then commit docs/ with the work. Run /update-sop instead when this is the deliberate end of the session.\n' "$(date +%Y-%m-%d)" "$AGENT"
    printf 'If work is still in progress: add one line to docs/agent-memory/in-flight/%s.md and refresh the resume snapshot, then carry on. This notice fires once per commit state and will not repeat until the facts above change.\n' "$AGENT"
} >&2

exit 2
