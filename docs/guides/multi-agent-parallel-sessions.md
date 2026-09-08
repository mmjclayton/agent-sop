# Parallel sessions on one repository

SOP-Version: 2026-09-08

The active mechanics for Claude Code and Codex. Replaces the archived guide in
`archive/multi-agent-parallel-sessions-20260908.md`. The shared process entrypoint
is `docs/sop/multi-agent.md`; coordinator context routing is a separate concern.

## 1. Agent identity

Call `scripts/resolve-resume-path.sh --agent-id`; do not copy a shell implementation.
Precedence: AGENT_SOP_AGENT_ID, CLAUDE_AGENT_ID, .sop-agent-id, main-worktree solo,
then linked-worktree path hash. Identifiers allow letters, digits, underscore and
hyphen. The main identity does not change with worktree count. Hash failure stops
resolution. Stored multi_agent/agent_id_override config fields are not resolver inputs.

## 2. Files and ownership

One writer per worktree. Start another writer with `git worktree add` on a unique
branch. Use the runtime-installed `sop-worktree-claim.sh claim SESSION TASK PATH...`
from that worktree. Claims reject duplicate tasks and overlapping source paths
across linked worktrees. They are cooperative, local and persistent until released.
Omitting paths claims the whole repository. Read-only reviewers do not claim writes.

The context hook exposes recently observed sessions, explicit claims and bounded
in-flight entries from local worktrees. Presence expires after 30 minutes; claims
require explicit release. A malformed registry is unavailable, never empty.

## 3. Derived records

Write decisions, gotchas and recent-work as separate files with agent identity.
Only the coordinating session integrates shared Backlog and generated rollups.
Re-run refresh-rollup/refresh-in-flight after merging source entries. Deterministic
output does not make concurrent writes to a shared document safe.

## 4. Resume and migration

Always use the resolver for read and write targets. Storage uses a full root digest.
Inspect `--legacy-dir` and confirm ownership before `--migrate-legacy`; old path
slugs can collide. Migration copies snapshots and rejects conflicting destinations.
The reader can recover a migrated older main-worktree hash snapshot. A repository
move still requires explicit migration. Do not guess machine-local memory paths.
If solo and the old main-path hash contain different snapshots, migration and read
stop for reconciliation. Merge the relevant content into solo, preserve both
originals in an archive, and remove the archived hash from the active memory directory.

## 5. Handoff

Record task purpose, acceptance criteria, relevant paths, current commit, next
step, blockers and non-obvious discoveries. Search relevant invariants before
restricting by recency. Refresh relevant context when HEAD, claims or peer presence
change. Finish with `sop-worktree-claim.sh release SESSION` using the recorded owner.
After an interruption, inspect uncommitted work before reassigning the claim.

## 6. Backlog and merges

P-numbers are sequential and can collide on independent branches. The old Step 2a
fetch-and-compare pre-check was retired. At integration, inspect both entries and
renumber a genuinely new collision together with its references. Serialise merges
and re-run relevant tests on the integrated tree. Claims reduce duplicate task work;
they do not allocate global P-numbers or replace Git conflict resolution.

## 7. Git boundaries

Linked worktrees have separate working files, index and HEAD but share refs.
Ordinary reset in one does not normally erase another's edits. Verify the command's
target worktree and coordinate shared-ref operations. Unstaged edits may never have
entered Git's object store and must not be assumed recoverable there.

## 8. Limits

The registry does not synchronise separate clones or machines, and cannot prevent
an agent or terminal that ignores claims from writing. Use a shared task owner
outside this local registry for distributed work. Do not mistake a prompt naming
a worktree for enforced reviewer isolation: use the runtime's isolated review path.
