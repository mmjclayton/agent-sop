<!-- SOP-Version: 2026-04-19 -->
# SOP Compliance Checklist

Last updated: 2026-04-19

The canonical list of checks used by the SOP Compliance Checker agent. Each check has a severity tier that determines its scoring weight.

---

## Scoring

| Tier | Points each | Cap rule |
|------|-------------|----------|
| Critical | 10 | Any critical failure caps total score at 49/100 |
| Important | 5 | Deducted from remaining pool |
| Recommended | 2 | Advisory — deducted but does not block compliance |

- Start at 100. Deduct points for each failed check.
- If any Critical check fails, the score is capped at 49 regardless of other results.
- Score normalised to 100 based on applicable checks (code vs non-code projects have different totals).
- Floor at 0.

**Compliance tiers:**
- 90-100: Fully compliant
- 70-89: Largely compliant, minor gaps
- 50-69: Partially compliant, structural work needed
- 0-49: Non-compliant (or has critical failures)

---

## Code vs Non-Code Detection

Check in order. If any match, treat as a code project:

1. `CLAUDE.md` contains `## Auth`, `## Database`, or `## Design System`
2. `CLAUDE.md` references `claude-md-template-code.md`
3. `## Key Commands` section contains test commands (e.g. `test`, `jest`, `pytest`, `cargo test`)
4. Project root contains `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, or `Gemfile`

If none match: non-code project. Code-only checks are marked below and scored as N/A for non-code projects.

---

## 1. File Existence

### Critical

| ID | Check | What to look for |
|----|-------|-----------------|
| F1 | CLAUDE.md exists | File at project root |
| F2 | Backlog.md exists | File at project root |
| F3 | docs/agent-memory.md exists | Exact path. **Downgraded to Important for projects with fewer than 10 sessions** — check git log commit count as proxy. |
| F4 | docs/feature-map.md exists | Exact path |
| F5 | At least one build plan exists | Any file matching `docs/build-plans/phase-*.md` |

### Important

| ID | Check | What to look for |
|----|-------|-----------------|
| F6 | Per-agent resume file exists (local) | `~/.claude/projects/[hash]/memory/project_resume_<agent-id>.md` — at least one file matching this pattern. Legacy unsuffixed `project_resume.md` also accepted for single-agent projects. |
| F7 | MEMORY.md index exists (local) | `~/.claude/projects/[hash]/memory/MEMORY.md` — same discovery method |
| F8 | docs/recent-work/ directory exists | Directory at `docs/recent-work/` with `README.md`. Created by Phase 1 Batch 1.2 / pre-existing in SOP-setup projects from 2026-04-19 onwards. Legacy projects pre-migration acceptable. |
| F9 | docs/agent-memory/decisions/ directory exists | If `docs/agent-memory.md` exists, the `decisions/` subdirectory under `docs/agent-memory/` must exist with `README.md`. Legacy projects pre-migration acceptable. |
| F10 | docs/agent-memory/gotchas/ directory exists | Same as F9 for `gotchas/` subdirectory. Legacy projects pre-migration acceptable. |

---

## 2. CLAUDE.md Structure

### Critical

| ID | Check | What to look for |
|----|-------|-----------------|
| C1 | Agent SOP section exists | `## Agent SOP` header referencing the SOP document |
| C2 | Session & Memory Hygiene section exists | `## Session` header (match flexibly) |
| C3 | Session start checklist has 5 steps | Numbered list under session start heading (5 steps per canonical SOP) |
| C4 | Session end checklist has 9 steps | Numbered list under session end heading, step 1 is test gate for code projects. Steps 2a (P-number collision) and 3b (secondary tracker reconciliation) are documented as sub-steps, not separate top-level numbers. Projects still using 7-step (pre-P42) or 8-step (pre-P43) format should be WARN (not FAIL) with a note to update. |
| C5 | Dispatch reference exists with 5+ files | `## Dispatch` or `## Key Documents & Dispatch` header, table with at least 5 file path entries |

### Important

