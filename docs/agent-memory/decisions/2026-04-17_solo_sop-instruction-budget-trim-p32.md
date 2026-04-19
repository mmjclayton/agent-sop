# SOP instruction-budget trim (P32)

**Date:** 2026-04-17
**Agent:** solo

SOP instruction-budget trim (P32). Pre-trim: 392 instructions across 5 SOP files; `claude-agent-sop.md` alone was ~230, breaching its own Rule 5. Post-trim: core SOP ~193, total ~343. Under the 200 hard ceiling, still ~43 over the 150 soft cap. Cuts: Quick Reference Card (100% duplicate), Section 17 Managed Agents extracted to `docs/guides/` as P33 (deferred), Sections 12/16/18 extracted to guides, `hooks.md` + `context-management.md` merged into `harness-configuration.md`, `security.md` collapsed with container/network content split to `sandboxing.md`. Compliance-checklist left intact because sop-checker agent references check IDs — parametrising would break tooling. Archive at `.archive/sop-pre-trim-2026-04-17/` (gitignored). Candidate follow-up cuts (to reach 150): Section 14 mistakes table to guide, Section 15.4 benchmark safety to managed-agents guide, Section 1 compression, Section 8 tag taxonomy consolidation.
