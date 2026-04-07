# Agent SOP — Backlog

Single source of truth for all work items. Never delete without a trace — update in place, mark superseded, or archive.

## Tag Taxonomy

- Status (first): `[OPEN]` `[IN PROGRESS]` `[SHIPPED - YYYY-MM-DD]` `[VERIFIED - YYYY-MM-DD]` `[WON'T]`
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

## Shipped Archive

*Items below are shipped or verified. Never removed.*

- P1 — Core SOP document — SHIPPED 2026-04-07
- P2 — CLAUDE.md base template — SHIPPED 2026-04-07 (updated same day to base-only version)
- P11 — CLAUDE.md code project template — SHIPPED 2026-04-07
- P12 — SOP v2: owner feedback iteration — SHIPPED 2026-04-07
