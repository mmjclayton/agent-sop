---
description: Run the Agent SOP session end checklist. Updates all tracking files, writes the resume snapshot, and commits.
sop_version: "2026-04-19"
---

Execute the Agent SOP session end checklist. Complete every step below before the session ends. Do not skip any step. Never delete without a trace: update in place, mark superseded, or archive.

## Step 0: Resolve agent identity

Agent identity appears in filenames (`docs/recent-work/YYYY-MM-DD_<agent-id>_<slug>.md`), in per-agent `project_resume_<agent-id>.md`, and in commit-range partitioning routines (Step 3b, Step 11). Resolve it first so every subsequent step uses a consistent value.

Precedence: `CLAUDE_AGENT_ID` env var > `.sop-agent-id` file at worktree root > `solo` (single-worktree default) > 6-char hash of worktree path. See `docs/guides/multi-agent-parallel-sessions.md` Section 1 for full scenarios.

```bash
resolve_agent_id() {
  if [ -n "${CLAUDE_AGENT_ID:-}" ]; then
    printf '%s' "$CLAUDE_AGENT_ID"
    return
  fi

  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null) || { printf 'solo'; return; }

  if [ -f "$root/.sop-agent-id" ]; then
    head -1 "$root/.sop-agent-id" | tr -d '[:space:]'
    return
  fi

  local count
  count=$(git worktree list 2>/dev/null | wc -l | tr -d '[:space:]')
  if [ "$count" = "1" ]; then
    printf 'solo'
    return
  fi

  if command -v shasum >/dev/null 2>&1; then
    printf '%s' "$root" | shasum -a 256 | cut -c1-6
  else
    printf '%s' "$root" | sha256sum | cut -c1-6
  fi
}

AGENT_ID=$(resolve_agent_id)
echo "Agent identity: $AGENT_ID"
```

If `$AGENT_ID` is `solo`, single-agent conventions apply. If it is any other value, parallel-session conventions apply — see `docs/guides/multi-agent-parallel-sessions.md`.

## Step 0a: Resolve session commit range

Step 3b (secondary-tracker reconciliation) and Step 11 (hard-block reconciliation check) both partition commits by "what this session added to its branch, not yet on the default branch". Resolve the range once so both steps use it consistently.

```bash
resolve_session_commit_range() {
  local default_branch
  default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/@@')
  if [ -z "$default_branch" ]; then
    for candidate in origin/main origin/master origin/develop; do
      if git rev-parse --verify "$candidate" >/dev/null 2>&1; then
        default_branch="$candidate"
        break
      fi
    done
  fi
  if [ -z "$default_branch" ]; then
    printf ''
    return
  fi

  local base head_sha
  base=$(git merge-base "$default_branch" HEAD 2>/dev/null)
  head_sha=$(git rev-parse HEAD 2>/dev/null)
  if [ -z "$base" ] || [ "$base" = "$head_sha" ]; then
    printf ''
    return
  fi
  printf '%s..HEAD' "$base"
}

SESSION_RANGE=$(resolve_session_commit_range)
echo "Session commit range: ${SESSION_RANGE:-<empty — on default branch or no divergence>}"
```

When `SESSION_RANGE` is empty, Step 3b and Step 11's commit enumeration become no-ops — correct behaviour when an agent is committing directly to `main` or has made no commits yet. Guard every consumer with `if [ -n "$SESSION_RANGE" ]; then ... fi`.

## Step 1: Self-evaluate against Definition of Done

Before updating any tracking files, check your work against the relevant Definition of Done rubric in CLAUDE.md:
- **Bug fix:** Root cause identified? Fix applied to ALL instances? New test? Existing tests pass?
- **Feature:** All ACs met? Tests added? Design system followed? Brand voice checked?
- **Refactor:** Behaviour unchanged? No unrelated files? Dead code removed?
- **Test writing:** Edge cases covered? Test names describe behaviour? Existing patterns followed?

If any criterion is not met, fix it before proceeding. If it cannot be fixed in this session, note it in Step 4 (agent-memory.md Gotchas).

## Step 1b: Required reviewer turn (Features & Refactors over threshold)

