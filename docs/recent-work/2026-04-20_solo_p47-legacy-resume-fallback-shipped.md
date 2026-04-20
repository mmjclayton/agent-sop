# P47 legacy-resume fallback shipped

**Date:** 2026-04-20
**Agent:** solo
**Commits:** (see this session's commit)

## What shipped

- `scripts/validate-state-transitions.sh` — `--check-drift` fallback now fires regardless of agent-id. Non-`solo` path emits one-line advisory pointing at `/migrate-to-multi-agent`. Adjacent `set -u` bug fixed (`$root` previously unbound when `CLAUDE_AGENT_ID` preset).
- `.claude/commands/restart-sop.md` — Step 0d reassertion snippet mirrored; Step 0b note updated to describe the non-`solo` fallback behaviour.
- `~/.claude/commands/restart-sop.md` — user-scope mirror updated to match the project copy (pre-P47 SHA matched the agent-sop.config.json baseline, so no local drift).
- `docs/guides/multi-agent-parallel-sessions.md` — new scenario bullet in Section 1 explaining the legacy-fallback path for long-lived projects.
- `Backlog.md` — P47 transitioned `[OPEN]` → `[SHIPPED - 2026-04-20]`.
- `docs/feature-map.md` — P47 row added; "Last updated" bumped.
- `docs/agent-memory.md` — stale P43 In-Flight line cleared; P47 added to Completed Work.
- `docs/agent-memory/decisions/2026-04-20_solo_p47-legacy-resume-fallback-regardless-of-agent-id.md` — new decision file.
- `docs/build-plans/phase-1-parallel-sessions.md` — Batch Log entry appended.

## Dogfood

Four real-path scenarios verified against the updated `--check-drift` script (not just fixture mode):

1. Non-`solo` + legacy-only resume → advisory, drift check runs.
2. `solo` + legacy-only resume → silent fallback (backwards-compatible).
3. Non-`solo` + no files → graceful skip.
4. Non-`solo` + per-agent + stale legacy → per-agent wins, no advisory.

## Notes

- Fix was filed during the 2026-04-19 hst-tracker sync session. This session is follow-up only.
- No core SOP instruction count change. Script-level behaviour + docs only.
