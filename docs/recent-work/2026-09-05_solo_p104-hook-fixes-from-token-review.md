# P104 — hook fixes from the token review

**Date:** 2026-09-05
**Agent:** solo
**Commits:** `3d528a4` (feature), `ea2fdb0` (review fixes), housekeeping follows

Operator: "fix all of this". The hook-level items: gate demand forbids Backlog filing and names the isolation flag; context block prints only non-default facts; a superseded legacy resume is never served; three default gates in this repo's config (ship-sop P27 carries the template). Found live: the push gate refused a scratchpad write whose heredoc mentioned a push verb; the matcher now ignores heredoc bodies. Three-agent gate (the new default set): the superseded guard's first cut was an unanchored line-1 match — a CRITICAL and a HIGH — fixed with the marker anchored on the first non-blank line and five resolver fixtures. User-scope ECC hooks cut from 35 entries to 9 the same session (settings.json backed up first; a first jq attempt dropped everything and was restored).