Self-evaluation (Step 1 above) is the agent reviewing its own work. For any item transitioning to `[SHIPPED]` this session AND tagged `[Feature]` or `[Refactor]` AND whose session diff exceeds the threshold, invoke a sibling reviewer agent for an independent pass. The findings file is the gate — no file, no ship. No human sign-off; the reviewer is another agent, the substance assertion is automated.

**Threshold** (configurable in `~/.claude/agent-sop.config.json`, fields `review_loc_threshold` default 50 and `review_files_threshold` default 3):

```bash
# Count changed lines and files in the session range (merge-base..working-tree).
# Uses --numstat (machine-readable: "<added>\t<deleted>\t<path>" per file) and
# sums both columns. --shortstat is human-prose and breaks for deletion-only
# diffs where "1 deletion(-)" shifts columns.
count_session_diff() {
  local base="${1:-HEAD}"
  local loc files
  loc=$(git diff --numstat "$base" -- 2>/dev/null | awk '{a+=$1; d+=$2} END{print a+d+0}')
  files=$(git diff --numstat "$base" -- 2>/dev/null | wc -l | tr -d ' ')
  [ -z "$loc" ] && loc=0
  echo "loc=$loc files=$files"
}
```

Resolve the range once: prefer `SESSION_RANGE` from Step 0a; fall back to `HEAD` when on the default branch directly. Read thresholds from the config file or use defaults.

**For each P-number that shipped in this session as `[Feature]` or `[Refactor]`** (detected by diff of `Backlog.md` between `HEAD` and working tree — any tag flip to `[SHIPPED - YYYY-MM-DD]`):

1. If session diff is below threshold, skip — the item is small enough that self-eval suffices.
2. If `docs/reviews/YYYY-MM-DD_<agent-id>_P<n>.md` already exists AND passes substance assertion, skip (already reviewed).
3. Otherwise, invoke a reviewer subagent:
   - Default: `code-reviewer` (via the Agent tool with `subagent_type: code-reviewer`).
   - **Security override:** if any file in the session diff matches the auth / crypto / payment / auth-token / input-sanitisation heuristic list below, use `security-reviewer` instead.

    Security-trigger paths — narrowed to reduce false positives on generic prose (e.g. `git rev-parse --verify`, documentation using "sign" in "signature"). Match as case-insensitive substring against changed file paths only (not diff content), and prefer multi-token forms:

    - Auth: `auth`, `login`, `session`, `access_token`, `refresh_token`, `password`, `credential`, `jwt`, `oauth`
    - Crypto: `crypto`, `cipher`, `encrypt`, `decrypt`, `verify_token`, `verify_password`, `signing`, `signature`, `hash_password`
    - Web security: `csrf`, `cors`, `xss`, `content-security-policy`
    - Payments: `payment`, `billing`, `stripe`, `webhook`
    - Input safety: `sanitize`, `sanitise`, `escape_html`, `escape_sql`, `raw_query`

    Bare tokens like `sign`, `verify`, or `sql` are deliberately excluded — they match too broadly (prose, commit messages, unrelated utilities). Add project-specific trigger paths in `agent-sop.config.json` under a future `security_trigger_paths` field (not yet schemed; extend when a downstream project needs it).

4. Prompt the reviewer: "Review diff in SESSION_RANGE for `P<n>: <title>`. Use the review template at `docs/templates/review-template.md`. Write the result to `docs/reviews/YYYY-MM-DD_<agent-id>_P<n>.md`. Include: Summary, Severity (enum), Findings (concrete file:line bullets) OR a reasoned 'No issues — <reason>' statement."
5. Assert substance:
   ```bash
   bash scripts/validate-state-transitions.sh --assert-review "docs/reviews/YYYY-MM-DD_<agent-id>_P<n>.md" || exit 1
   ```
6. The Batch Log entry (Step 6) for this P-number must reference the review path — the state-transition validator's Batch Log check (Step 3c) keeps this honest.

**Hard-block conditions:**
- Shipping a `[Feature]`/`[Refactor]` over threshold with no review artifact → fail.
- Review artifact exists but fails substance assertion (stub / missing sections) → fail.
- Review artifact's severity is `CRITICAL` or `HIGH` with no matching Gotcha entry in `docs/agent-memory/gotchas/` or Backlog follow-up → warning (not block), but agent should address or note.

