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
    -- Loot groups removed - using WorldBossLootManager for automatic distribution
    -- Players who damage the boss receive loot directly to inventory
  },

  -- Primary and secondary weapon should be different types (rifle/carbine, carbine/pistol, rifle/unarmed, etc)
	-- Unarmed should be put on secondary unless the mobile doesn't use weapons, in which case "unarmed" should be put primary and "none" as secondary
	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "",
	
	-- primaryAttacks and secondaryAttacks should be separate skill groups specific to the weapon type listed in primaryWeapon and secondaryWeapon
	-- Use merge() to merge groups in creatureskills.lua together. If a weapon is set to "none", set the attacks variable to empty brackets
	primaryAttacks = { {"creatureareacombo",""}, {"creatureareaknockdown",""} },
	secondaryAttacks = { }
  
}

CreatureTemplates:addCreatureTemplate(peko_peko_infernomaw, "peko_peko_infernomaw")
