# P87 — Trigger (b) gets an execution arm

**Date:** 2026-08-03
**Agent:** solo
**Commits:** `eaa729c`, `dec7529`

The SOP called self-modification its one unconditional gate and had no implementation of it anywhere, so it was satisfiable by a `docs-only` token no code checked. Now enforced by pathspec in the validator, and made tag-independent: the tag exemption was the bigger hole, since P75 and this session's own P84/P92 work all shipped `[Bug]`/`[Refactor]` while the reviews that ran anyway found a HIGH and two CRITICALs.

Also closed P95's second half — a Batch Log citing a `docs/reviews/` path is not evidence until the path resolves. Batch 0.30 recorded that fail-open in prose and it was never fixed; I re-introduced the same false citation this session and the gate passed it. Suites: state-transition 18 → 20. Batch 0.33.
