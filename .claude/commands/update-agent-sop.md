---
description: Sync pristine-replica Agent SOP files (SOP docs, guides, slash commands, reference agents) from the upstream agent-sop repo into this project and the user's ~/.claude directory. Three-way diff for locally modified files; never force-overwrites.
sop_version: "2026-04-19"
---

Keep Agent SOP artefacts up to date. Pulls the current pristine-replica files from upstream (local checkout if available, GitHub raw otherwise), diffs them against this project's copies, and applies updates only where safe. Locally modified files are surfaced for reconciliation rather than overwritten.

## Prerequisites

The config resolves in this order, first match wins:
1. `.claude/agent-sop.config.json` in the current project (per-project override)
2. `~/.claude/agent-sop.config.json` (user-global default)

If neither exists, create `~/.claude/agent-sop.config.json` with:
```json
{
  "local_path": "~/Projects/agent-sop",
  "github": "mmjclayton/agent-sop",
  "update_reminder": "weekly",
  "last_update_check": null,
  "baseline_shas": {}
}
```
Inform the user, then proceed with first-run bootstrap behaviour (see Step 4).

## Pristine-replica file set

These are the files this command keeps in sync. Everything else (CLAUDE.md, Backlog, agent-memory, feature-map, build-plans, templates) is per-project and is never touched.

| Destination in consumer project | Upstream path | Scope |
|---------------------------------|---------------|-------|
| `docs/sop/claude-agent-sop.md` | `docs/sop/claude-agent-sop.md` | project |
| `docs/sop/security.md` | `docs/sop/security.md` | project |
| `docs/sop/sandboxing.md` | `docs/sop/sandboxing.md` | project |
| `docs/sop/harness-configuration.md` | `docs/sop/harness-configuration.md` | project |
| `docs/sop/compliance-checklist.md` | `docs/sop/compliance-checklist.md` | project |
| `docs/guides/optional-patterns.md` | `docs/guides/optional-patterns.md` | project |
| `docs/guides/multi-agent-context-routing.md` | `docs/guides/multi-agent-context-routing.md` | project |
| `docs/guides/multi-agent-parallel-sessions.md` | `docs/guides/multi-agent-parallel-sessions.md` | project |
| `docs/guides/managed-agents-integration.md` | `docs/guides/managed-agents-integration.md` | project |
| `docs/guides/sop-hill-climbing.md` | `docs/guides/sop-hill-climbing.md` | project |
| `docs/guides/sop-common-mistakes.md` | `docs/guides/sop-common-mistakes.md` | project |
| `scripts/migrate-to-multi-agent.py` | `scripts/migrate-to-multi-agent.py` | project |
| `scripts/refresh-rollup.sh` | `scripts/refresh-rollup.sh` | project |
| `~/.claude/commands/restart-sop.md` | `.claude/commands/restart-sop.md` | user |
| `~/.claude/commands/update-sop.md` | `.claude/commands/update-sop.md` | user |
| `~/.claude/commands/update-agent-sop.md` | `.claude/commands/update-agent-sop.md` | user |
| `~/.claude/commands/migrate-to-multi-agent.md` | `.claude/commands/migrate-to-multi-agent.md` | user |
| `~/.claude/agents/sop-checker.md` | `.claude/agents/sop-checker.md` | user |
| `~/.claude/agents/code-reviewer.md` | `.claude/agents/code-reviewer.md` | user |
| `~/.claude/agents/security-reviewer.md` | `.claude/agents/security-reviewer.md` | user |
| `~/.claude/agents/planner.md` | `.claude/agents/planner.md` | user |
| `~/.claude/agents/e2e-runner.md` | `.claude/agents/e2e-runner.md` | user |

## Steps

### Step 1: Resolve source

Check the config's `local_path`. If the path exists and contains `docs/sop/claude-agent-sop.md`, treat it as the source. Otherwise fall back to GitHub raw at `https://raw.githubusercontent.com/{github}/main/{path}`.

