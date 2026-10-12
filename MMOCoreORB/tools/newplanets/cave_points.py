#!/usr/bin/env python3
"""cave_points.py — spawn points inside each Hoth cave cell.

For every cave building in snapshot/hoth.ws: map cell index -> snapshot cell
object ID, read the cave's .pob for each cell's floor (.flr), and pick floor
triangle centroids (cell-local x, height, y) as spawn points. Writes
server_prep/hoth_cave_points.json.
"""
import json
import os
import struct

HERE = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(HERE, 'tre_inventory.py')).read().split('if __name__')[0])
exec(open(os.path.join(HERE, 'iff_tool.py')).read().split("if __name__ == '__main__':")[0])

CLIENT = r'C:\Dev-BG'
CAVES = {  # building template -> pob
    'object/building/general/shared_cave_01_ice.iff': 'appearance/thm_all_cave_s01_ice.pob',
    'object/building/general/shared_cave_02_ice.iff': 'appearance/thm_all_cave_s02_ice.pob',
    'object/building/general/shared_cave_03_ice.iff': 'appearance/thm_all_cave_s03_ice.pob',
    'object/building/general/shared_cave_04_ice_s01.iff': 'appearance/thm_all_cave_s01_ice.pob',
    'object/building/general/shared_cave_06_flatland_s01_ice.iff': 'appearance/thm_all_cave_flatland_s01_ice.pob',
}

_win = None


def client_file(name):
    global _win
    if _win is None:
        _win = {}
        for tre in walk_tres(CLIENT):
            for e in read_tre(tre):
                _win[e['name'].lower()] = (tre, e)
    tre, e = _win[name.lower()]
    with open(tre, 'rb') as f:
        f.seek(e['offset'])
        b = f.read(e['comp_size'] if e['comp'] else e['size'])
    return _inflate(b, e['comp'], e['size'])


def snapshot_nodes():
    """(objId, parentId, template, cellIndex, x, h, y) for every node."""
    buf = open(os.path.join(HERE, 'extract', 'infinity', 'snapshot', 'hoth.ws'), 'rb').read()
    root = parse(buf)
    body = root[0][4][0][4]
    otnl = find(body, ['OTNL'])
    n = struct.unpack_from('<I', otnl)[0]
    names = [x.decode('latin-1') for x in otnl[4:].split(b'\0')[:n]]
    out = []

    def walk(nodes):
        for tag, ft, off, size, kids in nodes:
            if tag == 'FORM' and ft == 'NODE':
                d = find(kids, ['0000', 'DATA'])
                if d and len(d) >= 52:
                    oid, pid, ni, cell, qw, qx, qy, qz, x, h, y = struct.unpack_from('<iiii7f', d)
                    out.append((oid, pid, names[ni], cell, x, h, y))
                walk(kids)
            elif tag == 'FORM':
                walk(kids)
    walk(body)
    return out


def pob_cells(pob):
    """List of (cell name, floor path or None) in cell-index order."""
    root = parse(client_file(pob))
    cells = []

    def walk(nodes):
        for tag, ft, off, size, kids in nodes:
            if tag == 'FORM' and ft == 'CELL':
                strs = re.findall(rb'[\x21-\x7e]{3,}', b''.join(_flatten(kids)))
                flr = next((s.decode().lower() for s in strs if s.lower().endswith(b'.flr')), None)
                name = next((s.decode() for s in strs if not s.lower().endswith((b'.msh', b'.flr', b'.lod', b'.cmp', b'.apt'))
                             and s not in (b'FORM', b'DATA', b'CELL', b'PRTL', b'LGHT', b'IDTL', b'VERT', b'INDX')
                             and not re.fullmatch(rb'\d{4}', s)), '?')
                cells.append((name, flr))
            elif tag == 'FORM':
                walk(kids)
    walk(root)
    return cells


def _flatten(nodes):
    for tag, ft, off, size, kids in nodes:
        if tag == 'FORM':
            yield from _flatten(kids)
        else:
            yield kids


def floor_points(flr, want=6):
    """Centroids of the largest floor triangles (x, height, y in cell space), spread apart."""
    root = parse(client_file(flr if flr.startswith('appearance/') else 'appearance/collision/' + flr.split('/')[-1]))
    verts = tris = None

    def walk(nodes):
        nonlocal verts, tris
        for tag, ft, off, size, kids in nodes:
            if tag == 'FORM':
                walk(kids)
            elif tag == 'VERT':
                n = struct.unpack_from('<I', kids)[0]
                verts = [struct.unpack_from('<3f', kids, 4 + 12 * i) for i in range(n)]
            elif tag == 'TRIS':
                n = struct.unpack_from('<I', kids)[0]
                size_each = (len(kids) - 4) // max(n, 1)
                tris = [struct.unpack_from('<3i', kids, 4 + size_each * i) for i in range(n)]
    walk(root)
    if not verts or not tris:
        return []
    cand = []
    for a, b, c in tris:
        A, B, C = verts[a], verts[b], verts[c]
        ux, uz = B[0] - A[0], B[2] - A[2]
        vx, vz = C[0] - A[0], C[2] - A[2]
        area = abs(ux * vz - uz * vx) / 2
        cx, ch, cz = ((A[0] + B[0] + C[0]) / 3, (A[1] + B[1] + C[1]) / 3, (A[2] + B[2] + C[2]) / 3)
        cand.append((area, cx, ch, cz))
    cand.sort(reverse=True)
    picked = []
    for area, x, h, z in cand:
        if all((x - p[0]) ** 2 + (z - p[2]) ** 2 > 16 for p in picked):  # >= 4 m apart
            picked.append((round(x, 2), round(h, 2), round(z, 2)))
        if len(picked) >= want:
            break
    return picked


def main():
    nodes = snapshot_nodes()
    caves = [n for n in nodes if n[1] == 0 and n[2] in CAVES]
    result = []
    for oid, pid, tmpl, cell, x, h, y in caves:
        cells = pob_cells(CAVES[tmpl])
        kids = {n[3]: n[0] for n in nodes if n[1] == oid}  # cell index -> cell objId
        entry = {'building': tmpl.split('/')[-1].replace('shared_', '').replace('.iff', ''), 'objectId': oid,
                 'world': [round(x, 1), round(h, 1), round(y, 1)], 'pob': CAVES[tmpl], 'cells': []}
        for idx, (name, flr) in enumerate(cells):
            if idx == 0 or idx not in kids:   # cell 0 is the exterior
                continue
            pts = floor_points(flr) if flr else []
            entry['cells'].append({'index': idx, 'cellId': kids[idx], 'name': name, 'floor': flr, 'points': pts})
        result.append(entry)
        print(f"{entry['building']:26s} oid={oid} cells={len(entry['cells'])} "
              f"with-points={sum(1 for c in entry['cells'] if c['points'])} pts={sum(len(c['points']) for c in entry['cells'])}")
    json.dump(result, open(os.path.join(HERE, 'server_prep', 'hoth_cave_points.json'), 'w'), indent=1)


if __name__ == '__main__':
    main()
