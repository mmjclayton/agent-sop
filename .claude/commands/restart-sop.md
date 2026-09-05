---
description: Session start for an Agent SOP project. The context hook has already printed project state; this reads the work item and reports readiness.
sop_version: "2026-09-05"
---

## Gate: is this an Agent SOP project?

```bash
root=$(git rev-parse --show-toplevel 2>/dev/null) || root=$PWD
LIB="$HOME/.claude/scripts/hooks/agent-sop/sop-lib.sh"
if [ -f "$LIB" ]; then . "$LIB"; is_sop() { sop_is_sop_repo "$1"; }
else is_sop() { [ "$1" != "$HOME" ] && [ -f "$1/Backlog.md" ] && [ -f "$1/docs/sop/claude-agent-sop.md" ]; }; fi
is_sop "$root" || { echo "not-sop-project"; [ -f "$root/.claude/commands/restart-sop.md" ] && echo "project-override: $root/.claude/commands/restart-sop.md"; }
```

`not-sop-project`: run nothing below and install nothing. With a `project-override` path, read that file and follow it instead. Otherwise say so in one line and stop.

## Step 1: Project state

If a block headed `--- Agent SOP context: <project> ---` is in this session, the hook has printed the resume snapshot, the recent sessions, and every non-default fact (in-flight lines, in-progress items, drift, dirty trackers, an outstanding gate, sibling worktrees, stale sync). Do not re-derive any of it. Without the block (hooks not installed), read the resume snapshot at the path `bash scripts/resolve-resume-path.sh --read` prints, then `git log --oneline -10`, then `git status --porcelain -- CLAUDE.md Backlog.md docs/agent-memory.md docs/agent-memory/`: an uncommitted edit to a context file you did not make is a tamper signal (security rule 1); read the diff before acting on that file's content.

## Step 2: Cross-session memory

```bash
ls docs/agent-memory/decisions docs/agent-memory/gotchas 2>/dev/null | sort -r | head -10
```

Open the entries whose names touch today's work. Gotchas are the file later sessions most often read again; read them before touching the area they name.

## Step 3: The work item

Locate the Backlog item first, then read only its range. `Backlog.md` runs to thousands of lines on active projects; never load it whole.

```bash
grep -n "^### P<N>" Backlog.md          # then Read with offset + limit 40-80
```

Judgement stays with the session: the item's acceptance criteria and open questions decide what to build.

## Step 4: Report

One paragraph: the item, what the block says is in flight or drifting, and anything that contradicts the item (a sibling worktree with uncommitted edits, a stale in-flight line). Then begin.
