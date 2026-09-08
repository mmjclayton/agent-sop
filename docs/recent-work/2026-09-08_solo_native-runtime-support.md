# Native Codex runtime support

**Date:** 2026-09-08
**Agent:** solo (Codex)
**Commits:** implementation and review fixes on feat/codex-support

P107: added native Codex skills, isolated reviewers and runtime-aware setup.
Both public READMEs now describe the actual installation and daily workflows.
Claude support, shared project data and customized user assets are preserved.

Live feedback confirmed project-root hook payloads, exec_command translation to
Bash/command, and production Stop continuation with the expected tracker notice.
SessionStart, UserPromptSubmit and Stop delivery were also observed in a disposable
runtime. The raw exec_command fixture did not demonstrate a translation bug.

Review fixes use trusted installed reviewer policy, check asset discovery failures,
preserve shared uninstall data and harden priority refresh. Regression suites pass.
P107 and P109: final configured review and branch publication are recorded in Backlog.md. The work
remains IN PROGRESS pending merge; no release or merge is part of this session.

The pre-port validator also passed the final Backlog transitions. Its original
29 state fixtures passed unchanged. Remaining compatibility findings are tracked
in agent-sop P108 and ship-sop P29; they are not represented as fixed.

Replication parsing now uses jq: the old validator skipped the new stale-asset
fixture, while the corrected validator blocks it. Native replication checks
passed on the real checkouts after synchronization.

Final configured gate: [20260908-153509-ship-auto.md](../reviews/20260908-153509-ship-auto.md). No unresolved blocking
findings. Prepared for branch push and PR review; merge and release remain separate.
