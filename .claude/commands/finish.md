---
description: Verify the change on its real surface, simplify the diff, then close the session with /update-sop and open a PR. Three phases, hard-blocking.
sop_version: "2026-09-05"
---

`/finish` is the "I'm done" wrapper. Outside an Agent SOP project (no `Backlog.md`, no `docs/sop/claude-agent-sop.md`) Phase 3's `/update-sop` stops by design; use the project's own close-out.

## Phase 1: Verify on the real surface

Prove the change works where it runs, not only that tests pass. If the project is non-code by the shared rule (context block header, or `bash ~/.claude/scripts/hooks/agent-sop/sop-project-type.sh`), the surface is docs-only: skip this phase and say so.

Otherwise use the `run` skill, or the launch command in `## Key Commands`, to start the app and exercise the changed path end to end: a backend by hitting the touched endpoint and one known-failure path; a UI in the browser; a CLI by invoking the changed command. Capture what you saw. A change that cannot be exercised locally is escalated to the operator, never verified by assertion.

Print a short block: surface, what was exercised, result.

## Phase 2: Simplify

Run `/simplify` on the diff. Apply what it finds. Re-run the tests.

## Phase 3: Ship

1. Backlog: every P-number worked on carries the right status tag and, if shipped, its `review:` line or skip token (the `/update-sop` review step defines both).
2. Run `/update-sop`. It hard-blocks on transition, review or drift failures; resolve the cause, never bypass.
3. Open the PR per the user-scope git workflow (branch `<type>/<slug>`, conventional-commit title, summary plus test plan). Merge on green unless the operator has said otherwise.

Summary block at the end: PR link, Backlog transitions, `/update-sop` clean or what blocked.
