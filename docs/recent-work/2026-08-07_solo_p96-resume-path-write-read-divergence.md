# P96 — The write step never resolved the path the read steps derived

**Date:** 2026-08-07
**Agent:** solo

An agent running agent-sop on a consumer project reached `/update-sop` Step 7, found two resume files in its memory directory that belonged to other projects, and refused the step rather than overwrite either. It was right to. Step 7 named `~/.claude/projects/[project-hash]/memory/project_resume_${AGENT_ID}.md` and never resolved `[project-hash]`, while `/restart-sop` Step 0d and `--check-drift` both derived that directory from `git rev-parse --show-toplevel`. The only step that writes the file was the one step with no derivation.

An unresolved placeholder does not stop the write, it just relocates it: the agent uses the memory directory the *session* owns, which for a session launched outside the project is the harness catch-all shared across projects. So the snapshot landed where the drift gate never looks — `--check-drift` reported "no project_resume file found — skipping" and exited 0, enforcing nothing — and Step 7's write-side legacy fallback pointed at whichever project's unsuffixed `project_resume.md` got there first. Second occurrence, not first: the catch-all directory's `project_resume_solo.md` is Intelligent Studio's, already marked SUPERSEDED for the same reason.

Fixed by unifying the derivation into `scripts/resolve-resume-path.sh` rather than pasting the snippet into Step 7 — two copies had already been enough to hide a missing third. Writes lost the legacy fallback, reads kept it. The resolver refuses with exit 2 when the repo root is the home directory, where no project-scoped directory exists to derive.

Grepping for the *shape* rather than the filename found three more live instances: `sop-checker` located memory directories by substring-matching the project name against `~/.claude/projects/`, so an audit could score a project against another's files; the SessionStart hook in `harness-configuration.md` read every project's resume file on the machine and loaded it as session context; and `/restart-sop` Step 2's sibling scan used the same glob, now replaced by `git worktree list` enumeration since siblings have different repo roots.

New fixture suite at `docs/benchmark/resume-path-fixtures/`, 13 cases, verified to discriminate by running it against a stub that reproduces the pre-fix behaviour — 12 of 13 fail.
