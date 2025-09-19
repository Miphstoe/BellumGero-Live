----------------------------------------
--  RancorCaveScreenPlay
--  Mirrored from ForceCrystalCaveScreenPlay:
--    * Awards Force-Rank XP on cave mob kills
--    * Uses spawnPoints table + observers
----------------------------------------
RancorCaveScreenPlay = ScreenPlay:new {
    numberOfActs       = 1,
    screenplayName     = "RancorCaveScreenPlay",

    lootContainers     = {
        9815402,
        9815403,
        9815404,
        9815405,
        9815406,
        9815412
    },

    lootLevel          = 150,
    lootGroups         = {
        {
            groups = {
                {group = "nightsister_cave", chance = 10000000},
            },
            lootChance = 8000000
        }
    },
    lootContainerRespawn = 1800  -- 30 minutes (mirrors Force Crystal Cave)
}

registerScreenPlay("RancorCaveScreenPlay", true)

function RancorCaveScreenPlay:start()
    if isZoneEnabled("dathomir") then
        self:spawnMobiles()
        self:initializeLootContainers()
    end
end

function RancorCaveScreenPlay:spawnMobiles()
    -- Mirrors ForceCrystalCaveScreenPlay pattern: single spawnPoints table + loop + observer
    local spawnPoints = {
        { "nightsister_shaman",      -23.6, -27.5,   -8.1,   87, 4335463 },
        { "nightsister_shaman",      13.7, -5.2,   -9.8,   12, 4335463 },

        { "nightsister_hex_weaver",  -23.8, -42.4,  -64.0,    0, 4335464 },
        { "nightsister_hex_weaver",  -20.9, -40,  -63.7,    -16, 4335464 },
        { "nightsister_shaman",  -50.6, -48.9,  -61.7,  127, 4335464 },
        { "nightsister_shaman",  -49.1, -47.4,  -12.0,  177, 4335464 },
        { "nightsister_shaman",  -54.4, -68.3,  -40.0,  -82, 4335464 },

        { "nightsister_shaman",      -49.8, -48.8, -102.8,    -5, 4335472 },

        { "nightsister_shaman",      -93.4, -46.6, -128.6,    3, 4335473 },
        { "nightsister_hex_weaver",  -81.3, -46.2, -137.8,  152, 4335473 },
        { "nightsister_hex_weaver",  -72.7, -45.6, -139.7, -123, 4335473 },
        { "nightsister_hex_weaver",  -77.6, -45.8, -148.0,  -19, 4335473 },

        { "nightsister_hex_weaver",  -87.1, -62.2,  -14.9, -178, 4335465 },
        { "nightsister_hex_weaver",  -90.5, -62.2,  -17.9, -161, 4335465 },

        { "nightsister_shaman",  -79.0, -76.7,  -89.2,    4, 4335466 },
        { "nightsister_shaman",  -78.7, -76,  -62.6,    -1, 4335466 },

        { "nightsister_hex_weaver",  -93.8, -45.7, -99.7,  124, 4335467 },
        { "nightsister_hex_weaver",  -95.4, -66.3, -109.3,  172, 4335467 },
        { "nightsister_hex_weaver",  -93.6, -66.7, -109,  172, 4335467 },

        { "nightsister_shaman",  -53.4, -73.4, -108.5,  -3, 4335468 },

        { "nightsister_shaman",  -78.2, -65.6, -139.3,  87, 4335469 },

        { "nightsister_shaman",     -130.4, -66.8, -107.7,   91, 4335470 },
        { "nightsister_hex_weaver", -151.6, -66.5, -125.0,   69, 4335470 },
        { "nightsister_hex_weaver", -132.8, -66.6, -121.8,  -82, 4335470 },
        { "nightsister_shaman",     -141.4, -66.7, -88.2,   134, 4335470 },

        { "nightsister_shaman",     -189.9, -66.5, -102.1,   87, 4335471 },
        { "nightsister_shaman",     -194.9, -66.4, -96.8,   94, 4335471 },
        { "nightsister_shaman",     -191.8, -66.3, -108.6,   56, 4335471 },

        -- Surface sentinel near entrance (cell 0)
        { "nightsister_shaman",    -4224.2,  25.3, -2091.7, 132,     0 },
    }

    for i, data in ipairs(spawnPoints) do
        local tpl     = data[1]
        local x, y, z = data[2], data[3], data[4]
        local heading = data[5]
        local cell    = data[6]

        -- Force Crystal Cave uses 1800s; do the same here.
        local pMob = spawnMobile("dathomir", tpl, 1800, x, y, z, heading, cell)
        if pMob then
            Logger:log(
              string.format("RancorCaveScreenPlay: spawned '%s' #%d at [%.1f,%.1f,%.1f] cell %d",
                            tpl, i, x, y, z, cell),
              LT_INFO
            )
            createObserver(OBJECTDESTRUCTION,
                           "RancorCaveScreenPlay",
                           "onCaveMobDied",
                           pMob)
        else
            Logger:log(
              string.format("RancorCaveScreenPlay: FAILED to spawn '%s' #%d", tpl, i),
              LT_ERROR
            )
        end
    end
end

function RancorCaveScreenPlay:onCaveMobDied(pMob, pKiller)
    -- IDENTICAL flow to ForceCrystalCaveScreenPlay
    -- Resolve the *player* responsible (handles pets/vehicles).
    if pKiller == nil then return 0 end

    local pPlayer = nil
    if SceneObject(pKiller):isPlayerCreature() then
        pPlayer = pKiller
    else
        local ko = CreatureObject(pKiller)
        if ko and ko.getOwner then
            local pOwner = ko:getOwner()
            if pOwner ~= nil and SceneObject(pOwner):isPlayerCreature() then
                pPlayer = pOwner
            end
        end
    end
    if pPlayer == nil then return 0 end

    local RANGE_METERS = 80 -- only grant to group members present at the kill
    local mobSO = SceneObject(pMob)

    local function grantIfEligible(pTarget)
        if pTarget == nil or not SceneObject(pTarget):isPlayerCreature() then return end
        -- must be within range of the mob that died
        if mobSO and not SceneObject(pTarget):isInRangeWithObject(pMob, RANGE_METERS) then return end

        local c = CreatureObject(pTarget)
        if c and c.hasSkill and c:hasSkill("force_title_jedi_rank_03") then
            c:awardExperience("force_rank_xp", 100, true)
        end
    end

    local killerCO = CreatureObject(pPlayer)
    if killerCO and killerCO.isGrouped and killerCO:isGrouped() then
        local size = killerCO:getGroupSize()
        for i = 0, size - 1 do
            local pMember = killerCO:getGroupMember(i)
            grantIfEligible(pMember)
        end
    else
        -- not grouped: just grant to the solo killer if eligible
        grantIfEligible(pPlayer)
    end

    return 0
end