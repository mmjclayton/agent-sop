# Agent Memory

Shared context for all agents working on this project. Read at the start of every session. Update at the end. Never delete without a trace — update in place, mark superseded, or archive.

---

## Key Documents

See CLAUDE.md Key Documents table.

---

## Key Source Files for Current Work

*Updated at the start of each phase.*

| Area | File |
|------|------|
| Core SOP | `docs/sop/claude-agent-sop.md` |
| CLAUDE.md template | `docs/templates/claude-md-template.md` |
| Phase 0 build plan | `docs/build-plans/phase-0-foundation.md` |

---

## In-Flight Work

*(none)*

Cleared 2026-08-03. The previous line tracked branch `fix/p66-p73-validator-and-gate-coherence` as unpushed; it merged as `4621b1b` via PR #11 on 2026-07-26, but the session that followed ended without `/update-sop`, so the line's own clear-on-merge instruction never ran and it read as in-flight for eight days. See Batch 0.29.

*(This section uses the legacy flat-line format. `scripts/refresh-in-flight.sh` requires an `<!-- in-flight:start -->` sentinel that `docs/agent-memory.md` does not yet have; run `/update-agent-sop` to pick up the sentinel template.)*

---

## Decisions Made

See docs/agent-memory/decisions/. One file per decision. Migrated from legacy narrative on 2026-04-19.

---
## Gotchas and Lessons

See docs/agent-memory/gotchas/. One file per gotcha. Migrated from legacy narrative on 2026-04-19.

---

## Matt's Preferences

- Terse responses, no trailing summaries.
- Australian English in all outputs. No em-dashes.
- Exec-ready formatting: professional, clear, confident.

---

## Completed Work

