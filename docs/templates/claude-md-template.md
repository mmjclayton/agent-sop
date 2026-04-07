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

## Key Documents — READ THESE

| Document | Path | Purpose |
|----------|------|---------|
| Agent Memory | `docs/agent-memory.md` | Permanent cross-session context — decisions, gotchas, data model invariants. All agents read and update this. |
| Feature Map | `docs/feature-map.md` | Complete inventory of shipped features + prioritised roadmap |
| Backlog | `Backlog.md` | Single source of truth for all work items |
| Build Plans | `docs/build-plans/*.md` | Phase-level architecture decisions |
| Brand Voice | `.claude/brand-voice.md` | Copy rules, tone, terminology |
| Schema | `[path/to/schema]` | Database schema |
| CSS Tokens | `[path/to/styles]` (lines N-N) | CSS custom properties — always include line range |

### Current Priority Items (as of YYYY-MM-DD)

**Very High:**
- [P-number] — [item description]

**High:**
- [P-number] — [item description]

**Medium:**
- [P-number] — [item description]

---

## Backlog Management

`Backlog.md` at the repo root is the single source of truth. GitHub Issues mirror it but are downstream. Never create a GitHub issue that does not exist in `Backlog.md`.

**Canonical status rule:** `Backlog.md` holds the live status. Build-plan files describe the work. If they disagree, `Backlog.md` wins.

### Tag taxonomy

- Status (first): `[OPEN]`, `[IN PROGRESS]`, `[BLOCKED]`, `[SHIPPED - YYYY-MM-DD]`, `[VERIFIED - YYYY-MM-DD]`, `[WON'T]`
- Type (second): `[Feature]`, `[Iteration]`, `[Bug]`, `[Refactor]`
- Optional: `[has-open-questions]`, `[ok-for-automation]` (mutually exclusive)

### GitHub issues are lazy-created

Create the GitHub issue at the moment an item moves to `[IN PROGRESS]` or is handed to the auto-pipeline.

### Automation pipeline

Items tagged `[ok-for-automation]` can be routed to the auto-pipeline. Qualification criteria (all must hold):
- Small blast radius (one file/component/route)
- At least 2 concrete acceptance criteria
- Names the specific file/component
- No `[has-open-questions]` tag
- Reversible

### Starting work on an item

1. Read the full item including ACs, Out of Scope, and Open Questions.
2. Update status to `[IN PROGRESS]` in `Backlog.md` and sync the GitHub label.
3. Create a branch named `<type>/<short-slug>`.
4. Ask for answers to Open Questions when you reach a decision point - do not guess.

### Completing work on an item

1. Verify each acceptance criterion against the running code.
2. Update heading to `[SHIPPED - YYYY-MM-DD]`.
3. Close the GitHub issue.
4. Do all Backlog.md edits in the same commit/PR as the work.

### Never do

- Never create a GitHub issue without a corresponding Backlog.md entry.
- Never mark `[VERIFIED]` without testing in a running app.
- Never mark `[SHIPPED]` without CI green and merge to main.
- Never delete items from Backlog.md.
- Never reverse the tag order — status first, type second.

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

### Session start checklist

1. Read `MEMORY.md` index.
2. Read `project_resume.md` — where the last session left off.
3. Read `docs/agent-memory.md` — permanent decisions, gotchas, in-flight work.
4. Read current `docs/build-plans/` phase file.
5. Run `git log --oneline -10`.
6. Cross-check memory claims against git/code state — trust what you observe, not what memory says.
7. Read the specific Backlog.md item(s) for this session.

### Session end checklist

**Never delete without a trace. Update in place, mark superseded, or move to Archived/Completed. Never silently remove.**

1. Run tests (code projects) — fix failures before proceeding.
2. `Backlog.md` — update status tags and item bodies in place, append new items. Never remove items.
3. `docs/feature-map.md` — append shipped features, move roadmap items between tiers. Never remove.
4. `docs/agent-memory.md`:
   - In-Flight: move completed entries to `## Completed Work` with date and PR number.
   - Decisions: append with date. Mark superseded ones and move to `## Archived`.
   - Gotchas: append new lessons, invariants, utility function notes. Mark stale and move to `## Archived`.
5. `docs/build-plans/phase-N.md` — append to Batch Log with date and PR numbers. Never rewrite existing log entries.
6. `project_resume.md` — overwrite with current session state: what was done, what is next, blockers.
7. `MEMORY.md` index — append new entries. Never remove existing lines.
8. Commit `docs/` changes in the same commit as the work that prompted them.

---

## Dispatch Quick Reference

*Required. Minimum 5 named files. Update at the start of each phase.*

1. Read CLAUDE.md - then read the specific Backlog.md item - then read relevant source files below.
2. Key entry points for current work:

| Area | File |
|------|------|
| [Area 1] | `[full/relative/path/to/file]` |
| [Area 2] | `[full/relative/path/to/file]` |
| [Area 3] | `[full/relative/path/to/file]` |
| [Area 4] | `[full/relative/path/to/file]` |
| [Area 5] | `[full/relative/path/to/file]` |

3. Run `[test command]` before and after every change.
4. Update Backlog.md and docs/feature-map.md when work ships.

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
