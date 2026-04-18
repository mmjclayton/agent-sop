# Phase 1 — Parallel Sessions

Status: Planning

---

## Problem

The Agent SOP today assumes a single agent per project. `/update-sop` writes to shared files with patterns that guarantee merge conflicts when two agents end sessions in the same window:

| File | Write pattern | Conflict surface |
|------|---------------|------------------|
| `CLAUDE.md` Recent Work | **prepend** | Always conflicts on second writer |
| `docs/agent-memory.md` Decisions/Gotchas | append in narrative section | Conflicts on same-line or near-line appends |
| `docs/feature-map.md` `Last updated` header | in-place edit | Last-write-wins silently |
| `project_resume.md` | **overwrite** | Agents stomp each other |
| Secondary trackers (Step 3b) | implicit commit range | Agent A sees agent B's in-flight IDs as unreconciled |
| `/restart-sop` Step 4 drift guard | greps last 10 commits | No author partitioning |
| `Backlog.md` P-numbers | sequential assignment | Collide if agents discover new items simultaneously |

Section 0 "Multi-agent contention" today mandates sequential merges with human conflict resolution for documentation files. That breaks when 3-5 Claude Code terminal instances run in parallel on different worktrees with no human co-ordinating merges.

---

## Scope

| Batch | What | Priority |
|-------|------|----------|
| 1.1 | Agent-ID detection + config field | P0 |
| 1.2 | Directory-per-entry for Recent Work, Decisions, Gotchas + CLAUDE.md rollup | P0 |
| 1.3 | Commit-range partitioning (Step 3b, Step 11, /restart-sop Step 4) | P0 |
| 1.4 | P-number renumber-on-merge | P1 |
| 1.5 | Core SOP rewrites + compliance checks M1-M5 | P0 |
| 1.6 | Migration command `/update-sop --migrate-to-multi-agent` | P1 |
| 1.7 | Dogfood on hst-tracker (3 parallel worktrees, full /update-sop cycle) | P0 |

---

## Architecture

### Agent identity

Three-level precedence:
1. `CLAUDE_AGENT_ID` env var (highest)
2. `.sop-agent-id` file at worktree root
3. `sha256(git rev-parse --show-toplevel)[:6]` (default)

Solo override: when `git worktree list | wc -l` is 1 and no override is set, id is literal `solo`.

Rationale: worktree path is the isolation unit Matt uses; hash is deterministic per-worktree and conflict-proof without co-ordination; env/file overrides give humans meaningful names (`reviewer`, `refactor`); `solo` keeps single-agent projects readable.

### File layout (post-migration)

```
Backlog.md                              (unchanged — entries already per-P-number)
CLAUDE.md                               (Recent Work replaced by rollup section)
docs/
  recent-work/                          (new)
    YYYY-MM-DD-<agent-id>-<slug>.md
    archive/                            (entries older than 90 days)
  agent-memory.md                       (narrative only: In-Flight, Completed, Archived, Preferences)
  agent-memory/                         (new)
    decisions/
      YYYY-MM-DD-<agent-id>-<slug>.md
      archive/
    gotchas/
      YYYY-MM-DD-<agent-id>-<slug>.md
      archive/
  feature-map.md                        (Last-updated header becomes derived)
  build-plans/
    phase-N-*.md                        (Batch Log: strictly line-delimited entries with agent-id)
~/.claude/projects/[hash]/memory/
  project_resume_<agent-id>.md          (per-agent snapshot)
  project_resume_INDEX.md               (one-liner per agent, advisory)
```

### Commit-range partitioning

Reconciliation range across all three consumers (Step 3b, Step 11, /restart-sop Step 4):

```bash
BASE=$(git merge-base "$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/@@' 2>/dev/null || echo origin/main)" HEAD)
git log "$BASE..HEAD" --format='%s'
```

- Naturally partitions: each agent's worktree+branch owns its own commits since branching from main.
- No author tags, trailers, or git config required.
- Degrades gracefully on `main` directly (empty range, no-op).
- Works when default branch is `master`, `develop`, etc.

### Merge-time P-number reconciliation

`/update-sop` Step 3 pre-check:

```bash
git fetch origin main --quiet
MAIN_MAX=$(git show origin/main:Backlog.md | grep -oE '^### P[0-9]+' | grep -oE '[0-9]+' | sort -n | tail -1)
LOCAL_NEW=$(grep -oE '^### P[0-9]+' Backlog.md | grep -oE '[0-9]+' | sort -n)
# If any LOCAL_NEW <= MAIN_MAX and was not present on main, renumber
```

