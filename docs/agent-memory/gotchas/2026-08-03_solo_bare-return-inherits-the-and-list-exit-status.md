# A bare `return` inherits the exit status of the preceding `&&` list

**Date:** 2026-08-03
**Agent:** solo

**The surprise:** `scripts/validate-state-transitions.sh --before-file /missing.md` exited 1 with **zero bytes on both stdout and stderr**. The enforcement engine failed completely silently.

**The misleading prior expectation:** that `return` with no argument is neutral. It is not — it returns the status of the last command executed. In:

```bash
[ -f "$BEFORE_FILE" ] && cat "$BEFORE_FILE"
return
```

a missing file makes the `[ -f ]` test fail, `cat` never runs, and the bare `return` hands back 1. Because the function is called as a plain statement (`resolve_before > "$TMP_BEFORE"`), not inside an `if` or `&&`, `errexit` fires immediately — before the "no before-state ... Skipping" message on the next line could print.

**The rule:** in any function whose contract is "may legitimately do nothing", end the branch with an explicit `return 0`. This is the same silent-failure *class* as the P73 `pipefail` bug but a different *shape* — an `&&`-list return rather than a pipe — so an audit that greps for `grep|find|diff` pipelines will not find it. Audit by exit path, not by command name.

Related: P84, P73, and `2026-07-26_solo_auditing-by-command-name-misses-failures-by-exit-code.md`.
