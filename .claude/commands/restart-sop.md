---
description: Run the Agent SOP session start checklist. Reads all context files, checks git history, flags inconsistencies, and reports readiness before coding begins.
---

Start a new session by executing the Agent SOP session start checklist. Read every file listed below, in order. Do not skip any step.

## Determine checklist type

Check if this session's task is tagged `[ok-for-automation]` in the Backlog, or is a single-file change with fewer than 2 acceptance criteria. If so, use the **Lightweight Start** (steps 1L and 2L only). Otherwise, use the **Full Start** (steps 1-6).

---

## Full Start (default — use for multi-file tasks, features, bug fixes, refactors)

### Step 1: Read CLAUDE.md

Read the project's `CLAUDE.md` at the repo root. This is the master context file containing stack, conventions, Common Mistakes, intent-rich dispatch table, Definition of Done rubrics, priority items, and session checklists.

Pay special attention to:
- **Common Mistakes** — project-specific gotchas that prevent wrong turns
- **Key Documents & Dispatch** — intent-based table ("When you need to...")
- **Definition of Done** — self-evaluation rubrics by task type

### Step 2: Read memory files

Read these local memory files:
- `~/.claude/projects/[project-hash]/memory/MEMORY.md` (auto-memory index)
- `~/.claude/projects/[project-hash]/memory/project_resume.md` (last session snapshot)

If `project_resume.md` does not exist, note this and continue.

### Step 3: Read agent memory

Read `docs/agent-memory.md` (if it exists — optional for projects with fewer than 10 sessions). This contains cross-session decisions, gotchas, data model invariants, preferences, and in-flight work status.

Check the In-Flight Work section. If it is populated, the previous session was interrupted. Read the build plan Batch Log (linked from CLAUDE.md) before starting new work.

### Step 4: Check git history

Run `git log --oneline -10` and cross-check against:
- Recent Work in CLAUDE.md (do the commit refs match?)
- Completed Work in agent-memory.md (is anything missing?)
- project_resume.md "What was done" (does it match the latest commits?)

If anything is inconsistent, flag it before proceeding.

### Step 5: Read the current work item

Read the specific Backlog item(s) listed under Current Priority Items in CLAUDE.md. Read the full item in `Backlog.md` including acceptance criteria.

If there is an active build plan (linked in CLAUDE.md under Build Plans), read its Architecture and Batch Log sections.

### Step 6: Report readiness

After completing all reads, report:
- What the current priority item is
- Whether the previous session ended cleanly or was interrupted
- Any inconsistencies found between files
- Which Definition of Done rubric applies to this task type
- What you are ready to work on

Do not begin coding until you have completed all 6 steps.

---

## Lightweight Start (for `[ok-for-automation]` or single-file tasks)

### Step 1L: Read CLAUDE.md (targeted sections only)

Read the project's `CLAUDE.md`, focusing on:
- **Common Mistakes** — to avoid known gotchas
- **Key Documents & Dispatch** — to find the right file
- **Definition of Done** — to know the self-evaluation criteria

Skip: agent-memory.md, build plans, MEMORY.md, project_resume.md.

### Step 2L: Read the Backlog item

Read the specific item from `Backlog.md` including acceptance criteria. Then begin work.

Saves ~3-4K tokens compared to the full start. Use only when the task is truly self-contained.
