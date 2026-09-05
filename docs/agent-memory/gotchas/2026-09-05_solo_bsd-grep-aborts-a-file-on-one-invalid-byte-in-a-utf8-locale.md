# BSD grep in a UTF-8 locale aborts the whole file on one invalid byte — run byte-oriented hooks in the C locale

**Date:** 2026-09-05
**Agent:** solo

**The surprise.** `sop_project_type` piped CLAUDE.md through `grep`/`sed`/`awk` with stderr discarded. On macOS in a UTF-8 locale, one non-UTF-8 byte anywhere in the file (a pasted smart quote, a merge artifact) makes BSD grep exit 2 with "Invalid multibyte sequence" for the entire file, not the bad line. Swallowed, that read as "no declaration, no code signals": a repo with an explicit `**Project type:** code` line classified non-code, and because P102 and P103 hang the ship gate, the push gate and the Stop hook on that one answer, all three went silent with nothing printed anywhere. Found by the silent-failure-hunter gate agent at P103; reproduced through the CLI wrapper; fixed by `export LC_ALL=C` in `sop-lib.sh` (every pattern there is ASCII) with two fixtures planting `\xff\xfe` next to a declaration and next to a heading.

**Rule.** A hook that classifies from file content runs in the C locale, and a fail-open default that removes protection gets a fixture with an invalid byte in the input. Related, same review: the in-flight edit the Stop notice prescribes must not re-fire the notice — the sanctioned "carry on" path cannot count as a new state.
