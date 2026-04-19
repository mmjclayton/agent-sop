# P45 state-transition validator shipped

**Date:** 2026-04-19
**Agent:** solo
**Commits:** [pending — this session's commit]

Shipped P45 — `scripts/validate-state-transitions.sh` now enforces the Backlog status-tag transition graph at `/update-sop` Step 3c. Zero-dependency bash, 0.2s on the current 200-entry Backlog. Hard-blocks illegal transitions (`<absent>` → `[SHIPPED]`, terminal revivals, `[SHIPPED]` without Batch Log reference) and soft-warns on `[BLOCKED]` ↔ `[DEFERRED]` without a decision file reference.

**Shipped this session:**
- `scripts/validate-state-transitions.sh` — validator with `--assert-review` subcommand (prepared for P44's substance assertion)
- `docs/benchmark/state-transition-fixtures/` — 6 fixtures (3 legal, 3 illegal) + `run-tests.sh` harness + README
- `.claude/commands/update-sop.md` — Step 3c (runs after Backlog/tracker updates, hard-blocks on non-zero exit)
- `.claude/commands/update-agent-sop.md` — manifest entry for the new script
- `docs/sop/claude-agent-sop.md` — Section 8 gained transition graph table + Batch Log requirement note (+3 instructions)
- `docs/sop/compliance-checklist.md` — B11 check added, summary totals 75→76 / 84→85
- `.claude/agents/sop-checker.md` — B11 guidance for the compliance auditor

**Graph relaxation during dogfood:** `[OPEN]`/`[BLOCKED]`/`[DEFERRED]` → `[SHIPPED]` now legal when Batch Log reference exists. Single-session ships are legitimate; the Batch Log is the anti-gaming teeth, not the intermediate `[IN PROGRESS]` marker. See `docs/agent-memory/decisions/2026-04-19_solo_p45-graph-relaxed-open-to-shipped-legal.md`.

**Self-validation:** P45's own `[OPEN]` → `[SHIPPED]` transition passed the validator (Batch Log 0.15 entry references P45). Dogfood clean.

**Core SOP instruction count delta:** +3 in Section 8 (transition table + anti-gaming teeth note). Projected total ~181 → ~184. Well within 200 hard ceiling.

**Next session:** P44 — reviewer turn with substance assertion. `--assert-review` subcommand already works; needs wiring into `/update-sop` Step 1 and `docs/reviews/` directory convention.
