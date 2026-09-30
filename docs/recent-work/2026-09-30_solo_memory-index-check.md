# Memory index size check and harness memory rule

**Date:** 2026-09-30
**Agent:** solo
**Commits:** c17eff1, 22e76e0, 4e99b7f, 783cfe7

P113 shipped `scripts/hooks/sop-memory-index.sh`, a Claude Code `PostToolUse(Write|Edit|MultiEdit)` hook that reports a harness `MEMORY.md` at 80 per cent of its 200 line or 25,000 byte load limit. P114 added the rule that SOP project state stays out of harness memory to the SOP, `/update-sop` and the Codex skill.
The ship gate blocked once (MultiEdit not registered, unreadable index silent); 783cfe7 fixed both and the re-review passed. Receipt: `docs/reviews/20260930-111100-ship-auto.json`.
c17eff1 (24 Sep) recorded that main is protected and had no session record of its own.
Open at the time of writing: the PR is not merged, the hook is not installed on this machine, and ship-sop replication has not started. The in-flight file carries these.
