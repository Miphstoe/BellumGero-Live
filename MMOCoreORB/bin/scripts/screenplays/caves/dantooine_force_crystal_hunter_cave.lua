----------------------------------------
--  ForceCrystalCaveScreenPlay
--  Rewards Force-Rank XP on cave mob kills
--  + Adds server-spawned loot containers that use the same loot groups/level/respawn
--  + HYBRID Inquisitor death rewards:
--      (1) Per-damager direct loot: every player who damaged the boss gets
--          2 rolled items + 5000 credits (WorldBossLootManager tracking).
--      (2) Boss-locked premium containers in Valen Kade's room unlock and
--          seed loot on death; they re-lock on refill until the next kill.
----------------------------------------
local WorldBossLootManager = require("screenplays.managers.world_boss_loot_manager")


local INQUISITOR_LOOT_GROUPS = {
	{
		groups = {
			{ group = "dark_jedi_tier_5",              chance = 4000000 },
			{ group = "blasterfist_schematic",         chance = 1500000 },
			{ group = "clonetrooper_armor_schematics", chance = 1500000 },
			{ group = "jedi_house_deeds",              chance = 1200000 },
			{ group = "jedi_robe",                     chance = 1000000 },
			{ group = "endgame_weapon_schematics",     chance = 500000  },
			{ group = "bg_token_group",                chance = 300000  },
		},
		lootChance = 10000000
	}
}

local function _rollOneLoot(pInventory, lootGroups, bossLevel)
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

local function _giveBossLoot(pPlayer, lootGroups, bossName, bossLevel)
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

	local item1 = _rollOneLoot(pInventory, lootGroups, bossLevel)
	local item2 = _rollOneLoot(pInventory, lootGroups, bossLevel)

	pcall(function()
		CreatureObject(pPlayer):sendSystemMessage(
			"\\#00FF00You received from " .. bossName .. ": " .. item1 .. ", " .. item2 .. " and 5,000 credits!")
	end)
end

ForceCrystalCaveScreenPlay = ScreenPlay:new {
    numberOfActs       = 1,
    screenplayName     = "ForceCrystalCaveScreenPlay",

    -- Client-placed containers (static IDs baked in the TREs)
    lootContainers     = { 200335, 200336, 8535511 },

    -- Loot config used by BOTH static containers and the new server-spawned ones
    lootLevel          = 325,
    lootGroups         = {
        {
            groups = {
                { group = "color_crystals", chance = 10000000 },
            },
            lootChance = 10000000
        }
    },

    -- Respawn window (seconds). Used by both static- and server-spawned containers.
    lootContainerRespawn = 1800,  -- 30 minutes

    -- Server-spawned extra loot crate placements.
    -- Each entry: { planet, x, z, y, cellId, rotDeg [, lootGroups, lootLevel, lockedByBoss] }
    -- If lootGroups/lootLevel are omitted the spawn inherits self.lootGroups / self.lootLevel.
    -- lockedByBoss = true  => container starts locked; unlocks on Inquisitor death.
    extraLootSpawns = {
        { "dantooine",  77.0,   -45.7,   -147.6,   8535493,   0 },
        { "dantooine",  92.8,   -76.2,   -83.9,    8535486,   0 },

        -- Valen Kade (Fallen Inquisitor) room -- standalone premium containers
        {
            "dantooine",  195.5,  -66.6,  -99.9,   8535491,  0,
            lockedByBoss = true,
            lootLevel  = 400,
            lootGroups = {
                { groups = { { group = "dark_jedi_tier_5", chance = 10000000 } }, lootChance = 10000000 },
                { groups = { { group = "bg_token_group",   chance = 10000000 } }, lootChance = 350000   },
                { groups = { { group = "jedi_robe",        chance = 10000000 } }, lootChance = 1000000  },
            },
        },
        {
            "dantooine",  195.1,  -66.9,  -103.6,  8535491,  0,
            lockedByBoss = true,
            lootLevel  = 400,
            lootGroups = {
                { groups = { { group = "dark_jedi_tier_5", chance = 10000000 } }, lootChance = 10000000 },
                { groups = { { group = "bg_token_group",   chance = 10000000 } }, lootChance = 350000   },
                { groups = { { group = "jedi_robe",        chance = 10000000 } }, lootChance = 1000000  },
            },
        },
    },

    -- Persistent keys for boss-locked container tracking
    DATA_INQ_CONT_COUNT = "fcc:inq:contCount",
    DATA_INQ_CONT_OID   = "fcc:inq:cont:",

    -- Persistent key for the Inquisitor boss OID (so we can re-attach after respawn)
    DATA_INQ_BOSS_OID   = "fcc:inq:bossOID",

    -- How often (ms) to poll for the boss respawning so we can re-attach the observer
    INQ_POLL_INTERVAL_MS = 15000,   -- 15 seconds

    -- Inquisitor loot groups for the boss-locked containers (seeded on death)
    inqLootGroups = {
        { groups = { { group = "dark_jedi_tier_5", chance = 10000000 } }, lootChance = 10000000 },
        { groups = { { group = "bg_token_group",   chance = 10000000 } }, lootChance = 350000   },
        { groups = { { group = "jedi_robe",        chance = 10000000 } }, lootChance = 1000000  },
    },
}

