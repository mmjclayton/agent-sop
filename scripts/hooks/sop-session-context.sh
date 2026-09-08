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

# Live presence is local to this Git repository, shared across linked worktrees.
# It is advisory, not a write lock; one active writer per worktree remains required.
COMMON=$(git -C "$ROOT" rev-parse --git-common-dir 2>/dev/null)
case "$COMMON" in /*) ;; *) COMMON="$ROOT/$COMMON" ;; esac
PRESENCE="$COMMON/agent-sop/sessions"
SESSION_KEY=$(printf '%s' "$SESSION" | sop_sha256)
NOW=$(date +%s)
PRESENCE_WARNING=''
if mkdir -p "$PRESENCE" 2>/dev/null; then
    TEMP=$(mktemp "$PRESENCE/.presence.XXXXXX") || TEMP=''
    if [ -n "$TEMP" ] && jq -n --arg root "$ROOT" --arg session "$SESSION_KEY" --argjson updated "$NOW" \
      '{root:$root,session:$session,updated:$updated}' > "$TEMP" && mv "$TEMP" "$PRESENCE/$SESSION_KEY.json"; then :
    else PRESENCE_WARNING='unavailable: could not publish this session presence'; fi
    [ -z "$TEMP" ] || rm -f "$TEMP"
else PRESENCE_WARNING='unavailable: presence directory is not writable'; fi
OTHER=$(sop_registry_read "$PRESENCE" 2>/dev/null) || OTHER='[{"status":"unavailable: invalid or unreadable session registry"}]'
OTHER=$(printf '%s' "$OTHER" | jq -c --arg session "$SESSION_KEY" --argjson cutoff "$((NOW - 1800))" \
  '[.[] | select(.status != null or (.session != $session and .updated > $cutoff)) | del(.updated)] | sort_by(.root,.session)')
if [ -n "$PRESENCE_WARNING" ]; then OTHER=$(printf '%s' "$OTHER" | jq -c --arg warning "$PRESENCE_WARNING" '. + [{status:$warning}]'); fi
CLAIMS=$(sop_registry_read "$COMMON/agent-sop/claims" 2>/dev/null) || CLAIMS='[{"status":"unavailable: invalid or unreadable claim registry"}]'
CURRENT_HEAD=$(git -C "$ROOT" rev-parse HEAD 2>/dev/null)
CONTEXT_KEY=$(printf '%s|%s|%s' "$CURRENT_HEAD" "$OTHER" "$CLAIMS" | sop_sha256)
MARKER_DIR="$(sop_state_dir)/sessions/$SESSION"
MARKER="$MARKER_DIR/$(sop_repo_key "$ROOT").ctx"
case "$SOURCE" in
    compact|clear) ;;
    *)
        if [ -f "$MARKER" ]; then
            if [ "$(cat "$MARKER")" != "$CONTEXT_KEY" ]; then
                printf '[agent-sop] Context changed: HEAD %s. Refresh affected task context before editing. Other active sessions: %s; writer claims: %s\n' "$CURRENT_HEAD" "$(printf '%s' "$OTHER" | jq -c .)" "$CLAIMS"
                printf '%s' "$CONTEXT_KEY" > "$MARKER"
            fi
            exit 0
        fi ;;
esac
mkdir -p "$MARKER_DIR" 2>/dev/null && printf '%s' "$CONTEXT_KEY" > "$MARKER" 2>/dev/null
if [ "$CLAIMS" != '[]' ]; then printf '[agent-sop] Writer/task claims: %s\n' "$CLAIMS"; fi
if [ "$OTHER" != '[]' ]; then
    printf '[agent-sop] Other active sessions (30-minute presence lease): %s. Use one writer per worktree; coordinate task and path ownership.\n' "$(printf '%s' "$OTHER" | jq -c .)"
fi

NAME=$(basename "$ROOT")
BRANCH=$(git -C "$ROOT" branch --show-current 2>/dev/null)
AGENT=$(sop_agent_id "$ROOT")
PTYPE=$(sop_project_type "$ROOT")
DECLARED=$(sop_declared_project_type "$ROOT")
SIGNALS=$(sop_code_signals "$ROOT" | paste -sd, - | sed 's/,/, /g')
# Anything that makes the type answer suspect is said once, whether or not
# ship-sop is configured: the Stop hook's silence rides on this answer too
# (P103), so a contradicted declaration or an unreadable CLAUDE.md must not
# hide behind the gate line (review finding, HIGH).
PTYPE_NOTE=""
if [ "$DECLARED" = "non-code" ] && [ -n "$SIGNALS" ]; then
    PTYPE_NOTE="$(basename "$(sop_instruction_file "$ROOT")") declares non-code, but $SIGNALS say code; the declaration wins: the reviewer gate is off and the Stop hook enforces nothing here. Remove the line if that is not intended."
elif [ "$(sop_claude_md_state "$ROOT")" = "dangling" ]; then
    PTYPE_NOTE="$(basename "$(sop_instruction_file "$ROOT")") is a symlink whose target is missing; nothing could be read from it, the detected project type is $PTYPE. Repair the instruction link."
elif [ "$(sop_claude_md_state "$ROOT")" = "unreadable" ]; then
    PTYPE_NOTE="$(basename "$(sop_instruction_file "$ROOT")") could not be read; the detected project type is $PTYPE. Repair the instruction file."
fi

# ── Resume snapshot ───────────────────────────────────────────────────────────
RESUME_TEXT="(none found — first session on this project for agent-id $AGENT, or no resolver in scripts/)"
RESOLVER=$(sop_resolver) || { RESOLVER=''; RESUME_TEXT="Trusted resolver unavailable: update Agent SOP installation"; }
if [ -n "$RESOLVER" ]; then
    RESUME_ERROR=$(mktemp)
    RESUME_PATH=$(bash "$RESOLVER" --read --root "$ROOT" --home "${HOME:-}" 2> "$RESUME_ERROR")
    [ ! -s "$RESUME_ERROR" ] || RESUME_TEXT="$(cat "$RESUME_ERROR")"
    rm -f "$RESUME_ERROR"
    if [ -n "$RESUME_PATH" ] && [ -f "$RESUME_PATH" ]; then
        RESUME_TEXT="$RESUME_PATH
$(head -80 "$RESUME_PATH")"
    fi
fi

# Read all local worktree handoffs, bounded to keep coordination context small.
INFLIGHT=""
while IFS= read -r wt; do
    [ -n "$wt" ] || continue
    for file in "$wt"/docs/agent-memory/in-flight/*.md; do
        [ -s "$file" ] || continue
        [ "$(basename "$file")" != README.md ] || continue
        INFLIGHT="$INFLIGHT
$wt / $(basename "$file"):
$(head -5 "$file")"
    done
done <<EOF
$(git -C "$ROOT" worktree list --porcelain | sed -n 's/^worktree //p')
EOF
INFLIGHT=$(printf '%s\n' "$INFLIGHT" | head -30)
[ -n "$INFLIGHT" ] || INFLIGHT="(none)"

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

# ── Ship gate (same fact the Stop hook and push gate act on) ──────────────────
# "Drift: none" and an outstanding gate can both be true of one commit; a real
# session read the first and was surprised by the second at its next stop
# (P101). Printed only where ship-sop is configured. A config on a non-code
# project says so instead of implying a gate that will never fire (P102).
GATE_LINE=""
if [ -f "$ROOT/ship-sop.config.json" ]; then
    if [ "$PTYPE" != "code" ]; then
        GATE_LINE="none — non-code project; ship-sop's automatic gate fires only on code projects (declare \`**Project type:** code\` in CLAUDE.md to opt in)"
    else
        GATE=$(sop_shipsop_gate "$ROOT")
        if [ -n "$GATE" ]; then
            GATE_LINE="outstanding — $(printf '%s\n' "$GATE" | head -1) The Stop hook will demand the report at your next stop; the push gate refuses until it exists."
        fi
    fi
fi

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
        SIBLINGS="$WT_COUNT worktrees; sibling worktree(s) with uncommitted edits:$DIRTY_SIBS — coordinate ownership before operations targeting those worktrees or shared refs"
    else
        SIBLINGS="$WT_COUNT worktrees, all siblings clean"
    fi
fi

# ── Upstream SOP sync staleness ───────────────────────────────────────────────
SYNC=""
CFG="${AGENT_SOP_CONFIG_HOME:-${HOME:-}/.claude}/agent-sop.config.json"
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
printf -- '--- Agent SOP context: %s (branch %s, agent-id %s, %s project) ---\n' "$NAME" "${BRANCH:-detached}" "$AGENT" "$PTYPE"
[ -n "$PTYPE_NOTE" ] && printf 'Project type: %s — %s\n' "$PTYPE" "$PTYPE_NOTE"
printf 'Resume snapshot: %s\n' "$RESUME_TEXT"
# Facts print only when they are not the default (P104): a block of "(none)"
# lines is read by nobody, and the Stop hook enforces drift regardless.
[ "$INFLIGHT" != "(none)" ] && printf 'In-flight (%s):\n%s\n' "$AGENT" "$(printf '%s\n' "$INFLIGHT" | sed 's/^/  /')"
printf 'Recent sessions:\n%s\n' "$(printf '%s\n' "$RECENT" | sed 's/^/  /')"
[ "$INPROG" != "  (none tagged [IN PROGRESS])" ] && printf 'In progress in Backlog.md:\n%s\n' "$INPROG"
[ -n "$DRIFT" ] && printf 'Drift: %s\n' "$DRIFT_LINE"
[ -n "$DIRTY" ] && printf 'Uncommitted tracker files: %s\n' "$DIRTY_LINE"
[ -n "$GATE_LINE" ] && printf 'Ship gate: %s\n' "$GATE_LINE"
[ "$SIBLINGS" != "(single worktree)" ] && printf 'Worktrees: %s\n' "$SIBLINGS"
case "$SYNC" in *stale*) printf 'SOP sync: %s\n' "$SYNC" ;; esac
[ -n "$LEGACY" ] && printf '%s\n' "$LEGACY"
if [ "$PTYPE" = "code" ]; then
    printf 'This replaces /restart-sop Steps 0-4. Read the Backlog.md item for the task before starting it.\n'
else
    printf 'This replaces /restart-sop Steps 0-4. Read the Backlog.md item for the task before starting it. Non-code project: the Stop hook enforces nothing here; /update-sop is the deliberate close.\n'
fi
printf -- '--- end Agent SOP context ---\n'
exit 0
