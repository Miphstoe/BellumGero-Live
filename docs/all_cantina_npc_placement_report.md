# All Cantina NPC Placement — Cross-Server Research Report

**Project:** BellumGero-Live (SWGEmu)
**Date:** 2026-03-28
**Purpose:** Cross-cantina NPC placement research to support Mandalorian Recruiter placement debugging

---

## How Cantina NPC Spawns Work

All cantina NPCs use one of two patterns depending on the screenplay.

### Pattern A — Mobiles Table (most common)
```lua
{"npc_template", respawnSeconds, x, z, y, heading, cellID, "mood"}
```
- Used by most city screenplays (Mos Eisley, Mos Espa, Coronet, etc.)
- Processed in bulk by `CityScreenPlay:spawnMobiles()`

### Pattern B — Direct `spawnMobile()` call (used for special/quest NPCs)
```lua
local pNpc = spawnMobile(planet, template, respawn, x, z, y, heading, cellID)
if pNpc ~= nil then
    AiAgent(pNpc):setConvoTemplate("templateName")
    -- optional flag overrides
end
```
- Used when the NPC needs a conversation template, flag overrides, or data storage
- Used by Theed cantina, Endor outposts, and the **Mandalorian Recruiter**

### Coordinate System
```
x = left/right
z = height (ground level inside buildings is typically -0.9 to 0.1)
y = forward/back
heading = degrees (0–360, where 0/360 = north)
cellID = interior cell ID (0 = world exterior)
```

---

## TATOOINE

### Mos Eisley Cantina
**File:** `screenplays/cities/tatooine_mos_eisley.lua`

**Cell Map:**
| Cell ID | Room |
|---------|------|
| 1082876 | Entrance |
| 1082877 | Main Hall / Bar |
| 1082880 | Stage |
| 1082886 | Private Back Room |

**R3 Droid Patrol (Cell 1082877):**
```lua
-- patrolMobiles table
{"r3_1", "r3", 15.9, -0.9, -0.2, 56, 1082877, "", false},
-- patrolPoints
r3_1 = {{15.9, -0.89, -0.21, 1082877, false}, {9.2, -0.9, 7.8, 1082877, false}, {-9.4, -0.9, 8.6, 1082877, false}, {9.2, -0.9, 7.8, 1082877, true}},
```

**Cell 1082876 — Entrance:**
```lua
{"commoner_old",60,36,0.1,0.7,310,1082876, "npc_sitting_chair"},
{"commoner_tatooine",60,29.6,0.1,-7.4,71,1082876, "npc_sitting_chair"},
{"commoner_tatooine",60,30.9,0.1,-8.8,10,1082876, "npc_sitting_chair"},
{"commoner_tatooine",60,29.4,0.1,-6.1,107,1082876, "npc_sitting_chair"},
{"commoner_tatooine",60,35.7,0.1,3.1,180,1082876, "npc_sitting_table"},
```

