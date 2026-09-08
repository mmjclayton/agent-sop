# agent-sop — Codex

**Project type:** code

Read `CLAUDE.md` for shared project conventions and document dispatch.
Read `docs/sop/codex.md` for the Codex runtime adapter. Both runtimes use
one Backlog, SOP, memory, validators and review reports.

Codex workflows live in `.agents/skills/`, reviewers in `.codex/agents/`.
Use `restart-sop`, `update-sop` and `ship` for the corresponding workflows.
Reviewers use a separate checkout and read-only sandbox, return findings,
and never write into the working checkout. The parent writes reports.

Run all `docs/benchmark/*-fixtures/run-tests.sh` suites after script changes.
