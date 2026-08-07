#!/usr/bin/env bash
#
# Resolve the machine-local resume-file path for the current project.
#
# Single source of truth for the derivation. Three callers consume it:
#   /update-sop  Step 7                        — write target
#   /restart-sop Step 0d + Step 2              — read target
#   validate-state-transitions.sh --check-drift — read target
#
# Why this script exists (P96). The two readers already derived the memory
# directory from the git repo root, but the writer — /update-sop Step 7 —
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
    if [ -n "${CLAUDE_AGENT_ID:-}" ]; then
        printf '%s' "$CLAUDE_AGENT_ID"
        return 0
    fi

    if [ -f "$ROOT/.sop-agent-id" ]; then
        head -1 "$ROOT/.sop-agent-id" | tr -d '[:space:]'
        return 0
    fi

    # Only an exact count of 1 means solo. An empty or 0 count means the
    # worktree count could not be determined, and falling through to the path
    # hash is the conservative answer: a hash is unique per worktree, whereas
    # guessing `solo` would collide with every sibling. Kept byte-identical to
    # the copies this replaced (restart-sop.md:64, update-sop.md:37) — a
    # divergence here would silently rename every affected project's resume
    # file and strand the old one.
    local count
    count=$(git -C "$ROOT" worktree list 2>/dev/null | wc -l | tr -d '[:space:]')
    if [ "$count" = "1" ]; then
        printf 'solo'
        return 0
    fi

    if command -v shasum >/dev/null 2>&1; then
        printf '%s' "$ROOT" | shasum -a 256 | cut -c1-6
    else
        printf '%s' "$ROOT" | sha256sum | cut -c1-6
    fi
}

AGENT_ID=$(resolve_agent_id)
[ -z "$AGENT_ID" ] && AGENT_ID="solo"

if [ "$MODE" = "agent-id" ]; then
    printf '%s\n' "$AGENT_ID"
    exit 0
fi

# The harness normalises every non-alphanumeric path character to a hyphen, so
# `matt_clayton` becomes `matt-clayton`. Collapse runs so `My__Projects` matches
# the observed single-hyphen convention. Kept byte-identical to the derivation
# previously inlined in restart-sop.md and validate-state-transitions.sh.
PROJECT_HASH=$(printf '%s' "$ROOT" | sed 's|[^a-zA-Z0-9-]|-|g' | sed 's|--*|-|g' | sed 's|^-||')
MEMORY_DIR="$HOME_DIR/.claude/projects/-$PROJECT_HASH/memory"

if [ "$MODE" = "dir" ]; then
    printf '%s\n' "$MEMORY_DIR"
    exit 0
fi

PER_AGENT="$MEMORY_DIR/project_resume_${AGENT_ID}.md"
LEGACY="$MEMORY_DIR/project_resume.md"

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
    if [ "$AGENT_ID" != "solo" ]; then
        echo "resolve-resume-path: reading legacy unsuffixed resume file ($LEGACY). Run \`/migrate-to-multi-agent\` to move to per-agent format." >&2
    fi
    printf '%s\n' "$LEGACY"
    exit 0
fi

exit 1
