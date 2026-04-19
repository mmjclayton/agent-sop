# P38 — R5 post-trim benchmark pilot

**Date:** 2026-04-17
**Agent:** solo

P38 — R5 post-trim benchmark pilot. 4 vague tasks against hst-tracker commit 1c73062 (same as R2). SOP 75/84 vs baseline 61/84 = +16% aggregate. 3 of 4 tasks won by SOP; task 08 flipped to baseline (scorer error on design tokens contributed — `--color-accent-light` is real, 87 occurrences in index.css). R2 was +33%; margin narrowed. Major drivers of narrower gap: Opus 4.7 baseline more capable than R2's 4.6 (nosop didn't crash on task 07, used correct tokens on task 08); subagent methodology not comparable to fresh CLI sessions; single round not statistically averaged. Spot check (task 05 tonnage) held strongly — baseline regressed the B1 fix which is the catastrophic miss SOP specifically prevents. Verdict: trim did not break SOP, but the +33% figure is not defensible post-trim without a fresh R6 on CLI sessions same-model-as-R2. README updated: badge changed to "directional +16% to +33%"; R5 section added with caveats; Key finding #5 qualified to R2-specific.