| ID | Check | What to look for |
|----|-------|-----------------|
| C6 | Build Plans section exists | `## Build Plans` header with link(s) to phase files |
| C7 | Key Documents table exists | `## Key Documents` or `## Key Documents & Dispatch` header with a markdown table |
| C8 | Current Priority Items section exists | `## Current Priority` header with P-numbered items |
| C9 | Backlog Management section exists | `## Backlog Management` header with tag taxonomy |
| C10 | Stack section exists and populated | `## Stack` header with content (not just placeholders) |
| C11 | Key Commands section exists and populated | `## Key Commands` header with at least one command |
| C12 | Rules for Automated Builds section exists | `## Rules for Automated Builds` header with numbered list |
| C13 | Recent Work (rollup) section exists with sentinel markers | `## Recent Work (rollup)` header AND `<!-- recent-work-rollup:start -->` / `<!-- recent-work-rollup:end -->` comment sentinels present. Legacy `## Recent Work` acceptable during migration window before `/update-sop --migrate-to-multi-agent` has run. |
| C14 | Deprioritised section exists | `## Deprioritised` header |
| C15 | Non-negotiable rules referenced | Text references "never delete without a trace" or equivalent, and "single source of truth" or "one source of truth" |
| C16 | Conflict precedence defined or referenced | Text mentions precedence order or references the SOP conflict resolution |
| C17 | Per-session sections under line limit | Non-code: 200 lines. Code projects with Common Mistakes: 300 lines. Count from `## Agent SOP` through end of `## Dispatch Quick Reference`, excluding Auth/Database/Design System sections |

### Important (code projects only)

| ID | Check | What to look for |
|----|-------|-----------------|
| C18 | Auth section exists | `## Auth` header with content |
| C19 | Database section exists | `## Database` header with content |
| C20 | Design System section exists | `## Design System` header with content |
| C21 | Session end step 1 is test gate | First step of session end checklist mentions running tests |
| C22 | Build rules include schema protocol | Rules for Automated Builds mentions schema change sequence or migration protocol |

### Recommended

| ID | Check | What to look for |
|----|-------|-----------------|
| C23 | Recent Work entries include PR/commit refs | Entries contain `PR`, `#`, or commit hash patterns |
| C24 | Key Documents table has line-range hints | Table entries for large files include `(lines N-N)` notation |

---

## 3. Backlog.md Structure

### Critical

| ID | Check | What to look for |
|----|-------|-----------------|
| B1 | Tag taxonomy header present | Section defining valid status and type tags |
| B2 | At least one P-numbered item exists | Pattern: `### P[number]` |

### Important

| ID | Check | What to look for |
|----|-------|-----------------|
| B3 | Tag order correct: status first, type second | All items follow pattern: `[STATUS] [TYPE]` on the tag line |
| B4 | Status tags use valid values | Only: `[OPEN]`, `[IN PROGRESS]`, `[BLOCKED]`, `[DEFERRED]`, `[SHIPPED - YYYY-MM-DD]`, `[VERIFIED - YYYY-MM-DD]`, `[WON'T]` |
| B5 | Type tags use valid values | Only: `[Feature]`, `[Iteration]`, `[Bug]`, `[Refactor]` |
| B6 | [WON'T] items include reason | Format: `[WON'T] [Type] — Reason: [text]` |
| B7 | [SHIPPED] and [VERIFIED] items include date | Pattern: `YYYY-MM-DD` present in the tag |
| B8 | Date formats are YYYY-MM-DD | All dates in the file match this format |
| B9 | P-numbers are sequential | No unexpected gaps (gaps where intermediate P-numbers exist as [WON'T] referencing a superseding item are acceptable) |

### Recommended

| ID | Check | What to look for |
|----|-------|-----------------|
| B10 | Shipped Archive section exists when needed | If file exceeds ~2,000 lines, a `## Shipped Archive` section should exist |
| B11 | State-transition validator present | `scripts/validate-state-transitions.sh` exists and `/update-sop` references it as Step 3c. Retrospective: run the validator across `git log --follow Backlog.md` range; flag any illegal transitions (e.g. `[OPEN]` → `[SHIPPED]` with no `[IN PROGRESS]` intermediate) that predate the validator or bypassed it. Live sessions are already protected by Step 3c; this check catches historical drift. |

