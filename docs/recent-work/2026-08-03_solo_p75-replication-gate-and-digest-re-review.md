# P75 replication gate, plus a four-agent re-review that overturned most of the digest

**Date:** 2026-08-03
**Agent:** solo
**Commits:** `04d3722`, plus session-end housekeeping

**P75 shipped** (Batch 0.30). `--check-replication` added to `scripts/validate-state-transitions.sh`, invoked by new `/update-sop` Step 3e. It answers the question no existing gate asked: not "was this change declared?" but "did it reach the surface that enforces it?". The file list is the `baseline_shas` keys, so it reads the same source `/update-agent-sop` does rather than a second hardcoded list — acceptance criterion 3, and the bug class the item itself warns about. Two fixtures, count 15 → 17. Net +1 instruction; D1 was broadened rather than adding a check, so totals stay 85/94.

**It fired on its own shipping session.** Running `/update-sop` at session end, Step 3e blocked: the repo's `.claude/commands/update-sop.md` had gained Step 3e while `~/.claude/commands/update-sop.md`, the copy that actually executes in every session, had not. Mirror synced forward, five baselines refreshed. The gate's first live use caught a real instance of the exact drift it was written for.

**The digest re-review changed the outcome.** Four adversarial agents checked the initial reading of the 2026-07-30 digest, and overturned two of three rejections plus most of the proposed work. The digest's own repo spot-check was four days stale (91/82 against an actual 94/85), so its "Already addressed?" column was unreliable throughout. Of five findings, one survived: the 1M context-window drift, real and unfixed at `harness-configuration.md:53`, where `120K tokens (60% of 200K)` was 5x wrong on an Opus 5 default. Fixed proportionally rather than re-pinned. Two findings were already shipped, one would have reversed a reviewed `[WON'T]`, and one asked for a control that would not have contained the incident it cited, since the escape ran through a *permitted* egress point.

Four of the original proposals were dropped on the reviewers' evidence: a `/doctor` pass whose rule already exists three times over, a duplication check that would have flagged what C15 mandates, and a positioning passage that P68 had already shipped with the opposite inference.

**Also fixed:** `Backlog.md:1311`'s false "flipped twice in three releases", prescribed by a review a week earlier and only half-applied; a dead "file P53" reference that would have caused a P-number collision; and `print_help`'s hardcoded `sed` range, which had drifted past the comment block.

**Filed P76-P82:** checklist ID collisions, the orphaned P32 trim (the soft cap has been breached since April and the work was never given a P-number), the rescoped divergence check, the sandboxing clause, the benchmark rubric upgrade, the measurement-inert lite-benchmark rule, and a Step 2a collision check that fails open when its awk call errors.
