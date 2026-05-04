# P58 — Karpathy before/after pattern (extend across SOP)

**Date:** 2026-05-04
**Agent:** solo

Pattern proven by P25 (gotcha pedagogy: weak-vs-strong tonnage entry that prevented a benchmark agent removing a `Math.max` multiplier) and P48 (three pairs in `code-reviewer.md` Finding Voice — drop-list / keep-list / before-after). Deferred from P34 (2026-04-17); P55 sycophancy gate and the 2026-05-04 digest reinforced the principle that concrete examples beat abstract rules.

Applied to four reference surfaces:

**Core SOP** (`docs/sop/claude-agent-sop.md`):
- Rule 1 — one pair contrasting delete-on-deprioritisation vs in-place status flip with `Reason:` note. Addresses the most common Rule 1 misinterpretation.
- Rule 6 — one inline pair contrasting silent pick on a "tighten the validator" request vs surfacing three reads with a default and asking. Newest rule (P34), no pair until now.
- Net SOP body cost: **+474 bytes**. Self-imposed cap was +500 bytes. Two iterations of trim got under the limit.

**`planner.md`** Best Practices — two pairs:
- Vague refactor instruction vs concrete file-line step with explicit caller updates and named tests.
- "Phase 2: improve performance" vs phase with named endpoint, p95 target, two batches with file-line changes, and a load-test acceptance criterion.

**`security-reviewer.md`** Key Principles — two pairs plus a one-line cross-reference to the P55 substance-assertion principle:
- Hedged "there might be an SQL injection somewhere" vs specific file-line + exploit string + parameterised query fix.
- Vague "error handling could leak in some cases" vs specific file-line + exact field exposed + handler-level fix.

**`e2e-runner.md`** Common Failure Modes — one pair:
- Brittle `.btn-primary:nth-child(2)` selector vs `getByRole('button', { name: 'Submit order' })` with rationale.

Three reference agents mirrored to user-scope; baselines refreshed:
- `planner.md`: `538e0107` → `ffc63668`
- `security-reviewer.md`: `b881e3f8` → `4a2e7b73`
- `e2e-runner.md`: `42f9b262` → `86e2c0ad`

`code-reviewer.md` was skipped — already saturated with three pairs in Finding Voice. `sop-checker.md` was skipped — too mechanical to benefit from before/after framing.

Tracking: Backlog (P58 SHIPPED + Shipped Archive line), feature-map P58 row + last-updated, CLAUDE.md rollup, agent-memory Completed Work, project_resume_solo.

This closes both 2026-05-04 follow-ups Matt selected (P57 + P58); R6 stays deferred per the digest review. Five items shipped today total: P56 + P24 + P55 + P57 + P58.