**Pre-migration projects:** if `docs/templates/review-template.md` or `docs/reviews/` is absent, skip with a non-blocking warning: "Run `/update-agent-sop` to sync the review template + directory conventions."

Bug fixes, Iterations, and items under threshold are exempt — the self-eval rubric in Step 1 stands alone for them.

## Step 2: Run tests (code projects only)

If this is a code project with a test suite, run the full test suite now. Fix any failures before proceeding. If tests fail and cannot be fixed quickly, note the failures in agent-memory.md Gotchas and continue with the remaining steps.

Skip this step for documentation-only or markdown-only projects.

## Step 2a: Check for P-number collisions with the default branch

When multiple agents run in parallel, two sessions can assign the same P-number to different items before either merges to main. This step detects the collision before `/update-sop` writes conflicting entries. Hard-blocks if found — resolution is manual, via the `renumber_p` helper in `docs/guides/multi-agent-parallel-sessions.md` Section 6.

```bash
detect_pnumber_collisions() {
  git fetch origin --quiet 2>/dev/null || {
    echo "Warning: could not fetch origin. Skipping P-number collision check."
    return 0
  }

  local default_branch
  default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/@@')
  if [ -z "$default_branch" ]; then
    for candidate in origin/main origin/master origin/develop; do
      if git rev-parse --verify "$candidate" >/dev/null 2>&1; then
        default_branch="$candidate"; break
      fi
    done
  fi
  [ -z "$default_branch" ] && return 0

  local branch_pnums main_pnums collisions=""
  branch_pnums=$(grep -oE '^### P[0-9]+' Backlog.md 2>/dev/null | grep -oE '[0-9]+' | sort -u)
  main_pnums=$(git show "${default_branch}:Backlog.md" 2>/dev/null | grep -oE '^### P[0-9]+' | grep -oE '[0-9]+' | sort -u)

  for p in $branch_pnums; do
    if printf '%s\n' "$main_pnums" | grep -qx "$p"; then
      # Same P-number on both sides — check if content differs (titles only as a cheap heuristic)
      local branch_title main_title
      branch_title=$(awk -v p="### P${p}" '$0 ~ "^"p"($| )" {getline; getline; print; exit}' Backlog.md 2>/dev/null)
      main_title=$(git show "${default_branch}:Backlog.md" 2>/dev/null | awk -v p="### P${p}" '$0 ~ "^"p"($| )" {getline; getline; print; exit}')
      if [ "$branch_title" != "$main_title" ]; then
        collisions="$collisions $p"
      fi
    fi
  done

  if [ -n "$collisions" ]; then
    local max_main
    max_main=$(printf '%s\n' "$main_pnums" | sort -n | tail -1)
    echo ""
    echo "BLOCK: P-number collision(s) detected with ${default_branch}"
    echo "The following P-numbers exist on both this branch and ${default_branch} with different content:"
    for p in $collisions; do echo "  - P${p}"; done
    echo ""
    echo "Next free P-number on ${default_branch}: P$((max_main + 1))"
    echo ""
    echo "Resolve with the renumber_p helper from docs/guides/multi-agent-parallel-sessions.md Section 6:"
    local next=$((max_main + 1))
    for p in $collisions; do echo "  renumber_p ${p} ${next}"; next=$((next + 1)); done
    echo ""
    echo "Then re-run /update-sop."
    return 1
  fi
  return 0
}

detect_pnumber_collisions || exit 1
```

When no collisions are found, this step is silent. When a collision is found, stop — do not proceed to Step 3 until the agent has run the renumber helper and verified the result with `git diff`.

## Step 3: Update Backlog.md

- Update status tags for any items worked on this session (e.g. `[OPEN]` to `[IN PROGRESS]`, or `[IN PROGRESS]` to `[SHIPPED - YYYY-MM-DD]`)
- Append any new work items discovered during the session with `[OPEN]` status
- Add to the Shipped Archive if items were shipped
- Never delete items. Never remove items. Update in place.

## Step 3b: Reconcile project-specific secondary trackers

Many projects maintain tracker files separate from `Backlog.md` — audit findings, security scans, compliance checklists, migration punch-lists — using the same `[OPEN]` / `[SHIPPED]` status tags. `/update-sop` must reconcile those files too, or shipped work silently leaves stale `[OPEN]` entries behind.

