#!/usr/bin/env bash
#
# Test harness for `scripts/refresh-priorities.sh` (P92) and the shared
# sentinel-splice guard in `scripts/refresh-rollup.sh` (P95).
#
# Every case here is a regression: each one FAILS against the pre-fix scripts and
# passes after. That is the standard the state-transition suite adopted post-P73
# — a fixture that passes both before and after a change covers nothing.
#
# Two of these cover CONFIRMED CRITICAL findings from the P92 review
# (docs/reviews/2026-08-03_solo_P92.md):
#   - a malformed end sentinel silently deleted the rest of the file
#   - an item whose body opened with a bracketed reference vanished, and the
#     block then rendered "No open items" — a false claim, fail-open
#
# Run from repo root: bash docs/benchmark/priorities-fixtures/run-tests.sh
# Override the scripts under test with PRIORITIES= / ROLLUP= to prove the
# fixtures discriminate against a deliberately broken version.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PRIORITIES="${PRIORITIES:-$REPO_ROOT/scripts/refresh-priorities.sh}"
ROLLUP="${ROLLUP:-$REPO_ROOT/scripts/refresh-rollup.sh}"

pass=0; fail=0; failed=""

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

check() {   # check <name> <condition-description> <actual> <expected>
    local name="$1" desc="$2" actual="$3" expected="$4"
    if [ "$actual" = "$expected" ]; then
        echo "PASS: $name ($desc)"
        pass=$((pass + 1))
    else
        echo "FAIL: $name — $desc: expected '$expected', got '$actual'"
        fail=$((fail + 1)); failed="$failed $name"
    fi
}

block() { sed -n '/priority-items:start/,/priority-items:end/p' "$1"; }

# ── 1. CRITICAL: malformed end sentinel must not destroy trailing content ─────
d="$work/malformed-end"; mkdir -p "$d"; cd "$d" || exit 2
printf '# B\n\n### P1 — open\n`[OPEN] [Bug]`\n' > Backlog.md
printf '# P\n<!-- priority-items:start -->\nX\n<!-- priority-items:ends -->\n\n## SURVIVOR\n' > CLAUDE.md
bash "$PRIORITIES" >/dev/null 2>&1
check "malformed-end-sentinel" "trailing content survives" "$(grep -c 'SURVIVOR' CLAUDE.md)" "1"

# ── 2. CRITICAL: same guard in the shipped rollup script ─────────────────────
d="$work/malformed-end-rollup"; mkdir -p "$d/docs/recent-work"; cd "$d" || exit 2
printf '# E\n' > docs/recent-work/2026-08-01_solo_e.md
printf '# R\n<!-- recent-work-rollup:start -->\nX\n<!-- recent-work-rollup:ends -->\n\n## SURVIVOR\n' > docs/RECENT-WORK.md
bash "$ROLLUP" >/dev/null 2>&1
check "malformed-end-rollup" "trailing content survives" "$(grep -c 'SURVIVOR' docs/RECENT-WORK.md)" "1"

# ── 3. CRITICAL: bracketed body text must not swallow the status line ────────
d="$work/bracket-body"; mkdir -p "$d"; cd "$d" || exit 2
cat > Backlog.md <<'EOF'
# B

### P1 — real open item
`[see also P3]` a note before the status tag
`[OPEN] [Bug]`
EOF
printf '# P\n<!-- priority-items:start -->\nX\n<!-- priority-items:end -->\n' > CLAUDE.md
bash "$PRIORITIES" >/dev/null 2>&1
check "bracket-body-does-not-hide-item" "P1 still derived" "$(block CLAUDE.md | grep -c '^- P1')" "1"

# ── 4. HIGH: fenced examples must not be parsed as real items ────────────────
d="$work/fenced"; mkdir -p "$d"; cd "$d" || exit 2
printf '# B\n\n### P1 — real\n`[OPEN] [Bug]`\n\n```\n### P99 — fenced example\n`[OPEN] [Feature]`\n```\n' > Backlog.md
printf '# P\n<!-- priority-items:start -->\nX\n<!-- priority-items:end -->\n' > CLAUDE.md
bash "$PRIORITIES" >/dev/null 2>&1
check "fenced-example-ignored" "P99 absent" "$(block CLAUDE.md | grep -c '^- P99')" "0"

# ── 5. HIGH: unparseable Backlog reports failure, not "no open items" ────────
d="$work/unparseable"; mkdir -p "$d"; cd "$d" || exit 2
printf '# B\n\n## P1 — wrong heading depth\n`[OPEN] [Bug]`\n' > Backlog.md
printf '# P\n<!-- priority-items:start -->\nX\n<!-- priority-items:end -->\n' > CLAUDE.md
bash "$PRIORITIES" >/dev/null 2>&1
check "unparseable-reports-failure" "says 'Could not parse'" "$(block CLAUDE.md | grep -c 'Could not parse')" "1"

# ── 6. Terminal states excluded; open states included ───────────────────────
d="$work/statuses"; mkdir -p "$d"; cd "$d" || exit 2
cat > Backlog.md <<'EOF'
# B

### P1 — shipped
`[SHIPPED - 2026-01-01] [Feature]`

### P2 — open
`[OPEN] [Bug]`

### P3 — in progress
`[IN PROGRESS] [Feature]`

### P4 — blocked
`[BLOCKED] [Iteration]`

### P5 — wont
`[WON'T] [Feature] — Reason: superseded`

### P6 — deferred
`[DEFERRED] [Iteration]`
EOF
printf '# P\n<!-- priority-items:start -->\nX\n<!-- priority-items:end -->\n' > CLAUDE.md
bash "$PRIORITIES" >/dev/null 2>&1
check "status-filter" "3 non-terminal items derived" "$(block CLAUDE.md | grep -c '^- P')" "3"

# ── 7. Idempotency (load-bearing for parallel-session merges) ───────────────
cp CLAUDE.md first-run.md
bash "$PRIORITIES" >/dev/null 2>&1
if diff -q first-run.md CLAUDE.md >/dev/null 2>&1; then r=same; else r=differs; fi
check "idempotent" "second run byte-identical" "$r" "same"

# ── 8. Opt-in: no sentinel means untouched, exit 0 ──────────────────────────
d="$work/optin"; mkdir -p "$d"; cd "$d" || exit 2
printf '# B\n\n### P1 — open\n`[OPEN] [Bug]`\n' > Backlog.md
printf '# No sentinel here\n' > CLAUDE.md
bash "$PRIORITIES" >/dev/null 2>&1
check "opt-in-skip" "exit 0 on absent sentinel" "$?" "0"

echo ""
echo "Results: $pass passed, $fail failed"
[ "$fail" -gt 0 ] && echo "Failed:$failed" && exit 1
exit 0
