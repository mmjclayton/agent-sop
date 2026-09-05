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
# Overridable so a fixture can be run against an older copy of the validator to
# prove it actually catches the regression it was written for. A fixture that
# passes against both the broken and fixed validator is not covering anything.
VALIDATOR="${VALIDATOR:-$REPO_ROOT/scripts/validate-state-transitions.sh}"

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

  # Run the validator in fixture mode — no git. Legal ships of a Feature or
  # Refactor cite docs/reviews/fixture_P<n>.md on the entry (P105 moved the
  # citation from the Batch Log to the Backlog entry); the harness creates
  # those files so the P95 existence check has something real to find.
  tmp=$(mktemp -d)
  mkdir -p "$tmp/docs/reviews"
  for n in 100 101 102 103 104 105 106 107 108 109; do
    cat > "$tmp/docs/reviews/fixture_P${n}.md" <<REVIEW
# Review — fixture P${n}
## Findings
- \`fixture.sh:1\` synthetic anchor so --assert-review has something concrete
REVIEW
  done
  # Copy fixtures into place so relative paths resolve
  cp "$before" "$tmp/before.md"
  cp "$after" "$tmp/after.md"

  # Optional sidecar: <base>.self-mod-changed.txt supplies the changed-file list
  # for the Step 1b trigger (b) check (P87). Fixtures run in a temp dir with no
  # git history, so the real path detection cannot fire there.
  selfmod_args=""
  if [ -f "${base}.self-mod-changed.txt" ]; then
    cp "${base}.self-mod-changed.txt" "$tmp/self-mod-changed.txt"
    selfmod_args="--self-mod-changed-file self-mod-changed.txt"
  fi

  output=$(cd "$tmp" && bash "$VALIDATOR" --before-file before.md --after-file after.md $selfmod_args 2>&1)
  actual=$?

  # Optional stdout assertion. When `<base>.expect-stdout` exists, every line in
  # it must appear somewhere in the validator's output.
  #
  # Exit-code-only assertions cannot distinguish a reported failure from a
  # silent one. P73 was exactly that: a `grep`/`pipefail`/`errexit` interaction
  # killed the script before its BLOCK message printed, so operators saw a bare
  # non-zero exit with no explanation — and every fixture still passed, because
  # the exit code was non-zero either way. When a check's product is a
  # diagnostic message, assert on the message.
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
  elif [ "$actual" = "$expected" ]; then
    echo "FAIL: $name — exit $actual correct, but expected output missing: \"$missing_line\""
    echo "  output: $output"
    fail=$((fail + 1))
    failed_cases="$failed_cases $name"
  else
    echo "FAIL: $name — expected exit $expected, got $actual"
    echo "  output: $output"
    fail=$((fail + 1))
    failed_cases="$failed_cases $name"
  fi
  rm -rf "$tmp"
done

# --------------------------------------------------------------------------
# P55: review-substance fixtures (`*.review.md`).
#
# Iterates every *.review.md file in this directory and runs the validator's
# --assert-review mode against it. Filename prefix dictates expected exit:
#   legal-review-*   → expect exit 0  (passes substance + anchor checks)
#   illegal-review-* → expect exit 1  (sycophantic / no concrete anchor)
# --------------------------------------------------------------------------
for review in "$SCRIPT_DIR"/*.review.md; do
  [ -f "$review" ] || continue
  name="$(basename "${review%.review.md}")"

  case "$name" in
    legal-review-*) expected=0 ;;
    illegal-review-*) expected=1 ;;
    *) echo "SKIP: $name has no legal-review-/illegal-review- prefix"; continue ;;
  esac
  # Optional sidecar: <base>.self-mod-changed.txt supplies the changed-file
  # list for the Step 1b trigger (b) check (P87). Fixtures run in a temp dir
  # with no git history, so the real path-detection cannot fire there.
  selfmod_args=""
  if [ -f "${base}.self-mod-changed.txt" ]; then
    selfmod_args="--self-mod-changed-file ${base}.self-mod-changed.txt"
  fi

  output=$(bash "$VALIDATOR" --assert-review "$review" $selfmod_args 2>&1)
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
done

# --------------------------------------------------------------------------
# P75: replication fixtures (`*.repl/` directories).
#
# Each fixture is a directory containing config.json, changed.txt, repo/ and
# home/. The validator runs from repo/ with the fixture's config, changed-file
# list and stand-in HOME, so the check is exercised without touching the real
# user scope. Filename prefix dictates expected exit:
#   legal-replication-*   → expect exit 0  (mirror in sync)
#   illegal-replication-* → expect exit 1  (mirror stale — the 2026-08-03 state)
# --------------------------------------------------------------------------
for repl in "$SCRIPT_DIR"/*.repl; do
  [ -d "$repl" ] || continue
  name="$(basename "${repl%.repl}")"

  case "$name" in
    legal-replication-*) expected=0 ;;
    illegal-replication-*) expected=1 ;;
    *) echo "SKIP: $name has no legal-replication-/illegal-replication- prefix"; continue ;;
  esac

  if [ ! -d "$repl/repo" ] || [ ! -f "$repl/config.json" ] || [ ! -f "$repl/changed.txt" ]; then
    echo "SKIP: $name missing repo/, config.json or changed.txt"
    continue
  fi

  output=$(cd "$repl/repo" && bash "$VALIDATOR" --check-replication \
    --repl-config-file ../config.json \
    --repl-changed-file ../changed.txt \
    --repl-home ../home 2>&1)
  actual=$?

  # Same rationale as the .expect-stdout assertions above: a non-zero exit
  # alone cannot distinguish a reported failure from a silent one.
  stdout_ok=1
  missing_line=""
  if [ -f "$repl/expect-stdout" ]; then
    while IFS= read -r expect_line || [ -n "$expect_line" ]; do
      [ -z "$expect_line" ] && continue
      case "$output" in
        *"$expect_line"*) ;;
        *) stdout_ok=0; missing_line="$expect_line"; break ;;
      esac
    done < "$repl/expect-stdout"
  fi

  if [ "$actual" = "$expected" ] && [ "$stdout_ok" = "1" ]; then
    echo "PASS: $name (exit $actual)"
    pass=$((pass + 1))
  elif [ "$actual" = "$expected" ]; then
    echo "FAIL: $name — exit $actual correct, but expected output missing: \"$missing_line\""
    echo "  output: $output"
    fail=$((fail + 1))
    failed_cases="$failed_cases $name"
  else
    echo "FAIL: $name — expected exit $expected, got $actual"
    echo "  output: $output"
    fail=$((fail + 1))
    failed_cases="$failed_cases $name"
  fi
done

echo ""
echo "Results: $pass passed, $fail failed"
[ "$fail" -gt 0 ] && echo "Failed: $failed_cases" && exit 1
exit 0
