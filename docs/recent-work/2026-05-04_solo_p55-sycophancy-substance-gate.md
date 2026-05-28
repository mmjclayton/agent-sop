# P55 — Sycophantic reviewer detection: substance-assertion tightening

**Date:** 2026-05-04
**Agent:** solo
**Source:** `agent-sop-research-digest-2026-05-04.md` (Finding 1)

`scripts/validate-state-transitions.sh --assert-review` previously accepted any review with the structural sections present, including `## Findings\nNo issues — looks great`. The tightened check now requires findings (or the reasoned-no-issues line) to cite at least one concrete anchor — a file path with line number (e.g. `foo.ts:42`) or a backticked symbol or path (e.g. `` `processOrder` ``, `` `scripts/foo.sh` ``). Sycophantic reviews that pass structurally but cite nothing concrete are now blocked at the validator layer.

`docs/sop/claude-agent-sop.md` §6 gains a Step 1b rationale paragraph citing Anthropic's 30 April 2026 personal-guidance research — measured 9% baseline rate at which a frontier model trained against sycophancy still validates the user, rising to 25-38% in emotionally-loaded domains. Code review carries the same emotional load (peer agent, same session, easy approval path), making the cite-or-fail rule load-bearing rather than cosmetic.

`.claude/agents/code-reviewer.md` Finding Voice section gains a parallel sycophancy-gate paragraph so the reviewer agent sees the rule and the rationale at the point of writing. User-scope `~/.claude/agents/code-reviewer.md` mirrored.

Four new fixtures under `docs/benchmark/state-transition-fixtures/`:
- `legal-review-with-anchors.review.md` — Findings with file:line anchors → passes
- `legal-review-no-issues-with-anchor.review.md` — `No issues — verified \`multi-agent.md:45\`` → passes
- `illegal-review-sycophantic-no-issues.review.md` — `No issues — looks great` → blocks (the slippery case Matt flagged)
- `illegal-review-findings-no-anchors.review.md` — vague Findings prose with no anchor → blocks

`run-tests.sh` extended with a `*.review.md` loop alongside the existing `*.before.md` / `*.after.md` loop. All 11 fixtures pass (7 prior + 4 new). Backwards-compat verified end-to-end: all 4 existing `docs/reviews/*.md` artifacts still pass under the tightened check.

Baselines refreshed in `~/.claude/agent-sop.config.json`:
- `scripts/validate-state-transitions.sh`: `8e1899a3` → `55d0c36a`
- `.claude/agents/code-reviewer.md`: `b337aaf3` → `0a722d12`

Tracking: Backlog (P55 SHIPPED + Shipped Archive line), feature-map P55 row + last-updated, CLAUDE.md Current Priority Items (P55 removed) + rollup, agent-memory Completed Work, project_resume_solo.

This closes both findings from the 2026-05-04 research digest in one session (P56 earlier, P55 now). Combined with P24 (multi-agent entry point), three items shipped today.
