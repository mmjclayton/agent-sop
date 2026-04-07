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

*(none)*

---

## Decisions Made

- 2026-04-07: Project name is `agent-sop`. Short, descriptive, works as a GitHub repo name.
- 2026-04-07: Markdown only. No build process, no code, no dependencies.
- 2026-04-07: File structure — SOPs in `docs/sop/`, templates in `docs/templates/`, examples in `docs/examples/`.
- 2026-04-07: This project follows its own SOP — including additive-only writes and session checklists.
- 2026-04-07: P1 and P2 shipped as part of the initial scaffold (docs already existed from prior Cowork session).
- 2026-04-07: CLAUDE.md template split into base (`claude-md-template.md`) and code variant (`claude-md-template-code.md`). Base is stack-agnostic; code variant adds Auth, Database, Design System, and code build rules. P11 assigned to the code variant.
- 2026-04-07: project_resume.md filename is locked to exactly `project_resume.md` across all projects — no project-specific prefixes.
- 2026-04-07: `[WON'T]` tag now requires inline reason: `[WON'T] [Type] — Reason: ...`
- 2026-04-07: `[VERIFIED]` definition extended — code projects = tested in production; docs projects = reviewed by project owner and confirmed accurate.
- 2026-04-07: CLAUDE.md hard size limit set at 200 lines / 2,000 tokens (Anthropic guidance). Overflow goes to agent-memory.md or build plans.
- 2026-04-07: Context compaction threshold set at 60% (not 95%). At 60% capacity, wrap the current batch and run the session end checklist.
- 2026-04-07: Auto-memory (`~/.claude/projects/.../memory/`) is unreliable per community reports. Manual docs/agent-memory.md is the authoritative context source.
- 2026-04-07: Optional patterns section (Section 12) added - claude-progress.txt for human-readable status, .claude/agents/ for sub-agent delegation. Sections renumbered: old 12 is now 13, old 13 is now 14.
- 2026-04-07: CLAUDE.md 200-line limit reframed — applies to per-session sections only. Reference sections (Auth, Database, Design System) may extend beyond.
- 2026-04-07: Override hierarchy clarified — CLAUDE.md can override project-specific conventions but not the two non-negotiable rules (additive-only, single source of truth).
- 2026-04-07: Multi-agent contention rule added to Section 0 — separate branches, merge sequentially, resolve conflicts by appending both entries.
- 2026-04-07: Key Documents table in agent-memory.md replaced with pointer to CLAUDE.md — eliminates duplication per single-source-of-truth rule.
- 2026-04-07: "Additive-only" reframed to "never delete without a trace". In-place updates (status changes, folding answers, correcting errors) are expected. Silent removal is not. Based on real-world feedback from multi-session usage.
- 2026-04-07: Explicit conflict resolution precedence added: code/git > CLAUDE.md > Backlog.md > build-plan > feature-map > agent-memory > resume point.
- 2026-04-07: agent-memory.md vs auto-memory delineated: repo-committed for facts any contributor needs, local auto-memory for user preferences and session state.
- 2026-04-07: Test gates added to session-end checklist (step 1 for code projects).
- 2026-04-07: project_resume.md changed from prepend-only to overwrite (snapshot model). History belongs in batch logs.
- 2026-04-07: Schema change protocol added to SOP Section 12 and code template.
- 2026-04-07: Backlog archive threshold added — move shipped items older than 90 days to archive when file exceeds ~2,000 lines.
- 2026-04-07: "No derived facts in memory" rule added — store rules not measurements (test counts, line numbers, versions go stale immediately).
- 2026-04-07: Multi-agent contention expanded — docs conflicts resolve by appending, code conflicts require reading both versions, semantic conflicts flagged for human resolution.
- 2026-04-07: SOP Compliance Checker agent created (P13). Checklist at `docs/sop/compliance-checklist.md`, agent at `.claude/agents/sop-checker.md`. ~59 checks (non-code) / ~64 checks (code) across 8 categories. Three-tier scoring: Critical (cap at 49), Important (5pts), Recommended (2pts).
- 2026-04-07: Self-compliance fixes applied — 8-step session end checklist, [BLOCKED] in tag taxonomy, conflict precedence inline, commit refs in Recent Work and Batch Log, line-range hints in Key Documents. Score: 49 → 100.
- 2026-04-07: hst-tracker compliance checked three times (87 → 87 → 97). Validated the checker agent works against a real code project.

---

## Gotchas and Lessons

- [SUPERSEDED - 2026-04-07: replaced by "never delete without a trace" — in-place updates are now expected] 2026-04-07: The additive-only rule applies to the SOP docs themselves. When the SOP is updated, append corrections below existing content — do not overwrite sections.
- 2026-04-07: Do not store derived facts in agent-memory.md — test counts, line numbers, file sizes, dependency versions go stale immediately. Store the rule, not the measurement.

---

## Matt's Preferences

- Terse responses, no trailing summaries.
- Australian English in all outputs. No em-dashes.
- Exec-ready formatting: professional, clear, confident.

---

## Completed Work

- 2026-04-07: Batch 0.1 — Project scaffold created. All standard files in place.
- 2026-04-07: P1 — Core SOP document published at `docs/sop/claude-agent-sop.md`.
- 2026-04-07: P2 — CLAUDE.md base template published at `docs/templates/claude-md-template.md`.
- 2026-04-07: P11 — CLAUDE.md code template published at `docs/templates/claude-md-template-code.md`.
- 2026-04-07: 9 SOP improvements applied — Quick Reference Card, template split, `[WON'T]` format, project_resume.md naming lock, Key Documents sync rule, `[VERIFIED]` non-code definition, interrupted session recovery protocol, Issue Tracker Sync Rules rename, phase boundary definition.

---

## Archived

*(none yet)*
