# Claude Code Agent SOP
**Standard Operating Procedure — All Projects**
Last updated: 2026-04-09

---

## Quick Reference Card

*For agents already familiar with this SOP. If this is your first session on a project using this SOP, read the full document before using this card.*

**Two non-negotiable rules (cannot be overridden by CLAUDE.md):**
1. Never delete without a trace — update in place, mark `[SUPERSEDED]`, move to `## Archived`. In-place updates (status changes, folding answers into items, correcting errors) are expected. Silent removal is not.
2. One source of truth — information lives in exactly one file. Conflict precedence: code/git > `Backlog.md` > build-plan > `feature-map.md` > `agent-memory.md` > `project_resume.md`.

**Key limits:**
- CLAUDE.md: per-session sections max 200 lines / 2,000 tokens. Reference sections (Auth, DB, Design System) may extend beyond. Overflow goes to `docs/agent-memory.md` or build plans.
- Context: wrap up and run session end checklist at 60% capacity. Do not push to 95%.
- Auto-memory: unreliable - do not depend on it. `docs/agent-memory.md` is the source of truth.

**Session start: run `/restart-sop` (every session, no exceptions).**
If the command is not available, execute manually:
1. Read CLAUDE.md
2. Read `MEMORY.md` + `project_resume.md`
3. Read `docs/agent-memory.md`
4. Run `git log --oneline -10`, cross-check memory against current file state
5. Read the Backlog item(s) for this session
- If In-Flight Work is populated or `project_resume.md` has no What's Next — previous session was interrupted. Read the build plan Batch Log before starting anything new.

**Session end: run `/update-sop` (every session, no exceptions).**
If the command is not available, execute manually:
1. Run tests (code projects) — fix failures before proceeding
2. `Backlog.md` — update status tags in place, append new items
3. `docs/feature-map.md` — append shipped items
4. `docs/agent-memory.md` — append decisions/gotchas, move completed to `## Completed Work`
5. `docs/build-plans/phase-N.md` — append to Batch Log
6. `project_resume.md` — overwrite with current state (snapshot, not a log)
7. Commit `docs/` changes with the work

**Section index (for targeted reads — update line ranges when sections change):**

| Section | Lines |
|---------|-------|
| Non-Negotiable Rules (Section 0) | 39-76 |
| Standard File Set (Section 1) | 85-129 |
| File Ownership Rules (Section 2) | 132-144 |
| File Structure Specs (Section 3) | 147-241 |
| Versioning Rules (Section 4) | 293-306 |
| Session Checklists (Sections 5-6) | 309-348 |
| Update Triggers (Section 7) | 351-368 |
| Backlog Tag Taxonomy (Section 8) | 371-401 |
| P-Number System (Section 9) | 404-411 |
| Issue Tracker Sync (Section 10) | 414-423 |
| Dispatch Quick Reference (Section 11) | 426-435 |
| Optional Patterns (Section 12) | 438-520 |
| New Project Setup (Section 13) | 523-542 |
| Common Mistakes (Section 14) | 545-577 |
| Benchmark-Proven Practices (Section 15) | 579-680 |
| Multi-Agent Context Routing (Section 16) | 682-770 |
| Managed Agents Integration (Section 17) | 772-850 |

---

## Section 0: Non-Negotiable Rules

These two rules override everything else in this document. Read them first. Apply them without exception.

**Rule 1 — Never delete without a trace.**
No agent may silently remove content from any project document. In-place updates are expected and necessary — changing a status tag, folding an answered question into an item body, correcting an error. The rule is about preserving history, not preventing edits.

How this works:
- Decisions, gotchas, preferences: append new entries, dated. Mark old ones `[SUPERSEDED - YYYY-MM-DD: reason]` and move to `## Archived`.
- In-flight work: when work completes, move the entry to `## Completed Work`.
- Backlog items: update status tags and item bodies in place. Never remove the item.
- Build plans: append to Batch Log. Mark locked decisions `[LOCKED]`. Never rewrite existing log entries.
- Priority lists: append new items, move deprioritised items to `## Deprioritised`. Never remove.
- project_resume.md: overwrite each session — this is a snapshot, not a log. Historical context belongs in build-plan batch logs.
- Memory files: mark stale files `Status: Superseded - YYYY-MM-DD`. Never delete the file.

Git history is the backstop for in-repo files, but documents must remain human-readable records without requiring a git dig.

**Rule 2 — One source of truth per information type.**
Information lives in exactly one file. Never duplicate it. When files disagree, resolve using this precedence order:

1. **Code and git state** — what the code actually does and what git shows always wins
2. **`CLAUDE.md`** — authoritative for project-specific rules and conventions
3. **`Backlog.md`** — authoritative for work item status
4. **`docs/build-plans/phase-N.md`** — authoritative for phase architecture and decisions
5. **`docs/feature-map.md`** — authoritative for shipped feature inventory
6. **`docs/agent-memory.md`** — cross-session context (decisions, gotchas, invariants)
7. **`project_resume.md`** — lowest precedence, point-in-time snapshot only

If `agent-memory.md` contradicts the code, the code wins — update the memory. If `feature-map.md` is stale relative to `Backlog.md`, trust the Backlog and update the feature map.

**Override hierarchy:** `CLAUDE.md` can override any project-specific convention defined in this SOP (tag taxonomy, file paths, stack-specific rules). It cannot override the two non-negotiable rules above. Never-delete-without-a-trace and single source of truth apply to every project regardless of what CLAUDE.md says.

**Multi-agent contention:** When multiple agents work on the same project simultaneously, each agent must work on a separate branch and merge to main sequentially. Conflict resolution depends on the file type:
- **Documentation files** (`agent-memory.md`, `Backlog.md`, `feature-map.md`): resolve by appending both entries — never discard either agent's additions.
- **Code files**: cannot be resolved by concatenation. The agent merging second must read both versions, understand the intent, and produce a correct merge. If the conflict is non-trivial, flag it in `docs/agent-memory.md` Gotchas for human resolution rather than guessing.
- **Semantic conflicts** (e.g. two agents shipped the same P-number, or conflicting architectural decisions): always flag in `docs/agent-memory.md` Gotchas for human resolution.

