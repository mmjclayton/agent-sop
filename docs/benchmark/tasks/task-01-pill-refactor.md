# Task 01: Migrate TimeFilter to Pill Component

## Type
Refactor

## Prompt (given to both agents verbatim)

> The `TimeFilter` component at `client/src/components/TimeFilter.jsx` uses a hand-rolled `time-filter-btn` CSS class for its preset buttons. A unified `Pill` component already exists at `client/src/components/Pill.jsx`. Refactor TimeFilter to use the Pill component instead of raw buttons with the `time-filter-btn` class.
>
> After the refactor, remove the `.time-filter-btn` CSS class from `client/src/index.css` if it is no longer used anywhere.
>
> Do not change any behaviour. The active state, click handling, and custom date range should work exactly as before.
>
> Run `npm run test:client` after your changes and fix any failures.

## Acceptance Criteria

1. `TimeFilter.jsx` imports and renders `Pill` instead of `<button className="time-filter-btn ...">`
2. Active state is passed via `Pill`'s `active` prop
3. Click handler is passed via `Pill`'s `onClick` prop
4. `.time-filter-btn` CSS class is removed from `index.css` (if no other file uses it)
5. Custom date range inputs still render when "Custom" is selected
6. All client tests pass (`npm run test:client`)
7. No other files modified beyond TimeFilter.jsx and index.css

## Scoring Notes

- **Pattern consistency:** Does the agent discover and use Pill's existing API (variant, size, ariaLabel, ariaPressed)?
- **Context awareness:** Does the agent check whether `.time-filter-btn` is used elsewhere before removing it?
- **File hygiene:** Does the agent avoid modifying unrelated files?
