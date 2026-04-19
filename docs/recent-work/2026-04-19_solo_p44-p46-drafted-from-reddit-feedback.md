# P44/P45/P46 drafted from Reddit state-drift feedback

**Date:** 2026-04-19
**Agent:** solo
**Commits:** [pending — this session's commit]

Drafted three Backlog entries in response to external Reddit feedback (2026-04-19) arguing markdown SOPs fail to enforcement and need machine-checkable workflow with required reviewer turns. Assessment separated real gaps from overreach; user approved plan after action-vs-ceremony challenge led to reframing P46 and bolting a substance assertion onto P44.

**Shipped this session:**
- `Backlog.md` — new entries P44 (reviewer turn with substance assertion), P45 (state-transition validator), P46 (actionable drift detection). Ship order P45 → P44 → P46 locked in based on action-per-text ratio.
- `CLAUDE.md` — Current Priority Items reshuffled: P43 (shipped) removed, P44-P46 added as the next three items.
- `docs/agent-memory/decisions/2026-04-19_solo_action-vs-ceremony-test-for-sop-additions.md` — reusable test for future SOP additions: produces non-zero exit? catches real failure mode? resists stub-gaming?
- `docs/agent-memory/decisions/2026-04-19_solo_p44-p46-reddit-feedback-ship-order.md` — planning outcome, interpretation chosen, explicit rejections.

**No code / script changes yet.** Implementation deferred to future sessions per the three-phase plan in the decision file.

**Instruction budget projection:** +6-9 core SOP instructions across the three items → ~187-190 post-ship (within 200 hard ceiling). Section 1 / Section 8 trims available if drift becomes a binding concern.
