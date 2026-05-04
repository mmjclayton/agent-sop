# P56 — Backend assumptions: gateway / non-Anthropic backend warning

**Date:** 2026-05-04
**Agent:** solo
**Source:** `agent-sop-research-digest-2026-05-04.md` (Finding 2)

Documented that the SOP body, compliance scoring, and reviewer-substance gates were authored against Anthropic-hosted Claude (Opus / Sonnet 4.x). New `claude-agent-sop.md` §15.5 (Backend Assumptions) names the authoring substrate, lists which gates degrade on swapped backends (reviewer-substance, voice rules, drift detection), and notes that structural checks remain model-agnostic. Explicitly avoids any token-budget claim — the digest's 5,200-5,900 figure is unmeasured.

`/restart-sop` gains Step 0e: a soft advisory that prints when `ANTHROPIC_BASE_URL` is set to a non-`*.anthropic.com` value, pointing at §15.5. Does not block. Dogfooded across three cases (unset / anthropic gateway / openrouter) — silent on the first two, advisory fires on the third. User-scope `~/.claude/commands/restart-sop.md` mirrored; baseline SHA refreshed in `~/.claude/agent-sop.config.json` (`7ea818f6` → `049ade5c`).

Trigger: 1 May 2026 Claude Code changelog formalising gateway support (`/model picker now lists models from gateway's /v1/models endpoint`) plus DeepClaude (3 May 2026 HN front page) routing through cheaper backends — swapped-backend usage is now a first-class scenario.

P55 (sycophantic reviewer detection, same digest) filed `[OPEN]` for a future session.
