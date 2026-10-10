# R7: project instructions with and without agent-sop (P119)

**Date:** 2026-10-10
**Agent:** solo
**Commits:** 12ed1e6 and review fixes, on `feat/p119-context-control-arm`

Matt passed on an outside review of R6, which found that the arms differed in more than agent-sop. `setup.sh` keeps the project's own `CLAUDE.md` (300 lines, naming all three tasks at 814b3b5) and `docs/agent-memory.md`, while the native arm had a 5-line stub. Confirmed against hst-tracker and the harness; my earlier statement that R6 was enough to judge the SOP was wrong. Added a `context` arm (the project's `CLAUDE.md` as `AGENTS.md`, its memory, no agent-sop), ran 9 attempts, and re-judged R6's 18 with the current judge so all 27 are scored alike. Result: context and SOP overlap on every task (SOP minus context +0.08, -0.05, -0.05) with both at 9/9 on the core criterion. SOP took 2.2x the wall time and 2.1x the output tokens. Most of the R6 gain over the stub is reproduced by the project instructions alone; k=3 cannot separate context from SOP. Re-judging moved 10 of 18 R6 scores by 0.043 on average, so differences near 0.05 are judge noise. R6 summary now carries the confound note; the benchmark README points to R7. Multi-session tasks remain untested.
