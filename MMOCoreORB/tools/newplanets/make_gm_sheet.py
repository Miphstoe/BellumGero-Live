#!/usr/bin/env python3
"""make_gm_sheet.py — write HOTH_LOOT_GM_TEST.md: /object createitem commands for every new Hoth loot item plus the
crafting resource table. Reads the item lists from the generators so it stays in sync."""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import gen_hoth_loot_client as c
import gen_hoth_art as art

P = c.PIECES
sections = []
sections.append(('Snowtrooper armor (finished pieces)',
                 [f'object/tangible/wearables/armor/snowtrooper/armor_snowtrooper_{p}.iff' for p in P] +
                 ['object/tangible/wearables/backpack/backpack_snowtrooper.iff']))
sections.append(('Alliance Cold Weather armor (finished pieces)',
                 [f'object/tangible/wearables/armor/rebel_snow/armor_rebel_snow_{p}.iff' for p in P] +
                 ['object/tangible/wearables/backpack/backpack_rebel_snow_soldier.iff']))
sections.append(('Snowtrooper loot schematics (Master Armorsmith, 3 uses)',
                 [f'object/tangible/loot/loot_schematic/snowtrooper_{p}_crafted_schematic.iff' for p in P + ['backpack']]))
sections.append(('Alliance Cold Weather loot schematics (Master Armorsmith, 3 uses)',
                 [f'object/tangible/loot/loot_schematic/rebel_snow_{p}_crafted_schematic.iff' for p in P + ['backpack']]))
sections.append(('Hoth paintings (finished)',
                 [f'object/tangible/painting/{stem}.iff   -- {name}' for _, stem, _, name, _ in c.PAINTINGS]))
sections.append(('Hoth painting schematics (Architect Production III, 2 uses)',
                 [f'object/tangible/loot/hoth/painting_schematic_hoth_{k}.iff   -- {name}' for k, _, _, name, _ in c.PAINTINGS]))
sections.append(('Boss paintings (hoth_art_rare, finished only)',
                 [f'object/tangible/painting/hoth_art_{k}.iff   -- {n}' for k, _, n, _, _ in art.ART]))
sections.append(('Common decor', [
    'object/tangible/veteran_reward/frn_plush_tauntaun.iff', 'object/tangible/tcg/series4/decorative_stuffed_tauntaun.iff',
    'object/tangible/tcg/series4/decorative_stuffed_wampa.iff', 'object/tangible/tcg/series3/decorative_hoth_travel_advertisement.iff',
    'object/tangible/loot/themepark/frn_atat_statuette.iff', 'object/tangible/loot/themepark/frn_vet_at_at_toy.iff',
    'object/tangible/furniture/hoth/frn_hoth_snowglobe.iff', 'object/tangible/furniture/hoth/frn_hoth_snowglobe_gcw.iff'] +
    [f'object/tangible/loot/toy/hoth_atat_toy_{i:02d}.iff' for i in range(1, 11)]))
sections.append(('Rare decor', [
    'object/tangible/collection/reward/col_reward_hoth_tauntaun_head.iff', 'object/tangible/tcg/series8/diorama_atat_attack.iff',
    'object/tangible/tcg/series8/tauntaun_armored_statue.iff', 'object/tangible/loot/themepark/item_ice_sculpture_wampa.iff',
    'object/tangible/loot/themepark/item_ice_sculpture_tauntaun.iff', 'object/tangible/loot/themepark/item_wampa_arm.iff',
    'object/tangible/loot/themepark/frn_all_atat_chair.iff', 'object/tangible/furniture/hoth/frn_hoth_wampa_rug.iff',
    'object/tangible/furniture/hoth/frn_hoth_snowspeeder_holo.iff', 'object/tangible/furniture/hoth/frn_hoth_painting_esb_imperial.iff',
    'object/tangible/furniture/hoth/frn_hoth_painting_esb_neutral.iff', 'object/tangible/furniture/hoth/frn_hoth_painting_esb_rebel.iff',
    'object/tangible/furniture/hoth/frn_hoth_painting_reward.iff']))
sections.append(('Ice-cave decor', ['object/tangible/borrie/wall/cave_ice_wall.iff'] +
                 [f'object/tangible/furniture/hoth/frn_hoth_stalagmite_{i:02d}.iff' for i in range(1, 10)] +
                 [f'object/tangible/furniture/hoth/frn_hoth_stalactite_{i:02d}.iff' for i in range(1, 7)]))
import gen_hoth_vehicles as V
sections.append(('Vehicle deeds (use the deed, then call the vehicle from the datapad)',
                 [f'{V.server_path(V.deed_client(v))}   -- {v[1]}' for v in V.VEHICLES]))
