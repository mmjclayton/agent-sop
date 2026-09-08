#!/usr/bin/env bash
# Read-only integration diagnostics. Registration is not proof of runtime execution.
set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/sop-lib.sh"
ROOT=$PWD; RUNTIME=${AGENT_SOP_RUNTIME:-codex}
while [ $# -gt 0 ]; do
    [ $# -ge 2 ] || exit 2
    case "$1" in --root) ROOT=$2 ;; --runtime) RUNTIME=$2 ;; *) exit 2 ;; esac
    shift 2
done
case "$RUNTIME" in
    codex) CONFIG_HOME=${CODEX_HOME:-${AGENT_SOP_USER_HOME:-$HOME}/.codex}; SETTINGS="$CONFIG_HOME/hooks.json" ;;
    claude) CONFIG_HOME=${AGENT_SOP_USER_HOME:-$HOME}/.claude; SETTINGS="$CONFIG_HOME/settings.json" ;;
    *) echo 'runtime must be claude or codex' >&2; exit 2 ;;
esac
command -v jq >/dev/null || { echo 'INVALID: jq unavailable'; exit 1; }
ROOT=$(sop_repo_root "$ROOT")
[ -n "$ROOT" ] || { echo 'UNAVAILABLE: no repository'; exit 1; }
if [ "$RUNTIME" = codex ]; then
    export AGENT_SOP_STATE_DIR=${AGENT_SOP_STATE_DIR:-${TMPDIR:-/tmp}/agent-sop-hooks-codex}
fi
POLICY=unconfigured
if [ -f "$ROOT/ship-sop.config.json" ]; then
    POLICY=invalid
    if sop_policy_valid "$ROOT/ship-sop.config.json"; then POLICY=$(jq -r .trigger.mode "$ROOT/ship-sop.config.json"); fi
fi
MISSING='[]'
if [ "$POLICY" != invalid ] && [ "$POLICY" != unconfigured ]; then
    while IFS= read -r agent; do
        suffix=toml; [ "$RUNTIME" != claude ] || suffix=md
        [ -f "$CONFIG_HOME/agents/$agent.$suffix" ] || MISSING=$(jq --arg a "$agent" '. + [$a]' <<< "$MISSING")
    done < <(jq -r '.agents | to_entries[] | select(.value.enabled) | .key' "$ROOT/ship-sop.config.json")
fi
INSTALLED=true; REGISTERED=false; MISSING_HOOKS='[]'
DEST="$CONFIG_HOME/scripts/hooks/agent-sop"
REQUIRED=(sop-lib.sh sop-stop-drift.sh sop-push-gate.sh sop-session-context.sh sop-project-type.sh resolve-resume-path.sh sop-worktree-claim.sh)
[ "$RUNTIME" != codex ] || REQUIRED+=(sop-codex-hook.sh)
for dependency in "${REQUIRED[@]}"; do
    if [ ! -f "$DEST/$dependency" ] || [ ! -r "$DEST/$dependency" ]; then
        INSTALLED=false
        MISSING_HOOKS=$(jq --arg file "$dependency" '. + [$file]' <<< "$MISSING_HOOKS")
    fi
done
if [ -f "$SETTINGS" ]; then
    EXPECTED="bash \"$DEST/sop-stop-drift.sh\""
    [ "$RUNTIME" != codex ] || EXPECTED="bash \"$DEST/sop-codex-hook.sh\" Stop"
    jq -e --arg expected "$EXPECTED" '[.hooks.Stop[]?.hooks[]?.command // ""] |
      any(.[]; . == $expected)' "$SETTINGS" >/dev/null 2>&1 && REGISTERED=true
fi
OBSERVED=false
KEY=$(sop_repo_key "$ROOT")
if find "$(sop_state_dir)/sessions" -name "$KEY.ctx" -type f -print -quit 2>/dev/null | grep -q .; then OBSERVED=true; fi
CURRENT=false
[ ! -f "$DEST/sop-lib.sh" ] || { cmp -s "$DEST/sop-lib.sh" "$(dirname "${BASH_SOURCE[0]}")/sop-lib.sh" && CURRENT=true; }
RESUME=''; RESUME_NOTE=''
RESOLVER="$DEST/resolve-resume-path.sh"
if [ -f "$RESOLVER" ] && [ -r "$RESOLVER" ]; then
    ERROR=$(mktemp)
    RESUME=$(bash "$RESOLVER" --root "$ROOT" --read 2> "$ERROR") || RESUME=''
    RESUME_NOTE=$(cat "$ERROR"); rm -f "$ERROR"
else RESUME_NOTE='Installed trusted resolver unavailable; update Agent SOP'; fi
jq -n --arg root "$ROOT" --arg runtime "$RUNTIME" --arg policy "$POLICY" --arg resume "$RESUME" --arg resume_note "$RESUME_NOTE" \
    --argjson installed "$INSTALLED" --argjson registered "$REGISTERED" --argjson observed "$OBSERVED" \
    --argjson current "$CURRENT" --argjson missing "$MISSING" --argjson missing_hooks "$MISSING_HOOKS" --arg resolver "$RESOLVER" \
    '{root:$root,runtime:$runtime,policy:$policy,hooks_installed:$installed,
      stop_hook_registered:$registered,local_context_marker_seen:$observed,
      installed_policy_matches_this_doctor:$current,missing_reviewers:$missing,missing_hook_files:$missing_hooks,
      resume:$resume,resume_diagnostic:$resume_note,resume_resolver:$resolver,
      runtime_enforcement:"unverified by doctor; validate in a real session"}'
[ "$POLICY" != invalid ] && [ "$MISSING" = '[]' ]
