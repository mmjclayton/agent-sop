# Phase 0 — Foundation

Status: In Progress

---

## Problem

The Agent SOP exists as loose documents in an outputs folder. It needs a proper home — a structured project that itself follows the SOP, can be shared publicly, and extended with templates and examples.

---

## Scope

| Batch | What | Priority |
|-------|------|----------|
| 0.1 | Project scaffold (all standard files) | P0 |
| 0.2 | Publish core SOP document (P1) | P0 |
| 0.3 | Publish CLAUDE.md template (P2) | P0 |
| 0.4 | Publish remaining templates: agent-memory, Backlog, build-plan (P3-P5) | P1 |
| 0.5 | Publish example guides: new project walkthrough, migration guide (P6-P7) | P1 |

---

## Architecture

Pure markdown library. No code, no build process. Structure:

```
agent-sop/
  CLAUDE.md
  Backlog.md
  README.md
  docs/
    agent-memory.md
    feature-map.md
    sop/
      claude-agent-sop.md
      variants/         (P8-P10, future)
    templates/
      claude-md-template.md
      agent-memory-template.md
      backlog-template.md
      build-plan-template.md
    examples/
      new-project-walkthrough.md
      existing-project-migration.md
    build-plans/
      phase-0-foundation.md
```

---

## Key Decisions Locked In

- [LOCKED] Markdown only — no build tools, no dependencies.
- [LOCKED] Project follows its own SOP — additive-only writes, session checklists, all standard files.
- [LOCKED] Templates in `docs/templates/`. SOPs in `docs/sop/`. Examples in `docs/examples/`.
- [LOCKED] P-numbers in Backlog.md are permanent document identifiers.

---

## Batch Log

*Append-only. Format: YYYY-MM-DD: Batch N.X — description.*

- 2026-04-07: Batch 0.1 — Project scaffold created. CLAUDE.md, Backlog.md, docs/agent-memory.md, docs/feature-map.md, docs/build-plans/phase-0-foundation.md, README.md.
- 2026-04-07: Batch 0.2 — P1 shipped. Core SOP published at docs/sop/claude-agent-sop.md.
- 2026-04-07: Batch 0.3 — P2 shipped. CLAUDE.md base template published at docs/templates/claude-md-template.md.
- 2026-04-07: Batch 0.3b — P11 shipped. CLAUDE.md code template published at docs/templates/claude-md-template-code.md.
- 2026-04-07: Batch 0.3c — 9 SOP improvements applied following independent analysis: Quick Reference Card, template split, [WON'T] format standard, project_resume.md naming lock, Key Documents sync rule, [VERIFIED] non-code definition, interrupted session recovery, Issue Tracker Sync Rules rename, phase boundary definition.
- 2026-04-07: Batch 0.3d — P12 shipped. SOP v2 owner feedback iteration: 10 changes applied. Reframed additive-only rule, delineated memory systems, added test gates, snapshot resume model, conflict precedence, schema protocol, backlog archive threshold, no-derived-facts rule, multi-agent code conflict nuance. All templates and tracking files updated.

---

## Deploy Checklist

Before marking Phase 0 shipped:
- [ ] All P1-P5 documents exist at their specified paths and are complete
- [ ] Backlog.md statuses updated for all shipped items
- [ ] feature-map.md updated with all shipped documents
- [ ] README.md accurate and up to date
- [ ] Initial GitHub repo created and pushed

---

## Open Questions

- 2026-04-07: Create GitHub repo before or after Phase 0 completes? [UNRESOLVED]
