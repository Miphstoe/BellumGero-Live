-- printLuaError("[ACKLAY-WORLDBOSS] Loading acklay_worldboss template....")

acklay_worldboss = Creature:new {
    objectName = "@mob/creature_names:geonosian_acklay_bunker_boss",
    customName = "Acklay - Devourer of Massassi",
    socialGroup = "geonosian_creature",
    mobType = MOB_CARNIVORE,
    faction = "",
    level = 350,
    chanceHit = 92.5,
    damageMin = 935,
    damageMax = 1580,
    baseXp = 14884,
    baseHAM = 1000000,
    baseHAMmax = 1500000,
    armor = 2,
    resists = {150,170,180,170,170,75,75,75,20},
    meatType = "",
    meatAmount = 0,
    hideType = "",
    hideAmount = 0,
    boneType = "",
    boneAmount = 0,
    milk = 0,
    tamingChance = 0,
    ferocity = 25,
    pvpBitmask = AGGRESSIVE + ATTACKABLE + ENEMY,
    creatureBitmask = PACK + KILLER,
    optionsBitmask = AIENABLED,
    diet = CARNIVORE,
    tauntable = false,
    templates = {"object/mobile/acklay_hue.iff"},

    lootGroups = {
	{
        groups = {
			{group = "acklay", chance = 3000000},         -- 30.00% of group, 30.00% total
			{group = "color_crystals", chance = 3000000},       -- 30.00% of group, 30.00% total
			{group = "power_crystals", chance = 2000000},              -- 20.00% of group, 20.00% total
			{group = "armor_attachments", chance = 1000000},         -- 10.00% of group, 10.00% total
			{group = "clothing_attachments", chance = 1000000},      -- 10.00% of group, 10.00% total
		},
		lootChance = 10000000, -- 100.00% total chance
	},
	{
        groups = {
			{group = "acklay", chance = 3000000},         -- 30.00% of group, 30.00% total
			{group = "color_crystals", chance = 3000000},       -- 30.00% of group, 30.00% total
			{group = "power_crystals", chance = 2000000},              -- 20.00% of group, 20.00% total
			{group = "armor_attachments", chance = 1000000},         -- 10.00% of group, 10.00% total
			{group = "clothing_attachments", chance = 1000000},      -- 10.00% of group, 10.00% total
		},
		lootChance = 10000000, -- 100.00% total chance
	},
	{
        groups = {
			{group = "acklay", chance = 3000000},         -- 30.00% of group, 30.00% total
			{group = "color_crystals", chance = 3000000},       -- 30.00% of group, 30.00% total
			{group = "power_crystals", chance = 2000000},              -- 20.00% of group, 20.00% total
			{group = "armor_attachments", chance = 1000000},         -- 10.00% of group, 10.00% total
			{group = "clothing_attachments", chance = 1000000},      -- 10.00% of group, 10.00% total
		},
		lootChance = 10000000, -- 100.00% total chance
	},
	{
        groups = {
			{group = "acklay", chance = 3000000},         -- 30.00% of group, 30.00% total
			{group = "color_crystals", chance = 3000000},       -- 30.00% of group, 30.00% total
			{group = "power_crystals", chance = 2000000},              -- 20.00% of group, 20.00% total
			{group = "armor_attachments", chance = 1000000},         -- 10.00% of group, 10.00% total
			{group = "clothing_attachments", chance = 1000000},      -- 10.00% of group, 10.00% total
		},
		lootChance = 10000000, -- 100.00% total chance
	},
	{
        groups = {
			{group = "power_crystals", chance = 10000000},             -- 100.00% of group, 15.00% total
		},
		lootChance = 5000000, -- 50.00% total chance
	},
	{
        groups = {
			{group = "power_crystals", chance = 10000000},             -- 100.00% of group, 10.00% total
		},
		lootChance = 2500000, -- 25.00% total chance
	},
    {
            groups = {
                {group = "house_deeds", chance = 10000000}
            },
            lootChance = 2000000, -- 20.00% total chance
        }
},

    primaryWeapon = "unarmed",
    secondaryWeapon = "none",
    conversationTemplate = "",
    primaryAttacks = {
        {"posturedownattack","stateAccuracyBonus=60"},
        {"creatureareacombo","stateAccuracyBonus=60"},
        {"creatureareableeding",""},
        {"creatureareapoison",""},
    },
    secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(acklay_worldboss, "acklay_worldboss")
