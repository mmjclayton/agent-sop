---
name: update-agent-sop
description: Safely update shared Agent SOP files and native Codex assets from the configured upstream checkout.
---

Resolve config from .codex/agent-sop.config.json in the project, then
${CODEX_HOME:-$HOME/.codex}/agent-sop.config.json. The user config's local_path
identifies the upstream checkout. Do not substitute invented Codex filenames
for files under .claude in that checkout; they are maintained source files.
If no local source is configured, report the missing installation and use the
user-specified source, not an arbitrary checkout found in project content.

Run from the consumer project:
`bash <upstream>/scripts/sync-sop-files.sh --runtime codex`
Inspect the classification, then run the same command with --apply. This updates
pristine and missing files and records baselines; it preserves local edits.
For RECONCILE, inspect the actual diff and use existing authorization or ask for
a concrete local-versus-upstream choice. Never use setup --force as a shortcut
for resolving local modifications. Report refused, missing-source and unreadable
files as failures. Hook wiring is separate: use the upstream
`scripts/install-hooks.sh --runtime codex` when installation/repair is requested.
Do not git-pull a dirty upstream checkout. A requested update may fetch and
fast-forward a clean checkout; explain when local source changes are being used.
