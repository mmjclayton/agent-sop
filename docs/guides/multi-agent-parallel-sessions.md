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

The refresh is a pure function of `docs/recent-work/*.md`. Any agent regenerating the section from the same directory contents produces the same output. Two agents running `/update-sop` Step 8b in separate worktrees with identical directory states write byte-identical rollups. Git merges either side's rollup silently because they're equal.

When directories diverge (each agent added a file the other doesn't have yet), the merge produces a textual conflict inside the sentinel block — each agent's rollup is correct for its own view but different from the other's. Resolution is mechanical and canonical: `git checkout --ours CLAUDE.md` then `bash scripts/refresh-rollup.sh` then `git add CLAUDE.md && git commit`. The regenerated rollup reflects both agents' new entries because the merged `docs/recent-work/` directory contains both files. The 2026-04-19 dogfood run observed this exact pattern on merges 2 and 3; both resolved in under 30 seconds each.

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

## 5. Commit-range partitioning

Three routines need to identify "which commits belong to this session": `/update-sop` Step 3b (secondary-tracker reconciliation), `/update-sop` Step 11 (hard-block check), and `/restart-sop` Step 4 (drift guard). All three use the same rule: `git merge-base <default-branch> HEAD..HEAD`.

### Why merge-base

Each agent in a parallel session owns its own branch on its own worktree. Its new commits live between `merge-base(main, HEAD)` and `HEAD`. Anything before the merge-base is shared history (possibly another agent's work already merged to main). Anything after is this agent's own.

This partitions cleanly without any explicit agent-identity tagging in commit messages, git config, or trailers. The git data model already provides per-agent scope via the branch.

### Default branch detection

```bash
default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/@@')
```

`origin/HEAD` is a symbolic-ref that points to the default branch on the remote. Most clones set it automatically; `git remote set-head origin -a` re-detects it. Fallbacks:

1. `origin/HEAD` symbolic-ref (preferred)
2. `origin/main` if that ref exists
3. `origin/master` if that ref exists
4. `origin/develop` if that ref exists
5. Empty range (no remote, or no recognisable default) — all three consumer steps become no-ops

### Shared snippet

```bash
resolve_session_commit_range() {
  local default_branch
  default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/@@')
  if [ -z "$default_branch" ]; then
    for candidate in origin/main origin/master origin/develop; do
      if git rev-parse --verify "$candidate" >/dev/null 2>&1; then
        default_branch="$candidate"
        break
      fi
    done
  fi
  if [ -z "$default_branch" ]; then
    printf ''
    return
  fi

  local base head_sha
  base=$(git merge-base "$default_branch" HEAD 2>/dev/null)
  head_sha=$(git rev-parse HEAD 2>/dev/null)
  if [ -z "$base" ] || [ "$base" = "$head_sha" ]; then
    printf ''
    return
  fi
  printf '%s..HEAD' "$base"
}
```

### Behaviour by scenario

| Scenario | Default branch | `SESSION_RANGE` |
|----------|----------------|-----------------|
| Agent on `feature/foo`, branched from `main`, 3 commits | `origin/main` | `<base>..HEAD` (3 commits) |
| Agent on `main` directly (solo mode, no branching) | `origin/main` | empty (`base == HEAD`) |
| Agent on `main`, one commit ahead of `origin/main` | `origin/main` | `origin/main..HEAD` (1 commit) |
| No remote configured | none | empty |
| Freshly initialised repo, no commits | none | empty |
| On a detached HEAD at an old commit | `origin/main` | `<base>..HEAD` (range valid) |

In all "empty range" cases, consumer steps skip cleanly. No false positives, no false negatives, no need for special-casing in the main flow — guard with `if [ -n "$SESSION_RANGE" ]`.

### Why not commit-author or trailers

Alternatives considered and rejected:

- **`git log --author=`:** requires each agent to set a distinct git author name. Fragile — humans share global git config, most agents would use the same committer identity.
- **Commit trailers (`Agent: a7c3f2`):** requires every commit command in every agent's workflow to inject a trailer. Easy to forget on manual commits. No fallback.
- **Last N commits:** old `/restart-sop` behaviour. Works for single-agent but mixes sibling agents' finding IDs in parallel mode, producing false-positive drift reports.

Merge-base requires no discipline beyond the existing worktree+branch workflow. Worktrees already mandate separate branches; merge-base leverages that structure for free.

### Cross-references

- `.claude/commands/update-sop.md` Step 0a (defines `SESSION_RANGE`), Step 3b (consumes it), Step 11 (consumes it)
- `.claude/commands/restart-sop.md` Step 0c (defines `SESSION_RANGE`), Step 4 (consumes it)

## 6. P-number collisions and the `renumber_p` helper

Backlog.md P-numbers are sequential and non-reusable (core SOP Section 9). When parallel agents discover new work items before either merges to main, they can independently pick the same next integer. `/update-sop` Step 2a detects the collision by diffing P-number headings on the branch against the default branch; the collision is hard-blocked with a specific renumber command.

Rather than auto-renumber, `/update-sop` reports and the agent runs a shell helper. Auto-renumber is deferred because the renumber touches too many surfaces (headings, body references, filenames in three directories, rollup lines, build plan Batch Log entries) to apply safely without human review.

### When collisions happen

| Scenario | Collision? |
|----------|-----------|
| Agent A on feat/a adds P50 at T1; agent B on feat/b adds P50 at T2; A merges to main first; B runs /update-sop | Yes — B's P50 overlaps main's P50 with different content |
| Both agents pick P50 for the same item (e.g. same refactor the user asked both to do) | Detected, but titles match — treated as a no-op by the heuristic |
| Agent A ships P50 and merges; agent B pulls main, then adds P51 fresh | No — B is strictly above main_max |
| Agent branches from main one day, works offline, returns after main advanced past their local P-number | Yes — exactly the collision case |

### The helper

Paste this into the shell in the affected worktree and run it per collision surfaced by Step 2a:

```bash
renumber_p() {
  local old=$1 new=$2
  if [ -z "$old" ] || [ -z "$new" ]; then
    echo "usage: renumber_p <old-pnum> <new-pnum>"
    return 1
  fi

  echo "Renumber P${old} → P${new}"

  # Rename files in per-entry directories where filenames encode the P-number
  for dir in docs/recent-work docs/agent-memory/decisions docs/agent-memory/gotchas; do
    [ -d "$dir" ] || continue
    for old_path in "$dir"/*_p${old}-*.md "$dir"/*_p${old}.md; do
      [ -f "$old_path" ] || continue
      local new_path
      new_path=$(printf '%s' "$old_path" | sed "s/_p${old}-/_p${new}-/g; s/_p${old}\\.md\$/_p${new}.md/")
      git mv "$old_path" "$new_path"
    done
  done

  # Body substitution via perl (cross-platform word boundaries)
  local files
  files=$(find Backlog.md CLAUDE.md docs/feature-map.md docs/build-plans \
          docs/recent-work docs/agent-memory/decisions docs/agent-memory/gotchas \
          -type f -name '*.md' 2>/dev/null)
  [ -n "$files" ] && perl -i -pe "s/\\bP${old}\\b/P${new}/g" $files

  echo "Done. Review with: git diff"
  echo "Then run /update-sop again; the collision check will pass."
}
```

### Review before commit

Always run `git diff` after `renumber_p` and verify:

1. All references changed are P-number references (not incidental `P${old}` substrings in prose)
2. Filenames renamed correctly (check with `git status`)
3. No references survived in older archived files that shouldn't change

If any incidental match is wrong, fix by hand before the next `/update-sop` run.

### Why not auto-renumber

- Filename-in-slug coupling: `2026-04-18_a7c3f2_p50-fix-tonnage.md` encodes the P-number in the filename. Auto-rename via `git mv` plus body substitution requires traversing three directories.
- Prose-reference risk: an Archived decision may mention "P50 was superseded by P60". Mechanical substitution could corrupt historical narrative.
- Commit-message references: git log messages mentioning the old P-number are immutable (except via history rewrite). Renaming doesn't update them.

Ship the detection now; defer auto-renumber until dogfood surfaces whether the manual helper is too frictional.

### Cross-references

- `.claude/commands/update-sop.md` Step 2a (detection + block)
- Core SOP Section 9 (P-number assignment rules)

## Further sections (placeholder)

The remaining mechanics are added to this guide as their batches ship:

- Migration command (Batch 1.6)
- Dogfood protocol results (Batch 1.7)
