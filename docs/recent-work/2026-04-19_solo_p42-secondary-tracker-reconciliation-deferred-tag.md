# P42 — Secondary-tracker reconciliation + `[DEFERRED]` tag

**Date:** 2026-04-19
**Agent:** solo
**Commits:** 0c95727

Close a gap surfaced by hst-tracker: `/update-sop` treated `Backlog.md` as the sole work tracker and never reconciled project-specific finding files (e.g. `audit-backlog-*.md`) that use the same status-tag discipline. Fixed at four points. Core SOP Section 6 session-end checklist gained new step 3 (reconcile any `.md` in CLAUDE.md Key Documents using heading-level status tags); total 7 → 8 steps. `/update-sop` Step 3b auto-detects trackers (skip `Backlog.md`), reconciles finding IDs from this session's commits; Step 11 hard-blocks the commit if any ID is still `[OPEN]`. `/restart-sop` Step 4 gained an advisory drift guard for prior-session drift. Section 8 gains `[DEFERRED]` as distinct from `[BLOCKED]` (waiting-external vs intentionally-postponed). Templates + compliance checklist propagated (B4 accepts `[DEFERRED]`; new X6 check; totals 66 → 67 / 75 → 76). Heuristic is auto-detect rather than config opt-in — opt-in recreates the failure mode at a different level.
