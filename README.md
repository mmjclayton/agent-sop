# Agent SOP

Standard operating procedures for Claude Code agents. Consistent structure, persistent context, measurable compliance.

---

## The Problem

Claude Code agents start every session with no memory of previous sessions. Without structure, each session rediscovers context, duplicates information across files, loses track of decisions, and drifts from established patterns. Over multiple sessions this compounds — agents overwrite previous work, contradict earlier decisions, and leave the project in a state the next session cannot pick up cleanly.

The cost is real: wasted context window on re-orientation, repeated mistakes, inconsistent output quality, and human time spent correcting agent behaviour that should have been prevented by structure.

## The Solution

This library defines a standard operating procedure that gives every Claude Code agent session:

- **Immediate orientation** — a defined set of files to read at session start, so the agent has full project context within the first few tool calls
- **Persistent cross-session memory** — architectural decisions, data model invariants, gotchas, and preferences survive across sessions without relying on Claude Code's unreliable auto-memory
- **Consistent update rules** — every session leaves the project in a state the next session can pick up immediately
- **Measurable compliance** — an automated checker agent that audits any project against the SOP and scores it

## What the SOP Covers

### 1. Standard File Set

Every project using the SOP has these files:

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Master context file — stack, conventions, priority items, session checklists, dispatch reference. The first file every agent reads. |
| `Backlog.md` | Single source of truth for all work items. Status tags, P-numbers, acceptance criteria. |
| `docs/agent-memory.md` | Permanent cross-session context — architectural decisions, data model invariants, gotchas, named utility functions. Committed to git, visible to all contributors. |
| `docs/feature-map.md` | Shipped feature inventory and prioritised roadmap. |
| `docs/build-plans/phase-N.md` | Per-phase architecture, scope, locked decisions, batch logs, deploy checklists. |
| `project_resume.md` (local) | Point-in-time snapshot of where the project stands. Overwritten each session. |

### 2. Two Non-Negotiable Rules

These cannot be overridden by any project-specific configuration:

1. **Never delete without a trace.** Update in place, mark `[SUPERSEDED]`, or move to `## Archived`. In-place edits (status changes, corrections, folding answers into items) are expected. Silent removal is not.

2. **One source of truth.** Each information type lives in exactly one file. When files disagree, explicit precedence resolves it: code/git > CLAUDE.md > Backlog.md > build-plan > feature-map > agent-memory > resume point.

### 3. Session Checklists

**Session start (7 steps):** Read CLAUDE.md, MEMORY.md, project_resume.md, agent-memory.md, build plan, git log. Cross-check memory against current file state.

**Session end (8 steps):** Run tests (code projects), update Backlog, feature-map, agent-memory, build plan batch log, project_resume. Commit docs with the work.

Agents wrap up at 60% context capacity — not 95%. Running to the limit produces degraded output and risks losing session-end updates.

### 4. Backlog Management

- P-numbers assigned sequentially, never reused
- Tag order: status first (`[OPEN]`, `[IN PROGRESS]`, `[SHIPPED - YYYY-MM-DD]`, `[VERIFIED]`, `[WON'T]`), type second (`[Feature]`, `[Iteration]`, `[Bug]`, `[Refactor]`)
- Issues lazy-created only when work moves to `[IN PROGRESS]`
- Archive threshold at ~2,000 lines

### 5. Memory System Separation

| System | Location | What belongs |
|--------|----------|-------------|
| `docs/agent-memory.md` | In-repo (git) | Facts any contributor needs — decisions, invariants, gotchas, utility functions |
| Auto-memory (`~/.claude/.../memory/`) | Local machine | User preferences, session state, personal workflow notes |

Derived facts (test counts, line numbers, dependency versions) do not belong in either — they go stale immediately.

### 6. Build Plans and Phased Work

Each phase gets its own file with: Problem, Scope, Architecture, Key Decisions (marked `[LOCKED]`), Batch Log (append-only), Deploy Checklist, and Open Questions. Shipped phases are frozen except for the Batch Log.

### 7. Conflict Resolution

When files disagree, precedence is explicit and deterministic:

1. Code and git state (always wins)
2. CLAUDE.md (project rules)
3. Backlog.md (work item status)
4. Build plans (phase architecture)
5. Feature map (shipped inventory)
6. Agent memory (cross-session context)
7. Resume point (lowest precedence)

## How This Impacts Claude Code Performance

**Context efficiency.** The Dispatch Quick Reference (minimum 5 named files) and Key Documents table mean agents reach the right files in 2-3 tool calls instead of exploring blindly. The 200-line limit on CLAUDE.md per-session sections keeps the master context file lean.

