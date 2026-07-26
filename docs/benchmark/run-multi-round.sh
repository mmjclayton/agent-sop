#!/usr/bin/env bash
# Multi-round benchmark helper
# Creates worktrees with round-specific branch names.
#
# Usage:
#   bash run-multi-round.sh setup <round> [-k N] [--lite|--tasks "5 7 8"]
#   bash run-multi-round.sh cleanup <round>
#   bash run-multi-round.sh cleanup-all
#   bash run-multi-round.sh aggregate <scores.tsv>
#
# Options:
#   -k N            Runs per task per arm (default 1). The benchmark README
#                   requires k>=3, and k>=5 for any figure that gets published.
#   --lite          Use the frozen lite subset (tasks 5, 7, 8) instead of the
#                   full set. Membership is frozen — changing it invalidates
#                   comparison across SOP versions.
#   --tasks "A B C" Explicit task list. Overrides --lite.
#
# Environment:
#   HST_REPO            Target repo (default ~/Projects/hst-tracker)
#   BENCH_BASE_COMMIT   Pinned base commit
#   TASKS               Space-separated default task list
#
# P72: before 2026-07-26 this script hardcoded TASKS=(5 6 7 8) and had no
# repetition parameter, so the README's k>=3 rule and frozen lite subset were
# both unexecutable. That is why the lite-run rule shipped as SHOULD.

set -euo pipefail

HST_REPO="${HST_REPO:-$HOME/Projects/hst-tracker}"
# Base commit: has sharpened CLAUDE.md but BEFORE any benchmark features were implemented
BASE_COMMIT="${BENCH_BASE_COMMIT:-76b3b77}"

# Frozen lite subset. See docs/benchmark/README.md "Frozen lite subset".
LITE_TASKS=(5 7 8)
DEFAULT_TASKS=(5 6 7 8)

# shellcheck disable=SC2206
if [ -n "${TASKS:-}" ]; then TASK_LIST=($TASKS); else TASK_LIST=("${DEFAULT_TASKS[@]}"); fi
RUNS=1

log()  { echo -e "\033[0;32m[bench]\033[0m $*"; }
warn() { echo -e "\033[0;33m[bench]\033[0m $*" >&2; }

parse_opts() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -k) RUNS="${2:?-k needs a value}"; shift 2 ;;
      --lite) TASK_LIST=("${LITE_TASKS[@]}"); shift ;;
      # shellcheck disable=SC2206
      --tasks) TASK_LIST=(${2:?--tasks needs a value}); shift 2 ;;
      *) shift ;;
    esac
  done
  case "$RUNS" in
    ''|*[!0-9]*) echo "ERROR: -k must be a positive integer, got '$RUNS'" >&2; exit 2 ;;
  esac
  [ "$RUNS" -lt 1 ] && { echo "ERROR: -k must be >= 1" >&2; exit 2; }
  if [ "$RUNS" -lt 3 ]; then
    warn "k=$RUNS. The benchmark README requires k>=3 (k>=5 to publish) — a single run"
    warn "misranks arms ~29.3% of the time (arXiv:2602.11619). Proceeding anyway."
  fi
}

wt_path() { echo "$HST_REPO/.worktrees/bench-r${1}-run${2}-${3}-task-${4}"; }
br_name() { echo "bench/r${1}-run${2}-${3}-${4}"; }

