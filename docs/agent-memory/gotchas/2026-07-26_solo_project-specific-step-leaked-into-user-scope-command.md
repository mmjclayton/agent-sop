# Gotcha — a project-specific step leaked into a user-scope pristine replica

**Date:** 2026-07-26
**Agent:** solo
**Surfaced by:** `/update-agent-sop` Step 2 diff report

## What happened

`~/.claude/commands/update-sop.md` was classified `LOCALLY MOD + UPSTREAM CHANGED`. The local modification turned out to be an 80-line **Step 3e: Doc-touch check (user-facing documentation)**, added at user scope on 2026-07-06 and never upstreamed to agent-sop.

The step is RepCanvas-specific. It reads `docs/user-doc-map.yml` and writes `.mdx` pages into the `repcanvas-marketing` repo.

## Why it matters

`~/.claude/commands/` is a **pristine-replica destination**. `/update-agent-sop` syncs it from agent-sop and will overwrite it. Any edit made directly there is invisible to version control and lives exactly one `/update-agent-sop` run away from deletion. This one survived only because the sync had not run in 20 days.

It also reached the wrong projects. Slash-command resolution prefers project scope, so:

| Project | Has `user-doc-map.yml` | Has project-scope `update-sop.md` | Effect |
|---------|------------------------|-----------------------------------|--------|
| hst-tracker | yes | yes (carries the check as **Step 5**) | uses its own copy; Step 3e never fires |
| ship-sop | no | no | inherits Step 3e from user scope and would look for a map file it does not have |
| agent-sop | no | yes | insulated |

So the only project that could act on it never saw it, and the project that saw it could not act on it.

## The trap that nearly caused a second error

An initial grep for the literal string `Step 3e` against hst-tracker's project-scope command returned zero, and that was briefly read as "hst-tracker is missing the check". It is not. **The same check lives there as Step 5** — the same map file, the same four sub-steps, the same CHANGELOG requirement. Grepping for a step *number* tests the numbering, not the behaviour. Grep for the distinctive dependency instead, here `user-doc-map.yml`, which finds it under any heading.

Acting on the wrong conclusion would have duplicated an existing step into hst-tracker on a branch off `main`, mid-feature-work, to fix a problem that did not exist.

## The one real difference, preserved here

The two copies diverge in how they resolve the session diff. The user-scope copy is the better of the two and is the version at risk of being lost:

```bash
# user-scope Step 3e — uses the SOP-standard mechanism from Step 0a
if [ -n "$SESSION_RANGE" ]; then
  git diff --name-only $SESSION_RANGE
fi
# Skip entirely when SESSION_RANGE is empty (on the default branch, no divergence).
```

```bash
# hst-tracker Step 5 — rolls its own, and degrades to a manual instruction
SESSION_BASE=$(git merge-base origin/main HEAD 2>/dev/null || git merge-base main HEAD)
git diff --name-only "$SESSION_BASE"...HEAD
# (If the session is on `main` directly, use the commits made in this session
#  via the agent-memory In-Flight or reflog.)
```

`SESSION_RANGE` is resolved once in Step 0a and partitions correctly for parallel agents. Step 5's local resolution duplicates that logic and falls back to "consult the reflog", which is not executable guidance. **Porting the `SESSION_RANGE` form into hst-tracker's Step 5 is a real improvement and is not done** — it belongs in hst-tracker's own Backlog, not agent-sop's.

## Rules

1. **Never edit a file in `~/.claude/commands/` or `~/.claude/agents/` directly.** Those are sync destinations. Edit upstream in agent-sop, or in the consuming project's own `.claude/`, then sync.
2. **Project-specific steps belong in project scope.** A step naming another repo by name is per-project by definition.
3. **When checking whether a step exists in a consumer, grep for its distinctive dependency, not its step number.** Numbering drifts between copies; behaviour does not.

## Source

`/update-agent-sop` Step 2 classification, 2026-07-26. Related: `docs/reviews/2026-07-26_solo_P67-P69.md`.
