-- Jedi Knight Visibility Encounter (Encounter-based, event-only)
-- Triggered from C++ VisibilityManager when newVis >= threshold and the per-player cooldown gate has elapsed.

local ObjectManager = require("managers.object.object_manager")
local SpawnMobiles  = require("utils.spawn_mobiles")

-- Storage prefix for per-player keys
local PREFIX = "JkvEnc"
local DEBUG  = false -- set true while testing to get breadcrumbs

local function dbg(co, msg)
    if DEBUG and co ~= nil then
        CreatureObject(co):sendSystemMessage("\\#888888[JKV] " .. msg)
    end
end

-- ===========================
-- Main screenplay definition
-- ===========================
JediKnightVisibilityEncounter = ScreenPlay:new {
    -- No polling. C++ calls :onVisibilityIncreased when eligible.
    LOGIN_GRACE_SECONDS = 120,            -- block spawns right after login
    DESPAWN_MS          = 5 * 60 * 1000,  -- thug lifetime if ignored (5 minutes)
    SPAWN_GUARD_MS      = 2000            -- prevent double-fires within 2s
}

registerScreenPlay("JediKnightVisibilityEncounter", true)

function JediKnightVisibilityEncounter:start()
    -- No world spawns on boot; everything is event-driven.
    return true
end

-- Called from playerTriggers.lua (only for Knights)
function JediKnightVisibilityEncounter:playerLoggedIn(pPlayer)
    if (pPlayer == nil) then return end
    local pid = SceneObject(pPlayer):getObjectID()

    -- seed a grace window on login
    writeData(pid .. ":" .. PREFIX .. ":notBefore", os.time() + self.LOGIN_GRACE_SECONDS)

    -- clear stale mob tracking if needed
    local mobOID = readData(pid .. ":" .. PREFIX .. ":mobOID")
    if (mobOID ~= nil) then
        local pMob = getSceneObject(tonumber(mobOID))
        if (pMob == nil) then
            deleteData(pid .. ":" .. PREFIX .. ":mobOID")
            deleteData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID")
            deleteData(pid .. ":" .. PREFIX .. ":tagged")
        end
    end
end

function JediKnightVisibilityEncounter:playerLoggedOut(pPlayer)
    if (pPlayer == nil) then return end
    self:despawnForPlayer(pPlayer)
end

-- ====================================
-- C++ hook: called when threshold hit
-- Receives (pPlayer, threshold, cooldownSeconds)
-- ====================================
function JediKnightVisibilityEncounter:onVisibilityIncreased(pPlayer, threshold, cooldownSeconds)
    if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then return end
    local co = CreatureObject(pPlayer)
    if (co == nil or not co:hasSkill("force_title_jedi_rank_03")) then return end

    local pid = SceneObject(pPlayer):getObjectID()

    -- cache the current threshold/cooldown for this Knight (used by the retry timer)
    if (threshold ~= nil) then writeData(pid .. ":" .. PREFIX .. ":thr", tonumber(threshold)) end
    if (cooldownSeconds ~= nil) then writeData(pid .. ":" .. PREFIX .. ":cd",  tonumber(cooldownSeconds)) end

    -- spawn guard: avoid back-to-back double triggers within a few ms
    local nowms = os.time() * 1000
    local last  = readData(pid .. ":" .. PREFIX .. ":spawnGuard")
    if (last ~= nil and nowms < tonumber(last)) then
        dbg(pPlayer, "spawn guarded")
        return
    end
    writeData(pid .. ":" .. PREFIX .. ":spawnGuard", nowms + self.SPAWN_GUARD_MS)

    -- Respect login grace
    local notBefore = readData(pid .. ":" .. PREFIX .. ":notBefore")
    if (notBefore ~= nil and os.time() < tonumber(notBefore)) then
        dbg(pPlayer, "blocked by login grace")
        return
    end

    -- One-active-encounter: if a thug is still up, replace it so new triggers work
    local mobOID = readData(pid .. ":" .. PREFIX .. ":mobOID")
    if (mobOID ~= nil) then
        local pExisting = getSceneObject(tonumber(mobOID))
        if (pExisting ~= nil) then
            dbg(pPlayer, "replacing existing thug")
            self:despawnForPlayer(pPlayer) -- clear old one
        else
            -- stale; clean up keys
            deleteData(pid .. ":" .. PREFIX .. ":mobOID")
            deleteData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID")
            deleteData(pid .. ":" .. PREFIX .. ":tagged")
        end
    end

    -- Try to start the encounter (announcement happens inside the encounter on success)
    if JediKnightThugEncounter:start(pPlayer) then
        dbg(pPlayer, "encounter started")
        -- schedule a post-cooldown retry check so we can spawn again even without a vis bump
        local cd = readData(pid .. ":" .. PREFIX .. ":cd")
        if (cd ~= nil) then
            createEvent(tonumber(cd) * 1000, "JediKnightVisibilityEncounter", "cooldownCheck", pPlayer, "")
        end
    else
        dbg(pPlayer, "encounter start returned false")
    end
