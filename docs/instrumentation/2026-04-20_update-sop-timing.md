# `/update-sop` timing — sample 1 of 3

**Date:** 2026-04-20
**Agent:** solo
**Session characteristics:** docs-only project, solo on main, SESSION_RANGE empty, session diff 1 file / 23 LOC / below Feature-review threshold, [Iteration] tag, no subagent spawn

## Per-step wall-clock

Wall-clock only covers tool-execution wrappers and visible file writes. Agent-side thinking time between steps is *not* captured here — a real instrumentation run would need shell-side timing or a wrapping harness. These numbers therefore under-count the user-perceived latency of steps that involve non-trivial agent reasoning (Step 5 especially).

| Step | Description | Wall-clock (s) | Ran or no-op? | Notes |
|------|-------------|----------------|---------------|-------|
| 0 | Resolve agent-id | 0 | reused from session start | trivial when `/restart-sop` already ran |
| 0a | Resolve commit range | 0 | reused from session start | empty — on main, no divergence |
| 1 | DoD self-eval | 0 | agent reasoning | trivial for a Backlog-only edit |
| 1b | Reviewer-turn threshold | 0 | no-op | 1 file / 23 LOC, [Iteration] — skip |
| 2 | Tests | 0 | no-op | docs-only |
| 2a | P-number collision check | 3 | ran | git fetch origin (~3s) + compare |
| 3 | Update Backlog | 0 | already done in-session | |
| 3b | Secondary trackers | 0 | no-op | SESSION_RANGE empty |
| 3c | State-transition validator | <1 | ran | validator: OK (0 warnings) |
| 3d | Drift detection | <1 | ran | "no session commits yet — skipping" |
| 4 | feature-map | 0 | no-op | P49 not shipped |
| 5 | Decision file + agent-memory narrative | ~60 (agent-side) | ran | wrote decision + updated In-Flight |
| 6 | Build-plan Batch Log | ~20 (agent-side) | ran | +1 entry, number-collision self-check cost included |
| 7 | project_resume overwrite | ~15 (agent-side) | ran | rewrote resume file |
| 8 | recent-work entry | ~15 (agent-side) | ran | new file |
| 8b | CLAUDE.md rollup refresh | <1 | ran | script invocation |
| 9 | MEMORY.md index | 0 | no-op | no new memory files |
| 10 | Commit | ~5 | ran | (pending as of this file write) |
| 11 | Reconciliation check + report | <1 | no-op | SESSION_RANGE empty |

## Observations from sample 1

- **Tooling overhead (gates, scripts, git):** ~5 seconds total across Steps 0, 0a, 2a, 3c, 3d, 8b. Not the bottleneck.
- **Agent-side writing:** Steps 5, 6, 7, 8 dominate wall-clock — all are "agent drafts then writes a file" steps. Estimated ~110 seconds of thinking + writing for this minimal session. A real Feature ship with multiple decisions/gotchas would scale this up, not the gates.
- **Step 1b reviewer-turn did not fire** — this session is the cheapest envelope. Samples 2 and 3 need to include an over-threshold Feature ship to see the reviewer-turn's real cost.
- **Session characteristics matter more than command length** — a solo docs-only session hits no-ops on half the gates. The 446-line command read cost is real but not proportional to runtime.

## What sample 2 should cover

Code project, solo, session shipping a [Feature] over the 50-LOC / 3-file threshold so Step 1b reviewer-turn fires. That's where the wall-clock spike (subagent spawn) would land — if the hypothesis from P49 is right, it dominates everything else.

## What sample 3 should cover

Multi-agent session (parallel worktree) if available, otherwise a second code-project session with a different shape (e.g. a refactor spanning many files). The goal is variance across realistic working conditions, not identical shapes.
