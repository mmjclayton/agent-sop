---
name: update-sop
description: Close an Agent SOP session with tests, review evidence, Backlog updates, validators and a resume record.
---

Confirm Backlog.md and docs/sop/claude-agent-sop.md exist. Read the shared SOP's
session-end section and docs/sop/codex.md. Preserve the user's task scope.

1. Resolve the agent ID and resume path with scripts/resolve-resume-path.sh.
   Establish this session's actual diff from git history, in-flight work and
   the previous record. Do not assume the entire branch is this session.
2. Determine project type with the installed Codex sop-project-type.sh or the
   project's scripts/hooks/sop-project-type.sh. Run the real existing suites.
   Missing runners are reported, not recorded as a pass.
3. Apply the shared SOP review triggers. When ship-sop auto-mode applies, use
   the ship skill once and cite its report. Otherwise use an isolated read-only
   reviewer as described in docs/sop/codex.md. Include uncommitted changes in a
   temporary review snapshot when needed. Missing evidence blocks shipping.
4. Update Backlog tags and review citations in place; preserve all items.
   Run scripts/refresh-priorities.sh, scripts/archive-backlog.sh and
   scripts/detect-trackers.sh where installed. A missing required script is an
   installation gap to report and repair with update-agent-sop.
5. Run scripts/validate-state-transitions.sh normally, with --check-drift,
   and with --check-replication. For Codex checks set AGENT_SOP_RUNTIME=codex.
   Resolve failures; never manufacture a pass or mark unfinished work shipped.
6. Write substantive decisions/gotchas, refresh in-flight state, write a session
   record under docs/recent-work, and refresh the rollup. Overwrite the resolved
   resume snapshot with what changed, what's next and blockers. Preserve the
   shared legacy memory location; never guess a path.
7. Commit only files belonging to the task when authorized by the workflow;
   respect an explicit request to leave changes uncommitted. Summarize changes,
   test/review results and any remaining work. Publication requires its own
   user authorization; closing the session does not imply sending messages.
