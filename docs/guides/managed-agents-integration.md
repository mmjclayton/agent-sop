<!-- SOP-Version: 2026-04-17 -->
# Managed Agents Integration Guide

> **Status: DEFERRED (parked 2026-04-17)**
> Parked out of the core SOP pending actual Managed Agents usage. Revive when a project moves from Claude Code sessions to the Managed Agents API. Backlog: P33.

This guide maps SOP concepts to the Claude Managed Agents API (`api.anthropic.com/v1/agents`, beta `managed-agents-2026-04-01`). Use it when transitioning a project from Claude Code sessions to the Managed Agents API, or when building products on top of Managed Agents that follow the SOP.

## Memory store mapping

The SOP's file-based memory system maps to Managed Agents memory stores:

| SOP file | Memory store | Access | Notes |
|----------|-------------|--------|-------|
| `docs/agent-memory.md` Decisions + Gotchas | Shared project store (read-write) | `read_write` | All agents read; coordinator writes learnings |
| CLAUDE.md Common Mistakes | Reference store (read-only) | `read_only` | Loaded by all agents, never modified by agents |
| `project_resume.md` | Not needed | N/A | Sessions have built-in event history via `getEvents()` — resume from any checkpoint |
| `docs/feature-map.md` | Not needed | N/A | Track in the repo; agents read via filesystem |

Structure memory stores as many small files (max 100KB each), not a few large ones. Use path prefixes for organisation: `/common-mistakes/data-model.md`, `/common-mistakes/client.md`, `/decisions/2026-04.md`.

## Skills vs CLAUDE.md sections

Managed Agents skills load on demand when relevant to the task. For most projects, keep Common Mistakes and Dispatch in the system prompt (always loaded) rather than as skills. Skills are better suited for:
- Large reference material (API docs, design system specs > 300 lines)
- Domain-specific workflows that apply to some tasks but not others
- Content that changes independently of the agent configuration

A maximum of 20 skills per session applies across all agents in a multi-agent setup.

## Session lifecycle vs SOP checklists

| SOP concept | Managed Agents equivalent |
|-------------|--------------------------|
| Session start checklist | System prompt includes CLAUDE.md content; memory stores loaded automatically |
| Session end checklist | Agent writes learnings to memory store; event log persists all activity |
| `project_resume.md` snapshot | `getEvents()` — retrieve any prior session's full event history |
| Context compaction at 60% | Managed by the harness automatically (built-in prompt caching and compaction) |
| Never delete without a trace | Append-only event log is the native model — events cannot be deleted |

## Outcomes for quality-gated work

The `user.define_outcome` event pairs a task description with a rubric (markdown). A separate grader evaluates the output and returns per-criterion feedback. The agent iterates until the rubric is satisfied or `max_iterations` is reached.

Map the SOP's Definition of Done rubrics directly to outcome rubrics:
1. Upload the rubric via the Files API (`POST /v1/files`)
2. Send `user.define_outcome` with the rubric file reference
3. The grader evaluates independently (separate context window, no bias from the agent's implementation)
4. Results surface as `span.outcome_evaluation_end` events with `satisfied`, `needs_revision`, or `max_iterations_reached`

This is the API-native version of the self-evaluation pattern — the grader runs in a separate context window, avoiding the confirmation bias inherent in self-evaluation.

## Benchmark safety (Managed Agents API)

> Extracted from core SOP Section 15.4 on 2026-04-17 (P40). Core SOP retains the local-Claude-Code safety rules; this guide owns the API-specific block.

When benchmarks run via Managed Agents sessions instead of local Claude Code, use permission policies to enforce safety at the API level:

- `bash`: `always_allow` (agents need to run tests)
- `write` and `edit`: `always_allow` (agents need to modify code)
- Git push operations: restrict via system prompt ("never push to remote") or use a read-only GitHub token that lacks push permissions
- Mount repositories with read-only tokens when testing code review or analysis tasks
- Use isolated environments per session — each Managed Agent session gets its own container, eliminating the worktree contamination problem entirely
