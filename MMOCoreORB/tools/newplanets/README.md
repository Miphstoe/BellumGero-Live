# NewPlanets tooling

Python 3 (standard library only) scripts used to build the Hoth planet: porting client assets into
`bg_custom1.tre` and generating the server Lua for its creatures, NPCs, caves and points of interest.

Client assets (terrain, snapshot, models, shaders, textures) are **not** in git. They ship inside
`bg_custom1.tre`, which is built from a staging folder of extracted files with `tre_pack.py --merge`.

## Local paths to edit before use

| Script | Path it assumes |
|---|---|
| `dep_closure.py` | source client `C:\SWG Infinity\Live`, target client `C:\BellumGero` (or `DST` env var) |
| `cave_points.py` | client `C:\Dev-BG`; snapshot at `extract/infinity/snapshot/hoth.ws` |
| `gen_hoth_mobiles.py` (`ROOT`) | server scripts at `\\wsl.localhost\Debian\home\EnderWookie\workspace\BellumGero-Hoth\MMOCoreORB\bin\scripts` |
| `tre_inventory.py`, `make_asset_log.py` | paths only in examples / docstrings |

## Archive and file tools

- `tre_inventory.py` — `list` / `find` / `extract` / `diff` over a client folder; ranks TREs by the client `.cfg` `searchTree` priority.
- `tre_pack.py` — build a TRE from a folder, or `--merge <base.tre> <folder> <out.tre>` to add/replace files in an existing TRE (base is never modified).
- `iff_tool.py` — IFF `tree` / `refs` / `trn` / `table`; `refs()` follows every asset reference (incl. terrain shader families, LOD-relative and backslash paths).
- `dep_closure.py <name> <seed paths...>` — recursive dependency closure of seeds against the source client; writes `audit/<name>_closure.tsv` (`port` = file the target client lacks).
- `dt_tool.py`, `stf_tool.py`, `cstb_tool.py` — read/write datatables (DTII), string tables (.stf) and CRC string tables (planet / object template).
- `merge_ticket_ui.py` — copy one planet's elements from another client's `ui_ticketpurchase.inc`; its helpers were also used for `ui_planet_map.inc`.
- `make_asset_log.py` — ASSET_LOG.md from closure TSVs.

## Hoth generators (re-runnable)

- `gen_hoth_mobiles.py` — creature, boss and NPC templates (`mobile/hoth/`), lairs, the `hoth_world` spawn group, outpost/site static spawns and the ice-cave screenplay. Rebalance by editing its tables and re-running.
- `cave_points.py` — reads each cave's `.pob` floors and the snapshot cell IDs; writes `server_prep/hoth_cave_points.json` used by the cave screenplay.
- `gen_hoth_register.py` — outpost terminals (`planetObjects`), world spawner region, and server object templates for the ported mobile models.
- `gen_hoth_pois.py` — named POI regions (server) plus client region names / radar regions.

## Rebuilding the client TRE

```
python tre_pack.py --merge <current bg_custom1.tre> build/hoth <new bg_custom1.tre>
```

`build/hoth` holds the Hoth client files (ported from SWG Infinity / MTG, plus BG's own `travel.iff`,
`planet_n.stf`, `ui_ticketpurchase.inc`, `ui_planet_map.inc`, CRC tables and waypoint table with Hoth added).
Rebuild on top of the newest `bg_custom1.tre` whenever someone else changes it. Confirm permission/credit
for the Infinity/MTG assets before shipping to live.
