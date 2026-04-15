# Mos Eisley Cantina — NPC Placement & Position Report

**Project:** BellumGero-Live (SWGEmu)
**Date:** 2026-03-28
**Author:** Claude Code (generated from source review)

---

## Overview

The Mos Eisley Cantina is one of the most densely populated interiors in the game. Its NPC population is driven by two systems working in parallel:

1. **`TatooineMosEisleyScreenPlay`** — defines all static/respawning NPC spawns inside the cantina cells
2. **`BartendersScreenPlay`** — manages Wuher as a fully autonomous patrolling, animating, drink-vending NPC

The cantina is divided into **4 interior cells**, each with a unique cell ID used to place NPCs into the correct room.

---

## Source Files

| File | Purpose |
|------|---------|
| `MMOCoreORB/bin/scripts/screenplays/cities/tatooine_mos_eisley.lua` | Main NPC spawn definitions for all cells |
| `MMOCoreORB/bin/scripts/screenplays/cities/cantinas/bartenders.lua` | Wuher's patrol, animation, drink system |
| `MMOCoreORB/bin/scripts/mobile/tatooine/marco_vahn.lua` | Marco Vahn NPC definition |
| `MMOCoreORB/bin/scripts/mobile/tatooine/wuher.lua` | Wuher NPC definition |
| `MMOCoreORB/bin/scripts/mobile/misc/muftak.lua` | Muftak NPC definition |
| `MMOCoreORB/bin/scripts/object/building/tatooine/cantina_tatooine.lua` | Building structure, skill mods |

---

## Cell Structure

```
Cantina Building
├── Cell 1082876 — Entrance / Outer Room
├── Cell 1082877 — Main Hall / Bar Area        ← most populated
├── Cell 1082880 — Stage / Band Performance Area
└── Cell 1082886 — Private Back Room
```

Spawn entry format in code:
```lua
{"npc_template", respawnSeconds, x, z, y, heading, cellID, "mood"}
```

> **Coordinate note:** SWGEmu uses a Y-up coordinate system. The Z value in spawn entries is the vertical (height) offset, while Y is depth/forward. All cantina NPCs sit at Z ≈ -0.9 to 0.1 (ground level inside the building).

---

## Cell 1082876 — Entrance / Outer Room

5 NPCs, all seated. Respawn: **60 seconds**.

| NPC Template | X | Z | Y | Heading | Mood |
|---|---|---|---|---|---|
| commoner_old | 36.0 | 0.1 | 0.7 | 310° | npc_sitting_chair |
| commoner_tatooine | 29.6 | 0.1 | -7.4 | 71° | npc_sitting_chair |
| commoner_tatooine | 30.9 | 0.1 | -8.8 | 10° | npc_sitting_chair |
| commoner_tatooine | 29.4 | 0.1 | -6.1 | 107° | npc_sitting_chair |
| commoner_tatooine | 35.7 | 0.1 | 3.1 | 180° | npc_sitting_table |

These NPCs provide ambient life at the cantina entrance — seated locals that set the atmosphere as players walk in.

---

## Cell 1082877 — Main Hall / Bar Area

The primary social hub of the cantina. **37 NPCs total** (including named characters). Respawn: **60 seconds** for civilians, **400 seconds** for Imperial military.

### Named NPCs

#### Marco Vahn — Booking Agent
- **Position:** (-9.34, -0.894992, 5.66) | Heading: 59°
- **Mood:** calm
- **Level:** 10
- **Template:** `object/mobile/dressed_noble_human_male_01.iff`
- **Flags:** `AIENABLED + CONVERSABLE`
- **Conversation:** `padawan_old_musician_02_convo_template`
- **Purpose:** Quest-related NPC for the Padawan / old musician storyline. Players can initiate dialogue.

#### Muftak — Creature NPC
- **Position:** (20.2, -0.9, 5.0) | Heading: 107°
- **Mood:** happy
- **Level:** 100
- **Template:** `object/mobile/muftak.iff`
- **Flags:** None (non-conversable)
- **Combat:** Unarmed, 645–1000 damage, 24,000–30,000 HAM — this creature is extremely dangerous if provoked
- **Purpose:** Lore-accurate cantina patron from A New Hope; ambient presence only