sections.append(('Vehicle loot schematics (Artisan Engineering IV, 1 use)',
                 [f'{V.server_path(V.schem_client(v))}   -- {v[1]}' for v in V.VEHICLES]))
sections.append(('Crafting components for one full armor set', [
    'object/tangible/component/armor/armor_segment_composite.iff 20',
    'object/tangible/component/clothing/synthetic_cloth.iff 10',
    'object/tangible/component/clothing/reinforced_fiber_panels.iff 11',
    'object/tangible/component/clothing/fiberplast_panel.iff 1']))

out = ['# Hoth loot: GM test sheet', '',
       'Branch `Ender_Hoth_Loot_and_more`; client/server TRE `dist/devbg/bg_custom1.tre` (md5 7c02cdfe...).',
       'Spawn with `/object createitem <template> [quantity]`. Items land in your inventory; paintings and decor go in a house '
       '(drop, then radial to move/rotate).', '']
total = 0
for sec, rows in sections:
    out += [f'## {sec}', '', '```']
    for r in rows:
        total += 1
        out.append(f'/object createitem {r}')
    out += ['```', '']

out += ['## Resources for the schematics', '',
        'Classes are generic: any resource of the class works. Class names as the server knows them: `ore_intrusive` (Intrusive Ore), '
        '`fuel_petrochem_solid_known` (Known Solid Petrochem Fuel), `fiberplast_gravitonic` (Gravitonic Fiberplast), `aluminum`, '
        '`iron_kammris` (Kammris Iron), `hide_wooly` (Wooly Hide), `iron`, `steel`, `metal`, `hide`, `petrochem_inert_polymer` '
        '(Inert Petrochem Polymer), `metal_nonferrous`, `metal_ferrous`.', '',
        '| Schematic | Resources | Components |', '|---|---|---|',
        '| Helmet, Leggings (each) | 70 intrusive ore, 70 known solid petrochem fuel, 35 gravitonic fiberplast, 40 aluminum, 30 kammris iron, 30 wooly hide | 3 composite armor segments, 1 synthetic cloth, 1 reinforced fiber panels |',
        '| Chest plate / Padded vest | 100 intrusive ore, 100 known solid petrochem fuel, 50 gravitonic fiberplast, 60 aluminum, 50 kammris iron, 40 wooly hide | 4 composite armor segments, 1 synthetic cloth, 1 reinforced fiber panels |',
        '| Biceps, Bracers, Boots (each) | 50 intrusive ore, 50 known solid petrochem fuel, 25 gravitonic fiberplast, 30 aluminum, 20 kammris iron, 20 wooly hide | 2 composite armor segments, 1 synthetic cloth, 1 reinforced fiber panels |',
        '| Gloves | 25 intrusive ore, 25 known solid petrochem fuel, 15 gravitonic fiberplast, 10 aluminum, 10 kammris iron, 10 wooly hide | 1 composite armor segment, 2 synthetic cloth, 1 reinforced fiber panels |',
        '| Belt | 5 kammris iron, 5 wooly hide | 1 reinforced fiber panels |',
        '| Backpack | 15 iron, 5 steel | 1 fiberplast panel |',
        '| Painting (each, Architect) | 50 metal, 50 hide, 40 inert petrochem polymer | none |',
        '| T-47 snowspeeder (Artisan) | 1500 non-ferrous metal, 3500 ferrous metal | none |', '',
        'One full set (11 pieces): 540 intrusive ore, 540 known solid petrochem fuel, 270 gravitonic fiberplast, 320 aluminum, '
        '265 kammris iron, 235 wooly hide, 15 iron, 5 steel; 20 composite armor segments, 10 synthetic cloth, 11 reinforced fiber panels, 1 fiberplast panel.', '',
        '### Getting resources as a GM', '', '```',
        '/resource list hoth                     -- what is spawned on Hoth right now (Hothian classes)',
        '/resource create <ResourceName> 5000    -- a crate of any currently spawned resource, by its spawn name',
        '/gmcreatespecificresource <class>       -- spawn a new resource of a class, e.g. iron_kammris or fiberplast_gravitonic',
        '```', '',
        'Workflow: learn a loot schematic by using it with the right profession (Master Armorsmith; Architect Production III; '
        'Artisan Engineering IV), then craft on a Clothing and Armor station (armor), a Structure station (paintings) or a generic '
        'crafting tool (snowspeeder). A test character with master crafting skills from `/grantskill` is quickest.', '']
path = os.path.join(HERE, 'HOTH_LOOT_GM_TEST.md')
open(path, 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
print(path, total, 'spawn commands')
