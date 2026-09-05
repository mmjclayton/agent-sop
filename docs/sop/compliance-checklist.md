<!-- SOP-Version: 2026-07-06 -->
# SOP Compliance Checklist

Last updated: 2026-04-19

The canonical list of checks used by the SOP Compliance Checker agent. Each check has a severity tier that determines its scoring weight.

---

## Scoring

| Severity | Weight | Effect |
|---|---|---|
| Critical | 10 | Any critical failure caps total score at 49/100 |
| Important | 5 | Deducted from remaining pool |
| Recommended | 2 | Advisory — deducted but does not block compliance |

- Start at 100. Deduct points for each failed check.
- If any Critical check fails, the score is capped at 49 regardless of other results.
- Score normalised to 100 based on applicable checks (code vs non-code projects have different totals).
- Floor at 0.

**Compliance tiers:** 90-100 fully compliant; 70-89 largely compliant; 50-69 partially compliant; 0-49 non-compliant or a critical failure.

**What changed on 2026-09-05 (P105).** Checks for artefacts a measured review found write-only were removed: `docs/feature-map.md` (F4, FM1-FM4, X1), the Batch Log requirement (P3, P5, X5, the Batch Log half of R1), the Definition of Done, the `## Deprioritised` section (C14), the CLAUDE.md copies of the session checklists (C3, C4, C21), generic code-quality thresholds that load from the user's rules (Q1, Q2), and the six-section `docs/agent-memory.md` narrative (A1 now checks the In-Flight block only). IDs are never reused.

---

## Code vs Non-Code Detection

One rule, shared with the user-scope hooks, `/update-sop` Step 2, `/finish` and ship-sop's `/ship`: the executable form is `sop_project_type` in `scripts/hooks/sop-lib.sh`, run as `scripts/hooks/sop-project-type.sh` (installed at `~/.claude/scripts/hooks/agent-sop/`). When this prose and the script disagree, the script is the rule (cross-layer-rules Tier A). Since 2026-09-04 (P102) the ship-sop automatic gate fires only on code projects, so the answer here decides whether reviewer agents run at all.

0. `CLAUDE.md` carries a `**Project type:** code` or `**Project type:** non-code` line — that answer wins outright. The templates carry it; a scripts-and-markdown repo with a real test suite declares `code` because no heuristic below would find it.

Otherwise check in order, case-insensitively. If any match, treat as a code project:

1. `CLAUDE.md` contains `## Auth`, `## Database`, or `## Design System`
2. `CLAUDE.md` references `claude-md-template-code.md`
3. `## Key Commands` section runs a test suite (`npm`/`pnpm`/`yarn`/`bun test`, `pytest`, `jest`, `vitest`, `cargo test`, `go test`, `make test`); the word "test" in prose does not count
4. Project root contains `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, or `Gemfile`

If none match: non-code project. Code-only checks are marked below and scored as N/A for non-code projects.

---

## 1. File Existence

### Critical

| ID | Check | What to look for |
|----|-------|-----------------|
| F1 | CLAUDE.md exists | File at project root |
| F2 | Backlog.md exists | File at project root |
| F5 | At least one build plan exists | Any file matching `docs/build-plans/phase-*.md` (planning notes; no Batch Log is required since P105) |

### Important

| ID | Check | What to look for |
|----|-------|-----------------|
| F3 | docs/agent-memory.md exists | Exact path. Carries Key Documents (a pointer), Key Source Files, Preferences and the script-generated In-Flight block. |
| F6 | Per-agent resume file exists (local) | At least one `project_resume_<agent-id>.md` in the directory `bash scripts/resolve-resume-path.sh --dir` returns; a legacy unsuffixed file whose first non-blank line carries `**SUPERSEDED` does not count. |
| F8 | docs/recent-work/ directory exists | Directory with `README.md`. |
| F9 | docs/agent-memory/decisions/ directory exists | With `README.md`. |
| F10 | docs/agent-memory/gotchas/ directory exists | With `README.md`. |
| F11 | docs/backlog-archive.md exists when Backlog.md holds closed items older than 90 days | `scripts/archive-backlog.sh --dry-run` reports nothing to move. |

---

## 2. CLAUDE.md Structure

### Critical

| ID | Check | What to look for |
|----|-------|-----------------|
| C1 | Agent SOP section exists | `## Agent SOP` header pointing at `docs/sop/claude-agent-sop.md`, naming `/restart-sop` and `/update-sop` |
| C5 | Dispatch reference exists with 5+ files | `## Key Documents & Dispatch` header, intent-based table (`When you need to...`) with at least 5 file path entries |
| C25 | Project type declared | `**Project type:** code` or `non-code` line near the top (P102) |

