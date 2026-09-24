#!/usr/bin/env bash
set -euo pipefail
SOURCE="$(cd "$(dirname "$0")/../../.." && pwd -P)"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
export AGENT_SOP_USER_HOME="$WORK/user"
export AGENT_SOP_STATE_DIR="$WORK/state"
unset CODEX_HOME
mkdir -p "$WORK/project" "$WORK/dual" "$WORK/claude"
bash "$SOURCE/setup.sh" "$WORK/project" --runtime codex --code > "$WORK/install.log"
test -f "$WORK/project/AGENTS.md"
rm "$AGENT_SOP_USER_HOME/.codex/scripts/hooks/agent-sop/resolve-resume-path.sh"
bash "$SOURCE/scripts/sync-sop-files.sh" --runtime codex --root "$WORK/project" --apply > "$WORK/resolver-upgrade.log"
test -f "$AGENT_SOP_USER_HOME/.codex/scripts/hooks/agent-sop/resolve-resume-path.sh"
printf 'PASS: Codex sync restores the trusted resolver dependency\n'
jq -e '(.baseline_shas | length) > 0' "$AGENT_SOP_USER_HOME/.codex/agent-sop.config.json" >/dev/null
test ! -e "$WORK/project/CLAUDE.md"
test ! -e "$AGENT_SOP_USER_HOME/.claude"
test -f "$AGENT_SOP_USER_HOME/.agents/skills/update-sop/SKILL.md"
jq -e '.hooks | keys == ["PreToolUse","SessionStart","Stop","UserPromptSubmit"]' "$AGENT_SOP_USER_HOME/.codex/hooks.json" >/dev/null
printf 'PASS: Codex-only install creates native assets without Claude configuration\n'
printf '\nProject customization\n' >> "$WORK/project/AGENTS.md"
cp "$WORK/project/AGENTS.md" "$WORK/expected"
bash "$SOURCE/setup.sh" "$WORK/project" --runtime codex --code --force > "$WORK/reinstall.log"
cmp "$WORK/expected" "$WORK/project/AGENTS.md"
jq -e '[.hooks[][] .hooks[]] | length == 4' "$AGENT_SOP_USER_HOME/.codex/hooks.json" >/dev/null
printf 'PASS: reinstall is idempotent and preserves project instructions\n'
bash "$SOURCE/setup.sh" "$WORK/dual" --runtime both --code > "$WORK/both.log"
test -f "$WORK/dual/CLAUDE.md"; test -f "$WORK/dual/AGENTS.md"
bash "$SOURCE/setup.sh" "$WORK/claude" --runtime claude --code > "$WORK/claude.log"
test -f "$WORK/claude/CLAUDE.md"; test ! -e "$WORK/claude/AGENTS.md"
printf 'PASS: both and legacy Claude modes install the selected entrypoints\n'
PTYPE="$SOURCE/scripts/hooks/sop-project-type.sh"
test "$(bash "$PTYPE" "$WORK/project")" = code
test "$(bash "$PTYPE" "$WORK/dual")" = code
printf '**Project type:** non-code\n' > "$WORK/dual/AGENTS.md"
test "$(bash "$PTYPE" "$WORK/dual")" = non-code
printf -- '- **Project type:** code\n' > "$WORK/dual/AGENTS.md"
printf '**Project type:** non-code\n' > "$WORK/dual/CLAUDE.md"
test "$(bash "$PTYPE" "$WORK/dual")" = code
for alias in "$SOURCE"/.agents/skills/source-command-*/SKILL.md; do
    name="$(basename "$(dirname "$alias")")"; name="${name#source-command-}"
    test -f "$(dirname "$alias")/../$name/SKILL.md"
    grep -qF "(../$name/SKILL.md)" "$alias"
