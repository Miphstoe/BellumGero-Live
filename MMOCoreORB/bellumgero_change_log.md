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

### 2026-05-12 — Kashyyyk Tribal Master Bowcaster: dedicated shared client template wiring

- **Summary:** Added `object_weapon_ranged_rifle_shared_rifle_kashyyyk_tribal_master_bowcaster` in `rifle/objects.lua` mapping to `object/weapon/ranged/rifle/shared_rifle_kashyyyk_tribal_master_bowcaster.iff`. Rewired `rifle_kashyyyk_tribal_master_bowcaster.lua` to inherit from that shared Lua type instead of `shared_rifle_bowcaster`, so the client can load a **separate** cloned IFF (same art as stock) with custom STF pointers for name, description, and look-at without changing stock bowcasters. Removed `customObjectName` so display strings resolve from the custom IFF once the patch TRE is installed.
- **Files:** `bin/scripts/object/weapon/ranged/rifle/objects.lua`, `bin/scripts/object/weapon/ranged/rifle/rifle_kashyyyk_tribal_master_bowcaster.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only (zone restart). **Client must** ship `shared_rifle_kashyyyk_tribal_master_bowcaster.iff` plus matching rows in `string/en/weapon_name.stf`, `weapon_detail.stf`, and `weapon_lookat.stf` (IFF references `@weapon_*:rifle_kashyyyk_tribal_master_bowcaster`) **before** players rely on this weapon in the wild; a missing IFF in the TRE can prevent the asset from resolving. Pack the IFF at exactly `object/weapon/ranged/rifle/shared_rifle_kashyyyk_tribal_master_bowcaster.iff` inside the patch archive.

### 2026-05-12 — Kashyyyk Tribal Master Bowcaster: document weapon STFs (weapon_name / detail / lookat)

- **Summary:** Comments and changelog previously referred to `bg_items.stf` for localized strings; updated to match the stock weapon pattern — `@weapon_name`, `@weapon_detail`, and `@weapon_lookat` each with key `rifle_kashyyyk_tribal_master_bowcaster` in `string/en/weapon_name.stf`, `weapon_detail.stf`, and `weapon_lookat.stf`. Server Lua still only registers the IFF path; actual STF pointers remain in the client `shared_rifle_kashyyyk_tribal_master_bowcaster.iff`.
- **Files:** `bin/scripts/object/weapon/ranged/rifle/objects.lua`, `bin/scripts/object/weapon/ranged/rifle/rifle_kashyyyk_tribal_master_bowcaster.lua`, `bellumgero_change_log.md`
- **Notes:** Update the client IFF so Object name / Detailed description / Look at text use those `@weapon_*:` string IDs (not `@bg_items:`).

### 2026-05-11 — New rare loot: Kashyyyk Tribal Master Bowcaster (generic galaxy drop)

- **Summary:** Added a new Wookiee-themed rifle, the **Kashyyyk Tribal Master Bowcaster**, as a generic galaxy-wide rare drop. Visually it reuses the stock Wookiee bowcaster model (`appearance/wp_rifle_bowcaster.apt`) — same rig as the stock bowcaster — but the `playerRaces` list is overridden so any species can wield it (Bothan, Human, Ithorian, Mon Cal, Rodian, Sullustan, Trandoshan, Twi'lek, Wookiee, Zabrak — both genders). `certificationsRequired = { "cert_rifle_bowcaster" }` is retained, so only Rifleman-trained characters with the bowcaster cert can equip and fire it; everyone else sees the standard "not certified" gate. Stats sit a tier above stock: base **minDamage 900 / maxDamage 1350**, `attackSpeed 1.4`, `woundsRatio 18`, energy / light AP, range 0–64 m with peak accuracy at 45 m. Experimental ladder allows crafted instances to flex to roughly **1200 / 1600** at top quality. Registered on the server via `serverobjects.lua` and seeded into the shared `rifles` loot group at `weight = 100000` (lighter than the stock `rifle_bowcaster` at 700000 to keep it rare). **Follow-up (2026-05-12):** client string display is wired through a dedicated shared IFF + STF (see entry above); the original note about `customObjectName` was superseded when that field was removed in favor of IFF-driven localization.
- **Files:** `bin/scripts/object/weapon/ranged/rifle/rifle_kashyyyk_tribal_master_bowcaster.lua` (new), `bin/scripts/object/weapon/ranged/rifle/serverobjects.lua`, `bin/scripts/loot/groups/weapon/rifles.lua`, `bellumgero_change_log.md`
- **Notes:** No `core3` rebuild needed (Lua-only). Zone restart picks up the new template + loot entry. Client-side: ship `shared_rifle_kashyyyk_tribal_master_bowcaster.iff` + STF (see 2026-05-12 entry). With `weight = 100000` relative to the group's ~10.85M total weight, expected drop chance is ~0.92% of any roll that lands on the `rifles` group.

### 2026-05-11 — Mando armory trio: rewrite chapter-trial gift message ("This is the way!")

- **Summary:** Replaced the three short `giftMsg` strings in `MandoWayOfLife.mandoWayArmoryChapters[1..3]` with a single longer in-character message template that ties directly into the new 666 / 999 trial-gift damage cap. The new message tells the player that the **min dmg** signals the beginning of bringing destruction to their targets and the **max dmg** signifies completion of their latest trial, frames the weapon as a guild investment, and closes with "This is the way!" — reinforcing the questline-completion symbolism of the clamped 999 max from the matching damage rebalance entry below. The per-chapter weapon name is interpolated directly into each entry (Mandalorian Geonosian Blaster Pistol / Nym Slugthrower Carbine / Light Lightning Cannon). Sent via `CreatureObject:sendSystemMessage` from `grantMandoWayArmoryChapterGift` on chapter advance.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bellumgero_change_log.md`
- **Notes:** No `core3` rebuild needed (Lua-only string change). Light copy edits relative to the original draft: `grift`→`gift`, `mechicnisms`→`mechanisms`, `distruction`→`destruction`, `you max dmg`→`your max dmg`, added missing article ("a great investment") and one comma after "trigger mechanisms" for readability. Inner double quotes around `"This is the way!"` rendered as single quotes (`'This is the way!'`) so the outer Lua string literal stays in double quotes without escapes.

### 2026-05-11 — Mando armory trio: split damage between trial-gift (clamped 666/999) and craftable (flex above 999) + cosmetic display names

- **Summary:** Rebalanced the three Mando Way armory weapons (`pistol_mando_way_geo_blaster`, `carbine_mando_way_slugthrower`, `rifle_mando_way_lightning`) so the chapter-trial gift path (handed via `giveItem` in `MandoWayOfLife:grantMandoWayArmoryChapterGift`) yields a clamped 666 / 999 weapon — the **999** signaling questline completion — while the craftable path (via `mandoWayArmorySchematicSales` recruiter datapad → draft schematic → weaponsmith) can roll noticeably higher through resource quality + experimentation. Implemented by lowering top-level `minDamage` / `maxDamage` to 666 / 999 (used by `giveItem`) and bumping the `experimentalMin` / `experimentalMax` entries for `mindamage` (index 3) and `maxdamage` (index 4) per weapon class. Also kept the pending `customObjectName` strings on each file so the in-world display names match the lore ("Mandalorian Geonosian Blaster Pistol", "Mandalorian Nym Slugthrower Carbine", "Mandalorian Light Lightning Cannon") rather than the EE-3/DL-44 stock IFF names.
- **Files:** `bin/scripts/object/weapon/ranged/pistol/pistol_mando_way_geo_blaster.lua`, `bin/scripts/object/weapon/ranged/carbine/carbine_mando_way_slugthrower.lua`, `bin/scripts/object/weapon/ranged/rifle/rifle_mando_way_lightning.lua`, `bellumgero_change_log.md`
- **Notes:** No `core3` rebuild needed (Lua templates only); zone restart picks up the new stats. **Tier ladder for crafted instances** (experimental `mindamage` low→high / `maxdamage` low→high): pistol **700 → 1100 / 1000 → 1500**; carbine **800 → 1200 / 1100 → 1700**; rifle **900 → 1300 / 1300 → 1900**. Existing players who already received the old 900 / 1200 trial-gift weapon keep their copy; new chapter completions after this lands receive the 666 / 999 variant. The schematic / draft / loot files, the C++ lightning command whitelist (commit `4d5441c3e8`), and the grant logic in `mando_way_of_life.lua` are unchanged.

### 2026-05-11 — Mando Way: finish `/mandoStatus` end-to-end dispatch wiring

- **Summary:** Closed the last gap so `/mandoStatus` works end-to-end on the server. Added the Lua master-include line in `commands.lua` so `mandoStatus.lua` is loaded at boot, and registered `MandoStatusCommand` in the **commandFactory** (`CommandConfigManager::registerCommands3`) so the engine can construct the C++ `QueueCommand` instance when the action CRC dispatches. Companion to the earlier `CommandList` Option B registration in `CommandConfigManager::registerSpecialCommands`; both the factory and the CommandList are required for the slash command to dispatch cleanly.
- **Files:** `bin/scripts/commands/commands.lua`, `src/server/zone/managers/objectcontroller/command/CommandConfigManager3.cpp`, `bellumgero_change_log.md`
- **Notes:** Requires a `core3` rebuild + zone restart. Verified after rebuild — no `Invalid enqueueCommand` errors for `/mandoStatus`.

### 2026-05-11 — Lightning special attacks: whitelist Foundling/Mando lightning rifle templates

- **Summary:** The five lightning special-attack `QueueCommands` (`FireLightningCone1Command`, `FireLightningCone2Command`, `FireLightningSingle1Command`, `FireLightningSingle2Command`, `LightningBarrageCommand`) gated on `weapon->isLightningRifle()` or `tplPath == "object/weapon/ranged/rifle/rifle_lightning_heavy.iff"`. Custom Foundling/Mando lightning rifle templates don't carry the `isLightningRifle` IFF binding, so equipping them previously returned `INVALIDWEAPON` for every lightning special. Extended each command's `isLightningWeapon` check to additionally accept `rifle_foundling_light_lightning_cannon.iff` and `rifle_mando_way_lightning.iff`. Net effect: the Mando Light Lightning Cannon and the Foundling lightning cannon now unlock the full lightning special-attack suite.
- **Files:** `src/server/zone/objects/creature/commands/FireLightningCone1Command.h`, `src/server/zone/objects/creature/commands/FireLightningCone2Command.h`, `src/server/zone/objects/creature/commands/FireLightningSingle1Command.h`, `src/server/zone/objects/creature/commands/FireLightningSingle2Command.h`, `src/server/zone/objects/creature/commands/LightningBarrageCommand.h`, `bellumgero_change_log.md`
- **Notes:** Requires a `core3` rebuild. Cleaner long-term fix is to bind `isLightningRifle` on the custom IFFs so the explicit template-path whitelist can be retired; that work is deferred.

### 2026-05-11 — Spynet Chapter 1 bounty camp: tighten max spawn radius to 2200m

- **Summary:** Reduced `BellumBountyCampChapter1Theater.maximumDistance` from `3200` to `2200` in `bounty_camp_chapter1_theater.lua`. The 1600m floor is preserved (keeps camps out of city cores), but the upper bound was too generous — playtesting showed Chapter 1 camps occasionally landing across rivers or in adjacent biomes / no-spawn shells. Tightening to 2200m keeps the contract feeling local while still respecting the per-planet no-spawn shells the `GoToTheater` framework reads. Chapter 2 / Chapter 3 theaters are unchanged.
- **Files:** `bin/scripts/screenplays/bellum/bounty_camp_chapter1_theater.lua`, `bellumgero_change_log.md`
- **Notes:** No `core3` rebuild needed (Lua only). Active camps spawned before the restart keep their original anchor; the new ring only applies to camps spawned after reload.

### 2026-05-11 — SceneObject container access: bounds-check slot index in Lua + C++ paths

- **Summary:** `ContainerObjectsMap::get(int)` is backed by `VectorMap::get(int)` which throws on out-of-range slot indexes. The Lua binding `SceneObject:getContainerObject(idx)` exposed that throw to script code, so any stale or racing slot index from Lua could blow up the underlying C++. Added two defensive bounds checks: at the Lua boundary in `LuaSceneObject::getContainerObject` (returns Lua `nil` on miss; also switched `lua_tonumber` → `lua_tointeger` so non-integer Lua values truncate cleanly), and at the underlying C++ method in `ContainerObjectsMap::get` (returns `nullptr` on miss). Belt-and-suspenders — neither path now raises an exception for OOR slot ids.
- **Files:** `src/server/zone/objects/scene/LuaSceneObject.cpp`, `src/server/zone/objects/scene/variables/ContainerObjectsMap.cpp`, `bellumgero_change_log.md`
- **Notes:** Requires a `core3` rebuild. Note: callers that previously relied on a thrown exception to detect OOR access must now handle `nil`/`nullptr` returns explicitly; existing call sites already null-check the returned `SceneObject*`/Lua value, so no follow-up changes were needed in this pass.

