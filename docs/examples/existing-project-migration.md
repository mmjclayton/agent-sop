# Migrating an Existing Project to the Agent SOP

A checklist-based guide for adding the Agent SOP to a project that already has code, history, and possibly some ad-hoc CLAUDE.md or agent-memory files.

---

## Before you start

Migration does not require rewriting your project. The goal is to get the standard file set in place with correct structure so that every future Claude Code session starts with full context and ends with a clean handoff.

**Time estimate:** A minimal migration (Steps 1-4) can be done in a single session. The full migration (Steps 1-7) typically takes two sessions.

---

## Step 1 — Audit your current files

Run through this checklist to see what you already have and what is missing.

### File existence

- [ ] `CLAUDE.md` exists at project root
- [ ] `Backlog.md` exists at project root
- [ ] `docs/agent-memory.md` exists
- [ ] `docs/feature-map.md` exists
- [ ] `docs/build-plans/` directory exists with at least one phase file
- [ ] `project_resume.md` exists in local auto-memory (`~/.claude/projects/[hash]/memory/`)

### Common gaps in existing projects

| Gap | How to spot it | Fix |
|-----|---------------|-----|
| No Backlog.md | Work items scattered across CLAUDE.md, agent-memory, or nowhere | Create Backlog.md and migrate items (Step 2) |
| No feature-map.md | No record of what has shipped | Create from git history (Step 3) |
| No build plan | Architecture decisions live only in agent-memory or nowhere | Create a build plan for the current phase (Step 3) |
| agent-memory.md missing sections | No Completed Work, no Archived section, no Gotchas | Add missing sections (Step 4) |
| CLAUDE.md missing session checklists | Agents have no standard start/end routine | Add checklists (Step 4) |
| CLAUDE.md missing Dispatch table | Agents cannot orient quickly | Add Key Documents table (Step 4) |
| Duplicate information | Same status tracked in CLAUDE.md, agent-memory, and build plans | Consolidate per ownership rules (Step 5) |
| project_resume.md has wrong name | Uses a project-specific prefix like `project_taskflow_resume.md` | Rename to `project_resume.md` (Step 6) |

---

## Step 2 — Create missing files

### If Backlog.md does not exist

1. Create `Backlog.md` from the template (`docs/templates/backlog-template.md`).
2. Migrate work items from wherever they currently live:
   - CLAUDE.md priority lists or TODO sections
   - GitHub issues (use `gh issue list` to pull them)
   - Inline TODO comments in code
   - agent-memory.md In-Flight Work entries
3. Assign sequential P-numbers starting from P1.
4. Add status and type tags to every item. Already-shipped work gets `[SHIPPED - YYYY-MM-DD]` with the best date you can determine from git history.
5. Add the tag taxonomy header.

### If docs/feature-map.md does not exist

1. Create `docs/feature-map.md` with the standard header.
2. Populate the Shipped table from git history:
   ```bash
   git log --oneline --since="3 months ago" | head -30
   ```
   Group related commits into features. Each gets a row with P-number (matching Backlog), description, and ship date.
3. Populate the Roadmap section from your Backlog's `[OPEN]` items.

### If docs/build-plans/ does not exist

1. Create `docs/build-plans/`.
2. Create a build plan for whatever you are currently working on. If the project is between phases, create a plan for the next planned work.
3. Use the build plan template (`docs/templates/build-plan-template.md`).
4. You do not need to retroactively create build plans for past phases — the git history covers that.

---

## Step 3 — Fix agent-memory.md structure

If `docs/agent-memory.md` exists but is missing sections, add them. The required sections are:

```
## Key Documents
## Key Source Files for Current Work
## In-Flight Work
## Decisions Made
## Gotchas and Lessons
## [Project Name]'s Preferences
## Completed Work
## Archived
```

For each missing section:

- **Key Documents** — add `See CLAUDE.md Key Documents table.` (do not duplicate the table)
- **Key Source Files** — list 5-10 files relevant to the current phase of work
- **In-Flight Work** — check if there is active work; `*(none)*` if not
- **Decisions Made** — migrate any architectural decisions from CLAUDE.md or comments. Date them using git blame if needed
- **Gotchas and Lessons** — migrate data model invariants, utility function notes, framework quirks from CLAUDE.md or inline comments
- **Preferences** — move any agent behaviour rules from CLAUDE.md that are preferences rather than hard rules
- **Completed Work** — `*(none yet)*` is fine; it fills up as future sessions complete
- **Archived** — `*(none yet)*` is fine; it collects superseded entries over time

**Important:** Do not delete existing content during migration. Move entries to the correct section, but never drop them.

---

## Step 4 — Update CLAUDE.md to SOP standard

This is usually the largest step. Compare your existing CLAUDE.md against the template (`docs/templates/claude-md-template.md` or `claude-md-template-code.md` for code projects).

### Required sections checklist

- [ ] **Agent SOP** — reference to the SOP document and the two non-negotiable rules
- [ ] **Build Plans -- READ FIRST** — links to current phase files
- [ ] **Key Documents & Dispatch** — single table, minimum 5 entries with real file paths, test command, after-shipping reminder
- [ ] **Current Priority Items** — `[OPEN]` and `[IN PROGRESS]` items only, grouped by tier
- [ ] **Backlog Management** — tag taxonomy and rules (not the full Backlog content)
- [ ] **Stack** — technologies, hosting, CI, live URL
- [ ] **Key Commands** — 3-5 most-used shell commands
- [ ] **Rules for Automated Builds** — numbered list including "never delete without a trace"
- [ ] **Session & Memory Hygiene** — 5-step start checklist and 7-step end checklist
- [ ] **Recent Work** — append-only, new entries at top, PR/commit references
- [ ] **Deprioritised** — section exists (can be empty)

