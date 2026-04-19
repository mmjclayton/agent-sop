# P43 Batch 1.4 auto-renumber deferred; detect + manual helper is shipped scope

**Date:** 2026-04-19
**Agent:** solo

Original plan AC for Batch 1.4 said "renumber branch's new items in-place across all tracking files". Narrowed during execution — shipped detection + hard-block + a manual `renumber_p` shell helper. Auto-renumber remains a candidate follow-up if dogfood shows the manual helper is frictional.

Why: the renumber surface is too broad for a mechanical update without human review. It spans Backlog.md headings + body references, feature-map.md, CLAUDE.md rollup, build-plan Batch Log entries, `docs/recent-work/` filenames + body, and `docs/agent-memory/decisions/` and `gotchas/` filenames + body. An archived decision may mention "P50 was superseded by P60" — mechanical substitution would corrupt that narrative. Commit-message references are immutable.

The detection check in `/update-sop` Step 2a hard-blocks the commit when collision is detected and prints the exact `renumber_p` commands to run. The user reviews via `git diff` after running the helper. Safer than silent auto-renumber, cheap to implement, and reversible (just `git checkout .`).

Documented in `docs/guides/multi-agent-parallel-sessions.md` Section 6 with "Why not auto-renumber" rationale inline.
