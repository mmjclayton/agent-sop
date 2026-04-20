# P48 — Lift reviewer voice + item-sizing from claude-code-boilerplate, reject the rest

**Date:** 2026-04-20
**Agent:** solo
**Status:** shipped

## Decision

After a direct review of `levu304/claude-code-boilerplate` (122 stars, MIT, single 1,639-line template CLAUDE.md + 12 agents + 2 skills), lift two specific patterns into Agent SOP and ignore the remainder:

1. **Reviewer voice rules** from the `review-local-changes` SKILL — format, drop/keep lists, before/after examples, auto-clarity carve-out — imported into `.claude/agents/code-reviewer.md` as a new "Finding Voice" section.
2. **Task-sizing pedagogy** from Section 15.2 of the boilerplate CLAUDE.md — the "split if title needs 'and' or multiple bullets" heuristic — imported into `docs/templates/backlog-template.md` as a new "Item Sizing" section with one BAD/GOOD pair.

## Why — what was rejected and why

- **Wholesale absorption rejected.** The boilerplate CLAUDE.md duplicates what `~/.claude/rules/` already covers more cleanly (common + per-language split, modular, overridable), and its "score ≥9.5 across all reviewers" gate is aspirational prose with no enforcement mechanism. Agent SOP's P44/P45/P46 already solve the gate-enforcement problem with actual bash validators.
- **Sibling-project fork rejected.** Same reason — `~/.claude/rules/` is the existing home for coding standards; Agent SOP's axis is session discipline, not style.
- **Reviewer agents rejected.** The boilerplate ships 5 overlapping reviewer agents (principal-engineer, code-quality-reviewer, contracts-reviewer, historical-context-reviewer, test-coverage-reviewer). Agent SOP ships 1 (`code-reviewer`) + 1 (`security-reviewer`) deliberately — duplication as design dilutes routing clarity.

## What was actually transferable

The `review-local-changes` skill's terse-reviewer voice is concrete and teachable in a way that most of the rest of the repo is not. Format `L42: \`foo\` can be null after \`.find()\`. Add guard before \`.email\`.` beats prose like "I noticed that...". The drop-list rebuts hedging explicitly ("perhaps", "maybe", "I think"); the keep-list demands exact line numbers, backticked symbol names, concrete fixes. Before/after examples make the distinction unambiguous.

The item-sizing heuristic ("needs 'and' or multiple bullets → split") is a clean, memorable rule that `backlog-template.md` was missing. The BAD example (`Implement user authentication`) vs GOOD decomposition (`Add \`/api/auth/login\` endpoint`, `Add login form component`, `Add session token storage`) teaches the split pattern without needing a full taxonomy.

## How to apply

- **Reviewer voice carve-out:** the "auto-clarity" exception lets security findings, architectural disagreements, and onboarding contexts break terse mode and use normal verbose prose. This prevents the rule from becoming a style-over-substance trap when a finding genuinely needs explanation.
- **Severity taxonomy preserved:** Agent SOP's CRITICAL/HIGH/MEDIUM/LOW severity (which drives the verdict) stays; the boilerplate's 🔴 bug / 🟡 risk / 🔵 nit / ❓ q TYPE tags were not imported to avoid a competing taxonomy on the same finding.
- **Output template preserved:** the `## Review Summary` table and `File: / Issue: / Fix:` structure still stand. The new section tightens the prose inside those slots, not the structure around them.

## Dogfood

No runtime dogfood — this is content-only change to an agent definition and a template. Pass conditions are structural: `code-reviewer.md` parses as valid agent markdown, `backlog-template.md` renders correctly, state-transition validator green. Confirmed in the same session's commit.

## Baseline refresh

Config baselines refreshed for `scripts/validate-state-transitions.sh` (P47), `.claude/commands/restart-sop.md` (P47), and `.claude/agents/code-reviewer.md` (P48). User-scope `code-reviewer.md` mirrored. Config note `_p47_p48_baseline_refresh_2026-04-20` documents the refresh.
