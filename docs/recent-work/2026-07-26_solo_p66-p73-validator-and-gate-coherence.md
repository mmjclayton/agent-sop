# P66, P70-P73 — validator correctness and gate coherence

**Date:** 2026-07-26
**Agent:** solo
**Commits:** see Batch 0.27

Closed every item filed by Batch 0.26 plus P66, deferred since 6 July. Second session of the day, on top of P67-P69.

**P73** `[Bug]` — the validator's Batch Log `BLOCK:` message was unreachable: `grep -l` exits 1 on no match, `pipefail` carried it past `head`, `errexit` killed the script before the `echo`. Guarded, plus a fixture harness that can now assert on stdout and an overridable `VALIDATOR` so fixtures are provably discriminating. **P66** `[Bug]` — Tier A unification: the P44 gate accepts `review skipped (P<n>): <enumerated reason>`, the same token S7, `sop-checker` and `security.md` rule 11 read. **P70** `[Bug]` — the test gate's self-judged escape replaced by three verifiable conditions; T1 checks it. **P71** — `[DEFERRED]` requires a `**Reopens when:**` line across six surfaces; B12 checks it. **P72** `[Feature]` — `run-multi-round.sh` gains `--lite`, `--tasks`, `-k N` and `aggregate`. Totals 83/92 → 85/94.

**The reviewer turn returned 3 HIGH and every one was a defect in this session's own work.** P73's audit had missed `:164` (`git worktree list`, exits 128 outside a repo), so `--check-drift` still exited 128 with empty stdout *and* empty stderr in a non-git directory — the exact silent failure P73 was written to remove, surviving P73. The Batch Log claim "audited all 8 command-substitution sites" was false: the file has 28, and the risk filter used to pick the 8 matched on command name (`grep|find|diff`) and so could not match any failing `git` subcommand. T1's grep criterion failed on the very file it gates, because the explanation paragraph quoted the banned phrase verbatim. And `aggregate` keyed on `(task, arm)` while requiring `round` and `run` columns it never used, so two decisive opposite rounds pooled to a `+0.00 RANGES OVERLAP` wash.

Four MEDIUMs also fixed: the skip token could be shadowed onto a different P-number sharing a Batch Log line, `dep-bumpkin` satisfied the enumeration, `security.md` rule 11 still described a free-text exemption the hardened S7 now rejects, and the lite-benchmark rule went MANDATORY with its first exception unrecorded.

A pattern across all three reviews today: each defect was verified against the case its author had in mind rather than the case the code would meet. S7 tested inside a range that is always empty, the P73 audit tested inside a git repo, `aggregate` tested with one round.
