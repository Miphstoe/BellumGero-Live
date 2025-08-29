-- Jedi Knight Hunt Encounter (persistent, login-driven)
-- Visibility-agnostic. Lean version for AI-driven deathblow (via customAiMap).
-- Adds per-player generation tokens to prevent stacked spawns across relogs.

local ObjectManager = require("managers.object.object_manager")
local SpawnMobiles  = require("utils.spawn_mobiles")

local PREFIX = "JkhEnc"
local DEBUG  = false -- keep ON while testing

-- Probe prelude config
local PROBE_PRELUDE_LIFETIME_MS = 6000  -- ~6s on-screen, then BH spawns/engages

local function dbg(co, msg)
    if DEBUG and co ~= nil then
        CreatureObject(co):sendSystemMessage("\\#888888[JKH] " .. msg)
    end
end

local function pidOf(p) return SceneObject(p):getObjectID() end

-- -------- Generation helpers (de-duplicate scheduled spawns) --------
local function getGen(pPlayer)
    local g = readData(pidOf(pPlayer) .. ":" .. PREFIX .. ":gen")
    return tonumber(g) or 0
end

local function bumpGen(pPlayer)
    local key = pidOf(pPlayer) .. ":" .. PREFIX .. ":gen"
    local g = readData(key)
    g = tonumber(g) or 0
    g = g + 1
    writeData(key, g)
    return g
end
-- --------------------------------------------------------------------

-- ====== BH Taunts ======
local BH_TAUNT_LINES = {
    "You cannot run forever.",
    "There is no escape.",
    "Your lightsaber will make a fine addition to my collection.",
    "The Guild pays extra for live captures, don’t test me.",
    "Stand still; this will only hurt a lot.",
    "I’ve hunted bigger game than you.",
    "I can bring you in warm, or I can bring you in cold.",
    "I have you now.",
    "Don't make me destroy you.",
    "There will be no one to stop us this time.",
    "Ready to die?",
}

-- Local helper (avoids ordering/nil issues at load time)
local function bhSayRandomTaunt(pMob)
    if (pMob == nil) then return 0 end
    local n = #BH_TAUNT_LINES
    if n == 0 then return 0 end
    local idx = getRandomNumber(1, n)  -- inclusive
    spatialChat(pMob, BH_TAUNT_LINES[idx])
    return 0
end

-- ====== BH Victory / Finisher Taunts ======
local BH_FINISHER_LINES = {
    "All too easy.",
    "This is the way.",
    "You are beaten.",
    "Target neutralized.",
    "Another mark paid in full.",
    "The Guild will be pleased.",
}

local function bhSayFinishTaunt(pMob)
    if (pMob == nil) then return 0 end
    local n = #BH_FINISHER_LINES
    if n == 0 then return 0 end
    local idx = getRandomNumber(1, n)  -- inclusive
    spatialChat(pMob, BH_FINISHER_LINES[idx])
    return 0
end

JediKnightVisibilityEncounter = ScreenPlay:new {
    -- Spawn cadence
    LOGIN_GRACE_SECONDS       = 60,               -- no ambush right after login
    FIRST_DELAY_MIN_SECONDS   = 2700,               -- 3–10 min first window
    FIRST_DELAY_MAX_SECONDS   = 7200,
    RESPAWN_MIN_SECONDS       = 2700,               -- after loot, new window
    RESPAWN_MAX_SECONDS       = 7200,
    DESPAWN_MS                = 5 * 60 * 1000,    -- auto-despawn safety if ignored

    -- Light watchdogs (no manual DB logic)
    DEATH_CHECK_PERIOD_MS     = 4000,             -- check owner death/incap regularly
    DEATH_GRACE_SECONDS       = 180,              -- short grace after owner death
    DEATH_RESPAWN_MIN_SECONDS = 2700,              -- window to next encounter after death
    DEATH_RESPAWN_MAX_SECONDS = 7200,
}

registerScreenPlay("JediKnightVisibilityEncounter", true)

function JediKnightVisibilityEncounter:start()
    return true