---

## 4. docs/agent-memory.md Structure

### Critical

| ID | Check | What to look for |
|----|-------|-----------------|
| A1 | All 6 required narrative sections present | Headers for: Key Documents, Key Source Files, In-Flight Work, Preferences (may use project name), Completed Work, Archived. Decisions and Gotchas live in `docs/agent-memory/decisions/` and `docs/agent-memory/gotchas/` directories — their narrative sections may either pointer-link to those directories or be absent entirely. |

### Important

| ID | Check | What to look for |
|----|-------|-----------------|
| A2 | Key Documents references CLAUDE.md (not duplicated) | Section says "See CLAUDE.md" or equivalent, does not contain its own full Key Documents table |
| A3 | Decisions dated in YYYY-MM-DD format | Entries start with or contain `YYYY-MM-DD:` pattern |
| A4 | Superseded entries properly marked | Any superseded items use `[SUPERSEDED - YYYY-MM-DD: reason]` format |
| A5 | No derived facts stored | Scan for test counts, specific line numbers, version numbers, file sizes as stored facts (not as references in decisions about changes) |

### Recommended

| ID | Check | What to look for |
|----|-------|-----------------|
| A6 | In-Flight Work matches Backlog | Items listed in In-Flight should have corresponding `[IN PROGRESS]` entries in Backlog.md. Empty In-Flight is fine. |

---

## 5. docs/feature-map.md Structure

### Important

| ID | Check | What to look for |
|----|-------|-----------------|
| M1 | Last updated header present | `Last updated: YYYY-MM-DD` near top of file |
| M2 | Shipped features section exists | Header for shipped/completed features with a table |
| M3 | Roadmap section exists with priority tiers | At least one priority tier (High/Medium/Low) |

### Recommended

| ID | Check | What to look for |
|----|-------|-----------------|
| M4 | Backlog shipped items reflected here | All `[SHIPPED]` P-numbers in Backlog.md appear in the shipped features table |

---

## 6. docs/build-plans/phase-*.md Structure

### Important

| ID | Check | What to look for |
|----|-------|-----------------|
| P1 | Status line present | `Status:` line with Planning, In Progress, or Shipped YYYY-MM-DD |
| P2 | All 7 required sections present | Problem, Scope, Architecture, Key Decisions Locked In, Batch Log, Deploy Checklist, Open Questions |
| P3 | Batch Log entries dated | Entries contain `YYYY-MM-DD:` pattern |
| P4 | Locked decisions marked | Items in Key Decisions use `[LOCKED]` marker |

### Recommended

| ID | Check | What to look for |
|----|-------|-----------------|
| P5 | Batch Log entries reference PRs/commits | Entries contain `PR`, `#`, or commit hash patterns |

---

## 7. project_resume.md Structure

### Important

| ID | Check | What to look for |
|----|-------|-----------------|
| R1 | File named exactly project_resume.md | No project-specific prefix (e.g. not `project_myapp_resume.md`) |
| R2 | Contains required sections | What was done, What is next, Blockers (or equivalent headings) |
| R3 | Uses snapshot format | Single session block, not a growing log with multiple dated entries. Should have `Last updated:` near the top. |

---

## 8. Cross-File Consistency

### Important

| ID | Check | What to look for |
|----|-------|-----------------|
| X1 | Shipped items in both Backlog and feature-map | Extract P-numbers with `[SHIPPED]` from Backlog.md, verify they appear in feature-map.md shipped table |
| X2 | In-Flight Work consistent with Backlog | Items in agent-memory.md In-Flight section should have matching `[IN PROGRESS]` entries in Backlog.md |
| X3 | Key Documents tables consistent | agent-memory.md references CLAUDE.md table rather than maintaining its own |

### Recommended

