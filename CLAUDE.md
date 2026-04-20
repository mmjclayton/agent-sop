# Agent SOP — Standard Operating Procedure Library for Claude Code

> The reference implementation for consistent, productive Claude Code agent sessions.

---

## Agent SOP

This project IS the Agent SOP library. All agents working on this project still follow the SOP defined in `docs/sop/claude-agent-sop.md` — including the never-delete-without-a-trace rule and session checklists. Conflict precedence: code/git > CLAUDE.md > Backlog.md > build-plan > feature-map > agent-memory > resume point.

---

## Build Plans — READ FIRST

- `docs/build-plans/phase-0-foundation.md` — In Progress (scaffold, core SOP docs, templates)
- `docs/build-plans/phase-1-parallel-sessions.md` — Planning (P43 parallel multi-agent support)

---

## Key Documents & Dispatch

| Area | File | Purpose |
|------|------|---------|
| Agent Memory | `docs/agent-memory.md` | Cross-session decisions, gotchas |
| Feature Map | `docs/feature-map.md` | Shipped documents + roadmap |
| Backlog | `Backlog.md` | Single source of truth for work items |
| Core SOP | `docs/sop/claude-agent-sop.md` | Non-negotiable rules (Section 0), file specs, session checklists |
| Build Plan | `docs/build-plans/phase-0-foundation.md` | Current phase |
| Compliance | `docs/sop/compliance-checklist.md` | Audit checks + scoring (used by sop-checker agent) |
| Security | `docs/sop/security.md` | Core security rules |
| Sandboxing | `docs/sop/sandboxing.md` | Container / network isolation for autonomous runs |
| Harness | `docs/sop/harness-configuration.md` | Hooks + context primitives (clearing, compaction, memory) |
| Guides | `docs/guides/` | Optional patterns, multi-agent routing, Managed Agents (deferred), SOP hill-climbing |
| Templates | `docs/templates/claude-md-template.md` | Base template for new projects |
| SOP Checker | `.claude/agents/sop-checker.md` | Compliance audit agent |

---

## Current Priority Items (as of 2026-04-19)

**Next:**
- P24 — Multi-agent optimisation guide (informed by P23 benchmark results)
- P33 — Managed Agents integration guide (deferred — revive when a project uses Managed Agents API)
- P8 — Web app domain variant `[has-open-questions]`
- P9 — Marketing domain variant `[has-open-questions]`
- P10 — Data/analytics domain variant `[has-open-questions]`

**Follow-ups still open:**
- Config `exclude` field for per-project file skipping (gap found during hst-tracker audit — security.md filename collision). Also doubles as `exclude_from_tracker_scan` escape hatch for the P42 auto-detect heuristic if false positives emerge.
- Karpathy-skills before/after examples pattern (Common Mistakes pedagogy — deferred from P34)
- R6 full-framework benchmark on fresh CLI sessions, Opus 4.6, 2+ rounds (deferred from P38 — run if publicly citing a post-trim percentage)

---

## Backlog Management

`Backlog.md` is the single source of truth. Never delete without a trace — update in place, mark superseded, or archive.

### Tag taxonomy
- Status (first): `[OPEN]` `[IN PROGRESS]` `[BLOCKED]` `[DEFERRED]` `[SHIPPED - YYYY-MM-DD]` `[VERIFIED - YYYY-MM-DD]` `[WON'T]`
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
1. Read CLAUDE.md.
2. Read `MEMORY.md` + `project_resume.md`.
3. Read `docs/agent-memory.md`.
4. Run `git log --oneline -10`, cross-check memory against current file state.
5. Read the specific Backlog.md item(s) for this session.

If In-Flight Work is populated or `project_resume.md` has no What's Next — previous session was interrupted. Read the build plan Batch Log before starting new work.

### Session end checklist
**Never delete without a trace. Update in place, mark superseded, or archive.**

1. Run tests (code projects) — fix failures before proceeding.
2. `Backlog.md` — update status tags in place, append new items. Step 2a hard-blocks P-number collisions with the default branch.
3. Secondary trackers — reconcile any project-specific finding files in Key Documents (audit-backlog, security-findings, etc.) using heading-level `[OPEN]`/`[SHIPPED]` tags. Commit-range partitioned via `git merge-base`. Hard block on unreconciled finding IDs.
4. `docs/feature-map.md` — append shipped items.
5. `docs/agent-memory.md` narrative + decisions/gotchas directories — write to `docs/agent-memory/decisions/` and `docs/agent-memory/gotchas/`; update In-Flight/Completed in agent-memory.md by agent-id.
6. `docs/build-plans/phase-N.md` — append to Batch Log.
7. `project_resume_<agent-id>.md` — overwrite with current state (per-agent snapshot).
8. Write session entry to `docs/recent-work/` and refresh `CLAUDE.md` rollup section.
9. Commit docs/ changes with the work.

---

## Recent Work (rollup)

<!-- recent-work-rollup:start -->
*Auto-generated from `docs/recent-work/`. Last refreshed: 2026-04-20.*

- 2026-04-20 `solo`: P47 legacy-resume fallback shipped
- 2026-04-19 `solo`: README update + hst-tracker sync + P47 filing
- 2026-04-19 `solo`: P46 mid-session drift detection shipped
- 2026-04-19 `solo`: P45 state-transition validator shipped
- 2026-04-19 `solo`: P44 reviewer-turn + substance assertion shipped
- 2026-04-19 `solo`: P44/P45/P46 drafted from Reddit state-drift feedback
- 2026-04-19 `solo`: P43 close-out — README parallel-sessions coverage + Rule 5 audit
- 2026-04-19 `solo`: P43 Phase 1 Batches 1.1 through 1.6 shipped
- 2026-04-19 `solo`: P43 Batch 1.7 dogfood complete — P43 ships
- 2026-04-19 `solo`: P43 Batch 1.2 — directory structure + rollup specs
- 2026-04-19 `solo`: P42 — Secondary-tracker reconciliation + `[DEFERRED]` tag
- 2026-04-17 `solo`: P41 — README rewrite, License section, Acknowledgements removed, About refreshed
- 2026-04-17 `solo`: P40 — Section 14 + Section 15.4 trim, Recent Work + Decisions compaction
- 2026-04-17 `solo`: P32-P39 — Trim, sync mechanism, two repo reviews, R5 pilot, measurement gap (Batch 0.13, commits 3e452b7, 2350a9f, 0632aad, 8977f46, ee1b012, 988ab69, ca3d57b)
- 2026-04-13 `solo`: P29-P30 — Pre-launch README polish + research digest review
- 2026-04-09 `solo`: Batch 0.11 — P23-P28 (benchmark framework, optimisations, Managed Agents, digest changes) + graphify research
- 2026-04-08 `solo`: Batches 0.4-0.10 — P14-P22, ECC adaptation, token optimisation, slash commands
- 2026-04-07 `solo`: Batches 0.1-0.3f — Initial scaffold + P1-P2-P11-P12-P13
<!-- recent-work-rollup:end -->

---

## Deprioritised

*Items moved here from priority lists above. Never removed.*
