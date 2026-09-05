---
description: Sync pristine-replica Agent SOP files (SOP docs, guides, slash commands, reference agents) from the upstream agent-sop repo into this project and the user's ~/.claude directory. Runs scripts/sync-sop-files.sh: a consumer file that equals any past upstream version is pristine and updated; a local edit is kept or reconciled; never force-overwrites.
sop_version: "2026-09-05"
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
  "exclude": [],
  "baseline_shas": {}
}
```
Inform the user, then proceed with first-run bootstrap behaviour (see Step 4).

**`local_path` is the trust root of the sync.** The script copies whatever the checkout at that path holds into this project and into `~/.claude/`. A project-scope `.claude/agent-sop.config.json` that carries a `local_path` therefore decides what a machine executes; keep that key in the user-global config and do not commit a project config that sets it. Manifest rows are data: a destination that leaves the consumer root or `~/.claude/`, or an upstream path that leaves the checkout, is refused and reported, never written.

**`exclude`** is an array of pristine-replica paths (relative to project root) that this project deliberately overrides locally and does not want synced. Excluded files are skipped in Steps 2/3/4/5 entirely — no classification, no baseline tracking, no fetch. Replaces the older workaround of freezing a baseline SHA and adding an explanatory note. Example: `"exclude": ["docs/sop/security.md"]` for a project that ships its own security doc.

## Pristine-replica file set

These are the files this command keeps in sync. Everything else (CLAUDE.md, Backlog, agent-memory, feature-map, build-plans, and project-authored templates like claude-md-template / agent-memory-template / backlog-template / build-plan-template that get stamped into target files at setup) is per-project and is never touched. The `review-template.md` exception is intentional: the substance-assertion validator has structural expectations, so the template ships as a pristine replica.

| Destination in consumer project | Upstream path | Scope |
|---------------------------------|---------------|-------|
| `docs/sop/claude-agent-sop.md` | `docs/sop/claude-agent-sop.md` | project |
| `docs/sop/security.md` | `docs/sop/security.md` | project |
| `docs/sop/sandboxing.md` | `docs/sop/sandboxing.md` | project |
| `docs/sop/harness-configuration.md` | `docs/sop/harness-configuration.md` | project |
| `docs/sop/compliance-checklist.md` | `docs/sop/compliance-checklist.md` | project |
| `docs/sop/multi-agent.md` | `docs/sop/multi-agent.md` | project |
| `docs/guides/optional-patterns.md` | `docs/guides/optional-patterns.md` | project |
| `docs/guides/cross-layer-rules.md` | `docs/guides/cross-layer-rules.md` | project |
| `docs/guides/multi-agent-context-routing.md` | `docs/guides/multi-agent-context-routing.md` | project |
| `docs/guides/multi-agent-parallel-sessions.md` | `docs/guides/multi-agent-parallel-sessions.md` | project |
| `docs/guides/managed-agents-integration.md` | `docs/guides/managed-agents-integration.md` | project |
| `docs/guides/sop-hill-climbing.md` | `docs/guides/sop-hill-climbing.md` | project |
| `docs/guides/sop-common-mistakes.md` | `docs/guides/sop-common-mistakes.md` | project |
| `scripts/migrate-to-multi-agent.py` | `scripts/migrate-to-multi-agent.py` | project |
| `scripts/refresh-rollup.sh` | `scripts/refresh-rollup.sh` | project |
| `scripts/refresh-in-flight.sh` | `scripts/refresh-in-flight.sh` | project |
| `scripts/validate-state-transitions.sh` | `scripts/validate-state-transitions.sh` | project |
| `scripts/resolve-resume-path.sh` | `scripts/resolve-resume-path.sh` | project |
| `scripts/archive-backlog.sh` | `scripts/archive-backlog.sh` | project |
| `docs/templates/review-template.md` | `docs/templates/review-template.md` | project |
| `docs/agent-memory/in-flight/README.md` | `docs/agent-memory/in-flight/README.md` | project |
| `~/.claude/commands/restart-sop.md` | `.claude/commands/restart-sop.md` | user |
| `~/.claude/commands/update-sop.md` | `.claude/commands/update-sop.md` | user |
| `~/.claude/commands/update-agent-sop.md` | `.claude/commands/update-agent-sop.md` | user |
| `~/.claude/commands/migrate-to-multi-agent.md` | `.claude/commands/migrate-to-multi-agent.md` | user |
| `~/.claude/commands/finish.md` | `.claude/commands/finish.md` | user |
| `~/.claude/agents/sop-checker.md` | `.claude/agents/sop-checker.md` | user |
| `~/.claude/agents/code-reviewer.md` | `.claude/agents/code-reviewer.md` | user |
| `~/.claude/agents/security-reviewer.md` | `.claude/agents/security-reviewer.md` | user |
| `~/.claude/agents/planner.md` | `.claude/agents/planner.md` | user |
| `~/.claude/agents/e2e-runner.md` | `.claude/agents/e2e-runner.md` | user |
| `~/.claude/scripts/hooks/agent-sop/sop-lib.sh` | `scripts/hooks/sop-lib.sh` | user |
| `~/.claude/scripts/hooks/agent-sop/sop-session-context.sh` | `scripts/hooks/sop-session-context.sh` | user |
| `~/.claude/scripts/hooks/agent-sop/sop-stop-drift.sh` | `scripts/hooks/sop-stop-drift.sh` | user |
| `~/.claude/scripts/hooks/agent-sop/sop-push-gate.sh` | `scripts/hooks/sop-push-gate.sh` | user |
| `~/.claude/scripts/hooks/agent-sop/sop-project-type.sh` | `scripts/hooks/sop-project-type.sh` | user |

The hook scripts are registered in `~/.claude/settings.json` by `scripts/install-hooks.sh` (run from the agent-sop checkout, or by `setup.sh`). Syncing them here refreshes the installed copies; it does not touch `settings.json`. Preserve the executable bit when writing them.

## Steps

### Step 1: Resolve source and run the classifier

The config's `local_path` names the upstream checkout. When it exists, the sync is a script, not prose:

```bash
CFG=.claude/agent-sop.config.json; [ -f "$CFG" ] || CFG="$HOME/.claude/agent-sop.config.json"
UP=$(jq -r '.local_path // empty' "$CFG"); [ -n "$UP" ] || UP=$(jq -r '.local_path' "$HOME/.claude/agent-sop.config.json"); UP="${UP/#\~/$HOME}"
git -C "$UP" pull --ff-only || echo "upstream checkout at $UP did not fast-forward; the classifier runs against what is there"
bash "$UP/scripts/sync-sop-files.sh"            # dry run: one line per file that is not in sync, then a summary
```

The script reads the manifest table above from the upstream copy of this file, so the table is the single source of what is synced. Per file it prints one of: `MISSING`; `OLDER` (the consumer copy equals the baseline **or any past upstream version of the file in git history** — a copy upstream once shipped was never edited locally, whatever the shared baseline says); `modified` (a local edit with upstream unchanged since the baseline: kept); `RECONCILE` (a local edit and either upstream moved since the baseline or there is no baseline yet, as on a first run onto a pre-customised project: the operator decides once); `excluded`; `absent-upstream` (a manifest row whose upstream file does not exist: fix the row); `UNREADABLE` (a consumer file the script cannot read: fix permissions, it is not classified); `REFUSED` (a destination that would leave the consumer root or `~/.claude/`, or an upstream path that would leave the checkout: treat the checkout as corrupted or compromised, write nothing, stop). Files in sync print nothing. The summary line counts manifest rows; a row with a scope other than `project` or `user`, or a manifest that no longer parses, is an error (exit 1), never a silent omission. The script itself runs from the upstream checkout and is deliberately not a manifest row, like `scripts/install-hooks.sh`.

Without a local checkout (GitHub-raw only), fall back to the prose three-way: for each manifest file fetch `https://raw.githubusercontent.com/{github}/main/{path}`, compare its SHA-256 with the consumer copy and the baseline, and apply only where the consumer equals the baseline.

