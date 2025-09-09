print("[PEKO] loading creature: peko_peko_infernomaw")

peko_peko_infernomaw = Creature:new {
  objectName = "@mob/creature_names:peko_peko_albatross",
  customName = "Infernomaw-Bird of Prey",
  socialGroup = "peko",
  faction = "",
  mobType = MOB_CARNIVORE,

  level = 350,
  chanceHit = 9.0,
  damageMin = 1600,
  damageMax = 2500,
  baseXp = 100000,
  baseHAM = 1280000,
  baseHAMmax = 1340000,
  armor = 3,
  resists = {200,200,170,200,200,200,35,35,25},

  pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
  creatureBitmask = PACK + KILLER,
  optionsBitmask = AIENABLED,
  diet = CARNIVORE,

  templates = {"object/mobile/peko_peko_hue.iff"},
  hues = {16,17,18,19,20,21,22,23},
  scale = 2.6,
  lootGroups = {
    {
      groups = {
        { group = "peko_albatross",        chance = 3500000 }, -- 35%
        { group = "clothing_attachments",  chance = 3500000 }, -- 35%
        { group = "armor_attachments",     chance = 3000000 }  -- 30%
      },
      lootChance = 10000000
    },
    {
      groups = {
        { group = "peko_albatross", chance = 3500000 }, -- 35%
        { group = "holocron_dark",  chance = 3000000 }, -- 30%
        { group = "holocron_light", chance = 3500000 }  -- 35%
      },
      lootChance = 10000000
    },
    {
      groups = {
        { group = "peko_albatross",  chance = 3000000 }, -- 30%
        { group = "power_crystals",  chance = 3500000 }, -- 35%
        { group = "color_crystals",  chance = 3500000 }  -- 35%
      },
      lootChance = 10000000
    },
    {
      groups = {
        -- FIXED: all four at 2,500,000 (25% each)
        { group = "chemistry_component_advanced", chance = 2500000 },
        { group = "armor_component_advanced",     chance = 2500000 },
        { group = "weapon_component_advanced",    chance = 2500000 },
        { group = "crafting_component_advanced",  chance = 2500000 }
      },
      lootChance = 10000000
    },
    {
      groups = {
        { group = "component_enhancement", chance = 10000000 }
      },
      lootChance = 10000000
    },
    {
      groups = {
        { group = "sea_removal_tool_1x",  chance = 2500000 }, -- 25%
        { group = "clothing_attachments", chance = 3750000 }, -- 37.5%
        { group = "armor_attachments",    chance = 3750000 }  -- 37.5%
      },
      lootChance = 10000000
    }
  },

  primaryWeapon = "none",
  secondaryWeapon = "none",

  attacks = {
    {"flamecone2",""},{"flamecone1",""},
    {"flamesingle2",""},{"flamesingle1",""},
    {"fireacidcone2",""},{"fireacidcone1",""},
    {"fireacidsingle2",""},{"fireacidsingle1",""},
    {"unarmedknockdown2",""},{"unarmedhit3",""}
  }
}

CreatureTemplates:addCreatureTemplate(peko_peko_infernomaw, "peko_peko_infernomaw")
