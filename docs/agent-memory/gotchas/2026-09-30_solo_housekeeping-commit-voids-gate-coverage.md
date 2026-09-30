# A housekeeping commit can void the ship gate's coverage

**Date:** 2026-09-30
**Agent:** solo

**Surprise:** after a validated receipt covered `783cfe7`, the session-end commit (`2f7babf`: session record, Backlog tags, the receipt itself) put the branch back to "no gate report", and the branch was pushed in that state.

**Prior expectation:** a docs-only commit sits outside the gate, so a receipt for the last code commit covers the branch.

**Why:** `scripts/refresh-priorities.sh` rewrites the priority block in `CLAUDE.md`, and `CLAUDE.md` is an instruction file. `sop_shipsop_covered` treats any instruction-file change after the receipt's head as uncovered, whatever the file's other content. The push gate did not refuse the push; the cause of that was not established.

**Rule:** run `sop_shipsop_gate` (or read the Stop hook's notice) after the session-end commit and before `git push`. When the close-out regenerates `CLAUDE.md`, the receipt must be written after that commit, not before, or the priority refresh must be committed before the reviewed code commit. A reviewer re-check of a docs-only delta is cheap; a push that outruns the gate is a record that has to be corrected afterwards.
