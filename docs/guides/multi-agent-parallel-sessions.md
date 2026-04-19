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

## 2. Directory-per-entry structure

The single biggest source of merge conflicts between parallel agents is concurrent appends to narrative sections — especially prepends to `CLAUDE.md` Recent Work and appends to `docs/agent-memory.md` Decisions and Gotchas. Phase 1 moves those sections to per-entry directories:

```
docs/
  recent-work/
    YYYY-MM-DD_<agent-id>_<slug>.md
    README.md
    archive/
  agent-memory.md                  (narrative only: In-Flight, Completed, Preferences, Archived)
  agent-memory/
    decisions/
      YYYY-MM-DD_<agent-id>_<slug>.md
      README.md
      archive/
    gotchas/
      YYYY-MM-DD_<agent-id>_<slug>.md
      README.md
      archive/
```

Each directory's `README.md` documents filename convention, file format, and archive rules. Files in each directory are independent — two agents writing different files on the same date with different agent-ids produce no merge conflict because filenames are unique.

### Merge test

Scenario: Agent A on branch `feat/a` writes `2026-04-19_a7c3f2_fix-tonnage-bug.md`; Agent B on branch `feat/b` writes `2026-04-19_1e7aa9_scroll-jank-fix.md`. Both merge to main. Git sees two unrelated file additions and merges without conflict. Verified in Batch 1.2.

## 3. Rollup in CLAUDE.md

The `## Recent Work (rollup)` section of CLAUDE.md is a derived summary of `docs/recent-work/`, regenerated by `/update-sop` Step 8b. It uses sentinel markers:

```markdown
## Recent Work (rollup)

<!-- recent-work-rollup:start -->
*Auto-generated from `docs/recent-work/`. Last refreshed: YYYY-MM-DD.*

- 2026-04-19 `solo`: P43 Batch 1.2 — directory structure shipped
- 2026-04-18 `a7c3f2`: fix tonnage edge case
- 2026-04-17 `reviewer`: refactor auth middleware
<!-- recent-work-rollup:end -->
```

### Why it converges

The refresh is a pure function of `docs/recent-work/*.md`. Any agent regenerating the section from the same directory contents produces the same output. Two agents running `/update-sop` Step 8b in separate worktrees with identical directory states write byte-identical rollups. Git merges either side's rollup silently because they're equal. If the directories diverge (each agent added a file the other doesn't have yet), the second merge includes both new files, and the next `/update-sop` regenerates the rollup reflecting both.

### Why not edit by hand

Hand edits to the rollup get overwritten on the next `/update-sop`. Directory contents are the source of truth. If a rollup entry is wrong, fix the corresponding file in `docs/recent-work/` and re-run `/update-sop`.

## 4. Filename convention

All three directories (`docs/recent-work/`, `docs/agent-memory/decisions/`, `docs/agent-memory/gotchas/`) share one convention:

```
YYYY-MM-DD_<agent-id>_<slug>.md
```

| Field | Format | Allowed characters |
|-------|--------|--------------------|
| Date | `YYYY-MM-DD` | digits + hyphen |
| Agent-id | per `resolve_agent_id` | alphanumeric + hyphen; no underscore |
| Slug | kebab-case, max ~50 chars | lowercase alphanumeric + hyphen; no underscore, no leading/trailing hyphen |

Field separator is `_` (underscore). Within-field separator is `-` (hyphen). This distinction lets us parse filenames unambiguously without constraining dates or slugs to be single tokens.

### Slug recommendations

- Include P-number and batch where relevant: `p43-batch-1-2-directory-structure`
- For bug fixes: `fix-<what>-<where>`: `fix-tonnage-edge-case`
- For refactors: `refactor-<what>`: `refactor-auth-middleware`
- Keep under ~50 chars — shell tab-completion and `ls` output readable

### Agent-id validation

`resolve_agent_id` must emit an id containing only `[a-zA-Z0-9-]`. The hash fallback (`sha256(path)[:6]`) is hex-only and always valid. Env var and file overrides are validated: any whitespace or underscore is rejected with a warning; the agent falls through to the next precedence level.

## Further sections (placeholder)

The remaining mechanics are added to this guide as their batches ship:

- Commit-range partitioning (Batch 1.3)
- P-number renumber-on-merge (Batch 1.4)
- Migration command (Batch 1.6)
- Dogfood protocol results (Batch 1.7)

Each cross-links back to the relevant step in `.claude/commands/update-sop.md` and `.claude/commands/restart-sop.md`.
