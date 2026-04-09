# SOP Benchmark — Round 2 Results

**Date:** 2026-04-09
**Target repo:** hst-tracker (1c73062, with sharpened CLAUDE.md)
**Model:** Claude Opus 4.6 (1M context)
**Tasks:** 4 (vague prompts, multi-step, context-heavy)

## Changes from Round 1

1. **Sharpened SOP:** Added "Common Mistakes" section (data model traps, client architecture, CSS tokens, brand voice) and intent-rich dispatch table to hst-tracker's CLAUDE.md
2. **Harder tasks:** Vague, product-level prompts instead of precise specs. Tasks require project context, data model knowledge, and design system compliance.
3. **Same methodology:** Git worktrees, blind scoring, randomised A/B labels

## Final Scores (Round 2)

| Task | SOP | Baseline | Winner | Key Difference |
|------|-----|----------|--------|----------------|
| 5. Tonnage bug | **21/21** | 12/21 | **SOP** | SOP recognised prior fix, scoped to server gaps. Baseline modified wrong client function (weekTotal), left primary bug unfixed. |
| 6. Scroll padding | 16/21 | 16/21 | **Draw** | Identical single-line CSS fix. Both arrived at 88px independently. |
| 7. Skip exercise | **20/21** | 11/21 | **SOP** | SOP shipped complete feature (endpoints, UI, 17 tests, docs). Baseline crashed mid-implementation, left dead code. |
| 8. Keyboard buttons | **21/21** | 11/21 | **SOP** | SOP used correct CSS tokens, 8 tests, ExerciseCard data flow. Baseline used non-existent tokens (production breakage). |
| **Aggregate** | **78/84** | **50/84** | **SOP +28** | |

**Record:** SOP 3 wins, 1 draw, 0 losses

## Token and Efficiency Comparison

| Metric | SOP | Baseline | Delta |
|--------|-----|----------|-------|
| Total tokens | 346K | 280K | SOP +24% |
| Total tool calls | 188 | 160 | SOP +18% |
| Average score | 19.5/21 | 12.5/21 | **SOP +56%** |

### Per-Task Breakdown

| Task | SOP Tokens | SOP Tools | SOP Time | Baseline Tokens | Baseline Tools | Baseline Time |
|------|-----------|-----------|----------|-----------------|----------------|---------------|
| 5. Tonnage bug | 74K | 27 | 222s | 96K | 56 | 570s |
| 6. Scroll padding | 64K | 24 | 180s | 55K | 21 | 142s |
| 7. Skip exercise | 127K | 98 | 788s | (crashed) | 49 | 271s |
| 8. Keyboard buttons | 80K | 39 | 343s | 64K | 34 | 246s |

Note: Task 5 baseline used MORE tokens than SOP (96K vs 74K) while producing a worse result. The baseline spent 56 tool calls exploring blindly vs SOP's directed 27.

## Round 1 vs Round 2 Comparison

| Metric | Round 1 | Round 2 | Change |
|--------|---------|---------|--------|
| SOP aggregate score | 68/72 (94%) | 78/84 (93%) | Consistent |
| Baseline aggregate score | 62/72 (86%) | 50/84 (60%) | **-26 percentage points** |
| SOP margin | +6 points (8%) | +28 points (33%) | **+25 percentage points** |
| SOP wins | 2 of 4 | 3 of 4 | Improved |
| Tasks where baseline broke production | 0 | 2 (Tasks 5, 8) | Significant |

### What Changed

**Round 1 tasks** (precise, self-contained prompts) gave the baseline enough guidance to compensate for missing context. The baseline's main failures were subtle misses (stale test assertion, wrong default view).

**Round 2 tasks** (vague, context-dependent prompts) exposed the baseline's lack of project knowledge:
- **Task 5:** Baseline modified the wrong function because it couldn't distinguish weekTotal (builder) from inline tonnage (logger)
- **Task 7:** Baseline attempted a complex feature without understanding the existing data model and crashed
- **Task 8:** Baseline guessed at CSS token names and got them wrong, causing production visual breakage

The SOP agent navigated all four tasks correctly because CLAUDE.md told it:
- Where tonnage is calculated and that it's derived, not stored
- That ExerciseCard is separate from WorkoutLogger
- That WorkSet.status already supports "skipped"
- The exact CSS token names (--color-bg-elevated, not --color-surface-elevated)

## Key Findings

### 1. Vague prompts amplify the SOP advantage dramatically

Round 1 margin: +8%. Round 2 margin: +33%. The less hand-holding in the prompt, the more the SOP context matters.

### 2. The "Common Mistakes" section prevented production bugs

Two of four baseline submissions had production-breaking issues:
- Task 5: Wrong function modified (weekTotal vs inline render)
- Task 8: Non-existent CSS tokens (--color-surface-elevated)

Both are explicitly called out in the Common Mistakes section. The SOP agent avoided both.

### 3. The SOP saved tokens on complex tasks

Task 5: SOP used 74K tokens (27 tools) vs baseline's 96K (56 tools). The SOP agent went directly to the right files. The baseline spent twice as many tool calls exploring.

### 4. The SOP enabled complete feature delivery

Task 7 (Skip Exercise): The SOP agent shipped a complete feature with endpoints, UI, confirmation dialogs, CSS, 17 tests, and updated Backlog/feature-map. The baseline crashed after 49 tool calls with uncommitted partial work. Context-heavy features need context.

### 5. Token overhead is modest and pays for itself

SOP used 24% more tokens overall, but produced 56% higher scores. On Task 5 specifically, the SOP used FEWER tokens than baseline while producing a correct result. The overhead is in reading context files upfront; the payoff is fewer wrong turns.

## Conclusions

**The sharpened SOP significantly outperforms the baseline on real-world tasks.** The combination of:
1. Vague, product-level prompts (how real work arrives)
2. "Common Mistakes" with specific gotcha callouts
3. Intent-rich dispatch table (not just file paths)

...turns a modest round 1 advantage (+8%) into a decisive round 2 advantage (+33%).

**The SOP's value is not in raising the quality ceiling — it's in raising the quality floor.** Both agents can produce excellent code. The SOP prevents the specific, catastrophic misses that would require rework: wrong functions, wrong tokens, incomplete features.

### Recommendations for SOP Design

1. **"Common Mistakes" is the highest-value section.** It directly prevented 2 production bugs.
2. **Intent-rich dispatch** ("when you need to change X, start at Y") outperforms file-path lists.
3. **Gotcha callouts at the point of decision** beat general documentation.
4. **Vague prompts are the real test.** Precise prompts mask context deficiencies.
