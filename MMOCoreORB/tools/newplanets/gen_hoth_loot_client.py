#!/usr/bin/env python3
"""gen_hoth_loot_client.py — client files for the Hoth loot pass (Ender_Hoth_Loot_and_more). Idempotent.

Writes into build/hoth_loot/ (overlay merged on top of build/hoth):
  * cloned draft-schematic / loot-schematic / decor object templates (iff_clone.py)
  * string tables: frn_n/frn_d (BG copy + Hoth keys), new art_n/art_d/dt_n/dt_d
  * misc/object_template_crc_string_table.iff = build/hoth table + every new object path
Ported Infinity files are staged separately by stage_closure.py from audit/hoth_loot_closure.tsv.
"""
import os, sys, shutil
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
exec(open(os.path.join(HERE, 'tre_inventory.py')).read().split('if __name__')[0])
import iff_clone, stf_tool, cstb_tool
import gen_hoth_art

BG = r'C:\BellumGero'
OUT = os.path.join(HERE, 'build', 'hoth_loot')
CACHE = os.path.join(HERE, 'extract', 'bg')
_bg = None


def bg_file(path):
    """Extract a BG client file (highest-priority TRE wins) into extract/bg and return its local path."""
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


def out(path):
    p = os.path.join(OUT, *path.split('/'))
    os.makedirs(os.path.dirname(p), exist_ok=True)
    return p


NEW_OBJECTS = []  # every client object path we add (for the CRC table)


def ported_objects():
    for root, _, files in os.walk(os.path.join(OUT, 'object')):
        for f in files:
            yield os.path.relpath(os.path.join(root, f), OUT).replace('\\', '/')


def clone(src_path, dst_path, **patches):
    dst = out(dst_path)
    if patches:
        iff_clone.clone(bg_file(src_path), dst, patches)
    else:
        shutil.copyfile(bg_file(src_path), dst)
    NEW_OBJECTS.append(dst_path)


# ---------------------------------------------------------------- armor
PIECES = ['belt', 'bicep_l', 'bicep_r', 'boots', 'bracer_l', 'bracer_r', 'chest_plate', 'gloves', 'helmet', 'leggings']
ST_SRC = {'belt': 'utility_belt'}  # stormtrooper source piece name per our piece name
SETS = {  # set key -> (wearable dir, wearable prefix, backpack client iff)
    'snowtrooper': ('snowtrooper', 'armor_snowtrooper', 'object/tangible/wearables/backpack/shared_backpack_snowtrooper.iff'),
    'rebel_snow': ('rebel_snow', 'armor_rebel_snow', 'object/tangible/wearables/backpack/shared_backpack_rebel_snow_soldier.iff'),
}


def armor():
    for key, (d, prefix, backpack) in SETS.items():
        for p in PIECES:
            src = ST_SRC.get(p, p)
            target = f'object/tangible/wearables/armor/{d}/shared_{prefix}_{p}.iff'
            clone(f'object/draft_schematic/clothing/shared_clothing_armor_stormtrooper_{src}.iff',
                  f'object/draft_schematic/clothing/shared_clothing_armor_{key}_{p}.iff', craftedSharedTemplate=target)
            clone(f'object/tangible/loot/loot_schematic/shared_stormtrooper_{src}_crafted_schematic.iff',
                  f'object/tangible/loot/loot_schematic/shared_{key}_{p}_crafted_schematic.iff')
        clone('object/draft_schematic/clothing/shared_clothing_armor_marine_backpack.iff',
              f'object/draft_schematic/clothing/shared_clothing_armor_{key}_backpack.iff', craftedSharedTemplate=backpack)
        clone('object/tangible/loot/loot_schematic/shared_marine_backpack_crafted_schematic.iff',
              f'object/tangible/loot/loot_schematic/shared_{key}_backpack_crafted_schematic.iff')


