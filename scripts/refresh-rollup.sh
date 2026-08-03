#!/usr/bin/env bash
#
# Refresh the ## Recent Work (rollup) section from docs/recent-work/.
#
# The rollup lives in docs/RECENT-WORK.md in this repo (moved out of CLAUDE.md
# on 2026-08-03 so it stops consuming context every session) and in CLAUDE.md in
# projects that have not migrated. The target is resolved at run time rather
# than hardcoded, so both layouts work without a flag day for consumers.
#
# Idempotent: given identical directory contents, produces identical output.
# That property is load-bearing for parallel-session merges — two agents
# running this in separate worktrees with the same directory state write
# byte-identical rollups, so post-merge regeneration always converges.
#
# Usage:
#   bash scripts/refresh-rollup.sh [rollup-file] [recent-work-dir]
#
# Called by /update-sop Step 8b and /migrate-to-multi-agent Step 9.
#
# Why this lives in a script rather than inline in the slash commands:
# the inline form used `local var=$(cmd)` inside a `{ ... } > output`
# compound group, which under zsh (macOS default) leaks the `var=...`
# assignment lines to stdout and corrupts the target file. Bash handles it
# correctly. Shipping as a script with a bash shebang forces the right
# interpreter regardless of the caller's shell.

set -euo pipefail

SENTINEL_START='<!-- recent-work-rollup:start -->'

# Target resolution. An explicit argument always wins. Otherwise prefer
# docs/RECENT-WORK.md when it carries the sentinel — creating that file is a
# deliberate migration signal — and fall back to CLAUDE.md, which is where
# projects that have not migrated still keep the section.
resolve_rollup_file() {
    if [ -n "${1:-}" ]; then
        printf '%s' "$1"
        return 0
    fi
    for candidate in docs/RECENT-WORK.md CLAUDE.md; do
        if [ -f "$candidate" ] && grep -q "$SENTINEL_START" "$candidate"; then
            printf '%s' "$candidate"
            return 0
        fi
    done
    return 1
}

if ! ROLLUP_FILE=$(resolve_rollup_file "${1:-}"); then
    echo "Error: no rollup target found. Expected the ${SENTINEL_START} sentinel in docs/RECENT-WORK.md or CLAUDE.md." >&2
    exit 1
fi

RECENT_DIR="${2:-docs/recent-work}"

if [ ! -f "$ROLLUP_FILE" ]; then
    echo "Error: rollup target not found at $ROLLUP_FILE" >&2
    exit 1
fi

if ! grep -q "$SENTINEL_START" "$ROLLUP_FILE"; then
    echo "Error: $ROLLUP_FILE has no ${SENTINEL_START} sentinel" >&2
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
            # `|| true`: an entry with no `# ` heading makes grep exit 1, and
            # under `set -o pipefail` that killed the whole script with no
            # output — leaving the rollup silently unrefreshed and making the
            # "(untitled)" fallback below unreachable. Guard the pipe so one
            # malformed entry degrades to "(untitled)" instead of a silent death.
            TITLE=$( { grep -m1 '^# ' "$f" || true; } | sed 's/^# //')
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
' "$ROLLUP_FILE" > "${ROLLUP_FILE}.tmp" && mv "${ROLLUP_FILE}.tmp" "$ROLLUP_FILE"

echo "Rollup refreshed: $ROLLUP_FILE"
