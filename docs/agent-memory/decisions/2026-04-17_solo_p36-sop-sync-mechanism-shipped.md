# P36 — SOP sync mechanism shipped

**Date:** 2026-04-17
**Agent:** solo

P36 — SOP sync mechanism shipped. Distribution model is copy-based (not symlinks/submodules). `/update-agent-sop` command (user-scope) pulls from local path first, GitHub raw fallback. Three-way diff per file using SHA-256 baselines stored in `~/.claude/agent-sop.config.json`. Never force-overwrites locally modified files. `setup.sh` now distributes the full pristine-replica surface (17 files): SOP docs + guides project-scope, slash commands + reference agents user-scope. `/restart-sop` gained a Step 0 staleness check (one-line warning, non-blocking). Version markers placed as HTML comment (plain markdown) or `sop_version:` YAML field (files with frontmatter) — advisory only, SHA is authority. First-run bootstrap captures upstream as baseline; pre-existing local divergence surfaces immediately. GitHub repo slug locked as `mmjclayton/agent-sop`.
