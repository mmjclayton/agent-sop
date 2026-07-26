# Auditing by command name misses failures by exit code

**Date:** 2026-07-26
**Agent:** solo

## The surprise

P73 fixed a `set -euo pipefail` bug where a non-zero exit inside a command substitution killed the script before its error message printed. The fix included an audit "to find every site with the same shape". The audit was run, four sites were guarded, and the Batch Log recorded "audited all 8 command-substitution sites".

The reviewer found a fifth, still unguarded, and it was the worst one: `scripts/validate-state-transitions.sh:164`, `worktree_count=$(git worktree list 2>/dev/null | wc -l | tr -d '[:space:]')`. Outside a git repo `git worktree list` exits 128, so `--check-drift` in a non-git directory exited **128 with empty stdout and empty stderr** — the exact silent failure P73 existed to remove, still present after P73 shipped.

## The misleading prior expectation

The audit filtered candidate sites like this:

```bash
grep -nE '^[[:space:]]*(local )?[a-z_]+=\$\(' script.sh | grep -E 'grep|find|diff|awk.*exit|test '
```

That is a filter on **which command is being run**, built from a mental list of "commands that return non-zero normally": grep, find, diff, test. It cannot match `git worktree list`, `git symbolic-ref`, `git merge-base`, or any other subcommand whose failure mode is a non-zero exit rather than a no-match. The number it produced, 8, was then reported as if it were the total. The file actually has 28 command-substitution assignments, 19 of them piped.

Two compounding errors: the filter was wrong, and its output was described as exhaustive.

## Rules

1. **Enumerate the population first, then classify it. Never let the filter define the total.** Count all `=$(` assignments, then assess each. If the report says "all N sites", N must be the count of the population, not the count of the matches.
2. **Filter on the failure mode, not the command name.** The question is never "is this grep?" — it is "can this exit non-zero on a legitimate input?". Every external command can. `git` subcommands fail on missing repos, refs, and upstreams; `head`/`tail` fail on missing files.
3. **A claim of completeness is a claim, and it belongs in the review scope.** "Audited all N sites" written into a Batch Log is exactly the kind of assertion a reviewer should be asked to verify independently. This one was, and it was false.
4. **When a fix is prompted by a silent failure, test the fix in the failing environment.** The P73 fix was verified against the fixture suite, which runs inside a git repo. The surviving bug only manifests outside one.

## Related

Same session, same shape: `docs/reviews/2026-07-26_solo_P67-P69.md` found P69's S7 check inert because its git range was always empty, and `docs/reviews/2026-07-26_solo_P66-P73.md` found `aggregate` pooling rounds because its only test used a single round. In all three the verification exercised the happy path the author had in mind rather than the case the code would actually meet. See [[2026-07-26_solo_pipefail-kills-the-error-message-before-it-prints]].
