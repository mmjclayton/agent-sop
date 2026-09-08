# Review — P107 Codex support

**Date:** 2026-09-08
**Agent:** codex
**Reviewer agent:** independent code-reviewer via Codex CLI 0.153.4
**Commits:** temporary review snapshots; implementation checkpoint; final configured review follows

## Summary

Adds Codex installation, skills, reviewer definitions and hook integration while
retaining Claude defaults and shared SOP state. Independent reviewers ran in
separate clones with Codex reporting a read-only sandbox. This is a development
review record, not a ship gate stamp for committed HEAD.

Severity: HIGH

## Findings

- HIGH, `scripts/hooks/sop-lib.sh` (`sop_instruction_file`): bulleted AGENTS.md
  declarations could lose precedence. Fixed upstream by reusing the declaration
  parser, with a regression assertion for AGENTS code versus CLAUDE non-code.
- MEDIUM, `.agents/skills/source-command-*/SKILL.md`: compatibility links climbed
  one directory too far. Fixed all links and verified source and installed targets.
- MEDIUM, `scripts/install-codex.sh`: ship-sop installer metadata collided with
  its runtime fallback config. Metadata now uses ship-sop.source.json; the
  fallback has real trigger/agents fields. Added config-shape assertions.
- MEDIUM, `scripts/refresh-priorities.sh`: the new Backlog entry lacked the
  backtick-delimited status format the existing parser expects. Corrected the
  entry format; the pre-existing parser behavior itself was not changed.

## Validation and limits

All 192 legacy agent-sop fixture cases pass. The new agent-sop Codex suite and
ship-sop install/isolation suite pass. Native skill frontmatter, reviewer TOML,
installed aliases, shell syntax and blocking ShellCheck checks pass.

The independent reviewers reported integration verification incomplete because
their sandbox constraints prevented running write-producing suites; the parent
ran those suites separately. Findings above were corrected and regression-tested.
No full post-fix gate certification or Covers: stamp is claimed. Existing global
custom reviewer profiles were preserved rather than replaced by setup.

A separate live smoke test of the final `scripts/codex-review.sh` completed
with exit 0 and `Verdict: PASS` on a known-safe greeting diff. This verifies
the runner transport and sandbox invocation, not the quality of this full port.
