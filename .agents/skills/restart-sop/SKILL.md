---
name: restart-sop
description: Resume an Agent SOP project session, read relevant memory and locate the current Backlog work item.
---

Confirm the project has Backlog.md and docs/sop/claude-agent-sop.md; otherwise
report that it is not an SOP project and follow its own instructions.
Read AGENTS.md and docs/sop/codex.md. Follow the shared SOP session-start section.
If the Agent SOP context hook already printed state, use it. Otherwise run
`bash scripts/resolve-resume-path.sh --read`, read that snapshot when present,
and inspect recent git history and dirty tracker diffs before trusting them.
Search decisions and gotchas by the task topic and affected paths before using recency. Read the relevant invariants even when older.
Locate the requested Backlog P-number and read only that item. If interrupted,
read the corresponding build plan and in-flight entry. Report what is current
and continue the user's task. Do not invent missing snapshots or initialize a
non-SOP project as part of resume.

For parallel editing, inspect the installed `sop-worktree-claim.sh status` from
this worktree. Claim a unique session ID, task ID and intended source paths before
editing. Use the runtime's user hook directory (`~/.codex/scripts/hooks/agent-sop`
or `~/.claude/scripts/hooks/agent-sop`). A conflicting claim must be reconciled;
never release another session without first inspecting its work. Read-only review
sessions do not claim writing ownership.
