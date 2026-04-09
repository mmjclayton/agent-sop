# R4 Benchmark Results — Rolled-Back Config with Fixed Gotcha

**Date:** 2026-04-09
**Config:** Common Mistakes + Intent Dispatch + fixed tonnage gotcha. No Definition of Done.
**Base:** 7cb45b4 (1c73062 + corrected tonnage entry)
**Tasks:** 4 fast tasks (tonnage, pill, titles, scroll)

## Results

| Task | SOP | Baseline | Winner |
|------|-----|----------|--------|
| A: Tonnage | Correct server fix, 4 tests, 87K, 46t | Correct server fix, 3 tests, 76K, 44t | Draw |
| B: Pill | 4 components + CSS cleanup, 80K, 54t | 5 components + smart exclusions, 70K, 52t | Draw |
| C: Titles | 4 tests, 68K, 22t | 11 tests, 56K, 24t | Draw |
| D: Scroll | Fixed 390px breakpoint, 67K, 29t | 96px margin bump, 57K, 23t | Draw |

## Key Finding: Fixed Gotcha Works

| Gotcha version | SOP tonnage result | Attempts |
|---------------|-------------------|----------|
| Old ("calculated from countTwice flags") | Wrong — removed multiplier | 2/2 wrong |
| **Fixed ("Math.max is correct — do not remove it")** | **Correct — found server gap** | **1/1 correct** |

## Cross-Round Summary

| Round | Config | Margin | Key observation |
|-------|--------|--------|----------------|
| R1 | Original SOP, precise prompts | +8% | SOP prevents subtle misses |
| R2 | + Common Mistakes + Intent Dispatch, vague prompts | +33% | Peak — baseline crashed/wrong tokens |
| R3 | + Definition of Done | ~0% | DoD didn't help, baseline improved |
| Fast | R2 config (old gotcha) | Negative | Ambiguous gotcha caused wrong fixes |
| R4 | R2 + fixed gotcha, no DoD | ~0% | Fixed gotcha works, all draws |

## Conclusions

1. **The SOP's value is a higher floor, not a higher ceiling.** When baseline doesn't fail catastrophically, results are equivalent.
2. **Common Mistakes with correct-pattern entries is the optimal config.** Prevents wrong turns without adding noise.
3. **Definition of Done adds weight without adding quality** on bug fixes. May help features but not tested in isolation.
4. **Gotcha entries MUST state what IS correct.** Anti-pattern-only entries cause misinterpretation.
5. **Baseline quality varies stochastically.** R2 baseline crashed and used wrong tokens. R4 baseline matched SOP on every task. The SOP insures against bad rolls.
