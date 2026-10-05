#!/usr/bin/env python3
"""gen_hoth_vehicles.py — port Infinity's rideable vehicles into BG as Hoth boss loot. Idempotent.

Client side (client(), called from gen_hoth_loot_client.py): for every entry in VEHICLES
  * stage the control device, vehicle and deed templates plus their full asset closure (meshes, skeletons, LATs and
    the animations they name, shaders, textures, client data, particle effects, sounds and samples)
  * clone a deed template when Infinity has none, and a vehicle template for the XP-38
  * copy the vehicle's rows into the four datatables/mount tables; collect its rider pose (poses() -> lat_add_pose)
  * clone the snowspeeder loot-schematic and draft-schematic client templates per vehicle
  * export names()/descs() for art_n/art_d and the monster_name/monster_detail keys that BG lacks
Server side (server(), called from gen_hoth_loot.py): pcd, vehicle, deed, draft schematic, loot schematic, loot items
(deed as a direct drop and the schematic) and the two loot groups hoth_vehicle_deeds / hoth_vehicle_schematics.
"""
import os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import iff_clone, dt_tool, stf_tool

P = 'object/intangible/vehicle/', 'object/mobile/vehicle/', 'object/tangible/deed/vehicle_deed/'
# key, display name, pcd client iff, vehicle client iff (or ('clone', donor, appearance)), deed client iff (or None),
# saddle lookup keys, appearance (for the mount tables)
VEHICLES = [
    ('snowspeeder', 'T-47 Snowspeeder', 'shared_snowspeeder.iff', 'shared_snowspeeder.iff', 'shared_snowspeeder_deed.iff',
     ['lookup/snowspeeder'], 'appearance/pv_snowspeeder.sat'),
    ('landspeeder_ab1', 'AB-1 Landspeeder', 'shared_landspeeder_ab1_pcd.iff', 'shared_landspeeder_ab1.iff', 'shared_landspeeder_ab1_deed.iff',
     ['lookup/speeder_ab1'], 'appearance/speeder_ab1.apt'),
    ('landspeeder_xp38', 'XP-38 Landspeeder', 'shared_landspeeder_xp38_pcd.iff',
     ('clone', 'shared_landspeeder_ab1.iff', 'appearance/speeder_xp_38.apt'), 'shared_landspeeder_xp38_deed.iff',
     ['lookup/speeder_xp_38'], 'appearance/speeder_xp_38.apt'),
    ('landspeeder_organa', 'Organa Speeder', 'shared_landspeeder_organa_pcd.iff', 'shared_landspeeder_organa.iff', 'shared_vehicle_deed_organa_speeder.iff',
     ['lookup/bail_organa_speeder'], 'appearance/bail_organa_speeder.apt'),
    ('sith_speeder', 'Sith Speeder', 'shared_sith_speeder_pcd.iff', 'shared_sith_speeder.iff', 'shared_vehicle_deed_sith_speeder.iff',
     ['lookup/sith_speeder'], 'appearance/sith_speeder.apt'),
    ('basilisk_war_droid', 'Basilisk War Droid', 'shared_basilisk_war_droid.iff', 'shared_basilisk_war_droid.iff', 'shared_basilisk_war_droid.iff',
     ['lookup/basilisk_war_droid'], 'appearance/basilisk_war_droid.sat'),
    ('stap_speeder', 'STAP', 'shared_stap_speeder_pcd.iff', 'shared_stap_speeder.iff', 'shared_speeder_stap_deed.iff',
     ['lookup/stap_speeder'], 'appearance/stap_speeder.apt'),
    ('swamp_speeder', 'Swamp Speeder', 'shared_swamp_speeder_pcd.iff', 'shared_swamp_speeder.iff', 'shared_swamp_speeder_deed.iff',
     ['lookup/swamp_speeder'], 'appearance/swamp_speeder.apt'),
    ('tcg_republic_gunship', 'Republic Gunship', 'shared_tcg_republic_gunship_pcd.iff', 'shared_tcg_republic_gunship.iff', None,
     ['lookup/tcg_republic_gunship'], 'appearance/republic_gunship.apt'),
    ('tcg_military_transport', 'Enclosed Military Transport', 'shared_tcg_military_transport_pcd.iff', 'shared_tcg_military_transport.iff', 'shared_military_transport_deed.iff',
     ['lookup/tcg_military_transport'], 'appearance/enclosed_military_vehicle.apt'),
    ('tcg_hk47_jetpack', 'HK-47 Jetpack', 'shared_tcg_hk47_jetpack_pcd.iff', 'shared_tcg_hk47_jetpack.iff', None,
     ['lookup/hk47_jetpack'], 'appearance/jetpack_hk47_tcg.apt'),
    ('tcg_8_single_pod_airspeeder', 'Single-Pod Airspeeder', 'shared_tcg_8_single_pod_airspeeder.iff', 'shared_tcg_8_single_pod_airspeeder.iff', 'shared_tcg_8_air_speeder_deed.iff',
     ['lookup/tcg_8_single_pod_airspeeder'], 'appearance/single_pod_airspeeder.sat'),
    ('senate_pod', 'Senate Pod', 'shared_senate_pod_pcd.iff', 'shared_senate_pod.iff', None,
     ['lookup/senate_pod'], 'appearance/senate_pod.apt'),
    ('speeder_ric_920', 'RIC-920 Speeder', 'shared_speeder_ric_920_pcd.iff', 'shared_speeder_ric_920.iff', 'shared_speeder_ric_920_deed.iff',
     ['lookup/speeder_ric_920'], 'appearance/ric_920_speeder.sat'),
    ('pod_racer_ipg_longtail', 'IPG Longtail Podracer', 'shared_pod_racer_ipg_longtail_pcd.iff', 'shared_pod_racer_ipg_longtail.iff', None,
     ['lookup/ipg_podracer'], 'appearance/ipg_podracer.sat'),
    ('pod_racer_balta_podracer', 'Balta Podracer', 'shared_pod_racer_balta_podracer_pcd.iff', 'shared_pod_racer_balta_podracer.iff', None,
     ['lookup/balta_podracer'], 'appearance/balta_podracer.sat'),
    ('podracer_anakin', "Anakin's Podracer", 'shared_podracer_anakin_pcd.iff', 'shared_podracer_anakin.iff', 'shared_podracer_anakin_deed.iff',
     ['lookup/podracer_anakin'], 'appearance/anakin_podracer.sat'),
    ('mechno_chair', 'Mechno-Chair', 'shared_mechno_chair_pcd.iff', 'shared_mechno_chair.iff', 'shared_vehicle_deed_mechno_chair.iff',
     ['lookup/mechno_chair'], 'appearance/mechno_chair.apt'),
    ('koro2_speeder', 'Koro-2 Exodrive Airspeeder', 'shared_koro2_speeder_pcd.iff', 'shared_koro2_speeder.iff', 'shared_koro2_speeder_deed.iff',
     ['lookup/koro2_speeder'], 'appearance/zam_speeder.apt'),
    ('hover_chair', 'Hover Chair', 'shared_hover_chair_pcd.iff', 'shared_hover_chair.iff', 'shared_hover_chair_deed.iff',
     ['lookup/hover_chair'], 'appearance/yodas_levitator.apt'),
    ('geonosian_speeder', 'Geonosian Speeder', 'shared_geonosian_speeder_pcd.iff', 'shared_geonosian_speeder.iff', 'shared_geo_speeder.iff',
     ['lookup/geonosian_speeder'], 'appearance/geonosian_speeder.apt'),
    ('a1_deluxe_floater', 'A-1 Deluxe Floater', 'shared_a1_deluxe_floater_pcd.iff', 'shared_a1_deluxe_floater.iff', 'shared_a1_deluxe_floater_deed.iff',
     ['lookup/a1_deluxe_floater'], 'appearance/a1_deluxe_floater.apt'),
    ('fg_8t8_podracer', 'FG 8T8 Podracer', 'shared_fg_8t8_podracer_pcd.iff', 'shared_fg_8t8_podracer.iff', None,
     ['lookup/fg_8t8_podracer'], 'appearance/fg_8t8_podracer.apt'),
    ('air2_swoop_speeder', 'Air-2 Swoop', 'shared_air2_swoop_speeder_pcd.iff', 'shared_air2_swoop_speeder.iff', None,
     ['lookup/air2_swoop_speeder'], 'appearance/air2_swoop_speeder.apt'),
    ('xj6_air_speeder', 'XJ-6 Airspeeder', 'shared_xj6_air_speeder_pcd.iff', 'shared_xj6_air_speeder.iff', 'shared_xj6_air_speeder_deed.iff',
     ['lookup/xj6_air_speeder'], 'appearance/xj6_air_speeder.apt'),
    ('mustafar_panning_droid', 'Mustafar Panning Droid', 'shared_mustafar_panning_droid.iff', 'shared_mustafar_panning_droid.iff', 'shared_mustafar_panning_droid.iff',
     ['lookup/panning_droid'], 'appearance/pv_ma3_mark_2_vehicle.sat'),
    ('hoverlifter_speeder', 'Hoverlifter', 'shared_hoverlifter_speeder_pcd.iff', 'shared_hoverlifter_speeder.iff', 'shared_hoverlifter_speeder.iff',
     ['lookup/hoverlifter_speeder', 'lookup/hoverlifter_speeder_crafted'], 'appearance/hoverlifter_speeder.apt'),
    ('flare_s_swoop', 'Flare-S Swoop', 'shared_flare_s_swoop_pcd.iff', 'shared_flare_s_swoop.iff', 'shared_flare_s_swoop.iff',
     ['lookup/flare_s_swoop', 'lookup/flare_s_swoop_crafted'], 'appearance/flare_s_swoop.apt'),
    ('grievous_wheel_bike', "Grievous' Wheel Bike", 'shared_grievous_wheel_bike_pcd.iff', 'shared_grievous_wheel_bike.iff', 'shared_grievous_wheel_bike_deed.iff',
     ['lookup/grievous_wheel_bike'], 'appearance/grievous_wheel_bike.sat'),
    ('hover_bird', 'Hover Bird', 'shared_hover_bird_pcd.iff', 'shared_hover_bird.iff', 'shared_hover_bird_deed.iff',
     ['lookup/hover_bird'], 'appearance/pv_hover_bird.sat'),
]
MOUNT_TABLES = ['logical_saddle_name_map', 'rider_pose_map', 'saddle_appearance_map', 'valid_scale_range']
EXT = r'(?:iff|apt|sat|lmg|mgn|msh|lod|skt|lat|ans|sht|dds|cdf|prt|eft|snd|wav|cmp|flr|pob|cef)'
PATH_RE = re.compile(rb'(?:appearance|shader|texture|clientdata|sound|sample|effect|clienteffect|object|datatables)/[a-z0-9_/\-\.]+\.' + EXT.encode(), re.I)

