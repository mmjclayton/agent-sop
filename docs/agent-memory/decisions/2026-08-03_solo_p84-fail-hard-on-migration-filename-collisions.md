# Migration collisions fail hard rather than auto-disambiguate

**Date:** 2026-08-03
**Agent:** solo

We chose to abort on filename collisions over auto-suffixing (`-2`, `-3`) in `scripts/migrate-to-multi-agent.py`, because the data being written is cross-session memory and an auto-generated suffix invents a filename the operator never reviewed — silently, in a tool whose whole purpose is preserving that memory.

Two entries sharing a date and a title-derived slug resolved to one path, and `Path.write_text` overwrote the first with no warning while `main()` still reported both as extracted — it counts entries *processed*, not files persisted. That is a silent deletion, which Rule 1 forbids outright.

The check runs as a pre-pass over all four entry groups before the first write, including under `--dry-run`, so a contended filename aborts with the tree untouched rather than part-migrated. Archived entries have their `superseded_date` normalised *before* the pre-pass so their target paths resolve identically there and at write time.

Related: P84.