done
printf 'PASS: bulleted AGENTS declarations retain precedence and alias targets exist\n'
# Real Git state for transport + policy integration, without a network push.
git -C "$WORK/project" init -q -b main
git -C "$WORK/project" -c user.name=Test -c user.email=test@example.invalid add .
git -C "$WORK/project" -c user.name=Test -c user.email=test@example.invalid -c commit.gpgsign=false commit -qm initial
git -C "$WORK/project" update-ref refs/remotes/origin/main HEAD
git -C "$WORK/project" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
git -C "$WORK/project" checkout -qb feat/test
printf '{"trigger":{"mode":"auto","throttle":{"min_diff_lines":1}},"agents":{"code-reviewer":{"enabled":true,"block_on":"HIGH"}}}\n' > "$WORK/project/ship-sop.config.json"
printf 'echo changed\n' > "$WORK/project/app.sh"
git -C "$WORK/project" add .
git -C "$WORK/project" -c user.name=Test -c user.email=test@example.invalid -c commit.gpgsign=false commit -qm changed
INPUT=$(jq -n --arg cwd "$WORK/project" '{cwd:$cwd,session_id:"codex-fixture",hook_event_name:"UserPromptSubmit"}')
HOOK="$SOURCE/scripts/hooks/sop-codex-hook.sh"
printf '%s' "$INPUT" | bash "$HOOK" UserPromptSubmit > "$WORK/context"
jq -e '.hookSpecificOutput.additionalContext | contains("Agent SOP context")' "$WORK/context" >/dev/null
printf '%s' "$INPUT" | bash "$HOOK" UserPromptSubmit > "$WORK/context2"
test ! -s "$WORK/context2"
set +e
printf '%s' "$INPUT" | bash "$HOOK" Stop > "$WORK/stop.out" 2> "$WORK/stop.err"; STOP_CODE=$?
printf '%s' "$INPUT" | jq '.tool_name="Bash" | .tool_input={command:"git push origin HEAD"}' | bash "$HOOK" PreToolUse > "$WORK/push.out" 2> "$WORK/push.err"; PUSH_CODE=$?
set -e
test "$STOP_CODE" = 2; test "$PUSH_CODE" = 2
grep -q 'ship-sop' "$WORK/stop.err"; grep -q 'ship-sop' "$WORK/push.err"
printf 'PASS: Codex context JSON, deduplication, Stop continuation and push denial\n'
# Safe update installs missing assets and preserves modified native skills.
bash "$SOURCE/scripts/sync-sop-files.sh" --runtime codex --root "$WORK/project" --apply > "$WORK/sync.log"
printf '\nLocal customization\n' >> "$AGENT_SOP_USER_HOME/.agents/skills/ship-placeholder.md" # unrelated asset
printf '\nLocal customization\n' >> "$AGENT_SOP_USER_HOME/.agents/skills/restart-sop/SKILL.md"
bash "$SOURCE/scripts/sync-sop-files.sh" --runtime codex --root "$WORK/project" --apply > "$WORK/sync2.log"
grep -q 'Local customization' "$AGENT_SOP_USER_HOME/.agents/skills/restart-sop/SKILL.md"
printf 'PASS: Codex sync preserves local skill edits\n'
mkdir -p "$WORK/project/.codex"
printf '{"local_path":"/nonexistent/project-controlled-source","exclude":[],"baseline_shas":{}}\n' > "$WORK/project/.codex/agent-sop.config.json"
bash "$SOURCE/scripts/sync-sop-files.sh" --runtime codex --root "$WORK/project" --apply > "$WORK/project-authority"
cmp "$SOURCE/scripts/hooks/sop-lib.sh" "$AGENT_SOP_USER_HOME/.codex/scripts/hooks/agent-sop/sop-lib.sh"
printf 'PASS: project configuration cannot replace the trusted upstream\n'
bash "$SOURCE/scripts/install-codex.sh" --uninstall > "$WORK/uninstall.log"
test -f "$AGENT_SOP_USER_HOME/.agents/skills/restart-sop/SKILL.md"
test ! -f "$AGENT_SOP_USER_HOME/.agents/skills/update-sop/SKILL.md"
bash "$SOURCE/scripts/install-hooks.sh" --runtime codex --uninstall > "$WORK/unhook.log"
test -f "$AGENT_SOP_USER_HOME/.claude/settings.json"
test -f "$WORK/project/AGENTS.md"
printf 'PASS: removal preserves local edits, shared project data and Claude hooks\n'

# Codex-only dispatch detects secondary trackers, without duplicate bridge paths.
mkdir -p "$WORK/trackers/docs"
printf '`docs/tasks.md`\n' > "$WORK/trackers/AGENTS.md"
printf '### T1 [OPEN]\n' > "$WORK/trackers/docs/tasks.md"
(cd "$WORK/trackers" && bash "$SOURCE/scripts/detect-trackers.sh") > "$WORK/detected"
test "$(cat "$WORK/detected")" = docs/tasks.md
cp "$WORK/trackers/AGENTS.md" "$WORK/trackers/CLAUDE.md"
(cd "$WORK/trackers" && bash "$SOURCE/scripts/detect-trackers.sh") > "$WORK/detected"
test "$(wc -l < "$WORK/detected" | tr -d ' ')" = 1
printf 'PASS: native tracker dispatch and bridge deduplication\n'
# Discovery errors cannot become successful partial installation.
mkdir -p "$WORK/broken/scripts" "$WORK/broken/.agents/skills/restart-sop"
cp "$SOURCE/scripts/install-codex.sh" "$WORK/broken/scripts/"
if bash "$WORK/broken/scripts/install-codex.sh" > "$WORK/broken.log" 2>&1; then
    echo 'FAIL: incomplete source accepted'; exit 1
fi
printf 'PASS: incomplete source installation fails\n'

if (cd "$WORK/trackers" && bash "$SOURCE/scripts/detect-trackers.sh" missing.md) > "$WORK/missing-tracker" 2>&1; then
    echo 'FAIL: unreadable tracker input accepted'; exit 1
fi
printf 'PASS: explicit missing tracker input fails\n'

