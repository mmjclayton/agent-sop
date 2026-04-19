# rollup-refresh snippet leaks local var declarations under zsh

**Date:** 2026-04-19
**Agent:** solo

**Issue:** The canonical `refresh_recent_work_rollup` bash snippet documented in `/update-sop` Step 8b, `/migrate-to-multi-agent` Step 9, and `docs/guides/multi-agent-parallel-sessions.md` Section 3 uses `local var=$(cmd)` inside a `{ ... } > output` compound group. Under macOS default zsh (the default shell Claude Code's Bash tool uses), `local` declarations inside the compound group echo their assignments to stdout, polluting the generated rollup and corrupting `CLAUDE.md`. Under bash the same snippet runs clean.

**How surfaced:** Two independent subagents (agent A `009b16`, agent C `8a0be0`) ran the snippet during the 2026-04-19 Batch 1.7 dogfood and both caught the corruption. Both worked around it by re-invoking via `bash -c '...'`.

**Follow-up to fix upstream.** Three options:

1. **Wrap invocations in `bash -c`** in every documented location. Lowest-risk change, reversible.
2. **Rewrite the snippet to avoid `local` inside the compound group.** Move variable declarations outside the `{ }`, or use function-scoped assignments differently.
3. **Ship as a standalone script** at `scripts/refresh-rollup.sh` with an explicit `#!/usr/bin/env bash` shebang, and have the commands reference the script rather than inlining the snippet. Also lets the script be reused by the migration command cleanly.

Recommendation: option 3 — cleanest and reusable across /update-sop Step 8b, /migrate-to-multi-agent Step 9, and any future consumers. Creates `scripts/refresh-rollup.sh` paired with `scripts/migrate-to-multi-agent.py`, both tooling for the parallel-session mechanics.

**Not a P43 shipping blocker.** Both dogfood agents resolved via `bash -c` workaround and produced correct output. The canonical fix goes in as a small follow-up once P43 ships.
