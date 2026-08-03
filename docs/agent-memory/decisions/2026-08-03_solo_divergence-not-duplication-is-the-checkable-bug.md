# The checkable bug is two implementations that disagree, not two statements that agree

**Date:** 2026-08-03
**Agent:** solo

We chose to scope P78 on **divergence** rather than **duplication**, because check C15 mandates the restatement a duplication check would have flagged.

The 2026-07-30 digest reported that Anthropic and LangChain independently measured instruction repetition as pure token waste, and proposed a compliance check flagging the same directive in more than one instruction surface. That framing survives about ten minutes of contact with this repo. `docs/sop/compliance-checklist.md:93` (C15) **requires** every project to restate "never delete without a trace" in its CLAUDE.md, and the rule is deliberately repeated across more than twenty sites including both shipped templates. A duplication check would fail projects for complying with C15. Two checks in the same file would have contradicted each other.

The real defect the repo keeps hitting is narrower and has shipped as a bug four times: P66 (prose said skip, the validator blocked), P70 (two runtimes disagreed and the softer one executed), P73 (a single-site fix on a repeated pattern), and the user-scope Step 3e leak. In every case one logical rule had two implementations and they diverged. Restating a rule in two documents that agree costs tokens; implementing it twice in ways that disagree causes incidents.

The distinction also decides the implementation. A duplication check greps for matching text, which is why check T1 once failed the reference implementation by matching the paragraph that *quoted* the banned wording — it could not tell a rule from a citation of a rule. A divergence check has to compare behaviour across siblings, which is what `docs/guides/cross-layer-rules.md` Tier 0 already prescribes manually and what the 2026-07-26 gotcha states as a design constraint: grep the distinctive dependency, not the step number.

Recorded because the wrong version is the intuitive one, and the digest will likely propose it again.
