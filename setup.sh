#!/usr/bin/env bash
#
# Agent SOP Setup Script
#
# Copies templates into a target project directory and creates the standard
# file set required by the Claude Code Agent SOP. Does not overwrite existing
# files unless you pass --force.
#
# Usage:
#   ./setup.sh /path/to/your/project [--code] [--force]
#
# Options:
#   --code    Use the code project template (adds Auth, Database, Design System,
#             Code Quality Rules). Without this flag the base template is used.
#   --force   Overwrite existing files. Without this flag existing files are skipped.
#
# What it creates (per-project, customised — from templates):
#   CLAUDE.md                          Project instructions
#   Backlog.md                         Work item tracker
#   docs/agent-memory.md               Cross-session agent memory
#   docs/feature-map.md                Shipped features and roadmap (generated)
#   docs/build-plans/phase-0-foundation.md  First build plan
#
# What it syncs (per-project, pristine-replica SOP content — overwritten by /update-agent-sop):
#   docs/sop/*.md                      Core SOP + security + sandboxing + harness + compliance
#   docs/guides/*.md                   Optional patterns, multi-agent routing, managed agents, hill-climbing
#
# What it installs user-scope (one install, all projects benefit):
#   ~/.claude/commands/*.md            Slash commands (/restart-sop, /update-sop, /update-agent-sop)
#   ~/.claude/agents/*.md              Reference agents (sop-checker, code-reviewer, etc.)
#   ~/.claude/agent-sop.config.json    Update tracking (source path, baseline SHAs, reminder cadence)
#
# After running this script, open each file and replace the bracket placeholders
# with real project-specific content. The SOP compliance checker can validate
# your setup:
#
#   @sop-checker check SOP compliance for /path/to/your/project

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/docs/templates"

# ── Defaults ──────────────────────────────────────────────────────────────────

USE_CODE_TEMPLATE=false
FORCE=false
TARGET=""

# ── Parse arguments ───────────────────────────────────────────────────────────

usage() {
    echo "Usage: $(basename "$0") /path/to/project [--code] [--force]"
    echo ""
    echo "Options:"
    echo "  --code    Use the code project template (Auth, DB, Design System)"
    echo "  --force   Overwrite existing files"
    echo ""
    echo "Run this from the agent-sop repo directory."
    exit 1
}

for arg in "$@"; do
    case "$arg" in
        --code)  USE_CODE_TEMPLATE=true ;;
        --force) FORCE=true ;;
        --help|-h) usage ;;
        -*)
            echo "Unknown option: $arg"
            usage
            ;;
        *)
            if [ -z "$TARGET" ]; then
                TARGET="$arg"
            else
                echo "Unexpected argument: $arg"
                usage
            fi
            ;;
    esac
done

if [ -z "$TARGET" ]; then
    echo "Error: no target directory specified."
    echo ""
    usage
fi

# Resolve to absolute path
TARGET="$(cd "$TARGET" 2>/dev/null && pwd)" || {
    echo "Error: directory does not exist: $TARGET"
    exit 1
}

# ── Validate templates exist ──────────────────────────────────────────────────

if [ "$USE_CODE_TEMPLATE" = true ]; then
    CLAUDE_TEMPLATE="$TEMPLATE_DIR/claude-md-template-code.md"
else
    CLAUDE_TEMPLATE="$TEMPLATE_DIR/claude-md-template.md"
fi

for f in "$CLAUDE_TEMPLATE" \
         "$TEMPLATE_DIR/agent-memory-template.md" \
         "$TEMPLATE_DIR/backlog-template.md" \
         "$TEMPLATE_DIR/build-plan-template.md"; do
    if [ ! -f "$f" ]; then
        echo "Error: template not found: $f"
        echo "Are you running this from the agent-sop repo root?"
        exit 1
    fi
done

# ── Helper: copy file if it does not exist (or if --force) ────────────────────

copy_if_missing() {
    local src="$1"
    local dest="$2"

    if [ -f "$dest" ] && [ "$FORCE" = false ]; then
        echo "  skip  $(basename "$dest") (already exists, use --force to overwrite)"
        return
    fi

    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "  create  $(basename "$dest")"
}

# ── Helper: write content if file does not exist (or if --force) ──────────────

write_if_missing() {
    local dest="$1"
    local content="$2"

    if [ -f "$dest" ] && [ "$FORCE" = false ]; then
        echo "  skip  $(basename "$dest") (already exists, use --force to overwrite)"
        return
    fi

    mkdir -p "$(dirname "$dest")"
    echo "$content" > "$dest"
    echo "  create  $(basename "$dest")"
}

# ── Create the standard file set ──────────────────────────────────────────────

echo ""
echo "Agent SOP Setup"
echo "==============="
echo ""

# ── Check Claude Code version (recommend 2.1.101+) ────────────────────────────

if command -v claude >/dev/null 2>&1; then
    CLAUDE_VERSION="$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || true)"
    if [ -n "$CLAUDE_VERSION" ]; then
        REQUIRED="2.1.101"
        LOWEST="$(printf '%s\n%s\n' "$CLAUDE_VERSION" "$REQUIRED" | sort -V | head -n1)"
        if [ "$LOWEST" != "$REQUIRED" ]; then
            echo "Warning: Claude Code $CLAUDE_VERSION detected. Agent SOP recommends $REQUIRED+"
            echo "         (memory leak, permission, and --resume fixes)."
            echo ""
        fi
    fi
fi

echo "Target:   $TARGET"
if [ "$USE_CODE_TEMPLATE" = true ]; then
    echo "Template: code project"
else
    echo "Template: base (non-code)"
fi
echo ""

