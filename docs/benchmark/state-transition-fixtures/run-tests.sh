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
  if [ "$expected" = "0" ]; then
    # Stub phase file with all possible P-numbers referenced so the Batch Log
    # check passes for any legal [SHIPPED] transition.
    cat > "$tmp/docs/build-plans/phase-test.md" <<EOF
# Test phase
## Batch Log
- 2026-04-19 P100 P101 P102 P103 P104 P105 P106 P107 P108 P109
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
