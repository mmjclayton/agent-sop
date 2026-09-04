#!/usr/bin/env bash
#
# agent-sop SessionStart + UserPromptSubmit hook — loads project context once.
#
# Claude Code adds this hook's stdout to the model's context for both events.
# Registered on both because sessions here are launched from ~ and cd into a
# project: SessionStart fires too early to see the project, so the first
# prompt after the cd is what loads it. A marker per (session, repo) keeps it
# to one print; SessionStart with source "compact" or "clear" reprints, since
# the earlier context is gone.
#
# What it prints replaces /restart-sop Steps 0-4: resume snapshot, in-flight
# lines, recent sessions, in-progress Backlog items, drift facts, sibling
# worktree state, upstream-sync staleness. The Backlog item for the task is
# still read when the task starts — that is judgement, not mechanics.
#
# Silent (exit 0, no stdout) for any directory that is not an SOP project.

set -u
. "$(dirname "${BASH_SOURCE[0]}")/sop-lib.sh"

sop_have_jq || exit 0
sop_read_input

CWD=$(sop_field '.cwd')
[ -n "$CWD" ] || CWD="$PWD"
ROOT=$(sop_repo_root "$CWD")
sop_is_sop_repo "$ROOT" || exit 0

SESSION=$(sop_field '.session_id')
[ -n "$SESSION" ] || SESSION="nosession"
SOURCE=$(sop_field '.source')

MARKER_DIR="$(sop_state_dir)/sessions/$SESSION"
MARKER="$MARKER_DIR/$(sop_repo_key "$ROOT").ctx"
case "$SOURCE" in
    compact|clear) ;;
    *) [ -f "$MARKER" ] && exit 0 ;;
esac
mkdir -p "$MARKER_DIR" 2>/dev/null && : > "$MARKER" 2>/dev/null

NAME=$(basename "$ROOT")
BRANCH=$(git -C "$ROOT" branch --show-current 2>/dev/null)
AGENT=$(sop_agent_id "$ROOT")

# ── Resume snapshot ───────────────────────────────────────────────────────────
RESUME_TEXT="(none found — first session on this project for agent-id $AGENT, or no resolver in scripts/)"
if [ -f "$ROOT/scripts/resolve-resume-path.sh" ]; then
    RESUME_PATH=$(bash "$ROOT/scripts/resolve-resume-path.sh" --read --root "$ROOT" --home "${HOME:-}" 2>/dev/null)
    if [ -n "$RESUME_PATH" ] && [ -f "$RESUME_PATH" ]; then
        RESUME_TEXT="$RESUME_PATH
$(head -80 "$RESUME_PATH")"
    fi
fi

# ── In-flight lines for this agent ────────────────────────────────────────────
INFLIGHT="(none)"
if [ -s "$ROOT/docs/agent-memory/in-flight/$AGENT.md" ]; then
    INFLIGHT=$(head -10 "$ROOT/docs/agent-memory/in-flight/$AGENT.md")
fi

# ── Recent sessions (rollup between sentinels, else directory listing) ────────
RECENT=""
if [ -f "$ROOT/docs/RECENT-WORK.md" ]; then
    RECENT=$(awk '/recent-work-rollup:start/{f=1; next} /recent-work-rollup:end/{f=0} f' "$ROOT/docs/RECENT-WORK.md" \
        | grep -v '^\s*$' | grep -v '^\*No entries' | grep -v '^\*Auto-generated' | head -3)
fi
if [ -z "$RECENT" ] && [ -d "$ROOT/docs/recent-work" ]; then
    RECENT=$(find "$ROOT/docs/recent-work" -maxdepth 1 -name '[0-9][0-9][0-9][0-9]-*.md' -exec basename {} \; 2>/dev/null | sort -r | head -3)
fi
[ -n "$RECENT" ] || RECENT="(no session records yet)"

