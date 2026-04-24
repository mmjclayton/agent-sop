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
`[SHIPPED - 2026-04-19] [Feature]`

*Dogfood pass complete 2026-04-19. Three parallel subagents on separate worktrees of hst-tracker each ran `/update-sop` discipline independently. Sequential three-way merge to main produced 0 conflicts on Backlog status flips, 0 conflicts on per-entry directory files (`docs/recent-work/`, `docs/agent-memory/decisions/`), and 2 conflicts on `CLAUDE.md` rollup — resolved canonically by re-running the idempotent refresh snippet, as the guide prescribes. Full test suite (855/855: 415 server + 440 client) green on merged main. See `docs/benchmark/parallel-dogfood-log.md` for findings.*

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

### P44 — Required reviewer turn before ship (with substance assertion)
`[SHIPPED - 2026-04-19] [Feature]`

Close the gap identified in external feedback (2026-04-19): `/update-sop` Step 1 is agent self-evaluation against a Definition-of-Done rubric, but no step forces an independent reviewer-agent invocation before the shipping commit lands. Reviewer agents (`code-reviewer`, `security-reviewer`) exist but are not in the required path. Without a substance check, a required reviewer turn becomes ceremony — the agent can write "LGTM" in a file and pass the gate.

**Approach:**
1. `/update-sop` Step 1 extended: for any item transitioning to `[SHIPPED]` this session AND tagged `[Feature]` or `[Refactor]` AND session diff > threshold (default 50 LOC OR 3 files, configurable in `agent-sop.config.json`), invoke `code-reviewer` (or `security-reviewer` if the diff touches paths matching `docs/sop/security.md` mandatory-review triggers). Write findings to `docs/reviews/YYYY-MM-DD_<agent-id>_P<n>.md`.
2. Batch Log entry must reference the findings file path — hard-block if missing.
3. **Substance assertion:** findings file must contain three sections — diff summary, severity assessment (CRITICAL / HIGH / MEDIUM / LOW / NONE), and at least one concrete finding OR an explicit "no issues" statement with a one-sentence reason. Shared validator (from P45) asserts these sections exist. Hard-block on stub / LGTM-only files.
4. New compliance check `R1` in `compliance-checklist.md`: every shipped `[Feature]`/`[Refactor]` in the last 30 days with diff > threshold has a matching substantive review artifact. Important-tier (5pts).
5. No human-in-the-loop gate. The reviewer is a sibling agent, the substance check is automated, the hard-block is agent-enforced at `/update-sop`. Review artifacts exist for post-hoc QA and traceability — the human (project owner) reads them later if they want, never blocks on approval for shipping.

**Acceptance criteria:**
- `/update-sop` Step 1b hard-blocks shipping `[Feature]`/`[Refactor]` without a substantive review artifact when diff exceeds threshold - DONE
- `docs/reviews/` filenames follow per-agent convention (matches `docs/recent-work/` pattern) - DONE
- Substance validator rejects stub / LGTM-only files - DONE (via `bash scripts/validate-state-transitions.sh --assert-review <path>`, shipped with P45)
- Compliance check R1 added; summary table totals updated - DONE (76→77 / 85→86)
- Threshold + agent selection configurable in `agent-sop.config.json` - DONE (`review_loc_threshold`, `review_files_threshold`)
- Core SOP instruction delta: +3-4 (Rule 5 budget respected) - DONE (+4 in Section 6 Step 1b + Step 3c note + Batch Log review-path note)

**Out of scope:** blocking the actual git commit or push (pre-push hook is an optional snippet in `docs/guides/`, not default); human-approval gate on merge.

**Files shipped:** `docs/templates/review-template.md` (new), `.claude/commands/update-sop.md` (Step 1b), `docs/sop/claude-agent-sop.md` (Section 6 extended), `docs/sop/compliance-checklist.md` (R1 + summary totals), `docs/templates/agent-sop-config-template.json` (threshold fields), `.claude/commands/update-agent-sop.md` (manifest), `setup.sh` (review-template copy).

