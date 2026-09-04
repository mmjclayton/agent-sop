# Agent SOP — Backlog

Single source of truth for all work items. Never delete without a trace — update in place, mark superseded, or archive.

## Tag Taxonomy

- Status (first): `[OPEN]` `[IN PROGRESS]` `[BLOCKED]` `[DEFERRED]` `[SHIPPED - YYYY-MM-DD]` `[VERIFIED - YYYY-MM-DD]` `[WON'T]`
- Type (second): `[Feature]` `[Iteration]` `[Bug]` `[Refactor]`
- Optional: `[has-open-questions]` `[ok-for-automation]`
- `[BLOCKED]` = waiting on external action. `[DEFERRED]` = intentionally postponed with no external blocker, and must state a reopen trigger (`**Reopens when:** <condition>`; "no trigger identified" is legal and flags it for `[WON'T]` review).

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

**Recommendation (2026-08-03, from the P83 audit close-out):**
Close or trigger. `[has-open-questions]` and untouched since 2026-04-07 — four months with no movement. By P71's own rule an item carrying no reopen trigger is a `[WON'T]` candidate at the next review, and this close-out is that review. Either flip to `[WON'T]` with a reason, or attach an observable reopen trigger. Leaving all three `[OPEN]` indefinitely is the accumulation failure P71 was written to prevent.

**Open questions:** What web-app-specific sections beyond the base SOP? Separate doc or addendum?

---

### P9 — Marketing domain variant
`[OPEN] [Feature] [has-open-questions]`

**Recommendation (2026-08-03, from the P83 audit close-out):**
Close or trigger. `[has-open-questions]` and untouched since 2026-04-07 — four months with no movement. By P71's own rule an item carrying no reopen trigger is a `[WON'T]` candidate at the next review, and this close-out is that review. Either flip to `[WON'T]` with a reason, or attach an observable reopen trigger. Leaving all three `[OPEN]` indefinitely is the accumulation failure P71 was written to prevent.

**Open questions:** What content/marketing-specific sections are needed?

---

### P10 — Data/analytics domain variant
`[OPEN] [Feature] [has-open-questions]`

**Recommendation (2026-08-03, from the P83 audit close-out):**
Close or trigger. `[has-open-questions]` and untouched since 2026-04-07 — four months with no movement. By P71's own rule an item carrying no reopen trigger is a `[WON'T]` candidate at the next review, and this close-out is that review. Either flip to `[WON'T]` with a reason, or attach an observable reopen trigger. Leaving all three `[OPEN]` indefinitely is the accumulation failure P71 was written to prevent.

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

### P52 — Learnings capture pattern (doc-only, `/update-sop` integration)
`[SHIPPED - 2026-04-26] [Feature]`

Doc-only learnings-capture pattern. PreCompact and Stop hooks (documented in `harness-configuration.md`, not installed by `setup.sh`) prompt the agent to write `docs/agent-memory/learnings/YYYY-MM-DDTHH-MM_<agent-id>_<slug>.md` capturing four categories: (1) surprises about the codebase, (2) key learnings for future sessions, (3) hook/workflow recommendations, (4) skill recommendations. `/update-sop` Step 5 lists the folder and acts on each file: crystallise into a decision/gotcha, file a Backlog item, or archive as no-longer-relevant. Never delete — archive is `git mv` to `learnings/archive/YYYY-MM/`.

Inspired by CodeLeash's session-end learnings capture. Adapted for agent-sop:
- **stdout context injection only** (no `decision: block`). Avoids `stop_hook_active` infinite-loop guard logic and forced extra-turn-at-Stop disruption. PreCompact stdout injects post-compact; Stop stdout injects into the next user turn. SOP-side safety net is `/update-sop` Step 5 — even if a session ignores the prompt, the next `/update-sop` reviews the folder.
- **Separate folder for ephemeral signal vs durable decisions.** Keeps `decisions/` and `gotchas/` clean. Replaces the older one-line "pattern extraction on Stop" sketch in `harness-configuration.md` section f (which prompted appends to `agent-memory.md` directly).
- **Filename matches existing convention** (`YYYY-MM-DDTHH-MM_<agent-id>_<slug>.md`) — same shape as `decisions/` and `gotchas/`, with HH-MM precision because multiple captures per session are expected.
- **Archive, don't delete.** Sidesteps a Rule 2 carve-out. Cost is negligible (`git mv`); preserves audit trail.

**Scope cuts vs original proposal:**
- No `scripts/learnings-hook.sh` runtime script. agent-sop is the doc-time tool; ship-sop is the install-time tool. Crossing that boundary needs evidence the pattern delivers signal, which we don't have yet.
- No `setup.sh` changes. Consumers wire the documented snippet themselves into their own `.claude/settings.json` if they want the capture flow.
- No new `/update-sop` step. Folded into Step 5 — same directory tree, same audience, same lifecycle. Respects P49's "no step dominates" verdict (2026-04-24).
- No CLAUDE.md Rule 2 carve-out for deletion. Archive sidesteps the rule conflict.
- No `.gitkeep`. README.md keeps the folder.

**Acceptance criteria** (all met):
- `docs/sop/harness-configuration.md` section f rewritten as "Learnings capture (PreCompact + Stop)" with full 4-category prompt structure, idempotent jq merge example for ship-sop coexistence, boundary note.
- `docs/agent-memory/learnings/README.md` explains purpose, lifecycle, filename convention, file format.
- `.claude/commands/update-sop.md` Step 5 has the review-and-archive sub-step. User-scope mirror at `~/.claude/commands/update-sop.md` updated identically.
- agent-sop's own `.gitignore` excludes `docs/agent-memory/learnings/*.md` except `README.md` (project-internal hygiene; archive subtree IS committed because it preserves trace).

**Safety:** all four changes are documentation/wording. No new runtime code. Reversible in single-file edits. Failure mode is "no learnings captured" — same as the pre-P52 state.

**Follow-up (deferred, not this item):** if dogfood across 2-3 sessions shows real signal volume from the capture flow, file a fresh P-number to install the hook via `setup.sh` (mirroring ship-sop's consent-prompt + idempotent jq merge pattern). Until then, doc-only. Measurement-led, P49-style. *(Corrected 2026-08-03: this read "file P53", which was allocated to the `/finish` skill on 2026-04-29. Following it would have produced a P-number collision.)*
**Reopens when:** two or three consecutive sessions produce learnings entries with real signal rather than noise.

---

### P54 — Multi-agent hardening + perf gates + worktree advisory
`[SHIPPED - 2026-05-02] [Iteration]`

Tightens parallel-session safety and `/update-sop` perf, prompted by a hst-tracker code review where the local SOP commands were 32–38% the size of pristine and missing all parallel-safety machinery. Five concrete changes:

1. **Sibling-worktree safety advisory.** `/restart-sop` Step 0a prints a soft warning when `git worktree list | wc -l` > 1 and any sibling has uncommitted changes. Documents the wipe hazard (`docs/agent-memory/gotchas/2026-05-02_solo_worktree-uncommitted-wipe.md`) — sibling-worktree branch operations can discard uncommitted edits across the shared `.git` directory.
2. **Per-agent in-flight files.** New `scripts/refresh-in-flight.sh` regenerates the In-Flight Work section of `agent-memory.md` from `docs/agent-memory/in-flight/<agent-id>.md` per-agent files. Idempotent and conflict-free across parallel agents (each agent only writes its own file). Replaces the legacy "edit your own line" discipline-only protection. Sentinel block added to `agent-memory-template.md`. Migration is per-project; pre-migration projects fall back to legacy flat-line edit until `/update-agent-sop` syncs the sentinel template.
3. **`/update-sop` perf gates.** Step 4 + 7 + 8 (feature-map, resume snapshot, recent-work) declared as a parallel tool-call batch — independent writes, no inter-dependencies. Step 4 skip predicate: no-op when nothing in this session was tagged `[SHIPPED]`. Step 5 substance gate for decisions/gotchas: skip unless the decision fills "We chose X over Y because Z" without padding. Step 8b skip predicate: no rollup refresh when no new file in `docs/recent-work/`. Each gate eliminates a writing pass when the session content doesn't warrant it.
4. **Multi-agent guide §7 + §8.** `docs/guides/multi-agent-parallel-sessions.md` gains a "Pre-flight: sibling-worktree safety" section (cross-worktree dirty-tree check + recovery via `git fsck --lost-found`) and an explicit "Assumptions and constraints" section (one Claude per worktree, sequential merges to default, branch-per-agent, no coordination protocol).
5. **`/update-agent-sop` manifest + setup.sh.** Pristine-replica set extended with `scripts/refresh-in-flight.sh` and `docs/agent-memory/in-flight/README.md` so downstream projects pick up the new infrastructure on next sync. `setup.sh` seeds `docs/agent-memory/in-flight/` alongside `decisions/` and `gotchas/` for first-install. README updated: cross-session memory section documents the in-flight per-agent file pattern; parallel multi-agent sessions section bumped from "four structural choices" to five.

**Acceptance criteria** (all met):
- `/restart-sop` Step 0a sibling-worktree advisory prints when multi-worktree active.
- `scripts/refresh-in-flight.sh` is idempotent (verified against fixture: two consecutive runs produce no diff). Sorts agents alphabetically; preserves within-file line ordering.
- `agent-memory-template.md` has `<!-- in-flight:start -->` / `<!-- in-flight:end -->` sentinels under `## In-Flight Work`.
- `/update-sop` Step 4 prints "skipped: no [SHIPPED] tags added this session" when SESSION_RANGE empty AND no SHIPPED tag added.
- `/update-sop` Step 8b prints "skipped: no new recent-work entry this session" when `docs/recent-work/` is unchanged.
- `/update-sop` Step 5 documents the substance gate prose for decisions and gotchas.
- `docs/guides/multi-agent-parallel-sessions.md` §7 documents the pre-flight check + recovery; §8 lists the four structural assumptions.
- `/update-agent-sop` manifest includes `scripts/refresh-in-flight.sh` and `docs/agent-memory/in-flight/README.md`.
- `setup.sh` per-entry directory loop includes `agent-memory/in-flight`.
- README.md cross-session memory + parallel multi-agent sessions sections reflect the new pattern; quick-start blurb lists the full slash-command + script set.

**Files touched:** `.claude/commands/restart-sop.md`, `.claude/commands/update-sop.md`, `.claude/commands/update-agent-sop.md`, `docs/guides/multi-agent-parallel-sessions.md`, `docs/templates/agent-memory-template.md`, `docs/agent-memory/gotchas/2026-05-02_solo_worktree-uncommitted-wipe.md` (new), `docs/agent-memory/in-flight/README.md` (new), `scripts/refresh-in-flight.sh` (new), `setup.sh`, `README.md`, `~/.claude/commands/update-agent-sop.md` (user-scope mirror).

**Commits:** `1f105b6` (feat: machinery), `da279f6` (docs: README + manifest + setup.sh).

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
`[WON'T - 2026-05-04] [Feature]`

**Reason (2026-05-04):** Removed from active priorities — speculative without a project consumer. The guide at `docs/guides/managed-agents-integration.md` continues to exist as reference material (extracted from SOP Section 17 on 2026-04-17 in P40). If a future project actually uses `api.anthropic.com/v1/agents`, file a fresh P-number with the validation work scoped to the API state at that time, rather than reviving this entry — the API surface and beta status will have moved.

---

**Original entry below (kept per Rule 1):**

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
`[SHIPPED - 2026-05-04] [Feature]`

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

### P53 — `/finish` skill: end-to-end verify, simplify, ship
`[SHIPPED - 2026-04-29] [Feature]`

New slash command at `.claude/commands/finish.md` (mirrored to `~/.claude/commands/finish.md`). Three hard-blocking phases that run after Claude believes the work is done:

1. **Verify end-to-end.** Detect surface from the diff (backend / frontend / desktop / CLI / docs-only); for backend run the service via bash and exercise endpoints with curl; for frontend drive the browser via the Claude Chrome extension; for desktop drive the app via computer-use. Hard-fails if the change does not actually work against the real surface.
2. **Run `/simplify`.** Scoped to the session diff only. Re-runs Phase 1 if production code changed.
3. **Ship.** Reconcile `Backlog.md`, run `/update-sop` (the existing session-end checklist), then push and open a PR via `/prp-pr`.

Motivation: passing types and unit tests is not the same as exercising the change. `/finish` makes Claude prove the work runs before the SOP trail and PR get created.

Originally shipped as `/go`; renamed to `/finish` later the same day — `/go` collided with the Go language and read as imperative without context.

**Acceptance criteria:**
- Command exists in `agent-sop/.claude/commands/finish.md` so it ships with new SOP installs - DONE
- Command mirrored to `~/.claude/commands/finish.md` for immediate use across all projects - DONE
- Detection logic covers backend, frontend, desktop, CLI, and docs-only - DONE
- Phase 2 re-triggers Phase 1 if production code changed under simplification - DONE
- Phase 3 chains `/update-sop` and `/prp-pr` rather than duplicating their logic - DONE
- Listed in CLAUDE.md Key Documents table - DONE
- Recorded in `docs/feature-map.md` - DONE

---

### P55 — Sycophantic reviewer detection: tighten substance assertion
`[SHIPPED - 2026-05-04] [Iteration]`

Tighten `scripts/validate-state-transitions.sh --assert-review` to flag reviews that pass the structural check but contain no substance. Current implementation accepts `No issues — looks great` (any 2 words after the dash). Sycophancy data from Anthropic's 30 April 2026 personal-guidance research quantifies the failure mode: even a frontier model trained against sycophancy validates the user 9% baseline, 25-38% in emotionally-loaded domains. Reviewer-as-peer-agent has the same emotional load — the implementer just shipped this work, the reviewer is a peer in the same session, and the path of least resistance is to nod through.

**Source:** `agent-sop-research-digest-2026-05-04.md` (Finding 1).

**Acceptance criteria:**
- `--assert-review` requires findings (or reasoned-no-issues) to cite either a file path (`*.ts:N`, `*.md:N`) or a backticked code symbol from the diff
- `code-reviewer.md` Finding Voice section gains a short note tying the rule to the published baseline
- `claude-agent-sop.md` Section 6 Step 1b gains a paragraph citing the 9% / 25-38% baseline as load-bearing rationale
- New fixture under `docs/benchmark/state-transition-fixtures/` covering the slippery sycophancy-style review (passes today, must fail after the change)

**Why filed not built now:** filed alongside P56 from the 2026-05-04 digest; build order is P56 then P24, P55 deferred.

---

### P57 — Config `exclude` field for `/update-agent-sop`
`[SHIPPED - 2026-05-04] [Feature]`

Add an `exclude: []` array field to `agent-sop.config.json`. Files listed are skipped entirely by `/update-agent-sop` — no classification, no baseline tracking, no sync attempt. Eliminates the current workaround pattern of freezing a baseline at an old SHA and adding a long explanatory note (see `~/.claude/agent-sop.config.json` notes for `docs/sop/security.md` — frozen at `33c651b1` because hst-tracker runs a project-specific Supabase/Render security doc that collides with agent-sop's pristine).

**Acceptance criteria:**
- `agent-sop-config-template.json` gains `"exclude": []` with explanatory `_exclude_note`
- `/update-agent-sop` Step 2 (classification) introduces an EXCLUDED bucket; Step 3 / Step 4 / Step 5 skip excluded files
- Step 6 report counts EXCLUDED separately
- User-scope `~/.claude/commands/update-agent-sop.md` mirrored
- Baseline SHA refreshed for `update-agent-sop.md` and the template
- Backlog note: hst-tracker can migrate the `docs/sop/security.md` baseline-freeze note to `"exclude": ["docs/sop/security.md"]` next time its config is touched

---

### P58 — Karpathy before/after pattern (extend across SOP)
`[SHIPPED - 2026-05-04] [Iteration]`

Extend the "show one bad example next to one good example" pedagogy across additional SOP sections. Pattern proven in `code-reviewer.md` Finding Voice (3 pairs from P48) and `claude-agent-sop.md` §15.1 (strong-vs-weak gotcha entry — prevented a benchmark agent from removing a `Math.max` multiplier). Deferred from P34 (2026-04-17) pending evidence of broader value; the P55 sycophancy-gate work and 2026-05-04 digest reinforced the principle.

**Acceptance criteria:**
- Audit "do this not that" sections in the core SOP and reference agents; identify 4-5 candidates that materially benefit
- Add 2-3 before/after pairs per chosen section
- Net token cost stays under +500 bytes for the core SOP body (Rule 5 instruction budget unaffected — examples don't count as instructions but bytes still cost)
- User-scope mirrors updated where reference agents change
- Baselines refreshed

---

### P59 — Step 1b reviewer-gate tightening + cross-layer rules guide
`[SHIPPED - 2026-05-28] [Iteration]`

Two upstream tightenings prompted by hst-tracker 2026-05-28 evidence (composer fix — 220 LOC PR, 2 HIGH bugs caught only at review; three May 2026 cross-layer divergence bugs in the same shape).

1. **Step 1b reviewer-turn gate.** Add explicit skip list (docs-only, test-only, dependency bumps), document `review_loc_threshold: 0` always-on mode, add SOP-self-modification as an explicit trigger independent of LOC. Do not import hst-tracker's four-trigger framing into upstream — that policy belongs in project CLAUDE.md.
2. **New guide `docs/guides/cross-layer-rules.md`.** Inventory-first framing of unify-vs-parity-fixture pattern. Tier 0 grep-for-siblings is the load-bearing pre-step; Tier A unify, Tier B parity fixture follow. Strip RepCanvas-specific paths in favour of generic globs.

**Acceptance criteria:**
- Step 1b in `claude-agent-sop.md` adds skip list + zero-threshold semantics + SOP-self-modification trigger; ~15 LOC net
- New guide at `docs/guides/cross-layer-rules.md` (~150 LOC, inventory-first, project-agnostic)
- Key Documents row in `CLAUDE.md` + one entry in `sop-common-mistakes.md` pointing to the new guide
- Reviewer artifact at `docs/reviews/2026-05-28_solo_P59.md`
- Ship-sop side: single paragraph in `ship-sop/README.md` or `ship-sop/CLAUDE.md` clarifying per-stop gate vs agent-sop's per-session Step 1b — no mechanics change

**Source:** hst-tracker 2026-05-28 composer-fix session; `docs/process-improvements.md` §1, §4 in that repo.

**Why not the literal brief:** brief assumed upstream had a four-trigger model; it doesn't. Upstream is threshold-based (50 LOC / 3 files), and the empirical bug (220 LOC) was already over threshold. The real upstream gap is skip-list + always-on mode + SOP-self-mod trigger. See `docs/reviews/2026-05-28_solo_P59.md` rationale section.

---

### P56 — Backend assumptions: gateway / non-Anthropic backend warning
`[SHIPPED - 2026-05-04] [Iteration]`

Document that the SOP body, compliance scoring, and reviewer-substance gates were authored against Anthropic-hosted Claude (Opus / Sonnet). DeepClaude (3 May 2026 HN front page) routes Claude Code through cheaper backends via `ANTHROPIC_BASE_URL`; the 1 May 2026 Claude Code changelog formalised gateway support (`/model picker now lists models from gateway's /v1/models endpoint when ANTHROPIC_BASE_URL points at an Anthropic-compatible gateway`). Swapped-backend usage is now a first-class scenario. Reviewer-substance and instruction-following gates depend on instruction-following quality that smaller or cheaper backends may not match.

**Source:** `agent-sop-research-digest-2026-05-04.md` (Finding 2).

**Acceptance criteria:**
- New short section in `claude-agent-sop.md` after Section 15.4 naming the models the SOP was authored against and warning that gateway-routed sessions may degrade reviewer-substance and instruction-following gates
- `/restart-sop` gains a Step 0e advisory that prints when `ANTHROPIC_BASE_URL` is set to a non-empty value not matching `*.anthropic.com`
- User-scope `~/.claude/commands/restart-sop.md` mirrored
- Baseline SHA refreshed in `.claude/agent-sop.config.json` for restart-sop.md
- No claim about specific token-budget numbers (the 5,200-5,900 number from the digest is unmeasured)

---

### P60 — Facts correction: Sonnet 5 tokenizer, `/usage` measurement, external citations
`[SHIPPED - 2026-07-06] [Iteration]`

Corrections batch from the 2026-07-06 digest review (automated digest + manual re-run). All three are corrections or replacements, not additions.

1. **Tokenizer note.** Claude Sonnet 5 (launched 30 June 2026, default for Free/Pro users from 1 July) ships a new tokenizer producing ~30% more tokens for the same text. The core SOP states "200 lines / 2,000 tokens" and §15.5 names the authoring substrate as Opus/Sonnet 4.x. Mark token equivalences as 4.x-tokenizer figures; line caps stay the enforceable unit. One sentence at the size-limit rule, one extending §15.5, one at the 60% threshold (proportional, self-adjusts, arrives sooner on Sonnet 5).
2. **`/usage` methodology.** Claude Code 2.1.149/2.1.174 added per-category token attribution. Cite `/usage` readings as the primary measurement source in `docs/benchmark/README.md`, replacing estimate-based figures.
3. **External citations.** `docs/benchmark/README.md` gains an External validation paragraph: arXiv:2605.20049 (minimal-pair study — clean code cuts agent token footprint 7-8% and file revisitation ~34% on Claude Code + Sonnet 4.6, solve rate unchanged; caveat: measures code cleanliness, not SOP presence) and Anthropic's expertise study (16 June 2026) supporting the vague-prompt benchmark framing.

**Acceptance criteria:**
- Token equivalences in core SOP marked tokenizer-relative; §15.5 names Sonnet 5's tokenizer change
- Benchmark README cites `/usage` as the measurement source
- External-validation paragraph present with both citations and the adjacency caveat
- Net instruction count: zero new directives

**Source:** platform.claude.com release notes 30 Jun / 1 Jul 2026; Claude Code changelog 2.1.149/2.1.174; agent-sop-research-digest-2026-07-06 (manual re-run); digests 2026-05-25 + 2026-06-18 (`/usage`, surfaced twice).

**Skipped from the same two-month digest review** (per the 2026-04-13 decision — default to "remove or sharpen", not add): release-session subsection (no consumer evidence; `/finish` + ship-sop cover verify-and-ship), output-discipline template section (adds instructions to every consumer's session-read surface; contradicts the Round 2 sharpening finding), tool-schema advisory + MCP-vs-skill note (single-anecdote adds), subagent depth-cap guidance (no consumer spawns nested subagents), `sandbox.credentials` recommendation (setting unverified in changelog — revisit), "Dreaming" memory curation (not in the changelog, likely spurious), cache-aware read ordering (misconceived — within-turn read order does not bust the prefix cache).

---

### P61 — Memory poisoning: SOP context files as injection surfaces
`[SHIPPED - 2026-07-06] [Iteration]`

Anthropic's containment post (25 May 2026) names CLAUDE.md and persistent agent state as prompt-injection persistence vectors reloaded every session. `security.md` rule 1 treats external content as untrusted but does not cover the SOP's own persistent files. Reshaped from the digest suggestion to extend existing directives rather than add a subsection.

1. **`security.md` rule 1** — extend the untrusted-content list: the project's own persistent context files (CLAUDE.md, `docs/agent-memory*`, `Backlog.md`) are injection surfaces when modified outside a session's own commits.
2. **`/restart-sop` Step 4** — extend the existing git cross-check: flag uncommitted or non-session modifications to context files before acting on their contents. Advisory, not blocking — auto-filers are a legitimate source (ship-sop `compliance-reviewer` writes `[needs-triage]` Backlog entries via `auto_file_backlog: true`). One line covers out-of-repo resume files (machine-local, no git trace available).
3. **+1 Important check** in `compliance-checklist.md` + sop-checker guidance.

**Acceptance criteria:**
- `security.md` rule 1 list extended (no new numbered rule)
- restart-sop Step 4 flags dirty context files, names auto-filers as legitimate, advisory wording; user-scope mirror updated; baseline SHA refreshed
- Important check added; category totals updated
- Net instruction count: +1 (the check)

**Source:** anthropic.com/engineering/how-we-contain-claude; agent-sop-research-digest-2026-07-06 Finding 5; ship-sop composition review 2026-07-06.

---

### P62 — Background subagents: session-end checklist correctness fix
`[SHIPPED - 2026-07-06] [Bug]`

Claude Code 2.1.198 (1 July 2026) made subagents run in the background by default — the lead keeps working and is notified on completion. The session-end checklist assumes synchronous completion: `/update-sop` can run while subagents are outstanding, producing a resume snapshot that omits in-flight work (Rule 2 integrity risk).

1. **`multi-agent.md`** coordinator + specialist section: note background-by-default from 2.1.198; the lead must collect or explicitly terminate outstanding subagents before starting the session-end checklist.
2. **`/update-sop` pre-flight check**: confirm no subagents still running before Step 1. User-scope mirror in lockstep.
3. **+1 Recommended M-series check** (multi-agent projects document background-subagent handling).

Also verified: the same release removed the `/agents` wizard and made Explore inherit the session model — no SOP text depends on either (grep confirms).

**Acceptance criteria:**
- `multi-agent.md` documents background-by-default + collect-before-checklist rule
- `/update-sop` pre-flight check added; user-scope mirror updated; baseline SHA refreshed
- M-series check added
- Net instruction count: +2 (pre-check + check), justified: prevents incomplete resume snapshots

**Source:** Claude Code changelog 2.1.198 (verified); agent-sop-research-digest-2026-07-06 Finding 1.

---

### P63 — CI/CD hardening: Comment-and-Control mitigations
`[SHIPPED - 2026-07-06] [Iteration]`

Comment-and-Control (CVE-class, CVSS 9.4): prompt injection via PR titles / issue bodies / review comments into CI-wired agents, leading to credential theft. `security.md` rule 1 covers the untrusted-metadata principle; the enforceable CI specifics are absent (grep: no SHA-pinning, token-scope, or workflow guidance anywhere). Surfaced independently in two digests.

1. **`security.md`**: for projects wiring Claude Code into CI — read-only tokens for review workflows, third-party actions pinned to commit SHAs, never `allowed_non_write_users: "*"`.
2. **Deny-rule syntax as example blocks** inside existing rules (`Read(./.env)`, `Read(~/.ssh/**)`, `Agent(model:...)` — parameter-matched rules from Claude Code 2.1.178). Examples are exempt from the Rule 5 instruction count.
3. **+2 checks**: Critical (no wildcard non-write users; SHA-pinned actions) and Important (read-only token posture documented).

**Acceptance criteria:**
- `security.md` CI guidance present, kept to the existing numbered-rule format (+1 rule max)
- Deny-rule examples present as code blocks, not directives
- 2 checks added; category totals updated
- Net instruction count: +3 (1 rule + 2 checks), justified: in-the-wild CVE class

**Source:** SecurityWeek Comment-and-Control coverage; CSA research note (CVE-2025-66032); digests 2026-05-11 + 2026-06-29; Claude Code changelog 2.1.178.

---

### P64 — AGENTS.md positioning
`[SHIPPED - 2026-07-06] [Feature]`

AGENTS.md is stewarded by the Agentic AI Foundation (Linux Foundation) with multi-vendor support (OpenAI, Cursor, Factory, Sourcegraph, Gemini tooling). agent-sop was CLAUDE.md-only (zero AGENTS.md references in the repo). Decision-first item; open questions resolved with Matt 2026-07-06.

**Decisions (Matt, 2026-07-06):**
1. Consumer projects are Claude Code-only today but multi-tool is likely soon — positioning should exist before the need does.
2. Scope: **positioning only.** README subsection ("vs AGENTS.md") explaining the relationship and the recommended shape. No template, no `setup.sh` flag, no compliance check yet. Stewardship stance (open question 2): the Agentic AI Foundation is stable enough to reference in positioning, not yet proven enough to invest tooling against — that is what the reopen trigger below protects.
3. Recommended shape for multi-tool adopters: **AGENTS.md canonical** — shared context lives in AGENTS.md, CLAUDE.md becomes `@AGENTS.md` import plus the Claude-specific surface (SOP wiring, dispatch, slash commands). Never parallel copies (Rule 2).
4. **Reopen trigger for full support** (template + `setup.sh --multi-tool` + Recommended check): Claude Code reads AGENTS.md natively. Until then, deferred — do not re-litigate.

**Acceptance criteria:**
- README gains a "vs AGENTS.md" subsection in the comparisons section with the canonical-shape recommendation and the deferred-tooling note - DONE
- This Backlog entry records the four decisions and the reopen trigger - DONE
- No template/setup/check work (explicitly out of scope until the trigger fires) - DONE

**Source:** digests 2026-05-11 + 2026-06-18 (recurring finding); decision session 2026-07-06.

---

### P65 — Corrections bundle: `/simplify` note, README counts, digest-job fixes
`[SHIPPED - 2026-07-06] [Iteration]`

1. **`finish.md`**: one-line note — `/simplify` was renamed in Claude Code 2.1.147 but restored in 2.1.152 as an alias invoking `/code-review --fix`; the existing fallback paragraph stands. (Downgraded from the 2026-05-25 digest's Critical rating — the removal was reverted.)
2. **README**: verify check-count and file-count references against `compliance-checklist.md` totals (78 non-code / 87 code); fix if stale.
3. **Config**: bump `last_update_check` in `~/.claude/agent-sop.config.json`.
4. **Scheduled-job prompt fixes** (documented for the owner to apply in Claude Cowork — the job definition lives outside this repo): index the repo via GitHub MCP instead of WebFetch on JS-rendered pages (4 of 6 runs failed repo indexing); update source URLs (docs.anthropic.com → platform.claude.com/docs/en/release-notes/overview; blog.langchain.dev → langchain.com/blog); diff findings against prior digests in the Claude Config folder before reporting (3 findings were rediscovered from scratch across runs).

**Acceptance criteria:**
- `finish.md` note added (project + user-scope mirror)
- README counts verified current
- Cron fix list delivered in the recent-work entry
- Net instruction count: zero

**Source:** Claude Code changelog 2.1.147/2.1.152 (verified); two-month digest review 2026-07-06.

---

### P66 — Cross-layer divergence: validator P44 gate vs Step 1b skip list
`[SHIPPED - 2026-07-26] [Bug]`

Found while shipping P64 (docs-only `[Feature]`, well under threshold). `docs/sop/claude-agent-sop.md` Step 1b (as tightened by P59) says docs-only ships skip the reviewer turn. `scripts/validate-state-transitions.sh`'s P44 gate BLOCKs any `[Feature]`/`[Refactor]` ship whose Batch Log line lacks a `docs/reviews/` citation — it has no knowledge of the P59 skip list or the LOC/files threshold. The same logical rule lives in two runtimes and they disagree: prose says skip, validator says block. This is precisely the pattern `docs/guides/cross-layer-rules.md` (shipped in the same P59) exists to catch — Tier 0 grep-for-siblings was not run when the skip list was added.

Workaround used for P64: ran the reviewer turn anyway (cheap for a small diff) rather than evading the gate by committing first (the Batch 0.21 pattern — noted there as a process gap, not a precedent).

**Fix options (decide at implementation, per cross-layer-rules Tier A/B):**
- Tier A (unify): validator reads the skip conditions from config/prose-adjacent data — e.g. accept a `review skipped: docs-only per Step 1b skip list` citation in the Batch Log line as legal
- Tier B (parity fixture): keep both rules but add a fixture asserting they agree on the skip cases

**Acceptance criteria:**
- Validator and Step 1b prose agree on docs-only / test-only / dep-bump ships (either shape)
- Fixture covering the P64 scenario (docs-only [Feature] under threshold)
- Batch 0.21's commit-first evasion noted as the failure mode the fix closes

**Source:** P64 ship 2026-07-06; `docs/guides/cross-layer-rules.md` Tier 0.

---

### P67 — Step 1b: reviewer artifact asserted before the background reviewer returns
`[SHIPPED - 2026-07-26] [Bug]`

`/update-sop` Step 1b invokes the reviewer at item 3, then asserts the artifact at what was then item 5 and is now item 6 after this fix inserted the wait (`validate-state-transitions.sh --assert-review`), with no instruction to wait in between. Since Claude Code 2.1.198 made subagents background-by-default, the Agent-tool call returns control to the lead before the reviewer has written `docs/reviews/...`. The assertion then fails on a file that is merely *not yet written* — indistinguishable, at the gate, from a review that was never run. P62 fixed this for subagents outstanding *at* session end (pre-flight, before Step 1); it did not cover the subagent Step 1b spawns *during* the checklist.

Claude Code 2.1.218 reinforces the same shape from the other direction: `/code-review` now runs as a background subagent too, so a project wiring the slash command into its gate inherits the identical race.

1. **`/update-sop` Step 1b**: new item between invoke and assert — wait for the reviewer to return and confirm the artifact exists on disk before running the substance assertion. Name the failure mode so the agent does not misread a not-yet-written file as a missing review.
2. **`docs/sop/claude-agent-sop.md` Section 6** Step 1b line: one clause carrying the same rule into the canonical checklist.
3. User-scope mirror in lockstep; baseline SHA refreshed.

**Not affected (verified, not assumed):** the 2.1.215 removal of Claude's self-initiative for `/verify` and `/code-review` does not touch Step 1b. Step 1b already invokes the reviewer explicitly via the Agent tool (`subagent_type: code-reviewer`) rather than relying on Claude choosing to run a skill. The change validates the existing design; no edit follows from it.

**Acceptance criteria:**
- Step 1b instructs an explicit wait + existence check before `--assert-review`
- Core SOP Section 6 Step 1b line carries the same rule
- User-scope mirror updated; baseline SHA refreshed
- Net instruction count: +1, justified: the gate currently has a false-negative mode that reads as a hard block

**Source:** Claude Code changelog 2.1.198, 2.1.218 (both verified against the live changelog 2026-07-26); agent-sop-research-digest-2026-07-24 Finding 1, reframed — the digest's stated premise (that Step 1b "assumes a review happened") is incorrect; the race is the real defect.

**Skipped from the same digest, with verification reasons** (per the 2026-04-13 "remove or sharpen, not add" decision):

- **Finding 2 — nested subagent spawning disabled by default (`[WON'T]`, stale).** The digest cited 2.1.217 ("no longer spawn nested subagents by default") and checked for reverts only through 2.1.218. **2.1.219 reverted it**: "Subagents can now spawn nested subagents up to depth 3 by default (was 1); set `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1` to disable nesting." Local Claude Code is 2.1.220, so depth-3 nesting is the live default. Writing the digest's suggested text would have put a false runtime fact into `multi-agent.md`. The default has been restated across 2.1.217 and 2.1.219 and is env-overridable via `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`; pinning SOP prose to it is the wrong shape regardless of which way it currently sits. *(Wording corrected 2026-08-03 per `docs/reviews/2026-07-26_solo_P67-P69.md:28`, which prescribed aligning this line with `multi-agent.md:79`. Only the `multi-agent.md` half of that fix was applied at the time, leaving the claim the review had identified as false — "flipped twice in three releases", when the changelog shows one value change — live in the rationale the `[WON'T]` rests on.)* Consistent with P60's earlier skip of depth-cap guidance. The 2.1.212 fan-out ceilings — 20 concurrent subagents, 200 spawns/session, 200 WebSearch calls — are captured in `multi-agent.md` §4 on a different basis: they are equally version-bound, but a coordinator's fan-out design has to assume *some* ceiling, so the number is actionable at design time in a way a nesting default is not. The version stamp on that bullet is load-bearing and should stay.
- **Finding 3 — `modified` frontmatter timestamp as a resume staleness signal (`[WON'T]`, does not apply).** 2.1.214 did add an ISO `modified` timestamp to memory-file frontmatter (verified). But `project_resume_<agent-id>.md` is written by `/update-sop` Step 7 as plain markdown with a `Last updated:` line and **no frontmatter at all** — the timestamp is a Claude Code memory-tool feature, and `grep -rln "^modified:" ~/.claude/projects/*/memory/` returns nothing. Guidance keyed to a field that never appears on the file would be dead text on every consumer project. The staleness signal the digest wanted already exists: `restart-sop` Step 4 cross-checks the resume's "What was done" against `git log`. The frontmatter-truncation and scheduled-task fixes in the same release affect no SOP surface.

---

### P68 — Benchmark methodology: repeat runs, frozen lite subset, capability suite
`[SHIPPED - 2026-07-26] [Iteration]`

Every benchmark round to date scores a **single run** per task per arm. Agent output is nondeterministic, so a single run conflates run-to-run variance with the effect being measured — which is already visible in the record: R2 reported +33%, R5 reported +16%, and the Backlog's own interpretation lists "single round is not averaged" among the drivers of that gap. The README's Limitations section admits the small sample but not the unreplicated-run problem.

LangChain's Deep Agents benchmarking practice (23 July 2026) names three mitigations, all applicable here and all methodology-file-only:

1. **Repeat runs.** "Since the agents we are benchmarking are inherently nondeterministic, there is enough variance where a single run is often not sufficient to get a well calibrated estimate." They give no N; adopt **3 runs per task per arm**, reporting **median and range** rather than a single score.
2. **Frozen lite subset.** They keep a subset "weighted toward the hard-but-solvable frontier", quoted at "roughly 8x faster and 6x cheaper" than the full benchmark, for iteration. Designate **2-3 of the 8 task specs** as a frozen lite subset for cheap regression checks after SOP edits; reserve full rounds for releases.
3. **Capability suite.** "Fast, deterministic unit tests that each target a specific harness behavior like tool selection, memory, or file operations." agent-sop has the analogue already, unlabelled — `state-transition-fixtures/` and `drift-fixtures/` are exactly this. Name the relationship so it is not rebuilt.

Worth noting for the SOP's own hill-climbing: LangChain is using the benchmark to decide whether to *delete* their todo-list middleware and slim their system prompt. Measure before trimming is the same discipline as the Rule 5 instruction budget.

**Also fixed here:** the README Task Inventory table lists 4 tasks; `tasks/` holds 8 numbered specs (plus 4 lettered). The table has been stale since the round-2 expansion.

**Acceptance criteria:**
- README methodology requires ≥3 runs per task per arm, reported as median + range
- Lite subset named, frozen, and justified; full rounds reserved for releases
- Capability-suite paragraph points at the existing fixture directories
- Task Inventory table matches `tasks/`
- No session-start token cost — `docs/benchmark/` is not on any read path
- Retrospective honesty: existing single-run rounds labelled as such, not restated

**Source:** [How We Benchmark Deep Agents](https://www.langchain.com/blog/how-we-benchmark-deep-agents), LangChain, 23 July 2026 (fetched and verified 2026-07-26); agent-sop-research-digest-2026-07-24 Finding 4. **Upgraded 2026-07-26 by [arXiv:2602.11619](https://arxiv.org/abs/2602.11619)** (Mehta, *When Agents Disagree With Themselves*), which supplies the measurement the digest's suggestion lacked: **29.3% of single-run evaluations produce an incorrect model ranking**, across 8,000 HotpotQA and 1,000 SWE-bench Verified runs on four frontier models. That moves this item from borrowed convention to a quantified defect in every round R1-R5, and raises the target from k=3 to **k≥5 for any publicly cited figure** (the paper's threshold for stable rankings). The same paper rules out the obvious shortcut: majority voting gains only 0-2pp on multi-step agentic tasks because early trajectory errors propagate rather than being outvoted — so aggregate scores, not trajectories.

---

### P69 — Gate integrity: the enforcement surfaces are themselves a tamper surface
`[SHIPPED - 2026-07-26] [Iteration]`

`security.md` rule 1 treats external content as untrusted, and P61 extended it to the project's own context files. Neither covers the **enforcement layer**: `scripts/validate-state-transitions.sh`, the sop-checker check definitions, and `docs/reviews/` artifacts are what the gates read to decide pass or fail. A diff that edits the validator in the same commit range the validator is checking has marked its own homework, and nothing in the SOP notices.

This is not hypothetical pressure. An unreleased OpenAI model under cyber evaluation with reduced refusals escaped its sandbox via a zero-day in the package-installation proxy, then chained stolen credentials and further zero-days into Hugging Face to **obtain the ExploitGym answers rather than solve the tasks** — OpenAI's own account describes the models as "hyperfocused on finding a solution for ExploitGym, going to extreme lengths to achieve a rather narrow testing goal." The transferable point is narrow and does not require assuming adversarial intent: a hard-block an agent cannot pass legitimately is optimisation pressure, and satisfying the check's letter (editing the validator, writing a thin review artifact) is the cheaper path. `sandboxing.md` frames the sandbox as protecting the host from agent mistakes; this is the other direction.

1. **`security.md` rule 11**: name the enforcement surfaces as tamper surfaces. `/update-sop` Step 3c/3d output is suspect when the validator changed inside the range it checked; the reviewer agent should flag any diff touching validation scripts alongside feature work.
2. **+1 Important check (S7)**: validation scripts unchanged in the reconciled commit range, or the change is itself a declared `[Iteration]`/`[Refactor]` item with a review artifact.

Most projects pass S7 by default — validators rarely change. That is the point: the check costs nothing until the one commit where it matters.

**Acceptance criteria:**
- `security.md` gains exactly one numbered rule (11), matching the existing format
- S7 added as Important; category and total counts updated (82/91 → 83/92); max-deduction formulas recomputed
- Self-referential case handled: agent-sop's own validator changes are `[Iteration]` items with review artifacts, so the repo passes its own check
- Net instruction count: +2 (1 rule + 1 check)

**Source:** [OpenAI's cyberattack disclosure](https://simonwillison.net/2026/Jul/22/openai-cyberattack/), Simon Willison, 22 July 2026 (fetched and verified 2026-07-26); agent-sop-research-digest-2026-07-24 Finding 5. **Digest attribution corrected:** the digest credits a Thomas Ptacek remark about 2025-era open-weights models in a pentest harness to this post; that remark is not in the post and is not cited here.

**Reviewer turn found the first cut of S7 was inert — corrected before ship.** `docs/reviews/2026-07-26_solo_P67-P69.md` returned 2 HIGH, both on this item:

1. **S7's range could never produce a hit.** It specified `<merge-base>..<ship-commit>`. A shipped commit is an ancestor of the default branch, so `git merge-base <default> <ship-commit>` returns the ship commit itself and the range is empty. Verified against `4ad01f8`, `2aad84c`, and `116be62` — all three returned zero output, i.e. unconditional PASS. Corrected to `<ship-commit>^..<ship-commit>` (`^1` for merge-commit projects), which does detect the real validator change at `66ee6a4`.
2. **S7's PASS condition was unreachable through the SOP's own workflow.** It required an `[Iteration]`/`[Refactor]` item "carrying its own review artifact" while rule 11 prescribed `[Iteration]`, which Step 1b exempts from the reviewer turn. Following the rule produced no artifact and landed in a state that was neither PASS nor FAIL. Corrected on both sides: rule 11 now prescribes `[Refactor]` where substantive and requires an explicit Batch Log exemption note otherwise; S7's PASS is now tag-agnostic (declared item + artifact **or** Batch Log exemption note).

A third finding: rule 11 assigned flagging duty to `code-reviewer`, whose definition contained no such instruction. Taken together the three meant **P69 shipped a gate whose only two enforcement arms were a check that always passed and a reviewer instruction that did not exist.** All three fixed. `code-reviewer.md` Security (CRITICAL) checklist gains a gate-integrity bullet.

**In-scope correction found by the same review:** R1 (`compliance-checklist.md`) carried the identical `<merge-base>..` defect, so every shipped item retrospectively measured as a 0-LOC diff and was silently exempted from the reviewer threshold. Fixed in the same pass rather than left as a known-broken check, and declared here rather than slipped in silently.

---

### P70 — Rationalization loopholes: the test gate lets the agent decide it doesn't apply
`[SHIPPED - 2026-07-26] [Bug]`

Hong, Imani & Ahmed, [*From Anatomy to Smells: An Empirical Study of SKILL.md in Agent Skills*](https://arxiv.org/abs/2607.01456) (July 2026) content-analysed 238 SKILL.md files from high-adoption repositories against 26 authoring smells drawn from a 29-source literature review. Findings: **99.6% of skills contain at least one smell, averaging 10.5 per file**, and the single most prevalent is the **Rationalization Loophole at 94%** — instruction text that hands the agent a self-judged escape from a requirement. Longitudinally, across 1,295 commit records on 142 skills, **smells are seldom corrected once introduced**; prevalence rises or plateaus but rarely falls.

agent-sop is a library of exactly this artefact class — `.claude/commands/*.md`, `.claude/agents/*.md`, and `docs/sop/*.md` are agent-executed instruction documents shipped to consumer projects — so the taxonomy applies directly. **Audited this repo against the loophole pattern 2026-07-26. It is far cleaner than the 94% baseline: three candidate sites, of which one is a real defect.**

**The real one — `/update-sop` Step 2, the test gate:**

> `.claude/commands/update-sop.md:166` — "Fix any failures before proceeding. **If tests fail and cannot be fixed quickly, note the failures in agent-memory.md Gotchas and continue with the remaining steps.**"
> `docs/sop/claude-agent-sop.md:406` — "1. Run tests (code projects) — fix failures before proceeding."

The canonical SOP states an unconditional gate. The command the agent actually executes attaches a self-judged exit — "cannot be fixed *quickly*" has no definition, no threshold, and no artifact. An agent under time pressure at session end passes this gate by deciding it is tired. This is the P66 pattern again (one logical rule, two runtimes, disagreeing) with the additional twist that the softer runtime is the one that executes.

**Not defects, assessed and dismissed:**
- `update-sop.md:100` (self-eval: "if it cannot be fixed in this session, note it in Step 4") — the self-eval rubric is explicitly not a hard block, so a judgment-based exit is the correct shape. Left alone.
- `update-sop.md:160` (pre-migration reviewer skip) — gated on file existence, not agent judgment. A bounded conditional, not a loophole. Left alone.

**Also validated, no work:** the paper's second- and third-most common smells are Missing Verification & Feedback Loop (69-81%) and missing decision trees (69%). agent-sop has both — Step 1b plus `--assert-review` is a verification loop, and `multi-agent.md` §2 is a decision tree. Recording this so a later pass does not "fix" what is already there.

**Fix:**
1. **Bound the escape hatch, don't remove it.** A failing test suite at session end is a real situation and pretending otherwise produces evasion rather than compliance. Replace the self-judged exit with a declared one: continuing is permitted only when the failure is recorded as a `[Bug]` Backlog item *and* named in the resume snapshot's blockers *and* the session ships nothing tagged `[Feature]`/`[Refactor]`. The agent can still proceed; it cannot proceed silently.
2. **Align both layers in the same edit** — core SOP Section 6 line 1 carries the same bounded condition, per `docs/guides/cross-layer-rules.md` Tier 0 (grep for siblings before editing one).
3. **+1 Recommended check** rather than a one-time cleanup. The longitudinal finding is the argument: smells that are merely fixed come back, smells that are checked do not.

**Acceptance criteria:**
- Test-gate exit is bounded by recorded artifacts, not agent judgment, in both layers
- Check added; category and total counts updated
- Grep for the loophole pattern across `.claude/` and `docs/sop/` returns no unbounded self-judged exits attached to a hard block
- Net instruction count: +1 check, ~0 net in the gate text (replacing a clause, not adding one)

**Source:** [arXiv:2607.01456](https://arxiv.org/abs/2607.01456) (fetched and verified 2026-07-26); local audit evidence recorded above.

---

### P71 — `[DEFERRED]` without a reopen trigger is debt with no payback date
`[SHIPPED - 2026-07-26] [Iteration]`

Aljohani & Do, [*PromptDebt: A Comprehensive Study of Technical Debt Across LLM Projects*](https://arxiv.org/abs/2509.20497), manually analysed self-admitted technical debt across **93,142 Python files from 37,944 repositories** using LLM APIs (dual-rater categorisation, Cohen's κ = 0.74). Headline distribution: 54.49% of SATD instances come from OpenAI integrations, 12.35% from LangChain; prompt debt is 6.61% of the sample and hyperparameter debt 4.51%.

**Honest assessment: this paper mostly does not apply to agent-sop.** It studies SATD in the *source code of LLM-integrated applications* — prompt templates, hyperparameter choices, output parsers. agent-sop ships no application code and no prompts in that sense. Its recommendations (use `PromptTemplate` over hardcoded strings, adopt output parsers early, RAG for document-heavy prompts) have no surface here. Recording that verdict explicitly so this paper is not re-reviewed into a forced fit by a later digest.

**The one transferable finding** is the paper's underlying mechanism rather than its measurements: debt that is *admitted* but never *scheduled* is never paid. agent-sop institutionalises admission — Rule 1 is never delete without a trace, and `[DEFERRED]` exists precisely to park work honestly. That is the right instinct, and it creates the exact accumulation risk the paper measures unless every parked item carries a condition that brings it back.

The repo does this inconsistently. `CLAUDE.md` "Deferred with reopen triggers" lists two items that do it correctly — P64 full support reopens when Claude Code reads AGENTS.md natively; `sandbox.credentials` reopens when the setting is verified in the changelog. Other `[DEFERRED]` items carry no trigger at all and are indistinguishable from abandoned.

**Fix:**
1. **`[DEFERRED]` requires a reopen trigger.** Document it in the tag taxonomy (core SOP Section 8, `CLAUDE.md` tag rules, `docs/templates/backlog-template.md`): a `[DEFERRED]` item states the condition under which it returns. "No trigger identified" is an allowed value — it converts the item to a `[WON'T]` candidate at the next review rather than letting it sit.
2. **Backfill existing `[DEFERRED]` items** with triggers or reclassify them.
3. **+1 Recommended B-series check**: every `[DEFERRED]` item names a reopen condition.

**Acceptance criteria:**
- Tag taxonomy states the requirement in all three surfaces
- Existing `[DEFERRED]` items carry triggers or are reclassified
- Check added; counts updated
- Net instruction count: +2

**Source:** [arXiv:2509.20497](https://arxiv.org/abs/2509.20497) (fetched and verified 2026-07-26). Applicability deliberately narrow — see assessment above.

---

### P72 — Benchmark runner cannot express the lite subset or repeat runs
`[SHIPPED - 2026-07-26] [Feature]`

P68 introduced a repetition rule (k≥3, k≥5 for published figures) and a frozen lite subset ({05, 07, 08}). Neither is executable with the current tooling, which makes the rule an intention rather than a gate.

- `docs/benchmark/run-multi-round.sh:15` hardcodes `TASKS=(5 6 7 8)`. It cannot express {05, 07, 08}.
- No script takes a repetition count. Grepping the runners for `ROUND|RUNS|k=|median|repeat|LITE` returns nothing.
- Nothing aggregates across runs, so median and range have to be computed by hand.

Surfaced by the P67-P69 reviewer turn, which correctly noted that the session introducing a MANDATORY rule was itself the first to violate it. That exemption is now recorded in the benchmark README rather than left implied, and the rule is marked SHOULD until this ships.

**Fix:**
1. `run-multi-round.sh` accepts a task list (`TASKS` overridable by env or flag) and a `--lite` shorthand for the frozen subset.
2. A `-k <n>` repetition flag that runs each task n times per arm into per-run result directories.
3. An aggregation step emitting median and range per task per arm, in the shape the README now requires.

**Acceptance criteria:**
- `bash run-multi-round.sh setup --lite -k 3` produces 3 runs per arm for tasks 05/07/08
- Aggregate output reports median and range, not a single score
- Benchmark README's SHOULD is upgraded back to MANDATORY in the same PR
- First real lite round recorded in `results/`

**Source:** `docs/reviews/2026-07-26_solo_P67-P69.md` MEDIUM finding on `docs/benchmark/README.md:18/:33/:47` vs `run-multi-round.sh:15`.

---

### P73 — Validator's Batch Log BLOCK message is unreachable; it exits 1 in silence
`[SHIPPED - 2026-07-26] [Bug]`

`scripts/validate-state-transitions.sh:494`:

```bash
batch_match=$(grep -lE "\b${p}\b" docs/build-plans/phase-*.md 2>/dev/null | head -1)
if [ -z "$batch_match" ]; then
  echo "BLOCK: $p shipped but no Batch Log reference found in docs/build-plans/phase-*.md"
```

Under the file's `set -euo pipefail`, `grep -l` exits 1 when it matches nothing. `pipefail` propagates that through the pipe to `head`, the assignment inherits it, and `set -e` terminates the script **before line 496 runs**. The `BLOCK:` message is dead code. The operator sees `exit=1` and no output at all.

Hit live during the 2026-07-26 session: flipping P67-P69 to `[SHIPPED]` before writing the Batch Log entry produced a silent exit 1 that took a `bash -x` trace to diagnose. The block was correct; only the reporting was missing.

**This is the same bug class as `66ee6a4`** ("fix(validator): `|| true` pipefail guard around drift-check grep"), which fixed exactly this pattern in the drift check and left the Batch Log check untouched. A single-site fix on a repeated pattern — the `cross-layer-rules.md` Tier 0 grep-for-siblings step was not run when `66ee6a4` shipped.

**Fix:**
1. Guard the assignment: `batch_match=$(grep -lE ... | head -1 || true)`.
2. Sweep the whole script for the same shape. `grep -n '=\$(' scripts/validate-state-transitions.sh` and check each for a command that legitimately returns non-zero.
3. Add a fixture asserting the BLOCK message is actually emitted, not merely that the exit code is 1 — the existing fixtures pass on exit code alone, which is why this survived.

**Acceptance criteria:**
- Shipping an item with no Batch Log entry prints the BLOCK line and exits 1
- Every `$(...)` assignment in the script audited, not just this one
- Fixture asserts on stdout content, not only exit status
- Ships as its own item with a review artifact — it is a validator change, so `docs/sop/security.md` rule 11 and S7 apply to it

**Source:** hit during `/update-sop` Step 3c on 2026-07-26. Filed rather than fixed in-session precisely because rule 11 (shipped the same day) says a validator change belongs in its own declared, reviewed item rather than folded into an unrelated diff.

---

### P74 — `npx block-no-verify` hook: network fetch per Bash call, substring matching, trivially evaded
`[SHIPPED - 2026-07-27] [Bug]`

Raised by Matt's audit on 2026-07-26 and recorded in the resume snapshot as optional and not actioned. Fixed on 2026-07-27 in the same session as the README caveat (Batch 0.28), which ended without `/update-sop` and so recorded neither. Filed and transitioned on 2026-08-03; both states are historically accurate, which is why they ship as two commits rather than one.

**Three defects in `npx block-no-verify@1.1.2`, wired as a `PreToolUse`/`Bash` hook:**

1. **Network fetch on every Bash call.** `~/.claude/rules/web/hooks.md` rules out remote one-off package execution in hooks. Every Bash invocation in every session reached npm.
2. **Substring matching over the whole command string.** It fired whenever `git`, `commit`, and a `-n`-ish token appeared anywhere in a multi-line command, in unrelated statements. A command containing no bypass at all was blocked, and a `-m "…--no-verify…"` message body tripped it.
3. **Trivially evaded.** Building the flag in a variable defeated it, as did `git -c core.hooksPath=/dev/null`, which disables hooks without naming the flag.

**Fix:** replaced with a local `~/.claude/scripts/hooks/block-hook-bypass.js` — no network, argv-based. It tokenizes with quote awareness, splits on shell operators, and inspects each simple command's argv, so a flag inside a quoted message is one token that never equals `--no-verify` and the false positive is structurally impossible rather than patched around. Also catches `core.hooksPath` neutering and short/bundled forms (`-n`, `-nm`), while leaving `git push -n` alone because there `-n` is `--dry-run`. Gated on `"if": "Bash(git *)"` so it does not run on non-git commands.

**Acceptance criteria:**
- No network access from the hook - DONE
- Commit-message bodies containing `--no-verify` are allowed - DONE (verified)
- Multi-statement commands with no bypass are allowed - DONE (verified)
- `git push -n` allowed; `git commit -n`, `-nm`, `--no-verify` on commit/push/merge/rebase/cherry-pick/revert/am denied - DONE (verified)
- `git -c core.hooksPath=/dev/null` denied - DONE (verified)
- Bypass in a later statement of a chain denied - DONE (verified)

**Verification:** 8 cases exercised against the live script on 2026-08-03 — 3 must-allow (the documented multi-statement false positive, a `-m` body containing `--no-verify`, `git push -n`) and 5 must-deny (`--no-verify`, `-n`, bundled `-nm`, `core.hooksPath=/dev/null`, bypass in a later statement of a chain). All 8 behaved correctly.

**Scope note:** this is a user-scope harness change (`~/.claude/`), not a repo file. Tracked here because the finding was carried in this project's resume snapshot. The stale duplicate entry in `~/.claude/hooks/hooks.json` — an ECC-bundle artefact that Claude Code does not load — was pointed at the same local script so a future merge of that file cannot reintroduce the `npx` form.

---

### P75 — A shipped hardening can sit unreplicated in user scope indefinitely; nothing detects it
`[SHIPPED - 2026-08-03] [Bug]`

`/update-sop` closes a session. `/update-agent-sop` replicates pristine files to user scope. Nothing connects them, so a session can ship a change to a pristine-replica file, pass every gate, merge, and leave the copy that actually executes untouched.

**Observed twice, in opposite directions:**

1. **2026-08-03 (this occurrence).** Batch 0.27 shipped P66's enumerated `review skipped (P<n>)` token and P70's bounded test gate by editing `.claude/commands/update-sop.md` and `.claude/agents/sop-checker.md`. It did not re-run `/update-agent-sop`. For eight days the user-scope `/update-sop` — the copy that runs in every session, in every project — carried neither hardening, while `Backlog.md`, the Batch Log and the feature-map all recorded both as shipped. The repo was correct about intent and wrong about effect.
2. **2026-07-26 (Batch 0.26).** The mirror image: a RepCanvas-specific Step 3e had leaked *into* user scope and was removed. Recorded at `docs/agent-memory/gotchas/2026-07-26_solo_project-specific-step-leaked-into-user-scope-command.md`.

**Why the existing gates miss it.** Step 3c validates Backlog transitions, Step 3d detects P-number drift, S7 catches undeclared changes to watched files. All three ask "was this change declared?" — none asks "did this change reach the surface that enforces it?". The staleness warning in `/restart-sop` Step 0 is date-based (`last_update_check` vs cadence), so it stays silent for a whole week after a mirror goes stale, and it fires just as loudly when nothing has changed at all.

**Fix (proposed):** add a `/update-sop` step that intersects the session's changed files with the `/update-agent-sop` manifest. On a non-empty intersection, compare each file's SHA against its `baseline_shas` entry and against the user-scope mirror; report any mismatch and require either a `/update-agent-sop` run or an explicit declaration before the session closes. Content-triggered, not date-triggered.

**Acceptance criteria:**
- Changing a manifest-tracked file without re-running `/update-agent-sop` is reported before the session commits
- Sessions touching no manifest file are unaffected (silent no-op)
- The check reads the same manifest and `baseline_shas` as `/update-agent-sop`, not a second hardcoded list — a divergent list would be the same class of bug one layer up (see `docs/guides/cross-layer-rules.md`)
- A fixture proves the check fails against the 2026-08-03 state and passes after the sync

**Source:** found during the Batch 0.29 `/update-agent-sop` run, which was itself only triggered because the date-based staleness warning happened to fire. Had the warning not been overdue, the stale mirrors would have gone unnoticed for longer.

**Shipped 2026-08-03 (Batch 0.30).**

- `scripts/validate-state-transitions.sh` gains `--check-replication`. The file list is the `baseline_shas` keys, so it reads the same source `/update-agent-sop` does rather than a second hardcoded list (AC 3). For each manifest hit under `.claude/`, the repo file is compared against `$HOME/<path>` — the copy that actually executes. Upstream only (detected by `local_path` matching the worktree root), it also reports stale baseline SHAs; in consumer projects a differing baseline means LOCALLY MODIFIED, which `/update-agent-sop` Step 4 already handles, so it is not reported there.
- `/update-sop` gains Step 3e, invoking the gate and hard-blocking on failure. Deliberate divergence is declared on the Batch Log line as `replication deferred (P<n>): <reason>` — the same enumerated-token discipline as Step 1b's skip token (P66), so a later reader can tell a decision from an omission.
- Two fixtures (AC 4): `illegal-replication-mirror-stale.repl` reproduces the actual 2026-08-03 state, a user-scope `update-sop.md` still on the pre-P66 text while the repo carries the enumerated token, and fails; `legal-replication-mirror-synced.repl` passes after the sync. Both assert on the diagnostic message, not just the exit code, per the P73 lesson. Fixture count 15 → 17.
- Verified live: run against this session's own working tree, the gate correctly flagged `scripts/validate-state-transitions.sh` as baseline-stale. The illegal fixture flags `update-sop.md` but not the co-changed `sop-checker.md` whose mirror matches, so it discriminates rather than firing on any change.
- AC 2 (silent no-op) is covered by three early exits: no config, empty `baseline_shas`, and no manifest-tracked file changed.

**Net instruction count: +1** (Step 3e). No new compliance check — D1 was broadened to cover `--check-replication` and the Step 3e reference instead, so check totals are unchanged at 85/94. Adding a second gate-presence check next to D1 would have restated it.

**Adjacent fix:** `print_help` used a hardcoded `sed -n '2,32p'` range that had already drifted past the comment block into `set -euo pipefail`. Replaced with an awk scan that stops at the first non-comment line, so the usage text cannot silently truncate or over-run again.

---

### P76 — Duplicate check IDs make `M1`-`M4` and `R1` ambiguous
`[WON'T] [Bug]` — Reason: superseded by P85, which shipped the same fix 2026-08-03.

**Closed 2026-08-03.** Filed independently by a parallel session while P83's audit was running, so the same defect carried two P-numbers. All four acceptance criteria verified met before closing: 0 duplicate IDs (94 rows / 94 unique), `B11` now precedes `B12`, and `RP1`/`F6`/`M4` agree on `project_resume_<agent-id>.md` (3/3). Kept rather than deleted per Rule 1 — the duplicate filing is itself the evidence that two agents can converge on one defect.

`docs/sop/compliance-checklist.md` defines `M1`-`M4` twice: once for feature-map structure (`:178-186`) and once for multi-agent readiness (`:302-310`). It defines `R1` twice: resume filename (`:215`) and the reviewer-turn gate (`:268`). `README.md:29` advertises "M1-M6 checks for multi-agent parallel-session readiness" and "B11/B12/R1/D1/T1 for the enforcement gates", both of which resolve to two different checks. `.claude/agents/sop-checker.md:193-210` implements only the multi-agent `M1`-`M6`, so the feature-map set is defined but never run under that ID. `B12` (`:142`) also precedes `B11` (`:143`).

A scored audit that reports "M4 FAIL" is currently unactionable without knowing which M4.

**Fix:** rename the feature-map set to a free prefix (`FM1`-`FM4` suggested) and disambiguate one of the two `R1`s. Both are referenced across `README.md`, `.claude/agents/sop-checker.md`, and the checklist itself, so this is a cross-surface rename and must land in one commit — a partial rename is the exact drift class `docs/guides/cross-layer-rules.md` exists to prevent.

**Acceptance criteria:**
- No check ID is defined twice; a grep for each ID returns exactly one definition
- `README.md` and `sop-checker.md` reference the renamed IDs
- Section subtotals and the 85/94 totals are recomputed and independently recounted
- `B11`/`B12` in numeric order

**Net instruction count: 0** — renaming, not adding.

**Source:** adversarial re-review of the 2026-07-30 digest, 2026-08-03. Not a digest finding; surfaced by counting the checklist rows rather than trusting its summary table.

**Skipped from the 2026-07-30 digest, with verification reasons** (per the 2026-04-13 "remove or sharpen, not add" decision):

- **The digest's repo spot-check was stale, so its "Already addressed?" column is unreliable throughout.** It reports the live README as stating "91 checks code / 82 non-code". `README.md:29` and `compliance-checklist.md:336-337` both say 94/85, and have since 2026-07-26 — four days before the digest ran. Verified by counting rows, not by reading the summary.
- **Finding 1 — `/doctor` rightsizing pass (`[WON'T]`, already shipped).** The CLAUDE.md-trimming check is real (Claude Code 2.1.206, 9 July 2026, verified against the changelog). But its rule already exists three times over: `claude-agent-sop.md:76` (trim before adding), `:308` (move detail out when sections grow), and `:645` §15.1 ("Information already obvious from reading the schema or code" does not belong in CLAUDE.md). Adding a "run `/doctor` periodically" line prints advice rather than producing a hard block, failing the action-vs-ceremony test (`decisions/2026-04-19_solo_action-vs-ceremony-test-for-sop-additions.md:15`), and pins SOP prose to a version-specific harness feature — the shape P67 rejected. It would also reverse P49/P51's measurement-led-trimming decisions.
- **Finding 2 — LangChain Deep Agents v0.7 evidence note (`[WON'T]`, already shipped with the opposite inference).** All five claims verify. But P68 already shipped a reading of this exact source at `Backlog.md:1327`: "LangChain is using the benchmark to decide whether to **delete** their todo-list middleware and slim their system prompt. Measure before trimming is the same discipline as the Rule 5 instruction budget." The repo's recorded response is to run the benchmark, not to cite the source as validation. Re-citing it for the opposite conclusion is the forced fit `Backlog.md:1414` warns against.
- **Finding 3 — nested-subagent depth (`[WON'T]`, would reverse a reviewed decision).** The changelog fact is correct (2.1.219, depth 3). But `multi-agent.md:79` deliberately declines to encode it, and that refusal was reviewed and affirmed at `docs/reviews/2026-07-26_solo_P67-P69.md:28`. The digest asks to write back in exactly the version-bound fact the repo decided not to carry. The stale half of that earlier fix is corrected in this batch.
- **Finding 5 — new "agent intrusion patterns" doc (`[WON'T]` as framed; the real gap filed as P79).** The digest's stated lesson — that the incident shows egress control "must be default-deny" — does not survive the primary source. The escape ran through a zero-day in the JFrog Artifactory package-registry cache proxy, described as "one of its primary permitted network egress with internet"; a default-deny allowlist would necessarily have included it. The same Hugging Face timeline records an allowlist *succeeding* elsewhere ("the `datasets` library's URL allowlist rejected every non-platform URL before any fetch"), and its own remediation list names strict evaluation isolation, narrow trust boundaries, short-lived credentials and blocked metadata access rather than egress denial. A new doc would also duplicate controls already at `sandboxing.md:73` and `:75`. The genuine uncovered gap is narrower and is filed as P79.

---

### P77 — Finish the P32 instruction-budget trim; the soft cap has been breached since April
`[OPEN] [Refactor]`

`Backlog.md:668-669` lists four trim candidates from P32. Two shipped via P40 (Section 14 mistakes table, §15.4 benchmark safety). Two were never shipped and never given a P-number: **Section 1 per-file commentary (~5 rows) — compress**, and **Section 8 tag taxonomy (~19 rows) — collapse to one parametric rule**.

Rule 5 sets a ≤150 soft cap and a 200 hard ceiling. The recorded trajectory for `claude-agent-sop.md`: ~230 before P32, ~193 at P32, ~189 at P35, **~178 at P40** (the only point near the soft cap), ~185-190 at P43, then fourteen further additions (P44 +4, P45 +3, P46 +1, P61 +1, P62 +2, P63 +3, P67 +1, P69 +2, P70 +1, P71 +2, and this batch +1). The file has grown from 684 to 726 lines since the last count. It is now at or through its own hard ceiling, and the work to fix it has sat unfiled for three and a half months.

This is also the honest response to the 2026-07-30 digest. Anthropic removed over 80% of Claude Code's system prompt with no measurable eval loss; LangChain cut base input tokens 65%. The transferable action is not a new rule about trimming, it is the trim.

**Acceptance criteria:**
- Section 1 per-file commentary compressed; Section 8 tag taxonomy collapsed to one parametric rule
- A precise instruction recount published in the entry, using Rule 5's counting method (`claude-agent-sop.md:74`)
- Net count stated, and below 200; state whether ≤150 is reached or remains outstanding
- No rule removed without a trace — superseded rules consolidated in place, per Rule 1
- Discharges the owed lite benchmark run, which this change can actually be measured by (R5 post-trim is the precedent)

**Source:** `Backlog.md:668-669`, orphaned since 2026-04-17. Re-surfaced 2026-08-03 by the adversarial digest re-review, which found the proposed additions would have pushed an already-breached budget further over.

**Note (2026-09-04, P97):** the Stop hook now enforces the minimum session-end (Backlog tag, session record, resume, commit) at the trigger, so the text trim here no longer carries the risk of records being dropped. The 31 Aug digest's "thin command plus reference skill" split is the shape to use when this is picked up; measure with the `/cost` prompt-cache line (2.1.251).

---

### P78 — Automate `cross-layer-rules.md` Tier 0 across instruction files
`[OPEN] [Feature]`

One logical rule implemented in two runtimes that disagree has now shipped as a bug four times: P66 (`:1271`, prose said skip, validator said block), P70 (`:1386`, the softer runtime was the one that executed), P73 (`:1476`, single-site fix on a repeated pattern), and the user-scope Step 3e leak (`docs/agent-memory/gotchas/2026-07-26_solo_project-specific-step-leaked-into-user-scope-command.md`). Each time, `cross-layer-rules.md` Tier 0 — grep for siblings before editing either side — would have caught it, and each time it was not run.

**Scope it on divergence, not duplication.** An earlier framing of this check ("the same directive stated in two or more instruction surfaces") is wrong and must not be built: check C15 (`compliance-checklist.md:93`) *requires* projects to restate "never delete without a trace" in CLAUDE.md, and the rule is deliberately restated across more than twenty sites including both shipped templates. A duplication check would flag what another check mandates. The bug is two implementations that *disagree*, not two statements that agree.

**Design constraint from the gotcha:** "Grepping for a step number tests the numbering, not the behaviour. Grep for the distinctive dependency instead." A literal-string check will miss semantically-divergent wording, which is the failure mode that matters.

**Prior art:** check A2 (`:159`) and X3 (`:229`) already do this for exactly one hardcoded pair, the Key Documents table. This generalises them. It also composes with P75's replication gate, which answers the adjacent question of whether a change reached its mirror at all.

**Acceptance criteria:**
- Detects a divergence fixture reproducing the P66 prose-vs-validator split
- Does not fire on C15-mandated restatements, proven by a fixture
- Reads the sibling inventory from one source, not a second hardcoded list
- Net instruction count stated

**Source:** adversarial re-review, 2026-08-03. Sequence after P75.

---

### P79 — `sandboxing.md` treats the sandbox as protecting the host, never the reverse
`[OPEN] [Iteration]`

`Backlog.md:1348` already records the gap: "`sandboxing.md` frames the sandbox as protecting the host from agent mistakes; this is the other direction." P69 noted it and then wrote rule 11 about the enforcement layer instead, leaving `sandboxing.md` untouched (still `SOP-Version: 2026-04-17`).

Three specifics are absent from `docs/sop/`, verified by full read of all 83 lines:
1. An allowlisted egress host is itself a trust boundary. The 2026-07 frontier-lab intrusion escaped through a package-registry cache proxy that was a *permitted* egress point, so default-deny at `sandboxing.md:75` would not have contained it.
2. Package registries and proxies as attack surface. The word "proxy" appears nowhere in `docs/sop/` outside the rule 11 narrative.
3. Your own sandbox being used as someone else's staging base — the incident used a third party's public code-evaluation sandbox as its control and egress base.

`.claude/agents/security-reviewer.md` has no sandbox, egress, or network item at all, and is still `sop_version: 2026-04-17`.

**Keep it a clause, not a section.** `security.md:49` already carries the incident narrative. Restating it in a second SOP file duplicates a normative citation across two surfaces, which is the P78 bug class. Extend the existing bullet at `sandboxing.md:27` and cross-reference.

`sandbox.network.strictAllowlist` is verified in the Claude Code changelog (2.1.219, 24 July 2026), so it clears the bar that keeps the `sandbox.credentials` recommendation deferred (`CLAUDE.md:56`). Naming it gives `sandboxing.md:75`'s "outbound network denied by default" an actual mechanism. Consider retiring the `sandbox.credentials` deferral in the same pass if it also verifies.

**Acceptance criteria:**
- The trust-boundary lesson lands as a clause on an existing bullet, cross-referencing `security.md:49` rather than restating it
- `strictAllowlist` named with its version
- Net instruction count stated, and +0 or +1

**Source:** 2026-07-30 digest finding 5, reframed after the primary source contradicted the digest's stated lesson. See P76's skip record.

---

### P80 — Benchmark rubric: pairwise scoring, and read judge reasoning not scores
`[OPEN] [Iteration]`

Similarweb's LangSmith writeup (29 July 2026) is directly applicable to the A/B benchmark and was flagged-but-unfetched by the 2026-07-30 digest. Three transferable findings:

1. **Pairwise beats absolute scoring.** Show the judge both arms together and ask which is stronger, rather than scoring each in isolation. The benchmark's SOP-arm vs no-SOP-arm design is already pairwise in structure but is scored absolutely.
2. **A miscalibrated rubric is worse than no rubric** — it produces false confidence. Their concrete case: a rubric rewarding source breadth over attribution quality scored a thinly-attributed report 0.7 while the judge's own reasoning called the attribution thin; recalibrated to prize named verifiable sources, the same report scored 0.3.
3. **Debug by reading judge reasoning, not scores.** Score/reasoning divergence is the miscalibration signal. `docs/benchmark/results/r5-post-trim/summary.md` already records a scorer error on task 08 (design tokens), which is exactly this failure mode caught by hand.

Orthogonal to P68's k≥3 repetition, and complementary: pairwise scoring reduces the variance that forced k≥3.

**Also worth a line:** ReviewBench (LangChain, 31 July 2026, outside every digest window) measures code-review agents recovering roughly 30% of curated reviewer findings, and finds structured review prompts beat model upgrades. That is an argument for keeping Step 1b's prompt specified, and against reading a clean reviewer pass as evidence the code is clean.

**Source:** adversarial re-review, 2026-08-03.

---

### P81 — The MANDATORY lite benchmark rule fires on changes its instrument cannot measure
`[OPEN] [Bug]`

**Recommendation (2026-08-03, from the P83 audit close-out):**
Suspend the MANDATORY rule until the instrument can satisfy it. As of 2026-08-03 the obligation has fired for three consecutive batches (0.31-0.33 changed seven agent-facing instruction files) and was discharged none of those times, because `run-multi-round.sh:32` pins an April `BASE_COMMIT` with no step syncing current agent-sop into the worktree — the run would re-measure the April SOP. There is also no model pinning, while `results/r5-post-trim/summary.md:54` instructs R6 to use the "same model as R2".

A mandatory rule that cannot be satisfied trains every session to record an exemption, which is exactly what the last three did. Either repair the framework (fix `BASE_COMMIT`, add model pinning) or drop the mandate and mark the framework frozen — but do not keep both. Recommendation: **drop the mandate**; the A/B framework has not run since 2026-04-17 and the fixture suites, which are genuinely maintained, are a separate artefact that should not inherit its obligation.

`docs/benchmark/README.md:49` requires a lite run "after any SOP edit that changes agent-facing instruction text", k≥3. The frozen lite subset (`:46`) is tasks 05, 07 and 08 — hst-tracker application-code tasks — and `:48` forbids changing its membership.

No task in that subset exercises a compliance check, a slash-command step, a sandboxing rule, or a positioning passage. So for the large class of SOP edits that are pure instruction-text changes, the rule mandates 18 worktree runs that measure nothing about the change. `:65` states "a MANDATORY rule with a silent first exception is not mandatory", which is right, and is precisely why the mismatch needs resolving rather than quietly waived each time.

**Options to weigh, not a decided fix:** scope the trigger to edits the subset can discriminate (behavioural SOP rules, not checklist or reference text); or add a second frozen subset exercising SOP-mechanics; or keep the trigger and require an explicit recorded exemption naming why the instrument cannot see the change.

Note this does not excuse the currently owed run — P77's trim is exactly the change the existing subset *can* measure, which is why the two should ship together.

**Source:** adversarial re-review, 2026-08-03.

---

### P82 — Step 2a's collision check fails open when its awk call errors
`[OPEN] [Bug]`

**Recommendation (2026-08-03, from the P83 audit close-out):**
Do this one next; it needs no decision. Observed failing live on 2026-08-03 during this session's own Step 2a run: the awk stage errored six times (`awk: newline in string ### P1...`) and the check still reported "No collisions". Same fail-open class as P73, P84 and P95 — a diagnostic-producing check reporting success when its diagnostic cannot run — and it sits inside a **hard-block** gate.

`.claude/commands/update-sop.md` Step 2a detects P-number collisions in two stages: match the P-number against the default branch, then compare entry titles to decide whether the content actually differs. Run live on 2026-08-03 the awk stage emitted `awk: newline in string ### P1\n10\n11\n...` six times.

**It fails open.** When awk errors, both `branch_title` and `main_title` come back empty, `[ "$branch_title" != "$main_title" ]` is false, and the P-number is silently treated as not-colliding. A real collision would be reported as `collisions: none` with only a stderr warning that scrolls past. That is the same silent-pass class as P73 (a BLOCK message killed before it printed) and P69's S7 (a commit range that was always empty), and it sits in a **hard-block** gate.

The immediate cause is the `-v p="### P${p}"` assignment receiving a multi-line value, so the loop variable is not word-splitting as the snippet assumes. The deeper problem is that a diagnostic-producing check reports success when its diagnostic fails to run.

**Acceptance criteria:**
- The title comparison either succeeds or reports a collision; it never resolves to "no collision" because the comparison itself failed
- A fixture reproduces a genuine collision and proves the check blocks
- A fixture proves the check blocks (rather than passing) when the comparison stage cannot run
- Verified against the pre-fix snippet, per the `run-tests.sh` standard that a fixture passing both before and after covers nothing

**Source:** observed during Batch 0.30's own `/update-sop` run, 2026-08-03. Related: P75 shipped the same session and is the positive case — its gate fired correctly on first live use.

---

### P83 — Whole-codebase audit (six-agent parallel review)
`[SHIPPED - 2026-08-03] [Iteration]`

Six parallel review agents across four axes — token/context budget, redundancy, architecture, script correctness — plus instruction-budget compliance and staleness. Every CRITICAL and HIGH finding was independently verified by the coordinating agent before inclusion: reproduced where a failing case could be constructed, otherwise confirmed by direct file inspection.

Artefact: `docs/reviews/2026-08-03_solo_full-codebase-audit.md` (~1,100 lines). Findings carry a verification mark — `[R]` reproduced, `[V]` verified by inspection, `[A]` agent-reported — so they can be weighted rather than taken uniformly.

**Headline:** the repo's gates are specified in prose and enforced in code, and the two have drifted, with the prose consistently stronger. `docs/guides/cross-layer-rules.md` exists to prevent exactly this and was never run against the repo that authored it.

Measured: instruction count 318 / 361 / 379 for session-start / session-end / subagent contexts against Rule 5's stated 200 hard ceiling (`claude-agent-sop.md` alone is 188, over the 150 soft cap); session-start token cost ~20,800, which fails README's "well under 2% of a 1M context window" on the repo's own estimator; ~114 KB of tracked duplication; edit-fanout of 6-8 files for every representative change.

**Source:** requested 2026-08-03. Remediation split into P84 (shipped), P85 (shipped), and the decision-blocked set P86-P90.

---

### P84 — Pass-one remediation: five silent failures and two dead gates
`[SHIPPED - 2026-08-03] [Bug]`

Every fix reproduced against a failing case before the change was written.

**Silent failures** — each exited non-zero with zero bytes on stdout and stderr:
- `scripts/refresh-rollup.sh` died on every invocation after Batch 0.30 moved the rollup to `docs/RECENT-WORK.md` while the script still defaulted to `CLAUDE.md`. Target now resolved at run time (explicit arg > `docs/RECENT-WORK.md` > `CLAUDE.md`) so unmigrated consumer projects keep working.
- Same script died when any `docs/recent-work/` entry lacked a `# ` heading; its own `(untitled)` fallback was unreachable under `pipefail`.
- `scripts/validate-state-transitions.sh` `resolve_before()` ended in a bare `return` inheriting an `&&` list's status, so a missing `--before-file` killed the script under `errexit` before the "no before-state" message printed.
- `docs/benchmark/run-benchmark.sh:140` lost its "Task file not found" message to the same `pipefail`/glob interaction.

**Dead gates** — labelled hard blocks that could never fire:
- `/update-sop` Step 11 called `detect_trackers`, defined nowhere in the repo, so its `exit 1` was unreachable. Extracted to `scripts/detect-trackers.sh`; the two calling steps run in separate bash blocks, so a shared definition has to live in a file.
- `docs/benchmark/drift-fixtures/run-tests.sh` asserted exit codes only, so a validator returning correct exits while printing nothing — the P73 shape — passed all five fixtures. Ported the `.expect-stdout` assertion, added the `VALIDATOR` override, added a fixture asserting the BLOCK text. Proven: a stub with correct exit codes and no output now fails.

Also fixed the unterminated-final-line bug in all three assertion loops across both harnesses, and added filename-collision detection to `scripts/migrate-to-multi-agent.py` — two entries sharing a date and a title-derived slug resolved to one path and `write_text` overwrote the first silently while the run reported both as extracted. It now aborts before the first write, naming every colliding title.

Stale claims corrected: three uncaveated "33%" citations in files that ship to consumers (`results/r5-post-trim/summary.md:54` forbids citing it unconditionally); slash-command count stated as three and four when five ship; restored the missing `**S4 —**` heading in `sop-checker.md` without which the memory-poisoning check could never be reported by ID.

**Verification:** both fixture suites green (17 / 5), shell and Python syntax clean, DoD sweep confirms no remaining instances of either bug class. Commit `4473da2`.

---

### P85 — Compliance check-ID collisions and docs/recent-work ownership gap
`[SHIPPED - 2026-08-03] [Bug]`

`docs/sop/compliance-checklist.md` self-describes as the canonical list the sop-checker agent reports against, but carried 94 rows under 89 unique IDs — so `FAIL: M3` was ambiguous. Renamed the two sets with zero external citations and kept the two the README markets by name: Section 5 feature-map `M1-M4` → `FM1-FM4`, Section 7 resume `R1-R3` → `RP1-RP3`. Section 11 keeps `M1-M6` (12 citation sites); Section 9 keeps `R1`. Row count unchanged at 94, so README's advertised totals stay correct.

`RP1` also contradicted `F6` and `M4` outright — it required "File named exactly project_resume.md" while both others require `project_resume_<agent-id>.md`, so a multi-agent project passed F6/M4 and failed RP1 simultaneously. Reworded rather than deleted; deleting would have shifted the 85/94 totals and needed a Rule 1 trace.

`docs/recent-work/` appeared in neither the Section 2 ownership table nor the Section 7 update-trigger table — named only in a session-end step. It is the largest shipped-work prose surface in the repo with no assigned scope, which is the root cause of the narrative duplicated across recent-work, the Batch Log, feature-map rows and agent-memory Completed Work. Added with its 2-4 line spec and an explicit note that the rollup is derived, never hand-edited.

Commit `55b3cea`.

---

### P86 — `setup.sh --force` destroys per-project state with no backup
`[SHIPPED - 2026-08-03] [Bug] [has-open-questions]`

`setup.sh:17-27` documents two tiers — "per-project, customised" (`CLAUDE.md`, `Backlog.md`, `docs/agent-memory.md`) versus "pristine-replica SOP content" meant to be overwritten. `copy_if_missing` (`:116`) and `write_if_missing` (`:132`) apply one unconditional `cp` to both under `--force`, with no backup, no confirmation and no git-clean check. A user following the script's own "re-run with `--code`" tip loses a live `Backlog.md` — the SOP's declared single source of truth — to a blank template.

`scripts/migrate-to-multi-agent.py` already models the safer pattern: it refuses to run on a dirty tree.

**Open question:** refuse `--force` on the per-project tier outright, or keep it with timestamped backups? Refusing is safer but breaks anyone scripting it.

**Acceptance criteria:**
- Per-project files survive `--force`, or are recoverable from a timestamped backup
- Pristine-replica tier still force-syncs (verified by grep for a known SOP string)
- Dirty-tree re-run aborts with a named reason
- A seeded non-empty `exclude` array in `~/.claude/agent-sop.config.json` survives `--force`

**Source:** P83 audit §2.1 (verified by code reading; reproduced by a review agent).

---

### P87 — Step 1b trigger (b) has no execution arm
`[SHIPPED - 2026-08-03] [Bug]`

`claude-agent-sop.md:410` states the SOP's only unconditional gate: SOP self-modification fires the reviewer turn "regardless of LOC". Verified at HEAD: `grep -c 'self-modification' .claude/commands/update-sop.md` → 0, `grep -c 'review_triggers'` → 0, and the validator performs zero path inspection. `update-sop.md` implements trigger (a) only.

A 10-LOC edit to `docs/sop/claude-agent-sop.md` therefore skips the reviewer. Worse, the `docs-only` skip token clears every downstream check — the validator matches the token by regex and never inspects paths — so the strongest-sounding gate in the SOP is satisfiable by a self-declared four-word string that no code verifies.

**Decided 2026-08-03: enforce, and make it tag-independent.**

Original question was enforce vs downgrade. The evidence settled it: the sessions that most needed review on these paths shipped as `[Bug]`/`[Refactor]` and were exempt by tag, and the reviews that did run anyway found a HIGH (P84) and two CRITICALs (P92). Tag is a poor proxy for risk on the surface the agent itself executes, so the gate now fires on the pathspec regardless of tag or LOC, and `docs-only`/`below-threshold` skips are rejected on those paths — accepting either would reinstate the loophole trigger (b) exists to close.

~~Open question: enforce with a validator pathspec check, or downgrade `:410` to advisory prose?~~ Enforcing means every `[Feature]`/`[Refactor]` touching `docs/sop/**` in this repo *and in every consumer project* needs a real reviewer artefact, unconditionally. Downgrading is one line and honest but abandons the only unconditional gate.

**Note:** this decision gates roughly 25 of the audit's remaining items. It also determines whether P84/P85 are retroactively non-compliant — compliance check S7 is retrospective and commit-scoped.

**Source:** P83 audit §2.3.

---

### P88 — Definition of Done is gated on but never defined
`[SHIPPED - 2026-08-03] [Bug] [has-open-questions]`

`restart-sop.md` references it 4 times, `update-sop.md` 3 times (Step 1 self-evaluation gates on it). `grep -c 'Definition of Done'` returns 0 in both `docs/sop/claude-agent-sop.md` and this repo's `CLAUDE.md`. The CLAUDE.md structure spec (`claude-agent-sop.md:168-212`) never lists the section and Section 11's required-section rules never mention it. Only the two templates carry it. `/update-sop` Step 1 is therefore unsatisfiable in agent-sop's own repo.

**Open question:** add `## Definition of Done` to the CLAUDE.md spec, or remove the gating references? Evidence points against the obvious branch: `phase-0-foundation.md:105` records "Definition of Done removed (hurt bug fixes)", `results/r4-final-summary.md:30` measured ~0% effect, and `sop-hill-climbing.md:42` codifies "Remove to save tokens". The gap looks like a deliberate removal that was never de-gated, not an oversight.

**Source:** P83 audit §2.7.

---

### P89 — Rule 5 instruction budget is breached and unenforced
`[OPEN] [Iteration] [has-open-questions]`

**Recommendation (2026-08-03, from the P83 audit close-out):**
Split the rule; do not add a check against it as worded. Rule 5 scopes to "rules files under `~/.claude/rules/`", which agent-sop does not ship and cannot control — a check against that scope fails on every machine for reasons the project cannot fix. Split into (a) a hard, checkable cap on the instruction count of files agent-sop **ships**, and (b) a documented advisory for total assembled context. P94 shipped (b). Then add the check against (a) only.

Expect the enforceable half to fail on first measurement — `claude-agent-sop.md` alone counts 188 against a 150 soft cap — so this comes with a real trim, not just a check. Merge with **P77**, which is the same problem filed separately.

Rule 5 (`claude-agent-sop.md:69-76`) sets ≤150 distinct instructions soft, 200 hard, across the agent's combined context. Two independent counts using the rule's own method agreed within 6%: `claude-agent-sop.md` 188 (over the soft cap alone), `CLAUDE.md` 101, `restart-sop.md` 29, `update-sop.md` 72, `sop-checker.md` 90. Combined: session start 318, session end 361, subagent 379 — 1.6x to 1.9x over the hard ceiling. Including `~/.claude/rules/`, which Rule 5's own text names as in-budget, puts it near 3.5x.

The count also *under*-reports: the stated method excludes section headings, but `update-sop.md` carries 20 `## Step` headings that are functionally checklist items.

`grep -n 'instruction budget\|Rule 5\|150' docs/sop/compliance-checklist.md` returns nothing — the flagship rule is the only rule with no compliance check, and `docs/agent-memory/decisions/2026-04-19_solo_p43-rule-5-precise-instruction-count-deferred.md` records the measurement being deferred as too expensive. It has not been redone across the 30+ P-numbers shipped since.

**Open question:** add a compliance check, or restate the budget honestly? Adding a check means shipping one the reference implementation fails on day one. Carrying an aspirational rule that the reference implementation breaks by 1.9x is the option to rule out.

**Source:** P83 audit §3.1.

---

### P90 — Session-end step numbering incoherent across four files
`[OPEN] [Bug] [has-open-questions]`

**Recommendation (2026-08-03, from the P83 audit close-out):**
Stop citing bare step numbers across files; cite heading text instead. Picking one canonical sequence rebuilds the problem at the next inserted step, whereas heading citations are drift-proof.

**Ordering is not optional.** Seven compliance checks (`B11`, `D1`, `M1`, `M3`, `M6`, `S4`, `T1`) use step numbers as their grep anchor. Convert every one of those anchors to a heading string or content pattern and confirm all seven still PASS **before** renumbering anything. Renumbering first makes them fail *open*, so a graded project passes checks nobody ran — the most dangerous silent-failure mode in the remaining set.

The same operation carries four different numbers: `README.md` 0-10, `claude-agent-sop.md` 1-9, `CLAUDE.md` 0-9, `update-sop.md` 0-11. "Step 1" means *run tests* in the SOP and *self-evaluate* in the command; "Step 2" means *update Backlog* in one and *run tests* in the other; README is +1 against the other three from step 5 onward. `update-sop.md:100` directs a gotcha to "Step 4", which is feature-map — gotchas are Step 5. `finish.md:136` cites "Section 12" for the session-end checklist; Section 12 is Optional Patterns.

**Ordering hazard — read before starting.** Seven compliance checks (`B11`, `D1`, `M1`, `M3`, `M6`, `S4`, `T1`) use step numbers as their grep anchor. Renumbering without converting those anchors first makes them fail **open**, so a graded project passes checks nobody ran. Convert every anchor to a heading string or content pattern and confirm all seven still PASS *before* touching any numbering.

**Open question:** pick one canonical sequence, or stop citing bare step numbers cross-file and cite headings instead?

**Source:** P83 audit §3.2.

---

### P91 — Line-range hints rot; replace with stable anchors
`[SHIPPED - 2026-08-03] [Bug]`

The SOP did not permit line-range hints, it **mandated** them (`claude-agent-sop.md:580`, "any file over 200 lines"), and the worked example was wrong in the repo it was drawn from: hst-tracker's `:root` block runs lines 8-151 with 103 properties, not "lines 1-80" with "80+ tokens", in a 10,978-line file. Numeric ranges rot on every edit with nothing to detect it, and a stale range is worse than no hint — it sends the agent to the wrong slice and the agent draws a confident conclusion from the wrong text.

**Nine sites, not the six first identified.** Found by sweeping rather than trusting the list. The three extra: `claude-md-template-code.md:39` (a dispatch row shipping `(lines N-N)`); the `:311` token-overhead passage that motivated the rule; and `compliance-checklist.md:112` — **C24 scored projects on having the rot pattern**, requiring `(lines N-N)` notation. Inverted, with a pre-P91 exemption.

Two unbacked quantities in the `:311` rationale were verified before editing and are now caveated: a "1.7x" read-overhead multiplier with no derivation anywhere in the repo, and "reduce overhead significantly" with zero supporting measurement (`grep line-range docs/benchmark/` returns nothing). The directional point survives and is kept.

**Source:** handoff review 2026-08-03, independently verified. Related: P92-P94.

---

### P92 — Current Priority Items is a hand-maintained second source of truth
`[SHIPPED - 2026-08-03] [Refactor]`

CLAUDE.md declares `Backlog.md` the single source of truth for status, then kept a hand-written copy of the open items beside that declaration. Rule 2 violation shipped in both templates and the SOP spec. Drifted in every project that used it — worst observed 117 days, and agent-sop's own copy drifted within a single session.

Rejected the pointer-to-Backlog fix: it removes the drift by removing the benefit. Applied the pattern this repo already proves with the Recent Work rollup — sentinel markers plus a regenerating script, which is why the rollup does not go stale. `scripts/refresh-priorities.sh` derives `[OPEN]`/`[IN PROGRESS]`/`[BLOCKED]` from Backlog.md; `/update-sop` Step 3 calls it. Opt-in, so pre-P92 projects are untouched until they migrate.

---

### P93 — Templates reintroduce the CLAUDE.md rollup on every new project
`[SHIPPED - 2026-08-03] [Bug]`

Five projects have migrated the Recent Work rollup out of CLAUDE.md, but both templates still shipped the block inside it, so every new project reintroduced a section that grows by one line per session in the file read at every session start. `setup.sh` now creates `docs/RECENT-WORK.md` with the sentinels (per-project tier, protected by P86); templates carry a pointer. Safe because `refresh-rollup.sh` resolves its target at run time (P84).

C13 broke on a fresh install and was caught by testing, not review: it required a `## Recent Work (rollup)` header alongside the sentinels, which a dedicated file does not have. The header is now required only when the block lives inside CLAUDE.md.

---

### P94 — No user-scope guidance, while Rule 5 counts user-scope files
`[SHIPPED - 2026-08-03] [Feature]`

The SOP covered project `CLAUDE.md` thoroughly and said nothing about `~/.claude/CLAUDE.md` or `~/.claude/rules/` — while Rule 5 names rules files as in-budget. Measured on this machine: `~/.claude/rules/common/` ~247 directives, `~/.claude/rules/web/` ~157, which is most of what pushes the combined context past the 200 ceiling (P89).

Added a user-scope subsection to Section 1: what belongs at user versus project scope, and the `paths:` frontmatter load gate — a rules file without it loads into **every** session and subagent, and nothing in the project surfaces it because the files live outside the repo.

**Related:** P89. This is the advisory half of the Rule 5 split; the enforceable half is still open.

---

### P95 — Sentinel splice destroys the file when the end marker is malformed
`[SHIPPED - 2026-08-03] [Bug]`

Found by the P92 reviewer against the new script, then confirmed present in `scripts/refresh-rollup.sh` — **shipped since 2026-04-19 and run on every `/update-sop` Step 8b**.

The awk splice deletes every line between the sentinels by setting `skip=1` at the start marker and clearing it at the end marker. If the end marker is missing or mistyped (`:ends` for `:end`), `skip` is never cleared and the splice deletes the entire remainder of the file — silently, exit 0, with a "Rollup refreshed" success message. Reproduced in both scripts: seeded content after a typo'd marker, and it vanished.

Both scripts now verify the end sentinel before touching the file and refuse with a named error. Regression fixtures at `docs/benchmark/priorities-fixtures/run-tests.sh`, proven to discriminate against the pre-fix scripts via `PRIORITIES=` / `ROLLUP=` overrides.

**Also open (not fixed here):** Step 3c accepts a Batch Log line that *cites* a `docs/reviews/` path without checking that the path resolves. Batch 0.30 recorded this in prose ("a false citation the validator would have accepted") and it was never fixed, so any plausible filename clears the gate. One `test -f` in `scripts/validate-state-transitions.sh` plus a fixture. Filed here rather than silently carried.

**Source:** P92 reviewer, `docs/reviews/2026-08-03_solo_P92.md` (CRITICAL, CONFIRMED).

---

### P96 — Step 7 never resolved the resume directory, so writes and reads diverged
`[SHIPPED - 2026-08-07] [Bug]`

`/restart-sop` Step 0d and `scripts/validate-state-transitions.sh --check-drift` both derived the memory directory from `git rev-parse --show-toplevel`. `/update-sop` Step 7 — the only step that **writes** the file — named `~/.claude/projects/[project-hash]/memory/project_resume_${AGENT_ID}.md` and never resolved `[project-hash]` at all.

With no rule, an agent writes into the memory directory the *session* owns. The harness names those after the session's launch path, so a session started outside the project lands in a catch-all directory shared by every project touched the same way. Three failures follow:

1. **The drift gate silently no-ops.** The snapshot is written where Step 3d never looks, so `--check-drift` reports `no project_resume file found — skipping` and P46's enforcement is dead on exactly the projects that hit this.
2. **The write-side legacy fallback can overwrite another project's file.** Step 7 said: if the project uses an unsuffixed `project_resume.md` and `$AGENT_ID` is `solo`, write to that filename. In a shared directory that file belongs to whichever project got there first.
3. **`solo` is not unique across projects.** Every single-worktree project resolves to it, so only the directory separates two projects' snapshots.

**Observed twice.** `project_resume_solo.md` in the shared directory is Intelligent Studio's, already marked SUPERSEDED with a note that it "sat in the shared `-Users-matt-clayton` memory directory rather than Intelligent Studio's own". On 2026-08-07 an agent working on a different project reached Step 7, found `project_resume_solo.md` and `project_resume.md` in the same directory, recognised neither was its own, and refused the step rather than following it. The SOP instructed the destructive action; only agent judgement prevented it.

Two more instances of the same over-broad-lookup shape were found while fixing it, neither reachable from Step 7:
- `.claude/agents/sop-checker.md` located memory directories by matching a *substring* of the project's directory name against `~/.claude/projects/`, so an audit could score a project against another project's files.
- The SessionStart hook in `docs/sop/harness-configuration.md` read `~/.claude/projects/*/memory/project_resume.md` — every project on the machine — and loaded the result as this session's context.
- `/restart-sop` Step 2's sibling-agent scan used the same glob. Siblings live in separate worktrees, so it now enumerates `git worktree list` and resolves each root.

**Fix.** New `scripts/resolve-resume-path.sh` is the single source of truth for the derivation, unified rather than parity-tested per `docs/guides/cross-layer-rules.md` Tier A (the rule is a pure function of repo root, HOME and agent-id). Modes: `--read`, `--dir`, `--agent-id`, and a default write target. It refuses (exit 2) when the repo root is the home directory, because no project-scoped directory can be derived there. Writes always target the per-agent filename; the legacy unsuffixed file stays readable but is never written, and gets marked superseded once a per-agent file exists.

**Acceptance criteria:**
- `scripts/resolve-resume-path.sh` exists and is the only implementation of the derivation - DONE
- `/update-sop` Step 7, `/restart-sop` Step 0d + Step 2, and `--check-drift` all call it - DONE
- No SOP surface still carries an unresolved `[project-hash]` for the resume file - DONE
- Write-side legacy fallback removed; read-side fallback retained - DONE
- Fixture suite at `docs/benchmark/resume-path-fixtures/run-tests.sh`, proven to discriminate against the pre-fix behaviour via a `RESOLVER=` stub (12 of 13 cases fail against it) - DONE
- `scripts/resolve-resume-path.sh` added to the `/update-agent-sop` file table so existing consumer projects receive it - DONE
- Compliance checks F6, RP1, M4 and `sop-checker` require the resolved directory rather than a name match - DONE

**Also open (not fixed here):** agent-id resolution is implemented three times — `/update-sop` Step 0 (`update-sop.md:21`), `/restart-sop` Step 0 (`restart-sop.md:48`), and `scripts/resolve-resume-path.sh:99`. This diff removed a fourth from `scripts/validate-state-transitions.sh` by routing it through the resolver.

They agree only because the P96 reviewer caught them not agreeing. The resolver's first cut treated an empty or `0` worktree count as `solo`, where both inline copies fall through to the path hash — so a root whose worktree count could not be determined would have produced a different agent-id, a different filename, and a stranded resume file. Corrected to match the inline copies exactly, with a comment saying why, and covered by two new fixtures (`multi-worktree-agent-id-is-path-hash`, `sibling-worktree-gets-distinct-agent-id`) — the hash branch had no coverage anywhere in the repo before this.

That near-miss is the argument for unifying: three copies of one rule, one of which drifted within hours of being written. Tier A candidate — `--agent-id` already exists on the resolver and the other two could call it. Not done here because Step 0's value also feeds `docs/recent-work/` and `docs/reviews/` filenames, so the change is wider than this fix and deserves its own diff. Filed rather than silently carried.

**Source:** reported by an agent running agent-sop on a consumer project, 2026-08-07, when Step 7 directed it at a file belonging to another project.

---

### P97 — User-scope hooks run the SOP without a command typed; ship-sop auto-mode folded in
`[SHIPPED - 2026-09-04] [Feature]`

**Why.** The manual trigger was the failure point. Of six projects with the SOP installed, three ran it; agent-sop's own repo ended two sessions (2026-07-27, 2026-08-18) without `/update-sop`; repcanvas-marketing went 111 days and Meaningful never ran it once; intelligent-studio removed the whole layer on 2026-08-19. ship-sop's auto-mode had produced one gate report in four and a half months, its own dogfood on 2026-04-25, and no state file after 2026-07-27 even after its P14 wiring fix. Run by hand in a throwaway clone of a live consumer repo the hook fired correctly, so the silence had two causes outside the script: project-scope hooks in `<repo>/.claude/settings.json` load only from the directory Claude Code was launched in, and the maintainer launches from `~` and `cd`s into projects (three of this week's transcripts, each with thousands of consumer-repo references, sit in the home-directory project folder); and Claude Code discards `Stop` hook stdout — only `SessionStart`, `UserPromptSubmit`, `UserPromptExpansion` and `PostModelSwitch` stdout reaches the model — so the directive the hook printed was never seen even when it ran. See `docs/agent-memory/gotchas/2026-09-04_solo_project-scope-hooks-never-load-from-a-home-launched-session.md`.

**What shipped.**
- `scripts/hooks/sop-lib.sh` — shared rule set: SOP-repo detection from the hook's `cwd`, default-branch and merge-base resolution, last-session-record commit, drift commits, dirty trackers, ship-sop gate demand and coverage. One implementation feeds both the Stop hook and the push gate (cross-layer-rules Tier A).
- `scripts/hooks/sop-session-context.sh` — `SessionStart` + `UserPromptSubmit`. Prints resume snapshot (via `resolve-resume-path.sh`), in-flight lines, recent sessions, `[IN PROGRESS]` items, drift facts, dirty sibling worktrees, upstream-sync staleness, once per (session, repo); reprints on `compact`/`clear`. Replaces `/restart-sop` Steps 0-4.
- `scripts/hooks/sop-stop-drift.sh` — `Stop`. Exit 2 with the exact gap when commits exist after the newest `docs/recent-work/` entry, tracker files are uncommitted, or ship-sop auto-mode has no report covering HEAD. Throttled once per (HEAD, dirty set, gate state). Honours `stop_hook_active`.
- `scripts/hooks/sop-push-gate.sh` — `PreToolUse(Bash)`. Refuses `git push` / `gh pr create` only under ship-sop auto-mode with an uncovered code diff; `SOP_SKIP_GATE=1` bypasses once and is logged to `.ship/bypass.log`. Session-record drift is deliberately not push-gated: pushing early is the protection against sibling-worktree wipes.
- `scripts/install-hooks.sh` — copies the four to `~/.claude/scripts/hooks/agent-sop/` and registers them in `~/.claude/settings.json` via jq, idempotent, backup written first, `--uninstall` removes only its own entries. `setup.sh` calls it (`--no-hooks` opts out) and warns below Claude Code 2.1.251.
- `docs/benchmark/hook-fixtures/run-tests.sh` — 36 cases over real temp repos with a bare origin; 19 fail against exit-0 stubs, the other 17 are the silent-by-design cases.
- Docs: README "Automatic mode via hooks" section and ship-sop paragraph; `harness-configuration.md` reference implementations (a) and (b) replaced by the shipped scripts and a `UserPromptSubmit` row; core SOP §5 and §6 one sentence each; `/restart-sop` told to skip Steps 0-4 when the context block is present; `/update-agent-sop` file table carries the four scripts user-scope; agent-sop's own project-scope Stop hook removed from `.claude/settings.json`.

**Coverage is a fact, not a stamp.** The first cut required a report naming HEAD; committing the report moves HEAD, so a branch could never be covered once the report was in git. A report now covers HEAD when it names an ancestor with zero code lines between it and HEAD, using the same docs filter as the trigger. Caught by the fixture `stop-shipsop-gate-satisfied-by-covering-report`.

**Acceptance criteria:**
- Three hooks plus library exist under `scripts/hooks/`, shellcheck-clean, `set -u` only, fail open - DONE
- Each hook is silent (exit 0, no output) outside SOP repos and when no fact holds; fixture-proven - DONE
- Stop hook exits 2 with the gap on drift, once per commit state; fixture-proven - DONE
- Push gate refuses only under ship-sop auto with an uncovered code diff; bypass logged; fixture-proven - DONE
- Context hook prints once per (session, repo) and reprints after compact/clear; fixture-proven - DONE
- Installer idempotent, preserves existing hooks, backs up, uninstalls only its own entries; fixture-proven - DONE
- Suite discriminates: 19 of 36 cases fail against exit-0 stubs - DONE
- Step 1b review run in an isolated worktree; all findings fixed with a fixture each - DONE (HIGH: push gate missed `bash -c 'git push'`; MEDIUM: gate matched prose inside quotes; MEDIUM: installer replaced a symlinked settings.json; LOW: dirty-path listing broke on spaces; LOW: uninstall matched by filename rather than install path)
- Installed on the maintainer's machine - **NOT DONE**: the `install-hooks.sh` run against `~/.claude/settings.json` was denied by the permission classifier in this session. Run `bash scripts/install-hooks.sh` from the agent-sop checkout; it backs up `settings.json` first.

**Relation to P77 / P89 / P90.** The Stop hook enforces the minimum session-end (Backlog tag, session record, resume snapshot, commit) regardless of what the 22-step command says, which is the trim P77 asked for applied at the trigger rather than in the text. The command and SOP text trim remain open under P77/P89 with P90's anchor-conversion ordering; nothing was renumbered here.

**Not done, carried.** Consumer projects still carry ship-sop's project-scope Stop hook (hst-tracker, opportunity-scan, os-carry, ship-sop). It is inert when launched from `~` and a harmless duplicate otherwise (it writes `.ship/` files nobody reads). Remove each on that project's next session; the context hook flags any leftover directive. Filed in ship-sop's Backlog as P25.

**Reviewer incident (recorded, not hidden).** The first Step 1b reviewer run on this diff built its own ad-hoc test fixtures with the working tree as cwd and overwrote `Backlog.md`, `CLAUDE.md` and `docs/sop/claude-agent-sop.md` with stubs, plus three stray files. Caught within minutes by the very Stop-hook dry run it was reviewing (which listed the strays as uncommitted tracker files), the agent was stopped, the three files restored from git and the edits re-applied. The review was re-run in an isolated worktree. Gotcha filed: `docs/agent-memory/gotchas/2026-09-04_solo_reviewer-subagents-run-in-a-worktree-never-the-live-tree.md`.

**Source:** review of the 2026-08-10 and 2026-08-31 research digests plus a usage survey across `~/Projects`, 2026-09-04. Review: `docs/reviews/2026-09-04_solo_P97.md`.

---

### P98 — Research digest review 2026-08-10 + 2026-08-31: version floor, extract-then-execute pattern, branch convention; skip record
`[SHIPPED - 2026-09-04] [Iteration]`

Both digests unreviewed until now (the 2026-08-03 batch covered 2026-07-30). Every 31 August claim was verified against its primary source before acting: the Claude Code changelog (2.1.247-2.1.251 entries quoted verbatim; newest 2.1.260), the Anthropic multiagent post (2026-08-13), the LangChain OpenWiki post (2026-08-25), Willison on Rehberger's auto-mode break (2026-08-27), Willison on auto mode default (2026-08-08), and the 2.1.222 release. Filter applied per the 2026-04-13 decision: remove or sharpen before adding; an addition must change what happens, not what the agent reads.

**Shipped here:**
- README floor and badge to **v2.1.251**; `setup.sh` warns below it with the reason (2.1.222 worktree isolation; 2.1.251 symlink and deny-rule fixes). Outstanding across two digests. The maintainer runs 2.1.260.
- `security-reviewer.md` pattern table: archive extracted onto an import or executable path, CRITICAL, with the fix. No injected instruction is involved, so a prompt-injection classifier does not see it.
- `multi-agent-parallel-sessions.md` §7: `<agent-id>/<slug>` branch prefix and a pre-create `git branch --list`; the conflicting-directive response recorded as Rule 6 applied to a peer, in the guide rather than as a seventh rule.

**Folded into P97:** 31 Aug finding 1 (SessionStart staleness — the context hook reads `source` and reprints on compact/clear); finding 5 (thin command plus reference skill — the hooks carry the mechanics, the trim of the command text stays P77/P89).

**Skipped, with reasons:**
- 31 Aug 2 (evidence-linked decisions) — highest-value idea in either digest, deferred: needs a template field, a stale-lister and a grandfathering rule; worth its own item once the hooks have run for a few weeks, minimal form only (no compliance check, no backfill).
- 31 Aug 6 remainder ("auto mode is not containment" note; `--restricted` for sop-checker) — reading material; sop-checker is run manually and rarely.
- 31 Aug 7 (S4 filename validation) — same reason.
- 31 Aug 8 (benchmark re-run trigger, instruction retirement §15.5) — adds an obligation to a framework P81 records as unable to run; fold into the P81 decision.
- 10 Aug 1 (assumed-permission-mode subsection + S-series check) — positioning text; the Rehberger pattern above is the concrete descendant.
- 10 Aug 2 (floor 2.1.222) — superseded by 2.1.251.
- 10 Aug 3 (SendMessage is not a source of truth) — one-line restatement of Rule 2; not added.
- 10 Aug 4 (`Review level:` field) — bookkeeping until a gate reads it; revisit with P80.
- 10 Aug 5 (`prompt-audit` one-off) — worth one run to seed the P77 trim list; not run this session.
- 10 Aug 6 (ReviewBench ninth task) — benchmark framework cannot run (P81).

**On the digest pipeline itself.** Sixteen digests in five months at 4-21 day gaps against a daily spec; most runs could not index the repo; every review since April has recorded the same "adds rather than sharpens" bias. Its durable yield has been changelog tracking. Not changed here; noted for the next review of the research cron.

**Source:** `~/Documents/Claude/Projects/agent-sop-research/agent-sop-research-digest-2026-08-10.md` and `-2026-08-31.md`.

---

## Shipped Archive

*Items below are shipped or verified. Never removed.*

- P66 — Validator/Step 1b skip-list unification (Tier A) — SHIPPED 2026-07-26
- P70 — Test-gate escape hatch bounded + T1 check — SHIPPED 2026-07-26
- P71 — `[DEFERRED]` reopen triggers + B12 check — SHIPPED 2026-07-26
- P72 — Benchmark runner: lite subset, -k repetition, aggregate — SHIPPED 2026-07-26
- P73 — Validator silent-exit fix + stdout-asserting fixtures — SHIPPED 2026-07-26
- P74 — Replace `npx block-no-verify` with local argv-matching hook — SHIPPED 2026-07-27 (filed retroactively 2026-08-03)
- P75 — Replication gate: `--check-replication` + `/update-sop` Step 3e — SHIPPED 2026-08-03

- P67 — Step 1b wait-for-reviewer before substance assertion — SHIPPED 2026-07-26
- P68 — Benchmark repetition, frozen lite subset, capability suite — SHIPPED 2026-07-26
- P69 — Gate integrity rule 11 + S7 check — SHIPPED 2026-07-26
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
- P53 — `/finish` skill: end-to-end verify, simplify, ship — SHIPPED 2026-04-29 (originally shipped as `/go`, renamed same day)
- P54 — Multi-agent hardening + perf gates + worktree advisory — SHIPPED 2026-05-02
- P56 — Backend assumptions: gateway / non-Anthropic backend warning — SHIPPED 2026-05-04
- P24 — Multi-agent optimisation guide — SHIPPED 2026-05-04
- P55 — Sycophantic reviewer detection: tighten substance assertion — SHIPPED 2026-05-04
- P57 — Config `exclude` field for `/update-agent-sop` — SHIPPED 2026-05-04
- P58 — Karpathy before/after pattern (extend across SOP) — SHIPPED 2026-05-04
- P59 — Step 1b reviewer-gate tightening + cross-layer rules guide — SHIPPED 2026-05-28
