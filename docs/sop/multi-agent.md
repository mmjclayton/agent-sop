<!-- SOP-Version: 2026-07-06 -->
# Multi-Agent — Entry Point and Optimisation Guide

Canonical reference for any project running more than one agent on the same repo. Acts as the dispatch layer for the deep-mechanics guides; covers the decisions and trade-offs they intentionally do not.

This document does **not** restate the mechanics in `multi-agent-parallel-sessions.md` or `multi-agent-context-routing.md`. Where mechanics matter, follow the cross-references.

---

## 1. The two patterns

Multi-agent work in Claude Code splits cleanly into two patterns. Mixing them up is the most common source of wasted setup time.

| Pattern | Concurrency unit | Lifetime | Conflict mode | Deep guide |
|---------|------------------|----------|---------------|------------|
| **Parallel sessions** | One Claude Code instance per worktree, separate branches | Hours to days | Tracking-file appends, P-number collisions, sibling worktree wipe | `docs/guides/multi-agent-parallel-sessions.md` |
| **Coordinator + specialist** | One Claude Code session, sub-agents inside it | Minutes to hours | Same-file overlap between specialists | `docs/guides/multi-agent-context-routing.md` |

The patterns compose — a parallel session can spawn coordinator+specialist sub-agents internally — but the design choices are independent. Decide which one you need before reading the deep mechanics.

---

## 2. Decision tree: do you actually need parallel mode?

Multi-agent has setup cost (worktrees, agent-id resolution, per-entry directories, P-number discipline). It pays off only in specific shapes of work. Default to solo unless one of the triggers fires.

```
Are 3+ independent shippable items in flight at once?
  No  → Stay solo. Solo agents already use per-entry directories cleanly.
  Yes → Continue.

Can the items run on disjoint files (no shared modules)?
  No  → Stay solo. Sequential merging with one agent costs less than worktree contention with two.
  Yes → Continue.

Is each item bounded (estimated under one session)?
  No  → Reconsider. Long-running items create stale-branch hazard with sibling worktrees.
  Yes → Continue.

Will a human serialise the merges to the default branch?
  No  → Add a CI lock or stay solo. Concurrent merges to main race on Backlog flips and rollup regeneration.
  Yes → Parallel mode is appropriate.
```

For coordinator+specialist within one session, the decision is simpler: use it when a task has a clean read-only review pass alongside an implementation pass. Otherwise the coordinator overhead doesn't pay back. See `multi-agent-context-routing.md` for the context-tier table.

---

## 3. Mechanics summary

Phase 1 (P43) shipped four structural choices that prevent tracking-file conflicts in parallel mode without any human-in-the-loop coordination protocol. They are summarised here so this document is self-contained for orientation; full mechanics live in `multi-agent-parallel-sessions.md`.

- **Per-entry directories.** Recent Work, Decisions, Gotchas, and In-Flight all live as one file per entry with agent-id in the filename. Two agents writing on the same date produce distinct filenames. The `## Recent Work (rollup)` section in CLAUDE.md is regenerated from `docs/recent-work/` by `/update-sop` Step 8b — idempotent so merges converge.
- **Per-agent resume snapshots.** `project_resume_<agent-id>.md` keyed by agent-id (resolution: `CLAUDE_AGENT_ID` env > `.sop-agent-id` file > `solo` default > 6-char path hash). No cross-agent clobber. Agent-id separates agents *within* a project; the repo-root-derived directory from `scripts/resolve-resume-path.sh` separates projects. Both are needed — every single-worktree project resolves to the same `solo` id, so the directory is the only thing keeping two projects' snapshots apart.
- **Commit-range partitioning.** Secondary-tracker reconciliation, drift guard, and hard-block checks use `git merge-base <default> HEAD..HEAD` so sibling agents' finding IDs never contaminate this agent's scope.
- **P-number collision detection.** `/update-sop` Step 2a hard-blocks when two agents independently pick the same P-number; resolved via the `renumber_p` shell helper.

For the agent-id resolution snippet, the directory layout, the rollup regeneration command, the `renumber_p` helper, and the dogfood protocol, see the parallel-sessions guide directly.

---

## 4. Optimisation rules of thumb

These are heuristics derived from the P54 hardening dogfood (sibling-worktree wipe, perf gates) and the R2 / R5 benchmark rounds. Each rule has a measured or observed origin; none are speculative.

**Token budget allocation (coordinator + specialist pattern).**
- Coordinator carries full CLAUDE.md, agent-memory.md, and the active build plan (~5K-8K tokens of context overhead).
- Specialists carry only what their task tier in `multi-agent-context-routing.md` mandates — minimal-tier specialists (test writers, single-property CSS fixes) should not see CLAUDE.md.
- A coordinator that loads full context for every specialist call burns ~3x the necessary tokens. Always pass the tier-appropriate slice.

**Worktree count.**
- 2-3 parallel agents: human can name them with `.sop-agent-id` (`reviewer`, `refactor`, `qa`). Filenames stay readable.
- 4+ agents: prefer the path-hash default. Naming becomes overhead, hash collision is statistically negligible (6-char hex on per-worktree paths).
- Past 5 concurrent agents on one repo, expect the merge-serialisation step to dominate wall-clock. Re-evaluate whether the work could be batched.

**Fan-out ceilings (coordinator + specialist pattern).**
- Claude Code caps concurrently-running subagents at **20** (`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`), subagent spawns at **200 per session** (`CLAUDE_CODE_MAX_SUBAGENTS_PER_SESSION`, reset by `/clear`), and WebSearch calls at **200 per session** — all from Claude Code 2.1.212.
- Design coordinator fan-outs under the concurrency cap rather than discovering it mid-run. A 40-way fan-out does not fail; it queues, and the wall-clock estimate that justified the fan-out silently stops holding.
- **Do not encode the nesting-depth default in project docs.** It has been restated across 2.1.217 and 2.1.219 and is env-overridable via `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`, so any value written down is both version-bound and locally overridable. Check the changelog for the live value if a design depends on nesting; better, design so it doesn't.

