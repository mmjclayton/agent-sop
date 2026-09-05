#!/usr/bin/env bash
#
# Validate Backlog.md state-tag transitions against the allowed graph.
#
# Runs at /update-sop Step 2c. Rejects illegal transitions like [OPEN] →
# [SHIPPED] with no [IN PROGRESS] intermediate, terminal-state revivals,
# and [SHIPPED] Feature/Refactor entries with no review citation. Exit code:
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
#   bash scripts/validate-state-transitions.sh --check-replication
#     P75 replication gate. Intersects this session's changed files with the
#     baseline_shas manifest in agent-sop.config.json. For each hit under
#     .claude/, compares the repo file against its user-scope mirror — the
#     copy that actually executes. Upstream only, also reports stale baseline
#     SHAs. Silent no-op when the session touched no manifest file.
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
REPL_CONFIG_FILE=""         # override for --check-replication fixture mode
REPL_CHANGED_FILE=""        # fixture: file listing this session's changed paths
REPL_HOME=""                # fixture: stand-in for $HOME when resolving mirrors
SELF_MOD_CHANGED_FILE=""    # fixture: file listing changed paths for the review trigger (b) check

print_help() {
  # Print the leading comment block, stopping at the first non-comment line.
  # A hardcoded line range silently truncated (or over-ran into `set -euo
  # pipefail`) every time the usage text changed length.
  awk 'NR > 1 { if ($0 !~ /^#/) exit; sub(/^# ?/, ""); print }' "$0"
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
    --check-replication) MODE="check-replication"; shift ;;
    --repl-config-file) REPL_CONFIG_FILE="$2"; shift 2 ;;
    --repl-changed-file) REPL_CHANGED_FILE="$2"; shift 2 ;;
    --repl-home) REPL_HOME="$2"; shift 2 ;;
    --self-mod-changed-file) SELF_MOD_CHANGED_FILE="$2"; shift 2 ;;
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

  # 3. At least one concrete finding OR a reasoned no-issues statement,
  #    AND the finding/no-issues body must contain a concrete anchor — a
  #    file path with line number (`foo.ts:42`) or a backticked symbol/path
  #    (`processOrder`, `scripts/foo.sh`). Sycophancy gate (P55): reviews
  #    that pass structurally but cite nothing concrete are blocked here.
  #    Reasoning lives in claude-agent-sop.md §3 step 2 — Anthropic's
  #    30 April 2026 personal-guidance research measured 9% baseline /
  #    25-38% emotional-domain validation rates even in frontier models
  #    trained against sycophancy. Reviewer-as-peer-agent carries the
  #    same load. Cite or fail.
  has_findings=0
  has_anchor=0
  ANCHOR_RE='(`[A-Za-z_][A-Za-z0-9_./:-]*`|[A-Za-z0-9_./-]+\.[a-zA-Z]+:[0-9]+)'

  if grep -qiE '^##+[[:space:]]+findings?\b' "$ASSERT_REVIEW_FILE"; then
    # awk exits 0 if Findings has body+anchor, 2 if body but no anchor,
    # 1 if no body at all. Defused with `|| awk_exit=$?` to keep set -e happy.
    awk_exit=0
    awk '
      tolower($0) ~ /^##+[[:space:]]+findings?([[:space:]]|$)/ { in_f=1; next }
      in_f && /^##+ / { in_f=0 }
      in_f && NF { found=1 }
      in_f && /(`[A-Za-z_][A-Za-z0-9_.:\/-]*`|[A-Za-z0-9_.\/-]+\.[a-zA-Z]+:[0-9]+)/ { anchor=1 }
      END { exit (found ? (anchor ? 0 : 2) : 1) }
    ' "$ASSERT_REVIEW_FILE" || awk_exit=$?
    case "$awk_exit" in
      0) has_findings=1; has_anchor=1 ;;
      2) has_findings=1 ;;
      *) ;;
    esac
  fi

  if [ "$has_findings" = "0" ]; then
    # fallback: reasoned no-issues — same anchor rule applied to the line
    if grep -qiE 'no issues[[:space:]]*[—:-][[:space:]]*\S+[[:space:]]+\S+' "$ASSERT_REVIEW_FILE"; then
      has_findings=1
      if grep -iE 'no issues' "$ASSERT_REVIEW_FILE" | grep -qE "$ANCHOR_RE"; then
        has_anchor=1
      fi
    fi
  fi

  [ "$has_findings" = "0" ] && missing="$missing concrete-finding-or-reasoned-no-issues"
  [ "$has_findings" = "1" ] && [ "$has_anchor" = "0" ] && missing="$missing anchor-in-findings"

  if [ -n "$missing" ]; then
    echo "BLOCK: review artifact $ASSERT_REVIEW_FILE missing:$missing" >&2
    echo "Required: diff summary heading, Severity: <enum>, Findings section (or reasoned 'No issues — <reason>'), and at least one concrete anchor inside findings/no-issues — a file path with line number (e.g. \`foo.ts:42\`) or a backticked symbol or path (e.g. \`processOrder\`, \`scripts/foo.sh\`)." >&2
    echo "Sycophancy gate: reviews that pass structurally but cite nothing concrete are blocked. See SOP §3 step 2 for rationale." >&2
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
    # Delegated to scripts/resolve-resume-path.sh (P96). This block previously
    # inlined the agent-id and memory-dir derivation, which /restart-sop
    # duplicated verbatim and /update-sop Step 6 did not implement at all —
    # so the writer and the two readers could target different directories.
    # One implementation now serves all three; see the script header and
    # docs/guides/cross-layer-rules.md Tier A.
    #
    # `|| resolver_status=$?` is load-bearing under `set -e`: the resolver
    # exits 1 when no resume file exists (first session) and 2 when the repo
    # root is the home directory. Both are conditions this check degrades
    # through, not crashes on, so the status is captured rather than fatal.
    resolver="$(cd "$(dirname "$0")" && pwd)/resolve-resume-path.sh"
    resolver_status=0
    resolver_err=$(mktemp)
    resume_file=$(bash "$resolver" --read 2>"$resolver_err") || resolver_status=$?
    # Always re-emit the resolver's stderr when it wrote any. On success that is
    # the legacy-fallback migration advisory, which P47 made load-bearing. On
    # failure it is the specific reason — "not a git repository", or the
    # home-root refusal — which the generic "no project_resume file found"
    # message below would otherwise replace with something misleading. The
    # resolver stays silent on the ordinary first-session case (exit 1, no
    # output), so this adds no noise where D1 requires graceful degradation.
    if [ -s "$resolver_err" ]; then
      cat "$resolver_err" >&2
    fi
    rm -f "$resolver_err"
    if [ "$resolver_status" != "0" ]; then
      resume_file=""
    fi
    if [ "$resolver_status" = "2" ]; then
      echo "check-drift: repo root is the home directory — the memory directory there is" >&2
      echo "  the harness catch-all shared across projects, not project-scoped. Drift check skipped." >&2
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
    # `|| true`: grep exits 1 when the fixture names no P-number, which is a
    # legal input (it is what the no-declared-work case looks like). Under
    # pipefail that 1 propagates past `sort` and errexit kills the script.
    commit_pnums=$( { grep -oE '\bP[0-9]+\b' "$DRIFT_COMMITS_FILE" || true; } | sort -u)
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
    # `|| true` keeps pipefail+errexit from killing the script when no
    # P-numbers appear in commit messages — empty result is a legal state
    # (drift detection's whole point is "do commits reference declared work?").
    commit_pnums=$( { git log "${base}..HEAD" --format='%s%n%b' 2>/dev/null | grep -oE '\bP[0-9]+\b' || true; } | sort -u)
    # Measure diff over the committed range only — stays consistent with
    # commit_pnums so uncommitted work doesn't trigger a false-positive.
    # `|| true` on both: git diff exits non-zero on an unresolvable range, and
    # pipefail carries that past awk/wc into an errexit kill. The fallbacks
    # below turn an unmeasurable range into 0, which skips the gate rather than
    # crashing it — the same outcome as a below-threshold session.
    loc=$( { git diff --numstat "${base}..HEAD" -- 2>/dev/null || true; } | awk '{a+=$1; d+=$2} END{print a+d+0}')
    files=$( { git diff --numstat "${base}..HEAD" -- 2>/dev/null || true; } | wc -l | tr -d ' ')
    [ -z "$loc" ] && loc=0
    [ -z "$files" ] && files=0
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
  echo "  3) If the prior resume file is stale: update it (Step 6 of /update-sop) and re-run." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# --check-replication: P75 pristine-replica replication gate
