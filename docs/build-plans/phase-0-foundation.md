# Phase 0 — Foundation

Status: In Progress

---

## Problem

The Agent SOP exists as loose documents in an outputs folder. It needs a proper home — a structured project that itself follows the SOP, can be shared publicly, and extended with templates and examples.

---

## Scope

| Batch | What | Priority |
|-------|------|----------|
| 0.1 | Project scaffold (all standard files) | P0 |
| 0.2 | Publish core SOP document (P1) | P0 |
| 0.3 | Publish CLAUDE.md template (P2) | P0 |
| 0.4 | Publish remaining templates: agent-memory, Backlog, build-plan (P3-P5) | P1 |
| 0.5 | Publish example guides: new project walkthrough, migration guide (P6-P7) | P1 |

---

## Architecture

Pure markdown library. No code, no build process. Structure:

```
agent-sop/
  CLAUDE.md
  Backlog.md
  README.md
  docs/
    agent-memory.md
    feature-map.md
    sop/
      claude-agent-sop.md
      variants/         (P8-P10, future)
    templates/
      claude-md-template.md
      agent-memory-template.md
      backlog-template.md
      build-plan-template.md
    examples/
      new-project-walkthrough.md
      existing-project-migration.md
    build-plans/
      phase-0-foundation.md
```

---

## Key Decisions Locked In

- [LOCKED] Markdown only — no build tools, no dependencies.
- [LOCKED] Project follows its own SOP — additive-only writes, session checklists, all standard files.
- [LOCKED] Templates in `docs/templates/`. SOPs in `docs/sop/`. Examples in `docs/examples/`.
- [LOCKED] P-numbers in Backlog.md are permanent document identifiers.

---

## Batch Log

*Append-only. Format: YYYY-MM-DD: Batch N.X — description.*