| ID | Check | What to look for |
|----|-------|-----------------|
| X4 | Recent Work has PR/commit refs | CLAUDE.md Recent Work entries contain references to PRs or commits |
| X5 | Build plan Batch Log references PRs | Batch Log entries contain PR numbers or commit hashes |
| X6 | Secondary trackers reconciled with commit history | For every `.md` file in CLAUDE.md Key Documents that uses heading-level `[OPEN]`/`[SHIPPED]` tags (excluding `Backlog.md`): extract finding IDs from the last 20 commit messages (pattern `\b[A-Z]+-?[0-9]+\b`), then verify any matching entries in the tracker are not still `[OPEN]`. A still-`[OPEN]` entry whose ID was referenced in a shipped commit indicates drift from a skipped `/update-sop` Step 3b. |

---

## 9. Security, Hooks, Code Quality, and Agents

### Critical

| ID | Check | What to look for |
|----|-------|-----------------|
| S1 | No secrets in committed files | Scan for `.env` files, hardcoded API keys (`sk-...`), private keys, `password=` patterns in tracked files. Exclude `.env.example` and test fixtures. |

### Important

| ID | Check | What to look for |
|----|-------|-----------------|
| S2 | Security guidance referenced | `docs/sop/security.md` exists OR CLAUDE.md references security guidance |
| S3 | No `--dangerously-skip-permissions` usage | Scan `.claude/settings.json`, CLAUDE.md, and any shell scripts for the flag. Agents should use explicit permission rules (`allowedTools`) instead. Hardened in Claude Code v2.1.97. |
| Q1 | File size limits specified (code) | CLAUDE.md or a Code Quality section mentions maximum file line count (e.g. 800 lines) |
| Q2 | Test coverage threshold specified (code) | CLAUDE.md or a Code Quality section mentions minimum test coverage (e.g. 80%) |

### Recommended

| ID | Check | What to look for |
|----|-------|-----------------|
| H1 | Session hooks documented or configured | At least SessionStart and SessionEnd hooks mentioned in CLAUDE.md, `docs/sop/harness-configuration.md`, or `.claude/settings.json` |
| G1 | At least 2 review agents available | `.claude/agents/` contains at least 2 agent definitions (e.g. code-reviewer + security-reviewer or sop-checker + any other) |
| R1 | Reviewer-turn gate honoured for shipped [Feature]/[Refactor] items | For every `[SHIPPED]` `[Feature]` or `[Refactor]` item in the last 30 days whose session diff exceeded `review_loc_threshold` or `review_files_threshold` (from `agent-sop.config.json`, defaults 50 LOC / 3 files): verify a matching review artifact exists at `docs/reviews/YYYY-MM-DD_<agent-id>_P<n>.md` AND passes `bash scripts/validate-state-transitions.sh --assert-review <path>`. Best-effort retrospective — measure the session diff with `git diff --numstat <merge-base>..<ship-commit>` (sum columns 1+2 for LOC; line count for files). `git show --stat` is per-commit and undercounts multi-commit sessions — do not use. Projects predating P44 (before 2026-04-19) are exempt. |
| D1 | Drift-detection infrastructure present | `scripts/validate-state-transitions.sh --check-drift` works when invoked; `.claude/commands/update-sop.md` references Step 3d; `.claude/commands/restart-sop.md` includes the in-flight reassertion in Step 0d. Tooling presence is the check — retrospective audit of every past session for drift is out of scope (too expensive; `## Scope Change` blocks in `docs/recent-work/` would already surface legitimate cases). Projects predating P46 (before 2026-04-19) are exempt. |

---

## 10. Benchmark-Proven Practices

*These checks verify the patterns from SOP Section 15 that produced a 33% quality improvement in A/B benchmarks.*

### Important (code projects only)

| ID | Check | What to look for |
|----|-------|-----------------|
| BP1 | Common Mistakes section exists | `## Common Mistakes` header in CLAUDE.md with at least 3 gotcha entries (code projects). Each entry names a specific file, model, component, or token. |
| BP2 | Intent-rich dispatch table | Key Documents & Dispatch table uses "When you need to..." pattern or includes Notes column with contextual guidance (not just file paths) |

### Recommended

