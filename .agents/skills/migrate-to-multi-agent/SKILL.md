---
name: migrate-to-multi-agent
description: Migrate an Agent SOP project to per-agent memory and isolated concurrent work.
---

Read docs/sop/multi-agent.md and inspect scripts/migrate-to-multi-agent.py
usage before running it. Back up legacy records and preserve project customizations.
Use AGENT_SOP_AGENT_ID for Codex agent identity; derive snapshot paths only with
scripts/resolve-resume-path.sh. Shared historical .claude memory paths are valid
SOP storage. Create distinct checkouts for concurrent writers; a working-directory
instruction alone does not isolate tool access. Migrate records without deleting
history, run the state and drift validators, and report the new per-agent paths.
Do not launch concurrent work unless it is part of the user's requested task.

Current limitation: the legacy migration script requires CLAUDE.md. On an
AGENTS.md-only project, report that limitation before invoking it; do not claim
a completed migration. Codex-only migration support remains follow-up work.