# ── In-progress Backlog items ─────────────────────────────────────────────────
# Only the status line counts: the first non-empty line after a `### P<n>`
# heading, which by the Backlog spec carries the tags. Entry bodies quote tags
# in prose all the time ("no [IN PROGRESS] intermediate"), and matching those
# listed three shipped items as in progress on the hook's first live run (P100).
INPROG=$(awk '
    /^### P[0-9]+/ { title = $0; sub(/^### /, "", title); want = 1; next }
    want && /^[[:space:]]*$/ { next }
    want { if ($0 ~ /^`\[IN PROGRESS\]/) print "  " title; want = 0 }
' "$ROOT/Backlog.md" 2>/dev/null | head -8)
[ -n "$INPROG" ] || INPROG="  (none tagged [IN PROGRESS])"

# ── Drift facts ───────────────────────────────────────────────────────────────
DRIFT=$(sop_drift_commits "$ROOT")
if [ -n "$DRIFT" ]; then
    n=$(printf '%s\n' "$DRIFT" | grep -c .)
    DRIFT_LINE="$n commit(s) since the last session record — newest: $(printf '%s\n' "$DRIFT" | head -1)"
else
    DRIFT_LINE="none — last session record covers HEAD"
fi
DIRTY=$(sop_tracker_dirty "$ROOT")
[ -n "$DIRTY" ] && DIRTY_LINE="$(printf '%s\n' "$DIRTY" | tr '\n' ' ')" || DIRTY_LINE="none"

# ── Sibling worktrees ─────────────────────────────────────────────────────────
SIBLINGS="(single worktree)"
WT_COUNT=$(git -C "$ROOT" worktree list 2>/dev/null | wc -l | tr -d ' ')
if [ "${WT_COUNT:-1}" -gt 1 ] 2>/dev/null; then
    DIRTY_SIBS=""
    while read -r wt; do
        [ -n "$wt" ] || continue
        [ "$wt" = "$ROOT" ] && continue
        if [ -n "$(git -C "$wt" status --porcelain 2>/dev/null)" ]; then
            DIRTY_SIBS="$DIRTY_SIBS $wt"
        fi
    done <<EOF
$(git -C "$ROOT" worktree list --porcelain 2>/dev/null | awk '/^worktree /{sub(/^worktree /, ""); print}')
EOF
    if [ -n "$DIRTY_SIBS" ]; then
        SIBLINGS="$WT_COUNT worktrees; sibling worktree(s) with uncommitted edits:$DIRTY_SIBS — branch-mutating git ops here can wipe them"
    else
        SIBLINGS="$WT_COUNT worktrees, all siblings clean"
    fi
fi

# ── Upstream SOP sync staleness ───────────────────────────────────────────────
SYNC=""
CFG="${HOME:-}/.claude/agent-sop.config.json"
if [ -f "$CFG" ]; then
    last=$(jq -r '.last_update_check // empty' "$CFG" 2>/dev/null)
    cadence=$(jq -r '.update_reminder // "weekly"' "$CFG" 2>/dev/null)
    if [ -n "$last" ] && [ "$cadence" != "off" ]; then
        last_epoch=$(date -j -f %Y-%m-%d "$last" +%s 2>/dev/null || date -d "$last" +%s 2>/dev/null || echo "")
        if [ -n "$last_epoch" ]; then
            days=$(( ( $(date +%s) - last_epoch ) / 86400 ))
            SYNC="last /update-agent-sop check $last ($days days ago, reminder: $cadence)"
            [ "$cadence" = "weekly" ] && [ "$days" -gt 7 ] && SYNC="$SYNC — stale"
        fi
    fi
fi

# ── Legacy ship-sop directive ─────────────────────────────────────────────────
LEGACY=""
[ -f "$ROOT/.ship/.pending-auto-fire.md" ] && LEGACY="Legacy ship-sop directive at .ship/.pending-auto-fire.md — superseded by the agent-sop Stop hook, which now emits the gate demand itself. Ignore it and delete the .ship/.pending-auto-fire.* files."

# ── Print ─────────────────────────────────────────────────────────────────────
printf -- '--- Agent SOP context: %s (branch %s, agent-id %s) ---\n' "$NAME" "${BRANCH:-detached}" "$AGENT"
printf 'Resume snapshot: %s\n' "$RESUME_TEXT"
printf 'In-flight (%s):\n%s\n' "$AGENT" "$(printf '%s\n' "$INFLIGHT" | sed 's/^/  /')"
printf 'Recent sessions:\n%s\n' "$(printf '%s\n' "$RECENT" | sed 's/^/  /')"
printf 'In progress in Backlog.md:\n%s\n' "$INPROG"
printf 'Drift: %s\n' "$DRIFT_LINE"
printf 'Uncommitted tracker files: %s\n' "$DIRTY_LINE"
printf 'Worktrees: %s\n' "$SIBLINGS"
[ -n "$SYNC" ] && printf 'SOP sync: %s\n' "$SYNC"
[ -n "$LEGACY" ] && printf '%s\n' "$LEGACY"
printf 'This replaces /restart-sop Steps 0-4. Read the Backlog.md item for the task before starting it. Session-end is enforced by the Stop hook: when you stop with unrecorded commits or uncommitted trackers it tells you exactly what is missing.\n'
printf -- '--- end Agent SOP context ---\n'
exit 0
