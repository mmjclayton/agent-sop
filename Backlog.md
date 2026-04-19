# Agent SOP — Backlog

Single source of truth for all work items. Never delete without a trace — update in place, mark superseded, or archive.

## Tag Taxonomy

- Status (first): `[OPEN]` `[IN PROGRESS]` `[BLOCKED]` `[DEFERRED]` `[SHIPPED - YYYY-MM-DD]` `[VERIFIED - YYYY-MM-DD]` `[WON'T]`
- Type (second): `[Feature]` `[Iteration]` `[Bug]` `[Refactor]`
- Optional: `[has-open-questions]` `[ok-for-automation]`
- `[BLOCKED]` = waiting on external action. `[DEFERRED]` = intentionally postponed with no external blocker.

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

### P29 — Pre-launch README polish + LICENSE + minimum version note
`[SHIPPED - 2026-04-13] [Infra]`

Pre-traffic audit and polish for the public agent-sop repo. Six items:
1. MIT LICENSE file added (was missing — blocker for reuse).
2. Compliance check count corrected to 75 (66 non-code) — was inconsistent (~70/~74).
3. Status section rewritten for outside readers; removed internal P-number jargon.
4. Agent-driven setup paths generalised to `<AGENT_SOP_PATH>` placeholder.
5. Badges added at top of README (license, Claude Code version, benchmark, status).
6. Table of contents added under intro.

Also added Requirements section recommending Claude Code v2.1.101+ (memory leak,
permission, --resume fixes), with non-blocking version check in setup.sh.

Commits be449ac (version note) and 605cf60 (README polish + LICENSE).

---

### P30 — Research digest review (2026-04-13) — verdict only, no implementation bundle
`[SHIPPED - 2026-04-13] [Iteration]`

Reviewed weekly research digest covering Trustworthy Agents framework,
Claude Code v2.1.101 changelog, Claude Code source-leak architecture patterns,
and OpenAI AgentKit. All 4 sources verified directly via WebFetch/WebSearch
(AgentKit date in digest was wrong — actual launch was Oct 2025, not Apr 2026).

Initial Tier 1 slate (4 items) reduced to 1 after honest re-evaluation:
adding without sharpening violates the benchmark-proven principle that
sharpening wins. Only the Claude Code v2.1.101+ version note shipped (P29).
All other suggestions rejected (3 new compliance checks — duplicates existing
guidance; cargo-culted "do not rubber-stamp" prompt — untested; AgentKit
competitive section — distraction; version check in sop-checker — over-engineered;
compaction failure rule — too rare to justify).

**Lesson:** Research digests bias toward "things to add". Default position
should be "what does this remove or sharpen". Apply this filter before
proposing changes from future digests.

---

### P43 — Parallel multi-agent session support
`[IN PROGRESS] [Feature]`

*2026-04-19: Batches 1.1 through 1.6 shipped. Batch 1.7 playbook drafted; dogfood execution deferred to a Matt-hands multi-session run. Status moves to SHIPPED once the dogfood pass completes cleanly.*

Enable 3-5 Claude Code terminal instances on separate git worktrees to run `/update-sop` and `/restart-sop` concurrently without manual conflict resolution or human-in-the-loop co-ordination. Today the SOP mandates sequential merges and append patterns (prepend to Recent Work, overwrite `project_resume.md`) that guarantee conflicts when two agents end sessions in the same window.

**Root cause:** single-agent assumptions in `/update-sop` write patterns — prepend to `CLAUDE.md` Recent Work, overwrite of `project_resume.md`, mutable `Last updated` headers, implicit commit ranges for Step 3b reconciliation, no agent identity concept.

**Approach:** worktree + branch isolation already partitions code. Extend the same partitioning to tracking files via directory-per-entry for high-conflict sections (Recent Work, Decisions, Gotchas), per-agent resume files, and commit-range partitioning via `git merge-base main HEAD..HEAD`. Single-agent projects migrate to the same format with a `solo` default id — one format, not two.

**Key decisions locked in** (see `docs/build-plans/phase-1-parallel-sessions.md` Key Decisions):
- Agent-id = `sha256(worktree-path)[:6]`, override via `CLAUDE_AGENT_ID` or `.sop-agent-id` file
- `project_resume_<agent-id>.md` per-agent; `solo` default for single-agent
- Directory-per-entry for Recent Work, Decisions, Gotchas — rollup summary kept in CLAUDE.md
- Commit-range via merge-base (no author trailers, no git config changes)
- Single format for all projects — migration command handles existing projects
- Build in agent-sop, dogfood on hst-tracker (3 parallel worktrees)
- Single P43 in new Phase 1 — not decomposed

