# Full Codebase Audit — agent-sop

**Date:** 2026-08-03
**Agent:** solo
**Scope:** Whole repository (268 tracked files, 1,062,211 bytes), `main` @ `3a9a347`
**Type:** Whole-codebase audit — not a per-ship gate artifact
**Method:** Six parallel review agents across four axes, findings independently verified by the coordinating agent

---

## Verification legend

| Mark | Meaning |
|------|---------|
| **[R]** | Reproduced — a failing case was executed and observed |
| **[V]** | Verified — confirmed by direct file/grep/code inspection by the coordinator |
| **[A]** | Agent-reported — measured by a review agent, not independently re-run |

Every finding marked [R] or [V] was checked by the coordinating agent against source. [A] findings are reported as received and flagged where confidence is lower.

---

## Executive summary

### The pattern that explains most findings

**agent-sop's gates are specified in prose and enforced in code, and the two have drifted — with the prose consistently stronger than the code.**

The SOP reads as a rigorously enforced system: three hard-blocking gates, a 602-line validator, a 94-check compliance scorer, agent-to-agent review with no human sign-off. Trace each gate to its execution arm and a substantial share resolve to text that no code reads.

This is not a novel diagnosis. The repo already wrote the guide for it — `docs/guides/cross-layer-rules.md` exists specifically to prevent "one logical rule, two runtimes, opposite answers", and `scripts/validate-state-transitions.sh:546-556` narrates a real production incident of exactly this shape (P66). The guide was never run against the repo that authored it.

### Headline numbers

| Measure | Value | Stated target | Status |
|---|---:|---|---|
| Instruction count, session start | 318 | ≤150 soft / 200 hard | **1.6× over ceiling** |
| Instruction count, session end | 361 | ≤150 soft / 200 hard | **1.8× over ceiling** |
| Instruction count, subagent | 379 | ≤150 soft / 200 hard | **1.9× over ceiling** |
| `claude-agent-sop.md` alone | 188 | ≤150 soft cap | **Over soft cap alone** |
| Session-start token cost | ~21,700 | "well under 2% of 1M" | **2.17% / 3.68% w/ own multiplier** |
| Tracked duplication | ~114 KB (~29-38k tokens) | Rule 2: one source of truth | — |
| Edit-fanout per representative change | 6-8 files | Rule 2 predicts 1-2 | — |
| Blocking defects found | 10 | — | 2 CRITICAL data-loss |

### Scale corrections

Two surface figures are misleading and worth stating up front:

- **The repo is 11 MB on disk but 1,062,211 bytes tracked** across 268 files. `.git` is 8.8 MB; `.archive/` (155 KB) is gitignored and was never tracked (`git log --all -- .archive` is empty). **[V]**
- **Commit activity is heavily front-loaded**: 92 commits in 2026-04, then 9 / 6 / 2 in May / July / August. This is a mature artefact in maintenance, not an active build. **[V]** That materially changes what "optimise" should mean — the highest-value work is correctness repair, not feature velocity.

---

## 1. What this codebase is

A **documentation-as-product library** defining Standard Operating Procedure for Claude Code agent sessions. The premise (`README.md:12`): Claude Code sessions are "stateful in principle and stateless in practice" — each session starts blind to what the last one shipped, decided, or learned.

The answer shipped is a fixed file set plus a fixed session workflow, with no daemon, database, or MCP server.

| Layer | Artefact | Role |
|---|---|---|
| **Normative** | `docs/sop/claude-agent-sop.md` (726 lines) | Six non-negotiable rules, file specs, session checklists, tag taxonomy |
| **Mechanics** | `docs/guides/` (7 files) | Multi-agent concurrency, context routing, cross-layer rules, hill-climbing |
| **Procedure** | `.claude/commands/` (5) | `/restart-sop`, `/update-sop`, `/update-agent-sop`, `/migrate-to-multi-agent`, `/finish` |
| **Enforcement** | `scripts/validate-state-transitions.sh` (602 lines) | Illegal transition blocking, reviewer-substance assertion, drift detection |
| **Distribution** | `setup.sh` (347 lines) + three-way SHA sync | Installs into consumer projects, pulls upstream without clobbering local edits |
| **Evidence** | `docs/benchmark/` | A/B framework, 12 task specs, 2 fixture suites, 5 rounds of results |
| **Templates** | `docs/templates/` (6) | Stamped into new consumer projects at install |

### The design bet

Enforcement is **agent-to-agent, not human-gated**. Three hard-blocks fire at session end:

1. **Step 1b** — a reviewer subagent must produce a findings artifact with concrete anchors (`file:42`, backticked symbols) or the session blocks
2. **Step 3c** — a validator rejects illegal Backlog status-tag transitions and `[SHIPPED]` without a Batch Log reference
3. **Step 3d** — drift detection compares P-numbers in commit messages against the declared in-flight item

No human approval step anywhere. This is a genuinely interesting design, and where it is implemented in code (3c, 3d) it works. The findings below concentrate where it is implemented in prose.

### The self-referential structure

The repo dogfoods its own SOP: its `CLAUDE.md`, `Backlog.md`, `docs/agent-memory/`, `docs/recent-work/` all follow the SOP it defines. This creates a structural tension the review kept surfacing:

- **Rule 1** ("never delete without a trace") biases toward accumulation
- **Rule 5** ("instruction budget ≤150, trim before adding") demands the opposite

The resolution — Rule 1 governs *tracking* documents, Rule 5 governs the *instruction* surface — is coherent, is what the repo actually practises, and **is never stated anywhere an agent reads**. See §3.4.

---

## 2. Blocking defects

Ten defects that break behaviour. Two are CRITICAL data-loss.

### 2.1 CRITICAL — `setup.sh --force` destroys live project state **[V code / [A] repro]**

`setup.sh:17-27` explicitly documents two tiers:

- *"per-project, customised"* — `CLAUDE.md`, `Backlog.md`, `docs/agent-memory.md`, `docs/feature-map.md`, `docs/build-plans/phase-0-foundation.md`
- *"pristine-replica SOP content — overwritten by /update-agent-sop"* — `docs/sop/*`, `docs/guides/*`

The implementation ignores the distinction entirely. `copy_if_missing` (`setup.sh:116-128`) and `write_if_missing` (`:132-144`) apply one unconditional `cp` to both tiers under `--force`:

```bash
copy_if_missing() {
    local src="$1"; local dest="$2"
    if [ -f "$dest" ] && [ "$FORCE" = false ]; then
        echo "  skip  $(basename "$dest") (already exists, use --force to overwrite)"
        return
    fi
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"          # <-- no backup, no confirm, no git-clean check
    echo "  create  $(basename "$dest")"
}
```

**Failure scenario:** a user follows the script's own end-of-run tip ("if this is a code project, re-run with `--code`"), adds `--force` believing it necessary, and a live `Backlog.md` — the SOP's declared single source of truth — is replaced with a blank `[bracket placeholder]` template. Unrecoverable if uncommitted.

**The safer pattern already exists in-repo:** `scripts/migrate-to-multi-agent.py` refuses to run on a dirty tree.

**Fix:** split `--force` semantics by tier. Pristine-replica paths keep force-overwrite (that is their purpose). For the per-project tier, either drop `--force` support or write a timestamped backup and print an explicit warning naming what was preserved.

### 2.2 CRITICAL — `migrate-to-multi-agent.py` silently drops entries **[A] reproduced by review agent**

Output filenames are `{date}_solo_{slug(title)}.md` with no existence check or collision detection. `path.write_text(content)` overwrites unconditionally (`:271, :284, :296, :313`).

Two distinct decisions/gotchas sharing a date and a title-derived slug map to the same path. The second write destroys the first with no warning and no non-zero exit — and `main()` reports `Extracted N entries` counting *processed* entries, not files persisted.

**Reported repro:** two `## Decisions Made (legacy)` bullets, same date, same opening sentence, different bodies. Output: `Extracted 2 entries`; `docs/agent-memory/decisions/` contains one file holding only the second decision.

The docstring's "Idempotent... re-running is safe" claim covers re-runs of identical content. It does not describe or guard this within-run collision.

**This violates Rule 1 inside the SOP's own migration tool**, on cross-session memory — the data the whole library exists to preserve.

**Fix:** group entries by target path before writing; on collision either disambiguate deterministically (`-2`, `-3`) or abort listing every colliding title. Given the data class, fail loudly by default.

### 2.3 CRITICAL — Step 1b triggers (b) and (c) have no execution arm **[V]**

`docs/sop/claude-agent-sop.md:410` states the strongest gate in the SOP:

> **b. SOP self-modification** — any edit to files that the SOP itself executes or instructs (SOP docs, reference agent definitions, slash commands, validators that gate other steps) [...] **SOP changes are load-bearing regardless of LOC** because the agent itself executes them.