---

## Purpose

This SOP defines the standard file structure, naming conventions, update rules, and session checklists that all Claude Code agents must follow across every project. Consistent implementation means agents start every session with full context, never duplicate information, and leave every session in a state the next agent can pick up immediately.

---

## 1. Standard File Set

Every project must have the following files. Create them at project initialisation. Never rename or move them.

### In-repo files (committed to git)

| File | Path | Owner | Purpose |
|------|------|-------|---------|
| Project instructions | `CLAUDE.md` | Human + Agent | Stack, conventions, dispatch reference, rules. Master context file. |
| Backlog | `Backlog.md` | Human + Agent | Single source of truth for all work items. |
| Agent memory | `docs/agent-memory.md` | Agent | Permanent cross-session context: decisions, gotchas, data model invariants, preferences. Read and updated every session. **Optional for projects with fewer than 10 sessions** — CLAUDE.md is the mandatory context source; agent-memory becomes valuable once decisions accumulate. |
| Feature map | `docs/feature-map.md` | Agent | Inventory of shipped features and prioritised roadmap. |
| Build plans | `docs/build-plans/phase-N-[name].md` | Agent | Phase-level architecture, batch logs, deploy checklists. One file per phase. |

### Optional in-repo files (create when relevant)

| File | Path | Purpose |
|------|------|---------|
| Brand voice | `.claude/brand-voice.md` | Copy rules, tone, terminology. Required for any project with user-facing text. |
| Other AI config | `.claude/[name].md` | Project-specific guidance for agents that doesn't belong in CLAUDE.md. |

### Machine-local files (not committed)

| File | Path | Purpose |
|------|------|---------|
| Auto-memory index | `~/.claude/projects/[project-hash]/memory/MEMORY.md` | Index of all memory files. Maintained automatically. |
| Memory files | `~/.claude/projects/[project-hash]/memory/[type]_[topic].md` | Individual memory entries. Types: `user`, `feedback`, `project`, `reference`. |
| Resume point | `~/.claude/projects/[project-hash]/memory/project_resume.md` | Per-session handoff: what was done, what is next, any blockers. Updated every session end. |

**Two memory systems — clear separation:**
Claude Code has two memory systems. They serve different purposes and must not overlap:

| System | Location | What belongs here | Committed to git? |
|--------|----------|-------------------|-------------------|
| `docs/agent-memory.md` | In-repo | Facts any contributor needs: architectural decisions, data model invariants, gotchas, named utility functions, project preferences | Yes |
| Auto-memory (`~/.claude/.../memory/`) | Local machine | User-specific preferences, session state, personal workflow notes, feedback on agent behaviour | No |

**Rule of thumb:** if a different developer (or a different machine) would need this information, it goes in `docs/agent-memory.md`. If it is about how *this user* prefers to work, it goes in auto-memory.

**Reliability warning:** Auto-memory recall is unreliable — stored rules are frequently not applied in subsequent sessions (multiple confirmed community reports as of 2026). `docs/agent-memory.md` is the authoritative cross-session context source. Never store project-critical information only in auto-memory.

**Filename rule:** The resume file is always named `project_resume.md`. Do not use project-specific prefixes (e.g. `project_loadout_resume.md`). Projects using a prefixed name should rename to `project_resume.md` as part of their SOP migration.

**Distinction:** `docs/agent-memory.md` is permanent cross-session context (architectural decisions, data model invariants, named utility functions, patterns) — committed to git, visible to all contributors. `project_resume.md` is a point-in-time snapshot (where the project stands, what is next) — local, overwritten each session. Different purpose, different audience. Never confuse them.

**API primitive:** The Claude API `memory_20250818` tool is the underlying mechanism for file-backed persistent notes. The SOP's `docs/agent-memory.md` is the manual, git-committed equivalent. For Managed Agents API sessions, use memory stores instead (see Section 17). When using tool-result clearing, always exclude the memory tool from clearing — see `docs/sop/context-management.md`.

---

## 2. File Ownership Rules

| Information type | Lives in | Never in |
|-----------------|----------|----------|
| Work item status | `Backlog.md` | Build plans, agent-memory.md |
| Phase architecture and decisions | `docs/build-plans/phase-N.md` | CLAUDE.md, agent-memory.md |
| Shipped feature inventory | `docs/feature-map.md` | CLAUDE.md |
| Stack, conventions, hard rules | `CLAUDE.md` | agent-memory.md |
| Cross-session decisions, gotchas, invariants | `docs/agent-memory.md` | CLAUDE.md |
| Per-session handoff | `project_resume.md` (local) | Any in-repo file |
| Brand and copy rules | `.claude/brand-voice.md` | CLAUDE.md, agent-memory.md |
| Long-term feedback and preferences | `~/.claude/memory/` files | In-repo files |

---

## 3. File Structure Specs

### CLAUDE.md

```
# [Project Name] — [One-line description]

> [Brand tagline]

## Agent SOP
[Reference to this SOP document]

## Build Plans — READ FIRST
[Links to current phase files with status emoji]

## Key Documents & Dispatch
[Table: Area | File | Purpose — minimum 5 entries]
[Include line-range hints for large files, e.g. "CSS tokens — client/src/index.css (lines 1-80)"]
[Test command + after-shipping reminder]

## Current Priority Items
[OPEN/IN PROGRESS items only — shipped items tracked in Backlog.md]

## Backlog Management
[Tag taxonomy + rules. Process details in the SOP, not here.]

## Stack
[Frontend / Backend / Hosting / CI — include live URL]

## Key Commands
[bash commands for dev, test, migrate]

## Auth / Database / Design System
[Project-specific sections as needed]

## Rules for Automated Builds
[Numbered, non-negotiable rules]

## Session & Memory Hygiene
[Start checklist / End checklist]

## Recent Work
[Append-only. New sessions at top. Format: Date, PR numbers, 2-3 line summary.]

## Deprioritised
[Items moved here from priority lists. Never removed from this section.]
```

