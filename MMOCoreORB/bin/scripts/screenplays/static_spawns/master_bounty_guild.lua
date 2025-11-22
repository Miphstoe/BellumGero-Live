MasterBountyGuildScreenPlay = ScreenPlay:new {
    numberOfActs = 1,
}

registerScreenPlay("MasterBountyGuildScreenPlay", true)

function MasterBountyGuildScreenPlay:start()
    -- Example: Theed on Naboo; change coords as desired.
    if (isZoneEnabled("dantooine")) then
        spawnMobile("dantooine", "master_bounty_guild_npc", 1, -599, 3, 2493, 0, 0)
    end
end