_c = None


def _client_mod():
    global _c
    if _c is None:
        import gen_hoth_loot_client as c
        _c = c
    return _c


def pcd_client(v): return P[0] + v[2]
def mob_client(v):
    """Client vehicle template path; a cloned vehicle (tuple spec) is written as shared_<key>.iff."""
    return P[1] + (f'shared_{v[0]}.iff' if isinstance(v[3], tuple) else v[3])
def deed_client(v): return P[2] + (v[4] if v[4] else f'shared_{v[0]}_deed.iff')
def server_path(client): d, f = client.rsplit('/', 1); return f'{d}/{f[7:]}'
def luaid(client): return client[:-4].replace('/', '_')
def draft_client(v): return f'object/draft_schematic/vehicle/civilian/shared_{v[0]}.iff'
def schem_client(v): return f'object/tangible/loot/loot_schematic/shared_loot_schem_{v[0]}.iff'


def names():
    return {f'loot_schem_{v[0]}': f'{v[1]} Schematic' for v in VEHICLES}


def descs():
    return {f'loot_schem_{v[0]}': f'Engineering plans for a {v[1]}. An Artisan with Engineering IV can learn it. Recovered from the ice caves of Hoth.'
            for v in VEHICLES}


def object_name(local_iff):
    s = [m.decode('latin-1') for m in re.findall(rb'[\x20-\x7e]{3,}', open(local_iff, 'rb').read())]
    for i, x in enumerate(s):
        if x.endswith('objectName') and i + 2 < len(s) and not s[i + 1].endswith('detailedDescription'):
            return f'{s[i+1]}:{s[i+2]}'
    return None