Verified by grep:

| Check | Result |
|---|---|
| `grep -c 'self-modification' .claude/commands/update-sop.md` | **0** |
| `grep -c 'review_triggers' .claude/commands/update-sop.md` | **0** |
| `grep -cE 'docs/sop\|\.claude/commands\|\.claude/agents\|self.mod' scripts/validate-state-transitions.sh` | **0** |

`update-sop.md:127` implements trigger (a) only: *"If session diff is below threshold, skip — the item is small enough that self-eval suffices."*

**Consequence:** a 10-LOC edit to `docs/sop/claude-agent-sop.md` skips the reviewer turn — the precise case the SOP declares fires unconditionally.

**Worse, the skip token clears every downstream check.** Trace a `[Feature]` whose entire diff is `docs/sop/claude-agent-sop.md`:

| Layer | Path | Outcome |
|---|---|---|
| SOP trigger (b) | `claude-agent-sop.md:410` | Gate **fires** |
| SOP skip list | `:413` "Docs-only commits" | Skips (inline note says (b) overrides) |
| Skip declaration | `:416` enumerated set includes `docs-only` | Nothing forbids declaring it |
| `/update-sop` | `:127` below threshold | **Skip** |
| Validator | `validate-state-transitions.sh:571` regex match on token | **PASS** |
| Compliance S7 | `sop-checker.md:155` reads same token | **PASS** |

The validator performs **no path inspection whatsoever**. The SOP's one unconditional trigger is satisfied by a self-declared four-word token that no code verifies.

**Fix:** give the validator a pathspec check, or downgrade `:410`'s "regardless of LOC" to advisory prose. The current state markets a gate that does not exist.

### 2.4 HIGH — Validator fails silently on missing `--before-file` **[R]**

`scripts/validate-state-transitions.sh:441-455`:

```bash
resolve_before() {
  if [ -n "$BEFORE_FILE" ]; then
    [ -f "$BEFORE_FILE" ] && cat "$BEFORE_FILE"
    return                    # <-- inherits exit status of the && list
  fi
  ...
```

When the file is missing, `[ -f ]` fails, `cat` never runs, and the bare `return` inherits status 1. Called as a standalone statement (`resolve_before > "$TMP_BEFORE"`), that non-zero return triggers `errexit` before the intended "no before-state ... skipping" message at `:462`.

**Reproduced:**

```
$ bash scripts/validate-state-transitions.sh --before-file /nonexistent.md --after-file /nonexistent-after.md
exit=1  stdout_bytes=0  stderr_bytes=0
```

**Zero bytes on both streams.** This is the enforcement engine failing invisibly — the exact class documented in the repo's own gotcha at `docs/agent-memory/gotchas/2026-07-26_solo_pipefail-kills-the-error-message-before-it-prints.md`, in a code shape (`&&`-list return) that a grep-for-`grep|find|diff` audit would not catch.

**Fix:**

```bash
if [ -n "$BEFORE_FILE" ]; then
  if [ -f "$BEFORE_FILE" ]; then cat "$BEFORE_FILE"; fi
  return 0
fi
```

### 2.5 HIGH — `refresh-rollup.sh` dies silently, leaving the rollup stale **[R]**

`scripts/refresh-rollup.sh:52-53`:

```bash
TITLE=$(grep -m1 '^# ' "$f" | sed 's/^# //')
[ -z "$TITLE" ] && TITLE="(untitled)"      # <-- dead code
```

Unguarded pipe under `set -euo pipefail`. A `docs/recent-work/*.md` entry with no `# ` heading → `grep` exits 1 → pipefail propagates → `errexit` fires. Line 53, written specifically for this case, is unreachable.

**Reproduced** in an isolated directory with one good entry and one heading-less entry:

```
exit=1  stdout=0B  stderr=0B
CLAUDE.md rollup: unchanged (still "OLD")
```

This script runs in **mandatory `/update-sop` Step 8b** and `/migrate-to-multi-agent` Step 9. A single malformed entry silently breaks the rollup for every subsequent invocation until someone runs `bash -x` — which is precisely how the original P73 bug was found.

**Fix:** `TITLE=$( { grep -m1 '^# ' "$f" || true; } | sed 's/^# //')`, matching the guard style already used in `validate-state-transitions.sh:173`.

### 2.6 HIGH — `detect_trackers` is called but never defined **[V]**

`.claude/commands/update-sop.md:548`:

```bash
for tracker in $(detect_trackers); do  # same detection as Step 3b
```

`grep -rn "detect_trackers"` across the entire repo returns **exactly this one line** — the call site. Step 3b (`:268-277`) supplies an inline pipeline, not a reusable function.

The enclosing block is labelled **"Step 11: Reconciliation check (hard block)"** and contains `exit 1`. As written the loop body never executes. **A hard block that cannot fire.**

### 2.7 HIGH — "Definition of Done" is mandated but does not exist **[V]**

| Reference | Location |
|---|---|
| "Pay special attention to: **Definition of Done** — self-evaluation rubrics by task type" | `restart-sop.md:183` |
| Report "Which Definition of Done rubric applies to this task type" | `restart-sop.md:271` |
| "check your work against the relevant **Definition of Done** rubric in CLAUDE.md" | `update-sop.md:94` |

Counts: `claude-agent-sop.md` → **0**. `CLAUDE.md` → **0**. Referenced 4× in `restart-sop.md`, 3× in `update-sop.md`.

The CLAUDE.md structure spec (`claude-agent-sop.md:168-212`) never lists a `## Definition of Done` section, and Section 11's required-section rules never mention it. Only the two templates carry it.

**In agent-sop's own repo, `/update-sop` Step 1 is unsatisfiable.**

### 2.8 MEDIUM — `sop-checker.md` lost check S4 **[V]**

Bold headings in `.claude/agents/sop-checker.md`:

```
:108  **S1 — No secrets in committed files (Critical):**
:130  **S2 — Security guidance referenced (Important):**
:137  **S3 — No --dangerously-skip-permissions usage (Important):**
:141  **S5 — CI workflows invoking Claude Code are hardened (Critical, conditional):**
:144  **S6 — Read-only token posture for CI review workflows (Important, conditional):**
:147  **S7 — Gate integrity: validators unchanged in the range they gate (Important, conditional):**
```

**S4 is absent.** Its body — the memory-poisoning guard — is glued to the end of the S3 block at `:139` with no heading. `docs/sop/compliance-checklist.md:256` defines S4 canonically and it counts toward the advertised 94.

The auditing agent can never report S4 by ID. This is a direct consequence of the agent restating a checklist it is instructed to *read* (`sop-checker.md:15`).

### 2.9 MEDIUM — Five duplicate check IDs **[V]**

`docs/sop/compliance-checklist.md` has 94 rows but 89 unique IDs:

| ID | First definition | Second definition |
|---|---|---|
| `M1` | `:178` feature-map "Last updated header present" | `:302` multi-agent "Agent-id resolvable" |
| `M2` | `:179` "Shipped features section exists" | `:308` "Per-entry directory structure exists" |
| `M3` | `:180` "Roadmap section exists" | `:309` "Commit-range uses merge-base" |
| `M4` | `:186` "Backlog shipped items reflected here" | `:310` "Per-agent resume file exists" |
| `R1` | `:215` "File named exactly project_resume.md" | `:268` "Reviewer-turn gate honoured" |

The file self-describes as *"the canonical list of checks used by the SOP Compliance Checker agent"* (`:6`), and the agent reports findings by ID. **`FAIL: M3` is ambiguous.** `README.md:29` markets "M1-M6 checks" and "R1" by name.

`R1` additionally self-contradicts on the resume filename: `:215` requires *"File named exactly project_resume.md"* while `F6:60` and `M4:310` require `project_resume_<agent-id>.md`. A multi-agent project passes F6/M4 and fails R1 simultaneously.

### 2.10 MEDIUM — P53 shipped without a Batch Log entry **[V]**

`Backlog.md:1043` — `### P53 — /finish skill` is `[SHIPPED - 2026-04-29]`.

```
$ grep -c 'P53' docs/build-plans/phase-0-foundation.md docs/build-plans/phase-1-parallel-sessions.md
0
0
```

Both the SOP (`claude-agent-sop.md:499`) and `validate-state-transitions.sh` hard-block `[SHIPPED]` without a Batch Log reference. This evaded the check because **the validator only scans the working-tree diff** — past ships are never rechecked.

Related: P54 appears in `phase-1:321` but not `phase-0`; P47/P48 likewise. **Which build plan owns a batch is undefined once two phases are open.**

---

## 3. Axis (a) — Context and task performance

### 3.1 Rule 5 is breached in every realistic scenario **[V — independent count]**

