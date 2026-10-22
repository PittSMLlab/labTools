"""anchorCheck.py - verify #anchors in markdown links resolve.

Checks every `](file.md#anchor)` and `](#anchor)` link in the given .md
files against GitHub heading slugs of the target file (code fences
skipped, duplicate headings get -1, -2 suffixes).
Usage: python anchorCheck.py FILE.md...   Exit: 0 clean, 1 otherwise.
"""
import os
import re
import sys

LINK = re.compile(r'\]\(([^)\s]*)#([^)\s]+)\)')


def slugs(path):
    out, seen, fence = set(), {}, False
    with open(path, encoding='utf-8') as fh:
        for line in fh:
            if line.lstrip().startswith('```'):
                fence = not fence
                continue
            m = None if fence else re.match(r'#{1,6}\s+(.*?)\s*#*\s*$', line)
            if not m:
                continue
            s = m.group(1).strip().lower()
            s = re.sub(r'[^\w\- ]', '', s).replace(' ', '-')
            n = seen.get(s, 0)
            seen[s] = n + 1
            out.add(s if n == 0 else f'{s}-{n}')
    return out


def main(files):
    bad = n = 0
    cache = {}
    for f in files:
        with open(f, encoding='utf-8') as fh:
            text = fh.read()
        for tgt, anc in LINK.findall(text):
            if re.match(r'https?:|mailto:', tgt):
                continue
            path = os.path.normpath(os.path.join(os.path.dirname(f), tgt)) \
                if tgt else f
            if not path.endswith('.md') or not os.path.exists(path):
                continue
            n += 1
            if path not in cache:
                cache[path] = slugs(path)
            if anc.lower() not in cache[path]:
                print(f'BROKEN ANCHOR  {f} -> {tgt}#{anc}')
                bad += 1
    print(f'anchors checked: {n}; problems: {bad}')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