# ---------------------------------------------------------------- client
def copy_key(c, stf, key, tmp, tables):
    """Copy string key from Infinity's <stf>.stf into (an overlay copy of) BG's if BG lacks it. Missing tables are skipped."""
    if stf not in tables:
        try:
            bg_t = stf_tool.read(c.bg_file(f'string/en/{stf}.stf'))
            inf_d = stf_tool.as_dict(stf_tool.read(c.inf_file(f'string/en/{stf}.stf', tmp)))
        except KeyError:
            return
        tables[stf] = (bg_t, stf_tool.as_dict(bg_t), inf_d)
    bg_t, bg_d, inf_d = tables[stf]
    if key not in bg_d and key in inf_d:
        stf_tool.add(bg_t, key, inf_d[key]); bg_d[key] = inf_d[key]


def stage_recursive(c, rels, inf_paths, bg_paths):
    """Stage rels from Infinity (if BG lacks them) and everything they reference, to a fixpoint. Returns staged list."""
    staged, queue, seen = [], list(rels), set()
    while queue:
        rel = queue.pop().lower()
        if rel in seen:
            continue
        seen.add(rel)
        if rel.startswith('object/') and rel.endswith('.iff') and rel in bg_paths and not rel.startswith(P):
            continue  # keep BG's shared base object templates
        local = c.out(rel)
        if not os.path.exists(local):
            if rel in bg_paths or rel not in inf_paths:
                continue  # already in BG, or nowhere
            c.inf_file(rel, c.OUT); staged.append(rel)
        if rel.endswith(('.dds', '.wav')):
            continue
        data = open(local, 'rb').read()
        for m in PATH_RE.findall(data):
            queue.append(m.decode('latin-1'))
        if rel.endswith('.snd'):
            for w in re.findall(rb'[a-z0-9_\-\.]+\.wav', data, re.I):
                queue.append('sample/' + w.decode('latin-1'))
        if rel.endswith('.lmg') or rel.endswith('.lod'):
            for m in re.findall(rb'(?<![a-z0-9_/])(?:mesh|lod|skeleton|collision|component)/[a-z0-9_/\-\.]+\.(?:msh|mgn|lmg|lod|skt|cmp|apt)', data, re.I):
                queue.append('appearance/' + m.decode('latin-1'))
    return staged


