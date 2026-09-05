#!/usr/bin/env bash
#
# sync-sop-files.sh [--root <consumer>] [--config <path>] [--apply]
#
# The executable half of /update-agent-sop. Reads the pristine-replica manifest
# (the table in .claude/commands/update-agent-sop.md of the upstream checkout),
# classifies every file in the consumer, and with --apply writes the safe ones
# and refreshes baseline_shas + last_update_check in the config. Without
# --apply it only reports.
#
# Classification per file:
#   EXCLUDED   dest is listed in config.exclude
#   IN-SYNC    consumer sha == upstream sha
#   MISSING    consumer has no copy                      -> created on --apply
#   OLDER      consumer sha == baseline sha, OR matches any past upstream
#              version of the file (git history)         -> updated on --apply
#   MODIFIED   none of the above: a local edit           -> kept; RECONCILE when
#              upstream also moved since the baseline
#
# Why git history (P106, 2026-09-05): baseline_shas is one set shared by every
# consumer on the machine, so syncing one consumer advances the baseline for
# all. A consumer that is merely older than that baseline then looked locally
# modified to a baseline-only three-way and was left stale. A file that equals
# any version upstream has ever shipped was never edited locally.

set -u
ROOT=""; CONFIG=""; APPLY=0
while [ $# -gt 0 ]; do
    case "$1" in
        --root) ROOT="$2"; shift ;;
        --config) CONFIG="$2"; shift ;;
        --apply) APPLY=1 ;;
        -h|--help) sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "sync-sop-files: unknown option $1" >&2; exit 2 ;;
    esac
    shift
done
command -v jq >/dev/null 2>&1 || { echo "sync-sop-files: jq is required" >&2; exit 1; }
[ -n "$ROOT" ] || ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || ROOT=$PWD
if [ -z "$CONFIG" ]; then
    if [ -f "$ROOT/.claude/agent-sop.config.json" ]; then CONFIG="$ROOT/.claude/agent-sop.config.json"
    else CONFIG="$HOME/.claude/agent-sop.config.json"; fi
fi
[ -f "$CONFIG" ] || { echo "sync-sop-files: no config at $CONFIG" >&2; exit 1; }
# The upstream location is a fact about the machine: a project-scope config
# (exclusions, notes, its own baselines) may omit local_path, in which case
# the user-global config supplies it.
UP=$(jq -r '.local_path // empty' "$CONFIG")
[ -n "$UP" ] || UP=$(jq -r '.local_path // empty' "$HOME/.claude/agent-sop.config.json" 2>/dev/null)
UP="${UP/#\~/$HOME}"
[ -f "$UP/docs/sop/claude-agent-sop.md" ] || { echo "sync-sop-files: upstream checkout not found at '$UP' (config local_path); the GitHub-raw fallback is the command's prose path" >&2; exit 1; }
MANIFEST="$UP/.claude/commands/update-agent-sop.md"
[ -f "$MANIFEST" ] || { echo "sync-sop-files: manifest not found at $MANIFEST" >&2; exit 1; }

sha() { shasum -a 256 "$1" | awk '{print $1}'; }
# in_history <upstream-path> <sha> — true when some past upstream version of
# the file hashes to <sha>. Bounded to the file's own log; stops at first hit.
in_history() {
    local path="$1" want="$2" rev
    while read -r rev; do
        [ -n "$rev" ] || continue
        [ "$(git -C "$UP" show "$rev:$path" 2>/dev/null | shasum -a 256 | awk '{print $1}')" = "$want" ] && return 0
    done < <(git -C "$UP" log --format=%H -- "$path" 2>/dev/null)
    return 1
}

