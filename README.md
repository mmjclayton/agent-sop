# Agent SOP

Standard operating procedures for Claude Code agents. Consistent structure, persistent context, measurable compliance.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-v2.1.101+-orange.svg)](https://code.claude.com/docs/en/changelog)
[![Benchmark](https://img.shields.io/badge/A%2FB_benchmarked-directional_+16%25_to_+33%25-brightgreen.svg)](#benchmark-results)
[![Status](https://img.shields.io/badge/status-active-success.svg)](#status)

---

## Contents

- [The Problem](#the-problem) and [The Solution](#the-solution)
- [Token Efficiency](#token-efficiency)
- [What's Included](#whats-included)
- [Session Checklists](#session-checklists)
- [Compliance Checker](#compliance-checker)
- [Benchmark Results](#benchmark-results)
- [Getting Started](#getting-started) — [Quick setup](#quick-setup-recommended), [Keeping the SOP in sync](#keeping-the-sop-in-sync)

---

## The Problem

Claude Code agents start every session with no memory of previous sessions. Without structure, each session rediscovers context, duplicates information across files, loses track of decisions, and drifts from established patterns. Over multiple sessions this compounds. Agents overwrite previous work, contradict earlier decisions, and leave the project in a state the next session cannot pick up cleanly.

## The Solution

This library defines a standard operating procedure that gives every Claude Code agent session:

- **Immediate orientation.** A defined set of files to read at session start, so the agent has full project context within the first few tool calls.
- **Persistent cross-session memory.** Architectural decisions, data model invariants, gotchas, and preferences survive across sessions in `docs/agent-memory.md`.
- **Consistent update rules.** Every session leaves the project in a state the next session can pick up immediately.
- **Security guidance.** Prompt injection awareness, secret scanning, MCP trust boundaries, sandbox guidance.
- **Automated enforcement.** Hooks that automate session checklists, pre-commit quality gates, and pattern extraction.
- **Measurable compliance.** An automated checker agent that audits any project against the SOP and scores it out of 100.

---

## Token Efficiency

The SOP is designed to minimise context window consumption while giving agents full project awareness. Every file, section, and rule has been measured and trimmed. Measurements below were re-taken on **2026-04-17 against this repository** (post-P32-P36 state) on **Claude Opus 4.7 (1M context)**.

### Context windows by model

| Model | Context window |
|-------|---------------|
| Opus 4.7, Opus 4.6, Sonnet 4.6 | 1,000,000 tokens |
| Haiku 4.5, Sonnet 4, Opus 4.5 | 200,000 tokens |

### Session start cost

The 5-step session start checklist reads CLAUDE.md, agent-memory.md, project_resume.md, recent git history, and the current Backlog item. Measured costs per file:

| File | Lines | Words | Est. tokens (low) | Est. tokens (high) |
|------|-------|-------|-------------------|-------------------|
| CLAUDE.md | 174 | 1,562 | 2,030 | 2,922 |
| docs/agent-memory.md | 148 | 2,641 | 3,433 | 4,872 |
| git log --oneline -10 | 10 | 101 | 131 | 184 |
| One Backlog item (typical) | 11 | 54 | 70 | 96 |
| project_resume.md | ~15 | ~80 | 104 | 125 |
| **Session start total** | **~358** | **~4,438** | **~5,770** | **~8,200** |

Low estimate uses words x 1.3; high estimate uses characters / 4. No public offline Claude tokeniser exists, so the true count falls between these bounds. Realistic midpoint: **~7,000 raw tokens**.

Claude Code adds a 1.7x overhead when reading files (line number formatting, tool call framing). This is confirmed by community measurements (GitHub issue [anthropics/claude-code#20223](https://github.com/anthropics/claude-code/issues/20223), which measured 1.7 to 1.75x in practice). With this overhead, the effective session start cost is **~9,800 to 14,000 tokens**.

| Scenario | Raw tokens | Effective (1.7x) | % of 1M context | % of 200k context |
|----------|-----------|-------------------|-----------------|-------------------|
| Fresh project (from templates, ~1,294 words) | ~1,700 | ~2,900 | 0.3% | 1.5% |
| Mature project (this repo, 40+ decisions, P32-P36 shipped) | ~5,770 | ~9,800 | 1.0% | 4.9% |

For comparison, Claude Code's own system prompt and tool definitions consume an estimated 7,000 to 25,000 tokens before any CLAUDE.md is loaded (per community measurements at bswen.com and blog.vincentqiao.com). The SOP's session start overhead is a modest addition on top of baseline costs you cannot control.

After the first turn in a session, Anthropic's prompt caching applies a 90% discount (0.1x) on cache hits, reducing the recurring per-turn cost of loaded files to ~980 to 1,400 effective tokens.

### Library size vs session reads

The full SOP library (25 files across `docs/sop/`, `docs/guides/`, `docs/templates/`, `docs/examples/`, `.claude/agents/`, `.claude/commands/`) totals 4,419 lines and approximately 36,000 to 47,000 tokens. The session start checklist reads only ~358 lines, roughly **8% of the library**. The remaining 92% is accessed on demand through the dispatch table and line-range hints. A naive "read everything" approach would cost ~12x more and consume 18 to 24% of a 200k context window raw (30 to 40% with the 1.7x read overhead) before any work begins.

### How the overhead stays low

**CLAUDE.md size cap.** Per-session sections are capped at 200 lines (~2,000 tokens), consistent with Anthropic's official recommendation to keep CLAUDE.md under 200 lines. Reference sections (Auth, Database, Design System) are read on demand, not every session. The base template is 190 lines; the code template is 347 lines including all reference sections.

**Merged dispatch table.** Key Documents and Dispatch Quick Reference were originally two separate sections with overlapping file listings. Merging them into a single table eliminated the duplication. This was part of a dedicated optimisation pass (commit `71a34e0`) that removed 100 net lines across templates.

**Line-range hints.** The dispatch table supports line-range annotations (e.g. `index.css (lines 1-80)`). When an agent follows a hint, it reads 80 lines instead of the entire file. The core SOP itself supports targeted reads by section — ~45 lines for the session checklists (Sections 5-6) rather than all 632 lines.

**Snapshot resume, not a log.** `project_resume.md` is overwritten each session (~15 lines). Earlier designs used an append-only log that grew without bound. The snapshot model keeps the resume file at a constant size regardless of how many sessions have passed.

**No derived facts.** The SOP prohibits storing test counts, line numbers, file sizes, and dependency versions in memory files. These values go stale between sessions and cost tokens to read without providing reliable information. Agents check these at runtime instead.

**No duplication across files.** The single-source-of-truth rule means each fact lives in exactly one file. `agent-memory.md` points to the CLAUDE.md dispatch table rather than duplicating it. Work item status lives only in Backlog.md, not in build plans or memory.

**Unified checklists.** Session start (5 numbered steps plus a Step 0 SOP staleness check) and session end (7 steps) are defined once in the SOP and referenced by templates. Earlier versions had slightly different step counts in different files, which meant agents had to read multiple sources to reconcile. One canonical version means one read.

**60% context threshold.** The SOP instructs agents to wrap up at 60% context capacity rather than pushing to 95%. This prevents the degraded performance and unreliable behaviour that occurs when context approaches its limit, and ensures the session end checklist can run cleanly.

---

## What's Included

### Core SOP

| Document | Path | Purpose |
|----------|------|---------|
| Core SOP | `docs/sop/claude-agent-sop.md` | The main SOP: file structure, rules, checklists, update triggers |
| Security Guidance | `docs/sop/security.md` | Prompt injection, secret scanning, MCP trust, sandboxing |
| Harness Configuration | `docs/sop/harness-configuration.md` | Hook types + context primitives (clearing, compaction, memory) with reference implementations |
| Compliance Checklist | `docs/sop/compliance-checklist.md` | 75 checks (66 for non-code) with scoring weights |

### Templates

| Template | Path | Use for |
|----------|------|---------|
| CLAUDE.md (base) | `docs/templates/claude-md-template.md` | Any project type |
| CLAUDE.md (code) | `docs/templates/claude-md-template-code.md` | Full-stack code projects (adds Auth, Database, Design System, Code Quality Rules) |
| Agent Memory | `docs/templates/agent-memory-template.md` | New agent-memory.md files |
| Backlog | `docs/templates/backlog-template.md` | New Backlog.md files |
| Build Plan | `docs/templates/build-plan-template.md` | New phase build plans |

### Reference Agents

| Agent | Path | Purpose |
|-------|------|---------|
| SOP Checker | `.claude/agents/sop-checker.md` | Audits any project for SOP compliance |
| Code Reviewer | `.claude/agents/code-reviewer.md` | Reviews code for quality, security, maintainability |
| Security Reviewer | `.claude/agents/security-reviewer.md` | OWASP Top 10, secret detection, auth issues |
| Planner | `.claude/agents/planner.md` | Structured build plans with phases and risks |
| E2E Runner | `.claude/agents/e2e-runner.md` | Playwright end-to-end test generation and execution |

### Examples and Guides

| Document | Path | Purpose |
|----------|------|---------|
| Implementation Guide | `docs/examples/sop-implementation-guide.md` | Agent-facing setup instructions |
| New Project Walkthrough | `docs/examples/new-project-walkthrough.md` | Human-readable guide with a concrete example project |
| Migration Guide | `docs/examples/existing-project-migration.md` | Checklist for adding the SOP to an existing project |

---

## Six Non-Negotiable Rules

These cannot be overridden by any project-specific configuration. Each is tagged with the failure mode it prevents.

1. **Never delete without a trace. Never add without reason.** *Prevents lost history and unjustified content creeping in.* Update in place, mark `[SUPERSEDED]`, or move to `## Archived`. Every changed line must trace directly to the user's request — no drive-by refactors, no speculative abstractions, no "while I'm here" additions.

2. **One source of truth.** *Prevents drift and contradiction from duplicated facts.* Each information type lives in exactly one file. When files disagree, explicit precedence resolves it: code/git, then CLAUDE.md, then Backlog.md, then build plan, then feature map, then agent memory, then resume point.

3. **No opinion. State facts.** *Prevents subjective nudges disguised as recommendations.* Respond with evidence — what the code does, what the docs say, what git shows. Don't volunteer opinions or hedged framing. Offer an opinion only when explicitly asked.

4. **Work back and forth before writing any plan.** *Prevents committing to the wrong direction before the user sees it.* Surface open questions and a rough outline first. Wait for the user's response. Only write the formal plan once the questions are resolved.

5. **Instruction budget: ≤150 soft cap, 200 hard ceiling.** *Prevents instruction drop-out and diluted attention past ~200 items.* Any agent must operate under ≤150 distinct instructions across its combined context (SOP + CLAUDE.md + agent definition + rules + invocation prompt). Trim before adding.

6. **Surface interpretations before acting.** *Prevents hidden interpretation picks surfacing later as rework.* When a request has multiple valid interpretations, list them, name the default, and ask. Don't pick silently.

---

## Session Checklists

**Every session must start with `/restart-sop` and end with `/update-sop`.** These slash commands automate the full checklists. No exceptions.

| Command | When | What it does |
|---------|------|-------------|
| `/restart-sop` | Start of every session | Reads all context files, checks git history, flags inconsistencies, reports readiness |
| `/update-sop` | End of every session | Updates all tracking files, writes the resume snapshot, commits |

The commands are installed by the setup script into `~/.claude/commands/` (user-scope, available across all projects without a prefix). Reference agents are installed to `~/.claude/agents/` in the same pass. Project-scope copies can still be placed at `.claude/commands/` or `.claude/agents/` to override the user-scope version when needed.

**What `/restart-sop` does (6 steps):**
0. SOP staleness check — warn if `last_update_check` exceeds the configured cadence
1. Read CLAUDE.md
2. Read MEMORY.md and project_resume.md
3. Read docs/agent-memory.md
4. Run `git log --oneline -10`, cross-check memory against current state
5. Read the Backlog item(s) for this session

**What `/update-sop` does (7 steps):**
1. Run tests (code projects)
2. Update Backlog.md
3. Update docs/feature-map.md
4. Update docs/agent-memory.md
5. Update docs/build-plans/phase-N.md Batch Log
6. Overwrite project_resume.md
7. Commit docs/ changes with the work

Wrap up at 60% context capacity, not 95%.

---

## Compliance Checker

The SOP includes an automated compliance checker agent. Run it from a Claude Code session:

```
@sop-checker check SOP compliance for ~/Projects/my-app
```

### What it checks

75 checks across 10 categories (66 for non-code projects):

| Category | What it verifies |
|----------|-----------------|
| File Existence | All mandatory files present at correct paths |
| CLAUDE.md Structure | Required sections, checklist steps, line limits |
| Backlog.md Structure | Tag format, status/type order, P-number sequencing |
| agent-memory.md | All 8 sections, no derived facts, no duplication |
| feature-map.md | Last-updated header, shipped/roadmap sections |
| Build Plans | All 7 sections, Batch Log format, [LOCKED] markers |
| project_resume.md | Correct naming, snapshot format, required sections |
| Cross-File Consistency | Shipped items in both Backlog and feature map |
| Security, Hooks, Quality, Agents | Secret scanning, security docs, file limits, coverage threshold, hooks, agents |
| Benchmark-Proven Practices | Common Mistakes section, intent-rich dispatch, subsections |

### Scoring

| Tier | Points | Rule |
|------|--------|------|
| Critical | 10 each | Any failure caps total score at 49/100 |
| Important | 5 each | Deducted from pool |
| Recommended | 2 each | Advisory |

90 to 100: fully compliant. 70 to 89: largely compliant. 50 to 69: partially compliant. 0 to 49: non-compliant.

---

## Benchmark Results

The SOP has been A/B tested against a baseline (no SOP context) using blind-scored agent pairs on identical tasks. Rounds 1-2 (2026-04-09) ran against a production React/Express codebase (hst-tracker, ~15K lines, 7 models, 486 tests) on the pre-P32 SOP, using fresh Claude Code CLI sessions on Opus 4.6 — this is the methodology behind the +33% claim. Round 5 (2026-04-17) was a directional pilot re-run of the post-P32-P36 trimmed SOP on the same tasks and same base commit, using subagents rather than fresh CLI sessions, on Opus 4.7. R5 is directionally positive but methodologically weaker than R1-R2 and should not be read as a definitive replacement.

### Round 1: Precise prompts (detailed task instructions)

| Metric | SOP | Baseline | Delta |
|--------|-----|----------|-------|
| Aggregate score | 68/72 (94%) | 62/72 (86%) | **SOP +8%** |
| Wins | 2 | 1 | 1 draw |
| Token overhead | +16% | baseline | |

### Round 2: Vague prompts (product-level instructions, sharpened SOP)

| Metric | SOP | Baseline | Delta |
|--------|-----|----------|-------|
| Aggregate score | 78/84 (93%) | 50/84 (60%) | **SOP +33%** |
| Wins | 3 | 0 | 1 draw |
| Token overhead | +24% | baseline | |
| Production bugs prevented | 2 | 0 | |

### Round 5: Post-trim pilot (directional, subagent methodology)

Same 4 vague tasks as R2, same base commit. Ran 2026-04-17 on the post-P32-P36 SOP (~195 instructions after trim vs R2's ~230).

| Metric | SOP | Baseline | Delta |
|--------|-----|----------|-------|
| Aggregate score | 75/84 (89%) | 61/84 (73%) | **SOP +16%** |
| Wins | 3 | 0 | 1 loss |
| Tasks where baseline regressed prior fix | 0 | 1 (Task 5 tonnage) | |

R5 margin is roughly half of R2's +33%. Drivers (from `docs/benchmark/results/r5-post-trim/summary.md`): baseline was more capable this run (Opus 4.7 vs R2's 4.6; didn't crash on task 07 as R2's did; used correct design tokens on task 08 unlike R2); subagent methodology inherits parent-session capabilities in ways fresh CLI sessions do not; single-round run is not statistically averaged. R5 is **directional evidence the trim did not break the SOP** — not a definitive replacement for R2's +33% figure. A full-framework R6 on fresh CLI sessions, same model as R2, multi-round, is needed before citing a post-trim percentage unconditionally.

### Key findings

1. **"Common Mistakes" is the highest-value section.** It directly prevented 2 production bugs in round 2 (wrong CSS tokens, wrong function modified).
2. **Intent-rich dispatch outperforms file-path lists.** "When you need to change X, start at Y" navigates agents directly. File paths alone cause blind exploration.
3. **Vague prompts amplify the gap.** Precise prompts mask context deficiencies. Product-level prompts (how real work arrives) expose them.
4. **The SOP raises the quality floor, not the ceiling.** Both agents can produce excellent code. The SOP prevents catastrophic misses.
5. **Token overhead paid for itself in R2.** R2 SOP used 24% more tokens but produced 56% higher scores; on one task, SOP used fewer tokens than baseline while producing a correct result. R5 did not remeasure tokens — the post-trim token overhead has not been independently verified.

Full methodology, task specs, and scoring data: `docs/benchmark/`

---

## Getting Started

### Requirements

Claude Code **v2.1.101 or later**. Earlier versions have a long-session memory leak, permission rule bypasses, and `--resume` chain recovery bugs that affect SOP workflows. Check with `claude --version`.

### Quick setup (recommended)

Clone this repo, then run the setup script against your project:

```bash
# For documentation, markdown, or script projects
./setup.sh /path/to/your/project

# For web apps, APIs, CLIs, or anything with tests and a database
./setup.sh /path/to/your/project --code
```

This installs the full SOP surface:

- **Per-project** (customised — from templates): `CLAUDE.md`, `Backlog.md`, `docs/agent-memory.md`, `docs/feature-map.md`, `docs/build-plans/phase-0-foundation.md`.
- **Per-project** (pristine-replica — kept in sync by `/update-agent-sop`): `docs/sop/*.md` (core SOP + security + sandboxing + harness + compliance), `docs/guides/*.md` (optional patterns, multi-agent routing, managed agents, hill-climbing).
- **User-scope** (one install, all projects benefit): `~/.claude/commands/*.md` (slash commands), `~/.claude/agents/*.md` (reference agents: sop-checker, code-reviewer, security-reviewer, planner, e2e-runner), `~/.claude/agent-sop.config.json` (update tracking).

Existing files are not overwritten unless you pass `--force`.

After running the script, open each per-project customised file and replace the `[bracket placeholders]` with real project-specific content. Then validate:

```
@sop-checker check SOP compliance for /path/to/your/project
```

### Keeping the SOP in sync

The SOP evolves — this repo ships changes as new rules, cuts to reduce instruction load, or new reference agents. To pull updates into an existing project without losing any local edits:

```
/update-agent-sop
```

How it works:

1. **Source resolution.** Reads the config (`~/.claude/agent-sop.config.json` or per-project `.claude/agent-sop.config.json`). Uses `local_path` if it points to a valid agent-sop checkout; otherwise pulls from GitHub raw at `mmjclayton/agent-sop`.
2. **Three-way diff per file.** Compares upstream vs your copy vs the recorded baseline SHA. Files you haven't modified are updated automatically. Files you have modified are surfaced for reconciliation — you decide per file whether to accept upstream, keep local, or merge.
3. **No force-overwrite.** The command never silently replaces a locally edited file. Every conflict gets a prompt.

`/restart-sop` prints a one-line warning when your last sync is stale (default: 7-day cadence, configurable in the config file's `update_reminder` field: `"weekly"` | `"manual"` | `"off"`).

See `docs/templates/agent-sop-config-template.json` for the full config schema.

### Other setup options

**Human walkthrough.** Read `docs/examples/new-project-walkthrough.md` for a step-by-step guide using a concrete example project. Good for understanding what each file does and why before creating anything.

**Agent-driven setup.** Clone this repo to a path of your choice, then paste the following into a Claude Code session on your project (replace `<AGENT_SOP_PATH>` with the absolute path to your clone):

```
I want you to implement the Agent SOP in this project. The SOP repo is at <AGENT_SOP_PATH>.

1. Read <AGENT_SOP_PATH>/docs/sop/claude-agent-sop.md (the full SOP)
2. Read <AGENT_SOP_PATH>/docs/examples/sop-implementation-guide.md (step-by-step setup)
3. Choose the right CLAUDE.md template:
   - Base (non-code): <AGENT_SOP_PATH>/docs/templates/claude-md-template.md
   - Code projects: <AGENT_SOP_PATH>/docs/templates/claude-md-template-code.md

Then follow the implementation guide to create all standard files in THIS project.
Fill in all sections with real project-specific content. Do not leave template placeholders.
After creating the files, run through the verification checklist, then commit.
```

**Existing project migration.** Read `docs/examples/existing-project-migration.md` for a structured audit-and-fix checklist. Covers common gaps (missing sections, duplicate information, incorrect file naming) and provides a verification checklist at the end. Alternatively, run the compliance checker to see exactly what is missing:

```
@sop-checker check SOP compliance for ~/Projects/my-app
```

---

## Repository Structure

```
agent-sop/
  CLAUDE.md                              # This project's own SOP config
  Backlog.md                             # Work items for the SOP library itself
  README.md                              # This file
  setup.sh                               # Onboarding script for new projects
  .claude/
    commands/
      restart-sop.md                     # /restart-sop — session start checklist
      update-sop.md                      # /update-sop — session end checklist
      update-agent-sop.md                # /update-agent-sop — sync with upstream
    agents/
      sop-checker.md                     # Compliance checker agent
      code-reviewer.md                   # Code review agent
      security-reviewer.md               # Security review agent
      planner.md                         # Build planning agent
      e2e-runner.md                      # E2E testing agent
  docs/
    agent-memory.md                      # Cross-session context for this project
    feature-map.md                       # Shipped documents and roadmap
    sop/
      claude-agent-sop.md                # The core SOP document
      compliance-checklist.md            # Canonical compliance checks and scoring
      security.md                        # Core security rules
      sandboxing.md                      # Container / network isolation (autonomous runs)
      harness-configuration.md           # Hooks + context primitives (clearing, compaction, memory)
    guides/
      optional-patterns.md               # Patterns for large projects (claude-progress.txt, sub-agents, rubrics)
      multi-agent-context-routing.md     # Context tiers for parallel-agent work
      managed-agents-integration.md      # Deferred — Managed Agents API mapping
      sop-hill-climbing.md               # Benchmark-driven SOP improvement methodology
    templates/
      claude-md-template.md              # CLAUDE.md template (base, any project)
      claude-md-template-code.md         # CLAUDE.md template (code projects)
      agent-memory-template.md           # Agent memory template
      backlog-template.md                # Backlog template
      build-plan-template.md             # Build plan template
      agent-sop-config-template.json     # Schema for ~/.claude/agent-sop.config.json
    examples/
      sop-implementation-guide.md       # Agent-facing setup instructions
      new-project-walkthrough.md        # Human-readable new project guide
      existing-project-migration.md     # Migration checklist for existing projects
    benchmark/
      README.md                          # Benchmark methodology and scoring rubric
      run-benchmark.sh                   # Worktree setup, execution, scoring, cleanup
      nosop-stub.md                      # What gets stripped from baseline condition
      tasks/                             # 8 task specs (4 precise, 4 vague)
      results/                           # Round 1 and round 2 scored results
    build-plans/
      phase-0-foundation.md             # Current phase
```

---

## Status

**Active and ready to use.** The core SOP, templates, slash commands, compliance checker, reference agents, and cross-project sync mechanism (`/update-agent-sop`) are all shipped. The library has been A/B benchmarked against a baseline on a real production codebase (see [Benchmark Results](#benchmark-results)).

Active development continues on multi-agent coordination patterns and domain-specific variants for web apps, marketing, and data/analytics projects. Roadmap and full work history live in [`Backlog.md`](Backlog.md).

Issues, suggestions, and benchmark contributions welcome.

---

## Acknowledgements

Several concepts in this SOP were informed by or adapted from [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) (ECC) by [affaan-m](https://github.com/affaan-m), a comprehensive collection of skills, rules, agents, and hooks for Claude Code. Specific areas where ECC influenced our approach:

- **Security guidance** (`docs/sop/security.md`). Adapted from ECC's security rules covering prompt injection, secret scanning, and MCP trust boundaries.
- **Harness configuration** (`docs/sop/harness-configuration.md`). Hooks and context primitives in one file — reference implementations for SessionStart, PostToolUse, and Stop events, plus clearing/compaction/memory-tool settings.
- **Code quality rules** in the code template. File size limits, immutability, and error handling patterns drawn from ECC's coding-style rules.
- **Reference agent definitions.** The code-reviewer, security-reviewer, planner, and e2e-runner agents follow patterns established by ECC's agent library.
- **Compliance checker scoring model.** The three-tier (Critical/Important/Recommended) scoring approach with critical-failure caps.
- **Continuous learning pattern.** Pattern extraction cadence and promotion rules adapted from ECC's continuous-learning skill.

This SOP is not a fork of ECC. It is an independent, opinionated operating procedure that incorporates proven patterns from the ECC ecosystem alongside original work on session checklists, backlog management, cross-file consistency, and measurable compliance scoring.