registerScreenPlay("ForceCrystalCaveScreenPlay", true)

function ForceCrystalCaveScreenPlay:start()
    if isZoneEnabled("dantooine") then
        self:spawnMobiles()

        -- Keep original static-ID containers working
        self:initializeLootContainers()

        -- Add server-spawned loot containers
        self:setupExtraLootContainers()
    end
end

-- ============================================================
-- Server-spawned loot containers
-- ============================================================

function ForceCrystalCaveScreenPlay:setupExtraLootContainers()
    local respawnSec = self.lootContainerRespawn or 1800
    local spawns = self.extraLootSpawns or {}
    local inqIdx = 0

    for i = 1, #spawns do
        local P = spawns[i]
        local planet, x, z, y, cell, rotDeg =
            P[1], P[2], P[3], P[4], P[5], P[6]

        local groups     = P.lootGroups  or self.lootGroups
        local level      = P.lootLevel   or self.lootLevel
        local bossLocked = P.lockedByBoss or false

        local pCont = spawnSceneObject(
            planet,
            "object/tangible/container/loot/placable_loot_crate.iff",
            x, z, y, cell, math.rad(rotDeg or 0)
        )

        if pCont ~= nil then
            local oid = SceneObject(pCont):getObjectID()

            writeData(oid .. ":extraLootRespawnSec", respawnSec)
            writeData(oid .. ":extraLootLevel", level)
            writeData(oid .. ":extraLootBossLocked", bossLocked and 1 or 0)

            if bossLocked then
                TangibleObject(pCont):setLockedStatus(true)
                inqIdx = inqIdx + 1
                writeData(self.DATA_INQ_CONT_OID .. inqIdx, oid)
            else
                createLootFromCollection(pCont, groups, level)
                createLootFromCollection(pCont, groups, level)
            end

            createObserver(CONTAINERCONTENTSCHANGED, self.screenplayName, "onExtraContainerLooted", pCont)
        end
    end

    writeData(self.DATA_INQ_CONT_COUNT, inqIdx)
end

-- When a spawned crate is looted empty, schedule a refill
function ForceCrystalCaveScreenPlay:onExtraContainerLooted(pContainer, pWho)
    if pContainer == nil then return 1 end
    local oid = SceneObject(pContainer):getObjectID()
    local respawnSec = readData(oid .. ":extraLootRespawnSec")
    if respawnSec == 0 then respawnSec = 1800 end

    createEvent(respawnSec * 1000, self.screenplayName, "refillExtraContainer", pContainer, "")
    return 1
end

-- Refill (re-roll) the container if it is empty
function ForceCrystalCaveScreenPlay:refillExtraContainer(pContainer)
    if pContainer == nil then return end
    if SceneObject(pContainer):getContainerObjectCount() == 0 then
        local oid        = SceneObject(pContainer):getObjectID()
        local level      = readData(oid .. ":extraLootLevel")
        local bossLocked = readData(oid .. ":extraLootBossLocked")
        if level == 0 then level = self.lootLevel end

        if bossLocked == 1 then
            -- Re-lock; waits for next Inquisitor kill to fill
            TangibleObject(pContainer):setLockedStatus(true)
        else
            createLootFromCollection(pContainer, self.lootGroups, level)
            createLootFromCollection(pContainer, self.lootGroups, level)
        end
    end
end

-- ============================================================
-- Inquisitor boss observer management
-- ============================================================

