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

## Item Sizing

Each item should be small enough to ship in a single PR with a single clear outcome. **Rule of thumb:** if the title or description needs "and" or multiple top-level bullets, split it into separate P-numbered items.

- BAD: `### P12 — Implement user authentication` (scope unbounded: routes, schema, UI, emails, rate limiting, tests all bundled)
- GOOD: `### P12 — Add \`/api/auth/login\` endpoint with Zod schema + tests`, plus `### P13 — Add login form component`, plus `### P14 — Add session token storage`, and so on

Small items review faster, roll back cleanly, and let multiple agents work in parallel. A P-number that never ships because it was too big is worse than three that do.

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
