--printLuaError("[ACKLAY-WORLDBOSS] Loading acklay_worldboss template...")

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
        -- Roll 1: your original "acklay" pool (optional)
        {
            groups = {
                {group = "acklay", chance = 10000000}
            },
            lootChance = 10000000   -- 10% chance; adjust as you want
        },

        -- Roll 2: crystals (GUARANTEED)
        {
            groups = {
                {group = "power_crystals", chance = 7000000}, -- 70%
                {group = "color_crystals", chance = 3000000}, -- 30%
            },
            lootChance = 10000000
        },

        -- Roll 3: holocron (30% chance)
        {
            groups = {
                {group = "holocron_dark",  chance = 5000000},
                {group = "holocron_light", chance = 5000000},
            },
            lootChance = 10000000
        },

        -- Roll 4: attachment (70% chance)
        {
            groups = {
                {group = "armor_attachments",    chance = 5000000},
                {group = "clothing_attachments", chance = 5000000},
            },
            lootChance = 10000000
        },

        -- Roll 5: weapon component (80% chance)
        {
            groups = {
                {group = "weapon_component", chance = 10000000},
            },
            lootChance = 10000000
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
