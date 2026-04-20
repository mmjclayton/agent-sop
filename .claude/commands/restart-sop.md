---
description: Run the Agent SOP session start checklist. Reads all context files, checks git history, flags inconsistencies, and reports readiness before coding begins.
sop_version: "2026-04-19"
---

Start a new session by executing the Agent SOP session start checklist. Read every file listed below, in order. Do not skip any step.

## Step 0: SOP staleness check

Before running the checklist, check the Agent SOP update cadence. Read `.claude/agent-sop.config.json` (project) or `~/.claude/agent-sop.config.json` (user-global). If neither exists, skip this step.

Compare `last_update_check` against `update_reminder`:
- `weekly`: warn if `last_update_check` is more than 7 days old or `null`
- `manual`: never warn
- `off`: never warn

If stale, print: *"SOP update overdue — run `/update-agent-sop` to sync pristine-replica files."* Then continue with the checklist. Do not block.

## Step 0b: Resolve agent identity

Agent identity appears in filenames (`docs/recent-work/YYYY-MM-DD_<agent-id>_<slug>.md`), in per-agent `project_resume_<agent-id>.md`, and in commit-range partitioning for the drift guard (Step 4). Resolve it before reading any project files.

Precedence: `CLAUDE_AGENT_ID` env var > `.sop-agent-id` file at worktree root > `solo` (single-worktree default) > 6-char hash of worktree path. See `docs/guides/multi-agent-parallel-sessions.md` Section 1 for full scenarios.

```bash
resolve_agent_id() {
  if [ -n "${CLAUDE_AGENT_ID:-}" ]; then
    printf '%s' "$CLAUDE_AGENT_ID"
    return
  fi

  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null) || { printf 'solo'; return; }

  if [ -f "$root/.sop-agent-id" ]; then
    head -1 "$root/.sop-agent-id" | tr -d '[:space:]'
    return
  fi

  local count
  count=$(git worktree list 2>/dev/null | wc -l | tr -d '[:space:]')
  if [ "$count" = "1" ]; then
    printf 'solo'
    return
  fi

  if command -v shasum >/dev/null 2>&1; then
    printf '%s' "$root" | shasum -a 256 | cut -c1-6
  else
    printf '%s' "$root" | sha256sum | cut -c1-6
  fi
}

AGENT_ID=$(resolve_agent_id)
echo "Agent identity: $AGENT_ID"
```

When `$AGENT_ID` is `solo`, Step 2 reads `project_resume.md` (legacy filename). When any other value, Step 2 reads `project_resume_<agent-id>.md` first, and falls back to the legacy unsuffixed `project_resume.md` if the per-agent file is absent — supports long-lived projects that predate the per-agent convention. See Step 2 note.

## Step 0c: Resolve session commit range

Step 4 (secondary-tracker drift guard) scans only this agent's own branch commits since branching from the default branch. In parallel multi-agent work, scanning last-N commits on main would mix sibling agents' finding IDs with this agent's — producing false-positive drift reports. Branch-since-main scanning partitions cleanly.

```bash
resolve_session_commit_range() {
  local default_branch
  default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/@@')
  if [ -z "$default_branch" ]; then
    for candidate in origin/main origin/master origin/develop; do
      if git rev-parse --verify "$candidate" >/dev/null 2>&1; then
        default_branch="$candidate"
        break
      fi
    done
  fi
  if [ -z "$default_branch" ]; then
    printf ''
    return
  fi

  local base head_sha
  base=$(git merge-base "$default_branch" HEAD 2>/dev/null)
  head_sha=$(git rev-parse HEAD 2>/dev/null)
  if [ -z "$base" ] || [ "$base" = "$head_sha" ]; then
    printf ''
    return
  fi
  printf '%s..HEAD' "$base"
}

SESSION_RANGE=$(resolve_session_commit_range)
echo "Session commit range: ${SESSION_RANGE:-<empty — on default branch or no divergence>}"
```

When `SESSION_RANGE` is empty, the drift guard in Step 4 is a no-op.

## Step 0d: In-flight reassertion

Print a one-line reminder of the P-number(s) declared in `project_resume_<agent-id>.md`. This is informational — the enforcement layer (`/update-sop` Step 3d) checks the session's commits against these declarations at session end, with `## Scope Change` as the escape hatch. The reminder here exists so the agent sees the declaration explicitly before starting work, and notices if it drifted before committing.

```bash
root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [ -n "$root" ]; then
  project_hash=$(printf '%s' "$root" | sed 's|[^a-zA-Z0-9-]|-|g' | sed 's|--*|-|g' | sed 's|^-||')
  resume="$HOME/.claude/projects/-$project_hash/memory/project_resume_${AGENT_ID:-solo}.md"
  # Fallback: legacy unsuffixed project_resume.md. Always tried when the
  # per-agent file is absent, regardless of AGENT_ID. Long-lived projects
  # predating the per-agent filename convention keep the reassertion working
  # without forcing `/migrate-to-multi-agent` first. On non-`solo` agents,
  # emit a one-line advisory so the operator knows to migrate.
  if [ ! -f "$resume" ]; then
    legacy="$HOME/.claude/projects/-$project_hash/memory/project_resume.md"
    if [ -f "$legacy" ]; then
      resume="$legacy"
      [ "${AGENT_ID:-solo}" != "solo" ] && echo "Reading legacy unsuffixed resume ($resume). Run \`/migrate-to-multi-agent\` to move to per-agent format."
    fi
  fi
  if [ -f "$resume" ]; then
    pnums=$(grep -oE '\bP[0-9]+\b' "$resume" | sort -u | tr '\n' ' ' | sed 's/ *$//')
    [ -n "$pnums" ] && echo "In-flight declared: $pnums (from $resume)"
  fi
fi
```