### Important

| ID | Check | What to look for |
|----|-------|-----------------|
| C8 | Current priority items are derived | `<!-- priority-items:start -->` / `<!-- priority-items:end -->` sentinels present; content between them not hand-edited (P92) |
| C9 | Backlog Management section exists | `## Backlog Management` header with the tag taxonomy |
| C10 | Stack section exists and populated | `## Stack` header with content (not just placeholders) |
| C11 | Key Commands section exists and populated | `## Key Commands` header with at least one command |
| C12 | Rules for Automated Builds section exists | `## Rules for Automated Builds` header with numbered list |
| C13 | Recent Work rollup exists with sentinel markers | `<!-- recent-work-rollup:start -->` / `<!-- recent-work-rollup:end -->` in `docs/RECENT-WORK.md` (preferred) or `CLAUDE.md` |
| C15 | Non-negotiable rules referenced | Text references "never delete without a trace" or equivalent, and "single source of truth" or "one source of truth" |
| C16 | Conflict precedence defined or referenced | Text mentions precedence order or references the SOP conflict resolution |
| C17 | Per-session sections under line limit | Non-code: 200 lines. Code projects with Common Mistakes: 300 lines. Count everything except Auth/Database/Design System |

### Important (code projects only)

| ID | Check | What to look for |
|----|-------|-----------------|
| C18 | Auth section exists | `## Auth` header with content |
| C19 | Database section exists | `## Database` header with content |
| C20 | Design System section exists | `## Design System` header with content |
| C22 | Build rules include schema protocol | Rules for Automated Builds mentions schema change sequence or migration protocol |

### Recommended

