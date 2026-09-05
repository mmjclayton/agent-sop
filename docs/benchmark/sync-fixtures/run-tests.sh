#!/usr/bin/env bash
#
# Test harness for scripts/sync-sop-files.sh. Builds a fake upstream checkout
# with a two-version history and a manifest, a consumer, and a config, all in
# a temp dir with HOME redirected. Run from repo root:
#   bash docs/benchmark/sync-fixtures/run-tests.sh
set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SYNC="${SYNC:-$REPO_ROOT/scripts/sync-sop-files.sh}"
pass=0; fail=0; failed=""
ok()  { echo "PASS: $1"; pass=$((pass+1)); }
bad() { echo "FAIL: $1 — $2"; fail=$((fail+1)); failed="$failed $1"; }
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"; mkdir -p "$HOME/.claude/commands"
GIT="git -c user.email=t@t -c user.name=t -c commit.gpgsign=false"
UP="$TMP/upstream"; mkdir -p "$UP/docs/sop" "$UP/scripts" "$UP/.claude/commands"
(cd "$UP" && $GIT init -q -b main
 printf '# SOP v1\n' > docs/sop/claude-agent-sop.md; printf '#!/bin/sh\necho v1\n' > scripts/tool.sh; chmod +x scripts/tool.sh; printf 'cmd v1\n' > .claude/commands/thing.md; printf 'x v1\n' > docs/sop/extra.md
 printf '| Destination in consumer project | Upstream path | Scope |\n|---|---|---|\n| `docs/sop/claude-agent-sop.md` | `docs/sop/claude-agent-sop.md` | project |\n| `scripts/tool.sh` | `scripts/tool.sh` | project |\n| `docs/sop/extra.md` | `docs/sop/extra.md` | project |\n| `~/.claude/commands/thing.md` | `.claude/commands/thing.md` | user |\n' > .claude/commands/update-agent-sop.md
 $GIT add -A >/dev/null && $GIT commit -q -m v1
 printf '# SOP v2\n' > docs/sop/claude-agent-sop.md; printf '#!/bin/sh\necho v2\n' > scripts/tool.sh; printf 'cmd v2\n' > .claude/commands/thing.md; printf 'x v2\n' > docs/sop/extra.md
 $GIT add -A >/dev/null && $GIT commit -q -m v2)
V1_SOP=$(printf '# SOP v1\n' | shasum -a 256 | awk '{print $1}')
C="$TMP/consumer"; mkdir -p "$C/docs/sop" "$C/scripts"; (cd "$C" && git init -q)
printf '# SOP v1\n' > "$C/docs/sop/claude-agent-sop.md"          # older pristine (v1), baseline says v2
printf '#!/bin/sh\necho mine\n' > "$C/scripts/tool.sh"; chmod +x "$C/scripts/tool.sh"   # locally modified, executable
printf 'x v1\n' > "$C/docs/sop/extra.md"                          # excluded
printf 'cmd v1\n' > "$HOME/.claude/commands/thing.md"             # user-scope row, older pristine
V2_SOP=$(shasum -a 256 "$UP/docs/sop/claude-agent-sop.md" | awk '{print $1}')
CFG="$TMP/config.json"
printf '{ "local_path": "%s", "update_reminder": "weekly", "last_update_check": null, "exclude": ["docs/sop/extra.md"], "baseline_shas": { "docs/sop/claude-agent-sop.md": "%s", "scripts/tool.sh": "0000" } }\n' "$UP" "$V2_SOP" > "$CFG"

out=$(bash "$SYNC" --root "$C" --config "$CFG")
if printf '%s' "$out" | grep -q 'OLDER            docs/sop/claude-agent-sop.md' && printf '%s' "$out" | grep -q 'OLDER            ~/.claude/commands/thing.md'; then ok "older-pristine-detected-by-history"; else bad "older-pristine-detected-by-history" "$out"; fi
if printf '%s' "$out" | grep -q 'RECONCILE        scripts/tool.sh'; then ok "local-edit-with-upstream-move-is-reconcile"; else bad "local-edit-with-upstream-move-is-reconcile" "$out"; fi
if printf '%s' "$out" | grep -q 'excluded         docs/sop/extra.md'; then ok "excluded-is-skipped"; else bad "excluded-is-skipped" "$out"; fi
if grep -q '# SOP v1' "$C/docs/sop/claude-agent-sop.md" && ! [ -f "$CFG.bak" ] && [ "$(jq -r .last_update_check "$CFG")" = null ]; then ok "dry-run-writes-nothing"; else bad "dry-run-writes-nothing" "sop=$(cat "$C/docs/sop/claude-agent-sop.md") check=$(jq -r .last_update_check "$CFG")"; fi

