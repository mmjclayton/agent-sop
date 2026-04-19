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

## Batch 1.2 — Directory-per-entry structure + rollup (specs and new-entry paths)

**Scope narrowed from original plan:** historical extraction of agent-sop's own Recent Work, Decisions, and Gotchas moves to Batch 1.6 (where the migration command ships and is tested on real historical content). Batch 1.2 establishes the structure, specs, and new-entry write paths only. Until 1.6, legacy sections in CLAUDE.md and agent-memory.md coexist with the new directories — the rollup displays newly written entries; the legacy section remains for pre-migration history.

**Files touched:**
- `docs/sop/claude-agent-sop.md` (Section 1 standard file set; Section 3 file structure specs — new directories, rollup, agent-memory.md narrative-only)
- `docs/templates/claude-md-template.md`, `claude-md-template-code.md`, `agent-memory-template.md`
- `.claude/commands/update-sop.md` (Step 5 writes Decisions/Gotchas to directories; Step 8 writes Recent Work to directory; new Step 8b refreshes rollup)
- `.claude/commands/restart-sop.md` (Step 2 reads per-agent resume file; Step 3 reads narrative + glances at recent directory entries)
- `docs/guides/multi-agent-parallel-sessions.md` (Section 2 directory structure, Section 3 rollup, Section 4 filename convention)
- `docs/sop/compliance-checklist.md` (directory-existence checks; agent-memory.md narrative-only structure)
- `docs/recent-work/README.md`, `docs/agent-memory/decisions/README.md`, `docs/agent-memory/gotchas/README.md` (new — explain purpose and filename convention)
- agent-sop's own `CLAUDE.md` (add rollup section with sentinels; keep legacy Recent Work until Batch 1.6)
- agent-sop's own `docs/agent-memory.md` (cutover note above legacy Decisions and Gotchas sections)

**Filename convention locked:**
- Pattern: `YYYY-MM-DD_<agent-id>_<slug>.md` (underscore is the field separator; hyphens allowed within fields)
- Slug: lowercase alphanumeric + hyphens, max ~50 chars, no underscores, no leading/trailing hyphens
- Agent-id: alphanumeric + hyphens, no underscores (enforced by resolve_agent_id validation)

**Acceptance criteria:**
- `/update-sop` Step 5 and Step 8 write new entries to the directories with correct filename pattern
- `/update-sop` Step 8b refreshes rollup via idempotent shell snippet between sentinel markers
- `/restart-sop` Step 2 reads per-agent `project_resume_<agent-id>.md`; falls back to `project_resume.md` for `solo`
- `/restart-sop` Step 3 reads agent-memory.md narrative + lists 10 most recent decision filenames as advisory
- Core SOP Section 3 describes the new directory structure authoritatively
- Three directory README.md files explain purpose and filename convention
- agent-sop's own CLAUDE.md has a rollup section with `<!-- recent-work-rollup:start -->` / `<!-- recent-work-rollup:end -->` sentinels (initially empty pending the first new entry)
- Merge test documented: two agents creating entries on the same date with different slugs produce no git conflict (verified in guide's Section 2)
- Compliance checklist updates reflect the structural shift (A1 Decisions/Gotchas requirements removed; new directory-existence checks added)

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

## Batch 1.4 — P-number collision detection + manual renumber helper

**Scope narrowed:** auto-renumber is deferred because the renumber surface (filenames in three directories, body references in archived narrative, rollup lines, Batch Log) is too broad to apply mechanically without human review. Batch 1.4 ships detection + hard-block + a shell helper the agent runs manually. Auto-renumber becomes a follow-up if dogfood shows the manual helper is frictional.

**Files touched:**
- `.claude/commands/update-sop.md` (new Step 2a: P-number collision detection + hard block)
- `docs/guides/multi-agent-parallel-sessions.md` (Section 6: collision mechanics + `renumber_p` shell helper)

**Acceptance criteria:**
- Step 2a detects P-numbers that exist on both this branch and the default branch with different content (heuristic: title line comparison)
- When a collision is detected, `/update-sop` prints the colliding P-numbers + the next free P-number on the default branch + the exact `renumber_p` commands to run; exits non-zero
- When no collisions exist, Step 2a is silent and `/update-sop` proceeds to Step 3
- When `git fetch origin` fails, Step 2a warns but does not block (degrade gracefully for offline work)
- `renumber_p` helper in the guide covers: heading + body references via `perl -i -pe '\\bP<old>\\b/P<new>/g'`, filename renames via `git mv` across recent-work/, decisions/, gotchas/
- Document `git diff` review step and why auto-renumber was deferred

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

- 2026-04-19 `solo`: Plan shipped — P43 Backlog entry, phase-1 build plan, CLAUDE.md priority update. Commit ed3ac49.
- 2026-04-19 `solo`: Batch 1.1 — agent-id detection + config field. Commit ad33ec3.
- 2026-04-19 `solo`: Batch 1.2 — directory-per-entry structure + CLAUDE.md rollup + seed recent-work entry. Commit 07a3d5f.
- 2026-04-19 `solo`: Batch 1.3 — commit-range partitioning via `git merge-base`. Commit c34c6ef.
- 2026-04-19 `solo`: Batch 1.4 — P-number collision detection + renumber helper. Commit 9237302.
- 2026-04-19 `solo`: Batch 1.5 — core SOP rewrites (Section 0, Section 6, Section 15.4) + compliance checks M1-M5. Commit a3dd828.
- 2026-04-19 `solo`: Batch 1.6 tooling — migrate-to-multi-agent.py + slash command + setup.sh update. Commit 788663a.
- 2026-04-19 `solo`: Batch 1.6 dogfood on agent-sop — 77 legacy entries extracted, legacy sections removed, rollup refreshed. Commit 15650c0.
- 2026-04-19 `solo`: Batch 1.7 playbook drafted — requires Matt-hands dogfood on hst-tracker with 3 parallel sessions. Deferred.

---

## Deploy Checklist

Before marking Phase 1 shipped:

- [x] All 7 batches shipped (Batch 1.7 playbook only — dogfood execution deferred)
- [x] agent-sop migrated to new format (Recent Work, Decisions, Gotchas directories populated — 77 entries extracted 2026-04-19)
- [ ] hst-tracker dogfood pass: 3 parallel worktrees, 3 `/update-sop` runs, 3 sequential merges, 0 manual conflict resolution (requires Matt-hands multi-session — see `docs/benchmark/parallel-dogfood-playbook.md`)
- [x] Compliance checks M1-M5 wired into sop-checker; summary table totals correct
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
