# Review leftovers closed: dry-run, action pin, gating line (P118)

**Date:** 2026-10-10
**Agent:** solo
**Commits:** a3ee6b8, bde0ff2 and close-out, on `fix/p118-review-leftovers`

Matt asked for the three follow-ups left from the independent review. `install-hooks.sh --dry-run` no longer creates a settings file (fixture `installer-dry-run-writes-nothing`, failing against 6578ac0). CI pins `actions/checkout` to the v4.4.0 commit SHA. README states that an instruction-file change needs a receipt whatever its size when an enabled reviewer is in scope. Round one of review passed but found that the new missing-file path let a directory at the settings path report success with nothing written, and that an empty settings file reported up to date; bde0ff2 refuses a non-file settings path, reads an empty file as `{}`, checks `mv` and backup `cp`, and adds three fixtures. Three reviewers, one launch and two re-checks each, all PASS. Accepted LOWs are in the review report.
