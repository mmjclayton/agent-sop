#!/usr/bin/env python3
"""
One-time migration from legacy narrative sections to per-entry directory files.

Extracts:
  CLAUDE.md ## Recent Work (legacy) -> docs/recent-work/YYYY-MM-DD_solo_<slug>.md
  docs/agent-memory.md ## Decisions Made (legacy) -> docs/agent-memory/decisions/
  docs/agent-memory.md ## Gotchas and Lessons (legacy) -> docs/agent-memory/gotchas/
  docs/agent-memory.md ## Archived -> docs/agent-memory/decisions/archive/
    (treat all archived bullets as decisions; user can re-file gotchas manually)

Idempotent: writing the same filename overwrites the prior output, so re-running
is safe. Legacy section removal is NOT automatic — agent reviews git diff and
edits the legacy sections manually after extraction. /update-sop refreshes the
rollup on the next run.

Supports --dry-run.

Usage:
    python3 scripts/migrate-to-multi-agent.py [--dry-run] [--repo PATH]
"""
import argparse
import os
import re
import subprocess
import sys
from pathlib import Path


def make_slug(text: str, maxlen: int = 50) -> str:
    """Kebab-case slug: lowercase, non-alphanumeric -> hyphen, collapsed, trimmed."""
    s = text.lower()
    s = re.sub(r"[^a-z0-9]+", "-", s)
    s = re.sub(r"-+", "-", s)
    s = s.strip("-")
    if len(s) > maxlen:
        s = s[:maxlen].rstrip("-")
    return s or "entry"


def find_section(content: str, header_patterns: list[str]) -> tuple[int, int] | None:
    """Return (start_line_inclusive, end_line_exclusive) of the first matching section.

    Section ends at the next top-level ## heading that is NOT a variant of the
    matched section (we match variants by stripping the parenthesised suffix).
    """
    lines = content.split("\n")
    start = None
    for i, line in enumerate(lines):
        for pat in header_patterns:
            if re.match(pat, line):
                start = i
                break
        if start is not None:
            break
    if start is None:
        return None

    base_match = re.match(r"^(## [^\(]+)", lines[start])
    base_header = base_match.group(1).strip() if base_match else lines[start]

    for j in range(start + 1, len(lines)):
        if re.match(r"^## ", lines[j]):
            if lines[j].startswith(base_header):
                continue
            return (start, j)
    return (start, len(lines))


def extract_recent_work(content: str) -> list[dict]:
    section = find_section(
        content,
        [r"^## Recent Work \(legacy", r"^## Recent Work$"],
    )
    if section is None:
        return []
    start, end = section
    lines = content.split("\n")[start + 1 : end]

    entries = []
    current = None
    for line in lines:
        m = re.match(r"^### (\d{4}-\d{2}-\d{2}): (.+)$", line)
        if m:
            if current:
                entries.append(current)
            title_raw = m.group(2).strip()
            commit_match = re.search(
                r"\((commits?|PRs?)\s+([^)]+)\)\s*$", title_raw
            )
            commits = commit_match.group(2).strip() if commit_match else ""
            title = re.sub(
                r"\s*\((commits?|PRs?)\s+[^)]+\)\s*$", "", title_raw
            ).strip()
            current = {
                "date": m.group(1),
                "title": title,
                "commits": commits,
                "body_lines": [],
            }
        elif current is not None:
            current["body_lines"].append(line)
    if current:
        entries.append(current)
    return entries


def extract_bullet_entries(section_lines: list[str]) -> list[dict]:
    """Extract '- [SUPERSEDED - DATE: reason] YYYY-MM-DD: ...' or '- YYYY-MM-DD: ...' bullets.

    Continuation lines (following the bullet, indented or as paragraph) attach
    to the current entry until the next bullet or section break.
    """
    entries = []
    current = None
    sup_pattern = re.compile(
        r"^- (?:\[SUPERSEDED - (\d{4}-\d{2}-\d{2}): ([^\]]+)\]\s+)?(\d{4}-\d{2}-\d{2}): (.+)$"
    )

    for line in section_lines:
        m = sup_pattern.match(line)
        if m:
            if current:
                entries.append(current)
            superseded_date = m.group(1)
            superseded_reason = m.group(2)
            date = m.group(3)
            body_start = m.group(4).strip()
            # Title = first sentence (ending at ". " or ".\n" or end),
            # falling back to first 100 chars. Period-inside-word (e.g.
            # "CLAUDE.md") does not terminate the title.
            sentence_m = re.search(r"[.!?](?:\s|$)", body_start)
            end_idx = sentence_m.start() if sentence_m else min(len(body_start), 100)
            title = body_start[:end_idx].strip()
            if not title:
                title = body_start[:100].strip() or body_start
            current = {
                "date": date,
                "superseded_date": superseded_date,
                "superseded_reason": superseded_reason,
                "title": title,
                "body_lines": [body_start],
            }
        elif current is not None:
            current["body_lines"].append(line.rstrip())
    if current:
        entries.append(current)

    for e in entries:
        while e["body_lines"] and not e["body_lines"][-1].strip():
            e["body_lines"].pop()
    return entries


def extract_decisions(content: str) -> list[dict]:
    section = find_section(
        content,
        [r"^## Decisions Made \(legacy", r"^## Decisions Made$"],
    )
    if section is None:
        return []
    start, end = section
    return extract_bullet_entries(content.split("\n")[start + 1 : end])


