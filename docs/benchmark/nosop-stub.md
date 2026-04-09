# Baseline CLAUDE.md Stub

This is the minimal CLAUDE.md that replaces the full version in the no-SOP condition.
It provides only the bare minimum a Claude Code agent needs to orient: stack, test command, schema location.

No conventions, no dispatch table, no agent memory, no brand voice, no SOP, no build plans.

```markdown
# LOADOUT

- Frontend: React 19, Vite — client/
- Backend: Express 5, Prisma ORM, PostgreSQL 17 — server/
- Tests: npm test (Jest server, Vitest client)
- Schema: server/prisma/schema.prisma
```

## What is stripped from the baseline condition

| File/Directory | Purpose in SOP condition |
|---------------|-------------------------|
| `CLAUDE.md` (full) | Stack, conventions, dispatch, priorities, session checklists |
| `docs/agent-memory.md` | Cross-session decisions, gotchas, data model invariants |
| `docs/sop/claude-agent-sop.md` | Standard operating procedure |
| `docs/sop/security.md` | Security guidance |
| `.claude/agents/` | Sub-agent definitions |
| `.claude/brand-voice.md` | Copy/tone guidelines |
| `.claude/style-guide.md` | Visual design guidelines |
| `.claude/commands/` | Slash commands |
| `.claude/skills/` | Skill definitions |

## Rationale

The baseline agent still has:
- Full source code (can read any file)
- Git history (can run git log)
- Test infrastructure (can run npm test)
- Package.json (can see dependencies)

This means the baseline agent *can* discover everything the SOP provides, it just has to do it through exploration rather than being told. The benchmark measures whether pre-structured context improves outcomes enough to justify its token cost.