**Cell 1082877 — Main Hall:**
```lua
{"businessman",60,10.65,-0.894992,1.91,330,1082877, "npc_standing_drinking"},
{"businessman",60,-4.11,-0.894992,5.4,26.8951,1082877, "happy"},
{"chadra_fan_female",60,10.43,-0.894992,-1.47,123.102,1082877, "worried"},
{"chadra_fan_male",60,10.7,-0.894992,-0.23,80.4821,1082877, ""},
{"commoner",60,10.17,-0.894992,2.74,125.098,1082877, "conversation"},
{"commoner_fat",60,2.11,-0.894992,5.4,180,1082877, "npc_standing_drinking"},
{"commoner_fat",60,-2.2,-0.9,-10.9,65,1082877, "npc_sitting_table_eating"},
{"commoner_naboo",60,3.11,0,5.4,161.005,1082877, "bored"},
{"commoner_naboo",60,1.11,0,5.4,330.024,1082877, "npc_standing_drinking"},
{"commoner_naboo",60,-3.11,0,5.4,16.6733,1082877, "npc_standing_drinking"},
{"commoner_naboo",60,16.1,-0.9,4.1,340,1082877, "conversation"},
{"commoner_tatooine",60,4.11,-0.894992,5.4,158.443,1082877, "npc_standing_drinking"},
{"commoner_tatooine",60,1.99,-0.894992,-8.44,325.01,1082877, "conversation"},
{"commoner_tatooine",60,1.19,-0.894992,-7.63,152.004,1082877, "conversation"},
{"entertainer",60,9.4,0,3.9,310,1082877, "conversation"},
{"marco_vahn",60,-9.34,-0.894992,5.66,59.306,1082877, "calm"},
{"muftak",60,20.2,-0.9,5,107,1082877, "happy"},
{"noble",60,8.49,-0.894992,4.64,128.74,1082877, "conversation"},
{"patron",60,14.2,-0.9,-4.8,67,1082877, "npc_sitting_chair"},
{"patron",60,14.7,-0.9,-3,147,1082877, "npc_sitting_chair"},
{"patron",60,16.5,-0.9,-4.8,320,1082877, "npc_sitting_chair"},
{"patron",60,24.5,-0.9,-8.1,51,1082877, "npc_sitting_table"},
{"patron",60,26.1,-0.9,-8.2,317,1082877, "npc_sitting_table_eating"},
{"patron",60,8.8,-0.9,-6,208,1082877, "entertained"},
{"patron",60,6.8,-0.9,-6.5,230,1082877, "entertained"},
{"patron",60,-2.2,-0.9,11.8,97,1082877, "npc_sitting_table"},
{"patron",60,0.6,-0.9,11.9,269,1082877, "npc_sitting_chair"},
{"patron_chiss",60,3.62,-0.894992,-4.77,184.005,1082877, "sad"},
{"patron_chiss",60,1.74,-0.894992,-4.91,95.0028,1082877, "npc_consoling"},
{"patron_devaronian",60,21.4,-0.9,5.4,161,1082877, "npc_sitting_table"},
{"patron_ishitib",60,22.3,-0.9,3.1,339,1082877, "npc_sitting_chair"},
{"patron_ithorian",60,14.9,-0.9,4.9,51,1082877, "npc_sitting_table"},
{"patron_klaatu",60,15,-0.9,6.9,139,1082877, "npc_sitting_chair"},
{"patron_nikto",60,23.4,-0.9,4.8,272,1082877, "npc_sitting_chair"},
{"patron_quarren",60,17,-0.9,6.8,226,1082877, "npc_sitting_chair"},
-- !! Imperial presence — 400s respawn
{"stormtrooper",400,2.84,-0.894992,-6.3,16.0005,1082877, "npc_imperial"},
{"stormtrooper_squad_leader",400,3.62,-0.894992,-6.78,360.011,1082877, "npc_accusing"},
```

> **Mandalorian Recruiter also spawns in Cell 1082877 at (6.8, -0.894992, 4.2)** — see Mando Recruiter section below.

**Cell 1082880 — Stage:**
```lua
{"doikk_nats",60,2.32,-0.894992,-16.47,44.0013,1082880, "themepark_music_3"},
{"figrin_dan",60,3.69,-0.894992,-14.4,50.0015,1082880, "themepark_music_3"},
{"nalan_cheel",60,0.54,-0.894992,-17.13,38.0011,1082880, "themepark_music_1"},
{"tech_mor",60,4.11,-0.894992,-17.07,45.0013,1082880, "themepark_music_2"},
{"tedn_dahai",60,1.29,-0.894992,-15.18,70.0021,1082880, "themepark_music_3"},
```

**Cell 1082886 — Private Back Room:**
```lua
{"dravis",60,-21.2103,-0.894989,24.3324,164.437,1082886, "neutral"},
{"talon_karrde",60,-18.7,-0.9,24.9,-31.0,1082886, "npc_sitting_chair"},
```

**Wuher (Bartender)** — spawned separately by `BartendersScreenPlay` via `bartenders.lua`:
```lua
{"wuher", "tatooine", 1082877},  -- Cell 1082877, patrol-based
```

---

### Mos Espa Cantina
**File:** `screenplays/cities/tatooine_mos_espa.lua`

**Cell Map:**
| Cell ID | Notes |
|---------|-------|
| 1256058 | Main cantina room |
| 1256061 | Secondary room |
| 1256067 | Back area |
| 1256068 | Far back area |

```lua
{"dorn_gestros",60,-6.00754,-0.894992,-5.35219,231.068,1256058, "calm"},
{"medic",60,12.1732,-0.894991,3.93609,180.003,1256058, "conversation"},
{"sullustan_male",300,12.1732,-0.894992,2.93609,360.011,1256058, "conversation"},
{"bounty_hunter",300,2.1656,-0.894992,-15.9672,360.011,1256061, "calm"},
{"contractor",60,2.1656,-0.894992,-14.9672,180.001,1256061, "conversation"},
{"commoner_tatooine",60,-20.6545,-0.894989,25.0112,0,1256067, "conversation"},
{"noble",300,-20.6545,-0.894989,26.0112,180.01,1256067, "conversation"},
{"da_la_socuna",60,-29.7168,-0.519991,7.77728,54.7476,1256068, "conversation"},
```

