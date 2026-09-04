#!/usr/bin/env bash
#
# Install the agent-sop user-scope hooks and register them in settings.json.
#
# Why user-scope: project-scope hooks in <repo>/.claude/settings.json load
# only from the directory Claude Code was launched in. Sessions launched from
# ~ that cd into a project never see them — which is exactly how ship-sop's
# project-scope Stop hook sat inert for four months. User-scope hooks fire in
# every session and resolve the repo from the hook's own `cwd` input.
#
# Usage:
#   bash scripts/install-hooks.sh [--settings <path>] [--dest <dir>] [--uninstall] [--dry-run]
#
# Defaults: --settings ~/.claude/settings.json, --dest ~/.claude/scripts/hooks/agent-sop
#
# Idempotent: an entry is added only if no existing hook command names the
# script. Existing hooks are preserved. The settings file is backed up to
# <settings>.bak-<timestamp> before any write.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/hooks"
SETTINGS="${HOME}/.claude/settings.json"
DEST="${HOME}/.claude/scripts/hooks/agent-sop"
UNINSTALL=false
DRY_RUN=false

while [ $# -gt 0 ]; do
    case "$1" in
        --settings) SETTINGS="$2"; shift ;;
        --dest)     DEST="$2"; shift ;;
        --uninstall) UNINSTALL=true ;;
        --dry-run)  DRY_RUN=true ;;
        -h|--help)
            sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
    shift
done

if ! command -v jq >/dev/null 2>&1; then
    echo "install-hooks: jq is required (brew install jq)" >&2
    exit 1
fi

FILES="sop-lib.sh sop-session-context.sh sop-stop-drift.sh sop-push-gate.sh sop-project-type.sh"
for f in $FILES; do
    if [ ! -f "$SRC/$f" ]; then
        echo "install-hooks: missing $SRC/$f" >&2
        exit 1
    fi
done

CTX_CMD="bash \"$DEST/sop-session-context.sh\""
STOP_CMD="bash \"$DEST/sop-stop-drift.sh\""
PUSH_CMD="bash \"$DEST/sop-push-gate.sh\""

# A dotfiles-managed settings.json is often a symlink. `mv` over the link path
# would replace the link with a plain file and leave the dotfiles source
# stale, so resolve the chain and write to the real file.
resolve_settings_target() {
    local p="$SETTINGS" link i=0
    while [ -L "$p" ] && [ "$i" -lt 10 ]; do
        link=$(readlink "$p")
        case "$link" in
            /*) p="$link" ;;
            *)  p="$(cd "$(dirname "$p")" && pwd)/$link" ;;
        esac
        i=$((i + 1))
    done
    printf '%s' "$p"
}

backup_settings() {
    local target
    target=$(resolve_settings_target)
    [ -f "$target" ] || return 0
    cp "$target" "$target.bak-$(date +%Y%m%d-%H%M%S)"
}

write_settings() {
    local tmp target
    target=$(resolve_settings_target)
    tmp=$(mktemp)
    if printf '%s' "$1" > "$tmp" && jq empty "$tmp" 2>/dev/null; then
        mv "$tmp" "$target"
    else
        rm -f "$tmp"
        echo "install-hooks: refusing to write invalid JSON to $target" >&2
        exit 1
    fi
}

if [ "$UNINSTALL" = true ]; then
    if [ -f "$SETTINGS" ]; then
        # Remove only entries this installer wrote: commands that invoke a script
        # under our own $DEST. A filename-only match would also strip a user's
        # unrelated hook that happened to share a name.
        NEW=$(jq --arg prefix "bash \"$DEST/" '
            .hooks = ((.hooks // {}) | with_entries(
                .value = [ .value[]? | .hooks = [ .hooks[]? | select((.command // "") | startswith($prefix) | not) ] | select((.hooks | length) > 0) ]
            ) | with_entries(select((.value | length) > 0)))
        ' "$SETTINGS" 2>/dev/null) || { echo "install-hooks: could not parse $SETTINGS" >&2; exit 1; }
        if [ "$DRY_RUN" = true ]; then
            printf '%s\n' "$NEW"
        else
            backup_settings
            write_settings "$NEW"
        fi
    fi
    if [ "$DRY_RUN" = false ]; then
        for f in $FILES; do rm -f "$DEST/$f"; done
        rmdir "$DEST" 2>/dev/null || true
    fi
    echo "install-hooks: agent-sop hooks removed from $SETTINGS and $DEST"
    exit 0
fi

# ── Install scripts ───────────────────────────────────────────────────────────
if [ "$DRY_RUN" = false ]; then
    mkdir -p "$DEST"
    for f in $FILES; do
        cp "$SRC/$f" "$DEST/$f"
        chmod +x "$DEST/$f"
    done
fi

# ── Register hooks ────────────────────────────────────────────────────────────
[ -f "$SETTINGS" ] || { mkdir -p "$(dirname "$SETTINGS")"; echo '{}' > "$SETTINGS"; }

NEW=$(jq \
    --arg ctx "$CTX_CMD" --arg stop "$STOP_CMD" --arg push "$PUSH_CMD" '
    def ensure(ev; m; cmd; t):
        .hooks[ev] = ((.hooks[ev] // []) |
            if any(.[]?.hooks[]?; (.command // "") == cmd) then .
            else . + [{ matcher: m, hooks: [{ type: "command", command: cmd, timeout: t }] }]
            end);
    .hooks = (.hooks // {})
    | ensure("SessionStart"; "*"; $ctx; 15)
    | ensure("UserPromptSubmit"; "*"; $ctx; 10)
    | ensure("Stop"; "*"; $stop; 20)
    | ensure("PreToolUse"; "Bash"; $push; 10)
' "$SETTINGS" 2>/dev/null) || { echo "install-hooks: could not parse $SETTINGS" >&2; exit 1; }

if [ "$DRY_RUN" = true ]; then
    printf '%s\n' "$NEW"
    exit 0
fi

if [ "$NEW" != "$(cat "$SETTINGS")" ]; then
    backup_settings
    write_settings "$NEW"
    echo "install-hooks: registered hooks in $SETTINGS (backup written alongside)"
else
    echo "install-hooks: $SETTINGS already up to date"
fi
echo "install-hooks: scripts in $DEST"
echo "  SessionStart + UserPromptSubmit  -> sop-session-context.sh (replaces /restart-sop Steps 0-4)"
echo "  Stop                             -> sop-stop-drift.sh      (session-end drift, exit 2 with the gap)"
echo "  PreToolUse(Bash)                 -> sop-push-gate.sh       (refuses push/PR when ship-sop auto has no report for HEAD)"
exit 0
