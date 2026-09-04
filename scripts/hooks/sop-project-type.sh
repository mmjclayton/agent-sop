#!/usr/bin/env bash
#
# sop-project-type.sh [root] — prints "code" or "non-code" for the repository
# at root (default: the git toplevel of the current directory). Exit 0 always.
#
# The executable form of one rule, `sop_project_type` in sop-lib.sh, so that
# /update-sop, /restart-sop, /finish, /ship and the compliance checker ask the
# same question the hooks answer and cannot drift from them. An explicit
# `**Project type:** code|non-code` line in CLAUDE.md wins; otherwise the four
# heuristics in docs/sop/compliance-checklist.md § Code vs Non-Code Detection.
#
# Installed user-scope by scripts/install-hooks.sh next to the hooks:
#   bash ~/.claude/scripts/hooks/agent-sop/sop-project-type.sh

set -u
. "$(dirname "${BASH_SOURCE[0]}")/sop-lib.sh"

ROOT="${1:-}"
if [ -z "$ROOT" ]; then
    ROOT=$(sop_repo_root "$PWD")
    [ -n "$ROOT" ] || ROOT="$PWD"
fi
sop_project_type "$ROOT"
printf '\n'
exit 0
