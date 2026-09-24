# Review and continuity hardening

Status: Implemented and verified locally on fix/review-continuity-hardening. P110 remains IN PROGRESS until merge.

## Delivered contract

- Shared deterministic receipt validation in Agent SOP policy; ship-sop assembles
  receipts from reviewer/test results. Markdown stamps are informational.
- Receipts bind base, head, tree and policy; missing reviewers, failed tests,
  blocking findings and malformed configured policy cannot qualify.
- Executable instruction Markdown invalidates coverage. Receipt-only commits do not.
- Main-worktree identity survives worktree-count changes. Digest storage separates
  ambiguous old slugs; explicit legacy migration retains originals.
- Local presence and bounded cross-worktree handoffs improve discovery. Explicit
  cooperative claims protect task/path ownership; one writer per worktree.
- Codex reviews retain actual usage events and bounded execution metadata. No
  cheaper default reviewer/model is selected without measurements.
- One coordinating close-out; retired duplicated instructions and benchmark mandate.

## Integration

Upgrade both packages. Install/sync the current Agent SOP hooks before generating
receipts. The receipt tool must run from the trusted user installation. The shared
policy is still hosted in Agent SOP to avoid a circular installation dependency;
future packaging can move it behind a versioned standalone verifier.

Use reviewers.json as an array of name, version, model, verdict and findings.
Each finding contains severity, file, positive integer line and message. tests.json
contains status and evidence. PASS and justified NOT_AVAILABLE are accepted;
FAIL is not. The validator recomputes thresholds rather than trusting summary prose.
Version/model are provenance labels supplied from real runs, not signed identities.
Local receipts are not an adversarial security boundary against their own author.

## Verification and remaining measurement

All nine Agent SOP fixture suites, ship-sop installation/receipt checks, lint and
the real cross-package receipt test pass. Independent full-range findings were
corrected and the final corrections reviewed by every configured reviewer.
Evidence: `docs/reviews/20260908-hardening-ship-auto.md` and its validated JSON receipt.
Performance comparison follows Agent SOP docs/benchmark/evaluation-protocol.md.
A new paid model benchmark is not implied by passing mechanical fixtures.

## Budget decision - 2026-09-08

The user set a zero additional spending budget. The native-model comparison pilot
is deferred. Do not launch further paid model or reviewer calls. Use existing
evidence and local deterministic checks; no further spending approval is pending.
