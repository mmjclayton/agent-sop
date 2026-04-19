# P37 — Reviewed thedotmack/claude-mem

**Date:** 2026-04-17
**Agent:** solo

P37 — Reviewed thedotmack/claude-mem. 60.8k-star Claude Code plugin, substantive (daemon + SQLite + ChromaDB + MCP server + 5 lifecycle hooks + React UI). Categorically different from Agent SOP: claude-mem is observation/retrieval infrastructure, Agent SOP is prescription. Three portable patterns adopted: (1) progressive retrieval (index → narrow → fetch) as routing rule in multi-agent guide, (2) capture-time redaction via `<private>` tags in security.md (leaked-store threat model vs retrieval-time filtering), (3) hooks-must-fail-open in harness-configuration.md. Rejected: DB-backed memory, auto-capture, MCP server dependency — would compromise plain-markdown philosophy. Positioned claude-mem as optional complement (not competitor) in optional-patterns.md. Red flag: claude-mem cites "10x token savings" marketing, no A/B benchmark — Agent SOP's P23 benchmark (+33%) is stronger evidence. Bus-factor risk (single maintainer Alex Newman).
