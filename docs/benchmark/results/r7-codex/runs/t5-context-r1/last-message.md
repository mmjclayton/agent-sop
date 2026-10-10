Fixed the Count Twice tonnage bug. When either or both toggles are enabled, tonnage now doubles once. The corrected calculation applies to live totals, previous week comparisons, workout finish summaries, and historical summaries.

Added regression tests, including the 12.5 kg × 9 reps example (225 kg) and historical recalculation. Updated B1 in the backlog and feature map.

**Verification:** Full `npm test` passed: 198 server tests and 289 client tests. `git diff --check` passed.