#### Wuher — Bartender
- **Spawned by:** `BartendersScreenPlay` (not the main screenplay)
- **Cell:** 1082877
- **Level:** 10
- **Template:** `object/mobile/dressed_tatooine_wuher.iff`
- **Flags:** `AIENABLED + INVULNERABLE + CONVERSABLE`
- **AI Map:** `cityPatrol`
- **Conversation:** `BartendersConversationTemplate`
- **Purpose:** Functional bartender — sells drinks, patrols the bar, plays animations. Full details in the Wuher / Bartender System section below.

#### Mandalorian Recruiter
- **Position:** (6.8, -0.894992, 4.2)
- **Purpose:** Quest NPC for the Mandalorian Way of Life questline

### Stormtrooper Presence (Respawn: 400s)

| NPC Template | X | Z | Y | Heading | Mood |
|---|---|---|---|---|---|
| stormtrooper | 2.84 | -0.894992 | -6.3 | 16° | npc_imperial |
| stormtrooper_squad_leader | 3.62 | -0.894992 | -6.78 | 360° | npc_accusing |

These two are positioned near the bar interior, watching patrons. The `npc_accusing` mood on the squad leader gives him a more threatening posture. Their 400-second respawn (vs. 60s for civilians) means they take much longer to return after being cleared.

### Generic Patrons / Commoners (Standing)

| NPC Template | X | Z | Y | Heading | Mood |
|---|---|---|---|---|---|
| businessman | 10.65 | -0.894992 | 1.91 | 330° | npc_standing_drinking |
| businessman | -4.11 | -0.894992 | 5.4 | 26.9° | happy |
| chadra_fan_female | 10.43 | -0.894992 | -1.47 | 123.1° | worried |
| chadra_fan_male | 10.7 | -0.894992 | -0.23 | 80.5° | (neutral) |
| commoner | 10.17 | -0.894992 | 2.74 | 125.1° | conversation |
| commoner_fat | 2.11 | -0.894992 | 5.4 | 180° | npc_standing_drinking |
| commoner_naboo | 3.11 | 0 | 5.4 | 161° | bored |
| commoner_naboo | 1.11 | 0 | 5.4 | 330° | npc_standing_drinking |
| commoner_naboo | -3.11 | 0 | 5.4 | 16.7° | npc_standing_drinking |
| commoner_tatooine | 4.11 | -0.894992 | 5.4 | 158.4° | npc_standing_drinking |
| commoner_tatooine | 1.99 | -0.894992 | -8.44 | 325° | conversation |
| commoner_tatooine | 1.19 | -0.894992 | -7.63 | 152° | conversation |
| entertainer | 9.4 | 0 | 3.9 | 310° | conversation |
| noble | 8.49 | -0.894992 | 4.64 | 128.7° | conversation |

### Generic Patrons (Seated — Various Species)

| NPC Template | X | Z | Y | Heading | Mood |
|---|---|---|---|---|---|
| commoner_fat | -2.2 | -0.9 | -10.9 | 65° | npc_sitting_table_eating |
| commoner_naboo | 16.1 | -0.9 | 4.1 | 340° | conversation |
| patron | 14.2 | -0.9 | -4.8 | 67° | npc_sitting_chair |
| patron | 14.7 | -0.9 | -3.0 | 147° | npc_sitting_chair |
| patron | 16.5 | -0.9 | -4.8 | 320° | npc_sitting_chair |
| patron | 24.5 | -0.9 | -8.1 | 51° | npc_sitting_table |
| patron | 26.1 | -0.9 | -8.2 | 317° | npc_sitting_table_eating |
| patron | 8.8 | -0.9 | -6.0 | 208° | entertained |
| patron | 6.8 | -0.9 | -6.5 | 230° | entertained |
| patron | -2.2 | -0.9 | 11.8 | 97° | npc_sitting_table |
| patron | 0.6 | -0.9 | 11.9 | 269° | npc_sitting_chair |
| patron_chiss | 3.62 | -0.894992 | -4.77 | 184° | sad |
| patron_chiss | 1.74 | -0.894992 | -4.91 | 95° | npc_consoling |
| patron_devaronian | 21.4 | -0.9 | 5.4 | 161° | npc_sitting_table |
| patron_ishitib | 22.3 | -0.9 | 3.1 | 339° | npc_sitting_chair |
| patron_ithorian | 14.9 | -0.9 | 4.9 | 51° | npc_sitting_table |
| patron_klaatu | 15.0 | -0.9 | 6.9 | 139° | npc_sitting_chair |
| patron_nikto | 23.4 | -0.9 | 4.8 | 272° | npc_sitting_chair |
| patron_quarren | 17.0 | -0.9 | 6.8 | 226° | npc_sitting_chair |