If no resume file exists (first session, or fresh repo), the reassertion is silently skipped.

## Determine checklist type

Check if this session's task is tagged `[ok-for-automation]` in the Backlog, or is a single-file change with fewer than 2 acceptance criteria. If so, use the **Lightweight Start** (steps 1L and 2L only). Otherwise, use the **Full Start** (steps 1-6).

---

## Full Start (default — use for multi-file tasks, features, bug fixes, refactors)

### Step 1: Read CLAUDE.md

Read the project's `CLAUDE.md` at the repo root. This is the master context file containing stack, conventions, Common Mistakes, intent-rich dispatch table, Definition of Done rubrics, priority items, and session checklists.

Pay special attention to:
- **Common Mistakes** — project-specific gotchas that prevent wrong turns
- **Key Documents & Dispatch** — intent-based table ("When you need to...")
- **Definition of Done** — self-evaluation rubrics by task type

### Step 2: Read memory files (this agent's resume + optional sibling-agent snapshots)

Read these local memory files:
- `~/.claude/projects/[project-hash]/memory/MEMORY.md` (auto-memory index)
- `~/.claude/projects/[project-hash]/memory/project_resume_${AGENT_ID}.md` (this agent's last session snapshot)

If `project_resume_${AGENT_ID}.md` does not exist, fall back to `project_resume.md` (legacy single-agent filename). If neither exists, note this and continue.

When `$AGENT_ID` is not `solo`, also list sibling agents' resume files for advisory context — they reveal parallel in-flight work:

```bash
for f in ~/.claude/projects/*/memory/project_resume_*.md; do
  [ -e "$f" ] || continue
  [ "$(basename "$f")" = "project_resume_${AGENT_ID}.md" ] && continue
  echo "=== $f ==="
  sed -n '/^## What was done/,/^## /p' "$f" | head -20
done
```

These are read-only advisory — do not overwrite another agent's resume.

### Step 3: Read agent memory (narrative + decisions/gotchas directories)

Read `docs/agent-memory.md` if it exists. Contains the narrative sections: Key Documents pointer, Key Source Files, In-Flight Work, Completed Work, Preferences, Archived.

Scan the 10 most recent files in `docs/agent-memory/decisions/` and `docs/agent-memory/gotchas/` (sorted by filename date descending) to surface recent decisions and gotchas. Open any whose slug relates to this session's task; the rest stay advisory.

```bash
echo "=== Recent decisions ==="
ls -1 docs/agent-memory/decisions/*.md 2>/dev/null | sort -r | head -10
echo "=== Recent gotchas ==="
ls -1 docs/agent-memory/gotchas/*.md 2>/dev/null | sort -r | head -10
```

Check the `## In-Flight Work` section for a line matching this agent's id (`- ${AGENT_ID} (...)`). If that line exists, the previous session for this agent was interrupted — read the build plan Batch Log (linked from CLAUDE.md) before starting new work. Other agents' lines in In-Flight Work indicate parallel activity in sibling worktrees; do not clear them.

### Step 4: Check git history

Run `git log --oneline -10` and cross-check against:
- Recent Work in CLAUDE.md (do the commit refs match?)
- Completed Work in agent-memory.md (is anything missing?)
- project_resume.md "What was done" (does it match the latest commits?)

If anything is inconsistent, flag it before proceeding.

**Secondary-tracker drift guard:** partition commits by branch — use `SESSION_RANGE` from Step 0c. In parallel multi-agent work this restricts the scan to this agent's own branch, so sibling agents' finding IDs are not miscounted as this agent's drift. Detect trackers the same way `/update-sop` Step 3b does — `.md` files in CLAUDE.md's Key Documents that use heading-level status tags.

```bash
if [ -n "$SESSION_RANGE" ]; then
  git log "$SESSION_RANGE" --format='%s' | grep -oE '\b[A-Z]+-?[0-9]+\b' | sort -u
  # For each ID, grep tracker files; any still-[OPEN] is drift from a prior session on this branch
fi
```

When `SESSION_RANGE` is empty (agent on default branch directly, no diverging commits), the drift guard is a no-op. Flag any stale `[OPEN]` entries in Step 6 so the user can choose to reconcile before new work begins. Do not auto-reconcile — prior sessions may have had a reason to leave them open.

### Step 5: Read the current work item

Read the specific Backlog item(s) listed under Current Priority Items in CLAUDE.md. Read the full item in `Backlog.md` including acceptance criteria.

If there is an active build plan (linked in CLAUDE.md under Build Plans), read its Architecture and Batch Log sections.

### Step 6: Report readiness

After completing all reads, report:
- What the current priority item is
- Whether the previous session ended cleanly or was interrupted
- Any inconsistencies found between files
- Which Definition of Done rubric applies to this task type
- What you are ready to work on

Do not begin coding until you have completed all 6 steps.

---

## Lightweight Start (for `[ok-for-automation]` or single-file tasks)

### Step 1L: Read CLAUDE.md (targeted sections only)

Read the project's `CLAUDE.md`, focusing on:
- **Common Mistakes** — to avoid known gotchas
- **Key Documents & Dispatch** — to find the right file
- **Definition of Done** — to know the self-evaluation criteria

Skip: agent-memory.md, build plans, MEMORY.md, project_resume.md.

### Step 2L: Read the Backlog item

Read the specific item from `Backlog.md` including acceptance criteria. Then begin work.

Saves ~3-4K tokens compared to the full start. Use only when the task is truly self-contained.
