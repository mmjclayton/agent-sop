# P43 Batch 1.7 dogfood complete — P43 ships

**Date:** 2026-04-19
**Agent:** solo
**Commits:** (pending this commit)

Three parallel subagents executed on sibling git worktrees of hst-tracker. Agent A migrated `.time-filter-btn` to `<Pill>`. Agent B extended the XLSX parser to read START DATE (with label-scanning, real layout-aware). Agent C added `gh api` commands to the branch-protection Backlog entry. Sequential three-way merge to main: 0 conflicts on Backlog status flips, 0 on per-entry directory files, 2 expected conflicts on `CLAUDE.md` rollup (resolved canonically via idempotent refresh). 855/855 tests pass on merged main.

Two follow-ups logged: (1) `refresh_recent_work_rollup` bash snippet leaks `local var=...` in zsh — wrap in `bash -c` or rewrite; (2) migration script's bullet parser silently skips undated prose bullets — hst-tracker's Gotchas section left intact as legacy.

P43 `[IN PROGRESS]` → `[SHIPPED - 2026-04-19]`. Full Batch 1.7 log at `docs/benchmark/parallel-dogfood-log.md`. Phase 1 Deploy Checklist complete.
