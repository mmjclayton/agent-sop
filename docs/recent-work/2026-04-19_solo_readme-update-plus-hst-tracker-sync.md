# README update + hst-tracker sync + P47 filing

**Date:** 2026-04-19
**Agent:** solo
**Commits:** 75167df (README), 5b0220e (P47 filing); hst-tracker: 081c47b (SOP sync)

Follow-up session after the P44/P45/P46 enforcement-gates batch. Three small actions:

**README** — added a "Machine-checkable enforcement gates" bullet distinguishing P44/P45/P46 enforcement from prescription; updated compliance check counts 84→87 (code) / 75→78 (non-code); noted B11/R1/D1. +1 net line (239→240). Commit `75167df`.

**hst-tracker sync** — pulled P44/P45/P46 pristine-replica files via three-way-diff logic. All 8 touched files had `baseline == local` so copies were non-destructive. Project-scope (4 files) landed as one clean commit on main (`081c47b`, pushed to `github.com:mmjclayton/repcanvas.git`). User-scope (4 files in `~/.claude/`) refreshed ambiently. `security.md` correctly skipped per long-standing config note (hst-tracker runs its own RepCanvas security doc at that path). `docs/reviews/` created.

**P47 filed** — `[OPEN] [Bug]` entry added to Backlog, commit `5b0220e`. Surfaced during hst-tracker sync: drift-check's legacy-resume fallback (`project_resume.md` when `project_resume_<agent-id>.md` is missing) only fires when agent-id is literally `solo`. hst-tracker has 2 worktrees, so agent-id resolves to a 6-char hash, fallback never runs, drift check silently no-ops. Fix proposal: always try the legacy path as a last resort with a migration advisory when agent-id is not `solo`.

**No Backlog status flips this session.** No new shipped items on agent-sop itself. Session is purely follow-up / triage / distribution.

**Next session:** P47 bugfix (small, independent) or P24 multi-agent optimisation guide per CLAUDE.md priorities.