**Detection (auto, no config):** scan every `.md` path listed in CLAUDE.md's Key Documents & Dispatch table. A file is a secondary tracker if any of its headings (`^##` or `^###`) carry a status tag — one of `[OPEN]`, `[IN PROGRESS]`, `[BLOCKED]`, `[DEFERRED]`, `[SHIPPED`, `[VERIFIED`, `[WON'T]`. Skip `Backlog.md` itself (covered by Step 3).

```bash
# List candidates pulled from the Key Documents table
grep -oE '\`[^\`]+\.md\`' CLAUDE.md | tr -d '\`' | while read f; do
  [ "$f" = "Backlog.md" ] && continue
  [ -f "$f" ] || continue
  if grep -qE '^##+ .*\[(OPEN|IN PROGRESS|BLOCKED|DEFERRED|SHIPPED|VERIFIED|WON.T)' "$f"; then
    echo "tracker: $f"
  fi
done
```

**For each detected tracker:**

1. Identify this session's commits that reference a finding ID — e.g. `fix(audit): A1`, `fix(security): H-3`, `feat(migration): M5`. Use the `SESSION_RANGE` resolved in Step 0a — it naturally partitions commits per-agent via `git merge-base`, so parallel sessions on sibling branches never contaminate each other's reconciliation.
   ```bash
   if [ -n "$SESSION_RANGE" ]; then
     git log "$SESSION_RANGE" --format='%s' | grep -oE '\b[A-Z]+-?[0-9]+\b' | sort -u
   fi
   ```
2. For each referenced ID, locate the matching entry in the tracker and update its status tag: `[OPEN]` → `[SHIPPED - YYYY-MM-DD]`. Preserve the entry body. Never delete.
3. Update the tracker's `Last updated:` header (if present) to today's date.
4. Apply the same tag discipline as `Backlog.md`: status first, `[WON'T]` requires an inline reason, `[DEFERRED]` for intentional postponement.

Skip this step entirely when `SESSION_RANGE` is empty (agent is on the default branch directly with no diverging commits). Projects with no secondary trackers also see a no-op regardless of range.

## Step 3c: Validate Backlog state transitions

Step 2a catches P-number collisions. It does not catch illegal status-tag transitions — e.g. an entry jumping `[OPEN]` → `[SHIPPED - YYYY-MM-DD]` with no `[IN PROGRESS]` intermediate, a terminal-state revival, or a `[SHIPPED]` transition with no matching Batch Log entry. Step 3c runs the state-transition validator against the graph documented in Section 8 of the core SOP.

```bash
if [ -x scripts/validate-state-transitions.sh ]; then
  bash scripts/validate-state-transitions.sh || exit 1
else
  echo "Warning: validate-state-transitions.sh not found. Upgrade with /update-agent-sop or run from upstream: bash ~/Projects/agent-sop/scripts/validate-state-transitions.sh"
fi
```

Hard-blocks on non-zero exit. Runs *after* Step 3 (and Step 3b) so the validator sees this session's finalised Backlog state. The validator compares `HEAD:Backlog.md` against working-tree `Backlog.md` — exactly the changes this `/update-sop` is about to commit. No-ops when there is no working-tree diff.

For a retrospective whole-session validation, invoke with the session's merge-base: `bash scripts/validate-state-transitions.sh --before $(git merge-base origin/main HEAD)`. Use this if earlier commits in the session predated the validator or bypassed it.

Typical violations and fixes:
- `<absent> → [SHIPPED]` or `[OPEN] → [SHIPPED]` — missing `[IN PROGRESS]` intermediate. Fix: add it in the same `Backlog.md` edit, or downgrade to `[OPEN]` and ship in a follow-up session.
- `[VERIFIED] → [OPEN]` (or other terminal revival) — create a new P-number that references the original.
- `[SHIPPED]` without Batch Log reference — append the P-number to the current phase's `docs/build-plans/phase-N.md` Batch Log.

Soft warnings (`[BLOCKED]` ↔ `[DEFERRED]` with no decision file in the commit range) are non-blocking — re-classification is legitimate, the warning is a prompt to consider writing a decision entry.

## Step 3d: Detect session drift

`/restart-sop` reminds the agent of the declared in-flight P-number at session start. Mid-session context drift — auto-compaction, context resets, tangents into unrelated code — can leave the session committing work that the resume file never predicted. Step 3d compares P-numbers in this session's commit messages against P-numbers mentioned in `project_resume_<agent-id>.md` (the per-agent declaration of in-flight work). Hard-blocks if the session exceeds threshold AND no declared P-number is referenced AND no `## Scope Change` block exists in the resume.

```bash
if [ -x scripts/validate-state-transitions.sh ]; then
  bash scripts/validate-state-transitions.sh --check-drift || exit 1
else
  echo "Warning: validate-state-transitions.sh not found. Upgrade with /update-agent-sop."
fi
```

Thresholds reuse the P44 config fields (`review_loc_threshold` / `review_files_threshold`) — the same "too small to worry about" boundary applies. Below threshold: skip. First session (no prior resume file): skip.

Resolution paths when the gate fires:
- **Deliberate scope change:** add a `## Scope Change` block to `project_resume_<agent-id>.md` with the actual P-number + one-line reason. The validator accepts this as explicit redirection — documents the drift rather than hiding it.
- **Unintentional drift:** the commits are under the wrong P-number. Either amend the commit messages to reference the in-flight P-number, or split the work so the declared item ships this session and the drift item becomes its own Backlog entry next session.
- **Stale resume:** if the declared item already shipped in an earlier session but the resume wasn't refreshed, update the resume (Step 7 would overwrite it anyway) and re-run.

## Step 4: Update docs/feature-map.md

- Add any newly shipped items to the Shipped table
- Move any roadmap items that shipped from the Roadmap section to the Shipped table
- Update the `Last updated` date at the top

## Step 5: Update agent-memory narrative + decisions/gotchas directories

Decisions and gotchas live as one file per entry in `docs/agent-memory/decisions/` and `docs/agent-memory/gotchas/`. The narrative sections (In-Flight Work, Completed Work, Archived, Preferences) remain in `docs/agent-memory.md`.

**For each architectural decision made this session:**

Create `docs/agent-memory/decisions/YYYY-MM-DD_${AGENT_ID}_<slug>.md`:

```markdown
# [Decision title]

**Date:** YYYY-MM-DD
**Agent:** <agent-id>

[Decision body. Multi-paragraph is fine. Reference P-numbers where applicable.]
```

Slug convention: lowercase alphanumeric + hyphens, max ~50 chars, no underscores, no leading/trailing hyphen. Include P-number where relevant (e.g. `p43-rollup-derivation-idempotent`).

**For each gotcha / data model invariant / named utility:**

Create `docs/agent-memory/gotchas/YYYY-MM-DD_${AGENT_ID}_<slug>.md` with the same file format (swap "Decision" for "Gotcha" in the title).

**Superseded entries:** do not delete. Edit the superseded file to add a trailing `*Superseded by:* <new-file-name>` line, then `git mv` the file into `archive/` subdirectory once the replacement lands.

**Narrative updates in `docs/agent-memory.md`:**

- **In-Flight Work:** if the work this agent was tracking completed, remove this agent's `- <agent-id> (YYYY-MM-DD): ...` line. If new work started but did not finish, add or update this agent's line. Each agent manages only its own line — never touch another agent's entry.
- **Completed Work:** append `- YYYY-MM-DD ${AGENT_ID}: description — commit [hash]` when work completes.
- **Archived:** historical narrative content only (superseded decisions/gotchas move to their respective `archive/` subdirectories, not here).

Skip this step if `docs/agent-memory.md` does not exist (optional for projects with fewer than 10 sessions).

## Step 6: Update build plan Batch Log

Find the current build plan file in `docs/build-plans/`. Append a new entry to the Batch Log:

Format: `YYYY-MM-DD: Batch N.X — description. Commit [hash] or PR #N.`

If no build plan exists for the current work, skip this step.

## Step 7: Update project_resume_<agent-id>.md

Overwrite `~/.claude/projects/[project-hash]/memory/project_resume_${AGENT_ID}.md` with a fresh snapshot. Per-agent file — do not edit other agents' resume files.

```
# Session Resume — [Project Name] — Agent <agent-id>

Last updated: [today's date]

## What was done
[2-4 lines summarising this session's work. Include commit hashes or PR numbers.]

## What is next
[Specific next action: file, function, or Backlog item.]

## Blockers
[(none) or specific blocker with context]
```

This file is a snapshot, not a log. Overwrite the entire content.

**Legacy fallback:** if the project still uses the unsuffixed `project_resume.md` (single-agent legacy format) and `$AGENT_ID` is `solo`, write to that filename for backwards compatibility. Otherwise always use the suffixed filename.

## Step 8: Write session entry to docs/recent-work/

Create `docs/recent-work/YYYY-MM-DD_${AGENT_ID}_<slug>.md`:

```markdown
# [Session summary title]

**Date:** YYYY-MM-DD
**Agent:** <agent-id>
**Commits:** [hash, hash, ...]

[2-4 line summary of what shipped. Cross-reference Backlog P-numbers and build-plan batch numbers.]
```

Slug convention: same as Step 5 (lowercase alphanumeric + hyphens, no underscores, max ~50 chars). Include P-number and batch number where relevant (e.g. `p43-batch-1-2-directory-structure`).

**Do not edit CLAUDE.md `## Recent Work (rollup)` by hand.** Step 8b regenerates that section from this directory.

## Step 8b: Refresh CLAUDE.md Recent Work rollup

The `## Recent Work (rollup)` section in CLAUDE.md is a derived summary of `docs/recent-work/*.md`. Regenerate it between the sentinel markers on every `/update-sop` run. The refresh is idempotent — two agents producing identical directory contents produce identical output, so the rollup converges regardless of merge order.

```bash
bash scripts/refresh-rollup.sh
```

The script lives at `scripts/refresh-rollup.sh` (installed by `setup.sh`; present in any project that ran `/update-agent-sop` after 2026-04-19). If the script is missing (pre-migration project), invoke it via the agent-sop upstream:

```bash
bash ~/Projects/agent-sop/scripts/refresh-rollup.sh
```

Verify with: `grep -A 20 'recent-work-rollup:start' CLAUDE.md`

**Why a script, not inline:** the prior inline snippet used `local var=$(cmd)` inside a compound output group, which leaks assignment lines to stdout under zsh (macOS default). A script with an explicit `#!/usr/bin/env bash` shebang forces the right interpreter regardless of the caller's shell. See `docs/agent-memory/decisions/2026-04-19_solo_rollup-refresh-snippet-zsh-bug.md`.

## Step 9: Update MEMORY.md index

If any new memory files were created during this session, add them to `~/.claude/projects/[project-hash]/memory/MEMORY.md`. Each entry should be one line under ~150 characters.

## Step 10: Commit

Stage all modified docs/ files along with CLAUDE.md, Backlog.md, and any other changed files. Commit with a descriptive message:

```
docs: session end housekeeping — [brief description of what was updated]
```

## Step 11: Report completion

After completing all steps, report:
- Which files were updated (including any secondary trackers touched in Step 3b)
- Definition of Done self-evaluation result (all criteria met, or which gaps remain)
- What the next session should pick up (from project_resume.md)
- Whether any items need human attention (open questions, blockers, inconsistencies)

**Reconciliation check (hard block):** before finalising Step 10 (commit), verify that every finding ID referenced in this session's commit messages is now marked `[SHIPPED - YYYY-MM-DD]` (or explicitly `[DEFERRED]` / `[BLOCKED]`) in its tracker. Any ID still `[OPEN]` means Step 3b missed it — return to Step 3b and reconcile before committing. Do not proceed to Step 10 with unreconciled IDs.

Use `SESSION_RANGE` from Step 0a so the check partitions per-agent in parallel sessions — sibling agents' finding IDs in other branches do not count as this agent's drift.

```bash
if [ -n "$SESSION_RANGE" ]; then
  IDS=$(git log "$SESSION_RANGE" --format='%s' | grep -oE '\b[A-Z]+-?[0-9]+\b' | sort -u)
  for id in $IDS; do
    for tracker in $(detect_trackers); do  # same detection as Step 3b
      if grep -qE "^##+ .*${id}.*\[OPEN\]" "$tracker"; then
        echo "BLOCK: ${id} still [OPEN] in ${tracker}"
        exit 1
      fi
    done
  done
fi
```

When `SESSION_RANGE` is empty, the check is a no-op — correct for agents on the default branch directly.