n_sync=0; n_missing=0; n_older=0; n_modified=0; n_reconcile=0; n_excluded=0; n_applied=0
TODAY=$(date +%Y-%m-%d)
NEWCFG=$(mktemp); cp "$CONFIG" "$NEWCFG"
while IFS='|' read -r dest src scope; do
    dest=$(printf '%s' "$dest" | xargs); src=$(printf '%s' "$src" | xargs); scope=$(printf '%s' "$scope" | xargs)
    [ -n "$dest" ] && [ -n "$src" ] || continue
    [ -f "$UP/$src" ] || { echo "  absent-upstream  $dest (upstream has no $src)"; continue; }
    case "$scope" in
        user) target="${dest/#\~/$HOME}" ;;
        *)    target="$ROOT/$dest" ;;
    esac
    if jq -e --arg d "$dest" '(.exclude // []) | index($d) != null' "$CONFIG" >/dev/null; then
        echo "  excluded         $dest"; n_excluded=$((n_excluded+1)); continue
    fi
    up_sha=$(sha "$UP/$src")
    base=$(jq -r --arg f "$src" '.baseline_shas[$f] // empty' "$CONFIG")
    if [ ! -f "$target" ]; then
        cls=MISSING; n_missing=$((n_missing+1))
    else
        cur=$(sha "$target")
        if [ "$cur" = "$up_sha" ]; then
            cls=IN-SYNC; n_sync=$((n_sync+1))
        elif [ -n "$base" ] && [ "$cur" = "$base" ]; then
            cls=OLDER; n_older=$((n_older+1))
        elif in_history "$src" "$cur"; then
            cls=OLDER; n_older=$((n_older+1))
        else
            cls=MODIFIED; n_modified=$((n_modified+1))
            if [ -n "$base" ] && [ "$base" != "$up_sha" ]; then cls=RECONCILE; n_reconcile=$((n_reconcile+1)); fi
        fi
    fi
    case "$cls" in
        IN-SYNC)
            # Record the baseline when it is missing or stale so the next run
            # can classify by baseline before touching history.
            [ "$base" = "$up_sha" ] || jq --arg f "$src" --arg s "$up_sha" '.baseline_shas[$f] = $s' "$NEWCFG" > "$NEWCFG.tmp" && mv "$NEWCFG.tmp" "$NEWCFG" ;;
        MISSING|OLDER)
            echo "  $(printf '%-16s' "$cls") $dest"
            if [ "$APPLY" = 1 ]; then
                mkdir -p "$(dirname "$target")"; cp "$UP/$src" "$target"; [ -x "$UP/$src" ] && chmod +x "$target"
                jq --arg f "$src" --arg s "$up_sha" '.baseline_shas[$f] = $s' "$NEWCFG" > "$NEWCFG.tmp" && mv "$NEWCFG.tmp" "$NEWCFG"
                n_applied=$((n_applied+1))
            fi ;;
        MODIFIED)  echo "  modified         $dest (kept; upstream unchanged since baseline)" ;;
        RECONCILE) echo "  RECONCILE        $dest (local edit AND upstream moved: three-way, ask the operator)" ;;
    esac
done < <(grep -E '^\| `[^`]+` \| `[^`]+` \| (project|user) \|' "$MANIFEST" | sed -E 's/^\| `([^`]+)` \| `([^`]+)` \| (project|user) \|.*/\1|\2|\3/')

if [ "$APPLY" = 1 ]; then
    jq --arg d "$TODAY" '.last_update_check = $d' "$NEWCFG" > "$NEWCFG.tmp" && mv "$NEWCFG.tmp" "$NEWCFG"
    cp "$CONFIG" "$CONFIG.bak" 2>/dev/null; mv "$NEWCFG" "$CONFIG"
else
    rm -f "$NEWCFG"
fi
printf 'sync-sop-files: %s in sync, %s missing, %s older (pristine), %s modified, %s to reconcile, %s excluded%s\n' \
    "$n_sync" "$n_missing" "$n_older" "$n_modified" "$n_reconcile" "$n_excluded" "$([ "$APPLY" = 1 ] && printf ' — applied %s, baselines and last_update_check written to %s' "$n_applied" "$CONFIG" || printf ' — dry run; add --apply to write')"
exit 0
