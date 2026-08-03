# Retroactive filing ships as two commits, not a validator exemption

**Date:** 2026-08-03
**Agent:** solo

We chose to record P74 as two commits — `[OPEN]`, then `[SHIPPED - 2026-07-27]` — over adding a retroactive-filing exemption to `scripts/validate-state-transitions.sh`, because both states are historically true and changing the enforcement layer inside a diff that layer validates is exactly the tamper surface `security.md` rule 11 exists to name.

## The situation

The 2026-07-27 session fixed the `npx block-no-verify` hook and never wrote it to the Backlog. Filing it on 2026-08-03 as `[SHIPPED]` in one commit is an `<absent>` → `[SHIPPED]` transition, which the validator rejects:

```
BLOCK: P74 transitioned <absent> -> [SHIPPED] (illegal)
  Legal outbound from <absent>: [OPEN], [DEFERRED], [IN PROGRESS]
```

## Options considered

**Add an exemption to the validator** for entries carrying a `**Retroactive:**` marker. Rejected. It is a change to the gate, made inside the same diff the gate is checking, to let that diff pass — the precise shape rule 11 and P69 warn about. It would need its own declared item, its own review artifact, and fixtures. It would also edit agent-facing instruction text, which triggers the MANDATORY lite benchmark run. That is a large, separate piece of work, and reaching for it here would be scope creep dressed as a fix.

**Skip the Backlog entirely** and let the Batch Log, recent-work entry, feature-map row and gotcha carry the trace. Rejected. `Backlog.md` is the single source of truth for work items; four traces elsewhere and a hole in the one file that claims completeness is worse than the problem.

**Format around the check** — record P74 only as a Shipped Archive line, which the validator does not parse as a `### P<n>` heading. Rejected outright. Satisfying a check's letter by dodging its parser is the failure mode this project has now caught three separate times in reviews.

## Why two commits is not gate-gaming

Two facts settled it.

First, the sequence is true. P74 genuinely was an open finding — raised in Matt's audit on 2026-07-26, carried in the resume snapshot as "optional, not actioned" — before it was fixed on 2026-07-27. Writing `[OPEN]` then `[SHIPPED]` records what happened. It is late, not false.

Second, this is the project's designed path, not a loophole. The validator's own docstring says earlier commits in a session "are assumed already validated by their own `/update-sop` runs", and the whole-session replay via `--before <merge-base>` is offered as an explicit opt-in, not the default. P70 and P73 took the same two-commit route (`[OPEN]` at `e0f9e54`, `[SHIPPED]` at `4621b1b`).

## Rule

When already-shipped work needs a retroactive Backlog entry, file it at the state it actually occupied when the work began, then transition it in a second commit. Do not collapse the two, and do not weaken the validator to accept the collapse. If a future case arises where the `[OPEN]` state was never true — work that was never a known finding before it shipped — that is a genuine gap in the transition graph and belongs in its own reviewed item, not in the diff that discovered it.

## Related

[[2026-08-03_solo_merging-without-update-sop-strands-every-tracker]] — the missed `/update-sop` that created the need for a retroactive filing at all.
