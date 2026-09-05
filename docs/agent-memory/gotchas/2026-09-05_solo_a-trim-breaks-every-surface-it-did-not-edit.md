# A trim breaks every surface it did not edit — grep the old step numbers before shipping

**Date:** 2026-09-05
**Agent:** solo

**The surprise.** The P105 trim renumbered the session-end steps and removed artefacts, and the four files being rewritten came out coherent. The coherence gate then found five other surfaces still pointing at the old shape: `setup.sh` scaffolding a removed file, `security.md` rule 11 citing Steps 3c/3d, the checker grepping a string the trim had deleted (so a check would FAIL on every correctly configured project), a tamper check dropped from the no-hooks path with the checklist asserting it still existed, and the checklist's own summary arithmetic. Two of the stale references were runtime messages the validator prints.

**Rule.** Before shipping a renumbering or a removal, grep the whole repo for the old identifiers (`Step 1b|Step 2a|Step 3[bcde]|Step 8b|Step 11|feature-map|Batch Log|Definition of Done`) and fix or justify every hit; expect-stdout fixtures pin messages, so the grep includes them. The compliance checker is executable prose: when the checklist changes, the agent that runs it changes in the same commit.
