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
command -v python3 >/dev/null 2>&1 || { echo "archive-backlog: python3 is required" >&2; exit 1; }
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || ROOT=$PWD
BACKLOG="$ROOT/Backlog.md"; ARCHIVE="$ROOT/docs/backlog-archive.md"
[ -f "$BACKLOG" ] || { echo "archive-backlog: no Backlog.md at $ROOT" >&2; exit 1; }
CUTOFF=$(date -v-"${DAYS}"d +%Y-%m-%d 2>/dev/null || date -d "-${DAYS} days" +%Y-%m-%d)

python3 - "$BACKLOG" "$ARCHIVE" "$CUTOFF" "$DRY" <<'PY'
import re,sys,os
backlog,archive,cutoff,dry=sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4]=='1'
text=open(backlog).read()
# Split into the preamble and P-entries on `### P<n>` headings that sit OUTSIDE
# fenced code blocks (a quoted example heading is not an entry). Positions are
# found on a masked copy and applied to the original, so entries move verbatim.
mask=lambda m: re.sub(r'[^\n]', ' ', m.group(0))   # length-preserving: positions map back onto the original
masked=re.sub(r'(?ms)^[ \t]*```.*?^[ \t]*```[ \t]*$', mask, text)
starts=[m.start() for m in re.finditer(r'(?m)^### P\d+(?=[^0-9]|$)', masked)]
if starts:
    pre=text[:starts[0]]; entries=[text[a:b] for a,b in zip(starts, starts[1:]+[len(text)])]
else:
    pre, entries = text, []
def status(entry):
    # The entry's OWN status line: the first backticked bracket line after the
    # heading. A tag quoted further down in the body is narrative, not status.
    m=re.search(r'(?m)^`\[([^\]]+)\]', entry)
    if not m: return None, None
    tag=m.group(1)
    d=re.match(r'(SHIPPED|VERIFIED) - (\d{4}-\d{2}-\d{2})', tag)
    if d: return d.group(1), d.group(2)
    if tag.startswith("WON'T"):
        # Archived only when the status or Reason line itself carries a date;
        # a date elsewhere in the body says nothing about when it was closed.
        line=m.group(0)+entry[m.end():].split('\n',1)[0]
        reason=re.search(r'(?m)^.*Reason:.*$', entry)
        pool=line+(reason.group(0) if reason else '')
        dates=re.findall(r'\d{4}-\d{2}-\d{2}', pool)
        return ("WON'T", max(dates)) if dates else ("WON'T", None)
    return None, None
keep, move = [], []
for i, e in enumerate(entries):
    # Only the LAST entry can carry file tail that is not its own: a trailing
    # `## ` section (outside fences) or a footer after the entry's closing
    # `---`. That tail stays in Backlog.md; everything inside any other entry,
    # `## ` lines included, is that entry's own text and moves with it.
    head, rest = e, ''
    if i == len(entries) - 1:
        em=re.sub(r'(?ms)^[ \t]*```.*?^[ \t]*```[ \t]*$', mask, e)
        cut=None
        sec=re.search(r'(?m)^## ', em)
        if sec: cut=sec.start()
        else:
            sep=re.search(r'(?m)^---[ \t]*$', em)
            if sep and em[sep.end():].strip(): cut=sep.end()
        if cut is not None: head, rest = e[:cut], e[cut:]
    st, d = status(head)
    if st and d and d < cutoff:
        move.append(head)
        if rest: keep.append(rest)
    else:
        keep.append(e)
if not move:
    print("archive-backlog: nothing older than %s to move" % cutoff); sys.exit(0)
def heading(m):
    h=re.match(r'### (P\d+)\s*(?:[—–-]\s*)?(.*)', m)   # em dash, en dash or hyphen after the number
    return h.group(1), (h.group(2) or '').strip()
ids=[heading(m)[0] for m in move]
pointer_lines=''.join('- %s — archived: %s (see docs/backlog-archive.md)\n' % heading(m) for m in move)
new_backlog=pre+''.join(keep)
if '## Archived items' in new_backlog:
    new_backlog=new_backlog.replace('## Archived items\n', '## Archived items\n'+pointer_lines,1)
else:
    new_backlog=new_backlog.rstrip('\n')+'\n\n---\n\n## Archived items\n\nClosed more than 90 days ago; full entries in `docs/backlog-archive.md`, moved verbatim by `scripts/archive-backlog.sh`.\n\n'+pointer_lines
existing=open(archive).read() if os.path.exists(archive) else '# Backlog archive\n\nClosed items moved verbatim from `Backlog.md` by `scripts/archive-backlog.sh`. Never edited here; a revival is a new P-number.\n\n'
def entry_text(m):
    t=m.rstrip('\n')
    t=re.sub(r'\n+---\s*$', '', t)          # an entry's own trailing separator; one is added below
    return t+'\n\n---\n\n'
new_archive=existing.rstrip('\n')+'\n\n'+''.join(entry_text(m) for m in reversed(move))
print("archive-backlog: moving %d item(s) older than %s: %s" % (len(move), cutoff, ' '.join(ids)))
if dry: sys.exit(0)
# Archive first, then Backlog, each through a temp file and an atomic replace:
# an interruption can duplicate an entry, never lose one (review finding).
def atomic_write(path, text):
    os.makedirs(os.path.dirname(path) or '.', exist_ok=True)
    tmp=path+'.tmp'
    with open(tmp,'w') as f: f.write(text); f.flush(); os.fsync(f.fileno())
    os.replace(tmp, path)
atomic_write(archive, new_archive)
atomic_write(backlog, new_backlog)
print("archive-backlog: Backlog.md %d -> %d lines; docs/backlog-archive.md %d lines" % (text.count('\n'), new_backlog.count('\n'), new_archive.count('\n')))
PY
