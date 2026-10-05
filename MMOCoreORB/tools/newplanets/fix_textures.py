#!/usr/bin/env python3
"""fix_textures.py [--fix] — scan build/hoth and build/hoth_loot textures for DDS files the BG client cannot create
(DXT dimensions not a multiple of 4, or non-power-of-two sizes) and, with --fix, re-encode them to the nearest
power-of-two size (DXT1 without alpha, DXT5 with alpha). Textures are UV-mapped, so resizing does not change layout."""
import os, struct, sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
DIRS = [os.path.join(HERE, 'build', 'hoth', 'texture'), os.path.join(HERE, 'build', 'hoth_loot', 'texture')]


def pow2(v):
    return v & (v - 1) == 0


def nearest_pow2(v):
    lo = 1 << (v.bit_length() - 1)
    hi = lo << 1
    return max(4, lo if v - lo <= hi - v else hi)


def scan():
    bad = []
    n = 0
    for d in DIRS:
        for root, _, files in os.walk(d):
            for f in files:
                if not f.lower().endswith('.dds'):
                    continue
                p = os.path.join(root, f)
                n += 1
                h = open(p, 'rb').read(128)
                if h[:4] != b'DDS ':
                    bad.append((p, 'not a DDS', None))
                    continue
                height, width = struct.unpack_from('<II', h, 12)
                mips = struct.unpack_from('<I', h, 28)[0]
                fourcc = h[84:88]
                issues = []
                if fourcc in (b'DXT1', b'DXT3', b'DXT5') and (width % 4 or height % 4):
                    issues.append('DXT dims not multiple of 4')
                if '--strict' in sys.argv and not (pow2(width) and pow2(height)):
                    issues.append('non power of two')
                if issues:
                    bad.append((p, f'{width}x{height} {fourcc.decode("latin-1").strip() or "uncompressed"} mips={mips}: ' + ', '.join(issues), fourcc))
    print(f'{n} textures scanned; {len(bad)} problematic')
    for p, why, _ in bad:
        print('  ', os.path.relpath(p, HERE), why)
    return bad


def fix(bad):
    for p, _, fourcc in bad:
        im = Image.open(p)
        im.load()
        has_alpha = fourcc in (b'DXT3', b'DXT5') and im.mode == 'RGBA' and im.getchannel('A').getextrema()[0] < 255
        w, h = im.size
        nw, nh = nearest_pow2(w), nearest_pow2(h)
        out = im.convert('RGBA' if has_alpha else 'RGB').resize((nw, nh), Image.LANCZOS)
        out.save(p, pixel_format='DXT5' if has_alpha else 'DXT1')
        print(f'  fixed {os.path.relpath(p, HERE)}: {w}x{h} -> {nw}x{nh} {"DXT5" if has_alpha else "DXT1"}')


if __name__ == '__main__':
    bad = scan()
    if '--fix' in sys.argv and bad:
        fix(bad)
        print('re-scan:')
        scan()
