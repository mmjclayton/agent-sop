# agent-sop Research Digest - 4 October 2026

**Repo status (last 7 days):**

All activity is on 30 September 2026 (11 commits, three merged PRs #33, #34, #35). Nothing since. Indexed via the GitHub REST API (curl in the local shell, because WebFetch returned 403 on the commits endpoint).

- **P113 - memory index size check hook** (22e76e0, fixes 783cfe7): new `scripts/hooks/sop-memory-index.sh`, a PostToolUse(Write|Edit|MultiEdit) hook that warns when a harness MEMORY.md reaches 80 per cent of the 200-line / 25,000-byte load limit. Registered by `scripts/install-hooks.sh`, required by `sop-doctor.sh`, documented in `docs/sop/harness-configuration.md`, ten further fixture cases.
- **P114** (4e99b7f): SOP project state stays out of harness memory (`update-sop` skill/command and `docs/sop/claude-agent-sop.md` touched).
- Housekeeping and ship-gate receipt commits (P113/P114 close-out, Backlog.md, `docs/agent-memory/in-flight/solo.md`).

**README spot-check (raw.githubusercontent.com):** the README no longer states "91 / 82 checks", "11 categories" or "instruction budget" figures (grep found none; the 27 September digest recorded them as confirmed). Either the README was reworded or those counts now live only in the SOP doc. Unverified which; check before relying on the counts in the scanner brief.

**Sources scanned:** 10 | **Relevant findings:** 4 | **No-find sources:** Anthropic engineering (newest dated post 23 Apr 2026; "How we contain Claude" is from May), Anthropic research (1 Oct "Claude-shaped science", 30 Sep robots, 29 Sep GLM-5.3 cyber capabilities: off-topic for SOP), Latent Space (1-3 Oct: model news, AINews roundups, Airbnb interview), Google DeepMind (page returned titles without dates, nothing verifiable), OpenAI and Hacker News (see notes)
**Fetch method breakdown:** WebFetch: 8 | Chrome fallback: 0 | WebSearch fallback: 2 (OpenAI, Hacker News) | Unreachable: 0

**Fetch notes:** HN search returned only third-party agents-radar aggregator issues; nothing from HN is reported as a finding. OpenAI DevDay (2 Oct) was read via an InfoQ recap fetched after WebSearch; no item in it maps to an SOP change beyond what is noted under "Not reported". Simon Willison's post URL was found by search (its first guessed URL 404'd); content below comes from the site's index summary, not the full post.

**Version-revert check:** newest Claude Code is 2.1.289 (3 Oct). Items below were checked against 2.1.286 to 2.1.289 and none is reverted. No finding is rated Critical.

---

**`/code-review --max-findings <n>|all` (Claude Code 2.1.288)**
Source: https://code.claude.com/docs/en/changelog
Published: 2 October 2026
Topic: AI code review and security review automation
Relevance to agent-sop: the ship gate and receipt schema v2 (P110-P112) record per-reviewer launches, rechecks and block rounds, but the built-in `/code-review` can now cap or uncap findings per run. A capped run could silently truncate findings that a receipt then records as a clean pass.
Already addressed? No.

**Suggested change:**
In `docs/sop/claude-agent-sop.md` (ship-gate / code review section) and the code-reviewer agent template, state that review runs feeding a receipt must use `--max-findings all` (or record the cap used). Add a receipt-validation fixture in `docs/benchmark/` where a reviewer entry declares a finding cap and the validator requires `cap: all` or an explicit `findings_truncated: false`.

**Expected impact:**
- Compliance score: no change
- Token budget: no change
- Check coverage: new check (receipt must not come from a truncated review)

---

**Claude Code 2.1.286-2.1.288: duplicate CLAUDE.md loads fixed, `/context` now counts MCP server instructions**
Source: https://code.claude.com/docs/en/changelog
Published: 30 September to 2 October 2026
Topic: Context window and token optimisation
Relevance to agent-sop: the less-than-6K session-start target and the 200/300-line CLAUDE.md caps were being measured against a runtime that loaded folder CLAUDE.md twice (after resume/compaction, and in worktree-isolated subagents) and under-reported MCP instructions in `/context`. Prior measurements of session-start cost on resumed or worktree sessions may be inflated, and MCP overhead understated.
Already addressed? No.

