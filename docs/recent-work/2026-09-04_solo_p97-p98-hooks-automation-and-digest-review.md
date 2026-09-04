# P97 user-scope hooks automation + P98 digest review (10 Aug, 31 Aug)

**Date:** 2026-09-04
**Agent:** solo
**Commits:** `4e21dff` (file P97/P98 as in progress), `554d9c0` (feature, amended with the review fixes), housekeeping commit follows

The session opened as a review ("is agent-sop still adding value? how can it run automatically as I code?") and became a build on the operator's "proceed with the work". Batch 0.36.

**P97.** Three user-scope hooks under `scripts/hooks/` plus `scripts/install-hooks.sh` and a 36-case fixture suite. The context hook (SessionStart + UserPromptSubmit) prints what `/restart-sop` Steps 0-4 read, once per session and repo. The Stop hook exits 2 naming the gap when commits lack a session record, trackers are uncommitted, or a ship-sop auto-mode diff has no covering report; once per commit state. The push gate refuses an uncovered push only under ship-sop auto-mode. Root cause of ship-sop's four-and-a-half-month silence established by experiment (the hook fires by hand in a clone) and by docs (project-scope hooks load only from the launch directory; Stop stdout is discarded). Coverage rule corrected by a fixture before shipping. Install on this machine was denied by the permission classifier — one command owed, recorded in CLAUDE.md.

**P98.** Both digests verified at source. Shipped: floor 2.1.251, security-reviewer extract-then-execute row, branch-naming convention. Ten findings skipped with reasons.

**Incident.** The first reviewer subagent wrote fixture stubs over `Backlog.md`, `CLAUDE.md` and the core SOP in the live tree; caught by a dry run of the new Stop hook, stopped, restored from git, edits re-applied, gotcha filed, review re-run in an isolated worktree.

**ship-sop.** PR #9 reconciles its docs: P16 `[WON'T]`, P20 annotated, P25 filed to retire the project-scope wiring.
