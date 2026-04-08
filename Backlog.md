# Agent SOP — Backlog

Single source of truth for all work items. Never delete without a trace — update in place, mark superseded, or archive.

## Tag Taxonomy

- Status (first): `[OPEN]` `[IN PROGRESS]` `[BLOCKED]` `[SHIPPED - YYYY-MM-DD]` `[VERIFIED - YYYY-MM-DD]` `[WON'T]`
- Type (second): `[Feature]` `[Iteration]` `[Bug]` `[Refactor]`
- Optional: `[has-open-questions]` `[ok-for-automation]`

---

## P-Numbered Items

### P1 — Core SOP document
`[SHIPPED - 2026-04-07] [Feature]`

Publish the main Claude Code Agent SOP as `docs/sop/claude-agent-sop.md`.

**Acceptance criteria:**
- File exists at `docs/sop/claude-agent-sop.md` - DONE
- Contains all 14 sections per the SOP spec (updated 2026-04-07 with research findings - sections renumbered, Section 12 added) - DONE
- Additive-only rule is Section 0 - DONE
- Australian English, no em-dashes - DONE

---

### P2 — CLAUDE.md base template
`[SHIPPED - 2026-04-07] [Feature]`

Publish the base CLAUDE.md template as `docs/templates/claude-md-template.md`. Updated 2026-04-07 to be stack-agnostic with pointers to the code variant.

**Acceptance criteria:**
- File exists at `docs/templates/claude-md-template.md` - DONE
- Stack-agnostic, works for any project type - DONE
- Contains all required sections per SOP spec - DONE
- Includes Deprioritised section - DONE
- Dispatch Quick Reference has table format and 5-file minimum note - DONE
- Recent Work has append-only note - DONE

---

### P11 — CLAUDE.md code project template
`[SHIPPED - 2026-04-07] [Feature]`

Publish the code-project variant as `docs/templates/claude-md-template-code.md`. Extends the base template with Auth, Database, Design System, and code-specific build rules.

**Acceptance criteria:**
- File exists at `docs/templates/claude-md-template-code.md` - DONE
- Includes all base template sections - DONE
- Adds Auth, Database, Design System sections - DONE
- Build rules include test, ORM, migration, and PR description requirements - DONE
- Note at top points back to base template - DONE

---

### P3 — Agent memory template
`[OPEN] [Feature]`

Publish agent-memory.md template as `docs/templates/agent-memory-template.md`.

**Acceptance criteria:**
- File exists at `docs/templates/agent-memory-template.md`
- Contains all 8 sections: Key Documents, Key Source Files, In-Flight Work, Decisions Made, Gotchas, Preferences, Completed Work, Archived
- Each section has a comment explaining what belongs there (including expanded Gotchas definition)

---

### P4 — Backlog template
`[OPEN] [Feature]`

Publish Backlog.md template as `docs/templates/backlog-template.md`.

**Acceptance criteria:**
- File exists at `docs/templates/backlog-template.md`
- Includes tag taxonomy header
- Includes example P-numbered item with all fields: status, type, description, ACs, out of scope, open questions
- Includes Shipped Archive section

---

### P5 — Build plan template
`[OPEN] [Feature]`

Publish phase build plan template as `docs/templates/build-plan-template.md`.

**Acceptance criteria:**
- File exists at `docs/templates/build-plan-template.md`
- Contains all 7 sections per SOP spec
- Batch Log section notes append-only format with date and PR/commit format
- Open Questions notes answered questions stay with [RESOLVED] marker

---

### P6 — New project walkthrough
`[OPEN] [Feature]`

Write example guide at `docs/examples/new-project-walkthrough.md`.

**Acceptance criteria:**
- Covers: directory setup, git init, creating each standard file, first Claude Code session
- Uses a concrete example project
- References templates by path

---

### P7 — Existing project migration guide
`[OPEN] [Feature]`

Write migration guide at `docs/examples/existing-project-migration.md`.

**Acceptance criteria:**
- Covers minimum viable migration steps from SOP Section 12
- Checklist format
- Notes common gaps found in existing projects

---

### P8 — Web app domain variant
`[OPEN] [Feature] [has-open-questions]`

**Open questions:** What web-app-specific sections beyond the base SOP? Separate doc or addendum?

---

### P9 — Marketing domain variant
`[OPEN] [Feature] [has-open-questions]`

**Open questions:** What content/marketing-specific sections are needed?

---

### P10 — Data/analytics domain variant
`[OPEN] [Feature] [has-open-questions]`

**Open questions:** What data-specific sections are needed?

---

### P12 — SOP v2: owner feedback iteration
`[SHIPPED - 2026-04-07] [Iteration]`

Apply project owner feedback from multi-session usage. 10 changes:

1. Reframe "additive-only" to "never delete without a trace" — allow in-place updates
2. Delineate agent-memory.md (repo, contributor facts) vs auto-memory (local, user prefs)
3. Add test gates to session-end checklist
4. Change project_resume.md from prepend-only to snapshot (overwrite)
5. Add explicit conflict resolution precedence (code/git > Backlog > build-plan > feature-map > agent-memory > resume)
6. Add schema change protocol to SOP and code template
7. Add Backlog archive threshold guidance (~2,000 lines)
8. Add "no derived facts in memory" rule
9. Expand multi-agent contention for code conflicts
10. Propagate all changes to both templates, CLAUDE.md, agent-memory.md

---

### P13 — SOP Compliance Checker Agent
`[SHIPPED - 2026-04-07] [Feature]`

Agent that audits any project folder against the Claude Code Agent SOP and produces a scored compliance report with actionable recommendations.