### docs/agent-memory.md

```
# Agent Memory

Shared context for all agents. Read this at the start of every session.
Update this at the end of every session. Additive only — nothing is ever deleted.

## Key Documents
[Do not duplicate the table from CLAUDE.md. Instead: "See CLAUDE.md Key Documents table." Add line-range hints here only for files not listed in CLAUDE.md.]

## Key Source Files for Current Work
[Table: Area | File | Notes — updated at the start of each phase, not each session]

## In-Flight Work
[What is currently being built. When work completes, move entry to ## Completed Work. Never delete.]

## Decisions Made
[YYYY-MM-DD: Decision. One line per decision. Append only.
If superseded: mark [SUPERSEDED - YYYY-MM-DD: replaced by X] and move to ## Archived.]

## Gotchas and Lessons
[Non-obvious things that burned time, data model invariants, named utility functions.
Append only. Mark stale entries [SUPERSEDED - YYYY-MM-DD] and move to ## Archived.]

## [Project]'s Preferences
[Agent behaviour preferences for this project. Append only.]

## Completed Work
[Entries moved from In-Flight Work when done. Format: YYYY-MM-DD: description — PR #N]

## Archived
[Superseded decisions and gotchas. Format: [SUPERSEDED - YYYY-MM-DD: reason] original entry]
```

**Template variants:** Two CLAUDE.md templates exist in `docs/templates/`: `claude-md-template-base.md` for any project type (markdown, scripts, docs), and `claude-md-template-code.md` for full-stack code projects (adds Auth, Database, Design System, and code-specific build rules). Always start from the base template and add the code sections only if needed.

**CLAUDE.md size limit:** Keep the per-session sections of CLAUDE.md under 200 lines / 2,000 tokens for non-code projects, or **300 lines / 3,000 tokens for code projects that include a Common Mistakes section** (benchmark data shows the extra ~100 lines for Common Mistakes pays for itself in fewer wrong turns and prevented production bugs). Per-session sections are everything an agent reads every session: Agent SOP, Build Plans, Key Documents, Priority Items, Backlog Management, Key Commands, Common Mistakes, Rules for Automated Builds, Session & Memory Hygiene, Dispatch Quick Reference, and Recent Work. Project-specific reference sections (Auth, Database, Design System, and similar) may extend beyond the target — these are consulted on demand, not read every session, so their context cost is incurred only when relevant. If per-session sections are growing beyond the limit, move detail into `docs/agent-memory.md`, build plans, or source-file comments.

**Token overhead:** Every file read by an agent costs approximately 1.7x its raw token count (loading and processing overhead). This is why the size limit matters and why the Dispatch Quick Reference enforces a minimum rather than a maximum. Keep referenced files lean and targeted. Line-range hints (e.g. "CSS tokens - client/src/index.css lines 1-80") reduce overhead significantly for large files.

**What belongs in Gotchas:** not just lessons from mistakes, but also: data model invariants that aren't obvious from the schema (e.g. "ExerciseCategory is the shared library, Exercise is program-scoped - edits go to taxonomyOverrides"), named utility functions for cross-cutting concerns (e.g. "use displayMuscleGroup() for all muscle group display logic"), and framework-specific patterns that agents commonly get wrong.

**What does NOT belong in agent-memory.md:** derived facts that go stale — test counts, line numbers, file sizes, dependency versions. These are always cheaper to check at runtime than to maintain in a document. Store the *rule* ("always run tests before push") not the *measurement* ("test suite has 847 tests").

### docs/build-plans/phase-N-[name].md

```
# Phase N — [Name]

Status: [emoji] [Planning / In Progress / Shipped YYYY-MM-DD]

## Problem
[What the phase solves]

## Scope
[Table: Batch | What | Priority]

## Architecture
[Key technical decisions and approach]

## Key Decisions Locked In
[Bullet list marked [LOCKED] — not re-opened without explicit instruction]

## Batch Log
[Append-only. Format: YYYY-MM-DD: Batch N.X shipped — PR #N, #N. Description.]

## Deploy Checklist
[Steps to verify before marking the phase shipped]

## Open Questions
[Pending questions. Answered questions stay here, marked [RESOLVED - YYYY-MM-DD: answer]]
```

### project_resume.md (local, overwrite each session)

This file is a **snapshot**, not a log. Overwrite the entire content each session. Historical context belongs in build-plan batch logs.

```
# Session Resume — [Project Name]

Last updated: YYYY-MM-DD

## What was done
[2-4 lines. PR numbers where applicable.]

## What is next
[Specific next action — file, function, or Backlog item.]

## Blockers
[(none) or specific blocker with context]
```

---

## 4. Versioning Rules

Never delete without a trace. Update in place, mark superseded, or archive. See Section 0.

| File | Versioning approach |
|------|-------------------|
| `CLAUDE.md` | Update in place. Deprioritised items move to `## Deprioritised`. Recent Work appended at top. |
| `Backlog.md` | Status tags updated in place with dates. Items never deleted. |
| `docs/agent-memory.md` | Append-only. Superseded entries marked and moved to `## Archived`. |
| `docs/feature-map.md` | `Last updated: YYYY-MM-DD` header. Shipped features appended. Roadmap items move between tiers, never removed. |
| `docs/build-plans/` | One file per phase. Frozen once shipped — Batch Log only. New phase = new file. |
| `project_resume.md` | Overwrite each session. Snapshot of current state, not a log. |
| Memory files | Update in place with `Updated: YYYY-MM-DD`. Stale: `Status: Superseded` in frontmatter. Never delete. |

---

## 5. Session Start Checklist

**Every agent, every session, every project. No exceptions.**

**Run `/restart-sop` at the start of every session.** This slash command (installed via `.claude/commands/restart-sop.md`) automates the full checklist below. If the command is not available, execute the steps manually.

```
1. Read CLAUDE.md
2. Read MEMORY.md + project_resume.md
3. Read docs/agent-memory.md
4. Run git log --oneline -10, cross-check memory against current file state
5. Read the Backlog item(s) for this session
```