---

### Mos Taike Tavern
**File:** `screenplays/cities/tatooine_mos_taike.lua`

**Cell Map:**
| Cell ID | Notes |
|---------|-------|
| 1154121 | Entry room |
| 1154122 | Main tavern floor |
| 1154123 | Upper room / band area |
| 1154127 | Side room |
| 1154128 | Lower room |

**GCW NPC (owner switches Imperial/Rebel based on GCW state):**
```lua
{"mos_taike_cantina_owner", "mos_taike_cantina_owner_rebel", 9.6,0.4,-0.6,23,1154122, "conversation", "conversation"},
```

**Static commoner spawns (inline multi-entry format):**
```lua
{1, 4.6, 1.0, 6.3, -107, 1154121, "npc_use_terminal_high"},
{1, 10.4, 0.4, 0.6, -150, 1154122, "npc_standing_drinking"},
{1, 9.0, 0.4, -9.8, 172, 1154122, "sad"},
{1, 1.0, 0.4, -4.7, 173, 1154122, "sad"},
{1, 2.9, 0.4, 1.9, 90, 1154122, "npc_sitting_chair"},
{1, 5.9, 0.4, 1.8, -90, 1154122, "npc_sitting_chair"},
{1, 4.5, 0.4, 0.6, 0, 1154122, "npc_sitting_chair"},
{1, 9.1, 0.4, -5.1, 127, 1154122, ""},
{1, 10.4, 0.4, 5.6, -158, 1154122, ""},
{1, -8.9, 1.0, 7.5, 89, 1154123, "npc_sitting_chair"},
{1, -8.9, 1.0, 6.6, 89, 1154123, "npc_sitting_chair"},
{1, 5.0, -4.0, -7.6, 46, 1154128, "npc_sitting_chair"},
{1, -3.8, -4.0, 9.0, -45, 1154127, "npc_sitting_chair"},
{1, -4.3, -4.0, 8.7, 58, 1154127, "sad"},
{1, 1.7, 1.0, 4.8, -85, 1154123, "entertained"},
```

**Named mobile spawns:**
```lua
{"r3",60,4.9,-4.0,-5.6,171,1154128,"neutral"},
{"entertainer",120,-6.0,1.0,7.2,-96,1154123, "themepark_music_2"},
{"informant_npc_lvl_3", 1, 0.93374, 1.00421, 9.03511, 180, 1154123, ""},
```

---

### Mos Entha Tavern
**File:** `screenplays/cities/tatooine_mos_entha.lua`

Mos Entha uses a large complex with 13+ cell rooms. Cell IDs range from 1153625 to 1154023.

---

### Bestine Cantina
**File:** `screenplays/cities/tatooine_bestine.lua`

**Cell Map:**
| Cell ID | Notes |
|---------|-------|
| 1028491 | Main cantina room |
| 1028492 | Back area (trainer) |
| 1528396 | Secondary building |
| 1528397 | Side cantina |

```lua
-- Cell 1028491 — main cantina
{"noble",60,-3.6,0.4,-0.2,209,1028491, "npc_sitting_chair"},
{"contractor",300,-1.05454,0.408271,-5.70312,360.011,1028491, "conversation"},
{"info_broker",60,-1.05454,0.408271,-4.40312,180.006,1028491, "conversation"},
{"trainer_chef",0,-9.4,1.0,7.1,85,1028492, ""},

-- Cell 1528397 — side cantina
{"commoner_technician",300,4.6,1.0,7.5,90,1528396, "npc_use_terminal_high"},
{"chiss_female",60,10.2,0.4,-4.5,0,1528397, "npc_angry"},
{"chiss_male",60,10.3,0.4,-5.6,90,1528397, "sad"},
{"patron_ithorian",60,1.6,0.4,-6.0,90,1528397, "npc_sitting_ground"},
{"entertainer",60,3.8,0.4,-6.0,-90,1528397, "npc_sitting_ground"},
{"commoner",60,2.0,0.4,-2.6,165,1528397, "entertained"},
{"rancher",60,4.1,0.4,-2.7,-173,1528397, "happy"},
{"commoner_old",60,6.4,0.4,-2.9,-132,1528397, "npc_sitting_chair"},
{"commoner_naboo",60,-0.6,0.4,-2.8,134,1528397, "npc_sitting_chair"},
{"ishitib_male",60,3.0,0.4,-9.3,0,1528397, "npc_sitting_chair"},
{"mercenary",300,-10.6,0.4,-2.3,90,1528397, "threaten"},
```

