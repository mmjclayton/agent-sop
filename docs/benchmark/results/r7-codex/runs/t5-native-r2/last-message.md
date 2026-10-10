Fixed the tonnage calculation so enabling both “Count Twice” options applies a single 2× multiplier. The current and previous week totals now use the same calculation, and the regression test verifies that 12.5 kg × 9 reps totals 225 kg.

**Verification:** All client tests passed (289 tests across 25 files) and all server tests passed (197 tests across 3 suites).