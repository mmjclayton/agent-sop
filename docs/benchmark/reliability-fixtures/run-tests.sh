#!/usr/bin/env bash
# Regression cases from the 2026-09-08 review. SOURCE may point at a pre-fix clone.
set -euo pipefail
SOURCE=${SOURCE:-$(cd "$(dirname "$0")/../../.." && pwd)}
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
unset CLAUDE_AGENT_ID AGENT_SOP_AGENT_ID
git init -q -b main "$WORK/repo"
git -C "$WORK/repo" config user.name Test
git -C "$WORK/repo" config user.email test@example.invalid
mkdir -p "$WORK/repo/docs/reviews" "$WORK/repo/.agents/skills/example"
printf '**Project type:** code\n' > "$WORK/repo/AGENTS.md"
printf 'base\n' > "$WORK/repo/code.sh"
printf '{"trigger":{"mode":"auto"},"agents":{"code-reviewer":{"enabled":true,"block_on":"HIGH"}}}\n' > "$WORK/repo/ship-sop.config.json"
git -C "$WORK/repo" add .
git -C "$WORK/repo" commit -qm base
BASE=$(git -C "$WORK/repo" rev-parse HEAD)
git -C "$WORK/repo" update-ref refs/remotes/origin/main "$BASE"
git -C "$WORK/repo" switch -qc feature/test
seq 1 15 >> "$WORK/repo/code.sh"
git -C "$WORK/repo" commit -qam change
HEAD_SHA=$(git -C "$WORK/repo" rev-parse HEAD)
. "$SOURCE/scripts/hooks/sop-lib.sh"
printf 'Example: Covers: %s\nVerdict: BLOCK\n' "$HEAD_SHA" > "$WORK/repo/docs/reviews/example-ship-auto.md"
test -n "$(sop_shipsop_gate "$WORK/repo")"
echo 'PASS: a Markdown stamp is not coverage'
cp "$WORK/repo/ship-sop.config.json" "$WORK/config"
printf '{invalid\n' > "$WORK/repo/ship-sop.config.json"
test -n "$(sop_shipsop_gate "$WORK/repo")"
echo 'PASS: invalid configured policy demands repair'
cp "$WORK/config" "$WORK/repo/ship-sop.config.json"
for mutation in '.trigger.throttle=false' '.trigger.throttle.min_diff_lines=null' '.agents["code-reviewer"].block_on=false'; do
    jq "$mutation" "$WORK/config" > "$WORK/invalid-policy.json"
    if sop_policy_valid "$WORK/invalid-policy.json"; then echo "FAIL: accepted $mutation"; exit 1; fi
done
cat "$WORK/config" "$WORK/config" > "$WORK/invalid-policy.json"
if sop_policy_valid "$WORK/invalid-policy.json"; then echo 'FAIL: accepted multiple config documents'; exit 1; fi
echo 'PASS: policy validation rejects false/null defaults and multiple documents'
printf '# executable instructions\n' > "$WORK/repo/.agents/skills/example/SKILL.md"
git -C "$WORK/repo" add .agents
git -C "$WORK/repo" commit -qm instructions
test "$(sop_code_lines "$WORK/repo" "$HEAD_SHA" HEAD true)" -gt 0
echo 'PASS: executable Markdown invalidates coverage'
before=$(bash "$SOURCE/scripts/resolve-resume-path.sh" --root "$WORK/repo" --home "$WORK/user")
git -C "$WORK/repo" worktree add -qb sibling "$WORK/sibling"
after=$(bash "$SOURCE/scripts/resolve-resume-path.sh" --root "$WORK/repo" --home "$WORK/user")
test "$before" = "$after"
echo 'PASS: adding a worktree preserves the main identity'
first=$(bash "$SOURCE/scripts/resolve-resume-path.sh" --root "$WORK/a_b" --home "$WORK/user" --dir)
second=$(bash "$SOURCE/scripts/resolve-resume-path.sh" --root "$WORK/a-b" --home "$WORK/user" --dir)
test "$first" != "$second"
echo 'PASS: normalised path collisions remain separate'

