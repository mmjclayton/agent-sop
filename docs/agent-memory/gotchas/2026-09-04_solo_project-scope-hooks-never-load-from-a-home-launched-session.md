# Project-scope hooks never load for a session launched outside the project, and Stop stdout is discarded

**Date:** 2026-09-04
**Agent:** solo

Two harness facts that together kept ship-sop's auto-mode silent for four and a half months, both invisible from inside the script.

**1. `<repo>/.claude/settings.json` hooks are read from the launch directory only.** A session started in `~` that runs `cd ~/Projects/foo` never registers foo's hooks. `CLAUDE_PROJECT_DIR` stays at the launch directory for the whole session; only the `cwd` field in each hook's input JSON follows the `cd`. On this machine the heavy consumer-repo sessions are launched from `~` — their transcripts live in the home-directory project folder with thousands of consumer-repo path references — so every install probe that said "hook wired" was true and irrelevant.

**2. `Stop` hook stdout goes to the debug log, not the model.** The documented exceptions where stdout becomes context are `SessionStart`, `UserPromptSubmit`, `UserPromptExpansion` and `PostModelSwitch`. A Stop hook that wants the model to do something must exit 2 with the instruction on stderr. ship-sop's hook printed its directive to stdout on exit 0.

How it was found: the same hook, run by hand with `SHIP_SOP_DEBUG=1` inside a throwaway `git clone --shared` of the consumer repo with the live branch, fired cleanly and wrote every state file. The script was fine; the harness never ran it, and would have discarded its output if it had.

**Rule.** Any hook that must fire for the maintainer's sessions is user-scope and resolves the repo from `cwd`. Any Stop hook that needs the model to act exits 2. Test a hook by checking for its side effects on disk after a real session, never by reading the settings file. Related: `reference_project_commands_need_session_root` (slash commands have the same launch-directory dependence).
