#!/usr/bin/env python3
"""dds_info.py <client dir> <texture path>... — DDS header summary (size, fourcc, mips, cubemap flag) of the winning copy of each texture."""
import os, struct, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
exec(open(os.path.join(HERE, 'tre_inventory.py')).read().split('if __name__')[0])

root = sys.argv[1]; want = [w.lower().replace('\\', '/') for w in sys.argv[2:]]
winner = {}
for tre in walk_tres(root):
    for e in read_tre(tre):
        n = e['name'].lower()
        if n in want:
            winner[n] = (tre, e)
for w in want:
    if w not in winner:
        print(f'{w}: MISSING'); continue
    tre, e = winner[w]
    with open(tre, 'rb') as f:
        f.seek(e['offset']); blob = f.read(e['comp_size'] if e['comp'] else e['size'])
    d = _inflate(blob, e['comp'], e['size'])
    if d[:4] != b'DDS ':
        print(f'{w}: not DDS ({os.path.basename(tre)})'); continue
    flags, h, wd, pitch, depth, mips = struct.unpack_from('<6I', d, 8)
    fourcc = d[84:88]; caps2 = struct.unpack_from('<I', d, 112)[0]
    print(f'{w}: {os.path.basename(tre)} {wd}x{h} mips={mips} fourcc={fourcc!r} cube={bool(caps2 & 0x200)} caps2={caps2:#x} bytes={len(d)}')
