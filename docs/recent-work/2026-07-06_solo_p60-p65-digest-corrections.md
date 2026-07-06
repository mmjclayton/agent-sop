# P60-P63 + P65 — Digest-review corrections batch

**Date:** 2026-07-06
**Agent:** solo
**Commits:** 9d5d36f, 8ac905a, ed7f495, 492ede9, b70d842, c8b19ed (branch `feat/p60-p65-digest-corrections`)

Two-month digest review (6 Jul automated + manual re-run + five backlogged digests; ~29 distinct findings) filtered through the 2026-04-13 remove-or-sharpen decision. Five items shipped, one decision-blocked (P64 AGENTS.md), seven suggestions skipped with recorded reasons.

Shipped: P60 tokenizer-relative token figures + `/usage` measurement + external citations; P61 memory-poisoning guard (security.md rule 1 + restart-sop Step 4 + S4); P62 background-subagent pre-flight check (`[Bug]`, CC 2.1.198) + M6; P63 CI hardening (rule 10 + deny-rule examples + S5/S6, CVE-2025-66032); P65 corrections (`/simplify` note, README counts 82/91, config + 6 baselines). Check totals 78/87 → 82/91. User-scope mirrors updated in lockstep.

Cross-project: ship-sop composition pass filed P12 (background gate semantics) + P13 (`.ship/.pending-auto-fire.md` as injection surface) via ship-sop PR #3.

Digest-job fixes for the owner (Claude Cowork prompt, outside this repo): index the repo via GitHub MCP (4 of 6 runs failed on JS-rendered pages); update rotted source URLs (docs.anthropic.com → platform.claude.com/docs/en/release-notes/overview; blog.langchain.dev → langchain.com/blog); diff findings against prior digests in the Claude Config folder before reporting.