Rule 5 (`claude-agent-sop.md:69-76`) is the flagship constraint:

> Any agent — primary, subagent, or custom — must operate under a total of **≤150 distinct instructions** across its combined context (this SOP, `CLAUDE.md`, agent definition files, rules files under `~/.claude/rules/`, and the invocation prompt). **200 is the absolute ceiling.**

Two independent counts were run using the rule's own method (numbered rules, checklist items, always/never/must statements, behaviour-defining table rows; excluding prose, examples, code blocks, headings):

| File | Coordinator count | Review agent (strict) |
|---|---:|---:|
| `docs/sop/claude-agent-sop.md` | **188** | 176 |
| `CLAUDE.md` | **101** | 99 |
| `.claude/commands/restart-sop.md` | **29** | 29 |
| `.claude/commands/update-sop.md` | **72** | 71 |
| `.claude/agents/sop-checker.md` | **90** | 89 |

Agreement within ~6%, exact on `restart-sop.md`. Both land inside the repo's own last recorded estimate of ~185-190 for the core SOP (`docs/recent-work/2026-04-19_solo_p43-readme-and-close-out.md:7`).

**Combined scenarios:**

| Scenario | Count | vs 200 ceiling |
|---|---:|---|
| Session start — SOP + CLAUDE.md + `restart-sop` | **318** | **1.6× over** |
| Session end — SOP + CLAUDE.md + `update-sop` | **361** | **1.8× over** |
| Subagent — SOP + CLAUDE.md + `sop-checker` | **379** | **1.9× over** |

`claude-agent-sop.md` alone (188) exceeds the 150 soft cap.

**This undercounts.** The stated method excludes section headings, but `update-sop.md` has **20** `## Step` headings and `restart-sop.md` has **6** — functionally checklist items an agent executes. **[V]**

**And it excludes what the rule explicitly includes.** Rule 5 names "rules files under `~/.claude/rules/`" as in-budget. On this machine those load every session: `~/.claude/rules/common/` ≈ 247 directives, `~/.claude/rules/web/` ≈ 157. **[A]** Real combined context for session start ≈ 694 — roughly 3.5× the ceiling.

**Rule 5 has no compliance check.** `grep -n 'instruction budget\|Rule 5\|150' docs/sop/compliance-checklist.md` returns nothing. **The flagship rule is the only rule with no check.** `docs/agent-memory/decisions/2026-04-19_solo_p43-rule-5-precise-instruction-count-deferred.md` records that the measurement was deferred as too expensive. It has not been redone across the 31 P-numbers shipped since.

One recorded arithmetic error: `docs/recent-work/2026-04-17_solo_p40-...:7` states *"Core SOP ~189 → ~178 instructions (under 150 soft cap on first measure since Rule 5 was added)."* 178 is not under 150. **[A]**

### 3.2 Step numbering is incoherent across four files **[A, spot-verified]**

The same operation carries four different numbers. An agent told "Step 4" cannot resolve which step is meant.

| Operation | `README.md` | `claude-agent-sop.md` | `CLAUDE.md` | `update-sop.md` |
|---|---|---|---|---|
| Pre-flight: drain subagents | 0 | — | 0 | Pre-flight |
| Resolve agent identity | — | — | — | Step 0 |
| Resolve commit range | — | — | — | Step 0a |
| Self-evaluate vs DoD | 1 | — | — | **Step 1** |
| Reviewer-turn gate | — | Step 1b | — | Step 1b |
| **Run tests** | 2 | **1** | **1** | **Step 2** |
| P-number collision check | (in 3) | Step 2a | (in 2) | Step 2a |
| **Update `Backlog.md`** | 3 | **2** | **2** | **Step 3** |
| **Reconcile trackers** | 4 | **3** | **3** | Step 3b |
| State-transition validator | — | Step 3c | — | Step 3c |
| Drift detection | — | Step 3d | — | Step 3d |
| Update `feature-map.md` | 5 | 4 | 4 | Step 4 |
| decisions/gotchas | 6 | 5 | 5 | Step 5 |
| Batch Log | 7 | 6 | 6 | Step 6 |
| Resume snapshot | 8 | 7 | 7 | Step 7 |
| `docs/recent-work/` entry | 9 | 8 | 8 | Step 8 |
| Refresh rollup | (in 9) | (in 8) | (in 8) | Step 8b |
| Update `MEMORY.md` index | — | — | — | Step 9 |
| Commit | 10 | 9 | 9 | Step 10 |
| Prune merged branches | — | — | — | Step 10b |
| Reconciliation hard-block | — | — | — | Step 11 |

**Unresolvable tokens:**

| Token | Resolves to |
|---|---|
| "Step 1" | *run tests* (SOP, CLAUDE.md) **vs** *self-evaluate* (update-sop, README) |
| "Step 2" | *update Backlog* (SOP, CLAUDE.md) **vs** *run tests* (update-sop, README) |
| "Step 3" | *secondary trackers* (SOP, CLAUDE.md) **vs** *update Backlog* (update-sop, README) |
| "Steps 5-9" | README is **+1** against all three others throughout |
| "Step 1b" | Same operation, nested under *run tests* in the SOP but under *self-eval* in update-sop — **and executed in the opposite order relative to the test run** |

`Step 3c` resolves consistently, by coincidence — its parent happens to be number 3 in both.

**Cross-command collision:** `restart-sop.md` Step 0a = sibling-worktree check, Step 0c = commit range; `update-sop.md` Step 0a = commit range.

**Related defects:**
- `update-sop.md:100` directs a gotcha to "Step 4"; Step 4 is feature-map, gotchas are Step 5. **[A]**
- `finish.md:136` cites "Section 12" for the session-end checklist. Section 12 is *Optional Patterns for Large Projects*; the checklist is Section 6. **[V]**
- `README.md:86` claims "9 canonical steps" then enumerates 0-10 (11 items). **[A]**
- `docs/examples/existing-project-migration.md:120,260` still say "7-step end checklist". **[A]**

### 3.3 Half of `/restart-sop` cannot act

Steps 0-0e occupy `restart-sop.md:19-164` — **146 of 297 lines (49%)** — read every session, containing zero blocking paths. `grep -c 'BLOCK\|hard-block\|exit 1' .claude/commands/restart-sop.md` = **0**. **[A]**

Seven explicit non-blocking statements: `:17` "Do not block", `:21` "do not block", `:39` "informational", `:121` "informational", `:151` "do not block", `:164` "informational", `:236` "Advisory, not a block".

Step 0d (`:119-147`) prints the declared P-number whose enforcement lives entirely at `/update-sop` Step 3d. This is verbatim the pattern the repo's own decision file records **rejecting**: *"The initial P46 proposal was a PostToolUse hook printing status reassertions ... a print the agent can ignore is indistinguishable from not having the print."* The same construct was reintroduced as Step 0d.

Sharper: `compliance-checklist.md:256` (S4) makes the *presence* of the memory-poisoning warning a scored check. **The repo scores projects on having a warning that cannot block anything.**

### 3.4 Rule 1 vs Rule 5 — the resolution is nowhere an agent reads

`claude-agent-sop.md:12` — *"No agent may silently remove content from any project document."*
`claude-agent-sop.md:76` — *"trim before adding ... consolidate overlapping rules or move reference material out of the instruction surface."*

The implied resolution is a scope split: Rule 1 governs **tracking** documents (its "How this works" list at `:20-26` enumerates decisions, in-flight, backlog, build plans, priority lists, resume, memory files — instruction text is absent); Rule 5 governs the **instruction** surface.

**That split is never stated.** It exists only as practice recorded in decision files. `claude-agent-sop.md:370` is the visible artefact of a Rule-1-violating deletion ("Per-file versioning rules are defined in Section 0 Rule 1... No separate restatement here") and does not say what was removed. The "trace" lives in `.archive/`, which is gitignored — invisible to any consumer or future agent. **[A]**

**Recommendation:** state the scope split explicitly in Rule 1. Rule 5 should win for instruction text.

### 3.5 Rule 3 vs the recommendations the SOP mandates

`claude-agent-sop.md:50` — *"Do not volunteer opinions, preferences, subjective recommendations, or hedged framing ... Offer an opinion only when the user explicitly asks."*

Against:
- `:409` — "Projects with one observed missed-bug ... **should adopt** 0 for their next quarter"
- `:570` — "**A rule of thumb:** if the next batch of work would require rewriting more than half..."
- `update-sop.md:359` — "the discovery was **probably** routine debugging" (a word Rule 3 names as banned)
- `sop-checker.md:267-272` — mandated `## Top Recommendations` output
- `code-reviewer.md:116,128-130` — mandated `Verdict: [APPROVE / WARNING / BLOCK]`

