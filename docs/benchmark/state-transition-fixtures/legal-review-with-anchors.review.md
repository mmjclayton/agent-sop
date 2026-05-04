# Review — P999 (fixture)

## Summary

Diff touches `scripts/foo.sh` and adds a new helper.

## Findings

Severity: HIGH

`foo.sh:42` calls `processOrder` without checking the return value. Add `|| return 1` after the call, or surface the exit code in the caller.

Severity: LOW

Inline comment on `foo.sh:18` restates what the next line does. Drop it.
