# Round 5 (R5) — Post-Trim Light Benchmark

**Date:** 2026-04-17
**Target repo:** hst-tracker at commit `1c73062` (same as R2 — "Common Mistakes + intent-rich dispatch" state)
**Model:** Claude Opus 4.7 (1M context) — R2 used Opus 4.6
**SOP state:** Post-P36 (after trim, Rules 3-6 added, ~195 instructions)
**Methodology:** Subagent pilot from within a parent Claude Code session (not fresh CLI sessions). See Caveats below.
**Tasks:** 4 (same vague tasks as R2: 05 tonnage, 06 scroll, 07 skip exercise, 08 keyboard buttons)

## Why this benchmark

- Validate that the P32-P36 trim (pre-trim ~230 instructions → post-trim ~195) did not compromise SOP performance.
- Detect regressions early before the trim was benchmark-validated.

## Results

| Task | SOP score | Baseline score | Delta | R2 delta | R5 vs R2 |
|------|----------:|---------------:|------:|---------:|----------|
| 05. Tonnage bug (spot check) | 18/21 | 8/21 | **SOP +10** | SOP +9 | Consistent |
| 06. Scroll padding | 20/21 | 17/21 | **SOP +3** | Draw (16/21 each) | SOP wider |
| 07. Skip exercise | 21/21 | 15/21 | **SOP +6** | SOP +9 | Narrower |
| 08. Keyboard buttons | 16/21* | 21/21 | **Baseline +5** | SOP +10 | **Reversed** |
| **Aggregate** | **75/84 (89%)** | **61/84 (73%)** | **SOP +16%** | **SOP +33%** | **Margin halved** |

*Task 08 SOP score corrected by +1 after verifying scorer's deduction was wrong (scorer penalised SOP for using `--color-accent-light`; this token does exist in index.css, 87 occurrences). Scoring artifact from incomplete token list in my scorer prompt.

## Record

- R5: SOP 3 wins, 0 draws, 1 loss
- R2: SOP 3 wins, 1 draw, 0 losses

## Interpretation

1. **SOP still wins aggregate by +16%, but margin roughly halved from R2's +33%.**
2. **Drivers of the narrower gap:**
   - **Baseline was more capable this run than R2.** Task 07 baseline didn't crash (R2's did). Task 08 baseline used real design tokens (R2's invented non-existent ones).
   - **Model difference.** R2 used Opus 4.6; R5 used Opus 4.7. Opus 4.7 may itself produce stronger baseline output.
   - **Subagents inherit parent-session capabilities** — they are not fully fresh like CLI sessions.
   - **The trim may have genuinely reduced some SOP edge** — task 08 (which R2 scored 21/21 SOP win) flipped in R5.
3. **Spot check held strongly:** task 05 showed SOP +10 (baseline actively regressed the B1 fix — a user-visible breakage). This mirrors R2's catastrophic-miss prevention evidence.

## Caveats — why this is directional, not authoritative

- **Subagent methodology:** each condition ran as a subagent launched from an active parent Claude Code session. This is NOT identical to a fresh `claude` CLI invocation. Subagents share the parent's prompt cache and tool configuration. Fresh CLI sessions may produce different (likely more variable) outputs.
- **Scorer ran in the same session.** Although outputs were labelled A/B without revealing condition, the scorer was not a truly independent reviewer.
- **One round only.** R2 was itself a single round; P23 explicitly observed baseline quality is stochastic (baseline crashed in R2 but matched SOP in R4). Averaging across 2+ rounds is needed for statistical validity.
- **Model mismatch with R2** (4.7 vs 4.6). Strictly not apples-to-apples.
- **Task 08 scorer error** on `--color-accent-light` — corrected manually after verification.

## Conclusion

The trim did not break the SOP. It still provides a meaningful edge over a no-SOP baseline and still prevents the most diagnostic failure mode (task 05 regression). However, the margin is narrower than R2's +33% claim, and the methodology here is too compromised to say with confidence whether the narrowing is real or measurement artifact.

**The +33% figure should not be cited unconditionally for the post-trim SOP** — it was measured against pre-P32 SOP with a less capable model baseline. The honest post-trim figure is "directionally positive, pilot-measured +16% on a light benchmark with methodology caveats." For a definitive number, run the full-framework R6 against pre-rebrand hst-tracker with fresh CLI sessions, same model as R2.

## Artefacts

- Task prompts: `docs/benchmark/tasks/task-05..08-*.md` (unchanged)
- Base commit: hst-tracker `1c73062`
- Ephemeral worktree: `/tmp/bench-hst` (deleted after run)
- Session log: parent Claude Code session, 2026-04-17
