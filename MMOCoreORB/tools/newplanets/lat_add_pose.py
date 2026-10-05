#!/usr/bin/env python3
"""lat_add_pose.py — add rider poses to a player logical animation table (appearance/lat/all_m.lat).

  python lat_add_pose.py <base.lat> <donor.lat> <out.lat> <pose> [<pose> ...]

Every *_riding logical animation in a LAT holds a string selector on `rider_pose`:
  FORM SSAT / FORM 0000: INFO 'rider_pose', FORM ANMS (INFO uint16 count + one FORM PXAT per pose:
  INFO '<ans path>', PPTR props), VAL (pairs of uint16 index + 'pose name'), DFLT uint16.
For each such animation in <base>, the matching animation in <donor> is looked up by logical name, the donor's
PXAT for each requested pose is appended to the base's list, the count is bumped and VAL gets the new index.
The donor's .ans files for those poses must be shipped alongside (see the printed list). Idempotent.
"""
import os, struct, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
from iff_tool import parse
from iff_clone import serialize


def anim_name(node, buf):
    for t, ft, off, size, kids in node[4]:
        if t == 'INFO':
            return kids.split(b'\x00', 1)[0].decode('latin-1')
    return None


def find_selector(node):
    """Return the FORM 0000 under SSAT that selects on rider_pose, or None."""
    stack = [node]
    while stack:
        n = stack.pop()
        if n[0] == 'FORM':
            if n[1] == 'SSAT':
                for k in n[4]:
                    if k[0] == 'FORM' and k[1] == '0000':
                        infos = [c for c in k[4] if c[0] == 'INFO']
                        if infos and infos[0][4].startswith(b'rider_pose\x00'):
                            return k
            stack.extend(n[4])
    return None


def parse_val(data):
    """VAL = uint16 count, then count x ('name\\0' + uint16 entry index). Includes a 'default' name."""
    count = struct.unpack_from('<H', data, 0)[0]
    pairs, o = [], 2
    for _ in range(count):
        end = data.index(b'\x00', o)
        name = data[o:end].decode('latin-1'); o = end + 1
        idx = struct.unpack_from('<H', data, o)[0]; o += 2
        pairs.append((idx, name))
    assert o == len(data), 'VAL has trailing bytes'
    return pairs


def build_val(pairs):
    """The client binary-searches VAL by the SOE CRC-32 of the pose name, so entries must be sorted by that hash."""
    from tre_pack import soe_crc
    pairs = sorted(pairs, key=lambda p: soe_crc(p[1]))
    return struct.pack('<H', len(pairs)) + b''.join(n.encode('latin-1') + b'\x00' + struct.pack('<H', i) for i, n in pairs)


def selector_parts(sel):
    """(anms form, val chunk) from a selector FORM 0000."""
    anms = next(k for k in sel[4] if k[0] == 'FORM' and k[1] == 'ANMS')
    val = next(k for k in sel[4] if k[0] == 'VAL ')
    return anms, val


def pose_entries(sel):
    anms, val = selector_parts(sel)
    pxats = [k for k in anms[4] if k[0] == 'FORM' and k[1] == 'PXAT']
    return pxats, parse_val(val[4])


def ans_of(pxat):
    for t, ft, off, size, kids in pxat[4][0][4]:  # FORM 0000 children
        if t == 'INFO':
            return kids.split(b'\x00', 1)[0].decode('latin-1')


def add_poses(base_path, donor_path, out_path, poses):
    bbuf, dbuf = open(base_path, 'rb').read(), open(donor_path, 'rb').read()
    broot, droot = parse(bbuf), parse(dbuf)
    assert serialize(broot) == bbuf, 'base round-trip mismatch'
    donors = {anim_name(n, dbuf): n for n in droot[0][4][0][4] if n[0] == 'FORM' and n[1] == 'ANIM'}
    # fallback entries: any donor riding animation that knows the pose (used when the same-named animation does not)
    fallback = {}
    for dn in donors.values():
        ds = find_selector(dn)
        if ds is None:
            continue
        dpx, dval = pose_entries(ds)
        for i, pname in dval:
            if pname in poses and pname not in fallback and i < len(dpx):
                fallback[pname] = dpx[i]
    needed_ans, touched, missing = set(), 0, set()
    for n in broot[0][4][0][4]:
        if n[0] != 'FORM' or n[1] != 'ANIM':
            continue
        sel = find_selector(n)
        if sel is None:
            continue
        name = anim_name(n, bbuf)
        dsel = find_selector(donors[name]) if name in donors else None
        bpx, bval = pose_entries(sel)
        dpx, dval = pose_entries(dsel) if dsel is not None else ([], [])
        dindex = {pname: i for i, pname in dval}
        anms, val = selector_parts(sel)
        changed = False
        for pose in poses:
            if any(pname == pose for _, pname in bval):
                continue  # already there
            if pose in dindex:
                entry = dpx[dindex[pose]]
            elif pose in fallback:
                entry = fallback[pose]; missing.add(f'{name}:{pose} (used fallback entry)')
            else:
                missing.add(f'{name}:{pose} (no donor entry)'); continue
            anms[4].append(entry)
            bval.append((len(bpx), pose)); bpx.append(entry)
            needed_ans.add(ans_of(entry)); changed = True
        if changed:
            # rewrite count and VAL in place (tuples are immutable: rebuild the lists)
            new_kids = []
            for k in anms[4]:
                if k[0] == 'INFO':
                    k = ('INFO', None, k[2], 2, struct.pack('<H', len(bpx)))
                new_kids.append(k)
            anms[4][:] = new_kids
            sel_kids = []
            for k in sel[4]:
                if k[0] == 'VAL ':
                    nv = build_val(bval); k = ('VAL ', None, k[2], len(nv), nv)
                sel_kids.append(k)
            sel[4][:] = sel_kids
            touched += 1
    os.makedirs(os.path.dirname(out_path) or '.', exist_ok=True)
    open(out_path, 'wb').write(serialize(broot))
    print(f'{os.path.basename(out_path)}: {touched} riding animations updated; animations to ship: {sorted(needed_ans)}')
    if missing:
        print('  not found in donor:', sorted(missing))
    return needed_ans


def verify(path, poses):
    buf = open(path, 'rb').read(); root = parse(buf); ok = 0
    for n in root[0][4][0][4]:
        if n[0] == 'FORM' and n[1] == 'ANIM':
            sel = find_selector(n)
            if sel is None:
                continue
            px, val = pose_entries(sel)
            anms, _ = selector_parts(sel)
            count = struct.unpack('<H', next(k for k in anms[4] if k[0] == 'INFO')[4])[0]
            names = [v for _, v in val]
            assert count == len(px) and len(val) == count + ('default' in names), (anim_name(n, buf), count, len(px), len(val))
            assert all(0 <= i < count for i, _ in val), (anim_name(n, buf), 'index out of range')
            assert all(p in {v for _, v in val} for p in poses), anim_name(n, buf)
            ok += 1
    print(f'verified {ok} riding animations in {os.path.basename(path)}')


if __name__ == '__main__':
    if len(sys.argv) < 5:
        sys.exit(__doc__)
    add_poses(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4:])
    verify(sys.argv[3], sys.argv[4:])
