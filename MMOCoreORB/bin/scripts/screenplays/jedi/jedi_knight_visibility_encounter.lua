-- Jedi Knight Hunt Encounter (persistent, login-driven)
-- Visibility-agnostic. Lean version for AI-driven deathblow (via customAiMap).
-- Adds per-player generation tokens to prevent stacked spawns across relogs.

local ObjectManager = require("managers.object.object_manager")
local SpawnMobiles  = require("utils.spawn_mobiles")

local PREFIX = "JkhEnc"
local DEBUG  = true -- keep ON while testing

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

JediKnightVisibilityEncounter = ScreenPlay:new {
    -- Spawn cadence
    LOGIN_GRACE_SECONDS       = 60,               -- no ambush right after login
    FIRST_DELAY_MIN_SECONDS   = 60,               -- 3–10 min first window
    FIRST_DELAY_MAX_SECONDS   = 80,
    RESPAWN_MIN_SECONDS       = 60,               -- after loot, new window
    RESPAWN_MAX_SECONDS       = 80,
    DESPAWN_MS                = 5 * 60 * 1000,     -- auto-despawn safety if ignored

    -- Light watchdogs (no manual DB logic)
    DEATH_CHECK_PERIOD_MS     = 4000,              -- check owner death/incap regularly
    DEATH_GRACE_SECONDS       = 180,               -- short grace after owner death
    DEATH_RESPAWN_MIN_SECONDS = 300,               -- window to next encounter after death
    DEATH_RESPAWN_MAX_SECONDS = 900,
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
    CreatureObject(pPlayer):sendSystemMessage("\\#FFFF80You sense you are being watched...")
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
            dbg(pPlayer, "hunter already active; skipping spawn (gen " .. callGen .. ")")
            return
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

    -- start encounter
    if JediKnightThugEncounter:start(pPlayer) then
        dbg(pPlayer, "encounter started (gen " .. callGen .. ")")
    else
        dbg(pPlayer, "start returned false; retrying in 60s (gen " .. callGen .. ")")
        createEvent(60 * 1000, "JediKnightVisibilityEncounter", "spawnIfEligible", pPlayer, tostring(callGen))
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

-- Award XP on death (if owner killed OR tagged); DO NOT cleanup here
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

    if ownerIsKnight and (killerIsOwner or ownerTagged) then
        CreatureObject(pOwner):awardExperience("force_rank_xp", 1000, true)
    end

    -- Keep owner mapping until loot so we can attribute the corpse.
    -- Safety: if never looted, clean up after 20 minutes (no respawn on timeout).
    createEvent(20 * 60 * 1000, "JediKnightVisibilityEncounter", "onCorpseTimeout", pOwner, tostring(mobOID))
    return 0
end

-- Loot advances the loop (owner-only), then cleanup
function JediKnightVisibilityEncounter:onThugLooted(pMob, pLooter, _)
    if (pMob == nil or pLooter == nil) then return 0 end
    if (not SceneObject(pLooter):isPlayerCreature()) then return 0 end

    local mobOID   = SceneObject(pMob):getObjectID()
    local ownerPID = readData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID")
    if (ownerPID == nil) then return 0 end

    if (SceneObject(pLooter):getObjectID() ~= tonumber(ownerPID)) then
        return 0
    end

    -- schedule next cycle after loot (new gen)
    JediKnightVisibilityEncounter:scheduleNext(
        pLooter,
        JediKnightVisibilityEncounter.RESPAWN_MIN_SECONDS,
        JediKnightVisibilityEncounter.RESPAWN_MAX_SECONDS
    )
    CreatureObject(pLooter):sendSystemMessage("\\#FFFF80You feel the hunter's network regrouping...")

    -- cleanup now that loop advanced
    deleteData(ownerPID .. ":" .. PREFIX .. ":mobOID")
    deleteData(ownerPID .. ":" .. PREFIX .. ":tagged")
    deleteData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID")
    return 0 -- don't interfere with loot flow
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

return JediKnightVisibilityEncounter