Execute the Agent SOP session end checklist. Complete every step below before the session ends. Do not skip any step. Never delete without a trace: update in place, mark superseded, or archive.

## Step 1: Run tests (code projects only)

If this is a code project with a test suite, run the full test suite now. Fix any failures before proceeding. If tests fail and cannot be fixed quickly, note the failures in agent-memory.md Gotchas and continue with the remaining steps.

Skip this step for documentation-only or markdown-only projects.

## Step 2: Update Backlog.md

- Update status tags for any items worked on this session (e.g. `[OPEN]` to `[IN PROGRESS]`, or `[IN PROGRESS]` to `[SHIPPED - YYYY-MM-DD]`)
- Append any new work items discovered during the session with `[OPEN]` status
- Add to the Shipped Archive if items were shipped
- Never delete items. Never remove items. Update in place.

## Step 3: Update docs/feature-map.md

- Add any newly shipped items to the Shipped table
- Move any roadmap items that shipped from the Roadmap section to the Shipped table
- Update the `Last updated` date at the top

## Step 4: Update docs/agent-memory.md

- Append any architectural decisions to Decisions Made (format: `YYYY-MM-DD: Decision`)
- Append any gotchas, data model invariants, or framework patterns to Gotchas and Lessons
- Move any In-Flight Work entries that completed to Completed Work (format: `YYYY-MM-DD: description`)
- If new work started but did not finish, add it to In-Flight Work
- Mark any superseded entries `[SUPERSEDED - YYYY-MM-DD: reason]` and move to Archived
- Never delete entries

## Step 5: Update build plan Batch Log

Find the current build plan file in `docs/build-plans/`. Append a new entry to the Batch Log:

Format: `YYYY-MM-DD: Batch N.X — description. Commit [hash] or PR #N.`

If no build plan exists for the current work, skip this step.

## Step 6: Update project_resume.md

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

## Step 7: Update CLAUDE.md Recent Work

Add a new entry at the top of the Recent Work section in CLAUDE.md:

Format: `### YYYY-MM-DD: [summary] (commits [range] or PRs #N-#N)`

Keep to 2-3 lines. Include commit or PR references.

## Step 8: Commit

Stage all modified docs/ files along with CLAUDE.md, Backlog.md, and any other changed files. Commit with a descriptive message:

```
docs: session end housekeeping — [brief description of what was updated]
```

## Step 9: Report completion

After completing all steps, report:
- Which files were updated
- What the next session should pick up (from project_resume.md)
- Whether any items need human attention (open questions, blockers, inconsistencies)
