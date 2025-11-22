master_bounty_guild_npc = Creature:new {
    objectName = "@npc_name:bounty_guild_master", -- add STF if you like
    socialGroup = "bounty",
    faction = "",
    level = 100,
    chanceHit = 0.5,
    damageMin = 0,
    damageMax = 0,
    baseXp = 0,
    baseHAM = 10000,
    baseHAMmax = 10000,
    armor = 0,
    resists = {0,0,0,0,0,0,0,0,-1},
    meatType = "",
    meatAmount = 0,
    hideType = "",
    hideAmount = 0,
    boneType = "",
    boneAmount = 0,
    milk = 0,
    tamingChance = 0,
    ferocity = 0,
    pvpBitmask = NONE,
    creatureBitmask = NONE,
    optionsBitmask = INVULNERABLE + CONVERSABLE,
    diet = HERBIVORE,

    templates = {
        "object/mobile/dressed_bountyhunter_trainer_01.iff"
    },

    conversationTemplate = "master_bounty_guild",
    lootGroups = {},
    weapons = {},
    attacks = {}
}

CreatureTemplates:addCreatureTemplate(master_bounty_guild_npc, "master_bounty_guild_npc")