- If In-Flight Work is populated or `project_resume.md` has no What's Next — previous session was interrupted. Read the build plan Batch Log before starting anything new.
- Source files from the Key Source Files table in `agent-memory.md` are read as work begins, not as a checklist ceremony.

**Lightweight start (for small, scoped tasks):**
Tasks tagged `[ok-for-automation]` or single-file changes with fewer than 2 acceptance criteria may use a reduced checklist:
```
1. Read CLAUDE.md (specifically: Common Mistakes + Dispatch sections)
2. Read the Backlog item for this task
```
Skip agent-memory.md, build plans, and MEMORY.md/project_resume.md. The lightweight start saves ~3-4K tokens per session. Use the full checklist for any task that touches multiple files, requires data model knowledge, or involves architectural decisions.

---

## 6. Session End Checklist

**Run `/update-sop` at the end of every session.** This slash command (installed via `.claude/commands/update-sop.md`) automates the full checklist below. If the command is not available, execute the steps manually. Never-delete-without-a-trace applies to every step.

```
1. Run tests (code projects) — fix failures before proceeding
2. Backlog.md — update status tags in place, append new items
3. docs/feature-map.md — append shipped items
4. docs/agent-memory.md — append decisions/gotchas, move completed to ## Completed Work
5. docs/build-plans/phase-N.md — append to Batch Log
6. project_resume.md — overwrite with current state (snapshot, not a log)
7. Commit docs/ changes with the work
```

**Context compaction threshold:** When context reaches approximately 60% capacity, wrap up the current batch and run `/update-sop` (or complete the session end checklist manually) before continuing. Do not push to 95% — compaction at that point causes context loss and unreliable behaviour in the remainder of the session. Treat 60% as the session boundary signal, not a warning to ignore.

---

## 7. Update Triggers

| Trigger | Files to update |
|---------|----------------|
| Feature ships to production | `Backlog.md` (→ SHIPPED), `docs/feature-map.md` |
| Feature verified in production | `Backlog.md` (→ VERIFIED) |
| New work item identified | `Backlog.md` (append with [OPEN]) |
| Work item starts | `Backlog.md` (→ IN PROGRESS), create GitHub issue |
| Architectural decision made | `docs/build-plans/phase-N.md`, `docs/agent-memory.md` |
| Data model invariant or utility function identified | `docs/agent-memory.md` (Gotchas section) |
| Non-obvious lesson learned | `docs/agent-memory.md` (Gotchas section) |
| Phase completes | `docs/build-plans/phase-N.md` (status → Shipped, Batch Log final), `docs/feature-map.md` |
| New phase starts | Create `docs/build-plans/phase-N+1.md`, update CLAUDE.md Build Plans, update Key Source Files in agent-memory.md |
| Stack or convention changes | `CLAUDE.md` |
| Copy or tone rule established | `.claude/brand-voice.md` |
| Key Documents table updated in either CLAUDE.md or agent-memory.md | Update the other file to match. `CLAUDE.md` is authoritative if they conflict. |
| Session ends | `project_resume.md` (overwrite with snapshot), `docs/agent-memory.md` (In-Flight) |

---

## 8. Backlog Tag Taxonomy

**Status (always first, always one):**
- `[OPEN]` - not started
- `[IN PROGRESS]` - active work
- `[BLOCKED]` - waiting on something external
- `[SHIPPED - YYYY-MM-DD]` - merged to main and deployed
- `[VERIFIED - YYYY-MM-DD]` - confirmed correct in the live environment. For code projects: tested in production. For documentation projects: reviewed by the project owner and confirmed accurate and complete. For other project types: define what verified means in CLAUDE.md.
- `[WON'T]` - decision not to build. Required format: `[WON'T] [Type] — Reason: [one-line explanation or superseding P-number]`

**Type (always second, always one):**
- `[Feature]` - new capability
- `[Iteration]` - improvement to existing capability
- `[Bug]` - something broken
- `[Refactor]` - code quality, no user-visible change

**Optional (can combine, never used alone):**
- `[has-open-questions]` - cannot be automated, needs human input first
- `[ok-for-automation]` - qualifies for the auto-pipeline (see criteria below)

**Automation qualification — all must be true:**
- Small blast radius (one file, component, or route)
- At least 2 concrete acceptance criteria
- Names the specific file/component to change
- No `[has-open-questions]` tag
- Reversible

**Tag order:** Status first. Type second. Optional last. Never reverse.

**Backlog archive threshold:** When `Backlog.md` exceeds approximately 2,000 lines, move all `[SHIPPED]` and `[VERIFIED]` items older than 90 days to a `## Shipped Archive` section at the bottom of the file (or to a separate `docs/backlog-archive.md` if preferred). Items in the archive retain their full content and are never deleted.

---

## 9. P-Number System

- Assign sequentially. Never reuse a P-number.
- P-numbers do not imply priority — priority is set explicitly in CLAUDE.md.
- Priority tiers: Very High / High / Medium / Low / Won't Build.
- When superseded: mark old item `[WON'T]` and reference the superseding P-number.
- No P-number = operational work (infra, in-session bug fixes, migrations).

---

## 10. Issue Tracker Sync Rules

- Issues are lazy-created: only when an item moves to `[IN PROGRESS]`.
- `Backlog.md` is always authoritative. The issue tracker (GitHub, GitLab, Linear, or equivalent) is downstream.
- Close the issue in the same PR or commit that ships the work.
- Branch naming: `<type>/<short-slug>` — type matches the Backlog type tag.
- Conventional commits: `feat:`, `fix:`, `test:`, `refactor:`, `docs:`
- Recent Work entries in CLAUDE.md must include PR or commit reference ranges (e.g. "PRs #65-#94" or "commits abc123-def456"). For documentation-only projects with no PRs, use the commit hash range.
- Projects with no issue tracker: skip issue creation entirely. `Backlog.md` is the only tracker.

---

## 11. Key Documents & Dispatch (Required Section)