# ---------------------------------------------------------------- paintings (ported Infinity object iffs; names in art_n)
PAINTINGS = [  # key, client iff stem, art_n key, name, description
    ('battle', 'hothbattle_01_f00_000000000000', 'hothbattle_01_0000000000000000', 'First Strike on Hoth',
     'Rebel snowspeeders dive on the advancing Imperial walkers in the opening minutes of the Battle of Hoth.'),
    ('down', 'battlehoth_01_f05_000000000000', 'battlehoth_01_0000000000000000', 'Down for the Count',
     'A tow-cable run brings an AT-AT crashing onto the ice while the shield generator burns behind it.'),
    ('walkers_lg', 'hothatatlg_01_f00_000000000000', 'hothatatlg_01_0000000000000000', 'March of the Walkers (Large)',
     'Imperial AT-ATs cross the northern ice fields toward Echo Base. A large canvas.'),
    ('walkers_sm', 'hothatatsm_01_f00_000000000000', 'hothatatsm_01_0000000000000000', 'March of the Walkers (Small)',
     'Imperial AT-ATs cross the northern ice fields toward Echo Base. A small canvas.'),
    ('shield_lg', 'hothshieldlg_01_f00_0000000000', 'hothshieldlg_01_00000000000000', 'The Shield Generator Falls (Large)',
     "The moment Echo Base's shield generator was destroyed, as remembered by the survivors. A large canvas."),
    ('shield_sm', 'hothshieldsm_01_f00_0000000000', 'hothshieldsm_01_00000000000000', 'The Shield Generator Falls (Small)',
     "The moment Echo Base's shield generator was destroyed, as remembered by the survivors. A small canvas."),
] + [(f'esb{a}_{b}', f'art_esb{a}_{b}_f02_000000000000000', f'art_esb{a}_{b}_0000000000000000000',
      f'The Empire Strikes Back: Print {n}', 'A limited holoreel print from the Battle of Hoth series. Hangs on any wall.')
     for n, (a, b) in zip(['I', 'II', 'III', 'IV', 'V', 'VI'], [(1, 1), (1, 2), (1, 3), (2, 1), (2, 2), (2, 3)])]


def paintings():
    for key, stem, _, _, _ in PAINTINGS:
        target = f'object/tangible/painting/shared_{stem}.iff'
        clone('object/draft_schematic/furniture/bestine/shared_painting_bestine_lucky_despot.iff',
              f'object/draft_schematic/furniture/hoth/shared_painting_hoth_{key}.iff', craftedSharedTemplate=target)
        clone('object/tangible/loot/bestine/shared_bestine_painting_schematic_lucky_despot.iff',
              f'object/tangible/loot/hoth/shared_painting_schematic_hoth_{key}.iff')


# ---------------------------------------------------------------- decor that has appearances but no object template
DECO_BASE = 'object/tangible/furniture/all/shared_frn_all_decorative_sm_s1.iff'
RUG_BASE = 'object/tangible/furniture/all/shared_frn_all_rug_rectangle_large_style_01.iff'
PAINT_BASE = 'object/tangible/painting/shared_painting_bestine_lucky_despot.iff'
DECOR = [  # key, base, appearance, name, description
    ('snowglobe', DECO_BASE, 'appearance/frn_all_snowglobe.apt', 'Hoth Snow Globe',
     'A glass globe with a miniature Echo Base inside. Shake for a blizzard.'),
    ('snowglobe_gcw', DECO_BASE, 'appearance/frn_all_snowglobe_gcw.apt', 'Battle of Hoth Snow Globe',
     'A snow globe commemorating the Battle of Hoth, walkers and all.'),
    ('wampa_rug', RUG_BASE, 'appearance/frn_all_tcg_wampa_rug.apt', 'Wampa Pelt Rug',
     'The pelt of a Hoth wampa, tanned and spread flat. Still smells faintly of ice cave.'),
    ('snowspeeder_holo', DECO_BASE, 'appearance/frn_hologram_snowspeeder.apt', 'T-47 Snowspeeder Hologram',
     'A rotating hologram of a modified Incom T-47 airspeeder.'),
    ('painting_esb_imperial', PAINT_BASE, 'appearance/frn_all_painting_esb_30_final_imperial.apt', 'Victory on Hoth (Imperial Edition)',
     'A commemorative painting of the Imperial assault on Echo Base.'),
    ('painting_esb_neutral', PAINT_BASE, 'appearance/frn_all_painting_esb_30_final_neutral.apt', 'The Battle of Hoth',
     'A commemorative painting of the Battle of Hoth.'),
    ('painting_esb_rebel', PAINT_BASE, 'appearance/frn_all_painting_esb_30_final_rebel.apt', 'Evacuation of Echo Base (Rebel Edition)',
     'A commemorative painting of the Rebel evacuation of Echo Base.'),
    ('painting_reward', PAINT_BASE, 'appearance/frn_all_painting_hoth_reward.apt', 'Hoth Veteran Portrait',
     'Presented to those who fought on the ice.'),
] + [(f'stalagmite_{i:02d}', DECO_BASE, f'appearance/thm_all_cave_stalagmite_ice_{s}.apt', f'Ice Stalagmite (Style {i})',
      'A column of blue cave ice, cut from the wampa caves of Hoth.')
     for i, s in enumerate(['a1', 'a2', 'a3', 'b1', 'b2', 'b3', 'c1', 'c2', 'c3'], 1)] + \
    [(f'stalactite_{i:02d}', DECO_BASE, f'appearance/thm_all_cave_stalagtite_ice_{s}.apt', f'Ice Stalactite (Style {i})',
      'A hanging spike of blue cave ice from the wampa caves of Hoth.')
     for i, s in enumerate(['a2', 'a3', 'b2', 'b3', 'c2', 'c3'], 1)]