- 2026-08-03: **P75 shipped** — replication gate (Batch 0.30, commit `04d3722`). `--check-replication` on `scripts/validate-state-transitions.sh`, invoked by new `/update-sop` Step 3e. Answers the question no prior gate asked: not "was this change declared?" but "did it reach the surface that enforces it?". File list is the `baseline_shas` keys, deliberately the same source `/update-agent-sop` reads, so a second hardcoded list cannot drift from it (AC 3, and the bug class the item warns about). Fixtures 15 → 17. Net +1 instruction; D1 broadened rather than adding a check, totals stay 85/94. **The gate fired on its own shipping session** — Step 3e blocked because the repo's `.claude/commands/update-sop.md` had gained Step 3e while the user-scope copy that executes had not. Mirror synced, five baselines refreshed. **A four-agent adversarial re-review of the 2026-07-30 digest overturned two of three initial rejections and most of the proposed work**: the digest's own repo spot-check was four days stale (91/82 vs an actual 94/85), so its "Already addressed?" column was unreliable throughout. One of five findings survived — the 1M context drift at `harness-configuration.md:53`, where `120K tokens (60% of 200K)` was 5x wrong on an Opus 5 default, now restated proportionally. Two findings were already shipped, one would have reversed a reviewed `[WON'T]`, and one asked for a control that would not have contained the incident it cited (the escape ran through a *permitted* egress point). Four proposed additions dropped: a `/doctor` pass whose rule exists three times over already, a duplication check that would have flagged what C15 mandates, and a positioning passage P68 had shipped with the opposite inference. Correctness sweep also fixed `Backlog.md:1311`'s false "flipped twice in three releases" (prescribed by a review a week earlier, only half-applied), a dead "file P53" reference, and `print_help`'s drifted `sed` range. **No Step 1b artifact** — reviewer terminated unreturned at session end; recorded as `review skipped (P75): below-threshold` with the verification-by-execution noted. P76-P82 filed. Decision: `docs/agent-memory/decisions/2026-08-03_solo_divergence-not-duplication-is-the-checkable-bug.md`. Gotcha: `docs/agent-memory/gotchas/2026-08-03_solo_a-digest-can-report-stale-repo-state-while-claiming-a-fresh-fetch.md`.
- 2026-08-03: Tracker drift reconciliation (Batch 0.29, no P-number). `/restart-sop` Step 4 surfaced four inconsistencies, all downstream of Batch 0.28 ending without `/update-sop`: an unrecorded merged commit, an In-Flight line that never executed its own clear-on-merge instruction, a resume snapshot whose two stated next-actions were both already done, and a feature-map roadmap still listing P24 three months after it shipped. Backfilled Batch 0.28 across all four trackers, filed P74 retroactively, cleared In-Flight, rewrote the resume, and marked the feature-map's stale Recently Shipped sub-table superseded rather than maintaining two shipped lists. `/update-agent-sop` found real drift rather than just a stale date: Batch 0.27 changed `update-sop.md` and `sop-checker.md` without re-running the sync, so the user-scope `/update-sop` that actually executes in every session ran for eight days without P66's enumerated skip token and P70's bounded test gate. Both mirrors synced forward, six baselines refreshed. Lite benchmark correctly not owed — no agent-facing instruction text changed in this batch. **P75 filed** `[OPEN] [Bug]`: no gate asks whether a shipped change reached the surface that enforces it, and this is the second occurrence in opposite directions (the first being the RepCanvas Step 3e leak in Batch 0.26). Only the date-based staleness warning happening to be overdue surfaced it. Gotcha: `docs/agent-memory/gotchas/2026-08-03_solo_merging-without-update-sop-strands-every-tracker.md`. Decision: `docs/agent-memory/decisions/2026-08-03_solo_retroactive-filing-ships-as-two-commits.md`.
- 2026-07-27: Batch 0.28 — README benchmark caveat + P74 hook replacement. Commit `314b98f` (PR #12). *Backfilled 2026-08-03.* `README.md:229` still cited "+33% on vague prompts" bare after P68 caveated `:19`; now attributed to Round 2 and pointed at Limitations, the figure unchanged. **P74** `[Bug]`: `npx block-no-verify@1.1.2` replaced with a local argv-matching `block-hook-bypass.js` — the npx form hit the network on every Bash call, substring-matched so quoted commit-message bodies and unrelated multi-statement commands tripped it, and was evaded via a variable or `git -c core.hooksPath=/dev/null`. Re-verified 2026-08-03 across 8 cases, all correct. **The session left no tracker trace at all**, which is the whole reason the drift existed; recorded as a gotcha at `docs/agent-memory/gotchas/2026-08-03_solo_merging-without-update-sop-strands-every-tracker.md`.
- 2026-07-26: P66 + P70-P73 — validator correctness and gate coherence (Batch 0.27). Closed every item Batch 0.26 filed plus P66, deferred since 2026-07-06. P73 `[Bug]`: validator's Batch Log BLOCK unreachable under `set -euo pipefail`; guarded, plus `.expect-stdout` fixture assertions and an overridable `VALIDATOR` so fixtures provably discriminate. P66 `[Bug]`: Tier A unification — P44 gate accepts `review skipped (P<n>): <enumerated>`, bound to its own P-number and `\b`-anchored, the same token S7 / sop-checker / security.md rule 11 read. P70 `[Bug]`: test-gate escape bounded by three verifiable conditions + T1. P71: `[DEFERRED]` requires `**Reopens when:**` across six surfaces + B12. P72 `[Feature]`: `run-multi-round.sh` gains `--lite`/`--tasks`/`-k`/`aggregate`. Totals 83/92 → 85/94; fixtures 12 → 15. **Reviewer returned 3 HIGH, all defects in this session's own work** — P73's audit missed `:164` so `--check-drift` still exited 128 silently outside a git repo and the "audited all 8 sites" claim was false (28 exist); T1's grep failed on the file it gates; `aggregate` pooled rounds, reporting two opposite decisive results as `+0.00`. Decision: `docs/agent-memory/decisions/2026-07-26_solo_benchmark-rounds-are-reported-never-pooled.md`. Gotcha: `docs/agent-memory/gotchas/2026-07-26_solo_auditing-by-command-name-misses-failures-by-exit-code.md`.
- 2026-07-26: P67-P69 — 2026-07-24 digest review plus a three-paper review (Batch 0.26). P67 `[Bug]`: Step 1b now waits for the background reviewer and confirms the artifact on disk before the substance assertion (CC 2.1.198); the defect reproduced live during this session's own reviewer turn. P68: benchmark methodology gains k≥3/k≥5 repetition with median+range, frozen lite subset {05,07,08}, capability suite named, Task Inventory 4→8 rows, k=1 caveat on the published figure — driven by arXiv:2602.11619's 29.3% single-run misranking measurement. P69: `security.md` rule 11 (enforcement layer as tamper surface) + S7 check + `code-reviewer` gate-integrity bullet; totals 82/91 → 83/92. **Two of five digest findings rejected on verification** — 2.1.219 reverted the nesting default finding 2 relied on, and finding 3 keyed guidance to frontmatter absent from resume files. **Reviewer turn returned 2 HIGH, both on P69's own S7**: the `<merge-base>..` range was empty for merged commits so the check could never fail, and its PASS condition was unreachable through the SOP's own workflow; fixed pre-ship along with the identical pre-existing defect in R1. P70-P73 filed `[OPEN]`. `/update-agent-sop` run: 10/10 mirrors, 6 baselines, RepCanvas Step 3e removed from user scope, `security.md` exclude moved to hst-tracker's config. Commits `842f835`, `9f5ac2c`. Decision: `docs/agent-memory/decisions/2026-07-26_solo_s7-pass-is-tag-agnostic-not-tag-gated.md`.
- 2026-07-06: P64 — AGENTS.md positioning shipped (second session same day). Decisions recorded in Backlog: positioning only; AGENTS.md-canonical shape for multi-tool adopters; full support deferred until Claude Code reads AGENTS.md natively (reopen trigger — do not re-litigate). README comparisons section gains "vs AGENTS.md" subsection.
- 2026-07-06: P60-P63 + P65 — Digest-review batch (Batch 0.23). P60 facts correction: token equivalences marked 4.x-tokenizer-relative (Sonnet 5 +~30%, default from 1 Jul), `/usage` cited as primary measurement source, External validation section in benchmark README (arXiv:2605.20049 + Anthropic expertise study). P61 memory poisoning: `security.md` rule 1 extended to own context files, `/restart-sop` Step 4 memory-poisoning guard (advisory; auto-filers legitimate), S4 Important check. P62 `[Bug]`: `/update-sop` pre-flight check for background-by-default subagents (CC 2.1.198), `multi-agent.md` Common Mistakes entry, M6 check. P63 CI hardening: `security.md` rule 10 (read-only tokens, SHA-pinned actions, no wildcard non-write users; CVE-2025-66032), deny-rule examples under rule 7, S5 Critical + S6 Important conditional checks. P65 corrections: `finish.md` `/simplify` version note (2.1.147 rename reverted in 2.1.152), README counts 82/91, config bump + 6 baselines. P64 AGENTS.md filed `[has-open-questions]`. ship-sop P12/P13 filed via PR #3. Skip list (7 items) in P60 Backlog entry. Decision: `docs/agent-memory/decisions/2026-07-06_solo_digest-review-remove-or-sharpen-filter-applied.md`.
- 2026-05-28: P59 — Step 1b reviewer-gate tightening + new cross-layer-rules guide. `docs/sop/claude-agent-sop.md` Step 1b gains explicit triggers (size / SOP-self-mod / project-declared paths), skip list (docs-only / test-only / dep bumps), `review_loc_threshold: 0` always-on semantics; `docs/templates/agent-sop-config-template.json` gains `review_triggers: []`. New `docs/guides/cross-layer-rules.md` (~165 LOC, inventory-first). Cross-refs in CLAUDE.md and `sop-common-mistakes.md`. ship-sop README paragraph clarifies per-stop vs per-session relationship. Reviewer artifact at `docs/reviews/2026-05-28_solo_P59.md`. PR #6 (agent-sop), PR #2 (ship-sop). Commit `dd24ca3`. Decision: `docs/agent-memory/decisions/2026-05-28_solo_p59-tighten-step1b-not-mandate-every-pr.md`.
- 2026-05-04: P58 — Karpathy before/after pattern extended across the SOP. Core SOP gains pairs on Rule 1 (delete vs in-place) and Rule 6 (silent pick vs surface interpretations) — net +474 bytes, under the +500 byte cap. `planner.md`, `security-reviewer.md`, and `e2e-runner.md` each gain 1-2 pairs. Three reference agents mirrored to user scope; baselines refreshed.
- 2026-05-04: P57 — Config `exclude` field. `agent-sop-config-template.json` gains `"exclude": []` field with note. `/update-agent-sop` Step 2 introduces EXCLUDED classification (skipped before fetch/SHA/baseline lookup); Steps 3/4 skip EXCLUDED files; Step 6 reports them separately. Replaces the older workaround of freezing baseline SHAs with explanatory notes (e.g. `docs/sop/security.md` collision pattern). Migration note for hst-tracker filed. User-scope mirror updated; baseline refreshed.
- 2026-05-04: P55 — Sycophantic reviewer detection. `--assert-review` now requires findings or the reasoned-no-issues line to cite at least one concrete anchor (file path with line number, or backticked symbol/path). Sycophantic `No issues — looks great` blocked; structurally-complete-but-vacuous reviews blocked. SOP §6 Step 1b rationale paragraph cites Anthropic's 30 April 2026 baseline (9% / 25-38%). `code-reviewer.md` Finding Voice gains parallel paragraph. Four fixtures (2 legal + 2 illegal) and an extended runner. Backwards-compat — all 4 existing `docs/reviews/*.md` still pass. User-scope `code-reviewer.md` mirrored.
- 2026-05-04: P24 — Multi-agent optimisation guide. New canonical entry-point at `docs/sop/multi-agent.md` (two patterns, decision tree, optimisation rules, Common Mistakes, cross-references). Section 0 multi-agent paragraphs collapsed to a 1-line pointer; Section 16 renamed and shortened to a pointer paragraph. No content duplicated per Rule 2 — deep mechanics stay in `multi-agent-parallel-sessions.md` and `multi-agent-context-routing.md`. Both templates + CLAUDE.md gained Key Documents rows. M1-M5 compliance checks already shipped via P43; new guide cross-references them.
- 2026-05-04: P56 — Backend assumptions section (§15.5) added to `claude-agent-sop.md`; `/restart-sop` Step 0e advisory fires when `ANTHROPIC_BASE_URL` is non-Anthropic. User-scope mirror updated; baseline refreshed. Source: `agent-sop-research-digest-2026-05-04.md` Finding 2. P55 (sycophantic reviewer detection) filed `[OPEN]` for next session per Matt's build-order instruction.
- 2026-05-02: P54 — Multi-agent hardening + perf gates + worktree advisory. Five tightenings prompted by hst-tracker code review: sibling-worktree advisory, per-agent in-flight files (`scripts/refresh-in-flight.sh`), `/update-sop` perf gates (Steps 4/7/8 parallel + skip predicates), multi-agent guide §7/§8, `/update-agent-sop` manifest extension. Plus a follow-up retrospective Step 1b reviewer-turn that surfaced 1 HIGH + 2 MEDIUM + 1 LOW (commit `7587d5b`).
- 2026-04-26: P52 — Learnings capture pattern shipped doc-only. `harness-configuration.md` section f rewritten as "Learnings capture (PreCompact + Stop)" with full 4-category prompt structure (surprises / key learnings / hook recommendations / skill recommendations), idempotent jq-merge example for ship-sop coexistence, boundary note. `docs/agent-memory/learnings/README.md` explains lifecycle and filename convention. `/update-sop` Step 5 review-and-archive sub-step (project + user-scope mirror). agent-sop `.gitignore` excludes live entries; archive subtree committed. Scope cuts vs proposal: no runtime script, no setup.sh changes, no new /update-sop step, archive over Rule 2 carve-out. Decision file: `2026-04-26_solo_p52-learnings-doc-only.md`.
- 2026-04-24: P49 — `/update-sop` timing measurement programme closed across 3 samples. Decision: ABANDON the refactor. Per-step median/max showed no step dominates enough to justify rewrite; agent-side drafting steps each produce durable artifacts serving distinct audiences. Decision file: `2026-04-24_solo_p49-update-sop-timing-summary.md`.
- 2026-04-24: P51 — `/restart-sop` parallel-reads execution note + targeted Backlog-read pattern (`grep -n` + `Read offset/limit`) added to Full and Lightweight starts. User-scope mirror updated. P49 sample 2 captured as part of this session's `/update-sop`. Decision file: `2026-04-24_solo_p51-safe-optimisations-before-full-trim.md`.
- 2026-04-20: P48 — Reviewer voice rules lifted into `code-reviewer.md` (Finding Voice section: drop/keep lists, three before/after examples, auto-clarity carve-out). Backlog item-sizing pedagogy added to `backlog-template.md`. Both patterns sourced from direct review of `levu304/claude-code-boilerplate`; wholesale absorption rejected. User-scope `code-reviewer.md` mirrored, baselines refreshed.
- 2026-04-20: P47 — Drift-check legacy-resume fallback now fires regardless of agent-id. `/restart-sop` Step 0d mirrored. One-line advisory on non-`solo` fallback points at `/migrate-to-multi-agent`. Adjacent `set -u` bug fixed (`$root` unbound when `CLAUDE_AGENT_ID` preset). Four dogfood scenarios pass. User-scope slash command mirrored.
- 2026-04-09: P28 — Research digest: S3 skip-permissions check, context-management.md (compaction/clearing/memory API), memory API note in Section 1, Section 18 SOP evolution loop, sop-hill-climbing.md guide. 8 digest suggestions evaluated; 5 implemented, 8 skipped (would add tokens without proven quality improvement).
- 2026-04-09: P27 — Managed Agents integration. Outcome rubrics (Definition of Done) added to SOP Section 12 and both templates. Permission policy safety for benchmarks. Multi-agent callable patterns in Section 16 with coordinator/specialist configs. Section 17 Managed Agents Integration Guide (memory store mapping, skills guidance, session lifecycle, outcome grading). Benchmark README updated with Managed Agents harness design.
- 2026-04-09: P26 — Benchmark-driven optimisations applied. Common Mistakes mandatory for code projects. 300-line limit for code CLAUDE.md. Intent-only dispatch enforced (Area|File deprecated). Lightweight start for [ok-for-automation]. Multi-agent context routing (Section 16). agent-memory.md optional <10 sessions. Benchmark safety rules (no push to main). Naming convention gotcha requirement.
- 2026-04-09: P25 — Benchmark findings incorporated into SOP. New Section 15 (Benchmark-Proven Practices): Common Mistakes requirement, intent-rich dispatch pattern, vague prompt resilience. Both templates updated. 4 new compliance checks (BP1-BP4). README updated with results. Implementation guide updated.
- 2026-04-09: P23 — SOP Benchmark Framework shipped with two rounds. Round 1 (precise prompts): SOP 68/72 vs Baseline 62/72 (+8%). Round 2 (vague prompts, sharpened SOP): SOP 78/84 vs Baseline 50/84 (+33%). Key finding: "Common Mistakes" section prevented 2 production bugs. Intent-rich dispatch outperforms file-path lists. Vague prompts amplify SOP advantage dramatically. Full results at docs/benchmark/results/.
- 2026-04-08: P22 — Session slash commands shipped. `/restart-sop` and `/update-sop` in `.claude/commands/`. All SOP docs updated to reference as mandatory. Installed at user level for all projects.
- 2026-04-08: P21 — Setup script shipped at `setup.sh`. Bash onboarding script with --code and --force flags. README updated to recommend as primary setup path.
- 2026-04-08: README rewritten: removed all em dashes, added verified token efficiency section (measured per-file costs, model-specific context windows, library-vs-session ratio), ECC attribution corrected to affaan-m.
- 2026-04-08: P6 — New project walkthrough shipped at `docs/examples/new-project-walkthrough.md`. Uses concrete Taskflow example.
- 2026-04-08: P7 — Existing project migration guide shipped at `docs/examples/existing-project-migration.md`. Checklist format, 7 steps.
- 2026-04-08: README updated with ECC attribution, new examples and templates tables.
- 2026-04-08: P3 — Agent memory template shipped at `docs/templates/agent-memory-template.md`.
- 2026-04-08: P4 — Backlog template shipped at `docs/templates/backlog-template.md`.
- 2026-04-08: P5 — Build plan template shipped at `docs/templates/build-plan-template.md`.
- 2026-04-08: Token optimisation commit — SOP line-range index, unified checklists, merged dispatch, trimmed templates.
- 2026-04-08: sop-checker agent updated for C3 (5 steps), C4 (7 steps), C5/C7 (merged header).
- 2026-04-08: Implementation guide updated for current SOP state.
- 2026-04-08: README rewritten.
- 2026-04-08: P14 — Security guidance document shipped at `docs/sop/security.md`.
- 2026-04-08: P15 — Hooks guidance with 6 reference implementations shipped at `docs/sop/hooks.md`.
- 2026-04-08: P16 — Code quality rules added to `docs/templates/claude-md-template-code.md`.
- 2026-04-08: P17 — 4 reference agent definitions shipped in `.claude/agents/`.
- 2026-04-08: P18 — Auth, Database, Key Commands, Design System sections expanded in code template.
- 2026-04-08: P19 — Continuous learning pattern added to SOP Section 12.
- 2026-04-08: P20 — 6 new compliance checks added to checklist Section 9. sop-checker agent updated.
- 2026-04-07: Batch 0.1 — Project scaffold created. All standard files in place.
- 2026-04-07: P1 — Core SOP document published at `docs/sop/claude-agent-sop.md`.
- 2026-04-07: P2 — CLAUDE.md base template published at `docs/templates/claude-md-template.md`.
- 2026-04-07: P11 — CLAUDE.md code template published at `docs/templates/claude-md-template-code.md`.
- 2026-04-07: 9 SOP improvements applied — Quick Reference Card, template split, `[WON'T]` format, project_resume.md naming lock, Key Documents sync rule, `[VERIFIED]` non-code definition, interrupted session recovery protocol, Issue Tracker Sync Rules rename, phase boundary definition.

---

## Archived

Historical decisions moved to docs/agent-memory/decisions/archive/ on 2026-04-19 (P43 Batch 1.6 migration). Historical gotchas moved to docs/agent-memory/gotchas/archive/.

