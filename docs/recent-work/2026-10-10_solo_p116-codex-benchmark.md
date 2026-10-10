# R6: native Codex vs current Agent SOP (P116)

**Date:** 2026-10-10
**Agent:** solo
**Commits:** 97147f3, 645fae2 and fixes, on `feat/p116-codex-benchmark`

Matt decided the comparison runs and is scored on Codex under his ChatGPT login, which settled the cost cap and billing questions. `docs/benchmark/codex-bench.sh` runs each attempt as a fresh `codex exec` (`gpt-6-luna`, medium) with its own HOME and CODEX_HOME, then a blind Codex judge scores each acceptance criterion. The pilot found the lite subset's documented pin, hst-tracker 76b3b77, already ships tasks 05, 07 and 08; the subset was re-pinned to 814b3b5 and the 76b3b77 runs discarded. It also found and fixed Node, `.git` and database access differences in the isolated runs. Measured k=3, 18 runs: SOP median at or above native on every task, separated only on task 07 (+0.15, ranges do not overlap), core criterion 9/9 vs 6/9, at about 3.3x wall time and 4.8x output tokens. Review blocked the first harness for failures that could pass as results and found one judge arithmetic error (t7-native-r2, 0.70 reported vs 0.60 from its marks); the harness now computes scores, marks invalid runs, scrubs the environment and hardens git, and the R6 record was corrected. Codex login copies were deleted from the run homes and the main login confirmed working.
