# `/update-sop` timing — sample 2 of 3

**Date:** 2026-04-24
**Agent:** solo
**Session characteristics:** docs-only project (agent-sop itself), solo on main, 1 commit already in `SESSION_RANGE` from prior session (P49 filing) + this session's uncommitted work, session diff 2 files / 52 LOC, [Iteration] tag (no reviewer-turn), one new decision file, one new batch log entry, one new `recent-work` entry.

## Per-step wall-clock

Same methodology as sample 1 — shell-side `date +%s` wrappers around tool-execution steps. Agent-side thinking/writing time is observed but not mechanically measured; estimates in the "agent-side" rows are the perceptible time spent drafting before the final write.

| Step | Description | Wall-clock (s) | Ran or no-op? | Notes |
|------|-------------|----------------|---------------|-------|
| 0 | Resolve agent-id | 0 | ran | `solo` — trivial |
| 0a | Resolve commit range | 0 | ran | `8792fc4..HEAD` — includes 1 prior-session commit |
| 1 | DoD self-eval | <1 | agent reasoning | Iteration rubric, 3 of 4 ACs met in session scope |
| 1b | Reviewer-turn threshold | 0 | no-op | P51 is [Iteration] → exempt |
| 2 | Tests | 0 | no-op | docs-only project |
| 2a | P-number collision check | 3 | ran | `git fetch origin --quiet` + compare P-sets |
| 3 | Update Backlog | 0 | already done in-session | P51 filed earlier in session |
| 3b | Secondary trackers | 1 | ran | detection scanned CLAUDE.md Key Documents, none matched |
| 3c | State-transition validator | <1 | ran | `validate-state-transitions: OK (0 warnings)` |
| 3d | Drift detection | <1 | ran | P49 referenced in commit range, declared in resume — clean |
| 4 | feature-map | <1 | no-op | nothing shipped |
| 5 | Decision file + agent-memory narrative | ~45 (agent-side) | ran | 1 decision file (~1.3 KB), 2 narrative edits (In-Flight + Completed Work) |
| 6 | Build-plan Batch Log | ~20 (agent-side) | ran | Batch 0.19 entry, ~900 chars |
| 7 | project_resume overwrite | ~15 (agent-side) | ran | per-agent file |
| 8 | recent-work entry | ~15 (agent-side) | ran | `2026-04-24_solo_p51-restart-sop-optimisations.md` |
| 8b | CLAUDE.md rollup refresh | <1 | ran | `bash scripts/refresh-rollup.sh` |
| 9 | MEMORY.md index | 0 | no-op | no new auto-memory files |
| 10 | Commit | ~5 | ran | stage + conventional commit |
| 11 | Reconciliation check + report | <1 | no-op | no secondary-tracker IDs in commits |

## Observations from sample 2

- **Gate/bash overhead stays small:** ~5 s total across Steps 0-3d + 8b. Matches sample 1. Not the bottleneck on docs-only sessions.
- **Agent-side writing still dominates:** Steps 5, 6, 7, 8 account for ~95 s of perceptible wall-clock. Same pattern as sample 1. One substantial write per step, even on a modest session.
- **Step 1b reviewer-turn did not fire again:** P51 was [Iteration], session diff was just under threshold anyway (52 LOC / 2 files). Still no data on reviewer-turn wall-clock from either sample. Sample 3 in hst-tracker is the only realistic chance of capturing that — target a [Feature] or [Refactor] ship there.
- **Command read cost is NOT the bottleneck:** the 24.7 KB `update-sop.md` file reads once at invocation. The ~100 s drafting cost swamps that by an order of magnitude. Trimming the command file would be cosmetic.
- **Cross-sample signal:** samples 1 and 2 are both solo docs-only. Variance between them is ~10 s at the drafting stages, not meaningful. Both point at the same dominant steps.

## What sample 3 still needs to cover

Code project (hst-tracker), solo, ideally a [Feature] or [Refactor] over threshold so Step 1b reviewer-turn fires. That's the only untested wall-clock slot — the subagent spawn + file-reading cost is the main unknown for P49's refactor-or-abandon decision.

## Cross-reference

- Decision file (this session): `docs/agent-memory/decisions/2026-04-24_solo_p51-safe-optimisations-before-full-trim.md`
- Sample 1: `docs/instrumentation/2026-04-20_update-sop-timing.md`
