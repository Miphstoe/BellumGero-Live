# Hoth on Test Center — install notes for Miph

Branch: `Ender_Hoth` on Miphstoe/BellumGero-Live, PR #795 (3 commits ahead of Main: zone, creatures/caves/POIs, Hoth resources).

## Client + server TRE

| File | Size | MD5 |
|---|---|---|
| `bg_custom1_hoth_only.tre` (this folder: `C:\SWG-Dev\NewPlanets\dist\`) — rename to `bg_custom1.tre` when installing | 143,869,650 bytes | `3f788419438111fe37d1f05aa964ae80` |

**Replace the earlier build (md5 `0006e3f6…` / `98f8ef11…`) on TC with this one.** Those builds carried a CRC string table made from an older bg_custom1, so 80 entries of the live September table were missing: the armor suit packages, the droid foundry items and the worldbuilder ships. The server fails to create those objects ("could not create object CRC ...") while that TRE is installed. This build keeps the live table intact and adds the Hoth entries on top (16261 → 16269 entries). Nothing else changed.

(`dist\bg_custom1.tre`, 160,798,012 bytes, md5 `05718c8a5a4372e1e4be3c03a93a1e4b`, is the same plus the `Ender_Hoth_Loot_and_more` content. Only use it with that branch.)

It is the live Sep 12 `bg_custom1.tre` (md5 `e21067c45cc6388c9193fd42c9b8eb34`) with the Hoth files merged in. Nothing from the live copy was removed; `travel.iff` and `misc/object_template_crc_string_table.iff` are replaced with versions that add Hoth rows, and `datatables/resource/resource_tree.iff` is added (stock tree plus the 55 Hoth resource classes; the server reads it from the same TRE).

1. Server: back up `/trefiles/bg_custom1.tre`, then copy this file over it. Same file name, so no `config.lua` TrePath change.
2. TC client: same file replaces `bg_custom1.tre` in the client folder. No `.cfg` change.
3. Check with `md5sum` on both sides before starting.

## Server steps

1. Checkout `Ender_Hoth`, **rebuild core3** (C++ changed: `PlanetManager.idl`, `PlanetManagerImplementation.cpp` — new `allowAllDepartures` planet flag that lets shuttleports sell Hoth tickets).
2. Cold restart. `hoth` is already in `ZonesEnabled` in `bin/conf/config.lua` on the branch.
3. Boot check: wait for "Logging online players"; grep the log for `hoth`. Known unrelated noise on a stale TRE: armor-suit / droid-foundry schematic warnings and `gameObjectType 0`.

## Travel points (all accept incoming travel; 4000cr from every planet)

| Outpost | x, z, y |
|---|---|
| Scavenger Outpost | 20.34, 0, -1982.24 |
| Imperial Outpost | 5947.9, 3, -388.71 |
| Rebel Outpost | 4528.65, 87.8, 1190.75 |

## What to test on TC (none of this has been tested in game yet)

- Buying a Hoth ticket from a starport and from a shuttleport (client may grey Hoth out).
- Arriving and the terrain, sky and weather rendering (snow shaders were the main bug class).
- Planet map, waypoints, region names at the three outposts and the five POIs.
- Creature visibility: the world spawner lairs are gated by level (tauntaun CL 60 up to wampa CL 80), so test with a CL 80–90 character or GM.
- New models render: wampa, snowtrooper, Rebel snow soldier, probe droid.
- Ice caves near (-400, 2500): bosses Frostfang, Icemaw, Snowblind the Ravager, matriarch + patriarch in cave_03 (-75, 2969); mynock broodmother in the NW cavern (-5819, 6093).
- Battlefield around (5420, 780), raider camp (5068, 1300), Lucky Despot wreck scavengers (-100, -2048).
- Static spawns at the outposts sit on rings around each starport and may clip walls; report any that do.
- Resources: survey tools list Hothian resources, and harvesting a wampa/tauntaun gives Hothian Carnivore/Herbivore Meat, Hothian Wooly Hide and Hoth Animal Bones. Resources only spawn there once the server has booted with the new TRE and `hoth` in `activeZones`.

## Not included yet

- Hoth loading screen (still the default).
- Loot/items pass (snowtrooper and Echo Base armor, paintings, decor, snowspeeder) — coming on `Ender_Hoth_Loot_and_more`.

## Credit

Terrain, snapshot and models come from SWG Infinity / MTG / Takhomasak's releases. Get permission or add credit before this goes live.