setup_round() {
  local round="$1"
  log "Round $round — base $BASE_COMMIT (pinned), tasks: ${TASK_LIST[*]}, k=$RUNS"

  for task in "${TASK_LIST[@]}"; do
    for run in $(seq 1 "$RUNS"); do
      for cond in sop nosop; do
        local branch wt_dir
        branch=$(br_name "$round" "$run" "$cond" "$task")
        wt_dir=$(wt_path "$round" "$run" "$cond" "$task")

        if [ -d "$wt_dir" ]; then
          log "  exists, skipping: $wt_dir"
          continue
        fi

        git -C "$HST_REPO" worktree add -b "$branch" "$wt_dir" "$BASE_COMMIT" 2>/dev/null

        if [ "$cond" = "nosop" ]; then
          cat > "$wt_dir/CLAUDE.md" << 'STUB'
# LOADOUT

- Frontend: React 19, Vite — client/
- Backend: Express 5, Prisma ORM, PostgreSQL 17 — server/
- Tests: npm test (Jest server, Vitest client)
- Schema: server/prisma/schema.prisma
STUB
          rm -rf "$wt_dir/docs/sop" "$wt_dir/.claude/agents" "$wt_dir/.claude/commands" "$wt_dir/.claude/skills" 2>/dev/null || true
          rm -f "$wt_dir/docs/agent-memory.md" "$wt_dir/.claude/brand-voice.md" "$wt_dir/.claude/style-guide.md" "$wt_dir/.claude/style-guide-v1.md" 2>/dev/null || true
          git -C "$wt_dir" add -A && git -C "$wt_dir" commit -m "bench: strip SOP for baseline r${round} run${run}" --allow-empty 2>/dev/null || true
        fi

        log "  created: $wt_dir"
      done
    done
  done
  local total=$(( ${#TASK_LIST[@]} * RUNS * 2 ))
  log "Round $round setup complete — $total worktrees (${#TASK_LIST[@]} tasks x $RUNS runs x 2 arms)."
  log "Record scores as TSV: round<TAB>task<TAB>cond<TAB>run<TAB>score, then: run-multi-round.sh aggregate <file>"
}

cleanup_round() {
  local round="$1"
  log "Cleaning up round $round..."
  # Removes both the run-indexed layout and the pre-P72 flat layout, so rounds
  # created by the older script still clean up.
  for wt in "$HST_REPO"/.worktrees/bench-r"${round}"-*; do
    [ -d "$wt" ] || continue
    git -C "$HST_REPO" worktree remove "$wt" --force 2>/dev/null || true
  done
  git -C "$HST_REPO" worktree prune 2>/dev/null || true
  local branches
  branches=$( { git -C "$HST_REPO" branch --list "bench/r${round}-*" || true; } | tr -d ' *')
  for br in $branches; do
    [ -n "$br" ] && git -C "$HST_REPO" branch -D "$br" 2>/dev/null || true
  done
  log "Round $round cleaned."
}

cleanup_all() {
  for round in $(seq 1 20); do
    cleanup_round "$round" >/dev/null 2>&1 || true
  done
  log "All benchmark worktrees cleaned."
}

# Aggregate scores across runs. Input TSV, one row per run:
#   round<TAB>task<TAB>cond<TAB>run<TAB>score
# Emits median and range per task per arm, then the SOP-vs-baseline delta on
# medians. Median, not mean: with k=3 a single crashed run would drag a mean
# somewhere no individual run ever was.
aggregate() {
  local f="${1:?Usage: run-multi-round.sh aggregate <scores.tsv>}"
  [ -f "$f" ] || { echo "ERROR: no such file: $f" >&2; exit 2; }
  awk -F'\t' '
    # Round is part of the key, not decoration. Pooling rounds averages away
    # the thing a round measures: rounds 5 and 6 with opposite decisive results
    # (10/90 then 90/10) used to collapse to median 50 on both arms, delta
    # +0.00, "RANGES OVERLAP" — reporting a wash where there were two clear and
    # contradictory results. Found by the P66-P73 review; the original test only
    # ever used a single round, so it never exercised this.
    #
    # (round, task, arm, run) is also asserted unique: duplicated rows used to
    # inflate k, and k is the exact quantity the README gates publication on.
    /^[[:space:]]*(#|$)/ { next }
    NR==1 && $1 ~ /^[Rr]ound$/ { next }              # tolerate a bare header row
    NF < 5 { bad++; next }
    $5 !~ /^-?[0-9]+(\.[0-9]+)?$/ { bad++; next }    # non-numeric score
    {
      dk=$1 SUBSEP $2 SUBSEP $3 SUBSEP $4
      if (dk in seen) { dup++; next }
      seen[dk]=1
      key=$1 SUBSEP $2 SUBSEP $3
      n[key]++; v[key,n[key]]=$5+0
      rounds[$1]=1; tasks[$2]=1; pair[$1 SUBSEP $2]=1
    }
    END {
      if (bad) printf "warning: %d malformed row(s) skipped (need 5 tab-separated fields, numeric score)\n", bad
      if (dup) printf "warning: %d duplicate (round,task,arm,run) row(s) skipped — k reflects distinct runs only\n", dup
      if (bad || dup) print ""
      printf "%-6s %-6s %-7s %3s %8s %8s %8s\n", "round", "task", "arm", "k", "median", "min", "max"
      nr=0; for (r in rounds) rlist[++nr]=r
      for (i=1;i<=nr;i++) for (j=i+1;j<=nr;j++) if (rlist[j]<rlist[i]) { t0=rlist[i]; rlist[i]=rlist[j]; rlist[j]=t0 }
      nt=0; for (t in tasks) tlist[++nt]=t
      for (i=1;i<=nt;i++) for (j=i+1;j<=nt;j++) if (tlist[j]<tlist[i]) { t0=tlist[i]; tlist[i]=tlist[j]; tlist[j]=t0 }
      split("sop nosop", carr, " ")
      for (ri=1; ri<=nr; ri++) for (ti=1; ti<=nt; ti++) for (ci=1; ci<=2; ci++) {
        r=rlist[ri]; t=tlist[ti]; c=carr[ci]
        key=r SUBSEP t SUBSEP c; k=n[key]; if (!k) continue
        for (i=1;i<=k;i++) for (j=i+1;j<=k;j++) if (v[key,j]<v[key,i]) { tmp=v[key,i]; v[key,i]=v[key,j]; v[key,j]=tmp }
        med = (k%2) ? v[key,(k+1)/2] : (v[key,k/2]+v[key,k/2+1])/2
        printf "%-6s %-6s %-7s %3d %8.2f %8.2f %8.2f\n", r, t, c, k, med, v[key,1], v[key,k]
        M[r,t,c]=med; K[r,t,c]=k; LO[r,t,c]=v[key,1]; HI[r,t,c]=v[key,k]
      }
      print ""
      print "delta on medians (sop - nosop), per round:"
      any=0
      for (ri=1; ri<=nr; ri++) for (ti=1; ti<=nt; ti++) {
        r=rlist[ri]; t=tlist[ti]
        if (!((r,t,"sop") in M) || !((r,t,"nosop") in M)) continue
        any=1
        d = M[r,t,"sop"] - M[r,t,"nosop"]
        overlap = (LO[r,t,"sop"] <= HI[r,t,"nosop"] && LO[r,t,"nosop"] <= HI[r,t,"sop"]) ? "  RANGES OVERLAP — not separable at this k" : ""
        printf "  round %-4s task %-4s %+8.2f  (k=%d/%d)%s\n", r, t, d, K[r,t,"sop"], K[r,t,"nosop"], overlap
        if (K[r,t,"sop"] < 3 || K[r,t,"nosop"] < 3) printf "                            k<3 — below the README minimum, indicative only\n"
      }
      if (!any) print "  (no task has both arms present)"
      if (nr > 1) {
        print ""
        printf "%d rounds present. Rounds are reported separately and never pooled —\n", nr
        print "a round is a measurement, and averaging two of them hides disagreement"
        print "rather than resolving it. Compare rounds by reading the rows above."
      }
    }
  ' "$f"
}

case "${1:-}" in
  setup)
    round="${2:?Usage: run-multi-round.sh setup <round> [-k N] [--lite]}"
    shift 2; parse_opts "$@"; setup_round "$round" ;;
  cleanup)     cleanup_round "${2:?Usage: run-multi-round.sh cleanup <round>}" ;;
  cleanup-all) cleanup_all ;;
  aggregate)   aggregate "${2:-}" ;;
  *) echo "Usage: bash run-multi-round.sh {setup <round> [-k N] [--lite|--tasks \"5 7 8\"]|cleanup <round>|cleanup-all|aggregate <scores.tsv>}" ;;
esac