end

-- Fired after the cooldown window. If the Knight is still >= threshold, spawn again.
function JediKnightVisibilityEncounter:cooldownCheck(pPlayer)
    if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then return end
    local co = CreatureObject(pPlayer)
    if (co == nil or not co:hasSkill("force_title_jedi_rank_03")) then return end

    local pid = SceneObject(pPlayer):getObjectID()
    local thr = readData(pid .. ":" .. PREFIX .. ":thr")
    if (thr == nil) then return end
    thr = tonumber(thr)

    -- read current visibility
    local pGhost = co:getPlayerObject()
    if (pGhost == nil) then return end
    local vis = math.floor(PlayerObject(pGhost):getVisibility() or 0)

    if (vis < thr) then
        dbg(pPlayer, "cooldownCheck: below threshold (" .. vis .. " < " .. thr .. ")")
        return
    end

    -- if an old thug is still around, replace it so the new attempt can start cleanly
    local mobOID = readData(pid .. ":" .. PREFIX .. ":mobOID")
    if (mobOID ~= nil) then
        local pExisting = getSceneObject(tonumber(mobOID))
        if (pExisting ~= nil) then
            dbg(pPlayer, "cooldownCheck: despawning old thug")
            self:despawnForPlayer(pPlayer)
        else
            deleteData(pid .. ":" .. PREFIX .. ":mobOID")
            deleteData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID")
            deleteData(pid .. ":" .. PREFIX .. ":tagged")
        end
    end

    dbg(pPlayer, "cooldownCheck: starting new encounter")
    JediKnightThugEncounter:start(pPlayer)
end

-- ===========================
-- Encounter task (Sith-Shadow style)
-- ===========================
JediKnightThugEncounter = Encounter:new {
    taskName             = "JediKnightThugEncounter",
    encounterDespawnTime = 5 * 60 * 1000,  -- keep in sync with DESPAWN_MS
    spawnObjectList = {
        {
            template = "bounty_hunter_thug",
            minimumDistance = 64,  -- per your request
            maximumDistance = 90,
            referencePoint  = 0,
            followPlayer    = true,
            setNotAttackable = false,
            runOnDespawn    = true
        }
    }
}

-- Provide a start() alias to mirror other Encounters
function JediKnightThugEncounter:start(pPlayer)
    return self:taskStart(pPlayer)
end

