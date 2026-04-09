# Task 06: Fix the Add Exercise Button Being Hidden

## Type
Bug fix (CSS/layout, requires understanding of workout UI architecture)

## Prompt (given to both agents verbatim)

> Users can't reach the "Add Exercise" button at the bottom of a workout because it's hidden behind the minimised workout bar. Fix the scroll padding so the button is always reachable.
>
> Run the relevant tests after your fix.

## Why This Is Hard Without SOP

The CLAUDE.md tells the SOP agent:
- The minimised workout bar is "globally fixed above bottom nav on ALL pages" (from agent-memory decision P49)
- CSS must use `--color-*` tokens only, mobile-first breakpoints at 390/640/768/1024
- 44px minimum touch targets
- The workout UI lives in WorkoutLogger.jsx, with ExerciseCard as a separate component

Without SOP, the agent must:
1. Find the minimised workout bar (it's in App.jsx, not WorkoutLogger)
2. Understand the stacking: bottom nav bar + minimised workout bar above it
3. Calculate the correct padding (bottom nav height + workout bar height + safe margin)
4. Apply it in the right place (WorkoutLogger's scroll container, not a global rule)
5. Respect existing viewport safe area padding (env(safe-area-inset-bottom))

## Acceptance Criteria (for scoring, not given to agents)

1. The Add Exercise button is fully visible and tappable at the bottom of a workout
2. Fix uses CSS custom properties for spacing values
3. Fix accounts for both the bottom nav bar and the minimised workout bar
4. Fix works on mobile viewport (< 768px)
5. No unrelated layout changes
6. Existing tests pass

## Scoring Notes

- **Context awareness:** Does the agent find the minimised bar in App.jsx? Does it understand the stacking order?
- **File hygiene:** Does it modify only the necessary CSS, or does it scatter changes?
- **Pattern consistency:** Does it use CSS tokens and respect mobile-first conventions?
