# P52 learnings capture pattern (doc-only)

**Date:** 2026-04-26
**Agent:** solo

## What shipped

Doc-only learnings-capture pattern. Replaces `harness-configuration.md` section f with a fuller "Learnings capture (PreCompact + Stop)" subsection — 4-category prompt structure (surprises / key learnings / hook recommendations / skill recommendations), idempotent jq-merge example for ship-sop coexistence, boundary note. New `docs/agent-memory/learnings/` folder with README explaining lifecycle and filename convention. `/update-sop` Step 5 gains a review-and-archive sub-step (project + user-scope mirror): list folder, crystallise into decision/gotcha or file Backlog item, archive via `git mv` (never delete). agent-sop `.gitignore` excludes live `.md` entries; archive subtree IS committed because it preserves the audit trail per CLAUDE.md Rule 2.

## Scope cuts vs original proposal

- **No `scripts/learnings-hook.sh` runtime script.** agent-sop has been deliberately doc-only at consumer level since P21. Crossing into install territory needs evidence the pattern delivers signal — not yet available.
- **No `setup.sh` changes.** Consumers wire the documented snippet themselves into their own `.claude/settings.json`.
- **No new `/update-sop` step.** Folded into Step 5 — same directory tree, same lifecycle. Respects P49's 2026-04-24 verdict that no step dominates enough to justify churn.
- **No CLAUDE.md Rule 2 carve-out for delete.** Archive is `git mv` — trivial cost, no rule-friction precedent.
- **No `.gitkeep`.** README.md keeps the folder.

## Why doc-only first

Asymmetric reversibility. Doc-only → install (potential P53) is a small upgrade. Install → doc-only is a deprecation that affects every consumer who already wired the hook. Defer the install until 2-3 sessions of dogfood show real capture-flow signal volume.

## Files touched

- `docs/sop/harness-configuration.md` (section f rewrite)
- `docs/agent-memory/learnings/README.md` (new)
- `.claude/commands/update-sop.md` (Step 5 sub-step)
- `~/.claude/commands/update-sop.md` (user-scope mirror)
- `.gitignore` (exclude live learnings, commit archive)
- `Backlog.md` (P52 entry)
- `docs/feature-map.md` (P49 + P51 + P52 added; date bumped)
- `docs/agent-memory.md` (Completed Work for P49, P51, P52)
- `docs/agent-memory/decisions/2026-04-26_solo_p52-learnings-doc-only.md` (new)
- `docs/build-plans/phase-0-foundation.md` (Batches 0.19 + 0.20)