The sharp case: `code-reviewer` is **auto-invoked** by `/update-sop` Step 1b without the user asking, and its entire output is recommendations. Rule 3's exception does not cover automated invocation. **[A]**

**Recommendation:** narrow Rule 3 to agent-to-user conversational turns, exempting mandated report formats.

---

## 4. Axis (b) — Token economics

### 4.1 Measured per-session cost **[A, components spot-verified]**

Estimation basis: `bytes / 4` (the 4.x convention the repo itself uses at `docs/benchmark/README.md:119`). Sonnet 5 adds ~30% per `claude-agent-sop.md:710`.

**Session start — `/restart-sop`, full path:**

| File | Bytes | Est. tokens | Class |
|---|---:|---:|---|
| `restart-sop.md` (command body **is** the prompt) | 14,993 | 3,748 | always |
| `CLAUDE.md` | 10,045 | 2,511 | always |
| `docs/agent-memory.md` | 19,344 | 4,836 | always |
| build plan `## Batch Log` | **30,800** | **7,700** | always |
| `Backlog.md` targeted item | ~4,800 | 1,200 | partial |
| memory index + resume + git output + dir listings | ~3,100 | 775 | always |
| **TOTAL** | **~83,000** | **~20,800** | |

**Session end — `/update-sop`, incremental:**

| File | Bytes | Est. tokens |
|---|---:|---:|
| `update-sop.md` (command body = prompt) | 33,993 | 8,498 |
| `docs/feature-map.md` | 34,867 | 8,716 |
| validator output + reviewer return | ~2,500 | 625 |
| **TOTAL** | **~71,400** | **~17,800** |

`scripts/validate-state-transitions.sh` (28,131 B) is **executed, not read** — correctly zero context cost.

### 4.2 The README's "<2%" claim does not hold

`README.md:32` — *"Low session-start cost. Typical read on a mature project stays well under 2% of a 1M context window."*

| Basis | Tokens | % of 1M | % of 200K |
|---|---:|---:|---:|
| 4.x, `chars/4` | 20,800 | **2.08%** | 10.4% |
| Sonnet 5 | 27,000 | **2.70%** | 13.5% |
| 4.x × the SOP's own 1.7× overhead (`claude-agent-sop.md:310`) | 35,400 | **3.54%** | 17.7% |

Only the most generous combination lands under 2%, and "well under" is not defensible at any of them. Two further problems: the claim picks 1M as denominator when the standard window is 200K, and the SOP's own 60% compaction threshold (`:431`) means the working budget is 120K — **session start consumes ~17% of it before the agent reads a line of actual work**.

**The claim is unbacked.** `docs/agent-memory/decisions/2026-04-17_solo_p41-readme-rewritten-465-119-lines.md` records the P41 rewrite: *"Removed: TOC, token-efficiency math wall, ..."*. **The claim survived the deletion of its own arithmetic.** That is a Rule 3 failure in the README's own feature list. **[A]**

### 4.3 Hot paths

| Rank | Path | Bytes | % of start | Note |
|---|---|---:|---:|---|
| 1 | `phase-0-foundation.md` `## Batch Log` | **30,800** | 37% | **[V]** 93% of the file; 50 lines; the only append-only artefact with **no archive rule** |
| 2 | `docs/agent-memory.md` | 19,344 | 23% | 90% is `## Completed Work` (17,439 B) |
| 3 | `restart-sop.md` body | 14,993 | 18% | 49% of it advisory (§3.3) |
| 4 | `CLAUDE.md` | 10,045 | 12% | 25% is the derived rollup |
| — | `update-sop.md` | 33,993 | (end) | **[V]** loaded whole every invocation; **+38%** since last measured at 24.7 KB |
| — | `feature-map.md` | 34,867 | (end) | read with no targeting rule |

### 4.4 The read-parity gap — cheapest high-value fix **[V]**

`restart-sop.md:251` is explicit:

> **Do not load the full `Backlog.md`** — locate the item first, then read only its range. The file is often 3,000-5,000 lines on active projects and only ~40-80 lines belong to any one item.

`update-sop.md:255-260` Step 3 instructs edits to the same 127 KB file with **no equivalent guard**. Same for `:349` and the 35 KB `feature-map.md`.

`docs/guides/cross-layer-rules.md` exists in this repo specifically to prevent one logical rule living in two runtimes and diverging. This is that failure, inside the SOP itself.

**Note on the Batch Log:** `restart-sop.md:263` does say *"read its Architecture and Batch Log sections — same pattern: grep for the relevant batch anchor, then read its range."* Guidance exists but is ambiguous — "read the section" and "grep for the anchor" pull opposite ways. Tighten to name the last ~5 entries explicitly. **[V — this corrects an overstatement in the source review]**

### 4.5 The archive threshold is specified in the wrong unit

`claude-agent-sop.md:485` triggers Backlog archival at "approximately 2,000 lines". `Backlog.md` is **1,589 lines — under threshold — but 127,569 bytes**, because items are prose paragraphs at ~80 B/line rather than one-liners.

Measured: **52 `[SHIPPED]` items dated more than 90 days ago occupy ~77,700 B / ~1,066 lines = 61% of the file** — entirely invisible to the rule as written. **[A]**

**Fix:** restate as *"2,000 lines OR 60 KB, whichever comes first"*.

### 4.6 Reduction plan

| # | Action | Est. saving | Risk |
|---|---|---:|---|
| 1 | Archive the Batch Log; tighten `restart-sop.md:263` to last ~5 entries; add a Batch Log archive rule to `claude-agent-sop.md:335` | ~7,400 tok | none |
| 2 | Copy the targeted-read rule into `update-sop.md` Steps 3 and 4 | up to 8,700 tok + prevents a 32k unguarded read | none |
| 3 | Archive `agent-memory.md` `## Completed Work`, keep last ~10 | ~3,750 tok | low |
| 4 | Extract duplicated shell to `scripts/sop-session-env.sh` | ~2,250 tok/session | none |
| 5 | Move rationale prose from `update-sop.md` into the SOP doc | ~2,000 tok | low |
| 6 | Extract `restart-sop.md` Steps 0a-0e into a preflight script | ~1,625 tok | low |
| 7 | Cap the CLAUDE.md rollup at 10-12 entries in `refresh-rollup.sh` | ~500 tok/session + stops unbounded growth | none |
| 8 | Re-specify the Backlog archive threshold in bytes | — | low |

**Net if all ship:** session start ~20,800 → ~8,900 (**-57%**); session end ~17,800 → ~5,700 (**-68%**). Session start lands at ~0.9% of 1M — **making the README claim true rather than requiring its deletion**. **[A]**

### 4.7 Self-compliance failures

1. **CLAUDE.md breaches its own token cap.** `claude-agent-sop.md:308` sets "under 200 lines / 2,000 tokens for non-code projects". CLAUDE.md is **187 lines (pass) / 10,045 B ≈ 2,511 tok (fail by 26%)**. **[V]**
2. **The 1.7× read-overhead multiplier has no provenance.** `claude-agent-sop.md:310` states it as fact; its only other appearance (`docs/benchmark/README.md:119`) demotes it to *"acceptable as a cross-check only"*. A load-bearing number sourced nowhere. **[A]**
3. **Instrumentation was used to close a question it didn't answer.** `docs/instrumentation/2026-04-24_update-sop-timing.md`: *"Trimming the command file would be cosmetic."* That conclusion is about **wall-clock latency**, and has been carried as if it settled **token cost**. In the 3 months since, `update-sop.md` grew 24.7 KB → 34.0 KB unremarked. **[A]**

---

## 5. Axis (c) — Redundancy

**~114 KB of tracked duplication (~29-38k tokens).** The worst item is a correctness problem, not a size one.

### 5.1 CRITICAL — `docs/examples/` teaches a pre-Phase-1 SOP **[V]**

Anyone following these three documents builds a project that **fails the repo's own compliance checks**.

| Drifted claim | Location | Correct value |
|---|---|---|
| "the **two** non-negotiable rules" | `sop-implementation-guide.md:9,30`; `existing-project-migration.md:112` | **six** (`claude-agent-sop.md:10`) |
| Taxonomy omits `[DEFERRED]` | `sop-implementation-guide.md:56`; `new-project-walkthrough.md:157` | `claude-agent-sop.md:461` |
| "7-step end checklist" | `existing-project-migration.md:120,260` | 9 |
| Decisions written *into* `agent-memory.md` | `sop-implementation-guide.md:117-125,300`; `new-project-walkthrough.md:243-252` | per-entry directories (`claude-agent-sop.md:216`) |
| "all 8 sections" | all three | 6 |
| Deprecated `\| Area \| File \|` shown **and praised** at `:107` | `new-project-walkthrough.md:93-94` | banned at `claude-agent-sop.md:543-548` |
| Unsuffixed `project_resume.md` | `new-project-walkthrough.md:391`; `existing-project-migration.md:39,166` | `project_resume_<agent-id>.md` |