---

### Anchorhead Cantina
**File:** `screenplays/cities/tatooine_anchorhead.lua`

**Cell Map:**
| Cell ID | Notes |
|---------|-------|
| 1213345 | Main floor |
| 1213346 | Back room (trainer) |
| 1213349 | Lower level |

```lua
{"borra_setas", 60, 9.51111, 0.408271, -0.736723, 320.12, 1213345, "worried"},
{"commoner_tatooine", 60, -9.4, 0.4, 2.0, 161, 1213345, "npc_standing_drinking"},
{"trainer_doctor", 0, 1.53792, 1.00421, 6.82596, 265, 1213346, ""},
{"rebel_recruiter", 60, -6.22005, -3.96617, -6.58904, 194.653, 1213349, ""},
```

---

### Wayfar Cantina
**File:** `screenplays/cities/tatooine_wayfar.lua`

**Cell Map:**
| Cell ID | Notes |
|---------|-------|
| 1134559 | Outer room |
| 1134560 | Main cantina floor |
| 1499418 | Info broker side room |
| 1499419 | Main bar area |
| 1499420 | Back room (trainer) |
| 1499424 | Lower area |

```lua
-- Cell 1134559 / 1134560 — main cantina
{"artisan",60,34.4931,0.104999,-6.47601,180,1134559, "conversation"},
{"bounty_hunter",300,34.4931,0.104999,-7.576,0,1134559, "sad"},
{"artisan",60,-3.85346,-0.894991,6.73775,0,1134560, "conversation"},
{"businessman",60,4.86041,-0.894992,6.38401,249.175,1134560, ""},
{"noble",60,-5.69909,-0.894992,-10.4035,79.4873,1134560, ""},
{"osweri_hepa",60,11.3838,-0.894992,-2.63465,180.006,1134560, "conversation"},
{"medic",300,11.3838,-0.894992,-3.73465,0,1134560, "conversation"},
{"mercenary",300,10.2838,-0.894992,-2.63465,135.005,1134560, "calm"},
{"commoner_fat",300,-3.85346,-0.894991,7.83775,180.003,1134560, "conversation"},

-- Cell 1499418 / 1499419 / 1499420 / 1499424 — side bar area
{"info_broker",60,4.7,1.0,4.6,-148,1499418, "sad"},
{"entertainer",60,6.82411,0.40827,-8.7422,0,1499419, "conversation"},
{"brawler",300,6.82411,0.408269,-7.6422,180,1499419, "angry"},
{"commoner_technician",300,5.72411,0.408269,-7.6422,135.001,1499419, "conversation"},
{"trainer_medic",0,-8.4035,1.00421,8.19643,110,1499420, ""},
{"brawler",300,-7.85116,-3.96617,6.43429,272.53,1499424, ""},
{"devaronian_male",60,-2.4,0.4,-10.1,176,1499419, "neutral"},
{"commoner_fat",60,-8.9,0.4,2.2,179,1499419, "npc_sitting_chair"},
{"entertainer",60,-10.2,-4.0,6.5,-90,1499424, "sad"},
```

---

## CORELLIA

### Coronet Cantina
**File:** `screenplays/cities/corellia_coronet.lua`
**Cell ID:** 8105496

```lua
{"bounty_hunter",300,3.61201,-0.894992,-8.73417,135.006,8105496, "conversation"},
{"info_broker",300,2.80432,-0.894991,10.6543,180.012,8105496, "conversation"},
{"businessman",60,-7.91375,-0.894992,-4.88587,179.995,8105496, "conversation"},
{"corellia_times_reporter",300,-7.91375,-0.894992,-5.88587,0,8105496, "conversation"},
{"ithorian_male",300,4.71201,-0.894992,-8.73417,180.01,8105496, "conversation"},
{"entertainer",60,2.80432,-0.894991,9.55434,360.011,8105496, "conversation"},
{"farmer_rancher",60,4.71201,-0.894992,-9.83418,360.011,8105496, "conversation"},
```
**Bartender** spawned by `BartendersScreenPlay`: `{"bartender", "corellia", 8105496}`

---

