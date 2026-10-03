#!/usr/bin/env python3
"""Merge one planet's elements from Infinity's ui_ticketpurchase.inc into BG's.

  python merge_ticket_ui.py <Planet> <route_partner> [<route_partner> ...]

Copies: the codeData buttonX property, the galaxy-map label Text, the map Page,
the planet 3D viewer + button, the route Runner(s) '<partner>_<planet>' and the
DataSource. Each block is inserted after the equivalent Endor block in BG.
"""
import re
import sys

def load(p):
    return open(p, 'rb').read().decode('latin-1').replace('\r\n', '\n').replace('\r', '\n').split('\n')

def element_end(lines, s):
    depth = 0
    for i in range(s, len(lines)):
        t = lines[i]
        depth += len(re.findall(r'<(?![/!])\w', t))
        depth -= t.count('/>') + len(re.findall(r'</\w', t))
        if depth == 0:
            return i
    raise ValueError('unterminated element at %d' % s)

def element_containing(lines, i, tag):
    k = len(lines[i]) - len(lines[i].lstrip('\t')) - 1
    s = i
    while not lines[s].startswith('\t' * k + '<' + tag):
        s -= 1
        if len(lines[s]) - len(lines[s].lstrip('\t')) < k:
            return None
    return s, element_end(lines, s)

def find_block(lines, name, tag):
    for i, l in enumerate(lines):
        if l.strip() == "Name='%s'" % name:
            r = element_containing(lines, i, tag)
            if r:
                return r
    raise KeyError((name, tag))

def main(planet, partners):
    src = load('extract/infinity/ui/ui_ticketpurchase.inc')
    dst = load('extract/bg/ui/ui_ticketpurchase.inc')
    low = planet.lower()
    inserts = []  # (anchor_name, anchor_tag, lines)
    for name, tag, anchor in [(planet, 'Text', 'Endor'), (planet, 'Page', 'Endor'),
                              ('v' + planet, 'CuiWidget3dObjectListViewer', None),
                              ('button' + planet, 'Button', 'buttonEndor'),
                              (planet, 'DataSource', 'Endor')]:
        s, e = find_block(src, name, tag)
        inserts.append((anchor, tag, src[s:e + 1]))
    # viewer goes right before its button: merge them
    viewer = inserts.pop(2)
    inserts[2] = (inserts[2][0], 'Button', viewer[2] + inserts[2][2])
    for p in partners:
        s, e = find_block(src, '%s_%s' % (p, low), 'Runner')
        # anchor after any existing runner from the partner planet
        inserts.append((None, 'Runner', src[s:e + 1]))
    out = dst[:]
    for anchor, tag, block in inserts:
        if anchor is None:  # runners: after the last Runner element
            idx = max(i for i, l in enumerate(out) if l.lstrip('\t').startswith('<Runner'))
            e = element_end(out, idx)
        else:
            s, e = find_block(out, anchor, tag)
        out[e + 1:e + 1] = block
    # codeData property
    i = next(i for i, l in enumerate(out) if l.strip().startswith("buttonEndor='"))
    out.insert(i + 1, out[i].replace('buttonEndor', 'button' + planet).replace('buttonEndor', 'button' + planet))
    out[i + 1] = re.sub(r"buttonEndor", 'button' + planet, out[i + 1])
    text = '\r\n'.join(out)
    open('build/%s/ui/ui_ticketpurchase.inc' % low, 'wb').write(text.encode('latin-1'))
    print('merged', len(inserts), 'blocks;', len(dst), '->', len(out), 'lines')

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2:])