# Directory symlinks must never make uninstall remove the source checkout.
mkdir -p "$WORK/broken/.codex/agents" "$WORK/linked-user/.agents/skills"
printf 'source skill\n' > "$WORK/broken/.agents/skills/restart-sop/SKILL.md"
ln -s "$WORK/broken/.agents/skills/restart-sop" "$WORK/linked-user/.agents/skills/restart-sop"
AGENT_SOP_USER_HOME="$WORK/linked-user" bash "$WORK/broken/scripts/install-codex.sh" --uninstall --force > "$WORK/link-uninstall"
test -f "$WORK/broken/.agents/skills/restart-sop/SKILL.md"
printf 'PASS: uninstall preserves assets linked to the source checkout\n'

# Marker text is not proof that a legacy wrapper is unmodified.
mkdir -p "$WORK/custom-user/.agents/skills/source-command-restart-sop"
printf '# source-command-restart-sop\nUse this skill when the user asks to run the migrated source command\nMy custom workflow\n' > "$WORK/custom-user/.agents/skills/source-command-restart-sop/SKILL.md"
cp "$WORK/custom-user/.agents/skills/source-command-restart-sop/SKILL.md" "$WORK/custom-before"
AGENT_SOP_USER_HOME="$WORK/custom-user" bash "$SOURCE/scripts/install-codex.sh" > "$WORK/custom-install"
cmp "$WORK/custom-before" "$WORK/custom-user/.agents/skills/source-command-restart-sop/SKILL.md"
printf 'PASS: customized legacy aliases survive installation\n'

# Registering hooks must not reset custom user-wide script contents.
AGENT_SOP_USER_HOME="$WORK/hook-user" bash "$SOURCE/scripts/install-hooks.sh" --runtime codex > "$WORK/hook-install"
printf '\n# Custom policy\n' >> "$WORK/hook-user/.codex/scripts/hooks/agent-sop/sop-lib.sh"
cp "$WORK/hook-user/.codex/scripts/hooks/agent-sop/sop-lib.sh" "$WORK/hook-before"
AGENT_SOP_USER_HOME="$WORK/hook-user" bash "$SOURCE/scripts/install-hooks.sh" --runtime codex > "$WORK/hook-reinstall"
cmp "$WORK/hook-before" "$WORK/hook-user/.codex/scripts/hooks/agent-sop/sop-lib.sh"
AGENT_SOP_USER_HOME="$WORK/hook-user" bash "$SOURCE/scripts/install-hooks.sh" --runtime codex --uninstall > "$WORK/hook-remove"
cmp "$WORK/hook-before" "$WORK/hook-user/.codex/scripts/hooks/agent-sop/sop-lib.sh"
printf 'PASS: hook reinstallation and removal preserve customized scripts\n'

mkdir -p "$WORK/dangling"
printf '**Project type:** non-code\n' > "$WORK/dangling/CLAUDE.md"
ln -s missing-instructions "$WORK/dangling/AGENTS.md"
test "$(bash "$PTYPE" "$WORK/dangling")" = code
bash -c 'source "$1/scripts/hooks/sop-lib.sh"; test "$(sop_claude_md_state "$2")" = dangling' _ "$SOURCE" "$WORK/dangling"
printf 'PASS: dangling native instructions remain visible and do not downgrade gates\n'

# Project exclusions must not shadow user-owned replication baselines.
mkdir -p "$WORK/repl-project/.codex/agents" "$WORK/repl-user/.codex/agents"
printf 'new reviewer\n' > "$WORK/repl-project/.codex/agents/test.toml"
printf 'old reviewer\n' > "$WORK/repl-user/.codex/agents/test.toml"
printf '{"exclude":[]}\n' > "$WORK/repl-project/.codex/agent-sop.config.json"
REPL_SHA=$(shasum -a 256 "$WORK/repl-project/.codex/agents/test.toml" | cut -d' ' -f1)
jq -n --arg sha "$REPL_SHA" '{exclude:[],baseline_shas:{".codex/agents/test.toml":$sha}}' > "$WORK/repl-user/.codex/agent-sop.config.json"
printf '.codex/agents/test.toml\n' > "$WORK/repl-changed"
if (cd "$WORK/repl-project" && AGENT_SOP_RUNTIME=codex AGENT_SOP_USER_HOME="$WORK/repl-user" bash "$SOURCE/scripts/validate-state-transitions.sh" --check-replication --repl-changed-file "$WORK/repl-changed" --repl-home "$WORK/repl-user") > "$WORK/repl-result" 2>&1; then
    echo 'FAIL: project config shadowed user replica baseline'; exit 1
fi
grep -q 'content differs' "$WORK/repl-result"
printf 'PASS: project exclusions cannot disable native replication checks\n'

rm "$WORK/repl-user/.codex/agent-sop.config.json"
if (cd "$WORK/repl-project" && AGENT_SOP_RUNTIME=codex AGENT_SOP_USER_HOME="$WORK/repl-user" bash "$SOURCE/scripts/validate-state-transitions.sh" --check-replication) > "$WORK/missing-repl-config" 2>&1; then
    echo 'FAIL: missing user configuration became an unconfigured skip'; exit 1
fi
grep -q 'user configuration is missing' "$WORK/missing-repl-config"
printf 'PASS: project replication config requires its user-owned baseline config\n'
