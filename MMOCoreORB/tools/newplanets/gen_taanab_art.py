#!/usr/bin/env python3
"""gen_taanab_art.py — Taanab paintings for the Norulac raid loot (LIVE-64). Idempotent.

Source art: the 22 painting screenshots Miph shared (PNG, in C:\\Users\\Mobile-Wookie\\Downloads; copied to
art\\taanab\\ on first run). The Taanab posters are not in any client we have, so each painting is cut out of its
screenshot (inside the rendered frame), resized, and put in a stock BG frame of the matching shape.

Client (build/taanab_art/, merged on top of the base TRE with build_tre.py):
  texture/taanab_art_<key>.dds                     DXT1, 512x256 (wide) / 256x512 (tall) / 512x512 (square)
  shader/taanab_art_<key>.sht                      clone of the single-texture Hoth painting shader, texture swapped
  appearance/mesh/taanab_art_<key>.msh             clone of stock frn_all_painting_<shape>_s0N.msh, canvas shader swapped
  appearance/taanab_art_<key>.apt                  clone of the stock .apt, mesh path swapped
  object/tangible/painting/shared_taanab_art_<key>.iff   clone of the Hoth art template; names in taanab_art_n/_d
  string/en/taanab_art_n.stf, taanab_art_d.stf     new tables (art_n/art_d already belong to Hoth)
Server (worktree scripts dir): painting templates, shared defs, loot items, loot group taanab_art.

  python gen_taanab_art.py            # client + server
  python gen_taanab_art.py --preview  # only writes build/taanab_art_preview.png (crop check)
"""
import os, sys, shutil
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
exec(open(os.path.join(HERE, 'tre_inventory.py')).read().split('if __name__')[0])
import iff_clone, stf_tool
import gen_taanab_mobiles as g

SRC_DIR = r'C:\Users\Mobile-Wookie\Downloads'
ART_DIR = os.path.join(HERE, 'art', 'taanab')
OUT = os.path.join(HERE, 'build', 'taanab_art')
BG = r'C:\Dev-BG'
CACHE = os.path.join(HERE, 'extract', 'bg')
HOTH = os.path.join(HERE, 'build', 'hoth_loot')
DONOR_SHT = os.path.join(HOTH, 'shader', 'hothatatlg_01_f00_000000000000.sht')
DONOR_TEX = 'texture/hothatatlg_01_0000000000000000.dds'
DONOR_IFF = os.path.join(HOTH, 'object', 'tangible', 'painting', 'shared_hothatatlg_01_f00_000000000000.iff')
STF_LIKE = os.path.join(HERE, 'build', 'hoth', 'string', 'en', 'hoth_region_names.stf')

# stock canvas shader per shape (the one swapped out of the frame mesh) and texture size
SHAPES = {'wide': ('shader/frn_all_painting_256x128_agrilat_swap_as8.sht', (512, 256), 1.84),
          'tall': ('shader/frn_all_painting_128x256_swap_as8.sht', (256, 512), 0.54),
          'square_lg': ('shader/frn_all_painting_256x256_swap_as8.sht', (512, 512), 0.95)}
FRAME = {'silver': 1, 'gold': 2}