Report which source is being used.

### Step 2: Build the diff report

For each file in the pristine-replica set:
1. Fetch upstream content (from local path or GitHub raw).
2. Compute its SHA-256.
3. Read the consumer's current copy (if it exists). Compute its SHA-256.
4. Look up the `baseline_sha` for this file in the config.

Classify each file into one of:

- **MISSING** — consumer has no copy. First-run case.
- **IN SYNC** — consumer SHA == upstream SHA. No action.
- **UPSTREAM CHANGED, LOCAL UNCHANGED** — upstream SHA != consumer SHA, and consumer SHA == baseline SHA. Safe to apply.
- **LOCALLY MODIFIED, UPSTREAM UNCHANGED** — upstream SHA == baseline SHA, consumer SHA != baseline SHA. No action.
- **LOCALLY MODIFIED + UPSTREAM CHANGED** — all three SHAs differ. Needs reconciliation.
- **NO BASELINE** — `baseline_sha` entry missing for this file. First-ever run. Treat as IN SYNC + record upstream as new baseline only if consumer matches upstream; otherwise classify as LOCALLY MODIFIED + UPSTREAM CHANGED and surface the 3-way.

Print a summary table: file, classification, one-line description.

### Step 3: Apply safe updates

For every file classified `MISSING` or `UPSTREAM CHANGED, LOCAL UNCHANGED`:
- Write the upstream content to the destination (create parent directory if needed).
- Update `baseline_shas[file]` to the new upstream SHA.
- Report each file as `updated` or `created`.

Do not touch `LOCALLY MODIFIED, UPSTREAM UNCHANGED` or `IN SYNC` files.

### Step 4: Reconcile locally modified files

For every file classified `LOCALLY MODIFIED + UPSTREAM CHANGED` (or `NO BASELINE` where content differs):
1. Read the three versions: baseline (if available — from a git show of the last known pristine, or skip if no baseline), local (consumer's current), upstream (fetched).
2. Present a summary of:
   - What changed upstream since baseline (upstream ← baseline diff)
   - What this project changed locally (local ← baseline diff, or "no baseline, full local content is the customisation")
3. Ask the user for each conflicted file: accept upstream, keep local, or merge (Claude proposes a merge).
4. If merge chosen: Claude produces a merged file, user confirms, then write and update baseline SHA.

Never overwrite a locally modified file without explicit user confirmation.

### Step 5: Update config

- Set `last_update_check` to today's ISO date.
- Write updated `baseline_shas`.
- Save the config to the same location it was loaded from (project-scope if present, else user-scope).

### Step 6: Report

Print a final summary:
- N files in sync (no change)
- N files updated
- N files created (first-run MISSING)
- N files reconciled (user confirmed each)
- N files skipped (locally modified, upstream unchanged — kept as-is)
- Next reminder date based on `update_reminder` cadence

## First-run bootstrap

If `last_update_check` is `null` or the config was just auto-created:
- Treat every `NO BASELINE` file as a first-sync candidate.
- If consumer content matches upstream: record SHA, classify as IN SYNC.
- If consumer content differs from upstream: classify as LOCALLY MODIFIED + UPSTREAM CHANGED (Option a — surface divergence immediately).
- Files that don't exist in the consumer project at all are MISSING → fetched fresh.

This path handles existing projects (like hst-tracker) that pre-date this command.

## Notes

- Version markers are advisory only — SHA comparison is the authority. Marker locations: `<!-- SOP-Version: YYYY-MM-DD -->` as line 1 for plain markdown files (SOP docs, guides); `sop_version: YYYY-MM-DD` inside YAML frontmatter for agents and slash commands.
- The command does not modify `git` state. The user commits changes themselves.
- If the user's project has `.claude/settings.json` with allowlists, the command respects them.
- Slash commands and agents go to user-scope (`~/.claude/`). SOP docs and guides go to project-scope (`docs/`). This is deliberate: one install of the tooling, per-project copies of the reference material.