All three omit `docs/recent-work/`, `decisions/`, `gotchas/`, rollup sentinels, `docs/reviews/` and Step 1b **entirely** (0 grep hits) → fails F8/F9/F10 and C13.

Additionally, `sop-implementation-guide.md` is **43% line-identical** to `new-project-walkthrough.md` (76 identical lines). **[A]**

### 5.2 `resolve_agent_id()` implemented three times, fix applied once **[V]**

| Site | Implementation |
|---|---|
| `restart-sop.md:48-74` | Bash function — **byte-identical (628 B)** to update-sop's |
| `update-sop.md:21-47` | Bash function — byte-identical |
| `validate-state-transitions.sh:158-183` | Third, structurally different implementation |

The validator carries a documented bug fix with an explanatory comment at `:164-172`:

```bash
# `|| true`: outside a git repo `git worktree list` exits 128. 2>/dev/null
worktree_count=$( { git worktree list 2>/dev/null || true; } | wc -l | tr -d '[:space:]')
```

Both command copies still read `count=$(git worktree list 2>/dev/null | wc -l | tr -d '[:space:]')` — **no `|| true`**.

This is the one primitive every other multi-agent conflict-avoidance feature depends on. `docs/guides/cross-layer-rules.md:31-54` mandates a Duplicated-Logic Inventory at `docs/process-improvements.md` for exactly this shape. **No such file exists.** **[A]**

### 5.3 Fanout of shared strings and structures

| Item | Copies | Locations |
|---|---:|---|
| Skip-token grammar `review skipped (P<n>): <...>` | **6** living-spec files | `update-sop.md`, `sop-checker.md`, `claude-agent-sop.md`, `security.md`, `compliance-checklist.md`, `validate-state-transitions.sh` **[V]** |
| Session-end checklist | **6** | `update-sop.md` (canonical), SOP §6, `CLAUDE.md`, `README.md`, `sop-checker.md`, 2 examples |
| Session-start checklist | **5** | SOP §5, `CLAUDE.md`, `restart-sop.md`, `sop-checker.md`, examples |
| Tag taxonomy | **8** | SOP §8, `CLAUDE.md`, `README.md`, both templates, backlog-template, 2 examples |
| Precedence order | **5** | SOP Rule 2, `CLAUDE.md:9`, `README.md:148`, 2 in examples |
| M1-M6 table | **3** | checklist, `sop-checker.md`, `multi-agent.md` |
| Command count | **3 different values** | `setup.sh:29` says three, `README.md:9,59,216` say four, **five exist** **[V]** |

`claude-md-template-code.md` contains **89 identical lines (4,699 B) — 70% of the base template**. `setup.sh:97-101` already selects one file; `--code` could append a delta instead. **[A]**

### 5.4 The chronology cluster — a root cause worth naming

Four surfaces record the same shipped-work narrative: `docs/recent-work/` (58,721 B), `phase-0` Batch Log (30,554 B), `feature-map.md` rows, and `agent-memory.md` `## Completed Work` (17,434 B). Measured 5-gram overlap between recent-work and Batch Log: **14.2%**, with unbroken shared clauses. **[A]**

**Root cause:** `docs/recent-work/` appears in **neither** the Section 2 ownership table (`claude-agent-sop.md:151-160`) **nor** the Section 7 Update Triggers table (`:437-451`). It is named only in session-end step 8. It is the largest shipped-work prose surface in the repo and the SOP assigns it no scope.

Contributing: `docs/recent-work/README.md:30` specifies "2-4 line summary" — **19 of 37 entries exceed it**, up to 404 words. `agent-memory.md` `## Completed Work` is specified as one line per entry (`claude-agent-sop.md:238`); actual entries run 100-314 words. **[A]**

**Fix order:** add `docs/recent-work/` to the Section 2 ownership table first — it is prerequisite to deduplicating the prose.

### 5.5 Confirmed-OK patterns (do not flag) **[A]**

- **`Backlog.md` item bodies vs everything else: ≤3% 6-gram overlap.** Uniquely holds acceptance criteria and source citations. Rule 2 fully honoured on this axis.
- **`decisions/` and `gotchas/`: ≤3.6%** against every chronology surface. They hold rejected alternatives and hazard mechanics found nowhere else.
- **`CLAUDE.md` rollup: 37/37 lines match a `docs/recent-work/*.md` H1** on matching dates. Sentinel-bounded, derived, zero independent content — exactly as specified.
- **The multi-agent guide split is real:** `multi-agent.md` vs `multi-agent-parallel-sessions.md` = 2%; vs `multi-agent-context-routing.md` = 1%.
- **Reference agents clean:** code-reviewer vs security-reviewer 8% (frontmatter only).
- **`feature-map.md:82-93`** superseded sub-table is *the rule working correctly* — marked, reasoned, preserved. Exemplary.

### 5.6 `.archive/` is not a product problem **[V]**

`.gitignore:1` is `.archive/`. `git ls-files .archive` → **0**. `git log --all -- .archive` → empty; never tracked. The 155,299 bytes exist only on this machine and cost zero session tokens.

Worth noting it is a *redundant* preservation: the pre-trim SOP is already in git at `3e452b7`. Rule 1's "trace" for instruction-surface deletions currently lives somewhere no consumer, clone, or future agent can see.

---

## 6. Axis (d) — Architecture

### 6.1 Component map

```
                    ┌──────────────────────────────────────┐
                    │  DISTRIBUTION                         │
                    │  setup.sh · /update-agent-sop         │
                    │  (3-way SHA sync)                     │
                    └──────────────┬───────────────────────┘
                                    │ copies / syncs
        ┌───────────────────────────┼──────────────────────────┐
        ▼                           ▼                          ▼
┌──────────────────┐  ┌────────────────────────┐  ┌──────────────────────┐
│ NORMATIVE        │  │ MECHANICS (guides)     │  │ TEMPLATES            │
│ docs/sop/*.md    │◄─┤ cross-layer-rules.md   │  │ (stamped once,       │
│ claude-agent-sop │  │ multi-agent-*.md       │  │  never re-synced)    │
└────────┬─────────┘  └────────────────────────┘  └──────────────────────┘
         │ ⚠ prose duplicates procedure (§6.3)
         ▼
┌────────────────────────┐   invokes as hard gate   ┌─────────────────────┐
│ EXECUTABLE PROCEDURE   │─────────────────────────►│ ENFORCEMENT          │
│ .claude/commands/*.md  │                           │ validate-state-      │
│                        │◄── invokes subagent ──┐   │  transitions.sh      │
└───────────┬────────────┘                        │  │ refresh-*.sh         │
            │ reads                                │  └─────────────────────┘
            ▼                                      │
┌────────────────────────┐              ┌──────────┴──────────┐
│ COMPLIANCE / GRADING   │              │ REFERENCE AGENTS     │
│ compliance-checklist   │              │ code-reviewer etc.   │
│ sop-checker.md         │              └─────────────────────┘
└────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ DOGFOOD / PROJECT-INSTANCE DATA — NOT shipped                     │
│ CLAUDE.md · Backlog.md · agent-memory/ · feature-map · build-plans│
└──────────────────────────────────────────────────────────────────┘
```

The dogfood/product boundary is **mostly clean**: `setup.sh` ships `docs/templates/build-plan-template.md`, not this project's own `phase-0-foundation.md`. One leak — see §6.5.

### 6.2 Edit-fanout — the coupling metric **[A]**

| Change | Files that must change | Count |
|---|---|---:|
| Add a Backlog status tag | SOP §8, validator, checklist B4, `update-sop.md` regex, backlog-template, claude-md-template, own CLAUDE.md/Backlog.md | **~8** |
| Change the skip-token grammar | validator, `update-sop.md`, SOP, `security.md`, checklist S7, `sop-checker.md` | **6** **[V]** |
| Renumber a `/update-sop` step | `update-sop.md`, SOP §6, checklist C4, `sop-checker.md`, both templates, own CLAUDE.md | **~7** |
| Add a fourth gate | `update-sop.md`, SOP §6, checklist, `sop-checker.md`, `security.md`, README | **6-7** |
| Change agent-id precedence | both commands, validator, parallel-sessions guide §1, checklist M1, config template | **6** |

Every representative change touches 6-8 files. Rule 2 ("one source of truth") would predict 1-2.

### 6.3 Step 1b breaks the layering that 3c and 3d get right

