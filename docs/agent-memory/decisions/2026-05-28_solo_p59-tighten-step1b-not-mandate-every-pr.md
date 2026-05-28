# P59 — Tighten Step 1b with triggers + skip list, not mandate "every PR" upstream

**Date:** 2026-05-28
**Agent:** solo

## Decision

We chose to extend Step 1b with explicit triggers (size threshold / SOP-self-modification / project-declared paths) and a skip list (docs-only / test-only / dep bumps) over the brief's proposed mandate of "code-reviewer on every PR with code changes" because:

1. **The empirical evidence already cleared the existing gate.** The brief cited the hst-tracker 2026-05-28 composer-fix PR (220 LOC) as proof that the trigger model misses small-but-load-bearing changes. But upstream agent-sop is threshold-based (50 LOC / 3 files default), and 220 LOC is already above threshold — the upstream gate would have fired regardless. The bug the brief asked us to fix doesn't exist upstream.

2. **The brief's "four triggers" framing belongs in project CLAUDE.md, not the upstream SOP.** Those triggers (schema / auth / logic-rules / 300+ LOC) are hst-tracker's project-specific layering on top of upstream. Pulling them up just to deprecate them re-encodes project policy as the upstream default and creates the same coupling we've been trimming since P32.

3. **Skip list + zero-threshold mode is the actual missing capability.** Projects that observe a missed bug under default threshold need a low-friction way to lower the gate. Two missing pieces: (a) explicit skip-list so docs-only and dep-bump churn doesn't pay reviewer cost, (b) `review_loc_threshold: 0` semantics for "every Feature/Refactor with non-skipped paths." Both land in this PR.

4. **SOP-self-modification trigger is a real upstream gap.** Process docs that the agent itself executes are a known correctness hazard. Step 1b previously did not gate them at all (docs-only diffs are usually exempt from review). The new trigger (b) fires on any edit to files the SOP executes — SOP docs, reference agent definitions, slash commands, validators. This PR self-applies it (the trigger fires on this very PR's edit to `claude-agent-sop.md`).

## Why not the brief verbatim

The brief's framing of upstream as "Branch + code-reviewer subagent gate REQUIRED when… four trigger conditions" was incorrect — that text is in `~/Projects/hst-tracker/CLAUDE.md`, not in any agent-sop file. Carrying out the brief literally would have introduced a "Merge Policy" section to the upstream SOP with the four triggers, then immediately deprecated them in favour of universal "every PR" — net effect: more text upstream, more confusion downstream, no behaviour change for any project already running the 50 LOC threshold.

## Companion: cross-layer rules guide

Same session, same bug-class evidence (three May 2026 divergence bugs in one project). Codified into `docs/guides/cross-layer-rules.md` with inventory-first framing — the Duplicated-Logic Inventory is the load-bearing artifact; Tier A (unify) and Tier B (parity fixture) are how rows transition. Stripped RepCanvas-specific paths (`shared/rules/`, Vite alias, 95/90 coverage) in favour of generic pseudocode and platform-agnostic terminology.

## What's pending

- PR #6 open against agent-sop main; bundled with 7 catch-up commits from the unpushed 2026-05-04 session per user decision.
- ship-sop PR #2 open with a one-paragraph clarification of per-stop vs per-session reviewer-gate relationship.
- Backlog P59 stays `[IN PROGRESS]` until merge.
- Feature-map row to be added post-merge (Step 4 skipped this session per the skip predicate).

## Related

- Brief that prompted this work: hst-tracker `~/Projects/hst-tracker/docs/process-improvements.md` § 1 (reviewer on every PR) and § 4 (cross-layer logic).
- Reference impl that the new guide abstracts from: `~/Projects/hst-tracker/shared/README.md` (Tier A) and `~/Projects/hst-tracker/docs/fixtures/README.md` (Tier B).
- Review artifact: `docs/reviews/2026-05-28_solo_P59.md`.
