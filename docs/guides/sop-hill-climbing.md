# SOP Hill-Climbing: Benchmark-Driven Improvement

How to iteratively improve the Agent SOP using A/B benchmark data. This process was used to develop the SOP from +8% advantage (Round 1) through +33% (Round 2 peak), identify a regression (ambiguous gotcha), and fix it (Round 4).

## Prerequisites

- A real project codebase with at least 20 files and a test suite
- 4+ benchmark tasks that span: bug fix, refactor, feature, test writing
- Git worktrees for isolation (see `docs/benchmark/`)

## The Process

### Step 1: Establish baseline

Run the 4 tasks with NO SOP (4-line CLAUDE.md stub). Record:
- Did the agent complete the task correctly?
- How many tool calls?
- Any production-breaking errors?

This is your control group. You need it to know whether SOP changes help or hurt.

### Step 2: Run with current SOP

Same 4 tasks, same codebase commit, full CLAUDE.md. Compare against baseline on:

| Dimension | What to look for |
|-----------|-----------------|
| Correctness | Did both get the right answer? If SOP got it wrong, WHY? |
| Completeness | Did SOP find more instances? (e.g. tonnage: SOP found 4 sites, baseline found 2) |
| Efficiency | Did SOP use fewer tool calls? (SOP should navigate directly) |
| Failures | Did baseline crash or use wrong tokens? SOP prevents these. |

### Step 3: Identify what moved the needle

From the comparison, classify each CLAUDE.md section:

| Category | Example | Action |
|----------|---------|--------|
| **Helped** | Common Mistakes prevented wrong file modification | Keep, strengthen |
| **Hurt** | Ambiguous gotcha led to wrong fix | Fix the entry — state what IS correct |
| **No effect** | Definition of Done on bug fixes | Remove to save tokens |
| **Unknown** | Brand voice guidance | Not tested — design a task that tests it |

### Step 4: Make ONE change

Change one thing at a time. If you change 3 things and results improve, you don't know which change helped.

Good single changes:
- Fix one ambiguous gotcha entry
- Add one new gotcha for a failure you observed
- Remove one section that showed no effect
- Change dispatch from file-paths to intent-based

### Step 5: Re-run and compare

Same tasks, same codebase, changed SOP. Compare against both baseline AND previous SOP run.

| If... | Then... |
|-------|---------|
| SOP improved on the target task | The change worked. Keep it. |
| SOP regressed on another task | The change has side effects. Investigate. |
| No change | The modification was neutral. Consider removing to save tokens. |
| Both SOP and baseline improved | Model stochasticity, not your change. Run again. |

### Step 6: Repeat

Each cycle tightens the SOP. After 3-4 cycles, you'll converge on the minimum effective CLAUDE.md for your project.

## Avoiding Overfitting

The biggest risk is tuning the SOP to ace your 4 benchmark tasks without improving real work.

**Signs of overfitting:**
- SOP scores improve on benchmark tasks but real sessions don't feel different
- You're adding task-specific hints that only help one benchmark scenario
- The CLAUDE.md is growing past 300 lines with no new failures being prevented

**Countermeasures:**
- Rotate benchmark tasks every 3 cycles — introduce new ones, retire old ones
- Track qualitative observations from real sessions, not just benchmark scores
- If a section doesn't prevent a real failure you've observed, cut it

## Case Study: The Tonnage Gotcha

| Version | Entry | Result | Lesson |
|---------|-------|--------|--------|
| v1 | "Tonnage is derived from countTwice flags" | Agent removed the multiplier (WRONG) | Anti-pattern only → misinterpretation |
| v2 | "Math.max(wMult, rMult) is correct — do not remove it" | Agent found server gap (CORRECT) | Correct pattern stated → right action |

One line changed. The benchmark flipped from consistent failure to correct. This is what hill-climbing looks like: precise, data-driven, one change at a time.

## Reference

- Benchmark framework: `docs/benchmark/`
- Results: `docs/benchmark/results/`
- LangChain prior art: [Better Harness: Hill-Climbing with Evals](https://blog.langchain.com/better-harness-a-recipe-for-harness-hill-climbing-with-evals/)
