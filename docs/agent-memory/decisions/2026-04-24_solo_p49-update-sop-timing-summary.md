# P49 — `/update-sop` timing summary across 3 samples: ABANDON the refactor

**Date:** 2026-04-24
**Agent:** solo

Three samples captured across two projects. Verdict: **abandon the `/update-sop` refactor.** No step dominates wall-clock enough to justify a rewrite, and the two real costs (agent-side drafting, and the reviewer-turn for Features/Refactors over threshold) are structural to the task, not fat that can be trimmed.

## Per-step median and max across samples 1 + 2 + 3

Values are wall-clock seconds. Agent-side estimates are perceptible time between tool calls. The samples differ in shape (docs-only × 2, code project × 1) so median + max is more useful than mean.

| Step | Median (s) | Max (s) | Dominant when? | Notes |
|------|------------|---------|----------------|-------|
| 0, 0a | 0 | 0 | never | Trivial identity resolution + range detection |
| 1 | <3 | ~3 | never | Agent reasoning only; no IO |
| 1b (reviewer-turn) | 0 (no-op) | ~95 | **sample 3** | Fires only on Feature/Refactor over 50 LOC / 3 files. Samples 1+2 never tripped it. |
| 2 (tests) | 0 (no-op) | ~11 | rare | Only when a code project also had a tree change to re-verify |
| 2a (P-collision) | 3 | 3 | never | `git fetch origin --quiet` dominates; the compare is microseconds |
| 3 (Backlog edit) | ~15 | ~15 | always a medium slot | Agent drafting of retag / new entries |
| 3b (secondary trackers) | 0 | ~1 | never | SESSION_RANGE-gated; no-op when committing to main |
| 3c (state validator) | <1 | <1 | never | Fast bash script |
| 3d (drift detection) | <1 | <1 | never | Fast bash script |
| 4 (feature-map) | ~25 | ~30 | small slot | Agent drafting |
| 5 (decision + narrative) | ~60 | ~70 | **dominant** | 1–2 new decision files + narrative edits |
| 6 (build-plan Batch Log) | ~20 | ~20 | small slot | Skipped when not phase-scoped |
| 7 (project_resume) | ~20 | ~25 | small slot | Overwrite, not append |
| 8 (recent-work) | ~20 | ~30 | small slot | New file |
| 8b (rollup refresh) | <1 | <1 | never | Script |
| 9 (MEMORY.md index) | 0 | 0 | never | Almost always no-op on non-first-session |
| 10 (commit) | ~5 | ~5 | never | Stage + conventional commit + push |
| 11 (reconciliation) | <1 | <1 | never | SESSION_RANGE-gated no-op on main |

## Which steps dominate wall-clock

1. **Step 5 (decision + narrative): ~60-70 s, every session.** The largest structural cost. Agent drafts 1–2 decision/gotcha files, each 1–3 KB of considered prose. Not compressible without degrading the artifacts — these are the files that future-you or another agent reads six months from now to reconstruct why the code looks the way it does. Every attempt to shorten them erodes the audit trail.
2. **Step 1b reviewer-turn: ~95 s when it fires.** Only on Feature/Refactor over threshold. Measured once, in sample 3. Produces a real artifact (the review) that caught a real bug in that sample — not theoretical value.
3. **Steps 4 + 7 + 8 (feature-map + resume + recent-work): ~20-30 s each, every session.** Compressible only by auto-generating from a single source of truth, which would recreate the "update N duplicate places" problem that `recent-work/` + rollup refresh was designed to solve. **Net: the SOP is already at the efficient frontier on these.**

## Step 1b reviewer-turn: fires in 1 of 3 samples, costs ~95 s when it does, produces real value

Sample 3 is the only session in this P49 batch that tripped the reviewer-turn threshold. One MEDIUM finding surfaced (localStorage guard permanently true) that was NOT caught by the test suite — it was a "harmless I/O" shape that tests don't flag. First concrete data point on reviewer-turn ROI: the cost is a bounded ~95 s, the value is a non-trivial find, the artifact (`docs/reviews/...`) lands as durable evidence of why the change is safe. **Keep it.**

## Refactor-or-abandon decision: ABANDON

**Abandon the `/update-sop` refactor.** Reasons:

1. **No step dominates enough.** Agent-side drafting (Steps 4, 5, 7, 8) sums to ~140-155 s per session, spread across 4 writes, all necessary. The reviewer-turn (Step 1b) costs ~95 s but only fires on the subset of sessions where it pays. Everything else is <5 s aggregate.
2. **The "slow" steps are producing durable artifacts.** Decision files, feature-map entries, resume snapshots, recent-work entries. Each serves a distinct audience (decisions for future implementers, resume for session restart, recent-work for the rollup, feature-map for user-visible shipping log). Compressing them means collapsing those audiences into one artifact that serves none of them well.
3. **Command-file read cost is NOT the bottleneck.** The 24.7 KB `update-sop.md` reads once per invocation. Negligible compared to the ~155 s of drafting that follows.
4. **P44 reviewer-turn is working as specified.** One data point is not a pattern, but the mechanics are proven: subagent spawn → file reads → artifact write → substance assertion → Batch Log reference. All four gates passed in sample 3.

**What a refactor MIGHT still consider** (but does not justify the cost now):
- Parallelising Steps 4 + 7 + 8's agent-side writes via a single tool-call round with three `Write` operations. Worth maybe 30 s if agent drafting overlaps. Not worth the coordination complexity.
- Auto-filling the "what did this session do" section from git log + commit messages. Worth maybe 30 s of Step 5/8 drafting. But the editorialised framing is the point — raw commit messages don't convey why or future follow-ups.

## Closes

- P49 `[SHIPPED - 2026-04-24]`.
- P51 `[SHIPPED - 2026-04-24]` (A1 fired partially, A2 fired cleanly with ~20× byte reduction; both acceptable against P51's ACs — see sample 3 dogfood section).
- No Tier B trim for hst-tracker's CLAUDE.md or agent-memory.md — the marginal cost doesn't justify the migration effort. Revisit only if a future sample shows repeated cold-read pressure.

## Samples

- Sample 1: `docs/instrumentation/2026-04-20_update-sop-timing.md` (agent-sop itself, docs-only, Iteration)
- Sample 2: `docs/instrumentation/2026-04-24_update-sop-timing.md` (agent-sop itself, docs-only, Iteration)
- Sample 3: `docs/instrumentation/2026-04-24_hst-tracker_update-sop-timing.md` (hst-tracker, code project, Feature over threshold with reviewer-turn firing)
