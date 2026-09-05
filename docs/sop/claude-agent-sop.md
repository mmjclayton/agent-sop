# Claude Code Agent SOP

SOP-Version: 2026-09-05

The standard operating procedure for Claude Code sessions on a project. It supplies the context a session cannot derive and enforces the few standards a model does not keep by default. Everything else was cut on 2026-09-05 (P105) after a measured review: the hooks now do the mechanical half, and prose that duplicated them or was never read again is gone. Where a rule traces to a recorded incident, the P-number is given.

---

## Section 0: Rules

**Rule 1: Never delete without a trace.** In-place updates are the norm (a status tag, a corrected fact, an answered question folded into its item). Removal is not. Backlog items flip to `[WON'T]` with a `Reason:`; superseded decisions and gotchas get a trailing `*Superseded by:*` line and move to `archive/`; the resume snapshot is overwritten each session because it is a snapshot; a legacy resume file is marked `**SUPERSEDED - <date>.**` rather than removed. Every changed line traces to the request; no drive-by changes.

**Rule 2: One source of truth.** When files disagree: code and git state, then `CLAUDE.md`, then `Backlog.md`, then `docs/build-plans/`, then `docs/agent-memory/`, then the resume snapshot. Fix the lower one.

**Override:** `CLAUDE.md` is the authority on project-specific conventions; this document is the authority on process. Multi-agent mechanics (worktrees, agent-ids, merge discipline) live in `docs/sop/multi-agent.md`.

---

## 1. Files

