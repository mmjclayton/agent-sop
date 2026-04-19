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
