#!/usr/bin/env bash
#
# Validate Backlog.md state-tag transitions against the allowed graph.
#
# Runs at /update-sop Step 2c. Rejects illegal transitions like [OPEN] →
# [SHIPPED] with no [IN PROGRESS] intermediate, terminal-state revivals,
# and [SHIPPED] entries with no matching Batch Log reference. Exit code:
# 0 if all transitions legal, 1 if any illegal.
#
# Usage:
#   bash scripts/validate-state-transitions.sh
#     Default: compares HEAD's Backlog.md against working tree. Validates
#     exactly the changes /update-sop is about to commit. No-ops when there
#     is no working-tree diff (nothing to validate).
#
#   bash scripts/validate-state-transitions.sh --before <ref>
#     Compares working-tree Backlog.md against <ref>:Backlog.md. Use with
#     merge-base to replay a whole session's transitions.
#
#   bash scripts/validate-state-transitions.sh --before-file <path> --after-file <path>
#     Fixture mode — no git required. Used by the test harness.
#
#   bash scripts/validate-state-transitions.sh --assert-review <path>
#     P44 substance-assertion helper. Checks a review artifact file has
#     the three required sections (diff summary, severity, finding).
#
# Zero-dependency bash 3.2 (macOS default). No associative arrays.

set -euo pipefail

MODE="validate"
BEFORE_REF=""
BEFORE_FILE=""
AFTER_FILE="Backlog.md"
TRACKED_PATH="Backlog.md"   # path used with `git show <ref>:<path>`
ASSERT_REVIEW_FILE=""
DRIFT_RESUME_FILE=""        # override for --check-drift fixture mode
DRIFT_COMMITS_FILE=""       # override: file with commit messages (P-numbers extracted via grep)
DRIFT_SESSION_LOC=""        # fixture: set the session LOC count directly
DRIFT_SESSION_FILES=""      # fixture: set the session files count directly
DRIFT_THRESHOLD_LOC=""      # override the LOC threshold (skip config lookup)
DRIFT_THRESHOLD_FILES=""    # override the files threshold (skip config lookup)

print_help() {
  sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --before) BEFORE_REF="$2"; shift 2 ;;
    --before-file) BEFORE_FILE="$2"; shift 2 ;;
    --after-file) AFTER_FILE="$2"; shift 2 ;;
    --assert-review) MODE="assert-review"; ASSERT_REVIEW_FILE="$2"; shift 2 ;;
    --check-drift) MODE="check-drift"; shift ;;
    --drift-resume-file) DRIFT_RESUME_FILE="$2"; shift 2 ;;
    --drift-commits-file) DRIFT_COMMITS_FILE="$2"; shift 2 ;;
    --drift-session-loc) DRIFT_SESSION_LOC="$2"; shift 2 ;;
    --drift-session-files) DRIFT_SESSION_FILES="$2"; shift 2 ;;
    --drift-threshold-loc) DRIFT_THRESHOLD_LOC="$2"; shift 2 ;;
    --drift-threshold-files) DRIFT_THRESHOLD_FILES="$2"; shift 2 ;;
    -h|--help) print_help; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

