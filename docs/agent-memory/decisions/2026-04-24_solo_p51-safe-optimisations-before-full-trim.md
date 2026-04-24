# P51 — ship safe `/restart-sop` optimisations before completing the P49 measurement programme

**Date:** 2026-04-24
**Agent:** solo

## Context

Matt reported `/restart-sop` and `/update-sop` feel slower in hst-tracker than in agent-sop and asked for factual analysis, not opinion. Measurement found two separable causes:

1. **Justified:** hst-tracker's default-loaded state is ~4x larger than agent-sop's — `Backlog.md` 305 KB vs 63 KB, `agent-memory.md` 38 KB vs 7 KB, `CLAUDE.md` 25 KB vs 8 KB. Real project accumulation, not command bloat.
2. **Partially fixable in the command prompt itself:** Step 5 told the agent to "read the specific Backlog item(s)" without giving a pattern, so agents routinely loaded the full `Backlog.md` to find a ~40-80 line item. Steps 1-3 were presented serially though their reads are independent.

The first cause belongs to P49's measurement programme (sample 2 should be in hst-tracker with the new pattern active). The second is a prompt-wording fix that doesn't depend on measurement and is low-risk in isolation.

## Decision

Ship P51 now. Two prompt-level changes to `/restart-sop`:
- **A1:** parallel-reads execution note above Step 1 of Full Start. Steps 1-4 reads/shell calls are independent; should be issued as a single parallel batch.
- **A2:** targeted Backlog-read pattern (`grep -n` anchor → `Read offset + limit`) in Step 5 (Full) and Step 2L (Lightweight). Full-file read preserved as fallback on grep miss.

No changes to `/update-sop` this session. P49 is still gathering timing data there, and the update path already uses `git diff` / targeted `awk` + `grep` against `Backlog.md` rather than full `Read` calls — A2 does not apply.

Hold Tier B (hst-tracker `CLAUDE.md` + `agent-memory.md` trims) until P49 sample 2 confirms those files are still hot after A1 + A2 land. Don't pre-emptively trim without the measurement.

## Why not defer P51 too

P49 measures `/update-sop`. P51 changes `/restart-sop`. The two commands and their steps are distinct — P49's data doesn't tell us anything about Step 5 of restart, because `/update-sop` doesn't have a Step 5 that reads Backlog.md by item. Coupling them delays the obvious win and muddles the measurement (harder to attribute a wall-clock change in update-sop to a change in restart-sop).

## Safety

Both changes are prompt wording. Reversible in one edit. A2's failure mode (grep miss → no item found) is immediate and visible; the agent re-reads with a wider window. No silent regressions possible.

## What happens next

1. Next `/restart-sop` in hst-tracker dogfoods A1 + A2 and closes P51's last AC.
2. That same session records P49 sample 2 — hst-tracker is a code project with active work, so Step 1b reviewer-turn will fire there if a Feature ships. Exactly the shape we need for P49's variance.
3. If sample 2 shows `agent-memory.md` read as still-hot: file a new P-item for hst-tracker's Completed Work migration (same pattern agent-sop shipped 2026-04-19 via P43 Batch 1.6).
