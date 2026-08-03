# A digest can report stale repo state while claiming a fresh fetch

**Date:** 2026-08-03
**Agent:** solo

**The surprise.** The 2026-07-30 research digest opened by stating it had spot-checked the live raw README that run, and reported "91 checks code / 82 non-code". `README.md:29` and `docs/sop/compliance-checklist.md:336-337` both said 94/85, and had since 2026-07-26 — four days before the digest ran.

**The misleading prior expectation.** The digest's job prompt was overhauled on 2026-07-06 specifically to fix unreliable repo indexing: fetch via `api.github.com` and `raw.githubusercontent.com`, never `github.com` HTML, because that serves stale cache. The self-healing README spot-check was added as the safeguard. So the run *appeared* to carry its own freshness proof, which made its "Already addressed?" column look trustworthy. It reported that column as unverified because the commits API was unreachable, but the README figure was presented as freshly fetched. Both halves were stale; only one was flagged.

**The rule.** Verify a digest's repo claims against the working tree before reading anything else, and verify them by counting rather than by reading a summary. Here the check was `grep -cE '^\| [A-Z]+[0-9]+ \|' docs/sop/compliance-checklist.md`, which returns 94 and also surfaced two defects the summary table concealed: `M1`-`M4` and `R1` are each defined twice (filed as P76). A summary line is a claim about the document; the rows are the document.

The wider lesson is that a self-verification step which can fail silently is worse than none, because it converts "unknown freshness" into "apparently confirmed". Same class as the gates this repo keeps fixing: P73's unreachable BLOCK message, P69's always-empty commit range, and P82's collision check failing open when its awk call errors — all found on 2026-07-26 or later. A check that cannot report its own failure reports success.