def decor():
    for key, base, app, _, _ in DECOR:
        clone(base, f'object/tangible/furniture/hoth/shared_frn_hoth_{key}.iff', appearanceFilename=app,
              objectName=f'frn_n:frn_hoth_{key}', detailedDescription=f'frn_d:frn_hoth_{key}', lookAtText=f'frn_n:frn_hoth_{key}')


# ---------------------------------------------------------------- strings
ART_N = {k: n for _, _, k, n, _ in PAINTINGS}
ART_D = {k: d for _, _, k, _, d in PAINTINGS}
ART_N.update({
    'wall13': 'Ice Cave Wall Segment', 'loot_schem_snowspeeder': 'T-47 Snowspeeder Schematic',
    'loot_atat_toy': 'Imperial Walker Toy', 'loot_atat_toy_01': 'Tripping Hazard', 'loot_atat_toy_03': 'All-Terrain Nap Machine',
    'loot_atat_toy_05': "Emperor's Paperweight", 'loot_atat_toy_06': 'Four-Legged Blunder', 'loot_atat_toy_07': 'Imperial Overkill',
    'loot_atat_toy_08': 'Parking Nightmare', 'loot_atat_toy_09': 'Terrible at Stairs', 'loot_atat_toy_10': 'Snow Day Delay',
})
ART_D.update({
    'wall13': 'A slab of blue cave ice shaped into a wall segment. Place several to build an ice room.',
    'loot_schem_snowspeeder': 'Engineering plans for a modified Incom T-47 airspeeder, as flown by Rogue Squadron on Hoth. '
                              'An Artisan with Engineering IV can learn it.',
    'loot_atat_toy': 'A toy All Terrain Armored Transport. Massive, intimidating, and liable to trip over its own feet. '
                     'Looted from the wreck sites on Hoth.',
})
DT_N = {'frn_all_atat_chair': 'AT-AT Command Chair', 'frn_atat_statuette': 'AT-AT Statuette', 'frn_vet_at_at_toy': 'Miniature AT-AT Replica',
        'item_ice_sculpture_tauntaun': 'Tauntaun Ice Sculpture', 'item_ice_sculpture_wampa': 'Wampa Ice Sculpture', 'item_wampa_arm': 'Severed Wampa Arm'}
DT_D = {'frn_all_atat_chair': 'A chair built from an AT-AT pilot seat salvaged on Hoth.',
        'frn_atat_statuette': 'A desk-sized statuette of an Imperial walker.',
        'frn_vet_at_at_toy': 'A finely detailed miniature of an All Terrain Armored Transport.',
        'item_ice_sculpture_tauntaun': 'A tauntaun carved from Hoth ice. It never melts, somehow.',
        'item_ice_sculpture_wampa': 'A rearing wampa carved from Hoth ice.',
        'item_wampa_arm': 'A wampa arm, severed cleanly. Someone had a lightsaber.'}


def new_stf(like):
    t = stf_tool.read(like)
    t['vals'] = {}
    t['keys'] = []
    t['next'] = 1
    return t


def strings():
    like = os.path.join(HERE, 'build', 'hoth', 'string', 'en', 'hoth_region_names.stf')
    ART_N.update(gen_hoth_art.names()); ART_D.update(gen_hoth_art.descs())
    for name, table in [('art_n', ART_N), ('art_d', ART_D), ('dt_n', DT_N), ('dt_d', DT_D)]:
        t = new_stf(like)
        for k, v in table.items():
            stf_tool.add(t, k, v)
        stf_tool.write(t, out(f'string/en/{name}.stf'))
    for name, col in [('frn_n', 3), ('frn_d', 4)]:
        t = stf_tool.read(bg_file(f'string/en/{name}.stf'))
        have = stf_tool.as_dict(t)
        for row in DECOR:
            k = f'frn_hoth_{row[0]}'
            if k not in have:
                stf_tool.add(t, k, row[col])
        stf_tool.write(t, out(f'string/en/{name}.stf'))


def crc():
    """The CRC table is generated per base TRE by build_tre.py (base table + every object iff in the overlays),
    so the overlays must not carry one. Remove stale copies."""
    for d in ('hoth', 'hoth_loot'):
        p = os.path.join(HERE, 'build', d, 'misc', 'object_template_crc_string_table.iff')
        if os.path.exists(p):
            os.remove(p); print('removed stale', p)
    print(f'{len(set(NEW_OBJECTS) | set(ported_objects()))} object paths will get CRC entries at build time (build_tre.py)')


if __name__ == '__main__':
    armor()
    paintings()
    decor()
    gen_hoth_art.client()
    strings()
    crc()
    print(f'{len(NEW_OBJECTS)} cloned object templates; {len(list(ported_objects()))} object templates total in overlay')
