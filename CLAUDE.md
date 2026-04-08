# Agent SOP — Standard Operating Procedure Library for Claude Code

> The reference implementation for consistent, productive Claude Code agent sessions.

---

## Agent SOP

This project IS the Agent SOP library. All agents working on this project still follow the SOP defined in `docs/sop/claude-agent-sop.md` — including the never-delete-without-a-trace rule and session checklists. Conflict precedence: code/git > CLAUDE.md > Backlog.md > build-plan > feature-map > agent-memory > resume point.

---

## Build Plans — READ FIRST

- `docs/build-plans/phase-0-foundation.md` — In Progress (scaffold, core SOP docs, templates)

---

## Key Documents — READ THESE

| Document | Path | Purpose |
|----------|------|---------|
| Agent Memory | `docs/agent-memory.md` | Permanent cross-session context |
| Feature Map | `docs/feature-map.md` | Shipped documents + roadmap |
| Backlog | `Backlog.md` | Single source of truth for all work items |
| Core SOP | `docs/sop/claude-agent-sop.md` (lines 1-35 for Quick Reference) | The main SOP document |
| CLAUDE.md Template | `docs/templates/claude-md-template.md` | Template for new projects |

---

## Current Priority Items (as of 2026-04-08)

**Next:**
- P3 — Agent memory template (`docs/templates/agent-memory-template.md`)
- P4 — Backlog template (`docs/templates/backlog-template.md`)
- P5 — Build plan template (`docs/templates/build-plan-template.md`)
- P6 — New project walkthrough (`docs/examples/new-project-walkthrough.md`)
- P7 — Existing project migration guide (`docs/examples/existing-project-migration.md`)

**Medium:**
- P8 — Web app domain variant
- P9 — Marketing domain variant
- P10 — Data/analytics domain variant

---

## Backlog Management

`Backlog.md` is the single source of truth. Never delete without a trace — update in place, mark superseded, or archive.

### Tag taxonomy
- Status (first): `[OPEN]` `[IN PROGRESS]` `[BLOCKED]` `[SHIPPED - YYYY-MM-DD]` `[VERIFIED - YYYY-MM-DD]` `[WON'T]`
- Type (second): `[Feature]` `[Iteration]` `[Bug]` `[Refactor]`
- Optional: `[has-open-questions]` `[ok-for-automation]`

### Rules
- Never mark `[SHIPPED]` without the document existing and being complete.
- Never delete items from Backlog.md.
- Status first, type second. Never reverse.

---

## Stack

- Format: Markdown only
- Hosting: GitHub (public repository, to be created)
- No build process, no dependencies

---

## Key Commands

```bash
git log --oneline -10
git status
git add -A && git commit -m "docs: description"
```

---

## Rules for Automated Builds

1. Read CLAUDE.md first. Then the Backlog item. Then relevant existing docs.
2. Never delete without a trace: update in place, mark superseded, or archive. Never silently remove content.
3. New SOP documents go in `docs/sop/`.
4. New templates go in `docs/templates/`.
5. New example guides go in `docs/examples/`.
6. Every new document must have a corresponding Backlog entry.
7. Update `docs/feature-map.md` and `Backlog.md` when any document ships.
8. Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`

---

## Session & Memory Hygiene

Memory files live at `~/.claude/projects/[project-hash]/memory/`.

### Session start checklist
1. Read `MEMORY.md` index.
2. Read `project_resume.md` — current snapshot of where the project stands.
3. Read `docs/agent-memory.md`.
4. Read current `docs/build-plans/` phase file.
5. Run `git log --oneline -10`.
6. Cross-check memory against current file state — trust what you observe.
7. Read the specific Backlog.md item(s) for this session.

### Session end checklist
**Never delete without a trace. Update in place, mark superseded, or archive.**

1. Run tests (code projects) — fix failures before proceeding.
2. `Backlog.md` — update status tags and item bodies in place, append new items.
3. `docs/feature-map.md` — append shipped documents.
4. `docs/agent-memory.md` — append decisions/gotchas, move completed to Completed Work.
5. `docs/build-plans/phase-N.md` — append to Batch Log.
6. `project_resume.md` — overwrite with current session state.
7. `MEMORY.md` index — append new entries.
8. Commit all docs changes in the same commit as the work.

---

## Dispatch Quick Reference

| Area | File |
|------|------|
| Core SOP | `docs/sop/claude-agent-sop.md` |
| CLAUDE.md template | `docs/templates/claude-md-template.md` |
| Agent memory | `docs/agent-memory.md` |
| Backlog | `Backlog.md` |
| Current build plan | `docs/build-plans/phase-0-foundation.md` |
| Feature map | `docs/feature-map.md` |
| Compliance checklist | `docs/sop/compliance-checklist.md` |
| Security guidance | `docs/sop/security.md` |
| Hooks guidance | `docs/sop/hooks.md` |
| SOP checker agent | `.claude/agents/sop-checker.md` |

---

## Recent Work

*Append-only. New entries at top. Include commit refs.*

### 2026-04-08: P14-P20 — ECC-informed expansion (commits f928a42-present)
Security guidance, hooks guidance with 6 reference implementations, code quality rules, 4 reference agents (code-reviewer, security-reviewer, planner, e2e-runner), expanded code template sections (Auth, Database, Key Commands, Design System), continuous learning pattern, and 6 new compliance checks. Adapted from everything-claude-code reference repo.

### 2026-04-07: P13 — SOP Compliance Checker Agent (commits c0b697d-22f1eb0)
Compliance checker agent (`.claude/agents/sop-checker.md`) and canonical checklist (`docs/sop/compliance-checklist.md`). ~64 checks across 8 categories, three-tier scoring with critical-failure cap. README rewritten.

### 2026-04-07: P12 — SOP v2 owner feedback iteration (commit 79c5a5c)
10 changes applied based on multi-session usage feedback. Reframed additive-only to never-delete-without-a-trace, delineated memory systems, added test gates, snapshot resume model, conflict precedence, schema protocol, backlog archive threshold, no-derived-facts rule, multi-agent code conflict nuance.

### 2026-04-07: SOP improvements + P11 (commit 79c5a5c)
9 improvements applied to core SOP following independent analysis. CLAUDE.md template split into base + code variant (P11 shipped). All tracking files updated per session end checklist.

### 2026-04-07: Initial scaffold (commit 79c5a5c)
Project created and P1, P2 shipped — CLAUDE.md, Backlog.md, docs/agent-memory.md, docs/feature-map.md, phase-0 build plan, README.md, core SOP, CLAUDE.md template.

---

## Deprioritised

*Items moved here from priority lists above. Never removed.*
