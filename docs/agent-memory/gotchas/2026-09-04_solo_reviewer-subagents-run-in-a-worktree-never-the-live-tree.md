# A reviewer subagent with Bash can overwrite the tree it is reviewing — isolate it in a worktree

**Date:** 2026-09-04
**Agent:** solo

**The surprise.** The Step 1b `code-reviewer` run on P97's uncommitted diff decided to "test edge cases" by building its own mini fixtures with heredocs. Its shell cwd was the live repo. Within a minute `Backlog.md` was a six-line stub, `docs/sop/claude-agent-sop.md` was one line, `CLAUDE.md` had lost the session's edits, and `src.js`, a fake `docs/recent-work/2026-09-04_solo_first.md` and a fake in-flight line had appeared. Nothing was committed, so `git checkout --` recovered the three files and the session's edits were re-applied from context; the strays were deleted. The agent's own last message, when stopped, read: "this was more extensive damage. Restoring both files immediately."

What caught it: a dry run of the new `sop-stop-drift.sh` against the live tree listed the stray files as uncommitted tracker files. The gate under review reported the damage done by its reviewer.

**Rule.** Any subagent that has Bash and is pointed at uncommitted work runs with `isolation: "worktree"`, or the work is committed first and the agent reviews the commit from a worktree. Its instructions say explicitly: create nothing in the repo, run only the existing suites (which use `mktemp -d`), return findings in the final message rather than writing files. The review artifact is then written by the parent session. `.claude/agents/code-reviewer.md` describes itself as read-only; the tool list (`Bash`) makes that a request, not a property.

Related: `2026-05-02_solo_worktree-uncommitted-wipe.md` (sibling worktrees), and the parallel-agent memory in the user's global notes about a sibling session sweeping uncommitted work into its commit with a broad `git add`.
