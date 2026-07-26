# S7's PASS condition is tag-agnostic, not tag-gated

**Date:** 2026-07-26
**Agent:** solo

We chose to make check S7 grant PASS on **evidence of declaration** (a `docs/reviews/` artifact **or** an explicit Batch Log exemption note) over gating it on the item's **status tag** being `[Iteration]`/`[Refactor]`, because Step 1b exempts `[Bug]` and `[Iteration]` from the reviewer turn, so a tag-gated PASS demanded an artifact that the SOP's own workflow could not produce.

## What was wrong with the first cut

P69 shipped S7 requiring, for a validator change, that the item be "a declared `[Iteration]` or `[Refactor]` Backlog item carrying its own review artifact". `docs/sop/security.md` rule 11 told agents to ship validator changes as `[Iteration]`.

`.claude/commands/update-sop.md:125` scopes Step 1b to items shipping as `[Feature]` or `[Refactor]`, and `:162` states plainly that "Bug fixes, Iterations, and items under threshold are exempt". An agent doing exactly what rule 11 said produced no artifact, and landed in a state that was neither PASS nor FAIL. The undefined middle was the single most likely real-world case.

The reviewer turn caught it (`docs/reviews/2026-07-26_solo_P67-P69.md`, HIGH #2).

## Why tag-agnostic rather than widening Step 1b

The alternative fix was to extend Step 1b's trigger set so `[Iteration]` fires the reviewer turn when trigger (b) SOP self-modification matches `scripts/validate-*.sh`. That is arguably the more correct long-term shape, and it is what P66 is about.

Rejected for now on scope: widening Step 1b changes when the reviewer turn fires for every consumer project, which is a behaviour change well beyond P69's declared scope, and it would have shipped unreviewed inside the same diff the reviewer was reviewing. The tag-agnostic PASS achieves the same outcome — declared changes pass, undeclared ones fail — without touching gate-firing behaviour.

Rule 11 was amended in the same pass to prefer `[Refactor]` where the change is substantive, so the artifact path is the default rather than the exception, and to require an explicit Batch Log note when an exempt tag is genuinely right.

## The general lesson

**A check's PASS condition must be reachable by following the project's own documented workflow.** Writing a gate whose satisfying evidence the workflow never generates does not produce compliance; it produces an undefined verdict, and undefined verdicts get resolved in whichever direction is cheapest for the agent under pressure. That is the exact failure mode `docs/sop/security.md` rule 11 exists to warn about, so shipping it inside rule 11's own enforcement arm was a sharp lesson.

Related: [[P66]] (validator vs Step 1b skip-list divergence) is the same cross-layer pattern, now with a second confirmed instance.
