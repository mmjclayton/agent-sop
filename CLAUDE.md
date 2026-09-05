# Agent SOP — Standard Operating Procedure Library for Claude Code

> The reference implementation for consistent, productive Claude Code agent sessions.

---

**Project type:** code — Markdown by volume, but the hooks, installer and validators under `scripts/` are bash with fixture suites, and the ship-sop gate reviews them. Read by `scripts/hooks/sop-project-type.sh`; without the line the heuristics would say non-code (no manifest).

## Agent SOP

This project IS the SOP library and follows `docs/sop/claude-agent-sop.md` itself. This file is the authority on project conventions, the SOP on process. Start: the context hook prints project state on the first prompt, then `/restart-sop` reads the work item. End: `/update-sop`; the Stop hook enforces the minimum record and the ship-sop gate here. Never delete without a trace; when files disagree, code and git win, then this file, then `Backlog.md`.

---

## Key Documents & Dispatch

| When you need to... | Start at | Notes |
|---------------------|----------|-------|
| Check or update work items | `Backlog.md` | Grep `^### P<n>`, read only that range; closed items older than 90 days live in `docs/backlog-archive.md` |
| Read why something was decided, or what bites | `docs/agent-memory/decisions/`, `docs/agent-memory/gotchas/` | Newest first; the two reviewer-overwrite gotchas before launching any Bash-armed subagent |
| Change process rules | `docs/sop/claude-agent-sop.md` | Section numbers are stable; the compliance checklist greps them |
| Change what a hook does | `scripts/hooks/sop-lib.sh` (shared rules), then the hook script | Every rule the Stop hook, push gate and context block share lives in the lib; fixtures in `docs/benchmark/hook-fixtures/run-tests.sh` |
| Change the validator | `scripts/validate-state-transitions.sh`, the `[SHIPPED]` block | Fixtures in `docs/benchmark/state-transition-fixtures/`; expect-stdout files pin messages |
| Change what a consumer project receives | `.claude/commands/update-agent-sop.md`, the file table | Pristine-replica rows are SHA-tracked in `~/.claude/agent-sop.config.json` |
| Audit a project | `.claude/agents/sop-checker.md`, `docs/sop/compliance-checklist.md` | Check IDs are stable |
| Run more than one agent on this repo | `docs/sop/multi-agent.md` | Worktrees, agent-ids, merge discipline |
| Read phase architecture | `docs/build-plans/` | Each file carries its own `Status:`; planning notes, not a required log |

Test: `bash docs/benchmark/hook-fixtures/run-tests.sh` (also `resume-path-fixtures`, `state-transition-fixtures`, `drift-fixtures`, `priorities-fixtures`; run every suite when touching `scripts/`)

### Current priority items

<!-- Derived from Backlog.md by scripts/refresh-priorities.sh at every /update-sop. Do not edit by hand. -->

<!-- priority-items:start -->
*Derived from `Backlog.md` by `scripts/refresh-priorities.sh`. Do not edit by hand — the Backlog is the source of truth. Last refreshed: 2026-09-05.*

- P8 — Web app domain variant — [OPEN] [Feature] [has-open-questions]
- P9 — Marketing domain variant — [OPEN] [Feature] [has-open-questions]
- P10 — Data/analytics domain variant — [OPEN] [Feature] [has-open-questions]
- P78 — Automate `cross-layer-rules.md` Tier 0 across instruction files — [OPEN] [Feature]
- P79 — `sandboxing.md` treats the sandbox as protecting the host, never the reverse — [OPEN] [Iteration]
- P80 — Benchmark rubric: pairwise scoring, and read judge reasoning not scores — [OPEN] [Iteration]
- P81 — The MANDATORY lite benchmark rule fires on changes its instrument cannot measure — [OPEN] [Bug]
- P105 — Prose trim, validator retarget, Backlog archive: the SOP keeps what a session reads — [IN PROGRESS] [Refactor]
<!-- priority-items:end -->

---

## Backlog Management

`Backlog.md` is the single source of truth for work items. Status first, type second, never reversed: `[OPEN]` `[IN PROGRESS]` `[BLOCKED]` `[DEFERRED]` `[SHIPPED - YYYY-MM-DD]` `[VERIFIED - YYYY-MM-DD]` `[WON'T]`, then `[Feature]` `[Iteration]` `[Bug]` `[Refactor]`. `[DEFERRED]` states `**Reopens when:**`; `[WON'T]` states `Reason:`. A shipped `[Feature]` or `[Refactor]` carries a `review:` line or a `review skipped (P<n>): <reason>` token; this repo's own SOP-executed files trigger the review for every item. Never delete an item.

---

## Stack

- Markdown, plus bash and Python tooling in `scripts/` (`setup.sh`, `install-hooks.sh`, the hooks under `scripts/hooks/`, `validate-state-transitions.sh`, `resolve-resume-path.sh`, `archive-backlog.sh`, `migrate-to-multi-agent.py`)
- Hosting: GitHub, `mmjclayton/agent-sop`, public; no CI, merge on a green fixture run
- Tests: the fixture suites under `docs/benchmark/*-fixtures/run-tests.sh`

---

## Common Mistakes — Read Before Working

- A subagent with Bash writes into the live tree even when told not to and given a worktree path; launch every reviewer with `isolation: "worktree"` (gotchas 2026-09-04 and 2026-09-05).
- The push gate matches a push verb anywhere outside quotes and heredoc bodies; a command that only mentions `git push` in a quoted string is fine, one that runs it is refused until a report covers HEAD.
- Editing a pristine-replica file (the `update-agent-sop.md` table) without refreshing `baseline_shas` in `~/.claude/agent-sop.config.json` fails `--check-replication`; the installed copy is what runs, not the repo.
- `LC_ALL=C` is exported by `sop-lib.sh`: every pattern there is ASCII, and a UTF-8 locale made BSD grep abort a whole file on one invalid byte.
- The fixture helpers (`push_json`, `commit_record`) are defined at the top of `run-tests.sh`; a case that calls a helper before its definition passes vacuously.

---

## Rules for Automated Builds

1. Read the Backlog item, then the existing code, before changing anything.
2. New SOP documents go in `docs/sop/`, templates in `docs/templates/`, guides in `docs/guides/`; every new document has a Backlog entry.
3. Every hook or validator change carries a fixture that fails against the previous commit.
4. Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`.

---

## Where the history lives

Session records: `docs/recent-work/`, rolled up in `docs/RECENT-WORK.md`. Status: `Backlog.md`. Neither is duplicated here.