Notable detail: the two `patron_chiss` NPCs are placed near each other — one with mood `sad`, the other `npc_consoling`. This is intentional storytelling via NPC placement: a Chiss patron is being comforted by a companion.

---

## Cell 1082880 — Stage / Band Performance Area

**Figrin D'an and the Modal Nodes** — the iconic Bith cantina band from Star Wars Episode IV. 5 band members, all with `themepark_music_*` moods which trigger their in-game instrument animations.

Respawn: **60 seconds**.

| NPC Name | X | Z | Y | Heading | Mood |
|---|---|---|---|---|---|
| figrin_dan | 3.69 | -0.894992 | -14.4 | 50° | themepark_music_3 |
| doikk_nats | 2.32 | -0.894992 | -16.47 | 44° | themepark_music_3 |
| nalan_cheel | 0.54 | -0.894992 | -17.13 | 38° | themepark_music_1 |
| tech_mor | 4.11 | -0.894992 | -17.07 | 45° | themepark_music_2 |
| tedn_dahai | 1.29 | -0.894992 | -15.18 | 70° | themepark_music_3 |

The band is tightly clustered (X range: 0.54 to 4.11, Y range: -14.4 to -17.13), all facing roughly the same direction (~38–70°) toward the main hall. The use of three distinct `themepark_music_*` values (1, 2, 3) likely corresponds to different instrument types played per member.

There is also an **R3 droid** (`r3_1`) that patrols through this cell on a loop:
```
Patrol: (15.9, -0.89, -0.21) → (9.2, -0.9, 7.8) → (-9.4, -0.9, 8.6) → back
```

---

## Cell 1082886 — Private Back Room

Two named NPCs in the restricted back area. Respawn: **60 seconds**.

| NPC Name | X | Z | Y | Heading | Mood |
|---|---|---|---|---|---|
| dravis | -21.2103 | -0.894989 | 24.3324 | 164.4° | neutral |
| talon_karrde | -18.7 | -0.9 | 24.9 | -31° | npc_sitting_chair |

These are Expanded Universe characters — **Talon Karrde** (smuggler/information broker) and **Dravis** (his lieutenant). Their placement in a private back room is lore-consistent with their role as secretive operators. Karrde is seated; Dravis stands nearby.

---

## Wuher / Bartender System Deep Dive

Wuher is the most behaviorally complex NPC in the cantina. He is managed by `BartendersScreenPlay` independently of the main screenplay.

### Patrol System
Wuher does not have a fixed position. He has **11 patrol waypoints** that he moves between randomly:

```
(-11.1, -0.9, 2.4)    (3.0, -0.9, 3.4)     (7.2, -0.9, 2.6)
(7.5, -0.9, -1.5)     (8.2, -0.9, 1.4)     (6.7, -0.9, -2.2)
(7.2, -0.9, -1.8)     (6.3, -0.9, -2.3)    (1.4, -0.9, -2.4)
(-7.2, -0.9, -2.2)    (-10.5, -0.9, -2.2)
```

At each point he waits **15–45 seconds** (random), then moves to another random point.

