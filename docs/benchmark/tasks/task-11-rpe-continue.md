# Task 11: Continue Where We Left Off (RPE, Session 2 of 2)

## Type
Feature, second session of a resume pair (run after task 10 in the same project and home; P121, R9)

## Prompt (given to every arm verbatim, in a new session after task 10)

> Continue where we left off.

## Target
`client/src/components/ExerciseCard.jsx`

## What Session 2 Has to Recover

The prompt names no item, file or decision. Session 1 built the server side of P5 and was given three decisions in its prompt; two of them (RPE only on the last set and blank by default; a "Track RPE" toggle, off by default) apply only to the client and are written nowhere in the project unless session 1 wrote them down. The P5 backlog note says a 0-10 scale and nothing about which sets show RPE or the toggle's name.

## Primary Result (fixed before any run)

The decision score: the mean of criteria 1, 2 and 3 below. It measures whether session 2 carried the session-1 decisions forward. Criterion 2 (blank by default) is what many implementations do anyway, so the score has a floor above zero in every arm; criteria 1 and 3 carry most of the spread.

## Known Exposure

Session 1's prompt also exists on disk in every arm: in Codex's own transcripts under the isolated home (`~/.codex/sessions/`) and in the harness's `session-1/` folder beside the project. An agent that searches outside the project can find the decisions without any resume record. The harness flags such runs (`read_session_records` in result.json); report them separately.

## Acceptance Criteria (for scoring, not given to agents)

1. The workout logger shows an RPE input only on the last set of each exercise, not on every set
2. The RPE input starts blank; it is never pre-filled from a previous week or an earlier set
3. A Settings toggle labelled "Track RPE", off by default, controls whether the RPE input appears
4. A logged RPE value is sent to the server and saved with the set
5. The Previous column shows a logged RPE as "@ value" (for example "72kg x 12 @ 8")
6. The client accepts only 6 to 10 in 0.5 steps, or empty, matching the server
7. The server-side RPE work from session 1 is kept: its field, migration and validation are not removed, duplicated or rebuilt
8. Existing tests pass, and a client test covers the RPE input
