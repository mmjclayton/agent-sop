---
description: One-time migration — extract legacy CLAUDE.md Recent Work + agent-memory.md Decisions + Gotchas into per-entry directory files. Idempotent. Supports --dry-run.
sop_version: "2026-04-19"
---

One-time migration for projects upgrading to Phase 1 parallel-session conventions. Moves historical narrative from CLAUDE.md and agent-memory.md into per-entry files under `docs/recent-work/`, `docs/agent-memory/decisions/`, and `docs/agent-memory/gotchas/`. Idempotent — re-running overwrites the same filenames deterministically. Run only once per project.

All extracted entries are tagged with agent-id `solo` because historical content pre-dates the parallel-agent model.

## Quick path

The extraction is driven by `scripts/migrate-to-multi-agent.py` (shipped with agent-sop, copied to target projects by `setup.sh`). Run it:

```bash
# Preview what would be extracted (no file writes)
python3 scripts/migrate-to-multi-agent.py --dry-run

# Do the extraction (requires clean working tree)
python3 scripts/migrate-to-multi-agent.py
```

After extraction:
1. `git status` to review the new files
2. Manually remove the legacy sections from CLAUDE.md (`## Recent Work (legacy, ...)` or `## Recent Work`) and from docs/agent-memory.md (`## Decisions Made (legacy, ...)` and `## Gotchas and Lessons (legacy, ...)`) — the script intentionally leaves these for human review
3. Run `/update-sop` to refresh the `## Recent Work (rollup)` section in CLAUDE.md
4. Commit: `chore: migrate to multi-agent directory structure`

## Detailed instructions (for the agent)

## Step 0: Preconditions

1. Verify clean working tree. If `git diff --quiet && git diff --cached --quiet` fails, abort with message: `Working tree has uncommitted changes. Commit or stash first — migration needs a clean baseline for review.`
2. Verify CLAUDE.md exists at project root. Abort if not.
3. Resolve `$AGENT_ID` using the snippet from `/update-sop` Step 0. The running agent's id is only used for reporting; all migrated content uses `solo`.

## Step 1: Parse $ARGUMENTS for --dry-run

```bash
DRY_RUN=0
case "$ARGUMENTS" in
  *--dry-run*) DRY_RUN=1 ;;
esac
[ "$DRY_RUN" = "1" ] && echo "DRY RUN — no files will be written."
```

In dry-run mode, report what would be written but do not touch the filesystem. No commits either.

## Step 2: Detect whether migration has already run

Check CLAUDE.md for a "legacy" Recent Work section with pending entries:

```bash
has_legacy_recent_work() {
  grep -qE '^## Recent Work \(legacy' CLAUDE.md 2>/dev/null || \
    grep -qE '^## Recent Work$' CLAUDE.md 2>/dev/null
}
has_legacy_decisions() {
  grep -qE '^## Decisions Made \(legacy' docs/agent-memory.md 2>/dev/null || \
    grep -qE '^## Decisions Made$' docs/agent-memory.md 2>/dev/null
}
has_legacy_gotchas() {
  grep -qE '^## Gotchas and Lessons \(legacy' docs/agent-memory.md 2>/dev/null || \
    grep -qE '^## Gotchas and Lessons$' docs/agent-memory.md 2>/dev/null
}

if ! has_legacy_recent_work && ! has_legacy_decisions && ! has_legacy_gotchas; then
  echo "No legacy sections to migrate. Migration already done or not applicable."
  exit 0
fi
```

If none of the three legacy sections exist, migration is a no-op — exit cleanly.

## Step 3: Extract Recent Work entries

Read CLAUDE.md's Recent Work legacy section. Parse `### YYYY-MM-DD:` headings. For each entry, write `docs/recent-work/YYYY-MM-DD_solo_<slug>.md` with:

```markdown
# [Title from the heading, minus the date prefix]

**Date:** YYYY-MM-DD
**Agent:** solo
**Commits:** [extract from parenthesised list in heading if present, else: (migrated)]

[Full body text until the next ### heading or end of section]
```

Slug derivation rules:
1. Take the heading text after `YYYY-MM-DD: ` and before ` (commits ...)` or ` (PRs ...)`
2. Lowercase
3. Replace any non-alphanumeric character with `-`
4. Collapse runs of `-` into single `-`
5. Trim leading/trailing `-`
6. Truncate to 50 chars, then trim any trailing `-`

Use the agent's text-parsing capability rather than bash — the narrative may span multiple paragraphs with indented or quoted content.

In dry-run mode, print `WOULD WRITE: docs/recent-work/YYYY-MM-DD_solo_<slug>.md (N chars)` per entry.

## Step 4: Extract Decisions entries

Read docs/agent-memory.md's Decisions legacy section. Each entry starts with `- YYYY-MM-DD:`. Multi-paragraph entries continue until the next `- YYYY-MM-DD:` bullet or a blank line followed by a new section.

For each entry, write `docs/agent-memory/decisions/YYYY-MM-DD_solo_<slug>.md` with:

```markdown
# [Title — first sentence or topic phrase from the entry]

**Date:** YYYY-MM-DD
**Agent:** solo

[Full body — all paragraphs of this entry]
```

Slug derivation: same rules as Recent Work, applied to the derived title.

Entries tagged `[SUPERSEDED - DATE: reason]` get moved to `docs/agent-memory/decisions/archive/` with the supersession note preserved at the bottom of the body.

