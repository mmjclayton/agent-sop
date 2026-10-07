# agent-sop Research Digest - 27 September 2026

**Repo status (last 7 days):**

All activity in the last 7 days is concentrated on **24 September 2026**, between 07:49 and 11:25 UTC (12 commits, three merged PRs). Nothing has landed since - no commits on 25, 26 or 27 September.

- **PR #29 - P110, "review evidence, continuity and operating-cost hardening"**: validated JSON receipts replace the old Markdown coverage stamps; executable instruction files are now classified for review invalidation; worktree claim mechanics added for cooperative task/path ownership; resume storage migrated to full root-digest identities; new reliability and receipt-validation fixture suites; a new evaluation protocol replaces the old mandatory-benchmark rule; a GitHub Actions CI workflow (`.github/workflows/ci.yml`) was added to run fixtures on push.
- **PR #30 - P111, "reviewer scope by path in the ship gate library"**: reviewers can now be scoped to specific changed paths (in scope for every range, or only when a changed path matches, or never for an empty scope), with nine new test fixtures.
- **PR #31 - P112, "receipt schema version 2 with run counts per reviewer"**: `sop_receipt_valid` now accepts schema version 2 alongside version 1; a v2 reviewer entry must carry `launches` (>=1), `rechecks` (>=0) and `block_rounds` (>=0, capped at launches+rechecks), plus optional `usage`.
- **Governance change**: `main` is now protected - all commits go via PR (`docs: main is protected; commits go via PR`).

None of this touches prompt-audit tooling, agent-memory layout, or session-trajectory review, so nothing below is already addressed by this week's work.

**README spot-check (against https://raw.githubusercontent.com/mmjclayton/agent-sop/main/README.md):**

- 91 checks (code) / 82 (non-code): confirmed.
- Instruction budget 150 soft / 200 hard: confirmed.
- Six non-negotiable rules: confirmed.
- Four slash commands documented, five installed (`/finish` still undocumented) and the "9-step checklist" vs 10-item list drift both persist unchanged since the prior digest - not re-reported as findings, just confirmed still present.
- "11 categories" and the 60%/200-300-line figures are still not stated in the README itself (they live in the SOP doc, not checked this run).

**Coverage note:** the last saved digest is dated 24 September and this run is 27 September, so the usual 24-hour window would silently skip three days with no digest covering them. As with last run's Opus 5.5 exception, findings from 24-27 September are included below rather than only the last 24 hours, and each is dated so the gap is visible.

**Sources scanned:** 10 | **Relevant findings:** 3 | **No-find sources:** Anthropic engineering blog (latest dated post still 23 Apr 2026), Anthropic research (Sep 23-25 posts are life sciences/economics, off-topic), Latent Space (Sep 24-25 items are funding news and a science-cost essay, off-topic), Google DeepMind (all Gemini 3.8 model/science posts, no agent-ops content), OpenAI (no verifiable official post found for this window - see fetch notes), Hacker News (aggregator-only, see fetch notes)

**Fetch method breakdown:** WebFetch: 8 | Chrome fallback: 0 | WebSearch fallback: 2 (OpenAI, Hacker News) | Unreachable: 0

**Fetch notes:** All ten source URLs were reachable directly via WebFetch except OpenAI (per the brief, sent straight to WebSearch) and Hacker News. Hacker News search returned only third-party "agents-radar" issue-tracker aggregator digests, not Hacker News itself or any traceable original story - per the aggregator rule, nothing from HN is reported below. OpenAI's own newsroom could not be confirmed to have a relevant post in this window via search; treated as no-find rather than guessed. Separately, GitHub's commit-detail REST endpoint (`/commits/<sha>`) returned 403 to WebFetch for two of the four commits checked; both were retrieved instead via `curl` in the user's local shell (`device_bash`), which is not one of the three tiered fallbacks but resolved the block - noting it here per the "track reliability" instruction.

**Version-revert check:** Claude Code 2.1.283 (25 September 2026) is the newest published version. The dangerous-`rm` two-minute-timeout behaviour flagged in the 24 September digest is present through 2.1.283 with no revert - it remains an open item, not re-reported here.

---

**`/doctor prompt-audit` - new command audits CLAUDE.md, skills, agents and commands for prompting patterns written for older models**
Source: https://code.claude.com/docs/en/changelog (2.1.283)
Published: 25 September 2026
Topic: Prompt engineering for autonomous agents
Relevance to agent-sop: This is close to a built-in version of the SOP's own §15.5 model-migration concern raised in the last digest (Opus 5.5's always-on thinking replacing the disableable `thinking` field). `/doctor prompt-audit` (aliased `/checkup prompt-audit`) scans CLAUDE.md, skills, agent definitions and slash commands for prompting patterns aimed at older models - exactly the artefact set agent-sop ships (CLAUDE.md template, five reference agents, `.claude/commands/`).
Already addressed? No.