# key, screenshot, box in screenshot (outer edge of the rendered frame), frame inset px, shape, frame, name, description
ART = [
    ('pandath', '211image.png', (24, 37, 249, 160), 1, 'wide', 'silver', 'Pandath Taanab Poster',
     'A travel poster of Pandath\'s green domes. "Visit Pandath" runs along the bottom in Aurebesh.'),
    ('starhunter', '21image.png', (16, 35, 241, 149), 1, 'wide', 'silver', 'Starhunter Station Taanab Poster',
     'Starhunter Station at dusk. A poster from the station\'s own tourism office, which is one droid.'),
    ('invasive_species', '221image.png', (11, 40, 236, 159), 8, 'wide', 'gold', 'Invasive Species Warning',
     'An agricultural board notice: do not bring off-world plants or animals through the gate.'),
    ('death_troopers', '22221.png', (26, 36, 180, 261), 11, 'tall', 'gold', 'Death Troopers',
     'A grim scene of an Imperial prison barge gone very wrong.'),
    ('see_taanab', '3image.png', (31, 42, 256, 159), 7, 'wide', 'gold', 'See Taanab Advertisement',
     'Taanab and its sun, framed for the spaceport lounges of the Inner Rim.'),
    ('arc170', '4erwer.png', (21, 43, 246, 170), 9, 'wide', 'gold', 'ARC-170 in Flight',
     'An ARC-170 starfighter banks hard over a red world. Clone Wars era, lovingly restored.'),
    ('galactic_gathering', 'i221mage.png', (21, 45, 184, 270), 10, 'tall', 'gold', 'Galactic Gathering',
     'A commemorative print from a gathering of spacers from across the galaxy.'),
    ('islands', 'i2mage.png', (27, 36, 252, 154), 8, 'wide', 'gold', 'Islands of Taanab',
     'Taanab\'s moon rises over the island chains and the violet shallows.'),
    ('research_facility', 'i443mage.png', (42, 47, 267, 176), 9, 'wide', 'gold', 'Abandoned Research Facility',
     'The ruins of a research facility in the Taanab hills. Nobody says what was researched.'),
    ('vos_storehouse', 'i443mage.png', (42, 229, 267, 364), 11, 'wide', 'gold', 'Abandoned Vos Storehouse',
     'A long-empty storehouse in a green valley. The Vos family never came back for it.'),
    ('fly_for_freedom', 'imag41e.png', (12, 28, 133, 253), 15, 'tall', 'silver', 'Fly for Freedom',
     'A recruiting poster: a freighter threads an asteroid field. The slogan is in Aurebesh.'),
    ('painted_hills_1', 'image-1.png', (14, 62, 239, 176), 1, 'wide', 'silver', 'Painted Hills (Style 1)',
     'The Painted Hills of Taanab under a dusty evening sky.'),
    ('painted_hills_2', 'image-1.png', (14, 256, 239, 369), 1, 'wide', 'silver', 'Painted Hills (Style 2)',
     'The Painted Hills reflected in the still water of a lowland lake.'),
    ('wildlife', 'image.png', (34, 53, 259, 274), 16, 'square_lg', 'silver', 'Wildlife of Taanab',
     'A Taanab grazer stands in the long grass, part of a series on the planet\'s wildlife.'),
    ('great_herds', 'image1.png', (11, 58, 236, 171), 1, 'wide', 'silver', 'The Great Herds Poster',
     'The herds gather around a watchtower on the open plains. The tower keeper painted it from memory.'),
    ('defense_outpost', '2image.png', (12, 34, 237, 162), 9, 'wide', 'gold', 'Taanab Defense Force Outpost',
     'A Taanab Defense Force outpost on the purple flats. The guns face the sky; the Norulac came by land.'),
    ('hydro_station', '2image.png', (12, 215, 237, 343), 10, 'wide', 'gold', 'Taanab Hydro Station',
     'The hydro station in its valley, condensers gleaming.'),
    ('mining_facility', '2image.png', (12, 422, 237, 536), 1, 'wide', 'silver', 'Taanab Mining Facility Poster',
     'The mining outfit on its ridge. A company poster, so the dust has been painted out.'),
    ('roba_cave', '2image.png', (12, 590, 237, 717), 9, 'wide', 'gold', 'Taanab Roba Cave Painting',
     'The overgrown mound of the roba cave. Hunters hang this one for luck.'),
    ('shipwreck', '2image.png', (12, 797, 237, 911), 1, 'wide', 'silver', 'Taanab Shipwreck Poster',
     'The wrecked freighter in the grasslands, before the salvagers moved in.'),
    ('surveyors', '2image.png', (12, 964, 237, 1093), 9, 'wide', 'gold', 'Taanab Surveyors Encampment',
     'The surveyors\' camp among the stone pillars.'),
    ('vista_plateau', '2image.png', (12, 1173, 237, 1286), 1, 'wide', 'silver', 'Taanab Vista Plateau Poster',
     'The Vista Plateau, lit up at night. Best view on the planet, says the poster.'),
]
GROUP = 'taanab_art'
CROP_SHARE = 0.35


