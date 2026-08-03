# P95 — The P92 review returned BLOCK, and it was right

**Date:** 2026-08-03
**Agent:** solo
**Commits:** `68a1a1f`

The reviewer turn on P92 returned BLOCK with two CONFIRMED CRITICALs in the script that had just shipped: a malformed end sentinel silently deleted the rest of the target file, and the parser could drop a real open item and then render "No open items" — a false claim rather than an error. Both reproduced independently before fixing.

The splice bug was also present in `scripts/refresh-rollup.sh`, live since 2026-04-19 and running on every `/update-sop` Step 8b; I had introduced it into the new script by copying the pattern. The first parser fix was itself wrong — strict adjacency moved the fail-open instead of closing it — and the new fixture suite caught that before it shipped. Also fixed: fence-awareness, an unparseable-Backlog signal, a comment claiming a guard that never existed, and GNU-only sed alternation that would have failed on BSD.

Filed but not fixed: Step 3c accepts a Batch Log citing a `docs/reviews/` path without checking the path resolves. Batch 0.32.
