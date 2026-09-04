# `git diff --numstat` renames are one tab-separated path field — whitespace splitting reads the old name

**Date:** 2026-09-04
**Agent:** solo

**The surprise.** `sop_code_lines` fed numstat to `awk` with the default field separator and tested `$3` against the documentation extensions. A rename arrives as `docs/plan.md => src/gen.js` (or `dir/{a.md => b.js}/rest`) in one tab-separated field, so `$3` was `docs/plan.md`: a documentation file renamed into a code file with twelve lines of logic added counted as zero code lines. The trigger never fired on it, and worse, `sop_shipsop_covered` reported an existing `Covers:` report as still valid because "no code changed since". The bug was on main before P102; P102 made the docs filter unconditional, which removed the only way round it. Found by the silent-failure-hunter gate agent, reproduced by hand, fixed in 8903290.

**Rule.** Parse numstat with `awk -F'\t'`. Treat a rename as two names and exclude it as documentation only when both are. Any path-based classifier over git output gets a rename fixture (`git mv notes.md gen.js` plus added lines) in its suite — `stop-rename-doc-to-code-counts` is the one here.

Second, smaller: a fixture helper (`push_json`) defined below its first use fed the hook a JSON with no command, and two new push cases passed for the wrong reason. Helpers live with the other helpers at the top; a "silent" assertion on a hook needs a companion case proving the same input is not silent in the positive state.
