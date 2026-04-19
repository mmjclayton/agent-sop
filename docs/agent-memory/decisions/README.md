# Agent Memory — Decisions

One file per architectural decision, data model invariant, or named-utility callout. Concurrent-safe: each decision is a distinct file, so multiple agents appending decisions in parallel never conflict on merge.

## Filename convention

```
YYYY-MM-DD_<agent-id>_<slug>.md
```

- Field separator: `_`; hyphen allowed within fields
- Slug: lowercase alphanumeric + hyphens, max ~50 chars
- Agent-id: alphanumeric + hyphens, no underscores

Examples:
- `2026-04-19_solo_p42-secondary-tracker-reconciliation.md`
- `2026-04-17_solo_section-0-expanded-to-six-rules.md`

## File format

```markdown
# [Decision title]

**Date:** YYYY-MM-DD
**Agent:** <agent-id>

[Decision body. Multi-paragraph is fine. Reference P-numbers where applicable.]

---
*Supersedes:* [file-name or P-number, if any]
*Superseded by:* [file-name, if later entry replaces this]
```

## Superseded decisions

Do not delete. Edit the superseded file to add a trailing `*Superseded by:* <new-file-name>` line, then `git mv` the file to `archive/` once the replacement lands.

## See also

- `docs/sop/claude-agent-sop.md` Section 3 (authoritative file structure spec)
- `.claude/commands/update-sop.md` Step 5
