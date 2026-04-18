<!-- SOP-Version: 2026-04-19 -->
# Multi-Agent Parallel Sessions

Applies when multiple Claude Code terminal instances work on the same repo in separate `git worktree` checkouts, each running `/update-sop` and `/restart-sop` independently without human co-ordination.

This guide is distinct from `multi-agent-context-routing.md` — that guide covers token-efficient context selection when delegating to sub-agents within one session. This guide covers the concurrency mechanics that prevent tracking-file conflicts when three to five independent Claude Code sessions each ship work and update the SOP-managed files.

Shipped incrementally across the batches of Phase 1 (P43). Sections are added as batches ship; see `docs/build-plans/phase-1-parallel-sessions.md` for the roadmap.

## When to use

Use this guide when:
- Three or more Claude Code sessions run concurrently on the same repo via `git worktree`
- Each session may run `/update-sop` at any time, in any order
- No human is co-ordinating merges between agents

Solo agent projects: set `multi_agent: "off"` in `agent-sop.config.json` (or rely on the `solo` auto-detect) to keep the simpler single-agent file patterns. Everything in this guide still works with one agent — the `solo` agent-id is just one among potentially many.

## 1. Agent identity

Every agent needs a stable identity that appears in filenames (`docs/recent-work/YYYY-MM-DD-<agent-id>-<slug>.md`), in per-agent `project_resume_<agent-id>.md`, and in commit-range partitioning routines. The agent-id must be deterministic, require no central co-ordination, and remain stable across sessions in the same worktree.

### Resolution precedence

The resolution is ordered from most explicit to most automatic. The first match wins.

1. **`CLAUDE_AGENT_ID` environment variable.** Highest priority. Set in the terminal that launches Claude Code, or via a shell profile per-worktree (e.g. `direnv`, `.envrc`).
2. **`.sop-agent-id` file at the worktree root.** Plain text, single line, single token (no whitespace). **Gitignore this file** — committing it breaks merges because each worktree needs its own value but git tracks a single canonical path. Add `.sop-agent-id` to `.gitignore` (or to `.git/info/exclude` for a per-clone rule).
3. **`solo` default.** When `git worktree list` reports only one worktree and no override is set. Keeps single-agent projects readable and free of hash noise.
4. **Hash of worktree path.** `sha256(git rev-parse --show-toplevel)[:6]`. Deterministic per-worktree, no setup required. Used when parallel worktrees are active and no override is chosen.

### Which override to pick

| Scenario | Recommendation |
|----------|----------------|
| Single-agent project | No override. `solo` is the auto-default. |
| 2-3 agents with stable roles | `.sop-agent-id` with human names (`reviewer`, `refactor`, `qa`) |
| 3+ agents, ad-hoc tasks | No override — hash default is sufficient |
| Benchmark runs | `CLAUDE_AGENT_ID=bench-task-N` env var for scoring clarity |

### Configuration

`~/.claude/agent-sop.config.json` (user-global) or `.claude/agent-sop.config.json` (per-project, takes precedence if both exist):

```json
{
  "multi_agent": "auto",
  "agent_id_override": null
}
```

- `multi_agent`
  - `"auto"` (default) — detects parallel mode from `git worktree list` count
  - `"on"` — forces parallel conventions regardless of worktree count (useful for projects that intend to go parallel imminently)
  - `"off"` — forces single-agent conventions, id is literal `solo` regardless of worktree count
- `agent_id_override` — string or `null`. When set, takes precedence over env var and file. Rarely used; prefer env var or file.

### Shell snippet (canonical)

This snippet runs at the first step of both `/update-sop` and `/restart-sop`. Keep the two copies identical — changes here propagate to both.

```bash
resolve_agent_id() {
  if [ -n "${CLAUDE_AGENT_ID:-}" ]; then
    printf '%s' "$CLAUDE_AGENT_ID"
    return
  fi

  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null) || { printf 'solo'; return; }

  if [ -f "$root/.sop-agent-id" ]; then
    head -1 "$root/.sop-agent-id" | tr -d '[:space:]'
    return
  fi

  local count
  count=$(git worktree list 2>/dev/null | wc -l | tr -d '[:space:]')
  if [ "$count" = "1" ]; then
    printf 'solo'
    return
  fi

  if command -v shasum >/dev/null 2>&1; then
    printf '%s' "$root" | shasum -a 256 | cut -c1-6
  else
    printf '%s' "$root" | sha256sum | cut -c1-6
  fi
}

AGENT_ID=$(resolve_agent_id)
```

`$AGENT_ID` is available for all subsequent steps.

### Scenarios

**Single-agent project, one worktree, no overrides:** `AGENT_ID=solo`. All file patterns degrade to single-agent names — e.g. `project_resume_solo.md` — which remain readable.

**Two worktrees on the same repo, no overrides:** each session computes a different 6-char hash (paths differ). Their files never collide because filenames include the id.

**Three agents with role names:** each worktree has `.sop-agent-id` containing `reviewer`, `refactor`, or `qa`. Names are human-readable in filenames.

**Benchmark harness running 5 parallel task-agents:** each invocation sets `CLAUDE_AGENT_ID=bench-N` before launching Claude Code. Env var wins; file and hash are ignored.

**Not in a git repo:** `git rev-parse --show-toplevel` fails; falls through to `solo`. Non-git usage is supported for documentation-only test runs.

## Further sections (placeholder)

The remaining mechanics are added to this guide as their batches ship:

- Directory-per-entry structure (Batch 1.2)
- CLAUDE.md rollup refresh (Batch 1.2)
- Commit-range partitioning (Batch 1.3)
- P-number renumber-on-merge (Batch 1.4)
- Migration command (Batch 1.6)
- Dogfood protocol results (Batch 1.7)

Each will cross-link back to the relevant step in `.claude/commands/update-sop.md` and `.claude/commands/restart-sop.md`.
