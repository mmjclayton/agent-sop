# R7: does agent-sop add anything over the project's own instructions?

**Date:** 2026-10-10. **Backlog:** P119. **Harness:** `docs/benchmark/codex-bench.sh`. **Per-run data:** `r7-codex/`.

## Result

On these three single-session tasks, agent-sop added no measurable quality over the project's own instructions, and it took about twice the time.

- **Context vs SOP.** The context arm is Codex with hst-tracker's `CLAUDE.md` and `docs/agent-memory.md` and no agent-sop. Its ranges overlap the SOP arm's on every task, and the SOP arm's median is lower on two of the three. Both arms met the core criterion in 9 of 9 runs. The context arm used 813 s against 1,767 s and 60,785 output tokens against 130,497.
- **Context vs stub.** The gain R6 attributed to agent-sop comes from the project instructions. Context beat the stub-only native arm by +0.20 on task 07, where the ranges do not overlap. It met the core criterion in 9 of 9 runs against native's 5 of 9.
- **Multi-session value untested.** Dependent sessions, interrupted work and concurrent handoffs are what agent-sop is built for, and none of them were run.

| Task | Arm | Judge median | Range (k=3) | Core criterion met | Wall median (s) | Uncached input median | Output median |
|---|---|---|---|---|---|---|---|
| 05 tonnage bug | native (stub) | 0.83 | 0.50-1.00 | 2/3 | 52 | 28,880 | 3,453 |
| 05 tonnage bug | context | 0.83 | 0.83-1.00 | 3/3 | 77 | 58,500 | 4,806 |
| 05 tonnage bug | SOP | 0.92 | 0.92-0.92 | 3/3 | 133 | 78,338 | 10,913 |
| 07 skip exercise | native (stub) | 0.65 | 0.65-0.65 | 2/3 | 65 | 46,373 | 2,987 |
| 07 skip exercise | context | 0.85 | 0.80-0.90 | 3/3 | 138 | 86,148 | 11,012 |
| 07 skip exercise | SOP | 0.80 | 0.80-0.90 | 3/3 | 259 | 125,773 | 20,695 |
| 08 keypad buttons | native (stub) | 0.80 | 0.75-0.85 | 1/3 | 53 | 34,324 | 2,754 |
| 08 keypad buttons | context | 0.95 | 0.85-1.00 | 3/3 | 59 | 48,201 | 4,721 |
| 08 keypad buttons | SOP | 0.90 | 0.75-1.00 | 3/3 | 232 | 118,998 | 12,491 |

| Median difference | Task 05 | Task 07 | Task 08 |
|---|---|---|---|
| SOP minus context | +0.08 (overlap) | -0.05 (overlap) | -0.05 (overlap) |
| Context minus native | +0.00 (overlap) | +0.20 (no overlap) | +0.15 (overlap) |
| SOP minus native | +0.08 (overlap) | +0.15 (no overlap) | +0.10 (overlap) |

| Totals over 9 runs | Native (stub) | Context | SOP |
|---|---|---|---|
| Core criterion met | 5/9 | 9/9 | 9/9 |
| Wall time | 533 s | 813 s | 1,767 s |
| Output tokens | 27,153 | 60,785 | 130,497 |
| Input tokens (cached) | 4,264,604 (3,949,056) | 11,206,512 (10,629,376) | 26,717,201 (25,775,360) |

## Method

R7 uses the same template (hst-tracker 814b3b5), model (`gpt-6-luna`, medium) and login as R6. The SOP arm installs agent-sop main at d11e724.

- **Context arm (new, protocol condition 1).** The project's `CLAUDE.md` is copied verbatim to `AGENTS.md` and `docs/agent-memory.md` is kept. The April SOP copies the project shipped (`docs/sop/`, `.claude/`) are removed, and nothing is installed. Only agent-sop differs between this arm and the SOP arm, whose `setup.sh` keeps the same `CLAUDE.md` and memory.
- **Runs.** The 9 context runs ran on the revised harness (433a9ed plus the arm). The native and SOP runs are R6's 18 attempts, not repeated.
- **Judging.** All 27 attempts were judged in one pass by the current judge, so every arm is scored the same way. Scores are the mean of the per-criterion marks. The judge sees only product files, never process or SOP files.

## Judge noise

Re-judging the 18 R6 attempts with the current judge changed 10 of 18 scores. The mean absolute change was 0.043 and the largest was 0.15 (t8-native-r1). The packet changed only slightly between versions: an untrusted-data line and a marker for an empty diff. Most of this movement is the judge's own run-to-run variation. Differences of about 0.05 between arms are within it. R6's published figures used the earlier judge. R7's figures for the native and SOP arms differ from them for this reason; the attempts are the same.

## Limits

- **Small sample.** k=3, three tasks, one target repo, one model. The judge is the same model family as the agents.
- **Task IDs in the instructions.** The project's `CLAUDE.md` names the three tasks by ID with one-line descriptions, so both the context and SOP arms are told what is planned. That is realistic for this project but makes the tasks easier than a cold request.
- **Single sessions only.** Every task is one session. The protocol's dependent sessions, interrupted work, stale memory and concurrent handoffs, where agent-sop's records and claims are meant to pay off, were not run.
- **SOP overhead.** The SOP arm's extra time and tokens are process work its instructions require: reading the SOP, writing session records and, in some runs, review steps. That overhead applies to every task, so it belongs beside any quality claim.
- **No ship-sop arm.** Condition 4 (Agent SOP plus ship-sop) was not run.
- **R1-R5 unchecked.** The April rounds may share R6's wrong pin. Do not cite them until that is checked.
