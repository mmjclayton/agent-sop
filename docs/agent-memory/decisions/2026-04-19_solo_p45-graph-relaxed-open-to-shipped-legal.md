# P45 transition graph relaxed: `[OPEN]` → `[SHIPPED]` is legal

**Date:** 2026-04-19
**Agent:** solo

Initial P45 design forced a three-step path `[OPEN]` → `[IN PROGRESS]` → `[SHIPPED]` with no exception. Dogfood check while shipping P45 surfaced the friction: a single-session item shipping in one clean commit would be rejected by the validator I was about to release. Forcing a two-session split purely to satisfy the rule adds bookkeeping, not signal.

**Graph relaxed:** `[OPEN]` / `[BLOCKED]` / `[DEFERRED]` → `[SHIPPED]` are all legal when a Batch Log reference exists. The Batch Log requirement (already present for any `[SHIPPED]` transition) is the anti-gaming teeth — it forces the agent to leave a paper trail in `docs/build-plans/phase-*.md` naming the P-number. Without the entry, the transition still hard-blocks.

**Still illegal:**
- `<absent>` → `[SHIPPED]` (or `[VERIFIED]` / `[WON'T]`) — unplanned work has no paper trail. Catches the headline failure mode P45 exists for.
- Any transition from `[VERIFIED]` or `[WON'T]` (terminal states).

**Why the `[IN PROGRESS]` intermediate turned out to be bookkeeping, not enforcement:**
- For multi-session work: agents legitimately flip to `[IN PROGRESS]` when they start and leave the marker so sibling agents know who's working on what. Value is intent-signalling, not paper-trail.
- For single-session work: intent-signalling has no consumer — one agent, one session, one ship. The forced intermediate added ceremony.
- The Batch Log is the proof-of-work artifact. It names the P-number, the session, what shipped, and the commit hash.

**Source:** dogfood moment while flipping P45 status in this session. Fixtures updated (`legal-open-to-shipped` added, `illegal-open-to-shipped` removed). Section 8 table and Backlog AC both note the relaxation.
