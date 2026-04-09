# Task 04: Write Utility Function Tests for server/src/utils.js

## Type
Test writing

## Prompt (given to both agents verbatim)

> The file `server/src/utils.js` contains utility functions used across the server. Some are tested, some are not.
>
> Review `server/src/utils.js` and identify any exported functions that lack test coverage in `server/__tests__/utils.test.js`. Write tests for the uncovered functions.
>
> If all functions are already covered, expand the existing tests with additional edge cases:
> - Null/undefined inputs
> - Empty strings or empty arrays
> - Boundary values
> - Type coercion edge cases
>
> Use Jest (the server's test runner). Follow the existing patterns in `server/__tests__/utils.test.js`.
>
> Run `npm run test:server` after writing the tests and fix any failures.

## Acceptance Criteria

1. New tests added to `server/__tests__/utils.test.js`
2. Tests cover previously uncovered functions OR meaningful edge cases for covered functions
3. Tests use Jest (`describe`, `it`/`test`, `expect`)
4. All tests pass
5. No production code modified
6. Test descriptions are clear and descriptive

## Scoring Notes

- **Context awareness:** Does the agent compare utils.js exports against existing test coverage before writing?
- **Completeness:** Does it find the actual gaps rather than duplicating existing tests?
- **Pattern consistency:** Does it match the existing test file structure (describe grouping, naming)?
- **Code quality:** Are edge cases meaningful (not just filler)?
