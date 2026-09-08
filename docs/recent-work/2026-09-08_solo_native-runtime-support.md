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
Final configured review and branch publication are recorded in Backlog.md. The work
remains IN PROGRESS pending merge; no release or merge is part of this session.
