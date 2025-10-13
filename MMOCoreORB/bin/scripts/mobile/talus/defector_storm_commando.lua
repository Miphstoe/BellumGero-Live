defector_storm_commando = Creature:new {
  customName = "Storm Commando Defector",
  socialGroup = "gcw_defector",
  faction = "",

  level = 150,
  chanceHit = 15,
  damageMin = 500,
  damageMax = 740,
  baseXp = 9200,
  baseHAM = 30000,
  baseHAMmax = 40000,
  armor = 1,
  resists = {15,15,15,15,15,15,15,-1,-1},
  meatType = "",
  meatAmount = 0,
  hideType = "",
  hideAmount = 0,
  boneType = "",
  boneAmount = 0,
  milk = 0,
  tamingChance = 0,
  ferocity = 0,

  pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
  creatureBitmask = PACK + KILLER,
  optionsBitmask = AIENABLED,
  diet = HERBIVORE,

  templates = {
    "object/mobile/dressed_stormtrooper_commando1_m.iff"
  },

  lootGroups = {  
    {
        groups = {
			      {group = "defector_cave", chance = 10000000}
		  },
		  lootChance = 4000000, -- 40.00% total chance
	  },
    {
        groups = {
			      {group = "defector_cave", chance = 10000000}
		  },
		  lootChance = 2000000, -- 20.00% total chance
	  },
  },


  -- Primary and secondary weapon should be different types (rifle/carbine, carbine/pistol, rifle/unarmed, etc)
	-- Unarmed should be put on secondary unless the mobile doesn't use weapons, in which case "unarmed" should be put primary and "none" as secondary
	primaryWeapon = "stormtrooper_carbine",
	secondaryWeapon = "stormtrooper_pistol",
	thrownWeapon = "thrown_weapons",

	conversationTemplate = "",
	reactionStf = "@npc_reaction/stormtrooper",
	personalityStf = "@hireling/hireling_stormtrooper",

	-- primaryAttacks and secondaryAttacks should be separate skill groups specific to the weapon type listed in primaryWeapon and secondaryWeapon
	-- Use merge() to merge groups in creatureskills.lua together. If a weapon is set to "none", set the attacks variable to empty brackets
	primaryAttacks = merge(carbineermaster,marksmanmaster),
	secondaryAttacks = merge(pistoleermaster,marksmanmaster)
}

CreatureTemplates:addCreatureTemplate(defector_storm_commando, "defector_storm_commando")