# Codex automatic runtime verification

Date: 2026-09-08. Runtime: Codex CLI 0.153.4.
Result: PASS — implementation → production Stop continuation → configured
reviews → covering report and records → successful push to a local Git remote.

## Setup

A fresh Codex session ran in a disposable code project with AGENTS.md, Backlog.md,
the required SOP document, the normal installed user hooks, and auto-mode enabled.
All three standard reviewers were enabled at their existing thresholds. The only
remote was a disposable local bare repository. Plugins, apps and computer/browser
tools were disabled for the test session; hooks remained enabled with saved trust.
No hook script was invoked manually, no synthetic hook payload was injected, and
no bypass flag was used. Installed hook scripts still match the merged source.

The task requested a greeting CLI change, meaningful tests and a commit, then an
immediate stop. It authorized following subsequent runtime hook instructions and
pushing to the local remote only after the configured reviews passed.

## Observed sequence

| Event | Evidence |
|---|---|
| Implementation committed | `1034b277e77dd2d488d028d983b7d5322019be73` |
| Initial completion attempted | Event 15: the agent reported the commit and explicitly stated no review or push had occurred. |
| Production Stop continued the session | Event 16: the agent responded to the Stop requirement and read the installed ship skill. No second user prompt was sent. |
| Production hook recorded an uncovered gate | The Stop marker names implementation commit `1034b277...`, an empty dirty-tracker digest, and `gate`. |
| Independent reviewers completed | code-reviewer, security-reviewer and silent-failure-hunter each returned exit 0 and PASS, with no findings. |
| Report and housekeeping committed | `da63849554c591c4e2a98846287ae8f378a1e51a`; report covers the implementation commit; subsequent changes are documentation only. |
| Push permitted and completed | Event 37: actual `git push` returned exit 0. The local remote branch resolves to `da63849554c591c4e2a98846287ae8f378a1e51a`, matching HEAD. |
| Session completed | Event 40 reported completion; CLI exited 0 and the worktree was clean. |

The implementation's 15 behavioral test cases, Bash syntax checks and whitespace
checks passed. Reviewers used the trusted user-installed runner and independent
read-only clones. The parent collected their real results before writing coverage.

## Scope and limitations

This proves the complete automatic positive path in the tested local Codex runtime.
It does not claim that an unrelated installation or external terminal is governed
by these hooks. Uncovered-push rejection is covered by the existing fixture suite;
this run tested the real permitted push after automatic review. Nothing from the
disposable test project was pushed to GitHub.

An initial fixture omitted `docs/sop/claude-agent-sop.md`; the hooks correctly
skipped that unmanaged project. The corrected fixture above completed the cycle.
Production source and hook configuration were not changed to make the test pass.

Raw runtime evidence was retained locally, outside the public repositories.
JSONL event stream SHA-256: `405fc6e362e2c1b982cd3d0d21f2f6a353bd8cf4ea95c2ba40a27ad10a83c84e`.