copy_if_missing "$CLAUDE_TEMPLATE" "$TARGET/CLAUDE.md"
copy_if_missing "$TEMPLATE_DIR/backlog-template.md" "$TARGET/Backlog.md"
copy_if_missing "$TEMPLATE_DIR/agent-memory-template.md" "$TARGET/docs/agent-memory.md"
copy_if_missing "$TEMPLATE_DIR/build-plan-template.md" "$TARGET/docs/build-plans/phase-0-foundation.md"

# feature-map.md has no standalone template; generate a minimal one
FEATURE_MAP_CONTENT="# [Project Name] — Feature Map & Roadmap

Last updated: $(date +%Y-%m-%d)

---

## Shipped Features

| P# | Feature | Path/PR | Shipped |
|----|---------|---------|---------|

---

## Roadmap

### High Priority

| P# | Feature | Path |
|----|---------|------|

### Medium Priority

| P# | Feature | Path |
|----|---------|------|"

write_if_missing "$TARGET/docs/feature-map.md" "$FEATURE_MAP_CONTENT"

# ── Copy pristine-replica SOP docs + guides (project-scope) ───────────────────

for src in "$SCRIPT_DIR"/docs/sop/*.md; do
    [ -f "$src" ] || continue
    copy_if_missing "$src" "$TARGET/docs/sop/$(basename "$src")"
done

for src in "$SCRIPT_DIR"/docs/guides/*.md; do
    [ -f "$src" ] || continue
    copy_if_missing "$src" "$TARGET/docs/guides/$(basename "$src")"
done

# ── Create per-entry directories (recent-work, decisions, gotchas) ────────────

for subdir in "recent-work" "agent-memory/decisions" "agent-memory/gotchas"; do
    src="$SCRIPT_DIR/docs/$subdir/README.md"
    [ -f "$src" ] || continue
    copy_if_missing "$src" "$TARGET/docs/$subdir/README.md"
done

# ── Install slash commands and reference agents (user-scope) ──────────────────

USER_CLAUDE_DIR="${HOME}/.claude"
mkdir -p "$USER_CLAUDE_DIR/commands" "$USER_CLAUDE_DIR/agents"

for src in "$SCRIPT_DIR"/.claude/commands/*.md; do
    [ -f "$src" ] || continue
    dest="$USER_CLAUDE_DIR/commands/$(basename "$src")"
    if [ -f "$dest" ] && [ "$FORCE" = false ]; then
        echo "  skip  ~/.claude/commands/$(basename "$src") (already exists, use --force)"
    else
        cp "$src" "$dest"
        echo "  install  ~/.claude/commands/$(basename "$src")"
    fi
done

for src in "$SCRIPT_DIR"/.claude/agents/*.md; do
    [ -f "$src" ] || continue
    dest="$USER_CLAUDE_DIR/agents/$(basename "$src")"
    if [ -f "$dest" ] && [ "$FORCE" = false ]; then
        echo "  skip  ~/.claude/agents/$(basename "$src") (already exists, use --force)"
    else
        cp "$src" "$dest"
        echo "  install  ~/.claude/agents/$(basename "$src")"
    fi
done

# ── Write baseline SHA config so /update-agent-sop knows what's pristine ─────

CONFIG_PATH="$USER_CLAUDE_DIR/agent-sop.config.json"
if [ ! -f "$CONFIG_PATH" ] || [ "$FORCE" = true ]; then
    TODAY="$(date +%Y-%m-%d)"

    # Compute SHA-256 for each pristine-replica file. Prefer shasum (macOS/BSD), fall back to sha256sum.
    sha_of() {
        if command -v shasum >/dev/null 2>&1; then
            shasum -a 256 "$1" | awk '{print $1}'
        else
            sha256sum "$1" | awk '{print $1}'
        fi
    }

    {
        echo "{"
        echo "  \"local_path\": \"$SCRIPT_DIR\","
        echo "  \"github\": \"mmjclayton/agent-sop\","
        echo "  \"update_reminder\": \"weekly\","
        echo "  \"last_update_check\": \"$TODAY\","
        echo "  \"multi_agent\": \"auto\","
        echo "  \"agent_id_override\": null,"
        echo "  \"baseline_shas\": {"

        first=true
        for path_pattern in \
            "docs/sop/"*.md \
            "docs/guides/"*.md \
            ".claude/commands/"*.md \
            ".claude/agents/"*.md
        do
            src="$SCRIPT_DIR/$path_pattern"
            [ -f "$src" ] || continue
            rel="${src#$SCRIPT_DIR/}"
            sha="$(sha_of "$src")"
            if [ "$first" = true ]; then
                first=false
            else
                echo ","
            fi
            printf '    "%s": "%s"' "$rel" "$sha"
        done
        echo ""
        echo "  }"
        echo "}"
    } > "$CONFIG_PATH"

    echo "  create  ~/.claude/agent-sop.config.json"
else
    echo "  skip  ~/.claude/agent-sop.config.json (already exists, use --force)"
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Done. Next steps:"
echo ""
echo "  1. Open each file in $TARGET and replace [bracket placeholders]"
echo "     with real project-specific content."
echo ""
echo "  2. Start a Claude Code session on your project. Use /restart-sop"
echo "     to run the session start checklist. Use /update-sop at the end."
echo ""
echo "  3. Validate your setup with the compliance checker:"
echo "     @sop-checker check SOP compliance for $TARGET"
echo ""
echo "  4. Keep the SOP in sync as it evolves:"
echo "     /update-agent-sop    (run weekly — /restart-sop will remind you)"
echo ""
if [ "$USE_CODE_TEMPLATE" = false ]; then
    echo "  Tip: if this is a code project (web app, API, CLI), re-run with --code"
    echo "  to get Auth, Database, Design System, and Code Quality Rules sections."
    echo ""
fi