**Acceptance criteria:**
- `.claude/agents/sop-checker.md` exists with agent definition - DONE
- `docs/sop/compliance-checklist.md` exists with all checks, weights, and scoring formula - DONE
- Agent correctly detects code vs non-code projects - DONE
- Agent produces a scored markdown report with per-check PASS/FAIL - DONE
- Report includes "Top Recommendations" and "Path to 100%" sections - DONE
- Agent is read-only — never modifies target project files - DONE
- Checklist covers: file existence, section presence, tag format, date format, P-number sequencing, cross-file consistency, memory system separation - DONE
- Scoring uses Critical/Important/Recommended tiers with critical-failure cap at 49 - DONE

---

### P14 — Security guidance document
`[SHIPPED - 2026-04-08] [Feature]`

Agent security guidance at `docs/sop/security.md`. Covers prompt injection awareness, secret scanning, MCP trust boundaries, sandbox guidance for autonomous runs, memory hygiene for untrusted work, and minimum bar checklist.

**Acceptance criteria:**
- File exists at `docs/sop/security.md` - DONE
- Covers prompt injection, secret scanning, MCP trust, sandbox, memory hygiene - DONE
- Includes detection scan commands - DONE
- Australian English, no em-dashes - DONE
- Adapted from ECC security guide, not copied - DONE

---

### P15 — Hooks guidance document
`[SHIPPED - 2026-04-08] [Feature]`

Hooks guidance at `docs/sop/hooks.md`. Explains hook types and provides 6 reference implementations: SessionStart auto-read, SessionEnd/PreCompact checklist trigger, pre-commit quality gate, git push review, post-edit type check, pattern extraction on Stop.

**Acceptance criteria:**
- File exists at `docs/sop/hooks.md` - DONE
- Covers all 6 hook types (PreToolUse, PostToolUse, SessionStart, SessionEnd, PreCompact, Stop) - DONE
- 6 reference implementations with JSON config examples - DONE
- Combined hooks configuration example - DONE
- Security note about project-scope hooks - DONE

---

### P16 — Code quality rules in code template
`[SHIPPED - 2026-04-08] [Feature]`

Added Code Quality Rules section to `docs/templates/claude-md-template-code.md` covering: file size limits, immutability, error handling, import ordering, test coverage, linting/type checking, no debug artifacts, function size.

**Acceptance criteria:**
- Section exists in `docs/templates/claude-md-template-code.md` - DONE
- Language-agnostic defaults with note to add language-specific rules - DONE
- Covers all 8 areas from spec - DONE

---

### P17 — Reference agent definitions
`[SHIPPED - 2026-04-08] [Feature]`

Created 4 reference agents in `.claude/agents/`: code-reviewer.md, security-reviewer.md, planner.md, e2e-runner.md.

**Acceptance criteria:**
- 4 agent files exist in `.claude/agents/` - DONE
- Format matches existing sop-checker.md (YAML frontmatter with name, description, tools, model) - DONE
- code-reviewer: read-only, structured severity output - DONE
- security-reviewer: OWASP Top 10, secret detection, read-only - DONE
- planner: produces structured build plans, read-only - DONE
- e2e-runner: Playwright tests, artifact capture - DONE

---

### P18 — Expand code template sections
`[SHIPPED - 2026-04-08] [Feature]`

Fleshed out Auth (provider, token type, middleware, protected routes), Database (ORM, migration tool, naming, query patterns, schema change protocol), Key Commands (examples for dev, test, single test, migration, lint, type-check, build), Design System (component library, typography, spacing, responsive strategy, icon system) in `docs/templates/claude-md-template-code.md`.

**Acceptance criteria:**
- Auth has 8 fields including middleware and protected routes pattern - DONE
- Database has 8 fields including ORM, migration tool, schema change protocol - DONE
- Key Commands has example entries for all required categories - DONE
- Design System has 10 fields including component library, spacing, typography, icons - DONE

---

### P19 — Continuous learning pattern
`[SHIPPED - 2026-04-08] [Feature]`

Added continuous learning as an optional pattern in SOP Section 12. Covers what to extract, where to store, extraction cadence (every session + every 5 sessions audit + promotion at 3+ repeats), automated extraction via hooks, and exclusions.

**Acceptance criteria:**
- Pattern added to Section 12 of `docs/sop/claude-agent-sop.md` - DONE
- Covers what to extract and where to store - DONE
- Includes periodic review guidance (every 5 sessions) - DONE
- References hooks.md for automated extraction - DONE
- Clarifies what does not belong - DONE

---

### P20 — Compliance checklist update (security, hooks, quality, agents)
`[OPEN] [Feature]`

Add new compliance checks for security, hooks, code quality, and agent availability.

---

## Shipped Archive

*Items below are shipped or verified. Never removed.*

- P1 — Core SOP document — SHIPPED 2026-04-07
- P2 — CLAUDE.md base template — SHIPPED 2026-04-07 (updated same day to base-only version)
- P11 — CLAUDE.md code project template — SHIPPED 2026-04-07
- P12 — SOP v2: owner feedback iteration — SHIPPED 2026-04-07
- P13 — SOP Compliance Checker Agent — SHIPPED 2026-04-07
- P14 — Security guidance document — SHIPPED 2026-04-08
- P15 — Hooks guidance document — SHIPPED 2026-04-08
- P16 — Code quality rules in code template — SHIPPED 2026-04-08
- P17 — Reference agent definitions — SHIPPED 2026-04-08
- P18 — Expand code template sections — SHIPPED 2026-04-08
- P19 — Continuous learning pattern — SHIPPED 2026-04-08
