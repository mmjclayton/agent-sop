# P47 — Legacy resume fallback fires regardless of agent-id

**Date:** 2026-04-20
**Agent:** solo
**Status:** shipped

## Decision

The drift-check script (`validate-state-transitions.sh --check-drift`) and the `/restart-sop` Step 0d in-flight reassertion now try the legacy unsuffixed `project_resume.md` as a last fallback **regardless of the resolved agent-id**. Previously the fallback was gated on `agent_id = "solo"`, which silently skipped drift enforcement on long-lived multi-worktree projects that predate the per-agent filename convention.

On the non-`solo` fallback path, a one-line advisory prints: *"reading legacy unsuffixed resume file. Run `/migrate-to-multi-agent` to move to per-agent format."* The advisory appears once per invocation (the resolver runs once; no duplication risk).

## Why

- Surfaced during the hst-tracker P44/P45/P46 sync on 2026-04-19. hst-tracker is a two-worktree project (main + `--design-audit`); agent-id resolved to a 6-char hash on the main worktree, so the old `agent_id = "solo"` guard never fired and drift degraded to "no resume file found, skipping" — silent no-op.
- The highest-value drift-check targets are exactly these long-lived parallel-worktree projects. Forcing `/migrate-to-multi-agent` as a prerequisite for any drift enforcement was a usability trap, not a safety feature.
- A loud advisory (instead of silent fallback) keeps users moving toward migration without blocking correctness.

## How to apply

- Per-agent `project_resume_<id>.md` still wins when present. The legacy file is only consulted when the per-agent file is absent.
- The advisory prints to stderr so it does not interfere with the drift check's own stdout summary or with callers that parse the stdout.
- Same behaviour mirrored in both the project-scope and user-scope `restart-sop.md` Step 0d snippet — keep them in lockstep on future changes.
- Adjacent fix: hoisted `root=$(git rev-parse --show-toplevel 2>/dev/null) || root=""` above the agent-id branch so `set -u` no longer trips when `CLAUDE_AGENT_ID` is preset (the previous code only assigned `$root` on the auto-detect path).

## Dogfood evidence

Four synthetic scenarios tested against `scripts/validate-state-transitions.sh --check-drift`:

1. Non-`solo` agent-id + only legacy resume → advisory fires, drift check runs. ✓
2. `solo` agent-id + only legacy resume → silent fallback (backwards-compatible). ✓
3. Non-`solo` agent-id + no files at all → graceful skip with "first session, or fresh repo" message. ✓
4. Non-`solo` agent-id + per-agent file present + stale legacy file present → per-agent wins, legacy ignored, no advisory. ✓

All four used a real `$HOME` override so the path-derivation code ran end-to-end, not just the explicit `--drift-resume-file` harness path.
