# Stale ship-sop reviewer runner removed from agent-sop (P117)

**Date:** 2026-10-10
**Agent:** solo
**Commits:** d6bd141 and close-out, on `fix/p117-stale-codex-runner`

Handed over from the ship-sop session's 10 Oct review follow-up. agent-sop carried `scripts/codex-review.sh`, a P107-era copy of ship-sop's Codex reviewer runner missing the timeout, process-group kill, retained evidence and telemetry ship-sop has since added. agent-sop's `install-codex.sh` installs that file only when it runs as ship-sop, so the copy was never installed from here, and the runner installed on this machine already matched ship-sop's. The copy is deleted, `install-codex.sh` is synced byte-for-byte with ship-sop's (it lacked the `codex-usage.sh` lines), and the Codex fixture asserts an agent-sop install writes nothing under `~/.codex/scripts/ship-sop`. Three reviewers passed in one round with five LOWs accepted or deferred to ship-sop; receipt `docs/reviews/20261010-141500-ship-auto.json`. ship-sop P23's runner drift is resolved from this side.
