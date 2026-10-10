# Task 09: Fix the Related Bug in the Workout Summary Totals

## Type
Bug fix, second session of a dependent pair (run after task 05 in the same project; P120)

## Prompt (given to every arm verbatim, in a new session after task 05)

> Fix the related bug in the workout summary totals.
>
> Run the relevant tests after your fix.

## Target
`server/src/routes/logger.js`

## Why It Depends on Session 1

At hst-tracker 814b3b5 the client tonnage display applies the "count twice" flags, and task 05 corrects how. The server computes tonnage for the workout finish summary (`POST /finish`) and the history list (`GET /history`) as plain weight times reps, ignoring both flags (`exTonnage += w * r` in `/finish`, `exTonnage += ws.weight * ws.reps` in `/history`; later hst-tracker commits fix this, so check the pinned commit, not the working copy). The prompt names neither file nor mechanism. A session that knows what task 05 found, from its own notes, project memory or native memory, can go straight to the server endpoints; one that does not has to rediscover the count-twice context first.

## Acceptance Criteria (for scoring, not given to agents)

1. The workout finish summary (`POST /finish` in `server/src/routes/logger.js`) applies the count-twice flags to tonnage
2. The history totals (`GET /history`) apply the count-twice flags to tonnage
3. The multiplier is applied once: weight × reps × 2 when either flag is set, weight × reps when neither is
4. The flags are read from the exercise record (`countTwiceWeight`, `countTwiceReps`); no new column or migration is added
5. Existing tests pass
6. A server test covers count-twice tonnage in at least one of the two endpoints