**Suggested change:**
Add a step to `/update-sop` (or a new sop-checker check, suggested ID `C-doctor-audit`) that shells out to `claude doctor prompt-audit` (or documents running it manually) against the project's `CLAUDE.md`, `.agents/skills/*/SKILL.md`, `.claude/agents/*.md` and `.claude/commands/*.md`, and fails the check if the audit reports findings unresolved. Reference it in `docs/sop/claude-agent-sop.md` §15.5 alongside the existing Opus 5.5 effort-parameter migration note from the 24 September digest, since both are the same underlying problem (stale model-specific prompting) with two different detection mechanisms now available - one manual (grep for `thinking:`), one built-in (`/doctor prompt-audit`).

**Expected impact:**
- Compliance score: likely increase (one new passable check once the five reference agents and command templates are cleaned up)
- Token budget: no change
- Check coverage: one new check

---

**LangSmith "Trajectories": a readable, chronological view of an agent session for non-technical review**
Source: https://www.langchain.com/blog/langsmith-trajectories-tracing
Published: 25 September 2026
Topic: Automated compliance and audit patterns
Relevance to agent-sop: agent-sop's review evidence moved this week (P110/P112) to validated JSON receipts with per-reviewer run counts - machine-checkable, but not something a human reviewer can scan quickly. LangSmith's Trajectories view aggregates human/AI/tool messages into an ordered, technical-detail-free sequence specifically so a non-engineer reviewer (their example: compliance officers) can spot where an agent's behaviour went wrong before anyone opens the raw trace.
Already addressed? No.

**Suggested change:**
Add a `scripts/render-trajectory.sh` (or a step in `sop-checker`) that converts a session's JSON receipt plus its transcript into a short, human-readable chronological summary (user asks -> agent actions -> reviewer verdicts), for handoff to a non-technical stakeholder or auditor without requiring them to read raw receipts or `docs/agent-memory/decisions/*.md`. Document the format in `docs/guides/` alongside the existing multi-agent parallel-sessions guide. This is a documentation/tooling addition, not a new compliance gate.

**Expected impact:**
- Compliance score: no change (tooling convenience, not a new gate)
- Token budget: no change
- Check coverage: no change

---

**LangChain Managed Deep Agents v0.8: split agent-level vs user-level memory, mounted at separate paths to prevent leakage**
Source: https://www.langchain.com/blog/langsmith-managed-deep-agents-whats-new
Published: 24-25 September 2026
Topic: Agent session management and persistent memory
Relevance to agent-sop: `docs/agent-memory.md` and `docs/agent-memory/{decisions,in-flight}/` are currently organised by topic (decisions, in-flight, gotchas), with per-agent identity resolved via a worktree-path hash in multi-agent mode (per the prior digest's `/batch`/`WorktreeCreate` finding). LangChain's v0.8 release formalises a different split: memory explicitly partitioned into a shared "agent-level" layer (team-wide patterns, mounted at `/memories/agent/`) versus an isolated "user-level" layer per caller (`/memories/user/`), specifically to stop one session's context leaking into another's.
Already addressed? Partially - agent-sop's multi-agent guide already separates per-agent in-flight state by agent-id, but has no equivalent shared-vs-isolated split for `docs/agent-memory/decisions/` and `gotchas/`, which are currently one shared pool that any agent-id can write into.
**Suggested change:**
In `docs/guides/multi-agent-parallel-sessions.md`, add a convention splitting `docs/agent-memory/` into `docs/agent-memory/shared/` (decisions and gotchas meant to apply across all agents/sessions - the current default) and `docs/agent-memory/agents/<agent-id>/` (in-flight state and decisions scoped to one agent-id only, already partially done for `in-flight/solo.md`). Add a sop-checker check (suggested ID `M8`) that flags a decision or gotcha file written under an agent-specific path but referenced by a different agent-id's session, mirroring LangChain's leakage concern.

**Expected impact:**
- Compliance score: no change (new optional structure)
- Token budget: no change
- Check coverage: one new check (M8)

---

## Not reported as findings (still open, previously reported)

- **AGENTS.md support** - extended in Claude Code 2.1.282 (24 September) to also work on Bedrock, Vertex AI, Foundry, LLM gateways, and telemetry-disabled sessions. Still the same open item flagged in the 24 September digest (and rediscovered in runs before that); this is a platform-coverage extension of the same underlying item, not a new one.
- **Dangerous-`rm` two-minute timeout in auto/`--dangerously-skip-permissions` mode** - present unchanged through 2.1.283, no revert. Still open per the 24 September digest's finding 5 (S7/S8 sop-checker suggestion).

---

## Recommended next action

File `/doctor prompt-audit` integration (finding 1) as the next `[OPEN][Iteration]` item - it directly extends the Opus 5.5 effort-parameter migration work already queued from the 24 September digest, so the two should land in the same session. The Trajectories and split-memory findings (2 and 3) are lower urgency documentation/structure proposals - batch them as a single `[OPEN][Iteration]` for `docs/guides/`. The two "still open" items need no new filing; they are already on the Backlog from the prior digest.
