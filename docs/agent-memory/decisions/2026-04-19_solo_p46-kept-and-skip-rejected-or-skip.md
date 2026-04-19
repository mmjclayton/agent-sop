# P46: AND-skip kept after reviewer suggested OR-skip — De Morgan

**Date:** 2026-04-19
**Agent:** solo

During P46 dogfood review, the `code-reviewer` subagent flagged the drift check's threshold-skip condition as "stricter than documented intent, inconsistent with P44." Reviewer's suggested fix: change `loc < T_loc AND files < T_files` to `loc < T_loc OR files < T_files`.

**Decision:** reject the fix. The original AND-skip IS correct.

**Reasoning:** P44 documents "either dimension exceeded fires the check" — OR-fire semantics. By De Morgan:
- `fire` iff `loc >= T_loc OR files >= T_files`
- `skip` iff `NOT(fire)` = `(loc < T_loc AND files < T_files)`

So AND-skip implements OR-fire. Changing to OR-skip would implement AND-fire, which requires BOTH dimensions over to trigger the check — strictly weaker (misses single-dimension-over cases).

Reviewer's worked example: "a 200-LOC single-file change is drift-checked" — that IS the correct behaviour for OR-fire (200 LOC is over the 50-LOC threshold, so the OR is true, so we fire). The reviewer seems to have read "stricter" as "bad" when it's actually "correct per the documented semantics."

**Code change:** kept AND logic; expanded the comment to show the De Morgan derivation so the next reader doesn't repeat the confusion.

**Lesson:** a reviewer being wrong on a logic call is normal — they're reading cold, one pass, under time pressure. The gate is still valuable: 6 of 7 findings were real defects and got fixed. The dogfood is net-positive even when the reviewer makes occasional errors, as long as the human-in-loop (or agent defending the design) can spot and rebut them. For future P44 review artifacts: include a short "reviewer found X, re-assessed as Y because Z" block for any rejected suggestion so the audit trail explains the disagreement.
