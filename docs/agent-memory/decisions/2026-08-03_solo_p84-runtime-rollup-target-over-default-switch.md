# Rollup target resolved at run time rather than switching the default

**Date:** 2026-08-03
**Agent:** solo

We chose run-time target resolution (explicit arg > `docs/RECENT-WORK.md` > `CLAUDE.md`) over simply repointing `scripts/refresh-rollup.sh`'s default at the new location, because the script ships to consumer projects via `setup.sh` and every one of them still keeps the rollup in `CLAUDE.md`. A hard switch would have fixed agent-sop and broken every consumer on their next `/update-sop`.

Batch 0.30 moved the rollup out of `CLAUDE.md` to stop it consuming per-session context — a good change — but left `refresh-rollup.sh:24` defaulting to `CLAUDE.md`, so the script exited 1 on every invocation and `/update-sop` Step 8b died with it. Compliance checks M5 and C13 went red at the same time for the same reason.

The general shape: when a file's canonical location changes in a component that is *vendored downstream*, resolution belongs at run time until every consumer has migrated. A flag day needs a migration mechanism, and this repo's sync is pull-based with no way to force one.

Related: P84. Applied the same reasoning to C13, M5 and the Step 8b verify line, which all hardcoded `CLAUDE.md`.