# ---------------------------------------------------------------------------
# --assert-review: P44 substance-assertion helper
# ---------------------------------------------------------------------------
if [ "$MODE" = "assert-review" ]; then
  if [ -z "$ASSERT_REVIEW_FILE" ] || [ ! -f "$ASSERT_REVIEW_FILE" ]; then
    echo "BLOCK: review artifact not found: $ASSERT_REVIEW_FILE" >&2
    exit 1
  fi

  missing=""

  # 1. Diff summary — match any of: "## Summary", "## Diff summary", "Diff summary:"
  if ! grep -qiE '^(##+ .*summary|diff summary:)' "$ASSERT_REVIEW_FILE"; then
    missing="$missing diff-summary-section"
  fi

  # 2. Severity line — must have a value from the enum
  if ! grep -qE '[Ss]everity:[[:space:]]*(CRITICAL|HIGH|MEDIUM|LOW|NONE)\b' "$ASSERT_REVIEW_FILE"; then
    missing="$missing severity-line"
  fi

  # 3. At least one concrete finding OR a reasoned no-issues statement.
  #    Accepts: a "Findings" section with any non-empty line beneath, OR
  #    a line matching "No issues — <at least one more word>".
  has_findings=0
  if grep -qiE '^##+[[:space:]]+findings?\b' "$ASSERT_REVIEW_FILE"; then
    # a Findings heading with *some* content beneath it (any non-empty line
    # before the next heading)
    if awk '
      tolower($0) ~ /^##+[[:space:]]+findings?([[:space:]]|$)/ { in_f=1; next }
      in_f && /^##+ / { in_f=0 }
      in_f && NF { found=1 }
      END { exit found ? 0 : 1 }
    ' "$ASSERT_REVIEW_FILE"; then
      has_findings=1
    fi
  fi
  if [ "$has_findings" = "0" ]; then
    # fallback: reasoned no-issues
    if grep -qiE 'no issues[[:space:]]*[—:-][[:space:]]*\S+[[:space:]]+\S+' "$ASSERT_REVIEW_FILE"; then
      has_findings=1
    fi
  fi
  [ "$has_findings" = "0" ] && missing="$missing concrete-finding-or-reasoned-no-issues"

  if [ -n "$missing" ]; then
    echo "BLOCK: review artifact $ASSERT_REVIEW_FILE missing:$missing" >&2
    echo "Required sections: diff summary heading, Severity: <enum>, Findings section or reasoned 'No issues — <reason>'." >&2
    exit 1
  fi
  exit 0
fi

