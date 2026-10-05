#!/usr/bin/env python3
"""trn_inspect.py [trn] — raw dump of every LAYR that holds a circle boundary: the layer's direct children with their
leaf chunks in hex, so boundary/affector field layouts can be checked before editing."""
import os, struct, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
exec(open(os.path.join(HERE, 'iff_tool.py')).read().split("if __name__ == '__main__':")[0])

path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'build', 'hoth', 'terrain', 'hoth.trn')
root = parse(open(path, 'rb').read())


def leaves(nodes, path=''):
    for tag, ft, off, size, kids in nodes:
        if tag == 'FORM':
            yield from leaves(kids, path + '/' + ft)
        else:
            yield path + '/' + tag, kids


def show(nodes, depth):
    for tag, ft, off, size, kids in nodes:
        if tag != 'FORM':
            continue
        if ft == 'LAYR':
            print('  ' * depth + 'LAYR')
            for t2, f2, o2, s2, k2 in kids:
                if t2 == 'FORM' and f2 != 'LAYR':
                    for p, d in leaves(k2, f2):
                        txt = d[:48].hex(' ', 4)
                        extra = ''
                        if p.endswith('DATA') and len(d) % 4 == 0 and len(d) <= 48:
                            extra = '  f=' + ' '.join(f'{v:.2f}' for v in struct.unpack_from(f'<{len(d)//4}f', d))
                        if 'IHDR' in p:
                            extra = '  name=' + d[4:].split(b'\0')[0].decode('latin-1')
                        print('  ' * (depth + 1) + f'{p} [{len(d)}] {txt}{extra}')
            show(kids, depth + 1)
        else:
            show(kids, depth)


show(root, 0)
