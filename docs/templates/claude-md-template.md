# [PROJECT NAME] — [One-line description]

> [Optional: brand tagline]

---

**Project type:** non-code

*Base template for any project type. Code projects use `claude-md-template-code.md`, which adds Auth, Database, Design System and code-specific rules. Keep the per-session sections of this file under 200 lines (300 for code projects with a Common Mistakes section).*

---

## Agent SOP

Sessions follow `docs/sop/claude-agent-sop.md`; this file is the authority on project-specific conventions, the SOP on process. Start: the context hook prints project state on the first prompt, then `/restart-sop` reads the work item. End: `/update-sop` (on code projects the Stop hook enforces the minimum record). Never delete without a trace; when files disagree, code and git win, then this file, then `Backlog.md`.

---

## Key Documents & Dispatch

*At least five entry points with paths. Name a stable anchor (a symbol, a block, a grep target) for large files, never a line range.*

| When you need to... | Start at | Notes |
|---------------------|----------|-------|
| Check or update work items | `Backlog.md` | Grep the P-number, read only that range |
| Read why something was decided, or what bites | `docs/agent-memory/decisions/`, `docs/agent-memory/gotchas/` | Newest first; gotchas before touching the area they name |
| Read phase architecture | `docs/build-plans/*.md` | Locked decisions, open questions |
| Check copy/tone rules | `.claude/brand-voice.md` | Brand voice, terminology |
| Run more than one agent on this repo | `docs/sop/multi-agent.md` | Worktrees, agent-ids, merge discipline |
| [Change X] | `[path]` | [what to know when you arrive] |
| [Change Y] | `[path]` | [related component, constraint, gotcha] |

Test: `[test command, or "none" for a prose project]`

### Current priority items

<!-- Derived from Backlog.md by scripts/refresh-priorities.sh at every /update-sop. Do not edit by hand. -->

<!-- priority-items:start -->
*Not yet generated. The first `/update-sop` run will populate this from `Backlog.md`.*
<!-- priority-items:end -->

---

## Backlog Management

`Backlog.md` is the single source of truth for work items. Status first, type second, never reversed: `[OPEN]` `[IN PROGRESS]` `[BLOCKED]` `[DEFERRED]` `[SHIPPED - YYYY-MM-DD]` `[VERIFIED - YYYY-MM-DD]` `[WON'T]`, then `[Feature]` `[Iteration]` `[Bug]` `[Refactor]`. `[DEFERRED]` states `**Reopens when:**`; `[WON'T]` states `Reason:`. A shipped `[Feature]` or `[Refactor]` carries a `review:` line or a `review skipped (P<n>): <reason>` token. Never delete an item. Closed items older than 90 days move to `docs/backlog-archive.md` via `scripts/archive-backlog.sh`.

---

## Stack

- **Type:** [e.g. markdown library / data pipeline / research corpus]
- **Key technologies:** [list]
- **Hosting:** [platform or n/a]
- **Live:** [URL or n/a]

---

## Key Commands

```bash
[command] — [what it does]
[command] — [what it does]
```

---

## Common Mistakes — Read Before Working

*Project-specific. Each entry names the file, model or convention, says what is wrong and what is correct, and the consequence. No general best practice, no derived fact that goes stale.*

- [Example: "[File X] is separate from [File Y]. Do not look for X inside Y."]
- [Example: "[Thing] is derived, not stored. Never add a column for it; compute it with [function]."]

---

## Rules for Automated Builds

1. Read the Backlog item, then the existing work, before changing anything.
2. Do not modify files unrelated to the current Backlog item.
3. [Project-specific rule, e.g. "every client-facing document passes check-invariants.py"]
4. [Project-specific rule]

---

## Where the history lives

Session history: `docs/RECENT-WORK.md`, a rollup of `docs/recent-work/*.md` regenerated at every `/update-sop`. Status: `Backlog.md`. Neither is duplicated here.
