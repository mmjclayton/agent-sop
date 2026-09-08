# Codex runtime adapter

SOP-Version: 2026-09-08

The process in `claude-agent-sop.md` is shared. Its historical filename remains
stable for existing consumers. In Codex use these runtime bindings:

| Shared process concept | Codex binding |
|---|---|
| Project instructions | `AGENTS.md`; a bridge can reference `CLAUDE.md` for shared conventions |
| `/restart-sop`, `/update-sop`, `/finish` | `$restart-sop`, `$update-sop`, `$finish` skills |
| `/ship`, `/ship-on`, `/ship-off`, `/release`, `/audit` | Corresponding skills from ship-sop |
| User configuration | `${CODEX_HOME:-$HOME/.codex}`; never `.Codex/settings.json` |
| User skills | `~/.agents/skills/<name>/SKILL.md` |
| Reviewer agents | `.codex/agents/*.toml`, installed user-scope |
| Hook registration | `hooks.json` beside the active Codex config |
| Agent identity override | `AGENT_SOP_AGENT_ID`; existing `CLAUDE_AGENT_ID` remains a fallback |

AGENTS.md is preferred for project-type detection. If it is just a bridge with
no declaration, CLAUDE.md supplies the declaration. On existing projects keep
the shared priority block in CLAUDE.md; on Codex-only projects put it in
AGENTS.md. Do not maintain duplicate priority blocks.

The repo's `scripts/resolve-resume-path.sh` remains the only resume path resolver.
Its legacy `.claude/projects/.../memory` storage is deliberately shared between
runtimes, including Codex-only installs. It is SOP data storage, not a dependency
on an installed Claude executable. Existing snapshots are not moved or renamed.

## Hooks

`setup.sh <project> --runtime codex` installs user-scope hooks, or use
`bash scripts/install-hooks.sh --runtime codex` directly. Claude remains the
default runtime; `--runtime both` installs both. Hooks need jq. Reload the session
after installation and complete Codex's hook trust review if it requests one.

`sop-codex-hook.sh` wraps context output in Codex additionalContext JSON and
passes blocking exit code 2 through for Stop and PreToolUse. Both runtimes call
the same policy functions in `sop-lib.sh`. Delivery markers are runtime-specific;
Backlog, records, reviews and resume snapshots are shared. The Bash matcher uses
Codex's canonical shell alias, including exec_command. Hooks enforce supported
local tool paths, not arbitrary external git clients.

Auto-mode has one authority: agent-sop's Stop/push checks read the project's
`ship-sop.config.json`. Do not install ship-sop's legacy directive hook in Codex.
Manual ship works without hooks; missing hooks must be reported as inactive,
not as successful automatic enforcement.

## Reviewer isolation

Claude's `isolation: "worktree"` is not a Codex tool argument. For Codex reviews,
create an independent clone in `mktemp -d`, check out the exact review commit,
and run a separate `codex exec --sandbox read-only` process there. Disable hooks
for these reviewer processes to avoid recursive SOP sessions. Pass the range and
reviewer instructions on stdin, return findings inline, and have the parent write
the report. The ship-sop `scripts/codex-review.sh` implements this boundary.
A path mentioned in a subagent prompt does not isolate a process. Do not use
same-workspace writable subagents as a substitute. Missing/failed reviews are
INCOMPLETE, never PASS. Independent read-only reviewer processes are part of the
ship workflow, not authority to change source, publish or message other people.

## Updates and removal

`$update-agent-sop` runs `scripts/sync-sop-files.sh --runtime codex` from the
configured upstream checkout. It shares the existing classifier: pristine older
files update, local edits remain for reconciliation. No blanket word replacement.
Project-authored AGENTS.md, CLAUDE.md, Backlog and memory are never reset by setup.

To remove the user integration run `bash scripts/install-codex.sh --uninstall`
and `bash scripts/install-hooks.sh --runtime codex --uninstall`. Shared project
documents, resume records and other runtime installations are preserved.
