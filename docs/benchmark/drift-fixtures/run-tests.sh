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
VALIDATOR="$REPO_ROOT/scripts/validate-state-transitions.sh"

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

  if [ "$actual" = "$expected" ]; then
    echo "PASS: $name (exit $actual)"
    pass=$((pass + 1))
  else
    echo "FAIL: $name — expected exit $expected, got $actual"
    echo "  output: $output"
    fail=$((fail + 1))
    failed="$failed $name"
  fi
done

echo ""
echo "Results: $pass passed, $fail failed"
[ "$fail" -gt 0 ] && echo "Failed:$failed" && exit 1
exit 0
