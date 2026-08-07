# A write step with no path derivation inherits the session's directory

**Date:** 2026-08-07
**Agent:** solo

`/update-sop` Step 7 named its target as `~/.claude/projects/[project-hash]/memory/project_resume_${AGENT_ID}.md` and never said how to resolve `[project-hash]`. Both readers of the same file — `/restart-sop` Step 0d and `validate-state-transitions.sh --check-drift` — derived it from `git rev-parse --show-toplevel`. The asymmetry survived P43, P46 and P47, all of which touched the resume file, because every one of them was working on the read side.

An unresolved placeholder in an instruction is not a no-op. The agent still has to write somewhere, so it uses the only memory directory it can see: the one the *session* owns. The harness names those after the session's launch path, so a session started outside the project gets a catch-all directory shared with every other project touched the same way.

Two consequences, both silent:

- The snapshot lands where the drift gate never looks. `--check-drift` prints `no project_resume file found — skipping` and exits 0. The gate reports success while enforcing nothing.
- That shared directory holds several projects' resume files, and every single-worktree project resolves to agent-id `solo`. Step 7's write-side legacy fallback then names another project's file as the write target.

**The tell:** a path that appears in both a read instruction and a write instruction, where only one of them shows the derivation. Grep for the placeholder, not the filename — `project_resume` appeared on 12 files and read consistently; `[project-hash]` was where the rule went missing.

**Second tell:** locating a file by matching a *name* rather than deriving a *path*. Three more instances of the same shape were sitting in the repo: `sop-checker` substring-matched the project name against `~/.claude/projects/`, and two places globbed `~/.claude/projects/*/memory/`. All three silently widen to other projects.

Related: [[2026-08-03_solo_merging-without-update-sop-strands-every-tracker]] — same family, an enforcement step that no-ops while reporting success.
