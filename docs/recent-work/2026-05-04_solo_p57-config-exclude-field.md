# P57 — Config `exclude` field for `/update-agent-sop`

**Date:** 2026-05-04
**Agent:** solo

New `"exclude": []` array field in `agent-sop.config.json` lets a project declare pristine-replica paths it deliberately overrides locally. Excluded files are reported as EXCLUDED, never classified, never synced, and have no baseline tracked.

`docs/templates/agent-sop-config-template.json` gains the field with an `_exclude_note` describing usage and the canonical example (`["docs/sop/security.md"]` for projects that ship a project-specific security doc).

`.claude/commands/update-agent-sop.md` (and the user-scope mirror) updated:
- Step 2: new step 1 — if file is in `config.exclude`, classify as EXCLUDED and skip the rest of the per-file pipeline. New EXCLUDED entry in the classification list.
- Step 3: extends the skip-list to include EXCLUDED.
- Step 6: reports N excluded separately and suggests removing stale baseline entries when files have been added to `exclude` after a previous sync.
- Prerequisites: bootstrap config template + a paragraph explaining the field.

Replaces the older workaround visible in `~/.claude/agent-sop.config.json`'s notes block: `docs/sop/security.md` is frozen at `33c651b1` with a multi-line explanation because hst-tracker runs a project-specific Supabase/Render security doc. Two more `_skipped per long-standing note` references appear in sync history. The new field collapses that into declarative config.

Baseline refreshed: `update-agent-sop.md` `5c37f951` → `6e6a6026`. Project-scope and user-scope SHAs match.

**Migration note for downstream consumers (e.g. hst-tracker):** when next syncing the SOP, replace the `security.md` baseline-freeze pattern with `"exclude": ["docs/sop/security.md"]` in that project's `.claude/agent-sop.config.json`. The legacy baseline-freeze remains functional during the transition — `exclude` is purely additive.

**Note on this user-scope config:** `~/.claude/agent-sop.config.json`'s baseline freeze for `docs/sop/security.md` was kept as-is. This config is the agent-sop project's own self-config; the project doesn't sync from itself, so the freeze + note pattern is harmless here. Only consumer projects materially benefit from migrating to `exclude`.

Tracking: Backlog (P57 SHIPPED + Shipped Archive line), feature-map P57 row + last-updated, CLAUDE.md Current Priority Items (follow-up removed) + rollup, agent-memory Completed Work, project_resume_solo.