# ---------------------------------------------------------------------------
# --check-drift: P46 mid-session drift detection
#
# Compares the P-numbers mentioned in project_resume_<agent-id>.md (declared
# in-flight work) against P-numbers referenced in session commits. If the
# session has non-trivial commits (over threshold) but none reference a
# declared P-number AND no ## Scope Change block exists in the resume file,
# hard-block — the agent drifted and hasn't declared it.
# ---------------------------------------------------------------------------
if [ "$MODE" = "check-drift" ]; then
  # Resolve resume file
  resume_file="$DRIFT_RESUME_FILE"
  if [ -z "$resume_file" ]; then
    # Find agent-id
    agent_id="${CLAUDE_AGENT_ID:-}"
    if [ -z "$agent_id" ]; then
      root=$(git rev-parse --show-toplevel 2>/dev/null) || root=""
      if [ -n "$root" ] && [ -f "$root/.sop-agent-id" ]; then
        agent_id=$(head -1 "$root/.sop-agent-id" | tr -d '[:space:]')
      else
        worktree_count=$(git worktree list 2>/dev/null | wc -l | tr -d '[:space:]')
        if [ "$worktree_count" = "1" ]; then
          agent_id="solo"
        elif [ -n "$root" ]; then
          if command -v shasum >/dev/null 2>&1; then
            agent_id=$(printf '%s' "$root" | shasum -a 256 | cut -c1-6)
          else
            agent_id=$(printf '%s' "$root" | sha256sum | cut -c1-6)
          fi
        fi
      fi
    fi
    [ -z "$agent_id" ] && agent_id="solo"
    # Locate project memory dir (derived from worktree path). Claude Code
    # normalises all non-alphanumeric path chars to hyphens, so matt_clayton
    # becomes matt-clayton. Collapse consecutive hyphens so `My__Projects`
    # matches the observed single-hyphen naming convention.
    if [ -n "$root" ]; then
      project_hash=$(printf '%s' "$root" | sed 's|[^a-zA-Z0-9-]|-|g' | sed 's|--*|-|g' | sed 's|^-||')
      resume_file="$HOME/.claude/projects/-$project_hash/memory/project_resume_${agent_id}.md"
      # Fallback: legacy unsuffixed path when agent-id=solo
      if [ ! -f "$resume_file" ] && [ "$agent_id" = "solo" ]; then
        resume_file="$HOME/.claude/projects/-$project_hash/memory/project_resume.md"
      fi
    fi
  fi

  if [ -z "$resume_file" ] || [ ! -f "$resume_file" ]; then
    echo "check-drift: no project_resume file found — skipping (first session, or fresh repo)"
    exit 0
  fi

  # Collect session commits + diff size.
  #
  # Two critical invariants:
  #   a) commit_pnums and (loc, files) MUST come from the same range — either
  #      both committed-only or both including working tree. Mixing causes
  #      false-positives when an agent has large uncommitted work mid-session
  #      (large loc, empty commit list → false drift block). We use
  #      committed-only (`base..HEAD`) so both measurements match.
  #   b) Fixture mode uses explicit session-size overrides so harness tests
  #      can exercise the threshold-skip branch without a real git history.
  commit_pnums=""
  if [ -n "$DRIFT_COMMITS_FILE" ]; then
    commit_pnums=$(grep -oE '\bP[0-9]+\b' "$DRIFT_COMMITS_FILE" | sort -u)
    loc="${DRIFT_SESSION_LOC:-0}"
    files="${DRIFT_SESSION_FILES:-0}"
  else
    # Real mode: derive from git
    default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/@@') || true
    if [ -z "$default_branch" ]; then
      for candidate in origin/main origin/master origin/develop; do
        if git rev-parse --verify "$candidate" >/dev/null 2>&1; then
          default_branch="$candidate"
          break
        fi
      done
    fi
    if [ -z "$default_branch" ]; then
      echo "check-drift: no default branch — skipping"
      exit 0
    fi
    base=$(git merge-base "$default_branch" HEAD 2>/dev/null) || {
      echo "check-drift: no merge-base with $default_branch — skipping"
      exit 0
    }
    head_sha=$(git rev-parse HEAD 2>/dev/null)
    # No committed divergence AND no working-tree changes = nothing to check
    if [ "$base" = "$head_sha" ] && git diff --quiet HEAD 2>/dev/null; then
      echo "check-drift: no session commits or working-tree changes — skipping"
      exit 0
    fi
    # When there are no committed commits yet (everything still uncommitted),
    # skip drift detection — `/update-sop` Step 10 hasn't run. The next
    # invocation after commit will catch drift from the committed state.
    if [ "$base" = "$head_sha" ]; then
      echo "check-drift: no session commits yet — skipping until after first commit"
      exit 0
    fi
    commit_pnums=$(git log "${base}..HEAD" --format='%s%n%b' 2>/dev/null | grep -oE '\bP[0-9]+\b' | sort -u)
    # Measure diff over the committed range only — stays consistent with
    # commit_pnums so uncommitted work doesn't trigger a false-positive.
    loc=$(git diff --numstat "${base}..HEAD" -- 2>/dev/null | awk '{a+=$1; d+=$2} END{print a+d+0}')
    files=$(git diff --numstat "${base}..HEAD" -- 2>/dev/null | wc -l | tr -d ' ')
    [ -z "$loc" ] && loc=0
  fi

  # Thresholds: override flags win; otherwise read from config; otherwise defaults.
  threshold_loc="${DRIFT_THRESHOLD_LOC:-}"
  threshold_files="${DRIFT_THRESHOLD_FILES:-}"
  if [ -z "$threshold_loc" ] || [ -z "$threshold_files" ]; then
    config_file=""
    if [ -f ".claude/agent-sop.config.json" ]; then
      config_file=".claude/agent-sop.config.json"
    elif [ -f "$HOME/.claude/agent-sop.config.json" ]; then
      config_file="$HOME/.claude/agent-sop.config.json"
    fi
    if [ -n "$config_file" ]; then
      # `|| true` keeps pipefail + errexit from killing us when a field is
      # absent (grep exits 1 on no-match).
      [ -z "$threshold_loc" ] && threshold_loc=$( { grep -oE '"review_loc_threshold"[[:space:]]*:[[:space:]]*[0-9]+' "$config_file" 2>/dev/null || true; } | grep -oE '[0-9]+$' | head -1 || true)
      [ -z "$threshold_files" ] && threshold_files=$( { grep -oE '"review_files_threshold"[[:space:]]*:[[:space:]]*[0-9]+' "$config_file" 2>/dev/null || true; } | grep -oE '[0-9]+$' | head -1 || true)
    fi
    [ -z "$threshold_loc" ] && threshold_loc=50
    [ -z "$threshold_files" ] && threshold_files=3
  fi

  # Skip if BOTH dimensions under threshold. This IS the OR-fire semantics
  # P44 documents (either dimension over fires the check) — by De Morgan:
  #   fire iff (loc>=T_loc OR files>=T_files)
  #   skip iff NOT(...) = (loc<T_loc AND files<T_files)
  # A 200-LOC single-file change correctly fires (loc over, so OR is true).
  if [ "$loc" -lt "$threshold_loc" ] && [ "$files" -lt "$threshold_files" ]; then
    echo "check-drift: session under both thresholds (loc=$loc<$threshold_loc, files=$files<$threshold_files) — OK"
    exit 0
  fi

  # Extract P-numbers mentioned in the resume file. Wrap with || true so
  # pipefail+errexit don't kill us when the resume has no P-numbers (grep
  # exits 1 on no match, sort gets empty input — both legal states).
  resume_pnums=$( { grep -oE '\bP[0-9]+\b' "$resume_file" 2>/dev/null || true; } | sort -u)

  # Scope Change escape hatch — accept "Scope Change" or "Scope-Change",
  # case-insensitive. Matches intent over typography.
  if grep -qiE '^##+[[:space:]]+scope[[:space:]-]+change' "$resume_file"; then
    echo "check-drift: ## Scope Change block present in $resume_file — accepted as explicit redirection."
    exit 0
  fi

  if [ -z "$resume_pnums" ]; then
    echo "check-drift: no P-numbers declared in $resume_file — cannot establish baseline. Skipping."
    exit 0
  fi

  # Intersection: any resume P-number also in commit P-numbers?
  intersection=""
  for p in $resume_pnums; do
    if printf '%s\n' "$commit_pnums" | grep -qxF "$p"; then
      intersection="$intersection $p"
    fi
  done

  if [ -n "$intersection" ]; then
    echo "check-drift: OK — commits reference declared in-flight item(s):$intersection"
    exit 0
  fi

  # No match — hard-block
  echo "BLOCK: session drift detected." >&2
  echo "  Declared in-flight (project_resume):$(printf ' %s' $resume_pnums)" >&2
  if [ -n "$commit_pnums" ]; then
    echo "  Actual commit P-numbers:$(printf ' %s' $commit_pnums)" >&2
  else
    echo "  Commit messages reference no P-numbers." >&2
  fi
  echo "  Session diff: loc=$loc files=$files (thresholds: $threshold_loc / $threshold_files)" >&2
  echo "" >&2
  echo "Resolve by one of:" >&2
  echo "  1) If you changed scope deliberately: add a '## Scope Change' block to $resume_file with a one-line reason." >&2
  echo "  2) If you drifted unintentionally: amend the commit message(s) to reference the in-flight P-number, or split the work so the declared item ships." >&2
  echo "  3) If the prior resume file is stale: update it (Step 7 of /update-sop) and re-run." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Default: validate state transitions