### Direction Logic
After arriving at each patrol point, Wuher's facing direction is dynamically calculated based on his current position relative to the bar geometry:

- If X < -10.5: he's at the far end of the bar → faces direction 90° (away from players)
- If X > 7.3 and Y < 3.0: he's at the front end of the bar → 70% chance faces players (90°), 30% faces bar (270°)
- If Y > 2.1: right side of bar → 70% faces bar (0°), 30% faces players (180°)
- Default (left side of bar) → 70% faces bar (180°), 30% faces players (0°)

### Animation System
Two animation pools:

**Facing players** (when Wuher turns toward the crowd):
`worship, greet, nod_head_multiple, nod, applause_excited, slow_down, manipulate_medium, point_left, point_right, beckon, stretch, bounce, applause_polite, 2shot4u, expect_tip, he_dies, he_lives, hold_nose, rub_chin_thoughtful, thank, udaman, tiphat, wtf, entertained, thumbs_up_double_fisted`

**Making drinks** (when Wuher turns toward the bar):
`tap_foot, look_right, look_left, manipulate_high, manipulate_medium, scratch_head, slump_head, smell_armpit`

### Rumor System
Wuher has a **15% chance on spawn** to become a "rumor bartender." If he is, he listens to all spatial chat within range. If a player says a message that:
- Is between 10 and 60 words long, AND
- Contains one of these keywords: `jedi, spice, pixie, muon, slice, smuggler, frs, rebel, rebellion, giggledust, neutron`

Then Wuher replies: *"Ya never know what ya'll hear 'round these parts..."* and stores the player's name and message for use in rumors.

### Drink Menu (Tatooine)
| Drink | Cost |
|-------|------|
| Bantha Blood Fizz | 4 credits |
| Jawa Juice | 3 credits |
| Tatooine Sunburn | 4 credits |
| Lopez Softdrink | 5 credits |
| Ardees Beverage | 5 credits |
| Aitha Protein Drink | 5 credits |
| Milk | 5 credits |
| Bantha Blaster | 6 credits |
| Jawa Beer | 7 credits |
| Imported Utozz | 9 credits |

---

## Building Skill Mods

Defined in `cantina_tatooine.lua`, these mods apply to all players inside the cantina:

| Mod | Value | Effect |
|-----|-------|--------|
| private_med_wound_mind | 20 | Heals mind wounds |
| private_buff_mind | 100 | Buffs mind pool |
| private_med_battle_fatigue | 5 | Reduces battle fatigue |
| private_safe_logout | 1 | Allows safe logout |

The cantina functions as a rest/recovery zone. The `private_safe_logout` flag means players can log out safely from inside.

---

## NPC Count Summary

| Cell | Description | NPC Count |
|------|-------------|-----------|
| 1082876 | Entrance | 5 |
| 1082877 | Main Hall | 37 (+ Wuher via bartender system) |
| 1082880 | Stage | 5 (+ R3 droid patrol) |
| 1082886 | Back Room | 2 |
| **Total** | | **49+ NPCs** |

---

## Notable Design Observations

1. **Lore accuracy:** Named NPCs (Muftak, Figrin D'an, Wuher, Marco Vahn, Talon Karrde, Dravis) are all canon/EU characters placed in their lore-correct positions.

2. **Species diversity:** The main hall uses 10+ NPC species templates (Chiss, Devaronian, Ithorian, Klaatu, Nikto, Quarren, Chadra-Fan, etc.) to recreate the alien bar atmosphere.

3. **Behavioral storytelling:** The pair of Chiss patrons (one `sad`, one `npc_consoling`) and the stormtrooper with `npc_accusing` mood demonstrate that mood flags are used to tell micro-stories through static NPCs.

4. **Stormtrooper deterrence:** The 400-second respawn on the two stormtroopers is a deliberate design choice — long enough that clearing them gives players a meaningful window before Imperial presence returns.

5. **Wuher is the most complex NPC in the building:** He has patrol AI, positional direction logic, two animation sets, a rumor detection system, and a full functional drink shop — all layered on top of a standard NPC template.
