# Admin `/object` spawn reference (Bellum / Core3)

Privileged staff only. Run from in-game. **Requires rebuilt `core3`** with `/object createwearable` if you use that subcommand.

## Conventions

| Kind | Command | Sockets |
|------|---------|--------|
| **Armor, clothing, any wearable** | **`/object createwearable`** | **`4`** (max SEA sockets; shown on every line below) |
| **Weapons** | `/object createitem` | Wearable SEA sockets do **not** apply to weapons |
| **Attachments** | `/object createattachment` | N/A (creates the gem) |

Syntax:

```text
/object createwearable <full_template_path.iff> 4
/object createitem <full_template_path.iff>
/object createattachment AA|CA <stat_key> [1-25]
```

Wearables spawn with display suffix **`(Socketed)`** when using `createwearable`.

---

## Bellum weapons (`createitem`)

```text
/object createitem object/weapon/ranged/pistol/pistol_bellum_bowcaster_stats.iff
/object createitem object/weapon/ranged/carbine/carbine_bellum_bowcaster_stats.iff
/object createitem object/weapon/ranged/pistol/pistol_foundling_cdef_beskar.iff
/object createitem object/weapon/ranged/rifle/rifle_foundling_cdef_beskar.iff
/object createitem object/weapon/ranged/carbine/carbine_foundling_cdef_beskar.iff
```

---

## Kashyyykian / Wookie armor (`createwearable` … `4`)

### Kashyyykian hunting

```text
/object createwearable object/tangible/wearables/armor/kashyyykian_hunting/armor_kashyyykian_hunting_chest_plate.iff 4
/object createwearable object/tangible/wearables/armor/kashyyykian_hunting/armor_kashyyykian_hunting_leggings.iff 4
/object createwearable object/tangible/wearables/armor/kashyyykian_hunting/armor_kashyyykian_hunting_bracer_l.iff 4
/object createwearable object/tangible/wearables/armor/kashyyykian_hunting/armor_kashyyykian_hunting_bracer_r.iff 4
```

### Kashyyykian black mountain

```text
/object createwearable object/tangible/wearables/armor/kashyyykian_black_mtn/armor_kashyyykian_black_mtn_chest_plate.iff 4
/object createwearable object/tangible/wearables/armor/kashyyykian_black_mtn/armor_kashyyykian_black_mtn_leggings.iff 4
/object createwearable object/tangible/wearables/armor/kashyyykian_black_mtn/armor_kashyyykian_black_mtn_bracer_l.iff 4
/object createwearable object/tangible/wearables/armor/kashyyykian_black_mtn/armor_kashyyykian_black_mtn_bracer_r.iff 4
```

### Kashyyykian ceremonial

```text
/object createwearable object/tangible/wearables/armor/kashyyykian_ceremonial/armor_kashyyykian_ceremonial_chest_plate.iff 4
/object createwearable object/tangible/wearables/armor/kashyyykian_ceremonial/armor_kashyyykian_ceremonial_leggings.iff 4
/object createwearable object/tangible/wearables/armor/kashyyykian_ceremonial/armor_kashyyykian_ceremonial_bracer_l.iff 4
/object createwearable object/tangible/wearables/armor/kashyyykian_ceremonial/armor_kashyyykian_ceremonial_bracer_r.iff 4
```

---

## Wookie clothing (`createwearable` … `4`)

### Shirts & skirts

```text
/object createwearable object/tangible/wearables/wookiee/wke_shirt_s01.iff 4
/object createwearable object/tangible/wearables/wookiee/wke_shirt_s02.iff 4
/object createwearable object/tangible/wearables/wookiee/wke_shirt_s03.iff 4
/object createwearable object/tangible/wearables/wookiee/wke_shirt_s04.iff 4
/object createwearable object/tangible/wearables/wookiee/wke_skirt_s01.iff 4
/object createwearable object/tangible/wearables/wookiee/wke_skirt_s02.iff 4
/object createwearable object/tangible/wearables/wookiee/wke_skirt_s03.iff 4
/object createwearable object/tangible/wearables/wookiee/wke_skirt_s04.iff 4
```

