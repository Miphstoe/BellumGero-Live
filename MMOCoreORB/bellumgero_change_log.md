# Bellum Gero — MMOCoreORB change log

User-confirmed changes only. Commit this file with the related code when you land a change.

## How to add an entry

```markdown
### YYYY-MM-DD — Short title

- **Summary:** What changed and why (one or two sentences).
- **Files:** `path/one.ext`, `path/two.ext`
- **Notes:** Optional (commands, follow-ups, caveats).
```

---

### 2026-03-31 — Mando Foundling: fix mission-not-clearing + planet tracker crash

- **Summary:** Two bugs. (1) `sendFoundlingQuotaTrackerOnMissionComplete` threw `LuaPanicException` (IllegalArgumentException) on every quota mission, because `buildAndSendFoundlingPlanetTracker` passed a multi-line string (joined with `\n`) and an em-dash `—` (non-ASCII) to `sendSystemMessage`, both unsupported by SWGEmu's String layer. Fixed by sending each tracker line as a separate `sendSystemMessage` call and replacing `—` with `-`. (2) The exception propagated out of `awardReward()` in `CompleteMissionObjectiveTask`, aborting before `removeMissionFromPlayer()` ran — causing completed missions to stay in the player's datapad. Fixed by wrapping `luaTracker->callFunction()` in a `try/catch (Exception&)` so tracker errors can never abort mission completion.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `src/server/zone/objects/mission/MissionObjectiveImplementation.cpp`
- **Notes:** Requires C++ rebuild for the try-catch fix; Lua reload for the tracker fix.

### 2026-03-31 — Mando Foundling informant: fix broken conversation options + assignment status

- **Summary:** Two bugs fixed. (1) The `check_turnin` ConvoScreen was missing from the template — clicking "I have completed the work." routed to a non-existent screen, leaving the engine with a nil `pConvScreen`, causing `runScreenHandlers` to bail early and rendering only "Stop Conversing" with no player options. Fixed by adding the `check_turnin` screen to the template so the engine can pass it to the handler, which then redirects to `not_done` or `turnin`/`turnin_final` based on `planetDone`. (2) When the player talks to the informant while a quota assignment is already active (`countingEnabled == 1, planetDone == 0`), `getInitialScreen` now sends a system message showing missions completed/remaining before returning the `already_assigned` screen.
- **Files:** `bin/scripts/mobile/conversations/bellum/mando_foundling_informant_conv.lua`, `bin/scripts/screenplays/bellum/convos/mando_foundling_informant_conv_handler.lua`
- **Notes:** Lua-only; reload scripts or restart zone.

---

### 2026-03-29 — Mando Foundling informant: Dantooine spawn moved (pirate outpost area)

- **Summary:** Updated static `mando_foundling_informant` coordinates for planet index 4 (Dantooine) to **(-594, 3, 2474)** (x, z height, y) from in-game verification near “a pirate outpost”.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua` (`planetData[4]`)
- **Notes:** Reload screenplays or restart; Dantooine zone reboot may be needed to despawn the previous world informant.

### 2026-03-29 — Mando Foundling: planet tracker after each quota mission

- **Summary:** After every mission that counts toward the Foundling planet quota, the client now receives a second system message: a **Progress: N/10 planets complete (M remaining)** line (N = informant turn-ins finished, M = worlds left in the arc including the current planet), then a newline-separated list of all arc planets with **Done** (turned in at informant), **In progress** (current world; shows `X/Y` until quota met, then “return to contact”), or **Pending** (not reached yet). Implemented via `MandoWayOfLife.sendFoundlingQuotaTrackerOnMissionComplete` called from `MissionObjectiveImplementation` after the existing quota line.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `src/server/zone/objects/mission/MissionObjectiveImplementation.cpp`
- **Notes:** Rebuild core3 for the C++ change; reload Lua or restart zones for script updates.

### 2026-03-29 — Mando Foundling: login waypoint refresh + quota-phase markers

- **Summary:** On login, `PlayerTriggers` calls `MandoWayOfLife:onPlayerLoggedIn`, which removes screenplay-tracked yellow waypoints (recruiter / informant / return) and reapplies the correct one from progression: Tatooine recruiter (novice Scout+Marksman+Medic, arc not started), informant locator (arc active, assignment not accepted), **none** while mission quota is in progress, informant again when quota is met for turn-in. `tryLinkStaticFoundlingInformant` can link without granting an informant waypoint during active quota. Per-planet target is centralized as **`FOUNDLING_PLANET_QUOTA_TARGET`** (6 test; set **36** for production). Recruiter marker is removed when the arc starts.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/screenplays/bellum/convos/mando_foundling_informant_conv_handler.lua`, `bin/scripts/screenplays/playerTriggers.lua`
- **Notes:** Lua-only; reload scripts / restart zone. Stale world NPCs at old coords are not deleted by this change—restart **corellia** (or full server) to drop the old unreachable informant if it still exists in RAM/DB.

### 2026-03-29 — Mando Foundling informant: Corellia spawn moved (Coronet)

