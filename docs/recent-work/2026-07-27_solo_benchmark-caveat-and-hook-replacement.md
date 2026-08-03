# Benchmark figure caveat + `block-no-verify` hook replacement

**Date:** 2026-07-27
**Agent:** solo
**Commits:** `314b98f` (PR #12)

*Reconstructed on 2026-08-03 from git history and filesystem evidence. The session that did this work ended without running `/update-sop`, so it left no trace in any tracker — the gap is itself recorded below.*

Two things shipped, one in the repo and one in the user-scope harness.

**README caveat (no P-number, follow-on from P68).** `README.md:19` gained a k=1 caveat when P68 shipped, but `:229` still cited "+33% on vague prompts" bare. P68's own rule says a publicly cited figure needs k>=5, so the repo was publishing a number its own methodology calls indefensible — in the one place a reader arrives at it through the argument rather than the summary. Now attributed to Round 2 specifically and pointed at the Limitations section, matching `:19`. The number is not restated or re-weighted; R2 measured what it measured. The same single-line miss the P67-P69 review caught at `:19`, one line further down.

**P74 `[Bug]` — `npx block-no-verify@1.1.2` replaced with a local argv-matching hook.** Raised in Matt's 2026-07-26 audit, carried in the resume as optional and not actioned, fixed here. Three defects: it fetched a package from the network on every Bash call (against `~/.claude/rules/web/hooks.md`), it substring-matched the whole command string so unrelated multi-statement commands and `-m` message bodies tripped it, and it was trivially evaded by building the flag in a variable or by `git -c core.hooksPath=/dev/null`. The replacement at `~/.claude/scripts/hooks/block-hook-bypass.js` tokenizes with quote awareness and inspects each simple command's argv, which makes the false positive structurally impossible rather than patched around, and it catches the `core.hooksPath` evasion the original never saw.

**The tracking gap.** This session merged a PR and changed the live hook configuration, then ended without the session-end checklist. Every tracker file's last commit stayed at `4621b1b` while `main` moved to `314b98f`, so the next session's `/restart-sop` opened on a resume that still said "nothing is pushed yet" about a branch that had merged the day before, and on an In-Flight line whose own instruction to clear itself was never executed. Nothing was lost — git held the code and the hook change was on disk — but the trackers disagreed with reality for eight days, and the two stale next-actions in the resume were both already done. The drift was caught by `/restart-sop` Step 4, which is what that step is for.
