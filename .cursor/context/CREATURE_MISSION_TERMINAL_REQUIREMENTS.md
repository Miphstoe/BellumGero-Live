# New Creatures and Mission Terminals (Destroy Missions)

When creating **new creatures that should appear on mission terminals** (so players can take Destroy missions to hunt them), use this checklist. If the user has not specified, **ask first**:

> **"I see this is a new creature. Do you want it on the Destroy mission terminal so players can take target missions for it?"**

If yes, you must do **both** of the following.

---

## 1. Add the lair to the planet’s destroy-mission list

Mission terminals get their target list from **destroy mission groups**, not from world spawn.

- **File**: `MMOCoreORB/bin/scripts/mobile/spawn/destroy_mission/<planet>_destroy_missions.lua`
- **Action**: Add a `lairSpawns` entry with:
  - `lairTemplateName` = the **lair template name** (e.g. `rori_monstrous_dark_graul_pack_neutral_none`)
  - `minDifficulty` / `maxDifficulty` = difficulty band (align with creature level; see existing entries)
  - `size` = e.g. `25`

**Lair template name** must match the name used in `addLairTemplate(...)` in the lair’s Lua file (under `mobile/lair/creature_dynamic/<planet>/` or similar).

---

## 2. Give the lair a mission building (required for Destroy missions)

Destroy missions need an object to place at the waypoint. If the lair has `buildingType = "none"` and all `buildings*` tables empty, the server will **skip** creating Destroy missions and the Destroy tab will not show.

- **Files**: The lair Lua file(s) for the new creature (e.g. `MMOCoreORB/bin/scripts/mobile/lair/creature_dynamic/<planet>/<lair_name>.lua`)
- **Action**: Add to the Lair table:
  ```lua
  missionBuilding = "object/tangible/lair/base/poi_all_lair_nest_small.iff",
  customName = "Friendly Display Name Here",
  ```
  - `missionBuilding`: same small nest used by other creature lairs for missions.
  - `customName`: text shown as the mission **Target** in the mission details (e.g. "Wild Foreign Bantha Rori"). Without it, the client shows the raw key like `lair_n:[template_name]`.

Without `missionBuilding`, `getMissionBuilding(difficulty)` returns empty and the mission is aborted, so no Destroy missions appear in the browser.

---

## Quick reference

| Step | Where | What |
|------|--------|------|
| 1 | `.../spawn/destroy_mission/<planet>_destroy_missions.lua` | Add lair to `lairSpawns` with template name, min/max difficulty, size. |
| 2 | Lair Lua (e.g. `.../lair/creature_dynamic/<planet>/<name>.lua`) | Add `missionBuilding` and `customName` (see section 2 above). |

After changes: **reload server** (`shutdown 0 fast` then `./core3`) so Lua is re-read. Test: Choose Mission Target → select the creature → List Missions → Destroy tab should list missions; open a mission and confirm **Target** shows the friendly name, not `lair_n:[template_name]`.

---

## Lessons learned (gotchas)

- **Destroy tab empty or only Deliver shows** → Lair has `buildingType = "none"` and no `missionBuilding`. Add `missionBuilding = "object/tangible/lair/base/poi_all_lair_nest_small.iff"` to the lair Lua.
- **Target shows `lair_n:[rori_wild_foreign_bantha_herd_neutral_none]`** → No string-table entry for that lair; add `customName = "Friendly Display Name"` to the lair so the mission uses it.
- **Creature not in “Choose Mission Target” list** → Mission list comes from the planet’s **destroy_mission** group, not world spawn. Add the lair to `.../spawn/destroy_mission/<planet>_destroy_missions.lua`.

---

*See also: CREATURE_TEST_RUNNER.md, SOP_TESTING_NEW_CREATURES.md.*
