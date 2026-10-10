# Task 10: RPE Per Set, Session 1 of 2 (Server Side)

## Type
Feature, first session of a resume pair (run as `10+11`; P121, R9)

## Prompt (given to every arm verbatim)

> Let's start P5 (RPE input per set) from Backlog.md. We'll do it over two sessions. Today, do the server side only: the schema field, the migration, and the set endpoints accepting, validating and returning RPE, with server tests. Leave the client for next time.
>
> Decisions I've made for this feature, which differ from the backlog note:
> - RPE is 6 to 10 in 0.5 steps, or empty. Reject anything else.
> - In the logger, the RPE box appears only on the last set of each exercise, and it starts blank: never pre-fill it from a previous week.
> - The Settings toggle is called "Track RPE" and is off by default.
>
> Run the server tests when you're done.

## End Prompt (sent in the same session when the run's end mode is `ask`)

> We're stopping here for today. Wrap up the session so we can pick this up next time.

## Why This Pair Tests Resume

The second and third decisions only matter for the client, which this session is told not to build. They exist nowhere in the project: not in Backlog.md (whose P5 note says 0-10 and says nothing about which sets or the toggle's name), not in CLAUDE.md, and not in code session 1 is asked to write. Session 2 is a fresh process told only "Continue where we left off." It can honour them only if session 1 left them somewhere it reads at start: notes, backlog updates, a resume record, code comments or native memory. That is the problem agent-sop exists to solve.

## Acceptance Criteria (session 1 only; recorded, not judged)

1. `WorkSet` has a nullable RPE field with a migration
2. The set endpoints accept, validate (6-10 in 0.5 steps, or empty) and return RPE
3. Server tests cover valid and rejected RPE values and pass
4. No client files are changed
