# [PROJECT NAME] — [One-line description]

> [Optional: brand tagline]

---

**Project type:** code

*Code project template: the base template plus Auth, Database, Design System and code-specific rules. Keep the per-session sections (everything except Auth, Database and Design System) under 300 lines. General coding rules load from the user's `~/.claude/rules/`; do not repeat them here.*

---

## Agent SOP

Sessions follow `docs/sop/claude-agent-sop.md`; this file is the authority on project-specific conventions, the SOP on process. Start: the context hook prints project state on the first prompt, then `/restart-sop` reads the work item. End: `/update-sop`; the Stop hook enforces the minimum record and the ship-sop gate on this code project. Never delete without a trace; when files disagree, code and git win, then this file, then `Backlog.md`.

---

## Key Documents & Dispatch

*At least five entry points with paths. Name a stable anchor (a symbol, a block, a grep target) for large files, never a line range.*

| When you need to... | Start at | Notes |
|---------------------|----------|-------|
| Check or update work items | `Backlog.md` | Grep the P-number, read only that range |
| Read why something was decided, or what bites | `docs/agent-memory/decisions/`, `docs/agent-memory/gotchas/` | Newest first; gotchas before touching the area they name |
| Read phase architecture | `docs/build-plans/*.md` | Locked decisions, open questions |
| Change the data model | `[schema path]` | Follow the schema change protocol below |
| Change auth or session handling | `[auth middleware path]` | [key rule, e.g. verify with getUser(), never getSession() alone] |
| Change styling | `[css tokens file]`, in the `:root` block | Tokens only, never hardcoded hex |
| Run more than one agent on this repo | `docs/sop/multi-agent.md` | Worktrees, agent-ids, merge discipline |
| [Change X] | `[path]` | [what to know when you arrive] |

Test: `[test command]`

### Current priority items

<!-- Derived from Backlog.md by scripts/refresh-priorities.sh at every /update-sop. Do not edit by hand. -->

<!-- priority-items:start -->
*Not yet generated. The first `/update-sop` run will populate this from `Backlog.md`.*
<!-- priority-items:end -->

---

## Backlog Management

`Backlog.md` is the single source of truth for work items. Status first, type second, never reversed: `[OPEN]` `[IN PROGRESS]` `[BLOCKED]` `[DEFERRED]` `[SHIPPED - YYYY-MM-DD]` `[VERIFIED - YYYY-MM-DD]` `[WON'T]`, then `[Feature]` `[Iteration]` `[Bug]` `[Refactor]`. `[DEFERRED]` states `**Reopens when:**`; `[WON'T]` states `Reason:`. A shipped `[Feature]` or `[Refactor]` carries a `review:` line or a `review skipped (P<n>): <reason>` token. `[VERIFIED]` means tested where it runs. Never delete an item. Closed items older than 90 days move to `docs/backlog-archive.md` via `scripts/archive-backlog.sh`.

---

## Stack

- **Frontend:** [framework, language, build tool]
- **Backend:** [runtime, framework, language]
- **Database:** [engine, ORM]
- **Hosting:** [platform]
- **CI:** [tool and what it runs]
- **Live:** [URL]

---

## Key Commands

```bash
# Development
[dev server]                    # e.g. npm run dev

# Testing
[run all tests]                 # e.g. npm test
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

- **Identity provider:** [e.g. Supabase Auth, Auth0, NextAuth, Clerk]
- **Token type:** [JWT / session cookie / API key]
- **Session handling:** [e.g. httpOnly cookies, bearer tokens, middleware refresh]
- **Auth middleware:** [file path]
- **Protected routes pattern:** [middleware check, wrapper component, RLS]
- **Public routes:** [list]
- **Key rule:** [the one auth rule that bites, e.g. "never trust getSession() alone, always verify with getUser()"]

---

## Database

- **ORM:** [e.g. Prisma, Drizzle, SQLAlchemy]
- **Migration tool:** [e.g. Prisma Migrate, Alembic]
- **Schema location:** [file path]
- **Models:** [names and one-line purposes]
- **Naming conventions:** [tables, columns]
- **Key constraints:** [non-obvious relationships, cascades, integrity rules]
- **Schema change protocol:** edit schema -> create migration -> update server routes -> update client code -> add tests -> verify the suite passes

---

## Design System

- **Component library:** [e.g. Shadcn/ui, Radix, custom]
- **Palette and accents:** [key values]
- **Typography and spacing scale:** [font stack, sizes, base unit]
- **Responsive strategy:** [breakpoints, mobile-first or not, touch target minimum]
- **Icon system:** [e.g. Lucide]
- **CSS tokens location:** [file, in the `:root` block; never a line range]

---

## Common Mistakes — Read Before Coding

*Project-specific. Each entry names the file, model, component or token, says what is wrong and what is correct, and the consequence. No general best practice, no derived fact that goes stale.*

### Data Model
- [Model X] is GLOBAL. Never filter by userId. [Model Y] is user-scoped.
- [Field] is derived, not stored. Compute it with [function]; never add a column for it.

### Client
- [Component A] is its own file, not inside [Component B].
- Colours use [token prefix] tokens only. Never hardcode hex.

### Server
- Every query filters by [user field] via [relation]. Never query without it.
- [Utility function] does [thing]. Use it, do not create your own.

### Testing
- Tests use [real DB / mocks]. Test DB is [name].

---

## Rules for Automated Builds

1. Read the Backlog item, then the existing code, before changing anything.
2. Do not modify files unrelated to the current Backlog item.
3. Use the ORM for all database operations; never modify the schema without a migration, and follow the schema change protocol above.
4. Every new endpoint has an integration test; every new component with logic has a unit test.
5. [Project-specific rule]

---

## Where the history lives

Session history: `docs/RECENT-WORK.md`, a rollup of `docs/recent-work/*.md` regenerated at every `/update-sop`. Status: `Backlog.md`. Neither is duplicated here.
