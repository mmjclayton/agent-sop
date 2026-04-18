---
description: Run the Agent SOP session end checklist. Updates all tracking files, writes the resume snapshot, and commits.
sop_version: "2026-04-19"
---

Execute the Agent SOP session end checklist. Complete every step below before the session ends. Do not skip any step. Never delete without a trace: update in place, mark superseded, or archive.

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

## Step 5: Update docs/agent-memory.md

- Append any architectural decisions to Decisions Made (format: `YYYY-MM-DD: Decision`)
- Append any gotchas, data model invariants, or framework patterns to Gotchas and Lessons
- Move any In-Flight Work entries that completed to Completed Work (format: `YYYY-MM-DD: description`)
- If new work started but did not finish, add it to In-Flight Work
- Mark any superseded entries `[SUPERSEDED - YYYY-MM-DD: reason]` and move to Archived
- Never delete entries

If `docs/agent-memory.md` does not exist (optional for projects with fewer than 10 sessions), skip this step.

## Step 6: Update build plan Batch Log

Find the current build plan file in `docs/build-plans/`. Append a new entry to the Batch Log:

Format: `YYYY-MM-DD: Batch N.X — description. Commit [hash] or PR #N.`

If no build plan exists for the current work, skip this step.

## Step 7: Update project_resume.md

Overwrite `~/.claude/projects/[project-hash]/memory/project_resume.md` with a fresh snapshot:

```
# Session Resume — [Project Name]

Last updated: [today's date]

## What was done
[2-4 lines summarising this session's work. Include commit hashes or PR numbers.]

## What is next
[Specific next action: file, function, or Backlog item.]

## Blockers
[(none) or specific blocker with context]
```

This file is a snapshot, not a log. Overwrite the entire content.

## Step 8: Update CLAUDE.md Recent Work

Add a new entry at the top of the Recent Work section in CLAUDE.md:

Format: `### YYYY-MM-DD: [summary] (commits [range] or PRs #N-#N)`

Keep to 2-3 lines. Include commit or PR references.

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
