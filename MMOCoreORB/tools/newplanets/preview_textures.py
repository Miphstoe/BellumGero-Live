#!/usr/bin/env python3
"""preview_textures.py <client dir> <out dir> <mesh .mgn/.msh path>... — follow each mesh's shaders to their main
textures and write PNG previews (needs Pillow, which decodes DXT1/3/5 DDS)."""
import io, os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
exec(open(os.path.join(HERE, 'tre_inventory.py')).read().split('if __name__')[0])
from PIL import Image

root, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
win = {}
for tre in walk_tres(root):
    for e in read_tre(tre):
        win[e['name'].lower()] = (tre, e)


def data(rel):
    tre, e = win[rel.lower()]
    with open(tre, 'rb') as f:
        f.seek(e['offset']); blob = f.read(e['comp_size'] if e['comp'] else e['size'])
    return _inflate(blob, e['comp'], e['size'])


for mesh in sys.argv[3:]:
    shaders = sorted(set(m.decode().lower() for m in re.findall(rb'shader[/\\][a-z0-9_\-]+\.sht', data(mesh), re.I)))
    for sh in shaders:
        sh = sh.replace('\\', '/')
        if sh not in win:
            print('missing', sh); continue
        texs = [t.decode().replace('\\', '/') for t in re.findall(rb'texture[/\\][a-z0-9_\-]+\.dds', data(sh), re.I)]
        for t in texs[:1] + [x for x in texs if not x.endswith(('_n.dds', '_cn.dds', '_s.dds', '_spec.dds'))][:2]:
            if t.lower() not in win:
                continue
            try:
                img = Image.open(io.BytesIO(data(t)))
                img.thumbnail((512, 512))
                name = os.path.join(out, os.path.basename(mesh).split('.')[0] + '__' + os.path.basename(t).replace('.dds', '.png'))
                img.convert('RGB').save(name)
                print(mesh, sh, '->', name)
            except Exception as ex:
                print('cannot decode', t, ex)
