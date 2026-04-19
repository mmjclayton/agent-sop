#!/usr/bin/env bash
#
# Refresh the CLAUDE.md ## Recent Work (rollup) section from docs/recent-work/.
#
# Idempotent: given identical directory contents, produces identical output.
# That property is load-bearing for parallel-session merges — two agents
# running this in separate worktrees with the same directory state write
# byte-identical rollups, so post-merge regeneration always converges.
#
# Usage:
#   bash scripts/refresh-rollup.sh
#
# Called by /update-sop Step 8b and /migrate-to-multi-agent Step 9.
#
# Why this lives in a script rather than inline in the slash commands:
# the inline form used `local var=$(cmd)` inside a `{ ... } > output`
# compound group, which under zsh (macOS default) leaks the `var=...`
# assignment lines to stdout and corrupts CLAUDE.md. Bash handles it
# correctly. Shipping as a script with a bash shebang forces the right
# interpreter regardless of the caller's shell.

set -euo pipefail

CLAUDE_MD="${1:-CLAUDE.md}"
RECENT_DIR="${2:-docs/recent-work}"

if [ ! -f "$CLAUDE_MD" ]; then
    echo "Error: CLAUDE.md not found at $CLAUDE_MD" >&2
    exit 1
fi

if ! grep -q '<!-- recent-work-rollup:start -->' "$CLAUDE_MD"; then
    echo "Error: $CLAUDE_MD has no <!-- recent-work-rollup:start --> sentinel" >&2
    exit 1
fi

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

{
    echo "<!-- recent-work-rollup:start -->"
    echo "*Auto-generated from \`${RECENT_DIR}/\`. Last refreshed: $(date +%Y-%m-%d).*"
    echo ""

    FOUND=0
    if ls "$RECENT_DIR"/*.md >/dev/null 2>&1; then
        for f in $(ls "$RECENT_DIR"/*.md 2>/dev/null | sort -r); do
            [ "$(basename "$f")" = "README.md" ] && continue
            FNAME=$(basename "$f" .md)
            DATE_PART=$(printf '%s' "$FNAME" | cut -d_ -f1)
            AGENT_PART=$(printf '%s' "$FNAME" | cut -d_ -f2)
            TITLE=$(grep -m1 '^# ' "$f" | sed 's/^# //')
            [ -z "$TITLE" ] && TITLE="(untitled)"
            echo "- $DATE_PART \`$AGENT_PART\`: $TITLE"
            FOUND=1
        done
    fi

    [ "$FOUND" = "0" ] && echo "*No entries yet.*"

    echo "<!-- recent-work-rollup:end -->"
} > "$TMP"

awk -v repl_file="$TMP" '
    /<!-- recent-work-rollup:start -->/ {
        while ((getline line < repl_file) > 0) print line
        close(repl_file)
        skip = 1
        next
    }
    /<!-- recent-work-rollup:end -->/ {
        skip = 0
        next
    }
    !skip { print }
' "$CLAUDE_MD" > "${CLAUDE_MD}.tmp" && mv "${CLAUDE_MD}.tmp" "$CLAUDE_MD"

echo "Rollup refreshed: $CLAUDE_MD"
