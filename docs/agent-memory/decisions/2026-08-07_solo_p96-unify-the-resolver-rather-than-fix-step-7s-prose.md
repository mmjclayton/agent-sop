# P96: unify the resolver rather than fix Step 7's prose

**Date:** 2026-08-07
**Agent:** solo

The minimal fix for P96 was to paste the existing derivation snippet into `/update-sop` Step 7, matching what `/restart-sop` and the drift validator already carried. Rejected: that would have made three copies of one rule where two had already been enough to hide a missing third for four months.

Taken instead: `scripts/resolve-resume-path.sh` as a single implementation, per `docs/guides/cross-layer-rules.md` Tier A. The rule qualifies — it is a pure function of (repo root, HOME, agent-id) with no clock, network or DB input, so unification is available and is strictly stronger than a parity fixture.

Secondary decisions:

- **Writes lost the legacy fallback; reads kept it.** A write-side fallback to the unsuffixed `project_resume.md` is what let one project's session select another's file. Legacy projects still get read continuity, and Step 7 now marks the legacy file superseded once a per-agent file exists rather than deleting it (Section 0).
- **Exit 2 when the repo root is the home directory.** No project-scoped directory can be derived there, so the resolver refuses instead of returning the catch-all path. Callers degrade — the drift check skips with a message; Step 7 stops.
- **The resolver runs `set -u` only, deliberately**, with a comment saying so. Adding `-e`/`pipefail` would reintroduce P73 through the `git worktree list` call, which exits 128 outside a working tree.
- **Compliance checks were reworded, not added.** F6, RP1 and M4 now require the resolved directory rather than a name match. A new check would have shifted the 85/94 totals and forced a recount for no extra coverage.

Related: [[2026-08-07_solo_a-write-step-with-no-path-derivation-inherits-the-sessions-directory]]
