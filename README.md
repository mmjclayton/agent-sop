# Agent SOP

Standard operating procedures for Claude Code agents. Consistent structure, persistent context, measurable compliance.

---

## The Problem

Claude Code agents start every session with no memory of previous sessions. Without structure, each session rediscovers context, duplicates information across files, loses track of decisions, and drifts from established patterns. Over multiple sessions this compounds — agents overwrite previous work, contradict earlier decisions, and leave the project in a state the next session cannot pick up cleanly.

## The Solution

This library defines a standard operating procedure that gives every Claude Code agent session:

- **Immediate orientation** — a defined set of files to read at session start (~900 tokens), so the agent has full project context within the first few tool calls
- **Persistent cross-session memory** — architectural decisions, data model invariants, gotchas, and preferences survive across sessions in `docs/agent-memory.md`
- **Consistent update rules** — every session leaves the project in a state the next session can pick up immediately
- **Security guidance** — prompt injection awareness, secret scanning, MCP trust boundaries, sandbox guidance
- **Automated enforcement** — hooks that automate session checklists, pre-commit quality gates, and pattern extraction
- **Measurable compliance** — an automated checker agent that audits any project against the SOP and scores it out of 100

---

## What's Included

### Core SOP

| Document | Path | Purpose |
|----------|------|---------|
| Core SOP | `docs/sop/claude-agent-sop.md` | The main SOP — file structure, rules, checklists, update triggers |
| Security Guidance | `docs/sop/security.md` | Prompt injection, secret scanning, MCP trust, sandboxing |
| Hooks Guidance | `docs/sop/hooks.md` | Hook types + 6 reference implementations |
| Compliance Checklist | `docs/sop/compliance-checklist.md` | ~70 checks with scoring weights |

### Templates

| Template | Path | Use for |
|----------|------|---------|
| CLAUDE.md (base) | `docs/templates/claude-md-template.md` | Any project type |
| CLAUDE.md (code) | `docs/templates/claude-md-template-code.md` | Full-stack code projects (adds Auth, Database, Design System, Code Quality Rules) |

### Reference Agents

| Agent | Path | Purpose |
|-------|------|---------|
| SOP Checker | `.claude/agents/sop-checker.md` | Audits any project for SOP compliance |
| Code Reviewer | `.claude/agents/code-reviewer.md` | Reviews code for quality, security, maintainability |
| Security Reviewer | `.claude/agents/security-reviewer.md` | OWASP Top 10, secret detection, auth issues |
| Planner | `.claude/agents/planner.md` | Structured build plans with phases and risks |
| E2E Runner | `.claude/agents/e2e-runner.md` | Playwright end-to-end test generation and execution |

### Examples

| Document | Path | Purpose |
|----------|------|---------|
| Implementation Guide | `docs/examples/sop-implementation-guide.md` | Step-by-step setup for new projects |

---

## Two Non-Negotiable Rules

These cannot be overridden by any project-specific configuration:

1. **Never delete without a trace.** Update in place, mark `[SUPERSEDED]`, or move to `## Archived`. In-place edits are expected. Silent removal is not.

2. **One source of truth.** Each information type lives in exactly one file. When files disagree, explicit precedence resolves it: code/git > CLAUDE.md > Backlog.md > build-plan > feature-map > agent-memory > resume point.

---

## Session Checklists

**Start (5 steps):**
1. Read CLAUDE.md
2. Read MEMORY.md + project_resume.md
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
| Cross-File Consistency | Shipped items in both Backlog and feature-map |
| Security, Hooks, Quality, Agents | Secret scanning, security docs, file limits, coverage threshold, hooks, agents |

### Scoring

| Tier | Points | Rule |
|------|--------|------|
| Critical | 10 each | Any failure caps total score at 49/100 |
| Important | 5 each | Deducted from pool |
| Recommended | 2 each | Advisory |

90-100 fully compliant. 70-89 largely compliant. 50-69 partially compliant. 0-49 non-compliant.

---

## Getting Started

### New project

Paste this into a Claude Code session on your project:

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

Run the compliance checker to see exactly what is missing:

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
    examples/
      sop-implementation-guide.md       # Step-by-step setup instructions
    build-plans/
      phase-0-foundation.md             # Current phase
```

---

## Status

Phase 0 (foundation) in progress. 12 items shipped (P1-P2, P11-P20). Templates for agent-memory, backlog, and build plans are next (P3-P5), followed by walkthrough and migration guides (P6-P7).
