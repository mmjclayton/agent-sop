# Agent SOP

Portable project context and session coordination for Claude Code and Codex.
Help each session resume work and coordinate parallel tasks using plain-file
handoffs, worktree ownership claims and automated workflow checks. Project
instructions, work items, decisions and session records live in Markdown.

[MIT licensed](LICENSE). No database, background service or MCP server required.

## What it does

- Gives a project a consistent place for instructions, a backlog and session history.
- Provides commands to resume work, close a session and update the SOP files.
- Checks backlog transitions, review records and unfinished session housekeeping.
- Supplies hooks for context loading and, on code projects, session-end checks.
- Shares handoffs across local worktrees and detects conflicting task/file claims.
- Keeps session identity stable as worktrees are added or removed.
- Works with [ship-sop](https://github.com/mmjclayton/ship-sop) for code review gates.

Claude and Codex share the same project records. You can use either or install both.

## Quick start

You need Git, Bash, `jq`, and the agent runtime you want to use. Python 3 is needed
only for the optional memory migration tool.

Run setup against an existing project directory:

```bash
git clone https://github.com/mmjclayton/agent-sop.git

# Codex, for a project containing code
bash agent-sop/setup.sh /path/to/project --runtime codex --code

# Claude Code instead
bash agent-sop/setup.sh /path/to/project --runtime claude --code
```

Use `--runtime both` to install both integrations. Claude is the default when the
flag is omitted. Leave off `--code` for non-code projects; scripts and CLI tools
count as code.

Fill in the generated project instructions with your stack, commands and
conventions. Existing project instructions, backlog and memory are preserved.
`--force` replaces distributed SOP assets, so review local customizations before
using it. Add `--no-hooks` if you want to run the workflows manually.

Start a fresh session with the project as its working root. For Codex CLI:

```bash
codex -C /path/to/project
```

Asking an agent to run shell commands in a project directory does not change the
session's root. Hooks receiving your home directory will skip the project.

## Everyday use

Type these in your agent session:

| Task | Claude Code | Codex |
|---|---|---|
| Resume work and read relevant context | `/restart-sop` | `$restart-sop` |
| Close the session and update records | `/update-sop` | `$update-sop` |
| Update shared SOP files | `/update-agent-sop` | `$update-agent-sop` |
| Verify and close out a change | `/finish` | `$finish` |
| Migrate older memory layouts | `/migrate-to-multi-agent` | `$migrate-to-multi-agent` |

The daily pattern is simple: resume, work on a backlog item, then close the
session with tests, review evidence and an updated record of what comes next.

## Where things live

| Location | Purpose |
|---|---|
| `AGENTS.md` / `CLAUDE.md` | Project instructions for Codex / Claude |
| `Backlog.md` | Work items and their status |
| `docs/agent-memory/` | Decisions, gotchas and in-flight work |
| `docs/recent-work/` | Session records |
| `docs/RECENT-WORK.md` | Generated session index |
| `docs/reviews/` | Review evidence |
| `docs/sop/` | Shared process documentation |

Commands, skills and hooks install at user scope and can serve multiple projects.
Claude uses `~/.claude`; Codex uses `~/.codex` (or `CODEX_HOME`) and
`~/.agents/skills`. Both runtimes share resume snapshots under
`~/.claude/agent-sop/projects/<root-digest>/memory`. Always use
`scripts/resolve-resume-path.sh` to resolve the path; older storage requires
explicit migration as described below.

## Multiple agents and sessions

Use one writer per Git worktree. The restart workflow directs agents to inspect
and acquire local ownership claims before parallel editing. Claims detect a
second writer in the same worktree, duplicate tasks and overlapping file paths;
disjoint work can proceed in separate worktrees.

The context hook discovers handoffs from local worktrees and sends compact refresh
notices when HEAD, session presence or claims change. Presence expires after
30 minutes; ownership claims remain until explicitly released. One coordinating
session integrates shared backlog and rollup changes.

Claims are cooperative and local to linked worktrees. They do not coordinate
separate clones or machines, or prevent writes by an agent that ignores them.
See the [parallel-session guide](docs/guides/multi-agent-parallel-sessions.md)
for setup, ownership, handoffs and recovery.

## Automatic checks

When loaded and trusted by the runtime, the hooks:

- Load project context at session start or the first prompt.
- Request missing session records and tracker updates when a code session stops.
- Request a ship-sop review and block supported push/PR commands when its automatic
  review gate applies and the committed code lacks a validated review receipt.

Non-code projects use the manual session-close workflow. These are agent hooks,
not repository permissions: they do not govern pushes made in another terminal.

**Earlier Codex runtime verification:** a fresh-session test completed the automatic cycle:
production Stop continuation, all configured reviewers, a covering report and a
successful push to a local Git remote. See the [runtime test record](docs/reviews/2026-09-08_codex-auto-runtime.md).
That test predates the structured receipt contract. The
[hardening review and verification record](docs/reviews/20260908-hardening-ship-auto.md)
documents the subsequent receipt, migration and coordination checks, including
five simultaneous overlapping-claim races that each produced exactly one owner.
Start Codex in the project root; other installations still need working, trusted hooks.

See [Codex setup and runtime details](docs/sop/codex.md) for hook installation,
updates and removal. SOP updates preserve local edits and report conflicts for
reconciliation instead of silently replacing them.

## Contributing

See [project conventions](CLAUDE.md) and the [shared SOP](docs/sop/claude-agent-sop.md).
For script changes, run all fixture suites from this repository:

```bash
for suite in docs/benchmark/*-fixtures/run-tests.sh; do
  bash "$suite" || exit 1
done
```

Historical experiments are in [docs/benchmark](docs/benchmark/). Propose changes
through a pull request.

## Upgrade and diagnostics

Review coverage now requires a validated JSON receipt; Markdown-only reports are
history. Upgrade Agent SOP and ship-sop together. Executable instruction files
count as code for review invalidation, and invalid configured policy blocks
supported publication operations.

Resume storage uses a full root digest to avoid path-slug collisions. Inspect
`bash scripts/resolve-resume-path.sh --legacy-dir`, confirm the snapshots belong
to this repository, then run `--migrate-legacy`. Existing files are preserved.

Run `bash scripts/hooks/sop-doctor.sh --runtime codex --root /path/to/project`
from this checkout for configuration, installed-policy and reviewer diagnostics.
A local marker or registered hook is not proof of live runtime enforcement.
