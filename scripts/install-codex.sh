#!/usr/bin/env bash
# Install/update owned Codex assets; shared verbatim by agent-sop and ship-sop.
# --force replaces locally modified owned assets; uninstall preserves them by default.
set -euo pipefail
SOURCE="$(cd "$(dirname "$0")/.." && pwd -P)"
PACKAGE="$(basename "$SOURCE")"
# Clones can have arbitrary names. Identify the package by its source assets.
if [ -f "$SOURCE/.agents/skills/restart-sop/SKILL.md" ]; then PACKAGE=agent-sop; else PACKAGE=ship-sop; fi
USER_ROOT="${AGENT_SOP_USER_HOME:-$HOME}"
CODEX_DIR="${CODEX_HOME:-$USER_ROOT/.codex}"
FORCE=false; REMOVE=false
for arg in "$@"; do
    case "$arg" in --force) FORCE=true ;; --uninstall) REMOVE=true ;; *) echo "Unknown option: $arg" >&2; exit 2 ;; esac
done
command -v jq >/dev/null || { echo 'install-codex: jq is required' >&2; exit 1; }
mkdir -p "$CODEX_DIR"
MANIFEST="$CODEX_DIR/$PACKAGE.install.json"
CONFIG="$CODEX_DIR/$PACKAGE.config.json"
if [ "$PACKAGE" = ship-sop ]; then CONFIG="$CODEX_DIR/ship-sop.source.json"; fi
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
if [ -f "$MANIFEST" ]; then jq -e 'type == "object"' "$MANIFEST" >/dev/null; cp "$MANIFEST" "$WORK/manifest"; else echo '{}' > "$WORK/manifest"; fi
sha() { if command -v shasum >/dev/null; then shasum -a 256 "$1"; else sha256sum "$1"; fi | cut -d' ' -f1; }
asset_target() {
    case "$1" in
        .agents/skills/*) printf '%s/%s' "$USER_ROOT" "$1" ;;
        .codex/agents/*) printf '%s/agents/%s' "$CODEX_DIR" "${1#.codex/agents/}" ;;
        scripts/codex-review.sh) printf '%s/scripts/ship-sop/codex-review.sh' "$CODEX_DIR" ;;
        *) echo "Invalid asset: $1" >&2; return 1 ;;
    esac
}
# Paths come only from repository files, never from an installed manifest.
# Check discovery before the first asset mutation; process substitution loses failures.
[ -d "$SOURCE/.agents/skills" ] && [ -d "$SOURCE/.codex/agents" ] || { echo 'Missing Codex asset directories' >&2; exit 1; }
(cd "$SOURCE" && find .agents/skills .codex/agents -type f | LC_ALL=C sort) > "$WORK/assets" || { echo 'Codex asset discovery failed' >&2; exit 1; }
if [ "$PACKAGE" = ship-sop ]; then
    [ -f "$SOURCE/scripts/codex-review.sh" ] || { echo 'Missing reviewer runner' >&2; exit 1; }
    printf 'scripts/codex-review.sh\n' >> "$WORK/assets"
fi
[ -s "$WORK/assets" ] || { echo 'No Codex assets found' >&2; exit 1; }
while IFS= read -r src; do
    case "$src" in *.md|*.toml|*.yaml|*.sh) ;; *) continue ;; esac
    dest=$(asset_target "$src")
    old=$(jq -r --arg p "$src" '.[$p] // empty' "$WORK/manifest")
    current=''; [ ! -f "$dest" ] || current=$(sha "$dest")
    wanted=$(sha "$SOURCE/$src")
    if [ "$REMOVE" = true ]; then
        if [ -f "$dest" ] && { [ "$FORCE" = true ] || [ "$current" = "$old" ] || [ "$current" = "$wanted" ]; }; then
            rm "$dest"
            jq --arg p "$src" 'del(.[$p])' "$WORK/manifest" > "$WORK/next"; mv "$WORK/next" "$WORK/manifest"
            echo "remove $dest"
        elif [ -f "$dest" ]; then echo "keep $dest (locally modified)"; fi
        continue
    fi
    # One-time migration of known mechanically converted command wrappers.
    # Back up the old instruction body; customized canonical skills stay protected.
    case "$src" in
        .agents/skills/source-command-*/SKILL.md)
            if [ -f "$dest" ] && grep -q 'Use this skill when the user asks to run the migrated source command' "$dest" && grep -q '^# source-command-' "$dest"; then
                cp "$dest" "$dest.bak"; old="$current"
            fi ;;
    esac
    if [ -f "$dest" ] && [ "$current" != "$wanted" ] && [ "$current" != "$old" ] && [ "$FORCE" = false ]; then
        echo "RECONCILE $dest (locally modified; kept)"
        continue
    fi
    mkdir -p "$(dirname "$dest")"
    if [ "$current" != "$wanted" ]; then
        [ ! -f "$dest" ] || cp "$dest" "$dest.bak"
        cp "$SOURCE/$src" "$dest"
        echo "install $dest"
    fi
    jq --arg p "$src" --arg sha "$wanted" '.[$p]=$sha' "$WORK/manifest" > "$WORK/next"; mv "$WORK/next" "$WORK/manifest"
done < "$WORK/assets"
# Write through symlinks to preserve dotfiles-managed configuration.
cat "$WORK/manifest" > "$MANIFEST"
if [ "$REMOVE" = false ] && [ ! -f "$CONFIG" ]; then
    jq -n --arg path "$SOURCE" '{local_path:$path,exclude:[],baseline_shas:{},update_reminder:"weekly"}' > "$CONFIG"
fi

if [ "$PACKAGE" = ship-sop ] && [ "$REMOVE" = false ]; then
    FALLBACK="$CODEX_DIR/ship-sop.config.json"
    # Migrate metadata written into the runtime config by the initial Codex port.
    if [ -f "$FALLBACK" ] && jq -e --arg src "$SOURCE" '.local_path == $src and .trigger == null and .agents == null' "$FALLBACK" >/dev/null; then
        cp "$FALLBACK" "$FALLBACK.bak"
        jq '.trigger.mode="manual"' "$SOURCE/docs/templates/ship-sop.config.json" > "$FALLBACK"
    elif [ ! -f "$FALLBACK" ]; then
        jq '.trigger.mode="manual"' "$SOURCE/docs/templates/ship-sop.config.json" > "$FALLBACK"
    fi
fi