**Source:** Reddit feedback 2026-04-19 — state drift / required reviewer turns / human gate concerns. Substance-assertion caveat added during assessment after being challenged on action-vs-ceremony. P44 wording tightened 2026-04-19 to make the no-human-in-loop property explicit.

**Depends on:** P45 (validator infrastructure shared — `--assert-review` subcommand).

---

### P45 — State-transition validator
`[SHIPPED - 2026-04-19] [Feature]`

Status tags have semantics but no enforcement. Nothing prevents an agent writing `[OPEN] [Feature]` → `[SHIPPED - YYYY-MM-DD]` in one diff with no `[IN PROGRESS]` intermediate, no Batch Log entry, and no commit date inside the shipped-date window. `/update-sop` Step 2a covers P-number collision only.

**Approach:**
1. `scripts/validate-state-transitions.sh` — reads `Backlog.md` diff in the commit range (`git merge-base <default> HEAD..HEAD`), parses status-tag changes per P-number, validates against the transition graph:
   - `[OPEN]` → `[IN PROGRESS]`, `[DEFERRED]`, `[WON'T]`
   - `[IN PROGRESS]` → `[BLOCKED]`, `[DEFERRED]`, `[SHIPPED]`, `[WON'T]`
   - `[BLOCKED]` → `[IN PROGRESS]`, `[DEFERRED]`, `[WON'T]`
   - `[DEFERRED]` → `[IN PROGRESS]`, `[WON'T]`
   - `[SHIPPED]` → `[VERIFIED]` only
   - `[VERIFIED]` terminal
   - `[WON'T]` terminal (revival requires a new P-number)
   - `[BLOCKED]` ↔ `[DEFERRED]` permitted with a commit-range note referencing a decision file
2. Additional checks inside the validator:
   - `[SHIPPED - YYYY-MM-DD]` transition requires a Batch Log entry in the current phase's `docs/build-plans/phase-N.md` referencing the P-number within the commit range
   - Date in `[SHIPPED - YYYY-MM-DD]` falls inside the commit-range date window
   - Once P44 ships: `[SHIPPED]` on `[Feature]`/`[Refactor]` over threshold requires a P44-compliant review artifact
3. `/update-sop` Step 2c calls the validator; hard-block on non-zero exit. Output names the offending P-number and the legal paths available.
4. sop-checker compliance check `S2` runs retrospective state-transition audit on Backlog history.

**Acceptance criteria:**
- `scripts/validate-state-transitions.sh` exists, zero-dependency bash, runs <2s on a 200-item Backlog - DONE (0.2s measured)
- `/update-sop` Step 3c invokes validator; hard-block on non-zero exit - DONE (renumbered from 2c to run after Backlog updates)
- Transition graph documented once in Section 8 of core SOP (single artifact, not one rule per edge) - DONE
- `docs/benchmark/state-transition-fixtures/` with legal + illegal sample diffs; script validated against them - DONE (6 fixtures, all pass)
- Multi-agent safe: only evaluates diff inside this agent's merge-base range - DONE
- Substance-assertion helper (shared with P44) included in same script - DONE (--assert-review subcommand)
- Core SOP instruction delta: +2-3 - DONE (+3 in Section 8)

**Out of scope:** enforcing transition legality at Backlog write-time (editor-integration territory — too heavy); validator runs at session end.

**Graph relaxed during implementation:** initial design required `[IN PROGRESS]` intermediate before `[SHIPPED]`. Dogfood showed this forces two-session ships for trivial work. Graph relaxed so `[OPEN]`/`[BLOCKED]`/`[DEFERRED]` → `[SHIPPED]` are legal when a Batch Log reference exists — the Batch Log requirement provides anti-gaming teeth, making the intermediate state bookkeeping rather than enforcement. `<absent>` → `[SHIPPED]` stays illegal (unplanned work has no paper trail).

**Source:** Reddit feedback 2026-04-19 — machine-checkable workflow with explicit task states. Assessment flagged this as highest action-per-text ratio of the three proposed items; ship first.