**Batches** (full detail in `docs/build-plans/phase-1-parallel-sessions.md`):
1. 1.1 — Agent-ID detection + config field
2. 1.2 — Directory-per-entry extractions + CLAUDE.md rollup
3. 1.3 — Commit-range partitioning (Step 3b, Step 11, /restart-sop Step 4)
4. 1.4 — P-number renumber-on-merge
5. 1.5 — Core SOP rewrites + compliance checks M1-M5
6. 1.6 — Migration command `/update-sop --migrate-to-multi-agent`
7. 1.7 — Dogfood on hst-tracker

**Acceptance criteria:**
- 3 agents on 3 worktrees each running `/update-sop` sequentially at different times produce zero manual conflict resolution on merge to main
- `agent-sop` itself runs in the new format (self-hosting proof)
- hst-tracker dogfood pass: 3 parallel tasks × 3 `/update-sop` × 3 sequential merges = 0 conflicts
- Compliance checks M1-M5 added to `sop-checker` agent
- Single-agent projects (agent-id = `solo`) behave identically to current single-agent workflow
- `/update-agent-sop` baselines refreshed for all touched pristine-replica files
- Core SOP instruction count still under 200 hard ceiling (Rule 5)
- All tracking files updated (Backlog, feature-map, agent-memory, build plan, CLAUDE.md)

---

### P42 — Secondary-tracker reconciliation + [DEFERRED] tag
`[SHIPPED - 2026-04-19] [Iteration]`

Close a gap surfaced by hst-tracker: `/update-sop` treated `Backlog.md` as the sole work tracker and never reconciled project-specific secondary trackers (audit-backlog, security-findings, etc.) that use the same status-tag taxonomy. Silent drift left 118 shipped audit items marked `[OPEN]` in hst-tracker's `audit-backlog-2026-04-18.md` for a full day.

**Root cause:** SOP Section 6 session-end checklist and `/update-sop` Step 3 named only `Backlog.md`. No auto-detection of secondary trackers, no cross-check between commit IDs and tracker status at session end, no session-start guard to catch drift from a prior session.

**Secondary gap:** `[BLOCKED]` conflated "waiting on external action" with "intentionally postponed". `[DEFERRED]` needed as a distinct status for conscious postponement.

**Deliverables:**

1. **Core SOP Section 6** — session-end checklist gained a new step (3) for secondary-tracker reconciliation; total steps 7 → 8.
2. **Core SOP Section 8** — `[DEFERRED]` added with distinction vs `[BLOCKED]`.
3. **`/update-sop` command** — new Step 3b with auto-detection heuristic (scan .md files in CLAUDE.md Key Documents for heading-level status tags; skip `Backlog.md`). Step 11 report extended with hard-block reconciliation check: any finding ID in this session's commits still `[OPEN]` must be reconciled before commit.
4. **`/restart-sop` command** — Step 4 gained a drift guard: grep last 10 commits for finding IDs, verify matching entries not still `[OPEN]`. Advisory only (does not auto-reconcile).
5. **Templates** — `backlog-template.md`, `claude-md-template.md`, `claude-md-template-code.md` updated with `[DEFERRED]` and the new session-end step.
6. **Compliance checklist** — B4 now accepts `[DEFERRED]`; new check X6 (secondary tracker currency). Summary table totals: non-code 66→67, code 75→76.
7. **Version markers** — all touched pristine-replica files bumped from `2026-04-17` to `2026-04-19`.

**Heuristic design choice:** auto-detect over explicit opt-in. Explicit opt-in (a `secondary_trackers` array in `agent-sop.config.json`) recreates the original failure mode at a different level — user adds a new tracker file, forgets to register it, reconciliation silently skips it. Auto-detection scans `.md` paths from CLAUDE.md Key Documents and matches `^##+ .*\[(OPEN|IN PROGRESS|BLOCKED|DEFERRED|SHIPPED|VERIFIED|WON.T)` at heading level only. Inline prose mentions don't match. Escape hatch: the existing `exclude` config follow-up (from the hst-tracker audit) can double as `exclude_from_tracker_scan` when it ships.

