# Two-month digest review: remove-or-sharpen filter applied, 6 filed / 7 skipped

**Date:** 2026-07-06
**Agent:** solo

Reviewed the 6 July automated digest plus a manual re-run plus the five backlogged digests (11 May - 29 June): ~41 findings, ~29 distinct after dedup. Applied the 2026-04-13 decision (default to "what does this remove or sharpen", not "what could we add") before filing. Result: P60-P65 filed (two are corrections, one is a `[Bug]` against a runtime change, two are evidence-backed security extensions, one is decision-blocked); seven suggestions skipped with reasons recorded in the P60 Backlog entry.

Three verification lessons for future digest reviews:

1. **Verify digest claims against the changelog before accepting severity.** The 25 May digest rated the `/simplify` removal (2.1.147) Critical; the removal was reverted in 2.1.152 (`/simplify` → `/code-review --fix` alias). One WebFetch of the changelog collapsed it to a one-line note. Similarly "Dreaming" (8 June digest) does not exist in the changelog at all — likely releasebot noise.
2. **Automated runs with broken repo indexing produce unreliable "already addressed?" flags.** Four of six runs could not index the repo (private + JS-rendered pages) and re-discovered the same findings across runs (AGENTS.md, Comment-and-Control, `/usage` each surfaced twice). Fix is in the cron prompt, not the repo: GitHub MCP for commits, updated source URLs (docs.anthropic.com → platform.claude.com/docs/en/release-notes/overview; blog.langchain.dev → langchain.com/blog), diff against prior digests in the Claude Config folder.
3. **The digest missed the highest-impact finding** (Sonnet 5 tokenizer +30%, default model from 1 July) because its Anthropic-docs source URL had rotted. Source-list maintenance is part of digest hygiene.

Companion ship-sop items filed in the same pass (P12 background-gate semantics, P13 directive-file injection — ship-sop PR #3) because the composition review showed two of the agent-sop findings change documented ship-sop behaviour.
