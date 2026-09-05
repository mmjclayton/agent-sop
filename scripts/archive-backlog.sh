#!/usr/bin/env bash
#
# archive-backlog.sh [--days N] [--dry-run] — move closed Backlog items older
# than N days (default 90) to docs/backlog-archive.md.
#
# Closed = status [SHIPPED - date], [VERIFIED - date] or [WON'T]; the date is
# the one in the tag ([WON'T] items use the newest date found in the entry
# body, or are kept when none is found). Entries are moved verbatim, newest
# first in the archive, and never edited: the archive is the same record in
# another file (Section 0, never delete without a trace). Backlog.md keeps a
# one-line pointer per moved item under `## Archived items` so a P-number can
# still be found by grep. Idempotent.
#
# Why (P105, 2026-09-05): closed items were 67-89% of Backlog.md lines in four
# measured repos and nothing read them; the file only has to hold what a
# session can still act on.

set -u
DAYS=90; DRY=0
while [ $# -gt 0 ]; do
    case "$1" in
        --days) DAYS="$2"; shift ;;
        --dry-run) DRY=1 ;;
        -h|--help) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || ROOT=$PWD
BACKLOG="$ROOT/Backlog.md"; ARCHIVE="$ROOT/docs/backlog-archive.md"
[ -f "$BACKLOG" ] || { echo "archive-backlog: no Backlog.md at $ROOT" >&2; exit 1; }
CUTOFF=$(date -v-"${DAYS}"d +%Y-%m-%d 2>/dev/null || date -d "-${DAYS} days" +%Y-%m-%d)

python3 - "$BACKLOG" "$ARCHIVE" "$CUTOFF" "$DRY" <<'PY'
import re,sys,os
backlog,archive,cutoff,dry=sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4]=='1'
text=open(backlog).read()
# Split into the preamble and P-entries. An entry runs from its `### P<n>` heading
# to the next `### P` heading or a `## ` section heading.
parts=re.split(r'(?m)^(?=### P\d+ )', text)
pre, entries = parts[0], parts[1:]
def status(entry):
    m=re.search(r'(?m)^`\[(SHIPPED|VERIFIED) - (\d{4}-\d{2}-\d{2})\]', entry)
    if m: return m.group(1), m.group(2)
    if re.search(r"(?m)^`\[WON'T\]", entry):
        dates=re.findall(r'\d{4}-\d{2}-\d{2}', entry)
        return ("WON'T", max(dates)) if dates else ("WON'T", None)
    return None, None
keep, move = [], []
for e in entries:
    # keep any trailing `## ` section (e.g. Shipped Archive) attached to the last entry out of the move set
    head, sep, rest = e.partition('\n## ')
    st, d = status(head)
    if st and d and d < cutoff:
        move.append(head if not sep else head)
        if sep: keep.append('\n## '+rest)  # a section that followed the entry stays in Backlog.md
    else:
        keep.append(e)
if not move:
    print("archive-backlog: nothing older than %s to move" % cutoff); sys.exit(0)
ids=[re.match(r'### (P\d+)', m).group(1) for m in move]
pointer_lines=''.join('- %s — archived %s: see docs/backlog-archive.md\n' % (re.match(r'### (P\d+) — (.*)', m).group(1), re.match(r'### (P\d+) — (.*)', m).group(2).strip()) for m in move)
new_backlog=pre+''.join(keep)
if '## Archived items' in new_backlog:
    new_backlog=new_backlog.replace('## Archived items\n', '## Archived items\n'+pointer_lines,1)
else:
    new_backlog=new_backlog.rstrip('\n')+'\n\n---\n\n## Archived items\n\nClosed more than 90 days ago; full entries in `docs/backlog-archive.md`, moved verbatim by `scripts/archive-backlog.sh`.\n\n'+pointer_lines
existing=open(archive).read() if os.path.exists(archive) else '# Backlog archive\n\nClosed items moved verbatim from `Backlog.md` by `scripts/archive-backlog.sh`. Never edited here; a revival is a new P-number.\n\n'
new_archive=existing.rstrip('\n')+'\n\n'+''.join(m.rstrip('\n')+'\n\n---\n\n' for m in reversed(move))
print("archive-backlog: moving %d item(s) older than %s: %s" % (len(move), cutoff, ' '.join(ids)))
if dry: sys.exit(0)
open(backlog,'w').write(new_backlog); os.makedirs(os.path.dirname(archive),exist_ok=True); open(archive,'w').write(new_archive)
print("archive-backlog: Backlog.md %d -> %d lines; docs/backlog-archive.md %d lines" % (text.count('\n'), new_backlog.count('\n'), new_archive.count('\n')))
PY
