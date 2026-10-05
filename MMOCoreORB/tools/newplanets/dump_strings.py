#!/usr/bin/env python3
"""dump_strings.py <minidump> [pattern] — list asset paths found in a client minidump, optionally filtered by a regex."""
import re, sys
d = open(sys.argv[1], 'rb').read()
pat = re.compile(sys.argv[2], re.I) if len(sys.argv) > 2 else None
hits = sorted(set(m.decode('latin-1') for m in re.findall(rb'[a-z0-9_/]+\.(?:dds|sht|msh|mgn|lmg|apt|sat|skt|lat|ans|iff|lod|stf|cdf|prt|snd)', d, re.I)))
print(len(hits), 'asset paths in dump')
for h in hits:
    if pat is None or pat.search(h):
        print('  ', h)
