# [Project Name] — Backlog

Single source of truth for all work items. Never delete without a trace — update in place, mark superseded, or archive.

## Tag Taxonomy

- Status (first): `[OPEN]`, `[IN PROGRESS]`, `[BLOCKED]`, `[DEFERRED]`, `[SHIPPED - YYYY-MM-DD]`, `[VERIFIED - YYYY-MM-DD]`, `[WON'T]`
- Type (second): `[Feature]`, `[Iteration]`, `[Bug]`, `[Refactor]`
- Optional: `[has-open-questions]`, `[ok-for-automation]`

**Tag rules:**
- Status first, type second. Never reverse.
- `[BLOCKED]` = waiting on an external action (someone else must do X first).
- `[DEFERRED]` = intentionally postponed with no external blocker (chosen to do later). Use this instead of leaving stale `[OPEN]` entries that were consciously pushed back.
- `[WON'T]` requires inline reason: `[WON'T] [Type] — Reason: [one-line explanation or superseding P-number]`
- `[VERIFIED]` means tested in production (code projects) or reviewed and confirmed accurate (docs projects).
- P-numbers are assigned sequentially, never reused, and do not imply priority.

---

## P-Numbered Items

### P1 — [First work item]
`[OPEN] [Feature]`

[Description of what needs to be built and why.]

**Acceptance criteria:**
- [Concrete, testable criterion]
- [Concrete, testable criterion]

**Out of scope:**
- [What this item explicitly does not cover]

**Open questions:**
- [Any unresolved questions — mark `[has-open-questions]` if present]

---

<!-- Add more P-numbered items here. Format:

### P[N] — [Title]
`[STATUS] [TYPE]`

[Description]

**Acceptance criteria:**
- [criterion]

---
-->

## Shipped Archive

*Items below are shipped or verified. Never removed. Move items here when Backlog.md exceeds ~2,000 lines and items are older than 90 days.*