# A valid receipt works; every independently corrupted input must fail closed.
head=$(git -C "$WORK/repo" rev-parse HEAD)
jq -n --arg head "$head" --arg base "$BASE" \
  --arg tree "$(git -C "$WORK/repo" rev-parse 'HEAD^{tree}')" \
  --arg policy "$(sop_policy_digest "$WORK/repo/ship-sop.config.json")" \
  '{schema_version:1,head:$head,base:$base,tree:$tree,policy_sha256:$policy,
    tests:{status:"PASS",evidence:"real fixture"},
    reviewers:[{name:"code-reviewer",version:"v1",model:"fixture",verdict:"PASS",findings:[]}]}' > "$WORK/valid.json"
sop_receipt_valid "$WORK/repo" "$WORK/valid.json"
for mutation in \
  '.reviewers[0].verdict="BLOCK"' \
  '.reviewers[0].verdict="INCOMPLETE"' \
  '.reviewers=[]' \
  '.reviewers += .reviewers' \
  '.reviewers[0].findings=[{severity:"HIGH",file:"code.sh",line:1,message:"bug"}]' \
  '.reviewers[0].findings=[{severity:"UNKNOWN",file:"code.sh",line:1,message:"bug"}]' \
  '.tests.status="FAIL"' \
  '.tests.evidence=""' \
  '.tree="0000000000000000000000000000000000000000"' \
  '.policy_sha256="stale"' \
  '.base=.head'; do
    jq "$mutation" "$WORK/valid.json" > "$WORK/invalid.json"
    if sop_receipt_valid "$WORK/repo" "$WORK/invalid.json"; then
        echo "FAIL: accepted $mutation"; exit 1
    fi
done
echo 'PASS: receipt validation rejects missing, blocked, stale and incomplete evidence'
cp "$WORK/valid.json" "$WORK/repo/docs/reviews/valid-ship-auto.json"
sop_shipsop_covered "$WORK/repo" "$head"
git -C "$WORK/repo" add docs/reviews
git -C "$WORK/repo" commit -qm evidence
sop_shipsop_covered "$WORK/repo" "$(git -C "$WORK/repo" rev-parse HEAD)"
echo 'PASS: committing receipt and report preserves valid coverage'
printf 'Previously inert instruction\n' > "$WORK/repo/notes.md"
git -C "$WORK/repo" add notes.md && git -C "$WORK/repo" commit -qm notes
mkdir -p "$WORK/repo/src"
git -C "$WORK/repo" mv notes.md src/AGENTS.md
git -C "$WORK/repo" commit -qm rename-into-instructions
if sop_shipsop_covered "$WORK/repo" HEAD; then echo 'FAIL: rename into instructions retained coverage'; exit 1; fi
instruction_head=$(git -C "$WORK/repo" rev-parse HEAD)
jq --arg head "$instruction_head" --arg tree "$(git -C "$WORK/repo" rev-parse 'HEAD^{tree}')" '.head=$head | .tree=$tree' "$WORK/valid.json" > "$WORK/repo/docs/reviews/valid-ship-auto.json"
git -C "$WORK/repo" mv src/AGENTS.md notes.md
git -C "$WORK/repo" commit -qm rename-out-of-instructions
if sop_shipsop_covered "$WORK/repo" HEAD; then echo 'FAIL: rename out of instructions retained coverage'; exit 1; fi
test -n "$(sop_shipsop_gate "$WORK/repo")"
cp "$WORK/valid.json" "$WORK/repo/docs/reviews/valid-ship-auto.json"
echo 'PASS: content-preserving instruction renames invalidate receipts in both directions'

# Main identity remains stable when returning to one worktree.
git -C "$WORK/repo" worktree remove "$WORK/sibling"
test "$before" = "$(bash "$SOURCE/scripts/resolve-resume-path.sh" --root "$WORK/repo" --home "$WORK/user")"
legacy=$(bash "$SOURCE/scripts/resolve-resume-path.sh" --root "$WORK/repo" --home "$WORK/user" --legacy-dir)
mkdir -p "$legacy"
printf '# Legacy resume\n' > "$legacy/project_resume_solo.md"
if bash "$SOURCE/scripts/resolve-resume-path.sh" --root "$WORK/repo" --home "$WORK/user" --read; then
    echo 'FAIL: silently claimed ambiguous legacy storage'; exit 1