-- Attach ALL boss observers to a live boss pointer:
--   * damage observers feed WorldBossLootManager (per-damager loot)
--   * OBJECTDESTRUCTION drives onInquisitorDied (loot + container unlock)
-- Used both at initial spawn and after respawn (see checkInquisitorRespawn),
-- so the death observer is attached exactly once per boss instance.
function ForceCrystalCaveScreenPlay:attachInquisitorObserver(pBoss)
    createObserver(OBJECTDESTRUCTION, self.screenplayName, "onInquisitorDied", pBoss)

    for _, nm in ipairs({"DAMAGERECEIVED", "COMBATDAMAGE", "DAMAGE"}) do
        local ev = rawget(_G, nm)
        if type(ev) == "number" then
            pcall(createObserver, ev, self.screenplayName, "onInquisitorDamage", pBoss)
        end
    end
end

-- Poll until the boss has respawned, then re-attach the observers.
-- Called via createEvent after onInquisitorDied fires.
function ForceCrystalCaveScreenPlay:checkInquisitorRespawn(pUnused)
    local oid  = readData(self.DATA_INQ_BOSS_OID)
    if oid == 0 then return end   -- was never stored; nothing to do

    local pBoss = getSceneObject(oid)
    if pBoss ~= nil then
        -- Boss is back in the world; re-attach and stop polling
        self:attachInquisitorObserver(pBoss)
        Logger:log("ForceCrystalCaveScreenPlay: Inquisitor respawned (OID=" .. tostring(oid) .. "), observers re-attached.", LT_INFO)
    else
        -- Still dead/in-progress respawn; check again later
        createEvent(self.INQ_POLL_INTERVAL_MS, self.screenplayName, "checkInquisitorRespawn", nil, "")
    end
end

-- Feed damage tracking so every damager is eligible for boss loot
function ForceCrystalCaveScreenPlay:onInquisitorDamage(pBoss, pAttacker, damage)
    WorldBossLootManager:trackDamage(pBoss, pAttacker)
    return 0
end

-- ============================================================
-- Inquisitor boss death (HYBRID):
--   (1) per-damager direct loot + credits
--   (2) unlock boss-locked containers and seed them
--   (3) begin respawn polling to re-attach observers
-- ============================================================

function ForceCrystalCaveScreenPlay:onInquisitorDied(pBoss, pKiller)
    if pBoss == nil then return 0 end

    local soBoss = SceneObject(pBoss)
    if not soBoss then return 0 end
    local bossOID = soBoss:getObjectID()

    -- ---- (1) Per-damager direct loot ----
    -- Build recipient list from damage tracking; fall back to killer + group
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
        -- Damage observer wasn't attached (boss already existed at startup); fall back to killer
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
        pcall(_giveBossLoot, pRecipient, INQUISITOR_LOOT_GROUPS, "Valen Kade (Fallen Inquisitor)", 400)
    end

    -- Strip the boss corpse inventory/cash so loot only comes from the systems above
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

    -- ---- (2) Unlock boss-locked premium containers ----
    -- Announce to everyone who earned loot that the sealed containers opened
    local function msg(pTarget)
        if pTarget == nil then return end
        if not SceneObject(pTarget):isPlayerCreature() then return end
        CreatureObject(pTarget):sendSystemMessage(
            "\\#AA44FFThe Fallen Inquisitor is dead... his Force grip on the sealed containers shatters. The way is open."
        )
    end
    for _, pRecipient in ipairs(recipients) do
        msg(pRecipient)
    end

    -- Unlock every boss-locked container and seed 2 items each
    local count = readData(self.DATA_INQ_CONT_COUNT)
    for i = 1, count do
        local oid   = readData(self.DATA_INQ_CONT_OID .. i)
        local pCont = getSceneObject(oid)
        if pCont ~= nil then
            TangibleObject(pCont):setLockedStatus(false)

            local level = readData(oid .. ":extraLootLevel")
            if level == 0 then level = self.lootLevel end

            createLootFromCollection(pCont, self.inqLootGroups, level)
            createLootFromCollection(pCont, self.inqLootGroups, level)
        end
    end

    -- ---- (3) Begin polling for respawn so we can re-attach observers ----
    createEvent(self.INQ_POLL_INTERVAL_MS, self.screenplayName, "checkInquisitorRespawn", nil, "")

    return 0