**Decision persistence.** Architectural decisions, data model invariants, and gotchas survive across sessions in `docs/agent-memory.md`. Agents do not re-derive conclusions or repeat mistakes that previous sessions already resolved.

**Reduced drift.** The session-end checklist forces every session to update tracking files before closing. The next session starts with accurate state, not stale memory claims that need to be cross-checked against reality.

**Predictable behaviour.** Tag formats, file ownership rules, and update triggers are defined once. Agents do not invent their own conventions or slowly drift from established patterns across sessions.

**Safe handoffs.** Multi-agent contention is handled explicitly — separate branches, docs conflicts resolved by appending, code conflicts require reading both versions, semantic conflicts flagged for human resolution.

**Test gates.** Code projects run the full test suite as step 1 of the session-end checklist. Broken code does not get committed and left for the next session to discover.

---

## Compliance Checker

The SOP includes an automated compliance checker agent at `.claude/agents/sop-checker.md`. It audits any project folder against the SOP and produces a scored report.

### Running the checker

In a Claude Code session on this repo:

```
@sop-checker check SOP compliance for ~/Projects/my-app
```

### What it checks

~64 checks across 8 categories:

| Category | What it verifies |
|----------|-----------------|
| File Existence | All 5 mandatory files + 2 local files present at correct paths |
| CLAUDE.md Structure | All required sections present, 200-line limit, session checklists correct |
| Backlog.md Structure | Tag format, status/type order, P-number sequencing, date formats |
| agent-memory.md Structure | All 8 sections present, no derived facts, no duplicated Key Documents |
| feature-map.md Structure | Last-updated header, shipped/roadmap sections |
| Build Plan Structure | All 7 sections, Batch Log format, `[LOCKED]` markers |
| project_resume.md Structure | Correct naming, snapshot format, required sections |
| Cross-File Consistency | Shipped items in both Backlog and feature-map, in-flight work matches |

### Scoring

| Tier | Points | Rule |
|------|--------|------|
| Critical | 10 each | Any failure caps total score at 49/100 |
| Important | 5 each | Deducted from pool |
| Recommended | 2 each | Advisory |

**Compliance tiers:** 90-100 fully compliant, 70-89 largely compliant, 50-69 partially compliant, 0-49 non-compliant.

### Report output

The checker produces:
- Per-check PASS/FAIL tables with specific fix instructions
- Top recommendations ordered by impact
- "Path to 100%" grouped by effort level (quick / medium / structural)

The checker is **read-only** — it never modifies the target project.

---

## Getting Started

### New project

Read `docs/examples/sop-implementation-guide.md` for step-by-step setup instructions, or paste these instructions into a Claude Code session on your project:

```
I want you to implement the Agent SOP in this project. The SOP repo is at ~/Projects/agent-sop.

1. Read ~/Projects/agent-sop/docs/sop/claude-agent-sop.md (the full SOP)
2. Read ~/Projects/agent-sop/docs/examples/sop-implementation-guide.md (step-by-step setup)
3. Choose the right CLAUDE.md template:
   - Base (non-code): ~/Projects/agent-sop/docs/templates/claude-md-template.md
   - Code projects: ~/Projects/agent-sop/docs/templates/claude-md-template-code.md

Then follow the implementation guide to create all standard files in THIS project.
Fill in all sections with real project-specific content — do not leave template placeholders.
After creating the files, run through the verification checklist, then commit.
```

### Existing project

The SOP includes a minimum viable migration checklist in Section 13. The compliance checker can identify exactly what is missing and what to fix.

---

## Repository Structure

```
agent-sop/
  CLAUDE.md                              # This project's own SOP config
  Backlog.md                             # Work items for the SOP library itself
  README.md                              # This file
  .claude/
    agents/
      sop-checker.md                     # Compliance checker agent definition
  docs/
    agent-memory.md                      # Cross-session context for this project
    feature-map.md                       # Shipped documents and roadmap
    sop/
      claude-agent-sop.md               # The core SOP document
      compliance-checklist.md           # Canonical compliance checks and scoring
    templates/
      claude-md-template.md             # CLAUDE.md template (base, any project)
      claude-md-template-code.md        # CLAUDE.md template (code projects)
    examples/
      sop-implementation-guide.md       # Step-by-step setup instructions
    build-plans/
      phase-0-foundation.md             # Current phase
```

---

## Status

Phase 0 (foundation) in progress. Core SOP, both CLAUDE.md templates, implementation guide, and compliance checker are shipped. Templates for agent-memory, backlog, and build plans are next.