fi
bash "$SOURCE/scripts/resolve-resume-path.sh" --root "$WORK/repo" --home "$WORK/user" --migrate-legacy >/dev/null
test "$(bash "$SOURCE/scripts/resolve-resume-path.sh" --root "$WORK/repo" --home "$WORK/user" --read)" = "$before"
echo 'PASS: explicit legacy migration preserves the snapshot and identity'
old_hash=$(printf '%s' "$WORK/repo" | shasum -a 256 | cut -c1-6)
printf '# Newer main-worktree resume\n' > "$legacy/project_resume_$old_hash.md"
if bash "$SOURCE/scripts/resolve-resume-path.sh" --root "$WORK/repo" --home "$WORK/user" --migrate-legacy >/dev/null 2>&1; then
    echo 'FAIL: migrated conflicting main snapshots without reconciliation'; exit 1
fi
test -f "$legacy/project_resume_solo.md" && test -f "$legacy/project_resume_$old_hash.md"
cp "$legacy/project_resume_$old_hash.md" "$(dirname "$before")/project_resume_$old_hash.md"
if bash "$SOURCE/scripts/resolve-resume-path.sh" --root "$WORK/repo" --home "$WORK/user" --read >/dev/null 2>&1; then
    echo 'FAIL: silently selected stale solo from conflicting migrated snapshots'; exit 1
fi
rm "$(dirname "$before")/project_resume_$old_hash.md"
echo 'PASS: conflicting main snapshot generations require explicit reconciliation'

# Real linked worktrees share ownership, but permit disjoint tasks and paths.
git -C "$WORK/repo" worktree add -qb other "$WORK/other"
CLAIM="$SOURCE/scripts/hooks/sop-worktree-claim.sh"
(cd "$WORK/repo" && bash "$CLAIM" claim session-a task-a src) >/dev/null
if (cd "$WORK/repo" && bash "$CLAIM" claim session-b task-b tests) 2>/dev/null; then
    echo 'FAIL: accepted two writers in one worktree'; exit 1
fi
if (cd "$WORK/other" && bash "$CLAIM" claim session-b task-b src/file.sh) 2>/dev/null; then
    echo 'FAIL: accepted overlapping paths'; exit 1
fi
if (cd "$WORK/other" && bash "$CLAIM" claim session-b task-a tests) 2>/dev/null; then
    echo 'FAIL: accepted duplicate task'; exit 1
fi
(cd "$WORK/other" && bash "$CLAIM" claim session-b task-b tests) >/dev/null
test "$(cd "$WORK/repo" && bash "$CLAIM" status | jq length)" = 2
if (cd "$WORK/repo" && bash "$CLAIM" release session-b) 2>/dev/null; then
    echo 'FAIL: foreign owner released claim'; exit 1
fi
(cd "$WORK/repo" && bash "$CLAIM" release session-a) >/dev/null
(cd "$WORK/other" && bash "$CLAIM" release session-b) >/dev/null
echo 'PASS: writer, task and path claims coordinate real linked worktrees'
for repo in "$WORK/repo" "$WORK/other"; do
    mkdir -p "$repo/docs/sop" "$repo/docs/agent-memory/in-flight"
    touch "$repo/Backlog.md" "$repo/docs/sop/claude-agent-sop.md"
