# Measure `/update-sop` step timing before any trim refactor (P49)

**Date:** 2026-04-20
**Agent:** solo

Matt flagged that the SOP update commands feel slow. First-pass analysis of `/update-sop` (446 lines, ~17 steps) suggested a ~35-40% line cut was possible by extracting bash gate logic into `scripts/sop-gates.sh`. That estimate was made without measurement — it conflated token-read cost per invocation with wall-clock execution time, and assumed "cheap gates no-op on solo" without checking which gates actually dominate perceived slowness.

Matt pushed back: "that sounds almost too good to be true". Correct. Re-examined the line accounting:

- Extractable bash: ~150 lines realistic (not 200), giving a 35% cut not 40%
- Zero-enforcement-loss claim was overstated — inline bash lets the agent reason about edge cases; script delegation forces a second hop to understand what's being enforced
- Extraction helps token-read cost per invocation, NOT wall-clock time. Most runtime on a non-trivial session is: Step 1b reviewer-turn (subagent spawn, minutes), Step 5 decision/gotcha file writing (agent thinking), Step 8 recent-work drafting (agent thinking). Extracting bash doesn't touch any of those.

Decision: do not refactor `/update-sop` until three real sessions have been instrumented. File P49 to capture wall-clock per step across at least three diverse sessions (solo docs-only, solo code, multi-agent if one crops up). Only then commit to a refactor — and only on the steps that actually dominate.

Out-of-scope guard: P49 explicitly prohibits any command refactor or gate extraction work. Measurement only. Follow-up P-number will be filed if the data supports action.

Related: the "too good to be true" check is itself worth remembering. When a refactor estimate offers a big cut with no tradeoff, that's a signal the tradeoff hasn't been identified yet, not that it doesn't exist.
