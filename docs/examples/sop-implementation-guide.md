# Implement the Agent SOP in Your Project

**Instructions for a Claude Code agent to set up the full SOP in any project folder.**

---

## Step 1 — Read the SOP

Read the full SOP document at `docs/sop/claude-agent-sop.md` (or wherever the user has provided it). Understand the two non-negotiable rules before creating any files:

1. **Never delete without a trace** — update in place, mark `[SUPERSEDED]`, or move to `## Archived`. In-place edits (status changes, corrections, folding answers) are fine. Silent removal is not.
2. **One source of truth** — each information type lives in exactly one file. Conflict precedence: code/git > `CLAUDE.md` > `Backlog.md` > build-plan > `feature-map.md` > `agent-memory.md` > `project_resume.md`.

---

## Step 2 — Choose your CLAUDE.md template

- **Non-code projects** (docs, markdown, scripts): use the base template structure.
- **Code projects** (web apps, APIs, anything with tests/DB/deployments): use the code template structure, which adds Auth, Database, Design System sections and code-specific build rules including the schema change protocol.

---

## Step 3 — Create the standard file set

Create these files in order. Fill in project-specific details — do not leave template placeholders.

### 3.1 — `CLAUDE.md` (project root)

Required sections:
- **Agent SOP** — reference to the SOP and the two non-negotiable rules, plus conflict precedence
- **Build Plans — READ FIRST** — link to `docs/build-plans/phase-0-foundation.md`
- **Key Documents & Dispatch** — single table with paths to all standard files (minimum 5 entries), test command, and after-shipping reminder
- **Current Priority Items** — OPEN/IN PROGRESS items only, grouped by priority tier
- **Backlog Management** — tag taxonomy and rules (process details live in the SOP, not here)
- **Stack** — technologies, hosting, CI, live URL (or n/a)
- **Key Commands** — the 3-5 most-used shell commands for this project
- **Rules for Automated Builds** — numbered rules, must include "never delete without a trace" and "update Backlog.md and feature-map.md when work ships"
- **Session & Memory Hygiene** — start checklist (5 steps) and end checklist (7 steps, test gate is step 1 for code projects)
- **Recent Work** — append-only, new entries at top, always include PR/commit refs
- **Deprioritised** — items moved here from priority lists, never removed

For code projects, also add: **Auth**, **Database**, **Design System**, **Code Quality Rules** sections.

Keep per-session sections under 200 lines / 2,000 tokens. Reference sections (Auth, DB, Design System, Code Quality) may extend beyond.

### 3.2 — `Backlog.md` (project root)

