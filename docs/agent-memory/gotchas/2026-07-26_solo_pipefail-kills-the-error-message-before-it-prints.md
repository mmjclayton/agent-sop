# `set -euo pipefail` kills the error message before it prints

**Date:** 2026-07-26
**Agent:** solo

## The surprise

`/update-sop` Step 3c exited 1 with **completely empty output**. No `BLOCK:` line, no warning, nothing on stdout or stderr. It took a `bash -x` trace to find out why.

## The misleading prior expectation

The code reads as if it reports:

```bash
batch_match=$(grep -lE "\b${p}\b" docs/build-plans/phase-*.md 2>/dev/null | head -1)
if [ -z "$batch_match" ]; then
  echo "BLOCK: $p shipped but no Batch Log reference found in docs/build-plans/phase-*.md"
```

Reading it top to bottom, a missing Batch Log entry prints a clear diagnostic. It never does. `grep -l` exits 1 when it matches nothing, `pipefail` propagates that through the pipe to `head`, the assignment inherits the pipeline's status, and `set -e` terminates the script **on line 494, before line 496 is ever reached**. The `BLOCK:` message is unreachable code.

The `2>/dev/null` makes it worse by suggesting the author considered the no-match case and handled it. It suppresses grep's *stderr*, which was never the problem — the *exit code* is.

## Why it stayed hidden

The existing fixtures assert on **exit status**, not stdout. A silent exit 1 and a reported exit 1 are indistinguishable to them, so the fixtures passed throughout.

Worse: commit `66ee6a4` is titled "fix(validator): `|| true` pipefail guard around drift-check grep". The identical bug was found and fixed in the drift check on the same file, and this site was left untouched. A single-site fix on a repeated pattern — `docs/guides/cross-layer-rules.md` Tier 0 (grep for siblings before fixing one instance) would have caught it.

## Rules

1. **Any `var=$(cmd)` where `cmd` legitimately returns non-zero needs `|| true`** under `set -e`. `grep`, `find`, `diff`, and `test` all return non-zero as normal signalling, not as failure.
2. **`pipefail` makes this worse, not better.** Without it, `grep ... | head` returns `head`'s status (0) and the bug does not bite. With it, the pipeline returns grep's 1. Adding `pipefail` to a script retrofits this failure mode onto every existing pipeline in it.
3. **Fixtures that assert only on exit code cannot detect an unreported error.** When a check's product is a *diagnostic message*, assert on the message.
4. **When fixing a shell idiom bug, grep the whole file for the same shape** before committing. `66ee6a4` fixed one of two instances and the second survived three months.

Filed as P73. Not fixed in-session: it is a validator change, so `docs/sop/security.md` rule 11 requires it ship as its own declared, reviewed item rather than folded into an unrelated diff.
