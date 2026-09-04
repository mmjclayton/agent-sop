# Agent SOP — Standard Operating Procedure Library for Claude Code

> The reference implementation for consistent, productive Claude Code agent sessions.

---

## Agent SOP

**Project type:** code — Markdown by volume, but the hooks, installer and validators under `scripts/` are bash with a fixture suite, and the ship-sop gate reviews them. Read by `scripts/hooks/sop-project-type.sh`; delete the line to fall back to the heuristics (which would say non-code: no manifest).

This project IS the Agent SOP library. All agents working on this project still follow the SOP defined in `docs/sop/claude-agent-sop.md` — including the never-delete-without-a-trace rule and session checklists. Conflict precedence: code/git > CLAUDE.md > Backlog.md > build-plan > feature-map > agent-memory > resume point.

---

## Build Plans — READ FIRST

Each phase file carries its own `Status:` header. Read the directory rather than
trusting a status list here - the previous one still called phase 1 "Planning"
months after the file itself said Shipped.

---

## Key Documents & Dispatch

| Area | File | Purpose |
|------|------|---------|
| Agent Memory | `docs/agent-memory.md` | Cross-session decisions, gotchas |
| Feature Map | `docs/feature-map.md` | Shipped documents + roadmap |
| Backlog | `Backlog.md` | Single source of truth for work items |
| Core SOP | `docs/sop/claude-agent-sop.md` | Non-negotiable rules (Section 0), file specs, session checklists |
| Multi-Agent | `docs/sop/multi-agent.md` | Entry point, decision tree, optimisation rules, Common Mistakes (deep mechanics in `docs/guides/multi-agent-*.md`) |
| Build Plan | `docs/build-plans/phase-0-foundation.md` | Current phase |
| Compliance | `docs/sop/compliance-checklist.md` | Audit checks + scoring (used by sop-checker agent) |
| Security | `docs/sop/security.md` | Core security rules |
| Sandboxing | `docs/sop/sandboxing.md` | Container / network isolation for autonomous runs |
| Harness | `docs/sop/harness-configuration.md` | Hooks + context primitives (clearing, compaction, memory) |
| Guides | `docs/guides/` | Optional patterns, multi-agent routing, Managed Agents (deferred), SOP hill-climbing, cross-layer rules |
| Cross-layer rules | `docs/guides/cross-layer-rules.md` | Unify-first / parity-fixture pattern when one logical rule lives in more than one runtime |
| Templates | `docs/templates/claude-md-template.md` | Base template for new projects |
| SOP Checker | `.claude/agents/sop-checker.md` | Compliance audit agent |
| `/finish` command | `.claude/commands/finish.md` | End-to-end verify + `/simplify` + ship (Backlog, `/update-sop`, PR) |
| Hooks | `scripts/hooks/`, `scripts/install-hooks.sh` | User-scope context load, Stop drift gate, push gate (P97), project-type rule (P102); fixtures in `docs/benchmark/hook-fixtures/` |

---

## Current Priority Items (as of 2026-09-04)

**Next:**
- **Owed (consumer repos):** drop the superseded project-scope ship-sop Stop hook from `.claude/settings.json` in hst-tracker, opportunity-scan, os-carry and ship-sop on each project's next session (ship-sop P25).
- P77 / P89 instruction-budget trim — the Stop hook now enforces the minimum session-end at the trigger, so the text trim carries no record-loss risk; follow P90's anchor-conversion ordering.
- **Owed:** first lite benchmark run. The rule is MANDATORY as of Batch 0.27; both 2026-07-26 sessions took a recorded exemption, and Batches 0.28-0.29 did not trigger it (no agent-facing instruction text changed). Batch 0.36 changed agent-facing text and took the same recorded exemption: P81 records the framework as unable to run (April `BASE_COMMIT`, no model pinning). Resolve P81 before this can be discharged.

**Decision-blocked:**
- P8 — Web app domain variant `[has-open-questions]`
- P9 — Marketing domain variant `[has-open-questions]`
- P10 — Data/analytics domain variant `[has-open-questions]`

