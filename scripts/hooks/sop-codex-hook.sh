#!/usr/bin/env bash
# Codex transport adapter. Shared scripts own every policy decision.
set -u
export AGENT_SOP_RUNTIME=codex
export AGENT_SOP_CONFIG_HOME="${CODEX_HOME:-${AGENT_SOP_USER_HOME:-$HOME}/.codex}"
# Keep per-runtime delivery markers separate; durable records remain shared.
export AGENT_SOP_STATE_DIR="${AGENT_SOP_STATE_DIR:-${TMPDIR:-/tmp}/agent-sop-hooks-codex}"
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
case "${1:-}" in
    SessionStart|UserPromptSubmit)
        command -v jq >/dev/null 2>&1 || { echo 'agent-sop: jq is required' >&2; exit 1; }
        context=$(bash "$HOOK_DIR/sop-session-context.sh") || exit "$?"
        [ -n "$context" ] || exit 0
        jq -n --arg event "$1" --arg context "$context" \
            '{hookSpecificOutput:{hookEventName:$event,additionalContext:$context}}'
        ;;
    Stop) exec bash "$HOOK_DIR/sop-stop-drift.sh" ;;
    PreToolUse) exec bash "$HOOK_DIR/sop-push-gate.sh" ;;
    *) echo 'sop-codex-hook: expected SessionStart, UserPromptSubmit, Stop or PreToolUse' >&2; exit 1 ;;
esac