### Tyrena Cantina
**File:** `screenplays/cities/corellia_tyrena.lua`
**Cell IDs:** 2625353, 2625355, 2625358

```lua
{"comm_operator",400,48.13,0.105,2.47,248.001,2625353, "npc_imperial"},
{"trainer_dancer", 0,16.7961,-0.894993,-10.1031,3,2625355, ""},
{"trainer_musician", 0,21.1399,-0.894993,8.20648,120,2625355, ""},
{"trainer_entertainer", 0,6.15345,-0.894992,-19.3905,0,2625358, ""},
```
**Bartender** spawned by `BartendersScreenPlay`: `{"bartender", "corellia", 2625355}`

---

### Doaba Guerfel Cantina
**File:** `screenplays/cities/corellia_doaba_guerfel.lua`
**Cell IDs:** 3075427, 3075429, 3075430, 3075441

```lua
{"noble",60,-42.098,0.105009,-23.0786,180.012,3075441, "conversation"},
{"mercenary",300,-42.098,0.105009,-24.1786,0,3075441, "nervous"},
{"corellia_times_reporter",300,21.878,-0.894997,-15.7126,0,3075430, "conversation"},
{"patron_ithorian",300,40.8822,0.104999,2.22818,0,3075427, "conversation"},
{"commoner_naboo",300,8.35364,-0.894992,6.38149,360.011,3075429, "conversation"},
{"entertainer",60,21.878,-0.894997,-14.6126,179.999,3075430, "entertained"},
{"farmer_rancher",60,8.35364,-0.894992,7.38149,179.999,3075429, "conversation"},
{"contractor",60,40.8822,0.104999,3.32819,180.003,3075427, "worried"},
```
**Bartender** spawned by `BartendersScreenPlay`: `{"bartender", "corellia", 3075429}`

---

### Kor Vella Cantina
**File:** `screenplays/cities/corellia_kor_vella.lua`
**Cell IDs:** 3005397, 3005398, 3005399

```lua
{"comm_operator", 400, 48.13, 0.1, 2.47, 292, 3005397, ""},
{"artisan", 60, 34.4, 0.1, -8.04, 0, 3005398, ""},
{"mercenary", 300, 34.4, 0.1, -6.9, 180, 3005398, ""},
{"trainer_dancer", 0, 34.5107, 0.105, 1.79681, 89, 3005398, ""},
{"trainer_entertainer", 1, 26.2, -0.9, 10.25, 260, 3005399, ""},
```
**Bartender** spawned by `BartendersScreenPlay`: `{"bartender", "corellia", 3005399}`

---

### Bela Vistal Cantina
**File:** `screenplays/cities/corellia_bela_vistal.lua`
**Cell ID:** 3375355

```lua
{"noble", 60, 5.80982, -0.894992, -5.41349, 248.205, 3375355, ""},
{"businessman", 60, -10.2935, -0.895782, 7.13264, 339.313, 3375355, ""},
```
**Bartender** spawned by `BartendersScreenPlay`: `{"bartender", "corellia", 3375355}`

---

## NABOO

### Theed Cantina
**File:** `screenplays/cities/naboo_theed.lua`
**Cell ID:** 96

Theed uses Pattern B (direct `spawnMobile` call):
```lua
--Cantina
pNpc = spawnMobile(self.planet, "junk_dealer", 0, -5.8, -0.9, -20.9, -52, 96)
if pNpc ~= nil then
    AiAgent(pNpc):setConvoTemplate("junkDealerArmsConvoTemplate")
end
```
**Bartender** spawned by `BartendersScreenPlay`: `{"bartender", "naboo", 91}` (Theed cell)

---

### Moenia Cantina
**File:** `screenplays/cities/naboo_moenia.lua`
**Cell ID:** 119

```lua
--Cantina
{"rebel_recruiter",0,-29,-0.89,-1.2,74,119, ""},
{"informant_npc_lvl_3",0,-2.2226,-0.894992,5.90785,90,111, ""},
```
**Bartender** spawned by `BartendersScreenPlay`: `{"bartender", "naboo", 111}`

---

## TALUS

### Dearic Cantina
**File:** `screenplays/cities/talus_dearic.lua`
**Cell IDs:** 3175391, 3175397, 3175403 (and nearby 3175389, 3175390, 3175393)