Grep-sweep updates all references (Backlog, feature-map, CLAUDE.md rollup, recent-work/, decisions/, gotchas/, build plans). Preserves Section 9 "never reuse" rule.

### CLAUDE.md rollup

Derived summary that replaces prepend-semantic Recent Work:

```markdown
## Recent Work (rollup)

*Auto-generated summary of `docs/recent-work/`. Last refreshed: YYYY-MM-DD by agent <id>.*

### Week of 2026-04-19
- 2026-04-19 <agent-a>: P43 Batch 1.1 shipped — agent-id detection (commit [hash])
- 2026-04-19 <agent-b>: P43 Batch 1.2 shipped — directory extractions (commit [hash])

### Week of 2026-04-12
...
```

- Rollup is a pure function of directory contents + cutoff date. Order-of-rebuild produces identical output.
- `/update-sop` refreshes on every run; last writer wins is fine because output is derived.
- Compliance check M5 flags if rollup is >7 days stale.

---

## Key Decisions Locked In

- [LOCKED] Agent-ID = `sha256(worktree-path)[:6]` with env-var / file override precedence
- [LOCKED] `project_resume_<agent-id>.md` per-agent; `solo` default for single-agent
- [LOCKED] Directory-per-entry for Recent Work, Decisions, Gotchas — not inbox, not CRDT
- [LOCKED] CLAUDE.md Recent Work becomes rollup section (derived from directory)
- [LOCKED] Single format for single-agent and multi-agent projects — migration, not dual-path
- [LOCKED] Commit-range partitioning via `git merge-base main HEAD..HEAD`, not author trailers
- [LOCKED] Build in agent-sop first, dogfood on hst-tracker second
- [LOCKED] Single P43 in new Phase 1 (not decomposed into P43-P47)
- [LOCKED] P-number collision handled at merge-time (renumber on branch), not reservation
- [LOCKED] Append-only files keep "accept both" merge rule; human-resolves kept for code files only

---

## Batch 1.1 — Agent-ID detection + config field

**Files touched:**
- `.claude/commands/update-sop.md` (new Step 0: agent-id resolution)
- `.claude/commands/restart-sop.md` (new Step 0b: agent-id resolution)
- `docs/templates/agent-sop-config-template.json` (new fields: `multi_agent`, `agent_id_override`)
- `docs/guides/multi-agent-parallel-sessions.md` (new guide — agent-id section)
- `setup.sh` (propagate new config fields)

**Acceptance criteria:**
- Both slash commands expose `$AGENT_ID` shell variable via the precedence order
- Config schema documented at `docs/templates/agent-sop-config-template.json`
- Override via `CLAUDE_AGENT_ID=foo` works end-to-end
- Override via `.sop-agent-id` file at worktree root works end-to-end
- `solo` default activates when `git worktree list | wc -l` = 1 and no override
- Unit scenario documented in the guide: hash, env-var, file-override, solo

---

## Batch 1.2 — Directory-per-entry extractions + rollup

**Files touched:**
- `docs/sop/claude-agent-sop.md` (Section 3 agent-memory.md structure; Section 3 CLAUDE.md rollup section)
- `docs/templates/claude-md-template.md`, `claude-md-template-code.md`, `agent-memory-template.md`
- `.claude/commands/update-sop.md` (Steps 5 and 8 rewritten for directory writes; rollup refresh added)
- `.claude/commands/restart-sop.md` (Steps 2-3 updated to read rollup primarily)
- `docs/guides/multi-agent-parallel-sessions.md` (directory structure + rollup sections)
- `docs/sop/compliance-checklist.md` (new directory-existence checks; agent-memory.md narrative-only rule)
- agent-sop's own: `CLAUDE.md` Recent Work extraction, `docs/agent-memory.md` Decisions+Gotchas extraction, new `docs/recent-work/`, `docs/agent-memory/decisions/`, `docs/agent-memory/gotchas/` directories

**Acceptance criteria:**
- `/update-sop` writes session entries to new directories with correct filename pattern (`YYYY-MM-DD-<agent-id>-<slug>.md`)
- `/restart-sop` reads CLAUDE.md rollup by default; reads directory files directly only if rollup `Last refreshed` is >7 days old
- CLAUDE.md stays under the 300-line code-project limit / 200-line non-code limit
- agent-sop itself migrated as part of this batch — no content lost (git diff proves every extracted entry lands in a file)
- Merge test: two agents creating entries on the same date with different slugs produce no git conflict (filenames differ)

---