**Acceptance criteria:**
- Core SOP Section 6 has 8 steps, new step is secondary-tracker reconciliation - DONE
- Core SOP Section 8 has `[DEFERRED]` with semantic distinction from `[BLOCKED]` - DONE
- `/update-sop` Step 3b has detection heuristic + per-ID reconciliation + hard-block check in Step 11 - DONE
- `/restart-sop` Step 4 has advisory drift guard - DONE
- All three templates updated (`backlog-template.md`, `claude-md-template.md`, `claude-md-template-code.md`) - DONE
- Compliance checklist B4 accepts `[DEFERRED]`; new X6 check added; summary table totals corrected - DONE
- Version markers bumped on all touched pristine-replica files - DONE
- Tracking files updated (Backlog, feature-map, agent-memory, build plan, CLAUDE.md, project_resume) - DONE

---

### P41 — README rewrite, License section, Acknowledgements removed, GitHub About refresh
`[SHIPPED - 2026-04-17] [Iteration]`

README aligned to popular reference-repo aesthetic (claude-code-action, superpowers) and tightened to the project's actual purpose.

**Deliverables:**

1. **README compressed 465 → 119 lines.** Removed: TOC, the token-efficiency math wall, four-table What's Included block, repository tree, expanded session-checklist steps, expanded six-rules commentary, A/B benchmark badge.
2. **Hero reframed.** New opening: "Standard operating procedures and product management discipline for Claude Code sessions." Anchors the project's purpose on the standard file set and three slash commands rather than abstract benefits.
3. **New Backlog discipline + Cross-session memory sections.** Ground the PM-discipline angle in concrete file behaviour (status/type tag order, P-numbers, append-only batch logs, status-only-in-Backlog rule, snapshot vs log semantics).
4. **License section added.** Dedicated section near bottom (badge alone is conventional but a section is more discoverable).
5. **Acknowledgements section removed.** Verbatim review against `~/Projects/everything-claude-code` confirmed no copied prose. Structural similarities (YAML frontmatter, OWASP Top 10 enumeration, Playwright CLI listings) are public-spec / required-syntax / common patterns. Pattern inspiration does not trigger MIT attribution requirements.
6. **All opinion-coded language stripped.** Per Section 0 Rule 3 (state facts).
7. **GitHub About description rewritten** to match the new framing (~330 chars).

**Acceptance criteria:**
- README under 150 lines - DONE (119)
- Hero leads with operating-practice + PM-discipline framing - DONE
- No fabricated cross-references (e.g. `docs/token-efficiency.md` did not exist; not introduced) - DONE
- All numbers measured fresh against current repo state - DONE
- License section present - DONE
- Acknowledgements removed only after verbatim review - DONE
- Tracking files updated (Backlog, feature-map, agent-memory, build plan) - DONE

**Commits:** 38a3476 (rewrite), e36cb53 (badge removal), session-end housekeeping commit pending.

---

### P40 — Section 14 + Section 15.4 trim, CLAUDE.md Recent Work + agent-memory.md Decisions compaction
`[SHIPPED - 2026-04-17] [Iteration]`

Mechanical trim batch flagged from the P32-P39 session. Two SOP-content moves and two tracking-file gardening passes.

**Deliverables:**

1. **Section 14 Common Mistakes table → guide.** Full 14-row table moved to `docs/guides/sop-common-mistakes.md` (new). Section 14 in `docs/sop/claude-agent-sop.md` replaced with one-line pointer that also distinguishes from the per-project Section 15.1 template. Net cost in core SOP: ~-12 instructions.

2. **Section 15.4 Managed Agents API safety block → managed-agents-integration guide.** The 7-line "Managed Agents API safety" subsection moved into `docs/guides/managed-agents-integration.md` under a new "Benchmark safety (Managed Agents API)" section. Section 15.4 in core SOP retains the local-Claude-Code safety rules plus a one-line pointer to the guide.

3. **CLAUDE.md Recent Work compacted.** 16 entries (8 expanded 2026-04-17 + earlier session-day entries) collapsed to 6 entries: P40 entry + a single rolled-up P32-P39 entry referencing build-plan Batch 0.13, plus rolled-up entries for 2026-04-13, 2026-04-09, 2026-04-08, 2026-04-07. Full per-item detail still lives in agent-memory.md Decisions, build-plan Batch Log, and per-item Backlog entries. CLAUDE.md: 183 → 153 lines.