end

-- ============================================================
-- Mobile spawns and FRS XP logic
-- ============================================================

function ForceCrystalCaveScreenPlay:spawnMobiles()
    local spawnPoints = {
        { "dark_force_master",  89,   -62,   -13.4, -139, 8535485 },
        { "dark_force_knight",  52.5, -67.9, -42.9,   32, 8535484 },
        { "dark_force_knight",  76.3, -77,   -89.3,  -81, 8535486 },
        { "dark_force_knight",  26.1, -43,   -68.3,   84, 8535484 },
        { "dark_force_knight",  64.1, -68.9, -36.8,   86, 8535485 },
        { "dark_force_knight",  85.3, -77.2, -62.9,  -57, 8535486 },
        { "dark_force_knight",  69.3, -75.7, -65.4,   30, 8535486 },
        { "dark_force_master",   0.7, -13.6,  -6.9,  -82, 8535483 },
        { "dark_force_knight",  65.6, -77,   -78.4,  -10, 8535486 },
        { "dark_force_master",  23.8, -38.4, -32.8,   -2, 8535484 },
        { "dark_force_knight",  22.4, -42.1, -64.1,   38, 8535484 },
        { "dark_force_master",  49.8, -48.5, -65.6,  -51, 8535484 },
        { "dark_force_master",  49.7, -48,   -17.7,  167, 8535484 },
        { "dark_force_master",  52.1, -48.7, -104.0,  -7, 8535492 },
        { "dark_force_master",  91.1, -46.6, -110.8,  -80, 8535487 },
        { "dark_force_knight",  75.6, -46.5, -141.9,  50, 8535493 },
        { "dark_force_knight",  84.3, -46.9, -145.7,  21, 8535493 },
        { "dark_force_knight",  54,   -73.5, -108.5,  -2, 8535488 },
        { "dark_force_knight",  62.9, -66.4, -136.5,  18, 8535488 },
        { "dark_force_master",  92.8, -66.2, -126.4, -150, 8535489 },
        { "dark_force_knight", 117.4, -66,   -107.8,  -89, 8535490 },
        { "dark_force_knight", 141.3, -66.6,  -87.5, -138, 8535490 },
        { "dark_force_knight", 150.1, -66.6, -126,    -50, 8535490 },
        { "imperial_inquisitor_boss", 191.7, -66.8, -102, -84, 8535491 },
    }

    for i, data in ipairs(spawnPoints) do
        local tpl      = data[1]
        local x, y, z  = data[2], data[3], data[4]
        local heading  = data[5]
        local cell     = data[6]

        local pMob = spawnMobile("dantooine", tpl, 1800, x, y, z, heading, cell)
        if pMob then
            Logger:log(
              string.format("ForceCrystalCaveScreenPlay: spawned '%s' #%d at [%.1f,%.1f,%.1f] cell %d",
                            tpl, i, x, y, z, cell),
              LT_INFO
            )

            -- General mob XP observer (all mobs)
            createObserver(OBJECTDESTRUCTION,
                           self.screenplayName,
                           "onCaveMobDied",
                           pMob)

            -- Inquisitor: store OID for respawn polling + attach damage/death observers
            if tpl == "imperial_inquisitor_boss" then
                local bossOID = SceneObject(pMob):getObjectID()
                writeData(self.DATA_INQ_BOSS_OID, bossOID)
                self:attachInquisitorObserver(pMob)
            end
        else
            Logger:log(
              string.format("ForceCrystalCaveScreenPlay: FAILED to spawn '%s' #%d", tpl, i),
              LT_ERROR
            )
        end
    end
end

function ForceCrystalCaveScreenPlay:onCaveMobDied(pMob, pKiller)
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

    local RANGE_METERS = 80
    local mobSO = SceneObject(pMob)

    local function grantIfEligible(pTarget)
        if pTarget == nil or not SceneObject(pTarget):isPlayerCreature() then return end
        if mobSO and not SceneObject(pTarget):isInRangeWithObject(pMob, RANGE_METERS) then return end

        local c = CreatureObject(pTarget)
        if c and c.hasSkill and c:hasSkill("force_title_jedi_rank_03") then
            c:awardExperience("force_rank_xp", 300, true)
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
        grantIfEligible(pPlayer)
    end

    return 0
end