### 2026-05-11 — Mando Way: restore lost trialqa fast-path and re-register custom slash commands

- **Summary:** Several files had been removed from the working tree (unstaged deletions), which is why `mandoFoundlingAdminRun` resolved to `nil` and `village_jedi_manager.lua` saw `Glowing` as `nil`. Restored `bellumgero_change_log.md`, `bin/scripts/commands/mandoFoundlingAdmin.lua`, `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/screenplays/screenplays.lua`, and `src/server/zone/managers/objectcontroller/command/CommandConfigManager.cpp` from HEAD. Re-applied **Option B** in `CommandConfigManager::registerSpecialCommands` to register `mandoFoundlingAdmin` and `mandoStatus` in `CommandList` directly so server dispatch works without server-side `command_tables_shared*.iff` rows. Re-applied the **trialqa** privileged-admin fast-path in `mando_way_of_life.lua` (lost when the unstaged trialqa work was wiped during file restore): new `DEBUG_ADMIN_TRIAL_CAMP_QA` toggle in the script-level config table, new `MandoWayOfLife:adminTrialCampQaApply` / `adminTrialCampQaFromTokens` helpers, and a `trialqa` route inside `MandoWayOfLife:adminFoundlingCommand` so `/mandoFoundlingAdmin trialqa <start|restart|end|status> [playerName]` invokes the corresponding bounty-camp lifecycle function (`beginPrivateContract`, `restartSpynetBountyCampTrialFromOperative`, `finishActiveSpynetBountyCampTheater`).
- **Files:** `src/server/zone/managers/objectcontroller/command/CommandConfigManager.cpp`, `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bellumgero_change_log.md`
- **Notes:** Requires a `core3` rebuild + zone restart to pick up the `CommandConfigManager` change. Lua change reloads with the next zone restart. **QA confirmed:** three consecutive trial-camp kills produced no `mandoFoundlingAdminRun` or `Glowing` errors, so `DEBUG_ADMIN_TRIAL_CAMP_QA` was set back to **false** for shipping (privileged-admin check inside `adminFoundlingCommand` still gates the route; flag is the second belt-and-suspenders). The companion `village_jedi_manager.lua:87` `Glowing` nil-ref resolved on its own because the missing master `screenplays/screenplays.lua` (which includes `screenplays/village/intro/glowing.lua`) was restored.

### 2026-04-25 — Mando title nameplate: document client wrap / orphan ")"

- **Summary:** Documented that the floating **skill title** line is resolved and wrapped entirely on the **client** from `string/en/skl_t.stf` (skill id such as `mando_title_foundling`). Long `skl_t` values can leave a lone closing parenthesis on the next line; shorten the STF string or use a no-break space before `)` in the client TRE (e.g. `bg_custom1.tre`).
- **Files:** `bin/scripts/skills/bellum/mando_titles.lua`, `bellumgero_change_log.md`
- **Notes:** No server restart required for the comment alone. Changing the visible title still requires editing and shipping the **client** STF override.

### 2026-04-20 — Mission terminals: disable destroy mission level gating

- **Summary:** Updated destroy mission selection so mission terminals always pick from the active destroy mission group without filtering by player or group level. This keeps destroy contracts available on custom shard planets such as Yavin, even for lower-level characters.
- **Files:** `src/server/zone/managers/mission/MissionManagerImplementation.cpp`, `bellumgero_change_log.md`
- **Notes:** Requires rebuild and restart of `core3` (C++ change).

### 2026-04-18 — Foundling Beskar CDEF kit from recruiter on arc start

- **Summary:** Added three weapon templates (**pistol / rifle / carbine** `*_foundling_cdef_beskar`) with **CDEF** certifications, display names **Foundling Beskar CDEF …**, combat profile **666 min/max damage** and **0.6 attack speed**. **`MandoWayOfLife:startFoundlingArc`** calls **`grantFoundlingBeskarCdefKit`** after the first planet advance so new recruits receive the kit when the recruiter sends them to the Tatooine informant.
- **Files:** `bin/scripts/object/weapon/ranged/pistol/pistol_foundling_cdef_beskar.lua`, `bin/scripts/object/weapon/ranged/rifle/rifle_foundling_cdef_beskar.lua`, `bin/scripts/object/weapon/ranged/carbine/carbine_foundling_cdef_beskar.lua`, `bin/scripts/object/weapon/ranged/pistol/serverobjects.lua`, `bin/scripts/object/weapon/ranged/rifle/serverobjects.lua`, `bin/scripts/object/weapon/ranged/carbine/serverobjects.lua`, `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `docs/admin_object_create_commands.md`, `bellumgero_change_log.md`
- **Notes:** Rebuild **`core3`** (new IFF templates). Requires **three free inventory slots** at accept; species **CDEF** certs unchanged from stock (**species** skills on default DB).

### 2026-04-18 — Bellum bowcaster-stat pistol/carbine: no certification required

- **Summary:** Cleared **`certificationsRequired`** on **`pistol_bellum_bowcaster_stats`** and **`carbine_bellum_bowcaster_stats`** so adventure or staff-spawned copies equip without Marksman box certs (temporary until certs are revisited).
- **Files:** `bin/scripts/object/weapon/ranged/pistol/pistol_bellum_bowcaster_stats.lua`, `bin/scripts/object/weapon/ranged/carbine/carbine_bellum_bowcaster_stats.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; restart **`core3`**. Stock **`rifle_bowcaster.iff`** still requires **`cert_rifle_bowcaster`** unless changed separately.

### 2026-04-14 — Mando Way: Spynet comlink on Jabba badge; post rank Spynet signoff

- **Summary:** When **Jabba themepark** awards badge **105**, **Clanbound** players (chapter 4 complete, chapter 5 not yet) receive a **Spynet comlink** system line directing them to **Mos Eisley** and the **recruiter**. After **`grantMandalorian`** (rank, title, chapter badge), a second **Spynet comlink** line closes the arc (**Continue your Hunt**, FRS deferred). Hook lives in **`ThemeParkLogic:giveBadge`** calling **`MandoWayOfLife:onJabbaThemeparkBadgeEarned`**.
- **Files:** `bin/scripts/screenplays/themepark/themeParkLogic.lua`, `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; restart **`core3`**.

### 2026-04-14 — Mando Way: operative → Tatooine recruiter; "What's next?" Hutt trial copy

- **Summary:** Corellia Spynet operative now tells Clanbound players to return to the **Mandalorian Recruiter in the Mos Eisley cantina (Tatooine)** for the next path. Trialmaster **clanbound** gained a **What's next?** option; **`clanbound_whats_next`** is filled in the handler with the **Hutt / Jabba themepark** final trial text (plus epilogue when chapter 5 is complete). **Clanbound complete** system message and recruiter **no Jabba badge yet** intro line updated to match.
- **Files:** `bin/scripts/mobile/conversations/bellum/mando_spynet_operative_conv.lua`, `bin/scripts/mobile/conversations/bellum/mando_trialmaster_conv.lua`, `bin/scripts/screenplays/bellum/convos/mando_trialmaster_conv_handler.lua`, `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; restart **`core3`** or reload conversations.

### 2026-04-06 — Mando armory weapon stat tune (uniform high burst)

