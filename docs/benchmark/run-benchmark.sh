#!/usr/bin/env bash
# Agent SOP Benchmark Runner
# Sets up isolated worktrees in hst-tracker for A/B testing SOP vs no-SOP agents.
#
# Usage:
#   bash run-benchmark.sh setup              # Create all worktrees
#   bash run-benchmark.sh run <task-number>   # Print prompts for one task pair
#   bash run-benchmark.sh run-all             # Print prompts for all tasks
#   bash run-benchmark.sh score <task-number> # Print blind scoring prompt
#   bash run-benchmark.sh cleanup             # Remove all worktrees and branches

set -euo pipefail

HST_REPO="${HST_REPO:-$HOME/Projects/hst-tracker}"
BENCH_DIR="$(cd "$(dirname "$0")" && pwd)"
TASKS_DIR="$BENCH_DIR/tasks"
RESULTS_DIR="$BENCH_DIR/results"
TASK_COUNT="${BENCH_TASK_COUNT:-4}"
TASK_OFFSET="${BENCH_TASK_OFFSET:-1}"  # First task number (1 for round 1, 5 for round 2)

# ── Colours ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[bench]${NC} $*"; }
warn() { echo -e "${YELLOW}[bench]${NC} $*"; }
err()  { echo -e "${RED}[bench]${NC} $*" >&2; }

# ── Helpers ──

check_repo() {
  if [ ! -d "$HST_REPO/.git" ]; then
    err "hst-tracker not found at $HST_REPO"
    err "Set HST_REPO env var to the correct path"
    exit 1
  fi
}

get_base_commit() {
  git -C "$HST_REPO" rev-parse HEAD
}

# ── Commands ──

cmd_setup() {
  check_repo
  local base_commit
  base_commit=$(get_base_commit)
  log "Base commit: $base_commit"
  log "Creating worktrees..."

  for i in $(seq $TASK_OFFSET $((TASK_OFFSET + TASK_COUNT - 1))); do
    local sop_branch="bench/sop-task-$i"
    local nosop_branch="bench/nosop-task-$i"
    local sop_dir="$HST_REPO/.worktrees/bench-sop-task-$i"
    local nosop_dir="$HST_REPO/.worktrees/bench-nosop-task-$i"

    # SOP worktree (full context, unchanged)
    if [ -d "$sop_dir" ]; then
      warn "Worktree $sop_dir already exists, skipping"
    else
      git -C "$HST_REPO" worktree add -b "$sop_branch" "$sop_dir" "$base_commit" 2>/dev/null || \
        git -C "$HST_REPO" worktree add "$sop_dir" "$sop_branch" 2>/dev/null
      log "Created SOP worktree: $sop_dir"
    fi

    # Baseline worktree (SOP stripped)
    if [ -d "$nosop_dir" ]; then
      warn "Worktree $nosop_dir already exists, skipping"
    else
      git -C "$HST_REPO" worktree add -b "$nosop_branch" "$nosop_dir" "$base_commit" 2>/dev/null || \
        git -C "$HST_REPO" worktree add "$nosop_dir" "$nosop_branch" 2>/dev/null
      strip_sop "$nosop_dir"
      log "Created baseline worktree: $nosop_dir (SOP stripped)"
    fi
  done

  log ""
  log "Setup complete. $((TASK_COUNT * 2)) worktrees created."
  log "Base commit: $base_commit"
  log ""
  log "Next: run 'bash run-benchmark.sh run <task-number>' to get execution prompts"
}

strip_sop() {
  local dir="$1"

  # Replace CLAUDE.md with minimal stack-only stub
  cat > "$dir/CLAUDE.md" << 'STUB'
# LOADOUT

- Frontend: React 19, Vite — client/
- Backend: Express 5, Prisma ORM, PostgreSQL 17 — server/
- Tests: npm test (Jest server, Vitest client)
- Schema: server/prisma/schema.prisma
STUB

  # Remove SOP docs
  rm -rf "$dir/docs/sop" 2>/dev/null || true
  rm -f "$dir/docs/agent-memory.md" 2>/dev/null || true

  # Remove agent definitions and brand voice
  rm -rf "$dir/.claude/agents" 2>/dev/null || true
  rm -f "$dir/.claude/brand-voice.md" 2>/dev/null || true
  rm -f "$dir/.claude/style-guide.md" 2>/dev/null || true
  rm -f "$dir/.claude/style-guide-v1.md" 2>/dev/null || true

  # Remove slash commands
  rm -rf "$dir/.claude/commands" 2>/dev/null || true

  # Remove skills
  rm -rf "$dir/.claude/skills" 2>/dev/null || true

  # Commit the strip so the worktree is clean
  git -C "$dir" add -A
  git -C "$dir" commit -m "bench: strip SOP context for baseline condition" --allow-empty 2>/dev/null || true
}

