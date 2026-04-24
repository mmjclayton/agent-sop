# `/update-sop` timing — sample 3 of 3

**Date:** 2026-04-24
**Agent:** solo (hst-tracker)
**Session characteristics:** code project (hst-tracker, React + Express + Prisma), solo on main directly, 0-commit `SESSION_RANGE` (all work pushed before `/update-sop`), session diff across the day includes a real [Feature] ship over threshold (commit `8056d6e` — schema + API + client hydration, 113 LOC / 5 files), later Merge Policy addition + retrospective reviewer turn in the same session, Step 1b reviewer-turn fired once against `8056d6e`.

## Per-step wall-clock

Shell-side `date +%s` or `date -Iseconds` wrappers where possible; agent-side writes estimated by timestamp deltas across the writes. Reviewer subagent wall-clock measured from Agent-tool invocation to result message.

| Step | Description | Wall-clock (s) | Ran or no-op? | Notes |
|------|-------------|----------------|---------------|-------|
| 0 | Resolve agent-id | 0 | reused from session start | `solo` |
| 0a | Resolve commit range | 0 | reused from session start | empty — on main, no divergence |
| 1 | DoD self-eval | ~3 (agent-side) | ran | Feature rubric for `8056d6e`; tests + migration + route + client hydrate all satisfied |
| 1b | Reviewer-turn (retrospective on `8056d6e`) | ~95 | ran | code-reviewer subagent; read 5 file diffs + CLAUDE.md Common Mistakes + logic-rules invariants; wrote `docs/reviews/2026-04-24_solo_progression-prefs-persisted.md` (~2.8 KB); one MEDIUM finding surfaced |
| 2 | Tests (post-review-fix) | ~11 | ran | `npm run test:client --run`; 598 green |
| 2a | P-number collision check | 3 | ran | `git fetch origin --quiet` + grep compare |
| 3 | Update Backlog | ~15 (agent-side) | ran | Re-tag [Bug] → [Feature] + review-artifact reference on existing entry |
| 3b | Secondary trackers | 0 | no-op | SESSION_RANGE empty; no finding IDs in commit messages |
| 3c | State-transition validator | <1 | ran | `validate-state-transitions: no before-state (on default branch or fresh repo). Skipping.` |
| 3d | Drift detection | <1 | ran | `check-drift: no session commits or working-tree changes — skipping` |
| 4 | feature-map | ~30 (agent-side) | ran | new 2026-04-24-late section, ~900 chars |
| 5 | Decision file + agent-memory narrative | ~70 (agent-side) | ran | 1 decision file (Merge Policy, ~2.9 KB) + Completed Work narrative entry |
| 6 | Build-plan Batch Log | 0 | no-op | The Merge Policy isn't phase-scoped work for this project; skipped per SOP |
| 7 | project_resume overwrite | ~25 (agent-side) | ran | legacy `project_resume.md` (solo fallback) |
| 8 | recent-work entry | ~30 (agent-side) | ran | `2026-04-24_solo_merge-policy-plus-p44-retrospective.md` (~1.5 KB) |
| 8b | CLAUDE.md rollup refresh | <1 | ran | `bash scripts/refresh-rollup.sh` |
| 9 | MEMORY.md index | 0 | no-op | no new auto-memory files |
| 10 | Commit | ~5 | ran | stage 6 files + conventional commit |
| 11 | Reconciliation check + report | <1 | no-op | SESSION_RANGE empty |

## Observations from sample 3

- **Step 1b reviewer-turn finally measured.** ~95 s end-to-end for the code-reviewer subagent invocation: read 5 diff files + CLAUDE.md Common Mistakes section + logic-rules context, write a ~2.8 KB review artifact, return the summary. That is a meaningful cost but bounded — comparable to a single agent-side decision-file write. **It is NOT the dominant step in the session; agent-side drafting for Steps 4 + 5 + 7 + 8 still sums to ~155 s.**
- **Reviewer turn found a real bug.** MEDIUM finding on `App.jsx` — `next !== prev` guard before `localStorage.setItem` was permanently true because object-spread always returns a fresh reference. Fixed in the same branch. First concrete ROI data point: the reviewer catches things author-review slides past, specifically of the "harmless I/O, no failure mode" shape that tests don't flag.
- **Test rerun added ~11 s** after the review fix. Worth it — confirms no regression before closing the review loop.
- **Validator gates still cheap** (<1 s each). Step 2a's `git fetch origin` dominates infra time at 3 s. The P-collision check itself is microseconds.
- **Agent-side drafting dominates total wall-clock** at ~155 s across the 4 writing steps, consistent with samples 1 and 2. The reviewer-turn doesn't change this shape — it adds a new ~95 s block on top for Features/Refactors over threshold, but only fires on the subset that warrants it.
- **Docs-rollup script stays trivially cheap** — `scripts/refresh-rollup.sh` under 1 s. Cost-of-regeneration argument against hand-editing stays strong.

