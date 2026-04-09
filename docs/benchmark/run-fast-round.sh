#!/usr/bin/env bash
# Fast benchmark round cleanup
# Removes all worktrees and branches for a completed round.
# Usage: bash run-fast-round.sh cleanup

set -euo pipefail
HST="${HST_REPO:-$HOME/Projects/hst-tracker}"

cleanup() {
  echo "[bench] Cleaning up all fast benchmark worktrees..."
  cd "$HST"
  for wt in .worktrees/bench-fast-*; do
    [ -d "$wt" ] && git worktree remove "$wt" --force 2>/dev/null && echo "  Removed: $wt"
  done
  git worktree prune
  for br in $(git branch | grep 'bench/fast-' | tr -d ' *'); do
    git branch -D "$br" 2>/dev/null && echo "  Deleted branch: $br"
  done
  # Also clean the base branch
  git branch -D bench/fast-base 2>/dev/null && echo "  Deleted branch: bench/fast-base"
  echo "[bench] Cleanup complete. No benchmark artifacts remain."
}

case "${1:-}" in
  cleanup) cleanup ;;
  *) echo "Usage: bash run-fast-round.sh cleanup" ;;
esac
