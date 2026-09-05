#!/usr/bin/env bash
#
# Test harness for scripts/archive-backlog.sh. Builds a Backlog.md in a temp
# git repo and checks what moves, what stays, and that nothing is split or
# lost. Run from repo root: bash docs/benchmark/archive-fixtures/run-tests.sh
set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ARCHIVER="${ARCHIVER:-$REPO_ROOT/scripts/archive-backlog.sh}"
pass=0; fail=0; failed=""
ok()  { echo "PASS: $1"; pass=$((pass+1)); }
bad() { echo "FAIL: $1 — $2"; fail=$((fail+1)); failed="$failed $1"; }
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
mk() {
    rm -rf "$TMP/r"; mkdir -p "$TMP/r/docs"; (cd "$TMP/r" && git init -q)
    cat > "$TMP/r/Backlog.md" <<'MD'
# Backlog

## Tag Taxonomy

tags here

## P-Numbered Items

### P1 — Old shipped feature
`[SHIPPED - 2026-01-10] [Feature]`

Body of P1.

## An embedded heading that belongs to P1

More of P1.

---

### P2 — Old WON'T with no date
`[WON'T] [Feature] — Reason: superseded`

Body of P2.

---

### P3 - Old shipped with a hyphen heading
`[SHIPPED - 2026-02-01] [Bug]`

Body of P3.

---

### P4 — Recent shipped
`[SHIPPED - 2099-01-01] [Feature]`

Body of P4.

---

### P5 — Open item
`[OPEN] [Feature]`

Body of P5.

---

### P6 — Active item that quotes an old tag
`[IN PROGRESS] [Feature]`

For a moment the line read `[SHIPPED - 2020-01-01] [Bug]` before we reverted.

---

### P7 — Old shipped with a fenced example heading
`[SHIPPED - 2026-01-05] [Feature]`

Example of the format:

```
### P999 — Example title for illustration only
`[OPEN] [Feature]`
```

End of P7.

---

### P8 — Old WON'T with an unrelated date in the body
`[WON'T] [Feature] — Reason: superseded`

Cites a source dated 2020-01-01 but was never dated itself.

---

## Shipped Archive

Legacy section that must stay.
MD
}
mk
out=$(cd "$TMP/r" && bash "$ARCHIVER" --days 30 2>&1); rc=$?
B="$TMP/r/Backlog.md"; A="$TMP/r/docs/backlog-archive.md"
if [ "$rc" = 0 ] && [ -f "$A" ]; then ok "archive-runs-and-writes-archive"; else bad "archive-runs-and-writes-archive" "rc=$rc out='$out'"; fi
if grep -q '^### P1 ' "$A" && grep -q '^### P3 ' "$A" && ! grep -q '^### P4 ' "$A" && ! grep -q '^### P5 ' "$A"; then ok "archive-moves-only-old-closed-items"; else bad "archive-moves-only-old-closed-items" "$(grep '^### ' "$A" | tr '\n' ' ')"; fi
if grep -q '^### P2 ' "$B" && ! grep -q '^### P2 ' "$A"; then ok "archive-keeps-wont-without-date"; else bad "archive-keeps-wont-without-date" "$(grep '^### P2' "$A" "$B")"; fi
if grep -q '^## An embedded heading that belongs to P1' "$A" && ! grep -q '^## An embedded heading' "$B" && grep -q 'More of P1' "$A"; then ok "archive-moves-entry-with-internal-heading-whole"; else bad "archive-moves-entry-with-internal-heading-whole" "$(grep -n 'embedded\|More of P1' "$A" "$B" | tr '\n' ' ')"; fi
if grep -q '^## Shipped Archive' "$B" && grep -q 'Legacy section that must stay' "$B"; then ok "archive-keeps-trailing-section"; else bad "archive-keeps-trailing-section" "$(grep -n 'Shipped Archive' "$B")"; fi
if grep -q '^- P3 — archived: Old shipped with a hyphen heading' "$B"; then ok "archive-pointer-for-hyphen-heading"; else bad "archive-pointer-for-hyphen-heading" "$(grep -n 'P3' "$B" | tr '\n' ' ')"; fi
if [ "$(grep -c '^---$' "$A")" = 3 ]; then ok "archive-one-separator-per-entry"; else bad "archive-one-separator-per-entry" "separators=$(grep -c '^---$' "$A")"; fi
if grep -q '^### P6 ' "$B" && ! grep -q '^### P6 ' "$A"; then ok "archive-keeps-active-item-quoting-a-tag"; else bad "archive-keeps-active-item-quoting-a-tag" "$(grep -n '^### P6' "$A" "$B")"; fi
if grep -q '^### P7 ' "$A" && grep -q 'End of P7' "$A" && grep -q '^### P999' "$A" && ! grep -q '^### P999' "$B"; then ok "archive-fenced-heading-is-not-an-entry"; else bad "archive-fenced-heading-is-not-an-entry" "$(grep -n 'P999\|End of P7' "$A" "$B" | tr '\n' ' ')"; fi
if grep -q '^### P8 ' "$B" && ! grep -q '^### P8 ' "$A"; then ok "archive-keeps-wont-with-undated-reason"; else bad "archive-keeps-wont-with-undated-reason" "$(grep -n '^### P8' "$A" "$B")"; fi
before=$(cat "$B" "$A" | shasum -a 256)
out2=$(cd "$TMP/r" && bash "$ARCHIVER" --days 30 2>&1)
after=$(cat "$B" "$A" | shasum -a 256)
if [ "$before" = "$after" ] && printf '%s' "$out2" | grep -q 'nothing older'; then ok "archive-idempotent"; else bad "archive-idempotent" "out='$out2'"; fi
mk
out=$(cd "$TMP/r" && bash "$ARCHIVER" --days 30 --dry-run 2>&1)
if [ ! -f "$TMP/r/docs/backlog-archive.md" ] && grep -q '^### P1 ' "$TMP/r/Backlog.md" && printf '%s' "$out" | grep -q 'P1 P2\|P1 P3\|moving'; then ok "archive-dry-run-writes-nothing"; else bad "archive-dry-run-writes-nothing" "out='$out'"; fi
# A footer after the last entry's closing `---` stays in Backlog.md.
rm -rf "$TMP/f"; mkdir -p "$TMP/f/docs"; (cd "$TMP/f" && git init -q)
printf '# Backlog\n\n### P1 — Old\n`[SHIPPED - 2026-01-01] [Feature]`\n\nBody.\n\n---\n\n_Maintainer footer: reviewed monthly._\n' > "$TMP/f/Backlog.md"
(cd "$TMP/f" && bash "$ARCHIVER" --days 30 >/dev/null 2>&1)
if grep -q 'Maintainer footer' "$TMP/f/Backlog.md" && ! grep -q 'Maintainer footer' "$TMP/f/docs/backlog-archive.md" && grep -q '^### P1 ' "$TMP/f/docs/backlog-archive.md"; then ok "archive-keeps-footer-after-last-entry"; else bad "archive-keeps-footer-after-last-entry" "$(grep -n 'footer' "$TMP/f/Backlog.md" "$TMP/f/docs/backlog-archive.md")"; fi

echo ""; echo "archive-fixtures: $pass passed, $fail failed"
[ "$fail" -gt 0 ] && echo "Failed:$failed" && exit 1
exit 0
