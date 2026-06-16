----------------------------------------
--  RancorCaveScreenPlay
--  Mirrored from ForceCrystalCaveScreenPlay:
--    * Awards Force-Rank XP on cave mob kills
--    * Uses spawnPoints table + observers
--  + Distributes 1 loot item + 5000 credits to every damager when the boss dies
----------------------------------------
local WorldBossLootManager = require("screenplays.managers.world_boss_loot_manager")

local NIGHTSISTER_LOOT_GROUPS = {
	{
		groups = {
			{ group = "nightsister_cave",          chance = 5750000 },
			{ group = "house_deeds",               chance = 2000000 },
			{ group = "vet_holo_group",            chance = 1000000 },
			{ group = "endgame_weapon_schematics", chance = 750000  },
			{ group = "bg_token_group",            chance = 500000  },
		},
		lootChance = 10000000
	}
}

local function _rollOneNightLoot(pInventory, lootGroups, bossLevel)
	local entry = lootGroups[math.random(#lootGroups)]
	if not entry or not entry.groups then return "an item" end

	local totalWeight = 0
	for _, g in ipairs(entry.groups) do totalWeight = totalWeight + (g.chance or 0) end
	if totalWeight == 0 then return "an item" end

	local roll = math.random(totalWeight)
	local cumulative = 0
	local chosenGroup = nil
	for _, g in ipairs(entry.groups) do
		cumulative = cumulative + (g.chance or 0)
		if roll <= cumulative then chosenGroup = g.group; break end
	end
	if not chosenGroup then return "an item" end

	local itemOID = nil
	pcall(function() itemOID = createLoot(pInventory, chosenGroup, bossLevel, true) end)

	local itemName = "an item"
	if itemOID and itemOID ~= 0 then
		local pItem = getSceneObject(itemOID)
		if pItem then
			local so = SceneObject(pItem)
			if so then itemName = so:getDisplayedName() or "an item" end
		end
	end
	return itemName
end

local function _giveNightBossLoot(pPlayer, lootGroups, bossName, bossLevel)
	pcall(function()
		local co = CreatureObject(pPlayer)
		if co then co:addCashCredits(5000, true) end
	end)

	local pInventory = nil
	pcall(function()
		local co = CreatureObject(pPlayer)
		if co then pInventory = co:getSlottedObject("inventory") end
	end)
	if not pInventory then return end

	local item1 = _rollOneNightLoot(pInventory, lootGroups, bossLevel)
	local item2 = _rollOneNightLoot(pInventory, lootGroups, bossLevel)

	pcall(function()
		CreatureObject(pPlayer):sendSystemMessage(
			"\\#00FF00You received from " .. bossName .. ": " .. item1 .. ", " .. item2 .. " and 5,000 credits!")
	end)
end

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

        { "nightsister_boss",     -189.9, -66.5, -102.1,   87, 4335471 },
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
            if tpl == "nightsister_boss" then
                for _, nm in ipairs({"DAMAGERECEIVED", "COMBATDAMAGE", "DAMAGE"}) do
                    local ev = rawget(_G, nm)
                    if type(ev) == "number" then
                        pcall(createObserver, ev, "RancorCaveScreenPlay", "onNightBossDamage", pMob)
                    end
                end
                createObserver(OBJECTDESTRUCTION, "RancorCaveScreenPlay", "onNightBossDied", pMob)
            end
        else
            Logger:log(
              string.format("RancorCaveScreenPlay: FAILED to spawn '%s' #%d", tpl, i),
              LT_ERROR
            )
        end
    end
end

function RancorCaveScreenPlay:onNightBossDamage(pBoss, pAttacker, damage)
    WorldBossLootManager:trackDamage(pBoss, pAttacker)
    return 0
end

function RancorCaveScreenPlay:onNightBossDied(pBoss, pKiller)
    if pBoss == nil then return 0 end

    local soBoss = SceneObject(pBoss)
    if not soBoss then return 0 end
    local bossOID = soBoss:getObjectID()

    local recipients = {}
    local damagers = (_G.__WB_DAMAGE_TRACKING or {})[bossOID] or {}
    local trackedCount = 0
    for _ in pairs(damagers) do trackedCount = trackedCount + 1 end

    if trackedCount > 0 then
        for playerOID, _ in pairs(damagers) do
            pcall(function()
                local pPlayer = getSceneObject(tonumber(playerOID))
                if pPlayer and SceneObject(pPlayer):isPlayerCreature() then
                    table.insert(recipients, pPlayer)
                end
            end)
        end
    else
        local pPlayer = nil
        pcall(function()
            if pKiller and SceneObject(pKiller):isPlayerCreature() then
                pPlayer = pKiller
            elseif pKiller then
                local ko = CreatureObject(pKiller)
                if ko and ko.getOwner then
                    local pOwner = ko:getOwner()
                    if pOwner and SceneObject(pOwner):isPlayerCreature() then pPlayer = pOwner end
                end
            end
        end)
        if pPlayer then
            local killerCO = CreatureObject(pPlayer)
            if killerCO and killerCO.isGrouped and killerCO:isGrouped() then
                local size = killerCO:getGroupSize()
                for i = 0, size - 1 do
                    local pMember = killerCO:getGroupMember(i)
                    if pMember and SceneObject(pMember):isPlayerCreature() then
                        table.insert(recipients, pMember)
                    end
                end
            else
                table.insert(recipients, pPlayer)
            end
        end
    end

    if _G.__WB_DAMAGE_TRACKING then _G.__WB_DAMAGE_TRACKING[bossOID] = nil end

    for _, pRecipient in ipairs(recipients) do
        pcall(_giveNightBossLoot, pRecipient, NIGHTSISTER_LOOT_GROUPS, "Zaritha (a Nightsister clan mother)", 315)
    end

    pcall(function()
        local n = soBoss:getContainerObjectsSize()
        if n and n > 0 then
            for i = n - 1, 0, -1 do
                pcall(function()
                    local pItem = soBoss:getContainerObject(i)
                    if pItem then
                        local item = SceneObject(pItem)
                        if item then item:destroyObjectFromWorld(); item:destroyObjectFromDatabase() end
                    end
                end)
            end
        end
    end)
    pcall(function()
        local co = CreatureObject(pBoss)
        if co then
            local cash = co:getCashCredits()
            if cash and cash > 0 then co:subtractCashCredits(cash) end
            co:setCashCredits(0)
        end
    end)

    return 0
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
            c:awardExperience("force_rank_xp", 250, true)
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