done
printf 'task-b: parser invariant; next action is tests\n' > "$WORK/other/docs/agent-memory/in-flight/b.md"
context() {
    jq -n --arg cwd "$1" --arg session "$2" '{cwd:$cwd,session_id:$session}' |
      AGENT_SOP_STATE_DIR="$WORK/context-state" AGENT_SOP_CONFIG_HOME="$WORK/config-home" \
      bash "$SOURCE/scripts/hooks/sop-session-context.sh"
}
context "$WORK/repo" session-a > "$WORK/context-a"
grep -q 'parser invariant' "$WORK/context-a"
test -z "$(context "$WORK/repo" session-a)"
context "$WORK/other" session-b > "$WORK/context-b"
context "$WORK/repo" session-a > "$WORK/context-delta"
grep -q 'Context changed' "$WORK/context-delta"
grep -q 'Other active sessions' "$WORK/context-delta"
echo 'PASS: sibling handoffs load and presence changes produce a compact delta'
presence="$WORK/repo/.git/agent-sop/sessions"
printf '{"session":"expired","root":"old","updated":1}\n' > "$presence/expired.json"
touch -t 202001010000 "$presence/expired.json"
context "$WORK/repo" session-a >/dev/null
test ! -e "$presence/expired.json"
test "$(find "$presence" -name '*.json' | wc -l | tr -d ' ')" = 2
echo 'PASS: presence pruning removes expired records and preserves active peers'

mkdir -p "$WORK/repo/nested" "$WORK/other/nested"
(cd "$WORK/repo/nested" && bash "$CLAIM" claim owner task src) >/dev/null
if (cd "$WORK/repo" && bash "$CLAIM" claim foreign other docs) 2>/dev/null; then
    echo 'FAIL: subdirectory used a different registry'; exit 1
fi
for path in . src/./file src/.; do
    if (cd "$WORK/other/nested" && bash "$CLAIM" claim other-owner other-task "$path") 2>/dev/null; then
        echo 'FAIL: accepted ambiguous dot path'; exit 1
    fi
done
(cd "$WORK/repo/nested" && bash "$CLAIM" release owner) >/dev/null
mkdir -p "$WORK/repo/scripts"
printf '#!/bin/sh\ntouch "%s"\n' "$WORK/unsafe-resolver-ran" > "$WORK/repo/scripts/resolve-resume-path.sh"
CODEX_HOME="$WORK/doctor-codex" bash "$SOURCE/scripts/hooks/sop-doctor.sh" --runtime codex --root "$WORK/repo" > "$WORK/doctor.json" || true
test ! -f "$WORK/unsafe-resolver-ran"
jq -e 'has("resume_diagnostic")' "$WORK/doctor.json" >/dev/null
echo 'PASS: subdirectory ownership, dot-path rejection and trusted diagnostic resolver'
mkdir -p "$WORK/broken-hash-bin"
for name in shasum sha256sum; do
    printf '#!/bin/sh\nexit 127\n' > "$WORK/broken-hash-bin/$name"
    chmod +x "$WORK/broken-hash-bin/$name"
done
if PATH="$WORK/broken-hash-bin:$PATH" bash "$SOURCE/scripts/resolve-resume-path.sh" --root "$WORK/repo" --dir > "$WORK/bad-path" 2>/dev/null; then
    echo 'FAIL: hashing failure returned a storage path'; exit 1
fi
test ! -s "$WORK/bad-path"
mkdir -p "$WORK/registry"
printf '{invalid\n' > "$WORK/registry/bad.json"
if sop_registry_read "$WORK/registry" >/dev/null 2>&1; then echo 'FAIL: malformed registry appeared empty'; exit 1; fi
rm "$WORK/registry/bad.json"
ln -s "$WORK/absent" "$WORK/registry/unreadable.json"
if sop_registry_read "$WORK/registry" >/dev/null 2>&1; then echo 'FAIL: unreadable record appeared empty'; exit 1; fi
ln -s "$WORK/absent" "$WORK/repo/.git/agent-sop/claims/unreadable.json"
if (cd "$WORK/repo" && bash "$CLAIM" claim owner task src) >/dev/null 2>&1; then
    echo 'FAIL: claiming ignored an unreadable peer claim'; exit 1
fi
rm "$WORK/repo/.git/agent-sop/claims/unreadable.json"
git -C "$WORK/repo" update-ref refs/remotes/origin/main HEAD
mkdir -p "$WORK/repo/src"
printf 'One instruction\n' > "$WORK/repo/src/AGENTS.md"
git -C "$WORK/repo" add src/AGENTS.md
git -C "$WORK/repo" commit -qm nested-instruction
test -n "$(sop_shipsop_gate "$WORK/repo")"
echo 'PASS: hash failures stop resolution, registry errors surface, nested instructions demand review'
