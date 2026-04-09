#!/usr/bin/env bash
# Multi-round benchmark helper
# Creates worktrees with round-specific branch names
#
# Usage:
#   bash run-multi-round.sh setup <round>     # Create worktrees for a round
#   bash run-multi-round.sh cleanup <round>   # Remove worktrees for a round
#   bash run-multi-round.sh cleanup-all       # Remove all benchmark worktrees

set -euo pipefail

HST_REPO="${HST_REPO:-$HOME/Projects/hst-tracker}"
# Base commit: has sharpened CLAUDE.md but BEFORE any benchmark features were implemented
BASE_COMMIT="${BENCH_BASE_COMMIT:-76b3b77}"
TASKS=(5 6 7 8)

log()  { echo -e "\033[0;32m[bench]\033[0m $*"; }

setup_round() {
  local round="$1"
  local base_commit="$BASE_COMMIT"
  log "Round $round — base commit: $base_commit (pinned)"

  for task in "${TASKS[@]}"; do
    for cond in sop nosop; do
      local branch="bench/r${round}-${cond}-${task}"
      local wt_dir="$HST_REPO/.worktrees/bench-r${round}-${cond}-task-${task}"

      if [ -d "$wt_dir" ]; then
        log "  $wt_dir already exists, skipping"
        continue
      fi

      git -C "$HST_REPO" worktree add -b "$branch" "$wt_dir" "$base_commit" 2>/dev/null

      if [ "$cond" = "nosop" ]; then
        # Strip SOP context
        cat > "$wt_dir/CLAUDE.md" << 'STUB'
# LOADOUT

- Frontend: React 19, Vite — client/
- Backend: Express 5, Prisma ORM, PostgreSQL 17 — server/
- Tests: npm test (Jest server, Vitest client)
- Schema: server/prisma/schema.prisma
STUB
        rm -rf "$wt_dir/docs/sop" "$wt_dir/.claude/agents" "$wt_dir/.claude/commands" "$wt_dir/.claude/skills" 2>/dev/null || true
        rm -f "$wt_dir/docs/agent-memory.md" "$wt_dir/.claude/brand-voice.md" "$wt_dir/.claude/style-guide.md" "$wt_dir/.claude/style-guide-v1.md" 2>/dev/null || true
        git -C "$wt_dir" add -A && git -C "$wt_dir" commit -m "bench: strip SOP for baseline r${round}" --allow-empty 2>/dev/null || true
      fi

      log "  Created: $wt_dir ($cond)"
    done
  done
  log "Round $round setup complete."
}

cleanup_round() {
  local round="$1"
  log "Cleaning up round $round..."
  for task in "${TASKS[@]}"; do
    for cond in sop nosop; do
      local wt_dir="$HST_REPO/.worktrees/bench-r${round}-${cond}-task-${task}"
      local branch="bench/r${round}-${cond}-${task}"
      if [ -d "$wt_dir" ]; then
        git -C "$HST_REPO" worktree remove "$wt_dir" --force 2>/dev/null || true
      fi
      git -C "$HST_REPO" branch -D "$branch" 2>/dev/null || true
    done
  done
  log "Round $round cleaned."
}

cleanup_all() {
  for round in $(seq 1 20); do
    cleanup_round "$round" 2>/dev/null
  done
  log "All benchmark worktrees cleaned."
}

case "${1:-}" in
  setup)    setup_round "${2:?Usage: run-multi-round.sh setup <round>}" ;;
  cleanup)  cleanup_round "${2:?Usage: run-multi-round.sh cleanup <round>}" ;;
  cleanup-all) cleanup_all ;;
  *) echo "Usage: bash run-multi-round.sh {setup|cleanup|cleanup-all} [round]" ;;
esac
