#!/usr/bin/env python3
"""cstb_tool.py — read/write SWG CRC string tables (misc/*_crc_string_table.iff)."""
import struct
from tre_pack import soe_crc

def _chunk(tag, data):
    return tag.encode() + struct.pack('>I', len(data)) + data

def read(path):
    exec(open(__file__.replace('cstb_tool.py', 'iff_tool.py')).read().split("if __name__")[0], g := {})
    root = g['parse'](open(path, 'rb').read())
    body = {t: k for t, ft, o, s, k in root[0][4][0][4]}
    n = struct.unpack('<I', body['DATA'])[0]
    crcs = struct.unpack('<%dI' % n, body['CRCT'])
    offs = struct.unpack('<%dI' % n, body['STRT'])
    stng = body['STNG']
    names = [stng[o:stng.index(b'\x00', o)].decode('latin-1') for o in offs]
    return dict(zip(names, crcs))

def write(table, path):
    items = sorted(table.items(), key=lambda kv: kv[1])
    stng, offs = b'', []
    for name, _ in items:
        offs.append(len(stng)); stng += name.encode('latin-1') + b'\x00'
    n = len(items)
    body = (_chunk('DATA', struct.pack('<I', n)) + _chunk('CRCT', struct.pack('<%dI' % n, *[c for _, c in items])) +
            _chunk('STRT', struct.pack('<%dI' % n, *offs)) + _chunk('STNG', stng))
    form0 = _chunk('FORM', b'0000' + body)
    open(path, 'wb').write(_chunk('FORM', b'CSTB' + form0))

def add(table, name):
    table.setdefault(name, soe_crc(name.lower()))
