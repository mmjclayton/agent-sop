# Agent Memory — Gotchas and Lessons

One file per gotcha, data model invariant, named utility function, or framework-specific pattern agents commonly miss. Same structure and filename rules as decisions.

## Filename convention

```
YYYY-MM-DD_<agent-id>_<slug>.md
```

See `docs/agent-memory/decisions/README.md` for the full convention.

## File format

```markdown
# [Gotcha title — what to remember]

**Date:** YYYY-MM-DD
**Agent:** <agent-id>

**What NOT to do:** [anti-pattern statement]

**What IS correct:** [positive guidance — the correct path]

**Consequence if missed:** [what breaks]
```

The positive-guidance line is critical. Benchmark data shows agents given only "don't do X" sometimes remove the mechanism entirely instead of using the correct alternative.

## Superseded gotchas

Do not delete. Edit the file to add a trailing `*Superseded by:* <new-file-name>` line and move to `archive/`.

## See also

- `docs/sop/claude-agent-sop.md` Section 3 and Section 15.1 (what makes a good gotcha entry)
- `.claude/commands/update-sop.md` Step 5
