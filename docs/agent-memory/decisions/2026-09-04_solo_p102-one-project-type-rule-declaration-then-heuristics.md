# P102: "code project" is one executable rule — a declaration line first, the checklist heuristics second

**Date:** 2026-09-04
**Agent:** solo

We chose to make the ship-sop gate's "is this a code project" question a single function in `scripts/hooks/sop-lib.sh`, `sop_project_type`, with an explicit `**Project type:** code|non-code` line in CLAUDE.md taking precedence over the four heuristics the compliance checklist had documented since April (Auth/Database/Design System heading, code-template reference, a test command under Key Commands, a manifest at the root). Every consumer — the Stop hook, the push gate, the context block, `/update-sop`, `/finish`, ship-sop's `/ship`, the checker — reads that function or its CLI wrapper.

Why a declaration at all: the heuristics say non-code for agent-sop and ship-sop, whose bash hooks and installer have a fixture suite and CI. Without an override the gate would have stopped reviewing the code that runs on every prompt on this machine. Why the declaration wins rather than being one more signal: a rule with a tie-break is a rule nobody can predict from the file. The cost is that a stale `non-code` line can switch the gate off on a repo that has since grown a manifest — so the context block names that contradiction whenever it sees one, and checklist X7 fails it.

Why code lines only, always: the operator's rule is "coding, and nothing else". The config's `skip_docs_only` had been read through a jq `// true` default, which treats an explicit `false` as absent, so docs were already excluded in practice; making it unconditional turned an accident into the rule and let the docs say what happens.

What this does not change: session records and tracker hygiene apply to every SOP project. A prose project with SOP scaffolding still gets the drift notice; only the reviewer gates are code-only.