4. **agent-memory.md Decisions audited.** Pre-2026-04-09 entries (initial scaffold + ECC adaptation + token optimisation phase) moved to a new "Pre-2026-04-09 Decisions (relocated 2026-04-17 / P40)" subsection inside Archived, with a header explaining the move and noting that encoded rules live in the SOP docs themselves. Active Decisions section now contains 2026-04-09 onwards only.

**Acceptance criteria:**
- `docs/guides/sop-common-mistakes.md` exists with full Section 14 table preserved verbatim - DONE
- `docs/guides/managed-agents-integration.md` has new "Benchmark safety (Managed Agents API)" section with the moved block - DONE
- Core SOP Section 14 replaced with one-line pointer - DONE
- Core SOP Section 15.4 retains local rules + one-line pointer for Managed Agents block - DONE
- CLAUDE.md Recent Work compacted; under 200-line hard limit - DONE
- agent-memory.md Decisions section audited; pre-cutoff entries moved to Archived (preserved, not deleted) - DONE
- All four tracking files updated (Backlog, feature-map, agent-memory, build plan) - DONE
- Core SOP instruction count drops by ~10-12 - DONE

**Why this matters:** ~178 instructions in core SOP for the first time since Rule 5 was added (P32) — under the 150 soft cap target. CLAUDE.md and agent-memory.md Decisions sections are loaded into context every session start; both are now significantly slimmer.

---

### P39 — Measurement gap closed: hygiene rubric + continuity benchmark + longitudinal exhibit
`[SHIPPED - 2026-04-17] [Feature]`

The R1/R2/R5 code-quality benchmarks measure single-task quality. They end at "code shipped" and do not measure what the SOP's actual product is: a project state the next session can pick up cleanly. This gap was closed with three additions.

**Deliverables:**

1. **Session-hygiene scoring rubric** (appended to `docs/benchmark/README.md`) — 7 extra dimensions scored after each benchmark task: test gate, Backlog update, feature-map append, agent-memory capture, build-plan batch log, project_resume snapshot, docs/ commit. 0/1 per dimension. Baseline scores 0/7 by construction (no tracking files exist); SOP should score 6-7/7 with a disciplined agent. Demonstrative measurement, not comparative in the usual sense.

2. **Continuity benchmark methodology** (`docs/benchmark/continuity-methodology.md`) — dependent task pairs. Task 1 naturally surfaces an adjacent bug that an SOP agent captures in `agent-memory.md`; task 2's vague prompt depends on that captured context. Baseline has nowhere to look; SOP agent reads the gotcha at session start. Sample pair included (tonnage client-side + adjacent server-side gap). Scoring emphasises task-2 tool-call count and time-to-locate.

3. **Longitudinal exhibit** (appended to `docs/benchmark/README.md` + summary in main `README.md`) — measured artefact counts from hst-tracker: 86 dated decisions, 23 build-plan batch-log entries, 18 CLAUDE.md Recent Work entries, 64 docs/-only commits, 4,628 lines across the four tracking files. A no-SOP project of equivalent age has 0 of each. Makes the continuity value visible without running any agent.

**Why this matters for the value story:** the +16-33% R2/R5 scores capture single-task benefit. The 86 decisions, 23 batch entries, etc. capture the compounding lifetime value. Two dimensions, both worth measuring; previously only the first was.

**Artefacts:**
- `docs/benchmark/README.md` (updated with hygiene rubric + longitudinal exhibit)
- `docs/benchmark/continuity-methodology.md` (new)
- `README.md` (new "What the benchmarks don't measure" section)

**Deferred:** actually running the continuity benchmark (would be R7, requires dependent task pair execution on fresh CLI sessions). Methodology shipped now; execution when warranted.

---

### P38 — R5 post-trim benchmark + README claim audit
`[SHIPPED - 2026-04-17] [Iteration]`

Ran a directional pilot benchmark (R5) to validate the P32-P36 trim did not compromise SOP performance. Audited README for unsubstantiated claims and tightened language throughout.

**R5 methodology:**
- Same 4 vague tasks as R2 (05 tonnage, 06 scroll, 07 skip exercise, 08 keyboard buttons)
- Same base commit (hst-tracker `1c73062`)
- Subagent pilot (not fresh CLI sessions — directional only)
- Opus 4.7 (R2 used 4.6)
- Single round, blind-scored per condition

