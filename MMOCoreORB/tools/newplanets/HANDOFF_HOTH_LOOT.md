# Handoff: Hoth loot, vehicles and resources for Bellum Gero (SWGEmu/Core3)

State as of 2026-10-04 evening. Everything below is committed and pushed. Read this top to bottom before touching anything.

## 1. Where things live

| What | Where |
|---|---|
| Work dir: tools, staging, builds, audits, notes | `C:\SWG-Dev\NewPlanets\` |
| Server worktree (branch `Ender_Hoth_Loot_and_more`) | `~/workspace/BellumGero-Hoth` in WSL Debian (`\\wsl.localhost\Debian\home\EnderWookie\workspace\BellumGero-Hoth`) |
| Repo copy of the tools (committed) | `MMOCoreORB/tools/newplanets/` in that worktree. Edit in `C:\SWG-Dev\NewPlanets`, copy over, commit. |
| Main checkout (do not touch) | `~/workspace/BellumGero-Live` on `Ender_Mando_Way_of_Life_Schematics`, has an uncommitted edit |
| Dev client for local testing | `C:\Dev-BG` (logs in to 127.0.0.1:44453). Its base is the Aug 5 `bg_custom1.tre` backed up at `C:\Dev-BG\archive\bg_custom1.tre.bak-20260927-prehoth` |
| Live client (never install test builds) | `C:\BellumGero`; its Sep 12 `bg_custom1.tre` is backed up at `C:\BellumGero\Backup\bg_custom1.tre.bak-20260927-prehoth` |
| Source client | `C:\SWG Infinity\Live` |
| Server TREs | `/trefiles` (root-owned dir; `bg_custom1.tre` is user-owned, overwrite without sudo) |
| Server log | `~/hoth_boot4.log` (rewritten every restart) |
| Reference art for the 10 custom paintings | `C:\SWG-Dev\NewPlanets\art\4.jpg … 13.jpg` (not in the repo) |

Remote: `git@github.com:Miphstoe/BellumGero-Live.git`. `gh` works from **Windows** (logged in as Thewookie-Eng); WSL's `gh` login is broken.

## 2. Branches, PRs, commits

**`Ender_Hoth`** (PR [Miphstoe/BellumGero-Live#795](https://github.com/Miphstoe/BellumGero-Live/pull/795) → Main, open, Auto-fix on, Miph merged it into Test Center, waiting on Main):
- `01828b697d` Hoth as a ground zone (C++: `allowAllDepartures` planet flag → rebuild needed)
- `e19946afac` creatures, NPCs, wampa caves, POIs, tools
- `3dd5948d3c` Hoth resources (`hoth` in `activeZones`, resource tree in the TRE)

**`Ender_Hoth_Loot_and_more`** (branched from `Ender_Hoth`, **no PR yet**; open it once #795 is in Main, or stacked):
- `7659bf15a7` snow armor sets, Hoth paintings, decor, snowspeeder, loot groups
- `89c65c5318` CRC table generated from the base TRE at build time
- `a52de3c01e` 10 custom boss paintings (`hoth_art_rare`)
- `48227ba3c8` snowspeeder mount data + painting texture fix
- `30c6a3b3df` rider poses added to the player animation table
- `f90c87ab7c` 30 Infinity vehicles as deeds + schematics
- `c491b3f209` pose entries sorted by name hash (client crash fix)
- `b600673f8c` vehicle/deed name strings
- `1825edc2ad` mount rows keyed by the real model name
- `81560bd97c` AT-AT house placeable on Hoth
- `658f8a8c33` **C++** mount range 7m → 20m (`MountCommand.h`; rebuild needed)
- `d0a7c80730` backslash effect refs followed; shader inspection tools

`MMOCoreORB/bellumgero_change_log.md` has an entry per feature, newest first. Keep doing that.

## 3. TRE builds (client and server share the same file)

Build with `python build_tre.py <base> <out> build/hoth build/hoth_loot` from `C:\SWG-Dev\NewPlanets`. It merges the two overlay folders onto the base and **regenerates `misc/object_template_crc_string_table.iff` from the base's own table plus every object iff in the overlays**. Never ship a CRC table from the overlays (an earlier build dropped 80 live entries that way).

| File in `dist\` | Base | Content | md5 |
|---|---|---|---|
| `bg_custom1_hoth_only.tre` | live Sep 12 | Hoth only, matches PR #795. **This is what TC should run.** Replaces the broken `0006e3f6…`/`98f8ef11…` builds. | `3f788419438111fe37d1f05aa964ae80` |
| `bg_custom1.tre` | live Sep 12 | Hoth + everything on the loot branch | `d0c96ca01a9e5a3707556d2b09fb891c` |
| `devbg\bg_custom1.tre` | Dev-BG Aug 5 | same loot content, installed in `C:\Dev-BG` and `/trefiles` | `8f814d8e8948da74bee7bcb8a9076713` |

`bg_custom1_7_plus_hoth.tre` and `bg_custom1_hoth_plus_download.tre` in `dist\` were made by Brandon, not by the tools; leave them.

Verify any build with `python verify_tre.py` (overlay coverage + CRC completeness) and `python chain_check.py <tre> <roots…>` (walks asset chains, reports missing files).

## 4. Generators (idempotent; edit the tables, re-run)

Run from `C:\SWG-Dev\NewPlanets`. Order: client generator → server generators → build → install.

| Script | Does |
|---|---|
| `gen_hoth_loot_client.py` | all client files into `build/hoth_loot`: cloned draft/loot schematic iffs (armor, paintings), decor templates, string tables (`art_n/d`, `dt_n/d`, `frn_n/d`, `monster_name/detail`, `item_n/d`, `pet_deed`), mount tables, rider poses (`lat_add_pose.py`), snowspeeder extras; calls `gen_hoth_art.client()` and `gen_hoth_vehicles.client()` |
| `gen_hoth_art.py` | 10 custom paintings: textures from `art/`, cloned shader/mesh/apt/object iff per painting |
| `gen_hoth_vehicles.py` | 30 vehicles: asset closure staging (`stage_recursive`), deed/vehicle clones where Infinity lacks them, mount rows (keyed by saddle **and** real appearance), string copies, draft/loot schematic iffs; `server()` writes pcd/vehicle/deed/draft/loot-schematic Lua, loot items, groups |
| `gen_hoth_loot.py` | server Lua: armor wearables + schematics, paintings, decor, vehicles (via `gen_hoth_vehicles.server`), loot items in `loot/items/bellum/hoth/`, groups in `loot/groups/bellum/hoth/` |
| `gen_hoth_mobiles.py` | all Hoth creatures/NPCs/lairs/caves/static spawns (owns `mobile/hoth/*`); `HOOK()` adds the loot-group rolls; `LOOT_BOSS` is the cave-boss table |
| `gen_hoth_pois.py`, `gen_hoth_register.py` | POI regions, registration (planet pass) |
| `lat_add_pose.py` | adds rider poses to `appearance/lat/all_m.lat` from Infinity's table; **VAL entries must be sorted by SOE CRC-32 of the name** or the client crashes on login |
| `stage_closure.py`, `dep_closure.py` | closure of file references (stops at .snd; does not follow datatable rows or backslash paths) |
| `fix_textures.py [--fix] [--strict]` | DDS sizes the client rejects (DXT dims not multiple of 4 crash the client) |
| `effect_check.py [--stage]`, `shader_check.py`, `vehicle_materials.py`, `vehicle_inventory.py` | shader/effect diagnostics |
| `make_gm_sheet.py` → `HOTH_LOOT_GM_TEST.md` | every `/object createitem` command (189) plus crafting resources |
| `iff_clone.py` | clone object iffs with patched properties (`clone`) or any IFF with string replacement (`clone_raw`); FORM sizes recomputed |
| `tre_pack.py`, `tre_inventory.py`, `cstb_tool.py`, `stf_tool.py`, `dt_tool.py`, `iff_tool.py`, `iff_names.py`, `iff_strings.py` | low-level TRE/IFF/STF/datatable tools |

Server restart after installing a TRE: `wsl -d Debian -- bash /mnt/c/SWG-Dev/NewPlanets/wsl/reinstall_restart.sh` (stops core3, copies `dist/devbg/bg_custom1.tre` to `/trefiles`, starts, waits). `wsl/errors.sh ~/hoth_boot4.log` summarises errors. Baseline is **303 ERROR lines**, all pre-existing (stale droid foundry/armor-suit schematics, `ep3_pet_deed/objects.lua`). Core3 build: `cd MMOCoreORB/build/ninja && ninja -j6 core3` (incremental, ~4 min for a header change; output lands in `bin/core3`).

## 5. What is implemented

- **Hoth resources**: 55 Hothian classes in `datatables/resource/resource_tree.iff` (ships in the TRE, read by server and client); `hoth` in `activeZones`. Confirmed working in game (`/resource list hoth`).
- **Armor**: Snowtrooper and Alliance Cold Weather sets, 11 pieces each (incl. backpack), no faction lock, stormtrooper stats, Master Armorsmith loot schematics (3 uses). Crafting verified only as far as item creation.
- **Paintings**: 12 Hoth/ESB paintings as drops and Architect schematics; 10 custom boss paintings (`hoth_art_rare`, finished only).
- **Decor**: plush/stuffed/trophies/toys/snow globes/rug/holo/3 commemorative paintings, 16-piece ice-cave set. Decor derived from the generic tangible base gets `gameObjectType = 8203` (FURNITURE) so it can be placed.
- **Vehicles**: 30 (snowspeeder + 29 Infinity vehicles; see `HOTH_VEHICLES.md`). Deed + Artisan Engineering IV schematic each. Mount tables, 18 rider poses, vehicle client data, effects.
- **AT-AT house** (already in BG) now placeable on Hoth. All other 51 player structures still exclude Hoth (harvesters too; decide with Miph).

Loot groups (weights total 10,000,000, equal shares unless noted) and who rolls them:

| Group | Rolled by |
|---|---|
| `hoth_snowtrooper_schematics` / `hoth_rebel_snow_schematics` | snowtroopers 1.5%, sergeants 4% / Rebel soldiers 1.5%, sergeants 4% |
| `hoth_paintings` (schematics 7.29% each, finished 1.04% each) | cave bosses 25%, raiders 5% |
| `hoth_decor_common` | most NPCs 2–3%, wampas 3–4%, raiders 10%, salvage techs 15% |
| `hoth_decor_rare` | bosses 15% |
| `hoth_ice_decor` | bosses 20%, wampas 5%, elder wampas 7% |
| `hoth_art_rare` | bosses 10%, every other Hoth mobile 0.5% |
| `hoth_vehicle_schematics` | bosses 5% |
| `hoth_vehicle_deeds` | bosses 2% |

Cave bosses: Frostfang, Icemaw, Snowblind the Ravager, wampa matriarch, wampa patriarch, mynock broodmother.

## 6. Test status (Dev-BG, GM character BowBa Fango)

Works: resources; item creation for armor, schematics, paintings, decor; STAP calls and mounts; the fixed First Strike on Hoth painting; AT-AT house deed spawns.

**Open issues, in priority order**
1. **RIC-920 still renders bright green** after the effect fix (the gunship and the other five `a_envmask_specmap_cbmp` users should be fixed by `d0a7c80730` but are not yet re-tested). The RIC shader `ric_920_speeder_aesc22.sht` uses texture slots `CNRM`, `ENV` (`texture\env_theed.dds`, present), `MAIN`, `SPEC`. Green = the `_cn` normal map drawn as colour, i.e. the effect still isn't being applied. Next steps: confirm the client was relaunched after the `8f814d8e…` install; run `python shader_check.py dist/devbg/bg_custom1.tre appearance/ric_920_speeder.sat`; compare the staged `effect/a_envmask_specmap_cbmp.eft` against the one in the live client; check the effect's pixel/vertex programs load (all exist by name). Possibly the old renderer needs the `_cbmp` effects' ps20 path and the DXVK layer (`SWGEmu_d3d9.log`) refuses them.
2. **Podracers couldn't be mounted** because the server's range check measured to the object origin (pod sits 2–14m behind it). Fixed to 20m in `MountCommand.h`, core3 rebuilt and running. **Not yet re-tested.**
3. **Organa speeder (XJ-2) never appears when called.** All files present, same structure as the working STAP. Theory: it was already "deployed" from a call made while it was invisible; Call returns silently then. Have the user Store it from the datapad radial, then Call. If still invisible, diff against the STAP byte by byte.
4. Only the snowspeeder and STAP have been through generate → call → mount. The other 28 vehicles are untested.
5. Armor crafting end-to-end (learn schematic, craft, equip on male and female) untested. Female meshes were added for both sets.
6. Three Infinity references exist nowhere (one STAP shader `stap_speeder_sm_as8.sht`, two panning-droid sounds); left as-is.
7. Hoth loading screen (`ui/ui_load_hoth.inc`, `string/en/loading/hoth.stf`) not ported.
8. Permission/credit for Infinity, MTG and Takhomasak assets before anything goes live.

## 7. Gotchas learned the hard way

- Run WSL commands from the **PowerShell** tool as `wsl -d Debian -- bash /mnt/c/…/script.sh`; the Bash tool is Git Bash and rewrites `/mnt/c`. Bash heredocs also eat backslashes; write Python files with the Write tool instead.
- Never commit `managers/ghoutput.xml` or `managers/resource_manager_spawns.lua` (runtime files).
- Client crashes: `C:\Dev-BG\SWGEmu.exe-stage.*.txt` names the template/shader/texture being loaded. `CreateTexture failed` = bad DDS (run `fix_textures.py`). Access violation right after login = malformed `all_m.lat` (VAL sort).
- The client only renders a vehicle whose **real** appearance (`pv_*.sat`) has rows in `logical_saddle_name_map` and `valid_scale_range`; the saddle `.apt` name alone is not enough.
- The client only seats a rider whose pose exists in `all_m.lat`; the server never sees poses.
- Server `/mount` fails silently on range (>20m now), line of sight, wrong creature link, or player/vehicle inside a building.
- Shaders reference effects and some textures with **backslashes**; regexes that only accept `/` miss them.
- `build/hoth` and `build/hoth_loot` must not carry `misc/object_template_crc_string_table.iff`.
- Only copy a TRE into `C:\Dev-BG` when no `C:\Dev-BG\SWGEmu.exe` is running (the `C:\BellumGero` client doesn't matter).

## 8. Suggested next session

1. Relaunch the client on `8f814d8e…`, check gunship/RIC rendering, podracer mount, XJ-2 after Store/Call. Fix what fails.
2. Walk the remaining 28 vehicles with the GM sheet (deed → call → mount → ride → store).
3. Craft one armor piece end to end on a Master Armorsmith; equip on male and female.
4. Decide Hoth structure placement with Miph (all buildings vs houses/harvesters only).
5. Open the loot PR (base `Main` after #795 lands) with the `dist\bg_custom1.tre` checksum of that moment.