# ---------------------------------------------------------------------------

# Extract (P-number, normalised-status) pairs from a Backlog file.
# Only matches items in the main "P-Numbered Items" section — the Shipped
# Archive uses bullet lines, not ### headings.
extract_statuses() {
  awk '
    /^### P[0-9]+/ {
      match($0, /P[0-9]+/)
      p = substr($0, RSTART, RLENGTH)
      next
    }
    p && /^`\[/ {
      line = $0
      gsub(/`/, "", line)
      if (match(line, /^\[[^]]+\]/)) {
        status = substr(line, RSTART, RLENGTH)
        # normalise: strip trailing " - ..." suffix inside the first bracket
        sub(/ +- +[^]]*\]$/, "]", status)
        print p "\t" status
      }
      p = ""
    }
  ' "$1"
}

# Is the transition from $1 to $2 legal? Returns 0 (legal) or 1 (illegal).
transition_is_legal() {
  local from="$1" to="$2"
  [ "$from" = "$to" ] && return 0   # no-op always legal

  if [ "$from" = "<absent>" ]; then
    case "$to" in
      "[OPEN]"|"[DEFERRED]"|"[IN PROGRESS]") return 0 ;;
      *) return 1 ;;
    esac
  fi

  case "$from" in
    "[OPEN]")
      case "$to" in "[IN PROGRESS]"|"[DEFERRED]"|"[SHIPPED]"|"[WON'T]") return 0 ;; esac
      ;;
    "[IN PROGRESS]")
      case "$to" in "[BLOCKED]"|"[DEFERRED]"|"[SHIPPED]"|"[WON'T]") return 0 ;; esac
      ;;
    "[BLOCKED]")
      case "$to" in "[IN PROGRESS]"|"[DEFERRED]"|"[SHIPPED]"|"[WON'T]") return 0 ;; esac
      ;;
    "[DEFERRED]")
      case "$to" in "[IN PROGRESS]"|"[SHIPPED]"|"[WON'T]"|"[BLOCKED]") return 0 ;; esac
      ;;
    "[SHIPPED]")
      case "$to" in "[VERIFIED]") return 0 ;; esac
      ;;
    "[VERIFIED]"|"[WON'T]")
      return 1   # terminal
      ;;
  esac
  return 1
}

