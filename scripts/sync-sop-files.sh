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
# under <path> <base> — true when <path> sits inside <base>, decided WITHOUT
# creating anything: the longest existing ancestor of <path> is resolved
# physically (so a symlink inside the consumer cannot point out), and the
# not-yet-existing tail may not contain a `..` component. A manifest row is
# data from a checkout; a `..` or an absolute path in it must never write
# outside the consumer or ~/.claude, nor read outside the upstream checkout
# (review findings, CRITICAL: the first cut ran mkdir before this check).
under() {
    local p="$1" base="$2" anc tail b
    b=$(cd "$base" 2>/dev/null && pwd -P) || return 1
    anc="$p"; tail=""
    while [ ! -d "$anc" ]; do
        tail="$(basename "$anc")${tail:+/$tail}"
        case "$(basename "$anc")" in ..|.) return 1 ;; esac
        anc=$(dirname "$anc"); [ "$anc" != "/" ] && [ "$anc" != "." ] || break
    done
    anc=$(cd "$anc" 2>/dev/null && pwd -P) || return 1
    p="$anc${tail:+/$tail}"
    case "$p" in "$b"/*) return 0 ;; *) return 1 ;; esac
}
ROOT_R=$(cd "$ROOT" && pwd -P); CLAUDE_R="$HOME/.claude"; mkdir -p "$CLAUDE_R"; CLAUDE_R=$(cd "$CLAUDE_R" && pwd -P)
# in_history <upstream-path> <sha> — true when some past upstream version of
# the file hashes to <sha>. Bounded to the file's own log; stops at first hit.
in_history() {
    local path="$1" want="$2" rev="" line
    # --follow crosses renames; --name-only prints the path the file had at
    # each commit, which is the name `git show` needs for pre-rename revisions.
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        case "$line" in
            [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]*) [ "${#line}" -eq 40 ] && { rev="$line"; continue; } ;;
        esac
        [ -n "$rev" ] || continue
        [ "$(git -C "$UP" show "$rev:$line" 2>/dev/null | shasum -a 256 | awk '{print $1}')" = "$want" ] && return 0
    done < <(git -C "$UP" log --follow --format=%H --name-only -- "$path" 2>/dev/null)
    return 1
}
if [ "$(git -C "$UP" rev-parse --is-shallow-repository 2>/dev/null)" = "true" ]; then
    echo "sync-sop-files: upstream checkout at $UP is shallow; OLDER-by-history cannot see its full history, so an older pristine copy may be reported as a local edit" >&2
fi

n_sync=0; n_missing=0; n_older=0; n_modified=0; n_reconcile=0; n_excluded=0; n_applied=0; n_refused=0; n_unreadable=0; n_rows=0; n_seen=0; n_absent=0
TODAY=$(date +%Y-%m-%d)
# The working copy lives beside the config so the final replace is a
# same-device rename (atomic), and it is validated before it replaces anything.
NEWCFG=$(mktemp "$(dirname "$CONFIG")/.agent-sop.config.XXXXXX") || { echo "sync-sop-files: cannot create a temp file beside $CONFIG" >&2; exit 1; }
cp "$CONFIG" "$NEWCFG" || { rm -f "$NEWCFG"; echo "sync-sop-files: cannot read $CONFIG" >&2; exit 1; }
trap 'rm -f "$NEWCFG" "$NEWCFG.tmp"' EXIT
while IFS='|' read -r dest src scope; do
    dest=$(printf '%s' "$dest" | xargs); src=$(printf '%s' "$src" | xargs); scope=$(printf '%s' "$scope" | xargs)
    [ -n "$dest" ] && [ -n "$src" ] || continue
    if jq -e --arg d "$dest" '(.exclude // []) | index($d) != null' "$CONFIG" >/dev/null; then
        echo "  excluded         $dest"; n_excluded=$((n_excluded+1)); continue
    fi
    if ! under "$UP/$src" "$UP"; then echo "  REFUSED          $dest (upstream path escapes the checkout: $src)"; n_refused=$((n_refused+1)); continue; fi
    [ -f "$UP/$src" ] || { echo "  absent-upstream  $dest (upstream has no $src)"; n_absent=$((n_absent+1)); continue; }
    case "$scope" in
        user) target="${dest/#\~/$HOME}"; base_dir="$CLAUDE_R" ;;
        *)    target="$ROOT/$dest"; base_dir="$ROOT_R" ;;
    esac
    if ! under "$target" "$base_dir"; then echo "  REFUSED          $dest (destination leaves $([ "$scope" = user ] && echo "$HOME/.claude" || echo 'the consumer root'))"; n_refused=$((n_refused+1)); continue; fi
    up_sha=$(sha "$UP/$src")
    base=$(jq -r --arg f "$src" '.baseline_shas[$f] // empty' "$CONFIG")
    if [ ! -f "$target" ]; then
        cls=MISSING; n_missing=$((n_missing+1))
    elif [ ! -r "$target" ]; then
        echo "  UNREADABLE       $dest (permission denied; not classified)"; n_unreadable=$((n_unreadable+1)); continue
    else
        cur=$(sha "$target")
        if [ "$cur" = "$up_sha" ]; then
            cls=IN-SYNC; n_sync=$((n_sync+1))
        elif [ -n "$base" ] && [ "$cur" = "$base" ]; then
            cls=OLDER; n_older=$((n_older+1))
        elif in_history "$src" "$cur"; then
            cls=OLDER; n_older=$((n_older+1))
        else
            # A local edit. With a baseline that upstream has moved past, or with
            # no baseline at all (a first run onto a pre-customised project), the
            # operator decides once: RECONCILE. With a baseline upstream has not
            # moved past, the edit is a standing override: reported, kept.
            if [ -z "$base" ] || [ "$base" != "$up_sha" ]; then cls=RECONCILE; n_reconcile=$((n_reconcile+1))
            else cls=MODIFIED; n_modified=$((n_modified+1)); fi
        fi
    fi
    case "$cls" in
        IN-SYNC)
            # Record the baseline when it is missing or stale so the next run
            # can classify by baseline before touching history.
            if [ "$base" != "$up_sha" ]; then
                jq --arg f "$src" --arg s "$up_sha" '.baseline_shas[$f] = $s' "$NEWCFG" > "$NEWCFG.tmp" && mv "$NEWCFG.tmp" "$NEWCFG"
            fi ;;
        MISSING|OLDER)
            echo "  $(printf '%-16s' "$cls") $dest"
            if [ "$APPLY" = 1 ]; then
                mkdir -p "$(dirname "$target")"; cp "$UP/$src" "$target"; [ -x "$UP/$src" ] && chmod +x "$target"
                jq --arg f "$src" --arg s "$up_sha" '.baseline_shas[$f] = $s' "$NEWCFG" > "$NEWCFG.tmp" && mv "$NEWCFG.tmp" "$NEWCFG"
                n_applied=$((n_applied+1))
            fi ;;
        MODIFIED)  echo "  modified         $dest (kept; upstream unchanged since baseline)" ;;
        RECONCILE) echo "  RECONCILE        $dest ($([ -n "$base" ] && echo 'local edit and upstream moved since the baseline' || echo 'local edit, no baseline yet'): ask the operator once, then set the baseline or exclude it)" ;;
    esac
done < <(grep -E '^\| `[^`]+` \| `[^`]+` \| (project|user) \|' "$MANIFEST" | sed -E 's/^\| `([^`]+)` \| `([^`]+)` \| (project|user) \|.*/\1|\2|\3/')

