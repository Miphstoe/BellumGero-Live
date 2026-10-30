# Taanab: local test checklist (Dev-BG)

One pass through everything built for Taanab, in an order that keeps travel to a minimum. Mark each line ✅ / ❌ and
note what went wrong next to any ❌. Every ❌ becomes a fix or a new ticket in the "Taanab: Planet" module.

**Setup**
- Server: local core3 on `Ender_Taanab`. The server and `C:\Dev-BG` both run `bg_custom1_taanab_20261030.tre`
  (md5 `3926f895…`).
- Start `C:\Dev-BG` directly, **not** through the launcher (the launcher puts the live `bg_custom1.tre` back).
- Admin toon: `/setGodMode self on`, `/invuln`. Combat toon for anything that tests loot, harvesting or missions.
- Teleport is `/teleport <x> <y> <planet>`, for example `/teleport 2000 5400 taanab`.
- Kessic's first raid comes 30 min after a server boot, then about 3 h after each kill or retreat. Ask for a reboot
  if you want one right away.

---

## 1. Travel (LIVE-39)
- [ ] Buy a ticket to Taanab at a starport on **each** planet: Corellia, Naboo, Tatooine, Talus, Rori, Dantooine,
      Lok, Endor, Yavin 4, Dathomir and Hoth. Cost: 1,250 cr (4,000 cr from Hoth). Taanab sits on the east side of the
      galaxy map in the ticket window.
- [ ] Arrive at **Pandath Starport** and at **Starhunter Station**. You don't land inside a wall or under the floor.
- [ ] Ride between Pandath and Starhunter (100 cr).
- [ ] From Taanab, buy tickets back to 3 or more other planets, Hoth included.
- [ ] The loading screen, planet music, sky and terrain all render.

## 2. Pandath (LIVE-58, LIVE-56): `/teleport 2000 5400 taanab`
- [ ] Planet map (Taanab page) shows Taanab's own map, not Talus.
- [ ] Imperial and Rebel recruiters near the starport; junk dealer and chassis dealer.
- [ ] 8 trainers (brawler, marksman, scout, medic, artisan, entertainer, politician, merchant). Each one talks and
      trains.
- [ ] Townsfolk standing around; 8 militia guards on the town edge, who can't be attacked.
- [ ] No NPC is stuck inside a building, wall, lamp or terminal. Note the name and spot of any that are.
- [ ] **Cantina** (2120, 5320): bartender, patrons, an entertainer, and the musician and dancer trainers. Positions
      were borrowed from the Naboo cantinas in Moenia and Kaadara, so note anyone standing in a wall or the bar.
- [ ] Bank, bazaar, cloning, hospital and garage all work.

## 3. Starhunter Station: `/teleport 3610 -5425 taanab`
- [ ] Junk dealer, 4 trainers (scout, medic, brawler, artisan), townsfolk, 4 guards.
- [ ] Bank, bazaar, mission terminal and cloning facility all work.

## 4. Mission terminals (LIVE-56)
At the Pandath terminals (mission 2100, 5363; bounty 2095, 5356; entertainer 2129, 5366) and at Starhunter (3598, -5402):
- [ ] **Destroy** tab: Choose Mission Target lists the Taanab lairs (nerf herd, kaadu flock, bantha herd, kusak pack,
      sharnaff burrow, hill graul, Norulac camps, and so on). Take one, go to the waypoint, kill the lair and get paid.
- [ ] **Deliver**: take one, find the NPC in Pandath or Starhunter, finish it.
- [ ] **Escort** (if offered), **Hunting**, **Scout** (take one and finish it).
- [ ] **Bounty** terminal gives missions.
- [ ] **Entertainer** terminal gives dancer and musician missions that resolve in Pandath.
- [ ] **Imperial and Rebel** terminals (faction toon) offer missions.
- [ ] *(If you have one)* a player-city mission terminal on Taanab works.
- [ ] Missing for now: the BG Hub NPC at Pandath (carried over from LIVE-47).

## 5. Wildlife and world spawns (LIVE-58)
World lairs only spawn around players, so ride across the plains for a few minutes in several areas:
- [ ] Passive herds show up: Taanab nerf (45), vir vur (46), plains kaadu (48), field falumpaset (50), plains bantha
      (55) with a bantha bull (62).
