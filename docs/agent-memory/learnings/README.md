# Agent Memory — Learnings

Ephemeral mid-session signal: surprises about the codebase, friction worth fixing, hook or skill recommendations the agent noticed while working. Distinct from `decisions/` (durable architectural calls) and `gotchas/` (reusable invariants and named utilities).

## Lifecycle

1. **Capture (during a session).** Either an agent writes here directly when something surprises them, or a PreCompact/Stop hook prompts a write at compaction or session end. Reference snippet: `docs/sop/harness-configuration.md` "Learnings capture" section.
2. **Review (during `/update-sop`).** Step 5 sub-step lists this folder and acts on each file: crystallise into a decision/gotcha, file a Backlog item, or archive as no-longer-relevant.
3. **Archive (always, never delete).** Action taken or not, processed files move to `archive/YYYY-MM/`. Archiving is `git mv` — same cost as the decisions/gotchas archive; preserves the audit trail per CLAUDE.md Rule 2.

The folder ends every `/update-sop` empty (or near-empty). If files accumulate across multiple sessions without review, that's drift — surface it next `/restart-sop`.

## Filename convention

```
YYYY-MM-DDTHH-MM_<agent-id>_<slug>.md
```

Same shape as `decisions/` and `gotchas/` with HH-MM precision added (multiple captures per session are expected).

Examples:
- `2026-04-26T15-22_solo_setup-sh-jq-merge-feels-like-it-should-be-a-helper.md`
- `2026-04-26T16-08_solo_validate-state-transitions-script-grew-without-anyone-noticing.md`

## File format

```markdown
# [One-line summary of the surprise]

**Date:** YYYY-MM-DDTHH-MM
**Agent:** <agent-id>

## Surprises about the codebase
[What surprised you. Be specific — file paths, line numbers, names.]

## Key learnings for future sessions
[What you'd want a future-you / sibling agent to know.]

## Hook or workflow recommendations
[Anything the SOP harness could automate or prevent.]

## Skill recommendations
[Patterns that deserve a skill or template, not a one-off learning.]
```

Skip any heading where you have nothing useful. Skip the file entirely if nothing was noteworthy.

## See also

- `docs/sop/harness-configuration.md` — reference hook snippets (PreCompact + Stop)
- `.claude/commands/update-sop.md` Step 5 — the review-and-archive workflow
- `docs/agent-memory/decisions/README.md` — sibling pattern for durable decisions
