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
INSTALLED=false; REGISTERED=false
DEST="$CONFIG_HOME/scripts/hooks/agent-sop"
if [ -f "$DEST/sop-lib.sh" ] && [ -f "$DEST/sop-stop-drift.sh" ] && [ -f "$DEST/sop-push-gate.sh" ]; then INSTALLED=true; fi
if [ -f "$SETTINGS" ]; then
    jq -e --arg dest "$DEST/" '[.hooks[][]?.hooks[]?.command // ""] |
      any(.[]; contains($dest) and contains("sop-stop-drift.sh"))' "$SETTINGS" >/dev/null 2>&1 && REGISTERED=true
fi
OBSERVED=false
KEY=$(sop_repo_key "$ROOT")
if find "$(sop_state_dir)/sessions" -name "$KEY.ctx" -type f -print -quit 2>/dev/null | grep -q .; then OBSERVED=true; fi
CURRENT=false
[ ! -f "$DEST/sop-lib.sh" ] || { cmp -s "$DEST/sop-lib.sh" "$(dirname "${BASH_SOURCE[0]}")/sop-lib.sh" && CURRENT=true; }
RESUME=''
if [ -f "$ROOT/scripts/resolve-resume-path.sh" ]; then RESUME=$(bash "$ROOT/scripts/resolve-resume-path.sh" --root "$ROOT" --read 2>/dev/null || true); fi
jq -n --arg root "$ROOT" --arg runtime "$RUNTIME" --arg policy "$POLICY" --arg resume "$RESUME" \
    --argjson installed "$INSTALLED" --argjson registered "$REGISTERED" --argjson observed "$OBSERVED" \
    --argjson current "$CURRENT" --argjson missing "$MISSING" \
    '{root:$root,runtime:$runtime,policy:$policy,hooks_installed:$installed,
      stop_hook_registered:$registered,local_context_marker_seen:$observed,
      installed_policy_matches_this_doctor:$current,missing_reviewers:$missing,resume:$resume,
      runtime_enforcement:"unverified by doctor; validate in a real session"}'
[ "$POLICY" != invalid ] && [ "$MISSING" = '[]' ]
