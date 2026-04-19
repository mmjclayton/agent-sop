# Agent SOP

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-v2.1.101+-orange.svg)](https://code.claude.com/docs/en/changelog)
![Status](https://img.shields.io/badge/status-active-success.svg)

Standard operating procedures and product-management discipline for Claude Code sessions. A defined file set, six non-negotiable rules, session start/end checklists, a Backlog with status tags and P-numbers, build plans with phases and batch logs, and a feature map — together they give every session a consistent place to read context from at the start and write state to at the end.

Plain markdown plus four slash commands. No daemon, no database, no MCP server, no background process.

## Why this exists

Claude Code sessions are stateful in principle and stateless in practice. Each new session starts with no memory of what the last one shipped, what decisions are locked in, what gotchas a previous agent learned the hard way. If that context isn't written down in files the next agent will read, it evaporates.

The usual answers are either too heavy (databases, daemons, MCP servers with background capture) or too light (ad-hoc notes scattered across `docs/` that agents may or may not find). Agent SOP is the disciplined middle: a fixed file set, a fixed session workflow, and a fixed tag taxonomy — no tooling that isn't already in git and the shell.

Benchmark data shows SOP-context agents produce 8-33% higher task quality on identical tasks than bare-repo agents, with the gap widening on vague product-level prompts. The compounding benefit across sessions — durable decisions, gotchas, batch logs — is visible in long-running projects. A 15k-line full-stack production codebase running the SOP for ~2 weeks has accumulated 125 dated decisions, 26 build-plan batch entries, and 20 rollup session entries. Equivalent counts in a no-SOP project of the same age: zero.

## What it gives every project

- **A standard file set.** `CLAUDE.md` (per-session entry point with a derived Recent Work rollup), `Backlog.md` (work items with status/type tags + P-numbers), `docs/feature-map.md` (shipped + roadmap), `docs/agent-memory.md` narrative + `docs/agent-memory/decisions/` and `/gotchas/` directories (one file per entry), `docs/recent-work/` per-session entry files, `docs/build-plans/phase-N.md` (scope, architecture, batch log), per-agent `project_resume_<agent-id>.md` snapshots.
- **A session workflow.** `/restart-sop` reads the standard files and cross-checks against git. `/update-sop` runs the session-end checklist (tests, Backlog, feature-map, agent-memory narrative + decisions/gotchas directories, batch log, resume snapshot, recent-work entry, rollup refresh, commit) with commit-range reconciliation via `git merge-base`. `/update-agent-sop` syncs upstream SOP changes into your project via three-way diff. `/migrate-to-multi-agent` is a one-shot for projects moving from legacy narrative sections to the Phase 1 directory structure.
- **Parallel multi-agent support.** Three to five Claude Code terminal instances can run on separate git worktrees of one repo, each running `/update-sop` independently without manual conflict resolution. Agent-id resolution (`CLAUDE_AGENT_ID` env var > `.sop-agent-id` file > `solo` default > 6-char hash of worktree path) keys per-agent resume files and per-entry filenames. See [`docs/guides/multi-agent-parallel-sessions.md`](docs/guides/multi-agent-parallel-sessions.md).
- **Six non-negotiable rules** in Section 0 of the core SOP — never delete without a trace; one source of truth; state facts not opinions; back-and-forth before plans; instruction budget ≤150/200; surface interpretations before acting.
- **Five reference agents** — `sop-checker` (compliance audit), `code-reviewer`, `security-reviewer`, `planner`, `e2e-runner`.
- **A compliance checker** that scores any project 0-100 across 84 checks for code projects (75 for non-code), three-tier weighted scoring with a critical-failure cap, including M1-M5 checks for multi-agent parallel-session readiness.
- **Templates** for every standard file, plus `setup.sh` that installs them into a target project.
- **A/B benchmark framework** with eight task specs, blind scoring, runner script, and three rounds of recorded results.

## Quick start

```bash
git clone https://github.com/mmjclayton/agent-sop ~/Projects/agent-sop
cd ~/Projects/agent-sop

# For docs / markdown / script projects
./setup.sh /path/to/your/project

# For full-stack code projects (web apps, APIs, CLIs)
./setup.sh /path/to/your/project --code
```

This installs the SOP files into your project, the four slash commands into `~/.claude/commands/`, five reference agents into `~/.claude/agents/`, and the helper scripts (`scripts/migrate-to-multi-agent.py`, `scripts/refresh-rollup.sh`) into the project. Existing files are not overwritten unless you pass `--force`.

Open the new files, replace `[bracket placeholders]` with your project content, then validate:

```
@sop-checker check SOP compliance for /path/to/your/project
```

Every session from then on starts with `/restart-sop` and ends with `/update-sop`.

## Six non-negotiable rules

These cannot be overridden by project-specific configuration. Each is tagged with the failure mode it prevents.

1. **Never delete without a trace. Never add without reason.** Every changed line traces to the user's request — no drive-by refactors, no speculative abstractions.
2. **One source of truth.** Each fact lives in exactly one file. Conflicts resolve by precedence: code/git → `CLAUDE.md` → `Backlog.md` → build plan → feature map → agent memory → resume point.
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

Build plans (`docs/build-plans/phase-N.md`) define scope, architecture, key locked-in decisions, and an append-only batch log. Status lives only in Backlog — never in build plans — so the two cannot drift.

## Cross-session memory

`docs/agent-memory.md` holds the narrative: In-Flight Work (per-agent), Completed Work, Preferences, Archived. Decisions and gotchas live as one file per entry in `docs/agent-memory/decisions/` and `docs/agent-memory/gotchas/` with filenames `YYYY-MM-DD_<agent-id>_<slug>.md`. Per-entry files eliminate the merge-conflict surface when multiple agents end sessions in the same window — each agent writes a distinct file.

`docs/recent-work/` holds one file per session summary. The `## Recent Work (rollup)` section of `CLAUDE.md` is auto-generated from this directory via `/update-sop` Step 8b — derived, idempotent, regenerates deterministically.

`project_resume_<agent-id>.md` is a point-in-time snapshot per agent — overwritten each session, not appended to. Records what was done, what is next, any blockers. Lives in machine-local memory (`~/.claude/projects/[project-hash]/memory/`), not in the repo. Single-agent projects use id `solo`.

## Parallel multi-agent sessions

Three to five Claude Code terminal instances can run on separate git worktrees of one repo, each running `/update-sop` and `/restart-sop` independently. Tracking-file conflicts are prevented structurally — no human-in-the-loop co-ordination required:

- **Per-entry directory filenames** include the agent-id, so two agents writing on the same date produce distinct files that merge cleanly.
- **Commit-range partitioning** via `git merge-base <default-branch> HEAD..HEAD` scopes secondary-tracker reconciliation, drift guards, and hard-block checks to each agent's own branch.
- **P-number collision detection** in `/update-sop` Step 2a catches overlaps between an agent's branch and the default branch; the `renumber_p` helper in the guide updates all references.
- **Idempotent rollup** in `CLAUDE.md` derives from `docs/recent-work/` via `scripts/refresh-rollup.sh`. Post-merge regeneration produces canonical output regardless of merge order.

Dogfood-validated on 2026-04-19: three parallel subagents on sibling worktrees of a real production codebase shipped three mutually-exclusive tasks and merged sequentially to main. Two expected `CLAUDE.md` rollup conflicts resolved mechanically in under 30 seconds each via `git checkout --ours CLAUDE.md && bash scripts/refresh-rollup.sh`. 855/855 tests passed on merged main. Full log: [`docs/benchmark/parallel-dogfood-log.md`](docs/benchmark/parallel-dogfood-log.md).

Projects on the legacy narrative format migrate with `python3 scripts/migrate-to-multi-agent.py` (supports `--dry-run`).

## Keeping the SOP in sync

Run `/update-agent-sop` from any project to pull upstream changes without losing local edits. The command does a three-way diff per file (upstream vs your copy vs the recorded baseline SHA stored in `~/.claude/agent-sop.config.json`). Files you haven't modified update automatically; files you have modified surface for reconciliation. No silent overwrites.

`/restart-sop` warns when your last sync is over a week old (configurable via `update_reminder` in the config: `"weekly"`, `"manual"`, or `"off"`).

## How this compares to other Claude Code tools

### vs [`thedotmack/claude-mem`](https://github.com/thedotmack/claude-mem)

Both target the "Claude Code has no memory across sessions" problem. They solve it at opposite ends of the spectrum and are **complementary, not competitive**.

| Dimension | Agent SOP | claude-mem |
|-----------|-----------|------------|
| Model | Prescription — tells agents what to do and write | Observation — captures what agents did |
| State | Plain markdown files committed to your repo | SQLite + ChromaDB + MCP server + daemon |
| Capture | Deliberate, human-authored, written during `/update-sop` | Automatic, passive, via SessionStart/SessionEnd/Stop hooks |
| Retrieval | Agent reads `docs/agent-memory.md` + decisions/gotchas directories during `/restart-sop` | Agent queries the memory store via MCP tool calls |
| Surface | 4 slash commands + 5 agents + 17 reference markdown files | Daemon process, React UI, MCP server, background indexing |
| Version control | Everything in `git` — diff, blame, revert as usual | Separate data store outside git |
| Onboarding | `./setup.sh /path/to/project` | Install plugin, run daemon, connect MCP |
| Dependency profile | `bash`, `awk`, `python3` (for migration), `git` | Node, SQLite, ChromaDB, MCP |

**When to use Agent SOP:** you want the discipline, ceremony, and explicit tracking encoded into your repo. Your team (or future you) will read the files directly. You want decisions in git history with `git blame`, not in a search index. You prefer prescription ("always run `/update-sop` before you end") over observation ("it recorded what happened").

**When to use claude-mem:** you want automatic capture of session content without writing it down yourself. You have a large corpus of session transcripts and want semantic search across them. You're OK with a daemon + database as part of your dev environment.

**When to use both together:** the Agent SOP's prescriptive file set is your canonical project state (decisions, backlog, build plan). claude-mem or an equivalent becomes an optional retrieval layer over conversation transcripts — useful for recalling "how did that debugging session actually go" without polluting the curated `docs/agent-memory/decisions/` store. Agent SOP even ports three patterns from claude-mem (progressive retrieval, capture-time redaction, fail-open hooks) — see `docs/guides/optional-patterns.md` for the integration notes.

### vs no tooling

The common alternative is free-form notes in `README.md` or `docs/`, updated when someone remembers. That works for solo projects until you try to come back after a month or hand off to another agent. The benchmark gap (+33% on vague prompts) is mostly this: agents with structured context don't waste tool calls reconstructing what was already decided.

## Token efficiency

Session start reads ~6,400 raw tokens (~10,900 with Claude Code's 1.7× file-read overhead) on a mature project — about 1.1% of a 1M context window or 5.5% of a 200k window. The full library totals ~38-49K tokens; the session start checklist reads about 8% of that. The remaining 92% is accessed on demand through the dispatch table and line-range hints.

After the first turn, Anthropic's prompt caching applies a 90% discount on cache hits, reducing recurring per-turn cost of loaded files to ~1,000 effective tokens.

## Requirements

Claude Code **v2.1.101 or later**. Earlier versions have a long-session memory leak, permission rule bypasses, and `--resume` chain recovery bugs that affect SOP workflows. Check with `claude --version`.

Other dependencies:
- `bash` (the helper scripts use `#!/usr/bin/env bash`; some of zsh's scoping rules break the refresh snippet, hence the explicit shebang)
- `python3` (only for `/migrate-to-multi-agent`; one-time per project)
- `git` (required for agent-id hashing and commit-range partitioning)

## License

MIT License. Copyright (c) 2026 Matt Clayton.

Use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of this software freely — commercial or personal, closed-source or open. The single condition is that the copyright notice and the MIT permission notice are included in all copies or substantial portions. No warranty of any kind, express or implied.

Full legal text: [`LICENSE`](LICENSE).
