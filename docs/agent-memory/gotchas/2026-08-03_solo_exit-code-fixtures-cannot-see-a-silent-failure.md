# Exit-code-only fixtures cannot distinguish a reported failure from a silent one

**Date:** 2026-08-03
**Agent:** solo

**The surprise:** `docs/benchmark/drift-fixtures/run-tests.sh` passed 5/5 against a stub validator that returned the correct exit codes and printed absolutely nothing.

**The misleading prior expectation:** that a green fixture suite means the gate works. It means the gate *exits correctly*. When a check's product is a diagnostic message — every `BLOCK:` in `validate-state-transitions.sh` — the exit code is the least informative part of its behaviour.

This is the P73 shape exactly: a `grep`/`pipefail`/`errexit` interaction killed the script before its BLOCK message printed, operators saw a bare non-zero exit with no explanation, and every fixture still passed because the exit code was non-zero either way. The state-transition suite was upgraded with `.expect-stdout` assertions afterwards; the drift suite never was, so the same regression could recur undetected in `--check-drift`.

**The rule:** when a check exists to *tell the operator something*, assert on the message, not just the status. And prove the suite discriminates by running it against a deliberately broken stub — a suite that passes against a stub is not testing anything. Both harnesses now take a `VALIDATOR` override for exactly that.

Related: P84, P73.
