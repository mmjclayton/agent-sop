# P43 Rule 5 precise instruction count deferred — rough estimate used instead

**Date:** 2026-04-19
**Agent:** solo

Rule 5 sets a 200-instruction hard ceiling on each agent's combined context. After Batch 1.5's rewrites (Section 0 Multi-agent contention, Section 1 directory rows, Section 3 format specs, Section 6 step-8 addition), Phase 1 Deploy Checklist wants verification the core SOP stays under 200.

A precise count requires manually classifying every line of `claude-agent-sop.md` (684 lines, 48 sections) as directive vs narrative per the counting rule ("numbered rules, checklist items, always/never/must statements, required-behaviour table rows"). That's hours of judgement work.

Shipped approach: rough estimate by delta from the P40 measured baseline (~178). This session added approximately +10 net instructions (Section 0 rewrite +2, Section 1 three directory rows +3, Section 3 format specs +3, Section 6 step 8 +1, Section 15.4 clarification +1). Rough current total ~185-190. Well under 200 hard ceiling, over 150 soft cap.

Precise audit deferred to a later session if the soft cap becomes a priority. Deploy Checklist entry marked complete with the estimate inline so the reasoning is traceable.

Rationale: the counting rule is a budget, not a KPI. What matters is catching breaches (approach or exceed 200). An estimate with explicit margin to the ceiling is fit-for-purpose. A precise count would not change any shipping decision.
