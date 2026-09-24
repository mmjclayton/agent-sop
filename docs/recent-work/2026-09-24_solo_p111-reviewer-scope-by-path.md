# Reviewer scope by path in the ship gate library

Shipped P111 with ship-sop P33 after the user authorised the hardening merges
(P110 via PR #29, ship-sop P32 via PR #15) and then the scope mechanism ("do it").

One rule in `sop-lib.sh`, `sop_agents_in_scope`: an enabled reviewer without
`paths` is in scope for every range; with `paths` only when a path changed in
`base..head` matches one of its patterns; an empty `paths` never. The Stop-hook
demand lists the in-scope set and is silent when it is empty; the receipt
validator requires exactly the in-scope reviewers for the receipt's own range;
`sop_policy_valid` accepts `paths` only as an array of patterns that compile.
The legacy `auto-ship-hook.sh` applies the same filter. Nine hook fixtures pin
it (101 in the suite); all nine suites and shellcheck pass; CI green on main.

Source: the 2026-09-24 gate-yield review of eleven Opportunity Scan receipts.
code-reviewer and silent-failure-hunter carried 25 of 26 blocking findings;
security-reviewer had none there but a CRITICAL on this repository's shell on
5 September, so its yield follows what the diff touches. Decision record in
opportunity-scan `docs/agent-memory/decisions/2026-09-24_client_two-reviewers-carry-the-gate.md`.

Two process defects this session, both mine and both repaired before merge: the
first P111 commit carried a fixture stub in place of Backlog.md (a debug script
run in the tool's zsh with a failed `cd` wrote fixtures into this checkout), fixed
by restoring from the prior commit and amending; and `gh pr merge --auto` merged
both hardening PRs at once because neither repository protects main.
