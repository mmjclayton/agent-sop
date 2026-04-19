# Agent SOP

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-v2.1.101+-orange.svg)](https://code.claude.com/docs/en/changelog)
[![Status](https://img.shields.io/badge/status-active-success.svg)](#status)

Standard operating procedures and product management discipline for Claude Code sessions. A defined file set, six non-negotiable rules, session start/end checklists, a Backlog with status tags and P-numbers, build plans with phases and batch logs, and a feature map — together they give every session a consistent place to read context from at the start and write state to at the end.

Plain markdown plus three slash commands. No daemon, no database, no MCP server.

## What it gives every project

- **A standard file set.** `CLAUDE.md` (per-session entry point with a derived Recent Work rollup), `Backlog.md` (work items with status/type tags + P-numbers), `docs/feature-map.md` (shipped + roadmap), `docs/agent-memory.md` narrative + `docs/agent-memory/decisions/` and `/gotchas/` directories (one file per entry for conflict-free parallel appends), `docs/recent-work/` per-session entry files, `docs/build-plans/phase-N.md` (scope, architecture, batch log), per-agent `project_resume_<agent-id>.md` snapshots.
- **A session workflow.** `/restart-sop` reads the standard files and cross-checks against git. `/update-sop` runs the session-end checklist (Backlog, feature-map, agent-memory narrative + decisions/gotchas directories, batch log, resume snapshot, recent-work entry, rollup refresh, commit) with partitioned commit-range reconciliation via `git merge-base`. `/update-agent-sop` syncs upstream SOP changes into your project via three-way diff. `/migrate-to-multi-agent` is a one-shot for projects moving from legacy narrative sections to the Phase 1 directory structure.
- **Parallel multi-agent support.** 3-5 Claude Code terminal instances can run on separate git worktrees, each executing `/update-sop` independently without manual conflict resolution. Agent-id resolution (env var > `.sop-agent-id` file > `solo` default > 6-char hash of worktree path) keys per-agent resume files and per-entry filenames. See [`docs/guides/multi-agent-parallel-sessions.md`](docs/guides/multi-agent-parallel-sessions.md).
- **Six non-negotiable rules** in Section 0 of the core SOP — never delete without a trace; one source of truth; state facts not opinions; back-and-forth before plans; instruction budget ≤150/200; surface interpretations before acting.
- **Five reference agents** — `sop-checker` (compliance audit), `code-reviewer`, `security-reviewer`, `planner`, `e2e-runner`.
- **A compliance checker** that scores any project 0-100 across 84 checks for code projects (75 for non-code), three-tier weighted scoring with a critical-failure cap, including M1-M5 checks for multi-agent parallel-session readiness.
- **Templates** for every standard file, plus a setup script that installs them into a target project.
- **A/B benchmark framework** with 8 task specs, blind scoring, runner script, and three rounds of recorded results.

## Quick start

```bash
git clone https://github.com/mmjclayton/agent-sop ~/Projects/agent-sop
cd ~/Projects/agent-sop

# For docs / markdown / script projects
./setup.sh /path/to/your/project

# For full-stack code projects (web apps, APIs, CLIs)
./setup.sh /path/to/your/project --code
```

This installs the SOP files into your project, the three slash commands into `~/.claude/commands/`, and five reference agents into `~/.claude/agents/`. Existing files are not overwritten unless you pass `--force`.

Open the new files, replace `[bracket placeholders]` with your project content, then validate:

```
@sop-checker check SOP compliance for /path/to/your/project
```

Every session from then on starts with `/restart-sop` and ends with `/update-sop`.

## Six non-negotiable rules

These cannot be overridden by project-specific configuration. Each is tagged with the failure mode it prevents.

1. **Never delete without a trace. Never add without reason.** Every changed line traces to the user's request — no drive-by refactors, no speculative abstractions.
2. **One source of truth.** Each fact lives in exactly one file. Conflicts resolve by precedence: code/git → CLAUDE.md → Backlog.md → build plan → feature map → agent memory → resume point.
3. **No opinion. State facts.** Respond with evidence — what the code does, what the docs say, what git shows. Offer an opinion only when asked.
4. **Work back and forth before writing any plan.** Surface open questions and a rough outline first. Wait for the user's response.
5. **Instruction budget: ≤150 soft cap, 200 hard ceiling.** Trim before adding.
6. **Surface interpretations before acting.** When a request has multiple valid interpretations, list them, name the default, and ask. Don't pick silently.

Full text with extended commentary: [`docs/sop/claude-agent-sop.md`](docs/sop/claude-agent-sop.md) (Section 0).

## Backlog discipline

`Backlog.md` is the single source of truth for work items. Every item is tagged with status (first) and type (second), in that order:

- **Status:** `[OPEN]` `[IN PROGRESS]` `[BLOCKED]` `[DEFERRED]` `[SHIPPED - YYYY-MM-DD]` `[VERIFIED - YYYY-MM-DD]` `[WON'T - Reason: ...]`
- **Type:** `[Feature]` `[Iteration]` `[Bug]` `[Refactor]`
- **Optional:** `[has-open-questions]` `[ok-for-automation]`

`[BLOCKED]` means waiting on external action; `[DEFERRED]` means intentionally postponed with no blocker. The distinction prevents stale `[OPEN]` items that were consciously pushed back.

Items get a sequential `P` number. Shipped items move to a Recently Shipped section but are never removed from the file.

Build plans (`docs/build-plans/phase-N.md`) define the scope, architecture, key locked-in decisions, and an append-only batch log. Status lives only in Backlog — never in build plans — so the two cannot drift.

## Cross-session memory

`docs/agent-memory.md` holds the narrative: In-Flight Work (per-agent), Completed Work, Preferences, Archived. Decisions and gotchas live as one file per entry in `docs/agent-memory/decisions/` and `docs/agent-memory/gotchas/` with filenames `YYYY-MM-DD_<agent-id>_<slug>.md`. Per-entry files eliminate the merge-conflict surface when multiple agents end sessions in the same window — each agent writes a distinct file.

`docs/recent-work/` holds one file per session summary. The `## Recent Work (rollup)` section of `CLAUDE.md` is auto-generated from this directory via `/update-sop` Step 8b — derived, idempotent, regenerates deterministically.

`project_resume_<agent-id>.md` is a point-in-time snapshot per agent — overwritten each session, not appended to. Records what was done, what is next, any blockers. Lives in machine-local memory (`~/.claude/projects/[project-hash]/memory/`), not in the repo. Single-agent projects use id `solo`.

`docs/feature-map.md` lists shipped documents and the roadmap. Updated together with Backlog whenever an item ships.

## Parallel multi-agent sessions

Three to five Claude Code terminal instances can run on separate git worktrees of the same repo, each running `/update-sop` and `/restart-sop` independently. Tracking-file conflicts are prevented structurally — no human-in-the-loop co-ordination required:

- **Per-entry directory filenames** include the agent-id, so two agents writing on the same date produce distinct files that merge cleanly.
- **Commit-range partitioning** via `git merge-base <default-branch> HEAD..HEAD` scopes secondary-tracker reconciliation, drift guards, and hard-block checks to each agent's own branch.
- **P-number collision detection** in `/update-sop` Step 2a catches overlaps between an agent's branch and the default branch; a `renumber_p` shell helper updates all references.
- **Idempotent rollup** in `CLAUDE.md` derives from `docs/recent-work/`; any agent regenerating from identical directory contents produces identical output, so merge order does not matter.

Agent identity resolves as: `CLAUDE_AGENT_ID` env var > `.sop-agent-id` file at worktree root > literal `solo` for single-worktree projects > 6-char hash of worktree path.

Projects on the legacy narrative format migrate with `python3 scripts/migrate-to-multi-agent.py` (supports `--dry-run`). See [`docs/guides/multi-agent-parallel-sessions.md`](docs/guides/multi-agent-parallel-sessions.md) for full mechanics and [`docs/benchmark/parallel-dogfood-playbook.md`](docs/benchmark/parallel-dogfood-playbook.md) for the 3-worktree validation protocol.

## Keeping the SOP in sync

Run `/update-agent-sop` from any project to pull upstream changes without losing local edits. The command does a three-way diff per file (upstream vs your copy vs the recorded baseline SHA stored in `~/.claude/agent-sop.config.json`). Files you haven't modified update automatically; files you have modified surface for reconciliation. No silent overwrites.

`/restart-sop` warns when your last sync is over a week old (configurable via `update_reminder` in the config: `"weekly"`, `"manual"`, or `"off"`).

## Benchmarks

The SOP has been A/B tested against a baseline (no SOP context) using blind-scored agent pairs on identical tasks against a real production codebase (hst-tracker, ~15K lines, 7 models, 486 tests).

| Round | Date | Conditions | Result |
|-------|------|-----------|--------|
| R1 | 2026-04-09 | Precise prompts, Opus 4.6, fresh CLI sessions | SOP +8% (68/72 vs 62/72) |
| R2 | 2026-04-09 | Vague prompts, Opus 4.6, fresh CLI sessions | SOP +33% (78/84 vs 50/84) |
| R5 | 2026-04-17 | Vague prompts, Opus 4.7, subagent methodology, post-P32-P36 trim | SOP +16% directional (75/84 vs 61/84) |

R5 is methodologically weaker than R1-R2 (subagents not fresh CLI; Opus 4.7 baseline more capable than R2's 4.6; single round). A full R6 on the post-P40 SOP, fresh CLI sessions, model matched to R2, is open work.

The single-task scores measure code quality on individual tasks. The SOP also produces durable artefacts that compound across sessions; `hst-tracker` today has 86 dated decisions, 23 build-plan batch entries, 18 Recent Work entries, 64 docs-only commits, and 4,628 lines across the four tracking files. Equivalent counts in a no-SOP project are zero.

Full methodology, task specs, scoring rubric, and recorded results: [`docs/benchmark/`](docs/benchmark/).

## Token efficiency

Session start reads ~6,400 raw tokens (~10,900 with Claude Code's 1.7× file-read overhead) on a mature project — about 1.1% of a 1M context window or 5.5% of a 200k window. The full library of 27 files totals ~38-49K tokens; the session start checklist reads about 8% of that. The remaining 92% is accessed on demand through the dispatch table and line-range hints.

After the first turn, Anthropic's prompt caching applies a 90% discount on cache hits, reducing recurring per-turn cost of loaded files to ~1,000 effective tokens.

## Status

Active. Core SOP, templates, slash commands, compliance checker, reference agents, and cross-project sync mechanism are all shipped.

Recent work:
- **P43 (2026-04-19) — Parallel multi-agent sessions** — `[IN PROGRESS]`. Directory-per-entry structure, commit-range partitioning, P-number collision detection, migration tooling. Six of seven batches shipped; Batch 1.7 dogfood on hst-tracker with three parallel sessions pending.
- **P42 (2026-04-19)** — secondary-tracker reconciliation in `/update-sop` + `[DEFERRED]` status tag.
- **P32-P40 (2026-04-17)** — six non-negotiable rules in Section 0 (was two), core SOP trimmed ~230 → ~178 instructions, `/update-agent-sop` sync mechanism shipped, R5 post-trim benchmark pilot, measurement gap closed (session-hygiene rubric, continuity methodology, longitudinal exhibit).

Open work: P24 multi-agent optimisation guide, P8-P10 domain variants (web app, marketing, data/analytics), per-project `exclude` config field, R6 full benchmark. Roadmap and full work history: [`Backlog.md`](Backlog.md).

## Requirements

Claude Code **v2.1.101 or later**. Earlier versions have a long-session memory leak, permission rule bypasses, and `--resume` chain recovery bugs that affect SOP workflows. Check with `claude --version`.

## License

MIT. See [`LICENSE`](LICENSE).
