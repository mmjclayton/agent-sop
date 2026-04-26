# P52 — ship learnings capture as doc-only, not as a setup.sh install

**Date:** 2026-04-26
**Agent:** solo

## Context

Matt brought a CodeLeash-derived proposal to add a learnings-capture pattern: PreCompact + Stop hooks write `docs/agent-memory/learnings/<file>.md` describing surprises, key learnings, hook/workflow recommendations, skill recommendations. `/update-sop` reviews and acts on the folder. The proposal also asked `setup.sh` to idempotently install the hook into consumer `.claude/settings.json`, mirroring ship-sop's pattern.

## Decision

Ship doc-only. Four edits:
1. Replace `harness-configuration.md` section f with a fuller "Learnings capture (PreCompact + Stop)" subsection (full 4-category prompt, jq-merge example for ship-sop coexistence, boundary note).
2. Create `docs/agent-memory/learnings/README.md`.
3. Add a `/update-sop` Step 5 sub-step (project + user-scope mirror) for review-and-archive.
4. Update agent-sop's own `.gitignore` for project-internal hygiene.

No `scripts/learnings-hook.sh`. No `setup.sh` changes. No new `/update-sop` step. No CLAUDE.md Rule 2 carve-out.

## Why doc-only and not install

- **Boundary preservation.** agent-sop has been deliberately doc-only at the consumer level since P21 shipped `setup.sh` (which copies templates, syncs SOP docs, installs slash commands and reference agents — never writes to `.claude/settings.json`). ship-sop is the sister project that installs runtime hooks. Crossing the boundary should require evidence the new capability delivers, not just plausibility. We don't have that evidence yet.
- **Reversible in one direction.** Doc-only → install (P53 follow-up if signal warrants) is a small upgrade. Install → doc-only is a deprecation that affects every consumer who already wired the hook. Asymmetric reversibility favours doc-only first.
- **Measurement-led.** Same logic P49 applied two days ago when it abandoned the `/update-sop` refactor. Don't ship infrastructure without evidence the capability moves a real metric.

## Why stdout, not `decision: block`

- PreCompact has no `decision: block` option; it's stdout-only by design. Stop is the only place where blocking is even available.
- Block-decision at Stop forces an extra turn after the user has signalled "I'm done". User-disruptive; also requires a `stop_hook_active` guard against infinite loop.
- stdout context injection works for both: PreCompact stdout enters the post-compact session; Stop stdout enters the next user turn (when there is one). Sessions that never get a "next user turn" lose the prompt — but those sessions were going to be ignored anyway, and `/update-sop` Step 5 is the safety net for any captured-but-not-acted-on file.

## Why fold into Step 5, not new Step

- P49 (2026-04-24) ABANDON-ed the `/update-sop` refactor with the verdict "no step dominates enough to justify rewrite; agent-side drafting steps are all necessary." Adding a fourteenth top-level step contradicts that fresh decision.
- Step 5 already handles `decisions/` + `gotchas/` directories. learnings/ is a sibling — same directory tree, same archive-not-delete lifecycle, same audience.
- Sub-step cost when folder is empty: <1 s `ls` no-op (P49 measured similar no-ops at <1 s aggregate). Cost when populated scales with file count, bounded by sessions since last `/update-sop`.

## Why archive, not delete (and not a Rule 2 carve-out)

The original proposal said "fix / promote to Backlog / **delete**". Initial review left this as "your call — archive (a) or carve-out (b)". On second look, archive is the obvious choice:
- Cost: `git mv` to `learnings/archive/YYYY-MM/`. Trivial.
- Benefit: preserves the audit trail, no rule-conflict friction for future agents.
- Risk of carve-out: weakening Rule 2 with a single-file-type exception sets precedent for future "but THIS file type is also ephemeral" arguments. Each one is individually plausible; together they erode the rule.

Archive wins on cost-benefit. Don't carve.

## Why filename HH-MM precision but not session_id

- HH-MM matches the existing `decisions/` and `gotchas/` slug shape (which use date-only, but those expect ≤1 entry per agent per session). Learnings expect 1-2 per session (PreCompact + Stop), so HH-MM is the minimal precision bump that handles realistic collision.
- session_id would handle 100% of theoretical collision but adds shell complexity for ~no realistic gain.

## Closes

- P52 `[SHIPPED - 2026-04-26]`.
- Original proposal's Piece 1 (runtime hook script + setup.sh install) deferred to potential P53 pending dogfood signal.

## Follow-ups

- Dogfood: drop a learning in agent-sop or hst-tracker over the next 2-3 sessions. If `/update-sop` Step 5 surfaces and processes them cleanly, file P53 to install.
- If the capture flow produces no files across 5 sessions, the doc is signal-free; either remove or sharpen the prompts.