#
# Every existing gate asks "was this change declared?". None asks "did this
# change reach the surface that enforces it?". A session can edit a
# pristine-replica file, pass Step 4, merge, and leave the user-scope
# copy that actually executes untouched — observed twice, in both directions
# (Batch 0.27 left user scope stale for eight days; Batch 0.26 found a
# project-specific step that had leaked the other way).
#
# The file list comes from `baseline_shas` in agent-sop.config.json, which is
# the same source /update-agent-sop reads. A second hardcoded list here would
# be the same class of bug one layer up (docs/guides/cross-layer-rules.md).
# ---------------------------------------------------------------------------
if [ "$MODE" = "check-replication" ]; then
  # Resolve config: project scope wins over user scope, matching /update-agent-sop.
  config="$REPL_CONFIG_FILE"
  if [ -z "$config" ]; then
    for candidate in ".claude/agent-sop.config.json" "$HOME/.claude/agent-sop.config.json"; do
      if [ -f "$candidate" ]; then config="$candidate"; break; fi
    done
  fi
  if [ -z "$config" ] || [ ! -f "$config" ]; then
    echo "check-replication: no agent-sop.config.json found — skipping (project does not track pristine replicas)"
    exit 0
  fi

  home_root="${REPL_HOME:-$HOME}"

  sha_of() {
    if command -v shasum >/dev/null 2>&1; then
      shasum -a 256 "$1" | cut -d' ' -f1
    else
      sha256sum "$1" | cut -d' ' -f1
    fi
  }

  # Manifest = keys of baseline_shas. Zero-dep extraction: isolate the block,
  # then pull "path": "sha" pairs. Restricted to the tracked extensions so a
  # nested object cannot inject a false key.
  manifest=$(sed -n '/"baseline_shas"[[:space:]]*:[[:space:]]*{/,/^[[:space:]]*}/p' "$config" \
    | grep -oE '"[^"]+\.(md|sh|py)"[[:space:]]*:[[:space:]]*"[a-f0-9]{64}"' \
    | sed 's/"[[:space:]]*:[[:space:]]*"/|/; s/^"//; s/"$//' || true)

  if [ -z "$manifest" ]; then
    echo "check-replication: baseline_shas is empty — skipping (nothing tracked yet)"
    exit 0
  fi

  # Excluded files are never synced, so they can never be out of sync.
  excluded=$(sed -n '/"exclude"[[:space:]]*:[[:space:]]*\[/,/\]/p' "$config" \
    | grep -oE '"[^"]+\.(md|sh|py)"' | tr -d '"' || true)

  # Session-changed files: committed in range plus working tree. Fixture mode
  # supplies the list directly so the check is testable without a repo.
  if [ -n "$REPL_CHANGED_FILE" ]; then
    changed=$(cat "$REPL_CHANGED_FILE")
  else
    range=""
    default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/@@') || default_branch=""
    if [ -z "$default_branch" ]; then
      for candidate in origin/main origin/master origin/develop; do
        if git rev-parse --verify "$candidate" >/dev/null 2>&1; then default_branch="$candidate"; break; fi
      done
    fi
    if [ -n "$default_branch" ]; then
      base=$( { git merge-base "$default_branch" HEAD 2>/dev/null || true; } )
      head_sha=$( { git rev-parse HEAD 2>/dev/null || true; } )
      if [ -n "$base" ] && [ "$base" != "$head_sha" ]; then range="$base..HEAD"; fi
    fi
    committed=""
    if [ -n "$range" ]; then
      committed=$( { git diff --name-only "$range" 2>/dev/null || true; } )
    fi
    worktree=$( { git diff --name-only HEAD 2>/dev/null || true; } )
    changed=$(printf '%s\n%s\n' "$committed" "$worktree" | grep -v '^$' | sort -u || true)
  fi

  if [ -z "$changed" ]; then
    echo "check-replication: no changed files this session — skipping"
    exit 0
  fi

  # Baseline staleness is a real finding upstream, where baseline_shas records
  # this repo's own shipped state. In a consumer project a differing baseline
  # means LOCALLY MODIFIED, which /update-agent-sop Step 4 already handles, so
  # it is not reported there. Resolved once, not per file.
  cfg_local_path=$(grep -oE '"local_path"[[:space:]]*:[[:space:]]*"[^"]*"' "$config" | sed 's/.*:[[:space:]]*"//; s/"$//' || true)
  repo_root=$( { git rev-parse --show-toplevel 2>/dev/null || true; } )
  is_upstream="no"
  if [ -n "$cfg_local_path" ] && [ -n "$repo_root" ] && [ "$cfg_local_path" = "$repo_root" ]; then
    is_upstream="yes"
  fi

  stale_mirror=""
  stale_baseline=""
  checked=0

  while IFS='|' read -r path baseline; do
    [ -n "$path" ] || continue
    # Only files this session actually touched.
    printf '%s\n' "$changed" | grep -qxF "$path" || continue
    # Excluded files are out of scope by declaration.
    if [ -n "$excluded" ] && printf '%s\n' "$excluded" | grep -qxF "$path"; then continue; fi
    [ -f "$path" ] || continue

    checked=$((checked + 1))
    current=$(sha_of "$path")

    case "$path" in
      .claude/*)
        # User-scope mirror: the copy that actually executes in every session.
        mirror="$home_root/$path"
        if [ ! -f "$mirror" ]; then
          stale_mirror="$stale_mirror
  $path -> $mirror (mirror missing)"
        elif [ "$(sha_of "$mirror")" != "$current" ]; then
          stale_mirror="$stale_mirror
  $path -> $mirror (content differs)"
        fi
        ;;
    esac

    if [ "$is_upstream" = "yes" ] && [ "$current" != "$baseline" ]; then
      stale_baseline="$stale_baseline
  $path (baseline records $(printf '%.12s' "$baseline")…, file is $(printf '%.12s' "$current")…)"
    fi
  done <<EOF
$manifest
EOF

  if [ "$checked" = "0" ]; then
    echo "check-replication: no manifest-tracked files changed this session — skipping"
    exit 0
  fi

  if [ -z "$stale_mirror" ] && [ -z "$stale_baseline" ]; then
    echo "check-replication: OK — all $checked manifest-tracked file(s) changed this session are replicated."
    exit 0
  fi

  echo "BLOCK: manifest-tracked files changed this session have not been replicated." >&2
  if [ -n "$stale_mirror" ]; then
    echo "  User-scope mirror out of sync (this is the copy that executes):$stale_mirror" >&2
  fi
  if [ -n "$stale_baseline" ]; then
    echo "  Baseline SHA stale in $config:$stale_baseline" >&2
  fi
  echo "" >&2
  echo "Resolve by one of:" >&2
  echo "  1) Run /update-agent-sop to replicate the change and refresh baselines." >&2
  echo "  2) If the divergence is deliberate, record it on this item's Backlog entry as: replication deferred (P<n>): <reason>" >&2
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
    "[OPEN]") echo "[IN PROGRESS], [DEFERRED], [SHIPPED] (Feature/Refactor cites a review), [WON'T]" ;;
    "[IN PROGRESS]") echo "[BLOCKED], [DEFERRED], [SHIPPED] (Feature/Refactor cites a review), [WON'T]" ;;
    "[BLOCKED]") echo "[IN PROGRESS], [DEFERRED], [SHIPPED] (Feature/Refactor cites a review), [WON'T]" ;;
    "[DEFERRED]") echo "[IN PROGRESS], [SHIPPED] (Feature/Refactor cites a review), [WON'T], [BLOCKED]" ;;
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
# ── Review trigger (b): SOP self-modification ────────────────────────────────
#
# claude-agent-sop.md states this as the SOP's one unconditional gate: edits to
# files the SOP itself executes or instructs are load-bearing "regardless of
# LOC". Until P87 that sentence had no execution arm anywhere — update-sop.md
# implemented the diff-size trigger only, and this validator did no path
# inspection at all, so the strongest-sounding gate in the SOP was satisfiable
# by a self-declared `docs-only` token that no code verified.
#
# Tag-independent, deliberately. The tag exemption is the larger hole: the two
# sessions that most needed review on these paths (P75, and this session's own
# P84/P92 work) were tagged [Bug]/[Refactor] and exempt, and the reviews that
# did run found a HIGH and two CRITICALs. Tag is a poor proxy for risk here.
sop_self_mod_paths() {
  printf '%s\n' "$1" | grep -E '^(docs/sop/|docs/guides/sop-|\.claude/agents/|\.claude/commands/|scripts/validate-)' || true
}

session_changed_files() {
  local default_branch="" base head_sha range="" committed worktree
  default_branch=$( { git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || true; } | sed 's@^refs/remotes/@@')
  if [ -z "$default_branch" ]; then
    for candidate in origin/main origin/master origin/develop; do
      if git rev-parse --verify "$candidate" >/dev/null 2>&1; then default_branch="$candidate"; break; fi
    done
  fi
  if [ -n "$default_branch" ]; then
    base=$( { git merge-base "$default_branch" HEAD 2>/dev/null || true; } )
    head_sha=$( { git rev-parse HEAD 2>/dev/null || true; } )
    if [ -n "$base" ] && [ "$base" != "$head_sha" ]; then range="$base..HEAD"; fi
  fi
  committed=""
  [ -n "$range" ] && committed=$( { git diff --name-only "$range" 2>/dev/null || true; } )
  worktree=$( { git diff --name-only HEAD 2>/dev/null || true; } )
  printf '%s\n%s\n' "$committed" "$worktree" | grep -v '^$' | sort -u || true
}

resolve_before() {
  if [ -n "$BEFORE_FILE" ]; then
    # Explicit `return 0`, not a bare `return`. A bare return inherits the
    # exit status of the preceding `&&` list, so a missing --before-file made
    # this function return 1 — and because it is called as a plain statement
    # (`resolve_before > "$TMP_BEFORE"`), errexit killed the script before the
    # "no before-state ... Skipping" message below could print. The symptom was
    # exit 1 with zero bytes on both stdout and stderr: the same silent-failure
    # class as the P73 pipefail bug, in a different shape.
    if [ -f "$BEFORE_FILE" ]; then
      cat "$BEFORE_FILE"
    fi
    return 0
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

    # [SHIPPED] transitions of a [Feature]/[Refactor] item (or any item when the
    # session touched the SOP's own executable surface, trigger (b), P87) must
    # cite a review artifact under docs/reviews/ or declare an enumerated skip
    # — on the Backlog entry itself. Until P105 (2026-09-05) the citation lived
    # on a Batch Log line in docs/build-plans/; a measured review found the
    # Batch Log read by nothing else, so the entry is now the single place.
    if [ "$after_status" = "[SHIPPED]" ] && [ "$before_status" != "[SHIPPED]" ]; then
      # Bounded at the next `### ` or `## ` heading (a `## Shipped Archive`
      # after the last entry must not lend it a citation), anchored the same
      # way extract_statuses anchors (`### P<n>` followed by a non-digit), and
      # CRLF-tolerant. An entry that cannot be located fails closed below.
      entry_body=$(tr -d '\r' < "$AFTER_FILE" | awk -v p="### ${p}" '
        $0 ~ "^"p"([^0-9]|$)" { found=1; next }
        found && /^(### |## )/ { exit }
        found { print }
      ')
      if ! tr -d '\r' < "$AFTER_FILE" | grep -qE "^### ${p}([^0-9]|$)"; then
        echo "BLOCK: $p transitioned to [SHIPPED] but its entry heading could not be located in Backlog.md (expected a line starting \"### ${p}\")."
        violations=$((violations + 1))
        continue
      fi
      # Only labelled lines outside code fences count (review: HIGH): a path
      # quoted as an example, or a skip token in prose, is not a declaration.
      # The citation is a bare filename under docs/reviews/ — no slash after
      # it, so `..` cannot reach a file that is not a review (review: CRITICAL).
      review_lines=$(printf '%s\n' "$entry_body" | awk '/^[[:space:]]*```/{f=!f; next} !f' | grep -E '^[[:space:]]*review( skipped)?[: (]' || true)
      item_type=$(printf '%s\n' "$entry_body" | awk '
        /^`\[/ {
          line=$0
          gsub(/`/, "", line)
          sub(/^\[[^]]+\][[:space:]]*/, "", line)
          if (match(line, /^\[[^]]+\]/)) { print substr(line, RSTART+1, RLENGTH-2) }
          exit
        }')
      # Trigger (b), P87. Resolve once per run, not per item.
      if [ -z "${SELF_MOD_CHECKED:-}" ]; then
        SELF_MOD_CHECKED=1
        if [ -n "$SELF_MOD_CHANGED_FILE" ] && [ -f "$SELF_MOD_CHANGED_FILE" ]; then
          SELF_MOD_FILES=$(sop_self_mod_paths "$(cat "$SELF_MOD_CHANGED_FILE")")
        else
          SELF_MOD_FILES=$(sop_self_mod_paths "$(session_changed_files)")
        fi
      fi
      gate_type="$item_type"
      if [ -n "${SELF_MOD_FILES:-}" ]; then
        gate_type="Feature"
      fi

      case "$gate_type" in
        "Feature"|"Refactor")
          # The skip must name its own P-number and use the enumerated set
          # (P66); under trigger (b) only test-only and dep-bump survive.
          skip_re="review skipped \(${p}\): *(docs-only|test-only|dep-bump|below-threshold)\b"
          if [ -n "${SELF_MOD_FILES:-}" ]; then
            skip_re="review skipped \(${p}\): *(test-only|dep-bump)\b"
          fi
          if printf '%s' "$review_lines" | grep -qE '^[[:space:]]*review:[[:space:]]*docs/reviews/'; then
            # A citation is not evidence until the path resolves (P95).
            missing_reviews=""
            for cited in $(printf '%s' "$review_lines" | grep -oE '^[[:space:]]*review:[[:space:]]*docs/reviews/[A-Za-z0-9._-]+\.md' | sed -E 's/^[[:space:]]*review:[[:space:]]*//'); do
              [ -f "$cited" ] || missing_reviews="$missing_reviews $cited"
            done
            [ -n "$missing_reviews" ] || [ -n "$(printf '%s' "$review_lines" | grep -oE '^[[:space:]]*review:[[:space:]]*docs/reviews/[A-Za-z0-9._-]+\.md')" ] || missing_reviews=" (a review: line with a path that is not a bare filename under docs/reviews/)"
            if [ -n "$missing_reviews" ]; then
              echo "BLOCK: $p ([${item_type}]) cites a review artifact that does not exist:${missing_reviews}"
              echo "  A cited path that does not resolve is not a review. Either write the artifact,"
              echo "  or declare the skip on the entry as: review skipped (${p}): <docs-only|test-only|dep-bump|below-threshold>"
              violations=$((violations + 1))
            fi
          elif printf '%s' "$review_lines" | grep -qEi "$skip_re"; then
            : # enumerated skip, bound to this P-number — gate satisfied
          else
            if [ -n "${SELF_MOD_FILES:-}" ]; then
              echo "BLOCK: $p ([${item_type}]) shipped in a session that modified the SOP's own executable surface — the review trigger fires regardless of tag or diff size."
              echo "  Self-modifying paths changed this session:"
              printf '%s\n' "$SELF_MOD_FILES" | sed 's/^/    /'
              echo "  Requires a real reviewer artifact cited on the Backlog entry as: review: docs/reviews/<file>.md"
              violations=$((violations + 1))
              continue
            fi
            echo "BLOCK: $p ([${item_type}]) shipped but its Backlog entry neither cites a docs/reviews/ artifact nor declares an enumerated review skip."
            echo "  Add a line under the status line: review: docs/reviews/<file>.md"
            echo "  or declare the skip there as: review skipped (${p}): <docs-only|test-only|dep-bump|below-threshold>"
            violations=$((violations + 1))
          fi
          ;;
      esac
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
