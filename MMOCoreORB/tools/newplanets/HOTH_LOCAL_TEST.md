# Hoth: local dev test pass (before Test Center)

Local dev state when this was written (2026-10-06): server and client both on `bg_custom1.tre` `6333170e…`,
Core3 built from `0233531ba7` (last C++ change), branch `Ender_Hoth_Loot_and_more` clean and pushed.
Server: `wsl -d Debian -- bash /mnt/c/SWG-Dev/NewPlanets/wsl/reinstall_restart.sh` (log `~/hoth_boot4.log`, baseline 303 ERROR lines).

GM syntax: `/teleport <x> <y> hoth` · `/createCreature <template>` · `/object createitem <iff>` (see `HOTH_LOOT_GM_TEST.md`).
Tick each box; anything that fails, note it on the Plane item (LIVE-n) and tell Claude.

## 0. Boot sanity (Claude already checked)
- [x] Boot log: 303 errors, 23 Hoth regions, 343 snapshot objects, 0 "Moving stored snapshot object" (positions already stored)

## 1. Travel and starports — LIVE-4
- [ ] Imperial Forward Base starport (`/teleport 3820 -3080 hoth`): walk in, not bounced out; ticket terminal sells a ticket
- [ ] Board the shuttle to each Hoth stop: Scavenger Outpost, Imperial Forward Base, Rebel Forward Base, Eastern Ice Fields Shuttleport, Generator Ridge Shuttleport
- [ ] Rebel Forward Base (`/teleport -420 600 hoth`) and Scavenger Outpost (`/teleport -4030 -2080 hoth`): ticket terminal + shuttle work
- [ ] Buy a ticket off-planet to Hoth and back (any starport → Hoth)
- [ ] Buildings sit on the ground at all three outposts (nothing floating or buried)

## 2. Fortified shuttleports + map — LIVE-7
- [ ] Eastern Ice Fields (`/teleport 5928 -406 hoth`): Imperial walls closed on N/E/S, entrance gap on the west, 4 corner columns, 4 turrets
- [ ] Generator Ridge (`/teleport 4525 1164 hoth`): same with Rebel walls
- [ ] Planet map → Points of Interest: Eastern Ice Fields, Generator Ridge, Frostfang Cavern, Icemaw's Den, Snowblind the Ravager, Wampa Matriarch's Ice Cavern, Deep Freeze Den, Broodmother's Nest, Shield Generator Battlefield, Generator Raider Camp, Lucky Despot Wreck, Glacial Rancor Hunting Grounds
- [ ] Map → Cities: Scavenger Outpost, Imperial Forward Base, Rebel Forward Base · Shuttleports: both shuttleports listed
- [ ] Old datapad waypoints from earlier testing deleted (they point at the old sites)
- [ ] Terrain tear at -5270, 5707 is gone (`/teleport -5270 5707 hoth`; also check -5050 5410 and -5036 5106)

## 3. Missions — LIVE-5, LIVE-6
- [ ] General terminal (Scavenger Outpost): destroy missions list Hoth targets (tauntauns, mynocks, wampas, patrols, raider camp, salvage team, probe droid); take one and complete it
- [ ] Imperial terminal (Imperial FB, as an overt/covert Imperial): Rebel Snow Patrol missions
- [ ] Rebel terminal (Rebel FB, as an overt/covert Rebel): Snowtrooper Patrol / Salvage Team / Probe Droid missions
- [ ] Deliver missions appear on Hoth terminals; pick up and deliver one (start NPC and end NPC spawn)
- [ ] Scout terminal: hunting mission shows the creature name (e.g. "a wampa"), not blank

## 4. Bosses and loot — LIVE-9, LIVE-10, LIVE-2
- [ ] Cave boss with 2 characters (or a group): kill e.g. Frostfang (Frostfang Cavern, `/teleport -623 2292 hoth`); each player gets "Your share from …"; the corpse has no loot
- [ ] Repeat once for the mynock broodmother (Broodmother's Nest, `/teleport -5819 6093 hoth`)
- [ ] Glacial Rancor (`/teleport 600 -4600 hoth`): model renders (spiky, no glow), level 400; kill it → each eligible player gets 3 items + 5,000 credits + "Hoth spoils" roll
- [ ] Another boss with Hoth loot: `/createCreature tusken_king`, kill a few times → Hoth items show up in its loot over several kills
- [ ] One world boss off Hoth (e.g. Acklay on Yavin 4) gives the "Hoth spoils" message (only if convenient)

## 5. Balance — LIVE-8
- [ ] Wampa (90) and elder wampa (98) feel on par with Dathomir's enraged / ancient bull rancors
- [ ] Snowtroopers / Rebel soldiers (76) and sergeants (85) not trivial; scavenger raiders (74) fine
- [ ] Cave bosses (100–115) clearly harder than the elder wampas guarding them

## 6. Earlier work still to cover — LIVE-11, LIVE-12
- [ ] Glow fix: AT-AT house, gunship, RIC-920, XJ-6, pod car render without bloom
- [ ] A few more vehicles: deed → call → mount → ride → store (podracer mount at 20 m; Organa XJ-2 Store/Call)
- [ ] One armor piece crafted end to end on a Master Armorsmith, equipped on male and female

## When everything above passes
Tell Claude → open/refresh the loot PR, then LIVE-3 (Test Center deploy: Core3 rebuild, new `bg_custom1.tre` on server + clients, restart twice).