**Parallel-batch instruction in `/update-sop` (perf gate from P54).**
- Steps 4 (feature-map), 7 (resume snapshot), and 8 (recent-work + rollup refresh) are independent reads/writes — issue all of their tool calls in a single round, not sequentially. Measured ~30-40% wall-clock saving on docs-only sessions.

**Skip predicates (perf gate from P54).**
- `/update-sop` Step 4 skips when no `[SHIPPED]` tags are added in the session.
- Step 5 substance-gates decisions/gotchas (only fires when there is something genuine to record).
- Step 8b skips rollup regeneration when no new `docs/recent-work/` entry was written.
- Don't fight these gates. If a session genuinely has nothing in those buckets, the skip is correct — and the agent-memory rules (Rule 1: never delete without a trace, Rule 2: one source of truth) mean a no-op is structurally honest.

---

## 5. Common Mistakes — multi-agent

Multi-agent introduces failure modes that don't exist in solo work. Each entry below has a confirmed source incident.

**Sibling worktree wipe.** Branch-mutating git operations (`checkout`, `reset --hard`, `rebase`, ref-touching deletes) in any worktree can discard uncommitted edits in a *sibling* worktree because the `.git` directory is shared. `/restart-sop` Step 0a prints a soft advisory; `/update-sop` enforces the same gate harder. Recovery via `git fsck --lost-found` is possible but slow and lossy. **Always commit or stash in every worktree before any branch-mutating operation in any worktree.** Source: `docs/agent-memory/gotchas/2026-05-02_solo_worktree-uncommitted-wipe.md`.

**P-number collision masquerading as a no-op.** When two agents pick the same next P-number for *similar-sounding* items (e.g. both file "fix tonnage rounding"), the Step 2a check matches titles loosely and may treat the collision as a no-op rather than blocking. **Always re-read the colliding entry's body before merging.** If the items are genuinely different, run `renumber_p` on the second one regardless of what Step 2a reports. Source: parallel-sessions guide §6.

**Two Claude instances in one worktree.** The agent-id mechanism is per-worktree, not per-instance. Running two Claude Code terminals in the same worktree gives both agents the same agent-id and the same per-agent files — defeating every conflict-prevention guarantee. **One Claude per worktree, always.** New agents get `git worktree add <path> -b <branch>`. Source: parallel-sessions guide §8.

**Hand-edits to the rollup.** The `## Recent Work (rollup)` section in CLAUDE.md is regenerated by `/update-sop` Step 8b from `docs/recent-work/`. Hand-edits get overwritten silently. **Edit the source file in `docs/recent-work/` and re-run `/update-sop`.**

**Gateway-routed parallel sessions.** When `ANTHROPIC_BASE_URL` is set to a non-Anthropic backend, `/restart-sop` Step 0e prints a soft advisory. Reviewer-substance assertions, drift detection, and reviewer voice rules may degrade per `claude-agent-sop.md` §15.5. In parallel mode this compounds — a sycophantic reviewer agent can rubber-stamp a sibling agent's broken work without the operator catching it. **Treat compliance scores and reviewer findings as advisory in any parallel session running on a swapped backend.**

**Session-end with outstanding background subagents.** Subagents run in the background by default from Claude Code 2.1.198 (1 July 2026) — the coordinator keeps working and is notified on completion. Running the session-end checklist while subagents are outstanding produces a resume snapshot and Backlog state that omit their work, and any Backlog/tracker writes they make after the checklist land untracked. **Collect results from (or explicitly terminate) every outstanding subagent before starting `/update-sop`.** `/update-sop`'s pre-flight check asserts this. Source: Claude Code changelog 2.1.198 (runtime behaviour change, not an incident).

---

## 6. Compliance checks

The compliance checklist (`docs/sop/compliance-checklist.md` Section 11) covers multi-agent enforcement with six checks (M1-M6):

| ID | Check | Tier |
|----|-------|------|
| M1 | Agent-id resolvable (env > file > solo > hash) | Critical |
| M2 | Per-entry directory structure exists | Important |
| M3 | Commit-range uses `git merge-base` | Important |
| M4 | Per-agent resume file exists | Important |
| M5 | CLAUDE.md rollup refreshed within 7 days | Recommended |
| M6 | Background-subagent handling documented (collect/terminate before session-end) | Recommended |

Run via the `sop-checker` agent against any project — see `.claude/agents/sop-checker.md` Phase 4.5.

---

## 7. Cross-references

| Topic | File |
|-------|------|
| Concurrency mechanics, agent-id resolution, `renumber_p`, dogfood | `docs/guides/multi-agent-parallel-sessions.md` |
| Coordinator + specialist context allocation, token tiers | `docs/guides/multi-agent-context-routing.md` |
| Managed Agents API mapping (deferred, P33) | `docs/guides/managed-agents-integration.md` |
| Section 0 non-negotiables that apply equally to all agents | `docs/sop/claude-agent-sop.md` Section 0 |
| Backend-substituted (gateway) sessions | `docs/sop/claude-agent-sop.md` §15.5 |
| Compliance enforcement | `docs/sop/compliance-checklist.md` Section 11 |
| Sibling-worktree wipe gotcha | `docs/agent-memory/gotchas/2026-05-02_solo_worktree-uncommitted-wipe.md` |