def client():
    c = _client_mod()
    inf_paths = {l.split('\t')[1].lower() for l in open(os.path.join(HERE, 'infinity_all.txt'), encoding='utf-8', errors='replace') if '\t' in l}
    bg_paths = {l.split('\t')[1].lower() for l in open(os.path.join(HERE, 'bg_all.txt'), encoding='utf-8', errors='replace') if '\t' in l}
    tmp = os.path.join(HERE, 'extract', 'inf')
    roots, poses_needed = [], set()
    mount = {name: dt_tool.read(c.inf_file(f'datatables/mount/{name}.iff', tmp)) for name in MOUNT_TABLES}
    bgmount = {name: dt_tool.read(c.bg_file(f'datatables/mount/{name}.iff')) for name in MOUNT_TABLES}
    tables = {}  # stf name -> (bg table, bg dict, infinity dict); written out at the end
    snow_deed = c.inf_file(P[2] + 'shared_snowspeeder_deed.iff', tmp)
    snow_draft = c.inf_file('object/draft_schematic/vehicle/civilian/shared_snowspeeder.iff', tmp)
    snow_schem = c.inf_file('object/tangible/loot/loot_schematic/shared_loot_schem_snowspeeder.iff', tmp)
    for v in VEHICLES:
        key, name, pcd, mob, deed, saddles, app = v
        roots.append(pcd_client(v))
        if isinstance(mob, tuple):
            donor = c.inf_file(P[1] + mob[1], tmp)
            pcd_local = c.inf_file(pcd_client(v), tmp)
            oname = object_name(pcd_local) or f'monster_name:{key}'
            iff_clone.clone(donor, c.out(mob_client(v)), {'appearanceFilename': mob[2], 'objectName': oname,
                                                           'detailedDescription': oname.replace('monster_name', 'monster_detail'), 'lookAtText': oname})
            roots.append(mob[2])
        else:
            roots.append(mob_client(v))
        mob_local = c.out(mob_client(v)) if isinstance(mob, tuple) else c.inf_file(mob_client(v), tmp)
        oname = object_name(mob_local) or f'monster_name:{key}'
        if deed:
            roots.append(deed_client(v))
        else:
            iff_clone.clone(snow_deed, c.out(deed_client(v)), {'objectName': oname, 'detailedDescription': oname.replace('monster_name', 'monster_detail'), 'lookAtText': oname})
        # names: copy any string keys the vehicle or its deed uses that BG's tables lack
        deed_local = c.inf_file(deed_client(v), tmp) if deed else c.out(deed_client(v))
        for ref in (oname, object_name(deed_local) or ''):
            if ':' not in ref:
                continue
            stf, k = ref.split(':', 1)
            wanted = [(stf, k)]
            if '_name' in stf:
                wanted.append((stf.replace('_name', '_detail'), k))
            elif stf.endswith('_n'):
                wanted.append((stf[:-2] + '_d', k[:-2] + '_d' if k.endswith('_n') else k))
            elif stf == 'pet_deed':
                wanted.append(('pet_deed', k))
            for s, kk in wanted:
                copy_key(c, s, kk, tmp, tables)
            # a deed whose name key exists in neither client (e.g. Infinity's Organa deed) is renamed after its vehicle
            if ref != oname and deed and stf in tables and k not in tables[stf][1]:
                iff_clone.clone(deed_local, c.out(deed_client(v)), {'objectName': oname, 'detailedDescription': oname.replace('monster_name', 'monster_detail'), 'lookAtText': oname})
                print(f'  {key}: deed renamed to {oname} (no string for {ref})')
        # mount rows
        for tname, t in mount.items():
            bg = bgmount[tname]; have = {tuple(r) for r in bg['rows']}
            for row in t['rows']:
                if row[0] == app or row[0] in saddles:
                    if tname == 'rider_pose_map':
                        poses_needed.add(row[2])
                        bg['rows'] = [r for r in bg['rows'] if r[0] != row[0]]
                    if tname == 'saddle_appearance_map' and row[3]:
                        roots.append(row[3])
                    if tuple(row) not in have:
                        bg['rows'].append(list(row)); have.add(tuple(row))
        # schematic templates
        iff_clone.clone(snow_draft, c.out(draft_client(v)), {'craftedSharedTemplate': deed_client(v)})
        if not os.path.exists(c.out(schem_client(v))):
            import shutil; shutil.copyfile(snow_schem, c.out(schem_client(v)))
    for tname, t in bgmount.items():
        dt_tool.write(t, c.out(f'datatables/mount/{tname}.iff'))
    for stf, (bg_t, _, _) in tables.items():
        stf_tool.write(bg_t, c.out(f'string/en/{stf}.stf'))
    staged = stage_recursive(c, roots, inf_paths, bg_paths)
    print(f'vehicles: {len(VEHICLES)} vehicles, {len(staged)} files staged this run, poses: {sorted(poses_needed)}')
    return sorted(p for p in poses_needed if p)


