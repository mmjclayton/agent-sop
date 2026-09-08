#!/usr/bin/env bash
#
# Resolve the machine-local resume-file path for the current project.
#
# Single source of truth for the derivation. Three callers consume it:
#   /update-sop  Step 6                        — write target
#   /restart-sop Step 0d + Step 2              — read target
#   validate-state-transitions.sh --check-drift — read target
#
# Why this script exists (P96). The two readers already derived the memory
# directory from the git repo root, but the writer — /update-sop Step 6 —
# carried an unresolved `[project-hash]` placeholder and no derivation at all.
# An agent with no rule writes into whichever memory directory the *session*
# owns, which for a session launched outside the project is the harness's
# catch-all bucket. Writes and reads then land in different directories: the
# resume file is written somewhere the drift gate never looks, so the gate
# degrades to "no project_resume file found — skipping" and silently no-ops.
#
# The catch-all bucket also accumulates several projects' resume files at once,
# and every single-worktree project resolves to the same `solo` agent-id. Step
# 7's legacy fallback would therefore instruct an agent on project A to
# overwrite project B's unsuffixed `project_resume.md`. Observed twice before
# this fix.
#
# Unified rather than parity-tested per docs/guides/cross-layer-rules.md Tier A:
# the derivation is a pure function of (repo root, HOME, agent-id), so one
# implementation can serve every caller and divergence becomes impossible.
#
# Usage:
#   bash scripts/resolve-resume-path.sh              # write target (absolute)
#   bash scripts/resolve-resume-path.sh --read       # read target, exit 1 if none
#   bash scripts/resolve-resume-path.sh --dir        # memory directory
#   bash scripts/resolve-resume-path.sh --agent-id   # resolved agent id
#
# Test overrides: --root <repo-root>  --home <home-dir>
#
# Exit codes:
#   0  resolved — path (or agent-id) on stdout
#   1  not a git repository, or --read found no resume file
#   2  refused — repo root is the home directory, so the derived directory is
#      the harness catch-all shared by every home-launched session rather than
#      a project-scoped directory. Writing there is what P96 fixes.

# `set -u` only, deliberately. Do not add `-e` or `-o pipefail` here: this
# script runs `git worktree list` in directories that may not be a working
# tree, where git exits 128. Under pipefail that status survives the
# `| wc -l | tr` pipeline and errexit would kill the script before it printed
# anything — the exact shape of P73, where a caller saw a bare non-zero exit
# with empty stdout and empty stderr. Every failure path below reports before
# it exits.
set -u

MODE="write"
ROOT_OVERRIDE=""
HOME_OVERRIDE=""

while [ $# -gt 0 ]; do
    case "$1" in
        --migrate-legacy) MODE="migrate" ;;
        --legacy-dir) MODE="legacy-dir" ;;
        --read)     MODE="read" ;;
        --dir)      MODE="dir" ;;
        --agent-id) MODE="agent-id" ;;
        --write)    MODE="write" ;;
        --root)     shift; ROOT_OVERRIDE="${1:-}" ;;
        --home)     shift; HOME_OVERRIDE="${1:-}" ;;
        *) echo "resolve-resume-path: unknown argument: $1" >&2; exit 1 ;;
    esac
    shift
done

HOME_DIR="${HOME_OVERRIDE:-$HOME}"

if [ -n "$ROOT_OVERRIDE" ]; then
    ROOT="$ROOT_OVERRIDE"
else
    ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || ROOT=""
fi

if [ -z "$ROOT" ]; then
    echo "resolve-resume-path: not a git repository — cannot derive a project-scoped memory directory." >&2
    exit 1
fi

# Strip any trailing slash so `/repo/` and `/repo` derive the same directory.
case "$ROOT" in
    */) ROOT="${ROOT%/}" ;;
esac

# The harness names project directories after the session's launch path, so a
# session started from the home directory owns `-<home-slug>` — a bucket shared
# by every project touched from that session. Deriving into it would reproduce
# exactly the collision this script exists to prevent, so refuse instead.
if [ "$ROOT" = "$HOME_DIR" ]; then
    echo "resolve-resume-path: repo root is the home directory ($ROOT)." >&2
    echo "  That memory directory is the harness catch-all shared by every home-launched" >&2
    echo "  session, not a project-scoped one. Run the SOP from inside the project repo." >&2
    exit 2
fi

