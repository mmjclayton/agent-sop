# Agent Memory

Shared context for all agents working on this project. Read at the start of every session. Update at the end. Never delete without a trace — update in place, mark superseded, or archive.

---

## Key Documents

<!-- Do not duplicate the table from CLAUDE.md. Point here instead. -->
See CLAUDE.md Key Documents & Dispatch table.

---

## Key Source Files for Current Work

<!-- Updated at the start of each phase, not each session. List the files an agent needs to read to work on the current phase. -->

| Area | File |
|------|------|
| [Area] | `[path/to/file]` |

---

## In-Flight Work

<!-- Per-agent lines. Format: `- <agent-id> (YYYY-MM-DD): description`. Each agent manages their own line. When work completes, the agent moves their line to ## Completed Work. Empty is fine. -->

*(none)*

---

## Decisions Made

<!-- Decisions live as one file per entry in `docs/agent-memory/decisions/`. Filename: `YYYY-MM-DD_<agent-id>_<slug>.md`. See `docs/sop/claude-agent-sop.md` Section 3 and `docs/guides/multi-agent-parallel-sessions.md` for the format and filename convention. -->

See `docs/agent-memory/decisions/`. One file per decision.

---

## Gotchas and Lessons

<!-- Gotchas live as one file per entry in `docs/agent-memory/gotchas/`. Same filename convention as decisions. Non-obvious things that burned time, data model invariants not obvious from the schema, named utility functions for cross-cutting concerns, framework-specific patterns that agents commonly get wrong. -->

See `docs/agent-memory/gotchas/`. One file per gotcha.

---

## [Project Name]'s Preferences

<!-- Agent behaviour preferences specific to this project. E.g. "terse responses", "Australian English", "no emojis in code". -->

*(none yet)*

---

## Completed Work

<!-- Entries moved from In-Flight Work when done. Format: `- YYYY-MM-DD <agent-id>: description — PR #N or commit hash`. Each line per agent per completion. -->

*(none yet)*

---

## Archived

<!-- Historical narrative that no longer belongs in active sections. Superseded decisions and gotchas move to `docs/agent-memory/decisions/archive/` and `docs/agent-memory/gotchas/archive/` respectively — this section is only for narrative content that doesn't live in those directories. Never delete. -->

*(none yet)*