**R5 results:**
| Task | SOP | Baseline | Delta | R2 delta |
|------|----:|---------:|------:|---------:|
| 05 Tonnage | 18 | 8 | SOP +10 | SOP +9 |
| 06 Scroll | 20 | 17 | SOP +3 | Draw |
| 07 Skip exercise | 21 | 15 | SOP +6 | SOP +9 |
| 08 Keyboard buttons | 16* | 21 | Baseline +5 | SOP +10 |
| **Aggregate** | **75/84 (89%)** | **61/84 (73%)** | **SOP +16%** | **SOP +33%** |

(*Task 08 SOP score corrected +1 after scorer incorrectly penalised `--color-accent-light` which does exist — 87 occurrences in index.css.)

**Interpretation:** SOP still wins (+16% aggregate, 3 of 4 tasks), but margin narrowed from R2's +33%. Drivers: Opus 4.7 baseline was more capable than R2's 4.6 (didn't crash on task 07 as R2's did; used correct design tokens on task 08 unlike R2); subagent methodology is weaker than fresh CLI sessions; single round is not averaged. The spot check (task 05) held strongly — baseline actively regressed the B1 fix, exactly the catastrophic miss the SOP prevents.

**README audit + updates:**
- Benchmark badge changed from `+33% vs baseline` → `directional +16% to +33%`.
- Benchmark preamble rewritten to name the methodology difference between R1/R2 (fresh CLI, Opus 4.6) and R5 (subagents, Opus 4.7).
- R5 section added with caveats and explicit "not a definitive replacement for R2" framing.
- Key finding #5 ("token overhead pays for itself") qualified to R2-specific — R5 didn't remeasure tokens.

**Deferred:** full-framework R6 on fresh CLI sessions, same model as R2, multi-round — before citing a post-trim percentage unconditionally.

**Artefact:** `docs/benchmark/results/r5-post-trim/summary.md`

---

### P37 — claude-mem review findings applied
`[SHIPPED - 2026-04-17] [Iteration]`

Three portable patterns harvested from the claude-mem review (2026-04-17) and applied to existing docs. Each addition traces to a specific claude-mem mechanism shown to be valuable independent of its infra choices.

**Changes:**
1. `docs/guides/multi-agent-context-routing.md` — added Routing Rule 5: **progressive retrieval pattern** (index → narrow → fetch). Generalises claude-mem's 3-layer MCP retrieval into a context-routing heuristic for large corpuses.
2. `docs/sop/security.md` — added Rule 9: **redact sensitive content at capture time**. `<private>...</private>` marker stripped at hook write, not retrieval read. Addresses the leaked-store threat model that retrieval-time filtering misses.
3. `docs/sop/harness-configuration.md` — added Core Rule 9: **hooks must fail open**. Catch errors, log, continue. Blocking gates fail closed but need a circuit breaker so a broken hook can't strand the agent.
4. `docs/guides/optional-patterns.md` — added **heavyweight persistent memory** section positioning `claude-mem` as an optional complement (not competitor). Clarifies that Agent SOP covers prescription, claude-mem (or equivalent) covers observation/retrieval.

**Patterns explicitly NOT adopted:** DB-backed memory, auto-capture by default, MCP server, web UI. Would compromise Agent SOP's plain-markdown / git-committed / human-authored philosophy.

Core SOP instruction count unchanged (edits landed in guides + security + harness, not `claude-agent-sop.md`).

---

### P36 — SOP sync mechanism (/update-agent-sop)
`[SHIPPED - 2026-04-17] [Feature]`

Added a distribution and update mechanism so downstream projects can keep their pristine-replica Agent SOP artefacts in sync as upstream evolves.

**Components shipped:**
1. **Version markers** on all 17 pristine-replica files — HTML comment on plain markdown, `sop_version:` YAML field inside frontmatter for agents/commands. Advisory only (SHA comparison is the authority).
2. **`/update-agent-sop` slash command** (`.claude/commands/update-agent-sop.md`) — resolves source (local path preferred, GitHub raw fallback to `mmjclayton/agent-sop`). Three-way diff per file: unchanged local → apply silently; modified local + changed upstream → surface reconciliation; no force-overwrite.
3. **Staleness check added to `/restart-sop`** — new Step 0 prints one-line warning when `last_update_check` exceeds `update_reminder` cadence. Non-blocking.
4. **`setup.sh` expanded** — now copies full pristine-replica set. SOP docs + guides → project-scope. Slash commands + agents → user-scope (`~/.claude/`). Auto-creates `~/.claude/agent-sop.config.json` with baseline SHA-256 for each file.
5. **Config schema** documented at `docs/templates/agent-sop-config-template.json`. Fields: `local_path`, `github`, `update_reminder` (weekly|manual|off), `last_update_check`, `baseline_shas`.
6. **README updated** — new "Keeping the SOP in sync" section explains the three-way diff behaviour, config locations, and reminder cadence.

