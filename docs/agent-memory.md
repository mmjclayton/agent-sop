# Agent Memory

Shared context for all agents working on this project. Read at the start of every session. Update at the end. Never delete without a trace — update in place, mark superseded, or archive.

---

## Key Documents

See CLAUDE.md Key Documents table.

---

## Key Source Files for Current Work

*Updated at the start of each phase.*

| Area | File |
|------|------|
| Core SOP | `docs/sop/claude-agent-sop.md` |
| CLAUDE.md template | `docs/templates/claude-md-template.md` |
| Phase 0 build plan | `docs/build-plans/phase-0-foundation.md` |

---

## In-Flight Work

*(none)*

Cleared 2026-08-03. The previous line tracked branch `fix/p66-p73-validator-and-gate-coherence` as unpushed; it merged as `4621b1b` via PR #11 on 2026-07-26, but the session that followed ended without `/update-sop`, so the line's own clear-on-merge instruction never ran and it read as in-flight for eight days. See Batch 0.29.

<!-- in-flight:start -->
*Auto-generated from `docs/agent-memory/in-flight/`.*

- solo (2026-09-24): P110 merged (PR #29); P111 (PR #30) and P112 (PR #31) shipped with ship-sop P33/P34. Native-model pilot stays deferred (AUD 0). main is protected since this evening (required CI check, enforce_admins, auto-merge on): every commit goes via PR.
- solo (2026-09-30): P113 and P114 merged via PR #33 (6d89a77). Hook installed and registered on this machine, installed commands and baseline SHAs refreshed the same day. ship-sop replication is ship-sop P36, on its own PR. Nothing else in flight.
- solo (2026-10-07): research digests moved into docs/research/ (PR #36, 5af9db2); the scheduled scanner now writes there, so each run leaves an uncommitted digest for the next session to commit via PR. Nothing else in flight.
- solo (2026-10-10): P115 merged via PR #38 (5191fe0); four stale remote branches deleted. P116 (fresh multi-run comparison) is open and waits on Matt's cost cap. Nothing else in flight.
- solo (2026-10-11): R8 stopped (pre-run review, PR #51); P120 closed as superseded by P121 (resume test, ship-sop session owns it). Nothing else in flight here.
<!-- in-flight:end -->
