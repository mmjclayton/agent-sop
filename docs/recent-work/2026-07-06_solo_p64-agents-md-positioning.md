# P64 — AGENTS.md positioning

**Date:** 2026-07-06
**Agent:** solo
**Commits:** (see PR #8)

Decision session with Matt resolved P64's open questions one by one: consumer projects are Claude-only today but multi-tool is likely soon; scope is positioning only; recommended shape is AGENTS.md-canonical (shared context in AGENTS.md, CLAUDE.md reduced to `@AGENTS.md` import plus Claude-specific surface — Rule 2, never parallel copies); full support (template + `setup.sh --multi-tool` + Recommended check) is deferred until Claude Code reads AGENTS.md natively.

Shipped: README "vs AGENTS.md (the cross-tool standard)" subsection in the comparisons section, with the canonical-shape recommendation, an example CLAUDE.md import stub, and the deferred-tooling note pointing back at P64. Backlog entry records all four decisions and the reopen trigger so future sessions don't re-litigate.
