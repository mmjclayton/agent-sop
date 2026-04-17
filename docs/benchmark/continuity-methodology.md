# Continuity Benchmark — Methodology

Last updated: 2026-04-17

The code-quality rubric scores what an agent ships. The session-hygiene rubric scores what an agent leaves behind. This methodology measures the third dimension: **does session N+1 benefit from what session N left?**

That is the core SOP promise — persistent cross-session context — and the single-task benchmarks do not measure it.

## Design

A **dependent task pair**: two tasks in sequence against the same worktree. Task 1 and task 2 are scored independently, but task 2 is designed so that an agent benefits from information task 1 naturally discovers and should capture in `agent-memory.md`.

| | Task 1 | Task 2 |
|--|--------|--------|
| **Prompt** | Fix the reported bug. | Fix the related bug. (No file path; no naming hints.) |
| **What happens mid-task** | Agent finds and fixes the reported bug. In the course of that, it also discovers an adjacent, related bug that is NOT in scope. | Agent must locate the adjacent bug. |
| **What task 1 records** | SOP agent: captures the adjacent bug in `agent-memory.md` Gotchas with specific file/function names, per Rule 1 extension (trace-to-request: the adjacent bug is relevant context for future work). Baseline agent: no `agent-memory.md` exists, nothing captured. | — |
| **What task 2 benefits from** | — | SOP agent: reads `agent-memory.md` Gotchas at session start (`/restart-sop` step 3), immediately identifies the file/function. Baseline agent: must re-discover from scratch. |

## A/B conditions

Same as the single-task benchmark:

- **SOP condition**: full CLAUDE.md, agent-memory.md, docs/sop/, reference agents.
- **Baseline condition**: stack-only CLAUDE.md stub. No agent-memory, no SOP docs.

Both conditions run task 1 and task 2 back-to-back in the same worktree. The agent-memory.md produced in task 1 (SOP) or absent (baseline) is the only state carried between tasks.

## Scoring

Task 1 is scored per the standard 7-dimension code-quality rubric. SOP and baseline are usually close — both agents can fix the reported bug.

Task 2 is where divergence surfaces. Score task 2 with emphasis on:

- **Time-to-identify** — tool calls before the agent lands in the correct file
- **Correctness** — did the agent fix the actual adjacent bug, not an unrelated issue
- **Context awareness** — did the agent reference the gotcha it (or the prior session) captured
- **Efficiency** — total tool calls to complete task 2

**Expected pattern:**

| Task 2 metric | SOP | Baseline |
|---------------|-----|----------|
| Tool calls to locate target file | 1-3 | 8-20 |
| Correct fix landed | Yes | Sometimes (may pick wrong candidate) |
| Agent mentions the gotcha by reference | Yes | No (nothing to reference) |

The delta between SOP and baseline on task 2 is the **continuity benefit**. It is usually much larger than the single-task delta, because task 2 exposes exactly what the baseline does not have: persisted cross-session context.

## Sample task pair

### Pair 1: Primary tonnage bug + adjacent server-side gap

Based on `docs/benchmark/tasks/task-05-tonnage-bug.md` and the known architectural gap that R2 surfaced.

**Task 1 prompt (identical in both conditions):**

> There's a bug with the tonnage calculation for exercises that have "count twice" enabled. The numbers are wrong — roughly double what they should be. Find the bug and fix it.
>
> Run the relevant tests after your fix and make sure nothing breaks.

**Expected task-1 outcome:**
- SOP agent: recognises prior B1 client-side fix is in place, identifies the server-side `logger.js` `/finish` and `/history` endpoints compute raw `weight * reps` without `countTwice` multiplier (the client/server discrepancy). Captures this as a Gotcha in `agent-memory.md` even if out of scope.
- Baseline agent: may fix the client (regressing B1) or may correctly diagnose the server-side gap, but has no memory file to capture it in.

**Task 2 prompt (identical in both conditions — issued after task 1 ships):**

> Fix the related bug in the workout summary totals.
>
> Run the relevant tests after your fix.

**Expected task-2 outcome:**

| Metric | SOP | Baseline |
|--------|-----|----------|
| Reads `agent-memory.md` first | Yes | No (doesn't exist) |
| Locates `server/src/routes/logger.js` without grepping | Yes, via captured gotcha | No, must grep |
| Tool calls before landing in correct file | 1-3 | 10-20 |
| Correct fix (adds `Math.max(wMult, rMult)` multiplier to server endpoints) | Yes | Varies |

## Caveats

- **Requires task 1 to succeed first.** If the SOP agent's task 1 doesn't capture the gotcha, task 2 becomes the same problem for both conditions.
- **Requires discipline.** If the SOP agent skips session end, the agent-memory.md isn't updated, and task 2 loses its advantage. This is a real-world variable — measure what actually happens, not idealised behaviour.
- **Task pair authoring is non-trivial.** The "related bug" must be discoverable-during-task-1 but not trivially visible from a fresh grep. The tonnage pair above works because the client/server split is architectural, not textual.
- **Single round is noise.** Same caveat as single-task benchmarks: run 2+ rounds or accept directional only.

## How to run

1. Set up worktree at target commit (same as single-task framework).
2. Run task 1 in SOP worktree and baseline worktree. Record task 1 scores.
3. Verify task 1 completed and, in the SOP condition, `agent-memory.md` was updated.
4. Run task 2 in the **same worktrees** (state carries forward). Record task 2 scores.
5. Compare task 2 outcomes. The delta between SOP and baseline on task 2 — beyond what task 1 alone showed — is the continuity contribution.

## What this benchmark does NOT measure

- Long-horizon continuity (sessions 5, 10, 20). Two tasks is a floor; real-world projects accumulate dozens.
- Value of `docs/feature-map.md`, `docs/build-plans/*`, `project_resume.md` in future sessions — task pairs only exercise `agent-memory.md`.
- Onboarding value (new contributor reading the files). That's a qualitative audit, not a benchmark.

For those dimensions, see the longitudinal exhibit in `docs/benchmark/README.md`.
