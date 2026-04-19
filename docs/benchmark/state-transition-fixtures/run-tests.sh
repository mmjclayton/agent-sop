#!/usr/bin/env bash
#
# Test harness for scripts/validate-state-transitions.sh.
#
# Iterates every *.before.md / *.after.md pair in this directory and checks
# the validator's exit code against the filename prefix:
#   legal-*   → expect exit 0
#   illegal-* → expect exit 1
#
# Run from repo root: bash docs/benchmark/state-transition-fixtures/run-tests.sh

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
failed_cases=""

for before in "$SCRIPT_DIR"/*.before.md; do
  [ -f "$before" ] || continue
  base="${before%.before.md}"
  after="${base}.after.md"
  name="$(basename "$base")"

  if [ ! -f "$after" ]; then
    echo "SKIP: missing .after.md for $name"
    continue
  fi

  case "$name" in
    legal-*) expected=0 ;;
    illegal-*) expected=1 ;;
    *) echo "SKIP: $name has no legal-/illegal- prefix"; continue ;;
  esac

  # Run the validator in fixture mode — no git, no phase files. The
  # Batch-Log-reference check needs real phase files; fixtures that test
  # [SHIPPED] transitions must work around this by including a phase file
  # path grep will match, OR we accept that fixture-mode [SHIPPED] tests
  # only cover the transition graph, not the batch-log requirement.
  #
  # For these v1 fixtures, run from a scratch temp dir so the validator's
  # glob `docs/build-plans/phase-*.md` either matches a stub or gracefully
  # no-ops. We create a minimal phase stub in temp for legal-*.
  tmp=$(mktemp -d)
  mkdir -p "$tmp/docs/build-plans"
  # Phase stub: a fixture-specific `<base>.phase-stub.md` wins if present;
  # otherwise default to a stub that names every possible fixture P-number
  # with a docs/reviews/ citation so legal [Feature]/[Refactor] ships pass.
  # Illegal fixtures that need a phase file (e.g. to isolate the new P44
  # review-path check from the prior no-batch-log check) ship their own stub.
  if [ -f "${base}.phase-stub.md" ]; then
    cp "${base}.phase-stub.md" "$tmp/docs/build-plans/phase-test.md"
  elif [ "$expected" = "0" ]; then
    cat > "$tmp/docs/build-plans/phase-test.md" <<EOF
# Test phase
## Batch Log
- 2026-04-19 P100 docs/reviews/fixture_P100.md
- 2026-04-19 P101 docs/reviews/fixture_P101.md
- 2026-04-19 P102 docs/reviews/fixture_P102.md
- 2026-04-19 P103 docs/reviews/fixture_P103.md
- 2026-04-19 P104 docs/reviews/fixture_P104.md
- 2026-04-19 P105 docs/reviews/fixture_P105.md
- 2026-04-19 P106 docs/reviews/fixture_P106.md
- 2026-04-19 P107 docs/reviews/fixture_P107.md
- 2026-04-19 P108 docs/reviews/fixture_P108.md
- 2026-04-19 P109 docs/reviews/fixture_P109.md
EOF
  fi
  # Copy fixtures into place so relative paths resolve
  cp "$before" "$tmp/before.md"
  cp "$after" "$tmp/after.md"

  output=$(cd "$tmp" && bash "$VALIDATOR" --before-file before.md --after-file after.md 2>&1)
  actual=$?

  if [ "$actual" = "$expected" ]; then
    echo "PASS: $name (exit $actual)"
    pass=$((pass + 1))
  else
    echo "FAIL: $name — expected exit $expected, got $actual"
    echo "  output: $output"
    fail=$((fail + 1))
    failed_cases="$failed_cases $name"
  fi
  rm -rf "$tmp"
done

echo ""
echo "Results: $pass passed, $fail failed"
[ "$fail" -gt 0 ] && echo "Failed: $failed_cases" && exit 1
exit 0
