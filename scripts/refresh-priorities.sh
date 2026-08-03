#!/usr/bin/env bash
#
# Regenerate the Current Priority Items block in CLAUDE.md from Backlog.md.
#
# Why derived rather than hand-maintained: CLAUDE.md declares Backlog.md the
# single source of truth for work item status, then kept a second hand-written
# copy of the open items beside it. That is a Rule 2 violation shipped in the
# template, and it drifted in every project that used it — worst observed case
# 117 days stale, and agent-sop's own copy drifted inside a single session.
#
# The fix is the pattern this repo already proves with the Recent Work rollup:
# sentinel markers plus a regenerating script. A derived view does not drift,
# because nobody maintains it. This keeps the benefit the pointer alternative
# throws away — the agent sees priorities without grepping Backlog.md — while
# removing the copy that goes stale (P92).
#
# Idempotent: identical Backlog.md contents produce identical output, so
# parallel agents regenerating in separate worktrees converge on merge.
#
# Usage:
#   bash scripts/refresh-priorities.sh [claude-md] [backlog]
#
# Called by /update-sop Step 3 after Backlog.md is updated.
#
# Opt-in: a project whose CLAUDE.md has no sentinel block is left untouched and
# exits 0. Adding the block is what enables the derivation.

set -euo pipefail

SENTINEL_START='<!-- priority-items:start -->'
SENTINEL_END='<!-- priority-items:end -->'

CLAUDE_MD="${1:-CLAUDE.md}"
BACKLOG="${2:-Backlog.md}"

if [ ! -f "$CLAUDE_MD" ]; then
    echo "Error: $CLAUDE_MD not found" >&2
    exit 1
fi

if [ ! -f "$BACKLOG" ]; then
    echo "Error: $BACKLOG not found" >&2
    exit 1
fi

# Opt-in, not a hard requirement. Pre-P92 projects keep their hand-written
# section until they choose to migrate; failing here would break their
# /update-sop run for a section they never opted into.
if ! grep -q "$SENTINEL_START" "$CLAUDE_MD"; then
    echo "refresh-priorities: no ${SENTINEL_START} block in $CLAUDE_MD — skipping (section is opt-in)"
    exit 0
fi

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

# Emit one line per non-terminal item. A P-number heading is followed by its
# status line in backticks, e.g. `[OPEN] [Bug] [has-open-questions]`.
# `|| true` on the grep: a Backlog with no open items is a legitimate state
# (everything shipped), and a bare grep failure would kill the script under
# pipefail — the exact class P84 fixed across the other scripts.
{
    echo "$SENTINEL_START"
    echo "*Derived from \`${BACKLOG}\` by \`scripts/refresh-priorities.sh\`. Do not edit by hand — the Backlog is the source of truth. Last refreshed: $(date +%Y-%m-%d).*"
    echo ""

    FOUND=0
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            '### P'*)
                pending_heading="$line"
                continue
                ;;
            '`['*)
                [ -z "${pending_heading:-}" ] && continue
                status=$(printf '%s' "$line" | sed -n 's/^`\[\([A-Z '"'"']*\)\].*/\1/p')
                case "$status" in
                    OPEN|"IN PROGRESS"|BLOCKED)
                        title=$(printf '%s' "$pending_heading" | sed 's/^### //')
                        tags=$(printf '%s' "$line" | tr -d '`')
                        echo "- ${title} — ${tags}"
                        FOUND=1
                        ;;
                esac
                pending_heading=""
                ;;
        esac
    done < "$BACKLOG"

    [ "$FOUND" = "0" ] && echo "*No open items. Everything in \`${BACKLOG}\` is shipped, deferred, or closed.*"

    echo "$SENTINEL_END"
} > "$TMP"

awk -v repl_file="$TMP" '
    /<!-- priority-items:start -->/ {
        while ((getline line < repl_file) > 0) print line
        close(repl_file)
        skip = 1
        next
    }
    /<!-- priority-items:end -->/ {
        skip = 0
        next
    }
    !skip { print }
' "$CLAUDE_MD" > "${CLAUDE_MD}.tmp" && mv "${CLAUDE_MD}.tmp" "$CLAUDE_MD"

echo "Priority items refreshed: $CLAUDE_MD"
