# Independent review verified and its fixes shipped (P115); benchmark reopened (P116)

**Date:** 2026-10-10
**Agent:** solo
**Commits:** 01face9, 55d5864, d6880e0 and close-out, squash-merged as 5191fe0 (PR #38); merge record abc12c2 (PR #39)

An outside review of main at 61b8642 was checked claim by claim. Confirmed: the README's stale "awaiting merge" sentence, the stale `setup.sh` header, single-run April benchmarks, home-directory footprint, one-author history and branch clutter. Corrected: shellcheck was not clean outside `scripts/` (7 findings in `docs/benchmark/`), shell is 7,358 lines, and the 90-day archive rule was being followed with 6 items newly due. P115 fixed the README and setup usage, added a "What setup changes, and how to remove it" section, archived P60 to P65, cleared the lint and widened CI lint to every tracked `.sh` file. Three ship reviewers passed both rounds; their wording findings on the install section were fixed in 55d5864. P116 reopens the native-model comparison pilot (deferred at AUD 0 on 24 Sep) and waits on Matt's cost cap.

Post-merge: the four stale remote branches were deleted and the in-flight line records the merge. P116 waits on Matt's cost cap and billing choice.