end

-- Called from playerTriggers.lua on login for Knights
function JediKnightVisibilityEncounter:playerLoggedIn(pPlayer)
    if (pPlayer == nil) then return end
    local pid = pidOf(pPlayer)

    -- grace period after login
    writeData(pid .. ":" .. PREFIX .. ":notBefore", os.time() + self.LOGIN_GRACE_SECONDS)

    -- clear stale mob tracking if any
    local mobOID = readData(pid .. ":" .. PREFIX .. ":mobOID")
    if (mobOID ~= nil) then
        local pMob = getSceneObject(tonumber(mobOID))
        if (pMob == nil) then
            deleteData(pid .. ":" .. PREFIX .. ":mobOID")
            deleteData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID")
            deleteData(pid .. ":" .. PREFIX .. ":tagged")
        end
    end

    -- schedule first window (bumps gen so old timers become stale)
    self:scheduleNext(pPlayer, self.FIRST_DELAY_MIN_SECONDS, self.FIRST_DELAY_MAX_SECONDS)

    -- breadcrumb
    CreatureObject(pPlayer):sendSystemMessage("\\#FFFF80You sense you are being tracked...")
end

function JediKnightVisibilityEncounter:playerLoggedOut(pPlayer)
    if (pPlayer == nil) then return end
    -- Invalidate all pending spawn timers from this session
    bumpGen(pPlayer)
    self:despawnForPlayer(pPlayer)
end

-- Schedule a spawn attempt in [minS, maxS] seconds
function JediKnightVisibilityEncounter:scheduleNext(pPlayer, minS, maxS)
    if (pPlayer == nil) then return end
    local pid   = pidOf(pPlayer)
    local gen   = bumpGen(pPlayer) -- <- new cycle; invalidate older timers
    local delay = getRandomNumber(minS, maxS)
    writeData(pid .. ":" .. PREFIX .. ":nextAt", os.time() + delay)
    -- allow the next window to show the probe again
    deleteData(pid .. ":" .. PREFIX .. ":probeShownGen")
    createEvent(delay * 1000, "JediKnightVisibilityEncounter", "spawnIfEligible", pPlayer, tostring(gen))
    dbg(pPlayer, "scheduled next spawn in " .. delay .. "s (gen " .. gen .. ")")
end

