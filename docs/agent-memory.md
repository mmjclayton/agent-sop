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
| Core SOP | `docs/sop/claude-agent-sop.md` |
| CLAUDE.md template | `docs/templates/claude-md-template.md` |
| Phase 0 build plan | `docs/build-plans/phase-0-foundation.md` |

---

## In-Flight Work

*(none — P43 dogfood completed 2026-04-19; P44/P45/P46/P47 all shipped 2026-04-19/20)*

---

## Decisions Made

See docs/agent-memory/decisions/. One file per decision. Migrated from legacy narrative on 2026-04-19.

---
## Gotchas and Lessons

See docs/agent-memory/gotchas/. One file per gotcha. Migrated from legacy narrative on 2026-04-19.

---

## Matt's Preferences

- Terse responses, no trailing summaries.
- Australian English in all outputs. No em-dashes.
- Exec-ready formatting: professional, clear, confident.

---

## Completed Work

- 2026-04-20: P48 — Reviewer voice rules lifted into `code-reviewer.md` (Finding Voice section: drop/keep lists, three before/after examples, auto-clarity carve-out). Backlog item-sizing pedagogy added to `backlog-template.md`. Both patterns sourced from direct review of `levu304/claude-code-boilerplate`; wholesale absorption rejected. User-scope `code-reviewer.md` mirrored, baselines refreshed.
- 2026-04-20: P47 — Drift-check legacy-resume fallback now fires regardless of agent-id. `/restart-sop` Step 0d mirrored. One-line advisory on non-`solo` fallback points at `/migrate-to-multi-agent`. Adjacent `set -u` bug fixed (`$root` unbound when `CLAUDE_AGENT_ID` preset). Four dogfood scenarios pass. User-scope slash command mirrored.
- 2026-04-09: P28 — Research digest: S3 skip-permissions check, context-management.md (compaction/clearing/memory API), memory API note in Section 1, Section 18 SOP evolution loop, sop-hill-climbing.md guide. 8 digest suggestions evaluated; 5 implemented, 8 skipped (would add tokens without proven quality improvement).
- 2026-04-09: P27 — Managed Agents integration. Outcome rubrics (Definition of Done) added to SOP Section 12 and both templates. Permission policy safety for benchmarks. Multi-agent callable patterns in Section 16 with coordinator/specialist configs. Section 17 Managed Agents Integration Guide (memory store mapping, skills guidance, session lifecycle, outcome grading). Benchmark README updated with Managed Agents harness design.
- 2026-04-09: P26 — Benchmark-driven optimisations applied. Common Mistakes mandatory for code projects. 300-line limit for code CLAUDE.md. Intent-only dispatch enforced (Area|File deprecated). Lightweight start for [ok-for-automation]. Multi-agent context routing (Section 16). agent-memory.md optional <10 sessions. Benchmark safety rules (no push to main). Naming convention gotcha requirement.
- 2026-04-09: P25 — Benchmark findings incorporated into SOP. New Section 15 (Benchmark-Proven Practices): Common Mistakes requirement, intent-rich dispatch pattern, vague prompt resilience. Both templates updated. 4 new compliance checks (BP1-BP4). README updated with results. Implementation guide updated.
- 2026-04-09: P23 — SOP Benchmark Framework shipped with two rounds. Round 1 (precise prompts): SOP 68/72 vs Baseline 62/72 (+8%). Round 2 (vague prompts, sharpened SOP): SOP 78/84 vs Baseline 50/84 (+33%). Key finding: "Common Mistakes" section prevented 2 production bugs. Intent-rich dispatch outperforms file-path lists. Vague prompts amplify SOP advantage dramatically. Full results at docs/benchmark/results/.
- 2026-04-08: P22 — Session slash commands shipped. `/restart-sop` and `/update-sop` in `.claude/commands/`. All SOP docs updated to reference as mandatory. Installed at user level for all projects.
- 2026-04-08: P21 — Setup script shipped at `setup.sh`. Bash onboarding script with --code and --force flags. README updated to recommend as primary setup path.
- 2026-04-08: README rewritten: removed all em dashes, added verified token efficiency section (measured per-file costs, model-specific context windows, library-vs-session ratio), ECC attribution corrected to affaan-m.
- 2026-04-08: P6 — New project walkthrough shipped at `docs/examples/new-project-walkthrough.md`. Uses concrete Taskflow example.
- 2026-04-08: P7 — Existing project migration guide shipped at `docs/examples/existing-project-migration.md`. Checklist format, 7 steps.
- 2026-04-08: README updated with ECC attribution, new examples and templates tables.
- 2026-04-08: P3 — Agent memory template shipped at `docs/templates/agent-memory-template.md`.
- 2026-04-08: P4 — Backlog template shipped at `docs/templates/backlog-template.md`.
- 2026-04-08: P5 — Build plan template shipped at `docs/templates/build-plan-template.md`.
- 2026-04-08: Token optimisation commit — SOP line-range index, unified checklists, merged dispatch, trimmed templates.
- 2026-04-08: sop-checker agent updated for C3 (5 steps), C4 (7 steps), C5/C7 (merged header).
- 2026-04-08: Implementation guide updated for current SOP state.
- 2026-04-08: README rewritten.
- 2026-04-08: P14 — Security guidance document shipped at `docs/sop/security.md`.
- 2026-04-08: P15 — Hooks guidance with 6 reference implementations shipped at `docs/sop/hooks.md`.
- 2026-04-08: P16 — Code quality rules added to `docs/templates/claude-md-template-code.md`.
- 2026-04-08: P17 — 4 reference agent definitions shipped in `.claude/agents/`.
- 2026-04-08: P18 — Auth, Database, Key Commands, Design System sections expanded in code template.
- 2026-04-08: P19 — Continuous learning pattern added to SOP Section 12.
- 2026-04-08: P20 — 6 new compliance checks added to checklist Section 9. sop-checker agent updated.
- 2026-04-07: Batch 0.1 — Project scaffold created. All standard files in place.
- 2026-04-07: P1 — Core SOP document published at `docs/sop/claude-agent-sop.md`.
- 2026-04-07: P2 — CLAUDE.md base template published at `docs/templates/claude-md-template.md`.
- 2026-04-07: P11 — CLAUDE.md code template published at `docs/templates/claude-md-template-code.md`.
- 2026-04-07: 9 SOP improvements applied — Quick Reference Card, template split, `[WON'T]` format, project_resume.md naming lock, Key Documents sync rule, `[VERIFIED]` non-code definition, interrupted session recovery protocol, Issue Tracker Sync Rules rename, phase boundary definition.

---

## Archived

Historical decisions moved to docs/agent-memory/decisions/archive/ on 2026-04-19 (P43 Batch 1.6 migration). Historical gotchas moved to docs/agent-memory/gotchas/archive/.