Every project's CLAUDE.md must include a Key Documents & Dispatch section. Requirements:

- **Intent-based format required.** Use "When you need to..." column headers, not "Area | File". Benchmark data shows intent-based dispatch reduces tool calls by 50% on complex tasks (agents go directly to the right file instead of exploring). The old "Area | File" format is deprecated.
- Minimum 5 named entry-point files with full relative paths
- Notes column must include contextual guidance (related components, gotchas, constraints)
- Updated at the start of each phase — not just at project setup
- Include line-range hints for large files (e.g. "CSS tokens — client/src/index.css (lines 1-80)")
- Include test command and after-shipping reminder

**Correct format:**
```
| When you need to... | Start at | Notes |
|---------------------|----------|-------|
| Change X | `path/to/file` | Related component is Y. Watch out for Z. |
```

**Deprecated format (do not use):**
```
| Area | File |
|------|------|
| X | `path/to/file` |
```

This section is what allows an agent dropped into the middle of a project to orient in under 2 minutes.

---

## 12. Optional Patterns for Large Projects

These patterns are optional. Add them when complexity warrants it - they are not required for standard projects.

### claude-progress.txt (human-readable status file)

For large features spanning multiple sessions, maintain a `claude-progress.txt` at project root. Unlike `project_resume.md` (agent-facing, prepend-only), this file is human-readable at a glance and updated in-place each session.

Recommended format:
```
Current task: [P-number and short name]
Status: [In Progress / Blocked / Ready for review]
Completed: [bullet list of done steps]
Next: [specific next action]
Blockers: [(none) or description]
Last updated: YYYY-MM-DD
```

Do not add `claude-progress.txt` to `.gitignore` - it is a useful artefact for project owners to check without opening Claude Code.

### Sub-agent delegation (.claude/agents/)

For projects where parallel work is feasible, Claude Code supports named sub-agents defined as markdown files in `.claude/agents/[name].md`. Each sub-agent receives its own system prompt and optional tool restrictions.

Use cases: a `test-runner` agent that only runs test suites and reports results, a `migration-agent` that handles database schema changes, or a `docs-agent` restricted to documentation updates only.

Each agent file format:
```
---
name: [agent-name]
description: [one-line purpose — used by the orchestrator to decide when to delegate]
tools: [optional comma-separated tool restrictions]
---

[Agent system prompt here]
```

Sub-agents add coordination overhead. Only introduce them when a project has clearly separable workstreams that would otherwise require sequential single-agent effort.

### Schema change protocol (projects with a database)

Any change to the data model must follow this sequence. Do not skip steps or reorder.

```
1. Edit the schema definition (ORM model, SQL, or equivalent)
2. Create and run the migration
3. Update server routes / API handlers that touch the changed model
4. Update client code that consumes the changed data
5. Add or update tests covering the change
6. Verify the full test suite passes
```

Add this checklist to the project's CLAUDE.md under Rules for Automated Builds. The SOP templates include it in the code variant (`claude-md-template-code.md`).

### Continuous learning (pattern extraction across sessions)

Agent sessions produce reusable decisions, gotchas, and patterns that are valuable beyond the current session. Continuous learning is the practice of systematically extracting these patterns and persisting them for future sessions.

**What to extract:**
- Decisions that resolved ambiguity (e.g. "use displayMuscleGroup() for all muscle group display logic")
- Data model invariants that are not obvious from the schema
- Framework-specific patterns that agents commonly get wrong
- Workarounds for library or tooling quirks
- Error resolutions that took significant debugging effort

**Where to store extracted patterns:**
- `docs/agent-memory.md` -- for facts any contributor needs (decisions, invariants, gotchas, named utility functions)
- Auto-memory (`~/.claude/projects/.../memory/`) -- for user preferences, feedback on agent behaviour, session-specific notes

**Extraction cadence:**
- After every session: extract decisions and gotchas as part of the session end checklist (step 4)
- Every 5 sessions: audit `docs/agent-memory.md` for stale or redundant entries. Mark outdated entries `[SUPERSEDED]` and move to `## Archived`
- When a pattern repeats across 3+ sessions: promote it from a gotcha to a rule in CLAUDE.md or a dedicated `.claude/rules/` file

**Automated extraction (optional):**
Claude Code hooks can automate pattern detection. A `Stop` hook can evaluate each agent response for extractable patterns and prompt the agent to persist them. See `docs/sop/hooks.md` for reference implementations.

**What does NOT belong in extracted patterns:**
- Derived facts (test counts, line numbers, dependency versions) -- these go stale immediately
- One-time fixes or typo corrections
- External API issues or transient errors
- Information already documented in CLAUDE.md or the codebase

### Outcome rubrics (self-evaluation before shipping)

An outcome rubric defines what "done" looks like for a task type. The agent evaluates its own work against the rubric before committing. Benchmark data shows rubric-based evaluation catches quality gaps that checklist-based approaches miss — the rubric forces the agent to verify results against specific criteria rather than simply confirming steps were followed.

**Add a `## Definition of Done` section to CLAUDE.md** with per-task-type rubrics. The agent reads the relevant rubric before committing and self-evaluates. If any criterion is not met, it iterates before shipping.

Example rubrics by task type:

**Bug fix:**
```markdown
- Root cause identified from reading the actual code — do not infer root cause from documentation alone
- Fix is minimal: change the broken logic, do not remove working mechanisms
- Fix applied to ALL instances of the pattern (grep for similar occurrences)
- No regressions — full test suite passes
- New test covers the specific bug scenario
- Fix uses existing project utilities where they exist (check Common Mistakes section)
- Commit message explains the root cause, not just what changed
```

**Feature:**
```markdown
- All acceptance criteria from the Backlog item are met
- Server endpoint has integration tests (real DB, not mocks)
- Client component has unit tests for logic
- UI follows design system (CSS tokens, touch targets, responsive breakpoints)
- Brand voice followed in all user-facing copy
- No console.log or debug artifacts
- Backlog.md and feature-map.md updated in the same commit
```