legal_paths_from() {
  case "$1" in
    "<absent>") echo "[OPEN], [DEFERRED], [IN PROGRESS]" ;;
    "[OPEN]") echo "[IN PROGRESS], [DEFERRED], [SHIPPED] (needs Batch Log), [WON'T]" ;;
    "[IN PROGRESS]") echo "[BLOCKED], [DEFERRED], [SHIPPED] (needs Batch Log), [WON'T]" ;;
    "[BLOCKED]") echo "[IN PROGRESS], [DEFERRED], [SHIPPED] (needs Batch Log), [WON'T]" ;;
    "[DEFERRED]") echo "[IN PROGRESS], [SHIPPED] (needs Batch Log), [WON'T], [BLOCKED]" ;;
    "[SHIPPED]") echo "[VERIFIED]" ;;
    "[VERIFIED]"|"[WON'T]") echo "(terminal — revival requires new P-number)" ;;
  esac
}

# Resolve the before-state contents onto stdout. Empty output = skip validation.
#
# Default: compare HEAD's Backlog.md against working tree (what the current
# /update-sop invocation is about to finalise). Earlier commits in the session
# are assumed already validated by their own /update-sop runs, or can be
# revalidated with `--before <merge-base>` explicitly.
#
# Override precedence: --before-file > --before <ref> > HEAD (default).
resolve_before() {
  if [ -n "$BEFORE_FILE" ]; then
    [ -f "$BEFORE_FILE" ] && cat "$BEFORE_FILE"
    return
  fi
  local ref="${BEFORE_REF:-HEAD}"
  # Verify ref exists — else skip (fresh repo with no commits)
  git rev-parse --verify "${ref}" >/dev/null 2>&1 || return 0
  # Check whether there is any working-tree difference against the ref. If
  # not and ref=HEAD, skip (nothing to validate).
  if [ "$ref" = "HEAD" ] && git diff --quiet HEAD -- "$TRACKED_PATH" 2>/dev/null; then
    return 0
  fi
  git show "${ref}:${TRACKED_PATH}" 2>/dev/null || true
}

TMP_BEFORE=$(mktemp)
trap 'rm -f "$TMP_BEFORE"' EXIT

resolve_before > "$TMP_BEFORE"
if [ ! -s "$TMP_BEFORE" ]; then
  echo "validate-state-transitions: no before-state (on default branch or fresh repo). Skipping."
  exit 0
fi

if [ ! -f "$AFTER_FILE" ]; then
  echo "BLOCK: after-file not found: $AFTER_FILE" >&2
  exit 1
fi

BEFORE_STATES=$(extract_statuses "$TMP_BEFORE")
AFTER_STATES=$(extract_statuses "$AFTER_FILE")

violations=0
warnings=0