## Batch 1.3 — Commit-range partitioning

**Files touched:**
- `.claude/commands/update-sop.md` (Step 3b enumeration; Step 11 hard-block range)
- `.claude/commands/restart-sop.md` (Step 4 drift guard range)
- `docs/guides/multi-agent-parallel-sessions.md` (commit-range section with the shared snippet)

**Acceptance criteria:**
- All three consumers use identical range-resolution logic (single shared snippet, copied into each command body)
- Works when agent is on `main` directly (empty range → no-op, no error)
- Works when default branch is `master`, `develop`, or custom
- Documented scenario: 3 agents with 3 branches, each `/update-sop` reconciles only its own branch's finding IDs and surfaces only its own drift on `/restart-sop`

---

## Batch 1.4 — P-number renumber-on-merge

**Files touched:**
- `.claude/commands/update-sop.md` (Step 3 pre-check: fetch + compare + renumber)
- `docs/guides/multi-agent-parallel-sessions.md` (P-number collision section)

**Acceptance criteria:**
- Script detects overlap between local new P-numbers and `origin/main` P-numbers
- Renumbers in-place: Backlog.md, feature-map.md, CLAUDE.md rollup entries, recent-work/, decisions/, gotchas/, build plan Batch Log entries
- Surfaces the renumber action in Step 11 report ("P50 → P53 to avoid collision with main's P50")
- No-op when no overlap
- Does not trigger when agent is on `main` directly

---

## Batch 1.5 — Core SOP rewrites + compliance checks

**Files touched:**
- `docs/sop/claude-agent-sop.md`:
  - Section 0 "Multi-agent contention" — rewritten: worktree + branch + directory-per-entry mechanics; drop human-resolves fallback for tracking files; keep for code files
  - Section 1 — new directories listed; `project_resume_<id>.md` pattern documented
  - Section 3 — file structure specs updated (agent-memory.md narrative-only; CLAUDE.md rollup section)
  - Section 15.4 — "Run strictly sequentially" clarified as benchmark-only
- `docs/sop/compliance-checklist.md` — new Section 11 Multi-agent: M1-M5
- `.claude/agents/sop-checker.md` — updated to run M1-M5
- `docs/guides/multi-agent-context-routing.md` — cross-reference new parallel-sessions guide

**Compliance check definitions:**
- **M1 (Critical, 10pts):** Agent-id resolvable when `multi_agent` is `auto` or `on`. Fails if no env var, no file, and repo is not a git worktree.
- **M2 (Important, 5pts):** Directory-per-entry structure exists (`docs/recent-work/`, `docs/agent-memory/decisions/`, `docs/agent-memory/gotchas/`) OR project is explicitly single-agent legacy (`multi_agent: off`).
- **M3 (Important, 5pts):** Commit-range partitioning uses `git merge-base main HEAD..HEAD` in all three consumer steps. Grep-verifiable in `.claude/commands/`.
- **M4 (Important, 5pts):** Per-agent `project_resume_<id>.md` files exist in local memory dir. `solo` acceptable for single-agent.
- **M5 (Recommended, 2pts):** CLAUDE.md rollup refreshed within 7 days. Reads `Last refreshed:` line from rollup section.

**Acceptance criteria:**
- Core SOP instruction count still under 200 hard ceiling (Rule 5)
- sop-checker agent updated with new phase for M1-M5
- Compliance summary table totals updated (deltas calculated at ship time)
- Version markers bumped on all touched pristine-replica files

---

## Batch 1.6 — Migration command

**Files touched:**
- `.claude/commands/update-sop.md` (new flag `--migrate-to-multi-agent` with dry-run section)
- `docs/guides/multi-agent-parallel-sessions.md` (migration section)

**Acceptance criteria:**
- Flag runs mechanical extraction: CLAUDE.md Recent Work → `docs/recent-work/`, agent-memory.md Decisions → `docs/agent-memory/decisions/`, agent-memory.md Gotchas → `docs/agent-memory/gotchas/`
- Filename pattern for extracted historical entries uses original date and the migrating agent's id (e.g. `2026-04-17-solo-p41-readme-rewrite.md`)
- Replaces extracted sections with rollup + pointer
- Dry-run mode lists exact file writes without touching disk
- Requires clean working tree (refuses with mixed changes)
- Idempotent: re-run is a no-op
- Git reflog is the safety net for accidental runs
- agent-sop runs cleanly against itself as part of this batch — zero content loss verified by line count + spot-check

---

## Batch 1.7 — Dogfood on hst-tracker

**Protocol:**

