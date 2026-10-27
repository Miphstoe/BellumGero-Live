# Taanab on Test Center — install notes for Miph

Branch: `Ender_Taanab` on Miphstoe/BellumGero-Live (Plane module "Taanab: Planet", LIVE-35..50).

## Client + server TRE

| File | Size | MD5 |
|---|---|---|
| `bg_custom1_taanab_20261026.tre` (`C:\SWG-Dev\NewPlanets\dist\`) — rename to `bg_custom1.tre` when installing | 220,133,124 bytes | `a1dad2b90a7e8e13ebbb1fcd116e1a75` |

This is the live `bg_custom1.tre` from 2026-10-25 (md5 `d3eafff1aab3a148fe59a9a1a7c95a87`, Hoth included) with the Taanab files merged in: 22 files added and 6 replaced. Nothing from the live copy was removed.

**Replaced:** `travel.iff`, `planet_n.stf`, `misc/planet_crc_string_table.iff`, `datatables/player/waypoint_planets.iff`, `ui/ui_ticketpurchase.inc` and `ui/ui_planet_map.inc`. Each one has Taanab added.

1. **Server:** back up `/trefiles/bg_custom1.tre`, then copy this file over it. The file name is the same, so `config.lua` doesn't change.
2. **TC client:** this same file replaces `bg_custom1.tre` in the client folder.
3. **Check:** run `md5sum` on both sides before starting.

If `bg_custom1.tre` changes on live before this ships, rebuild the Taanab TRE on top of the new copy (`tools/newplanets/stage_taanab.py`, then `tre_pack.py --merge`).

## Server steps

1. **Rebuild Core3:** check out `Ender_Taanab` and rebuild. The C++ changed in `GcwStatusCommand.h` (Taanab in `/gcwstatus all`) and `ResourceSpawner.cpp` (Galaxy Harvester export).
2. **Cold restart.** `taanab` is already in `ZonesEnabled` in `bin/conf/config.lua` on the branch.
3. **Boot check:** wait for "Logging online players", then grep the log for `taanab`.

## Travel points (both interplanetary; 1250cr from every planet, 4000cr from Hoth)

| Starport | x, z, y |
|---|---|
| Pandath Starport | 2117.8, 45, 5379.6 |
| Starhunter Station | 3592.2, 31.7, -5404.6 |

## What's on the planet in this drop

- **Housing:** every player house, merchant tent and civic city structure can be placed.
- **Cities:** Corellia's caps (20/20/15/10/10/5), so at most 5 Cosmopolis.
- **Faction HQs** can be placed.
- **Harvesters and factories** can be placed, and resources spawn.
- **GCW:** it's a GCW planet and is in the Imperial crackdown scans.
- **No-build zones:**
  - Map edges.
  - Pandath (550 m) and Starhunter Station (350 m).
  - Taanab Mining Outfit, Arcon hex farms, the shipwreck (Lucky Despot) and the Norulac Raider Cave. These four also show on the planet map.
- **Towns** come from the Infinity snapshot and include a cloning facility, bank or bank terminal, bazaar and mission terminals.
  - Pandath: Naboo-style buildings, cantina, hospital and garage.
  - Starhunter Station: an outpost.

## Not included yet

- **Creatures, NPCs and world spawns** (LIVE-46). The planet is empty land for now.
- **Mission terminal content** (LIVE-47).
- **Great Herds and Painted Hills regions** (no location yet).
- **Shuttle voice lines:** there are none for Taanab, so announcements are silent.

## What to test on TC

- **Travel:**
  - Buy a ticket to Taanab from a starport on every planet, Hoth included, and back.
  - Taanab should be on the galaxy map in the ticket window, on the east side.
  - Shuttles land at both starports, and arrivals don't put you inside a wall.
- **Look:** the terrain, sky and loading screen render, and the planet map shows Taanab's map, not Talus.
- **Housing:**
  - Place a small house, a merchant tent and a guild hall.
  - Placement is refused inside the town and POI no-build circles and at the map edge.
- **Cities:** found a city and grow it. The full test is LIVE-45: a 6th Cosmopolis must be refused.
- **HQs and harvesters:** place a faction HQ and a harvester, and survey for resources.
- **GCW:** `/gcwstatus all` lists Taanab.

## Credit

The terrain, snapshot, map, loading screens and planet globe come from SWG Infinity / MTG. Get permission or add credit before this goes live.
