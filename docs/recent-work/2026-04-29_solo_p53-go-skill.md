# P53 `/go` skill — end-to-end verify, simplify, ship

**Date:** 2026-04-29
**Agent:** solo
**Commits:** 7b33355 (P52 feat, pre-existing on local main), a4dadb9 (P52 close-out, pre-existing), 28e3755 (P53 feat) — squash-merged as 4433bb3 via PR #1.

## What shipped

New slash command at `.claude/commands/go.md` (mirrored to `~/.claude/commands/go.md`). Three hard-blocking phases that run when Claude believes the work is done:

1. **Verify end-to-end.** Detect surface from the diff: backend → boot the service in bash and exercise the changed endpoints with curl; frontend → drive the browser through the Claude Chrome extension at desktop + mobile widths; desktop → computer-use; CLI → real invocation; docs-only → skip with stated reason. Asks the user when detection is ambiguous.
2. **Run `/simplify`** scoped to the session diff. Re-runs Phase 1 if production code changed under the simplification.
3. **Ship.** Reconcile `Backlog.md`, run `/update-sop`, push, open PR via `/prp-pr`.

Motivation: passing types and unit tests is not the same as exercising the change. `/go` makes Claude prove the work runs against the real surface before the SOP trail and PR get created.

## First PR on this repo

Direct push to `main` was denied by the new "no push to main" guard, which forced the PR path. This is PR #1 across the repo's 89-commit history — every prior commit was pushed straight to `main`. Bundled with two pre-existing P52 commits that had been sitting unpushed on local main.

## Files touched

- `.claude/commands/go.md` (new — canonical, ships with SOP installs)
- `~/.claude/commands/go.md` (user-scope mirror)
- `Backlog.md` (P53 entry + Shipped Archive line)
- `CLAUDE.md` (Key Documents table row)
- `docs/feature-map.md` (P53 row, `Last updated` bumped to 2026-04-29)

## Follow-ups

- No follow-ups filed. `/go` will dogfood itself the next time a code change ships through this repo (or any other ECC project).
- Watch for: Phase 1 detection misclassifying monorepo changes; Phase 2 re-verification loop bouncing if `/simplify` keeps touching production code.
