# Resume test on Claude Code: sandboxed harness merged (P122)

**Date:** 2026-10-11
**Agent:** 2d10c2 (ship-sop session, worktree `agent-sop-p121`)
**Commits:** 90d3185 (PR #56)

P122: `codex-bench.sh` runs the P121 resume test on Claude Code (`BENCH_RUNTIME=claude`): each turn `claude -p` under `sandbox-exec` (session folders only; operator home, keychain, LaunchServices, Apple Events, pasteboard and outside processes denied), the subscription token passed only through the sandboxed child's environment and scrubbed from output. Six review rounds; profile verified with node and the real hst-tracker suites. Pilot waits on Matt's `claude setup-token` file and his confirmation that native auto-memory stays on.