**Suggested change:**
Add a note to `docs/sop/claude-agent-sop.md` §15.5 (token equivalences) that session-start baselines must be taken on Claude Code 2.1.288 or later, and that the baseline procedure should include MCP server instructions. Re-run the session-start token measurement on a worktree session and a resumed session and update any recorded figures in `docs/benchmark/`.

**Expected impact:**
- Compliance score: no change
- Token budget: no change to design, possible correction of recorded figures
- Check coverage: no change

---

**Claude Sonnet 5.5 (28 September): `thinking: disabled` replaced by `between_tools`; forced tool use returns 400**
Source: https://platform.claude.com/docs/en/release-notes/overview
Published: 28 September 2026
Topic: Anthropic API and model changelog
Relevance to agent-sop: extends the Opus 5.5 migration item from the 24 September digest (still open). Same breaking-change family, now on Sonnet 5.5, plus Sonnet 4.5 retirement on 30 November 2026. Any agent template or script in agent-sop that sets `thinking: disabled` or `tool_choice` `any`/`tool` will 400.
Already addressed? Partially - the Opus 5.5 item is queued but not shipped; this adds Sonnet 5.5 and a retirement date. Not a fresh finding.

**Suggested change:**
Fold into the existing Opus 5.5 `[OPEN][Iteration]`: extend the grep-based check from `thinking:` to also flag `"disabled"` and `tool_choice` in `.claude/agents/*.md`, `scripts/` and `docs/benchmark/`, and add `claude-sonnet-4-5-20250929` (retires 30 November) to the stale-model-ID check.

**Expected impact:**
- Compliance score: likely increase when combined with the Opus 5.5 item
- Token budget: no change
- Check coverage: extends one planned check

---

**"We're going to need default hard budget caps on pretty much everything" (Simon Willison)**
Source: https://simonwillison.net/2026/Oct/3/default-hard-budget-caps/
Published: 3 October 2026
Topic: Multi-agent orchestration and delegation
Relevance to agent-sop: argues that services need hard spending cut-offs rather than soft alerts because coding agents can run up large bills unattended. agent-sop has parallel-session and autonomous-run guidance but no spend or runaway-cost control in the session checklist. Detail taken from the site index summary only; read the full post before acting.
Already addressed? No.

**Suggested change:**
Add a "cost guard" item to the autonomous/parallel-session section of `docs/guides/multi-agent-parallel-sessions.md`: before an unattended or multi-agent run, record a max spend or turn limit and the kill condition in `docs/agent-memory/in-flight/<agent-id>.md`. Optionally add a sop-checker check that an in-flight file for a parallel session contains a `budget:` line.

**Expected impact:**
- Compliance score: no change (optional check)
- Token budget: no change
- Check coverage: one optional new check

---

## Not reported as findings

- **Claude Mods, `agent.spawn`, single agent id across plugin hook events (2.1.287, 2.1.289):** platform feature, relevant to the multi-agent identity scheme (worktree-path hash) but no SOP change needed until the owner decides to adopt mods. Watch item only.
- **Dangerous `rm` safeguards lost with output redirection (fixed 2.1.288):** a different bug from the two-minute-timeout item from the 24 September digest. That item (S7/S8) is still open; no changelog entry shows the timeout behaviour changed.
- **AGENTS.md support:** still open per the 24 September digest; nothing new this run.
- **LangSmith Trajectories and Managed Deep Agents v0.8 memory split:** already reported 27 September, still open.
- **OpenAI DevDay (2 Oct): Agents API with context compaction, `/agents` delegation in Codex CLI, code-review workflow, Codex Security Cloud:** product announcements via secondary coverage only, no new pattern for the SOP.
- **LangChain "How to Build a Model Router in the Harness" (1 Oct), LangSmith Engine v2 red teaming (24-25 Sep):** not read in full, titles only; no SOP mapping identified.

---

## Recommended next action

File finding 1 (`--max-findings` in receipts) as an `[OPEN][Iteration]` for the ship gate library, and merge the Sonnet 5.5 addendum into the existing Opus 5.5 item so both land in one session. Re-measure session-start tokens on 2.1.288+ (finding 2) before the next change to the CLAUDE.md caps. Confirm whether the README intentionally dropped the 91/82 check counts.
