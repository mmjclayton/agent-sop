# R9 pilot - session resume test (P121)

2026-10-11. Harness `docs/benchmark/codex-bench.sh` (PR #53), tasks 10 and 11, hst-tracker 814b3b5, gpt-6-luna medium on the ChatGPT login. Raw runs stay outside the repository (`/tmp/p121-bench`).

## Status: incomplete, not a result

The Codex plan's usage limit was hit at 08:39 on 11 Oct 2026, part-way through the pilot ("try again at Nov 10th, 2026 8:04 AM"). Valid pairs: 3 of the 12 attempted across two harness builds, all in the `ask` end mode. No `sop`-arm pair completed. No pair was judged. Nothing here meets the threshold set in P121 (median gap of 0.10 or more with non-overlapping ranges, k of 5 or more).

| Pair | Harness | Session 1 + end turn | Session 2 | Session 2 first message |
|---|---|---|---|---|
| native, ask | 8d21e93 (final pilot) | 117 s + 4 s | 48 s | "I'll check the workspace and recent history to pick up the unfinished work." |
| native, ask | efe3277 (first build) | 59 s + 6 s | 32 s | "I'll check the workspace state and recent conversation context available to me..." |
| context, ask | efe3277 (first build) | 63 s + 19 s | 59 s | "I'll inspect the repository's resume notes, build plans, and recent history first..." |

## Observations (n = 1 per cell; read as a check of the harness, not as findings)

- **Mechanics work on real Codex.** The end turn resumed session 1's own thread (same `thread.started` id), wrote inside the project, and session 2 started fresh in the same files.
- **native:** both session 2s found the unfinished work from the code and built the client. Neither kept the two client decisions: RPE was added to every set, not only the last, and no "Track RPE" toggle was added. Session 1's end turn summarised the work in its reply but left no file recording the decisions.
- **context:** session 1's end turn wrote the decisions into `docs/project_resume.md`. Session 2 read the resume notes first and built RPE on the last set only, behind a "Track RPE" setting that defaults to off. This arm carries hst-tracker's own CLAUDE.md, which already includes the April agent-sop records routine, so it is not a no-process control.

## Cost (unverified)

Output tokens per pair, as reported in the events: native 13,364 and 10,902; context 17,908. The end turn's reported output (for example 5,202 after a 5,168-token session 1) suggests Codex reports a resumed thread's usage cumulatively, which would double-count session 1. Not yet verified; per-pair cost is not stated until it is. Input tokens were 1.6 to 3.0 million per pair, mostly cached context; the cached share was not separated here.

## Next

Resume when the Codex limit resets (10 Nov 2026 08:04): rebuild the template, re-run the six-pair pilot on the current harness (`BENCH_ARMS="native context sop"`, `BENCH_END_MODE=ask` then `closed`, `-k 1 --tasks "10+11"`), judge, verify the token accounting, report per-pair cost to Matt, then let him set k.