resolve_agent_id() {
    if [ -n "${AGENT_SOP_AGENT_ID:-}" ]; then
        printf '%s' "$AGENT_SOP_AGENT_ID"
        return 0
    fi
    if [ -n "${CLAUDE_AGENT_ID:-}" ]; then
        printf '%s' "$CLAUDE_AGENT_ID"
        return 0
    fi

    if [ -f "$ROOT/.sop-agent-id" ]; then
        head -1 "$ROOT/.sop-agent-id" | tr -d '[:space:]'
        return 0
    fi

    # Main worktrees keep solo regardless of the number of linked worktrees.
    # Linked worktrees have a .git file and keep their path identity after siblings leave.
    if [ -d "$ROOT/.git" ]; then
        printf 'solo'
        return 0
    fi

    local hash
    hash=$(printf '%s' "$ROOT" | { shasum -a 256 2>/dev/null || sha256sum; } | cut -c1-6)
    [[ "$hash" =~ ^[0-9a-f]{6}$ ]] || { echo 'resolve-resume-path: identity hashing failed' >&2; return 1; }
    printf '%s' "$hash"
}

AGENT_ID=$(resolve_agent_id) || exit 2
[ -z "$AGENT_ID" ] && AGENT_ID="solo"
case "$AGENT_ID" in *[!a-zA-Z0-9_-]*|.|..) echo 'resolve-resume-path: invalid agent identity' >&2; exit 2 ;; esac

if [ "$MODE" = "agent-id" ]; then
    printf '%s\n' "$AGENT_ID"
    exit 0
fi

# The harness normalises every non-alphanumeric path character to a hyphen, so
# `matt_clayton` becomes `matt-clayton`. Collapse runs so `My__Projects` matches
# the observed single-hyphen convention. Kept byte-identical to the derivation
# previously inlined in restart-sop.md and validate-state-transitions.sh.
PROJECT_HASH=$(printf '%s' "$ROOT" | sed 's|[^a-zA-Z0-9-]|-|g' | sed 's|--*|-|g' | sed 's|^-||')
LEGACY_DIR="$HOME_DIR/.claude/projects/-$PROJECT_HASH/memory"
ROOT_DIGEST=$(printf '%s' "$ROOT" | { shasum -a 256 2>/dev/null || sha256sum; } | cut -d' ' -f1)
[[ "$ROOT_DIGEST" =~ ^[0-9a-f]{64}$ ]] || { echo 'resolve-resume-path: root hashing failed; no safe storage path' >&2; exit 2; }
MEMORY_DIR="$HOME_DIR/.claude/agent-sop/projects/$ROOT_DIGEST/memory"
OLD_HASH=$(printf '%s' "$ROOT_DIGEST" | cut -c1-6)
check_main_conflict() {
    local dir="$1"
    if [ "$AGENT_ID" = solo ] && [ -d "$ROOT/.git" ] &&
       [ -z "${AGENT_SOP_AGENT_ID:-}${CLAUDE_AGENT_ID:-}" ] && [ ! -f "$ROOT/.sop-agent-id" ] &&
       [ -f "$dir/project_resume_solo.md" ] && [ -f "$dir/project_resume_$OLD_HASH.md" ] &&
       ! cmp -s "$dir/project_resume_solo.md" "$dir/project_resume_$OLD_HASH.md"; then
        echo "Resume conflict: $dir contains differing solo and $OLD_HASH snapshots. Reconcile their content into solo and archive the hash snapshot before resuming; preserve originals." >&2
        return 1
    fi
}
if [ "$MODE" = legacy-dir ]; then printf '%s\n' "$LEGACY_DIR"; exit 0; fi
if [ "$MODE" = migrate ]; then
    # Explicit operator action: legacy slugs can collide, so never auto-claim them.
    [ -d "$LEGACY_DIR" ] || { echo 'No legacy directory to migrate.' >&2; exit 1; }
    check_main_conflict "$LEGACY_DIR" || exit 2
    check_main_conflict "$MEMORY_DIR" || exit 2
    mkdir -p "$MEMORY_DIR"
    # Preflight all destinations before copying, so a failed repeat migration
    # cannot reintroduce a stale hash snapshot beside an updated canonical file.
    incoming_solo="$LEGACY_DIR/project_resume_solo.md"
    [ ! -f "$MEMORY_DIR/project_resume_solo.md" ] || incoming_solo="$MEMORY_DIR/project_resume_solo.md"
    incoming_hash="$LEGACY_DIR/project_resume_$OLD_HASH.md"
    [ ! -f "$MEMORY_DIR/project_resume_$OLD_HASH.md" ] || incoming_hash="$MEMORY_DIR/project_resume_$OLD_HASH.md"
    if [ "$AGENT_ID" = solo ] && [ -d "$ROOT/.git" ] &&
       [ -f "$incoming_solo" ] && [ -f "$incoming_hash" ] && ! cmp -s "$incoming_solo" "$incoming_hash"; then
        echo 'Migration conflict: differing main snapshot generations require reconciliation before copying.' >&2
        exit 2
    fi
    for source in "$LEGACY_DIR"/project_resume*.md; do
        [ -f "$source" ] || continue
        target="$MEMORY_DIR/$(basename "$source")"
        [ ! -e "$target" ] || cmp -s "$source" "$target" || { echo "Migration conflict: $target" >&2; exit 2; }
    done
    for source in "$LEGACY_DIR"/project_resume*.md; do
        [ -f "$source" ] || continue
        target="$MEMORY_DIR/$(basename "$source")"
        if [ -e "$target" ]; then
            cmp -s "$source" "$target" || { echo "Migration conflict: $target" >&2; exit 2; }
        else cp "$source" "$target" || exit 1; fi
    done
    check_main_conflict "$MEMORY_DIR" || exit 2
    if [ "$AGENT_ID" = solo ] && [ -d "$ROOT/.git" ] &&
       [ -z "${AGENT_SOP_AGENT_ID:-}${CLAUDE_AGENT_ID:-}" ] && [ ! -f "$ROOT/.sop-agent-id" ] &&
       [ -f "$MEMORY_DIR/project_resume_$OLD_HASH.md" ]; then
        # Establish one active main snapshot; a later normal close must not conflict
        # with the historical hash generation retained by this explicit migration.
        hash_snapshot="$MEMORY_DIR/project_resume_$OLD_HASH.md"
        archive_snapshot="$MEMORY_DIR/archive/project_resume_$OLD_HASH.md"
        mkdir -p "$MEMORY_DIR/archive" || exit 1
        if [ -e "$archive_snapshot" ]; then
            cmp -s "$hash_snapshot" "$archive_snapshot" || { echo "Migration conflict: $archive_snapshot" >&2; exit 2; }
        else cp "$hash_snapshot" "$archive_snapshot" || exit 1; fi
        [ -f "$MEMORY_DIR/project_resume_solo.md" ] || cp "$hash_snapshot" "$MEMORY_DIR/project_resume_solo.md" || exit 1
        rm "$hash_snapshot" || exit 1
    fi
    printf '%s\n' "$MEMORY_DIR"
    exit 0
