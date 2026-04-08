# [PROJECT NAME] — [One-line description]

> [Optional: brand tagline]

---

*This is the code project template — for full-stack web apps and other software projects. It extends the base template (`claude-md-template-base.md`) with Auth, Database, Design System, and code-specific build rules. For non-code projects, use the base template.*

---

## Agent SOP

All agents working on this project follow the Claude Code Agent SOP (`docs/sop/claude-agent-sop.md`). The SOP defines the standard file structure, never-delete-without-a-trace policy, session checklists, and update triggers. This file (CLAUDE.md) is the authority on project-specific conventions. The SOP is the authority on process.

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
| Schema | `[path/to/schema]` | Database schema |
| CSS Tokens | `[path/to/styles]` (lines N-N) | CSS custom properties — include line range |

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
- `[WON'T]` format: `[WON'T] [Type] — Reason: [explanation or superseding P-number]`
- `[VERIFIED]` means: tested in production on the live URL

### Rules

- Never delete items from Backlog.md.
- Never mark `[SHIPPED]` without CI green and merge to main.
- Never mark `[VERIFIED]` without testing in a running app.
- Status first, type second. Never reverse.

---

## Stack

- **Frontend:** [framework, libraries] — `client/`
- **Backend:** [framework, ORM, database] — `server/`
- **Hosting:** [platform]
- **CI:** [CI tool and what it runs]
- **Live:** [URL]

---

## Key Commands

```bash
# Development
[dev server command]            # e.g. npm run dev:server
[dev client command]            # e.g. npm run dev:client

# Testing
[run all tests]                 # e.g. npm test
[run server tests only]         # e.g. npm run test:server
[run client tests only]         # e.g. npm run test:client
[run single test file]          # e.g. npx vitest run path/to/file.test.ts

# Database
[migration deploy command]      # e.g. npx prisma migrate deploy
[migration create command]      # e.g. npx prisma migrate dev --name [name]

# Linting and type checking
[lint command]                  # e.g. npx eslint .
[type check command]            # e.g. npx tsc --noEmit

# Build
[build command]                 # e.g. npm run build
```

---

## Auth

- **Identity provider:** [provider, e.g. Supabase Auth, Auth0, NextAuth, Clerk]
- **Token type:** [JWT / session cookie / API key]
- **Session handling:** [approach, e.g. httpOnly cookies, bearer tokens, middleware refresh]
- **Auth middleware:** [file path, e.g. `src/middleware.ts` or `server/middleware/auth.js`]
- **Protected routes pattern:** [how routes are guarded, e.g. middleware check, wrapper component, RLS]
- **Public routes:** [list routes that do not require authentication]
- **Database:** [where user and session data lives, e.g. `users` table, Supabase auth.users]
- **Key rule:** [the most important auth rule for this project, e.g. "never trust getSession() alone, always verify with getUser()"]

---

## Database

- **ORM:** [e.g. Prisma, Drizzle, Sequelize, SQLAlchemy, raw SQL]
- **Migration tool:** [e.g. Prisma Migrate, Knex, Alembic, manual SQL files]
- **Schema location:** [file path, e.g. `prisma/schema.prisma`, `server/models/`]
- **Models:** [list model names and brief purpose, e.g. "User, Program, Exercise, WorkSet"]
- **Naming conventions:** [table naming, e.g. snake_case plural; column naming, e.g. camelCase]
- **Query patterns:** [e.g. "always use ORM, never raw SQL" or "use query builder for complex joins"]
- **Key constraints:** [anything non-obvious about relationships, cascades, or data integrity]
- **Schema change protocol:** edit schema -> create migration -> update server routes -> update client code -> add tests -> verify test suite passes

---

## Design System

