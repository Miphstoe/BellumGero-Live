local ObjectManager = require("managers.object.object_manager")

-- Storage prefix for per-player data
local PREFIX = "JkvEnc"

JediKnightVisibilityEncounter = ScreenPlay:new {
    LOGIN_GRACE_SECONDS = 120,  -- time after login before an encounter may fire
    DESPAWN_MS = 5 * 60 * 1000, -- thug lifetime if ignored (5 minutes)
}

registerScreenPlay("JediKnightVisibilityEncounter", true)

function JediKnightVisibilityEncounter:start()
    -- No world spawns on boot; logic is event-only (called from C++).
    return true
end

-- Seed login grace and clear any stale tracking
function JediKnightVisibilityEncounter:playerLoggedIn(pPlayer)
    if (pPlayer == nil) then return end
    local pid = SceneObject(pPlayer):getObjectID()
    writeData(pid .. ":" .. PREFIX .. ":notBefore", os.time() + self.LOGIN_GRACE_SECONDS)
    -- Optional: clear stale mob pointer if the mob no longer exists
    local mobOID = readData(pid .. ":" .. PREFIX .. ":mobOID")
    if (mobOID ~= nil) then
        local pMob = getSceneObject(tonumber(mobOID))
        if (pMob == nil) then
            deleteData(pid .. ":" .. PREFIX .. ":mobOID")
            deleteData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID")
        end
    end
end

function JediKnightVisibilityEncounter:playerLoggedOut(pPlayer)
    if (pPlayer == nil) then return end
    self:despawnForPlayer(pPlayer)
end

-- Called from C++ when (newVis >= threshold) and the per-player cooldown gate passed.
function JediKnightVisibilityEncounter:onVisibilityIncreased(pPlayer)
    if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then return end
    local co = CreatureObject(pPlayer)
    if (co == nil or not co:hasSkill("force_title_jedi_rank_03")) then return end

    -- Respect login grace
    local pid = SceneObject(pPlayer):getObjectID()
    local notBefore = readData(pid .. ":" .. PREFIX .. ":notBefore")
    if (notBefore ~= nil and os.time() < tonumber(notBefore)) then
        return
    end

    -- Only one active encounter per player
    local mobOID = readData(pid .. ":" .. PREFIX .. ":mobOID")
    if (mobOID ~= nil and tonumber(mobOID) > 0) then
        local pExisting = getSceneObject(tonumber(mobOID))
        if (pExisting ~= nil) then
            return
        end
        -- stale pointer; clear it
        deleteData(pid .. ":" .. PREFIX .. ":mobOID")
        deleteData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID")
    end

    self:startEncounter(pPlayer)
end

function JediKnightVisibilityEncounter:startEncounter(pPlayer)
    if (pPlayer == nil) then return end

    local zone = SceneObject(pPlayer):getZoneName()
    local px = SceneObject(pPlayer):getWorldPositionX()
    local py = SceneObject(pPlayer):getWorldPositionY()
    local sx, sy = px + 6, py + 6
    local sz = getTerrainHeight(zone, sx, sy)

    local mob = spawnMobile(zone, "bounty_hunter_thug", 0, sx, sz, sy, 0, 0)
    if (mob == nil) then
        CreatureObject(pPlayer):sendSystemMessage("Could not spawn bounty hunter thug.")
        return
    end

    local mobOID = SceneObject(mob):getObjectID()
    local pid = SceneObject(pPlayer):getObjectID()

    -- Track both ways so we can verify ownership on death
    writeData(pid .. ":" .. PREFIX .. ":mobOID", mobOID)
    writeData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID", pid)

    -- Reward on death if killed by the owner Knight
    createObserver(OBJECTDESTRUCTION, "JediKnightVisibilityEncounter", "onThugDied", mob)

    -- Attack immediately
    CreatureObject(mob):engageCombat(pPlayer)

    -- Auto-despawn timer
    createEvent(self.DESPAWN_MS, "JediKnightVisibilityEncounter", "onDespawnTimer", pPlayer, "")

    CreatureObject(pPlayer):sendSystemMessage("\\#FFCC00A bounty hunter has picked up your trail!")
end

function JediKnightVisibilityEncounter:onDespawnTimer(pPlayer)
    self:despawnForPlayer(pPlayer)
end

function JediKnightVisibilityEncounter:despawnForPlayer(pPlayer)
    if (pPlayer == nil) then return end
    local pid = SceneObject(pPlayer):getObjectID()
    local mobOID = readData(pid .. ":" .. PREFIX .. ":mobOID")
    if (mobOID == nil) then return end

    local pMob = getSceneObject(tonumber(mobOID))
    if (pMob ~= nil) then
        SceneObject(pMob):destroyObjectFromWorld(true)
        SceneObject(pMob):destroyObjectFromDatabase()
    end

    deleteData(pid .. ":" .. PREFIX .. ":mobOID")
    deleteData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID")
end

function JediKnightVisibilityEncounter:onThugDied(pMob, pKiller)
    if (pMob == nil or pKiller == nil) then return 0 end
    if (not SceneObject(pKiller):isPlayerCreature()) then return 0 end

    local mobOID = SceneObject(pMob):getObjectID()
    local ownerPID = readData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID")
    if (ownerPID == nil) then return 0 end

    local killerPID = SceneObject(pKiller):getObjectID()
    if (tonumber(ownerPID) ~= tonumber(killerPID)) then
        -- Not the owner who triggered this encounter; clean ownership and exit
        deleteData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID")
        return 0
    end

    local co = CreatureObject(pKiller)
    if (co ~= nil and co:hasSkill("force_title_jedi_rank_03")) then
        co:awardExperience("force_rank_xp", 1000, true)
        co:sendSystemMessage("\\#00FF00You earned 1,000 Force Rank XP for defeating the attacker.")
    end

    -- Clear tracking for the owner
    deleteData(killerPID .. ":" .. PREFIX .. ":mobOID")
    deleteData("mob:" .. mobOID .. ":" .. PREFIX .. ":ownerPID")
    return 0
end

return JediKnightVisibilityEncounter