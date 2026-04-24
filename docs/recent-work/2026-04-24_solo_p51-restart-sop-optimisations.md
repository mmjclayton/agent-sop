# P51 `/restart-sop` optimisations + P49 sample 2

**Date:** 2026-04-24
**Agent:** solo
**Commits:** pending (to be added after commit)

Two prompt-level optimisations shipped to `/restart-sop` as P51 `[IN PROGRESS] [Iteration]`: parallel-reads execution note above Step 1 (Full Start), and targeted Backlog-read pattern (`grep -n` → `Read offset/limit`) in Step 5 and Step 2L. User-scope mirror updated. Dogfood AC pending next hst-tracker session, which doubles as P49 sample 3. Sample 2 captured this session at `docs/instrumentation/2026-04-24_update-sop-timing.md` — agent-side drafting dominates, command read cost is not the bottleneck. Batch 0.19 in phase-0 build plan.
