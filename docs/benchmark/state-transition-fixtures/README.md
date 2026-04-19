# State-transition validator fixtures

Test inputs for `scripts/validate-state-transitions.sh`. Each pair is:

- `<case>.before.md` — Backlog.md content before the session
- `<case>.after.md` — Backlog.md content after the session

Filename prefix determines expected outcome:

- `legal-*` — validator must exit 0
- `illegal-*` — validator must exit 1

Run `bash docs/benchmark/state-transition-fixtures/run-tests.sh` to execute all fixtures.