| ID | Check | What to look for |
|----|-------|-----------------|
| BP3 | Common Mistakes has subsections | Common Mistakes section has at least 2 subsections (e.g. Data Model, Client, Server, Testing) for code projects |
| BP4 | Dispatch notes reference related components | Dispatch table Notes column mentions related files, gotchas, or constraints (e.g. "ExerciseCard is separate file", "Never hardcode hex") |

---

## 11. Multi-Agent Parallel Sessions

*These checks apply only when the project is in parallel-agent mode (`multi_agent: auto` and worktree count > 1, OR `multi_agent: on`). Non-applicable when `multi_agent: off` or the project has never added per-agent directories.*

### Critical

| ID | Check | What to look for |
|----|-------|-----------------|
| M1 | Agent-id resolvable | `resolve_agent_id` snippet present in both `.claude/commands/update-sop.md` Step 0 and `.claude/commands/restart-sop.md` Step 0b. Function runs without error (precedence: `CLAUDE_AGENT_ID` env > `.sop-agent-id` file > `solo` > worktree-path hash). Inside a valid git repo, `$AGENT_ID` always resolves to a non-empty string. |

### Important

| ID | Check | What to look for |
|----|-------|-----------------|
| M2 | Per-entry directory structure exists | `docs/recent-work/`, `docs/agent-memory/decisions/`, `docs/agent-memory/gotchas/` all exist with `README.md`. Legacy projects pre-migration: accept the legacy `## Recent Work` / `## Decisions Made` / `## Gotchas and Lessons` narrative sections provided a cutover note references the migration (Batch 1.6). |
| M3 | Commit-range uses merge-base | `resolve_session_commit_range` snippet present in `.claude/commands/update-sop.md` Step 0a and `.claude/commands/restart-sop.md` Step 0c. Snippet uses `git merge-base <default-branch> HEAD` (not last-N commits, not git author filtering). Grep-verifiable by pattern `git merge-base`. |
| M4 | Per-agent resume file exists | `~/.claude/projects/[hash]/memory/` contains at least one `project_resume_<agent-id>.md`. Legacy `project_resume.md` accepted as fallback when `$AGENT_ID` is `solo`. |

### Recommended

| ID | Check | What to look for |
|----|-------|-----------------|
| M5 | CLAUDE.md rollup refreshed within 7 days | `CLAUDE.md` contains `<!-- recent-work-rollup:start -->` / `<!-- recent-work-rollup:end -->` sentinels. The `Last refreshed: YYYY-MM-DD` line inside is within the last 7 days (advisory; rollup is auto-refreshed by `/update-sop`, so staleness indicates `/update-sop` was skipped). |

---

## Check Summary

| Category | Critical | Important | Recommended | Total |
|----------|----------|-----------|-------------|-------|
| File Existence | 5 | 5 | 0 | 10 |
| CLAUDE.md Structure | 5 | 12 (+5 code) | 2 | 19 (+5) |
| Backlog.md Structure | 2 | 7 | 2 | 11 |
| agent-memory.md Structure | 1 | 4 | 1 | 6 |
| feature-map.md Structure | 0 | 3 | 1 | 4 |
| Build Plans Structure | 0 | 4 | 1 | 5 |
| project_resume.md Structure | 0 | 3 | 0 | 3 |
| Cross-File Consistency | 0 | 3 | 3 | 6 |
| Security, Hooks, Quality, Agents | 1 | 2 (+2 code) | 4 | 7 (+2) |
| Benchmark-Proven Practices | 0 | 0 (+2 code) | 2 | 2 (+2) |
| Multi-Agent Parallel Sessions | 1 | 3 | 1 | 5 |
| **Total (non-code)** | **15** | **46** | **17** | **78** |
| **Total (code)** | **15** | **55** | **17** | **87** |

**Maximum deductions:**
- Non-code: 15 x 10 + 46 x 5 + 17 x 2 = 150 + 230 + 34 = 414
- Code: 15 x 10 + 55 x 5 + 17 x 2 = 150 + 275 + 34 = 459

**Normalisation:** Score = max(0, 100 - (total deductions / max possible deductions * 100)). Then apply critical cap (49 max) if any critical check fails.