**Refactor:**
```markdown
- Behaviour is unchanged — all existing tests pass without modification
- If tests needed updating, the change was in test assertions matching new implementation (not weakening tests)
- No unrelated files modified
- New pattern is consistent with existing codebase conventions
- Dead code from the old pattern is removed (not commented out)
```

**Test writing:**
```markdown
- Tests cover the actual behaviour of the code, not just the happy path
- Edge cases tested: null/undefined inputs, empty collections, boundary values
- Test names describe the behaviour under test (not the implementation)
- Tests follow existing patterns in the test file (describe blocks, naming, helpers)
- No production code modified
- All tests pass
```

These rubrics work with Claude Managed Agents' `user.define_outcome` API (which provisions an independent grader), but are equally effective as self-evaluation prompts in Claude Code sessions — the agent reads the rubric from CLAUDE.md and checks its own work before committing.

---

## 13. Applying This SOP to a New Project

1. Copy `claude-md-template.md` and fill in project-specific sections.
2. Create `Backlog.md` with the tag taxonomy header and first items.
3. Create `docs/agent-memory.md` with all sections (including empty Completed Work and Archived).
4. Create `docs/feature-map.md` with `Last updated` header and empty Shipped/Roadmap sections.
5. Create `docs/build-plans/phase-0-foundation.md`.
6. Create `.claude/brand-voice.md` if the project has user-facing copy.
7. On first Claude Code session: confirm MEMORY.md path, create `project_resume.md`.

**When to start a new phase:** A new phase begins when the current phase's Deploy Checklist is complete, or when the scope shifts to a meaningfully different set of capabilities or users — even if some items from the previous phase remain open. A rule of thumb: if the next batch of work would require rewriting more than half of the current build plan's Architecture section, it warrants a new phase. Carry-over items from the previous phase are added to the new phase's Scope table rather than re-opened in the old phase file.

**Minimum viable setup for existing projects being migrated:**
1. Audit existing files against the standard file set.
2. Add Completed Work and Archived sections to docs/agent-memory.md.
3. Replace the session checklists in CLAUDE.md with the standard ones from this SOP.
4. Add project_resume.md to the MEMORY.md index if missing.
5. Add line-range hints to the Key Documents table for any file over 200 lines.
6. Verify Dispatch Quick Reference has at least 5 named files and is current.

---

## 14. Common Mistakes to Avoid

| Mistake | Why it matters | Correct approach |
|---------|----------------|-----------------|
| Silently removing content | Destroys project history, may erase still-relevant decisions | Update in place, mark superseded, or move to Archived — never silently delete |
| Appending to project_resume.md instead of overwriting | Bloats the file with history that belongs in batch logs | Overwrite with current snapshot each session |
| Removing stale entries from agent-memory.md | Agents shouldn't unilaterally decide what's stale | Move to Archived with a superseded date |
| Confusing agent-memory.md with project_resume.md | Different purposes - permanent context vs point-in-time handoff | Permanent patterns go in agent-memory.md, session state goes in project_resume.md |
| Putting work item status in build plans | Agents check Backlog.md - build plans drift | Status only in Backlog.md |
| Updating feature-map.md but not Backlog.md | Next agent sees inconsistent state | Always update both together |
| Leaving In-Flight Work populated after shipping | Next agent thinks work is still active | Move to Completed Work with date and PR number |
| Not dating decisions in agent-memory.md | Stale decisions can't be identified | Always format as `YYYY-MM-DD: Decision` |
| Gotchas section limited to "mistakes" only | Data model invariants and utility functions get lost | Gotchas covers invariants, named utility functions, and framework patterns too |
| Dispatch Quick Reference listing vague entry points | Agents can't orient quickly | Name specific files with full paths - update each phase |
| Recent Work with no PR numbers | Can't cross-reference with git history | Always include PR number range |
| Storing derived facts in memory (test counts, line numbers, versions) | Goes stale immediately, misleads future agents | Store the rule, not the measurement — check at runtime |
| Skipping tests before committing (code projects) | Broken code ships, next session starts with failures | Run the test suite as step 1 of session-end checklist |
| Skipping session end checklist for "small changes" | Small changes compound into context debt | No exceptions |

---

## 15. Benchmark-Proven Practices

*The following practices are backed by A/B benchmark data (SOP vs no-SOP agents on identical tasks). They produced a 33% quality improvement on vague, context-dependent tasks. See `docs/benchmark/results/` for full methodology and data.*

### 15.1 Common Mistakes Section (Required for Code Projects)

Every code project's CLAUDE.md must include a `## Common Mistakes` section with project-specific gotcha callouts. This is the single highest-value section for agent quality — it directly prevented production bugs in benchmark testing.

**Structure the section by area:**

```
## Common Mistakes — Read Before Coding

### Data Model
- [Model X] is GLOBAL. Never filter by userId. [Model Y] is user-scoped.
- [Field] is derived, not stored. Never add a column for it.
- [Table.column] is scoped to [constraint], not globally unique.

### Client
- [Component A] is its own file, not inside [Component B].
- The default view is [view name]. When referring to "home", it is [key].
- [Component] exists at [path]. Check for it before creating a similar one.
- CSS colours must use [token prefix] tokens only. Never hardcode hex.

### Server
- Every query filters by [user field] via [relation]. Never query without it.
- [Utility function] does [thing]. Use it, do not create your own.

### Testing
- Tests use [real DB / mocks]. Test DB is [name].

### Brand Voice
- [One-line summary of tone]. See [path] for full guide.
```

**What makes a good gotcha entry:**
- States what NOT to do and why (negative guidance prevents errors)
- **States what IS correct** (not just the anti-pattern — benchmark data shows agents can misinterpret "don't do X" as "remove the mechanism entirely" without a positive alternative)
- Names specific files, functions, models, or CSS tokens
- Explains the consequence of getting it wrong
- Is discoverable by reading code, but easily missed under time pressure

**Example of a weak entry (anti-pattern only):**
```
Tonnage is derived, not stored. Calculated from weight x reps x countTwice flags.
```

