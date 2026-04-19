# P32-P39 — Trim, sync mechanism, two repo reviews, R5 pilot, measurement gap (Batch 0.13, commits 3e452b7, 2350a9f, 0632aad, 8977f46, ee1b012, 988ab69, ca3d57b)

**Date:** 2026-04-17
**Agent:** solo
**Commits:** (migrated)

Eight P-items in one session. Core SOP trim (~230 → ~195 instructions; Section 4 removed; Sections 12/16/17/18 to guides; hooks.md + context-management.md merged into harness-configuration.md; security.md collapsed). Section 0 expanded to six non-negotiable rules with *Prevents:* annotations. `/update-agent-sop` sync command shipped (three-way diff, never force-overwrites). Reviewed forrestchang/andrej-karpathy-skills (trace-to-request ported) and thedotmack/claude-mem (progressive retrieval, capture-time redaction, fail-open hooks ported). R5 post-trim benchmark pilot: SOP +16% aggregate (vs R2's +33%); README badge changed to "directional +16% to +33%". Measurement gap closed: session-hygiene rubric, continuity methodology, longitudinal exhibit (hst-tracker: 86 decisions, 23 batches, 64 docs commits). Full per-item detail in agent-memory.md Decisions.