# Iterate every P-number in the after-state. P-numbers that disappear from
# after are ignored — removal isn't a legitimate transition (Rule 1), but
# the "never delete" rule is a separate concern covered by grep-based checks.
while IFS=$'\t' read -r p after_status; do
  [ -z "$p" ] && continue
  before_status=$(printf '%s\n' "$BEFORE_STATES" | awk -F'\t' -v p="$p" '$1 == p { print $2; exit }')
  [ -z "$before_status" ] && before_status="<absent>"

  if transition_is_legal "$before_status" "$after_status"; then
    # Soft warning: [BLOCKED] ↔ [DEFERRED] with no decision-file reference
    case "${before_status}->${after_status}" in
      "[BLOCKED]->[DEFERRED]"|"[DEFERRED]->[BLOCKED]")
        if [ -z "$BEFORE_FILE" ]; then
          # only check when we have a real git range (not fixture mode)
          range_ref="${BEFORE_REF:-}"
          if [ -z "$range_ref" ]; then
            range_ref=$(git merge-base HEAD @{upstream} 2>/dev/null || git merge-base HEAD origin/main 2>/dev/null || echo "")
          fi
          if [ -n "$range_ref" ]; then
            if ! git log "${range_ref}..HEAD" --name-only --format= 2>/dev/null | grep -qE "docs/agent-memory/decisions/.*${p}[^0-9]"; then
              echo "WARN: $p transitioned $before_status -> $after_status with no decision-file reference in commit range"
              warnings=$((warnings + 1))
            fi
          fi
        fi
        ;;
    esac

    # [SHIPPED] transitions require a Batch Log reference in some phase file.
    # For [Feature]/[Refactor] items over threshold, the Batch Log entry must
    # additionally cite a review artifact under docs/reviews/ — enforces P44's
    # reviewer-turn gate at the state-transition layer, not just by prose.
    if [ "$after_status" = "[SHIPPED]" ] && [ "$before_status" != "[SHIPPED]" ]; then
      batch_match=""
      batch_match=$(grep -lE "\b${p}\b" docs/build-plans/phase-*.md 2>/dev/null | head -1)
      if [ -z "$batch_match" ]; then
        echo "BLOCK: $p shipped but no Batch Log reference found in docs/build-plans/phase-*.md"
        violations=$((violations + 1))
      else
        # Determine whether this P-number is [Feature]/[Refactor]. If so,
        # require the Batch Log entry referencing the P-number to also name
        # a docs/reviews/ path.
        item_type=$(awk -v p="### ${p}" '
          $0 ~ "^"p"( |$)" { found=1; next }
          found && /^`\[/ {
            line=$0
            gsub(/`/, "", line)
            # strip the first bracket block (status) plus trailing whitespace
            sub(/^\[[^]]+\][[:space:]]*/, "", line)
            # extract the first bracket block from what remains (type tag)
            if (match(line, /^\[[^]]+\]/)) {
              type=substr(line, RSTART+1, RLENGTH-2)
              print type
            }
            exit
          }
        ' "$AFTER_FILE")
        case "$item_type" in
          "Feature"|"Refactor")
            # Find the batch-log line that names this P-number and check for a review path on it.
            batch_line=$(grep -E "\b${p}\b" "$batch_match" | head -1)
            if ! printf '%s' "$batch_line" | grep -qE 'docs/reviews/'; then
              echo "BLOCK: $p ([${item_type}]) shipped but Batch Log entry in ${batch_match} does not reference a docs/reviews/ artifact. P44 gate requires review path citation."
              echo "  Add the review artifact path to the Batch Log line that names ${p}."
              violations=$((violations + 1))
            fi
            ;;
        esac
      fi
    fi
  else
    echo "BLOCK: $p transitioned $before_status -> $after_status (illegal)"
    echo "  Legal outbound from $before_status: $(legal_paths_from "$before_status")"
    violations=$((violations + 1))
  fi
done <<EOF
$AFTER_STATES
EOF

if [ "$violations" -gt 0 ]; then
  echo ""
  echo "$violations illegal state transition(s). Fix Backlog.md before committing." >&2
  exit 1
fi
[ "$warnings" -gt 0 ] && echo "$warnings warning(s) — not blocking."
echo "validate-state-transitions: OK (${warnings} warnings)"
exit 0