| Gate | Normative | Executable | Enforcement | Compliance | Coherent? |
|---|---|---|---|---|---|
| **Step 1b** | `claude-agent-sop.md:407-431` — **full mechanics restated** | `update-sop.md:102-172` | `--assert-review` `:69-138` | R1 (retrospective) + S7 (integrity) — **no presence check** | **Divergent-by-history.** P66 shipped a prose/validator contradiction |
| **Step 3c** | SOP §6, transition table §8 | `update-sop.md:293-314` — **thin wrapper** | `validate-state-transitions.sh:358-602` | B11 — explicit presence check | **Coherent** |
| **Step 3d** | SOP §6, one paragraph | `update-sop.md:316-333` — **thin wrapper** | `:141-356` | D1 — explicit presence check | **Coherent at gate level**, divergent at the agent-id sub-dependency (§5.2) |

3c and 3d demonstrate the correct pattern: the command invokes the script rather than restating the logic. Step 1b restates full mechanics in the normative doc — which is exactly how P66's contradiction shipped.

**Also missing:** Step 1b has no compliance *presence* check. B11 verifies 3c is wired; D1 verifies 3d is wired. Step 1b has only R1, which is retrospective and conditioned on having shipped `[Feature]`/`[Refactor]` items in the last 30 days. **A freshly-installed project scores clean on "is Step 1b wired up" without the checker having looked.** **[A]**

**Recommendation:** trim SOP §6 Step 1b to policy + rationale (the sycophancy citation and hst-tracker incident are genuinely narrative and belong there) with a cross-reference to `update-sop.md` for mechanics — matching the pattern §16 already uses correctly at `:716-719`.

### 6.4 `/finish` depends on three undefined commands **[V]**

`.claude/commands/finish.md` invokes `/simplify` (`:110,116,118`), `/prp-pr` (`:152`), `/checkpoint` (`:195`).

`.claude/commands/` contains exactly five files: `finish.md`, `migrate-to-multi-agent.md`, `restart-sop.md`, `update-agent-sop.md`, `update-sop.md`. `setup.sh:246-271` installs those five. **None of the three exist.**

`/simplify` has documented provenance as a Claude-Code-native command (`finish.md:118`). `/checkpoint` and `/prp-pr` have **zero** documented provenance anywhere in the repo.

This is a distribution-boundary leak: a file the sync manifest treats as portable product silently assumes personal tooling.

### 6.5 A `Status: DEFERRED` guide ships to every consumer **[V]**

`setup.sh:220` globs **all** of `docs/guides/*.md` unconditionally:

```bash
for src in "$SCRIPT_DIR"/docs/guides/*.md; do
    copy_if_missing "$src" "$TARGET/docs/guides/$(basename "$src")"
```

That includes `docs/guides/managed-agents-integration.md`, marked *"Status: DEFERRED (parked 2026-04-17)"*, describing a beta API frozen 108 days ago. 4,331 B × every consumer project.

**Fix:** exclude it from `setup.sh`, or move it to `docs/guides/parked/`.

### 6.6 The state model is inconsistent under concurrency

Phase 1 (P43) restructured Recent Work, Decisions, Gotchas and In-Flight into per-entry directories *"to remove the merge-conflict surface for concurrent appends"* (`claude-agent-sop.md:216`).

**`Backlog.md` (1,589 lines) and `feature-map.md` were not.** At the 3-5 concurrent-agent scale the guide targets (`multi-agent.md:73`), these are the two files most likely to produce a literal merge conflict — two agents editing the same status-tag line, or appending near the same P-number heading. P-number collision detection (Step 2a) is a detect-after-the-fact hard block, not a structural impossibility. **[A]**

Two plausible design reasons exist, neither written down:
- Backlog items need **in-place status mutation**, which append-only per-entry does not support
- `feature-map.md` is **purely derived** and could use the regenerate-from-directory pattern that already works for the CLAUDE.md rollup — nothing blocks this

**Recommendation:** document the Backlog rationale in `multi-agent.md`; evaluate regeneration for `feature-map.md`.

### 6.7 Extension seams are thin

`agent-sop.config.json` is the intended configuration surface, but:
- It is referenced at **three different paths**: bare `agent-sop.config.json` (`claude-agent-sop.md:409,411`), `.claude/agent-sop.config.json` or `~/.claude/...` (`restart-sop.md:10`), `~/.claude/...` only (`update-sop.md:106`). Actual precedence per `validate-state-transitions.sh:286-289` is project-first, so `update-sop.md:106` states the wrong order. **[A]**
- The live `~/.claude/agent-sop.config.json` has **no** `review_loc_threshold`, `review_files_threshold`, or `review_triggers` keys — the entire P44/P59 config surface is absent from the deployed config; defaults silently apply. **[A]**
- `review_triggers[]` is schemed in the template but **no command or script reads it** (§2.3).

Most real configuration is effectively hardcoded in prose.

---

## 7. Staleness and drift

### 7.1 Three bare "33%" claims ship to every consumer **[V]**

`docs/benchmark/results/r5-post-trim/summary.md:54` states plainly:

> **The +33% figure should not be cited unconditionally for the post-trim SOP** — it was measured against pre-P32 SOP with a less capable model baseline.

| Location | Caveat? |
|---|---|
| `README.md:19` — "+8-33% quality uplift (k=1 per arm...)" | ✅ |
| `README.md:229` — "single-run — see the Limitations" | ✅ |
| **`docs/sop/claude-agent-sop.md:590`** — "produced a 33% quality improvement" | ❌ **none** |
| **`docs/sop/claude-agent-sop.md:675`** — "Vague prompts exposed a 33% quality gap" | ❌ **none** |
| **`docs/sop/compliance-checklist.md:276`** — "produced a 33% quality improvement" | ❌ **none** |

The 2026-07-27 caveat session fixed `README.md:229`; P68 fixed `README.md:19`. **Neither touched the SOP docs.** All three uncaveated instances sit in files `setup.sh:215-218` copies into every consumer project, and `claude-agent-sop.md` is read every session.

### 7.2 The `[DEFERRED]` mechanism is vacuous **[V]**

Item-level status counts in `Backlog.md`:

```
68 [SHIPPED]     4 [OPEN]     1 [WON'T]
 0 [DEFERRED]    0 [IN PROGRESS]    0 [BLOCKED]    0 [VERIFIED]
```

**Zero `[DEFERRED]` items.** All 24 `[DEFERRED]` string hits are prose — the taxonomy definition, the transition graph inside P45, and P42/P71 describing the tag they introduced.

Consequences:
- **Check B12** (`compliance-checklist.md:142`, shipped by P71 on 2026-07-26) is vacuous against `Backlog.md` — and **fails on its other half**. B12 requires a `**Reopens when:**` marker in the CLAUDE.md deferred list. `CLAUDE.md:53-55` has the list, written as inline lowercase prose. `grep -c 'Reopens when' CLAUDE.md` → **0**. **The repo fails its own check.** **[A]**
- The repo's own reviewer caught this at `docs/reviews/2026-07-26_solo_P66-P73.md:46` — *"Backlog.md contains zero items whose status line is `[DEFERRED]`, so that half is vacuous"* — and it was never actioned.

**Real deferred work lives as prose inside `[SHIPPED]` entries.** That is the accumulation failure P71 diagnosed, one level below where P71 looked.

**A trigger has fired:** `sandbox.credentials` was deferred pending changelog verification. It landed in Claude Code **2.1.187**; the installed CLI is **2.1.220** — 33 releases past. `Backlog.md:1167` still says "setting unverified in changelog". **[A]** **Reopen this.**

**A trigger has not fired:** P64 / AGENTS.md — official docs still state *"Claude Code reads `CLAUDE.md`, not `AGENTS.md`."* Deferral stands. **[A]**

### 7.3 Two `[SHIPPED]` items violate "never mark SHIPPED without the document existing" **[A]**

1. **P15** `[SHIPPED - 2026-04-08]` (`Backlog.md:190-202`) asserts *"File exists at `docs/sop/hooks.md` — DONE"*. The file was deleted in `3e452b7` on 2026-04-17 (merged into `harness-configuration.md`). The merge is traced at `Backlog.md:645`; **P15 was never annotated**.
2. **P72** `[SHIPPED - 2026-07-26]` — acceptance criterion 4 requires *"First real lite round recorded in `results/`"*. `docs/benchmark/results/` holds five files, none a lite or R6 round.

### 7.4 Broken references **[A, spot-verified]**

