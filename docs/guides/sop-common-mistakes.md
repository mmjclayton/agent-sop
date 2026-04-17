<!-- SOP-Version: 2026-04-17 -->
# SOP Common Mistakes to Avoid

> Extracted from core SOP Section 14 on 2026-04-17 (P40 — instruction-budget trim).
> These are mistakes agents make when *applying* the SOP, distinct from the per-project "Common Mistakes — Read Before Coding" template described in core SOP Section 15.1.

| Mistake | Why it matters | Correct approach |
|---------|----------------|-----------------|
| Silently removing content | Destroys project history, may erase still-relevant decisions | Update in place, mark superseded, or move to Archived — never silently delete |
| Appending to project_resume.md instead of overwriting | Bloats the file with history that belongs in batch logs | Overwrite with current snapshot each session |
| Removing stale entries from agent-memory.md | Agents shouldn't unilaterally decide what's stale | Move to Archived with a superseded date |
| Confusing agent-memory.md with project_resume.md | Different purposes — permanent context vs point-in-time handoff | Permanent patterns go in agent-memory.md, session state goes in project_resume.md |
| Putting work item status in build plans | Agents check Backlog.md — build plans drift | Status only in Backlog.md |
| Updating feature-map.md but not Backlog.md | Next agent sees inconsistent state | Always update both together |
| Leaving In-Flight Work populated after shipping | Next agent thinks work is still active | Move to Completed Work with date and PR number |
| Not dating decisions in agent-memory.md | Stale decisions can't be identified | Always format as `YYYY-MM-DD: Decision` |
| Gotchas section limited to "mistakes" only | Data model invariants and utility functions get lost | Gotchas covers invariants, named utility functions, and framework patterns too |
| Dispatch Quick Reference listing vague entry points | Agents can't orient quickly | Name specific files with full paths — update each phase |
| Recent Work with no PR numbers | Can't cross-reference with git history | Always include PR number range |
| Storing derived facts in memory (test counts, line numbers, versions) | Goes stale immediately, misleads future agents | Store the rule, not the measurement — check at runtime |
| Skipping tests before committing (code projects) | Broken code ships, next session starts with failures | Run the test suite as step 1 of session-end checklist |
| Skipping session end checklist for "small changes" | Small changes compound into context debt | No exceptions |
