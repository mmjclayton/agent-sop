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
List the newest decisions and gotchas; read those relevant to this task.
Locate the requested Backlog P-number and read only that item. If interrupted,
read the corresponding build plan and in-flight entry. Report what is current
and continue the user's task. Do not invent missing snapshots or initialize a
non-SOP project as part of resume.
