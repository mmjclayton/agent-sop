#!/usr/bin/env bash
#
# Test harness for `validate-state-transitions.sh --check-drift`.
#
# Fixtures live alongside as pairs: <case>.resume.md + <case>.commits.txt.
# Filename prefix determines expected exit:
#   legal-*   → 0
#   illegal-* → 1
#
# Run from repo root: bash docs/benchmark/drift-fixtures/run-tests.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# Overridable so the suite can be pointed at a deliberately broken validator to
# prove the fixtures actually discriminate — a suite that passes against a stub
# is not testing anything. Matches state-transition-fixtures/run-tests.sh:19.
VALIDATOR="${VALIDATOR:-$REPO_ROOT/scripts/validate-state-transitions.sh}"

if [ ! -x "$VALIDATOR" ]; then
  echo "Validator not executable: $VALIDATOR" >&2
  exit 2
fi

pass=0
fail=0
failed=""

for resume in "$SCRIPT_DIR"/*.resume.md; do
  [ -f "$resume" ] || continue
  base="${resume%.resume.md}"
  commits="${base}.commits.txt"
  name="$(basename "$base")"

  if [ ! -f "$commits" ]; then
    echo "SKIP: missing .commits.txt for $name"
    continue
  fi

  case "$name" in
    legal-*) expected=0 ;;
    illegal-*) expected=1 ;;
    *) echo "SKIP: $name has no legal-/illegal- prefix"; continue ;;
  esac

  # Per-fixture session size (for threshold-skip tests) via sidecar
  # <base>.session-size (format: "loc files", e.g. "10 1"). Absent = over
  # threshold so the drift check fires.
  session_size_file="${base}.session-size"
  if [ -f "$session_size_file" ]; then
    read -r fixture_loc fixture_files < "$session_size_file"
  else
    fixture_loc=500
    fixture_files=10
  fi

  output=$(bash "$VALIDATOR" --check-drift \
    --drift-resume-file "$resume" \
    --drift-commits-file "$commits" \
    --drift-session-loc "$fixture_loc" \
    --drift-session-files "$fixture_files" \
    --drift-threshold-loc 50 \
    --drift-threshold-files 3 2>&1)
  actual=$?

  # Optional stdout assertion. When `<base>.expect-stdout` exists, every line in
  # it must appear somewhere in the validator's output.
  #
  # Exit-code-only assertions cannot distinguish a reported failure from a
  # silent one. P73 was exactly that: a `grep`/`pipefail`/`errexit` interaction
  # killed the script before its BLOCK message printed, so operators saw a bare
  # non-zero exit with no explanation — and every fixture still passed, because
  # the exit code was non-zero either way. The `--check-drift` path this harness
  # covers has the same shape and had no such assertion until now. When a
  # check's product is a diagnostic message, assert on the message.
  #
  # `|| [ -n "$expect_line" ]` keeps the final line when the expectation file
  # has no trailing newline — without it, `read` returns non-zero on the last
  # line and silently drops the very assertion the fixture was written for.
  stdout_ok=1
  missing_line=""
  if [ -f "${base}.expect-stdout" ]; then
    while IFS= read -r expect_line || [ -n "$expect_line" ]; do
      [ -z "$expect_line" ] && continue
      case "$output" in
        *"$expect_line"*) ;;
        *) stdout_ok=0; missing_line="$expect_line"; break ;;
      esac
    done < "${base}.expect-stdout"
  fi

  if [ "$actual" = "$expected" ] && [ "$stdout_ok" = "1" ]; then
    echo "PASS: $name (exit $actual)"
    pass=$((pass + 1))
  else
    if [ "$actual" != "$expected" ]; then
      echo "FAIL: $name — expected exit $expected, got $actual"
    else
      echo "FAIL: $name — exit $actual correct, but expected stdout line missing: $missing_line"
    fi
    echo "  output: $output"
    fail=$((fail + 1))
    failed="$failed $name"
  fi
done

echo ""
echo "Results: $pass passed, $fail failed"
[ "$fail" -gt 0 ] && echo "Failed:$failed" && exit 1
exit 0
