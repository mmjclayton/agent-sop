# SOP Benchmark Results

**Date:** 2026-04-09
**Target repo:** hst-tracker (fecb997)
**Model:** Claude Opus 4.6 (1M context)
**Tasks:** 4 (refactor, 2x test writing, feature)

## Final Scores

| Task | SOP | Baseline | Winner | Key Difference |
|------|-----|----------|--------|----------------|
| 1. Pill refactor | **17/18** | 11/18 | **SOP** | SOP updated test assertion to match Pill's class naming; baseline left it stale |
| 2. Import preset tests | 17/18 | **18/18** | **Baseline** | Baseline used stronger equality assertions, no uncertainty comments |
| 3. Page titles | **17/18** | 16/18 | **SOP** | SOP correctly handled default view showing just "LOADOUT"; baseline showed "Train — LOADOUT" |
| 4. Server utils tests | 17/18 | 17/18 | **Draw** | Both thorough; SOP tighter, baseline had one standout negative test |
| **Aggregate** | **68/72** | **62/72** | **SOP +6** | |

**Record:** SOP 2 wins, Baseline 1 win, 1 draw

## Token and Efficiency Comparison

| Metric | SOP | Baseline | Delta |
|--------|-----|----------|-------|
| Total tokens | 243K | 209K | SOP +16% |
| Total tool calls | 87 | 78 | SOP +12% |
| Average time | 172s | 155s | SOP +11% |
| Average score | 17.0/18 | 15.5/18 | SOP +10% |

### Per-Task Breakdown

| Task | SOP Tokens | SOP Tools | Baseline Tokens | Baseline Tools |
|------|-----------|-----------|-----------------|----------------|
| 1. Pill refactor | 67K | 28 | 57K | 27 |
| 2. Preset tests | 65K | 23 | 59K | 28 |
| 3. Page titles | 55K | 15 | 46K | 7 |
| 4. Utils tests | 56K | 21 | 47K | 16 |

## Key Findings

### 1. SOP improved correctness on tasks requiring project knowledge

Tasks 1 and 3 had acceptance criteria that depended on understanding project-specific context:
- **Task 1:** The SOP agent knew to check and update the existing test assertion when class names changed (Pill uses `pill--active` not `active`)
- **Task 3:** The SOP agent knew that the logger view is the default/home screen and should show just "LOADOUT", not "Train — LOADOUT"

The baseline agent could have discovered both through exploration, but didn't. The SOP front-loaded the context.

### 2. SOP did NOT improve test-writing quality

Tasks 2 and 4 (both test-writing) showed no SOP advantage. The baseline matched or beat the SOP agent. Test writing depends on reading the source file under test, not project context files. Both agents read `presets.js` and `utils.js` equally well.

### 3. SOP costs ~16% more tokens

The SOP agent consistently read CLAUDE.md, agent-memory.md, and other context files before starting work. This added ~34K tokens across 4 tasks. The overhead was worthwhile when project context mattered (Tasks 1, 3) but wasted on isolated test-writing tasks (Tasks 2, 4).

### 4. Quality was consistently high regardless of condition

Both conditions scored 17+ on 3 of 4 tasks. The baseline's only low score (11 on Task 1) came from a specific miss (stale test assertion), not from generally poor work. This suggests the SOP's value is in preventing specific misses, not in raising the baseline quality floor.

### 5. Blind reviewers found meaningful differences

The scoring agents identified real qualitative differences without knowing which was SOP:
- Task 1: "B updated the test assertion... A left the test file untouched" (SOP caught the regression)
- Task 3: "B explicitly handles the logger case first" (SOP understood the UX intent)
- Task 2: "B uses ordered equality... Submission A has a mid-test uncertainty comment" (Baseline wrote tighter tests)

## Conclusions

**The SOP earns its token cost when the task requires project-specific knowledge.** Refactors, features that touch existing conventions, and changes with non-obvious side effects benefit most. The SOP prevents the kind of subtle misses (stale tests, wrong default behaviour) that would get caught in code review but waste a round-trip.

**The SOP adds overhead with no benefit on isolated, self-contained tasks.** Test writing, utility creation, and single-file changes where the source file is the only context needed are better served by a minimal CLAUDE.md that saves tokens.

### Implications for Multi-Agent Optimisation (P24)

- **Context-aware tasks** (refactors, features, bug fixes touching multiple files) should use agents with full SOP context
- **Isolated tasks** (test writing, utility creation, documentation) can use agents with minimal context to save tokens
- A **tiered context loading** strategy could give agents just the sections they need rather than the full CLAUDE.md
- The 16% token overhead is modest. At scale across many agents, selective context loading could save 10-15% without quality loss

## Limitations

- 4 tasks is a small sample. Results are directional, not statistically significant.
- Single codebase (hst-tracker). Other projects may show different patterns.
- Same model for both conditions (Opus 4.6). Results may differ on Sonnet or Haiku.
- No DB-dependent tasks tested (migrations, API endpoints).
- Blind reviewers were the same model family. A human reviewer might score differently.
