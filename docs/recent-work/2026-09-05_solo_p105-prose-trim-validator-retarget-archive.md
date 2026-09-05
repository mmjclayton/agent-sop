# P105 — prose trim, validator retarget, Backlog archive

**Date:** 2026-09-05
**Agent:** solo
**Commits:** `59b4ae5` (trim, retarget, archive), `465dbdf` (review fixes), `1bff70d` (post-gate SIGPIPE fix), housekeeping follows

Operator: "fix all of this", on the five-agent token review. The SOP now keeps what a session reads: core doc ~110 lines, `/update-sop` seven steps each a script call or a checkable product, `/restart-sop` and `/finish` a page each, templates without the Definition of Done or checklist copies, a derived priority block, closed Backlog items archived after 90 days, and the review citation on the entry the validator reads. Resolves P77 and P90; P82 and P89 moot.

**Review.** Three default gates, all BLOCK at the first commit. The validator's new entry extraction ran to end of file and missed some heading shapes (silent-failure); the citation regex allowed traversal and matched anywhere (security); the archive script misread quoted tags and fenced headings and wrote Backlog.md first (both); the coherence gate found five surfaces the trim had not updated. All fixed with discriminating fixtures; 106 cases across six suites. The three gate runs cost about 555k tokens and found five CRITICALs; the two agents dropped from the default set had found nothing in four runs on this repo.

**Consumers.** Pristine-replica files synced to hst-tracker, ship-sop, Resonate and Meaningful where the consumer copy matched a past upstream version; the three opportunity-scan worktrees are on feature branches and take the sync in their own sessions.