## Step 5: Extract Gotchas entries

Same mechanism as Decisions, written to `docs/agent-memory/gotchas/`.

## Step 6: Extract Archived entries (if any)

If docs/agent-memory.md has an `## Archived` section with dated entries, each entry is migrated to the appropriate `archive/` subdirectory (decisions or gotchas — infer by content, or default to decisions if ambiguous). Preserve all historical context.

## Step 7: Replace legacy sections

In CLAUDE.md:
- Remove the legacy `## Recent Work (legacy, pending Batch 1.6 migration)` section (or `## Recent Work` if legacy cutover note wasn't present)
- Keep the `## Recent Work (rollup)` section intact (it will be refreshed in Step 9)

In docs/agent-memory.md:
- Remove the legacy `## Decisions Made (legacy, ...)` and `## Gotchas and Lessons (legacy, ...)` sections (or `## Decisions Made` / `## Gotchas and Lessons` if cutover note wasn't present)
- Keep the pointer-note sections present in the post-1.2 agent-memory.md template (they already say "See `docs/agent-memory/decisions/`")
- If the current sections are the legacy ones and pointer-note sections don't exist yet, add pointer-note sections after removal

In dry-run mode, print `WOULD REPLACE: CLAUDE.md legacy Recent Work section (X lines)` etc.

## Step 8: Verify no content loss

Count entries extracted. Compare against bullets counted in legacy sections before removal.

```bash
# Before Step 3
LEGACY_RW_COUNT=$(grep -cE '^### [0-9]{4}-[0-9]{2}-[0-9]{2}:' CLAUDE.md)
LEGACY_DEC_COUNT=$(awk '/^## Decisions Made/,/^## [A-Z]/' docs/agent-memory.md | grep -cE '^- [0-9]{4}-[0-9]{2}-[0-9]{2}:')
LEGACY_GOT_COUNT=$(awk '/^## Gotchas and Lessons/,/^## [A-Z]/' docs/agent-memory.md | grep -cE '^- \[?(SUPERSEDED|[0-9]{4})')
```

After Steps 3-5, count new files:

```bash
NEW_RW=$(ls docs/recent-work/*.md 2>/dev/null | grep -v README.md | wc -l | tr -d ' ')
NEW_DEC=$(ls docs/agent-memory/decisions/*.md 2>/dev/null | grep -v README.md | wc -l | tr -d ' ')
NEW_GOT=$(ls docs/agent-memory/gotchas/*.md 2>/dev/null | grep -v README.md | wc -l | tr -d ' ')
```

Report: `Extracted: Recent Work X/X, Decisions Y/Y, Gotchas Z/Z`. If counts don't match, abort with a diff summary — do not commit.

## Step 9: Refresh the CLAUDE.md rollup

Run the `refresh_recent_work_rollup` snippet from `/update-sop` Step 8b to regenerate the rollup section in CLAUDE.md with the newly extracted entries.

```bash
refresh_recent_work_rollup() {
  local claude_md="CLAUDE.md"
  local recent_dir="docs/recent-work"
  local tmp
  tmp=$(mktemp)

  {
    echo "<!-- recent-work-rollup:start -->"
    echo "*Auto-generated from \`docs/recent-work/\`. Last refreshed: $(date +%Y-%m-%d).*"
    echo ""

    local found=0
    if ls "$recent_dir"/*.md >/dev/null 2>&1; then
      for f in $(ls "$recent_dir"/*.md 2>/dev/null | sort -r); do
        [ "$(basename "$f")" = "README.md" ] && continue
        local fname title date_part agent_part
        fname=$(basename "$f" .md)
        date_part=$(printf '%s' "$fname" | cut -d_ -f1)
        agent_part=$(printf '%s' "$fname" | cut -d_ -f2)
        title=$(grep -m1 '^# ' "$f" | sed 's/^# //')
        [ -z "$title" ] && title="(untitled)"
        echo "- $date_part \`$agent_part\`: $title"
        found=1
      done
    fi

    [ "$found" = "0" ] && echo "*No entries yet.*"

    echo "<!-- recent-work-rollup:end -->"
  } > "$tmp"

  awk -v repl_file="$tmp" '
    /<!-- recent-work-rollup:start -->/ {
      while ((getline line < repl_file) > 0) print line
      close(repl_file)
      skip = 1
      next
    }
    /<!-- recent-work-rollup:end -->/ {
      skip = 0
      next
    }
    !skip { print }
  ' "$claude_md" > "${claude_md}.tmp" && mv "${claude_md}.tmp" "$claude_md"

  rm -f "$tmp"
}

[ "$DRY_RUN" = "0" ] && refresh_recent_work_rollup
```

## Step 10: Report

Print a summary:
- Number of entries extracted per category
- Paths to all new files (or count for brevity)
- Line counts of CLAUDE.md and agent-memory.md before/after
- Reminder: `git diff` to review, then commit with a conventional message like `chore: migrate to multi-agent directory structure`

In dry-run mode, print the same report but prefix with `DRY RUN — no changes made.`

## Notes

- Running this command multiple times is safe: Step 2 detects completed migration and exits cleanly.
- The command does not commit. The agent running the command reviews the result with `git diff` and commits manually.
- If any extraction looks incorrect, `git checkout .` reverts all changes and re-run after fixing.
