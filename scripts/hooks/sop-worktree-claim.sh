#!/usr/bin/env bash
# Explicit local writer/task/path ownership. Claims persist until their owner releases.
set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/sop-lib.sh"
ACTION=${1:-status}; shift || true
ROOT=$(git rev-parse --show-toplevel)
COMMON=$(git -C "$ROOT" rev-parse --git-common-dir)
case "$COMMON" in /*) ;; *) COMMON="$ROOT/$COMMON" ;; esac
REGISTRY="$COMMON/agent-sop/claims"
mkdir -p "$REGISTRY"
if [ "$ACTION" = status ]; then
    sop_registry_read "$REGISTRY"
    exit 0
fi
SESSION=${1:-}; shift || true
[ -n "$SESSION" ] || { echo 'A stable session identifier is required' >&2; exit 2; }
# Serialise mutations across worktrees so two disjoint writers cannot race a path claim.
mkdir "$REGISTRY/.lock" 2>/dev/null || { echo 'BUSY: registry locked; retry after the other claim operation' >&2; exit 1; }
TMP=''
trap 'rmdir "$REGISTRY/.lock"; [ -z "$TMP" ] || rm -f "$TMP"' EXIT
FILE="$REGISTRY/$(sop_repo_key "$ROOT").json"
if [ "$ACTION" = release ]; then
    [ -f "$FILE" ] || exit 0
    jq -e --arg session "$SESSION" '.session == $session' "$FILE" >/dev/null || {
        echo 'BLOCK: only the recorded session owner can release this worktree' >&2; exit 1;
    }
    rm "$FILE"
    echo 'Released writer claim'
    exit 0
fi
[ "$ACTION" = claim ] || { echo 'Use: status | claim SESSION TASK [paths...] | release SESSION' >&2; exit 2; }
TASK=${1:-}; shift || true
[ -n "$TASK" ] || { echo 'A task identifier is required' >&2; exit 2; }
PATHS='[]'
[ $# -gt 0 ] || set -- '*'
for path in "$@"; do
    case "$path" in ''|.|/*|..|../*|*/../*|*/..|./*|*/./*|*/.|*//*|*\\*) echo "Invalid repository-relative path: $path" >&2; exit 2 ;; esac
    path=${path%/}
    PATHS=$(jq --arg path "$path" '. + [$path]' <<< "$PATHS")
done
for other in "$REGISTRY"/*.json; do
    [ -e "$other" ] || [ -L "$other" ] || continue
    [ -f "$other" ] && [ -r "$other" ] || { echo "BLOCK: unreadable claim $other" >&2; exit 1; }
    jq -se 'length == 1' "$other" >/dev/null || { echo "BLOCK: malformed claim $other" >&2; exit 1; }
    jq -e '(.root | type == "string") and (.session | type == "string") and
      (.task | type == "string") and (.paths | type == "array" and length > 0 and all(.[]; type == "string"))' "$other" >/dev/null || {
        echo "BLOCK: invalid claim record $other; inspect and repair" >&2; exit 1;
    }
    if [ "$other" = "$FILE" ] && jq -e --arg session "$SESSION" '.session == $session' "$other" >/dev/null; then continue; fi
    if jq -e --arg root "$ROOT" --arg task "$TASK" --argjson paths "$PATHS" '
      . as $claim | .root == $root or .task == $task or
      any(.paths[]; . as $old | any($paths[]; . as $new |
        $new == "*" or $old == "*" or $new == $old or
        ($new | startswith($old + "/")) or ($old | startswith($new + "/"))))
    ' "$other" >/dev/null; then
        echo "BLOCK: conflicting writer/task/path claim: $(cat "$other")" >&2; exit 1
    fi
done
TMP=$(mktemp "$REGISTRY/.claim.XXXXXX")
jq -n --arg root "$ROOT" --arg session "$SESSION" --arg task "$TASK" \
    --arg base "$(git rev-parse HEAD)" --argjson paths "$PATHS" \
    '{root:$root,session:$session,task:$task,base:$base,paths:$paths}' > "$TMP"
mv "$TMP" "$FILE"
echo "Claimed: $(cat "$FILE")"
