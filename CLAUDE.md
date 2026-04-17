# Agent SOP — Standard Operating Procedure Library for Claude Code

> The reference implementation for consistent, productive Claude Code agent sessions.

---

## Agent SOP

This project IS the Agent SOP library. All agents working on this project still follow the SOP defined in `docs/sop/claude-agent-sop.md` — including the never-delete-without-a-trace rule and session checklists. Conflict precedence: code/git > CLAUDE.md > Backlog.md > build-plan > feature-map > agent-memory > resume point.

---

## Build Plans — READ FIRST

- `docs/build-plans/phase-0-foundation.md` — In Progress (scaffold, core SOP docs, templates)

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

## Current Priority Items (as of 2026-04-17)

**Next:**
- P24 — Multi-agent optimisation guide (informed by P23 benchmark results)
- P33 — Managed Agents integration guide (deferred — revive when a project uses Managed Agents API)
- P8 — Web app domain variant `[has-open-questions]`
- P9 — Marketing domain variant `[has-open-questions]`
- P10 — Data/analytics domain variant `[has-open-questions]`

**Follow-ups flagged from 2026-04-17 session:**
- Section 14 Common Mistakes table → guide (next low-risk trim candidate, ~-12 instructions)
- Config `exclude` field for per-project file skipping (gap found during hst-tracker audit — security.md filename collision)
- Karpathy-skills before/after examples pattern (Common Mistakes pedagogy — deferred from P34)

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
3. `docs/feature-map.md` — append shipped items.
4. `docs/agent-memory.md` — append decisions/gotchas, move completed to Completed Work.
5. `docs/build-plans/phase-N.md` — append to Batch Log.
6. `project_resume.md` — overwrite with current state.
7. Commit docs/ changes with the work.

---

## Recent Work

*Append-only. New entries at top. Include commit refs.*

### 2026-04-17: P37 — claude-mem review, three portable patterns adopted
Reviewed thedotmack/claude-mem (60.8k stars, Claude Code plugin, daemon + SQLite + ChromaDB). Confirmed categorically different from Agent SOP (observation/retrieval infrastructure vs prescription layer). Harvested three portable patterns: progressive retrieval (index → narrow → fetch) added as Routing Rule 5 in `multi-agent-context-routing.md`; `<private>` capture-time redaction added as Rule 9 in `security.md`; hooks-must-fail-open added as Core Rule 9 in `harness-configuration.md`. claude-mem positioned as optional complement in `optional-patterns.md`. Core SOP instruction count unchanged.

### 2026-04-17: P36 — SOP sync mechanism shipped
New `/update-agent-sop` slash command keeps consumer projects in sync with upstream. Three-way diff per file (upstream vs local vs baseline SHA); never force-overwrites locally modified files. `setup.sh` expanded to distribute the full 17-file pristine-replica surface (SOP docs + guides project-scope; slash commands + reference agents user-scope) and auto-create `~/.claude/agent-sop.config.json` with baseline SHAs. `/restart-sop` gained a Step 0 staleness warning (weekly by default, configurable via `update_reminder`). All 17 pristine-replica files now carry version markers — HTML comment for plain markdown, `sop_version:` YAML field for files with frontmatter. GitHub repo: `mmjclayton/agent-sop`.

### 2026-04-17: P35 — Section 4 Versioning Rules removed
Pure duplicate of Section 0 Rule 1 "How this works" bullets — self-declared via its own opening "See Section 0" line. Replaced with a one-line pointer. Core SOP ~197 → ~189 instructions. Zero content loss; grep confirmed no external "Section 4" references.

### 2026-04-17: P34 — Karpathy-skills findings applied
Rule 1 extended: *"Never delete without a trace. Never add without reason. Every changed line must trace directly to the user's request."* Closes the silent-add gap symmetric to silent-delete. Rule 6 added: *"Surface interpretations before acting."* Names the ambiguity-resolution pattern Rule 4 implied but didn't spell out. All six non-negotiable rules now carry an italic *Prevents:* annotation naming the failure mode each one prevents — format-only, zero instruction cost. Net: ~+4 instructions (~197 total in core SOP). Applied from the 2026-04-17 review of forrestchang/andrej-karpathy-skills.

### 2026-04-17: P32 — SOP instruction-budget trim
Added Rules 3 (no opinion, state facts), 4 (back-and-forth before planning), 5 (≤150 soft / 200 hard instruction cap) to Section 0. Audited full SOP: 392 instructions across 5 files, with `claude-agent-sop.md` alone at ~230 — breaching its own Rule 5. Cuts: Quick Reference Card removed (100% duplicate of Sections 0/5/6); Section 17 Managed Agents extracted to `docs/guides/managed-agents-integration.md` (deferred, P33); Sections 12, 16, 18 extracted to `docs/guides/`; `hooks.md` + `context-management.md` merged into `harness-configuration.md`; `security.md` collapsed, container/network-isolation content split to `sandboxing.md`; compliance-checklist left intact (tooling dependency — sop-checker agent references check IDs). Pre-trim snapshot archived at `.archive/sop-pre-trim-2026-04-17/` (gitignored). Core SOP 975→624 lines. Also reviewed forrestchang/andrej-karpathy-skills — 3 of 4 principles duplicate existing SOP coverage; "trace-to-request" phrasing and failure-mode annotations identified as candidate additions (not yet applied).

### 2026-04-13: P29-P30 — Pre-launch README polish + research digest review (commits be449ac, 605cf60)
P29: MIT LICENSE added (was missing — blocker for reuse), compliance check count corrected to 75/66, Status section rewritten for outside readers, agent-driven setup paths generalised to placeholder, badges and TOC added, Claude Code v2.1.101+ requirement noted in README and setup.sh. P30: Reviewed weekly research digest (4 sources verified directly — AgentKit date in digest was wrong). Tier 1 slate cut from 4 items to 1 on "sharpening > adding" filter; only the version note shipped. Decision logged: research digests bias toward additions; default filter is "what does this remove or sharpen".

### 2026-04-09: Research session — graphify analysis, P24 scoping
Evaluated safishamsi/graphify for use alongside agent-sop and hst-tracker. Conclusion: not valuable for agent-sop (too small, too well-structured), moderate value for hst-tracker but SOP dispatch already covers navigation. Recommended ARCHITECTURE.md over graphify for hst-tracker. Fleshed out P24 acceptance criteria with concrete scope informed by benchmark data.

### 2026-04-09: P23-P28 — Benchmark framework, optimisations, Managed Agents, digest changes
P23: A/B benchmark framework with 8 task specs, runner script, blind scoring. Two rounds against hst-tracker. Round 1 (precise prompts): SOP +8%. Round 2 (vague prompts, sharpened SOP): SOP +33%. P25: Incorporated findings into SOP Section 15 (Benchmark-Proven Practices), both templates (Common Mistakes + intent-rich dispatch), compliance checklist (BP1-BP4), implementation guide, README. Also committed sharpened CLAUDE.md to hst-tracker with Common Mistakes section.

### 2026-04-08: P6-P7, P21-P22 — Guides, setup script, slash commands (commits c4620b6-3e8d340)
New project walkthrough (P6), migration checklist (P7), setup.sh onboarding script (P21), /restart-sop and /update-sop slash commands (P22). README rewritten: em dashes removed, verified token efficiency section, ECC attribution corrected to affaan-m. Commands installed at user level for all projects.

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
