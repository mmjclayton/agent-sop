# Agent SOP

Standard operating procedures for Claude Code agents. Consistent structure, persistent context, measurable compliance.

---

## The Problem

Claude Code agents start every session with no memory of previous sessions. Without structure, each session rediscovers context, duplicates information across files, loses track of decisions, and drifts from established patterns. Over multiple sessions this compounds. Agents overwrite previous work, contradict earlier decisions, and leave the project in a state the next session cannot pick up cleanly.

## The Solution

This library defines a standard operating procedure that gives every Claude Code agent session:

- **Immediate orientation.** A defined set of files to read at session start, so the agent has full project context within the first few tool calls.
- **Persistent cross-session memory.** Architectural decisions, data model invariants, gotchas, and preferences survive across sessions in `docs/agent-memory.md`.
- **Consistent update rules.** Every session leaves the project in a state the next session can pick up immediately.
- **Security guidance.** Prompt injection awareness, secret scanning, MCP trust boundaries, sandbox guidance.
- **Automated enforcement.** Hooks that automate session checklists, pre-commit quality gates, and pattern extraction.
- **Measurable compliance.** An automated checker agent that audits any project against the SOP and scores it out of 100.

---

## Token Efficiency

The SOP is designed to minimise context window consumption while giving agents full project awareness. Every file, section, and rule has been measured and trimmed.

### Session start cost

The 5-step session start checklist reads CLAUDE.md, agent-memory.md, project_resume.md, recent git history, and the current Backlog item. Measured token costs for these reads:

| Scenario | Raw tokens | With 1.7x loading overhead | % of 200k context |
|----------|-----------|---------------------------|-------------------|
| Fresh project (from templates) | ~1,500 | ~2,600 | 1.3% |
| Mature project (this repo, 40+ decisions, 17 shipped items) | ~3,100 | ~5,200 | 2.6% |

Token counts are approximated at 1.3 tokens per word. The 1.7x loading overhead reflects the cost of tool calls, file reading, and processing that Claude Code incurs when loading content into context.

### How the overhead stays low

**CLAUDE.md size cap.** Per-session sections are capped at 200 lines (~2,000 tokens). Reference sections (Auth, Database, Design System) are read on demand, not every session. The base template is 151 lines; the code template is 270 lines including all reference sections.

**Merged dispatch table.** Key Documents and Dispatch Quick Reference were originally two separate sections with overlapping file listings. Merging them into a single table eliminated the duplication. This was part of a dedicated optimisation pass (commit `71a34e0`) that removed 100 net lines across templates.

**Line-range hints.** The dispatch table supports line-range annotations (e.g. `index.css (lines 1-80)`). When an agent follows a hint, it reads 80 lines instead of the entire file. The core SOP itself includes a section index with line ranges so agents can read specific sections (~40 lines for session checklists) rather than all 572 lines.

**Snapshot resume, not a log.** `project_resume.md` is overwritten each session (~15 lines). Earlier designs used an append-only log that grew without bound. The snapshot model keeps the resume file at a constant size regardless of how many sessions have passed.

**No derived facts.** The SOP prohibits storing test counts, line numbers, file sizes, and dependency versions in memory files. These values go stale between sessions and cost tokens to read without providing reliable information. Agents check these at runtime instead.

**No duplication across files.** The single-source-of-truth rule means each fact lives in exactly one file. `agent-memory.md` points to the CLAUDE.md dispatch table rather than duplicating it. Work item status lives only in Backlog.md, not in build plans or memory.

**Unified checklists.** Session start (5 steps) and session end (7 steps) are defined once in the SOP and referenced by templates. Earlier versions had slightly different step counts in different files, which meant agents had to read multiple sources to reconcile. One canonical version means one read.

**60% context threshold.** The SOP instructs agents to wrap up at 60% context capacity rather than pushing to 95%. This prevents the degraded performance and unreliable behaviour that occurs when context approaches its limit, and ensures the session end checklist can run cleanly.

---

## What's Included

### Core SOP

| Document | Path | Purpose |
|----------|------|---------|
| Core SOP | `docs/sop/claude-agent-sop.md` | The main SOP: file structure, rules, checklists, update triggers |
| Security Guidance | `docs/sop/security.md` | Prompt injection, secret scanning, MCP trust, sandboxing |
| Hooks Guidance | `docs/sop/hooks.md` | Hook types and 6 reference implementations |
| Compliance Checklist | `docs/sop/compliance-checklist.md` | ~70 checks with scoring weights |

