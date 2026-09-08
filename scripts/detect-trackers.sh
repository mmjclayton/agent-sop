#!/usr/bin/env bash
#
# List this project's secondary tracker files.
#
# A secondary tracker is any `.md` path named in the project instructions' Key Documents &
# Dispatch table whose headings carry a Backlog-style status tag — audit
# findings, security scans, compliance checklists, migration punch-lists.
# `Backlog.md` and `docs/backlog-archive.md` are excluded; Step 3 covers them.
#
# Emits one bare path per line. Empty output means the project has no secondary
# trackers, which is a normal state and exits 0 — not an error.
#
# Usage:
#   bash scripts/detect-trackers.sh [instructions-path]
#
# Called by /update-sop Step 4 (reconciliation; formerly Steps 3b and 11, the reconciliation
# hard block).
#
# Why this lives in a script rather than inline in the slash command: those two
# steps run in separate bash blocks, so a function defined in one block does not
# survive to another. The old Step 11 called `detect_trackers` with no definition
# anywhere in the repo, so its `exit 1` hard block could never fire — the loop
# body was unreachable. One definition, two callers, no drift.

set -euo pipefail

INSTRUCTIONS=()
if [ $# -gt 0 ]; then INSTRUCTIONS=("$1")
else
    for candidate in AGENTS.md CLAUDE.md; do
        [ ! -f "$candidate" ] || INSTRUCTIONS+=("$candidate")
    done
fi
[ "${#INSTRUCTIONS[@]}" -gt 0 ] || exit 0
for input in "${INSTRUCTIONS[@]}"; do
    [ -f "$input" ] && [ -r "$input" ] || { echo "Cannot read instructions: $input" >&2; exit 1; }
done
PATHS=$(mktemp)
trap 'rm -f "$PATHS"' EXIT
status=0
grep -hoE '`[^`]+\.md`' "${INSTRUCTIONS[@]}" > "$PATHS" || status=$?
[ "$status" -le 1 ] || { echo 'Tracker discovery failed reading project instructions' >&2; exit "$status"; }
cat "$PATHS" \
  | tr -d '`' \
  | sort -u \
  | while read -r f; do
        # Backlog.md is Step 3; its archive is the same entries moved verbatim (P105).
        case "$f" in Backlog.md|docs/backlog-archive.md) continue ;; esac
        if [ ! -f "$f" ]; then continue; fi
        if grep -qE '^##+ .*\[(OPEN|IN PROGRESS|BLOCKED|DEFERRED|SHIPPED|VERIFIED|WON.T)' "$f"; then
            printf '%s\n' "$f"
        fi
    done
