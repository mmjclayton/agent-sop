# Agent SOP

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-v2.1.101+-orange.svg)](https://code.claude.com/docs/en/changelog)
![Status](https://img.shields.io/badge/status-active-success.svg)

Standard operating procedures and product-management discipline for Claude Code sessions. A defined file set, six non-negotiable rules, session start/end checklists, a Backlog with status tags and P-numbers, build plans with phases and batch logs, and a feature map — together they give every session a consistent place to read context from at the start and write state to at the end.

Plain markdown plus four slash commands. No daemon, no database, no MCP server, no background process.

## Why this exists

Claude Code sessions are stateful in principle and stateless in practice. Each new session starts with no memory of what the last one shipped, what decisions are locked in, what gotchas a previous agent learned the hard way. If that context isn't written down in files the next agent will read, it evaporates.

The usual answers are either too heavy (databases, daemons, MCP servers with background capture) or too light (ad-hoc notes scattered across `docs/` that agents may or may not find). Agent SOP is the disciplined middle: a fixed file set, a fixed session workflow, and a fixed tag taxonomy — no tooling that isn't already in git and the shell. The same file set supports a single agent working solo or three to five agents running concurrently on separate git worktrees of the same repo.

The compounding benefit across sessions — durable decisions, gotchas, batch logs that the next session can read — is the thing Agent SOP is designed to deliver. A 15k-line full-stack production codebase running the SOP for ~2 weeks has accumulated 125 dated decisions, 26 build-plan batch entries, and 20 rollup session entries. Equivalent counts in a no-SOP project of the same age: zero.

Single-task A/B benchmarks in [`docs/benchmark/`](docs/benchmark/) also show a +8-33% quality uplift, but they measure per-task code quality, not the cross-session durability this library is actually for.

## What it gives every project

- **A standard file set.** `CLAUDE.md` (per-session entry point with a derived Recent Work rollup), `Backlog.md` (work items with status/type tags + P-numbers), `docs/feature-map.md` (shipped + roadmap), `docs/agent-memory.md` narrative + `docs/agent-memory/decisions/` and `/gotchas/` directories (one file per entry), `docs/recent-work/` per-session entry files, `docs/build-plans/phase-N.md` (scope, architecture, batch log), per-agent `project_resume_<agent-id>.md` snapshots.
- **A session workflow.** `/restart-sop` reads the standard files and cross-checks against git. `/update-sop` runs the session-end checklist (tests, Backlog, feature-map, agent-memory narrative + decisions/gotchas directories, batch log, resume snapshot, recent-work entry, rollup refresh, commit) with commit-range reconciliation via `git merge-base`. `/update-agent-sop` syncs upstream SOP changes into your project via three-way diff. `/migrate-to-multi-agent` is a one-shot for projects moving from legacy narrative sections to the Phase 1 directory structure.
- **Machine-checkable enforcement gates.** Three hard-blocks at `/update-sop` keep the SOP enforced, not just documented. Step 1b requires a substantive reviewer-agent findings artifact at `docs/reviews/` for `[Feature]`/`[Refactor]` ships over threshold (diff count, not prose). Step 3c runs `scripts/validate-state-transitions.sh` against the Backlog diff and rejects illegal status-tag transitions (`<absent>` → `[SHIPPED]`, terminal revivals, `[SHIPPED]` without a Batch Log reference). Step 3d detects session drift by comparing P-numbers in commit messages against the declared in-flight item in `project_resume_<agent-id>.md`; `## Scope Change` in the resume is the explicit-redirect escape hatch. All three are agent-to-agent — no human approval gate. Thresholds configurable in `agent-sop.config.json`.
- **Parallel multi-agent support.** Run three to five Claude Code instances concurrently on the same codebase. Each session works in its own git worktree, runs `/update-sop` independently, and merges to main sequentially without tripping over the other agents' tracking-file changes. Agent-id resolution (`CLAUDE_AGENT_ID` env var > `.sop-agent-id` file > `solo` default > 6-char hash of worktree path) keys per-agent resume files and per-entry filenames. See [`docs/guides/multi-agent-parallel-sessions.md`](docs/guides/multi-agent-parallel-sessions.md).
- **Six non-negotiable rules** in Section 0 of the core SOP — never delete without a trace; one source of truth; state facts not opinions; back-and-forth before plans; instruction budget ≤150/200; surface interpretations before acting.
- **Five reference agents** — `sop-checker` (compliance audit), `code-reviewer`, `security-reviewer`, `planner`, `e2e-runner`.
- **A compliance checker** that scores any project 0-100 across 87 checks for code projects (78 for non-code), three-tier weighted scoring with a critical-failure cap, including M1-M5 checks for multi-agent parallel-session readiness and B11/R1/D1 for the enforcement gates.
- **Templates** for every standard file, plus `setup.sh` that installs them into a target project.
- **A/B benchmark framework** with eight task specs, blind scoring, runner script, and three rounds of recorded results.
- **Low session-start cost.** Typical read on a mature project stays well under 2% of a 1M context window. Measure per project via Claude Code's context usage indicator.

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

## Using the slash commands

Four slash commands cover the full session lifecycle. They install to `~/.claude/commands/` on setup and work in any project with the SOP files.

### `/restart-sop` — at the start of every session

Run this as the first thing in every new Claude Code session. It takes no arguments.

```
/restart-sop
```

The command reads the standard context files in order (`CLAUDE.md`, the local memory index and per-agent resume file, `docs/agent-memory.md` plus recent entries under `docs/agent-memory/decisions/` and `docs/agent-memory/gotchas/`, the current build plan), runs `git log --oneline -10`, and cross-checks that memory agrees with git state. It reads the Backlog item(s) flagged as current priority and reports:

- What the current priority is and what you're ready to work on
- Whether the previous session ended cleanly or was interrupted
- Any inconsistencies between files that need reconciling
- Which Definition of Done rubric applies to this task type

Typical runtime: ~30 seconds. A lightweight variant kicks in automatically when the task is tagged `[ok-for-automation]` and reads fewer files.

### `/update-sop` — at the end of every session

Run this before closing every session. It takes no arguments.

```
/update-sop
```

Runs the 9-step session-end checklist:

1. Self-evaluate the work against the Definition of Done rubric for the task type (bug fix, feature, refactor, test writing)
2. Run the full test suite (code projects only)
3. Update `Backlog.md` status tags — Step 2a hard-blocks if a P-number collides with one already on the default branch
4. Reconcile any project-specific secondary trackers (audit findings, security scans, compliance lists) against this session's commits, partitioned per-agent via `git merge-base`
5. Update `docs/feature-map.md` with shipped items
6. Write any new decisions to `docs/agent-memory/decisions/` and new gotchas to `docs/agent-memory/gotchas/` as individual files; update the narrative sections of `docs/agent-memory.md` by your agent-id
7. Append to the current build plan's Batch Log
8. Overwrite `project_resume_<agent-id>.md` with a fresh snapshot
9. Write the session summary to `docs/recent-work/YYYY-MM-DD_<agent-id>_<slug>.md`, refresh the Recent Work rollup in `CLAUDE.md` via `bash scripts/refresh-rollup.sh`
10. Commit the docs changes together with the feature work

On a parallel multi-agent worktree, each agent's `/update-sop` only touches its own branch — the commit-range partitioning via `git merge-base` ensures agents don't step on each other's reconciliation.

### `/update-agent-sop` — periodically, when you want upstream SOP changes

Run this roughly weekly to pull improvements from the agent-sop repo into your project (and to update the slash commands installed at `~/.claude/`). It takes no arguments.

```
/update-agent-sop
```

Per file, it computes three SHAs — upstream, your local copy, the recorded baseline — and classifies the state:

| Classification | Action |
|----------------|--------|
| IN SYNC (consumer matches upstream) | No change |
| UPSTREAM CHANGED, LOCAL UNCHANGED | Copy upstream to consumer, refresh baseline SHA |
| LOCALLY MODIFIED, UPSTREAM UNCHANGED | No change — your local edits preserved |
| LOCALLY MODIFIED + UPSTREAM CHANGED | Surfaced for reconciliation; never force-overwrites |
| MISSING (first-run) | Copy upstream, record as baseline |

Config at `~/.claude/agent-sop.config.json` controls behaviour:

- `update_reminder`: `"weekly"` (default) / `"manual"` / `"off"` — `/restart-sop` prints a one-line staleness warning when `last_update_check` falls outside this cadence
- `local_path`: path to your local agent-sop checkout (preferred source, falls back to GitHub raw)
- `github`: `owner/repo` for the raw fallback
- `multi_agent`: `"auto"` (default) / `"on"` / `"off"` — controls whether parallel-session conventions apply (see [Parallel multi-agent sessions](#parallel-multi-agent-sessions))

The staleness reminder is non-blocking; it doesn't stop session start.

### `/migrate-to-multi-agent` — one-shot when upgrading a legacy project

Run this once when moving an existing project from the pre-Phase-1 narrative format (where Recent Work was a prepend section in `CLAUDE.md` and Decisions/Gotchas were bullet lists in `docs/agent-memory.md`) to the Phase 1 directory structure. Not needed for projects set up with `setup.sh` from 2026-04-19 onwards — those are already in the new format.

```bash
# Preview what would be extracted (no file writes)
python3 scripts/migrate-to-multi-agent.py --dry-run

# Do the extraction (requires clean working tree)
python3 scripts/migrate-to-multi-agent.py
```

After the script runs, manually remove the legacy narrative sections from `CLAUDE.md` and `docs/agent-memory.md` (the script leaves them for review), then run `/update-sop` to refresh the rollup and commit. Full mechanics in [`docs/guides/multi-agent-parallel-sessions.md`](docs/guides/multi-agent-parallel-sessions.md).

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

Run three to five Claude Code sessions concurrently on the same codebase. Each session works in its own git worktree on its own branch, runs `/update-sop` and `/restart-sop` independently, and merges to main sequentially — without tripping over the other agents' tracking-file changes. No human co-ordination required.

Four structural choices make this possible:

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

## Companion projects

[**ship-sop**](https://github.com/mmjclayton/ship-sop) — pre-merge quality gates (tests, security, compliance, diagrams + API catalog) that fire automatically on session-end via a SessionStop hook, or manually via `/ship`. Independent of Agent SOP but composes with it: ship-sop auto-files findings as `[OPEN][Bug][needs-triage]` Backlog entries using the Agent SOP tag taxonomy when both are installed. Different decision point (per-ship gate, not per-session discipline), separate install, separate release cycle.

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
