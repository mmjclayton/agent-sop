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
- P43 — Parallel multi-agent session support (Phase 1 — plan shipped 2026-04-19, ready to execute Batch 1.1)
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
2. `Backlog.md` — update status tags in place, append new items.
3. Secondary trackers — reconcile any project-specific finding files in Key Documents (audit-backlog, security-findings, etc.) using heading-level `[OPEN]`/`[SHIPPED]` tags. Hard block: finding IDs referenced in this session's commits must not be left `[OPEN]`.
4. `docs/feature-map.md` — append shipped items.
5. `docs/agent-memory.md` — append decisions/gotchas, move completed to Completed Work.
6. `docs/build-plans/phase-N.md` — append to Batch Log.
7. `project_resume.md` — overwrite with current state.
8. Commit docs/ changes with the work.

---

## Recent Work (rollup)

<!-- recent-work-rollup:start -->
*Auto-generated from `docs/recent-work/`. Last refreshed: 2026-04-19.*

- 2026-04-19 `solo`: P43 Batch 1.2 — directory structure + rollup specs
<!-- recent-work-rollup:end -->

---

## Recent Work (legacy, pending Batch 1.6 migration)

*Pre-2026-04-19 session-day entries preserved here until `/update-sop --migrate-to-multi-agent` lands in Batch 1.6 and extracts them into `docs/recent-work/`. After migration this section will be removed. Full detail for each entry lives in build-plan Batch Log + Backlog.md per item.*

### 2026-04-19: P42 — Secondary-tracker reconciliation + `[DEFERRED]` tag (commit 0c95727)
Close a gap surfaced by hst-tracker: `/update-sop` treated `Backlog.md` as the sole work tracker and never reconciled project-specific finding files (e.g. `audit-backlog-*.md`) that use the same status-tag discipline. Fixed at four points. Core SOP Section 6 session-end checklist gained new step 3 (reconcile any `.md` in CLAUDE.md Key Documents using heading-level status tags); total 7 → 8 steps. `/update-sop` Step 3b auto-detects trackers (skip `Backlog.md`), reconciles finding IDs from this session's commits; Step 11 hard-blocks the commit if any ID is still `[OPEN]`. `/restart-sop` Step 4 gained an advisory drift guard for prior-session drift. Section 8 gains `[DEFERRED]` as distinct from `[BLOCKED]` (waiting-external vs intentionally-postponed). Templates + compliance checklist propagated (B4 accepts `[DEFERRED]`; new X6 check; totals 66 → 67 / 75 → 76). Heuristic is auto-detect rather than config opt-in — opt-in recreates the failure mode at a different level.

### 2026-04-17: P41 — README rewrite, License section, Acknowledgements removed, About refreshed (commits 38a3476, e36cb53)
README compressed 465 → 119 lines. Hero reframed to "Standard operating procedures and product management discipline for Claude Code sessions" anchored on the standard file set + three slash commands. New Backlog discipline + Cross-session memory sections make the PM angle concrete. Removed: TOC, token-efficiency math wall, four-table What's Included, repository tree, expanded session-checklist + six-rules commentary, A/B benchmark badge, Acknowledgements. Added: License section. Verbatim review against ECC found no copied prose — pattern inspiration only, MIT attribution not required. Aesthetic aligned with claude-code-action and superpowers reference READMEs. GitHub About description rewritten.

### 2026-04-17: P40 — Section 14 + Section 15.4 trim, Recent Work + Decisions compaction (commit 5b36751)
Section 14 Common Mistakes table moved to `docs/guides/sop-common-mistakes.md`; Section 15.4 Managed Agents API safety block moved into `docs/guides/managed-agents-integration.md`. Core SOP ~189 → ~178 instructions (under 150 soft cap on first measure since Rule 5 was added). Same session: CLAUDE.md Recent Work compacted (older session-days rolled into one-liners) and agent-memory.md Decisions audited (pre-2026-04-09 entries moved to Archived with a dated relocation note). Token saving from CLAUDE.md alone is the larger win.

### 2026-04-17: P32-P39 — Trim, sync mechanism, two repo reviews, R5 pilot, measurement gap (Batch 0.13, commits 3e452b7, 2350a9f, 0632aad, 8977f46, ee1b012, 988ab69, ca3d57b)
Eight P-items in one session. Core SOP trim (~230 → ~195 instructions; Section 4 removed; Sections 12/16/17/18 to guides; hooks.md + context-management.md merged into harness-configuration.md; security.md collapsed). Section 0 expanded to six non-negotiable rules with *Prevents:* annotations. `/update-agent-sop` sync command shipped (three-way diff, never force-overwrites). Reviewed forrestchang/andrej-karpathy-skills (trace-to-request ported) and thedotmack/claude-mem (progressive retrieval, capture-time redaction, fail-open hooks ported). R5 post-trim benchmark pilot: SOP +16% aggregate (vs R2's +33%); README badge changed to "directional +16% to +33%". Measurement gap closed: session-hygiene rubric, continuity methodology, longitudinal exhibit (hst-tracker: 86 decisions, 23 batches, 64 docs commits). Full per-item detail in agent-memory.md Decisions.

### 2026-04-13: P29-P30 — Pre-launch README polish + research digest review (commits be449ac, 605cf60)
MIT LICENSE added; Status rewritten for outside readers; setup paths generalised; badges + TOC added; Claude Code v2.1.101+ noted. Weekly research digest reviewed with source verification (4 sources; AgentKit date in digest was wrong). Tier 1 slate cut 4 → 1 on "sharpening > adding" filter. Meta-decision logged: research digests bias toward additions; default filter is "what does this remove or sharpen".

### 2026-04-09: Batch 0.11 — P23-P28 (benchmark framework, optimisations, Managed Agents, digest changes) + graphify research
A/B benchmark framework: Round 1 precise prompts +8%, Round 2 vague prompts +33% (sharpening wins). Section 15 Benchmark-Proven Practices added; Common Mistakes mandatory for code projects; intent-rich dispatch. P24 multi-agent guide scoped (deferred). graphify evaluated and rejected (corpus too small for agent-sop; ARCHITECTURE.md preferred for hst-tracker).

### 2026-04-08: Batches 0.4-0.10 — P14-P22, ECC adaptation, token optimisation, slash commands (commits f928a42-3e8d340)
Security guidance, hooks guidance (6 reference implementations), code quality rules, 4 reference agents (code-reviewer, security-reviewer, planner, e2e-runner), expanded code template sections, continuous learning pattern, 6 new compliance checks. New project walkthrough + migration checklist. setup.sh shipped. `/restart-sop` and `/update-sop` slash commands shipped. README rewritten (em dashes removed, ECC attribution corrected to affaan-m, verified token efficiency section).

### 2026-04-07: Batches 0.1-0.3f — Initial scaffold + P1-P2-P11-P12-P13 (commits 79c5a5c-b0942cf)
Project scaffold (CLAUDE.md, Backlog.md, agent-memory.md, feature-map.md, phase-0 build plan, README.md). P1 Core SOP. P2 base CLAUDE.md template. P11 code template. P12 SOP v2 owner feedback iteration (10 changes including additive-only → never-delete-without-a-trace, snapshot resume model, conflict precedence). P13 SOP Compliance Checker agent + canonical checklist (~64 checks, three-tier scoring). Self-compliance fixes (49 → 100).

---

## Deprioritised

*Items moved here from priority lists above. Never removed.*