- [ ] Hostiles show up: zucca boar (52), crop-raiding quenker (58), plains kusak (66), sharnaff (72), Taanab hill
      graul (84).
- [ ] Norulac raider camps (70–74) and strike teams (74–82) show up.
- [ ] Nothing is invisible, a placeholder model, the wrong size, or under the ground.
- [ ] No lairs inside Pandath, Starhunter or any POI.

## 6. Harvesting and resources (LIVE-40)
- [ ] Kill and harvest a nerf (herder camp `/teleport 5536 -4957 taanab`): meat, hide and bone come out as
      **Taanab** resources (for example "Taanab Wooly Hide").
- [ ] Harvest a carnivore (kusak or graul) and a bantha (milk too).
- [ ] Survey tools on Taanab list Taanab-native resources: "Taanab Steel", "Taanab Wind Renewable Energy", and so on.
- [ ] Place a harvester, a factory and a generator on Taanab. They run and collect.

## 7. Housing, cities, GCW (LIVE-41, 42, 43, 44, 45)
- [ ] A small house, a merchant tent and a guild hall all place in open land.
- [ ] Placement is **refused** in Pandath (550 m), Starhunter (350 m), every POI circle, the Great Herds core (400 m)
      and at the map edge (|x| or |y| > 7640).
- [ ] A city hall places, and civic structures place in the city.
- [ ] *(LIVE-45, longer test)* the city grows through its ranks, and a 6th Cosmopolis is refused.
- [ ] A faction HQ places. `/gcwstatus all` lists Taanab.

## 8. Points of interest and planet map (LIVE-57, LIVE-48)
- [ ] The map lists the 5 sites: Taanab Mining Outfit, Arcon Multinode Hybrid Plantings, Shipwreck, Norulac Raider
      Cave, Great Herds of Taanab, under **Points of Interest** (the category formerly labelled "Theme Park", on
      every planet).
- [ ] Each marker sits on the real site; walking in shows "You have entered …".
- [ ] **Mining Outfit** `/teleport -2610 -1300 taanab`: contractors, scientists and an artisan among the machinery.
- [ ] **Hex farms** `/teleport -3000 -100 taanab`: farmers, agriculturalists and ranchers.
- [ ] **Shipwreck** `/teleport 3318 -1306 taanab`: Norulac salvagers on the Lucky Despot (hostile).
- [ ] **Herder camp** `/teleport 5536 -4957 taanab`: ranchers and nerfs.
- [ ] The "Waypoint" entries under the map are only the waypoints you made by clicking the POIs. Deleting them from
      the datapad removes them.

## 9. Bosses and loot (LIVE-52, 53, 54, 59)
- [ ] **Regular Norulac mobs** (cave or wreck): almost every corpse now has loot (weapons, junk, clothing, kit
      parts). Rare drops: Norulac items, BG tokens.
- [ ] **Norulac Raider Cave** `/teleport -861 7206 taanab`: 21 mobs inside. **Sela Drux** in the back chamber; on her
      death **every** player who hit her and is within 64 m gets "Your share from Sela Drux: …", and the items are
      really in the inventory. She respawns after 30 min.
- [ ] **Old Thunderhorn** `/teleport 4900 -4500 taanab`: a huge bantha with 10 herd banthas. Hit one and the herd
      joins in ("The ground shakes…"). His corpse holds a trophy (rug, skull or plush) and harvests big.
- [ ] **Varn Kessic raid** at the hex farms `/teleport -2970 -150 taanab`:
  - [ ] galaxy warning, then 2 waves, then Kessic with 4 honor guards
  - [ ] Kessic can't be attacked until the guards are dead
  - [ ] reinforcements at 75, 50 and 25 %; detonator warnings and blasts below 25 %
  - [ ] on the kill, **each** damager gets 3 items in their inventory. With 2 toons both should get loot: this is
        the shared damage-tracking fix.
  - [ ] if left alone, the raid retreats after 45 min
- [ ] One **Hoth** boss (an ice cave boss or Rimeclaw) still pays out as before, since it shares the loot code.

## 10. Sanity
- [ ] No client crash anywhere on Taanab.
- [ ] Nothing new in `bin/log/lua.log` while testing (ask Claude to check the log afterwards).

---

**Report back:** paste the ❌ lines (with names and coordinates). For anything visual, a screenshot.
