---
description: Run the Agent SOP session end checklist. Updates all tracking files, writes the resume snapshot, and commits.
sop_version: "2026-04-19"
---

Execute the Agent SOP session end checklist. Complete every step below before the session ends. Do not skip any step. Never delete without a trace: update in place, mark superseded, or archive.

## Step 0: Resolve agent identity

Agent identity appears in filenames (`docs/recent-work/YYYY-MM-DD-<agent-id>-<slug>.md`), in per-agent `project_resume_<agent-id>.md`, and in commit-range partitioning routines (Step 3b, Step 11). Resolve it first so every subsequent step uses a consistent value.

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

1. Identify this session's commits that reference a finding ID — e.g. `fix(audit): A1`, `fix(security): H-3`, `feat(migration): M5`. Run `git log --format='%s' [since-last-/update-sop]` to enumerate.
2. For each referenced ID, locate the matching entry in the tracker and update its status tag: `[OPEN]` → `[SHIPPED - YYYY-MM-DD]`. Preserve the entry body. Never delete.
3. Update the tracker's `Last updated:` header (if present) to today's date.
4. Apply the same tag discipline as `Backlog.md`: status first, `[WON'T]` requires an inline reason, `[DEFERRED]` for intentional postponement.

Skip this step only if no `.md` files in Key Documents match the tracker detection. Projects with no secondary trackers see a no-op.

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
refresh_recent_work_rollup() {
  local claude_md="CLAUDE.md"
  local recent_dir="docs/recent-work"
  local tmp
  tmp=$(mktemp)

  {
    echo "<!-- recent-work-rollup:start -->"
    echo "*Auto-generated from \`docs/recent-work/\`. Last refreshed: $(date +%Y-%m-%d).*"
    echo ""

    local found=0
    if ls "$recent_dir"/*.md >/dev/null 2>&1; then
      for f in $(ls "$recent_dir"/*.md 2>/dev/null | sort -r); do
        [ "$(basename "$f")" = "README.md" ] && continue
        local fname title date_part agent_part
        fname=$(basename "$f" .md)
        date_part=$(printf '%s' "$fname" | cut -d_ -f1)
        agent_part=$(printf '%s' "$fname" | cut -d_ -f2)
        title=$(grep -m1 '^# ' "$f" | sed 's/^# //')
        [ -z "$title" ] && title="(untitled)"
        echo "- $date_part \`$agent_part\`: $title"
        found=1
      done
    fi

    [ "$found" = "0" ] && echo "*No entries yet.*"

    echo "<!-- recent-work-rollup:end -->"
  } > "$tmp"

  # Replace content between sentinels in CLAUDE.md
  awk -v repl_file="$tmp" '
    /<!-- recent-work-rollup:start -->/ {
      while ((getline line < repl_file) > 0) print line
      close(repl_file)
      skip = 1
      next
    }
    /<!-- recent-work-rollup:end -->/ {
      skip = 0
      next
    }
    !skip { print }
  ' "$claude_md" > "${claude_md}.tmp" && mv "${claude_md}.tmp" "$claude_md"

  rm -f "$tmp"
}

refresh_recent_work_rollup
```

Verify with: `grep -A 20 'recent-work-rollup:start' CLAUDE.md`

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

```bash
# Enumerate IDs referenced in this session's commits
git log --format='%s' [range] | grep -oE '\b[A-Z]+-?[0-9]+\b' | sort -u
# For each ID, grep the tracker files — any still-[OPEN] match is a block
```