```markdown
# [Project Name] — Backlog

Single source of truth for all work items. Never delete without a trace — update in place, mark superseded, or archive.

## Tag Taxonomy

- Status (first): `[OPEN]` `[IN PROGRESS]` `[BLOCKED]` `[SHIPPED - YYYY-MM-DD]` `[VERIFIED - YYYY-MM-DD]` `[WON'T]`
- Type (second): `[Feature]` `[Iteration]` `[Bug]` `[Refactor]`
- Optional: `[has-open-questions]` `[ok-for-automation]`

---

## P-Numbered Items

### P1 — [first work item]
`[OPEN] [Feature]`

[Description]

**Acceptance criteria:**
- [criterion 1]
- [criterion 2]

---

## Shipped Archive

*Items below are shipped or verified. Never removed.*
```

Rules:
- P-numbers are sequential, never reused, do not imply priority.
- Tag order is always status first, type second.
- `[WON'T]` requires a reason: `[WON'T] [Type] — Reason: [explanation]`
- When the file exceeds ~2,000 lines, move shipped items older than 90 days to the Shipped Archive section.

### 3.3 — `docs/agent-memory.md`

```markdown
# Agent Memory

Shared context for all agents working on this project. Read at the start of every session. Update at the end. Never delete without a trace — update in place, mark superseded, or archive.

---

## Key Documents

See CLAUDE.md Key Documents table.

---

## Key Source Files for Current Work

*Updated at the start of each phase.*

| Area | File |
|------|------|
| [Area 1] | `[path]` |

---

## In-Flight Work

*(none)*

---

## Decisions Made

- [YYYY-MM-DD]: [first decision]

---

## Gotchas and Lessons

*(none yet)*

---

## [Project]'s Preferences

[Any agent behaviour preferences for this project]

---

## Completed Work

*(none yet)*

---

## Archived

*(none yet)*
```

Rules:
- Store facts any contributor needs: architectural decisions, data model invariants, named utility functions, framework patterns agents get wrong.
- Do NOT store derived facts (test counts, line numbers, dependency versions) — these go stale immediately. Store the rule, not the measurement.
- This file is committed to git. User-specific preferences go in local auto-memory (`~/.claude/projects/.../memory/`) instead.

### 3.4 — `docs/feature-map.md`

```markdown
# [Project Name] — Feature Map & Roadmap

Last updated: [YYYY-MM-DD]

---

## Shipped Documents/Features

| P# | Feature | Path/PR | Shipped |
|----|---------|---------|---------|

---

## Roadmap

### High Priority

| P# | Feature | Path |
|----|---------|------|

### Medium Priority

| P# | Feature | Path |
|----|---------|------|
```

### 3.5 — `docs/build-plans/phase-0-foundation.md`

```markdown
# Phase 0 — Foundation

Status: In Progress

---

## Problem

[What this phase solves]

## Scope

| Batch | What | Priority |
|-------|------|----------|

## Architecture

[Key technical decisions]

## Key Decisions Locked In

- [LOCKED] [decision 1]

## Batch Log

*Append-only. Format: YYYY-MM-DD: Batch N.X — description.*

## Deploy Checklist

- [ ] [verification step 1]

## Open Questions

*(none)*
```

---

## Step 4 — Create local files (not committed to git)

### 4.1 — `project_resume.md`

Location: `~/.claude/projects/[project-hash]/memory/project_resume.md`

This is a **snapshot**, not a log. Overwrite the entire file each session.

```markdown
# Session Resume — [Project Name]

Last updated: [YYYY-MM-DD]

## What was done
[2-4 lines]

## What is next
[Specific next action]

## Blockers
(none)
```

### 4.2 — `MEMORY.md`

Location: `~/.claude/projects/[project-hash]/memory/MEMORY.md`

One-line index of memory files. Each entry under ~150 characters.

---

## Step 5 — Verify the setup

Run through the session start checklist to confirm everything works:

1. Read `CLAUDE.md` — confirm all sections present
2. Read `MEMORY.md` — confirm it exists
3. Read `project_resume.md` — confirm it exists
4. Read `docs/agent-memory.md` — confirm all 8 sections present
5. Read `docs/build-plans/phase-0-foundation.md` — confirm structure
6. Run `git log --oneline -10`
7. Confirm `Backlog.md` has at least one P-numbered item
8. Confirm Dispatch Quick Reference in CLAUDE.md has at least 5 named files

---

## Step 6 — Commit

```bash
git add CLAUDE.md Backlog.md docs/agent-memory.md docs/feature-map.md docs/build-plans/phase-0-foundation.md
git commit -m "docs: implement Agent SOP — standard file set and session checklists"
```

---

## Step 7 — Optional: security, hooks, and agents

These are not required for basic SOP compliance but are recommended for code projects.

**Security guidance:** Copy `docs/sop/security.md` from the agent-sop repo to your project, or create a `## Security` section in CLAUDE.md covering your auth model, secret handling, and input validation.

**Hooks:** Create `.claude/settings.json` with at least SessionStart (auto-load context) and PreCompact (session-end reminder) hooks. See `docs/sop/hooks.md` in the agent-sop repo for 6 reference implementations with JSON config examples.

**Review agents:** Copy `code-reviewer.md` and `security-reviewer.md` from the agent-sop repo's `.claude/agents/` to your project's `.claude/agents/` directory. Customise the stack-specific sections for your project.

**Code quality rules:** For code projects, add a `## Code Quality Rules` section to CLAUDE.md specifying file size limits (800 max), test coverage threshold (80%), and language-specific conventions. The code template includes a ready-made section.

---

## Ongoing rules

**Every session start:** run the 5-step start checklist. No exceptions.

**Every session end:** run the 7-step end checklist. For code projects, step 1 is running tests. No exceptions. Wrap up at 60% context capacity — do not push to 95%.

**When files disagree:** code/git > CLAUDE.md > Backlog.md > build-plan > feature-map > agent-memory > resume point. Trust what you observe over what memory says.

**Memory separation:** `docs/agent-memory.md` (committed) is for facts any contributor needs. Auto-memory (local) is for user preferences and session state. Never store project-critical information only in auto-memory.

**Continuous learning:** After every session, extract reusable decisions and gotchas into `docs/agent-memory.md`. Every 5 sessions, audit for stale entries. When a pattern repeats 3+ times, promote it to a rule in CLAUDE.md.
