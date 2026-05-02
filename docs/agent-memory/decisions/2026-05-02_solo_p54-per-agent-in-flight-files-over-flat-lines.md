# Per-agent in-flight files over flat-line discipline

**Date:** 2026-05-02
**Agent:** solo

We chose per-agent files (one file per agent in `docs/agent-memory/in-flight/<agent-id>.md`) over flat lines in `agent-memory.md` because flat-line edits gave only discipline-level isolation ("each agent edits their own line") with no git-level conflict avoidance. Two parallel agents editing adjacent lines, or two agents editing the same line in different worktrees, could produce merge conflicts that forced manual resolution.

Per-agent files give structural isolation: each agent only writes to its own file, and the `## In-Flight Work` section of `agent-memory.md` is regenerated between sentinel markers from the directory by `scripts/refresh-in-flight.sh`. Two parallel `/update-sop` runs in different worktrees write to different files; the rendered section is a pure function of directory contents, so post-merge regeneration converges by construction. Same model as the `## Recent Work (rollup)` section that derives from `docs/recent-work/`.

The pattern was already in scope for Phase 1 — the rollup proves the approach works — but the In-Flight Work section had been left on flat-line discipline, accepted at the time as low-risk because In-Flight is short-lived and per-agent. The hst-tracker code review surfaced it as the remaining unmitigated multi-agent hazard alongside the two real ones (worktree-wipe gotcha, no humans-serialise-merges note). Cleaner to fix all three together than triage which is "real enough."

Migration is trivial: existing flat lines map 1:1 to per-agent files (file is the agent-id, contents are the bullet body). Pre-migration projects keep working because `/update-sop` Step 5 falls back to the legacy flat-line edit when the `<!-- in-flight:start -->` sentinel is absent — same fallback pattern as P47 (legacy `project_resume.md`). The sentinel template flows into existing projects via `/update-agent-sop` syncing the updated `agent-memory-template.md`.

Alternative considered and rejected: extend the `agent-memory-template.md` instructions to require atomic per-agent line writes (e.g. with a separator pattern git can auto-merge). Rejected because git's textual merger does not understand per-agent line semantics — two agents editing distinct lines that happen to be adjacent still trigger conflicts. Structural isolation via filename is the only conflict-free design.

Reference: `scripts/refresh-in-flight.sh`, `docs/agent-memory/in-flight/README.md`, `.claude/commands/update-sop.md` Step 5.
