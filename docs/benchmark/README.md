# Agent SOP Benchmark Framework

Measures whether the Agent SOP improves Claude Code agent output quality, consistency, and efficiency compared to a baseline agent with no SOP context.

## Methodology

### A/B design

Each benchmark task runs twice against the same codebase commit:

| Condition | Label | What the agent sees |
|-----------|-------|---------------------|
| **SOP** | `sop` | Full CLAUDE.md, docs/agent-memory.md, docs/sop/, .claude/agents/, brand-voice.md |
| **Baseline** | `nosop` | Bare repo only. CLAUDE.md replaced with stack-only stub (framework, commands, schema path). No agent-memory, no SOP docs, no brand-voice. |

Both agents receive the **identical task prompt**. The only variable is project context.

### Run repetition and variance (MANDATORY from 2026-07-26)

**Every task runs at least 3 times per arm, 5 preferred. Report median and range, never a single score.**

Rounds R1-R5 scored one run per task per arm. That is not enough to separate the effect being measured from ordinary run-to-run variance, and the record shows the cost: R2 reported +33%, R5 reported +16%, and "single round is not averaged" sits in the Backlog's own list of reasons for the gap. Some unknown share of that 17-point swing is noise that the methodology had no way to expose.

The size of the problem has been measured once, externally. As reported by Mehta, [*When Agents Disagree With Themselves*](https://arxiv.org/abs/2602.11619) (July 2026), from 8,000 repeated executions on HotpotQA and 1,000 on SWE-bench Verified across four frontier models at fixed temperature:

- **29.3% of single-run evaluations produce an incorrect model ranking.** Roughly one in three single-run A/B comparisons puts the wrong arm on top.
- Agents produce **2.3-4.2 unique action sequences per 10 runs** on identical inputs.
- Tasks the agent approaches consistently (≤2 distinct paths) score **82-87%**; tasks it approaches inconsistently (≥4 paths) score **41-65%**. Behavioural spread predicts failure at AUROC 0.62-0.78.
- The paper recommends **k≥5 runs per task** for published agent benchmarks, reporting mean, variance, and confidence intervals.

That is a single unreplicated study and this repo cannot verify it. It is cited as the reason the rule below exists, not as settled fact. The rule stands on its own regardless: repeated runs cost little and a point estimate of unknown spread is not a measurement.

Rules for every round from R6 onward:

1. **k≥3 runs per task per arm; k=5 for any result that will be cited publicly.** The README's headline figure is a public claim — it needs k=5.
2. **Report median and range.** A `+16%` with no spread is not a finding. `median +16% (range +4% to +27%, k=5)` is.
3. **Report the per-arm spread separately from the SOP-vs-baseline delta.** If the two arms' ranges overlap, say so — that is the honest result, and it is more useful than a point estimate that survives to a badge.
4. **Do not use majority voting to pick a winner.** In multi-step agentic tasks the same paper measured majority voting at 0-2pp gain, because an early wrong turn propagates through the whole trajectory rather than being outvoted. Aggregate the *scores*, not the *trajectories*.

Retrospective honesty: R1-R5 results in `results/` stand as recorded and are labelled single-run. They are not restated, re-weighted, or deleted. Their limitation is now named here rather than left implicit.

### Frozen lite subset

Full rounds are expensive, which is why they run rarely, which is why SOP edits ship without measurement. A frozen subset fixes the incentive.

**Lite subset: tasks 05 (tonnage bug), 07 (skip exercise), 08 (keyboard buttons).** Chosen because each has produced a discriminating result before — task 05 is the spot check where the baseline actively regressed a prior fix, and 07/08 are where R5's model-capability shift showed up. Weighted toward the hard-but-solvable frontier, per LangChain's [Deep Agents benchmarking practice](https://www.langchain.com/blog/how-we-benchmark-deep-agents) (23 July 2026), which reports its own lite subset running "roughly 8x faster and 6x cheaper" than the full benchmark.

- **Lite subset is frozen.** Changing its membership invalidates comparison across SOP versions. Adding a task means starting a new series, recorded as such.
- **Run lite after any SOP edit that changes agent-facing instruction text. SHOULD, pending runner support.** Not yet enforceable: `run-multi-round.sh:15` hardcodes `TASKS=(5 6 7 8)`, which cannot express the {05, 07, 08} subset, and the script has no repetition parameter, so k>1 has no mechanism. Filed as P72. Until that ships, this is an intention, and sessions that skip it should say so rather than leave it implied.
- **Reserve full 8-task rounds for releases** and for any figure that will be published.

**Known exemption, recorded rather than implied:** the 2026-07-26 session that wrote this section changed agent-facing instruction text in `.claude/commands/update-sop.md`, `docs/sop/claude-agent-sop.md`, and `.claude/agents/sop-checker.md`, and did not run the lite subset. No runner existed to run it with. The first session to satisfy this rule will be the first one after P72 ships.

### Capability suite (deterministic, already present)

Alongside the end-to-end benchmarks, agent-sop has a capability suite — fast deterministic tests targeting one harness behaviour each, the analogue of LangChain's "capability suite… unit tests that each target a specific harness behavior like tool selection, memory, or file operations". It exists but was never named as such:

| Directory | Behaviour under test |
|-----------|---------------------|
| `state-transition-fixtures/` | Backlog tag transitions — illegal flips blocked, legal ones allowed |
| `drift-fixtures/` | Drift detection — commits not referencing a declared P-number |

These run in seconds and answer a different question from the benchmark: *did this SOP edit break an enforcement mechanism?* Run them on every SOP change. The benchmark answers *did this SOP edit change output quality?* and cannot be run that often. Do not conflate the two, and do not let a green capability suite stand in for a benchmark round.

### Isolation and Safety (MANDATORY)

**Benchmark agents must NEVER modify the real codebase.** These rules are non-negotiable:

- Each agent runs in a **git worktree** on a throwaway branch (`bench/sop-task-N` or `bench/nosop-task-N`)
- **No push to main or any shared branch.** Benchmark branches exist locally only.
- **No push to remote at all.** No CI triggers, no deploys.
- **No database access.** No production, staging, or shared test databases.
- **No dev server.** Pure code generation and test execution only.
- Worktrees are deleted after scoring.
- **Run strictly sequentially.** Never overlap agent batches on the same worktrees. Concurrent batches cause worktree contamination (confirmed in multi-round testing).
- Sequence: setup round N → run all agents → wait for ALL to complete → score → cleanup → setup round N+1.

### Task selection criteria

Tasks must:
1. Have objectively measurable outcomes (tests pass, lint clean, file exists)
2. Span different task types (refactor, test writing, feature, bug fix)
3. Be completable without DB access or running servers
4. Have clear acceptance criteria that a reviewer can score without subjectivity
5. Not require migrations or schema changes (no DB dependency)

## Scoring Rubric

Each task is scored across 7 dimensions (0-3 scale each, max 21):

| Dimension | 0 | 1 | 2 | 3 |
|-----------|---|---|---|---|
| **Correctness** | Broken / does not compile | Compiles but tests fail | Tests pass with minor issues | All tests pass, no regressions |
| **Pattern consistency** | Ignores existing patterns | Partially follows patterns | Mostly follows patterns | Perfectly matches existing conventions |
| **Completeness** | Task not attempted | Partial implementation | Most ACs met | All acceptance criteria met |
| **Code quality** | Significant issues (large functions, deep nesting) | Some issues | Minor nits only | Clean, idiomatic, well-structured |
| **File hygiene** | Wrong files modified, collateral changes | Some unnecessary changes | Minimal extra changes | Only the necessary files touched |
| **Context awareness** | No evidence of reading existing code | Read some relevant code | Good understanding shown | Deep understanding, reuses existing utilities |
| **Efficiency** | Excessive tool calls, circular exploration | Some wasted effort | Mostly efficient | Direct path to solution |

### Scoring process

1. Both outputs are reviewed **blind** (reviewer does not know which is SOP vs baseline)
2. A code-reviewer agent scores each dimension with justification
3. The reviewer also notes any **qualitative differences** (naming choices, error handling approach, test structure)
4. Token usage and tool call counts are recorded via `/usage` per-category attribution (Claude Code 2.1.174+) — the first-party measurement source. Session-metadata estimates (words x 1.3, chars / 4, the 1.7x read multiplier) remain acceptable as a cross-check only. Note that token counts are tokenizer-relative: Sonnet 5's tokenizer yields ~30% more tokens for the same text than 4.x-family figures (core SOP Section 15.5)

## Session-Hygiene Rubric (supplementary — measures cross-session value)

The code-quality rubric above measures what an agent ships for one task. It does not measure what an agent leaves for the next session. The SOP's second product — a project state the next session can pick up cleanly — is measured here.

This rubric is scored **after** the code-quality phase, using the same blind methodology. Run it when you want to measure SOP adoption discipline, not just single-task quality.

Each dimension is 0 or 1 (did the agent do this thing by session end?). Max 7.

| Dimension | 0 (not done) | 1 (done) |
|-----------|--------------|----------|
| **Test gate** | Session ended without running project tests (code projects) | Tests were run before stopping |
| **Backlog status update** | Task shipped but `Backlog.md` not updated | Relevant item marked `[SHIPPED - YYYY-MM-DD]` or `[IN PROGRESS]` appropriately |
| **Feature-map append** | `docs/feature-map.md` unchanged when a shipped feature should be recorded | Shipped item appended to feature-map |
| **Agent-memory capture** | Non-obvious decision, gotcha, or invariant discovered in the task but not captured | Entry appended to `docs/agent-memory.md` with date |
| **Build-plan batch log** | No entry in `docs/build-plans/phase-N.md` Batch Log for the work | Batch entry dated and appended |
| **project_resume.md snapshot** | Resume file unchanged or absent | Resume overwritten with current "what's done / what's next / blockers" snapshot |
| **docs/ commit** | Code committed without accompanying docs update | `docs/` changes committed in the same commit (or adjacent commit) as the code |

**Expected baseline result: 0/7** — a no-SOP agent has none of these files to update. This rubric is not comparative in the usual sense. It is a **demonstrative measurement** — it makes visible the continuity value that the code-quality rubric ignores entirely.

**Expected SOP result: 6-7/7** with a disciplined agent and `/update-sop` slash command. Failures typically indicate the agent treated the task as done at "code shipped" rather than at "session end checklist complete".

### How to run the session-hygiene phase

After the code-quality phase for each task:
1. Tell the agent the task is complete and ask it to run session end.
2. Observe (or have a scorer agent observe) whether each of the 7 dimensions was satisfied.
3. Record per-task scores. Aggregate across the benchmark.

The hygiene score is reported separately from the code-quality score — they measure different things. A high code score with a low hygiene score indicates an agent that ships good work but leaves no trail.

## Continuity Benchmark (optional — measures multi-session value)

Code-quality and hygiene rubrics both score single tasks. The SOP's third product — agents in session N+1 benefit from what session N recorded — requires a dependent task pair.

See `docs/benchmark/continuity-methodology.md` for the methodology and a sample task pair.

## Longitudinal Exhibit — what the SOP accumulates in a real project

This is not a benchmark — no A/B, no scoring. It is a measurement of the **artefacts a mature SOP project actually contains** that a no-SOP project would not. It makes the continuity value visible without re-running anything.

**Target project:** `hst-tracker` (now RepCanvas, mid-rebrand). Four months of SOP-following sessions from 2025-12 onwards.

| Artefact | hst-tracker count | What a no-SOP project has |
|----------|-------------------|----------------------------|
| Dated decisions in `docs/agent-memory.md` | **86** | 0 (no file exists) |
| Build-plan batch-log entries | **23** | 0 (no build plans) |
| `CLAUDE.md` Recent Work entries | **18** | 0 (no Recent Work section) |
| Commits touching `docs/` (separate from code) | **64** | Effectively 0 — docs changes interleaved or absent |
| Total lines across the four tracking files (CLAUDE.md, Backlog.md, agent-memory.md, feature-map.md) | **4,628** | 0 |

**What this means in practice:** a fresh Claude Code session opened in `hst-tracker` today has immediate access to:
- 86 specific decisions with dates and context ("why does muscle group display use `displayMuscleGroup()`?", "why is tonnage derived, not stored?")
- 18 summaries of prior sessions, each with commit references
- 23 batch-log entries tracing how the current phase's architecture emerged
- 64 audit points in git history where `docs/` changes were committed alongside code

A no-SOP project of equivalent size and age would have none of this. A fresh agent would re-discover each of those 86 decisions by reading code and guessing. Some would be re-discovered correctly; some would be reached incorrectly and the wrong pattern adopted.

**Why this matters for the SOP's value story:** the +16-33% benchmark scores capture what the SOP buys on a single task. The longitudinal exhibit captures what it buys over a project's lifetime: **discoverable decisions, traceable architecture, recoverable context**. These compound. A project with 6 months of SOP discipline is substantially easier for the next agent to contribute to than a project with 6 months of code commits and no tracking files — even when the code is identical.

This dimension is not visible in single-task benchmarks by construction. Single-task benchmarks end at "code shipped". The SOP's value ends at "project in a state the next session can pick up cleanly".

**Caveat:** this is an exhibit, not a proof. It does not show that the 86 decisions would have been re-discovered wrongly without the SOP; it shows only that they are present. To prove re-discovery failure, run the continuity benchmark.

### Aggregate scoring

After all tasks complete:
- Per-task scores compared (SOP vs baseline)
- Win/loss/draw tallied across dimensions
- Token cost delta calculated (does SOP context pay for itself in fewer tool calls?)
- Qualitative patterns summarised (what did the SOP agent do differently?)

## Task Inventory

| # | Task | Type | Complexity | Files | Lite subset |
|---|------|------|-----------|-------|-------------|
| 01 | Migrate TimeFilter to Pill component | Refactor | Low | 3 | |
| 02 | Write import preset unit tests | Test writing | Medium | 1 new | |
| 03 | Add dynamic page titles | Feature | Low | 2 | |
| 04 | Write utility function tests for `server/src/utils.js` | Test writing | Medium | 1 new | |
| 05 | Fix the tonnage calculation bug | Bug fix (vague prompt, needs data-model knowledge) | not recorded | not recorded | ✅ |
| 06 | Fix the Add Exercise button being hidden | Bug fix (CSS/layout, needs UI architecture) | not recorded | not recorded | |
| 07 | Add skip-exercise functionality | Feature (multi-file, data model, ceremony) | not recorded | not recorded | ✅ |
| 08 | Add Copy Last / Next buttons to the keyboard row | Feature (UI, design system) | not recorded | not recorded | ✅ |

Complexity and Files for 01-04 are the original round-1 estimates, preserved from `116be62`. The round-2 specs (05-08) never recorded either value, and the task files carry no file manifest, so those cells are marked unrecorded rather than backfilled with guesses. Fill them from a real round when one runs.

Tasks 01-04 were the original round-1 set; 05-08 were added for round 2 and are the harder, more discriminating specs — `run-multi-round.sh` pins `TASKS=(5 6 7 8)` for that reason. Four lettered variants (`task-A-tonnage.md` through `task-D-scroll.md`) exist as vague-prompt rewrites used in the R2 prompt-precision comparison.

See `tasks/` for full specs.

## Running the Benchmark

### Prerequisites

- hst-tracker repo cloned at `~/Projects/hst-tracker`
- All tests passing on current main (`npm test`)
- No uncommitted changes

### Setup

```bash
cd ~/Projects/agent-sop
bash docs/benchmark/run-benchmark.sh setup
```

This creates 8 worktrees (2 per task: sop + nosop variants).

### Execution

Run from a Claude Code session in hst-tracker:

```bash
# Each task pair runs as two parallel Agent calls with worktree isolation.
# See run-benchmark.sh for the exact prompts.
bash docs/benchmark/run-benchmark.sh run <task-number>
```

Or run all tasks:

```bash
bash docs/benchmark/run-benchmark.sh run-all
```

### Scoring

```bash
bash docs/benchmark/run-benchmark.sh score <task-number>
```

Launches a blind code-reviewer agent against both worktrees for the given task.

### Cleanup

```bash
bash docs/benchmark/run-benchmark.sh cleanup
```

Removes all worktrees and benchmark branches.

## Results

Results are written to `results/` as markdown files, one per task plus a summary.

## Future: Managed Agents Benchmark Harness

The local worktree approach has a contamination problem when running concurrent batches (confirmed in multi-round testing). The Claude Managed Agents API eliminates this by design:

**Architecture:**
```
For each task pair:
  1. Create SOP agent (full CLAUDE.md in system prompt)
  2. Create baseline agent (4-line stub in system prompt)
  3. Create two sessions, each mounting the repo as a github_repository resource
  4. Send identical user.message with the task prompt
  5. Stream events until session.status_idle
  6. Score via a third agent session with user.define_outcome + rubric
```

**Advantages over local worktrees:**
- Each session gets its own isolated container — no shared filesystem, no contamination
- Repos mounted read-only (no push token) enforces safety at the infrastructure level
- `user.define_outcome` with scoring rubric automates blind evaluation
- Token usage tracked precisely via `usage` fields in events
- Concurrent execution is safe — sessions are fully isolated

**Permission policy config for benchmark agents:**
```json
{
  "type": "agent_toolset_20260401",
  "default_config": {
    "permission_policy": {"type": "always_allow"}
  }
}
```
No `git push` possible when the GitHub token is read-only. No deploy possible when there's no CI integration.

**Prerequisites:** Claude Managed Agents API access (beta, enabled for all API accounts). Multi-agent features require research preview access.

## External validation

Independent evidence adjacent to this benchmark's claims (adjacent, not identical — neither study measures SOP presence directly):

- **Code cleanliness and agent cost** ([arXiv:2605.20049](https://arxiv.org/abs/2605.20049), controlled minimal-pair study, May 2026): on Claude Code with Sonnet 4.6, behaviourally-equivalent repo pairs differing only in cleanliness showed no change in solve rate, but the clean variant cut token-equivalent footprint by 7-8% and file revisitation by ~34%. Supports the thesis that structural hygiene lowers agent cost even when task success is unchanged.
- **Operator expertise and agentic coding** ([Anthropic Economic Research, 16 June 2026](https://www.anthropic.com/research/claude-code-expertise)): outcomes vary with operator expertise — consistent with this benchmark's Round 2 finding that vague prompts amplify the SOP-vs-baseline gap; structure raises the floor most where prompt precision is lowest.
- **Behavioural consistency and early-step divergence** ([arXiv:2602.11619](https://arxiv.org/abs/2602.11619), Mehta, July 2026): trajectory divergence concentrates at **step 2** — the initial repository exploration and query formulation — and the paper's recommendation is to improve first-step determinism through "standardized file discovery patterns, structured initial context gathering". That is a description of what `/restart-sop` does. The evidence is adjacent, not identical: the paper does not test SOP presence, and this benchmark has not yet measured trajectory variance with and without a standardised session-start read order. **That experiment is now cheap to run** — the lite subset with k≥5, scoring action-sequence diversity alongside the existing rubric — and would convert an argued mechanism into a measured one. Filed as a follow-up, not claimed as a result.

## Limitations

- Single codebase (hst-tracker). Results may not generalise to all project types.
- Same model for both conditions. SOP effectiveness may vary across model versions.
- No DB access means some task types (migration, API endpoints) cannot be benchmarked.
- Token counting is approximate (session metadata, not exact API counts) for local runs. Managed Agents API provides exact counts.
- Small sample size (8 tasks). Statistical significance is limited. This is directional, not definitive.
- **Rounds R1-R5 are single-run per arm.** Measured externally at a 29.3% rate of incorrect model ranking from single-run evaluation (arXiv:2602.11619). Treat every pre-R6 figure — including the +16% and +33% headline numbers — as a point estimate of unknown spread. The k≥3/k≥5 requirement above exists to retire this limitation from R6 onward; until an R6 runs, it is the most serious caveat on this page.