### Templates

| Template | Path | Use for |
|----------|------|---------|
| CLAUDE.md (base) | `docs/templates/claude-md-template.md` | Any project type |
| CLAUDE.md (code) | `docs/templates/claude-md-template-code.md` | Full-stack code projects (adds Auth, Database, Design System, Code Quality Rules) |
| Agent Memory | `docs/templates/agent-memory-template.md` | New agent-memory.md files |
| Backlog | `docs/templates/backlog-template.md` | New Backlog.md files |
| Build Plan | `docs/templates/build-plan-template.md` | New phase build plans |

### Reference Agents

| Agent | Path | Purpose |
|-------|------|---------|
| SOP Checker | `.claude/agents/sop-checker.md` | Audits any project for SOP compliance |
| Code Reviewer | `.claude/agents/code-reviewer.md` | Reviews code for quality, security, maintainability |
| Security Reviewer | `.claude/agents/security-reviewer.md` | OWASP Top 10, secret detection, auth issues |
| Planner | `.claude/agents/planner.md` | Structured build plans with phases and risks |
| E2E Runner | `.claude/agents/e2e-runner.md` | Playwright end-to-end test generation and execution |

### Examples and Guides

| Document | Path | Purpose |
|----------|------|---------|
| Implementation Guide | `docs/examples/sop-implementation-guide.md` | Agent-facing setup instructions |
| New Project Walkthrough | `docs/examples/new-project-walkthrough.md` | Human-readable guide with a concrete example project |
| Migration Guide | `docs/examples/existing-project-migration.md` | Checklist for adding the SOP to an existing project |

---

## Two Non-Negotiable Rules

These cannot be overridden by any project-specific configuration:

1. **Never delete without a trace.** Update in place, mark `[SUPERSEDED]`, or move to `## Archived`. In-place edits are expected. Silent removal is not.

2. **One source of truth.** Each information type lives in exactly one file. When files disagree, explicit precedence resolves it: code/git, then CLAUDE.md, then Backlog.md, then build plan, then feature map, then agent memory, then resume point.

---

## Session Checklists

**Start (5 steps):**
1. Read CLAUDE.md
2. Read MEMORY.md and project_resume.md
3. Read docs/agent-memory.md
4. Run `git log --oneline -10`, cross-check memory against current state
5. Read the Backlog item(s) for this session

**End (7 steps):**
1. Run tests (code projects)
2. Update Backlog.md
3. Update docs/feature-map.md
4. Update docs/agent-memory.md
5. Update docs/build-plans/phase-N.md Batch Log
6. Overwrite project_resume.md
7. Commit docs/ changes with the work

Wrap up at 60% context capacity, not 95%.

---

## Compliance Checker

The SOP includes an automated compliance checker agent. Run it from a Claude Code session:

```
@sop-checker check SOP compliance for ~/Projects/my-app
```

### What it checks

~70 checks across 9 categories:

| Category | What it verifies |
|----------|-----------------|
| File Existence | All mandatory files present at correct paths |
| CLAUDE.md Structure | Required sections, checklist steps, line limits |
| Backlog.md Structure | Tag format, status/type order, P-number sequencing |
| agent-memory.md | All 8 sections, no derived facts, no duplication |
| feature-map.md | Last-updated header, shipped/roadmap sections |
| Build Plans | All 7 sections, Batch Log format, [LOCKED] markers |
| project_resume.md | Correct naming, snapshot format, required sections |
| Cross-File Consistency | Shipped items in both Backlog and feature map |
| Security, Hooks, Quality, Agents | Secret scanning, security docs, file limits, coverage threshold, hooks, agents |

### Scoring

| Tier | Points | Rule |
|------|--------|------|
| Critical | 10 each | Any failure caps total score at 49/100 |
| Important | 5 each | Deducted from pool |
| Recommended | 2 each | Advisory |

90 to 100: fully compliant. 70 to 89: largely compliant. 50 to 69: partially compliant. 0 to 49: non-compliant.

---

## Getting Started

### New project

