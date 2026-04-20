# P49 filed + sample 1 of `/update-sop` timing captured

**Date:** 2026-04-20
**Agent:** solo
**Commits:** (pending this commit)

P49 `[OPEN] [Iteration]` filed after Matt questioned whether SOP update commands are overbloated. First-pass estimate of a 35-40% line cut for `/update-sop` was ungrounded — conflated token-read cost with wall-clock runtime and missed the tradeoff in "zero enforcement loss". Plan: capture per-step wall-clock over three sessions, summarise dominance, then decide. Decision file records the measure-before-refactor reasoning and flags the "too good to be true" signal as worth remembering.

This session's `/update-sop` run is sample 1 of 3. Timings captured in `docs/instrumentation/2026-04-20_update-sop-timing.md`. Docs-only, solo-on-main, below-threshold case — expected to be the cheap envelope. Samples 2 and 3 should cover code project and (ideally) multi-agent or code-plus-reviewer scenarios.

Related: Batch 0.18 in phase-0 build plan. In-Flight Work now tracks P49 under agent `solo`.