**Files shipped:** `scripts/validate-state-transitions.sh`, `docs/benchmark/state-transition-fixtures/` (6 fixtures + run-tests.sh + README), `.claude/commands/update-sop.md` (Step 3c), `.claude/commands/update-agent-sop.md` (manifest), `docs/sop/claude-agent-sop.md` (Section 8 graph), `docs/sop/compliance-checklist.md` (B11 + summary table), `.claude/agents/sop-checker.md` (B11 guidance).

---

### P46 — Mid-session drift detection (actionable, not informational)
`[SHIPPED - 2026-04-19] [Feature]`

External feedback (2026-04-19) named mid-session state drift as the central failure mode of markdown-only SOPs. Initial proposal was a PostToolUse hook printing status reassertions — rejected as ceremony (a printout the agent can ignore). Reframed as an actionable commit-range check: at `/update-sop`, verify the session's actual work matches the declared in-flight P-number.

**Approach:**
1. `/update-sop` Step 2d: commit-range scope check. Parse commits in `git merge-base <default> HEAD..HEAD` for P-number references (`P<n>` tokens in commit messages + files touched). Compare against `project_resume_<agent-id>.md` In-Progress entry and the newest Batch Log entry. Hard-block if the session committed substantial work (>50 LOC OR >3 files) with no reference to the declared in-flight P-number.
2. Escape hatch — session-end scope-change declaration. `project_resume_<agent-id>.md` update can include a `## Scope Change` block re-declaring the actual P-number worked on with a one-line reason. Validator accepts this as legitimate redirection and surfaces it in the `docs/recent-work/` entry.
3. `/restart-sop` gains a one-line reassertion print of the current in-flight P-number read from `Backlog.md` — acceptable because it fires once at session start, not as a recurring ceremony.
4. sop-checker compliance check `D1` (drift detection): retrospective audit of last 10 `docs/recent-work/` entries counting `Scope Change` blocks and commit-to-P-number mismatches. Recommended-tier (2pts).

**Acceptance criteria:**
- `/update-sop` Step 3d detects commit-range work that doesn't reference the declared in-flight P-number - DONE (renumbered from 2d to match placement after Step 3c)
- Hard-block with clear message naming the P-number and the commits lacking references - DONE
- Legitimate scope-change path via `project_resume` `## Scope Change` block - DONE
- Compliance check D1 added; summary table totals updated - DONE (77→78 / 86→87)
- Multi-agent safe: scoped per-agent via commit-range partitioning + per-agent resume file - DONE
- Core SOP instruction delta: +1-2 - DONE (+1 in Section 6)

