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

*Minimum 5 entries. Update at the start of each phase.*

| Area | File | Purpose |
|------|------|---------|
| Agent Memory | `docs/agent-memory.md` | Cross-session decisions, gotchas, invariants |
| Feature Map | `docs/feature-map.md` | Shipped features + roadmap |
| Backlog | `Backlog.md` | Single source of truth for all work items |
| Build Plans | `docs/build-plans/*.md` | Phase architecture, batch logs |
| Brand Voice | `.claude/brand-voice.md` | Copy rules, tone, terminology |
| [Area] | `[path]` | [purpose] |
| [Area] | `[path]` (lines N-N) | [purpose — include line range for large files] |

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

- Status (first): `[OPEN]`, `[IN PROGRESS]`, `[BLOCKED]`, `[SHIPPED - YYYY-MM-DD]`, `[VERIFIED - YYYY-MM-DD]`, `[WON'T]`
- Type (second): `[Feature]`, `[Iteration]`, `[Bug]`, `[Refactor]`
- Optional: `[has-open-questions]`, `[ok-for-automation]`

### Rules

- Never delete items from Backlog.md.
- Never mark `[SHIPPED]` without merge to main.
- Never mark `[VERIFIED]` without testing in a running app.
- Status first, type second. Never reverse.

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
3. `docs/feature-map.md` — append shipped items.
4. `docs/agent-memory.md` — append decisions/gotchas, move completed to `## Completed Work`.
5. `docs/build-plans/phase-N.md` — append to Batch Log.
6. `project_resume.md` — overwrite with current state.
7. Commit `docs/` changes with the work.

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
