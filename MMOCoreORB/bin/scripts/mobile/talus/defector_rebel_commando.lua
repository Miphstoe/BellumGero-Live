defector_rebel_commando = Creature:new {
  -- NOTE: You typed "Rebel Commando, Defector". If you want the comma, set it here:
  -- customName = "Rebel Commando, Defector",
  customName = "Rebel Commando Defector",
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
    "object/mobile/dressed_rebel_commando_human_male_01.iff",
    "object/mobile/dressed_rebel_commando_human_female_01.iff"
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
	primaryWeapon = "rebel_carbine",
	secondaryWeapon = "commando_melee",
	thrownWeapon = "thrown_weapons",

	conversationTemplate = "",
	reactionStf = "@npc_reaction/military",
	personalityStf = "@hireling/hireling_military",

	-- primaryAttacks and secondaryAttacks should be separate skill groups specific to the weapon type listed in primaryWeapon and secondaryWeapon
	-- Use merge() to merge groups in creatureskills.lua together. If a weapon is set to "none", set the attacks variable to empty brackets
	primaryAttacks = merge(carbineernovice,marksmanmaster),
	secondaryAttacks = merge(tkanovice,brawlermaster)
}

CreatureTemplates:addCreatureTemplate(defector_rebel_commando, "defector_rebel_commando")