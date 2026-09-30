# A shipped tag on an unmerged branch needs the unmerged state recorded beside it

**Date:** 2026-09-30
**Agent:** solo

**Surprise:** the silent-failure reviewer blocked the session-end commit as HIGH: it removed the in-flight line and tagged P113 and P114 `[SHIPPED]` while the branch was unmerged, the hook was installed nowhere and replication had not started. No tracked file said so.

**Prior expectation:** the shipped tag is set in the PR that ships the item, as P110 to P112 were, so setting it on the branch is the normal close.

**Rule:** the tag can stay on the branch, because main accepts no direct commit and the tag can only reach main inside the PR. What must not happen is the in-flight line going while merge, install or replication are still open. Keep the in-flight line until each of those is done, name the PR number in it once the PR exists, and record `replication deferred (P<n>): <reason>` on the entry until the installed copies are refreshed. The reviewer accepted the tag once the unmerged state was recorded in three places.
