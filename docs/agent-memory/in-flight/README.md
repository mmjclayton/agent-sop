# In-Flight Work — per-agent files

This directory holds one markdown file per active agent declaring that agent's mid-flight work. The `## In-Flight Work` section of `../agent-memory.md` is regenerated from these files by `scripts/refresh-in-flight.sh` (called from `/update-sop` Step 5).

## Why per-agent files

Earlier versions of the SOP kept the In-Flight section as flat lines in `agent-memory.md` with the rule "each agent edits only their own line." That works under solo workflow but offers no structural protection in parallel-agent mode — two agents editing adjacent lines, or two agents editing the same line in different worktrees, can produce git conflicts that force manual resolution.

Per-agent files (one per agent, named by agent-id) give each agent an isolated write target. Concurrent `/update-sop` runs in different worktrees write to different files. The `## In-Flight Work` section is then a derived view: regenerated from these files by an idempotent script, conflict-free on merge by construction (same model as `## Recent Work (rollup)`).

## File convention

```
docs/agent-memory/in-flight/<agent-id>.md
```

- One file per agent. Filename is the agent-id (e.g. `solo.md`, `reviewer.md`, `a7c3f2.md`).
- Contents: one bullet per in-flight item, no leading `- ` (the refresh script adds the dash and prepends the agent-id).
- Format per line: `(YYYY-MM-DD): short description`.
- Empty file means that agent has nothing in flight (treated identically to no file).

Example `solo.md`:

```
(2026-05-02): P49 timing measurement — sample 4 captured, write-up pending
(2026-05-01): P55 RN/native iOS-app technology decision write-up
```

After `bash scripts/refresh-in-flight.sh`, `agent-memory.md` shows:

```markdown
## In-Flight Work

<!-- in-flight:start -->
*Auto-generated from `docs/agent-memory/in-flight/`. Last refreshed: 2026-05-02.*

- solo (2026-05-02): P49 timing measurement — sample 4 captured, write-up pending
- solo (2026-05-01): P55 RN/native iOS-app technology decision write-up
<!-- in-flight:end -->
```

## Rules

- Each agent edits only its own file. Never edit another agent's file.
- When work completes, the agent removes the corresponding line(s) from its own file in the same `/update-sop` run that ships the work — and writes a `docs/agent-memory/<decisions|gotchas>/` entry or a `docs/recent-work/` entry if appropriate.
- Files are NEVER deleted, only emptied. An empty file is the canonical "this agent has nothing in flight" signal. (Some workflows will still want to `git rm` long-dormant agent files; that's allowed but not required.)

## Migration

Existing flat In-Flight Work lines in `agent-memory.md` migrate one-time to per-agent files:

```bash
mkdir -p docs/agent-memory/in-flight
# Inspect existing ## In-Flight Work section, then create one file per agent.
# Move each agent's lines into <agent-id>.md, preserving format.
# Replace the section body in agent-memory.md with the sentinel block:
#   <!-- in-flight:start -->
#   *(none)*
#   <!-- in-flight:end -->
# Run: bash scripts/refresh-in-flight.sh
```

`/migrate-to-multi-agent` will be extended to do this automatically in a future batch.
