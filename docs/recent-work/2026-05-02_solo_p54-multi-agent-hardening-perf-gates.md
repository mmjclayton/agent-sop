# P54 — Multi-agent hardening + perf gates + worktree advisory

**Date:** 2026-05-02
**Agent:** solo
**Commits:** 1f105b6, da279f6
**Pushed:** origin/main

Five tightenings on parallel-session safety and `/update-sop` perf, prompted by a hst-tracker code review where local SOP commands were 32-38% the size of pristine and missing all parallel-safety machinery.

`/restart-sop` Step 0a now prints a soft sibling-worktree advisory when `git worktree list` > 1 and any sibling has uncommitted changes — wipe hazard documented in `gotchas/2026-05-02_solo_worktree-uncommitted-wipe.md`. New `scripts/refresh-in-flight.sh` regenerates the `## In-Flight Work` section of `agent-memory.md` from per-agent files in `docs/agent-memory/in-flight/<agent-id>.md` (sentinel block in `agent-memory-template.md`); pre-migration projects keep flat-line discipline until they sync. `/update-sop` gains a parallel-batch instruction for Steps 4/7/8, plus skip predicates on Steps 4 (no `[SHIPPED]` tags added), 5 (substance gate for decisions/gotchas), and 8b (no new recent-work entry). `multi-agent-parallel-sessions.md` adds §7 Pre-flight (cross-worktree dirty-tree check, recovery via `git fsck --lost-found`) and §8 Assumptions (one Claude per worktree, sequential merges, branch-per-agent, no coordination protocol). `/update-agent-sop` manifest extended with `refresh-in-flight.sh` and the in-flight README; `setup.sh` seeds the new directory; README's cross-session memory + parallel sessions sections updated.
