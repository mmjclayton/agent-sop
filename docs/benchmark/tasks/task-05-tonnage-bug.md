# Task 05: Fix the Tonnage Calculation Bug

## Type
Bug fix (vague prompt, requires data model knowledge)

## Prompt (given to both agents verbatim)

> There's a bug with the tonnage calculation for exercises that have "count twice" enabled. The numbers are wrong — roughly double what they should be. Find the bug and fix it.
>
> Run the relevant tests after your fix and make sure nothing breaks.

## Why This Is Hard Without SOP

The CLAUDE.md "Common Mistakes" section says:
- "Tonnage is derived, not stored. Never add a tonnage column."
- "ExerciseCard is its own file, not inside WorkoutLogger."
- The agent-memory.md records: "B1: formula applies doubling to both weight and reps independently ((w×2)×(r×2)) instead of per-side sum ((w×r)×2). Display-only — tonnage is derived, not stored."

Without SOP, the agent must:
1. Figure out where tonnage is calculated (could search blindly across client and server)
2. Understand the count-twice data model (two independent booleans: countTwiceWeight, countTwiceReps)
3. Find the formula in ExerciseCard.jsx (1211 lines) or WorkoutLogger.jsx
4. Understand the correct formula: when BOTH are true, multiply once by 2, not each independently

## Acceptance Criteria (for scoring, not given to agents)

1. The tonnage formula is corrected: when both countTwiceWeight and countTwiceReps are true, result is (weight × reps × 2), not (weight × 2) × (reps × 2)
2. When only one flag is true, its respective value is doubled (this should already be correct)
3. Fix is in the client code (tonnage is display-only, derived at render time)
4. No new database columns or migrations added
5. Existing tests pass
6. Ideally, a new test is added for the corrected formula

## Scoring Notes

- **Context awareness:** Does the agent find ExerciseCard.jsx (not WorkoutLogger) on the first try?
- **Pattern consistency:** Does the agent understand tonnage is derived, not stored?
- **Correctness:** Is the formula actually fixed? Edge cases: only weight doubled, only reps doubled, both doubled, neither doubled.
