#!/usr/bin/env bash
#
# Refresh the docs/agent-memory.md ## In-Flight Work section from
# docs/agent-memory/in-flight/<agent-id>.md per-agent files.
#
# Idempotent: given identical directory contents, produces identical output.
# Two parallel agents only ever write their own per-agent file, so concurrent
# /update-sop runs cannot collide on this section. Post-merge regeneration
# always converges because the inputs (per-agent files) merge cleanly when
# filenames are distinct.
#
# Usage:
#   bash scripts/refresh-in-flight.sh                     # default paths
#   bash scripts/refresh-in-flight.sh <memory.md> <dir>   # explicit
#
# Called by /update-sop Step 5.
#
# Per-agent file format: one bullet per in-flight item, no leading dash.
#   (YYYY-MM-DD): short description of what's mid-flight
#   (YYYY-MM-DD): another in-flight item for the same agent
#
# An empty per-agent file means that agent has nothing in flight; the script
# treats it the same as an absent file. Agents always overwrite their own
# file — never edit other agents' files.

set -euo pipefail

MEMORY_MD="${1:-docs/agent-memory.md}"
INFLIGHT_DIR="${2:-docs/agent-memory/in-flight}"

if [ ! -f "$MEMORY_MD" ]; then
    echo "Error: agent-memory.md not found at $MEMORY_MD" >&2
    exit 1
fi

if ! grep -q '<!-- in-flight:start -->' "$MEMORY_MD"; then
    echo "Error: $MEMORY_MD has no <!-- in-flight:start --> sentinel" >&2
    echo "Add the sentinel block under ## In-Flight Work to enable refresh." >&2
    exit 1
fi

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

{
    echo "<!-- in-flight:start -->"
    echo "*Auto-generated from \`${INFLIGHT_DIR}/\`. Last refreshed: $(date +%Y-%m-%d).*"
    echo ""

    FOUND=0
    if [ -d "$INFLIGHT_DIR" ] && ls "$INFLIGHT_DIR"/*.md >/dev/null 2>&1; then
        for f in $(ls "$INFLIGHT_DIR"/*.md 2>/dev/null | sort); do
            base=$(basename "$f" .md)
            [ "$base" = "README" ] && continue
            agent_id="$base"
            # Read non-blank, non-comment lines; emit one bullet per line.
            while IFS= read -r line; do
                # skip blanks and HTML comments
                case "$line" in
                    ''|'<!--'*) continue ;;
                esac
                # strip a leading bullet if the agent left one in
                line="${line#- }"
                printf -- '- %s %s\n' "$agent_id" "$line"
                FOUND=1
            done < "$f"
        done
    fi

    [ "$FOUND" = "0" ] && echo "*(none)*"

    echo "<!-- in-flight:end -->"
} > "$TMP"

awk -v repl_file="$TMP" '
    /<!-- in-flight:start -->/ {
        while ((getline line < repl_file) > 0) print line
        close(repl_file)
        skip = 1
        next
    }
    /<!-- in-flight:end -->/ {
        skip = 0
        next
    }
    !skip { print }
' "$MEMORY_MD" > "${MEMORY_MD}.tmp" && mv "${MEMORY_MD}.tmp" "$MEMORY_MD"

echo "In-Flight Work refreshed: $MEMORY_MD"