```lua
--Cantina
{"businessman",60,-5.0724,-0.894996,21.4966,284.21,3175397, ""},
{"medic",60,-44.5373,0.105009,-20.8963,0,3175403, "conversation"},
{"pilot",60,-44.5373,0.104709,-19.7963,180.005,3175403, "npc_consoling"},
{"agriculturalist",60,12.85,-0.894992,1.20077,360.011,3175391, "conversation"},
{"mercenary",300,12.85,-0.894992,2.30077,180.005,3175391, "npc_accusing"},
{"commoner_technician",60,18.5617,-0.894992,17.5882,360.011,3175393, "nervous"},
{"vendor",60,18.5617,-0.894992,18.6882,180.006,3175393, "npc_consoling"},
{"bounty_hunter",60,34.3579,0.105,2.70668,135.004,3175390, "conversation"},
{"businessman",60,35.4579,0.105,2.70668,180.005,3175390, "conversation"},
{"farmer",60,43.6156,0.104999,0.752079,0,3175389, "conversation"},
{"ithorian_male",300,43.6156,0.104999,1.85208,180.005,3175389, "conversation"},
```
**Bartender** spawned by `BartendersScreenPlay`: `{"bartender", "talus", 3175391}`

---

### Nashal Cantina
**File:** `screenplays/cities/talus_nashal.lua`
**Cell IDs:** 4265374, 4265375, 4265376

```lua
--Cantina
{"bounty_hunter",60,35.6665,0.105,2.3343,180.006,4265374, "angry"},
{"seeker",300,35.6665,0.105,1.2343,360.011,4265374, "neutral"},
{"ithorian_male",300,21.4737,-0.894997,-13.904,180.01,4265376, "conversation"},
{"artisan",60,21.4737,-0.894997,-14.904,360.011,4265376, "conversation"},
{"artisan",60,2.49489,-0.894992,-5.58394,0,4265375, "conversation"},
{"info_broker",60,11.3604,-0.894992,5.58351,180.01,4265375, "conversation"},
{"commoner_technician",60,2.49489,-0.894992,-4.58394,179.992,4265375, "conversation"},
{"commoner",60,11.3604,-0.894992,4.58351,360.011,4265375, "nervous"},
```
**Bartender** spawned by `BartendersScreenPlay`: `{"bartender", "talus", 4265375}`

---

## LOK

### Nym's Stronghold Cantina
**File:** `screenplays/cities/lok_nym_stronghold.lua`
**Cell IDs:** 8145378 (main hall), 8145383 (cantina room)

```lua
--cantina
{"businessman",60,-12.2,-0.9,-20.1,-85,8145383, "npc_consoling"},
{"vixur_webb", 60, -13.2, -0.9, -20.2, 22, 8145383, "npc_sitting_chair"},
```
**Bartender** spawned by `BartendersScreenPlay`: `{"bartender", "lok", 8145378}`

---

## RORI

### Rebel Outpost Tavern
**File:** `screenplays/cities/rori_rebel_outpost.lua`
**Cell IDs:** 4505635, 4505636, 4505637

```lua
-- Tavern
{"rebel_medic", 360, -8.5, 0.6, -7.3, 47, 4505636, ""},
{"specforce_marine", 360, 2.2, 0.6, -2.2, 243, 4505636, ""},
{"specforce_marine", 360, 2.1, 0.6, -6.5, 280, 4505636, ""},
{"rebel_high_general", 360, 7.8, 0.6, -4.4, 270, 4505637, ""},
{"ufwol", 360, -8.4, 0.6, 3.5, 88, 4505635, ""},
```

---

## DANTOOINE

### Agro Outpost Cantina
**File:** `screenplays/cities/dantooine_agro_outpost.lua`
**Cell IDs:** 6205496, 6205497, 6205498, 6205499

```lua
--In the Cantina
{"chiss_male",60,3.0,0.6,0.8,-42,6205496, "npc_sitting_chair"},
{"patron_devaronian",60,-7.5,0.6,5.7,-95,6205497, "npc_standing_drinking"},
{"bartender",60,-9.1,0.6,5.3,85,6205497, "conversation"},
{"businessman", 60, 8.90672, 0.625, -2.94252, 244, 6205499, ""},
{"entertainer",60,-7.77368,0.624999,-5.2158,188,6205498, "happy"},
```

---

### Mining Outpost Cantina
**File:** `screenplays/cities/dantooine_mining_outpost.lua`
**Cell IDs:** 6205565, 6205566, 6205567

```lua
--In The Cantina
{"artisan",60,8.8,0.6,-4.9,-93,6205567, "sad"},
{"businessman", 60, -8, 0.6, -6, 83, 6205566, ""},
{"adwan_turoldine",60,-9.37871,0.625,2.98841,82.9313,6205565, "neutral"},
```

