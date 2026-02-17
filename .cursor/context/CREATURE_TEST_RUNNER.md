# Creature Test Runner – Run in order

Use this checklist in-game after Core3 is running (reboot first if you changed Lua: `shutdown 0 fast` in server console, then `./core3` from `~/localswgserver/MMOCoreORB/bin`).

---

## 1. Prerequisites (already done by agent)

- Build: MMOCoreORB build was run.
- Core3: Process is running. **To reload creature Lua:** in the server console type `shutdown 0 fast`, wait for exit, then run `cd ~/localswgserver/MMOCoreORB/bin && ./core3`.

---

## 2. In-game admin setup (do once per session)

| Step | Command |
|------|--------|
| 1 | Ensure account has admin (e.g. DB: `admin_level = 1`) |
| 2 | `/setGodMode self on` |
| 3 | `/invuln` |
| 4 | (Optional) `/gmrevive buff` |

---

## 3. Quick spawn test

**Rori** — `/teleport rori 0 0`

- `/createCreature monstrous_dark_graul` → target, check name/level (~20), hit to see health move, then `/kill` → harvest (Rori wild meat).
- `/createCreature wild_foreign_bantha_rori` → target, check name/level (~18), `/kill` → harvest (Rori wild meat, wooly hide, bone, Rori wild milk).

**Talus** — `/teleport talus 0 0`

- `/createCreature wild_foreign_bantha` → target, check name/level (~18), `/kill` → harvest (Talus wild meat, wooly hide, bone, milk).

**Lok** — `/teleport lok 0 0`

- `/createCreature longclaw_wild_vortor_lizard` → target, check name/level (~19), `/kill` → harvest (Lok wild meat, scaley hide, bone).

Optional per creature: `/dumpTargetInformation` before killing. Cleanup stuck mobs with `/destroy`.

---

## 4. Field test (natural lair spawns)

- **Rori:** Find Monstrous Dark Graul and Wild Foreign Bantha in the wild; kill and harvest. Confirm Rori wild meat; from bantha also wooly hide, bone, Rori wild milk.
- **Talus:** Find Wild Foreign Bantha; kill and harvest. Confirm Talus wild meat, wooly hide, bone, milk.
- **Lok:** Find LongClaw Wild Vortor Lizard; kill and harvest. Confirm Lok wild meat, scaley hide, bone.

Use `/teleport <planet> <x> <y>` (e.g. from SOP_TESTING_NEW_CREATURES.md §2.2) to reach spawn areas.

---

## 5. Sanity checks

- Names and levels match plan (graul ~20, banthas ~18, lizard ~19).
- No Lua errors in Core3 console or log when spawning/harvesting these creatures.

---

## 6. Mission terminal (if creature is on Destroy missions)

- At a **general** mission terminal: **Choose Mission Target** → select the creature → **List Missions**.
- **Destroy** tab should list missions for that target; take one and open mission details.
- **Target** should show the friendly name (e.g. *Wild Foreign Bantha Rori*), not `lair_n:[template_name]`. If you see the raw key, add `customName` to the lair (see CREATURE_MISSION_TERMINAL_REQUIREMENTS.md).

---

*Plan: SWG Dev Creature Test. Key files: MMOCoreORB/bin/scripts/mobile/{rori,talus,lok}/*.lua, lair/spawn in mobile/lair/ and mobile/spawn/.*

**Mission terminals:** If the creature should appear on Destroy mission terminals, see `.cursor/context/CREATURE_MISSION_TERMINAL_REQUIREMENTS.md` (add to destroy_mission list + set missionBuilding on lair).
