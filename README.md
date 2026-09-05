# Agent SOP

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-v2.1.251+-orange.svg)](https://code.claude.com/docs/en/changelog)
![Status](https://img.shields.io/badge/status-active-success.svg)

Standard operating procedures and product-management discipline for Claude Code sessions. A defined file set, six non-negotiable rules, session start/end checklists, a Backlog with status tags and P-numbers, build plans with phases and batch logs, and a feature map — together they give every session a consistent place to read context from at the start and write state to at the end.

Plain markdown, five slash commands, and three user-scope hook scripts that run the mechanical parts without anything typed. No daemon, no database, no MCP server.

## Why this exists

Claude Code sessions are stateful in principle and stateless in practice. Each new session starts with no memory of what the last one shipped, what decisions are locked in, what gotchas a previous agent learned the hard way. If that context isn't written down in files the next agent will read, it evaporates.

The usual answers are either too heavy (databases, daemons, MCP servers with background capture) or too light (ad-hoc notes scattered across `docs/` that agents may or may not find). Agent SOP is the disciplined middle: a fixed file set, a fixed session workflow, and a fixed tag taxonomy — no tooling that isn't already in git and the shell. The same file set supports a single agent working solo or three to five agents running concurrently on separate git worktrees of the same repo.

The compounding benefit across sessions — durable decisions, gotchas, batch logs that the next session can read — is the thing Agent SOP is designed to deliver. A 15k-line full-stack production codebase running the SOP for ~2 weeks has accumulated 125 dated decisions, 26 build-plan batch entries, and 20 rollup session entries. Equivalent counts in a no-SOP project of the same age: zero.

Single-task A/B benchmarks in [`docs/benchmark/`](docs/benchmark/) also show a +8-33% quality uplift (k=1 per arm across rounds R1-R5, so treat it as directional — see the Limitations section there), but they measure per-task code quality, not the cross-session durability this library is actually for.

## What it gives every project

- **A standard file set.** `CLAUDE.md` (per-session entry point: project type, intent-based dispatch table, a derived priority block, Common Mistakes), `Backlog.md` (work items with status/type tags and P-numbers; closed items older than 90 days archived to `docs/backlog-archive.md`), `docs/agent-memory/decisions/` and `/gotchas/` (one file per entry), `docs/recent-work/` (one file per session, rolled up into `docs/RECENT-WORK.md`), `docs/reviews/` (review artefacts and gate reports), `docs/build-plans/` (planning notes), and a per-agent resume snapshot in machine-local memory.
- **A session workflow.** The context hook prints project state on the first prompt; `/restart-sop` lists the newest decisions and gotchas and reads the work item. `/update-sop` runs the seven-step close: tests, one review run, Backlog tags, the validators, memory entries, snapshot and session record, commit. Trimmed on 2026-09-05 (P105) from 669 to under 120 lines after a measured review found most of the old text duplicated the hooks or produced artefacts nothing read.
- **Machine-checkable enforcement gates.** A shipped `[Feature]`/`[Refactor]` must cite a substantive reviewer artefact on its Backlog entry (`review: docs/reviews/...`, path checked, substance asserted) or declare an enumerated skip; `scripts/validate-state-transitions.sh` enforces tag transitions, the citation, session drift against the resume snapshot, and replication of pristine files to the installed copy. On code projects the user-scope Stop hook and push gate enforce the minimum record and the ship-sop gate without a command being typed.
- **Parallel multi-agent support.** Run three to five Claude Code instances concurrently on the same codebase. Each session works in its own git worktree, runs `/update-sop` independently, and merges to main sequentially without tripping over the other agents' tracking-file changes. Agent-id resolution (`CLAUDE_AGENT_ID` env var > `.sop-agent-id` file > `solo` default > 6-char hash of worktree path) keys per-agent resume files and per-entry filenames. See [`docs/guides/multi-agent-parallel-sessions.md`](docs/guides/multi-agent-parallel-sessions.md).
- **Two rules** in Section 0 of the core SOP: never delete without a trace; one source of truth with a stated precedence. (Four further rules were moved to the user-scope rules or dropped on 2026-09-05; models keep them by default.)
- **Five reference agents** — `sop-checker` (compliance audit), `code-reviewer`, `security-reviewer`, `planner`, `e2e-runner`.
- **A compliance checker** that scores any project 0-100 across 79 checks for code projects (73 for non-code), three-tier weighted scoring with a critical-failure cap, including M1-M6 checks for multi-agent parallel-session readiness, S4-S7 for memory-poisoning, CI hardening, and gate integrity, B11/B12/R1/D1/T1 for the enforcement gates and their escape hatches.
- **Templates** for every standard file, plus `setup.sh` that installs them into a target project.
- **A/B benchmark framework** with eight task specs, blind scoring, runner script, and five rounds of recorded results.
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

This installs the SOP files into your project, the slash commands into `~/.claude/commands/` (`/restart-sop`, `/update-sop`, `/update-agent-sop`, `/migrate-to-multi-agent`, `/finish`), five reference agents into `~/.claude/agents/`, and the helper scripts (`scripts/migrate-to-multi-agent.py`, `scripts/refresh-rollup.sh`, `scripts/refresh-in-flight.sh`, `scripts/validate-state-transitions.sh`) into the project. It also registers three user-scope hooks in `~/.claude/settings.json` (see [Automatic mode via hooks](#automatic-mode-via-hooks); skip with `--no-hooks`). Existing files are not overwritten unless you pass `--force`.

Open the new files, replace `[bracket placeholders]` with your project content, then validate:

```
@sop-checker check SOP compliance for /path/to/your/project
```

Every session from then on starts with `/restart-sop` and ends with `/update-sop`.

## Using the slash commands

Five slash commands cover the full session lifecycle. They install to `~/.claude/commands/` on setup and work in any project with the SOP files.

### `/restart-sop` — at the start of every session

Run this as the first thing in every new Claude Code session. It takes no arguments.

```
/restart-sop
```

With the hooks installed the context block has already supplied project state; `/restart-sop` lists the ten newest decisions and gotchas, locates the Backlog item by grep and reads only its range, then reports in one paragraph. Without hooks it reads the resume snapshot and `git log --oneline -10` first.


### `/update-sop` — at the end of every session

Run this before closing every session. It takes no arguments.

```
/update-sop
```

Runs the seven-step close:

1. Tests (code projects); a red suite ships nothing tagged `[Feature]`/`[Refactor]` unless the failure is filed and named in the snapshot
2. Review: one reviewer run per shipping `[Feature]`/`[Refactor]` over threshold, on SOP-executed paths, or on security paths; on code projects under ship-sop auto-mode the gate run is that turn; the entry cites the artefact or a skip token
3. Backlog tags in place; `scripts/refresh-priorities.sh`
4. Validators: `scripts/detect-trackers.sh`, `scripts/validate-state-transitions.sh` (transitions and citations, `--check-drift`, `--check-replication`)
5. Decision and gotcha files that pass the substance gate; `scripts/refresh-in-flight.sh`
6. Resume snapshot at the resolver path; session record; `scripts/refresh-rollup.sh`
7. Commit `docs/` with the work

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

### Automatic mode via hooks

Three user-scope hook scripts make the mechanical half of the SOP run without a command being typed. A fourth, `sop-project-type.sh`, is not a hook but the one rule the others share for "is this a code project" (see below). `setup.sh` installs them; `bash scripts/install-hooks.sh` installs or refreshes them on their own, and `--uninstall` removes them. They live in `~/.claude/scripts/hooks/agent-sop/` and are registered in `~/.claude/settings.json`.

| Hook | Event | What it does |
|------|-------|--------------|
| `sop-session-context.sh` | `SessionStart`, `UserPromptSubmit` | Once per session and project, prints the resume snapshot and the three most recent sessions, and — only when the fact is not the default — in-flight lines, `[IN PROGRESS]` Backlog items, commits since the last session record, dirty trackers, an outstanding ship gate, dirty sibling worktrees, and a stale upstream sync. Replaces `/restart-sop` Steps 0-4. Reprints after `/compact` or `/clear`. |
| `sop-stop-drift.sh` | `Stop` | On a code project only: when the agent stops with commits that no `docs/recent-work/` entry covers, uncommitted tracker files, or a ship-sop auto-mode diff with code lines and no gate report, it exits 2 with exactly what is missing, and the agent does the minimum session-end (Backlog tag, session record, resume snapshot, commit) before finishing. Fires once per commit state, so it never loops. |
| `sop-push-gate.sh` | `PreToolUse` on `Bash` | Refuses `git push` and `gh pr create` (as a simple command, inside a `bash -c` / `sh -c` / `eval` wrapper, or in a command substitution; text inside quoted arguments is ignored) when the project is a code project, `ship-sop.config.json` has `trigger.mode: auto`, the code diff against the default branch is over `min_diff_lines`, and no `docs/reviews/*-ship-auto.md` names an ancestor of HEAD with no code change since. `SOP_SKIP_GATE=1 git push ...` bypasses once and is logged to `.ship/bypass.log`. |

**Code projects only.** ship-sop's automatic gate fires for coding and for nothing else (operator rule, 2026-09-04, P102): a prose repository carrying a config gets no gate demand and no refused push, and a documentation-only branch in a code repository gets none either — documentation extensions are always excluded from the line count. What counts as a code project is one rule for every consumer, `scripts/hooks/sop-project-type.sh`: an explicit `**Project type:** code|non-code` line in CLAUDE.md wins (both templates carry one), otherwise the heuristics in `docs/sop/compliance-checklist.md` § Code vs Non-Code Detection. The context block names the type in its header. The Stop hook is code-only as a whole (P103): a prose project with SOP scaffolding gets no notice, and `/update-sop` is its deliberate close. The context block still prints the drift facts there and says nothing is enforced. The global `/update-sop` and `/restart-sop` open with a gate of their own: outside the SOP file set they stop, or defer to the project's own `.claude/commands/` override when one exists.

They are user-scope on purpose. A project's own `.claude/settings.json` is only read from the directory Claude Code was launched in, so a session started in `~` that then changes into the project never loads project hooks. These resolve the repository from the hook's `cwd` input and stay silent anywhere that is not an SOP project (no `Backlog.md` plus `docs/sop/claude-agent-sop.md`).

Every fact the hooks act on is one a script can check: a commit range, a file's presence, a line in a report. Judgement stays with the agent and the full checklists. `/restart-sop` and `/update-sop` still work and remain the deliberate way to open and close a session; the hooks are what happens when nobody types them.

Fixture suite: `bash docs/benchmark/hook-fixtures/run-tests.sh`.

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

`docs/agent-memory.md` holds a pointer to CLAUDE.md's Key Documents, the Key Source Files for current work, project preferences, and the script-generated In-Flight block. Decisions and gotchas live as one file per entry in `docs/agent-memory/decisions/` and `docs/agent-memory/gotchas/`; a superseded entry gets a trailing `*Superseded by:*` line and moves to `archive/`. The Completed Work narrative was dropped on 2026-09-05: it duplicated the session records and nothing read it.

The In-Flight Work section is itself derived: each agent owns a file at `docs/agent-memory/in-flight/<agent-id>.md`, and the section in `agent-memory.md` is regenerated between sentinel markers by `bash scripts/refresh-in-flight.sh`. Two parallel agents only ever edit their own file, so the section converges on merge with no shared-line conflicts. See `docs/agent-memory/in-flight/README.md` for the file format.

`docs/recent-work/` holds one file per session summary; `docs/RECENT-WORK.md` is regenerated from it by `bash scripts/refresh-rollup.sh` at every `/update-sop`. The context hook shows the three newest titles; keep titles specific.

`project_resume_<agent-id>.md` is a point-in-time snapshot per agent — overwritten each session, not appended to. Records what was done, what is next, any blockers. Lives in machine-local memory, not in the repo. Single-agent projects use id `solo`.

The path is always resolved by `scripts/resolve-resume-path.sh`, never hand-written. The directory it returns is derived from the git repo root, so it is stable no matter where the session was launched. That matters because the harness names its memory directories after the session's launch path: a session started outside the project gets a catch-all directory shared with every other project touched the same way, where `solo` is not a unique name and one project's snapshot can land on another's.

## Parallel multi-agent sessions

Run three to five Claude Code sessions concurrently on the same codebase. Each session works in its own git worktree on its own branch, runs `/update-sop` and `/restart-sop` independently, and merges to main sequentially — without tripping over the other agents' tracking-file changes. No human co-ordination required.

Five structural choices make this possible:

- **Per-entry directory filenames** include the agent-id, so two agents writing on the same date produce distinct files that merge cleanly.
- **Commit-range partitioning** via `git merge-base <default-branch> HEAD..HEAD` scopes secondary-tracker reconciliation, drift guards, and hard-block checks to each agent's own branch.
- **P-number collisions** between an agent's branch and the default branch surface as a merge conflict in `Backlog.md`; the `renumber_p` helper in `docs/guides/multi-agent-parallel-sessions.md` Section 6 resolves them. (The per-session pre-check was removed on 2026-09-05; it never fired.)
- **Idempotent rollup** in `CLAUDE.md` derives from `docs/recent-work/` via `scripts/refresh-rollup.sh`. Post-merge regeneration produces canonical output regardless of merge order.
- **Per-agent in-flight files** at `docs/agent-memory/in-flight/<agent-id>.md` replace the legacy "edit your own line in agent-memory.md" pattern. The narrative section is regenerated by `scripts/refresh-in-flight.sh` from the per-agent files — same idempotence model as the rollup, no shared-line edits.

`/restart-sop` Step 0a also prints a soft advisory when more than one worktree is checked out and any sibling worktree has uncommitted changes — sibling branch operations can wipe uncommitted edits across the shared `.git` directory. See [`docs/guides/multi-agent-parallel-sessions.md`](docs/guides/multi-agent-parallel-sessions.md) §7 (Pre-flight) and §8 (Assumptions).

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
| Surface | 5 slash commands + 5 agents + 19 reference markdown files | Daemon process, React UI, MCP server, background indexing |
| Version control | Everything in `git` — diff, blame, revert as usual | Separate data store outside git |
| Onboarding | `./setup.sh /path/to/project` | Install plugin, run daemon, connect MCP |
| Dependency profile | `bash`, `awk`, `python3` (for migration), `git` | Node, SQLite, ChromaDB, MCP |

**When to use Agent SOP:** you want the discipline, ceremony, and explicit tracking encoded into your repo. Your team (or future you) will read the files directly. You want decisions in git history with `git blame`, not in a search index. You prefer prescription ("always run `/update-sop` before you end") over observation ("it recorded what happened").

**When to use claude-mem:** you want automatic capture of session content without writing it down yourself. You have a large corpus of session transcripts and want semantic search across them. You're OK with a daemon + database as part of your dev environment.

**When to use both together:** the Agent SOP's prescriptive file set is your canonical project state (decisions, backlog, build plan). claude-mem or an equivalent becomes an optional retrieval layer over conversation transcripts — useful for recalling "how did that debugging session actually go" without polluting the curated `docs/agent-memory/decisions/` store. Agent SOP even ports three patterns from claude-mem (progressive retrieval, capture-time redaction, fail-open hooks) — see `docs/guides/optional-patterns.md` for the integration notes.

### vs no tooling

The common alternative is free-form notes in `README.md` or `docs/`, updated when someone remembers. That works for solo projects until you try to come back after a month or hand off to another agent. The Round 2 benchmark gap (+33% on vague prompts, single-run — see the Limitations in `docs/benchmark/`) is mostly this: agents with structured context don't waste tool calls reconstructing what was already decided.

### vs AGENTS.md (the cross-tool standard)

[AGENTS.md](https://agents.md) — stewarded by the Agentic AI Foundation under the Linux Foundation — is a cross-vendor format for project-level agent instructions, read natively by Cursor, Codex, Gemini CLI, and others. It solves a different problem to Agent SOP: AGENTS.md standardises *where one file of context lives*; Agent SOP prescribes *a working discipline* — session checklists, enforcement gates, backlog and memory conventions — that happens to use CLAUDE.md as its entry point.

They compose rather than compete. If your project runs Claude Code only, CLAUDE.md as this SOP ships it is all you need. If non-Claude agents work the same repo, keep one source of truth (Rule 2): put the shared project context — architecture, conventions, build commands, hard constraints — in AGENTS.md, and reduce CLAUDE.md to an import plus the Claude-specific surface:

```markdown
# CLAUDE.md
@AGENTS.md

<!-- Claude-specific from here: SOP wiring, Key Documents & Dispatch,
     slash-command conventions, Current Priority Items -->
```

Do not maintain parallel copies — duplicated context drifts, and drift is exactly what Rule 2 exists to prevent. Agent SOP does not currently ship an AGENTS.md template or a `setup.sh` flag for this split; that support is deliberately deferred until Claude Code reads AGENTS.md natively, at which point the split becomes zero-cost and the tooling ships (tracked as P64 in the Backlog).

## Companion projects

[**ship-sop**](https://github.com/mmjclayton/ship-sop) — pre-merge quality gates (tests, security, compliance, diagrams + API catalog) run manually via `/ship`. Its automatic trigger now lives in Agent SOP: when a project carries `ship-sop.config.json` with `trigger.mode: auto`, the `sop-stop-drift.sh` Stop hook emits the gate demand and `sop-push-gate.sh` refuses a push until a report covers HEAD (see [Automatic mode via hooks](#automatic-mode-via-hooks)). ship-sop's own project-scope Stop hook is superseded. Findings still file as `[OPEN][Bug][needs-triage]` Backlog entries using the Agent SOP tag taxonomy. Different decision point (per-ship gate, not per-session discipline), separate install, separate release cycle.

## Requirements

Claude Code **v2.1.251 or later**. Check with `claude --version`. The floor moved from v2.1.101 on 2026-09-04 for three fixes the SOP's containment model depends on: 2.1.222 stopped worktree-isolated sessions and their subagents running destructive git commands against the main checkout (the parallel-session workflow ran on a broken isolation guarantee before it); 2.1.251 closed file tools following a symlink swapped after the permission check and Grep/Glob ignoring `Read(...)` deny rules through symlinked paths; 2.1.251 also delivers the `SessionStart` staleness fields the hooks read. The original v2.1.101 reasons (long-session memory leak, permission rule bypasses, `--resume` chain recovery) still apply below that version.

Other dependencies:
- `bash` (the helper scripts use `#!/usr/bin/env bash`; some of zsh's scoping rules break the refresh snippet, hence the explicit shebang)
- `python3` (only for `/migrate-to-multi-agent`; one-time per project)
- `git` (required for agent-id hashing and commit-range partitioning)

## License

MIT License. Copyright (c) 2026 Matt Clayton.

Use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of this software freely — commercial or personal, closed-source or open. The single condition is that the copyright notice and the MIT permission notice are included in all copies or substantial portions. No warranty of any kind, express or implied.

Full legal text: [`LICENSE`](LICENSE).
