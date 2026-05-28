# P24 — Multi-agent optimisation guide

**Date:** 2026-05-04
**Agent:** solo

New canonical entry-point doc at `docs/sop/multi-agent.md` covering: (1) the two patterns (parallel sessions vs coordinator+specialist) with a comparison table, (2) a decision tree for when parallel mode actually pays off vs solo, (3) a mechanics summary that points to the deep guides without duplicating them, (4) optimisation rules of thumb (token budgets across coordinator/specialist, worktree count thresholds, P54 perf-gate parallel-batch + skip-predicate guidance), (5) Common Mistakes for multi-agent (sibling-worktree wipe, P-collision masquerade, two-Claude-one-worktree, hand-edits to rollup, gateway-routed parallel sessions), (6) compliance checks reference, (7) cross-reference table to all related files.

Per Rule 2, no content was duplicated from `multi-agent-parallel-sessions.md`, `multi-agent-context-routing.md`, or `managed-agents-integration.md`. Section 0 multi-agent paragraphs (lines 83-89, ~7 lines) consolidated into a single 1-line pointer to the new entry point. Section 16 renamed from "Multi-Agent Context Routing" to "Multi-Agent" and reduced to 1 paragraph pointing at the new entry point + the two deep guides.

Both templates (base + code) gained a Key Documents row pointing at `docs/sop/multi-agent.md` with the deep-mechanics guide called out parenthetically. CLAUDE.md (agent-sop's own) gained the same row in its Key Documents & Dispatch table.

Compliance acceptance criterion ("Compliance checklist updated with multi-agent checks") was already satisfied by P43's M1-M5 in checklist Section 11. The new guide cross-references those checks explicitly so the wiring is now visible from the entry point.

Tracking: Backlog (P24 marked SHIPPED + Shipped Archive line), feature-map.md (P24 row + last-updated bump), CLAUDE.md Current Priority Items (P24 removed, P55 added), CLAUDE.md rollup, agent-memory.md Completed Work, this resume snapshot.
