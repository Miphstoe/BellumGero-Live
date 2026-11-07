"""flr_spots.py <flr>... : open floor spots (server x, z, y) with clearance from the floor boundary, for NPC placement."""
import struct, sys, math
import iff_tool as t


def chunk(nodes, path):
    return t.find(nodes, path)


def load(path):
    d = open(path, 'rb').read()
    nodes = t.parse(d)
    def get(tag):
        stack = list(nodes)
        while stack:
            n = stack.pop(0)
            if n[1] == tag or (n[0] == tag and n[1] is None):
                return n
            if isinstance(n[4], list):
                stack.extend(n[4])
    vert = get('VERT')[4]; tris = get('TRIS')[4]; bedg = get('BEDG')[4]
    nv = struct.unpack_from('<i', vert)[0]
    V = [struct.unpack_from('<3f', vert, 4 + 12 * i) for i in range(nv)]
    nt = struct.unpack_from('<i', tris)[0]
    T = [struct.unpack_from('<3i', tris, 4 + 60 * i) for i in range(nt)]
    nb = struct.unpack_from('<i', bedg)[0]
    B = [struct.unpack_from('<ii', bedg, 4 + 9 * i) for i in range(nb)]
    return V, T, B


def seg_dist(px, pz, ax, az, bx, bz):
    dx, dz = bx - ax, bz - az
    l = dx * dx + dz * dz
    u = 0 if l == 0 else max(0, min(1, ((px - ax) * dx + (pz - az) * dz) / l))
    return math.hypot(px - ax - u * dx, pz - az - u * dz)


def spots(path, step=0.5, minclear=1.2):
    V, T, B = load(path)
    edges = [(V[T[ti][e]], V[T[ti][(e + 1) % 3]]) for ti, e in B]
    out = []
    xs = [v[0] for v in V]; zs = [v[2] for v in V]
    x = min(xs)
    while x <= max(xs):
        z = min(zs)
        while z <= max(zs):
            for a, b, c in T:
                A, Bv, C = V[a], V[b], V[c]
                d = (Bv[2] - C[2]) * (A[0] - C[0]) + (C[0] - Bv[0]) * (A[2] - C[2])
                if d == 0: continue
                l1 = ((Bv[2] - C[2]) * (x - C[0]) + (C[0] - Bv[0]) * (z - C[2])) / d
                l2 = ((C[2] - A[2]) * (x - C[0]) + (A[0] - C[0]) * (z - C[2])) / d
                l3 = 1 - l1 - l2
                if min(l1, l2, l3) >= 0:
                    h = l1 * A[1] + l2 * Bv[1] + l3 * C[1]
                    cl = min(seg_dist(x, z, e[0][0], e[0][2], e[1][0], e[1][2]) for e in edges)
                    if cl >= minclear:
                        out.append((cl, x, h, z))
                    break
            z += step
        x += step
    return out


if __name__ == '__main__':
    for p in sys.argv[1:]:
        s = spots(p)
        s.sort(reverse=True)
        picked = []
        for cl, x, h, z in s:  # greedy spread: at least 2.5 m apart
            if all(math.hypot(x - px, z - pz) >= 2.5 for _, px, _, pz in picked):
                picked.append((cl, x, h, z))
            if len(picked) >= 8: break
        print(p.split('thm_nboo_cantina_')[-1].split('_collision')[0], ' '.join(f'({x:.1f},{h:.2f},{z:.1f})c{cl:.1f}' for cl, x, h, z in picked))