- 2026-04-19: Batch 0.15 — P45 shipped. State-transition validator (`scripts/validate-state-transitions.sh`, zero-dep bash, 0.2s on 200-item Backlog) enforces the Backlog status-tag transition graph. Runs as `/update-sop` Step 3c after Backlog updates; hard-blocks illegal transitions (`<absent>` → `[SHIPPED]`, terminal revivals) and `[SHIPPED]` without Batch Log reference. Graph relaxed during implementation so `[OPEN]`/`[BLOCKED]`/`[DEFERRED]` → `[SHIPPED]` is legal when Batch Log reference exists — the Batch Log is the anti-gaming teeth; the `[IN PROGRESS]` intermediate was bookkeeping, not enforcement. 6 fixtures ship under `docs/benchmark/state-transition-fixtures/`. Section 8 of core SOP gained the transition table (+3 instructions). Shared `--assert-review` subcommand prepared for P44. Compliance check B11 + sop-checker guidance added. First item shipped via its own new `/update-sop` Step 3c — dogfood clean.
- 2026-04-07: Batch 0.1 — Project scaffold created. CLAUDE.md, Backlog.md, docs/agent-memory.md, docs/feature-map.md, docs/build-plans/phase-0-foundation.md, README.md. Commit 79c5a5c.
- 2026-04-07: Batch 0.2 — P1 shipped. Core SOP published at docs/sop/claude-agent-sop.md. Commit 79c5a5c.
- 2026-04-07: Batch 0.3 — P2 shipped. CLAUDE.md base template published at docs/templates/claude-md-template.md. Commit 79c5a5c.
- 2026-04-07: Batch 0.3b — P11 shipped. CLAUDE.md code template published at docs/templates/claude-md-template-code.md. Commit 79c5a5c.
- 2026-04-07: Batch 0.3c — 9 SOP improvements applied following independent analysis: Quick Reference Card, template split, [WON'T] format standard, project_resume.md naming lock, Key Documents sync rule, [VERIFIED] non-code definition, interrupted session recovery, Issue Tracker Sync Rules rename, phase boundary definition. Commit 79c5a5c.
- 2026-04-07: Batch 0.3d — P12 shipped. SOP v2 owner feedback iteration: 10 changes applied. Reframed additive-only rule, delineated memory systems, added test gates, snapshot resume model, conflict precedence, schema protocol, backlog archive threshold, no-derived-facts rule, multi-agent code conflict nuance. All templates and tracking files updated. Commit 79c5a5c.
- 2026-04-07: Batch 0.3e — P13 shipped. SOP Compliance Checker agent and canonical compliance checklist. ~64 checks across 8 categories with three-tier scoring system. Agent definition at `.claude/agents/sop-checker.md`, checklist at `docs/sop/compliance-checklist.md`. Commit c0b697d.
- 2026-04-07: Batch 0.3f — Self-compliance fixes. 8-step session end checklist, [BLOCKED] tag, conflict precedence, commit refs, line-range hints. Score: 49 → 100. Commit b0942cf.
- 2026-04-08: Batch 0.4 — P14-P20 shipped. Security guidance, hooks guidance, code quality rules, 4 reference agents, expanded code template sections, continuous learning pattern, 6 new compliance checks. Adapted from ECC reference repo. Commits f928a42-28dc771.
- 2026-04-08: Batch 0.5 — Token optimisation. SOP line-range index, unified checklists (5 start / 7 end), merged Key Documents + Dispatch, trimmed template Backlog Management. Net -100 lines. Compliance checks C3/C4/C5/C7 updated. sop-checker agent updated. Commits 71a34e0-fd29ee9.
- 2026-04-08: Batch 0.6 — P3-P5 shipped. Standalone templates for agent-memory, backlog, and build plan. Implementation guide and README updated. Commits a812881-606e49e.
- 2026-04-08: Batch 0.7 — P6-P7 shipped. New project walkthrough (concrete Taskflow example), existing project migration checklist. README updated with ECC attribution, new examples table. All tracking files updated. Commit c4620b6.
- 2026-04-08: Batch 0.8 — README quality pass. Removed all em dashes, corrected ECC attribution to affaan-m. Added verified token efficiency section with per-file measurements, model-specific context windows, and library-vs-session ratio. Commits ba5ea4c-b3235da.
- 2026-04-08: Batch 0.9 — P21 shipped. Setup script (`setup.sh`) for onboarding new projects. Supports --code and --force flags. README updated to recommend script as primary setup path. Commit b36dd89.
- 2026-04-08: Batch 0.10 — P22 shipped. `/restart-sop` and `/update-sop` slash commands with YAML frontmatter. setup.sh updated to copy commands. All SOP docs (core SOP, both templates, README, implementation guide) updated to reference commands as mandatory. Installed at user level for all projects. Commits 0d682b8-3e8d340.
- 2026-04-19: Batch 0.16 — P42 shipped. Secondary-tracker reconciliation mechanism. Core SOP Section 6 gained new step 3 (reconcile project-specific finding files via CLAUDE.md Key Documents auto-detect); steps 7 → 8. Section 8 gained `[DEFERRED]` tag with distinction from `[BLOCKED]`. `/update-sop` Step 3b auto-detects trackers (scan `.md` files in CLAUDE.md Key Documents, match heading-level status tags, skip `Backlog.md`), reconciles finding IDs from session commits; Step 11 hard-blocks commit if any ID is still `[OPEN]`. `/restart-sop` Step 4 added advisory drift guard. Templates (backlog, claude-md base, claude-md code) propagated. Compliance checklist: B4 accepts `[DEFERRED]`; new X6 check (secondary tracker currency); summary totals 66 → 67 / 75 → 76. Version markers bumped to 2026-04-19 on all touched pristine-replica files. Root cause: hst-tracker had 118 shipped audit items marked `[OPEN]` in `docs/audit-backlog-2026-04-18.md` for a day because `/update-sop` only named `Backlog.md`. Commit 0c95727.

- 2026-04-17: Batch 0.15 — P41 shipped. README rewrite 465 → 119 lines anchored on operating-practice + PM-discipline framing. New Backlog discipline + Cross-session memory sections. License section added. Acknowledgements removed after verbatim review confirmed pattern inspiration only. A/B benchmark badge removed. GitHub About description rewritten. Aesthetic aligned with claude-code-action and superpowers reference READMEs. Commits 38a3476, e36cb53.
- 2026-04-17: Batch 0.14 — P40 shipped. Section 14 Common Mistakes table extracted to `docs/guides/sop-common-mistakes.md`; Section 15.4 Managed Agents API safety block extracted to `docs/guides/managed-agents-integration.md`; CLAUDE.md Recent Work compacted (16 entries → 6); agent-memory.md Decisions audited (pre-2026-04-09 entries moved to Archived). Core SOP ~189 → ~178 instructions (under 150 soft cap target met for the first time since Rule 5 was added in P32). CLAUDE.md 183 → 153 lines. Commit 5b36751.
- 2026-04-17: Batch 0.13 — P32-P39 shipped in one session. Instruction-budget trim (core SOP 230→195), new Rules 3-6 in Section 0 (no opinion, back-and-forth before plan, instruction budget ≤150/200, surface interpretations), Rule 1 extended with trace-to-request clause, failure-mode *Prevents* annotations on all six rules, Section 4 removed as duplicate, Managed Agents deferred to docs/guides/. `/update-agent-sop` sync mechanism (three-way diff, no force-overwrite), setup.sh expanded to full pristine-replica surface, ~/.claude/agent-sop.config.json baseline SHA tracking, /restart-sop staleness check. Reviewed forrestchang/andrej-karpathy-skills (trace-to-request phrasing ported) and thedotmack/claude-mem (progressive retrieval, capture-time redaction, fail-open hooks ported; positioned as optional complement). R5 post-trim benchmark pilot: SOP +16% aggregate, 3/4 task wins, directional not authoritative. README audit tightened unsubstantiated claims. Measurement gap closed: session-hygiene rubric (7 new 0/1 dimensions), continuity benchmark methodology (dependent task pairs), longitudinal exhibit (hst-tracker: 86 decisions, 23 batch entries, 18 Recent Work, 64 docs commits, 4,628 tracking-file lines). Commits 3e452b7, 2350a9f, 0632aad, 8977f46, ee1b012, 988ab69.
- 2026-04-13: Batch 0.12 — P29 + P30 shipped. Pre-launch README polish for public traffic: MIT LICENSE added (was missing), compliance check count corrected to 75/66, Status section rewritten for outside readers, agent-driven setup paths generalised, badges + TOC added. Requirements section recommending Claude Code v2.1.101+ added with non-blocking version check in setup.sh. Research digest reviewed (4 sources verified directly, Tier 1 slate cut from 4 to 1 item on "sharpening > adding" filter). Commits be449ac, 605cf60.
- 2026-04-09: Batch 0.11 — P23-P28 shipped. A/B benchmark framework (5 rounds, 40+ agent runs). Key findings: Common Mistakes + Intent Dispatch = optimal config (+33% at peak). Gotcha entries must state what IS correct. Definition of Done removed (hurt bug fixes). Managed Agents integration (Sections 16-17). Research digest: context-management.md, S3 check, Section 18 evolution loop, hill-climbing guide. Commands updated with lightweight start + DoD self-evaluation. 28 P-items total.

---

## Deploy Checklist

Before marking Phase 0 shipped:
- [x] All P1-P5 documents exist at their specified paths and are complete
- [x] Backlog.md statuses updated for all shipped items
- [x] feature-map.md updated with all shipped documents
- [x] README.md accurate and up to date
- [x] Initial GitHub repo created and pushed
- [x] P6-P7 example guides shipped
- [x] P21 setup script shipped
- [ ] Owner review and verification of all shipped documents

---

## Open Questions

- 2026-04-07: Create GitHub repo before or after Phase 0 completes? [RESOLVED - 2026-04-08: created during Phase 0, pushed incrementally as work shipped]
