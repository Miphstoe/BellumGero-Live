master_bounty_guild_npc = Creature:new {
    objectName     = "@mob/creature_names:bounty_guild_master", -- add STF entry if you like
    randomNameType = NAME_GENERIC,
    randomNameTag  = true,
    mobType        = MOB_NPC,

    socialGroup = "bounty",
    faction     = "",
    level       = 100,

    chanceHit = 0.39,
    damageMin = 0,
    damageMax = 0,

    baseXp    = 0,
    baseHAM   = 8400,
    baseHAMmax = 10200,

    armor   = 0,
    resists = {-1,-1,-1,-1,-1,-1,-1,-1,-1},

    meatType   = "",
    meatAmount = 0,
    hideType   = "",
    hideAmount = 0,
    boneType   = "",
    boneAmount = 0,
    milk       = 0,

    tamingChance = 0,
    ferocity     = 0,

    pvpBitmask      = NONE,
    creatureBitmask = NONE,
    optionsBitmask  = INVULNERABLE + CONVERSABLE,

    diet = HERBIVORE,

    templates = {
        "object/mobile/dressed_bountyhunter_trainer_01.iff"
    },

    -- No combat: this is a conversation utility NPC
    lootGroups = {},
    weapons    = {},

    conversationTemplate = "master_bounty_guild",

    attacks = {}
}

CreatureTemplates:addCreatureTemplate(master_bounty_guild_npc, "master_bounty_guild_npc")