-- Attempt to start encounter if eligible
-- args = stringified generation number that scheduled this attempt.
function JediKnightVisibilityEncounter:spawnIfEligible(pPlayer, args)
    if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then return end
    local co = CreatureObject(pPlayer)
    if (co == nil or not co:hasSkill("force_title_jedi_rank_03")) then return end

    local callGen = tonumber(args) or -1
    local curGen  = getGen(pPlayer)
    if callGen ~= curGen then
        dbg(pPlayer, "stale spawn tick ignored (gen " .. callGen .. " != " .. curGen .. ")")
        return
    end

    local pid = pidOf(pPlayer)

    -- block during login/death grace
    local notBefore = readData(pid .. ":" .. PREFIX .. ":notBefore")
    if (notBefore ~= nil and os.time() < tonumber(notBefore)) then
        dbg(pPlayer, "blocked by grace; retry in 30s (gen " .. callGen .. ")")
        createEvent(30 * 1000, "JediKnightVisibilityEncounter", "spawnIfEligible", pPlayer, tostring(callGen))
        return
    end

    -- prevent duplicate active mob
    local existing = readData(pid .. ":" .. PREFIX .. ":mobOID")
    if (existing ~= nil) then
        local pExisting = getSceneObject(tonumber(existing))
        if (pExisting ~= nil) then
            -- *** CHANGED: Only treat as active if it's a *living* CreatureObject.
            local isAlive = false
            local ok, deadFlag = pcall(function() return CreatureObject(pExisting):isDead() end)
            if ok then
                isAlive = (deadFlag == false)
            else
                -- Not a CreatureObject (likely a corpse container) → not alive
                isAlive = false
            end

            if isAlive then
                dbg(pPlayer, "hunter already active; skipping spawn (gen " .. callGen .. ")")
                return
            else
                -- It’s a corpse or invalid; do not block spawns. Keep mob→owner mapping for loot,
                -- but clear the player→mob pointer so new BHs can spawn.
                deleteData(pid .. ":" .. PREFIX .. ":mobOID") -- *** CHANGED
                dbg(pPlayer, "previous hunter no longer alive; clearing active pointer and proceeding")
            end
        else
            -- stale
            deleteData(pid .. ":" .. PREFIX .. ":mobOID")
            deleteData("mob:" .. existing .. ":" .. PREFIX .. ":ownerPID")
            deleteData(pid .. ":" .. PREFIX .. ":tagged")
        end
    end

    -- Optional: pre-check location (indoors/NPC-city). Safe no-op if not defined.
    if (JediKnightThugEncounter.isPlayerInPositionForEncounter ~= nil) then
        if not JediKnightThugEncounter:isPlayerInPositionForEncounter(pPlayer) then
            dbg(pPlayer, "not in a valid spot; retry in 60s (gen " .. callGen .. ")")
            createEvent(60 * 1000, "JediKnightVisibilityEncounter", "spawnIfEligible", pPlayer, tostring(callGen))
            return
        end
    end

    -- Always clean up any stray probe before a new attempt
    self:despawnProbeByOwner(pPlayer)

    -- Show the probe only once per generation (window). On retries, skip the probe.
    local shownGen = tonumber(readData(pid .. ":" .. PREFIX .. ":probeShownGen")) or -1

    if shownGen ~= curGen then
        writeData(pid .. ":" .. PREFIX .. ":probeShownGen", curGen)
        -- prelude first; after it ends, finishPreludeStartEncounter will try BH start
        createEvent(0, "JediKnightVisibilityEncounter", "beginPreludeThenEncounter", pPlayer, tostring(curGen))
        dbg(pPlayer, "probe prelude scheduled once for gen " .. curGen)
    else
        -- Skip prelude on retries within the same window; try starting BH directly.
        if not JediKnightThugEncounter:start(pPlayer) then
            dbg(pPlayer, "start() failed on retry; scheduling another attempt in 30s (no probe)")
            createEvent(30 * 1000, "JediKnightVisibilityEncounter", "spawnIfEligible", pPlayer, tostring(curGen))
            return
        end
        dbg(pPlayer, "encounter started on retry (no probe this time)")
    end
end

-- Reassert target shortly after spawn (helps initial aggro)
function JediKnightVisibilityEncounter:retargetKnight(pPlayer)
    if (pPlayer == nil) then return end
    local mobOID = readData(pidOf(pPlayer) .. ":" .. PREFIX .. ":mobOID")
    if (mobOID == nil) then return end
    local pMob = getSceneObject(tonumber(mobOID))
    if (pMob == nil) then return end

    if (AiAgent ~= nil) then
        AiAgent(pMob):addDefender(pPlayer)
    end
    CreatureObject(pMob):engageCombat(pPlayer)
end

-- ======================================
-- Encounter (Sith Shadow style scaffold)
-- ======================================
JediKnightThugEncounter = Encounter:new {
    taskName             = "JediKnightThugEncounter",
    encounterDespawnTime = 5 * 60 * 1000,
    spawnObjectList = {
        {
            template         = "jk_hunt_bh", -- your custom hunter (customAiMap="enclaveSentinel")
            minimumDistance  = 30,
            maximumDistance  = 45,
            referencePoint   = 0,
            followPlayer     = true,
            setNotAttackable = false,
            runOnDespawn     = true
        }
    }
}

function JediKnightThugEncounter:start(pPlayer)
    return self:taskStart(pPlayer)
end

