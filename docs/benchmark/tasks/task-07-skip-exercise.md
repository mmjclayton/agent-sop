# Task 07: Add Skip Exercise Functionality

## Type
Feature (multi-file, requires data model knowledge, ceremony)

## Prompt (given to both agents verbatim)

> Add a "Skip Exercise" option to the workout logger. Users should be able to skip an entire exercise during a workout, and it should be clearly distinguishable from a partially completed exercise.
>
> Run all tests after your changes.

## Why This Is Hard Without SOP

The CLAUDE.md and agent-memory tell the SOP agent:
- WorkSet.status already supports "skipped" at the data level — this is a UI feature, not a schema change
- The exercise menu is in ExerciseCard.jsx (separate from WorkoutLogger)
- The data isolation pattern: all queries filter by req.userId via Program relation
- WorkoutLogger auto-saves via debounced loop — skip must work within that flow
- Brand voice: "direct, dry, precise. No exclamation marks."
- Backlog item P57 has full acceptance criteria including: confirmation prompt, "Skipped" label, unskip capability, and analytics compatibility

Without SOP, the agent must:
1. Discover that WorkSet.status already supports "skipped" (schema reading)
2. Find the right component for the exercise menu (ExerciseCard, not WorkoutLogger)
3. Figure out the API pattern (logSets endpoint or a new skip endpoint?)
4. Handle the UI states correctly (skipped vs partially complete vs not started)
5. Decide on confirmation UX without guidance

## Acceptance Criteria (for scoring, not given to agents)

1. "Skip Exercise" option exists in the exercise menu during a workout
2. Confirmation prompt shown before skip is applied
3. All sets for the exercise are marked as skipped (WorkSet.status = "skipped")
4. Exercise shows a "Skipped" label, not "partially complete"
5. Users can unskip during the same session
6. Server endpoint exists (or existing endpoint handles skip)
7. New server test for skip/unskip
8. New client test for skip UI
9. All existing tests pass
10. Brand voice followed in UI copy (no exclamation marks, direct language)

## Scoring Notes

- **Context awareness:** Does the agent discover WorkSet.status already supports "skipped" or does it try to add a schema change?
- **Pattern consistency:** Does it follow the existing API pattern (logSets) or create something inconsistent?
- **Completeness:** Does it add tests? Update the right components?
- **Code quality:** Is the skip/unskip flow clean? Does it handle the auto-save correctly?