---

### Imperial Outpost Tavern
**File:** `screenplays/cities/dantooine_imperial_outpost.lua`
**Cell ID:** 1365879

```lua
--tavern
{"scientist",60,3.3,0.1,4.5,127,1365879, "npc_sitting_table_eating"},
```

---

## ENDOR

### Research Outpost Tavern
**File:** `screenplays/cities/endor_research_outpost.lua`
**Cell ID:** 9925367

Uses Pattern B (direct spawnMobile):
```lua
--tavern building
pNpc = spawnMobile("endor", "kilnstrider", 60, -3.44448, 0.624999, -6.82681, 331.362, 9925367)
if pNpc ~= nil then
    self:setMoodString(pNpc, "npc_imperial")
    if CreatureObject(pNpc):getPvpStatusBitmask() == 0 and CreatureObject(pNpc):getOptionsBitmask() > 0 then
        CreatureObject(pNpc):clearOptionBit(AIENABLED)
    end
end
```

---

### Smuggler Outpost Tavern
**File:** `screenplays/cities/endor_smuggler_outpost.lua`
**Cell ID:** 6645605

```lua
--tavern
local pNpc = spawnMobile("endor", "commoner_old", 60, 1.0, 0.7, -4.4, 0, 6645605)
if pNpc ~= nil then
    self:setMoodString(pNpc, "npc_sitting_chair")
    CreatureObject(pNpc):setOptionsBitmask(0)
end
```

---

## YAVIN 4

### Mining Outpost Taverns (A & B)
**File:** `screenplays/cities/yavin4_mining_outpost.lua`
**Cell IDs:** 7925449 (tavern B), 7925451 (tavern B entry), 7925478 (tavern A)

**Tavern A (7925478):**
```lua
{1, 3.1, 0.7, 2.4, 0, 7925478, "npc_sitting_chair"},
{1, 2.3, 0.7, 6.5, -5, 7925478, "sad"},
-- R3 droid patrols through this cell:
surgical_1 = {{-1.9, 0.7, 2.5, 7925478, false}, {-1.8, 0.7, 4.4, 7925478, false}, ...}
```

**Tavern B (7925449, 7925451):**
```lua
{1, 0.4, 0.6, -0.7, -179, 7925451, "npc_sitting_chair"},
{1, 3.5, 0.6, 4.2, -5, 7925449, "npc_standing_drinking"},
-- Bartender (direct call):
local pNpc = spawnMobile("yavin4", "bartender", 60, 3.4, 0.6, 5.6, 173, 7925449)
```

---

## MANDALORIAN RECRUITER — Full Placement Analysis

### Mobile Definition
**File:** `mobile/bellum/mando_trialmaster.lua`
```lua
mando_trialmaster = Creature:new {
    objectName   = "",
    customName   = "Mandalorian Recruiter",
    socialGroup  = "neutral",
    faction      = "",
    mobType      = MOB_NPC,
    level        = 50,
    chanceHit    = 0.5,
    damageMin    = 100,
    damageMax    = 200,
    baseXp       = 0,
    baseHAM      = 5000,
    baseHAMmax   = 6000,
    armor        = 0,
    resists      = {0,0,0,0,0,0,0,-1,-1},
    pvpBitmask   = 0,
    creatureBitmask = NONE,
    optionsBitmask  = AIENABLED + INVULNERABLE + CONVERSABLE,
    templates    = {"object/mobile/dressed_bountyhunter_trainer_01.iff"},
    conversationTemplate = "mandoTrialmasterConvoTemplate",
    primaryAttacks  = brawlermid,
    secondaryAttacks = {},
}
```

### Spawn Configuration
**File:** `screenplays/bellum/mando_way_of_life.lua` (lines 22–31)
```lua
recruiterConfig = {
    planet   = "tatooine",
    x        = 6.8,
    z        = -0.894992,
    y        = 4.2,
    heading  = 200,
    cellId   = 1082877,
    template = "mando_trialmaster",
    name     = "Mando Recruiter",
},
```