def extract_gotchas(content: str) -> list[dict]:
    section = find_section(
        content,
        [
            r"^## Gotchas and Lessons \(legacy",
            r"^## Gotchas and Lessons$",
        ],
    )
    if section is None:
        return []
    start, end = section
    return extract_bullet_entries(content.split("\n")[start + 1 : end])


def extract_archived(content: str) -> list[dict]:
    section = find_section(content, [r"^## Archived"])
    if section is None:
        return []
    start, end = section
    return extract_bullet_entries(content.split("\n")[start + 1 : end])


def write_recent_work(entry: dict, out_dir: Path, dry_run: bool) -> Path:
    slug = make_slug(entry["title"])
    path = out_dir / f"{entry['date']}_solo_{slug}.md"
    body = "\n".join(entry["body_lines"]).strip()
    content = (
        f"# {entry['title']}\n\n"
        f"**Date:** {entry['date']}\n"
        f"**Agent:** solo\n"
        f"**Commits:** {entry['commits'] or '(migrated)'}\n\n"
        f"{body}\n"
    )
    if dry_run:
        print(f"  WOULD WRITE: {path} ({len(content)} chars)")
    else:
        out_dir.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
    return path


def write_bullet(
    entry: dict,
    out_dir: Path,
    archive_dir: Path,
    dry_run: bool,
) -> Path:
    slug = make_slug(entry["title"])
    target = archive_dir if entry.get("superseded_date") else out_dir
    path = target / f"{entry['date']}_solo_{slug}.md"
    body = "\n".join(entry["body_lines"]).strip()
    content = (
        f"# {entry['title']}\n\n"
        f"**Date:** {entry['date']}\n"
        f"**Agent:** solo\n\n"
        f"{body}\n"
    )
    if entry.get("superseded_date"):
        content += (
            f"\n---\n"
            f"*Superseded: {entry['superseded_date']} — {entry['superseded_reason']}*\n"
        )
    if dry_run:
        print(f"  WOULD WRITE: {path} ({len(content)} chars)")
    else:
        target.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
    return path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--repo", default=".", help="Project root (default: cwd)")
    args = parser.parse_args()

    repo = Path(args.repo).resolve()
    os.chdir(repo)

    if not args.dry_run:
        r = subprocess.run(["git", "diff", "--quiet"], capture_output=True)
        if r.returncode != 0:
            print("ERROR: uncommitted changes in working tree.", file=sys.stderr)
            return 1
        r = subprocess.run(
            ["git", "diff", "--cached", "--quiet"], capture_output=True
        )
        if r.returncode != 0:
            print("ERROR: staged changes present.", file=sys.stderr)
            return 1

    claude_md = Path("CLAUDE.md")
    am_md = Path("docs/agent-memory.md")

    if not claude_md.exists():
        print("ERROR: CLAUDE.md not found at project root.", file=sys.stderr)
        return 1

    rw_entries = extract_recent_work(claude_md.read_text())
    if am_md.exists():
        am_content = am_md.read_text()
        dec_entries = extract_decisions(am_content)
        got_entries = extract_gotchas(am_content)
        arch_entries = extract_archived(am_content)
    else:
        dec_entries, got_entries, arch_entries = [], [], []

    total = len(rw_entries) + len(dec_entries) + len(got_entries) + len(arch_entries)
    if total == 0:
        print("No legacy entries to migrate. Nothing to do.")
        return 0

    print(
        f"Found: {len(rw_entries)} Recent Work, "
        f"{len(dec_entries)} Decisions, "
        f"{len(got_entries)} Gotchas, "
        f"{len(arch_entries)} Archived"
    )

    rw_dir = Path("docs/recent-work")
    dec_dir = Path("docs/agent-memory/decisions")
    dec_arch = dec_dir / "archive"
    got_dir = Path("docs/agent-memory/gotchas")
    got_arch = got_dir / "archive"

    print("\nRecent Work:")
    for e in rw_entries:
        write_recent_work(e, rw_dir, args.dry_run)
    print("\nDecisions:")
    for e in dec_entries:
        write_bullet(e, dec_dir, dec_arch, args.dry_run)
    print("\nGotchas:")
    for e in got_entries:
        write_bullet(e, got_dir, got_arch, args.dry_run)
    print("\nArchived (treated as decisions):")
    for e in arch_entries:
        # Force archive directory for all archived entries
        e["superseded_date"] = e.get("superseded_date") or "pre-cutoff"
        e["superseded_reason"] = e.get("superseded_reason") or "archived"
        write_bullet(e, dec_dir, dec_arch, args.dry_run)

    print(f"\n{'DRY RUN — ' if args.dry_run else ''}Extracted {total} entries.")

    if not args.dry_run:
        print(
            "\nNext steps:\n"
            "  1. Review with: git status && git diff --stat\n"
            "  2. Spot-check extracted files: ls docs/recent-work/ docs/agent-memory/decisions/\n"
            "  3. Remove legacy sections from CLAUDE.md and docs/agent-memory.md manually.\n"
            "  4. Run /update-sop to refresh the CLAUDE.md rollup.\n"
            "  5. Commit: chore: migrate to multi-agent directory structure."
        )

    return 0


if __name__ == "__main__":
    sys.exit(main())