**Deferred with reopen triggers:**
- P64 full support (AGENTS.md template + `setup.sh --multi-tool` + check) — reopens when Claude Code reads AGENTS.md natively
- `sandbox.credentials` recommendation — reopens when the setting is verified in the Claude Code changelog

**Follow-ups still open:**
- R6 full-framework benchmark on fresh CLI sessions, Opus 4.6, 2+ rounds (deferred from P38 — run if publicly citing a post-trim percentage)

---

## Backlog Management

`Backlog.md` is the single source of truth. Never delete without a trace — update in place, mark superseded, or archive.

### Tag taxonomy
- Status (first): `[OPEN]` `[IN PROGRESS]` `[BLOCKED]` `[DEFERRED]` `[SHIPPED - YYYY-MM-DD]` `[VERIFIED - YYYY-MM-DD]` `[WON'T]`
- Type (second): `[Feature]` `[Iteration]` `[Bug]` `[Refactor]`
- Optional: `[has-open-questions]` `[ok-for-automation]`
- `[DEFERRED]` must carry a reopen trigger: `**Reopens when:** <observable condition>`. "No trigger identified" is legal and marks it a `[WON'T]` candidate at next review.

### Rules
- Never mark `[SHIPPED]` without the document existing and being complete.
- Never delete items from Backlog.md.
- Status first, type second. Never reverse.

---

## Stack

- Format: mostly Markdown, plus bash and Python tooling in `scripts/`
  (`setup.sh`, `validate-state-transitions.sh`, `migrate-to-multi-agent.py`,
  `install-hooks.sh`, the user-scope hooks under `scripts/hooks/`)
- Hosting: GitHub, `mmjclayton/agent-sop`, public
- No build step, but there ARE tests: the fixture suites under
  `docs/benchmark/*-fixtures/run-tests.sh`. Run them when touching the validator
  or the migration script.

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

Memory files live at `~/.claude/projects/-Users-matt-clayton-Projects-agent-sop/memory/`.

### Session start checklist
1. Read CLAUDE.md.
2. Read `MEMORY.md` + `project_resume.md`.
3. Read `docs/agent-memory.md`.
4. Run `git log --oneline -10`, cross-check memory against current file state.
5. Read the specific Backlog.md item(s) for this session.

If In-Flight Work is populated or `project_resume.md` has no What's Next — previous session was interrupted. Read the build plan Batch Log before starting new work.

### Session end checklist
**Never delete without a trace. Update in place, mark superseded, or archive.**

0. Pre-flight: collect or terminate any outstanding background subagents (background-by-default since Claude Code 2.1.198).
1. Run tests (code projects) — fix failures before proceeding.
2. `Backlog.md` — update status tags in place, append new items. Step 2a hard-blocks P-number collisions with the default branch.
3. Secondary trackers — reconcile any project-specific finding files in Key Documents (audit-backlog, security-findings, etc.) using heading-level `[OPEN]`/`[SHIPPED]` tags. Commit-range partitioned via `git merge-base`. Hard block on unreconciled finding IDs.
4. `docs/feature-map.md` — append shipped items.
5. `docs/agent-memory.md` narrative + decisions/gotchas directories — write to `docs/agent-memory/decisions/` and `docs/agent-memory/gotchas/`; update In-Flight/Completed in agent-memory.md by agent-id.
6. `docs/build-plans/phase-N.md` — append to Batch Log.
7. `project_resume_<agent-id>.md` — overwrite with current state (per-agent snapshot). Resolve the path with `bash scripts/resolve-resume-path.sh`; never hand-construct it.
8. Write session entry to `docs/recent-work/` and refresh the `docs/RECENT-WORK.md` rollup.
9. Commit docs/ changes with the work.

---

## Where the history lives

Session records live in `docs/recent-work/`, indexed in `docs/RECENT-WORK.md`.
Status lives in `Backlog.md`. Neither is duplicated here.
