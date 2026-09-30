#!/usr/bin/env bash
#
# agent-sop PostToolUse(Write|Edit) hook — reports a harness memory index that
# is near its load limit (P113).
#
# The harness loads the first 200 lines or 25,000 bytes of a memory directory's
# MEMORY.md, whichever comes first, and says so only after entries have already
# been cut off. This hook reports from 80 per cent of either limit (exit 2,
# facts on stderr), so the index is trimmed while every entry still loads.
#
# It speaks only when all of:
#   - the tool wrote a file named MEMORY.md whose directory is named `memory`
#   - that file is at or over the warning share of the byte or line limit
#   - this session has not already been told about an index this large
#
# It reports, never refuses: the write has happened by the time it runs. It is
# not limited to SOP projects, because the index that overflows is the one
# shared by every session launched from the home directory.
#
# Lengths are bytes, not characters: sop-lib.sh exports LC_ALL=C, and bytes are
# what the harness limit counts.
#
# Usage:
#   sop-memory-index.sh                  hook mode, input JSON on stdin
#   sop-memory-index.sh --file <path>    print the report for one index, exit 0

set -u
. "$(dirname "${BASH_SOURCE[0]}")/sop-lib.sh"

LIMIT_BYTES=25000
LIMIT_LINES=200
LINE_BYTES=200
WARN_PERCENT=80
LONGEST_SHOWN=5

# index_report <file> — the facts, one per line.
index_report() {
    local file="$1" bytes lines long
    bytes=$(wc -c < "$file" | tr -d ' ')
    lines=$(awk 'END { print NR }' "$file")
    long=$(awk -v max="$LINE_BYTES" 'length($0) > max { n++ } END { print n + 0 }' "$file")
    printf '%s of %s bytes (%s%%), %s of %s lines (%s%%)\n' \
        "$bytes" "$LIMIT_BYTES" "$((bytes * 100 / LIMIT_BYTES))" \
        "$lines" "$LIMIT_LINES" "$((lines * 100 / LIMIT_LINES))"
    [ "$long" -gt 0 ] || return 0
    printf '%s lines over %s bytes; the longest:\n' "$long" "$LINE_BYTES"
    awk -v max="$LINE_BYTES" 'length($0) > max { printf "%d %d %s\n", length($0), NR, substr($0, 1, 60) }' "$file" |
        sort -rn | head -n "$LONGEST_SHOWN" |
        while read -r len nr text; do printf '  line %s (%s bytes): %s\n' "$nr" "$len" "$text"; done
}

# index_over_threshold <file> — true at or over the warning share of a limit.
index_over_threshold() {
    local bytes lines
    bytes=$(wc -c < "$1" | tr -d ' ')
    lines=$(awk 'END { print NR }' "$1")
    [ "$bytes" -ge $((LIMIT_BYTES * WARN_PERCENT / 100)) ] ||
        [ "$lines" -ge $((LIMIT_LINES * WARN_PERCENT / 100)) ]
}

if [ "${1:-}" = "--file" ]; then
    [ -f "${2:-}" ] || { echo "sop-memory-index: no such file: ${2:-}" >&2; exit 1; }
    index_report "$2"
    exit 0
fi

sop_have_jq || exit 0
sop_read_input

case "$(sop_field '.tool_name')" in
    Write|Edit|MultiEdit) ;;
    *) exit 0 ;;
esac

FILE=$(sop_field '.tool_input.file_path')
case "$FILE" in
    */memory/MEMORY.md) ;;
    *) exit 0 ;;
esac
[ -f "$FILE" ] || exit 0

index_over_threshold "$FILE" || exit 0

# Once per size reached: the marker holds the largest size this session has
# been told about, so a trim followed by regrowth to the same size is quiet
# and any growth past it is a new fact.
SESSION=$(sop_field '.session_id')
[ -n "$SESSION" ] || SESSION=unknown
MARKER_DIR="$(sop_state_dir)/sessions/$SESSION"
MARKER="$MARKER_DIR/memory-index-$(printf '%s' "$FILE" | sop_sha256)"
BYTES=$(wc -c < "$FILE" | tr -d ' ')
LINES=$(awk 'END { print NR }' "$FILE")
if [ -f "$MARKER" ]; then
    read -r TOLD_BYTES TOLD_LINES < "$MARKER" || true
    if [ "$BYTES" -le "${TOLD_BYTES:-0}" ] && [ "$LINES" -le "${TOLD_LINES:-0}" ]; then exit 0; fi
fi
mkdir -p "$MARKER_DIR" 2>/dev/null && printf '%s %s\n' "$BYTES" "$LINES" > "$MARKER" 2>/dev/null

{
    printf '[agent-sop] memory index near its load limit: %s\n' "$FILE"
    index_report "$FILE"
    printf 'The harness loads the first %s lines or %s bytes and drops the rest. ' "$LIMIT_LINES" "$LIMIT_BYTES"
    printf 'Keep each entry to one line under %s bytes and move detail into its topic file. ' "$LINE_BYTES"
    printf 'State of an Agent SOP project belongs in that project (/update-sop), with one pointer line here. '
    printf 'Change or remove index lines only with the user'"'"'s agreement; topic files stay on disk.\n'
} >&2

exit 2
