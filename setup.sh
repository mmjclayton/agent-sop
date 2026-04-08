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
# What it creates:
#   CLAUDE.md                          Project instructions (from template)
#   Backlog.md                         Work item tracker (from template)
#   docs/agent-memory.md               Cross-session agent memory (from template)
#   docs/feature-map.md                Shipped features and roadmap (generated)
#   docs/build-plans/phase-0-foundation.md  First build plan (from template)
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

# ── Copy the core SOP document ────────────────────────────────────────────────

SOP_SOURCE="$SCRIPT_DIR/docs/sop/claude-agent-sop.md"
if [ -f "$SOP_SOURCE" ]; then
    copy_if_missing "$SOP_SOURCE" "$TARGET/docs/sop/claude-agent-sop.md"
fi

# ── Copy slash commands ───────────────────────────────────────────────────────

COMMANDS_DIR="$SCRIPT_DIR/.claude/commands"
if [ -d "$COMMANDS_DIR" ]; then
    for cmd_file in "$COMMANDS_DIR"/*.md; do
        [ -f "$cmd_file" ] || continue
        copy_if_missing "$cmd_file" "$TARGET/.claude/commands/$(basename "$cmd_file")"
    done
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
if [ "$USE_CODE_TEMPLATE" = false ]; then
    echo "  Tip: if this is a code project (web app, API, CLI), re-run with --code"
    echo "  to get Auth, Database, Design System, and Code Quality Rules sections."
    echo ""
fi
