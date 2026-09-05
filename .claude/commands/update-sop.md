---
description: Session end for an Agent SOP project. Tests, one review run, Backlog tags, the validators, memory entries, the resume snapshot and session record, then commit.
sop_version: "2026-09-05"
---

Deliberate session close. The Stop hook enforces the minimum on code projects (a session record, clean trackers, a covering gate report); this command is the full close and the only close on non-code projects. Never delete without a trace: update in place, mark superseded, or archive.

## Gate: is this an Agent SOP project?

```bash
root=$(git rev-parse --show-toplevel 2>/dev/null) || root=$PWD
LIB="$HOME/.claude/scripts/hooks/agent-sop/sop-lib.sh"
if [ -f "$LIB" ]; then . "$LIB"; is_sop() { sop_is_sop_repo "$1"; }
else is_sop() { [ "$1" != "$HOME" ] && [ -f "$1/Backlog.md" ] && [ -f "$1/docs/sop/claude-agent-sop.md" ]; }; fi
is_sop "$root" || { echo "not-sop-project"; [ -f "$root/.claude/commands/update-sop.md" ] && echo "project-override: $root/.claude/commands/update-sop.md"; }
```

`not-sop-project`: run nothing below, create no `Backlog.md`, install nothing. With a `project-override` path, read that file and follow it instead. Otherwise say so in one line and stop.

## Step 0: Identity, range, outstanding subagents

```bash
AGENT_ID=$(bash scripts/resolve-resume-path.sh --agent-id)          # solo, or the worktree id
SESSION_RANGE=$( . "$HOME/.claude/scripts/hooks/agent-sop/sop-lib.sh" 2>/dev/null; b=$(sop_range_base "$(pwd)"); [ -n "$b" ] && printf '%s..HEAD' "$b" )
```

`SESSION_RANGE` is empty on the default branch with no diverging commits; steps that partition by range are no-ops then. Collect or terminate every subagent this session spawned before Step 1; a close taken while one is still running omits its result.

## Step 1: Tests (code projects)

Code project by the shared rule: the context block header, or `bash ~/.claude/scripts/hooks/agent-sop/sop-project-type.sh`. Run the full suite. Continuing with a red suite requires all three: the failure filed as a `[Bug]` this session, named in the resume snapshot's Blockers, and nothing tagged `[Feature]` or `[Refactor]` shipping. Otherwise the suite is the gate (P70: the exit is declared, never self-judged). Non-code: skip.

## Step 2: Review (one run serves the ship gate and this step)

For each item shipping this session as `[Feature]` or `[Refactor]`, a reviewer turn fires on any trigger:

- a. diff over threshold: `review_loc_threshold` (default 50) or `review_files_threshold` (default 3) in `~/.claude/agent-sop.config.json`, counted over `SESSION_RANGE` with `git diff --numstat`;
- b. SOP self-modification: any change under `docs/sop/`, `docs/guides/sop-*`, `.claude/agents/`, `.claude/commands/`, `scripts/validate-*` fires the turn for every item shipping, whatever its tag or size;
- c. a path listed in `agent-sop.config.json#review_triggers[]`, or a security path (`auth`, `login`, `session`, `token`, `password`, `credential`, `jwt`, `oauth`, `crypto`, `encrypt`, `signing`, `csrf`, `cors`, `xss`, `payment`, `billing`, `stripe`, `webhook`, `sanitize`, `escape_`, `raw_query`, matched against changed paths) which also routes to `security-reviewer`.

On a code project with ship-sop `trigger.mode: "auto"`, the gate run the Stop hook demands **is** this turn: launch the config's enabled agents with `isolation: "worktree"`, read-only, wait for every result, write `docs/reviews/<YYYYMMDD-HHMMSS>-ship-auto.md` with `Covers: <sha>` after any fix commit. Otherwise launch `code-reviewer` (or `security-reviewer` for trigger c) the same way and write `docs/reviews/YYYY-MM-DD_<agent-id>_P<n>.md` from the review template. Either way the session writes the artefact; agents return findings inline.

Then, on the Backlog entry, one line under the status line:

```
review: docs/reviews/<file>.md            # the path must exist
review skipped (P<n>): <docs-only|test-only|dep-bump|below-threshold>
```

The skip must name its own P-number and use that enumerated set. Under trigger b only `test-only` and `dep-bump` are accepted. Assert substance:

```bash
bash scripts/validate-state-transitions.sh --assert-review docs/reviews/<file>.md || exit 1
```

A not-yet-written artefact and a never-run review look identical to the assertion; wait for the reviewer, do not write the file by hand.

## Step 3: Backlog

Update status tags in place; add new items with acceptance criteria; never remove an entry. `[WON'T]` carries a `Reason:`; `[DEFERRED]` carries `**Reopens when:**`. Then:

```bash
bash scripts/refresh-priorities.sh          # rewrites CLAUDE.md priority block from Backlog tags where the sentinels exist
```

## Step 4: Validators

```bash
bash scripts/detect-trackers.sh             # secondary trackers (heading-level status tags); reconcile IDs named in SESSION_RANGE commits, [OPEN] -> [SHIPPED - date]
bash scripts/validate-state-transitions.sh || exit 1                       # legal tag transitions; shipped Feature/Refactor cites a review or a skip
bash scripts/validate-state-transitions.sh --check-drift || exit 1        # commits reference a P-number the resume declared, or a `## Scope Change` block says why not
bash scripts/validate-state-transitions.sh --check-replication || exit 1  # pristine-replica files changed this session reached the installed copy
```

Drift resolution: add `## Scope Change` to the resume snapshot with the actual P-number and one line of reason, or fix the commit references. Replication resolution: run `/update-agent-sop`, or record `replication deferred (P<n>): <reason>` on the Backlog entry.

## Step 5: Memory

Substance gate first: a decision is "we chose X over Y because Z"; a gotcha is the surprise, the prior expectation, and the rule that prevents a repeat. If a slot is empty, it goes in the session record, not a file.

Write `docs/agent-memory/decisions/YYYY-MM-DD_<agent-id>_<slug>.md` and `docs/agent-memory/gotchas/...` (title, `**Date:**`, `**Agent:**`, body; slug kebab-case, no underscores). Superseded entries get a trailing `*Superseded by:*` line, never deletion. Then:

```bash
bash scripts/refresh-in-flight.sh           # regenerates the In-Flight block of docs/agent-memory.md from docs/agent-memory/in-flight/
```

Remove this session's line from `docs/agent-memory/in-flight/<agent-id>.md` if the work is done; leave it if it carries over.

## Step 6: Resume snapshot and session record

```bash
RESUME=$(bash scripts/resolve-resume-path.sh)    # write target; never hand-construct
```

Overwrite `$RESUME` with: title, `Last updated:`, `## What was done` (commits or PRs), `## What is next` (file, function or P-number), `## Blockers`. Snapshot, not log. If an unsuffixed `project_resume.md` sits beside it, its first line becomes `**SUPERSEDED - YYYY-MM-DD.**`.

Write `docs/recent-work/YYYY-MM-DD_<agent-id>_<slug>.md`: title, `**Date:**`, `**Agent:**`, `**Commits:**`, and two to four lines on what shipped with P-numbers. Its title is what the rollup and the context block show; keep it short. Then:

```bash
bash scripts/refresh-rollup.sh              # docs/RECENT-WORK.md
```

## Step 7: Commit

```bash
git add Backlog.md docs/ && git commit -m "docs: session end housekeeping — <what shipped>"
```

Name the files; never `git add -A` after a review. Report in one paragraph: what shipped, which validators ran, what remains.
