# Agent SOP — Feature Map & Roadmap

Last updated: 2026-04-20 (P47)

---

## Shipped Documents

| P# | Document | Path | Shipped |
|----|----------|------|---------|
| P1 | Core SOP (9 improvements + v2 feedback iteration) | `docs/sop/claude-agent-sop.md` | 2026-04-07 |
| P2 | CLAUDE.md base template | `docs/templates/claude-md-template.md` | 2026-04-07 |
| P11 | CLAUDE.md code project template | `docs/templates/claude-md-template-code.md` | 2026-04-07 |
| P12 | SOP v2: owner feedback iteration (10 changes) | `docs/sop/claude-agent-sop.md` | 2026-04-07 |
| P13 | SOP Compliance Checker Agent | `.claude/agents/sop-checker.md` + `docs/sop/compliance-checklist.md` | 2026-04-07 |
| P14 | Security guidance | `docs/sop/security.md` | 2026-04-08 |
| P15 | Hooks guidance | `docs/sop/hooks.md` | 2026-04-08 |
| P16 | Code quality rules | `docs/templates/claude-md-template-code.md` | 2026-04-08 |
| P17 | Reference agent definitions (4) | `.claude/agents/{code-reviewer,security-reviewer,planner,e2e-runner}.md` | 2026-04-08 |
| P18 | Expanded code template sections | `docs/templates/claude-md-template-code.md` | 2026-04-08 |
| P19 | Continuous learning pattern | `docs/sop/claude-agent-sop.md` (Section 12) | 2026-04-08 |
| P20 | Compliance checklist update (6 new checks) | `docs/sop/compliance-checklist.md` + `.claude/agents/sop-checker.md` | 2026-04-08 |
| P3 | Agent memory template | `docs/templates/agent-memory-template.md` | 2026-04-08 |
| P4 | Backlog template | `docs/templates/backlog-template.md` | 2026-04-08 |
| P5 | Build plan template | `docs/templates/build-plan-template.md` | 2026-04-08 |
| P6 | New project walkthrough | `docs/examples/new-project-walkthrough.md` | 2026-04-08 |
| P7 | Migration guide | `docs/examples/existing-project-migration.md` | 2026-04-08 |
| P21 | Setup script | `setup.sh` | 2026-04-08 |
| P22 | Session slash commands | `.claude/commands/{restart-sop,update-sop}.md` | 2026-04-08 |
| P29 | Pre-launch README polish + LICENSE + min version note | `README.md`, `LICENSE`, `setup.sh` | 2026-04-13 |
| P30 | Research digest review (verdict only) | `Backlog.md`, `docs/agent-memory.md` | 2026-04-13 |
| P32 | SOP instruction-budget trim (Rules 3-5 added; ~230 → ~193 instructions in core SOP) | `docs/sop/claude-agent-sop.md`, `docs/sop/harness-configuration.md`, `docs/sop/sandboxing.md`, `docs/guides/{optional-patterns,multi-agent-context-routing,managed-agents-integration}.md` | 2026-04-17 |
| P34 | Rule 1 extended (trace-to-request); Rule 6 added (surface interpretations); failure-mode annotations on all 6 rules | `docs/sop/claude-agent-sop.md` | 2026-04-17 |
| P35 | Section 4 Versioning Rules removed (pure duplicate of Section 0 Rule 1) | `docs/sop/claude-agent-sop.md` | 2026-04-17 |
| P36 | SOP sync mechanism — version markers, `/update-agent-sop` command, `setup.sh` expansion, staleness check on `/restart-sop` | `.claude/commands/update-agent-sop.md`, `.claude/commands/restart-sop.md`, `setup.sh`, `docs/templates/agent-sop-config-template.json`, `README.md`, 17 pristine-replica files | 2026-04-17 |
| P37 | claude-mem review — 3 portable patterns adopted: progressive retrieval, capture-time redaction, fail-open hooks. claude-mem positioned as optional complement in `optional-patterns.md` | `docs/guides/multi-agent-context-routing.md`, `docs/sop/security.md`, `docs/sop/harness-configuration.md`, `docs/guides/optional-patterns.md` | 2026-04-17 |
| P38 | R5 post-trim benchmark pilot (+16% aggregate vs baseline, 3 of 4 tasks won; directional not authoritative) + README claim audit (benchmark badge and language tightened) | `docs/benchmark/results/r5-post-trim/summary.md`, `README.md` | 2026-04-17 |
| P39 | Measurement gap closed: session-hygiene rubric (7 new dimensions, 0/1 each), continuity benchmark methodology (dependent task pairs), longitudinal exhibit (hst-tracker artefact counts: 86 decisions / 23 batch entries / 18 Recent Work / 64 docs commits / 4,628 lines) | `docs/benchmark/README.md`, `docs/benchmark/continuity-methodology.md`, `README.md` | 2026-04-17 |
| P40 | Section 14 Common Mistakes table extracted to guide; Section 15.4 Managed Agents API safety block extracted to managed-agents-integration guide; CLAUDE.md Recent Work compacted; agent-memory.md Decisions audited (pre-2026-04-09 entries moved to Archived). Core SOP ~189 → ~178 instructions. | `docs/guides/sop-common-mistakes.md` (new), `docs/guides/managed-agents-integration.md`, `docs/sop/claude-agent-sop.md`, `CLAUDE.md`, `docs/agent-memory.md` | 2026-04-17 |
| P41 | README rewrite (465 → 119 lines), hero reframed to operating-practice + PM-discipline, new Backlog discipline + Cross-session memory sections, License section added, Acknowledgements removed (verbatim review confirmed pattern inspiration only — no copied prose), A/B benchmark badge removed, GitHub About description rewritten | `README.md` | 2026-04-17 |
| P42 | Secondary-tracker reconciliation + `[DEFERRED]` tag. `/update-sop` Step 3b auto-detects tracker files via CLAUDE.md Key Documents scan; Step 11 hard-blocks commit if any finding ID from this session's commits is still `[OPEN]`. `/restart-sop` Step 4 adds advisory drift guard. Section 8 gains `[DEFERRED]` with distinction from `[BLOCKED]`. Compliance B4 + new X6 check, totals 66→67 / 75→76. | `docs/sop/claude-agent-sop.md`, `docs/sop/compliance-checklist.md`, `.claude/commands/update-sop.md`, `.claude/commands/restart-sop.md`, `docs/templates/backlog-template.md`, `docs/templates/claude-md-template.md`, `docs/templates/claude-md-template-code.md` | 2026-04-19 |
| P45 | State-transition validator. `scripts/validate-state-transitions.sh` enforces Backlog status-tag transition graph at `/update-sop` Step 3c. Hard-blocks `<absent>` → `[SHIPPED]`, terminal revivals, and `[SHIPPED]` without Batch Log reference. Zero-dep bash, 0.2s on 200-item Backlog. 6 fixtures + test harness. Includes `--assert-review` subcommand for P44's substance assertion. Section 8 of core SOP gains transition graph (+3 instructions). Compliance B11 added, totals 75→76 / 84→85. | `scripts/validate-state-transitions.sh`, `docs/benchmark/state-transition-fixtures/` (6 fixtures + run-tests.sh), `docs/sop/claude-agent-sop.md`, `docs/sop/compliance-checklist.md`, `.claude/commands/update-sop.md`, `.claude/commands/update-agent-sop.md`, `.claude/agents/sop-checker.md` | 2026-04-19 |
| P44 | Required reviewer turn with substance assertion. `/update-sop` Step 1b invokes `code-reviewer` (or `security-reviewer` for auth/crypto/payment diffs) for any `[Feature]`/`[Refactor]` shipping over threshold (default 50 LOC / 3 files, configurable). Findings written to `docs/reviews/YYYY-MM-DD_<agent-id>_P<n>.md` using new review template. Substance assertion via `--assert-review` (shipped with P45) hard-blocks stub files. Compliance R1 added, totals 76→77 / 85→86. +4 core SOP instructions in Section 6. No human-in-the-loop gate — agent-to-agent review, validator-enforced. | `docs/templates/review-template.md` (new), `.claude/commands/update-sop.md` (Step 1b), `docs/sop/claude-agent-sop.md` (Section 6), `docs/sop/compliance-checklist.md` (R1 + totals), `docs/templates/agent-sop-config-template.json` (thresholds), `.claude/commands/update-agent-sop.md` (manifest), `setup.sh` (template copy) | 2026-04-19 |
| P46 | Actionable drift detection. `scripts/validate-state-transitions.sh --check-drift` compares P-numbers in session commits vs `project_resume_<agent-id>.md` declarations. Hard-blocks over-threshold sessions with no match AND no `## Scope Change` block. Reuses P44 thresholds. `/update-sop` Step 3d wiring; `/restart-sop` Step 0d in-flight reassertion. 3 fixtures. Fixed project-hash path normalization bug (non-alphanumeric-to-hyphen) and pipefail+errexit interaction in config parsing during dogfood. Compliance D1 added, totals 77→78 / 86→87. +1 core SOP instruction. | `scripts/validate-state-transitions.sh`, `docs/benchmark/drift-fixtures/` (3 fixtures + run-tests.sh), `.claude/commands/update-sop.md` (Step 3d), `.claude/commands/restart-sop.md` (Step 0d), `docs/sop/claude-agent-sop.md`, `docs/sop/compliance-checklist.md` | 2026-04-19 |
| P47 | Legacy resume fallback on multi-worktree projects. Drift-check and `/restart-sop` Step 0d now fall back to legacy unsuffixed `project_resume.md` regardless of agent-id (previously only when agent-id was literally `solo`). On non-`solo` agents the fallback emits a one-line advisory pointing at `/migrate-to-multi-agent`. Keeps drift enforcement working on long-lived projects that predate the per-agent filename convention. Adjacent set-u bug fixed (`$root` unbound when `CLAUDE_AGENT_ID` preset). User-scope `/restart-sop` mirrored. Four synthetic scenarios dogfooded. | `scripts/validate-state-transitions.sh`, `.claude/commands/restart-sop.md` (Step 0d + Step 0b note), `docs/guides/multi-agent-parallel-sessions.md`, `~/.claude/commands/restart-sop.md` (user-scope mirror) | 2026-04-20 |

---

## Roadmap

### High Priority

*All high-priority items shipped.*

### Recently Shipped

| P# | Document | Path | Shipped |
|----|----------|------|---------|
| P23 | SOP Benchmark Framework | `docs/benchmark/` | 2026-04-09 |
| P25 | Benchmark findings incorporated | SOP Section 15, templates, checklist, README | 2026-04-09 |
| P26 | Benchmark-driven optimisations | SOP Sections 1,5,11,15,16; templates; checklist | 2026-04-09 |
| P27 | Managed Agents integration + outcome rubrics | SOP Sections 12,15,16,17; both templates; benchmark README | 2026-04-09 |
| P28 | Research digest (context mgmt, evolution, security) | SOP Section 18; docs/sop/context-management.md; docs/guides/sop-hill-climbing.md; compliance S3 | 2026-04-09 |

### Medium Priority

| P# | Document | Path |
|----|----------|------|
| P24 | Multi-agent optimisation guide | `docs/sop/multi-agent.md` |
| P8 | Web app variant | `docs/sop/variants/web-app.md` |
| P9 | Marketing variant | `docs/sop/variants/marketing.md` |
| P10 | Data/analytics variant | `docs/sop/variants/data-analytics.md` |
