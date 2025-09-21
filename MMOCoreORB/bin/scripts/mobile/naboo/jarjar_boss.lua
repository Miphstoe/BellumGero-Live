print("[JARJAR] loading jarjar_boss.lua")

jarjar_boss = Creature:new {
  objectName = "Jar Jar Binks",
  customName = "Jar Jar Binks The Banished",
  randomNameType = 0,
  randomNameTag = false,
  mobType = MOB_NPC,
  socialGroup = "gungan",
  faction = "gungan",
  level = 250,
  chanceHit = 0.65,
  damageMin = 800,
  damageMax = 1200,
  baseXp = 12000,
  baseHAM = 195000,
  baseHAMmax = 310000,
  armor = 2,
  resists = {55,55,40,30,45,35,50,25,30},

  pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
  creatureBitmask = KILLER + PACK,
  optionsBitmask = AIENABLED,
  diet = HERBIVORE,

  -- MUST match the screenplay name
  deathCallback = "jarjar_worldboss",

  templates = {"object/mobile/gungan_male.iff"},
  scale = 1.2,

  lootGroups = {
    {
      groups = {
        {group = "power_crystals", chance = 6000000},
        {group = "holocron_light",  chance = 2000000},
        {group = "holocron_dark", chance = 2000000}
      },
      lootChance = 10000000
    },
    {
      groups = {
        {group = "clothing_attachments", chance = 6000000},
        {group = "potted_plants_sml_s02_schematic",  chance = 2000000},
        {group = "sea_removal_tool", chance = 2000000}
      },
      lootChance = 5000000
    },
    {
      groups = {
        {group = "color_crystals", chance = 6000000},
        {group = "potted_plants_sml_s02_schematic",  chance = 2000000},
        {group = "sea_removal_tool", chance = 2000000}
      },
      lootChance = 2500000
    },
    {
      groups = {
        {group = "armor_attachments", chance = 6000000},
        {group = "potted_plants_sml_s02_schematic",  chance = 2000000},
        {group = "sea_removal_tool", chance = 2000000}
      },
      lootChance = 1250000
    }
  },

  -- keep it ultra-safe for now:
  primaryWeapon   = "unarmed",
  secondaryWeapon = "none",
  conversationTemplate = "",

  primaryAttacks   = {},  -- no skills while we debug
  secondaryAttacks = {}
}

print("[JARJAR] registering jarjar_boss")
CreatureTemplates:addCreatureTemplate(jarjar_boss, "jarjar_boss")
