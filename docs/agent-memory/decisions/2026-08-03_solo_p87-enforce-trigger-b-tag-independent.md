# Trigger (b) enforced and made tag-independent, rather than downgraded

**Date:** 2026-08-03
**Agent:** solo

We chose to give Step 1b trigger (b) a real execution arm **and** make it fire regardless of item tag, over the cheaper option of downgrading `claude-agent-sop.md:410` to advisory prose, because the tag exemption — not the missing pathspec — turned out to be the larger hole.

The framing that survived contact with evidence: trigger (b) had no implementation anywhere (`update-sop.md` implemented diff-size only; the validator did zero path inspection), so the SOP's one unconditional gate was satisfiable by a self-declared `docs-only` token no code verified. Downgrading would have been one honest line. But the sessions that most needed a reviewer on those paths — P75, and this session's own P84 and P92 — all shipped as `[Bug]` or `[Refactor]` and were **exempt by tag**, so enforcing trigger (b) as written would still have caught none of them. The reviews that ran anyway, discretionarily, found a HIGH (a fail-open I had just introduced) and two CRITICALs (one of them latent in `refresh-rollup.sh` since 2026-04-19).

Tag is a poor proxy for risk on the surface the agent itself executes. So the gate keys on the pathspec, not the tag, and `docs-only`/`below-threshold` are rejected there — accepting either would reinstate exactly the loophole trigger (b) exists to close.

**Cost accepted:** every future `[Feature]`/`[Refactor]`/`[Bug]` touching `docs/sop/**`, `.claude/**` or `scripts/validate-*.sh`, in this repo and in every consumer, now owes a review artifact. On a repo doing two commits a month that is cheap; on a busier consumer it may not be, and `review_loc_threshold` does not soften it. Revisit if a consumer reports the cost as real.

Related: P87, P84, P92, P95, and [[2026-08-03_solo_exit-code-fixtures-cannot-see-a-silent-failure]].
