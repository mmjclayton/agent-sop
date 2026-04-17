# New Project Walkthrough

A step-by-step guide to setting up the Agent SOP in a brand new project. This walkthrough uses a concrete example — a task management API called **Taskflow** — so you can see what each file looks like when filled in rather than as abstract templates.

---

## Prerequisites

- A git repository (even if empty)
- Claude Code installed and working
- The Agent SOP repository cloned or accessible (for templates)

---

## Step 1 — Create the directory structure

```bash
mkdir -p docs/build-plans docs/sop
```

You will end up with:

```
taskflow/
├── CLAUDE.md
├── Backlog.md
├── docs/
│   ├── agent-memory.md
│   ├── feature-map.md
│   └── build-plans/
│       └── phase-0-foundation.md
└── (your source code)
```

---

## Step 2 — Choose your template

Two CLAUDE.md templates are available:

| Template | Use when | Path in agent-sop repo |
|----------|----------|------------------------|
| Base | Documentation, markdown libraries, scripts, any non-code project | `docs/templates/claude-md-template.md` |
| Code | Web apps, APIs, CLIs, anything with tests, a database, or deployments | `docs/templates/claude-md-template-code.md` |

Taskflow is a code project, so we will use the code template.

Copy the template to your project root as `CLAUDE.md` and fill in every placeholder. Do not leave `[bracket placeholders]` in the file — an agent reading this on its first session needs real values.

---

## Step 3 — Fill in CLAUDE.md

Here is what the Taskflow CLAUDE.md looks like after filling in the template. Key sections shown; the full file follows the template structure.

### Header

```markdown
# Taskflow — Task management API with a React dashboard

> Ship tasks, not tickets.
```

### Agent SOP

```markdown
## Agent SOP

All agents working on this project follow the Claude Code Agent SOP
(`docs/sop/claude-agent-sop.md`). The SOP defines the standard file structure,
never-delete-without-a-trace policy, session checklists, and update triggers.
This file (CLAUDE.md) is the authority on project-specific conventions.
The SOP is the authority on process.
```

### Stack

```markdown
## Stack

- **Frontend:** React 19, Vite, TanStack Query — `client/`
- **Backend:** Express, Prisma, PostgreSQL — `server/`
- **Hosting:** Render (web service + managed Postgres)
- **CI:** GitHub Actions — lint, type-check, test on every PR
- **Live:** https://taskflow.example.com
```

### Key Documents and Dispatch