**Scope decisions (from user):**
- Distribution model: copy-based (not symlinks/submodules). Projects stay self-contained.
- `/restart-sop` piggybacks the reminder (no separate hook).
- Locally modified files are never force-overwritten — Claude surfaces the diff for manual reconciliation.
- Slash commands + agents install user-scope; SOP docs + guides install project-scope.
- First-run against an existing project (e.g. hst-tracker) bootstraps by capturing upstream SHA as baseline; any pre-existing local divergence surfaces immediately.

**Acceptance criteria:**
- `/update-agent-sop` command file exists and is documented — DONE
- `setup.sh` distributes the full pristine-replica surface (17 files) — DONE
- Version markers on all 17 files — DONE
- Config schema documented — DONE
- README has "Keeping the SOP in sync" section — DONE
- `setup.sh` passes `bash -n` syntax check — DONE

**Deferred:**
- Running `/update-agent-sop` against hst-tracker (separate step, offer to user).
- Public GitHub publication of `mmjclayton/agent-sop` (user decision, separate step).
- Per-project `.claude/agent-sop.config.json` override — schema supports it, no separate docs needed.

---

### P35 — Section 4 Versioning Rules removed (pure duplicate)
`[SHIPPED - 2026-04-17] [Refactor]`

Section 4 consisted of an opening sentence literally stating "See Section 0" plus a 7-row table where every row restated a bullet already under Section 0 Rule 1 "How this works". Removed entirely, replaced with a one-line pointer: *"Per-file versioning rules are defined in Section 0 Rule 1 'How this works'. No separate restatement here."*

**Savings:** ~8 instructions. core SOP ~197 → ~189.

**Verification:** grep confirmed no external references to "Section 4" by number. Every versioning directive remains reachable via Rule 1's existing bullets. No directive silently removed — all rules live in Section 0 Rule 1.

Lowest-risk cut from the P32 candidate list. Self-declared duplicate.

---

### P34 — Rule 1 extended; Rule 6 added; failure-mode annotations
`[SHIPPED - 2026-04-17] [Iteration]`

Applied three findings from the karpathy-skills review (P32 follow-up):

1. **Rule 1 extended** — now reads "Never delete without a trace. Never add without reason." Added sentence: *"Every changed line must trace directly to the user's request. If you can't justify a line by pointing to the request that asked for it, delete it. No drive-by refactors, no speculative abstractions, no 'while I'm here' additions."*
2. **Rule 6 added** — "Surface interpretations before acting." When a request has multiple valid interpretations, list them and ask; do not pick silently. Trivial reversible choices (variable naming) exempt.
3. **Failure-mode annotations** added to each of the six non-negotiable rules (italic *Prevents:* line). Format-only change, zero instruction cost.

**Count impact:** +~4 instructions (trace-to-request sentence, "no drive-by" line, Rule 6 statement, Rule 6 exception). claude-agent-sop.md ~193 → ~197. Still under 200 hard ceiling.

**Rationale:** trace-to-request generalises Rule 1 from "don't silently delete" to "don't silently add" — closes the gap the audit flagged. Rule 6 names the interpretation-ambiguity pattern that Rule 4 implied but didn't spell out. Prevents annotations sharpen each rule's reason for existing without adding load.

**Source:** forrestchang/andrej-karpathy-skills review, 2026-04-17 agent-memory entry.

---

### P32 — SOP instruction-budget trim
`[SHIPPED - 2026-04-17] [Refactor]`

Enforced Section 0 Rule 5 by auditing and trimming the SOP instruction set. Pre-trim total: 392 instructions across 5 SOP files; `claude-agent-sop.md` alone was ~230, breaching its own Rule 5 (200 hard ceiling).

**Audit classification:**
- CORE: 58, PROVEN: 31, CONDITIONAL: 72, DUPLICATE: 58, ASPIRATIONAL: 89, NOISE: 84

