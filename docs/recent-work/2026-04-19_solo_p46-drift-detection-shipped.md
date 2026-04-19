# P46 mid-session drift detection shipped

**Date:** 2026-04-19
**Agent:** solo
**Commits:** [pending — this session's P46 commit]

Shipped P46 — actionable drift detection at `/update-sop` Step 3d. `scripts/validate-state-transitions.sh --check-drift` compares P-numbers in session commit messages against `project_resume_<agent-id>.md` declarations. Hard-blocks over-threshold sessions with no match AND no `## Scope Change` block. `/restart-sop` gains Step 0d in-flight reassertion.

**Shipped this session:**
- `scripts/validate-state-transitions.sh` — `--check-drift` subcommand; project-hash path normalization (non-alphanumeric-to-hyphen, consecutive-hyphen collapse); pipefail-safe config + grep wrappers
- `docs/benchmark/drift-fixtures/` — 5 fixtures covering legal-matching, illegal-mismatch, legal-scope-change, legal-below-threshold, legal-no-declaration + run-tests.sh with per-fixture `.session-size` sidecar support
- `.claude/commands/update-sop.md` — Step 3d (drift check hard-block)
- `.claude/commands/restart-sop.md` — Step 0d (in-flight reassertion at session start)
- `docs/sop/claude-agent-sop.md` — Section 6 Step 3d note (+1 instruction)
- `docs/sop/compliance-checklist.md` — D1 check + summary totals 77→78 / 86→87

**Dogfood result:** reviewer subagent found 7 issues (3 MEDIUM, 4 LOW). 6 fixed in-session, 1 rejected after re-assessment (the AND-vs-OR threshold semantics — reviewer's suggested fix would have inverted the logic; De Morgan confirms AND-skip is correct implementation of OR-fire). Decision file documents the rebut. Additional pipefail+errexit bug discovered and fixed during fix work (grep-on-no-match killing script silently — same class as the config-parse bug from P46's first pass).

All 12 fixtures green (7 state-transition + 5 drift). Real-repo `--check-drift` reports `OK — commits reference declared in-flight item(s): P44 P45 P46`.

**Core SOP instruction count:** +1 in Section 6. Projected ~188 → ~189. Under 200 ceiling with headroom.

**Session summary:** three Reddit-feedback features shipped in one day. P45 → P44 → P46. Each dogfooded on its own diff. P44's reviewer gate caught real defects in P44 and P46 that would have shipped otherwise. That's the action-per-text ratio the action-vs-ceremony test was asking for.

**Next session:** no Backlog priority items remain from the Reddit-feedback batch. Options: P24 (multi-agent optimisation guide), P8/P9/P10 (domain variants — all tagged `[has-open-questions]`), or ad-hoc refinements to the new P44/P45/P46 mechanisms based on multi-session use. Matt to direct.