# ---------------------------------------------------------------- server
def server(g, write, body, read, ensure_shared, loot_item, GROUPS):
    import re as _re
    deed_src = body(read('object/tangible/deed/vehicle_deed/landspeeder_x34_deed.lua'))
    draft_src = body(read('object/draft_schematic/vehicle/civilian/landspeeder_x34.lua'))
    for v in VEHICLES:
        key, name = v[0], v[1]
        pcd_s, mob_s, deed_s = server_path(pcd_client(v)), server_path(mob_client(v)), server_path(deed_client(v))
        draft_s, schem_s = server_path(draft_client(v)), server_path(schem_client(v))
        write(pcd_s[:-4] + '.lua', f'{luaid(pcd_s)} = {luaid(pcd_client(v))}:new {{\n}}\n\nObjectTemplates:addTemplate({luaid(pcd_s)}, "{pcd_s}")\n')
        g.register('object/intangible/vehicle/serverobjects.lua', f'includeFile("{pcd_s[7:-4]}.lua")')
        write(mob_s[:-4] + '.lua', f'{luaid(mob_s)} = {luaid(mob_client(v))}:new {{\n\ttemplateType = VEHICLE,\n'
              f'\tdecayRate = 15, -- Damage tick per decay cycle\n\tdecayCycle = 600 -- Time in seconds per cycle\n}}\n\n'
              f'ObjectTemplates:addTemplate({luaid(mob_s)}, "{mob_s}")\n')
        g.register('object/mobile/vehicle/serverobjects.lua', f'includeFile("{mob_s[7:-4]}.lua")')
        t = deed_src.replace('object_tangible_deed_vehicle_deed_landspeeder_x34_deed', luaid(deed_s)) \
            .replace('object_tangible_deed_vehicle_deed_shared_landspeeder_x34_deed', luaid(deed_client(v))) \
            .replace('object/intangible/vehicle/landspeeder_x34_pcd.iff', pcd_s).replace('object/mobile/vehicle/landspeeder_x34.iff', mob_s) \
            .replace('object/tangible/deed/vehicle_deed/landspeeder_x34_deed.iff', deed_s)
        assert 'x34' not in t, key
        write(deed_s[:-4] + '.lua', t)
        g.register('object/tangible/deed/vehicle_deed/serverobjects.lua', f'includeFile("{deed_s[7:-4]}.lua")')
        t = draft_src.replace('object_draft_schematic_vehicle_civilian_landspeeder_x34', luaid(draft_s)) \
            .replace('object_draft_schematic_vehicle_civilian_shared_landspeeder_x34', luaid(draft_client(v))) \
            .replace('object/tangible/deed/vehicle_deed/landspeeder_x34_deed.iff', deed_s) \
            .replace('object/draft_schematic/vehicle/civilian/landspeeder_x34.iff', draft_s) \
            .replace('resourceQuantities = {1125, 3125}', 'resourceQuantities = {1500, 3500}')
        t = _re.sub(r'customObjectName = "[^"]*"', f'customObjectName = "{name}"', t)
        assert 'x34' not in t, key
        write(draft_s[:-4] + '.lua', t)
        g.register('object/draft_schematic/vehicle/civilian/serverobjects.lua', f'includeFile("{draft_s[7:-4]}.lua")')
        write(schem_s[:-4] + '.lua', f'{luaid(schem_s)} = {luaid(schem_client(v))}:new {{\n\ttemplateType = LOOTSCHEMATIC,\n'
              f'\tcustomName = "{name} Schematic",\n\tobjectMenuComponent = "LootSchematicMenuComponent",\n'
              f'\tattributeListComponent = "LootSchematicAttributeListComponent",\n\trequiredSkill = "crafting_artisan_engineering_04",\n'
              f'\ttargetDraftSchematic = "{draft_s}",\n\ttargetUseCount = 1,\n}}\n\nObjectTemplates:addTemplate({luaid(schem_s)}, "{schem_s}")\n')
        g.register('object/tangible/loot/loot_schematic/serverobjects.lua', f'includeFile("{schem_s[7:-4]}.lua")')
        loot_item(f'{key}_schematic', schem_s)
        loot_item(f'hoth_vehicle_{key}_deed', deed_s, f'{name} Deed')
    ensure_shared('object/intangible/vehicle/objects.lua', [pcd_client(v) for v in VEHICLES])
    ensure_shared('object/mobile/vehicle/objects.lua', [mob_client(v) for v in VEHICLES])
    ensure_shared('object/tangible/deed/vehicle_deed/objects.lua', [deed_client(v) for v in VEHICLES])
    ensure_shared('object/draft_schematic/vehicle/civilian/objects.lua', [draft_client(v) for v in VEHICLES])
    ensure_shared('object/tangible/loot/loot_schematic/objects.lua', [schem_client(v) for v in VEHICLES])
    GROUPS['hoth_vehicle_schematics'] = [f'{v[0]}_schematic' for v in VEHICLES]
    GROUPS['hoth_vehicle_deeds'] = [f'hoth_vehicle_{v[0]}_deed' for v in VEHICLES]
