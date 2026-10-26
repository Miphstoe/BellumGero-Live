#!/usr/bin/env python3
"""build_tre.py — merge overlay folders onto a base bg_custom1.tre and regenerate the object CRC table.

  python build_tre.py <base.tre> <out.tre> <overlay_dir> [<overlay_dir> ...]

The CRC string table (misc/object_template_crc_string_table.iff) written into <out.tre> is the BASE TRE's own
table plus every object/**/*.iff found in the overlays, so no entry of the base is ever lost (the overlays must
not carry a CRC table of their own). Overlays are applied in order; later ones win.
"""
import os, sys, shutil, tempfile
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
exec(open(os.path.join(HERE, 'tre_inventory.py')).read().split('if __name__')[0])
import cstb_tool
from tre_pack import pack

CRC = 'misc/object_template_crc_string_table.iff'


def main(base, out, overlays):
    if os.path.abspath(base) == os.path.abspath(out):
        sys.exit('refusing to overwrite the base TRE')
    tmp = tempfile.mkdtemp()
    ents = {e['name'].lower(): e for e in read_tre(base)}
    if CRC not in ents:
        sys.exit(f'{base} has no {CRC}; refusing to guess')
    table = cstb_tool.read(extract_entry(base, ents[CRC], os.path.join(tmp, 'base')))
    before = len(table)
    for ov in overlays:
        if os.path.exists(os.path.join(ov, *CRC.split('/'))):
            sys.exit(f'{ov} carries its own {CRC}; delete it, build_tre.py generates the table')
        for root, _, files in os.walk(os.path.join(ov, 'object')):
            for f in files:
                if f.lower().endswith('.iff'):
                    rel = os.path.relpath(os.path.join(root, f), ov).replace(os.sep, '/').lower()
                    cstb_tool.add(table, rel)
    crc_dir = os.path.join(tmp, 'crc'); os.makedirs(os.path.join(crc_dir, 'misc'))
    cstb_tool.write(table, os.path.join(crc_dir, *CRC.split('/')))
    print(f'CRC table: {before} (base) -> {len(table)} entries')
    cur = base
    for i, ov in enumerate(list(overlays) + [crc_dir]):
        nxt = out if i == len(overlays) else os.path.join(tmp, f'step{i}.tre')
        pack(ov, nxt, cur)
        cur = nxt
    shutil.rmtree(tmp, ignore_errors=True)


if __name__ == '__main__':
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2], sys.argv[3:])