1. `cd ~/Projects/hst-tracker && /update-agent-sop` to pull new artefacts
2. Commit in hst-tracker if artefacts changed
3. `/update-sop --migrate-to-multi-agent --dry-run` then real run
4. Commit migration separately (distinct from any feature work)
5. Create 3 worktrees with mutually exclusive task scope:
   - `git worktree add ../hst-a feature/parallel-test-a`
   - `git worktree add ../hst-b feature/parallel-test-b`
   - `git worktree add ../hst-c feature/parallel-test-c`
6. Matt opens 3 Claude Code sessions (one per worktree)
7. Each session runs `/restart-sop` then completes a pre-assigned task from Backlog (file sets must not overlap)
8. Each session runs `/update-sop` independently at session end
9. Matt merges branches sequentially to main:
   - `git checkout main && git merge feature/parallel-test-a` → expect clean
   - repeat for b, c → expect clean
10. Verify:
    - Each agent's entries appear in `docs/recent-work/`, `docs/agent-memory/decisions/`, `docs/agent-memory/gotchas/` with correct agent-id in filename
    - CLAUDE.md rollup reflects all three (last writer wins is fine because derived)
    - `~/.claude/projects/[hash]/memory/` has three `project_resume_*.md` files
    - No git conflict messages on any of the three merges
11. Any gap surfaced: log to `docs/benchmark/parallel-dogfood-log.md`, fix in agent-sop, re-sync via `/update-agent-sop`, re-run the dogfood

**Acceptance criteria:**
- Zero manual conflict resolution across 3 sequential merges
- Per-agent directory entries intact and correctly named
- CLAUDE.md rollup current
- Three `project_resume_*.md` files present
- Dogfood log published (even if empty) as evidence

---

## Batch Log

*Append-only. Format: `- YYYY-MM-DD <agent-id>: Batch N.X — description. Commit [hash] or PR #N.`*

(empty — planning phase)

---

## Deploy Checklist

Before marking Phase 1 shipped:

- [ ] All 7 batches shipped
- [ ] agent-sop migrated to new format (Recent Work, Decisions, Gotchas directories populated)
- [ ] hst-tracker dogfood pass: 3 parallel worktrees, 3 `/update-sop` runs, 3 sequential merges, 0 manual conflict resolution
- [ ] Compliance checks M1-M5 wired into sop-checker; summary table totals correct
- [ ] README updated to cover parallel-sessions feature
- [ ] `/update-agent-sop` baselines refreshed for all touched pristine-replica files
- [ ] Core SOP instruction count verified under 200 hard ceiling (Rule 5)
- [ ] Owner review and verification

---

## Risk Register

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Rollup derivation diverges across agents | Medium | Low | Rollup is pure function of directory contents + cutoff; all agents produce identical output |
| Directory files explode over time | Low | High | Archive threshold: entries older than 90 days move to `archive/` subdirectory (pattern mirrors Backlog archive rule) |
| CLAUDE.md rollup goes stale | Low | Medium | M5 compliance check flags it; `/update-sop` refreshes on every run |
| P-number renumber misses a reference | Medium | Low | Grep-sweep covers all known surfaces; audit step in Step 11 report |
| Agent-id hash collision | High | Very low | sha256 collision space; env/file override available if ever triggered |
| Migration loses content | High | Low | Dry-run mode + clean-tree requirement + git reflog backstop |
| hst-tracker dogfood exposes unfixable design flaw | High | Medium | Batch 1.7 is explicit gate; fix in agent-sop, re-dogfood before Phase 1 ships |
| Section 0 rewrite confuses single-agent users | Low | Medium | New guide is primary reference; Section 0 stays short with link |
| Rule 5 instruction-budget breach from Section 0 rewrite | Medium | Medium | Measure before and after Batch 1.5; push detail to guide if needed |

---

## Open Questions

*Answered questions stay here marked `[RESOLVED - YYYY-MM-DD: answer]`.*

- 2026-04-19: Should rollup cadence be weekly or monthly for grouping? [RESOLVED - 2026-04-19: weekly groups, with optional monthly compaction later if directory grows past ~200 entries]
- 2026-04-19: Is `solo` hard-coded or configurable? [RESOLVED - 2026-04-19: hard-coded literal; users wanting a named id set `CLAUDE_AGENT_ID` or `.sop-agent-id`]
- 2026-04-19: Does migration preserve original commit-date metadata? [RESOLVED - 2026-04-19: yes, via filename `YYYY-MM-DD-` prefix parsed from existing entry dates; file mtime irrelevant]
