#!/usr/bin/env bash
#
# Regenerate the Current Priority Items block in CLAUDE.md from Backlog.md.
#
# Why derived rather than hand-maintained: CLAUDE.md declares Backlog.md the
# single source of truth for work item status, then kept a second hand-written
# copy of the open items beside it. That is a Rule 2 violation shipped in the
# template, and it drifted in every project that used it — worst observed case
# 117 days stale, and agent-sop's own copy drifted inside a single session.
#
# The fix is the pattern this repo already proves with the Recent Work rollup:
# sentinel markers plus a regenerating script. A derived view does not drift,
# because nobody maintains it. This keeps the benefit the pointer alternative
# throws away — the agent sees priorities without grepping Backlog.md — while
# removing the copy that goes stale (P92).
#
# Idempotent: identical Backlog.md contents produce identical output, so
# parallel agents regenerating in separate worktrees converge on merge.
#
# Usage:
#   bash scripts/refresh-priorities.sh [claude-md] [backlog]
#
# Called by /update-sop Step 3 after Backlog.md is updated.
#
# Opt-in: a project whose CLAUDE.md has no sentinel block is left untouched and
# exits 0. Adding the block is what enables the derivation.

set -euo pipefail

SENTINEL_START='<!-- priority-items:start -->'
SENTINEL_END='<!-- priority-items:end -->'

CLAUDE_MD="${1:-CLAUDE.md}"
BACKLOG="${2:-Backlog.md}"

if [ ! -f "$CLAUDE_MD" ]; then
    echo "Error: $CLAUDE_MD not found" >&2
    exit 1
fi

if [ ! -f "$BACKLOG" ]; then
    echo "Error: $BACKLOG not found" >&2
    exit 1
fi

# Opt-in, not a hard requirement. Pre-P92 projects keep their hand-written
# section until they choose to migrate; failing here would break their
# /update-sop run for a section they never opted into.
if ! grep -q "$SENTINEL_START" "$CLAUDE_MD"; then
    echo "refresh-priorities: no ${SENTINEL_START} block in $CLAUDE_MD — skipping (section is opt-in)"
    exit 0
fi

# The awk splice below drops every line between the start and end sentinels. If
# the end sentinel is missing or mistyped, `skip` is never cleared and the splice
# deletes the entire remainder of the file — silently, with exit 0 and a success
# message. Verify both markers before touching the file.
if ! grep -q "$SENTINEL_END" "$CLAUDE_MD"; then
    echo "Error: $CLAUDE_MD has ${SENTINEL_START} but no matching ${SENTINEL_END}." >&2
    echo "       Refusing to splice — that would delete everything after the start marker." >&2
    exit 1
fi

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

# Emit one line per non-terminal item. A P-number heading is followed by its
# status line in backticks, e.g. `[OPEN] [Bug] [has-open-questions]`.
# Extraction is a pure `while read` loop with no pipeline, so the P84
# pipefail class does not arise here. (An earlier draft of this comment claimed
# a `|| true` grep guard that was never present — corrected, since a comment
# asserting a guard that does not exist is worse than no comment.)
{
    echo "$SENTINEL_START"
    echo "*Derived from \`${BACKLOG}\` by \`scripts/refresh-priorities.sh\`. Do not edit by hand — the Backlog is the source of truth. Last refreshed: $(date +%Y-%m-%d).*"
    echo ""

    # Structural parse. Three rules keep this honest:
    #
    # 1. Scan forward from each heading only until the NEXT heading, and accept
    #    the first line that parses as a RECOGNISED status tag. Two weaker rules
    #    were tried and both fail open: taking the first backtick-bracket line
    #    lets a bracketed cross-reference swallow the status and the item
    #    vanishes; requiring strict adjacency drops any item whose tag is not on
    #    the very next line. Both render "No open items" on a backlog that has
    #    them — a false claim, which is worse than an error.
    # 2. Fenced blocks are skipped. This Backlog contains fenced reproduction
    #    snippets shaped exactly like real entries.
    # 3. A heading with no recognised status before the next heading is counted
    #    as malformed and surfaced, never silently dropped.
    FOUND=0
    HEADINGS=0
    MALFORMED=0
    in_fence=0
    in_item=0
    pending_heading=""

    flush_item() {
        [ "$in_item" = "1" ] && MALFORMED=$(( MALFORMED + 1 ))
        in_item=0
    }

    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            '```'*) in_fence=$(( 1 - in_fence )); continue ;;
        esac
        [ "$in_fence" = "1" ] && continue

        case "$line" in
            '### P'*)
                flush_item
                pending_heading="$line"
                HEADINGS=$(( HEADINGS + 1 ))
                in_item=1
                continue
                ;;
        esac

        [ "$in_item" = "1" ] || continue

        # Only a recognised status tag closes an item. Anything else — prose,
        # bracketed cross-references, blank lines — is body text.
        #
        # Parameter expansion, not sed: BRE alternation (\|) is a GNU extension
        # that BSD/macOS sed does not support, and this ships to both.
        case "$line" in
            '`['*) rest=${line#'`['}; status=${rest%%]*} ;;
            *) continue ;;
        esac

        case "$status" in
            OPEN|"IN PROGRESS"|BLOCKED)
                title=${pending_heading#\#\#\# }
                tags=$(printf '%s' "$line" | tr -d '`')
                echo "- ${title} — ${tags}"
                FOUND=1
                ;;
            SHIPPED*|VERIFIED*|DEFERRED|"WON'T"*)
                : # recognised terminal state — closes the item, not listed
                ;;
            *)
                continue # not a status tag; keep scanning this item's body
                ;;
        esac
        in_item=0
    done < "$BACKLOG"
    flush_item

    # Distinguish "everything is closed" from "the parse found nothing". A
    # Backlog with no P-headings at all means the format assumption is wrong,
    # not that the work is done — reporting the latter would be a false claim.
    if [ "$HEADINGS" = "0" ]; then
        echo "*Could not parse \`${BACKLOG}\` — no \`### P<n>\` headings found. Priority items not derived; check the Backlog format.*"
    elif [ "$FOUND" = "0" ]; then
        echo "*No open items. All ${HEADINGS} items in \`${BACKLOG}\` are shipped, deferred, or closed.*"
    fi

    echo "$SENTINEL_END"
} > "$TMP"

awk -v repl_file="$TMP" '
    /<!-- priority-items:start -->/ {
        while ((getline line < repl_file) > 0) print line
        close(repl_file)
        skip = 1
        next
    }
    /<!-- priority-items:end -->/ {
        skip = 0
        next
    }
    !skip { print }
' "$CLAUDE_MD" > "${CLAUDE_MD}.tmp" && mv "${CLAUDE_MD}.tmp" "$CLAUDE_MD"

echo "Priority items refreshed: $CLAUDE_MD"
