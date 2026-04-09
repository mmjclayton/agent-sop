# Task 03: Add Dynamic Page Titles

## Type
Feature

## Prompt (given to both agents verbatim)

> LOADOUT has no dynamic page titles. The browser tab always shows the default from `index.html` regardless of which view is active.
>
> Add dynamic page titles that update when the user navigates between views. The format should be `{View Name} — LOADOUT` (using an em dash). When on the default/home view, just show `LOADOUT`.
>
> The navigation state is managed in `client/src/App.jsx` via a `currentView` state variable. The view keys and labels are defined in the `NAV_ITEMS` array at the top of that file.
>
> Do not install any external routing library. Use `document.title` in a `useEffect`.
>
> Run `npm run test:client` after your changes and fix any failures.

## Acceptance Criteria

1. Browser tab title updates when switching views
2. Format: `{View Name} — LOADOUT` (em dash separator)
3. Default/home view shows just `LOADOUT`
4. Implementation uses `useEffect` and `document.title` (no external dependencies)
5. Title updates for all views in NAV_ITEMS
6. All client tests pass
7. Changes limited to `client/src/App.jsx` (and optionally `client/index.html` for the default title)

## Scoring Notes

- **Pattern consistency:** Does the agent follow the existing useState/useEffect patterns in App.jsx?
- **Context awareness:** Does the agent discover the NAV_ITEMS array and use it rather than hardcoding view names?
- **Code quality:** Is the useEffect properly dependent on currentView? Is cleanup handled?