### Gloves, hoods, hat, shoulder pads

```text
/object createwearable object/tangible/wearables/wookiee/wke_gloves_s01.iff 4
/object createwearable object/tangible/wearables/wookiee/wke_gloves_s02.iff 4
/object createwearable object/tangible/wearables/wookiee/wke_gloves_s03.iff 4
/object createwearable object/tangible/wearables/wookiee/wke_gloves_s04.iff 4
/object createwearable object/tangible/wearables/wookiee/wke_hood_s01.iff 4
/object createwearable object/tangible/wearables/wookiee/wke_hood_s02.iff 4
/object createwearable object/tangible/wearables/wookiee/wke_hood_s03.iff 4
/object createwearable object/tangible/wearables/wookiee/wke_hat_s01.iff 4
/object createwearable object/tangible/wearables/wookiee/wke_shoulder_pad_s01.iff 4
/object createwearable object/tangible/wearables/wookiee/wke_shoulder_pad_s02.iff 4
```

### Lifeday robes (full-body; still wearables — sockets apply if type supports menu)

```text
/object createwearable object/tangible/wearables/wookiee/wke_lifeday_robe.iff 4
/object createwearable object/tangible/wearables/wookiee/wke_lifeday_robe_m.iff 4
/object createwearable object/tangible/wearables/wookiee/wke_lifeday_robe_f.iff 4
```

---

## Attachments — examples

Armor piece → **AA**; clothing → **CA**. Stat keys must match `ObjectCommand` whitelist (`src/server/zone/objects/creature/commands/ObjectCommand.h`).

```text
/object createattachment AA pistol_accuracy 25
/object createattachment CA clothing_assembly 25
```

---

## Armor attachments (`AA`) — every allowed stat at **25**

**Only** these mods work with `AA`. There is no `bounty_hunter_*`, `terrain_negotiation`, or generic `*_aim` on this list in Core3’s command check. Use **`/object createattachment AA <stat> 25`** (copy block below).

### By category (same commands as full list)

**Pistol**

```text
/object createattachment AA pistol_accuracy 25
/object createattachment AA pistol_hit_while_moving 25
/object createattachment AA pistol_speed 25
/object createattachment AA pistol_accuracy_while_standing 25
```

**Carbine**

```text
/object createattachment AA carbine_accuracy 25
/object createattachment AA carbine_hit_while_moving 25
/object createattachment AA carbine_speed 25
```

**Rifle**

```text
/object createattachment AA rifle_accuracy 25
/object createattachment AA rifle_hit_while_moving 25
/object createattachment AA rifle_speed 25
```

**Heavy rifle (lightning)**

```text
/object createattachment AA heavy_rifle_lightning_accuracy 25
/object createattachment AA heavy_rifle_lightning_speed 25
```

**Melee**

```text
/object createattachment AA onehandmelee_accuracy 25
/object createattachment AA onehandmelee_speed 25
/object createattachment AA twohandmelee_accuracy 25
/object createattachment AA twohandmelee_speed 25
/object createattachment AA polearm_accuracy 25
/object createattachment AA polearm_speed 25
/object createattachment AA unarmed_accuracy 25
/object createattachment AA unarmed_speed 25
/object createattachment AA thrown_accuracy 25
/object createattachment AA thrown_speed 25
```

**Movement / “terrain” (closest on AA list)**

```text
/object createattachment AA slope_move 25
/object createattachment AA group_slope_move 25
```

**Defense / posture / states**

