# P97: the Stop hook speaks only through exit 2, only on facts, once per commit state

**Date:** 2026-09-04
**Agent:** solo

Three choices in `scripts/hooks/sop-stop-drift.sh`, each ruling out an alternative that was tried or proposed elsewhere.

**Exit 2, not stdout.** Claude Code writes `Stop` hook stdout to the debug log and never shows it to the model; only `SessionStart`, `UserPromptSubmit`, `UserPromptExpansion` and `PostModelSwitch` stdout becomes context. Exit 2 with the reason on stderr is the documented way a Stop hook makes Claude continue. ship-sop's hook design ("stdout from Stop hooks is piped into the next turn's context") was wrong about this, which is the second reason its directives were never acted on. Every Stop hook in this repo prints its reason to stderr and exits 2, or prints nothing and exits 0.

**Facts only, and a full list at once.** The hook fires on three conditions a script can check — commits after the newest `docs/recent-work/` entry, uncommitted tracker files, a ship-sop auto-mode code diff with no covering report — and lists every one that holds in a single reason, so a compliant continuation clears them in one turn. It does not fire on "the session seems to be ending", which no script can know, and it does not fire on judgement ("are the findings serious"). The action-vs-ceremony test (2026-04-19) is what rules out the alternative: a `PreCompact`/`SessionEnd` echo that the agent can ignore is indistinguishable from no echo, and `SessionEnd` output cannot reach the model at all.

**Once per commit state.** The signature is (HEAD, hash of the dirty tracker set, gate-needed flag), stored per repo under `AGENT_SOP_STATE_DIR`. A session that ignores the notice pays one extra turn per commit, never a loop; a session that acts on it changes HEAD and the next Stop is silent. `stop_hook_active` is honoured as a second guard even though the current docs do not list it.

**Coverage is a fact, not a stamp.** For the ship-sop gate, "a report covers HEAD" means a `docs/reviews/*-ship-auto.md` file carries `Covers: <sha>` for an ancestor of HEAD with zero code lines between them (same docs filter as the trigger). The first cut required the report to name HEAD itself; committing the report moves HEAD, so a branch could never become covered once the report was in git. A fixture caught it before it shipped. ship-sop P18 records the mirror-image failure of stamping at emission time: an interrupted turn leaves a commit permanently ungated. Reading the fact from the report avoids both.

**Not push-gated: session records.** The push gate refuses only under ship-sop auto-mode with an uncovered code diff. Pushing early is the standing protection against sibling-worktree wipes (`gotchas/2026-05-02_solo_worktree-uncommitted-wipe.md`); a gate that held pushes until housekeeping was written would trade a review gap for a data-loss risk.

---
*Supersedes:* ship-sop's throttle-stamp-at-emission model (`auto-ship-hook.sh`, P18) for the gate-coverage question.
