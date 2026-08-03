# Merging without `/update-sop` strands every tracker at once

**Date:** 2026-08-03
**Agent:** solo

## The surprise

A session on 2026-07-27 did real work: merged PR #12 and replaced a live `PreToolUse` hook in `~/.claude/settings.json`. It ended without running `/update-sop`.

Eight days later `/restart-sop` opened on a project that looked mid-flight and confused:

- `project_resume_solo.md` said "Open the PR for this branch and merge. Nothing is pushed yet." The branch had merged as PR #11 the day before that session even started.
- The same resume said "hst-tracker PR #616 is open". It had merged 2026-07-26 07:30 UTC.
- `docs/agent-memory.md` In-Flight carried a line ending "Clear this line once this branch merges." The branch had merged. The line was still there.
- Every tracker's last commit was `4621b1b` while `main` was at `314b98f`.

The In-Flight line is the specific trap. Its presence is the SOP's own signal for "previous session was interrupted, read the Batch Log before starting new work". Here it was a **false positive**: Batch 0.27 was complete, reviewed, merged, and fully logged. The line was stale, not live. An agent that trusted the signal would have gone hunting for unfinished work in a batch that had none.

## Why one missed checklist produced four symptoms

The trackers are not independent. `/update-sop` is the single write-point where a session's outcome reaches all of them — Backlog status, feature-map, Batch Log, agent-memory In-Flight and Completed, resume snapshot, recent-work entry, CLAUDE.md rollup. Skipping it does not degrade one file. It leaves every file holding the *previous* session's world-view while git moves on without them.

That asymmetry is what makes it dangerous. Nothing was lost — git had the commit, the hook change was on disk and working. But the written record actively asserted things that were false, and it asserted them in exactly the files the next session is required to read first and trust.

## Rules

1. **Merging is not shipping. The checklist is.** A merged PR with no `/update-sop` is a session that did not finish. Treat the two as one operation.
2. **A self-clearing instruction only clears if something runs it.** "Clear this line once X" written into a tracker is not a mechanism, it is a note to a future agent who may never arrive. Prefer state a later step actually recomputes.
3. **Distinguish a stale In-Flight line from a live one before acting on it.** Cross-check the named branch against `git log`/`gh pr` first. If the work merged, the line is drift, and the correct response is to clear it, not to go looking for an unfinished batch.
4. **Treat "the trackers all stop at the same commit while `main` is ahead" as the drift signature.** One `git log -1 -- <file>` per tracker catches it in seconds, and it is far more reliable than reading each file for plausibility — stale files read as perfectly coherent, just wrong.
5. **Out-of-repo state needs the same closing discipline.** The hook change lived in `~/.claude/` with no git trace at all. Had the disk not still held it, there would have been no record it ever happened.

## Related

The 2026-07-27 session also left a duplicate `npx block-no-verify` entry in the dead `~/.claude/hooks/hooks.json` while fixing the live one in `settings.json` — a second instance of rule 5, fixed under P74. Reconciliation logged as Batch 0.29. See [[2026-07-26_solo_project-specific-step-leaked-into-user-scope-command]] for the adjacent problem of user-scope config drifting out of step with the repo that governs it.