cmd_run() {
  local task_num="${1:-}"
  if [ -z "$task_num" ]; then
    err "Usage: run-benchmark.sh run <task-number>"
    exit 1
  fi

  check_repo
  local sop_dir="$HST_REPO/.worktrees/bench-sop-task-$task_num"
  local nosop_dir="$HST_REPO/.worktrees/bench-nosop-task-$task_num"

  if [ ! -d "$sop_dir" ] || [ ! -d "$nosop_dir" ]; then
    err "Worktrees not found. Run 'bash run-benchmark.sh setup' first."
    exit 1
  fi

  # Read task prompt
  local task_file="$TASKS_DIR/task-0${task_num}-*.md"
  task_file=$(ls $task_file 2>/dev/null | head -1)
  if [ -z "$task_file" ]; then
    err "Task file not found for task $task_num"
    exit 1
  fi

  # Extract the prompt section
  local prompt
  prompt=$(sed -n '/^## Prompt/,/^## Acceptance/p' "$task_file" | sed '1d;$d' | sed 's/^> //')

  echo ""
  echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
  echo -e "${CYAN}  TASK $task_num — $(basename "$task_file" .md)${NC}"
  echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
  echo ""
  echo -e "${GREEN}SOP worktree:${NC}     $sop_dir"
  echo -e "${YELLOW}Baseline worktree:${NC} $nosop_dir"
  echo ""
  echo -e "To run both conditions, open two terminals and start Claude Code:"
  echo ""
  echo -e "${GREEN}Terminal 1 (SOP):${NC}"
  echo "  cd $sop_dir && claude"
  echo ""
  echo -e "${YELLOW}Terminal 2 (Baseline):${NC}"
  echo "  cd $nosop_dir && claude"
  echo ""
  echo -e "Paste this prompt into both sessions:"
  echo ""
  echo "────────────────────────────────────────"
  echo "$prompt"
  echo "────────────────────────────────────────"
  echo ""
  echo "After both complete, run: bash run-benchmark.sh score $task_num"
  echo ""
}

cmd_run_all() {
  for i in $(seq $TASK_OFFSET $((TASK_OFFSET + TASK_COUNT - 1))); do
    cmd_run "$i"
  done
}

cmd_score() {
  local task_num="${1:-}"
  if [ -z "$task_num" ]; then
    err "Usage: run-benchmark.sh score <task-number>"
    exit 1
  fi

  check_repo
  local sop_dir="$HST_REPO/.worktrees/bench-sop-task-$task_num"
  local nosop_dir="$HST_REPO/.worktrees/bench-nosop-task-$task_num"

  echo ""
  echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
  echo -e "${CYAN}  SCORING TASK $task_num (blind review)${NC}"
  echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
  echo ""
  echo "Launch Claude Code in the hst-tracker repo and paste this prompt:"
  echo ""
  echo "────────────────────────────────────────"
  cat << SCORE_PROMPT
I need a blind code review comparing two implementations of the same task. Do not try to determine which is "better" overall until you have scored each dimension independently.

**Submission A** is at: $sop_dir
**Submission B** is at: $nosop_dir

Steps:
1. Read the task spec at: $(ls "$TASKS_DIR/task-0${task_num}-"*.md 2>/dev/null | head -1)
2. For each submission, run \`git diff HEAD~1\` in the worktree to see what changed
3. Run \`npm run test:client\` (or test:server) in each worktree to verify tests pass
4. Score each submission on these 7 dimensions (0-3 scale):
   - Correctness: Do tests pass? Any regressions?
   - Pattern consistency: Does the code match existing project conventions?
   - Completeness: Are all acceptance criteria met?
   - Code quality: Clean, idiomatic, well-structured?
   - File hygiene: Only necessary files modified?
   - Context awareness: Did the agent understand and reuse existing code?
   - Efficiency: (Note any observations about approach directness)
5. Output a markdown table with scores for A and B
6. Note qualitative differences
7. Save the result to: $(pwd)/docs/benchmark/results/task-${task_num}-result.md
SCORE_PROMPT
  echo "────────────────────────────────────────"
  echo ""
}

cmd_cleanup() {
  check_repo
  log "Removing benchmark worktrees..."

  for i in $(seq $TASK_OFFSET $((TASK_OFFSET + TASK_COUNT - 1))); do
    for condition in sop nosop; do
      local wt_dir="$HST_REPO/.worktrees/bench-${condition}-task-$i"
      local branch="bench/${condition}-task-$i"
      if [ -d "$wt_dir" ]; then
        git -C "$HST_REPO" worktree remove "$wt_dir" --force 2>/dev/null || true
        log "Removed worktree: $wt_dir"
      fi
      git -C "$HST_REPO" branch -D "$branch" 2>/dev/null || true
    done
  done

  log "Cleanup complete."
}

# ── Main ──

case "${1:-}" in
  setup)    cmd_setup ;;
  run)      cmd_run "${2:-}" ;;
  run-all)  cmd_run_all ;;
  score)    cmd_score "${2:-}" ;;
  cleanup)  cmd_cleanup ;;
  *)
    echo "Agent SOP Benchmark Runner"
    echo ""
    echo "Usage:"
    echo "  bash run-benchmark.sh setup              Create worktrees"
    echo "  bash run-benchmark.sh run <task-number>   Show prompts for a task"
    echo "  bash run-benchmark.sh run-all             Show prompts for all tasks"
    echo "  bash run-benchmark.sh score <task-number> Show scoring prompt"
    echo "  bash run-benchmark.sh cleanup             Remove worktrees"
    ;;
esac