| ID | Check | What to look for |
|----|-------|-----------------|
| C23 | Recent Work entries include PR/commit refs | Entries contain `PR`, `#`, or commit hash patterns |
| C24 | Key Documents table anchors large files | Entries for files over 200 lines name a stable anchor (a symbol, a block, a grep target). A `(lines N-N)` range FAILS (P91). |

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
| B9 | P-numbers are sequential | No unexpected gaps (gaps where intermediate P-numbers exist as [WON'T] referencing a superseding item, or in `docs/backlog-archive.md`, are acceptable) |
| B13 | Shipped Feature/Refactor entries cite a review or a skip | Every `[SHIPPED]` `[Feature]` or `[Refactor]` entry carries `review: docs/reviews/<file>.md` (the file exists) or `review skipped (P<n>): <docs-only|test-only|dep-bump|below-threshold>` naming its own P-number (P44, P66, P95, P105) |

### Recommended

| ID | Check | What to look for |
|----|-------|-----------------|
| B10 | Closed items archived | Nothing closed more than 90 days ago remains in `Backlog.md`; `scripts/archive-backlog.sh --dry-run` reports nothing to move; `## Archived items` pointers present when the archive exists |
| B11 | State-transition validator present | `scripts/validate-state-transitions.sh` exists and `/update-sop` runs it in Step 4 |
| B12 | Every `[DEFERRED]` item states a reopen trigger | A `**Reopens when:**` line names the observable condition; "no trigger identified" is legal and marks a `[WON'T]` candidate (P71) |

---

## 4. docs/agent-memory.md Structure

### Important

| ID | Check | What to look for |
|----|-------|-----------------|
| A1 | In-Flight block is script-generated | `<!-- in-flight:start -->` / `<!-- in-flight:end -->` sentinels present, content matches `docs/agent-memory/in-flight/*.md` (refreshed by `scripts/refresh-in-flight.sh`) |
| A2 | Key Documents references CLAUDE.md (not duplicated) | Section says "See CLAUDE.md" or equivalent, does not contain its own full Key Documents table |
| A4 | Superseded entries properly marked | Superseded decisions and gotchas carry a trailing `*Superseded by:*` line and live in `archive/` |
| A5 | No derived facts stored | Scan for test counts, specific line numbers, version numbers, file sizes as stored facts |

### Recommended

| ID | Check | What to look for |
|----|-------|-----------------|
| A6 | In-Flight matches Backlog | Items listed in In-Flight have corresponding `[IN PROGRESS]` entries in Backlog.md. Empty In-Flight is fine. |
| A7 | Entry files follow the naming convention | `docs/agent-memory/decisions/` and `gotchas/` files are `YYYY-MM-DD_<agent-id>_<slug>.md` with a title, `**Date:**` and `**Agent:**` |

---

## 5. docs/build-plans/phase-*.md Structure

### Important

| ID | Check | What to look for |
|----|-------|-----------------|
| P1 | Status line present | `Status:` line with Planning, In Progress, or Shipped YYYY-MM-DD |
| P2 | Planning sections present | Problem, Scope, Architecture, Key Decisions Locked In, Open Questions (a Batch Log may exist but is not required since P105) |
| P4 | Locked decisions marked | Items in Key Decisions use `[LOCKED]` marker |

---

## 6. project_resume.md Structure

### Important

| ID | Check | What to look for |
|----|-------|-----------------|
| RP1 | Resume file follows the per-agent naming convention, in the resolved directory | `project_resume_<agent-id>.md` in the directory `bash scripts/resolve-resume-path.sh --dir` returns; no hand-built path (P96) |
| RP2 | Contains required sections | What was done, What is next, Blockers (or equivalent headings) |
| RP3 | Uses snapshot format | Single session block with `Last updated:` near the top, not a growing log |

---

## 7. Cross-File Consistency

### Important

| ID | Check | What to look for |
|----|-------|-----------------|
| X2 | In-Flight consistent with Backlog | Items in the In-Flight block have matching `[IN PROGRESS]` entries in Backlog.md |
| X3 | Key Documents tables consistent | agent-memory.md references the CLAUDE.md table rather than maintaining its own |

### Recommended

| ID | Check | What to look for |
|----|-------|-----------------|
| X4 | Recent Work has PR/commit refs | Rollup entries or session records contain references to PRs or commits |
| X6 | Secondary trackers reconciled with commit history | For every `.md` file `scripts/detect-trackers.sh` lists: extract finding IDs from the last 20 commit messages (`\b[A-Z]+-?[0-9]+\b`) and verify matching tracker entries are not still `[OPEN]` (P42) |
| X7 | Declared project type does not contradict the heuristics | A `**Project type:** non-code` declaration while any code heuristic holds FAILS (the reviewer gate and the Stop hook are off for what the repository says is code); declared `code` with no heuristic hit PASSES as the documented opt-in. `sop-project-type.sh` gives the answer; `sop_code_signals` in the same library lists the hits (P102) |

---

## 8. Security, Hooks, and Agents

### Critical

| ID | Check | What to look for |
|----|-------|-----------------|
| S1 | No secrets in committed files | Scan for `.env` files, hardcoded API keys (`sk-...`), private keys, `password=` patterns in tracked files. Exclude `.env.example` and test fixtures. |
| S5 | CI workflows invoking Claude Code are hardened | Applies only when CI invokes Claude Code or a Claude action; otherwise N/A. FAIL if any such workflow sets `allowed_non_write_users` (or equivalent) to a wildcard, or lets an unprivileged actor trigger a write-capable run. |

### Important

| ID | Check | What to look for |
|----|-------|-----------------|
| S2 | Security guidance referenced | `docs/sop/security.md` exists OR CLAUDE.md references security guidance |
| S3 | No `--dangerously-skip-permissions` usage | Scan `.claude/settings.json`, CLAUDE.md, and shell scripts for the flag |
| S4 | Context-file integrity surfaced | The user-scope context hook is installed (`~/.claude/settings.json` registers `sop-session-context.sh`), so uncommitted edits to CLAUDE.md, `Backlog.md` and `docs/agent-memory*` are printed before the session acts on them; without hooks, `/restart-sop` Step 1 reads `git status` on those files |
| S6 | Read-only token posture for CI review workflows | Applies only when CI runs Claude Code in a review-only capacity; otherwise N/A. The workflow's token grants read-only repository access. |
| S7 | Gate integrity — validators unchanged in the range they gate | When the project has `scripts/validate-*.sh` or a checked-in check, a session that changes a validator ships that change as its own Backlog item with a `review:` citation or an accepted skip token (`test-only`, `dep-bump`); `docs-only` and `below-threshold` are not accepted on validator paths (P87) |

### Recommended

| ID | Check | What to look for |
|----|-------|-----------------|
| H1 | User-scope hooks installed | `~/.claude/settings.json` registers `sop-session-context.sh`, `sop-stop-drift.sh` and `sop-push-gate.sh` (installed by `scripts/install-hooks.sh`); project-scope hook entries for the retired `auto-ship-hook.sh` are gone |
| G1 | At least 2 review agents available | `~/.claude/agents/` or `.claude/agents/` contains at least 2 reviewer definitions |
| R1 | Reviewer-turn gate honoured for shipped [Feature]/[Refactor] items | For every `[SHIPPED]` `[Feature]` or `[Refactor]` in the last 30 days whose diff exceeded the threshold, the entry cites an existing `docs/reviews/` artefact that passes `--assert-review`; a skip token is accepted only for the enumerated reasons. Measured with `git diff --numstat <ship-commit>^..<ship-commit>` |
| T1 | Test-gate escape hatch is bounded, not self-judged | `.claude/commands/update-sop.md` Step 1 permits continuing past a failing suite only with a filed `[Bug]`, a Blockers entry, and no `[Feature]`/`[Refactor]` shipping (P70) |
| D1 | Drift-detection infrastructure present | `scripts/validate-state-transitions.sh --check-drift` works when invoked and `/update-sop` runs it in Step 4; for projects tracking pristine replicas, `--check-replication` also runs there (P46, P75) |

---

## 9. Benchmark-Proven Practices

*These checks verify the patterns the core SOP §5 requires (Common Mistakes, intent-based dispatch). A/B benchmarks measured those patterns at +8% to +33% across rounds R1-R5 at k=1 per arm — directional, not a measured effect size. See SOP Section 15's opening note for the citation caveat on the +33% figure specifically.*

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

## 10. Multi-Agent Parallel Sessions

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
| M4 | Per-agent resume file exists | The directory returned by `bash scripts/resolve-resume-path.sh --dir` contains at least one `project_resume_<agent-id>.md`. Legacy `project_resume.md` accepted as fallback when `$AGENT_ID` is `solo`. |

### Recommended

| ID | Check | What to look for |
|----|-------|-----------------|
| M5 | Recent Work rollup refreshed within 7 days | The rollup file — `docs/RECENT-WORK.md` if it carries the sentinels, else `CLAUDE.md` — contains `<!-- recent-work-rollup:start -->` / `<!-- recent-work-rollup:end -->`. The `Last refreshed: YYYY-MM-DD` line inside is within the last 7 days (advisory; rollup is auto-refreshed by `/update-sop`, so staleness indicates `/update-sop` was skipped). |
| M6 | Background-subagent handling documented | `.claude/commands/update-sop.md` contains the pre-flight check (collect or terminate outstanding subagents before Step 1), and any project multi-agent doc notes background-by-default behaviour (Claude Code 2.1.198+). Grep-verifiable by pattern `background` in `.claude/commands/update-sop.md`. |

---

## Check Summary

| Category | Critical | Important | Recommended | Total |
|----------|----------|-----------|-------------|-------|
| File Existence | 3 | 6 | 0 | 9 |
| CLAUDE.md Structure | 3 | 9 (+4 code) | 2 | 14 (+4) |
| Backlog.md Structure | 2 | 8 | 3 | 13 |
| docs/agent-memory.md Structure | 0 | 4 | 2 | 6 |
| docs/build-plans/phase-*.md Structure | 0 | 3 | 0 | 3 |
| project_resume.md Structure | 0 | 3 | 0 | 3 |
| Cross-File Consistency | 0 | 2 | 3 | 5 |
| Security, Hooks, and Agents | 2 | 5 | 5 | 12 |
| Benchmark-Proven Practices | 0 | 0 (+2 code) | 2 | 2 (+2) |
| Multi-Agent Parallel Sessions | 1 | 3 | 2 | 6 |
| **Total (non-code)** | **11** | **43** | **19** | **73** |
| **Total (code)** | **11** | **49** | **19** | **79** |

**Maximum deductions:**
- Non-code: 11 x 10 + 43 x 5 + 19 x 2 = 110 + 215 + 38 = 363
- Code: 11 x 10 + 49 x 5 + 19 x 2 = 110 + 245 + 38 = 393

**Normalisation:** Score = max(0, 100 - (total deductions / max possible deductions * 100)). Then apply critical cap (49 max) if any critical check fails.
