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

print_help() {
  sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --before) BEFORE_REF="$2"; shift 2 ;;
    --before-file) BEFORE_FILE="$2"; shift 2 ;;
    --after-file) AFTER_FILE="$2"; shift 2 ;;
    --assert-review) MODE="assert-review"; ASSERT_REVIEW_FILE="$2"; shift 2 ;;
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

    # [SHIPPED] transitions require a Batch Log reference in some phase file
    if [ "$after_status" = "[SHIPPED]" ] && [ "$before_status" != "[SHIPPED]" ]; then
      if ! grep -lE "\b${p}\b" docs/build-plans/phase-*.md >/dev/null 2>&1; then
        echo "BLOCK: $p shipped but no Batch Log reference found in docs/build-plans/phase-*.md"
        violations=$((violations + 1))
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