**Example of a strong entry (anti-pattern + correct pattern):**
```
Tonnage is derived, not stored. The bilateral multiplier Math.max(wMult, rMult) is the correct formula — do not remove it. Historical bug (B1) was wMult * rMult (4x) instead of Math.max (2x).
```

The weak entry led a benchmark agent to remove the multiplier entirely. The strong entry prevents that misinterpretation.

**What does NOT belong:**
- General best practices (use the Code Quality Rules section)
- Derived facts that go stale (test counts, line numbers)
- Information already obvious from reading the schema or code

### 15.2 Intent-Rich Dispatch (Required)

The Key Documents & Dispatch section must use **intent-based descriptions**, not just file paths. Agents given "when you need to change X, start at Y" navigate directly to the right files. Agents given only file paths waste tool calls exploring.

**Pattern:**

```
| When you need to... | Start at | Notes |
|---------------------|----------|-------|
| Change workout logging | `WorkoutLogger.jsx` | State machine. ExerciseCard is separate file. |
| Change the data model | `schema.prisma` | Always create a migration. Follow protocol. |
| Change colours/spacing | `index.css` (lines 1-80) | 80+ CSS tokens. Never hardcode hex. |
```

**Compare with the weaker pattern (file-path only):**

```
| Area | File |
|------|------|
| Workout logger | `WorkoutLogger.jsx` |
| Schema | `schema.prisma` |
| CSS | `index.css` |
```

The intent-based version tells the agent what to do when they arrive. The file-path version only tells them where to go.

### 15.3 Vague Prompt Resilience

The SOP should be designed to help agents succeed when prompts are vague and product-level ("fix the tonnage bug", "add skip exercise"), not just when prompts are precise ("modify line 42 of file X"). In benchmarks, precise prompts masked context deficiencies — both SOP and baseline agents scored similarly. Vague prompts exposed a 33% quality gap.

**Implication for CLAUDE.md authors:** write context that answers the questions a developer would ask when handed a vague task:
- "Where does this logic live?" (intent-rich dispatch)
- "What should I NOT do?" (common mistakes)
- "What already exists that I should reuse?" (named components, utilities, tokens)
- "What are the non-obvious constraints?" (data model gotchas, brand voice rules)

### 15.4 Benchmark Safety Rules

When running A/B benchmarks or any agent testing against a real codebase:

- **Never push to main or any shared branch.** Benchmark agents work on throwaway branches in git worktrees only.
- **Never access production or staging databases.** Benchmark agents use test databases or no database.
- **Never deploy.** No CI triggers, no Render/Vercel deploys, no pushing to remote.
- **Clean up after every round.** Remove worktrees and branches when scoring is complete.
- **Run strictly sequentially.** Never overlap agent batches on the same worktrees. Setup round N, run all agents, wait for completion, score, cleanup, then setup round N+1. Concurrent batches cause worktree contamination.

**Managed Agents API safety (when using `api.anthropic.com/v1/agents`):**
When benchmarks run via Managed Agents sessions instead of local Claude Code, use permission policies to enforce safety at the API level:
- `bash`: `always_allow` (agents need to run tests)
- `write` and `edit`: `always_allow` (agents need to modify code)
- Git push operations: restrict via system prompt ("never push to remote") or use a read-only GitHub token that lacks push permissions
- Mount repositories with read-only tokens when testing code review or analysis tasks
- Use isolated environments per session — each Managed Agent session gets its own container, eliminating the worktree contamination problem entirely

---

## 16. Multi-Agent Context Routing

When multiple agents work in parallel on the same project, not every agent needs the full SOP context. Routing the right context to each agent based on task type saves 15-25% of token spend while maintaining quality on the tasks that matter.

### Context tiers

| Task type | Context needed | What to load |
|-----------|---------------|-------------|
| Bug fix (multi-file) | Full | CLAUDE.md + agent-memory.md + build plan |
| Feature (multi-file) | Full | CLAUDE.md + agent-memory.md + build plan |
| Refactor (cross-cutting) | Full | CLAUDE.md + agent-memory.md |
| CSS fix (single property) | Partial | CLAUDE.md Common Mistakes + Design System only |
| Test writing | Minimal | Source file under test only. CLAUDE.md optional. |
| Utility creation | Minimal | CLAUDE.md Common Mistakes only (for naming conventions) |
| Documentation | Minimal | Backlog item only |

### Routing rules

1. **Default to full context.** When in doubt, load everything. The cost of unnecessary context (~5K tokens) is lower than the cost of a wrong turn (rework, production bugs).
2. **Use minimal context only when the task is tagged `[ok-for-automation]`** or is explicitly a single-file, self-contained change.
3. **Test-writing agents should NOT read CLAUDE.md.** Benchmark data shows SOP context adds no quality to test writing and may introduce caution that weakens assertions.
4. **Every agent, regardless of tier, must follow the session end checklist** if it modifies committed files.

### Conflict avoidance

- Each agent works on a **separate branch** and merges sequentially.
- Agents on the same codebase must not modify the same files. Assign files explicitly in the task prompt.
- If two agents need to modify the same file, run them sequentially, not in parallel.
- Documentation conflicts (agent-memory.md, Backlog.md) resolve by appending both entries.
- Code conflicts require human review. Flag in agent-memory.md Gotchas.

### Managed Agents API implementation

When using the Claude Managed Agents API (`api.anthropic.com/v1/agents`), the context routing table maps directly to agent configurations:

**Coordinator agent** (full context):
```json
{
  "name": "Engineering Lead",
  "model": "claude-sonnet-4-6",
  "system": "[Full CLAUDE.md content including Common Mistakes, Dispatch, Definition of Done]",
  "tools": [{"type": "agent_toolset_20260401"}],
  "callable_agents": [
    {"type": "agent", "id": "REVIEWER_ID", "version": 1},
    {"type": "agent", "id": "TEST_WRITER_ID", "version": 1},
    {"type": "agent", "id": "RESEARCHER_ID", "version": 1}
  ]
}
```