# Every table row that names two paths must have been classified: a row with
# a scope the parser does not know would otherwise vanish from the report,
# and a manifest that no longer parses at all would read as "all clear"
# (review findings, CRITICAL). n_seen counts rows the loop handled.
n_rows=$(grep -cE '^\| `[^`]+` \| `[^`]+` \|' "$MANIFEST")
if [ "$n_rows" -eq 0 ]; then
    echo "sync-sop-files: no manifest rows parsed from $MANIFEST — the table format may have changed; nothing was classified" >&2; exit 1
fi
n_seen=$((n_sync + n_missing + n_older + n_modified + n_reconcile + n_excluded + n_refused + n_unreadable + n_absent))
if [ "$n_seen" -ne "$n_rows" ]; then
    echo "sync-sop-files: $n_rows manifest rows but $n_seen classified — rows with an unrecognised scope (not project|user) were skipped:" >&2
    grep -E '^\| `[^`]+` \| `[^`]+` \|' "$MANIFEST" | grep -vE '^\| `[^`]+` \| `[^`]+` \| (project|user) \|' | sed 's/^/    /' >&2
    exit 1
fi

if [ "$APPLY" = 1 ]; then
    jq --arg d "$TODAY" '.last_update_check = $d' "$NEWCFG" > "$NEWCFG.tmp" && mv "$NEWCFG.tmp" "$NEWCFG"
    if ! [ -s "$NEWCFG" ] || ! jq empty "$NEWCFG" 2>/dev/null; then
        echo "sync-sop-files: refusing to replace $CONFIG — the rewritten config is empty or not valid JSON; files were written but baselines were not" >&2; exit 1
    fi
    if ! cp "$CONFIG" "$CONFIG.bak"; then
        echo "sync-sop-files: refusing to replace $CONFIG — could not write $CONFIG.bak" >&2; exit 1
    fi
    if [ -L "$CONFIG" ]; then
        # A dotfiles-managed config is a symlink; a rename would sever it and
        # leave the real file stale (review finding). Write through the link.
        cat "$NEWCFG" > "$CONFIG" && rm -f "$NEWCFG"
    else
        mv "$NEWCFG" "$CONFIG"
    fi
fi
printf 'sync-sop-files: %s rows: %s in sync, %s missing, %s older (pristine), %s modified (kept), %s to reconcile, %s excluded, %s refused, %s unreadable%s\n' \
    "$n_rows" "$n_sync" "$n_missing" "$n_older" "$n_modified" "$n_reconcile" "$n_excluded" "$n_refused" "$n_unreadable" "$([ "$APPLY" = 1 ] && printf ' — applied %s, baselines and last_update_check written to %s' "$n_applied" "$CONFIG" || printf ' — dry run; add --apply to write')"
exit 0