fi

if [ "$MODE" = "dir" ]; then
    printf '%s\n' "$MEMORY_DIR"
    exit 0
fi

PER_AGENT="$MEMORY_DIR/project_resume_${AGENT_ID}.md"
LEGACY="$MEMORY_DIR/project_resume.md"
if [ "$MODE" = read ]; then check_main_conflict "$MEMORY_DIR" || exit 2; fi
# Pre-hardening main worktrees could switch from solo to their path hash.
if [ "$MODE" = read ] && [ "$AGENT_ID" = solo ] && [ ! -f "$PER_AGENT" ] &&
   [ -z "${AGENT_SOP_AGENT_ID:-}${CLAUDE_AGENT_ID:-}" ] && [ ! -f "$ROOT/.sop-agent-id" ]; then
    [ ! -f "$MEMORY_DIR/project_resume_$OLD_HASH.md" ] || PER_AGENT="$MEMORY_DIR/project_resume_$OLD_HASH.md"
fi

# Write target is always the per-agent filename in the project-scoped directory.
# Deterministic by construction: never depends on where the session was launched
# and never resolves onto another project's file.
if [ "$MODE" = "write" ]; then
    printf '%s\n' "$PER_AGENT"
    exit 0
fi

# Read target prefers the per-agent file and falls back to the legacy unsuffixed
# filename for projects predating the per-agent convention. The fallback is safe
# here only because MEMORY_DIR is derived from this repo's root — any
# `project_resume.md` inside it belongs to this project. The same fallback
# against a session-owned directory is what let a foreign project's file be
# selected before P96.
if [ -f "$PER_AGENT" ]; then
    printf '%s\n' "$PER_AGENT"
    exit 0
fi

if [ -f "$LEGACY" ]; then
    # A legacy file that announces itself superseded is not a resume: serving
    # it put a stale snapshot in front of a session whose agent-id had no
    # per-agent file yet (found by the 2026-09-05 cost audit).
    # Anchored to the marker /update-sop writes (`**SUPERSEDED - <date>.**`),
    # so prose that merely contains the word still resolves; read from the
    # first non-blank line with a BOM or CR stripped, so a leading blank line
    # or a Windows-edited file cannot slip a stale snapshot through (review).
    if head -5 "$LEGACY" 2>/dev/null | LC_ALL=C sed 's/^\xEF\xBB\xBF//; s/\r$//' | grep -v '^[[:space:]]*$' | head -1 | grep -qi '^\*\*SUPERSEDED'; then
        echo "resolve-resume-path: legacy resume file is marked superseded ($LEGACY); treating as absent." >&2
        exit 1
    fi
    if [ "$AGENT_ID" != "solo" ]; then
        echo "resolve-resume-path: reading legacy unsuffixed resume file ($LEGACY). Run \`/migrate-to-multi-agent\` to move to per-agent format." >&2
    fi
    printf '%s\n' "$LEGACY"
    exit 0
fi

[ ! -d "$LEGACY_DIR" ] || echo "Legacy snapshots require explicit ownership confirmation: inspect $LEGACY_DIR then run --migrate-legacy for this root." >&2
exit 1
