# P86-P94 — Template rot root cause, and the fixes it generated

**Date:** 2026-08-03
**Agent:** solo
**Commits:** `1590af8`, `52aa6bd`, `c129c2a`, `7138852`

A handoff review identified agent-sop as the upstream cause of defects appearing in every downstream project: the SOP mandated line-range hints and shipped a worked example that was wrong in the repo it came from. Verified before acting, and the sweep found nine sites rather than the six handed over — including C24, a compliance check that scored projects on *having* the rot pattern (P91).

Also shipped: derived Current Priority Items via sentinel+regenerate rather than the proposed pointer, which would have removed the benefit along with the drift (P92); templates now ship the split rollup layout (P93); user-scope and `paths:` load-gate guidance, the advisory half of the Rule 5 split (P94); `setup.sh --force` no longer overwrites per-project files (P86); and Definition of Done reconciled to the templates after my own recommendation to delete it proved wrong on inspection (P88). Batch 0.32.
