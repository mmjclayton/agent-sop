# Task 08: Add Copy Last and Next Buttons to the Keyboard Input Row

## Type
Feature (UI, requires understanding of workout logging flow and design system)

## Prompt (given to both agents verbatim)

> The keyboard input for logging sets only has a "Done" button. Add "Copy Last" and "Next" buttons alongside it. Copy Last should fill the field with the value from the previous set. Next should advance from weight to reps.
>
> Run all tests after your changes.

## Why This Is Hard Without SOP

The CLAUDE.md tells the SOP agent:
- 44px minimum touch targets on all interactive elements
- CSS tokens only, no hardcoded hex values
- Dark-first palette with specific accent colours
- Brand voice: direct, no hype
- Design system v2.0 conventions
- The keyboard input component is NumericKeypad (imported in WorkoutLogger)
- ExerciseCard handles per-set state, WorkoutLogger manages the global workout state

Without SOP, the agent must:
1. Find the NumericKeypad component (not obvious from the vague prompt)
2. Understand the set data flow: ExerciseCard manages individual set state, NumericKeypad is a shared input component
3. Figure out how to get "previous set" data (it's in the workout data structure, passed down from WorkoutLogger through ExerciseCard)
4. Design the button layout to match the existing design system (dark theme, accent colours, touch targets)
5. Handle the "Next" focus advancement between weight and reps inputs

## Acceptance Criteria (for scoring, not given to agents)

1. Three buttons on the keyboard row: Copy Last, Done, Next
2. Done button narrower than current full-width
3. All buttons meet 44px minimum touch target
4. Copy Last fills from previous set's value for the same field
5. Next advances focus from weight to reps
6. Buttons use design system tokens (--color-*, --radius-*, etc.)
7. Layout works on mobile (< 768px)
8. No exclamation marks or hype in button labels
9. All existing tests pass
10. At least one new test for Copy Last logic

## Scoring Notes

- **Context awareness:** Does the agent find NumericKeypad? Does it understand the set data flow?
- **Pattern consistency:** Does it follow the design system (tokens, touch targets, dark theme)?
- **Code quality:** Is the Copy Last logic clean? Does Next handle focus correctly?
- **Brand voice:** Are button labels direct and minimal ("Copy Last" not "Copy from Previous Set!")?