- **Component library:** [e.g. Shadcn/ui, Radix, custom components, Material UI]
- **Palette:** [key colour values, e.g. primary: #1a1a2e, surface: #16213e]
- **Accent colours:** [values for interactive elements, status indicators]
- **Typography scale:** [font stack, heading sizes, body size, line heights]
- **Spacing scale:** [base unit and scale, e.g. "4px base: 4, 8, 12, 16, 24, 32, 48"]
- **Responsive breakpoint:** [value, e.g. 768px single breakpoint]
- **Responsive strategy:** [e.g. mobile-first, desktop-first, single breakpoint with fluid scaling]
- **Touch targets:** [minimum size, e.g. 44x44px]
- **Icon system:** [e.g. Lucide, Heroicons, custom SVGs]
- **CSS tokens location:** [file + line range, e.g. `client/src/index.css` (lines 1-80)]

---

## Code Quality Rules

*Language-agnostic defaults. Add language-specific rules below or in a separate `.claude/rules/` file.*

### File size

- 200-400 lines typical, 800 lines maximum
- If a file exceeds 800 lines, split it by responsibility before adding more code
- Organise by feature or domain, not by type (e.g. `features/auth/` not `controllers/`)

### Immutability

- Prefer `const` over `let`. Never use `var`
- Create new objects rather than mutating existing ones (spread operator, `map`, `filter`)
- Rationale: immutable data prevents hidden side effects and makes debugging easier

### Error handling

- Handle errors explicitly at every level. No silent catches, no empty catch blocks
- Provide user-friendly messages in UI-facing code, detailed context in server logs
- Never swallow errors. If you catch, log and re-throw or return an error result

### Import ordering

- Standard library / built-in modules first
- External packages second
- Internal project modules third
- Relative imports last
- Blank line between each group

### Test coverage

- 80% minimum coverage for new code
- Every new API endpoint must have integration tests
- Every new component with logic must have unit tests
- Run the full test suite before opening a PR

### Linting and type checking

- Lint and type-check are non-negotiable pre-commit gates
- Fix lint errors in your code. Never weaken linter config to make errors go away
- Type checking (e.g. `tsc --noEmit`, `mypy`, `cargo check`) must pass before commit

### No debug artifacts

- No `console.log` or `debugger` statements in committed code
- No `TODO` or `FIXME` comments without a corresponding issue or P-number
- No commented-out code blocks. Delete dead code; git has the history

### Function size

- Functions should do one thing. Prefer small, focused functions over large monolithic ones
- Split at 50 lines. If a function exceeds 50 lines, extract helpers
- Prefer early returns over deep nesting (max 4 levels)

---

## Rules for Automated Builds

1. Read this file first. Then read the Backlog item. Then look at existing code.
2. Do not modify files unrelated to the current Backlog item.
3. Never delete without a trace: update in place, mark superseded, or archive. Never silently remove content.
4. Every new API endpoint must have integration tests.
5. Every new component with logic must have a unit test.
6. Run the full test suite and fix failures before opening a PR.
7. Use the ORM for all database operations. Never write raw SQL.
8. Never modify the schema file without creating a migration.
9. Schema changes must follow this sequence: edit schema → create/run migration → update server routes → update client code → add/update tests → verify test suite passes.
10. PR descriptions must include: what was built, why key decisions were made, and how to test manually.
11. Update `Backlog.md` and `docs/feature-map.md` when work ships.

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

1. Run tests — run the full test suite. Fix failures before proceeding.
2. `Backlog.md` — update status tags in place, append new items.
3. `docs/feature-map.md` — append shipped items.
4. `docs/agent-memory.md` — append decisions/gotchas, move completed to `## Completed Work`.
5. `docs/build-plans/phase-N.md` — append to Batch Log.
6. `project_resume.md` — overwrite with current state.
7. Commit `docs/` changes with the work.

---

## Recent Work

*Append-only. New entries at top. Always include PR number range.*

### YYYY-MM-DD: PRs #N-#N
[2-3 line summary of what shipped]

### YYYY-MM-DD: PRs #N-#N
[2-3 line summary of what shipped]

---

## Deprioritised

*Items moved here from priority lists above. Never removed.*