- **Summary:** Updated the three new Mandalorian armory weapons to a unified test profile per request: **`minDamage=900`**, **`maxDamage=1200`**, **`attackSpeed=1.5`** on pistol, carbine, and LLC variants.
- **Files:** `bin/scripts/object/weapon/ranged/pistol/pistol_mando_way_geo_blaster.lua`, `bin/scripts/object/weapon/ranged/carbine/carbine_mando_way_slugthrower.lua`, `bin/scripts/object/weapon/ranged/rifle/rifle_mando_way_lightning.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; restart **`core3`**. Crafting experiment ranges are unchanged in this pass.

### 2026-04-06 — Spynet bounty camp: restore yellow Quest waypoint; finish all stuck GoToTheater tasks

- **Summary:** The **yellow Spynet bounty camp** pin lives under the datapad **Quest** tab (**`WAYPOINTQUESTTASK`**). After **relog**, login refresh only nudged the player in chat and **did not re-add** the waypoint if the client dropped it. Added **`restoreSpynetBountyCampQuestWaypoint`** (theater anchor → **`addWaypoint`**) and call it from **`refreshPrivateContractTargetWaypointFromActiveTarget`** (camp mode), **`beginPrivateContract`**, and **`migrateLegacyPrivateContractToBountyCampTheater`**. **`finishActiveSpynetBountyCampTheater`** now **`finish`es every** **`BellumBountyCampChapter*`** task that is still marked started so stale **`Task:start`** “already started” state cannot block a new trial. **`go_to_theater.lua`** logs when **`addWaypoint`** returns nil or ghost is nil.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/screenplays/quest_tasks/go_to_theater.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; restart **`core3`**. If the pin still never appears, confirm the client shows **Quest/Mission** waypoints and check server log for **`getSpawnArea`** / **`GoToTheater:taskStart`** errors (camp placement can still fail on bad terrain).

### 2026-04-06 — Spynet operative: re-issue waypoint when Task state desyncs; rebuild camp from operative

- **Summary:** **`restoreSpynetBountyCampQuestWaypoint`** previously required **`Task:hasTaskStarted`**. If that flag desynced while the **theater object** still existed, the operative’s **“Remind me how the waypoint works”** path could not place a pin. **`resolveSpynetBountyCampTheaterFromTheaterId`** now finds the camp via **`theaterID`** data like **`GoToTheater:getTheaterObject`**. **`refreshSpynetTrialSupportFromOperative`** (operative convo) calls **`restartSpynetBountyCampTrialFromOperative`** when restore still fails: **`forceTeardownSpynetBountyCampTheaters`** runs **`GoToTheater:taskFinish`** for all three chapter tables + clears **`:taskStarted:`** keys, then **`beginPrivateContract`** places a fresh camp and waypoint.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; restart **`core3`**. Rebuild requires **Foundling helmet**, **solo**, and valid terrain for **`getSpawnArea`** (same rules as first accept).

### 2026-04-06 — Mando Way armory: chapter gift weapons + recruiter schematics (hidden certs)

- **Summary:** Added three **high-DPS** Mandalorian weapons gated by **hidden certification skills** granted on **chapter trial completion**: **Initiate** → Geo-style blaster pistol, **Hunter** → Nym slugthrower-style carbine, **Verd’ika** → light lightning cannon. Each chapter grants the **cert + gift weapon** in **`applyChapterAdvanceAfterTrial`**. The **Mandalorian Recruiter** sells matching **loot schematics** (cash, **weaponsmith master** to learn) after the same chapter flag is set, for crafted rerolls. Recruiter access requires **Foundling arc complete** and **Novice BH** (same bar as the Spynet gate).
- **Files:** `bin/scripts/skills/bellum/mando_armory_certs.lua`, `bin/scripts/skills/serverobjects.lua`, `bin/scripts/object/weapon/ranged/pistol/pistol_mando_way_geo_blaster.lua`, `bin/scripts/object/weapon/ranged/carbine/carbine_mando_way_slugthrower.lua`, `bin/scripts/object/weapon/ranged/rifle/rifle_mando_way_lightning.lua`, `bin/scripts/object/weapon/ranged/pistol/objects.lua`, `bin/scripts/object/weapon/ranged/carbine/objects.lua`, `bin/scripts/object/weapon/ranged/rifle/objects.lua`, `bin/scripts/object/weapon/ranged/pistol/serverobjects.lua`, `bin/scripts/object/weapon/ranged/carbine/serverobjects.lua`, `bin/scripts/object/weapon/ranged/rifle/serverobjects.lua`, `bin/scripts/object/draft_schematic/weapon/pistol_mando_way_geo_blaster.lua`, `bin/scripts/object/draft_schematic/weapon/carbine_mando_way_slugthrower.lua`, `bin/scripts/object/draft_schematic/weapon/rifle_mando_way_lightning.lua`, `bin/scripts/object/draft_schematic/weapon/objects.lua`, `bin/scripts/object/draft_schematic/weapon/serverobjects.lua`, `bin/scripts/object/tangible/loot/loot_schematic/mando_way_geo_blaster_schematic.lua`, `bin/scripts/object/tangible/loot/loot_schematic/mando_way_slugthrower_schematic.lua`, `bin/scripts/object/tangible/loot/loot_schematic/mando_way_lightning_schematic.lua`, `bin/scripts/object/tangible/loot/loot_schematic/serverobjects.lua`, `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/mobile/conversations/bellum/mando_trialmaster_conv.lua`, `bin/scripts/screenplays/bellum/convos/mando_trialmaster_conv_handler.lua`, `bellumgero_change_log.md`
- **Notes:** **Certification** is enforced via **`certificationsRequired`** and skills **`mando_way_cert_*`** (commands **`cert_mando_way_geo_blaster`**, **`cert_mando_way_slugthrower_carbine`**, **`cert_mando_way_lightning_cannon`**). This does **not** check that Mandalorian **armor** is equipped; a stricter armor-only rule would need **C++ equip validation** or another mechanism. **Client TRE** may need aliases or rows for new **`shared_*mando_way*.iff`** template strings and new **object .iff** paths if the stock client does not already resolve them (same pattern as other custom Bellum objects). Restart **`core3`**.

### 2026-04-13 — Spynet: reset terminal gate after trial; mark mesh; no stale 5/5 re-trial

- **Summary:** **`applyChapterAdvanceAfterTrial`** now **zeros** **`bhTerminalCount`**, **`needsCustomContract`**, and **`countingEnabled`**, then for **`chNew < 4`** calls **`startChapterGate`** + **`startGateProgressPoll`** so the next rank requires a **new 0/5 BH terminal cycle** (fixes operative **`unlockPrivateTrialGateIfEligible`** re-firing on stale **5/5**). Removed post-trial **`grantPurpleOperativeReturnWaypoint`** (purple only when **5/5**). **`bellum_bounty_mark`** uses **`dressed_criminal_smuggler_human_male_01.iff`** instead of the BH trainer mesh for more reliable death/knockdown client animation.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/mobile/bellum/bellum_bounty_mark.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; restart **`core3`**. **`ArrayIndexOutOfBoundsException` in combat** at mark death is separate; redeploy **`LuaObject` `get*At`** hardening if not already live.

### 2026-04-13 — Spynet: fix `beginPrivateContract` nil `todayCount` after daily-cap removal

- **Summary:** **`beginPrivateContract`** success log still used **`todayCount + 1`** (variable removed with **`privateContractsToday`**). Removed **`contractsToday`** from the log line to avoid **`attempt to perform arithmetic on a nil value`** when accepting the private trial.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; restart **`core3`**.

### 2026-04-12 — Mando Way: BH skill gates per chapter, beskar tune removed, Ch5 Mandalorian title via Jabba Themepark

- **Summary:** Removed the beskar tune system entirely (no more post-trial armor stat bumps). Each chapter 1 through 4 now requires a specific Bounty Hunter specialization column maxed before the Spynet gate opens: Ch1 requires Bounty Pistol Specialization IV, Ch2 requires Bounty Carbine Specialization IV, Ch3 requires Light Lightning Cannon Specialization IV, Ch4 requires Investigation IV and Master Bounty Hunter. Players who do not meet the gate get a clear system message naming the exact skill and trainer. Ch4 reward simplified to the Clanbound 5-piece set only (no prior-tier wardrobe dump; belt, bracers, and biceps removed from the grant). Added Chapter 5 "Mandalorian": after earning Clanbound the Recruiter sends the player to complete Jabba's Themepark (badge 105). On return with the badge the Recruiter grants the Mandalorian title and badge (index 145). New `mando_title_mandalorian` title skill registered.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/screenplays/bellum/convos/mando_trialmaster_conv_handler.lua`, `bin/scripts/skills/bellum/mando_titles.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; restart **`core3`**. Badge ID 145 (`bdg_mando_mandalorian`) requires a matching row in the client TRE `badge_map.iff` and `badge_n`/`badge_d` string files before it will display correctly. Title `mando_title_mandalorian` requires a `skl_t.stf` entry in the client TRE or the nameplate will show the raw skill key.

### 2026-04-06 — Mando Way player text: remove Unicode dashes (Spynet gate comma, plain ASCII)

- **Summary:** Replaced Unicode em dashes in **`mando_way_of_life.lua`** and **operative convo** with **commas / periods / semicolons** in player-visible strings so clients do not garble punctuation (e.g. “1/3”). **Spynet gate** lines now use **`Spynet gate, Phase N:`**. Status chapter line uses **parentheses** and plain **1 through 4** wording; **!mando** tips avoid hyphen before “no slash”.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/mobile/conversations/bellum/mando_spynet_operative_conv.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; restart **`core3`**.

### 2026-04-06 — Mando status: !mando Say alias, Trialmaster convo, clarify slash vs spatial

- **Summary:** **`ChatManagerImplementation`** also treats **`!mando`** / **`!mandostatus`** like **`!foundling`** (spatial Say). **`sendFoundlingStatusReportToPlayer`** tips explain that **`/foundling` fails on stock clients** (slash is rejected locally) and that **`/mandoFoundlingAdmin`** needs a **client command_table** entry. **Trialmaster** (`mando_trialmaster_conv.lua` / handler): **`mando_way_status`** screen + options on **`arc_complete_no_bh`**, **`chapter_gate_ready`**, **`clanbound`** so players can get the same report **without** chat tricks.
- **Files:** `src/server/chat/ChatManagerImplementation.cpp`, `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/mobile/conversations/bellum/mando_trialmaster_conv.lua`, `bin/scripts/screenplays/bellum/convos/mando_trialmaster_conv_handler.lua`, `bellumgero_change_log.md`
- **Notes:** **Rebuild core3** for the C++ change; Lua reload or restart for convo.

### 2026-04-06 — Spynet: remove private-contract daily cap; !foundling shows chapter + advance hints

- **Summary:** Removed **`PRIVATE_CONTRACT_DAILY_CAP`**, **`resetDailyCapIfNeeded`**, the **`beginPrivateContract`** block that blocked after N starts/day, and the per-accept **`privateContractsToday`** increment. Dropped unused operative convo screen **`daily_cap`**. After the Foundling arc, **`sendFoundlingStatusReportToPlayer`** (`!foundling` / **`!foundlingstatus`**) now prints **stored story chapter** (0–4 + rank name), **5/5 terminal progress**, the same **Phase 0–3** line as gate reminders, and short **how to advance** text (plus staff note for **`/mandoFoundlingAdmin`**).
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/mobile/conversations/bellum/mando_spynet_operative_conv.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; restart **`core3`**. Legacy **`privateContractsToday`** / **`privateDailyReset`** keys may remain on old characters but are no longer read.

### 2026-04-06 — Mando Way Ch4: grant full custom armor wardrobe (all tiers + Clanbound accessories)

- **Summary:** **`chapterRewards[4]`** now grants **every** `mandalorian/custom/` tier piece (Foundling through Verd’ika, including **`initiate_gloves`**), then the full **Clanbound** set (**helmet, chest, legs, gloves, boots, belt, bracers, biceps**). Earlier chapters unchanged; Ch4 is intentionally cumulative (players may receive duplicate copies of pieces already earned).
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bellumgero_change_log.md`
- **Notes:** **`grantReward`** still uses **`giveItem`** per template; ensure inventory (or bank) space for **21** items on Ch4 completion.

### 2026-04-06 — Clanbound armor: full resists, **`vulnerability = NONE`**

- **Summary:** **HEAVY** Clanbound kit (**helmet, chest, legs, gloves, boots**): **`electricity = 65`** (was 0) so it matches **`cold`** and the other **65** rows; **`stun = 10`**, **`lightSaber = 10`**; **`vulnerability = NONE`** (no cold/elec/stun/saber holes). **LIGHT** accessories (**bracers, biceps**): **`cold`** and **`electricity`** set to **58** (aligned with kinetic/energy/heat/acid), **`stun`** / **`lightSaber`** to **10**, **`vulnerability = NONE`**.
- **Files:** `bin/scripts/object/tangible/wearables/armor/mandalorian/custom/clanbound_helmet.lua`, `clanbound_chest.lua`, `clanbound_legs.lua`, `clanbound_gloves.lua`, `clanbound_shoes.lua`, `clanbound_bracer_l.lua`, `clanbound_bracer_r.lua`, `clanbound_bicep_l.lua`, `clanbound_bicep_r.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; restart **`core3`**. Uses the same **`NONE`** sentinel as other armor scripts (e.g. Ubese) for an empty vulnerability bitmask.

### 2026-04-06 — Mando Way armor: match design table (cumulative kits, 25–65% resists, LIGHT/MED/HEAVY)

- **Summary:** **`chapterRewards`** now matches the tier table: **Ch0** Foundling helm only; **Ch1** Initiate helm+chest; **Ch2** Hunter helm+chest+legs; **Ch3** Verd’ika helm+chest+legs+gloves; **Ch4** Clanbound helm+chest+legs+gloves+boots (no belt/biceps/bracers in the grant). Resist **steps** use template values **25 / 35 / 45 / 55 / 65** on the listed families (cold remains vulnerability); **rating** is **LIGHT** through Hunter, **MEDIUM** for Verd’ika, **HEAVY** for Clanbound. New templates: **`hunter_legs`**, **`verdika_chest`**, **`verdika_gloves`**, **`clanbound_chest`**, **`clanbound_legs`**, **`clanbound_gloves`**. Existing tier Lua files retuned; **`initiate_gloves`** left as legacy Initiate-tier stats only.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/object/tangible/wearables/armor/mandalorian/serverobjects.lua`, `bin/scripts/object/tangible/wearables/armor/mandalorian/custom/*.lua` (foundling/initiate/hunter/verdika/clanbound pieces listed above), `bellumgero_change_log.md`
- **Notes:** Lua + object scripts; restart **`core3`**. Client TRE must ship new **`.iff`** paths for added templates.

### 2026-04-06 — Mando Way: 60s camp delay, deferred chapter rewards, tiered helm + armor grants

