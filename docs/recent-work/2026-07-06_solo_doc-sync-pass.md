# Doc-sync pass after P60-P65

**Date:** 2026-07-06
**Agent:** solo
**Commits:** (see PR #9)

Documentation sync sweep after the day's ships, per owner request. Four fixes:

1. **`/update-agent-sop` manifest gap closed** (flagged in config notes 2026-05-28, never actioned): `docs/sop/multi-agent.md` and `docs/guides/cross-layer-rules.md` added as tracked pristine-replicas. Without this, consumers never received multi-agent.md at all — including today's M6/background-subagent changes. User-scope mirror + baseline refreshed.
2. **Pre-flight line propagated** to every surface that restates the session-end checklist: README `/update-sop` section (which also mislabelled a 10-item list as "9-step" — pre-existing), repo CLAUDE.md, and both CLAUDE.md templates. C4 guidance in `compliance-checklist.md` + `sop-checker.md` updated so the optional `0.` line never miscounts against the 9-step check.
3. **`sop-implementation-guide.md`** end-checklist counts corrected 7 → 9 (two sites; stale since P42/P43).
4. Config note `_doc_sync_2026-07-06` records the pass.
