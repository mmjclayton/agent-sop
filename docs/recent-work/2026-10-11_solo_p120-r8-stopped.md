# R8 stopped and P120 closed as superseded

**Date:** 2026-10-11
**Agent:** solo
**Commits:** a56b80e, 44245a7, 26fb9d4 and the receipt commit, on `feat/p120-r8-results`; ae53050 (PR #51, ship-sop session)

Matt reported the Codex usage limit had reset. A test call worked, P120 moved to in progress (a56b80e) and R8 started. The ship-sop session then recorded a pre-run design review on P120 (PR #51, ae53050). It found points 2, 5 and 6 not met: there is no common session-1 cut and no pre-agreed result threshold. Most importantly, session 2's target, `server/src/routes/logger.js`, is named in the context and SOP arms' file maps, so pair 5+9 cannot separate the arms. Matt decided to stop R8 and approved a redesign that tests session resume, now P121 and owned by the ship-sop session. R8 was stopped after 7 of 9 pairs had finished and before judging completed; no process or login copy remained. The partial `r8b` data is not a result and is not reported (44245a7). P120 is closed as WON'T, superseded by P121. The claim was narrowed so P121 can change `docs/benchmark/codex-bench.sh`.
