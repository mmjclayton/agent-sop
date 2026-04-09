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
`[SHIPPED - 2026-04-08] [Feature]`

Publish agent-memory.md template as `docs/templates/agent-memory-template.md`.

**Acceptance criteria:**
- File exists at `docs/templates/agent-memory-template.md` - DONE
- Contains all 8 sections: Key Documents, Key Source Files, In-Flight Work, Decisions Made, Gotchas, Preferences, Completed Work, Archived - DONE
- Each section has a comment explaining what belongs there (including expanded Gotchas definition) - DONE

---

### P4 — Backlog template
`[SHIPPED - 2026-04-08] [Feature]`

Publish Backlog.md template as `docs/templates/backlog-template.md`.

**Acceptance criteria:**
- File exists at `docs/templates/backlog-template.md` - DONE
- Includes tag taxonomy header - DONE
- Includes example P-numbered item with all fields: status, type, description, ACs, out of scope, open questions - DONE
- Includes Shipped Archive section - DONE

---

### P5 — Build plan template
`[SHIPPED - 2026-04-08] [Feature]`

Publish phase build plan template as `docs/templates/build-plan-template.md`.

**Acceptance criteria:**
- File exists at `docs/templates/build-plan-template.md` - DONE
- Contains all 7 sections per SOP spec - DONE
- Batch Log section notes append-only format with date and PR/commit format - DONE
- Open Questions notes answered questions stay with [RESOLVED] marker - DONE

---

### P6 — New project walkthrough
`[SHIPPED - 2026-04-08] [Feature]`

Write example guide at `docs/examples/new-project-walkthrough.md`.

**Acceptance criteria:**
- Covers: directory setup, git init, creating each standard file, first Claude Code session - DONE
- Uses a concrete example project (Taskflow — task management API) - DONE
- References templates by path - DONE

---

### P7 — Existing project migration guide
`[SHIPPED - 2026-04-08] [Feature]`

Write migration guide at `docs/examples/existing-project-migration.md`.

**Acceptance criteria:**
- Covers minimum viable migration steps from SOP Section 13 - DONE
- Checklist format - DONE
- Notes common gaps found in existing projects - DONE

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
`[SHIPPED - 2026-04-08] [Feature]`

Added 6 new compliance checks across a new Section 9: S1 (no secrets, Critical), S2 (security doc, Important), Q1 (file size limits, Important code-only), Q2 (test coverage threshold, Important code-only), H1 (hooks documented, Recommended), G1 (2+ review agents, Recommended). Updated sop-checker agent with new Phase 4 for these checks.

**Acceptance criteria:**
- 6 new checks added to `docs/sop/compliance-checklist.md` - DONE
- Summary table updated with new totals - DONE
- sop-checker agent updated to know about new checks - DONE
- S1 is Critical (10pts), S2/Q1/Q2 are Important (5pts), H1/G1 are Recommended (2pts) - DONE

---

### P21 — Setup script for new projects
`[SHIPPED - 2026-04-08] [Feature]`

Bash onboarding script (`setup.sh`) that copies the standard file set into a target project directory.

**Acceptance criteria:**
- Script exists at repo root as `setup.sh`, executable - DONE
- Copies CLAUDE.md, Backlog.md, agent-memory.md, feature-map.md, build plan, core SOP doc - DONE
- Supports `--code` flag for code project template - DONE
- Supports `--force` flag to overwrite existing files - DONE
- Skips existing files by default with clear messaging - DONE
- Prints next steps including compliance checker command - DONE
- README updated to recommend the script as the primary setup path - DONE

---

### P22 — Session slash commands (/restart-sop, /update-sop)
`[SHIPPED - 2026-04-08] [Feature]`

Two Claude Code slash commands that automate the session start and end checklists.

**Acceptance criteria:**
- `.claude/commands/restart-sop.md` exists with YAML frontmatter - DONE
- `.claude/commands/update-sop.md` exists with YAML frontmatter - DONE
- Commands execute the full session checklists from the SOP - DONE
- setup.sh copies commands into target projects - DONE
- README, core SOP, both templates, and implementation guide reference commands as mandatory - DONE
- Commands installed at user level (`~/.claude/commands/`) for all projects - DONE

---

### P23 — SOP Benchmark Framework
`[SHIPPED - 2026-04-09] [Feature]`

A/B testing framework to measure Agent SOP effectiveness. Runs identical tasks against hst-tracker with two conditions: full SOP context vs bare repo. Uses git worktrees for isolation.

