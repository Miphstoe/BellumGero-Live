# SWG Core3 File/Code Structure Context

This file captures a snapshot of the repository/folder layout for:

- **Path**: `D:\SWGProjects\Core3`
- **Captured**: 2026-02-01 (from terminal output)

## High-level layout

- `build/`
- `docker/`
  - `files/firstboot/home-files/`
    - `bin/`
    - `mysql/`
- `linux/`
- `MMOCoreORB/`
  - `.externalToolBuilders/`
  - `.settings/`
  - `bin/`
    - `conf/`
    - `custom_scripts/`
    - `databases/`
    - `log/admin/`
    - `navmeshes/`
    - `scripts/` (many subtrees: `ai/`, `commands/`, `loot/`, `mobile/`, `object/`, `screenplays/`, etc.)
    - `terrain/`
  - `build/` (`unix/config/`, `win32/SWGEmu2005/`)
  - `cmake/Modules/`
  - `doc/` (AI, charts, ConversationEditor, dummies, www/css)
  - `sql/updates/archived/`
  - `src/` (client, server, templates, terrain, tests, tre3, utils, etc.)
  - `utils/` (engine, engine3, googletest-release-1.13.0, etc.)
- `wsl2/`

## Full `tree` output (verbatim)

```text
PS D:\SWGProjects\Core3> tree
Folder PATH listing for volume Slower
Volume serial number is BEF4-6D00
D:.
├───build
├───docker
│   └───files
│       └───firstboot
│           └───home-files
│               ├───bin
│               └───mysql
├───linux
├───MMOCoreORB
│   ├───.externalToolBuilders
│   ├───.settings
│   ├───bin
│   │   ├───conf
│   │   ├───custom_scripts
│   │   ├───databases
│   │   ├───log
│   │   │   └───admin
│   │   ├───navmeshes
│   │   ├───scripts
│   │   │   ├───ai
│   │   │   ├───ai_space
│   │   │   ├───commands
│   │   │   ├───custom_scripts
│   │   │   │   ├───loot
│   │   │   │   ├───mobile
│   │   │   │   ├───object
│   │   │   │   └───screenplays
│   │   │   ├───loot
│   │   │   │   ├───groups
│   │   │   │   │   ├───armor
│   │   │   │   │   ├───bestine_election
│   │   │   │   │   ├───component_loot
│   │   │   │   │   ├───corellian_corvette
│   │   │   │   │   ├───creature
│   │   │   │   │   ├───death_watch_bunker
│   │   │   │   │   ├───forage
│   │   │   │   │   ├───generic_quests
│   │   │   │   │   ├───geonosian_lab
│   │   │   │   │   ├───hero_of_tatooine
│   │   │   │   │   ├───npc
│   │   │   │   │   │   ├───corellia
│   │   │   │   │   │   ├───dantooine
│   │   │   │   │   │   ├───dathomir
│   │   │   │   │   │   ├───endor
│   │   │   │   │   │   ├───faction
│   │   │   │   │   │   │   ├───imperial
│   │   │   │   │   │   │   └───rebel
│   │   │   │   │   │   ├───lok
│   │   │   │   │   │   ├───naboo
│   │   │   │   │   │   ├───rori
│   │   │   │   │   │   ├───talus
│   │   │   │   │   │   ├───tatooine
│   │   │   │   │   │   ├───thug
│   │   │   │   │   │   ├───townsperson
│   │   │   │   │   │   └───yavin4
│   │   │   │   │   ├───resource
│   │   │   │   │   ├───ship
│   │   │   │   │   │   └───components
│   │   │   │   │   ├───space
│   │   │   │   │   │   ├───faction
│   │   │   │   │   │   ├───special_loot
│   │   │   │   │   │   └───story_loot
│   │   │   │   │   ├───task_loot
│   │   │   │   │   ├───task_reward
│   │   │   │   │   ├───theme_park_loot
│   │   │   │   │   ├───theme_park_reward
│   │   │   │   │   ├───village
│   │   │   │   │   ├───weapon
│   │   │   │   │   └───wearables
│   │   │   │   └───items
│   │   │   │       ├───armor
│   │   │   │       ├───bestine_election
│   │   │   │       ├───coa
│   │   │   │       ├───component_loot
│   │   │   │       ├───corellian_corvette
│   │   │   │       ├───creature
│   │   │   │       ├───death_watch_bunker
│   │   │   │       ├───forage
│   │   │   │       ├───geonosian_lab
│   │   │   │       ├───hero_of_tatooine
│   │   │   │       ├───junk
│   │   │   │       ├───loot_kit
│   │   │   │       ├───loot_schematic
│   │   │   │       ├───misc
│   │   │   │       ├───npc
│   │   │   │       ├───painting
│   │   │   │       ├───quest
│   │   │   │       ├───recycler
│   │   │   │       ├───resource
│   │   │   │       ├───ship
│   │   │   │       │   └───components
│   │   │   │       │       ├───armor
│   │   │   │       │       ├───booster
│   │   │   │       │       ├───droid_interface
│   │   │   │       │       ├───engine
│   │   │   │       │       ├───reactor
│   │   │   │       │       ├───shield_generator
│   │   │   │       │       ├───weapon
│   │   │   │       │       └───weapon_capacitor
│   │   │   │       ├───skill_buff
│   │   │   │       ├───space
│   │   │   │       │   ├───mission_objects
│   │   │   │       │   ├───special_loot
│   │   │   │       │   └───story_loot
│   │   │   │       ├───task_loot
│   │   │   │       ├───task_reward
│   │   │   │       ├───themepark_loot
│   │   │   │       ├───themepark_reward
│   │   │   │       ├───weapon
│   │   │   │       └───wearables
│   │   │   │           ├───apron
│   │   │   │           ├───bandolier
│   │   │   │           ├───belt
│   │   │   │           ├───bikini
│   │   │   │           ├───bodysuit
│   │   │   │           ├───boots
│   │   │   │           ├───bracelet
│   │   │   │           ├───bustier
│   │   │   │           ├───dress
│   │   │   │           ├───gloves
│   │   │   │           ├───hat
│   │   │   │           ├───helmet
│   │   │   │           ├───ithorian
│   │   │   │           ├───jacket
│   │   │   │           ├───necklace
│   │   │   │           ├───pants
│   │   │   │           ├───ring
│   │   │   │           ├───robe
│   │   │     │           ├───shirt
│   │   │   │           ├───shoes
│   │   │   │           ├───skirt
│   │   │   │           ├───vest
│   │   │   │           └───wookiee
│   │   │   ├───managers
│   │   │   ├───mobile
│   │   │   ├───object
│   │   │   ├───screenplays
│   │   │   ├───ship_mobile
│   │   │   ├───skills
│   │   │   ├───staff
│   │   │   └───utils
│   │   └───terrain
│   ├───build
│   │   ├───unix
│   │   │   └───config
│   │   └───win32
│   │       └───SWGEmu2005
│   ├───cmake
│   │   └───Modules
│   ├───doc
│   │   ├───AI
│   │   ├───charts
│   │   ├───ConversationEditor
│   │   ├───dummies
│   │   │   └───ZoneDummyReversing
│   │   │       ├───conf
│   │   │       ├───Include
│   │   │       ├───Lib
│   │   │       ├───packets
│   │   │       ├───raw
│   │   │       └───VC8
│   │   └───www
│   │       └───css
│   ├───sql
│   │   └───updates
│   │       └───archived
│   │   ├───src
│   ├───utils
└───wsl2
PS D:\SWGProjects\Core3>
```
