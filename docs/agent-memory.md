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

*(none)* -- P23 round 2 complete 2026-04-09, moved to Completed Work.

---

## Decisions Made

*Pre-2026-04-09 entries (initial scaffold + ECC adaptation + token optimisation + foundational rule decisions) relocated to Archived on 2026-04-17 (P40). Decisions still in force are encoded in the SOP docs themselves (Section 0 rules, file specs, compliance checklist). The Archived entries preserve the why/when context.*

- 2026-04-17: P41 — README rewritten 465 → 119 lines. Hero reframed: "Standard operating procedures and product management discipline for Claude Code sessions" anchored on the standard file set + three slash commands rather than abstract benefits. New Backlog discipline + Cross-session memory sections make the PM-discipline angle concrete (status/type tag order, P-numbers, append-only batch logs, status-only-in-Backlog rule, snapshot vs log semantics). Removed: TOC, token-efficiency math wall, four-table What's Included block, repository tree, expanded session-checklist + six-rules commentary, A/B benchmark badge, Acknowledgements section. Added: dedicated License section. Aesthetic aligned with claude-code-action and superpowers reference READMEs. GitHub About refreshed to match.
- 2026-04-17: ECC verbatim review completed. Diffed `~/Projects/everything-claude-code` against our four reference agents (`code-reviewer`, `security-reviewer`, `planner`, `e2e-runner`), `docs/sop/security.md`, and `docs/sop/harness-configuration.md`. Finding: no copied prose blocks. Structural overlap exists (YAML frontmatter format, OWASP Top 10 enumeration, Playwright CLI listings, common section headings, three-tier scoring concept) but all are public-spec / required-syntax / common-pattern territory, not copyrightable. Decision: Acknowledgements section removed from README per Matt's directive ("using patterns is ok"). MIT attribution requirements not triggered.
- 2026-04-17: P40 — Section 14 Common Mistakes table moved to `docs/guides/sop-common-mistakes.md`; Section 15.4 Managed Agents API safety block moved to `docs/guides/managed-agents-integration.md`. Core SOP ~189 → ~178 instructions (under 150 soft cap on first measure since Rule 5 was added in P32). Same session: CLAUDE.md Recent Work compacted (older session-days rolled into one-liners) and pre-2026-04-09 entries here moved to Archived. Intent: cut active-context bloat without losing history. Both moves preserve content, only relocate it.
- 2026-04-17: Section 0 expanded from 2 to 5 non-negotiable rules. Rule 3 (no opinion, state facts), Rule 4 (back-and-forth before planning), Rule 5 (≤150 soft / 200 hard instruction cap). Added to override-everything-else tier so CLAUDE.md cannot weaken them.
- 2026-04-17: SOP instruction-budget trim (P32). Pre-trim: 392 instructions across 5 SOP files; `claude-agent-sop.md` alone was ~230, breaching its own Rule 5. Post-trim: core SOP ~193, total ~343. Under the 200 hard ceiling, still ~43 over the 150 soft cap. Cuts: Quick Reference Card (100% duplicate), Section 17 Managed Agents extracted to `docs/guides/` as P33 (deferred), Sections 12/16/18 extracted to guides, `hooks.md` + `context-management.md` merged into `harness-configuration.md`, `security.md` collapsed with container/network content split to `sandboxing.md`. Compliance-checklist left intact because sop-checker agent references check IDs — parametrising would break tooling. Archive at `.archive/sop-pre-trim-2026-04-17/` (gitignored). Candidate follow-up cuts (to reach 150): Section 14 mistakes table to guide, Section 15.4 benchmark safety to managed-agents guide, Section 1 compression, Section 8 tag taxonomy consolidation.
- 2026-04-17: Rule 5 instruction-budget counting method. Each distinct directive = 1 (numbered rules, checklist items, "always/never/must" statements, table rows mandating behaviour). Narrative, examples, code blocks, section headings, descriptive tables do not count. Budget is per-agent (SOP + CLAUDE.md + agent definition + rules files + invocation prompt), not per-repo.
- 2026-04-17: Reviewed forrestchang/andrej-karpathy-skills (52k stars, ~60-line CLAUDE.md + packaging). 3 of 4 principles duplicate existing SOP coverage. 1 phrase worth porting: "every changed line must trace directly to the user's request" (generalises Rule 1 from deletes to additions). Format ideas worth adopting: annotate each rule with the failure mode it prevents; before/after examples for Common Mistakes in `docs/guides/`.
- 2026-04-17: P39 — Closed the measurement gap the benchmarks didn't cover. R1/R2/R5 score single-task quality only; they end at "code shipped" and ignore the SOP's real product (project state the next session can pick up cleanly). Three supplementary measurements added: (1) session-hygiene scoring rubric — 7 extra 0/1 dimensions (test gate, Backlog, feature-map, agent-memory, batch log, resume, docs commit); baseline scores 0/7 by construction so this is demonstrative not comparative. (2) Continuity benchmark methodology — dependent task pairs where task 2 depends on a gotcha task 1 naturally surfaces; measures whether session N+1 benefits from session N. Sample pair (tonnage client-side fix → adjacent server-side gap) included. (3) Longitudinal exhibit — hst-tracker's actual artefact counts: 86 dated decisions, 23 batch-log entries, 18 Recent Work entries, 64 docs-only commits, 4,628 lines across tracking files. A no-SOP project of equivalent age has 0 of each. Makes continuity value visible without running any agent. Artefacts: docs/benchmark/README.md (hygiene + exhibit sections), docs/benchmark/continuity-methodology.md (new), README.md (new "What the benchmarks don't measure" section). Continuity benchmark execution deferred to R7.
- 2026-04-17: P38 — R5 post-trim benchmark pilot. 4 vague tasks against hst-tracker commit 1c73062 (same as R2). SOP 75/84 vs baseline 61/84 = +16% aggregate. 3 of 4 tasks won by SOP; task 08 flipped to baseline (scorer error on design tokens contributed — `--color-accent-light` is real, 87 occurrences in index.css). R2 was +33%; margin narrowed. Major drivers of narrower gap: Opus 4.7 baseline more capable than R2's 4.6 (nosop didn't crash on task 07, used correct tokens on task 08); subagent methodology not comparable to fresh CLI sessions; single round not statistically averaged. Spot check (task 05 tonnage) held strongly — baseline regressed the B1 fix which is the catastrophic miss SOP specifically prevents. Verdict: trim did not break SOP, but the +33% figure is not defensible post-trim without a fresh R6 on CLI sessions same-model-as-R2. README updated: badge changed to "directional +16% to +33%"; R5 section added with caveats; Key finding #5 qualified to R2-specific.
- 2026-04-17: P37 — Reviewed thedotmack/claude-mem. 60.8k-star Claude Code plugin, substantive (daemon + SQLite + ChromaDB + MCP server + 5 lifecycle hooks + React UI). Categorically different from Agent SOP: claude-mem is observation/retrieval infrastructure, Agent SOP is prescription. Three portable patterns adopted: (1) progressive retrieval (index → narrow → fetch) as routing rule in multi-agent guide, (2) capture-time redaction via `<private>` tags in security.md (leaked-store threat model vs retrieval-time filtering), (3) hooks-must-fail-open in harness-configuration.md. Rejected: DB-backed memory, auto-capture, MCP server dependency — would compromise plain-markdown philosophy. Positioned claude-mem as optional complement (not competitor) in optional-patterns.md. Red flag: claude-mem cites "10x token savings" marketing, no A/B benchmark — Agent SOP's P23 benchmark (+33%) is stronger evidence. Bus-factor risk (single maintainer Alex Newman).
- 2026-04-17: P36 — SOP sync mechanism shipped. Distribution model is copy-based (not symlinks/submodules). `/update-agent-sop` command (user-scope) pulls from local path first, GitHub raw fallback. Three-way diff per file using SHA-256 baselines stored in `~/.claude/agent-sop.config.json`. Never force-overwrites locally modified files. `setup.sh` now distributes the full pristine-replica surface (17 files): SOP docs + guides project-scope, slash commands + reference agents user-scope. `/restart-sop` gained a Step 0 staleness check (one-line warning, non-blocking). Version markers placed as HTML comment (plain markdown) or `sop_version:` YAML field (files with frontmatter) — advisory only, SHA is authority. First-run bootstrap captures upstream as baseline; pre-existing local divergence surfaces immediately. GitHub repo slug locked as `mmjclayton/agent-sop`.
- 2026-04-17: P35 — Section 4 Versioning Rules removed (~8 instructions). Section 4 was a pure duplicate of Section 0 Rule 1 "How this works" bullets, self-declared by its own "See Section 0" opening. Replaced with a one-line pointer. Core SOP ~197 → ~189. Lowest-risk cut identified from the P32 candidate list — no external references to "Section 4" by number (grep-verified).
- 2026-04-17: P34 shipped three karpathy-skills findings. (1) Rule 1 extended to cover additions via trace-to-request: every changed line must justify to the user's request. (2) Rule 6 added: surface interpretations before acting on ambiguous requests. (3) Italic *Prevents:* annotation added to each of the six non-negotiable rules — format-only, zero instruction cost. Net count: claude-agent-sop.md ~193 → ~197, still under 200 hard ceiling. The before/after examples idea deferred to a future guide.
- 2026-04-13: Research digests bias toward "things to add". Future digest reviews must default to "what does this remove or sharpen" rather than "what could we add". Adding 4 items that don't sharpen anything is exactly what the benchmark warned against (Round 2 won by sharpening, not adding). When re-evaluating Tier 1 slate from the 2026-04-13 digest, 3 of 4 items dropped on this filter; only the Claude Code v2.1.101+ version note shipped.
- 2026-04-13: Source verification is mandatory before acting on research digests. The 2026-04-13 digest cited OpenAI AgentKit as April 2026 (it actually launched October 2025) — the digest's "Already addressed? No" framing was misleading. Always WebFetch / WebSearch sources before treating findings as actionable.
- 2026-04-13: Conservative claim policy — never claim "100% accuracy" or unverified benchmark scores. Use "deterministic / reproducible" (defensible: same input → same output) instead. Always run benchmarks before claiming scores in README.
- 2026-04-09: Graphify knowledge graph tool evaluated for agent-sop and hst-tracker. Not adopted. For agent-sop: corpus too small, dispatch table already covers navigation. For hst-tracker: SOP dispatch + Common Mistakes already handles 90% of agent navigation. A hand-written ARCHITECTURE.md would deliver more value than an auto-generated graph for codebases the owner understands.
- 2026-04-09: P24 (multi-agent optimisation) scoped with concrete acceptance criteria. Justified as community value even if not immediately needed for solo serial-agent workflow.
- 2026-04-09: Benchmark framework uses git worktrees in hst-tracker for isolation. Baseline condition strips CLAUDE.md (replaced with 4-line stub), removes docs/sop/, docs/agent-memory.md, .claude/agents/, .claude/commands/, .claude/skills/, brand-voice, style-guides. SOP condition is untouched. Both get identical task prompts. Scoring is blind (reviewer does not know which is which).
- 2026-04-09: Four benchmark tasks chosen: Pill refactor (pattern-following), import preset tests (test writing), page titles (feature), server utils tests (edge case coverage). All safe without DB access.
- 2026-04-09: P24 (multi-agent optimisation) scoped but deferred until benchmark results show what matters most.

