<!-- SOP-Version: 2026-04-17 -->
# Optional Patterns for Large Projects

Patterns that are optional. Add them when complexity warrants — they are not required for standard projects. Extracted from SOP Section 12 on 2026-04-17 as part of the P32 trim.

## claude-progress.txt (human-readable status file)

For large features spanning multiple sessions, maintain a `claude-progress.txt` at project root. Unlike `project_resume.md` (agent-facing, prepend-only), this file is human-readable at a glance and updated in-place each session.

Recommended format:
```
Current task: [P-number and short name]
Status: [In Progress / Blocked / Ready for review]
Completed: [bullet list of done steps]
Next: [specific next action]
Blockers: [(none) or description]
Last updated: YYYY-MM-DD
```

Do not add `claude-progress.txt` to `.gitignore` — it is a useful artefact for project owners to check without opening Claude Code.

## Sub-agent delegation (.claude/agents/)

For projects where parallel work is feasible, Claude Code supports named sub-agents defined as markdown files in `.claude/agents/[name].md`. Each sub-agent receives its own system prompt and optional tool restrictions.

Use cases: a `test-runner` agent that only runs test suites and reports results, a `migration-agent` that handles database schema changes, or a `docs-agent` restricted to documentation updates only.

Each agent file format:
```
---
name: [agent-name]
description: [one-line purpose — used by the orchestrator to decide when to delegate]
tools: [optional comma-separated tool restrictions]
---

[Agent system prompt here]
```

Sub-agents add coordination overhead. Only introduce them when a project has clearly separable workstreams that would otherwise require sequential single-agent effort.

## Schema change protocol (projects with a database)

Any change to the data model must follow this sequence. Do not skip steps or reorder.

```
1. Edit the schema definition (ORM model, SQL, or equivalent)
2. Create and run the migration
3. Update server routes / API handlers that touch the changed model
4. Update client code that consumes the changed data
5. Add or update tests covering the change
6. Verify the full test suite passes
```

Add this checklist to the project's CLAUDE.md under Rules for Automated Builds. The SOP templates include it in the code variant (`claude-md-template-code.md`).

## Continuous learning (pattern extraction across sessions)

Agent sessions produce reusable decisions, gotchas, and patterns that are valuable beyond the current session. Continuous learning is the practice of systematically extracting these patterns and persisting them for future sessions.

**What to extract:**
- Decisions that resolved ambiguity (e.g. "use displayMuscleGroup() for all muscle group display logic")
- Data model invariants that are not obvious from the schema
- Framework-specific patterns that agents commonly get wrong
- Workarounds for library or tooling quirks
- Error resolutions that took significant debugging effort

**Where to store extracted patterns:**
- `docs/agent-memory.md` — for facts any contributor needs (decisions, invariants, gotchas, named utility functions)
- Auto-memory (`~/.claude/projects/.../memory/`) — for user preferences, feedback on agent behaviour, session-specific notes

**Extraction cadence:**
- After every session: extract decisions and gotchas as part of the session end checklist (step 4)
- Every 5 sessions: audit `docs/agent-memory.md` for stale or redundant entries. Mark outdated entries `[SUPERSEDED]` and move to `## Archived`
- When a pattern repeats across 3+ sessions: promote it from a gotcha to a rule in CLAUDE.md or a dedicated `.claude/rules/` file

**Automated extraction (optional):**
Claude Code hooks can automate pattern detection. A `Stop` hook can evaluate each agent response for extractable patterns and prompt the agent to persist them. See `docs/sop/harness-configuration.md` for reference implementations.

**What does NOT belong in extracted patterns:**
- Derived facts (test counts, line numbers, dependency versions) — these go stale immediately
- One-time fixes or typo corrections
- External API issues or transient errors
- Information already documented in CLAUDE.md or the codebase

## Outcome rubrics (self-evaluation before shipping)

An outcome rubric defines what "done" looks like for a task type. The agent evaluates its own work against the rubric before committing. Benchmark data shows rubric-based evaluation catches quality gaps that checklist-based approaches miss — the rubric forces the agent to verify results against specific criteria rather than simply confirming steps were followed.

**Add a `## Definition of Done` section to CLAUDE.md** with per-task-type rubrics. The agent reads the relevant rubric before committing and self-evaluates. If any criterion is not met, it iterates before shipping.

Example rubrics by task type:

**Bug fix:**
```markdown
- Root cause identified from reading the actual code — do not infer root cause from documentation alone
- Fix is minimal: change the broken logic, do not remove working mechanisms
- Fix applied to ALL instances of the pattern (grep for similar occurrences)
- No regressions — full test suite passes
- New test covers the specific bug scenario
- Fix uses existing project utilities where they exist (check Common Mistakes section)
- Commit message explains the root cause, not just what changed
```

**Feature:**
```markdown
- All acceptance criteria from the Backlog item are met
- Server endpoint has integration tests (real DB, not mocks)
- Client component has unit tests for logic
- UI follows design system (CSS tokens, touch targets, responsive breakpoints)
- Brand voice followed in all user-facing copy
- No console.log or debug artifacts
- Backlog.md and feature-map.md updated in the same commit
```

**Refactor:**
```markdown
- Behaviour is unchanged — all existing tests pass without modification
- If tests needed updating, the change was in test assertions matching new implementation (not weakening tests)
- No unrelated files modified
- New pattern is consistent with existing codebase conventions
- Dead code from the old pattern is removed (not commented out)
```

**Test writing:**
```markdown
- Tests cover the actual behaviour of the code, not just the happy path
- Edge cases tested: null/undefined inputs, empty collections, boundary values
- Test names describe the behaviour under test (not the implementation)
- Tests follow existing patterns in the test file (describe blocks, naming, helpers)
- No production code modified
- All tests pass
```

These rubrics work with Claude Managed Agents' `user.define_outcome` API (independent grader) — see `docs/guides/managed-agents-integration.md`. They are equally effective as self-evaluation prompts in Claude Code sessions: the agent reads the rubric from CLAUDE.md and checks its own work before committing.
