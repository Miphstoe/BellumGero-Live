# Infinity vehicles and mounts not yet in Bellum Gero

Source: Infinity's `datatables/mount/*` and `object/{intangible,mobile}/vehicle`, `object/tangible/deed/vehicle_deed` compared with BG's client (Oct 2026).
"Templates" = Infinity ships a control device (pcd), vehicle (mobile) and deed template. "Pose" = the rider pose the client needs; BG's player animation table (`all_m.lat`) only knows the stock poses, so every pose marked *port* has to be copied in with `lat_add_pose.py` (done for `vehicle_hover_chair`).

## Already done

| Vehicle | Saddle key | Pose | Templates | Status |
|---|---|---|---|---|
| T-47 Snowspeeder | snowspeeder | vehicle_hover_chair (ported) | pcd / mobile / deed | wired, loot schematic in `hoth_decor_rare` |

## Speeders and airspeeders

| Vehicle | Saddle key | Appearance | Pose | Templates | Notes |
|---|---|---|---|---|---|
| AB-1 Landspeeder | speeder_ab1 | speeder_ab1.apt | vehicle_landspeeder (BG has) | pcd / mobile / deed | straightforward |
| XP-38 Landspeeder | speeder_xp_38 | speeder_xp_38.apt | vehicle_landspeeder (BG has) | pcd / deed only (`landspeeder_xp38`) | no mobile template: clone one |
| Organa Speeder | bail_organa_speeder | bail_organa_speeder.apt | vehicle_landspeeder (BG has) | `landspeeder_organa` pcd/mobile, `vehicle_deed_organa_speeder` deed | names differ from saddle key |
| Sith Speeder | sith_speeder | sith_speeder.apt | vehicle_barc_speeder (BG has) | pcd / mobile / deed (`vehicle_deed_sith_speeder`) | |
| STAP | stap_speeder | stap_speeder.apt | vehicle_stap_speeder (port) | pcd (`gift_stap`) / mobile / deed (`speeder_stap`) | |
| Swamp Speeder (ISP) | swamp_speeder | swamp_speeder.apt | vehicle_swamp_speeder (port) | pcd / mobile / deed | |
| RIC-920 Speeder | speeder_ric_920 | ric_920_speeder.sat | vehicle_ric_920_speeder (port) | pcd / mobile / deed | skeletal appearance |
| Koro-2 Exodrive (Zam's speeder) | koro2_speeder | zam_speeder.apt | vehicle_zam_speeder (port) | pcd / mobile / deed | |
| Geonosian Speeder | geonosian_speeder | geonosian_speeder.apt | vehicle_geonosian_speeder (port) | pcd / mobile / deed (`geo_speeder`) | |
| A-1 Deluxe Floater | a1_deluxe_floater | a1_deluxe_floater.apt | vehicle_landspeeder (BG has) | pcd / mobile / deed | |
| XJ-6 Airspeeder | xj6_air_speeder | xj6_air_speeder.apt | vehicle_xj6_air_speeder (port) | pcd / mobile / deed | |
| Single-Pod Airspeeder | tcg_8_single_pod_airspeeder | single_pod_airspeeder.sat | vehicle_landspeeder (BG has) | pcd / mobile, deed `tcg_8_air_speeder` | |
| Air-2 Swoop | air2_swoop_speeder | air2_swoop_speeder.apt | vehicle_air2_swoop_speeder (port) | pcd / mobile, no deed | clone a deed |
| Flare-S Swoop | flare_s_swoop (+ _crafted) | flare_s_swoop.apt | vehicle_flare_swoop (port) | pcd / mobile / deed (both variants) | |
| Hoverlifter | hoverlifter_speeder (+ _crafted) | hoverlifter_speeder.apt | vehicle_hoverlifter (port) | pcd / mobile / deed (both variants) | |

## Podracers

| Vehicle | Saddle key | Appearance | Pose | Templates | Notes |
|---|---|---|---|---|---|
| Anakin's Podracer | podracer_anakin | anakin_podracer.sat | vehicle_anakin_podracer (port) | pcd / mobile / deed | |
| Balta Podracer | balta_podracer | balta_podracer.sat | vehicle_podracer_04 (port) | pcd / mobile, no deed | clone a deed |
| IPG Longtail Podracer | ipg_podracer | ipg_podracer.sat | vehicle_ipg_podracer (port) | `pod_racer_ipg_longtail` pcd/mobile, no deed | clone a deed |
| FG 8T8 Podracer | fg_8t8_podracer | fg_8t8_podracer.apt | vehicle_fg_8t8_podracer (port) | pcd / mobile, no deed | clone a deed |
| Gasgano Podracer | lb_pod_racer_one | lb_gasgano_pod_racer.sat | unknown in Infinity table | pcd / mobile / deed (`pod_racer_one`) | BG already has `pod_racer_one`; skip |

## Walkers, droids and oddities

| Vehicle | Saddle key | Appearance | Pose | Templates | Notes |
|---|---|---|---|---|---|
| Basilisk War Droid | basilisk_war_droid | basilisk_war_droid.sat | vehicle_landspeeder_lars (BG has) | pcd / mobile / deed | big skeletal mount, own `basilisk_war_droid.lat` |
| Grievous' Wheel Bike | grievous_wheel_bike | grievous_wheel_bike.sat | not in Infinity pose table | pcd / mobile / deed | pose would have to be guessed |
| Mustafar Panning Droid | panning_droid | pv_ma3_mark_2_vehicle.sat | vehicle_ma3_mark_2_vehicle (port) | pcd / mobile / deed | |
| Enclosed Military Transport | tcg_military_transport | enclosed_military_vehicle.apt | vehicle_ma3_mark_2_vehicle (port) | pcd / mobile / deed (`military_transport`) | |
| Republic Gunship (ground vehicle) | tcg_republic_gunship | republic_gunship.apt | vehicle_republic_gunship_driver (port) | pcd / mobile, no deed | drives on the ground; not a ship |
| HK-47 Jetpack | hk47_jetpack | jetpack_hk47_tcg.apt | vehicle_jetpack (BG has) | pcd / mobile, no deed | clone a deed |
| Hover Chair (Yoda's levitator) | hover_chair | yodas_levitator.apt | vehicle_hover_chair (ported) | pcd / mobile / deed | pose already in BG now |
| Mechno-Chair | mechno_chair | mechno_chair.apt | vehicle_mechno_chair (port) | pcd / mobile / deed (`vehicle_deed_mechno_chair`) | |
| Senate Pod | senate_pod | senate_pod.apt | space_sitting (BG has) | pcd / mobile, no deed | clone a deed |
| Hover Bird | hover_bird | pv_hover_bird.sat | saddle_bird_01 (port) | pcd / mobile / deed | |
| Saddle bird | mnt_saddle_bird_s01 | mnt_saddle_bird_s01.apt | saddle_body1_medium | none | a creature saddle, not a vehicle; skip |

Infinity also carries vehicle templates that reuse saddles BG already has (so no table row above): AT-ST, AT-XT, AT-PT, AT-AT and a Hoth AT-ST as walkers, Death Watch and Merr-Sonn JT-12 jetpacks, seven swoop racer colours, V-35, Tantive IV advanced, USV-5 s02, Imperial/Rebel BARC. Those need the same template work but no new pose.

## Space

BG's server already has space: `SpaceZonesEnabled` lists the space zones and the planets have JTL launch points, so flight is a BG feature, not something to port. Infinity's client additionally carries about 330 ship object templates BG lacks (extra player ships, components, asteroid fields, a snowspeeder "ship" variant). Those are a separate project: each needs server ship templates and chassis/component data, and we can't see Infinity's server side to know how they behave. The Republic gunship in the mount table is a ground vehicle, not a flyable ship.

## How the hover-chair pose works (and why no server code changes)

Rider poses are purely client-side. `datatables/mount/rider_pose_map.iff` says which pose a mount uses, and `appearance/lat/all_m.lat` maps that pose, inside every `*_riding` logical animation, to an `.ans` animation file. BG's table did not know `vehicle_hover_chair`, so the client could not seat the rider. `tools/newplanets/lat_add_pose.py` copies a pose's entries from Infinity's table into BG's (12 riding animations) and reports the `.ans` to ship; `gen_hoth_loot_client.py` runs it for `RIDER_POSES`. Adding another pose is one line in that list. The server only reads `valid_scale_range.iff`, which the generator also merges.

## Planned GM spawn commands (after wiring)

Server deed paths follow Infinity's client deed names with `shared_` removed; vehicles without an Infinity deed get a cloned `<key>_deed.iff`.

```
/object createitem object/tangible/deed/vehicle_deed/snowspeeder_deed.iff
/object createitem object/tangible/deed/vehicle_deed/landspeeder_ab1_deed.iff
/object createitem object/tangible/deed/vehicle_deed/landspeeder_xp38_deed.iff
/object createitem object/tangible/deed/vehicle_deed/vehicle_deed_organa_speeder.iff
/object createitem object/tangible/deed/vehicle_deed/vehicle_deed_sith_speeder.iff
/object createitem object/tangible/deed/vehicle_deed/speeder_stap_deed.iff
/object createitem object/tangible/deed/vehicle_deed/swamp_speeder_deed.iff
/object createitem object/tangible/deed/vehicle_deed/speeder_ric_920_deed.iff
/object createitem object/tangible/deed/vehicle_deed/koro2_speeder_deed.iff
/object createitem object/tangible/deed/vehicle_deed/geo_speeder_deed.iff
/object createitem object/tangible/deed/vehicle_deed/a1_deluxe_floater_deed.iff
/object createitem object/tangible/deed/vehicle_deed/xj6_air_speeder_deed.iff
/object createitem object/tangible/deed/vehicle_deed/tcg_8_air_speeder_deed.iff
/object createitem object/tangible/deed/vehicle_deed/air2_swoop_speeder_deed.iff
/object createitem object/tangible/deed/vehicle_deed/flare_s_swoop_deed.iff
/object createitem object/tangible/deed/vehicle_deed/hoverlifter_speeder_deed.iff
/object createitem object/tangible/deed/vehicle_deed/podracer_anakin_deed.iff
/object createitem object/tangible/deed/vehicle_deed/balta_podracer_deed.iff
/object createitem object/tangible/deed/vehicle_deed/ipg_podracer_deed.iff
/object createitem object/tangible/deed/vehicle_deed/fg_8t8_podracer_deed.iff
/object createitem object/tangible/deed/vehicle_deed/basilisk_war_droid_deed.iff
/object createitem object/tangible/deed/vehicle_deed/grievous_wheel_bike_deed.iff
/object createitem object/tangible/deed/vehicle_deed/mustafar_panning_droid_deed.iff
/object createitem object/tangible/deed/vehicle_deed/military_transport_deed.iff
/object createitem object/tangible/deed/vehicle_deed/tcg_republic_gunship_deed.iff
/object createitem object/tangible/deed/vehicle_deed/hk47_jetpack_deed.iff
/object createitem object/tangible/deed/vehicle_deed/hover_chair_deed.iff
/object createitem object/tangible/deed/vehicle_deed/vehicle_deed_mechno_chair.iff
/object createitem object/tangible/deed/vehicle_deed/senate_pod_deed.iff
/object createitem object/tangible/deed/vehicle_deed/hover_bird_deed.iff
```

Exact names get confirmed when each vehicle is generated; this list is regenerated by `make_gm_sheet.py` at that point.