Two options:

**Option A: Human walkthrough.** Read `docs/examples/new-project-walkthrough.md` for a step-by-step guide using a concrete example project. Good for understanding what each file does and why.

**Option B: Agent setup.** Paste this into a Claude Code session on your project:

```
I want you to implement the Agent SOP in this project. The SOP repo is at ~/Projects/agent-sop.

1. Read ~/Projects/agent-sop/docs/sop/claude-agent-sop.md (the full SOP)
2. Read ~/Projects/agent-sop/docs/examples/sop-implementation-guide.md (step-by-step setup)
3. Choose the right CLAUDE.md template:
   - Base (non-code): ~/Projects/agent-sop/docs/templates/claude-md-template.md
   - Code projects: ~/Projects/agent-sop/docs/templates/claude-md-template-code.md

Then follow the implementation guide to create all standard files in THIS project.
Fill in all sections with real project-specific content. Do not leave template placeholders.
After creating the files, run through the verification checklist, then commit.
```

### Existing project

Two options:

**Option A: Checklist migration.** Read `docs/examples/existing-project-migration.md` for a structured audit-and-fix checklist. Covers common gaps (missing sections, duplicate information, incorrect file naming) and provides a verification checklist at the end.

**Option B: Automated audit.** Run the compliance checker to see exactly what is missing:

```
@sop-checker check SOP compliance for ~/Projects/my-app
```

The report includes a "Path to 100%" section grouped by effort level.

---

## Repository Structure

```
agent-sop/
  CLAUDE.md                              # This project's own SOP config
  Backlog.md                             # Work items for the SOP library itself
  README.md                              # This file
  .claude/
    agents/
      sop-checker.md                     # Compliance checker agent
      code-reviewer.md                   # Code review agent
      security-reviewer.md              # Security review agent
      planner.md                         # Build planning agent
      e2e-runner.md                      # E2E testing agent
  docs/
    agent-memory.md                      # Cross-session context for this project
    feature-map.md                       # Shipped documents and roadmap
    sop/
      claude-agent-sop.md               # The core SOP document
      compliance-checklist.md           # Canonical compliance checks and scoring
      security.md                        # Security guidance
      hooks.md                           # Hooks guidance with reference implementations
    templates/
      claude-md-template.md             # CLAUDE.md template (base, any project)
      claude-md-template-code.md        # CLAUDE.md template (code projects)
      agent-memory-template.md          # Agent memory template
      backlog-template.md               # Backlog template
      build-plan-template.md            # Build plan template
    examples/
      sop-implementation-guide.md       # Agent-facing setup instructions
      new-project-walkthrough.md        # Human-readable new project guide
      existing-project-migration.md     # Migration checklist for existing projects
    build-plans/
      phase-0-foundation.md             # Current phase
```

---

## Status

Phase 0 (foundation) in progress. 17 items shipped (P1 through P7, P11 through P20). Next up: domain-specific variants for web apps (P8), marketing (P9), and data/analytics (P10).

---

## Acknowledgements

Several concepts in this SOP were informed by or adapted from [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) (ECC) by [affaan-m](https://github.com/affaan-m), a comprehensive collection of skills, rules, agents, and hooks for Claude Code. Specific areas where ECC influenced our approach:

- **Security guidance** (`docs/sop/security.md`). Adapted from ECC's security rules covering prompt injection, secret scanning, and MCP trust boundaries.
- **Hooks guidance** (`docs/sop/hooks.md`). Reference implementations inspired by ECC's hook patterns for SessionStart, PostToolUse, and Stop events.
- **Code quality rules** in the code template. File size limits, immutability, and error handling patterns drawn from ECC's coding-style rules.
- **Reference agent definitions.** The code-reviewer, security-reviewer, planner, and e2e-runner agents follow patterns established by ECC's agent library.
- **Compliance checker scoring model.** The three-tier (Critical/Important/Recommended) scoring approach with critical-failure caps.
- **Continuous learning pattern.** Pattern extraction cadence and promotion rules adapted from ECC's continuous-learning skill.

This SOP is not a fork of ECC. It is an independent, opinionated operating procedure that incorporates proven patterns from the ECC ecosystem alongside original work on session checklists, backlog management, cross-file consistency, and measurable compliance scoring.