| Missing target | Referenced from |
|---|---|
| `agent-sop-research-digest-2026-05-04.md` | `agent-memory.md:67`, `Backlog.md:1072,1139`, `feature-map.md:52`, 2 recent-work files — **cited as `**Source:**` for two shipped items (P55, P56); the provenance chain points at nothing** |
| `docs/sop/hooks.md` | `feature-map.md:17`, `agent-memory.md:93`, `Backlog.md:193,196` |
| `docs/sop/context-management.md` | `feature-map.md:92` |
| `claude-md-template-base.md` | `claude-agent-sop.md:306` **and** `claude-md-template-code.md:7` — actual file is `claude-md-template.md`; `claude-agent-sop.md:562` gets it right, so **the core SOP contradicts itself 256 lines apart** |
| `../agent-memory.md` | `docs/agent-memory/in-flight/README.md:3` — off-by-one; correct is `../../agent-memory.md` |

`feature-map.md:92` also cites "SOP Section 18"; the SOP has sections 0-17.

### 7.5 Stale counts **[V/A]**

| Claim | Location | Actual |
|---|---|---|
| "four slash commands" | `README.md:9,59,216` | **5** **[V]** |
| 3 commands listed | `setup.sh:29` | **5** installed by the loop at `:251` **[V]** |
| "17 reference markdown files" | `README.md:216` | **19** (sop 6 + guides 7 + templates 6) |
| "eight task specs" | `README.md:31` | **12** on disk (8 numeric + 4 lettered) |
| `SOP-Version` markers | 25 files | **14 stale**; `compliance-checklist.md` is self-contradictory — `:1` says 2026-07-06, `:4` says 2026-04-19 |

Severity on version markers is LOW by design — `update-agent-sop.md:144` states *"Version markers are advisory only — SHA comparison is the authority."* But 14/25 stale means the marker conveys no information.

**Verified correct, no action:** "94 checks (85 for non-code)" ✅ · "six non-negotiable rules" ✅ · "9 canonical steps" ✅ · "5 commands + 5 agents + 4 scripts installed" ✅.

**Unverifiable floating claim:** `README.md:17` — *"A 15k-line full-stack production codebase running the SOP for ~2 weeks has accumulated 125 dated decisions, 26 build-plan batch entries, and 20 rollup session entries."* Written 2026-04-19 (`git blame` → `574bbc61`), present perfect, no date or project name — 106 days stale. It also **contradicts the repo's own longitudinal exhibit**: `docs/benchmark/README.md:168-184` gives 86 / 23 / 18 for the same project measured two days earlier. Both still published, neither labelled. **[A]**

### 7.6 Dogfooding gaps

Three features shipped but never exercised in their own repo:

1. **`refresh-in-flight.sh`** shipped 2026-05-02 (P54) and is **still unrunnable here**. `docs/agent-memory.md:31` carries a live warning: *"This section uses the legacy flat-line format. `scripts/refresh-in-flight.sh` requires an `<!-- in-flight:start -->` sentinel that `docs/agent-memory.md` does not yet have."* Three months. **[A]**
2. **The learnings capture pattern** (P52, shipped 2026-04-26) has captured **zero entries in ~13 sessions**. `docs/agent-memory/learnings/` contains only `README.md`, dated ship day. **[A]**
3. **The multi-agent machinery has never been run concurrently by its author.** 109 commits, every rollup entry tagged `solo`. The 3-5-agent conflict-avoidance design is consumer-facing infrastructure the repo has not exercised on itself — which is why §5.2 and §6.6 had no opportunity to surface through the project's own feedback loop. **[V — all rollup entries are `solo`]**

### 7.7 Benchmark framework — two artefacts, opposite health **[A]**

**The fixture suites are genuinely maintained. Keep as-is.**
`state-transition-fixtures/` and `drift-fixtures/` were run during this audit: **15/15 and 5/5 pass**, exit 0, `git status` clean before and after. Extended four times (P45 → P44 → P59 → P66/P73), each for a real regression. Wired as hard blocks into `/update-sop` Steps 3c/3d. `4621b1b` added `.expect-stdout` assertions and an overridable `VALIDATOR` so fixtures are provably discriminating. **Cost: seconds. Value: high.**

**The A/B benchmark is a preserved artefact with an actively growing specification.**

Last real run: **2026-04-17 (R5) — 108 days and 30 sessions ago.** Every results file is write-once (`git log --follow` shows zero post-creation modifications on all five). Commits over `docs/benchmark/`: 8 in April, 1 in May, 3 in July — of which one is tooling and two are prose edits. **Zero new observations since May.**

**Five competing headlines, no supersession chain:**

| File | Headline |
|---|---|
| `results/summary.md:16` | SOP **+8%** (R1, precise prompts) |
| `results/round-2-summary.md:22` | SOP **+33%** (R2, vague prompts) |
| `results/multi-round-summary.md:48` | **"SOP never loses"** |
| `results/r4-final-summary.md:12-15` | **All four tasks a Draw (~0%)** |
| `results/r5-post-trim/summary.md:23` | SOP **+16%** (Opus 4.7) |

No file points forward. The only arbitration is at `r5-post-trim/summary.md:54`, reaching *backwards*, in the file a chronological reader hits last. A sixth number exists that no file records: `r4-final-summary.md:31` lists a "Fast" round with a **Negative** margin and there is no `results/fast-*.md` — because `run-fast-round.sh:24-27` accepts only `cleanup` and has no setup or run path.

**The owed run cannot answer the question it is owed for.** `CLAUDE.md:46` instructs `bash docs/benchmark/run-multi-round.sh setup <r> --lite -k 3`. But `run-multi-round.sh:32` pins `BASE_COMMIT=76b3b77` and creates a worktree at that pinned commit **with no step syncing current agent-sop into it**. At `76b3b77` the SOP arm holds three files frozen 2026-04-09; agent-sop today ships six SOP docs. The run would re-measure the April SOP. There is also **zero model pinning** (`grep -rniE 'opus|sonnet|--model|ANTHROPIC_MODEL'` over the runners returns nothing) while `r5-post-trim/summary.md:54` instructs R6 to use "same model as R2" — an instruction the tooling cannot express.

**The un-run runner has rotted undetected.** `run-benchmark.sh:139-144` carries verbatim the P73 bug fixed elsewhere on 2026-07-26: `ls $glob 2>/dev/null | head -1` under `pipefail` exits before the `err "Task file not found"` line prints. The P73 audit scoped to `validate-state-transitions.sh` and never looked at the benchmark runners.

**Verdict:** the specification is now stricter than any evidence it holds. `docs/benchmark/README.md:35` requires k≥5 for a public figure; every recorded round is k=1, and `:316` says so honestly. The repo is admirably candid — but honesty about a stale number is not a fresh number.

---

## 8. Test coverage gaps **[A]**

The state-transition fixtures cover **4 of 20 legal transitions**.

**No fixture exists for:**
`<absent>`→`[DEFERRED]` · `<absent>`→`[IN PROGRESS]` · `[OPEN]`→`[IN PROGRESS]` · `[OPEN]`→`[DEFERRED]` · `[OPEN]`→`[WON'T]` · `[IN PROGRESS]`→`[BLOCKED]` · `[IN PROGRESS]`→`[DEFERRED]` · `[IN PROGRESS]`→`[WON'T]` · `[BLOCKED]`→`[IN PROGRESS]` · `[BLOCKED]`→`[DEFERRED]` · `[BLOCKED]`→`[SHIPPED]` · `[BLOCKED]`→`[WON'T]` · `[DEFERRED]`→`[IN PROGRESS]` · `[DEFERRED]`→`[SHIPPED]` · `[DEFERRED]`→`[WON'T]` · `[DEFERRED]`→`[BLOCKED]`

**No fixture ever sets a before-state of `[BLOCKED]` or `[DEFERRED]`** — every transition from those states, plus the soft-warn logic at `validate-state-transitions.sh:486-503`, is completely untested.

**`[WON'T]` terminal revival is never tested.** Only `[VERIFIED]`→`[OPEN]` exercises terminal rejection.

**The type-based review exemption is untested in its exempting direction.** No fixture proves that an `[Iteration]`/`[Bug]` shipping *with* a Batch Log entry but *without* a review citation is legal. A regression widening the review requirement to all types would go undetected.

**`drift-fixtures/run-tests.sh` asserts exit codes only.** The state-transition harness was explicitly upgraded post-P73 to assert stdout content *"because P73 was exactly [a silent failure and] every fixture still passed"* on exit code alone. The drift harness never received that upgrade. A silent-block regression in `--check-drift` — structurally identical to §2.4 — **would pass this harness today**.

---

## 9. Prioritised remediation plan

### P0 — Stop data loss (do first)

| # | Action | Ref |
|---|---|---|
| 1 | Split `setup.sh --force` semantics by tier, or drop `--force` for the per-project tier. Add a git-clean check, matching `migrate-to-multi-agent.py`'s existing pattern | §2.1 |
| 2 | Add collision detection to `migrate-to-multi-agent.py` — fail loudly, listing every colliding title | §2.2 |

### P1 — Fix silent failures