- **Summary:** **`SPYNET_BOUNTY_CAMP_FINISH_DELAY_MS`** is **60000** (one minute). For **bounty-camp** trials, **chapter advance, armor, loot, title, badge, beskar tuning, and gate waypoints** run only after **`delayedFinishSpynetBountyCampTheater`** ( **`applyChapterAdvanceAfterTrial`** ), not on mark death. Legacy non-camp trials still finalize immediately. **`beginPrivateContract`** blocks while **`privateContract.pendingTrialFinalize`** is set. **`chapterRewards`**: Ch **1** = initiate chest + initiate helmet; **2** = gloves + hunter helmet; **3** = hunter chest + verdika helmet; **4** = verdika legs + clanbound helmet + existing clanbound accessories. New object Lua: **`initiate_chest`**, **`initiate_helmet`**, **`hunter_helmet`**, **`verdika_helmet`**, **`clanbound_helmet`** (registered in **`mandalorian/serverobjects.lua`**). Trial helmet check accepts any **`mandalorian/custom/*_helmet.iff`**. New screenplay keys: **`privateContract.pendingTrialFinalize`**, **`privateContract.postTrialChapter`** (also cleared on fail / migrate / **`consoleResetArc`**).
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/object/tangible/wearables/armor/mandalorian/serverobjects.lua`, `bin/scripts/object/tangible/wearables/armor/mandalorian/custom/initiate_chest.lua`, `.../initiate_helmet.lua`, `.../hunter_helmet.lua`, `.../verdika_helmet.lua`, `.../clanbound_helmet.lua`, `.../hunter_chest.lua`, `.../initiate_gloves.lua`, `.../verdika_legs.lua`, `bellumgero_change_log.md`
- **Notes:** Lua + object scripts; restart **`core3`**. Ensure **client TRE** defines the new **`.iff`** strings (or alias meshes) so clients resolve **`object/tangible/wearables/armor/mandalorian/custom/*_helmet.iff`** and **`initiate_chest.iff`**.

### 2026-04-06 — LuaObject get*At: rawgeti + nil defaults (no rawlen gate)

- **Summary:** **`getIntAt`** / **`getSignedIntAt`** / **`getLongAt`** / **`getBooleanAt`** / **`getStringAt`** / **`getFloatAt`** / **`getDoubleAt`** no longer gate reads on **`lua_rawlen`** (`#t`). That length can be shorter than the highest numeric key on mixed/sparse tables, so skipping **`lua_rawgeti`** could hide real values or diverge from Lua. All **`idx >= 1`** now use **`lua_rawgeti`** and treat **nil** as the type default (no **`ArrayIndexOutOfBoundsException`**). Invalid **`idx < 1`** still logs to **stderr**. **`getObjectAt`** rejects **`idx < 1`** by yielding a nil-valued **`LuaObject`** instead of indexing.
- **Files:** `utils/engine3/MMOEngine/src/engine/lua/LuaObject.cpp`, `bellumgero_change_log.md`
- **Notes:** **Rebuild `core3`** (engine / link step must pick up **`LuaObject.cpp`**). If you still see **`ArrayIndexOutOfBoundsException at 16`**, the throw is likely **not** from **`LuaObject`** (grep **`stderr`** for **`[LuaObject::`** vs full stack symbols).

### 2026-04-06 — Spynet chapter gate: phase-labeled progress and login hints

- **Summary:** **`sendChapterGateProgressFooter`** and **`formatChapterGateOperativeStatusLine`** now label the Mandalorian Spynet arc as **Phase 0** (operative / count not opened) through **Phase 3** (private trial, including yellow Quest waypoint vs purple operative pin). Phase 1 keeps the **x/5** terminal count line; Phase 2 and 3 spell out the next action. **`beginPrivateContract`** calls **`sendChapterGateProgressFooter`** after the trial start message so accepting at the operative immediately reinforces Phase 3.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; restart **`core3`**.

### 2026-04-06 — Spynet operative convo: no duplicate 5/5 progress system line

- **Summary:** **`getInitialScreen`** called **`sendChapterGateProgressFooter`** on **`trial_ready`** after **`unlockPrivateTrialGateIfEligible`**, which already ends with the same footer — two identical **"Mandalorian Operative: 1/1 | Spynet contracts: 5/5 | …"** lines. Footer is sent only when **`unlockPrivateTrialGateIfEligible`** did not transition (player was already trial-ready).
- **Files:** `bin/scripts/screenplays/bellum/convos/mando_spynet_operative_conv_handler.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; restart **`core3`**.

### 2026-04-06 — LuaObject: no throw on get*At table OOB (fixes combat Lua crash)

- **Summary:** **`LuaObject::getIntAt`** / **`getSignedIntAt`** / **`getLongAt`** / **`getBooleanAt`** / **`getStringAt`** / **`getFloatAt`** / **`getDoubleAt`** no longer throw **`ArrayIndexOutOfBoundsException`** when the Lua sequence is shorter than the requested index (e.g. index **16** vs smaller **`#`**). They **`fprintf`** to **stderr** with index and table size and return safe defaults so **`CombatQueueCommand::doCombatAction`** and other paths are not aborted by malformed Lua tables. **`DotEffect::loadDot`** and **`StateEffect::loadState`** only iterate **`defender*`** subtables when **`isValidTable()`**.
- **Files:** `utils/engine3/MMOEngine/src/engine/lua/LuaObject.cpp`, `src/server/zone/objects/creature/commands/effect/DotEffect.h`, `src/server/zone/objects/creature/commands/effect/StateEffect.h`, `bellumgero_change_log.md`
- **Notes:** **Rebuild `core3`** (engine + server). After deploy, grep **stderr** / **`core3.log`** for **`[LuaObject::`** to find broken Lua data (often **`dotEffects`** / modifier arrays). Root data should still be fixed when identified.

### 2026-04-06 — Spynet bounty camp: 1500 ms despawn delay + trial complete guard

- **Summary:** Doubled **`SPYNET_BOUNTY_CAMP_FINISH_DELAY_MS`** to **1500** so **`GoToTheater`** teardown runs later after the mark dies (less “frozen upright” corpse). **`notifyBountyMobileKilled`** now requires **`privateContractActive == 1`** before calling **`onSpynetMarkDown`** / **`completePrivateContract`**, and sets **`:campFinished` only after** that path runs so players are not soft-locked with **camp finished** but no chapter advance; inactive kills log **`logDiagPlayer`** and show an operative system line.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/screenplays/bellum/bounty_camp_theater_helpers.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; restart **`core3`**.

### 2026-04-06 — Spynet bounty camp: defer GoToTheater teardown on trial complete

- **Summary:** **`completePrivateContract`** no longer calls **`finishActiveSpynetBountyCampTheater`** synchronously when **`privateContract.useBountyCampTheater`** is set. It schedules **`delayedFinishSpynetBountyCampTheater`** after **`SPYNET_BOUNTY_CAMP_FINISH_DELAY_MS`** so the mark’s death / **`OBJECTDESTRUCTION`** path can finish before **`GoToTheater:taskFinish`** despawns camp mobiles (reduces upright 0-HAM client glitch). **`privateContract.pendingCampTeardown`** gates the delayed run; **`beginPrivateContract`**, **`failPrivateContract`**, **`migrateLegacy`**, and **`consoleResetArc`** clear it so a new trial or reset does not run a stale teardown.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; restart **`core3`**. Tune **`SPYNET_BOUNTY_CAMP_FINISH_DELAY_MS`** if needed (now **1500** ms; see follow-up entry above).

### 2026-04-06 — Bounty terminal: optional contract tier menu (like mission direction)

- **Summary:** Bounty hunter terminals gain radial **Choose Bounty Contract Tier** (id **115**), opening Lua **`bounty_contract_tier`** (Sui list). Players persist **`bounty_contract_tier` / `tierChoice`** (`auto`, `1`–`4`): Automatic = legacy skill-based highest tier; fixed tiers map to mission levels **1 / 2 / 3** with gates **Novice / Investigation I / III**; **`4`** uses the same Tier **3** mission pool but requires **Investigation IV**. **`randomizeGenericBountyMission`** reads the preference and falls back to automatic if skills no longer match.
- **Files:** `src/server/zone/objects/tangible/terminal/mission/MissionTerminalImplementation.cpp`, `src/server/zone/managers/mission/MissionManagerImplementation.cpp`, `bin/scripts/screenplays/tools/bounty_contract_tier.lua`, `bin/scripts/screenplays/screenplays.lua`, `bellumgero_change_log.md`
- **Notes:** **Rebuild `core3`** and **restart** (C++ + Lua). **Investigation II** does not change Core3 bounty tier math today; Tier 2 still means Investigation **I** as before. **Mando Spynet 5/5** does not read **`tierChoice`**; it still counts **`BOUNTY`** completions with non-empty NPC **`TargetOptionalTemplate`** while **`countingEnabled`**. UI copy + **`startChapterGate`** text clarify that.

### 2026-04-06 — Mando: beskar tune step count + waypoint failure logs

- **Summary:** **`tryApplyArmorBeskarTune`** returns the **C++ apply step count** (not just boolean); **`applyBeskarTuneAfterTrial`** logs **`piecesTuned`** and **`totalC++ApplySteps`**. **`completePrivateContract`** logs when gate or purple waypoint grants fail. Comment on **`logDiagPlayer`** (delegate only) and on waypoints vs theater.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; restart **`core3`**.

### 2026-04-06 — Bounty tier 4, beskar tune, logging, trial waypoints

- **Summary:** **(1)** **`tierChoice == "4"`** sets **`eliteInvestigationListing`**: same mission level 3 pool as tier 3, but **+10** (cap **50**) to the Jedi / player-bounty roll **`compareValue`** so elite listing is distinct. **(2)** **`logDiagPlayer`** delegates to **`logDiag`** (single printf/logLua path). **(3)** **`applyBellumBeskarTune`** returns **int** count of applied changes; **`applyArmorBeskarTune`** Lua pushes that count; **`tryApplyArmorBeskarTune`** treats **>0** as success so all-vulnerable pieces do not count as tuned. **(4)** **`grantChapterGateBriefingWaypoints`** / **`grantPurpleOperativeReturnWaypoint`** return **boolean**; **`completePrivateContract`** warns if pins fail. Beskar player message and diag log clarify vulnerable skips.
- **Files:** `src/server/zone/managers/mission/MissionManagerImplementation.cpp`, `src/server/zone/objects/tangible/wearables/ArmorObject.idl`, `ArmorObjectImplementation.cpp`, `LuaTangibleObject.cpp`, `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/screenplays/tools/bounty_contract_tier.lua`, `bellumgero_change_log.md`
- **Notes:** **Full C++ rebuild** (IDL regen). Lua-only callers of gate helpers ignore return values safely.

### 2026-04-06 — Spynet operative: sync 5/5 gate on convo (fix stale gate_in_progress)

- **Summary:** After the 5th NPC bounty, **C++** updates **`bhTerminalCount`** and shows **5/5** immediately, but **`needsCustomContract`** was only set by **`gateProgressEvent`** (15s poll). Until that ran, **`countingEnabled`** stayed **1**, so **`MandoSpynetOperativeConvoHandler`** kept returning **`gate_in_progress`** (keep clearing bounties). Added **`unlockPrivateTrialGateIfEligible`** (shared with **`gateProgressEvent`**) and call it when opening the operative convo so flags, purple waypoint, and **`trial_ready`** match **5/5**.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/screenplays/bellum/convos/mando_spynet_operative_conv_handler.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; restart **`core3`**.

### 2026-04-06 — Bounty NPC: tier 2 no longer simulates cross-map walk

- **Summary:** **`BountyHunterTargetTask`** only sets **`move=true`** for **mission level 3** (hard). **Tier 2** (standard) now keeps the simulated target at **mission end** coordinates like tier 1, so the datapad waypoint and spawn **256 m** check align. Previously tier 2 walked toward a random planet point (often thousands of meters away), matching logs where **`curPos`** drifted toward **`dest`** while the player stood at the waypoint.
- **Files:** `src/server/zone/objects/mission/bountyhunter/events/BountyHunterTargetTask.h`, `bellumgero_change_log.md`
- **Notes:** **Rebuild `core3`**. Tier 3 behavior unchanged (starport / random planet simulation).

### 2026-04-06 — MandoWayOfLife: default Spynet debug verbose off

- **Summary:** **`SPYNET_BOUNTY_DEBUG_VERBOSE`** defaults to **`false`** so production shards are not flooded with **`[SpynetDebug]`** / contract-check heartbeat lines; set **`true`** locally when diagnosing Spynet / bounty camp.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; restart **`core3`**.

### 2026-04-06 — bounty_contract_tier: ASCII-friendly list labels (no em dash)

- **Summary:** Replaced em dashes (—) in Sui list row labels and prompt with periods and colons so clients that lack that glyph do not show empty boxes.
- **Files:** `bin/scripts/screenplays/tools/bounty_contract_tier.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; restart **`core3`** or reload screenplays as you usually do.

### 2026-04-06 — Mando Spynet: clarify tier menu vs 5/5 gate (copy + comment)

- **Summary:** **`bounty_contract_tier`** Sui prompt and **`startChapterGate`** system message state that contract tier only changes terminal offers, not Spynet **x/5**. C++ comment on **`tierChoice`** block points maintainers at **`MissionObjectiveImplementation`** counting rules.
- **Files:** `bin/scripts/screenplays/tools/bounty_contract_tier.lua`, `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `src/server/zone/managers/mission/MissionManagerImplementation.cpp`, `bellumgero_change_log.md`

### 2026-04-06 — Config: enable BountyNpcSpawnDebug for local repro

- **Summary:** Set **`MissionManager.BountyNpcSpawnDebug = true`** in **`bin/conf/config.lua`** so rebuilt **`core3`** emits **`[BountyNpcSpawnDebug]`** logs without a **`config-local`** override. Set back to **`false`** on shards that should not log NPC bounty ticks.
- **Files:** `bin/conf/config.lua`, `bellumgero_change_log.md`

### 2026-04-06 — Debug: NPC bounty spawn tracing ([BountyNpcSpawnDebug])

- **Summary:** Optional verbose server logging for **terminal NPC bounties**: each **`BountyHunterTargetTask`** tick logs planet match, distance to simulated target, nav adjust pushing past 256 m, and **`spawnTarget`** logs template, X/Y/Z, spawn success (**oid**, **inQuadTree**, world pos) or null. Toggle **`Core3.MissionManager.BountyNpcSpawnDebug`** in **`bin/conf/config.lua`** (default **false**).
- **Files:** `src/server/zone/objects/mission/bountyhunter/events/BountyHunterTargetTask.h`, `src/server/zone/objects/mission/BountyMissionObjectiveImplementation.cpp`, `bin/conf/config.lua`, `bellumgero_change_log.md`
- **Notes:** **Rebuild `core3`**. Grep logs for **`[BountyNpcSpawnDebug]`**. Hot path checks config each tick (~10 s per active NPC bounty) when enabled.

### 2026-04-06 — Spynet: tell players bounty camp pin is on datapad Quest tab

- **Summary:** GoToTheater adds **`WAYPOINTQUESTTASK`** pins; they show under the client’s **Quest** (mission) waypoint UI, not the main **Waypoints** list — players saw only the operative/house pins and thought the trial had no mark. Updated **`beginPrivateContract`**, **refresh** (bounty mode), **migrate** system text, and **operative convo** screens to say **Quest tab** explicitly.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/mobile/conversations/bellum/mando_spynet_operative_conv.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; **restart `core3`**. Client may label the tab slightly differently; core idea is **task / mission waypoint**.

### 2026-04-06 — Spynet: verbose debug channel ([SpynetDebug])

- **Summary:** Added **`SPYNET_BOUNTY_DEBUG_VERBOSE`** (defaults **`false`** in **`MandoWayOfLife`**; set **`true`** for dev diagnosis) and **`logSpynetDebug`**. Extra lines on **begin/fail/complete private contract**, **refresh waypoint**, **migrate legacy**, **respawn skip**, **contract check (camp heartbeat + which chapter task is started)**, **finishActive camp**, **bounty helper** (mob presentation, observers, kills, mark-down), and **GoToTheater** hooks **`onTheaterCreated` / `onEnteredActiveArea`** on all three chapter camps. **`applyBountyMobPresentation`** now takes **`pPlayer`** for logging.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/screenplays/bellum/bounty_camp_theater_helpers.lua`, `bin/scripts/screenplays/bellum/bounty_camp_chapter1_theater.lua`, `bin/scripts/screenplays/bellum/bounty_camp_chapter2_theater.lua`, `bin/scripts/screenplays/bellum/bounty_camp_chapter3_theater.lua`, `bellumgero_change_log.md`
- **Notes:** **Restart `core3`**. Filter: **`[SpynetDebug]`**. Camp heartbeat logs every **`CONTRACT_CHECK_INTERVAL_MS`** while trial active (noisy).

### 2026-04-06 — Spynet bounty camp: push theater spawn ring out of cities

- **Summary:** **`GoToTheater`** picks the camp from **`getSpawnArea`** around the player at trial accept; **750–1400 m** often stayed inside Corellian urban **no-spawn** bands. **`minimumDistance` / `maximumDistance`** raised on **`BellumBountyCampChapter1/2/3Theater`** (**1600/3200**, **1700/3400**, **1800/3600**) so the yellow waypoint lands farther in the wild.
- **Files:** `bin/scripts/screenplays/bellum/bounty_camp_chapter1_theater.lua`, `bin/scripts/screenplays/bellum/bounty_camp_chapter2_theater.lua`, `bin/scripts/screenplays/bellum/bounty_camp_chapter3_theater.lua`, `bellumgero_change_log.md`
- **Notes:** **Restart `core3`**. Accepting the trial **in town** still uses your position as the ring center — for a shorter ride, step outside the city first.

### 2026-04-06 — Spynet: auto-migrate legacy private trial to bounty camp theater

- **Summary:** Characters still on **pre-theater** Spynet trials (**`privateContract.useBountyCampTheater=0`**, stale **`contractTargetId`**, **`spawnRelinkDone`** blocking **`tryRespawnPrivateContractTargetOnce`**) were stuck on **orange anchor** waypoints. **`migrateLegacyPrivateContractToBountyCampTheater`** clears the legacy OID, resets relink, removes the orange pin, starts **`BellumBountyCampChapter1/2/3Theater`** (same tier rule as **`beginPrivateContract`**), and sets **`useBountyCampTheater=1`**. Invoked from **`onPlayerLoggedIn`** (arc complete branch), **`refreshSpynetTrialSupportFromOperative`**, and **`refreshPrivateContractTargetWaypointFromActiveTarget`** when **respawn after nil resolve** fails. Does **not** increment **`privateContractsToday`**.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; **restart `core3`**. Live legacy **`mando_contract_target`** is **destroyed** when migrating.

### 2026-04-06 — Spynet private trial: remove coordinate disk; Mellichae-style bounty camp; lower CL

- **Summary:** **Private trial** no longer grants or uses the **coordinate disk** (legacy disks stripped on fail/complete/reset; old item radial shows a retire message). **`beginPrivateContract`** starts **`BellumBountyCampChapter1/2/3Theater:start`** (tier **`min(3, chapter+1)`**) so the player gets the **yellow GoToTheater waypoint** only; camp spawns on approach; **mark kill** calls **`onSpynetMarkDown` → `MandoWayOfLife:completePrivateContract`**. **`contractCheckEvent`** is a heartbeat in bounty-camp mode. Operative option **Remind me…** → **`refreshSpynetTrialSupportFromOperative`**. **`failPrivateContract` / `consoleResetArc`** call **`finishActiveSpynetBountyCampTheater`**. Reduced combat profile on **`mando_contract_target`**, **`bellum_bounty_mark`**, **`bellum_bounty_henchman`**, and **chapter theater `markLevel`/`henchLevel`**.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/screenplays/bellum/bounty_camp_theater_helpers.lua`, `bin/scripts/screenplays/bellum/bounty_camp_chapter1_theater.lua`, `bin/scripts/screenplays/bellum/bounty_camp_chapter2_theater.lua`, `bin/scripts/screenplays/bellum/bounty_camp_chapter3_theater.lua`, `bin/scripts/screenplays/bellum/mando_spynet_contract_waypoint_disk_menu.lua`, `bin/scripts/screenplays/bellum/convos/mando_spynet_operative_conv_handler.lua`, `bin/scripts/mobile/conversations/bellum/mando_spynet_operative_conv.lua`, `bin/scripts/object/tangible/mission/mando_spynet_contract_waypoint_disk.lua`, `bin/scripts/mobile/bellum/mando_contract_target.lua`, `bin/scripts/mobile/bellum/bellum_bounty_mark.lua`, `bin/scripts/mobile/bellum/bellum_bounty_henchman.lua`, `bellumgero_change_log.md`
- **Notes:** **Restart `core3`**. First-time convo cache may need relog after **`trial_refresh_hint`** replaces **`trial_reissue_disk`**.

### 2026-04-06 — Spynet trial: complete when refresh sees dead mark; reissue disk if trial ended

- **Summary:** **`refreshPrivateContractTargetWaypointFromActiveTarget`** used to **skip** when **`contractTargetId`** resolved but **`isDead()`**, leaving **`privateContractActive=1`** until the next **`contractCheckEvent`** and still granting a **new disk** on operative reissue. It now calls **`completePrivateContract`** in that case. **`reissueSpynetContractWaypointDiskFromOperative`** and **`useSpynetContractWaypointDiskFromItem`** check **`privateContractActive`** after refresh and skip disk / upload with a clear system message if the trial was closed.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; **restart `core3`**.

### 2026-04-06 — Spynet bounty camps (Mellichae-style theater, simplified)

- **Summary:** Added **three** **`GoToTheater`** screenplays (**Chapter 1–3**) inspired by **`MellichaeOutroTheater`**: same rough **camp decor** (no **`power_shrine` / `power_shrine_red`**). **No** healing pulses or crystal logic. **Two** creature templates (**`bellum_bounty_mark`**, **`bellum_bounty_henchman`**) with **empty `lootGroups`**; **credits** are granted on kill to the **player** who got the killing blow. **Chapter 1** = mark + 2 associates; **2** = +1 associate; **3** = +2 associates, higher levels/credits. Comments on **Ch 2–3** files note where to add green/red shrines later. **Not** wired into **`mando_way_of_life`** yet — start with **`BellumBountyCampChapter1Theater:start(pPlayer)`** (etc.) from a convo or trial step when ready.
- **Files:** `bin/scripts/screenplays/bellum/bounty_camp_theater_helpers.lua`, `bin/scripts/screenplays/bellum/bounty_camp_chapter1_theater.lua`, `bin/scripts/screenplays/bellum/bounty_camp_chapter2_theater.lua`, `bin/scripts/screenplays/bellum/bounty_camp_chapter3_theater.lua`, `bin/scripts/mobile/bellum/bellum_bounty_mark.lua`, `bin/scripts/mobile/bellum/bellum_bounty_henchman.lua`, `bin/scripts/mobile/serverobjects.lua`, `bin/scripts/screenplays/screenplays.lua`, `bellumgero_change_log.md`
- **Notes:** **Restart `core3`**. If **`require("screenplays.bellum.bounty_camp_theater_helpers")`** fails on your fork, fix Lua path or inline the helper into one file.

### 2026-04-09 — Dr. Kaelen Varr: fix convo handler load in CreatureTemplateManager Lua

- **Summary:** **`dr_kaelen_varr_convo_handler.lua`** was **`includeFile`**’d from **`mobile/conversations.lua`**, which runs in the **CreatureTemplateManager** Lua VM **before** screenplays. That VM never defines **`conv_handler`**, so line 1 **`conv_handler:new {}`** errored. The handler is already loaded by **`screenplays/screenplays.lua`** (`endor/conversations/dr_kaelen_varr_convo_handler.lua`) in **DirectorManager** Lua where conversations run. Removed the mobile include and deleted the duplicate **`bin/scripts/mobile/conversations/endor/dr_kaelen_varr_convo_handler.lua`**; **`dr_kaelen_varr_conv.lua`** still registers the template during mobile load.
- **Files:** `bin/scripts/mobile/conversations.lua`, `bellumgero_change_log.md` (removed `bin/scripts/mobile/conversations/endor/dr_kaelen_varr_convo_handler.lua`)
- **Notes:** **Restart `core3`**. No change to quest logic; only load order / duplicate file cleanup.

### 2026-04-09 — Mando Spynet: private trial waypoint anchor when getSceneObject(targetId) is nil

- **Summary:** DEBUG logs showed **`refreshPrivateContractTargetWaypoint`** bailing because **`getSceneObject(contractTargetId)`** returned **nil** while the trial was still active (object not in **`ServerCore::getZoneServer()`** map on this process, unload timing, or similar). **`beginPrivateContract`** now persists **`privateContract.anchorPlanet`** and spawn **X/Z/Y** strings; **`refreshPrivateContractTargetWaypointFromActiveTarget`** uses that **anchor** to re-place the **orange mark** when the live NPC cannot be resolved. Anchor cleared on **fail/complete** and **`consoleResetArc`** (empty strings, not **`0`**). **Trial completion** still uses **`getSceneObject`** when the target resolves; if it never resolves, **`contractCheckEvent`** may eventually **fail** the trial after the miss cap.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; **restart `core3`**. Mid-trial characters **without** a stored anchor need to **start the trial again** (or reissue after a fresh **`beginPrivateContract`**) to populate anchor data. Watch for log **`ANCHOR FALLBACK`**.

### 2026-04-09 — Mando Spynet: fallback trial completion + TRIAL console lines

- **Summary:** **`resolvePrivateContractTargetById`** tries **`getSceneObject`** then **`getCreatureObject`** (same map today; harmless on unified **`core3`**). **`contractCheckEvent`** logs every tick with **`TRIAL contractCheckEvent:`** (always **`printf`** + **`logLua(1)`** via **`logDiagPlayer`**). If the OID stays unresolvable but the player remains within **`PRIVATE_CONTRACT_FALLBACK_RADIUS_SQ`** (192 m, world **X/Y**) of the stored anchor for **`PRIVATE_CONTRACT_FALLBACK_COMPLETE_NIL_TICKS`** ticks (default **9** × 10 s), the trial **completes** as **`COMPLETE (fallback near anchor + unresolved streak)`** so kills that despawn the corpse still finish the gate. Leaving the anchor wedge resets **`privateContract.fallbackNilStreak`**. **`logDiagPlayer`** now inlines **`printf`** so player lines always hit the terminal even if **`logDiag`** call patterns change.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; **restart `core3`**. Tune **`PRIVATE_CONTRACT_FALLBACK_RADIUS_SQ`** / **`PRIVATE_CONTRACT_FALLBACK_COMPLETE_NIL_TICKS`** on the screenplay table if the heuristic is too loose or tight. Grep **`TRIAL contractCheckEvent`**.

### 2026-04-09 — Mando Spynet: heal missing privateContract anchor (legacy trials)

- **Summary:** Characters mid trial with **`privateContractActive`** and **`contractTargetId`** but **no** **`privateContract.anchorPlanet`** (started before anchor save) hit **`resolve nil, no anchor`** on reissue/login. **`ensurePrivateContractSpawnAnchorForLegacyTrial`** stamps anchor at **player X + 200**, same **Z/Y**, same planet (**mirrors `beginPrivateContract`**). Called from **`refreshPrivateContractTargetWaypointFromActiveTarget`** and **`contractCheckEvent`** so waypoint fallback and proximity completion can run.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; **restart `core3`**. Log line **`healPrivateContractAnchor`**. If the pin is wrong, abandon/finish and **begin the trial again** for a precise spawn.

### 2026-04-09 — Mando Spynet: respawn contract NPC at anchor when OID does not resolve

- **Summary:** Orange waypoint alone left **no `mando_contract_target` in the world** when **`getSceneObject`/`getCreatureObject`** failed. **`tryRespawnPrivateContractTargetOnce`** runs **`spawnMobile`** at the **stored anchor** (navmesh may adjust), writes new **`contractTargetId`**, refreshes anchor from the mob’s world position, sets **`privateContract.spawnRelinkDone=1`** (one auto-respawn per trial). Invoked from **`refreshPrivateContractTargetWaypointFromActiveTarget`** (reissue/login/disk) and once from **`contractCheckEvent`** if still unresolved. Cleared on **`beginPrivateContract`**, **fail/complete**, **`consoleResetArc`**. Still **one** trial NPC by design (not a group).
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; **restart `core3`**. Logs **`tryRespawnPrivateContractTargetOnce OK`** / **`FAILED`**. If spawn fails (cliff/building), move to open ground or restart trial.

### 2026-04-09 — Loot: drop missing damage_type_electricity_schematic include

- **Summary:** **`items.lua`** included **`items/loot_schematic/damage_type_electricity_schematic.lua`**, but that file was never added (and no loot groups reference a **`damage_type_electricity_schematic`** template). Electricity weapon tuning uses **`damage_type_electricity_powerup`** in **`damage_type_powerups`** instead. Removed the dead **`includeFile`** so LootManager startup no longer errors.
- **Files:** `bin/scripts/loot/items.lua`, `bellumgero_change_log.md`
- **Notes:** **Restart `core3`**. If you later add a real schematic IFF + object template, re-add a matching loot item Lua and this include.

### 2026-04-07 — Mando Spynet: coordinate disk for private trial waypoint

- **Summary:** Added **`object/tangible/mission/mando_spynet_contract_waypoint_disk.iff`** (mission datadisk appearance) with Lua **`MandoSpynetContractWaypointDiskMenuComponent`**: radial **Upload Coordinates** calls **`MandoWayOfLife:useSpynetContractWaypointDiskFromItem`**, which re-places the **orange contract mark** on the datapad from the live **`mando_contract_target`**. **`beginPrivateContract`** grants one disk (strips duplicates); **`failPrivateContract` / `completePrivateContract` / `consoleResetArc`** remove disks. Operative **`trial_active`** offers **I need a new coordinate disk** → **`trial_reissue_disk`** → **`reissueSpynetContractWaypointDiskFromOperative`** (refreshes waypoint + new disk).
- **Files:** `bin/scripts/object/tangible/mission/mando_spynet_contract_waypoint_disk.lua`, `bin/scripts/object/tangible/mission/serverobjects.lua`, `bin/scripts/screenplays/bellum/mando_spynet_contract_waypoint_disk_menu.lua`, `bin/scripts/screenplays/screenplays.lua`, `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/mobile/conversations/bellum/mando_spynet_operative_conv.lua`, `bin/scripts/screenplays/bellum/convos/mando_spynet_operative_conv_handler.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; **restart zones**. Server template inherits **`shared_mission_datadisk`** client appearance. If a custom client TRE is required for the new IFF path, add it to your pack; many setups resolve via server object template alone.

### 2026-04-07 — Mando Spynet: disk + waypoint grant hardening

- **Summary:** **`grantPrivateContractMarkWaypointAt`** now treats **`addWaypoint`** return **0** or **nil** as failure (matches **`RangersPath`** pattern), logs diagnostics, and tells the player to use the coordinate disk. **`grantSpynetContractWaypointDisk`** falls back to **`mission_datadisk.iff`** with **custom name** + **`MandoSpynetContractWaypointDiskMenuComponent`** if the custom **`mando_spynet_contract_waypoint_disk`** template cannot be created; cleanup uses **`isSpynetContractDiskObject`** so only tagged fallbacks are removed.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/screenplays/bellum/mando_spynet_contract_waypoint_disk_menu.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; **restart zones**. If you still see no disk and no pin, check server log for **`grantSpynetContractWaypointDisk FAILED`** or **`grantPrivateContractMarkWaypointAt FAILED`**.

### 2026-04-07 — Mando Spynet: trial disk first, overload giveItem, fix nil target completing trial

- **Summary:** **`beginPrivateContract`** now grants the **coordinate disk before** the datapad waypoint so waypoint failures still leave the disk + **Upload Coordinates**. **`grantSpynetContractWaypointDisk`** retries **`giveItem(..., true)`** (overload) like other Bellum rewards, and sends a clear line if the inventory slot is nil. **`grantPrivateContractMarkWaypointAt`** no longer fails silently when **ghost** is nil. **`contractCheckEvent`** no longer treats **`getSceneObject` nil** as a kill (that could strip disk/waypoint and **complete the chapter**); it reschedules and only **fails the trial** after many misses (**`privateContractTargetResolveMisses`**, cleared on success/fail/complete/`consoleResetArc`).
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; **restart `core3`** so this loads. If you still get nothing, confirm you see the final **`trial_start`** convo line and watch for **`[Spynet trial]`** system messages.

### 2026-04-07 — Mando Spynet: DEBUG printf/log lines for trial disk and waypoint

- **Summary:** Added **`DEBUG`** lines via **`logDiag` / `logDiagPlayer`** (console **`printf`** + **`logLua(1, …)`**) on **`beginPrivateContract`**, per-**`giveItem`** attempt in **`grantSpynetContractWaypointDisk`**, **`grantPrivateContractMarkWaypointAt`** entry/success, **`refreshPrivateContractTargetWaypointFromActiveTarget`** early exits + success, **`reissueSpynetContractWaypointDiskFromOperative`**, **`useSpynetContractWaypointDiskFromItem`**, throttled **`contractCheckEvent`** nil-target resolves, and **`trial_start`** handler **`beginPrivateContract`** return value.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/screenplays/bellum/convos/mando_spynet_operative_conv_handler.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; **restart `core3`**. Grep logs for **`DEBUG grantSpynet`**, **`DEBUG beginPrivateContract`**, **`DEBUG reissueSpynetDisk`**, **`DEBUG useSpynetDiskFromItem`**. Remove or gate behind a flag once the issue is found.

### 2026-04-06 — Mando Spynet: private trial datapad pin + footer hardening

- **Summary:** The private trial never created a **BH terminal mission**, so “details in your datapad” was misleading. **`beginPrivateContract`** now grants an **orange datapad waypoint** to the spawned mark (**`chapterGate.contractMarkWpId`**), sends a **system line** with planet + rough coordinates, and **login** refreshes that pin if **`privateContractActive`**. Cleared on **fail/complete** and **`consoleResetArc`**. **`sendChapterGateProgressReminder`** is wrapped in **`pcall`**; Spynet footer uses **string concat** (no `string.format` on mixed tails). Operative **`trial_start`** line updated to match.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/mobile/conversations/bellum/mando_spynet_operative_conv.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; **restart zones**. This is still **not** a mission journal entry — only waypoint + system text.

### 2026-04-06 — Mando client text: no hyphen or em dash separators

- **Summary:** Some clients box **hyphen-minus** and **em dash** in chat, waypoints, and convo. Swept **Mando Way of Life** player-facing strings to use **periods, commas, colons, pipes, and parentheses** instead (e.g. **chain code**, **Mission terminal**, **Mandalorian Operative (private trial)**). Same for **Trialmaster**, **Foundling informant**, **Spynet operative** convos and **`MissionObjectiveImplementation`** Spynet hint line.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/mobile/conversations/bellum/mando_spynet_operative_conv.lua`, `bin/scripts/mobile/conversations/bellum/mando_trialmaster_conv.lua`, `bin/scripts/screenplays/bellum/convos/mando_trialmaster_conv_handler.lua`, `bin/scripts/mobile/conversations/bellum/mando_foundling_informant_conv.lua`, `src/server/zone/objects/mission/MissionObjectiveImplementation.cpp`, `bellumgero_change_log.md`
- **Notes:** **C++ rebuild** for the `.cpp` tweak; **restart zones** for Lua. Comments and server-only log strings may still use dashes.

### 2026-04-07 — Mando Spynet: purple operative waypoint at 5/5 and after each trial

- **Summary:** Chapter-gate **blue** operative pins could go **stale** (NPC moved) and nothing re-placed a trial return marker. Added **`chapterGate.trialPurpleWpId`**: **`WAYPOINT_PURPLE`** datapad waypoint at **`chapterGateBriefingConfig`** operative coords when **Spynet hits 5/5** (`gateProgressEvent`), **after each private trial** (`completePrivateContract`), and on **login** if **`needsCustomContract`**. Cleared when opening a new Spynet count (`startChapterGate`) or **accepting** a trial (`beginPrivateContract`). **`grantChapterGateBriefingWaypoints`** gains optional **`suppressSystemMessages`** so trial/login refresh does not fake a recruiter line. Reminder/footer + operative convo copy updated for purple.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/mobile/conversations/bellum/mando_spynet_operative_conv.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; **restart zones**. Yellow **BH hub** waypoint unchanged.

### 2026-04-07 — Mando Way: Foundling helmet detection (hat slot + template path)

- **Summary:** **`hasFoundlingHelmet`** only queried **`getSlottedObject("helmet")`** and **`getObjectTemplate()`** (not a **`LuaSceneObject`** method), so players wearing the real Foundling helm in the usual **`hat`** slot always failed checks and saw **“No helm. No chain-code. No work.”** Detection now tries **`hat`** then **`helmet`** and matches **`foundling_helmet`** via **`getTemplateObjectPath()`**.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/mobile/conversations/bellum/mando_spynet_operative_conv.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; **restart zones** loading these scripts. **`hair`** slot also scanned (strict **`foundling_helmet`** path only) for rare species/slot setups.

### 2026-04-07 — Mando Spynet operative: Corellia spawn + briefing waypoint (27, 28, -4712)

- **Summary:** Moved **`mando_spynet_operative`** from **(-173, 28, -4712)** to **(27, 28, -4712)** on Corellia and aligned **`chapterGateBriefingConfig`** operative waypoint coords so recruiter/datapad markers match the NPC.
- **Files:** `bin/scripts/screenplays/static_spawns/corellia_static_spawns.lua`, `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; **restart zones** (or reload static spawns if your process supports it). If the NPC clips or floats, adjust **`operativeZ`** in both files after a quick `/getMapLocation` or similar in-world.

### 2026-04-07 — Mando Spynet: explain BH completions that do not advance 5/5

- **Summary:** Spynet **only** increments for **NPC** terminal bounties while **`countingEnabled`** is on (after the Corellia operative’s **gate_start**). Player/Jedi marks use an empty optional template and never count — completions looked “silent.” **`MissionObjectiveImplementation`** now sends a **system message** after a **Bounty** completes when the player is on the Mando chapter path but that mission **did not** get a **`bhCounted_`** stamp (Spynet not open, or player mark, or both).
- **Files:** `src/server/zone/objects/mission/MissionObjectiveImplementation.cpp`, `bellumgero_change_log.md`
- **Notes:** **C++ rebuild** required. Messages are suppressed while **`needsCustomContract`** (5/5, return to operative) or **`privateContractActive`** is set, and after **`chapter4Complete`**.

### 2026-04-06 — Mando Way: beskar armor tune after each trial gate (chapters 1–4)

- **Summary:** After each private trial completes (`completePrivateContract`, chapters **1–4**), the screenplay scans the player’s **equipped slots + shallow inventory** for Mandalorian **custom** armor (`object/.../mandalorian/custom/`) and applies stacking **kinetic / energy / blast / heat / acid** bonuses plus **max condition** via new **`ArmorObject::applyBellumBeskarTune`** and Lua **`TangibleObject:applyArmorBeskarTune`**. Non-vulnerable types only (matches existing BH-style vuln on those templates). A **beskar / Guild** congratulations system message runs before the existing rank line.
- **Files:** `src/server/zone/objects/tangible/wearables/ArmorObject.idl`, `src/server/zone/objects/tangible/wearables/ArmorObjectImplementation.cpp`, `src/server/zone/objects/tangible/LuaTangibleObject.h`, `src/server/zone/objects/tangible/LuaTangibleObject.cpp`, `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bellumgero_change_log.md`
- **Notes:** **Full C++ rebuild** required (IDL regenerates `ArmorObject` stubs). Restart zones after deploy. If `applyArmorBeskarTune` is missing on an old binary, the `pcall` in Lua fails safely and no stats change. **`applyBellumBeskarTune`** locks with **`Locker(_this.getReferenceUnsafeStaticCast())`** (not `asArmorObject()`, which is not in scope on the implementation class).

### 2026-04-05 — Mando chapter gate: Operative visit 0/1 vs 1/1 reminders

- **Summary:** Added **Mandalorian Operative (Corellia)** checklist-style system lines: **0/1** until the player opens the Spynet count with the operative, **1/1** afterward, plus a **Spynet contracts x/5** footer where relevant. Wired into recruiter gate brief + waypoint refresh, **login** (Foundling arc complete), **operative conversation** open (`gate_explain` / `gate_in_progress` / `trial_ready`), **`startChapterGate`**, **`gateProgressEvent` (5/5)**, and a **C++ → Lua** call after each counted Spynet bounty completion (`sendChapterGateProgressReminder`).
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/screenplays/bellum/convos/mando_spynet_operative_conv_handler.lua`, `src/server/zone/objects/mission/MissionObjectiveImplementation.cpp`, `bellumgero_change_log.md`
- **Notes:** **C++ rebuild** required for the bounty-completion footer callback. Lua-only paths (briefing, login, operative convo, gate events) apply after zone restart / script reload.

### 2026-04-05 — Mando chapter gate: Spynet BH progress without accept-time tag

- **Summary:** Spynet **5/5** counting only incremented when **`bhTagged_<missionId>`** was set at mission accept. Bounties accepted **before** the operative opened the count (or any accept path that skipped tagging) never got a tag, so **`MissionObjectiveImplementation::awardReward`** never sent **“Spynet contracts: x/5”** on completion. Completion now counts **NPC-mark bounties** whenever **`countingEnabled`** is on: **`MissionTypes::BOUNTY`** and **non-empty `getTargetOptionalTemplate()`** (player bounties use an empty template). **`startChapterGate`** system text notes that in-flight datapad missions can count.
- **Files:** `src/server/zone/objects/mission/MissionObjectiveImplementation.cpp`, `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bellumgero_change_log.md`
- **Notes:** Requires **C++ rebuild** and zone restart. Accept-time tagging in **`MissionManagerImplementation.cpp`** is now optional/redundant for this gate; left in place for clarity.

### 2026-04-05 — Travel: `purchaseTicket` command blocked by characterAbility (silent fail)

- **Summary:** Ground/spaceport ticket purchase is driven by the **`purchaseticket`** queue command. If **`command_tables_shared*.iff`** assigns a **`characterAbility`** the player does not have, **`ObjectControllerImplementation::activateCommand`** clears the action with **no system message**, so buying tickets appears to do nothing. **`purchaseTicket.lua`** now sets **`characterAbility = ""`** after IFF load so the command is not ability-gated (matches common SWGEmu practice of fixing this in Lua).
- **Files:** `bin/scripts/commands/purchaseTicket.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; **restart zone processes** so CommandConfigManager reloads — no C++ rebuild required for this fix. If ticket purchase still misbehaves after that, see the **next** changelog entry (C++ kiosk / range / messaging); that part needs a **rebuilt binary** to take effect. If you prefer gating (e.g. only after a tutorial skill), grant that ability via skills instead of re-adding a non-empty `characterAbility` here.

### 2026-04-05 — Travel: PurchaseTicket ignored kiosks + in-range fallback + terminal error message

- **Summary:** **`PurchaseTicketCommand`** only treated **`SceneObjectType::TRAVELTERMINAL`** as valid; many templates still expose travel kiosks as generic interactive terminals while the C++ class is **`TravelTerminal`**, so the command never saw a terminal in **`closeObjects`** and the client looked completely dead. Detection now also accepts objects whose template path contains **`terminal_travel`**, adds a **`Zone::getInRangeObjects`** fallback when close-objects are empty/stale, and null-checks **`getCloseObjects()`**. **`TravelTerminalImplementation`** now sends a **system message** when no **`PlanetTravelPoint`** resolves (previously only **`error()`** to log).
- **Files:** `src/server/zone/objects/creature/commands/PurchaseTicketCommand.h`, `src/server/zone/objects/tangible/terminal/travel/TravelTerminalImplementation.cpp`, `bellumgero_change_log.md`
- **Notes:** **Not live until you rebuild and deploy the zone/core binary** — restarting processes alone does **not** pick up C++ changes; only a new binary does. Contrast the Lua **`purchaseTicket`** entry above: a **restart** there is enough for the script override. After you ship this build, restart zones as usual. If players still see the new “could not match shuttle route” line, fix **`planet_manager.lua`** travel point positions vs actual terminal/shuttle world positions (or **`ScheduleShuttleTask`** 128 m link).

### 2026-04-05 — Mando chapter gate: recruiter briefing, Corellia waypoints, clearer Spynet copy

- **Summary:** The Mandalorian Recruiter’s **chapter gate** screen now explains the real order of operations (operative first → five **Bounty Hunter mission terminal** NPC bounties → one private trial), grants **two datapad waypoints** (operative at Corellia static spawn coords matching `mando_spynet_operative`, Tyrena BH guild reference for terminals), and sends a **system-message checklist**. Returning while mid-count or post-5/5 gets **short NPC lines** plus waypoint refresh without repeating the full brief. Spynet operative conversation strings and `startChapterGate` / `gateProgressEvent` system lines were aligned with **BOUNTY** terminal counting (C++). **`consoleResetArc`** now clears chapter-gate waypoint keys, removes those waypoints, snapshots IDs **before** zeroing screenplay data (fix), and resets **`needsCustomContract`**.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/screenplays/bellum/convos/mando_trialmaster_conv_handler.lua`, `bin/scripts/mobile/conversations/bellum/mando_trialmaster_conv.lua`, `bin/scripts/mobile/conversations/bellum/mando_spynet_operative_conv.lua`, `bellumgero_change_log.md`
- **Notes:** Lua-only; restart zones loading these scripts. Verify in-world that Tyrena guild terminals exist near the BH trainer waypoint; adjust `chapterGateBriefingConfig` if your shard places terminals elsewhere.

### 2026-04-04 — Mando Way of Life: chapter badge indices (badge_map 140–144)

- **Summary:** Set **`MandoWayOfLife.chapterBadgeIds`** for chapters **0–4** to **140–144**, matching custom **`badge_map.iff`** rows (`bdg_mando_*`) shipped in **`bg_custom1.tre`** with **`badge_n` / `badge_d`** (and title strings in **`skl_t` / `skl_n` / `skl_d`**). Chapter milestones call **`tryAwardChapterBadge`** with these indices.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`
- **Notes:** Lua-only; **restart zones** that run the screenplay. Server and client must load the same **`badge_map`** override **last** in the TRE list. Smoke-test with **`/grantBadge 140`** … **`144`** if needed.

### 2026-04-04 — Foundling: remove shared static Tatooine informant (Mos Eisley)

- **Summary:** Removed the world `mando_foundling_informant` spawn from **`TatooineMosEisleyScreenPlay`** (was duplicating / conflicting with **per-player** `spawnInformant()` at `planetData[1]`). On city load, **`deleteData("mando_way:foundling_informant_static:tatooine")`** clears the legacy hub key. Set **`planetData[1].citySpawn = false`** so optional **`spawnStaticInformants()`** can include Tatooine like other planets if used.
- **Files:** `bin/scripts/screenplays/cities/tatooine_mos_eisley.lua`, `bin/scripts/screenplays/bellum/mando_way_of_life.lua`
- **Notes:** Lua-only. **Restart Tatooine zone** (or full server) to despawn any old shared informant still in the world from prior boots.

### 2026-04-04 — Mando Way of Life: rank title skills + Lua `PlayerObject:setTitle`

- **Summary:** Wired **Foundling → Clanbound** ranks as **title skills** (`mando_title_*` in `skills/bellum/mando_titles.lua`, registered from `skills/serverobjects.lua`). On chapter milestones, `MandoWayOfLife` calls **`awardSkill`** and **`PlayerObject:setTitle`** so the rank appears in the Community title list and is **auto-equipped** (addresses “logged but not shown”: `setTitle` was not exposed to Lua). **Badges** remain **optional**: `chapterBadgeIds` defaults to **nil** per chapter until you assign numeric indices that exist in **`datatables/badge/badge_map.iff`** and match **client** `badge_n.stf` (per Titles/Badges system notes).
- **Files:** `bin/scripts/skills/bellum/mando_titles.lua`, `bin/scripts/skills/serverobjects.lua`, `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `src/server/zone/objects/player/LuaPlayerObject.h`, `src/server/zone/objects/player/LuaPlayerObject.cpp`
- **Notes:** Requires **C++ rebuild** for `setTitle`. **Lua-only** skill definitions: restart zones / server so SkillManager reloads. Without **skl_n.stf** patch, titles may show as raw skill names (e.g. `mando_title_foundling`). For badges after TRE work, set `MandoWayOfLife.chapterBadgeIds[ch]` and use `/grantBadge <id>` to validate IDs.

### 2026-04-04 — Foundling: `!foundling` spatial chat status (replaces broken `/foundlingStatus`)

- **Summary:** Removed **`/foundlingStatus`** queue command — stock SWG clients reject unknown slash commands locally (`No such command, mood, chat type`) so the server never sees them. Added **`ChatManagerImplementation::broadcastChatMessage`** hook: if a player sends spatial chat exactly **`!foundling`** or **`!foundlingstatus`** (trimmed, case-insensitive), call Lua **`mandoFoundlingStatusRun`** → **`sendFoundlingStatusReportToPlayer`** and **do not broadcast** that line to others. Status output includes a tip to use **`!foundling`** again. Optional later: add **`foundlingStatus`** to client `command_table` IFF if you want a true slash.
- **Files:** `src/server/chat/ChatManagerImplementation.cpp`, `bin/scripts/screenplays/bellum/mando_way_of_life.lua`; removed `FoundlingStatusCommand.h`, `bin/scripts/commands/foundlingStatus.lua`, `SkillManager` ability stub, `CommandConfigManager3` / `commands.h` registrations, `onPlayerLoggedIn` ability grant.
- **Notes:** Requires **C++ rebuild**. In-game: open **Say**, type **`!foundling`**, Enter (not `/foundlingStatus`).

### 2026-04-04 — Mando Trialmaster: Foundling mid-arc status + contact resync

- **Summary:** Replaced dead-end `arc_in_progress` convo (no options) with choices: **What is my status?** (prints planet, quota phase, informant spawn state via separate `sendSystemMessage` lines) and **Reset contact** (`despawnInformant` + `ensureFoundlingInformant` to respawn private informant and waypoints). `getInitialScreen` still calls `ensureFoundlingInformant` on open as a light safety net.
- **Files:** `bin/scripts/mobile/conversations/bellum/mando_trialmaster_conv.lua`, `bin/scripts/screenplays/bellum/convos/mando_trialmaster_conv_handler.lua`, `bin/scripts/screenplays/bellum/mando_way_of_life.lua`
- **Notes:** Lua-only; reload conversations + screenplays. Use reset on Tatooine cantina recruiter, then travel to current planet if needed.

### 2026-04-04 — Mando Foundling: Dathomir informant coords (Science Outpost, player HUD)

- **Summary:** Moved Foundling informant `planetData[9]` from `(-3800, 5, 1100)` to player-verified Science Outpost: `(-123, 18, -1609)` as `spawnMobile(x, z, y)`.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`
- **Notes:** Lua-only; reload Dathomir zone / relog so the informant respawns at the new point.

### 2026-04-04 — Mando Foundling: Endor informant coords (outpost); Talus stays Dearic

- **Summary:** Moved Foundling informant `planetData[8]` (Endor) to `(3220, 24, -3430)` as `spawnMobile(x, z, y)` — player HUD near an outpost (same numeric fix was briefly applied to Talus by mistake). Restored `planetData[7]` (Talus) to Dearic `(455, 6, -3120)`.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`
- **Notes:** Lua-only; reload Endor zone / relog. Endor coords sit near existing `myswg_vendor` research spawn (~3201, 24, -3501).

### 2026-04-04 — Mando Foundling: Talus informant coords (outpost, player HUD)

- **Summary:** Moved Foundling informant `planetData[7]` from Dearic `(455, 6, -3120)` to player HUD near an outpost: `(3220, 24, -3430)` as `spawnMobile(x, z, y)` so the contact is not isolated in the wilderness.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`
- **Notes:** Lua-only; reload scripts or zone / relog so the informant respawns at the new point.

### 2026-04-04 — Mando Foundling: Talus informant coords (Dearic, player HUD)

- **Summary:** Moved Foundling informant `planetData[7]` from `(551, 5, -2906)` to player-verified open ground in Dearic: `(455, 6, -3120)` as `spawnMobile(x, z, y)` to avoid building/unreachable spawn and `NpcConversationStart` cell/LoS issues.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`
- **Notes:** Lua-only; reload scripts or zone / relog so dynamic informant respawns at the new point.

### 2026-04-04 — Mando Foundling: Rori informant coords (Narmle, player HUD)

- **Summary:** Moved Foundling informant `planetData[6]` to open-ground coordinates taken from in-game HUD at Narmle: `(-5185, 80, -2197)` in `spawnMobile` order `(x, z, y)`, replacing `(-5199, 80, -2186)` near a building porch to reduce `NpcConversationStart` failures (different parent cell / LoS).
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`
- **Notes:** Lua-only; reload scripts or re-enter zone / relog so `ensureFoundlingInformant` / `advanceToPlanet` spawns the new position.

### 2026-04-04 — Mando Way: document AIENABLED; centralize informant post-spawn; fix recruiter start() fallback

- **Summary:** Added file-header + inline comments describing `AIENABLED` (`OptionBitmask::AIENABLED` in `src/templates/params/OptionBitmask.h`) and that `setOptionsBitmask` replaces the full mask. Introduced `configureFoundlingInformantMobile()` so dynamic + GM static informant paths share one implementation. Fixed `start()` recruiter fallback when `SPAWN_RECRUITER_ON_START=true` to match `tatooine_mos_eisley.lua` (set `AIENABLED + INVULNERABLE + CONVERSABLE`, stop clearing `AIENABLED`). Commented city/Corellia Mandalorian spawns for the same policy. Clarified conv handler comment: re-asserting template does not replace missing `AIENABLED` on the creature.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/screenplays/cities/tatooine_mos_eisley.lua`, `bin/scripts/screenplays/static_spawns/corellia_static_spawns.lua`, `bin/scripts/screenplays/bellum/convos/mando_foundling_informant_conv_handler.lua`
- **Notes:** Lua-only. We do not set options on “every NPC” globally — only Bellum/scripted post-spawn overrides; stock mobiles keep template defaults unless a screenplay replaces the mask.

### 2026-04-04 — Mando Foundling: informant spawn — AIENABLED + converse diagnostics

- **Summary:** Dynamic (and GM `spawnStaticInformants`) informant NPCs now use `AIENABLED + INVULNERABLE + CONVERSABLE` and `setMoodString("conversation")`, matching the working Mos Eisley hub spawn. `INVULNERABLE + CONVERSABLE` alone was suspected of leaving radial/converse unreliable on some setups. Added spawn log line with `parentId` (cell) and a reminder that `NpcConversationStart` requires same cell as the NPC outdoors within ~6m with line-of-sight — otherwise the client often shows no dialog and Lua `getInitialScreen` never runs.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`
- **Notes:** Lua-only. If conversation still fails outdoors, verify `planetData` height (`z`) so the NPC is not floating above terrain (LoS failure).

### 2026-04-04 — Mando Foundling: dynamic per-player informant spawn (replaces static)

- **Summary:** Rewrote the foundling informant spawn model from shared static NPCs (one per planet at boot) to per-player dynamic NPCs (spawned when a player advances to a planet, destroyed on turn-in). Root cause of "informant not talking / nothing happens": `setConvoTemplate` is runtime-only and was wiped by zone restarts, leaving the shared static NPC with no conversation binding. Dynamic spawn eliminates the shared static key entirely — no `_MANDO_LOAD_FLAG` race, no zone-restart wipe. Key changes: (1) `spawnInformant` now does a `spawnMobile` + configure NPC + write per-player ownership key; (2) `ensureFoundlingInformant` now calls `spawnInformant` instead of `tryLinkStaticFoundlingInformant` — handles relog, NPC death, and zone restarts; (3) `onPlayerLoggedIn` simplified to single `ensureFoundlingInformant` call; (4) `start()` no longer calls `spawnStaticInformants()` — function kept for GM use; (5) conv handler re-asserts `setConvoTemplate` on every conversation open (Option 1 safety); (6) conv handler ownership guard prevents Player B from hijacking Player A's NPC when both are on the same planet.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bin/scripts/screenplays/bellum/convos/mando_foundling_informant_conv_handler.lua`
- **Notes:** Lua-only — no C++ rebuild needed. On next server restart all players in arc will have their informant re-spawned dynamically via `onPlayerLoggedIn`. Existing static NPCs from previous boots will remain in-world but are inert (ownership guard prevents linking). `tryLinkStaticFoundlingInformant` and `spawnStaticInformants` kept in codebase for future Option 5 GM respawn command.

### 2026-04-01 — Mando Foundling: Rori informant coords corrected (Narmlex)

- **Summary:** Rori informant (planet index 6) moved from (-5178, 5, -2194) — inside a building — to (-5199, -80, 2185) near Narmlex, verified in-game.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua` (planetData[6] coords)
- **Notes:** Lua-only; zone reboot or despawn/respawn needed to move the existing informant.

### 2026-04-01 — Mando Foundling: Lok informant coords + stale-link hardening

- **Summary:** Two fixes. (1) Lok informant (planet index 5) coords corrected from (-5537, 5, 300) to (456, 2, 5434) — near Nym's Stronghold as verified in-game. (2) Hardened `getInitialScreen` in the conv handler: previously, if the static key OID was stale (server restart, spawn failure) and the stored `foundling.informantId` didn't match, the handler returned `nil` on all planets, leaving the player with only "Stop Conversing". Now re-links any NPC whose template is `mando_foundling_informant` and player is in arc (or OID matches static key), heals the static key via `writeData` so future lookups work, and re-grants the appropriate waypoint.
- **Files:** `bin/scripts/screenplays/bellum/mando_way_of_life.lua` (planetData[5] coords), `bin/scripts/screenplays/bellum/convos/mando_foundling_informant_conv_handler.lua` (re-link logic)
- **Notes:** Lua-only; reload scripts or restart zone. Existing spawned informant at old Lok coords will persist until zone reboot.

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

### 2026-05-16 — PR: restore `.cursor/` from Main (no Mando diff on context files)

- **Summary:** Re-checked out **`.cursor/context`** and **`.cursor/plans`** from **`origin/Main`** so **`Ender_MandalorianWay`** no longer proposes deleting them in the PR. Local **`.cursor/`** remains in **`.gitignore`** for dev-only edits; Mando work stays in **`MMOCoreORB`**.
- **Files:** `.cursor/context/CREATURE_MISSION_TERMINAL_REQUIREMENTS.md`, `.cursor/context/CREATURE_TEST_RUNNER.md`, `.cursor/context/SWG_CONTEXT.md`, `.cursor/plans/creature_testing_procedure_eee15654.plan.md`, `bellumgero_change_log.md`
- **Notes:** Prior commit `85da21c045` had removed these from the branch tree; restoring aligns with Main and drops ~384 lines of red PR noise.

### 2026-04-14 — Repo: drop tracked `.cursor/` and root `docs/` reports from branch

- **Summary:** Removed **`.cursor/context`** and **`.cursor/plans`** and repo-root **`docs/`** (cantina placement reports) from version control so other developers only need the shared tree (**`MMOCoreORB`**, **docker**, **linux**, **wsl2**, etc.). Added **`.cursor/`** to **`.gitignore`** so local Cursor context stays untracked.
- **Files:** `.gitignore`, `bellumgero_change_log.md` (this file); deleted `.cursor/**`, `docs/all_cantina_npc_placement_report.md`, `docs/mos_eisley_cantina_npc_report.md`
- **Notes:** **`MMOCoreORB/docs/`** remains for optional server admin notes.

### 2026-04-07 — Cursor rule: no ASCII hyphen in player-visible game text

- **Summary:** Added **`.cursor/rules/no-ascii-hyphen-game-text.mdc`**: when working under **`MMOCoreORB`**, avoid **hyphen-minus (U+002D)** and Unicode dashes in **convo, system messages, waypoint text, and other client-displayed strings**; use commas, periods, colons, pipes, parentheses instead. Documents allowed exceptions (code, comments, server-only logs, STF key paths).
- **Files:** `~/.cursor/rules/no-ascii-hyphen-game-text.mdc`, `bellumgero_change_log.md` (this file)
- **Notes:** Rule is **glob-scoped** to `workspace/BellumGero-Live/MMOCoreORB/**/*`, not `alwaysApply`.

### 2026-04-05 — Mando titles: comment — client skl_t.stf vs skl_n

- **Summary:** Corrected header comment in **`mando_titles.lua`**: floating title uses **`skl_t`**, not **`skl_n`** (matches in-game `(skl_t:[...])` when STF is missing); noted optional **`skl_n`/`skl_d`** and client skill datatables for Community title list.
- **Files:** `bin/scripts/skills/bellum/mando_titles.lua`
- **Notes:** Server Lua already calls **`awardSkill`** + **`setTitle`**; broken nameplate is a **client TRE** fix.

### 2026-04-05 — Docs: SWG_CONTEXT scoped to mobile laptop + Dev-BG / BellumGero

- **Summary:** `.cursor/context/SWG_CONTEXT.md` documents **this dev laptop only** (banner + paths): WSL repo at **`~/workspace/BellumGero-Live`**, TRE sync from **`/mnt/c/Dev-BG/`** to **`/trefiles`**, **`/mnt/c/BellumGero/`** for prod-style client on the same machine — not team-wide canonical paths; removed stale **`/mnt/c/SWGEmu`** examples for this PC.
- **Files:** `.cursor/context/SWG_CONTEXT.md`
- **Notes:** On this laptop: `sudo cp -f /mnt/c/Dev-BG/bg_custom1.tre /trefiles/` then restart Core3.

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

### 2026-04-16 — Docs: Mandalorian project player perspective overview

- **Summary:** Added a player facing overview for the Mandalorian project that consolidates what the arc includes, major updates, current flow, and active direction using the existing changelog history.
- **Files:** `docs/mandalorian_project_player_perspective.md`, `bellumgero_change_log.md`
- **Notes:** Documentation only. No code or runtime behavior changed.

### 2026-04-16 — Docs: remove non working chat command references from Mandalorian overview

- **Summary:** Removed `!foundling` and `!mando` references from the player perspective overview so the guide does not direct players to commands that are not working on this shard.
- **Files:** `docs/mandalorian_project_player_perspective.md`, `bellumgero_change_log.md`
- **Notes:** Documentation only. No gameplay logic changes.

### 2026-04-25 — Foundling weapon naming and chapter gate LLC perk

- **Summary:** Renamed Foundling starter weapon display names from CDEF phrasing to `Foundling Pistol`, `Foundling Carbine`, and `Foundling Rifle`; added a new `Foundling Light Lightning Cannon` weapon tuned to the same Foundling combat profile and granted once per player when the post-Foundling Novice Bounty Hunter chapter gate opens.
- **Files:** `bin/scripts/object/weapon/ranged/pistol/pistol_foundling_cdef_beskar.lua`, `bin/scripts/object/weapon/ranged/carbine/carbine_foundling_cdef_beskar.lua`, `bin/scripts/object/weapon/ranged/rifle/rifle_foundling_cdef_beskar.lua`, `bin/scripts/object/weapon/ranged/rifle/rifle_foundling_light_lightning_cannon.lua`, `bin/scripts/object/weapon/ranged/rifle/serverobjects.lua`, `bin/scripts/object/weapon/ranged/rifle/objects.lua`, `bin/scripts/screenplays/bellum/mando_way_of_life.lua`, `bellumgero_change_log.md`
- **Notes:** New perk uses `cert_mando_way_lightning_cannon` and grants the hidden cert skill at perk time so the weapon is immediately usable when unlocked.

### 2026-04-25 — Foundling weapons renamed to Beskar Polished format

- **Summary:** Updated Foundling weapon display names to the requested `Beskar Polished <weapon type>` format for pistol, carbine, rifle, and Lightning Cannon.
- **Files:** `bin/scripts/object/weapon/ranged/pistol/pistol_foundling_cdef_beskar.lua`, `bin/scripts/object/weapon/ranged/carbine/carbine_foundling_cdef_beskar.lua`, `bin/scripts/object/weapon/ranged/rifle/rifle_foundling_cdef_beskar.lua`, `bin/scripts/object/weapon/ranged/rifle/rifle_foundling_light_lightning_cannon.lua`, `bellumgero_change_log.md`
- **Notes:** Naming only. No stat or progression logic changes.