def out(rel):
    p = os.path.join(OUT, *rel.split('/')); os.makedirs(os.path.dirname(p), exist_ok=True); return p


_bg = None
def bg_file(path):
    """Extract a dev-client file (highest-priority TRE wins) into extract/bg and return its local path."""
    global _bg
    local = os.path.join(CACHE, *path.split('/'))
    if os.path.exists(local):
        return local
    if _bg is None:
        _bg = {}
        for tre in walk_tres(BG):
            for e in read_tre(tre):
                _bg[e['name'].lower()] = (tre, e)
    tre, e = _bg[path.lower()]
    return extract_entry(tre, e, CACHE)


def source(src):
    os.makedirs(ART_DIR, exist_ok=True)
    local = os.path.join(ART_DIR, src)
    if not os.path.exists(local):
        shutil.copyfile(os.path.join(SRC_DIR, src), local)
    return local


def canvas(key, src, box, inset, shape):
    """Cut the painting out of its screenshot and fit it to the canvas aspect: crop CROP_SHARE of the mismatch (log
    scale) and stretch the rest, so titles near the edges survive."""
    im = Image.open(source(src)).convert('RGB')
    l, t, r, b = box
    im = im.crop((l + inset, t + inset, r - inset, b - inset))
    w, h = im.size
    _, size, target = SHAPES[shape]
    aspect = w / h
    keep = aspect ** (1 - CROP_SHARE) * target ** CROP_SHARE  # aspect we crop to before the stretch
    if aspect > target:
        nw = round(h * keep); im = im.crop(((w - nw) // 2, 0, (w - nw) // 2 + nw, h))
    else:
        nh = round(w / keep); im = im.crop((0, (h - nh) // 2, w, (h - nh) // 2 + nh))
    return im.resize(size, Image.LANCZOS)


def preview():
    tiles = [(key, canvas(key, src, box, inset, shape)) for key, src, box, inset, shape, *_ in ART]
    W = 260; cols = 6; rows = (len(tiles) + cols - 1) // cols
    sheet = Image.new('RGB', (W * cols, W * rows), (240, 240, 240))
    for i, (key, im) in enumerate(tiles):
        im = im.copy(); im.thumbnail((W - 10, W - 10)); sheet.paste(im, ((i % cols) * W + 5, (i // cols) * W + 5))
    p = os.path.join(HERE, 'build', 'taanab_art_preview.png'); sheet.save(p); print(p)


def client():
    for key, src, box, inset, shape, frame, *_ in ART:
        n = f'taanab_art_{key}'
        canvas(key, src, box, inset, shape).save(out(f'texture/{n}.dds'), pixel_format='DXT1')
        stock = f'frn_all_painting_{shape}_s0{FRAME[frame]}'
        iff_clone.clone_raw(DONOR_SHT, out(f'shader/{n}.sht'), {DONOR_TEX: f'texture/{n}.dds'})
        iff_clone.clone_raw(bg_file(f'appearance/mesh/{stock}.msh'), out(f'appearance/mesh/{n}.msh'),
                            {SHAPES[shape][0]: f'shader/{n}.sht'})
        iff_clone.clone_raw(bg_file(f'appearance/{stock}.apt'), out(f'appearance/{n}.apt'),
                            {f'appearance/mesh/{stock}.msh': f'appearance/mesh/{n}.msh'})
        iff_clone.clone(DONOR_IFF, out(f'object/tangible/painting/shared_{n}.iff'),
                        {'appearanceFilename': f'appearance/{n}.apt', 'objectName': f'taanab_art_n:{n}',
                         'detailedDescription': f'taanab_art_d:{n}', 'lookAtText': f'taanab_art_n:{n}'})
    for table, col in (('taanab_art_n', 6), ('taanab_art_d', 7)):
        t = stf_tool.read(STF_LIKE); t['vals'] = {}; t['keys'] = []; t['next'] = 1
        for row in ART:
            stf_tool.add(t, f'taanab_art_{row[0]}', row[col])
        stf_tool.write(t, out(f'string/en/{table}.stf'))
    print(f'client: {len(ART)} paintings in {OUT}')


def luaid(client_path):
    return client_path[:-4].replace('/', '_')


def server():
    objects = os.path.join(g.ROOT, 'object', 'tangible', 'painting', 'objects.lua')
    s = open(objects, encoding='utf-8', newline='').read(); nl = '\r\n' if '\r\n' in s else '\n'
    add = []
    for key, *_rest in ART:
        n = f'taanab_art_{key}'; shared = f'object/tangible/painting/shared_{n}.iff'; tangible = f'object/tangible/painting/{n}.iff'
        if luaid(shared) + ' =' not in s:
            add.append(f'{luaid(shared)} = SharedTangibleObjectTemplate:new {{{nl}\tclientTemplateFileName = "{shared}"{nl}}}{nl}{nl}'
                       f'ObjectTemplates:addClientTemplate({luaid(shared)}, "{shared}"){nl}')
        g.write(f'object/tangible/painting/{n}.lua',
                f'{luaid(tangible)} = {luaid(shared)}:new {{\n}}\n\nObjectTemplates:addTemplate({luaid(tangible)}, "{tangible}")\n')
        g.register('object/tangible/painting/serverobjects.lua', f'includeFile("tangible/painting/{n}.lua")')
        g.write(f'loot/items/bellum/taanab/{n}.lua',
                f'-- Generated by NewPlanets/gen_taanab_art.py (Norulac raid loot, LIVE-64).\n{n} = {{\n\tminimumLevel = 0,\n\tmaximumLevel = -1,\n'
                f'\tcustomObjectName = "",\n\tdirectObjectTemplate = "{tangible}",\n\tcraftingValues = {{\n\t}},\n'
                f'\tcustomizationStringNames = {{}},\n\tcustomizationValues = {{}}\n}}\n\naddLootItemTemplate("{n}", {n})\n')
        g.register('loot/items.lua', f'includeFile("items/bellum/taanab/{n}.lua")', after_prefix='includeFile("items/bellum/taanab/')
    if add:
        s = s.rstrip('\r\n') + nl + nl + nl.join(add)
        open(objects, 'w', encoding='utf-8', newline='').write(s)
    weight = 10000000 // len(ART)
    rows = ''.join(f'\t\t{{itemTemplate = "taanab_art_{k}", weight = {weight + (10000000 - weight * len(ART) if i == 0 else 0)}}},\n'
                   for i, (k, *_r) in enumerate(ART))
    g.write(f'loot/groups/bellum/taanab/{GROUP}.lua',
            f'-- Generated by NewPlanets/gen_taanab_art.py. Taanab paintings (Norulac raid). Weights total 10,000,000.\n'
            f'{GROUP} = {{\n\tdescription = "",\n\tminimumLevel = 0,\n\tmaximumLevel = 0,\n\tlootItems = {{\n{rows}\t}}\n}}\n\n'
            f'addLootGroupTemplate("{GROUP}", {GROUP})\n')
    g.register('loot/groups.lua', f'includeFile("groups/bellum/taanab/{GROUP}.lua")', after_prefix='includeFile("groups/bellum/taanab/')
    print(f'server: {len(ART)} painting templates + loot items, group {GROUP} ({len(add)} new shared defs)')


if __name__ == '__main__':
    if '--preview' in sys.argv:
        preview()
    else:
        client(); server()