### For code projects, also add

- [ ] **Auth** — provider, token type, middleware path, protected routes pattern
- [ ] **Database** — ORM, migration tool, schema location, schema change protocol
- [ ] **Design System** — component library, palette, typography, spacing, responsive strategy
- [ ] **Code Quality Rules** — file size limits, test coverage, linting requirements

### Common CLAUDE.md migration fixes

| Problem | Fix |
|---------|-----|
| Work item status tracked in CLAUDE.md | Move to Backlog.md. CLAUDE.md only shows current priorities |
| Architecture decisions in CLAUDE.md | Move to agent-memory.md Decisions Made or a build plan |
| No line-range hints in Dispatch table | Add hints for any file over 200 lines (e.g. `index.css (lines 1-80)`) |
| Session checklists missing or incomplete | Replace with the standard checklists from the SOP |
| No test command in Dispatch | Add `Test: [command]` below the table |
| Recent Work section missing PR numbers | Add commit or PR ranges retroactively from `git log` |
| CLAUDE.md over 200 lines of per-session content | Move detail to agent-memory.md or build plans |

---

## Step 5 — Eliminate duplicate information

The SOP assigns each information type to exactly one file. Common duplications to resolve:

| Duplicated information | Keep in | Remove from |
|-----------------------|---------|-------------|
| Work item status | `Backlog.md` | CLAUDE.md, build plans, agent-memory |
| Shipped feature inventory | `docs/feature-map.md` | CLAUDE.md |
| Architecture decisions | `docs/build-plans/phase-N.md` | CLAUDE.md, agent-memory (keep a short reference) |
| Cross-session decisions and gotchas | `docs/agent-memory.md` | CLAUDE.md |
| Stack and conventions | `CLAUDE.md` | agent-memory.md |
| Brand and copy rules | `.claude/brand-voice.md` | CLAUDE.md, agent-memory |

When removing duplicates, leave a pointer to the authoritative location (e.g. "See Backlog.md for work item status") rather than silently deleting.

---

## Step 6 — Fix local files

### project_resume.md

- If it uses a project-specific name (e.g. `project_myapp_resume.md`), rename it to `project_resume.md`.
- If it has accumulated log entries rather than being a snapshot, rewrite it as a clean snapshot:
  ```markdown
  # Session Resume — [Project Name]

  Last updated: [today's date]

  ## What was done
  [Most recent session summary]

  ## What is next
  [Next Backlog item or action]

  ## Blockers
  (none)
  ```

### MEMORY.md

- Ensure it exists at `~/.claude/projects/[project-hash]/memory/MEMORY.md`.
- Ensure it contains a pointer to `project_resume.md`.
- Keep entries under 150 characters each, under 200 lines total.

---

## Step 7 — Optional: hooks, agents, and security

These are recommended for code projects but not required for basic SOP compliance.

### Hooks

Create `.claude/settings.json` with hooks. The two highest-value hooks:

1. **SessionStart** — automatically reads CLAUDE.md and agent-memory.md at the start of every session.
2. **PreCompact** — reminds the agent to run the session end checklist before context is compressed.

See `docs/sop/harness-configuration.md` for JSON config examples and 4 additional reference implementations.

### Review agents

Copy agent definitions from the agent-sop repo's `.claude/agents/` directory:
- `code-reviewer.md` — general code quality
- `security-reviewer.md` — OWASP Top 10 and secret detection

Customise the stack sections for your project.

### Security

Review `docs/sop/security.md` in the agent-sop repo. At minimum:
- Confirm no secrets are committed (run `git log --all -p | grep -i "password\|secret\|api_key"`)
- Add secret patterns to `.gitignore` if not already present
- Ensure your auth model is documented in CLAUDE.md

---

## Migration verification checklist

After completing the migration, verify with this checklist:

### Files exist and have correct structure

- [ ] `CLAUDE.md` — all required sections present, no bracket placeholders
- [ ] `Backlog.md` — tag taxonomy header, at least one P-numbered item, Shipped Archive section
- [ ] `docs/agent-memory.md` — all 8 sections present (Key Documents, Key Source Files, In-Flight Work, Decisions Made, Gotchas, Preferences, Completed Work, Archived)
- [ ] `docs/feature-map.md` — Last Updated header, Shipped table, Roadmap section
- [ ] `docs/build-plans/phase-N.md` — at least one build plan with Problem, Scope, Architecture, Batch Log
- [ ] `project_resume.md` — exists in local auto-memory, named correctly

### Cross-file consistency

- [ ] Backlog items match priority list in CLAUDE.md
- [ ] Shipped features in feature-map match `[SHIPPED]` items in Backlog
- [ ] Key Documents table has at least 5 entries with real paths
- [ ] No duplicate information across files (use the ownership table in Step 5)
- [ ] Session start and end checklists match the SOP standard

### First session test

Run the session start checklist as a test:

1. Read CLAUDE.md — can you orient in under 2 minutes?
2. Read agent-memory.md — does it contain useful decisions and gotchas?
3. Read project_resume.md — do you know what to work on next?
4. Run `git log --oneline -10` — does Recent Work in CLAUDE.md match?
5. Read the next Backlog item — are the acceptance criteria clear?

If any step fails, fix the relevant file before considering the migration complete.

---

## After migration

From this point forward, every session follows the SOP rhythm:
- Start with the 5-step checklist
- End with the 7-step checklist
- Wrap up at 60% context capacity, not 95%

The SOP compliance checker agent (`.claude/agents/sop-checker.md` in the agent-sop repo) can audit your project at any time. Run it after migration to confirm your score and identify any remaining gaps.
