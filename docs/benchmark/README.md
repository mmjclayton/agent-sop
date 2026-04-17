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
4. Token usage and tool call counts are recorded from session metadata

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

| # | Task | Type | Complexity | Files |
|---|------|------|-----------|-------|
| 1 | Migrate TimeFilter to Pill component | Refactor | Low | 3 |
| 2 | Write import preset unit tests | Test | Medium | 1 new |
| 3 | Add dynamic page titles | Feature | Low | 2 |
| 4 | Write WorkoutLogger utility tests | Test | Medium | 1 new |

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

## Limitations

- Single codebase (hst-tracker). Results may not generalise to all project types.
- Same model for both conditions. SOP effectiveness may vary across model versions.
- No DB access means some task types (migration, API endpoints) cannot be benchmarked.
- Token counting is approximate (session metadata, not exact API counts) for local runs. Managed Agents API provides exact counts.
- Small sample size (4 tasks). Statistical significance is limited. This is directional, not definitive.