```markdown
## Key Documents & Dispatch

| Area | File | Purpose |
|------|------|---------|
| Agent Memory | `docs/agent-memory.md` | Cross-session decisions, gotchas, invariants |
| Feature Map | `docs/feature-map.md` | Shipped features + roadmap |
| Backlog | `Backlog.md` | Single source of truth for all work items |
| Build Plans | `docs/build-plans/*.md` | Phase architecture, batch logs |
| Schema | `server/prisma/schema.prisma` | Database schema |
| CSS Tokens | `client/src/index.css` (lines 1-60) | Design tokens and custom properties |
| Auth Middleware | `server/src/middleware/auth.js` | JWT verification and route protection |

Test: `npm test`
After shipping: update Backlog.md + docs/feature-map.md
```

Note: 7 entries, all with real paths. Line-range hint on the CSS file so agents only read 60 lines, not the whole stylesheet.

### Key Commands

```markdown
## Key Commands

```bash
npm run dev:server            # Express on :3001
npm run dev:client            # Vite on :5173
npm test                      # Full test suite (Vitest)
npx vitest run path/to/file   # Single test file
npx prisma migrate dev --name [name]   # Create migration
npx eslint .                  # Lint
npx tsc --noEmit              # Type check
```
```

### Current Priority Items

```markdown
### Current Priority Items (as of 2026-04-10)

**Very High:**
- P1 — User authentication (JWT + refresh tokens)
- P2 — Task CRUD API with Prisma

**High:**
- P3 — React dashboard with task list and filters

**Medium:**
- P4 — Email notifications on task assignment
```

Fill in priorities from your Backlog. Keep this section in sync — it is the quick-glance view.

---

## Step 4 — Create Backlog.md

Start from the backlog template (`docs/templates/backlog-template.md`). Each work item gets a sequential P-number, status tag, type tag, and acceptance criteria.

```markdown
# Taskflow — Backlog

Single source of truth for all work items. Never delete without a trace —
update in place, mark superseded, or archive.

## Tag Taxonomy

- Status (first): `[OPEN]`, `[IN PROGRESS]`, `[BLOCKED]`,
  `[SHIPPED - YYYY-MM-DD]`, `[VERIFIED - YYYY-MM-DD]`, `[WON'T]`
- Type (second): `[Feature]`, `[Iteration]`, `[Bug]`, `[Refactor]`
- Optional: `[has-open-questions]`, `[ok-for-automation]`

---

## P-Numbered Items

### P1 — User authentication
`[OPEN] [Feature]`

JWT-based authentication with refresh tokens. Users can register, log in,
and log out. Protected routes require a valid access token.

**Acceptance criteria:**
- POST /auth/register creates a user and returns tokens
- POST /auth/login validates credentials and returns tokens
- POST /auth/refresh rotates the refresh token
- Auth middleware rejects expired or invalid tokens
- 80%+ test coverage on auth routes

---

### P2 — Task CRUD API
`[OPEN] [Feature]`

RESTful task management. Tasks belong to a user and have a title, description,
status (open/in_progress/done), and due date.

**Acceptance criteria:**
- GET/POST/PATCH/DELETE on /tasks
- Tasks are scoped to the authenticated user
- Pagination on GET /tasks (default 20, max 100)
- Prisma schema includes Task model with all fields
- Integration tests for all endpoints

---

## Shipped Archive

*Items below are shipped or verified. Never removed.*
```

Tips:
- Write 3-5 items to start. You can always add more.
- Acceptance criteria should be concrete and testable — "works correctly" is not a criterion.
- Do not add `[has-open-questions]` unless there is a genuine unresolved question written in the item.

---

## Step 5 — Create docs/agent-memory.md

Start from the agent memory template (`docs/templates/agent-memory-template.md`). On a brand new project, most sections will be empty — that is fine. The structure needs to exist so agents know where to write.

```markdown
# Agent Memory

Shared context for all agents working on this project. Read at the start of
every session. Update at the end. Never delete without a trace — update in
place, mark superseded, or archive.

---

## Key Documents

See CLAUDE.md Key Documents & Dispatch table.

---

## Key Source Files for Current Work

| Area | File |
|------|------|
| Auth routes | `server/src/routes/auth.js` |
| Auth middleware | `server/src/middleware/auth.js` |
| Prisma schema | `server/prisma/schema.prisma` |

---

## In-Flight Work

*(none)*

---

## Decisions Made

- 2026-04-10: Use JWT with short-lived access tokens (15min) and
  httpOnly refresh tokens (7d) rather than session cookies.

---

## Gotchas and Lessons

*(none yet)*

---

## Taskflow's Preferences

- Australian English in all documentation and user-facing strings.
- Terse commit messages — one line, no body unless the change is complex.

---

## Completed Work

*(none yet)*

---

## Archived

*(none yet)*
```

Key points:
- Key Source Files is populated with the files relevant to your first phase, not every file in the repo.
- Decisions Made should have at least one entry — the first architectural choice you made. Date it.
- Preferences captures how this project wants agents to behave. If you have no preferences yet, leave it empty.

---

## Step 6 — Create docs/feature-map.md

```markdown
# Taskflow — Feature Map & Roadmap

Last updated: 2026-04-10

---

## Shipped Features

| P# | Feature | Path/PR | Shipped |
|----|---------|---------|---------|

---

## Roadmap

### High Priority

| P# | Feature | Path |
|----|---------|------|
| P1 | User authentication | `server/src/routes/auth.js` |
| P2 | Task CRUD API | `server/src/routes/tasks.js` |

### Medium Priority

| P# | Feature | Path |
|----|---------|------|
| P3 | React dashboard | `client/src/pages/Dashboard.tsx` |
| P4 | Email notifications | `server/src/services/email.js` |
```

The Shipped table is empty on a new project. It fills up as you ship work.

---

## Step 7 — Create docs/build-plans/phase-0-foundation.md

Start from the build plan template (`docs/templates/build-plan-template.md`).

```markdown
# Phase 0 — Foundation

Status: In Progress

---

## Problem

Taskflow needs authentication and core task management before any UI work
can begin. This phase establishes the data model, auth system, and API
endpoints that everything else depends on.

---

## Scope

| Batch | What | Priority |
|-------|------|----------|
| 0.1 | Prisma schema + initial migration | P0 |
| 0.2 | Auth routes (register, login, refresh) | P0 |
| 0.3 | Task CRUD routes | P1 |
| 0.4 | Integration test suite | P1 |

---

## Architecture

- Express with route-level middleware for auth
- Prisma ORM with PostgreSQL
- JWT access tokens (15min) + httpOnly refresh tokens (7d)
- Vitest for testing with supertest for HTTP assertions

---

## Key Decisions Locked In

- [LOCKED] JWT over session cookies — stateless API, easier to scale
- [LOCKED] Prisma over raw SQL — type safety and migration tooling

---

## Batch Log

*(no batches shipped yet)*

---

## Deploy Checklist

- [ ] Auth routes return correct status codes and tokens
- [ ] Task CRUD respects user scoping
- [ ] All tests passing with 80%+ coverage
- [ ] Backlog.md statuses updated for P1 and P2
- [ ] docs/feature-map.md updated with shipped items

---

## Open Questions

*(none)*
```

---

## Step 8 — Set up local files

These files live on your machine, not in git.

### project_resume.md

Location: `~/.claude/projects/[project-hash]/memory/project_resume.md`

You do not need to create this manually. On your first Claude Code session, the agent will create it as part of the session end checklist. If you want to seed it:

```markdown
# Session Resume — Taskflow

Last updated: 2026-04-10

## What was done
Initial SOP setup — created CLAUDE.md, Backlog.md, agent-memory.md,
feature-map.md, and phase-0 build plan.

## What is next
P1 — User authentication (register, login, refresh routes).

## Blockers
(none)
```

### MEMORY.md

Location: `~/.claude/projects/[project-hash]/memory/MEMORY.md`

This is an index of auto-memory files. It will be populated automatically as Claude Code stores memories. You can seed it with a pointer to the resume file:

```markdown
- [Project resume](project_resume.md) — Current session state for Taskflow
```

---

## Step 9 — Optional: brand voice, hooks, and agents

These are not required for basic SOP compliance, but recommended for mature projects.

### Brand voice (`.claude/brand-voice.md`)

If your project has user-facing text (UI copy, emails, docs), create a brand voice file:

```markdown
- Tone: direct, professional, no jargon
- Australian English spelling (colour, organisation, favour)
- No exclamation marks in UI copy
- Error messages: state what happened, then what to do
```

### Hooks (`.claude/settings.json`)

See `docs/sop/harness-configuration.md` for 6 reference implementations. The two most valuable for a new project:

1. **SessionStart** — auto-reads CLAUDE.md and agent-memory.md
2. **PreCompact** — reminds the agent to run the session end checklist before context compaction

### Review agents (`.claude/agents/`)

Copy `code-reviewer.md` and `security-reviewer.md` from the agent-sop repo's `.claude/agents/` directory. Customise the stack-specific sections for your project.

---

## Step 10 — Initial commit and first session

```bash
git add CLAUDE.md Backlog.md docs/
git commit -m "docs: implement Agent SOP — standard file set and session checklists"
```

Your first Claude Code session should begin with the agent reading CLAUDE.md and confirming the setup. A well-configured project lets the agent orient in under 2 minutes and start productive work immediately.

---

## Checklist — Did you get everything?

- [ ] `CLAUDE.md` exists with all required sections filled in (no bracket placeholders)
- [ ] `Backlog.md` exists with tag taxonomy and at least one P-numbered item
- [ ] `docs/agent-memory.md` exists with all 8 sections
- [ ] `docs/feature-map.md` exists with Last Updated header and Roadmap entries
- [ ] `docs/build-plans/phase-0-foundation.md` exists with Problem, Scope, and Architecture
- [ ] Key Documents table in CLAUDE.md has at least 5 entries with real file paths
- [ ] Session start and end checklists are present in CLAUDE.md
- [ ] All files are committed to git

---

## What happens next

With the SOP in place, every Claude Code session follows the same rhythm:

1. **Start** — agent reads CLAUDE.md, agent-memory.md, resume point, recent git history
2. **Work** — agent picks up the next Backlog item, follows the build plan
3. **End** — agent updates all tracking files, commits, writes the resume snapshot

The SOP eliminates the "where was I?" problem across sessions. Context is always recoverable, decisions are always traceable, and no work is ever silently lost.
