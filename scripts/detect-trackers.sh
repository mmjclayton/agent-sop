#!/usr/bin/env bash
#
# List this project's secondary tracker files.
#
# A secondary tracker is any `.md` path named in CLAUDE.md's Key Documents &
# Dispatch table whose headings carry a Backlog-style status tag — audit
# findings, security scans, compliance checklists, migration punch-lists.
# `Backlog.md` itself is excluded; Step 3 covers it.
#
# Emits one bare path per line. Empty output means the project has no secondary
# trackers, which is a normal state and exits 0 — not an error.
#
# Usage:
#   bash scripts/detect-trackers.sh [claude-md-path]
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

CLAUDE_MD="${1:-CLAUDE.md}"

# No CLAUDE.md is a legal state for a freshly scaffolded project.
[ -f "$CLAUDE_MD" ] || exit 0

# `|| true`: CLAUDE.md containing no backticked `.md` paths is legal, and a bare
# grep exit 1 would propagate under `set -o pipefail` and kill the caller.
{ grep -oE '`[^`]+\.md`' "$CLAUDE_MD" 2>/dev/null || true; } \
  | tr -d '`' \
  | sort -u \
  | while read -r f; do
        if [ "$f" = "Backlog.md" ]; then continue; fi
        if [ ! -f "$f" ]; then continue; fi
        if grep -qE '^##+ .*\[(OPEN|IN PROGRESS|BLOCKED|DEFERRED|SHIPPED|VERIFIED|WON.T)' "$f"; then
            printf '%s\n' "$f"
        fi
    done
