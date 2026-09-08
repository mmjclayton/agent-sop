# Validated receipts and cooperative local ownership

**Date:** 2026-09-08
**Agent:** solo (Codex)
**Work item:** P110

The 2026-09-08 review reproduced false coverage from a BLOCK Markdown report and
lost continuity when worktree count changed. Receipt validation now checks the
reviewed Git range/tree, policy digest, required reviewers, verdicts, findings and
test evidence. Markdown coverage stamps are historical information only. The
shared verifier remains in Agent SOP for this release; ship-sop assembles receipts
through the trusted installed verifier. These local files are not a security
boundary against their own author.

Main-worktree identity is stable solo, linked worktrees retain path identity, and
resume storage uses a full root digest. Explicit migration preserves originals,
rejects ambiguous generations and archives an unambiguous old main hash before
subsequent session closure. Root moves still need explicit reconciliation.

Writer/task/path claims live in the common Git directory and require explicit
release. Presence expires independently after 30 minutes. Claims are cooperative
and local to linked worktrees, not distributed locks. One writer per worktree and
one coordinating writer for shared records remain required. Handoff symlinks are
excluded. Context changes produce small refresh notices rather than full replay.

Keep all configured reviewers until controlled measurements establish their
incremental value. Usage telemetry and the evaluation protocol support that next
decision; fixture success is not evidence of lower total model cost.