function JediKnightThugEncounter:taskStart(pPlayer, ...)
    if (pPlayer == nil) then return false end
    if not CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_03") then return false end

    local ok = self:createEncounter(pPlayer)
    if not ok then return false end

    local pid = SceneObject(pPlayer):getObjectID()
    local spawned = SpawnMobiles.getSpawnedMobiles(pPlayer, self.taskName)
    if (spawned ~= nil) then
        for i = 1, #spawned do
            local mob = spawned[i]
            if SpawnMobiles.isValidMobile(mob) then
                local mobOID = SceneObject(mob):getObjectID()

                -- Track ownership for credit logic
                writeData(pid .. ":" .. PREFIX .. ":mobOID", mobOID)
                writeData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID", pid)

                -- Observe damage and death
                createObserver(DAMAGERECEIVED,    "JediKnightVisibilityEncounter", "onThugDamaged", mob)
                createObserver(OBJECTDESTRUCTION, "JediKnightVisibilityEncounter", "onThugDied",    mob)

                -- Force aggro on the Knight
                if (AiAgent ~= nil) then
                    AiAgent(mob):addDefender(pPlayer)
                end
                CreatureObject(mob):addHate(pPlayer, 100000)
                CreatureObject(mob):engageCombat(pPlayer)
            end
        end
    end

    -- Reassert target once in case something stole initial aggro
    createEvent(2000, "JediKnightVisibilityEncounter", "retargetKnight", pPlayer, "")
    -- Auto-despawn (matches encounterDespawnTime)
    createEvent(self.encounterDespawnTime, "JediKnightVisibilityEncounter", "onDespawnTimer", pPlayer, "")

    -- Announce on confirmed spawn
    CreatureObject(pPlayer):sendSystemMessage("\\#FFCC00A bounty hunter has picked up your trail!")

    return true
end

-- ===========================
-- Helpers / observers
-- ===========================
function JediKnightVisibilityEncounter:retargetKnight(pPlayer)
    if (pPlayer == nil) then return end
    local pid = SceneObject(pPlayer):getObjectID()
    local mobOID = readData(pid .. ":" .. PREFIX .. ":mobOID")
    if (mobOID == nil) then return end

    local pMob = getSceneObject(tonumber(mobOID))
    if (pMob == nil) then return end

    if (AiAgent ~= nil) then
        AiAgent(pMob):addDefender(pPlayer)
    end
    CreatureObject(pMob):addHate(pPlayer, 100000)
    CreatureObject(pMob):engageCombat(pPlayer)
end

-- Mark the Knight as having "tagged" the mob (did damage)
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

-- Award credit if the Knight killed OR had tagged the mob
function JediKnightVisibilityEncounter:onThugDied(pMob, pKiller)
    if (pMob == nil) then return 0 end

    local mobOID   = SceneObject(pMob):getObjectID()
    local ownerPID = readData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID")
    if (ownerPID == nil) then return 0 end

    local pOwner = getSceneObject(tonumber(ownerPID))
    local ownerIsKnight = (pOwner ~= nil and SceneObject(pOwner):isPlayerCreature() and CreatureObject(pOwner):hasSkill("force_title_jedi_rank_03"))

    local killerIsOwner = false
    if (pKiller ~= nil and SceneObject(pKiller):isPlayerCreature()) then
        killerIsOwner = (SceneObject(pKiller):getObjectID() == tonumber(ownerPID))
    end

    local tagged = readData(ownerPID .. ":" .. PREFIX .. ":tagged")
    local ownerTagged = (tagged ~= nil and tonumber(tagged) == 1)

    if ownerIsKnight and (killerIsOwner or ownerTagged) then
        CreatureObject(pOwner):awardExperience("force_rank_xp", 1000, true)
        CreatureObject(pOwner):sendSystemMessage("\\#00FF00You earned 1,000 Force Rank XP for defeating the attacker.")
    end

    -- cleanup keys
    deleteData(ownerPID .. ":" .. PREFIX .. ":mobOID")
    deleteData(ownerPID .. ":" .. PREFIX .. ":tagged")
    deleteData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID")

    return 0
end

function JediKnightVisibilityEncounter:onDespawnTimer(pPlayer)
    self:despawnForPlayer(pPlayer)
end

function JediKnightVisibilityEncounter:despawnForPlayer(pPlayer)
    if (pPlayer == nil) then return end

    -- Encounter-aware despawn
    if (SpawnMobiles ~= nil) then
        SpawnMobiles.despawnMobiles(pPlayer, JediKnightThugEncounter.taskName, false)
    end

    local pid    = SceneObject(pPlayer):getObjectID()
    local mobOID = readData(pid .. ":" .. PREFIX .. ":mobOID")
    if (mobOID ~= nil) then
        deleteData(pid .. ":" .. PREFIX .. ":mobOID")
        deleteData(pid .. ":" .. PREFIX .. ":tagged")
        deleteData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID")
    end
end

return JediKnightVisibilityEncounter