| # | Action | Ref |
|---|---|---|
| 3 | `resolve_before()` — explicit `return 0` | §2.4 |
| 4 | `refresh-rollup.sh:52` — `{ grep ... \|\| true; }` | §2.5 |
| 5 | `run-benchmark.sh:140` — same guard | §7.7 |
| 6 | Port `.expect-stdout` assertions to `drift-fixtures/run-tests.sh` | §8 |

### P2 — Close the gates that are only prose

| # | Action | Ref |
|---|---|---|
| 7 | Give Step 1b trigger (b) a pathspec check in the validator — or downgrade `:410` to advisory | §2.3 |
| 8 | Define `detect_trackers`, or inline Step 3b's pipeline at Step 11 | §2.6 |
| 9 | Add `## Definition of Done` to the CLAUDE.md spec, or stop gating on it | §2.7 |
| 10 | Add a Step 1b *presence* check to the compliance checklist, mirroring B11 | §6.3 |

### P3 — Correctness of shipped artefacts

| # | Action | Ref |
|---|---|---|
| 11 | **Rewrite `docs/examples/`** — highest correctness exposure for new adopters | §5.1 |
| 12 | Add the S4 heading to `sop-checker.md` | §2.8 |
| 13 | Renumber the five duplicate check IDs; resolve the R1 resume-filename contradiction | §2.9 |
| 14 | Caveat or remove the three bare "33%" claims in shipped SOP docs | §7.1 |
| 15 | Exclude `managed-agents-integration.md` from `setup.sh`, or re-home it | §6.5 |
| 16 | Fix `finish.md:136` (Section 12 → Section 6); resolve the three undefined command references | §2.10, §6.4 |
| 17 | Reconcile the command count across `setup.sh:29`, `README.md:9,59,216` | §5.3 |

### P4 — Token reductions (~57% start, ~68% end)

| # | Action | Saving |
|---|---|---|
| 18 | Copy the targeted-read rule into `update-sop.md` Steps 3 and 4 | up to 8,700 tok |
| 19 | Add a Batch Log archive rule; tighten `restart-sop.md:263` | ~7,400 tok |
| 20 | Archive `agent-memory.md` `## Completed Work` | ~3,750 tok |
| 21 | Extract shared shell into `scripts/sop-session-env.sh` | ~2,250 tok |
| 22 | Move rationale prose out of `update-sop.md` | ~2,000 tok |
| 23 | Extract `restart-sop.md` Steps 0a-0e into a preflight script | ~1,625 tok |
| 24 | Cap the CLAUDE.md rollup at 10-12 entries | ~500 tok |
| 25 | Re-specify the Backlog archive threshold in bytes | — |

### P5 — Structural decisions (not fixes — these need a call)

| # | Decision |
|---|---|
| 26 | **Rule 5**: add a compliance check, or restate it honestly. At 318-379 against a 200 ceiling it is currently aspirational — and an unmeasured budget is the exact failure the rule exists to prevent |
| 27 | **Step numbering**: pick one canonical sequence and make the other three derive from it, or stop cross-referencing by number and cite headings instead |
| 28 | **Step 1b layering**: trim SOP §6 to policy + rationale, delegate mechanics to `update-sop.md` — matching the §16 pattern |
| 29 | **`docs/recent-work/` ownership**: add it to the Section 2 table. Prerequisite to deduplicating the ~85 KB chronology cluster |
| 30 | **`resolve_agent_id()`**: extract to `scripts/resolve-agent-id.sh`; create the Duplicated-Logic Inventory that `cross-layer-rules.md:31-54` already mandates |
| 31 | **`feature-map.md`**: evaluate the regenerate-from-directory pattern — it is purely derived and nothing blocks it |
| 32 | **`[DEFERRED]`**: either adopt the tag for real or retire P71's machinery. It is currently inert |
| 33 | **Benchmark**: separate the fixture suites (healthy, keep) from the A/B framework (stale). Fix `BASE_COMMIT`, add model pinning, add forward-pointers to the five results files — or freeze the framework and stop growing its spec |
| 34 | **Rule 1 vs Rule 5**: state the scope split in Rule 1's text |
| 35 | **Rule 3**: narrow to conversational turns, exempting mandated report formats |

---

## 10. What is working well

This audit is deliberately weighted toward defects. For calibration, the following were checked and found sound:

- **The three-gate design is genuinely novel and mostly correct.** Where implemented in code (Steps 3c, 3d), the layering is exemplary: thin command wrapper, one enforcement script, explicit compliance presence check.
- **The fixture suites are real engineering.** 20/20 passing, extended four times for real regressions, `.expect-stdout` assertions added specifically because exit-code-only testing let P73 through. This is what a maintained test suite looks like.
- **Rule 2 is fully honoured on the axis that matters most.** `Backlog.md` item bodies show ≤3% overlap with every other surface; `decisions/` and `gotchas/` ≤3.6%. These hold acceptance criteria, rejected alternatives and hazard mechanics found nowhere else.
- **The CLAUDE.md rollup is a correct derived view** — 37/37 lines trace to a `docs/recent-work/` H1, sentinel-bounded, zero independent content.
- **The multi-agent guide split is real**, not nominal: 1-3% overlap between the entry point and the two deep-mechanics guides.
- **`feature-map.md:82-93`** is Rule 1 working exactly as designed — a superseded sub-table, marked, reasoned, preserved.
- **The repo is candid about its own evidence.** `docs/benchmark/README.md:316` and `r5-post-trim/summary.md:54` disown their own headline figure. That is rare and worth preserving.
- **Recoverable bytes are approximately zero.** Rule 1 has not produced bloat — 1.06 MB tracked after four months and 73 items. The glob-consumed directories are load-bearing; all nine review artifacts still pass the live gate.

**What Rule 1 has produced is not byte bloat but a growing surface of unmaintained assertions.** That is the thing to manage.

---

## Appendix A — Method

Six review agents ran in parallel, each with an independent context and a scoped brief:

| Agent | Axis | Tool calls |
|---|---|---:|
| A | Token/context budget | 33 |
| B | Redundancy and duplication | 35 |
| C | Architecture | 31 |
| D | Scripts and executable code | 51 |
| E | Instruction budget and contradictions | 29 |
| F | Staleness, dead weight, broken references | 62 |

The coordinating agent independently verified findings before inclusion:

**Reproduced by the coordinator:** `resolve_before` silent exit · `refresh-rollup.sh` silent failure on heading-less entry.

**Verified by direct inspection:** Batch Log size · read-parity gap · `resolve_agent_id` byte-identity and the `|| true` divergence · `finish.md` Section 12 · three undefined commands · skip-token 6-file fanout · examples "two rules" · `sop-checker` missing S4 · duplicate check IDs · README command count · P53 Batch Log absence · `update-sop.md` trigger-b absence · validator path-inspection absence · `detect_trackers` · "Definition of Done" absence · instruction counts (independent count, agreement within 6%) · bare 33% claims · R5 prohibition text · zero `[DEFERRED]` items · `setup.sh` guide glob · `.archive` untracked · tracked size · commit distribution.

**Corrected during verification:** the source review characterised the Batch Log as an unguarded read. `restart-sop.md:263` does provide grep-then-range guidance; the defect is ambiguity, not absence. Downgraded accordingly (§4.4).

## Appendix B — Limitations

- **Token figures are estimates.** No first-party Claude tokenizer was available; all figures are `chars/4` with a `words×1.3` cross-check, giving a ±30% band. The repo itself points at `/usage` as authoritative (`docs/benchmark/README.md:119`). Conclusions that depend on crossing a threshold (the <2% claim) hold across the whole band; precise percentages do not.
- **Instruction counts depend on a contested method.** Rule 5's own counting rules structurally under-report: excluding "code blocks" zeroes both session checklists (they live inside untagged fences), and excluding "section headings" zeroes 26 of the 39 `## Step` headings across the two commands. Two independent counts agreed within 6%, and the *verdict* (over the 200 ceiling) is robust — the smallest scenario would need the count to be 37% too generous to fall under.
- **Downstream projects start lower.** Consumers install from `docs/templates/`, so their session-start cost begins far below these figures and grows toward them with session count. This audit measures agent-sop at ~4 months and 38 sessions.
- **Two CRITICAL findings were reproduced by the review agent, not the coordinator** (`setup.sh --force`, `migrate-to-multi-agent.py`). Both were verified by direct code reading, which independently confirms the mechanism in each case.
- **External facts were not verified.** Claims about Claude Code changelog entries, Sonnet 5 tokenizer behaviour, and third-party API status were checked against a local changelog cache where available and are otherwise reported as unverifiable from within the repo.
- **No file was modified during the audit.** All script executions were scoped to temp directories; `git status --porcelain` was clean before and after.
