Added **Skip Exercise** to the workout logger’s exercise menu. It asks for confirmation, marks all sets for the active week as skipped, and offers **Unskip Exercise** so users can resume logging. Skipped exercises have a distinct badge in the logger and workout history, and aren’t counted as completed or unlogged sets.

Added an integration test for skipping and unskipping. Updated P57 in the backlog and agent memory.

**Verification:** `npm test` passed: 198 server tests and 289 client tests. `git diff --check` passed. The backlog remains **In Progress** pending CI and manual verification in a running app.