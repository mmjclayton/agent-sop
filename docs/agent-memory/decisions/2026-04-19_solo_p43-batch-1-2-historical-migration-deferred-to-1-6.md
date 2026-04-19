# P43 Batch 1.2 historical migration deferred to Batch 1.6

**Date:** 2026-04-19
**Agent:** solo

Original plan AC for Batch 1.2 included "agent-sop itself migrated as part of this batch". Narrowed during execution — historical extraction moved to Batch 1.6 where the migration command ships. Batch 1.2 establishes structure, specs, commands, and new-entry write paths only. Until 1.6 lands, legacy sections in CLAUDE.md and agent-memory.md coexist with the new directories via cutover notes.

Rationale: splitting keeps 1.2's commit focused on structural changes (reviewable atomic) and validates the migration command on real historical content (a stronger test than hand-running extraction). Batch 1.6 subsequently ran cleanly on agent-sop with 77 entries extracted, no filename collisions.

Documented in the build plan Batch 1.2 AC section.