| File | Written by | Read by |
|---|---|---|
| `CLAUDE.md` | operator and session | the harness, every session |
| `Backlog.md` | session | the context hook (in-progress headings) and the session (one item's range, never the whole file) |
| `docs/agent-memory/decisions/`, `gotchas/` | session, one file per entry | later sessions by filename, then by need; gotchas are the entry most often read again |
| `docs/agent-memory/in-flight/<agent-id>.md` | session | the context hook |
| `docs/agent-memory.md` | scripts (In-Flight block) and the operator (Key Documents, Key Source Files, Preferences) | `/restart-sop` when hooks are absent |
| `docs/recent-work/` | session, one file per session | the rollup script; the context hook shows the three newest titles |
| `docs/RECENT-WORK.md` | `scripts/refresh-rollup.sh` | the context hook |
| `docs/reviews/` | session, after a review run | the validator (`review:` citations), the push gate (`Covers:` lines), later reviews |
| `docs/build-plans/phase-N.md` | operator and session, as planning | the session on an interrupted phase |
| resume snapshot, `project_resume_<agent-id>.md` | session, overwritten each close | the context hook (first 80 lines), the drift validator |

**Path rule (P96):** the resume snapshot lives in the machine-local memory directory derived from the git root, at the path `bash scripts/resolve-resume-path.sh` prints (`--read` for the read target). Never hand-construct it: the harness names its directories after the launch path, so a hand-built path lands in another project's directory.

**Entry files:** `YYYY-MM-DD_<agent-id>_<slug>.md`; slug kebab-case, no underscores. Body: a title line, `**Date:**`, `**Agent:**`, then the content (`**Commits:**` on session records). A decision says what was chosen over what and why; a gotcha says the surprise, the prior expectation, and the rule that prevents a repeat (P54). Data-model invariants and named utilities that a reader of the schema would miss belong in gotchas too.

**Project type:** `CLAUDE.md` opens with `**Project type:** code` or `non-code`. One rule, `scripts/hooks/sop-project-type.sh`, reads it (heuristics in `compliance-checklist.md` apply when the line is absent); the ship gate, the Stop hook, `/update-sop`, `/finish` and `/ship` all follow it (P102, P103).

**CLAUDE.md size:** per-session sections under 200 lines for non-code projects, 300 for code projects with a Common Mistakes section. Point large files at a stable anchor (a symbol, a block, a grep target), never a line range: ranges rot on the next edit and send a session to the wrong slice with confidence (P91).

**Backlog size:** move closed items older than 90 days to `docs/backlog-archive.md` with `bash scripts/archive-backlog.sh` (P105). Closed items were 67 to 89 percent of the file in four measured repos and nothing read them.

---

## 2. Session start

With the user-scope hooks installed (`scripts/install-hooks.sh`), the context hook prints the resume snapshot, the recent sessions and every non-default fact on the first prompt inside the project. `/restart-sop` then does the two things that stay a judgement: list the newest decisions and gotchas and open the relevant ones; locate the Backlog item with `grep -n "^### P<n>"` and read only its range.

Without hooks, read the resume snapshot at the resolver's `--read` path and `git log --oneline -10` first.

---

## 3. Session end

On a code project the Stop hook enforces the minimum (P97, P103): a session record for every commit, clean tracker files, and a gate report covering HEAD when ship-sop applies. `/update-sop` is the full close and the only close on non-code projects. Its steps, each one an action with a checkable product:

1. **Tests** (code projects). A red suite ships nothing tagged `[Feature]` or `[Refactor]` unless the failure is filed as a `[Bug]` this session and named in the resume snapshot's Blockers (P70).
2. **Review.** A `[Feature]` or `[Refactor]` shipping this session takes a reviewer turn when the diff exceeds the threshold (default 50 lines or 3 files), when any SOP-executed file changed (`docs/sop/`, `docs/guides/sop-*`, `.claude/agents/`, `.claude/commands/`, `scripts/validate-*`: every item, whatever its tag, P87), or when a project-declared or security path changed. On a code project under ship-sop auto-mode the gate run is that turn; one run, one report. Reviewer agents run with `isolation: "worktree"` and return findings; the session writes the artefact (two overwrite incidents, 2026-09-04 and 05). The Backlog entry then carries `review: docs/reviews/<file>` (the path must exist, P95) or `review skipped (P<n>): <docs-only|test-only|dep-bump|below-threshold>` (P66); under the self-modification trigger only `test-only` and `dep-bump` are accepted.
3. **Backlog.** Tags in place; new items with acceptance criteria; `scripts/refresh-priorities.sh` where `CLAUDE.md` carries the sentinels (P92); `scripts/archive-backlog.sh` (a no-op until something is 90 days closed).
4. **Validators.** `scripts/detect-trackers.sh` for secondary trackers (P42); `scripts/validate-state-transitions.sh` for transitions and review citations (P45); `--check-drift` for commits the resume never declared (P46; a `## Scope Change` block in the snapshot is the declared exception); `--check-replication` for pristine-replica files that changed but did not reach the installed copy (P75).
5. **Memory.** Decision and gotcha files that pass the substance gate; `scripts/refresh-in-flight.sh`.
6. **Snapshot and record.** Overwrite the resume snapshot (what was done, what is next, blockers); write the session record; `scripts/refresh-rollup.sh`.
7. **Commit** `docs/` with the work, by name.

---

## 4. Backlog

**Status, first:** `[OPEN]`, `[IN PROGRESS]`, `[BLOCKED]` (waiting on someone else), `[DEFERRED]` (chosen to wait; must carry `**Reopens when:** <observable condition>`, P71), `[SHIPPED - YYYY-MM-DD]`, `[VERIFIED - YYYY-MM-DD]` (confirmed where it runs; for documentation projects, confirmed by the owner), `[WON'T]` (with `Reason:`).

**Type, second:** `[Feature]`, `[Iteration]`, `[Bug]`, `[Refactor]`. **Optional, last:** `[has-open-questions]`, `[ok-for-automation]` (small blast radius, two concrete criteria, names the file, reversible).

**Transitions** are enforced by the validator: `[OPEN]` and `[BLOCKED]`/`[DEFERRED]` move through `[IN PROGRESS]` to `[SHIPPED]`; `[SHIPPED]` moves only to `[VERIFIED]`; `[VERIFIED]` and `[WON'T]` are terminal (a revival is a new P-number); nothing ships from absent.

**P-numbers** are sequential and never reused; they carry no priority. Operational work (infra, in-session fixes) takes no P-number. Branches are `<type>/<slug>`.

---

## 5. CLAUDE.md

Required sections: the project-type line; `## Key Documents & Dispatch` in intent-based form (`When you need to... | Start at | Notes`, at least five entry points with paths, anchors not line ranges; benchmark round 2 measured 27 versus 56 tool calls on the task it was built for); `## Common Mistakes` on code projects (project-specific entries that name the file, the model or the token, state what is wrong and what is correct, and the consequence; benchmark round 2 showed an anti-pattern-only entry led an agent to remove the mechanism); `## Backlog Management` (the tag rules above, briefly); `## Stack` and `## Key Commands`; a priority block between `<!-- priority-items:start -->` and `<!-- priority-items:end -->` that the script rewrites; a two-line pointer to this document for session start and end. Templates: `docs/templates/claude-md-template.md` (non-code) and `claude-md-template-code.md` (adds Auth, Database, Design System).

What does not belong: general coding rules (they load from the user's `~/.claude/rules/`), a Definition of Done (measured at zero effect on bug fixes, P88), hand-maintained priority lists (117 days stale in one measured repo, P92), derived facts such as test counts.

---

## 6. Companions

`docs/sop/security.md` (secrets, injection, gate integrity), `docs/sop/sandboxing.md`, `docs/sop/harness-configuration.md` (the hooks and what each prints), `docs/sop/multi-agent.md`, `docs/sop/compliance-checklist.md` (what `sop-checker` audits), `docs/guides/` for the optional patterns. ship-sop (separate install) supplies the reviewer gates; its trigger lives in agent-sop's hooks and fires only on code projects and code lines.
