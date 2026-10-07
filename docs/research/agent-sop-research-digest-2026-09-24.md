# agent-sop Research Digest - 24 September 2026

**Repo status (last 7 days):**

No commits in the last 7 days. The most recent commit on `main` is dated **2026-08-07** (`docs: session end housekeeping - Batch 0.35 commit and PR references`). The last active window was 3-7 August 2026, covering P83-P96: the whole-codebase audit and remediation (P83-P85), `setup.sh --force` scoping (P86), the SOP self-modification execution arm (P87), Definition of Done reconciliation (P88, P93), line-range anchors (P91), Current Priority Items becoming a derived block (P92), review-path resolution in Step 3c (P95), and resume-path unification (P96, PRs #15/#16). Nothing in `docs/sop/` or `.claude/` has moved since. Every "Already addressed?" flag below is therefore assessed against the 7 August state.

**README spot-check (against https://raw.githubusercontent.com/mmjclayton/agent-sop/main/README.md):**

- 91 checks (code) / 82 (non-code): **confirmed**.
- Instruction budget ≤150 soft / 200 hard: **confirmed**.
- Six non-negotiable rules: **confirmed**.
- "11 categories": **not stated in the README**. The README describes "three-tier weighted scoring with a critical-failure cap" plus named check groups (M1-M6, S4-S6, B11/R1/D1). Treat the 11-category figure as unverified until the SOP doc is read.
- 200/300-line CLAUDE.md caps and the 60% context threshold: **not in the README**. The README's only session-start cost claim is "typical read on a mature project stays well under 2% of a 1M context window". Findings below are evaluated against that claim.
- Two documentation drift items noticed in passing, worth a Backlog entry independent of any finding: the README says "Four slash commands" but the Quick start lists five installed (`/restart-sop`, `/update-sop`, `/update-agent-sop`, `/migrate-to-multi-agent`, `/finish`); and `/update-sop` is described as a "9-step session-end checklist" immediately above a 10-item numbered list.

**Sources scanned:** 10 | **Relevant findings:** 6 | **No-find sources:** Anthropic engineering (latest dated post Apr 23, 2026), Anthropic research (latest Sep 23 but life-sciences, off-topic), Latent Space (last 24h items are AI-for-science and open-weights model news), LangChain blog (latest Sep 22, healthcare LangSmith use cases), Google DeepMind (Gemini 3.8 Flash, no agent-ops content), OpenAI (Sep 23 item is the Ukraine cyber-defence programme, off-topic), Hacker News (see caveat below)

**Fetch method breakdown:** WebFetch: 10 | Chrome fallback: 0 | WebSearch fallback: 2 (OpenAI, Hacker News) | Unreachable: 0

**Fetch notes:** the GitHub REST commits endpoint with a `?since=...` query string was refused by the fetch provenance guard; the unfiltered `/commits` endpoint worked and returned enough history to date the repo. Hacker News could only be reached via WebSearch, which surfaced third-party aggregator digests rather than HN itself - no HN item is reported as an actionable finding below, per the aggregator rule.

**Version-revert check:** Claude Code 2.1.281 (23 September 2026) is the newest published version, so there are no subsequent releases to check for reverts. Urgency ratings are capped accordingly - no finding is rated Critical.

---

**`/context` now reports an accurate total, including messages added since the last response**
Source: https://code.claude.com/docs/en/changelog (2.1.281)
Published: 23 September 2026
Topic: Context window and token optimisation
Relevance to agent-sop: The SOP's 60% context threshold rule and the README's "well under 2% of a 1M context window" claim both depend on Claude Code's own context indicator. Until this release, `/context` under-reported - it excluded messages added since the last response and could read lower than the status line. Any threshold calibrated against the old reading is measuring a smaller number than reality.
Already addressed? No - last repo activity 7 August 2026.

**Suggested change:**
Update `docs/sop/claude-agent-sop.md` §15.5 (token equivalences / context threshold) to state that the 60% threshold must be read from `/context` on Claude Code 2.1.281 or later, and add a one-line note that readings taken on earlier versions understate usage. Bump the minimum-version requirement in `README.md` ("Claude Code v2.1.101 or later") to v2.1.281 for accurate threshold measurement, or add a second, softer "recommended for accurate `/context`" line so the hard floor stays at 2.1.101. Add a sop-checker check (suggested ID `C-new`) that greps the SOP doc for a version-qualified threshold statement.

**Expected impact:**
- Compliance score: no change (documentation accuracy, not a new gate)
- Token budget: no change
- Check coverage: one new check

---

**Large-CLAUDE.md startup notice now counts instruction files together, including `@`-imports**
Source: https://code.claude.com/docs/en/changelog (2.1.281)
Published: 23 September 2026
Topic: Context window and token optimisation
Relevance to agent-sop: agent-sop deliberately splits context across `CLAUDE.md`, `Backlog.md`, `docs/agent-memory.md`, per-entry decision/gotcha files and the build plan. Under the old notice, each file was measured alone and a split file set never triggered the warning. Claude Code now aggregates them, so a compliant agent-sop project with many mid-sized files can now trip the notice that the SOP's own structure was designed to avoid.
Already addressed? No.

**Suggested change:**
Add a gotcha entry under `docs/agent-memory/gotchas/` and a note in `docs/sop/claude-agent-sop.md` §15.5 explaining that from 2.1.281 the startup notice is aggregate, not per-file, so splitting a large `CLAUDE.md` into imports no longer suppresses it. Then extend `scripts/` with an aggregate line-count check (or add it to sop-checker) that sums `CLAUDE.md` plus every `@`-imported instruction file against the 200/300-line cap, rather than checking `CLAUDE.md` in isolation. This is the single highest-value item in this digest: the SOP's core sizing discipline is now measured differently by the runtime.

**Expected impact:**
- Compliance score: risk of decrease on existing projects until they trim (the aggregate is larger than any single file)
- Token budget: likely decrease, once projects trim to pass the aggregate check
- Check coverage: one new check, one existing check redefined

---

**`/batch` now runs where a `WorktreeCreate` hook provides the agent worktrees, not only inside a git repository**
Source: https://code.claude.com/docs/en/changelog (2.1.281)
Published: 23 September 2026
Topic: Multi-agent orchestration and delegation
Relevance to agent-sop: `docs/guides/multi-agent-parallel-sessions.md` assumes each agent is manually placed in its own `git worktree`, with agent-id resolution falling back to a 6-char hash of the worktree path. A `WorktreeCreate` hook plus `/batch` is a supported way to provision those worktrees automatically, which would remove the manual setup step the guide currently documents in §7 (Pre-flight).
Already addressed? No.

**Suggested change:**
Add a section to `docs/guides/multi-agent-parallel-sessions.md` documenting `/batch` with a `WorktreeCreate` hook as an alternative to manual `git worktree add`, including how `CLAUDE_AGENT_ID` or `.sop-agent-id` should be seeded by the hook so agent-id resolution stays deterministic (rather than falling through to the path hash, which changes if the hook picks a different directory). Add a reference hook example under `scripts/`. Add checks M7 to sop-checker: if a `WorktreeCreate` hook is configured, it must write an agent-id file into each new worktree.

**Expected impact:**
- Compliance score: no change (new optional path)
- Token budget: no change
- Check coverage: one new check (M7)

---

**`"attribution": false` in settings.json suppresses all commit and PR attribution**
Source: https://code.claude.com/docs/en/changelog (2.1.281)
Published: 23 September 2026
Topic: Git workflow automation for AI agents
Relevance to agent-sop: `/update-sop` Step 10 commits docs changes together with the feature work, and Step 3d's drift guard reads P-numbers out of commit messages. Attribution trailers are noise in that parse and clutter the batch-log commit references the repo backfills manually (see the 7 August `Batch 0.35` commit). Note the compatibility trap in the changelog: older CLI versions skip an entire settings file containing the boolean form.
Already addressed? No.

**Suggested change:**
Add `"attribution": false` to the settings template installed by `setup.sh`, using the object form rather than the boolean so that projects running a mix of CLI versions do not silently lose their whole settings file. Document the version caveat in `README.md` under Requirements. Confirm `scripts/validate-state-transitions.sh` and the Step 3d P-number parse are unaffected either way - they should be, but the assumption is currently untested.

**Expected impact:**
- Compliance score: no change
- Token budget: marginal decrease (shorter commit messages read by `/restart-sop`'s `git log --oneline -10`)
- Check coverage: no change

---

**Dangerous-`rm` handling hardened; auto mode classifier moves server-side for read-only and sandboxed commands**
Source: https://code.claude.com/docs/en/changelog (2.1.281)
Published: 23 September 2026
Topic: AI code review and security review automation
Relevance to agent-sop: Non-negotiable Rule 1 is "never delete without a trace". Claude Code now asks before a recursive `rm` whose target is only command-substitution output (`rm -rf "$(pwd)"`), flags removals at a shell variable followed by a top-level directory name, and in unattended `--dangerously-skip-permissions` or auto mode waits two minutes then denies with a rewrite hint. That last behaviour changes what an unattended agent-sop session does when it hits a destructive command: it now stalls for two minutes rather than proceeding.
Already addressed? No. Also relevant to the S4-S6 memory-poisoning and CI-hardening checks.

**Suggested change:**
Update the `security-reviewer` agent definition to check for `CLAUDE_CODE_DISABLE_DANGEROUS_RM_TIMEOUT` and `CLAUDE_CODE_DISABLE_SUBSTITUTION_RM_PROMPT` being set in project settings or CI - either one disables a protection that Rule 1 now gets for free from the runtime, and both should be treated as findings. Add checks S7/S8 to sop-checker for those two variables. Separately, note in `docs/guides/multi-agent-parallel-sessions.md` that an unattended parallel session can now stall up to two minutes per flagged command, which matters for timeout budgets in any CI harness.

**Expected impact:**
- Compliance score: likely increase (two new passable checks on most projects)
- Token budget: no change
- Check coverage: two new checks (S7, S8)

---

**Claude Opus 5.5: 1M context by default, thinking cannot be disabled, effort parameter replaces thinking controls**
Source: https://platform.claude.com/docs/en/release-notes/overview (22 September 2026) and https://simonwillison.net/2026/Sep/22/opus-and-sol-and-luna/
Published: 22 September 2026 - two days old, outside the strict 24-hour window. Included because it is a model-behaviour change with direct SOP consequences and no prior digest exists in this folder to have caught it.
Topic: Anthropic API and model changelog
Relevance to agent-sop: The README's session-start cost claim is expressed as a percentage of a 1M context window, which is now the default on the flagship coding model rather than an opt-in - that claim gets easier to meet, not harder. More consequential: on Opus 5.5 `thinking: {"type": "disabled"}` returns a 400, and depth is controlled by the effort parameter instead. Any SOP guidance, agent definition or benchmark harness that sets thinking explicitly will fail on this model.
Already addressed? No.

**Suggested change:**
Grep `.claude/agents/` (all five reference agents), `docs/benchmark/` runner scripts and any `agent-sop.config.json` template for `thinking` configuration and migrate to the effort parameter. Add a line to `docs/sop/claude-agent-sop.md` §15.5 noting that on Opus 5.5 thinking tokens are always present and always count toward the context threshold, so the 60% rule bites earlier in absolute terms than on models where thinking could be switched off. Re-baseline the A/B benchmark in `docs/benchmark/` against Opus 5.5 before the next round of quality claims - the current +8-33% figures were measured on a different model generation and should be labelled with the model they were run on.

**Expected impact:**
- Compliance score: no change
- Token budget: risk of increase (always-on thinking on the flagship model)
- Check coverage: no change

---

## Not reported as findings

- **AGENTS.md support in Claude Code 2.1.277** (via Simon Willison, 18 September 2026 - Claude checks for `AGENTS.md` when no `CLAUDE.md` is present in a folder, built as a Claude Code "mod"). The task brief records AGENTS.md as already rediscovered across prior runs. It is noted here as still open rather than written up fresh. The new detail worth a line in the Backlog is the underlying mechanism - Claude Code "mods" as a customisation surface for project instructions - which is a plausible future home for the agent-sop file set and has not been assessed.
- **Hacker News items** (Claude Code reportedly signing a contract without confirmation; agent-driven performance tuning claims). Reachable only via third-party aggregator digests, not verifiable against HN itself. Unverified, aggregator-only - not actionable.

---

## Recommended next action

Two items are worth filing as Backlog entries this week, in this order:

1. **Aggregate instruction-file sizing** (finding 2). It changes how the runtime measures the thing the SOP's §15.5 discipline exists to control, and it can move compliance scores on projects that pass today. File as `[OPEN][Refactor]`.
2. **Effort-parameter migration and benchmark re-baselining for Opus 5.5** (finding 6). The five reference agents and the benchmark harness are the blast radius. File as `[OPEN][Bug]` for the agent definitions, `[OPEN][Iteration]` for the benchmark labelling.

The remaining four are `[OPEN][Iteration]` documentation and check additions and can batch into one session.

Separately: the repo has had no commits for seven weeks. If that is deliberate, no action. If not, the `/update-agent-sop` staleness reminder ("weekly" by default) will be firing on every consumer project's `/restart-sop`.