**Out of scope:** preventing drift within a single tool call (Claude Code doesn't expose runtime hooks for this); PostToolUse print reminders (explicitly rejected — ceremony, not action).

**Files shipped:** `scripts/validate-state-transitions.sh` (new `--check-drift` subcommand, project-hash normalization fix, pipefail-safe config parsing), `docs/benchmark/drift-fixtures/` (3 fixtures + run-tests.sh), `.claude/commands/update-sop.md` (Step 3d), `.claude/commands/restart-sop.md` (Step 0d in-flight reassertion), `docs/sop/claude-agent-sop.md` (Section 6 note on Step 3d), `docs/sop/compliance-checklist.md` (D1 check + summary totals).

**Source:** Reddit feedback 2026-04-19 — drift after tool calls / edits / context resets. Reframed from initial print-hook proposal after user challenge: "tell me why each item will add value, and not simply add more text and markup without any action or result."

---

### P48 — Reviewer voice rules + Backlog item-sizing pedagogy
`[SHIPPED - 2026-04-20] [Iteration]`

Source: direct review of `levu304/claude-code-boilerplate` (2026-04-20). Two transferable patterns identified; the rest of the repo is aspirational prose or duplicates `~/.claude/rules/`.

**Scope:**
- Lift the reviewer-voice rules (format, drop-list, keep-list, auto-clarity carve-out, before/after examples) from the boilerplate's `review-local-changes` SKILL into `.claude/agents/code-reviewer.md`. Tightens every finding's prose without changing the severity taxonomy or output template.
- Add a brief "Item Sizing" section to `docs/templates/backlog-template.md` teaching the "split if it needs 'and' or multiple bullets" heuristic plus a single BAD/GOOD example pair.

**Out of scope:** absorbing the boilerplate CLAUDE.md, forking a sibling coding-standards project, pulling any other agents or skills. See decision file for the full "not worth engaging" rationale.

**Acceptance criteria:**
- `code-reviewer.md` gains a "Finding Voice" section with format, drop/keep lists, examples; severity taxonomy and output template unchanged.
- `backlog-template.md` gains ~6 lines of item-sizing guidance with one BAD/GOOD pair.
- No net increase in core SOP instruction count (templates and agents are not counted against the ceiling).

---

### P49 — Instrument `/update-sop` step timing before any trim refactor
`[SHIPPED - 2026-04-24] [Iteration]`

**Decision:** ABANDON the `/update-sop` refactor. Per-step median/max across 3 samples shows no step dominates enough to justify rewrite; agent-side drafting for the decision / feature-map / resume / recent-work writes sums to ~140-155 s but each write produces a durable artifact serving a distinct audience, and the reviewer-turn cost (~95 s in sample 3) fires only on the Feature/Refactor subset where it pays. Full summary at `docs/agent-memory/decisions/2026-04-24_solo_p49-update-sop-timing-summary.md`. Samples at `docs/instrumentation/2026-04-20_update-sop-timing.md`, `2026-04-24_update-sop-timing.md`, and `2026-04-24_hst-tracker_update-sop-timing.md`.

Surfaced 2026-04-20. Commands feel slow; first-pass estimate claimed ~35-40% line cut possible by extracting bash gates to scripts. That estimate conflated two kinds of slowness — token read cost per invocation vs wall-clock time the agent spends thinking through steps — and was not grounded in measurement. Refactoring before measuring risks churn without hitting the real bottleneck.

**Hypothesis (to confirm or disprove):**
- Perceived slowness is dominated by Step 1b reviewer-turn (subagent spawn), Step 5 decision/gotcha file writing, and Step 8 recent-work entry drafting — not by the 446-line command read cost.
- If true, extracting bash gates to scripts is cosmetic. The useful interventions would be making the reviewer-turn opt-out cheaper, or templating Step 5/8 more aggressively.

**Approach:**
- Over the next 2-3 real `/update-sop` runs, capture wall-clock per step. Simplest instrumentation: wrap each step with `date +%s` before/after in a session log (e.g. `docs/instrumentation/YYYY-MM-DD_update-sop-timing.md`). No code changes to the command itself — the agent records times as it works.
- Log session characteristics: solo vs multi-agent, docs-only vs code, which gates fired vs no-op'd, whether Step 1b triggered.
- After 3 sessions, summarise which steps dominate. File a follow-up refactor item (P50) only if the data supports it.

**Acceptance criteria:**
- Three instrumented sessions captured with per-step timings
- Summary table of median/max time per step across the three
- Explicit decision recorded in `docs/agent-memory/decisions/`: refactor (with scope) or abandon (with reason)

**Out of scope:** any actual refactor of `/update-sop`, `/update-agent-sop`, or gate extraction. This item is measurement only.

---

### P51 — Safe optimisations to `/restart-sop` read phase (parallel reads + targeted Backlog load)
`[SHIPPED - 2026-04-24] [Iteration]`

**Dogfood result (hst-tracker session, 2026-04-24):**
- A1 parallel reads: fired partially. The Steps 1-4 block was a single parallel round (6 concurrent tool calls), but setup + Step 0c/0d preceded it in 2 separate rounds. Not a protocol violation — those calls produce values the later round consumes — but also not a textbook "everything in one batch" implementation. Acceptable.
- A2 targeted Backlog read: fired cleanly. Session read ~15 KB of a 308 KB `Backlog.md` (~4.9 %) across all lookups. No full-file reads occurred. ~20× reduction vs the worst-case old pattern.
- Dogfood artifact: `docs/instrumentation/2026-04-24_hst-tracker_update-sop-timing.md`.

Surfaced 2026-04-24 while analysing why `/restart-sop` and `/update-sop` feel slower in hst-tracker than in agent-sop. Measurement:
- hst-tracker default-loaded state is ~4x larger than agent-sop (`Backlog.md` 305 KB vs 63 KB; `agent-memory.md` 38 KB vs 7 KB; `CLAUDE.md` 25 KB vs 8 KB).
- Command-file read overhead is constant and small relative to project state.
- Step 5 tells agents to "read the specific Backlog item(s)" without a pattern, so on large backlogs agents often load the whole file.
- Steps 1-3 are presented sequentially though their reads are independent, biasing serial execution.

**Scope (this item):**
1. Execution note above Step 1 (Full Start) — explicit instruction that Steps 1-4 reads/shell calls are independent and should be issued as a single parallel batch.
2. Targeted Backlog-read pattern in Step 5 (Full Start) and Step 2L (Lightweight Start) — `grep -n` for the item anchor, then `Read` with `offset` + `limit`. Full-file read remains the fallback on grep miss.

**Out of scope:**
- Step count, reviewer-turn, decision/gotcha authoring behaviour.
- Any change to `/update-sop` — P49 is still gathering timing samples there.
- hst-tracker project-level trims (`CLAUDE.md`, `agent-memory.md`) — revisit if P49 sample 2+ shows those files still hot after A1/A2.

**Acceptance criteria:**
- `.claude/commands/restart-sop.md` gains the parallel-reads execution note and targeted-read pattern in Full + Lightweight starts.
- User-scope mirror `~/.claude/commands/restart-sop.md` updated identically.
- Dogfood run (next `/restart-sop` in hst-tracker) issues reads in parallel and does not load full `Backlog.md` for item lookup.
- No net behaviour change — same files read, same checks performed.

**Safety:** both are prompt-wording changes, reversible in one edit. Targeted-read failure mode (grep miss → no item found) is immediate and visible; the agent re-reads with a wider window. No silent regressions possible.

---

### P47 — Drift check: resume-file fallback fails on multi-worktree projects with legacy unsuffixed resume
`[SHIPPED - 2026-04-20] [Bug]`

Surfaced during hst-tracker P44/P45/P46 sync on 2026-04-19. The drift-check path resolution:
```
resume_file="project_resume_${agent_id}.md"
if [ ! -f "$resume_file" ] && [ "$agent_id" = "solo" ]; then
  resume_file="project_resume.md"  # legacy fallback
fi
```

Fires fallback **only when agent-id is literally `solo`**. On a multi-worktree project (hst-tracker has a `--design-audit` sibling worktree), agent-id resolves to a 6-char path hash, NOT `solo`. Main worktree still uses the pre-P43 legacy unsuffixed `project_resume.md` because the project predates multi-agent format migration. Fallback never fires → drift check degrades to "no resume file found, skipping" → gate silently no-ops.

**Failure mode:** the most valuable drift-check targets (long-lived projects with parallel worktrees) get no drift enforcement until they've run `/migrate-to-multi-agent`. That's a usability sharp edge — the gate quietly does nothing without signalling why.

**Approach:**
- Always try the legacy unsuffixed `project_resume.md` as the last fallback, regardless of agent-id value.
- If that file exists AND agent-id is not `solo`, emit a one-line advisory: "Reading legacy unsuffixed resume file. Run `/migrate-to-multi-agent` to move to per-agent format."
- Same treatment for the `/restart-sop` Step 0d reassertion snippet.

**Acceptance criteria:**
- `scripts/validate-state-transitions.sh --check-drift` finds the legacy file on multi-worktree projects
- `/restart-sop` Step 0d reassertion works for hst-tracker without migration
- Advisory message only prints once per invocation (not spammy)
- Migration guide (`docs/guides/multi-agent-parallel-sessions.md`) gets a pointer to this fallback behaviour

**Source:** observed during hst-tracker sync, 2026-04-19. Two-worktree project (main + design-audit). Main worktree uses `project_resume.md` (legacy), sibling has no resume file yet.

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
