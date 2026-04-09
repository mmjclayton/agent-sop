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
