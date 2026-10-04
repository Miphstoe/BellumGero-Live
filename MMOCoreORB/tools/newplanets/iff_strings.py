#!/usr/bin/env python3
"""iff_strings.py <file>... — print printable strings (>=4 chars) found in binary IFF files, excluding 4-char chunk tags."""
import re, sys
TAGS = {b'FORM',b'SHOT',b'STOT',b'DERV',b'XXXX',b'PCNT',b'SWOT',b'SVOT',b'SMSO',b'SPCT',b'DSCO',b'ARMO',b'DATA',b'0000',b'0001',b'0002',b'0003',b'0004',b'0005',b'0006',b'0007',b'0008',b'0009',b'0010',b'0011',b'0012',b'0013',b'0014',b'0015',b'0016',b'0017',b'0018',b'0019',b'0020',b'0021',b'0022',b'0023',b'0024'}
for f in sys.argv[1:]:
    d = open(f, 'rb').read()
    out = [s.decode('latin-1') for s in re.findall(rb'[\x20-\x7e]{4,}', d) if s not in TAGS]
    print(f'### {f}\n  ' + ' | '.join(out))
