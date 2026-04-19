# P44 reviewer-turn + substance assertion shipped

**Date:** 2026-04-19
**Agent:** solo
**Commits:** [pending — this session's P44 commit]

Shipped P44 — `/update-sop` Step 1b invokes `code-reviewer` (or `security-reviewer` for auth/crypto/payment diffs) for any `[Feature]`/`[Refactor]` shipping over threshold (default 50 LOC / 3 files, configurable). Findings go to `docs/reviews/YYYY-MM-DD_<agent-id>_P<n>.md` using the new review template. Substance assertion via `--assert-review` (shipped with P45) hard-blocks stub / LGTM-only files. Compliance check R1 added.

**Shipped this session:**
- `docs/templates/review-template.md` — review artifact schema
- `.claude/commands/update-sop.md` — Step 1b (reviewer-turn gate with threshold resolution, security-reviewer auto-selection, substance assertion)
- `docs/sop/claude-agent-sop.md` — Section 6 extended (+4 instructions for Step 1b note + Batch Log review-path note)
- `docs/sop/compliance-checklist.md` — R1 check, summary totals 76→77 / 85→86
- `docs/templates/agent-sop-config-template.json` — `review_loc_threshold` / `review_files_threshold` fields
- `.claude/commands/update-agent-sop.md` — review-template.md added to pristine-replica manifest with rationale note
- `setup.sh` — copies review-template.md, creates `docs/reviews/` directory
- `scripts/validate-state-transitions.sh` — extended Batch-Log check: `[Feature]`/`[Refactor]` ships must cite `docs/reviews/` path in batch log line
- `docs/benchmark/state-transition-fixtures/illegal-feature-shipped-no-review*` — new fixture covering the extended check, per-fixture `.phase-stub.md` override supported

**Dogfood result:** P44's own ship triggered Step 1b. `code-reviewer` subagent produced a substantive review (severity MEDIUM, 5 concrete findings). All 5 findings were real defects in P44's implementation:
1. Fragile LOC counting (shortstat parsing) → fixed via numstat
2. Security-trigger list false positives (bare `sign`/`verify`) → narrowed to multi-token forms
3. Self-referential hole: "Step 3c keeps this honest" was false prose → fixed by extending validator to actually enforce review-path citation
4. `setup.sh` never created `docs/reviews/` → `mkdir -p` added
5. R1 compliance used wrong git command → corrected

Resolution appended to review file. All fixes ship in the same commit as P44 itself. See `docs/agent-memory/decisions/2026-04-19_solo_p44-reviewer-turn-dogfood-caught-five-mediums.md`.

**Core SOP instruction count delta:** +4 in Section 6. Projected ~184 → ~188. Well within 200 ceiling.

**Next session:** P46 — actionable drift detection (commit-range scope check at `/update-sop` Step 2d).