**Acceptance criteria:**
- Framework doc at `docs/benchmark/README.md` with methodology, scoring rubric, limitations - DONE
- 4 task specs in `docs/benchmark/tasks/` covering refactor, test writing, feature - DONE
- Runner script at `docs/benchmark/run-benchmark.sh` (setup, run, score, cleanup) - DONE
- Baseline stub doc at `docs/benchmark/nosop-stub.md` - DONE
- Non-destructive: uses worktrees, never touches main, no DB access
- Results template in `docs/benchmark/results/`
- At least one full benchmark run completed with scored results

---

### P24 — Multi-agent optimisation guide
`[OPEN] [Feature]`

Guidance for multiple agents working in the same repo efficiently. Token cost management, context sharing, conflict avoidance, worktree patterns.

**Open questions:** Scope TBD after benchmark results inform what matters most.

---

### P25 — Incorporate benchmark findings into SOP
`[SHIPPED - 2026-04-09] [Iteration]`

Update all SOP documents to incorporate benchmark-proven practices: Common Mistakes section (required for code projects), intent-rich dispatch pattern, vague prompt resilience guidance.

**Acceptance criteria:**
- Core SOP Section 15 added (Benchmark-Proven Practices) with 3 subsections - DONE
- Base template updated with Common Mistakes scaffold and intent-rich dispatch - DONE
- Code template updated with code-specific Common Mistakes examples and intent-rich dispatch - DONE
- Compliance checklist updated with 4 new checks (BP1-BP4) across Section 10 - DONE
- Implementation guide updated to reference Common Mistakes as required - DONE
- README updated with benchmark results section and findings - DONE
- SOP section index updated - DONE

---

### P26 — Benchmark-driven SOP optimisations
`[SHIPPED - 2026-04-09] [Iteration]`

Applied all optimisations derived from benchmark data analysis:
1. Common Mistakes mandatory for code projects (was recommended)
2. CLAUDE.md per-session limit raised to 300 lines for code projects with Common Mistakes
3. Intent-only dispatch format enforced (old Area|File deprecated)
4. Lightweight session start for [ok-for-automation] tasks
5. Multi-agent context routing (Section 16): task-type → context tier → agent config
6. agent-memory.md optional for projects with fewer than 10 sessions
7. Benchmark safety rules: no push to main, worktree-only, sequential batches
8. Naming convention gotcha requirement in Common Mistakes template

---

### P27 — Managed Agents integration and outcome rubrics
`[SHIPPED - 2026-04-09] [Feature]`

Integrated Claude Managed Agents API patterns into the SOP. Six components:
1. Outcome rubrics (Definition of Done) — self-evaluation before shipping, per-task-type rubrics in CLAUDE.md templates and SOP Section 12
2. Permission policy safety guidance for benchmarks — API-level enforcement via tool configs
3. Multi-agent callable patterns in Section 16 — coordinator + specialist configs with tool restrictions
4. Managed Agents benchmark harness design — isolated containers, mounted repos, user.define_outcome scoring
5. Section 17 Managed Agents Integration Guide — memory store mapping, skills guidance, session lifecycle mapping, outcome rubrics
6. Reference notes for low-impact items (memory stores, skills as lazy context, append-only events)

---

### P28 — Research digest implementation (v2.1.97, context management, evolution loop)
`[SHIPPED - 2026-04-09] [Feature]`

5 changes from the weekly research digest:
1. sop-checker S3: no --dangerously-skip-permissions flag
2. docs/sop/context-management.md: compaction, clearing, memory API reference
3. Memory API note in SOP Section 1
4. SOP Section 18: Evolution loop with benchmark-proven principles
5. docs/guides/sop-hill-climbing.md: iterative improvement methodology

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
- P20 — Compliance checklist update — SHIPPED 2026-04-08
- P3 — Agent memory template — SHIPPED 2026-04-08
- P4 — Backlog template — SHIPPED 2026-04-08
- P5 — Build plan template — SHIPPED 2026-04-08
- P6 — New project walkthrough — SHIPPED 2026-04-08
- P7 — Existing project migration guide — SHIPPED 2026-04-08
- P21 — Setup script for new projects — SHIPPED 2026-04-08
- P22 — Session slash commands — SHIPPED 2026-04-08
- P23 — SOP Benchmark Framework — SHIPPED 2026-04-09
- P25 — Incorporate benchmark findings into SOP — SHIPPED 2026-04-09
- P26 — Benchmark-driven SOP optimisations — SHIPPED 2026-04-09
- P27 — Managed Agents integration and outcome rubrics — SHIPPED 2026-04-09
- P28 — Research digest implementation — SHIPPED 2026-04-09
