# P59 — Step 1b reviewer-gate tightening + cross-layer rules guide

**Date:** 2026-05-28
**Agent:** solo
**Commits:** dd24ca3

Two upstream SOP tightenings prompted by hst-tracker 2026-05-28 composer-fix evidence. (1) Step 1b in `docs/sop/claude-agent-sop.md` gains explicit triggers (size threshold / SOP-self-modification / project-declared paths), explicit skip list (docs-only / test-only / dep bumps), `review_loc_threshold: 0` always-on-code semantics, and a `review_triggers: []` field in `docs/templates/agent-sop-config-template.json`. (2) New project-agnostic guide `docs/guides/cross-layer-rules.md` (~165 LOC) with inventory-first framing: Tier 0 grep is the load-bearing pre-step, the Duplicated-Logic Inventory is the load-bearing artifact, Tier A (unify) and Tier B (parity fixture) are how rows transition.

Cross-references: `CLAUDE.md` Key Documents row added; one entry in `docs/guides/sop-common-mistakes.md`. Companion 12-line clarification paragraph in `ship-sop/README.md` describing per-stop-vs-per-session reviewer-gate relationship.

Reviewer artifact at `docs/reviews/2026-05-28_solo_P59.md`. Self-applies the new SOP-self-modification trigger. Validator passes.

**Status:** PR #6 open (agent-sop), PR #2 open (ship-sop). P59 stays `[IN PROGRESS]` in Backlog until merge.

**Why not the brief verbatim:** the brief framed upstream as having a four-trigger model, but that's in `~/Projects/hst-tracker/CLAUDE.md`, not in any agent-sop file. Upstream is threshold-based (50 LOC default) and the cited 220 LOC PR would already have fired the existing gate. The actual upstream gap was skip-list + always-on mode + SOP-self-mod trigger. See `docs/agent-memory/decisions/2026-05-28_solo_p59-tighten-step1b-not-mandate-every-pr.md`.