out=$(bash "$SYNC" --root "$C" --config "$CFG" --apply)
if grep -q '# SOP v2' "$C/docs/sop/claude-agent-sop.md" && grep -q 'cmd v2' "$HOME/.claude/commands/thing.md"; then ok "apply-updates-older-pristine-files"; else bad "apply-updates-older-pristine-files" "$out"; fi
if grep -q 'echo mine' "$C/scripts/tool.sh"; then ok "apply-keeps-local-edit"; else bad "apply-keeps-local-edit" "$(cat "$C/scripts/tool.sh")"; fi
if grep -q 'x v1' "$C/docs/sop/extra.md"; then ok "apply-keeps-excluded"; else bad "apply-keeps-excluded" "$(cat "$C/docs/sop/extra.md")"; fi
if [ "$(jq -r '.baseline_shas["docs/sop/claude-agent-sop.md"]' "$CFG")" = "$V2_SOP" ] && [ "$(jq -r .last_update_check "$CFG")" = "$(date +%Y-%m-%d)" ] && [ "$(jq -r '.baseline_shas["scripts/tool.sh"]' "$CFG")" = "0000" ]; then ok "apply-refreshes-baselines-only-for-written-files"; else bad "apply-refreshes-baselines-only-for-written-files" "$(jq -c .baseline_shas "$CFG") $(jq -r .last_update_check "$CFG")"; fi
if [ -x "$C/scripts/tool.sh" ]; then ok "exec-bit-preserved-on-kept-file"; else bad "exec-bit-preserved-on-kept-file" "mode lost"; fi
rm -f "$C/docs/sop/claude-agent-sop.md"
out=$(bash "$SYNC" --root "$C" --config "$CFG" --apply)
if printf '%s' "$out" | grep -q 'MISSING          docs/sop/claude-agent-sop.md' && grep -q '# SOP v2' "$C/docs/sop/claude-agent-sop.md"; then ok "missing-file-created"; else bad "missing-file-created" "$out"; fi
before=$(cat "$C/docs/sop/claude-agent-sop.md" "$CFG" | shasum -a 256)
out=$(bash "$SYNC" --root "$C" --config "$CFG" --apply)
after=$(cat "$C/docs/sop/claude-agent-sop.md" "$CFG" | shasum -a 256)
if [ "$before" = "$after" ] && printf '%s' "$out" | grep -q 'applied 0'; then ok "second-run-is-a-no-op"; else bad "second-run-is-a-no-op" "$out"; fi
printf '#!/bin/sh\necho v1\n' > "$C/scripts/tool.sh"   # revert the local edit to v1: pristine-older by history despite a wrong baseline
out=$(bash "$SYNC" --root "$C" --config "$CFG")
if printf '%s' "$out" | grep -q 'OLDER            scripts/tool.sh'; then ok "history-beats-a-wrong-baseline"; else bad "history-beats-a-wrong-baseline" "$out"; fi
chmod -x "$C/scripts/tool.sh"; bash "$SYNC" --root "$C" --config "$CFG" --apply >/dev/null
if grep -q 'echo v2' "$C/scripts/tool.sh" && [ -x "$C/scripts/tool.sh" ]; then ok "written-file-takes-upstream-exec-bit"; else bad "written-file-takes-upstream-exec-bit" "$(ls -l "$C/scripts/tool.sh")"; fi
# A project-scope config without local_path takes the upstream from the
# user-global config (repcanvas-marketing's shape).
mkdir -p "$C/.claude"; printf '{ "exclude": [], "baseline_shas": {} }\n' > "$C/.claude/agent-sop.config.json"
printf '{ "local_path": "%s", "baseline_shas": {} }\n' "$UP" > "$HOME/.claude/agent-sop.config.json"
printf '# SOP v1\n' > "$C/docs/sop/claude-agent-sop.md"
out=$(cd "$C" && bash "$SYNC" 2>&1)
if printf '%s' "$out" | grep -q 'OLDER            docs/sop/claude-agent-sop.md'; then ok "project-config-without-local-path-uses-user-config"; else bad "project-config-without-local-path-uses-user-config" "$out"; fi

echo ""; echo "sync-fixtures: $pass passed, $fail failed"
[ "$fail" -gt 0 ] && echo "Failed:$failed" && exit 1
exit 0