### Actual Spawn Logic
**File:** `screenplays/bellum/mando_way_of_life.lua` (lines 98–136)
```lua
function MandoWayOfLife:start()
    local cfg = self.recruiterConfig
    local cellId = cfg.cellId or 0

    if (isZoneEnabled(cfg.planet) == false) then
        logLua(1, "[MandoWayOfLife] recruiter not spawned: zone not enabled.")
        return
    end

    local pRecruiter = spawnMobile(cfg.planet, cfg.template, 0, cfg.x, cfg.z, cfg.y, cfg.heading, cellId)
    if (pRecruiter ~= nil) then
        CreatureObject(pRecruiter):setPvpStatusBitmask(0)
        CreatureObject(pRecruiter):setOptionsBitmask(AIENABLED + INVULNERABLE + CONVERSABLE)
        SceneObject(pRecruiter):setCustomObjectName(cfg.name)
        AiAgent(pRecruiter):setConvoTemplate("mandoTrialmasterConvoTemplate")
        AiAgent(pRecruiter):addObjectFlag(AI_STATIC)
        writeData("mando_way:recruiter_id", SceneObject(pRecruiter):getObjectID())
        logLua(1, "[MandoWayOfLife] boot: recruiter spawned OK (Mos Eisley cantina main room).")
    else
        logLua(1, string.format(
            "[MandoWayOfLife] recruiter spawn FAILED: template=%s planet=%s x=%s z=%s y=%s heading=%s cellId=%s",
            tostring(cfg.template), tostring(cfg.planet),
            tostring(cfg.x), tostring(cfg.z), tostring(cfg.y),
            tostring(cfg.heading), tostring(cellId)
        ))
    end
end
```

### Recruiter Position in Context of Cell 1082877

The Recruiter is at **(6.8, -0.894992, 4.2)** heading **200°**. Here are the nearby NPCs for spatial context:

```lua
-- ~2 units away
{"entertainer",60,9.4,0,3.9,310,1082877, "conversation"},         -- X+2.6 from recruiter
{"patron",60,6.8,-0.9,-6.5,230,1082877, "entertained"},            -- same X, Y-10.7 (far south)
{"noble",60,8.49,-0.894992,4.64,128.74,1082877, "conversation"},   -- X+1.7, Y+0.4

-- Stormtroopers in same cell
{"stormtrooper",400,2.84,-0.894992,-6.3,16.0005,1082877, "npc_imperial"},
{"stormtrooper_squad_leader",400,3.62,-0.894992,-6.78,360.011,1082877, "npc_accusing"},
```

The recruiter is positioned heading 200° (roughly southwest) in a cluster with the entertainer and noble, near the bar side of the main hall.

---

## Key Observations for Recruiter Placement Debugging

### 1. The Recruiter Uses Pattern B (spawnMobile), Not the Mobiles Table
Unlike most cantina NPCs (Pattern A), the recruiter is spawned via a direct `spawnMobile()` call in `MandoWayOfLife:start()`. This means:
- He only spawns when the screenplay boots successfully
- He will not auto-respawn if killed (respawn = `0`)
- If the screenplay fails to register or `start()` throws before the spawn call, he never appears
- He's stored by object ID: `writeData("mando_way:recruiter_id", ...)`

### 2. Common Failure Modes
| Symptom | Likely Cause |
|---------|-------------|
| Recruiter never appears | `isZoneEnabled("tatooine")` returned false at boot, OR `spawnMobile()` returned nil (bad cellId or coordinates inside geometry) |
| Recruiter appears but can't be talked to | `setConvoTemplate` failed, or `mandoTrialmasterConvoTemplate` not registered |
| Recruiter appears in wrong position | `recruiterConfig` coordinates are wrong for the cell |
| Recruiter disappears after server restart | No respawn (`0`) — if killed before shutdown, gone on reload |
| Recruiter appears twice | `MandoWayOfLife:start()` was called more than once (double-registration) |

### 3. Ground Level in Cell 1082877
The correct Z height for ground-level NPCs in cell 1082877 is **-0.894992** (used by nearly all static NPCs in this cell). The recruiter correctly uses this value.

### 4. How to Verify Recruiter ID After Boot
The screenplay stores the recruiter's object ID:
```lua
writeData("mando_way:recruiter_id", SceneObject(pRecruiter):getObjectID())
```
You can read this in-game with:
```
/getserverobject mando_way:recruiter_id
```
If 0 or nil, the recruiter never spawned.

### 5. Log Check
The screenplay emits boot logs at level 1 (always visible):
```
[MandoWayOfLife] boot: recruiter spawned OK (Mos Eisley cantina main room).
-- or --
[MandoWayOfLife] recruiter spawn FAILED: template=... planet=... x=... cellId=...
```
Check `MMOCoreORB/bin/log/lua.log` after server boot.
