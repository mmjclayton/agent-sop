# P106 — /update-agent-sop runs a script; pristine means any past upstream version

**Date:** 2026-09-05
**Agent:** solo
**Commits:** `519db25` (feature), `75688b4` (review fixes), housekeeping follows

Operator's option 2. The command's three-way keyed on a baseline set shared by every consumer, so an older-but-untouched consumer looked locally modified. `scripts/sync-sop-files.sh` now classifies each manifest file with git history as the pristine test, applies the safe ones, refuses anything that would leave the consumer root, `~/.claude/` or the upstream checkout, and rewrites the config atomically. Three gates found four CRITICALs at the first commit (path traversal, manifest rows silently dropped); all fixed with 25 fixtures. repcanvas-marketing synced by the new path afterwards.