function JediKnightThugEncounter:taskStart(pPlayer, ...)
    if (pPlayer == nil) then return false end
    if not CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_03") then return false end

    local ok = self:createEncounter(pPlayer)
    if not ok then return false end

    local pid = pidOf(pPlayer)
    local spawned = SpawnMobiles.getSpawnedMobiles(pPlayer, self.taskName)
    if (spawned ~= nil) then
        for i = 1, #spawned do
            local mob = spawned[i]
            if SpawnMobiles.isValidMobile(mob) then
                local mobOID = SceneObject(mob):getObjectID()

                -- owner mapping
                writeData(pid .. ":" .. PREFIX .. ":mobOID", mobOID)
                writeData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID", pid)

                -- observers
                createObserver(DAMAGERECEIVED,    "JediKnightVisibilityEncounter", "onThugDamaged", mob)
                createObserver(OBJECTDESTRUCTION, "JediKnightVisibilityEncounter", "onThugDied",    mob)
                createObserver(LOOTCREATURE,      "JediKnightVisibilityEncounter", "onThugLooted",  mob)

                -- initial aggro nudge
                if (AiAgent ~= nil) then
                    AiAgent(mob):addDefender(pPlayer)
                end
                CreatureObject(mob):engageCombat(pPlayer)
                
                -- TAUNT once on spawn
                bhSayRandomTaunt(mob)           -- or: createEvent(500, "HelperFuncs", "spatialChatTask", mob, BH_TAUNT_LINES[getRandomNumber(1, #BH_TAUNT_LINES)])

                -- minimal timers
                createEvent(2000, "JediKnightVisibilityEncounter", "retargetKnight", pPlayer, "")
                createEvent(JediKnightVisibilityEncounter.DESPAWN_MS, "JediKnightVisibilityEncounter", "onDespawnTimer", pPlayer, "")
                -- simple death watchdog (no DB logic here)
                createEvent(JediKnightVisibilityEncounter.DEATH_CHECK_PERIOD_MS, "JediKnightVisibilityEncounter", "onDeathWatchdog", pPlayer, "")
            end
        end
    end

    CreatureObject(pPlayer):sendSystemMessage("\\#FFA500A Bounty Hunter is on your trail!")
    return true
end

-- Tag credit if owner dealt damage
function JediKnightVisibilityEncounter:onThugDamaged(pMob, pAttacker, damage)
    if (pMob == nil or pAttacker == nil) then return 0 end
    if (not SceneObject(pAttacker):isPlayerCreature()) then return 0 end

    local mobOID   = SceneObject(pMob):getObjectID()
    local ownerPID = readData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID")
    if (ownerPID == nil) then return 0 end

    if (SceneObject(pAttacker):getObjectID() == tonumber(ownerPID)) then
        writeData(ownerPID .. ":" .. PREFIX .. ":tagged", 1)
    end
    return 0
end

-- Award XP on death (if owner killed OR tagged); advance loop on death; DO NOT cleanup here
function JediKnightVisibilityEncounter:onThugDied(pMob, pKiller)
    if (pMob == nil) then return 0 end
    local mobOID   = SceneObject(pMob):getObjectID()
    local ownerPID = readData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID")
    if (ownerPID == nil) then return 0 end

    local pOwner = getSceneObject(tonumber(ownerPID))
    local ownerIsKnight = (pOwner ~= nil and SceneObject(pOwner):isPlayerCreature()
        and CreatureObject(pOwner):hasSkill("force_title_jedi_rank_03"))

    local killerIsOwner = false
    if (pKiller ~= nil and SceneObject(pKiller):isPlayerCreature()) then
        killerIsOwner = (SceneObject(pKiller):getObjectID() == tonumber(ownerPID))
    end

    local tagged = readData(ownerPID .. ":" .. PREFIX .. ":tagged")
    local ownerTagged = (tagged ~= nil and tonumber(tagged) == 1)

    -- XP stays the same
    if ownerIsKnight and (killerIsOwner or ownerTagged) then
        CreatureObject(pOwner):awardExperience("force_rank_xp", 1000, true)
    end

    -- NEW: advance the loop on death (instead of waiting for loot)
    if (pOwner ~= nil) then
        -- prevent loot handler from scheduling again
        writeData(ownerPID .. ":" .. PREFIX .. ":rescheduledOnDeath", 1)
        JediKnightVisibilityEncounter:scheduleNext(
            pOwner,
            JediKnightVisibilityEncounter.RESPAWN_MIN_SECONDS,
            JediKnightVisibilityEncounter.RESPAWN_MAX_SECONDS
        )
        CreatureObject(pOwner):sendSystemMessage("\\#FFFF80You feel the hunter's network regrouping...")
    end

    -- *** CHANGED: Clear the player→mob active pointer now that the hunter is dead,
    -- while keeping the mob→owner mapping for corpse attribution and cleanup.
    deleteData(ownerPID .. ":" .. PREFIX .. ":mobOID")

    -- Keep owner mapping until loot so we can attribute the corpse.
    -- Safety: if never looted, clean up after 20 minutes (no additional scheduling here).
    createEvent(20 * 60 * 1000, "JediKnightVisibilityEncounter", "onCorpseTimeout", pOwner, tostring(mobOID))
    return 0
end

-- Loot now only cleans up; schedules next window only if death didn't already do it
function JediKnightVisibilityEncounter:onThugLooted(pMob, pLooter, _)
    if (pMob == nil or pLooter == nil) then return 0 end
    if (not SceneObject(pLooter):isPlayerCreature()) then return 0 end

    local mobOID   = SceneObject(pMob):getObjectID()
    local ownerPID = readData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID")
    if (ownerPID == nil) then return 0 end

    if (SceneObject(pLooter):getObjectID() ~= tonumber(ownerPID)) then
        return 0
    end

    -- If we didn't already schedule on death (e.g., owner was nil at the time), do it now as a fallback
    local alreadyRescheduled = (readData(ownerPID .. ":" .. PREFIX .. ":rescheduledOnDeath") ~= nil)
    if (not alreadyRescheduled) then
        JediKnightVisibilityEncounter:scheduleNext(
            pLooter,
            JediKnightVisibilityEncounter.RESPAWN_MIN_SECONDS,
            JediKnightVisibilityEncounter.RESPAWN_MAX_SECONDS
        )
        CreatureObject(pLooter):sendSystemMessage("\\#FFFF80You feel the hunter's network regrouping...")
    end

    -- cleanup now that corpse was handled
    deleteData(ownerPID .. ":" .. PREFIX .. ":mobOID")
    deleteData(ownerPID .. ":" .. PREFIX .. ":tagged")
    deleteData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID")
    deleteData(ownerPID .. ":" .. PREFIX .. ":rescheduledOnDeath")
    return 0
end

-- Corpse was never looted: just cleanup (do NOT schedule next cycle)
function JediKnightVisibilityEncounter:onCorpseTimeout(pOwner, args)
    if (pOwner == nil) then return 0 end
    local mobOID = tonumber(args) or 0
    if mobOID == 0 then return 0 end

    local ownerPID = pidOf(pOwner)
    local mappedOwner = readData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID")
    if (mappedOwner ~= nil and tonumber(mappedOwner) == ownerPID) then
        deleteData(ownerPID .. ":" .. PREFIX .. ":mobOID")
        deleteData(ownerPID .. ":" .. PREFIX .. ":tagged")
        deleteData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID")
        deleteData(ownerPID .. ":" .. PREFIX .. ":rescheduledOnDeath")
        dbg(pOwner, "corpse timeout cleanup")
    end
    return 0
end

-- Lightweight death watchdog (no DB logic): if owner dies, despawn & reschedule with grace
function JediKnightVisibilityEncounter:onDeathWatchdog(pPlayer)
    if (pPlayer == nil) then return 0 end

    local pid    = pidOf(pPlayer)
    local mobOID = readData(pid .. ":" .. PREFIX .. ":mobOID")

    if (mobOID == nil) then return 0 end
    local pMob = getSceneObject(tonumber(mobOID))
    if (pMob == nil) then
        -- Hunter disappeared; cleanup mapping
        deleteData(pid .. ":" .. PREFIX .. ":mobOID")
        deleteData(pid .. ":" .. PREFIX .. ":tagged")
        deleteData("mob:" .. tostring(mobOID) .. ":" .. PREFIX .. ":ownerPID")
        return 0
    end

    local ownerCO = CreatureObject(pPlayer)
    if (ownerCO ~= nil and ownerCO:isDead()) then
        dbg(pPlayer, "owner dead: hunter withdrawing")

        -- Victory taunt (if hunter still present)
        if (pMob ~= nil) then bhSayFinishTaunt(pMob) end

        -- EXACTLY like Village: run away now, despawn ~18s later
        createEvent(2 * 1000, "JediKnightThugEncounter", "handleDespawnEvent", pPlayer, "")

        -- keep your grace + reschedule timings
        writeData(pid .. ":" .. PREFIX .. ":notBefore", os.time() + self.DEATH_GRACE_SECONDS)
        self:scheduleNext(pPlayer, self.DEATH_RESPAWN_MIN_SECONDS, self.DEATH_RESPAWN_MAX_SECONDS)
        CreatureObject(pPlayer):sendSystemMessage("\\#FF8080The hunter withdraws into the shadows...")

        -- cleanup encounter keys now; the Encounter will finish the despawn later
        if (mobOID ~= nil) then
            deleteData("mob:" .. tostring(mobOID) .. ":" .. PREFIX .. ":ownerPID")
        end
        deleteData(pid .. ":" .. PREFIX .. ":mobOID")
        deleteData(pid .. ":" .. PREFIX .. ":tagged")
        return 0
    end

    -- keep watching while hunter exists
    createEvent(self.DEATH_CHECK_PERIOD_MS, "JediKnightVisibilityEncounter", "onDeathWatchdog", pPlayer, "")
    return 0
end

function JediKnightVisibilityEncounter:onDespawnTimer(pPlayer)
    self:despawnForPlayer(pPlayer)
end

function JediKnightVisibilityEncounter:despawnForPlayer(pPlayer)
    if (pPlayer == nil) then return end

    local pid    = pidOf(pPlayer)
    local mobOID = readData(pid .. ":" .. PREFIX .. ":mobOID")
    local pMob   = nil
    if (mobOID ~= nil) then
        pMob = getSceneObject(tonumber(mobOID))
    end

    -- Encounter-aware despawn via helper
    if (SpawnMobiles ~= nil) then
        SpawnMobiles.despawnMobiles(pPlayer, JediKnightThugEncounter.taskName, false)
    end

    -- Strong fallback: directly destroy the tracked mob if still present
    if (pMob ~= nil) then
        local so = SceneObject(pMob)
        if (so ~= nil) then
            so:destroyObjectFromWorld()
        end
    end

    -- cleanup keys
    if (mobOID ~= nil) then
        deleteData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID")
    end
    deleteData(pid .. ":" .. PREFIX .. ":mobOID")
    deleteData(pid .. ":" .. PREFIX .. ":tagged")
end

-- =========================
-- Probe prelude & orchestration
-- =========================

-- Despawn any stored probe for this player (robust; safe if absent)
function JediKnightVisibilityEncounter:despawnProbeByOwner(pPlayer)
    if (pPlayer == nil) then return 0 end
    local key = pidOf(pPlayer) .. ":" .. PREFIX .. ":probeOID"
    local oidStr = readData(key)
    if (oidStr ~= nil) then
        local pProbe = getSceneObject(tonumber(oidStr))
        if (pProbe ~= nil) then
            local ok = pcall(function() createEvent(0, "HelperFuncs", "despawnMobileTask", pProbe, "") end)
            if (not ok) then
                local so = SceneObject(pProbe)
                if (so ~= nil) then so:destroyObjectFromWorld() end
            end
        end
        deleteData(key)
    end
    return 0
end

-- Spawn probe now; remember OID; schedule despawn and encounter start
function JediKnightVisibilityEncounter:beginPreludeThenEncounter(pPlayer, genStr)
    if (pPlayer == nil) then return 0 end

    local scheduledGen = tonumber(genStr) or -1
    local curGen = tonumber(readData(pidOf(pPlayer) .. ":" .. PREFIX .. ":gen")) or 0
    if scheduledGen ~= curGen then
        return 0
    end

    -- Spawn Imperial Probe Droid a bit to the side
    local so   = SceneObject(pPlayer)
    local zone = so:getZoneName()
    local px   = so:getWorldPositionX()
    local py   = so:getWorldPositionY()
    local pz   = so:getWorldPositionZ()

    local heading = getRandomNumber(360) - 180
    local offset  = 20  -- ~20m lateral

    -- spawnMobile uses (x, z, y)
    local pProbe = spawnMobile(zone, "imperial_probe_drone", 0, px + offset, pz, py, heading, 0, "")
    if (pProbe ~= nil) then
        -- Robust chat: use the global helper (method form may not be bound)
        spatialChat(pProbe, "Target located. Reporting back.")
        writeData(pidOf(pPlayer) .. ":" .. PREFIX .. ":probeOID", SceneObject(pProbe):getObjectID())
    end

    -- Despawn probe after lifetime, then start the encounter
    createEvent(PROBE_PRELUDE_LIFETIME_MS, "JediKnightVisibilityEncounter", "finishPreludeStartEncounter", pPlayer, genStr)
    return 0
end

-- Finish the probe prelude: ensure probe is gone, then (re)start encounter sanely.
function JediKnightVisibilityEncounter:finishPreludeStartEncounter(pPlayer, _genStr)
    if (pPlayer == nil) then return 0 end

    -- Ensure probe is despawned
    self:despawnProbeByOwner(pPlayer)

    -- If a hunter is already active, we're done.
    local existing = readData(pidOf(pPlayer) .. ":" .. PREFIX .. ":mobOID")
    if (existing ~= nil) then
        local pExisting = getSceneObject(tonumber(existing))
        if (pExisting ~= nil) then
            -- Only block if *alive* (same logic as in spawnIfEligible)
            local ok, deadFlag = pcall(function() return CreatureObject(pExisting):isDead() end)
            if ok and (deadFlag == false) then
                dbg(pPlayer, "prelude finished: hunter already active; skipping start")
                return 0
            else
                deleteData(pidOf(pPlayer) .. ":" .. PREFIX .. ":mobOID")
            end
        else
            -- stale mapping
            deleteData(pidOf(pPlayer) .. ":" .. PREFIX .. ":mobOID")
            deleteData("mob:" .. tostring(existing) .. ":" .. PREFIX .. ":ownerPID")
            deleteData(pidOf(pPlayer) .. ":" .. PREFIX .. ":tagged")
        end
    end

    -- If current location isn't valid anymore, reschedule a normal attempt and exit.
    if (JediKnightThugEncounter.isPlayerInPositionForEncounter ~= nil)
       and (not JediKnightThugEncounter:isPlayerInPositionForEncounter(pPlayer)) then
        dbg(pPlayer, "prelude finished: location invalid; retrying window in 30s")
        -- Use the CURRENT generation; don't bump it here.
        local curGen = tonumber(readData(pidOf(pPlayer) .. ":" .. PREFIX .. ":gen")) or 0
        createEvent(30 * 1000, "JediKnightVisibilityEncounter", "spawnIfEligible", pPlayer, tostring(curGen))
        return 0
    end

    -- Try to start now. If it fails, hand control back to spawnIfEligible (no 3s spin).
    if (not JediKnightThugEncounter:start(pPlayer)) then
        dbg(pPlayer, "prelude finished: start() failed; retrying window in 30s")
        local curGen = tonumber(readData(pidOf(pPlayer) .. ":" .. PREFIX .. ":gen")) or 0
        createEvent(30 * 1000, "JediKnightVisibilityEncounter", "spawnIfEligible", pPlayer, tostring(curGen))
        return 0
    end

    dbg(pPlayer, "prelude finished: hunter engaged")
    return 0
end

return JediKnightVisibilityEncounter