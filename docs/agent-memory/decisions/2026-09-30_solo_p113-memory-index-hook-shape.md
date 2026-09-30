# P113: the memory index hook reports in bytes, from 80 per cent, once per size, and never refuses

**Date:** 2026-09-30
**Agent:** solo

**Chosen:** a `PostToolUse(Write|Edit|MultiEdit)` hook that measures the written `MEMORY.md` in bytes and lines, reports on stderr with exit 2 when either is at or over 80 per cent of the harness limit (25,000 bytes or 200 lines), and stays quiet in a session until the index grows past the size it last reported.

**Over:**
- A `PreToolUse` refusal. The index is a file the harness prompt tells the agent to maintain; refusing the write would block ordinary memory work and would still leave the oversize index in place. The write has happened by the time a report can be accurate, so the hook reports.
- Character counts. `sop-lib.sh` exports `LC_ALL=C`, so `awk length` counts bytes, and the harness limit is a byte limit. The guideline "about 200 characters" becomes 200 bytes, which is stricter on lines with em-dashes.
- Reporting on every write once over the threshold. That is the nag the P97 design rejected; a marker per session and per index path keyed on the largest size reported keeps it to once per fact.
- A `/update-sop` step that maintains a pointer line per project (option D in the brief). A pointer of name, path and purpose has nothing to maintain; a maintained line reintroduces state into the index.

**Also decided:** Claude Code only, because the index is a Claude Code file and Codex keeps its own store; runs outside SOP projects, because the index that overflowed is the one shared by sessions launched from the home directory; missing jq and an unreadable index are reported, not passed over.

**Evidence:** `docs/reviews/20260930-111100-ship-auto.md`, `docs/reviews/20260930-111521-ship-auto.md`; the brief's measurements are in the session record.
