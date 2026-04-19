# Action-vs-ceremony test for SOP additions

**Date:** 2026-04-19
**Agent:** solo

When evaluating any new SOP rule, command step, or process addition, apply this test before shipping: **what concrete thing happens differently that wouldn't happen today?** If the answer is "the agent reads more text" or "a warning prints," the addition is ceremony, not action — either reframe it as an enforceable gate or drop it.

The test surfaced during the P44/P45/P46 planning session (Reddit feedback on state drift). The initial P46 proposal was a PostToolUse hook printing status reassertions — sounds useful, but a print the agent can ignore is indistinguishable from not having the print. Reframed P46 as an actionable `/update-sop` commit-range check: compare commits in range against declared in-flight P-number, hard-block on mismatch. That's a gate, not a reminder.

Same test flagged a weakness in P44: "require a reviewer-turn findings file" becomes ceremony if the agent can write "LGTM" and pass. Bolted on a substance assertion — findings file must contain diff summary + severity + concrete finding — so the gate resists gaming.

**Applies to:** any future additions — new checklist steps, new compliance checks, new hook templates. Specific failure mode this prevents: accreting prescriptive text that agents read and skip, inflating the instruction budget without improving outcomes.

**Reusable criteria:**
1. Does this produce a non-zero exit (or other hard-block) when violated, rather than a warning?
2. Does it catch a failure mode that has actually happened, or is imaginable from known context-drift patterns?
3. Can the assertion be gamed with a stub / one-word satisfaction? If yes, bolt on a substance check or drop the rule.
