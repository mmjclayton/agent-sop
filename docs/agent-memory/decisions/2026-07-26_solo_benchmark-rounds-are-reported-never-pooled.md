# Benchmark rounds are reported separately, never pooled

**Date:** 2026-07-26
**Agent:** solo

We chose to make `round` part of the aggregation key over pooling all rows for a task, because pooling averages away disagreement between rounds rather than resolving it — and disagreement between rounds is the single most important thing this benchmark has ever produced.

## What went wrong

P72's `aggregate` keyed on `(task, arm)`. The input format requires a `round` column and a `run` column, and the awk used neither. The reviewer reproduced the consequence: round 5 scoring sop 10 / nosop 90, and round 6 scoring sop 90 / nosop 10, aggregated to **median 50 on both arms, delta +0.00, "RANGES OVERLAP"**.

Two decisive, opposite results reported as a wash. That is worse than reporting nothing, because it looks like a measurement.

The same key ignored `run`, so duplicated rows inflated `k` — the exact quantity the README now gates publication on (k>=3 to report, k>=5 to publish).

## Why not pool

Pooling is defensible when rounds are repeated samples of one stable quantity. They are not. A round pins a base commit, a model version, and a prompt set. R2 and R5 differed by all three, which is why they disagreed by 17 points, and the Backlog's own interpretation lists model capability and methodology as the drivers. Averaging R2 and R5 into "+24%" would assert a number no round measured and would hide the reason the two disagree.

`k` exists to average out **run-to-run nondeterminism within one configuration**. That is the variance arXiv:2602.11619 measures and the only variance repetition can address. Round-to-round variance is a different quantity and needs to be read, not averaged.

## What ships

`aggregate` keys on `(round, task, arm)`, asserts `(round, task, arm, run)` unique, and prints a line when more than one round is present saying rounds are never pooled and why. Output ordering is deterministic (awk's `for (k in arr)` is not).

## The general lesson

**If a data format requires a column, the code must use it or the format must stop requiring it.** `round` and `run` were mandatory in the input, enforced by the `NF < 5` guard, and then discarded. That gap is invisible in review unless someone constructs input where the ignored column carries the signal — which is exactly the test the original never wrote, because it used one round.

Related: [[2026-07-26_solo_auditing-by-command-name-misses-failures-by-exit-code]] — same session, same failure to test the case the code would actually meet.
