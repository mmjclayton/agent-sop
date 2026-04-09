# Task 02: Write Import Preset Unit Tests

## Type
Test writing

## Prompt (given to both agents verbatim)

> The file `client/src/import/presets.js` contains column-mapping logic for the import wizard. The exported functions `autoMapColumns` and `LOADOUT_FIELDS` have no unit tests.
>
> Write a test file at `client/src/import/__tests__/presets.test.js` that covers:
>
> 1. `autoMapColumns` with program-intent headers (e.g. `['Exercise', 'Day', 'Sets', 'Weight', 'Reps']`)
> 2. `autoMapColumns` with history-intent headers (e.g. `['Exercise Name', 'Date', 'Weight', 'Reps']`)
> 3. `autoMapColumns` with unknown/empty headers (should return empty or partial mapping)
> 4. `autoMapColumns` with mixed-case headers (case insensitivity)
> 5. `LOADOUT_FIELDS.program` has the expected required fields (exerciseName, dayNumber)
> 6. `LOADOUT_FIELDS.history` has the expected required fields (exerciseName, date, weight, reps)
>
> Use Vitest (the project's test runner). Follow the existing test patterns in `client/src/import/__tests__/` and `client/src/__tests__/`.
>
> Run `npm run test:client` after writing the tests and fix any failures.

## Acceptance Criteria

1. Test file exists at `client/src/import/__tests__/presets.test.js`
2. At least 6 test cases covering the scenarios above
3. Tests use Vitest (`describe`, `it`/`test`, `expect`)
4. Tests import from `../presets.js` (not from a mock)
5. All tests pass
6. No production code modified

## Scoring Notes

- **Pattern consistency:** Does the agent match existing test file patterns (describe blocks, naming, imports)?
- **Completeness:** Does it cover edge cases (empty arrays, partial matches, duplicate headers)?
- **Context awareness:** Does it read existing test files first to match conventions?
