# P105: the SOP keeps only what a later session reads, and the validator reads the Backlog entry

**Date:** 2026-09-05
**Agent:** solo

We chose to cut the SOP to the artefacts with a measured reader over keeping the full ceremony, because the consumer-repo lens showed feature-map.md with zero readers, Batch Log lines read by the validator alone, decision-file bodies read five times in 267 and session-record bodies three or four times in 181, while the resume snapshot, gotchas, reviews, open Backlog items and rollup titles were read every session. What has a reader stays; what does not is gone, with the P-number of the incident that motivated each surviving rule named inline so the reason travels with the rule.

We chose the Backlog entry as the single place the review citation lives over the Batch Log because it is the file every session already edits to close an item, and one place cannot disagree with itself. The cost surfaced immediately: the entry is also the easiest file to write a false citation into, so the citation is now a labelled line, outside code fences, naming a bare filename under docs/reviews/, bounded to its own entry, and the path must exist.

We chose to archive closed items out of Backlog.md rather than leave them, because closed items were 67 to 89 percent of the file in four repos and the instruction "never load the whole file" was the only thing standing between a session and 50k to 170k tokens.