**Cuts applied:**
1. Quick Reference Card deleted (100% duplicate of Sections 0/5/6) — DONE
2. Section 17 Managed Agents → `docs/guides/managed-agents-integration.md` (deferred → P33) — DONE
3. Sections 12, 16, 18 → `docs/guides/{optional-patterns,multi-agent-context-routing,sop-hill-climbing}.md` — DONE
4. Parametrise compliance-checklist.md — SKIPPED: sop-checker agent references check IDs, parametrising breaks tooling. Doesn't count against main SOP budget (loaded only by sop-checker).
5. Merge `context-management.md` + `hooks.md` → `harness-configuration.md` — DONE
6. Collapse `security.md` to core rules; split container/network content to `sandboxing.md` — DONE

**Final measurements (instruction count):**
| File | Pre-trim | Post-trim |
|------|---------:|----------:|
| claude-agent-sop.md | ~230 | ~193 |
| compliance-checklist.md | ~84 | ~86 (skipped — tooling dependency) |
| harness-configuration.md | n/a (merged) | ~31 |
| sandboxing.md | n/a (split) | ~25 |
| security.md | ~52 | ~8 |
| hooks.md | ~13 | REMOVED (merged) |
| context-management.md | ~13 | REMOVED (merged) |
| **Grand total** | **~392** | **~343** |

- `claude-agent-sop.md` now under 200 hard ceiling (Rule 5 no longer self-breached) — BUT ~43 over the 150 soft cap.
- 975 → 624 lines in core SOP.
- Pre-trim state archived in `.archive/sop-pre-trim-2026-04-17/` (gitignored).
- Tracking files updated (Backlog, feature-map, agent-memory, CLAUDE.md, README, sop-checker agent, example guides).

**Candidate follow-up (to hit ≤150 soft cap):**
- Section 14 Common Mistakes table (~14 rows) — move examples to a guide, keep cross-refs
- Section 15.4 Managed Agents benchmark safety (~5 rows) — move to `docs/guides/managed-agents-integration.md` (already deferred)
- Section 1 per-file commentary (~5 rows) — compress
- Section 8 tag taxonomy (~19 rows) — collapse to one parametric rule

**Deferred to follow-up:** Evaluate karpathy-skills "trace-to-request" phrasing and failure-mode annotations for addition to Rule 1 / Common Mistakes (agent-memory entry 2026-04-17).

---

### P33 — Managed Agents integration guide (deferred)
`[OPEN] [Feature] [has-open-questions]`

Bring `docs/guides/managed-agents-integration.md` back into active use when a project transitions from Claude Code sessions to the Managed Agents API.

**Why parked:** No current project uses Managed Agents. Content lives at `docs/guides/managed-agents-integration.md` (extracted from SOP Section 17 on 2026-04-17).

**Trigger to revive:**
- First project uses `api.anthropic.com/v1/agents`
- Managed Agents API leaves beta
- User explicitly requests integration work

**Acceptance criteria when revived:**
- Validate memory store mapping against current Managed Agents API
- Validate session lifecycle mapping
- Validate `user.define_outcome` event reference
- Decide whether content returns to main SOP or stays as a standalone guide

---

### P24 — Multi-agent optimisation guide
`[OPEN] [Feature]`

Standalone guide at `docs/sop/multi-agent.md` for multiple agents working the same repo. Consolidates and extends existing coverage (Section 0 contention, Section 16 context routing, Section 17 Managed Agents) into a single reference.

**Scope (informed by benchmark rounds 1-2):**
- Worktree isolation patterns (when to use, setup/teardown)
- Token budget allocation across parallel agents (coordinator vs specialist)
- Context sharing: what each agent reads vs what stays local
- Conflict avoidance: file locking conventions, branch strategies, merge sequencing
- Common Mistakes for multi-agent (based on Section 0 contention rules)
- Managed Agents API patterns (permission policies, outcome grading)

**Acceptance criteria:**
- `docs/sop/multi-agent.md` exists as standalone guide
- Consolidates Section 0, 16, 17 content without duplicating (single source of truth)
- Core SOP section index updated with cross-reference
- Both templates updated with multi-agent section scaffold
- Compliance checklist updated with multi-agent checks
- All tracking files updated (Backlog, feature-map, agent-memory, CLAUDE.md)

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
