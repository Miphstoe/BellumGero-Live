----------------------------------------
--  ForceCrystalCaveScreenPlay
--  Rewards Force-Rank XP on cave mob kills
--  + Adds server-spawned loot containers that use the same loot groups/level/respawn
----------------------------------------
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

    -- Inquisitor loot groups (shared by onInquisitorDied and refillExtraContainer)
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

-- Attach the dedicated death observer to a live boss pointer
function ForceCrystalCaveScreenPlay:attachInquisitorObserver(pBoss)
    createObserver(OBJECTDESTRUCTION,
                   self.screenplayName,
                   "onInquisitorDied",
                   pBoss)
end

-- Poll until the boss has respawned, then re-attach the observer.
-- Called via createEvent after onInquisitorDied fires.
function ForceCrystalCaveScreenPlay:checkInquisitorRespawn(pUnused)
    local oid  = readData(self.DATA_INQ_BOSS_OID)
    if oid == 0 then return end   -- was never stored; nothing to do

    local pBoss = getSceneObject(oid)
    if pBoss ~= nil then
        -- Boss is back in the world; re-attach and stop polling
        self:attachInquisitorObserver(pBoss)
        Logger:log("ForceCrystalCaveScreenPlay: Inquisitor respawned (OID=" .. tostring(oid) .. "), observer re-attached.", LT_INFO)
    else
        -- Still dead/in-progress respawn; check again later
        createEvent(self.INQ_POLL_INTERVAL_MS, self.screenplayName, "checkInquisitorRespawn", nil, "")
    end
end

-- ============================================================
-- Inquisitor boss death: unlock containers, seed loot, message players
-- ============================================================

function ForceCrystalCaveScreenPlay:onInquisitorDied(pBoss, pKiller)
    -- Resolve the player credit (same pet/owner logic as onCaveMobDied)
    local pPlayer = nil
    if pKiller ~= nil then
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
    end

    -- Message the killer's group within 150m
    local function msg(pTarget)
        if pTarget == nil then return end
        if not SceneObject(pTarget):isPlayerCreature() then return end
        CreatureObject(pTarget):sendSystemMessage(
            "\\#AA44FFThe Fallen Inquisitor is dead... his Force grip on the sealed containers shatters. The way is open."
        )
    end

    if pPlayer ~= nil then
        local co = CreatureObject(pPlayer)
        if co and co.isGrouped and co:isGrouped() then
            local size = co:getGroupSize()
            for i = 0, size - 1 do
                local pMember = co:getGroupMember(i)
                if pMember ~= nil and SceneObject(pMember):isInRangeWithObject(pPlayer, 150) then
                    msg(pMember)
                end
            end
        else
            msg(pPlayer)
        end
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

    -- Begin polling for the respawn so we can re-attach this observer
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

            -- Dedicated Inquisitor death observer + store OID for respawn polling
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