- **Summary:** Relocated the static `mando_foundling_informant` for planet index 2 (Corellia) from coords that placed it inside unreachable city geometry to open ground at **(-367, 28, -4577)** (x, z height, y) per in-game verification.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua` (`planetData[2]`)
- **Notes:** Restart or reload the screenplay so `spawnStaticInformants()` runs with the new `planetData`; existing informant mobile may need a zone reboot to despawn old instance. Players mid-arc get waypoints from linked data—GM reset or re-advance planet step may be needed if coords were cached on a character.

### 2026-03-30 — RIS armor: stronger template baseline resists

- **Summary:** Raised default layer percentages on all RIS server pieces from Blue Frog 15% to **60%** on kinetic/energy/electricity/blast/heat/cold; **0%** on stun/acid/lightsaber to align with `vulnerability = ACID + STUN + LIGHTSABER` (same idea as composite chest vs stun). Improves admin-spawned / unscannable RIS; crafted runs still use `updateCraftingValues`.
- **Files:** `bin/scripts/object/tangible/wearables/armor/ris/armor_ris_*.lua` (9 pieces)
- **Notes:** Lua-only; restart or reload scripts as your server requires. Re-spawn new pieces; existing DB objects unchanged.

### Tooling / repo-adjacent

*(Editor rules, CI, docs-only, etc.)*

### 2026-03-29 — Cursor rules: confirm-before-changes + mandatory changelog

- **Summary:** Agent must ask before implementing unless explicitly told to proceed; after confirmed MMOCoreORB edits, append an entry here in the same turn.
- **Files:** `~/.cursor/rules/confirm-before-changes.mdc`, `bellumgero_change_log.md` (this file)
- **Notes:** Changelog lives in-repo for git history alongside features.

### 2026-03-29 — `/object createwearable` admin command (SEA sockets)

- **Summary:** Restored `createwearable` in `ObjectCommand` so admin-spawned wearables call `setMaxSockets` (default 4, optional second arg). `/object createitem` still leaves sockets at 0.
- **Files:** `src/server/zone/objects/creature/commands/ObjectCommand.h`
- **Notes:** Rebuild Core3. Usage: `/object createwearable object/tangible/.../template.iff [1-4]`.

### 2026-03-29 — Mando Way of Life: planet quota set to 6 (testing)

- **Summary:** Replaced random 25–100 mission quota with a flat 6 for QA testing. TODO comment in code flags it for production change to 36 (6 rounds × 6 missions per planet).
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`
- **Notes:** Lua only, no rebuild. Before production: change `target = 6` to `target = 36` and remove the TESTING ONLY comment.

### 2026-03-29 — Mando Way of Life: yellow waypoint disappearance fixes

- **Summary:** Fixed two waypoint bugs. (1) `acceptPlanetAssignment` now removes the "Mandalorian Informant" waypoint before issuing the "Return to your contact" waypoint — previously both existed simultaneously. (2) The conv handler re-link path now re-grants the waypoint if the player lost it (rezone/relog edge case) and hasn't accepted the assignment yet.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/screenplays/bellum/convos/mando_foundling_informant_conv_handler.lua`
- **Notes:** No rebuild required (Lua only).

### 2026-03-29 — Mando Way of Life: static informant boot spawns

- **Summary:** `start()` now spawns one static `mando_foundling_informant` per planet at server boot (near cantina in each major city) via new `spawnStaticInformants()`. Each OID is written to `mando_way:foundling_informant_static:<planet>` so `tryLinkStaticFoundlingInformant` can find them automatically — no manual placement needed.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`
- **Notes:** No rebuild required (Lua only). z values in `planetData` are approximate — do one in-game pass per planet to verify informants aren't spawning underground or floating and update coords if needed.

### 2026-03-29 — Mando Way of Life: static-only informant spawns

- **Summary:** Removed dynamic `spawnMobile` fallback and `DEBUG_SKIP` block from `spawnInformant`; it now only links to pre-placed static NPCs. Simplified `ensureFoundlingInformant` to re-link static NPC on reconnect without the despawn/respawn cycle. Dynamic spawns deferred to a later phase after FRS endgame gates are complete.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`
- **Notes:** No rebuild required (Lua only). Static informant NPCs must be placed in-world for each planet before the arc is tested. Yellow waypoints granted via `tryLinkStaticFoundlingInformant` → `grantInformantWaypoint` are unchanged and working.

### 2026-03-30 — Docs: full armor attachment (`AA`) command list @ 25

- **Summary:** Documented every `ObjectCommand` whitelisted AA stat as `/object createattachment AA … 25`, grouped (pistol/carbine/rifle/etc.) plus alphabetical block; noted mods absent from AA (BH, terrain_negotiation, *\_aim).
- **Files:** `docs/admin_object_create_commands.md`
- **Notes:** List matches `ObjectCommand.h` only; extend C++ whitelist to add more stats.

### 2026-03-30 — Admin spawn doc: socketed wearables + weapons

- **Summary:** Added markdown listing all discussed `/object` lines; armor and Wookie cloth use `createwearable … 4`; Bellum pistol/carbine use `createitem`.
- **Files:** `docs/admin_object_create_commands.md`
- **Notes:** Requires server build with `createwearable` in `ObjectCommand`.

### 2026-03-29 — Bellum bowcaster-stat pistol and carbine templates

- **Summary:** DL-44 and EE-3 appearance templates with combat stats aligned to `rifle_bowcaster.lua`; all species on pistol; same certs as base DL-44 / EE-3.
- **Files:** `bin/scripts/object/weapon/ranged/pistol/pistol_bellum_bowcaster_stats.lua`, `bin/scripts/object/weapon/ranged/carbine/carbine_bellum_bowcaster_stats.lua`, `bin/scripts/object/weapon/ranged/pistol/serverobjects.lua`, `bin/scripts/object/weapon/ranged/carbine/serverobjects.lua`
- **Notes:** Spawn IFFs end in `pistol_bellum_bowcaster_stats.iff` / `carbine_bellum_bowcaster_stats.iff`.
