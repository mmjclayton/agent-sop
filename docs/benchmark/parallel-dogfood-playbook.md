<!-- SOP-Version: 2026-04-19 -->
# Phase 1 Parallel-Session Dogfood Playbook

The Batch 1.7 validation exercise for P43. Demonstrates that three parallel Claude Code sessions can run `/update-sop` concurrently on separate git worktrees of the same repo and merge to main without manual conflict resolution.

This is a Matt-hands exercise — requires three terminal instances of Claude Code running in parallel. Not something a single agent session can perform.

## Prerequisites

1. agent-sop repo up to date on `main` with all Phase 1 batches (1.1-1.6) committed.
2. hst-tracker repo on a clean working tree. If uncommitted work exists (`git status --short` not empty), either commit, stash, or choose a different target project for the dogfood. Running the migration on a dirty tree is refused by the script.
3. Python 3 available on `PATH` (already standard on macOS and most Linux).

## Stage 1 — Pull agent-sop updates into the target project

In a single session (not parallel yet):

```bash
cd ~/Projects/hst-tracker   # or whichever target project
# Run the /update-agent-sop slash command inside Claude Code.
# This syncs pristine-replica files from agent-sop via three-way diff.
```

The command should report: Phase 1 artefacts pulled (new `migrate-to-multi-agent.py` script, updated `/update-sop` / `/restart-sop` commands, new parallel-sessions guide, updated core SOP, updated compliance checklist).

Review with `git status` and commit the synced artefacts with a dedicated commit:

```
chore: sync agent-sop Phase 1 artefacts (parallel-session support)
```

## Stage 2 — Run migration

Dry-run first:

```bash
python3 scripts/migrate-to-multi-agent.py --dry-run
```

Review the reported extraction counts and sample filenames. If anything looks off, fix the script in agent-sop (not in hst-tracker) and re-sync.

Then the real run:

```bash
python3 scripts/migrate-to-multi-agent.py
```

After extraction:

1. `git status` — confirm new directories and files
2. `git diff --stat` — verify no unexpected file changes
3. Manually remove the legacy sections from CLAUDE.md and docs/agent-memory.md (the script intentionally leaves them for human review — see `/update-sop --migrate-to-multi-agent` Step 7 in `.claude/commands/migrate-to-multi-agent.md`)
4. Run `/update-sop` (normal session-end) to refresh the `## Recent Work (rollup)` section in CLAUDE.md
5. Commit: `chore: migrate to multi-agent directory structure`

Migration complete. hst-tracker is now in Phase 1 format.

## Stage 3 — Create three worktrees

Pick three Backlog items with mutually exclusive file sets. Good candidates:

- Frontend-only item (`client/...` files)
- Server-only item (`server/...` files)
- Documentation / configuration item (`docs/` or root config)

Create the worktrees:

```bash
cd ~/Projects/hst-tracker
git worktree add ../hst-a feature/parallel-test-a
git worktree add ../hst-b feature/parallel-test-b
git worktree add ../hst-c feature/parallel-test-c
```

## Stage 4 — Three parallel Claude Code sessions

Open three terminals. In each:

```bash
# Terminal 1
cd ~/Projects/hst-a
claude
# Once inside Claude Code: run /restart-sop then pick up task A

# Terminal 2
cd ~/Projects/hst-b
claude
# Inside Claude Code: /restart-sop then task B

# Terminal 3
cd ~/Projects/hst-c
claude
# Inside Claude Code: /restart-sop then task C
```

Each session's `/restart-sop` should:

- Detect a non-`solo` agent-id (hash of worktree path — three distinct ids)
- Read `project_resume_<agent-id>.md` (does not exist yet — falls back and notes this)
- Read the agent-memory narrative, scan recent decisions/gotchas
- Resolve session commit range via `git merge-base` (empty on a brand-new branch)
- Report readiness

Each session performs its assigned task, makes commits on its own branch, then runs `/update-sop`. Expected behaviour:

- Step 0a resolves the session commit range to `<branch-point>..HEAD`
- Step 2a checks for P-number collisions (none expected since tasks are mutually exclusive)
- Step 3b scans the branch's own commits for finding IDs (partitioned per-agent)
- Step 5 writes any new decisions/gotchas to per-entry files
- Step 7 writes `project_resume_<agent-id>.md`
- Step 8 writes a session entry to `docs/recent-work/` with the agent's id in the filename
- Step 8b refreshes the CLAUDE.md rollup

## Stage 5 — Sequential merge

Matt merges branches to main one at a time:

```bash
cd ~/Projects/hst-tracker
git checkout main

git merge feature/parallel-test-a
# Expect: clean merge. Verify no conflict messages.

git merge feature/parallel-test-b
# Expect: clean merge. The rollup section may show a merge conflict
# IF agent A and agent B both refreshed it — but since the content is
# idempotent, pick either side or re-run /update-sop Step 8b to regenerate.

git merge feature/parallel-test-c
# Same.
```

If any merge conflicts appear on tracking files, that is a finding — log it.

## Stage 6 — Verification

After all three merges:

1. Check that three `project_resume_*.md` files exist locally:
   ```bash
   ls ~/.claude/projects/*/memory/project_resume_*.md | grep -i hst-tracker
   ```
2. Check that three session-entry files exist in `docs/recent-work/` with distinct agent-ids in filenames.
3. Check that any new decisions/gotchas are present as individual files in their respective directories.
4. Check the CLAUDE.md rollup reflects all three sessions.
5. Run `/update-sop` one more time on main to re-refresh the rollup (idempotent — should produce the same content).

## Stage 7 — Cleanup

```bash
cd ~/Projects/hst-tracker
git worktree remove ../hst-a
git worktree remove ../hst-b
git worktree remove ../hst-c
# Branches are retained — delete if truly done:
git branch -d feature/parallel-test-a feature/parallel-test-b feature/parallel-test-c
```

## Recording findings

Append to `docs/benchmark/parallel-dogfood-log.md` (create if absent):

```markdown
### YYYY-MM-DD: hst-tracker 3-agent parallel dogfood

- Agents: <agent-id-a>, <agent-id-b>, <agent-id-c>
- Tasks: A = <description>; B = <description>; C = <description>
- Merges: clean / N conflicts — describe
- Tracking files verified: rollup, resume files, recent-work, decisions, gotchas
- Issues encountered: <none | listed>
- Follow-ups: <agent-sop issues to address>
```

If findings surface SOP gaps, fix in agent-sop, sync via `/update-agent-sop`, re-run the dogfood. Do not patch hst-tracker in isolation.

## Status tracking

Update `docs/build-plans/phase-1-parallel-sessions.md` Deploy Checklist item for Batch 1.7 when the dogfood pass completes cleanly.
