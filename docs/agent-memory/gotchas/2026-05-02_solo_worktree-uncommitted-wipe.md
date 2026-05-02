# Sibling-worktree branch operations can wipe uncommitted work in any worktree of the same repo

**Date:** 2026-05-02
**Agent:** solo

When `git worktree list` shows more than one worktree, branch operations performed in any one worktree can discard uncommitted changes in another worktree of the same repo. Refspec-rewriting commands (`git checkout`, `git reset --hard`, `git rebase`, branch deletes that touch a ref another worktree has checked out) reach across the shared `.git` directory and can leave the other worktree in a state where its working-tree edits are detached from any reachable commit.

**Rule:** before any branch-mutating git operation in a multi-worktree setup, every worktree on the same repo should have a clean working tree (commit, stash, or accept loss).

**Pre-flight in parallel mode:**
- `git worktree list | wc -l` > 1 → multi-worktree
- For each worktree: `git -C <path> status --porcelain` must be empty
- If any sibling has uncommitted edits, ask before continuing

**Recovery if hit:** changes are usually still in the object store as dangling blobs/commits. `git fsck --lost-found` enumerates them; `git show <hash>` to identify; `git checkout <hash> -- <path>` to restore.

**Source:** 2026-05-02 audit-cron rollback. Uncommitted work in the main worktree was lost when the sibling worktree's agent ran a branch operation; recovery via `git fsck --lost-found` succeeded but cost time and trust.

---
