# [PROJECT NAME] — [One-line description]

> [Optional: brand tagline]

---

*This is the base template — suitable for any project type. For full-stack code projects, use `claude-md-template-code.md` instead, which adds Auth, Database, Design System, and code-specific build rules.*

---

## Agent SOP

All agents working on this project follow the Claude Code Agent SOP (`claude-agent-sop.md`). The SOP defines the standard file structure, never-delete-without-a-trace policy, session checklists, and update triggers. This file (CLAUDE.md) is the authority on project-specific conventions. The SOP is the authority on process.

---

## Build Plans — READ FIRST

Always check `docs/build-plans/` at the start of any session to see what has shipped, what is in flight, and what is next.

Current phase files:
- `docs/build-plans/phase-0-foundation.md` — [status emoji] [status description]

---

## Key Documents & Dispatch

*Minimum 5 entries. Use intent-based descriptions. Update at the start of each phase.*

| When you need to... | Start at | Notes |
|---------------------|----------|-------|
| Read cross-session context | `docs/agent-memory.md` | Decisions, gotchas, invariants |
| Check shipped features or roadmap | `docs/feature-map.md` | Shipped inventory + priority tiers |
| Check or update work items | `Backlog.md` | Single source of truth for all items |
| Read phase architecture | `docs/build-plans/*.md` | Batch logs, locked decisions |
| Check copy/tone rules | `.claude/brand-voice.md` | Brand voice, terminology |
| [Change X] | `[path]` | [what to know when you arrive] |
| [Change Y] | `[path]` (lines N-N) | [include line range for large files] |

Test: `[test command]`
After shipping: update Backlog.md + docs/feature-map.md

### Current Priority Items (as of YYYY-MM-DD)

**Very High:**
- [P-number] — [item description]

**High:**
- [P-number] — [item description]

**Medium:**
- [P-number] — [item description]

---

## Backlog Management

`Backlog.md` is the single source of truth. If it disagrees with build plans, `Backlog.md` wins. Issues are lazy-created: only when work moves to `[IN PROGRESS]`.

### Tag taxonomy

- Status (first): `[OPEN]`, `[IN PROGRESS]`, `[BLOCKED]`, `[DEFERRED]`, `[SHIPPED - YYYY-MM-DD]`, `[VERIFIED - YYYY-MM-DD]`, `[WON'T]`
- Type (second): `[Feature]`, `[Iteration]`, `[Bug]`, `[Refactor]`
- Optional: `[has-open-questions]`, `[ok-for-automation]`

### Rules

- Never delete items from Backlog.md.
- Never mark `[SHIPPED]` without merge to main.
- Never mark `[VERIFIED]` without testing in a running app.
- Status first, type second. Never reverse.
- `[BLOCKED]` = waiting on external action. `[DEFERRED]` = intentionally postponed. Use `[DEFERRED]` instead of leaving stale `[OPEN]` items sitting around.

---

## Stack

- **Type:** [e.g. full-stack web app / markdown library / data pipeline / mobile app]
- **Key technologies:** [list]
- **Hosting:** [platform or n/a]
- **CI:** [CI tool and what it runs, or n/a]
- **Live:** [URL or n/a]

---

## Key Commands

```bash
# Add the most commonly needed commands for this project type
[command] — [what it does]
[command] — [what it does]
```

*For code projects: see `claude-md-template-code.md` for dev, test, and migration command patterns.*

---

## Common Mistakes — Read Before Working

*Project-specific gotchas that prevent wrong turns. Update as new gotchas are discovered.*

- [State what NOT to do and why. Name specific files, components, or conventions.]
- [Example: "[File X] is separate from [File Y]. Do not look for X inside Y."]
- [Example: "The default view is [key]. 'Home' means [key], not [other key]."]
- [Example: "[Thing] is derived, not stored. Never add a column for it."]

*See SOP Section 15 for full guidance on writing effective gotcha callouts.*

---

## Definition of Done

*Self-evaluate against the relevant rubric before committing. If any criterion is not met, iterate before shipping.*

### Bug fix
- Root cause identified from reading the actual code — do not infer from documentation alone
- Fix is minimal: change the broken logic, do not remove working mechanisms
- Fix applied to ALL instances (grep for similar occurrences)
- No regressions — existing tests pass

### Feature
- All acceptance criteria from the Backlog item are met
- No debug artifacts (console.log, TODO without P-number)
- Backlog.md and feature-map.md updated in the same commit

### Refactor
- Behaviour unchanged — all existing tests pass without modification
- No unrelated files modified
- Dead code from old pattern removed

*For code projects: see `claude-md-template-code.md` for expanded rubrics with test and design system criteria.*

---

## Rules for Automated Builds

1. Read this file first. Then read the Backlog item. Then look at existing work.
2. Do not modify files unrelated to the current Backlog item.
3. Never delete without a trace: update in place, mark superseded, or archive. Never silently remove content.
4. Update `Backlog.md` and `docs/feature-map.md` when work ships.
5. Commit docs/ changes in the same commit as the work that prompted them.

*For code projects: see `claude-md-template-code.md` for additional build rules (tests, ORM, migrations, PR descriptions).*

---

## Session & Memory Hygiene

Memory files live at `~/.claude/projects/[project-hash]/memory/`.

### Session start: run `/restart-sop`

**Every session, no exceptions.** The `/restart-sop` command automates this checklist. If the command is not available, execute manually:

1. Read CLAUDE.md.
2. Read `MEMORY.md` + `project_resume.md`.
3. Read `docs/agent-memory.md`.
4. Run `git log --oneline -10`, cross-check memory against current file state.
5. Read the specific Backlog.md item(s) for this session.

If In-Flight Work is populated or `project_resume.md` has no What's Next — previous session was interrupted. Read the build plan Batch Log before starting new work.

### Session end: run `/update-sop`

**Every session, no exceptions.** The `/update-sop` command automates this checklist. If the command is not available, execute manually. Never delete without a trace. Update in place, mark superseded, or archive.

1. Run tests (code projects) — fix failures before proceeding.
2. `Backlog.md` — update status tags in place, append new items.
3. Secondary trackers — reconcile any project-specific finding files (audit-backlog, security-findings, etc.) that use heading-level `[OPEN]`/`[SHIPPED]` tags. Hard block: any finding ID referenced in this session's commits must not be left `[OPEN]`.
4. `docs/feature-map.md` — append shipped items.
5. `docs/agent-memory.md` — append decisions/gotchas, move completed to `## Completed Work`.
6. `docs/build-plans/phase-N.md` — append to Batch Log.
7. `project_resume.md` — overwrite with current state.
8. Commit `docs/` changes with the work.

---

## Recent Work

*Append-only. New entries at top. Always include PR numbers.*

### YYYY-MM-DD: PRs #N-#N
[2-3 line summary of what shipped]

### YYYY-MM-DD: PRs #N-#N
[2-3 line summary of what shipped]

---

## Deprioritised

*Items moved here from priority lists above. Never removed.*