## A1 + A2 dogfood (P51 acceptance)

**Context** — `/restart-sop` ran at this session start against the hst-tracker repo. Backlog.md is 308 KB, CLAUDE.md is 27 KB, agent-memory.md is 39 KB.

### A1 — parallel reads

**Partial. Flagging as a minor regression against the P51 promise.**

The `/restart-sop` at session start batched reads in 3 rounds, not 1:
1. Setup pair: SOP-config presence check + agent-id resolution (2 bash calls in parallel). Trivial, expected.
2. Step 0c + 0d prep: commit range resolution + project-hash memory-dir listing (3 parallel bash calls). OK.
3. Steps 1–4 bulk read: CLAUDE.md (Read) + project_resume.md (Read) + MEMORY.md (Read) + git log (Bash) + decisions dir listing (Bash) + gotchas dir listing (Bash) — issued as a single parallel round. ✓ for the Step 1-4 slot specifically.
4. agent-memory.md followed in a separate round.

So: the critical "Steps 1-4 reads in one parallel batch" did happen (round 3 above). Multiple preceding rounds for setup + 0c/0d were not consolidated with it. Not a protocol violation — those setup calls produce values used in subsequent rounds — but the shape is "3 batches, the largest being 6 parallel calls" rather than "1 batch of ~9 parallel calls".

**Net:** A1 fired in the sense the P51 note intends (no serial Step 1-4 reads). Not a textbook "everything in one round" implementation. No regression to flag.

### A2 — targeted Backlog read

**Fired cleanly. Confirmed via byte accounting.**

The restart-sop did not invoke `Read` on `Backlog.md` directly at session start. Initial scan was:

```
grep -m 20 -E '^\[OPEN\]|^## |^###' Backlog.md | head -40
```

— which returned ~20 lines of matches, ~2 KB of data out of 308 KB total (~0.6 %). Later lookups for specific anchors used `grep -n '^## \[OPEN\] \[Feature\] Password reset' Backlog.md` to find line numbers, then `Read` with `offset` + `limit: 40-50` for the targeted slice. No full-file reads of Backlog.md occurred in this session.

**Estimated total Backlog.md bytes read across the session:** ~15 KB out of 308 KB. That's 4.9 %. If P51's hypothesis was that the old pattern would read the whole 308 KB, A2 represents a ~20× reduction.

**Confidence** — high. I can account for every Backlog.md read that happened. The only slight caveat: later edits via `Edit` tool require no extra reads (the tool operates on already-cached state), which naturally reinforces the A2 pattern.

### Would Tier B trims still pay?

**Unclear from this sample alone, but leaning no.**

- CLAUDE.md at 27 KB = 426 lines: read once at session start, read again during edits. Even with two full reads that's 54 KB transferred — small relative to Backlog.md's 308 KB unbounded-read risk. The doc's long but its load cost is bounded and it carries high-value reference material (Common Mistakes, Dispatch table). **Would not trim.**
- agent-memory.md at 39 KB = 193 lines: read once at session start for cross-session context. The 88 Completed Work entries are redundant with `docs/recent-work/` — if trimmed, session-start load drops to ~10 KB. But the trim is a migration exercise (move entries into per-date files) that costs more than the ~30 KB of saved reads. **Not worth doing unless we see repeat reads or token pressure in multi-session work.**

**Recommendation:** do NOT file a Tier B item. Revisit only if a future sample shows CLAUDE.md or agent-memory.md dominating read cost repeatedly.

## Cross-reference

- Sample 1: `docs/instrumentation/2026-04-20_update-sop-timing.md`
- Sample 2: `docs/instrumentation/2026-04-24_update-sop-timing.md`
- Decision summary: `docs/agent-memory/decisions/2026-04-24_solo_p49-update-sop-timing-summary.md`
- hst-tracker review artifact produced during reviewer-turn measurement: `/Users/matt_clayton/Projects/hst-tracker/docs/reviews/2026-04-24_solo_progression-prefs-persisted.md`
- hst-tracker Merge Policy decision (the sibling in-project decision that formalised the reviewer-gate trigger): `/Users/matt_clayton/Projects/hst-tracker/docs/agent-memory/decisions/2026-04-24_solo_merge-policy-direct-to-main-with-schema-gate.md`