**Code reviewer** (read-only, partial context):
```json
{
  "name": "Code Reviewer",
  "model": "claude-sonnet-4-6",
  "system": "[Common Mistakes + Design System + Definition of Done rubrics only]",
  "tools": [{
    "type": "agent_toolset_20260401",
    "default_config": {"enabled": false},
    "configs": [
      {"name": "read", "enabled": true},
      {"name": "grep", "enabled": true},
      {"name": "glob", "enabled": true},
      {"name": "bash", "enabled": true}
    ]
  }]
}
```

**Test writer** (minimal context, write access):
```json
{
  "name": "Test Writer",
  "model": "claude-sonnet-4-6",
  "system": "Write tests. Read the source file under test first. Follow existing test patterns.",
  "tools": [{"type": "agent_toolset_20260401"}]
}
```

**Key patterns:**
- The coordinator has `callable_agents` — specialists do not (only one level of delegation).
- All agents share the same container and filesystem but run in isolated threads with separate context.
- Threads are persistent: the coordinator can send follow-up messages to a specialist that retains its prior context.
- Attach `memory_store` resources for persistent cross-session learnings. Map `docs/agent-memory.md` sections to memory store paths: Common Mistakes → read-only store, Decisions Made → read-write store.
- Use `user.define_outcome` with rubrics from the Definition of Done section for quality-gated work — a separate grader evaluates the output and sends feedback for iteration.

---

## 17. Managed Agents Integration Guide

This section maps SOP concepts to the Claude Managed Agents API (`api.anthropic.com/v1/agents`, beta `managed-agents-2026-04-01`). Use this when transitioning a project from Claude Code sessions to the Managed Agents API, or when building products on top of Managed Agents that follow the SOP.

### Memory store mapping

The SOP's file-based memory system maps to Managed Agents memory stores:

| SOP file | Memory store | Access | Notes |
|----------|-------------|--------|-------|
| `docs/agent-memory.md` Decisions + Gotchas | Shared project store (read-write) | `read_write` | All agents read; coordinator writes learnings |
| CLAUDE.md Common Mistakes | Reference store (read-only) | `read_only` | Loaded by all agents, never modified by agents |
| `project_resume.md` | Not needed | N/A | Sessions have built-in event history via `getEvents()` — resume from any checkpoint |
| `docs/feature-map.md` | Not needed | N/A | Track in the repo; agents read via filesystem |

Structure memory stores as many small files (max 100KB each), not a few large ones. Use path prefixes for organisation: `/common-mistakes/data-model.md`, `/common-mistakes/client.md`, `/decisions/2026-04.md`.

### Skills vs CLAUDE.md sections

Managed Agents skills load on demand when relevant to the task. For most projects, keep Common Mistakes and Dispatch in the system prompt (always loaded) rather than as skills. Skills are better suited for:
- Large reference material (API docs, design system specs > 300 lines)
- Domain-specific workflows that apply to some tasks but not others
- Content that changes independently of the agent configuration

A maximum of 20 skills per session applies across all agents in a multi-agent setup.

### Session lifecycle vs SOP checklists

| SOP concept | Managed Agents equivalent |
|-------------|--------------------------|
| Session start checklist | System prompt includes CLAUDE.md content; memory stores loaded automatically |
| Session end checklist | Agent writes learnings to memory store; event log persists all activity |
| `project_resume.md` snapshot | `getEvents()` — retrieve any prior session's full event history |
| Context compaction at 60% | Managed by the harness automatically (built-in prompt caching and compaction) |
| Never delete without a trace | Append-only event log is the native model — events cannot be deleted |

### Outcomes for quality-gated work

The `user.define_outcome` event pairs a task description with a rubric (markdown). A separate grader evaluates the output and returns per-criterion feedback. The agent iterates until the rubric is satisfied or `max_iterations` is reached.

Map the SOP's Definition of Done rubrics directly to outcome rubrics:
1. Upload the rubric via the Files API (`POST /v1/files`)
2. Send `user.define_outcome` with the rubric file reference
3. The grader evaluates independently (separate context window, no bias from the agent's implementation)
4. Results surface as `span.outcome_evaluation_end` events with `satisfied`, `needs_revision`, or `max_iterations_reached`

This is the API-native version of the self-evaluation pattern described in Section 12. The key advantage: the grader runs in a separate context window, avoiding the confirmation bias inherent in self-evaluation.

---

## 18. SOP Evolution Loop

The SOP is a living document. Use benchmark data to iteratively improve it — not gut feeling.

### The loop

```
1. Run A/B benchmark (SOP vs no-SOP) on real tasks
2. Identify where SOP helped, hurt, or had no effect
3. Fix what hurt, keep what helped, cut what had no effect
4. Re-run benchmark to verify the fix worked
5. Repeat
```

### Proven principles (from 5 benchmark rounds, 40+ agent runs)

| Principle | Evidence |
|-----------|----------|
| **Gotcha entries must state what IS correct, not just the anti-pattern** | Ambiguous tonnage entry caused 2/2 wrong fixes. Fixed entry caused 1/1 correct fix. |
| **Less context is better than ambiguous context** | Definition of Done rubric added weight without quality. Removing it eliminated over-correction. |
| **Intent-rich dispatch saves tool calls** | "When you need to change X, start at Y" vs file-path tables: ~50% fewer exploration tool calls. |
| **The SOP's value is a higher floor, not a higher ceiling** | When baseline doesn't fail catastrophically, results are equivalent. SOP insures against bad rolls. |
| **Baseline quality is stochastic** | Same task, same codebase: baseline crashed in R2, matched SOP in R4. The SOP removes this variance. |

### What to benchmark

- **Vague prompts** (how real work arrives), not precise specs
- **Context-dependent tasks** (require project knowledge), not self-contained ones
- **Multiple rounds** for statistical confidence — single rounds are misleading

### What to cut

If a section of CLAUDE.md doesn't improve benchmark outcomes, remove it. Every line costs tokens. The optimal CLAUDE.md is the minimum set of context that prevents the specific failures you've observed.

See `docs/guides/sop-hill-climbing.md` for the detailed methodology.
