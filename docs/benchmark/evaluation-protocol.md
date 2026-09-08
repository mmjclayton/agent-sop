# Current evaluation protocol

2026-09-08. Replaces the historical mandatory benchmark rerun rule (P81).

Run deterministic fixtures for every changed hook, resolver and validator. Prove
new regression cases fail against the prior implementation. Keep these checks
separate from stochastic model evaluation.

For performance changes compare identical tasks, commits, permissions, model and
runtime in fresh independent processes with isolated home/config directories:

1. Native runtime defaults, normal project instructions and native memory.
2. Minimal project card plus one handoff file.
3. Current Agent SOP, explicitly installed into the target.
4. Agent SOP plus ship-sop.

Use small obvious changes, ambiguous multi-file bugs, dependent session pairs,
interrupted work and concurrent worktree handoffs. Include stale memory and
conflicting ownership. Do not use inherited parent-session context.

Score deterministic task acceptance first. Record regressions, duplicate
investigation, time to useful progress, handoff accuracy, confirmed review defects,
false-positive handling, user interventions and all implementation/review/retry
cost. SOP-specific file creation is a mechanics check, not user value.

Pin versions, randomise condition order, retain artefacts and actual usage, and
blind qualitative scoring where practical. Report cached/uncached input and output
separately, reasoning when exposed, wall time and unknown usage as unknown.

Validate the harness with a small pilot before spending on repeated model runs.
Set task count, repetitions, cost cap and practical success criteria before a
paid run. Expand based on observed variance; a fixed repetition count does not
guarantee statistical power. Do not change the three-reviewer default until
measured defect yield and cost justify it. Historical R1-R5 results are not
measurements of current runtime performance.
