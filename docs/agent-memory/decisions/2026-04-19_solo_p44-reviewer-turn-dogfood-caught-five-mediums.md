# P44 reviewer-turn dogfood: reviewer caught five MEDIUM findings, all fixed in-session

**Date:** 2026-04-19
**Agent:** solo

P44 (reviewer-turn gate) was dogfooded as it shipped — the very first invocation of Step 1b reviewed P44's own diff. The `code-reviewer` subagent produced a substantive review (all three required sections, severity MEDIUM, five concrete findings with file:line references). Substance assertion passed. All five findings were real defects, all were fixed in-session before P44 commit.

**Findings and fixes:**
1. `count_session_diff` was parsing `--shortstat` fragile-awk style (column positions shift on deletion-only diffs). Fix: `git diff --numstat` and sum columns.
2. Security-trigger path list contained bare `sign` / `verify` / `sql` — false positives on any `git rev-parse --verify` or prose. Fix: replaced with multi-token forms (`verify_token`, `signing`, `raw_query`).
3. Step 1b claimed "Step 3c keeps review-path honest" but the validator only checked P-number presence. Fix: validator extended — for `[Feature]`/`[Refactor]` transitioning to `[SHIPPED]`, the Batch Log line naming the P-number must cite a `docs/reviews/` path. Hard-block. Fixed a type-tag awk extraction bug while adding this.
4. `setup.sh` never created `docs/reviews/`. Fix: `mkdir -p` added.
5. R1 compliance check documented `git show --stat` for retrospective measurement — that's per-commit, undercounts sessions. Fix: `git diff --numstat <merge-base>..<tip>`.

**What this validates:**
- P44's architecture delivers enforceable gates, not prose ceremony. The reviewer agent was a different Claude instance with no investment in the diff; it found real issues a self-eval would have missed (Finding 3 was a self-undermining hole in the feature's own enforcement claim).
- Substance assertion worked: three required sections, concrete file:line references, no LGTM stubs. Exit 0.
- The action-vs-ceremony test (decision 2026-04-19_solo_action-vs-ceremony-test-for-sop-additions) holds. Every one of the five findings was about a gate that was present-as-text but not enforced-as-code, or a heuristic that would silently fail.

**Lesson:** when shipping an enforcement mechanism, the first invocation must be against the mechanism's own diff. Otherwise the self-referential blind spot stays. The reviewer in this case was another agent running with a clean prompt and no investment — exactly the independence P44 exists to provide.
