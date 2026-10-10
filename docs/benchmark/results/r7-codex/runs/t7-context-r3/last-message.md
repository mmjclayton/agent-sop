Implemented exercise-level skip and same-session undo in the workout logger. Skips require confirmation, mark all sets in the active week as skipped, and appear as “Skipped” in the logger and workout history, distinct from partial completion.

**Verification:** `npm test` passed: 198 server tests and 289 client tests. `git diff --check` passed.

P57 is marked **In Progress** in the backlog because the project requires CI to be green before marking work shipped.