```text
/object createattachment AA blind_defense 25
/object createattachment AA block 25
/object createattachment AA camouflage 25
/object createattachment AA combat_bleeding_defense 25
/object createattachment AA counterattack 25
/object createattachment AA dizzy_defense 25
/object createattachment AA dodge 25
/object createattachment AA intimidate 25
/object createattachment AA intimidate_defense 25
/object createattachment AA knockdown_defense 25
/object createattachment AA melee_defense 25
/object createattachment AA posture_change_down_defense 25
/object createattachment AA posture_change_up_defense 25
/object createattachment AA ranged_defense 25
/object createattachment AA rescue 25
/object createattachment AA stun_defense 25
```

**Resistances**

```text
/object createattachment AA resistance_bleeding 25
/object createattachment AA resistance_disease 25
/object createattachment AA resistance_fire 25
/object createattachment AA resistance_poison 25
```

**Droid**

```text
/object createattachment AA droid_find_chance 25
/object createattachment AA droid_find_speed 25
/object createattachment AA droid_track_chance 25
/object createattachment AA droid_track_speed 25
```

**Creature / misc**

```text
/object createattachment AA foraging 25
/object createattachment AA keep_creature 25
/object createattachment AA tame_aggro 25
/object createattachment AA tame_bonus 25
/object createattachment AA tame_non_aggro 25
```

### Full list — alphabetical (all **AA** @ 25)

```text
/object createattachment AA blind_defense 25
/object createattachment AA block 25
/object createattachment AA camouflage 25
/object createattachment AA carbine_accuracy 25
/object createattachment AA carbine_hit_while_moving 25
/object createattachment AA carbine_speed 25
/object createattachment AA combat_bleeding_defense 25
/object createattachment AA counterattack 25
/object createattachment AA dizzy_defense 25
/object createattachment AA dodge 25
/object createattachment AA droid_find_chance 25
/object createattachment AA droid_find_speed 25
/object createattachment AA droid_track_chance 25
/object createattachment AA droid_track_speed 25
/object createattachment AA foraging 25
/object createattachment AA group_slope_move 25
/object createattachment AA heavy_rifle_lightning_accuracy 25
/object createattachment AA heavy_rifle_lightning_speed 25
/object createattachment AA intimidate 25
/object createattachment AA intimidate_defense 25
/object createattachment AA keep_creature 25
/object createattachment AA knockdown_defense 25
/object createattachment AA melee_defense 25
/object createattachment AA onehandmelee_accuracy 25
/object createattachment AA onehandmelee_speed 25
/object createattachment AA pistol_accuracy 25
/object createattachment AA pistol_accuracy_while_standing 25
/object createattachment AA pistol_hit_while_moving 25
/object createattachment AA pistol_speed 25
/object createattachment AA polearm_accuracy 25
/object createattachment AA polearm_speed 25
/object createattachment AA posture_change_down_defense 25
/object createattachment AA posture_change_up_defense 25
/object createattachment AA ranged_defense 25
/object createattachment AA rescue 25
/object createattachment AA resistance_bleeding 25
/object createattachment AA resistance_disease 25
/object createattachment AA resistance_fire 25
/object createattachment AA resistance_poison 25
/object createattachment AA rifle_accuracy 25
/object createattachment AA rifle_hit_while_moving 25
/object createattachment AA rifle_speed 25
/object createattachment AA slope_move 25
/object createattachment AA stun_defense 25
/object createattachment AA tame_aggro 25
/object createattachment AA tame_bonus 25
/object createattachment AA tame_non_aggro 25
/object createattachment AA thrown_accuracy 25
/object createattachment AA thrown_speed 25
/object createattachment AA twohandmelee_accuracy 25
/object createattachment AA twohandmelee_speed 25
/object createattachment AA unarmed_accuracy 25
/object createattachment AA unarmed_speed 25
```

---

## Notes

- Some shirt + chest armor or glove + bracer pairs may **conflict on slots** depending on arrangement; swap variants if equip fails.
- Random rolled SEAs (optional): `/object createloot armor_attachments 300` and `/object createloot clothing_attachments 300`.
