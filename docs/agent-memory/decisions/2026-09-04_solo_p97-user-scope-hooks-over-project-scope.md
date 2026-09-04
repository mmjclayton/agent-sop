# P97: hooks are user-scope and resolve the repo from `cwd`, never project-scope

**Date:** 2026-09-04
**Agent:** solo

We chose to ship the automation as **user-scope hooks** registered in `~/.claude/settings.json`, each resolving the repository from the `cwd` field in its input JSON, rather than as project-scope entries in `<repo>/.claude/settings.json` — the placement ship-sop used and the SOP's harness reference implementations showed.

The reason is a fact about the harness, verified against the hooks documentation and against this machine's transcripts: project-scope hooks load only from the directory Claude Code was launched in, and `CLAUDE_PROJECT_DIR` "points at the project root where the session started". The maintainer launches from `~` and `cd`s into a project. Three of this week's heaviest consumer-repo sessions have their transcripts in the home-directory project folder. In those sessions the project's Stop hook was never registered, which is why ship-sop's hook wrote no state file on any consumer repo after its wiring was fixed, even though the same script fires correctly when run by hand in a clone.

A user-scope hook fires in every session. Resolving the repo from `cwd` (which follows the session's `cd`) rather than from the launch directory means it finds the project the agent is actually working in. The cost is one guard at the top of every hook — is this an SOP repo? — and silence everywhere else.

Two consequences:

- `SessionStart` alone is not enough for context loading, because it fires before the `cd`. The context hook is registered on `UserPromptSubmit` too; the first prompt inside the project is what loads it. One prompt of lag, no command typed.
- Anything installed project-scope for the maintainer's own use is inert. `harness-configuration.md` now says so; ship-sop's remaining project-scope wiring in consumer repos is filed for removal.

Rejected: keeping project-scope and documenting "launch from inside the project". A rule the operator has to remember is the failure mode this whole item exists to remove.

---
*Supersedes:* the placement in `harness-configuration.md` reference implementations (a) and (b), and ship-sop's decision `2026-08-03_solo_sessionstart-hook-is-the-automation-path.md` (same intent, wrong scope).
