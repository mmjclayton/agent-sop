# R6: native Codex vs current Agent SOP (lite subset, k=3)

**Date:** 2026-10-10. **Backlog:** P116. **Harness:** `docs/benchmark/codex-bench.sh`. **Per-run data:** `r6-codex/`.

## Result

Agent SOP scored the same as native Codex or higher on all three tasks, by median. Only task 07 separates the arms: its ranges do not overlap. On tasks 05 and 08 the ranges overlap, so k=3 cannot separate the arms there. The SOP arm used about 3.3 times the wall time, 4.8 times the output tokens and 6.3 times the input tokens (96% of it cached).

| Task | Arm | Judge median | Range (k=3) | Core criterion met | Wall median (s) | Uncached input median | Output median |
|---|---|---|---|---|---|---|---|
| 05 tonnage bug | native | 0.92 | 0.50-1.00 | 2/3 | 52 | 28,880 | 3,453 |
| 05 tonnage bug | SOP | 0.92 | 0.83-0.92 | 3/3 | 133 | 78,338 | 10,913 |
| 07 skip exercise | native | 0.65 | 0.60-0.70 | 2/3 | 65 | 46,373 | 2,987 |
| 07 skip exercise | SOP | 0.80 | 0.80-0.90 | 3/3 | 259 | 125,773 | 20,695 |
| 08 keypad buttons | native | 0.75 | 0.60-0.85 | 2/3 | 53 | 34,324 | 2,754 |
| 08 keypad buttons | SOP | 0.95 | 0.65-0.95 | 3/3 | 232 | 118,998 | 12,491 |

Median difference, SOP minus native: task 05 +0.00 (ranges overlap), task 07 +0.15 (ranges do not overlap), task 08 +0.20 (ranges overlap).

"Core criterion" is acceptance criterion 1 of each task: the formula is corrected, the Skip Exercise option exists, or the three keypad buttons exist. SOP met it in 9 of 9 runs and native in 6 of 9. Both arms changed product code in every run. After every run, the harness's own test pass found 0 failures in either arm.

| Totals over 9 runs | Native | SOP |
|---|---|---|
| Input tokens (cached) | 4,264,604 (3,949,056) | 26,717,201 (25,775,360) |
| Output tokens (reasoning) | 27,153 (4,857) | 130,497 (58,598) |
| Wall time | 533 s | 1,767 s |

Billing: Matt's ChatGPT login through `codex exec`; no API spend. Token counts are what Codex reported in its `turn.completed` events.

## Method

- **Runtime:** Codex CLI 0.160.1, `gpt-6-luna` at medium effort, both arms. The configured default `gpt-6-astra` is refused on a ChatGPT login.
- **Isolation:** every run is a fresh `codex exec` with its own `HOME` and `CODEX_HOME`, holding only a copy of the login. The operator's instructions, memories, skills and hooks are absent from both arms.
- **Native arm:** the historical stack-only stub, written as `AGENTS.md`. `CLAUDE.md`, `docs/agent-memory.md`, `docs/sop/` and `.claude/` are removed.
- **SOP arm:** `setup.sh --runtime codex --code --force` from agent-sop main at d11e724. Its hooks run (`--dangerously-bypass-hook-trust`).
- **Target:** `hst-tracker` at 814b3b5, the commit that files B1, P57 and P62 before any of them is built. Baseline: 197 server and 289 client tests pass.
- **Order:** the 18 runs were shuffled and executed one after another (`r6-codex/plan.txt`).
- **Scoring:**
  - The harness re-runs both suites after each attempt.
  - A blind judge then scores each numbered acceptance criterion 1, 0.5 or 0, and the score is the mean. The judge is `gpt-6-luna` at high effort, in a fresh home, read-only.
  - The judge sees the task, the criteria, the harness test counts and the diff. Process and SOP files (`docs/`, `Backlog.md`, `AGENTS.md`, `CLAUDE.md`, `scripts/`, `.claude/`, `.agents/`, `.codex/`, `.review-*`) are removed from the diff.

## Corrections made during the pilot

- **Wrong pin.** The documented pin, 76b3b77 in `run-multi-round.sh`, already ships all three lite tasks: P57 in cd51d88, P62 in f126f7c and the B1 fix in e06d4a5. A SOP-arm agent reported that Skip Exercise was already present. The runs at that pin were discarded and the subset re-pinned to 814b3b5. This repo has not checked whether R1-R5 used the same pin.
- **Old Node.** Codex's login shell in an isolated `HOME` found Node v8.4.0 first. Each isolated home now gets the harness `PATH`.
- **No commits.** The sandbox blocked `.git`, so agents could not commit. `.git` is now a writable directory.
- **No database.** The sandbox blocked localhost, so agents could not run the server suite. That suite's setup uses the local `hst_tracker_test` database, so sandbox network access is on for both arms.
- **Judge arithmetic.** For t7-native-r2 the judge reported an overall of 0.70 while its own criterion marks average 0.60. Every `judge.json` now keeps the model's figure as `model_overall`, and `overall` is the criteria mean. That changes only this run; the table uses the corrected value. The revised harness computes the score itself.
- **Judge leak.** One SOP run (t7-sop-r2) left `.review-p57.*` clones in the project, which reached the judge as embedded-repo lines. They are now excluded. That run was re-judged blind: 0.80 both times (`judge-with-leak.json` is kept).

## Harness version

R6 ran on `codex-bench.sh` as committed in 645fae2. Review afterwards found failure modes that could have passed as normal results: a failed run, a test suite that never ran, and a judge score not computed from its marks. It also found isolation gaps around `.git`, the inherited environment and leftover login copies. The revised harness fixes these.

None of the failure modes occurred in R6:
- All 18 runs exited 0 with no timeout.
- Both suites reported counts at or above baseline in every run.
- Usage is present for every run.
- Every judge mark is 0, 0.5 or 1.

The one arithmetic error is corrected above. `valid` (Codex exit 0 and usage present) and `tests_ran` were added to each `result.json`; all 18 are valid, and none would be flagged `tests_suspect` (no suite exited non-zero). The revised harness was validated with one run per arm of task 05, which is not part of R6.

## Limits

- **k=3 is small.** The protocol expands repetitions based on observed variance. Task 05 native (0.50-1.00) and task 08 SOP (0.65-0.95) have the widest spread.
- **Same model family.** One model judges the work of the same model family. Its scores are not human ratings and were not calibrated against any.
- **Native keeps project docs.** The native arm keeps everything except the removed SOP paths, as the historical baseline did: `Backlog.md`, `README.md`, `docs/feature-map.md`, `docs/feature-inventory.md`, `docs/build-plans/` and three product documents. At 814b3b5, `Backlog.md` holds the B1, P57 and P62 specifications, so the native arm can find the same specification text the SOP arm reads.
- **Narrow scope.**
  - Lite subset only: three tasks, one target repo, one model.
  - Single-session tasks: the protocol's dependent sessions, interrupted work and concurrent handoffs were not run.
  - Conditions 2 (minimal card plus handoff) and 4 (Agent SOP plus ship-sop) were not run.
- **SOP extras.** The SOP arm's extra wall time and tokens include the work its instructions require on top of the task: reading SOP files, writing session records and, in some runs, review steps.
