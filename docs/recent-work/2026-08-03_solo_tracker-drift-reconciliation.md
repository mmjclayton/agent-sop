# Batch 0.29 — tracker drift reconciliation, P74 shipped, P75 filed

**Date:** 2026-08-03
**Agent:** solo
**Commits:** `1df1abc`, `4e3e1b8` (PR #13, merged `74c61ff`)

`/restart-sop` opened on four inconsistencies, all downstream of one cause: the 2026-07-27 session merged PR #12 and changed a live hook, then ended without `/update-sop`, leaving every tracker holding the previous session's world-view while `main` moved on. Backfilled Batch 0.28, cleared the In-Flight line, rewrote the resume, and corrected the feature-map — where P24 had sat in the Medium Priority roadmap since shipping on 2026-05-04, and a second Recently Shipped table had been frozen at P28 while Shipped Documents ran to P74.

**P74** `[Bug]` shipped `[OPEN]` → `[SHIPPED - 2026-07-27]` across two commits, because both states are historically true and `<absent>` → `[SHIPPED]` is illegal. The `npx block-no-verify@1.1.2` hook — network fetch per Bash call, substring matching over the whole command string, evadable via a variable or `core.hooksPath=/dev/null` — was replaced by a local argv-matching script. Verified across 8 cases: 3 must-allow including the documented multi-statement false positive and a `-m` body containing `--no-verify`, 5 must-deny including bundled `-nm` and the `core.hooksPath` evasion.

**The overdue `/update-agent-sop` found more than a stale date.** Batch 0.27 changed `.claude/commands/update-sop.md` and `.claude/agents/sop-checker.md` without re-running the sync, so for eight days the user-scope `/update-sop` — the copy that executes in every session, in every project — ran without P66's enumerated skip token and P70's bounded test gate, while three tracker files recorded both as shipped. The repo was correct about intent and wrong about effect. Two mirrors synced forward, six baselines refreshed. Filed as **P75**: no gate asks whether a shipped change reached the surface that enforces it, and the only thing that surfaced this was a date-based staleness warning happening to be overdue.

No lite benchmark run — this batch edits no agent-facing instruction text, so the MANDATORY rule does not fire. Still owed by the next batch that does.
