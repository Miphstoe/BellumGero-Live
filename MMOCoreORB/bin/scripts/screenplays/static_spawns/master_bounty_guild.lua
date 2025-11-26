MasterBountyGuildScreenPlay = ScreenPlay:new {
    numberOfActs = 1,
}

registerScreenPlay("MasterBountyGuildScreenPlay", true)

function MasterBountyGuildScreenPlay:start()
    -- Dantooine (existing setup)
    if (isZoneEnabled("dantooine")) then
        -- Master BH Guild NPC
        spawnMobile("dantooine", "master_bounty_guild_npc", 1, 1585, 4, -6368.8, 176, 0)
        -- Level 3 informant
        spawnMobile("dantooine", "informant_npc_lvl_3", 1, 1586.9, 4, -6369, 176, 0)
    end

    -- Tatooine
    if (isZoneEnabled("tatooine")) then
        -- TODO: Replace X,Y,Z,dir with your desired Tatooine city coords & direction
        spawnMobile("tatooine", "master_bounty_guild_npc", 1, -3027.7, 5.0, 2158.7, -109, 0)
        spawnMobile("tatooine", "informant_npc_lvl_3", 1, -3027.2, 5.0, 2156.5, -109, 0)
    end

    -- Naboo
    if (isZoneEnabled("naboo")) then
        -- TODO: Replace X,Y,Z,dir with your desired Naboo city coords & direction
        spawnMobile("naboo", "master_bounty_guild_npc", 1, -5206.1, 6.0, 4205.5, -146, 0)
        spawnMobile("naboo", "informant_npc_lvl_3", 1, -5204.5, 6.0, 4203.6, -146, 0)
    end

    -- Corellia
    if (isZoneEnabled("corellia")) then
        -- TODO: Replace X,Y,Z,dir with your desired Corellia city coords & direction
        spawnMobile("corellia", "master_bounty_guild_npc", 1, -351.0, 28.0, -4443.3, -2, 0)
        spawnMobile("corellia", "informant_npc_lvl_3", 1, -354.1, 28.0, -4443.7, -3, 0)
    end

    -- Talus
    if (isZoneEnabled("talus")) then
        -- TODO: Replace X,Y,Z,dir with your desired Talus city coords & direction
        spawnMobile("talus", "master_bounty_guild_npc", 1, 392.7, 6, -2928.4, -90, 0)
        spawnMobile("talus", "informant_npc_lvl_3", 1, 392.7, 6, -2931.0, -90, 0)
    end

    -- Rori
    if (isZoneEnabled("rori")) then
        -- TODO: Replace X,Y,Z,dir with your desired Rori city coords & direction
        spawnMobile("rori", "master_bounty_guild_npc", 1, -5222.4, 80.0, -2239.6, -145, 0)
        spawnMobile("rori", "informant_npc_lvl_3", 1, -5220.3, 80.0, -2241.2, 174, 0)
    end

    -- Lok
    if (isZoneEnabled("lok")) then
        -- TODO: Replace X,Y,Z,dir with your desired Lok outpost coords & direction
        spawnMobile("lok", "master_bounty_guild_npc", 1, 452.5, 8.7, 5514.2, -90, 0)
        spawnMobile("lok", "informant_npc_lvl_3", 1, 452.4, 8.7, 5512.4, -90, 0)
    end

    -- Dathomir
    if (isZoneEnabled("dathomir")) then
        -- TODO: Replace X,Y,Z,dir with your desired Dathomir outpost coords & direction
        spawnMobile("dathomir", "master_bounty_guild_npc", 1, -102.6, 18.0, -1573.9, 99, 0)
        spawnMobile("dathomir", "informant_npc_lvl_3", 1, -101.9, 18.0, -1571.2, 82, 0)
    end

    -- Yavin 4
    if (isZoneEnabled("yavin4")) then
        -- TODO: Replace X,Y,Z,dir with your desired Yavin IV outpost coords & direction
        spawnMobile("yavin4", "master_bounty_guild_npc", 1, -338.4, 35.0, 4859.2, 132, 0)
        spawnMobile("yavin4", "informant_npc_lvl_3", 1, -336.8, 35.0, 4860.7, 130, 0)
    end

    -- Endor
    if (isZoneEnabled("endor")) then
        -- TODO: Replace X,Y,Z,dir with your desired Endor outpost coords & direction
        spawnMobile("endor", "master_bounty_guild_npc", 1, -902.7, 80.0, 1617.8, 116, 0)
        spawnMobile("endor", "informant_npc_lvl_3", 1, -901.7, 80.0, 1618.8, 116, 0)
    end
end
