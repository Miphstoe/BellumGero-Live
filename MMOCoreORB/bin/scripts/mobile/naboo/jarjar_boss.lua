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
    -- Loot groups removed - using WorldBossLootManager for automatic distribution
    -- Players who damage the boss receive loot directly to inventory
  },

  -- No credits on corpse - players receive credits directly to inventory
  cashMin = 0,
  cashMax = 0,

  -- keep it ultra-safe for now:
  primaryWeapon   = "unarmed",
  secondaryWeapon = "none",
  conversationTemplate = "",

  primaryAttacks   = {},  -- no skills while we debug
  secondaryAttacks = {}
}

print("[JARJAR] registering jarjar_boss")
CreatureTemplates:addCreatureTemplate(jarjar_boss, "jarjar_boss")
