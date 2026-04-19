# P44/P45/P46 Backlog drafted from Reddit feedback on state drift

**Date:** 2026-04-19
**Agent:** solo

External feedback on 2026-04-19 (Reddit) argued that markdown SOPs fail to enforcement — "state drift once the agent has a few tool calls, edits, and context resets behind it" — and called for machine-checkable workflow with explicit states, required reviewer turns, and a human gate before merge. Redditor's framing: "treat the SOP like a protocol, not just a template."

**Interpretation chosen (Rule 6 surfaced before committing):** make existing prescriptions machine-checkable at session boundaries + hook points. NOT rebuild agent-sop on a protocol runtime — that would break the "plain markdown + git + shell, no daemon, no DB" design philosophy that differentiates it from claude-mem and similar tools.

**Three Backlog items drafted, shipped order P45 → P44 → P46 (highest to lowest action-per-text ratio):**

- **P45 (validator, ship first):** `scripts/validate-state-transitions.sh` reads Backlog diff in commit range, rejects illegal status-tag transitions (e.g., `[OPEN]` → `[SHIPPED]` skipping intermediates). `/update-sop` Step 2c hard-blocks on non-zero exit. Produces failure, not text. Foundation for P44.
- **P44 (reviewer turn with substance assertion):** `/update-sop` Step 1 invokes `code-reviewer` for `[Feature]`/`[Refactor]` over 50 LOC / 3 files. Findings file at `docs/reviews/YYYY-MM-DD_<agent-id>_P<n>.md` must contain three sections (diff summary, severity, concrete finding or reasoned no-issues). Validator rejects LGTM-only stubs. Without substance assertion this would become ceremony.
- **P46 (reframed from print-hook to actionable check):** initial proposal was PostToolUse reassertion prints. Rejected under action-vs-ceremony test. Reframed as `/update-sop` Step 2d: commit-range references the declared in-flight P-number, escape hatch via `project_resume` `## Scope Change` block.

**Instruction budget:** accept +6-9 core SOP drift to ~187-190 (within 200 hard ceiling, over 150 soft cap — same direction as since P32). Don't bundle Section 1 / Section 8 trims with these items — keeps the scope of each Backlog entry independently evaluable.

**Explicitly rejected:**
- New `[READY-FOR-REVIEW]` status tag (reviewer-artifact check delivers the same gate without expanding state machine)
- Git pre-push hook blocking merge without reviewer artifact (changes solo-user ergonomics; document as optional snippet)
- Protocol runtime / daemon / DB (breaks minimal-tooling ethos)

**Source:** chat discussion with user 2026-04-19 — plan pre-approved, drafted for review, user-approved additions before write. See `Backlog.md` P44-P46 for the full entries with acceptance criteria.