### Step 2: Apply

```bash
bash "$UP/scripts/sync-sop-files.sh" --apply    # writes MISSING and OLDER files, refreshes baseline_shas and last_update_check
```

User-scope rows land under `~/.claude/`; the hook scripts among them are registered by `scripts/install-hooks.sh`, which this command does not run. Preserve nothing by hand: the script copies the executable bit with the file.

### Step 3: Reconcile

For every `RECONCILE` line: show the operator what changed upstream since the baseline and what this project changed locally (`git -C "$UP" log -p -- <path>` for the upstream side; `diff` for the local side), then ask: accept upstream, keep local, or merge. On accept or merge, write the file and set `baseline_shas[<upstream path>]` to the upstream SHA in the config. Never overwrite a locally modified file without that answer. A `modified` line (upstream unchanged) needs no action; if the edit is permanent, add the path to `config.exclude` so the report stops naming it.

### Step 4: Report

The script's summary line plus, for each RECONCILE, what the operator chose. Mention the next reminder date from `update_reminder`.

## Notes

- Version markers are advisory only — SHA comparison is the authority. Marker locations: `<!-- SOP-Version: YYYY-MM-DD -->` as line 1 for plain markdown files (SOP docs, guides); `sop_version: YYYY-MM-DD` inside YAML frontmatter for agents and slash commands.
- The command does not modify `git` state. The user commits changes themselves.
- If the user's project has `.claude/settings.json` with allowlists, the command respects them.
- Slash commands and agents go to user-scope (`~/.claude/`). SOP docs and guides go to project-scope (`docs/`). This is deliberate: one install of the tooling, per-project copies of the reference material.