---

## Gotchas and Lessons

- [SUPERSEDED - 2026-04-07: replaced by "never delete without a trace" — in-place updates are now expected] 2026-04-07: The additive-only rule applies to the SOP docs themselves. When the SOP is updated, append corrections below existing content — do not overwrite sections.
- 2026-04-07: Do not store derived facts in agent-memory.md — test counts, line numbers, file sizes, dependency versions go stale immediately. Store the rule, not the measurement.

---

## Matt's Preferences

- Terse responses, no trailing summaries.
- Australian English in all outputs. No em-dashes.
- Exec-ready formatting: professional, clear, confident.

---

## Completed Work

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

### Pre-2026-04-09 Decisions (relocated 2026-04-17 / P40)

Rules and policies set during the initial scaffold + ECC adaptation phase. Every entry here is still in force unless explicitly superseded — the encoded rules live in the SOP docs themselves (Section 0 rules, file specs, compliance checklist, both templates). These entries preserve the why/when context.

- 2026-04-07: Project name is `agent-sop`. Short, descriptive, works as a GitHub repo name.
- 2026-04-07: Markdown only. No build process, no code, no dependencies. (Note: setup.sh added 2026-04-08 as a shell script, but the SOP library content itself remains markdown-only.)
- 2026-04-08: README must use Australian English, no em dashes. Hyphens minimised in prose; colons, periods, and conjunctions preferred.
- 2026-04-08: ECC attribution credits affaan-m (github.com/affaan-m/everything-claude-code), not Anthropic. ECC is a community project.
- 2026-04-08: Token efficiency claims in README must be verified with measured data. Two estimation methods used (words x 1.3, chars / 4) because no public offline Claude tokeniser exists.
- 2026-04-08: Claude Code custom slash commands require YAML frontmatter with a `description` field to be recognised. Without it they appear in the list but fail with "unknown skill" when invoked.
- 2026-04-08: Project-level commands (`.claude/commands/`) appear as `/project:command-name`. User-level commands (`~/.claude/commands/`) appear as `/command-name` without prefix. For commands that should be available everywhere, install at user level.
- 2026-04-07: File structure — SOPs in `docs/sop/`, templates in `docs/templates/`, examples in `docs/examples/`.
- 2026-04-07: This project follows its own SOP — including additive-only writes and session checklists.
- 2026-04-07: P1 and P2 shipped as part of the initial scaffold (docs already existed from prior Cowork session).
- 2026-04-07: CLAUDE.md template split into base (`claude-md-template.md`) and code variant (`claude-md-template-code.md`). Base is stack-agnostic; code variant adds Auth, Database, Design System, and code build rules. P11 assigned to the code variant.
- 2026-04-07: project_resume.md filename is locked to exactly `project_resume.md` across all projects — no project-specific prefixes.
- 2026-04-07: `[WON'T]` tag now requires inline reason: `[WON'T] [Type] — Reason: ...`
- 2026-04-07: `[VERIFIED]` definition extended — code projects = tested in production; docs projects = reviewed by project owner and confirmed accurate.
- 2026-04-07: CLAUDE.md hard size limit set at 200 lines / 2,000 tokens (Anthropic guidance). Overflow goes to agent-memory.md or build plans.
- 2026-04-07: Context compaction threshold set at 60% (not 95%). At 60% capacity, wrap the current batch and run the session end checklist.
- 2026-04-07: Auto-memory (`~/.claude/projects/.../memory/`) is unreliable per community reports. Manual docs/agent-memory.md is the authoritative context source.
- 2026-04-07: Optional patterns section (Section 12) added - claude-progress.txt for human-readable status, .claude/agents/ for sub-agent delegation. Sections renumbered: old 12 is now 13, old 13 is now 14.
- 2026-04-07: CLAUDE.md 200-line limit reframed — applies to per-session sections only. Reference sections (Auth, Database, Design System) may extend beyond.
- 2026-04-07: Override hierarchy clarified — CLAUDE.md can override project-specific conventions but not the two non-negotiable rules (additive-only, single source of truth). [Note: Section 0 has since expanded to six non-negotiable rules — see P32 and P34 entries above.]
- 2026-04-07: Multi-agent contention rule added to Section 0 — separate branches, merge sequentially, resolve conflicts by appending both entries.
- 2026-04-07: Key Documents table in agent-memory.md replaced with pointer to CLAUDE.md — eliminates duplication per single-source-of-truth rule.
- 2026-04-07: "Additive-only" reframed to "never delete without a trace". In-place updates (status changes, folding answers, correcting errors) are expected. Silent removal is not. Based on real-world feedback from multi-session usage.
- 2026-04-07: Explicit conflict resolution precedence added: code/git > CLAUDE.md > Backlog.md > build-plan > feature-map > agent-memory > resume point.
- 2026-04-07: agent-memory.md vs auto-memory delineated: repo-committed for facts any contributor needs, local auto-memory for user preferences and session state.
- 2026-04-07: Test gates added to session-end checklist (step 1 for code projects).
- 2026-04-07: project_resume.md changed from prepend-only to overwrite (snapshot model). History belongs in batch logs.
- 2026-04-07: Schema change protocol added to SOP Section 12 and code template.
- 2026-04-07: Backlog archive threshold added — move shipped items older than 90 days to archive when file exceeds ~2,000 lines.
- 2026-04-07: "No derived facts in memory" rule added — store rules not measurements (test counts, line numbers, versions go stale immediately).
- 2026-04-07: Multi-agent contention expanded — docs conflicts resolve by appending, code conflicts require reading both versions, semantic conflicts flagged for human resolution.
- 2026-04-08: Token optimisation applied — SOP line-range index (saves ~900 tokens), unified checklists to 5 start / 7 end, merged Key Documents + Dispatch into single section, trimmed template Backlog Management from ~47 to ~15 lines. Net -100 lines across templates.
- 2026-04-08: Compliance checks C3 updated to 5 steps (was 7), C4 to 7 steps (was 8), C5/C7 accept merged "Key Documents & Dispatch" header.
- 2026-04-08: P3-P5 standalone templates shipped. All High priority items now complete.
- 2026-04-08: Implementation guide updated for unified checklists, merged dispatch, and new Step 7 (security, hooks, agents, code quality).
- 2026-04-08: README fully rewritten to reflect current state (12 shipped items, 5 agents, ~70 checks).
- 2026-04-08: Security guidance adapted from ECC security guide, not copied. Rewritten in Agent SOP voice (Australian English, no em-dashes, direct). Covers prompt injection, secret scanning, MCP trust, sandbox, memory hygiene.
- 2026-04-08: Hooks guidance covers all 6 Claude Code hook types with reference JSON config examples. Hooks automate SOP checklists but do not replace them.
- 2026-04-08: Code quality rules are language-agnostic defaults in the code template. Projects should add language-specific rules via `.claude/rules/` files.
- 2026-04-08: 4 reference agents (code-reviewer, security-reviewer, planner, e2e-runner) added. All match sop-checker format (YAML frontmatter). code-reviewer and security-reviewer are read-only; planner is read-only; e2e-runner has write access.
- 2026-04-08: Continuous learning pattern added to SOP Section 12. Extraction cadence: per-session (gotchas), every 5 sessions (audit), at 3+ repeats (promote to rule).
- 2026-04-08: 6 new compliance checks in Section 9: S1 (secrets, Critical), S2 (security doc), Q1/Q2 (code quality, code-only), H1 (hooks), G1 (agents). Total checks now 63 (non-code) / 70 (code).
- 2026-04-07: SOP Compliance Checker agent created (P13). Checklist at `docs/sop/compliance-checklist.md`, agent at `.claude/agents/sop-checker.md`. ~59 checks (non-code) / ~64 checks (code) across 8 categories. Three-tier scoring: Critical (cap at 49), Important (5pts), Recommended (2pts).
- 2026-04-07: Self-compliance fixes applied — 8-step session end checklist, [BLOCKED] in tag taxonomy, conflict precedence inline, commit refs in Recent Work and Batch Log, line-range hints in Key Documents. Score: 49 → 100.
- 2026-04-07: hst-tracker compliance checked three times (87 → 87 → 97). Validated the checker agent works against a real code project.
