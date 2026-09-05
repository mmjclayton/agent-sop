# P103 — Stop hook fires only on code projects

**Date:** 2026-09-05
**Agent:** solo
**Commits:** `4f7f153` (feature), `650bb14` (review fixes), housekeeping commit follows

The operator's reply to the P102 report: yes, make the drift half code-only too. Batch 0.41.

**Change.** `sop-stop-drift.sh` exits 0 unless the repo is a code project, so Meaningful, Resonate and SyncHive get no Stop notice at all; `/update-sop` is their deliberate close. The context block still prints the drift facts there, and its closing line says nothing is enforced. Probed live before and after: silent on Meaningful and Resonate, still firing on agent-sop.

**Review.** Six gate agents against a detached worktree. The silent-failure reviewer found that BSD grep in a UTF-8 locale aborts the whole file on one invalid byte, so a pasted smart quote in CLAUDE.md read as no declaration and no signals — a code project became non-code and every hook went quiet. The library now runs in the C locale. It also found the contradiction warning printed only where a ship-sop config existed, though the Stop hook's silence rides on the same answer; a `Project type:` line now prints in every block, naming both consequences (security's MEDIUM). The test reviewer found the declaration never exercised against the drift half; four fixtures added. Live: the in-flight edit the notice itself prescribes re-fired the notice as a new dirty set — in-flight paths leave the throttle signature now. 85 cases.

**Incident, second time.** The test-coverage reviewer wrote fixture stubs (an eight-line `Backlog.md`, one-line `CLAUDE.md`, gutted core SOP, `src.js`) over the live tree while "breaking mechanisms in a throwaway copy", despite a read-only instruction and the worktree path in its prompt. The Backlog edit's anchor assertion caught it before anything was committed; seven tracked files restored with `git checkout --`, two strays deleted. The 2026-09-04 gotcha said "isolate in a worktree"; giving the agent a worktree path is not that — its shell starts in the session's cwd. The control is the Agent tool's `isolation: "worktree"`.

**Also seen.** With the review worktree present the resolver reported agent-id `1e7aa9` (two worktrees → path hash); `solo` again once it was removed. Records use `solo`.
