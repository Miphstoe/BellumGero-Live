local ObjectManager = require("managers.object.object_manager")
local Logger = require("utils.logger")
local SpawnMobiles = require("utils.spawn_mobiles")

-- Uses the built-in Encounter task framework (see: scripts/screenplays/quest_tasks/encounter.lua)
JediKnightThugEncounter = Encounter:new {
    taskName = "JediKnightThugEncounter",
    encounterDespawnTime = 5 * 60 * 1000, -- 5 minutes
    -- One attacker that spawns a short distance from the player
    spawnObjectList = {
        { template = "bounty_hunter_thug", minimumDistance = 24, maximumDistance = 60, referencePoint = 0, followPlayer = false, setNotAttackable = false, runOnDespawn = false }
    },
    onEncounterSpawned = nil,
    onEncounterDespawned = nil,
    isEncounterFinished = nil,
}

-- When the encounter is created, attach death observers and have the thug attack the player
function JediKnightThugEncounter:taskStart(pPlayer, ...)
    if (pPlayer == nil) then
        return false
    end

    -- Only start for actual Jedi Knights
    if not CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_03") then
        return false
    end

    local result = self:createEncounter(pPlayer)
    if (result) then
        -- Make spawned thug attack the player and attach death observer
        local spawned = SpawnMobiles.getSpawnedMobiles(pPlayer, self.taskName)
        if (spawned ~= nil) then
            for i = 1, #spawned, 1 do
                if (SpawnMobiles.isValidMobile(spawned[i])) then
                    -- tie a death observer to the thug to award XP if killed by the participant
                    createObserver(OBJECTDESTRUCTION, "JediKnightThugEncounter", "onThugDied", spawned[i])

                    -- Engage the player immediately
                    CreatureObject(spawned[i]):engageCombat(pPlayer)
                end
            end
        end

        -- Auto-despawn / clean up after timeout
        createEvent(self.encounterDespawnTime, self.taskName, "handleDespawnEvent", pPlayer, "")
    end

    return result
end

-- Award Force Rank XP only if the killer is the same Jedi Knight who got this encounter
function JediKnightThugEncounter:onThugDied(pMob, pKiller)
    if (pMob == nil or pKiller == nil) then
        return 0
    end

    if not SceneObject(pKiller):isPlayerCreature() then
        return 0
    end

    -- Ensure the killed mob belongs to the spawn created for this player
    if not SpawnMobiles.isFromSpawn(pKiller, self.taskName, pMob) then
        return 0
    end

    local co = CreatureObject(pKiller)
    if (co ~= nil and co:hasSkill("force_title_jedi_rank_03")) then
        co:awardExperience("force_rank_xp", 1000, true)
        CreatureObject(pKiller):sendSystemMessage("\\#00FF00You earned 1,000 Force Rank XP for defeating the attacker.")
    end

    -- Clean up remaining encounter mobiles for this player, if any
    SpawnMobiles.despawnMobiles(pKiller, self.taskName, false)

    return 0
end

-- ---------------------------------------------------------------------------
-- Visibility-driven watcher that triggers the encounter at most once per hour
-- when a Jedi Knight's visibility increases.
-- ---------------------------------------------------------------------------
JediKnightVisibilityEncounter = ScreenPlay:new {
    COOLDOWN_SECONDS  = 60 * 60,      -- (now handled in C++; kept only if you want double safety)
    STORAGE_PREFIX    = "JediKnightVis",
    LOGIN_GRACE_SECONDS = 120,        -- still used (no immediate spawn after login)
}

registerScreenPlay("JediKnightVisibilityEncounter", true)

-- Hook from playerTriggers.lua
function JediKnightVisibilityEncounter:playerLoggedIn(pPlayer)
    if (pPlayer == nil) then
        return
    end

    local playerID = SceneObject(pPlayer):getObjectID()
    local pGhost = CreatureObject(pPlayer):getPlayerObject()
    if (pGhost ~= nil) then
        writeData(playerID .. ":" .. self.STORAGE_PREFIX .. ":lastVis", math.floor(PlayerObject(pGhost):getVisibility()))
    end

    -- Seed a *login grace* window: the Lua hook will check this and ignore early triggers
    local now = os.time()
    writeData(playerID .. ":" .. self.STORAGE_PREFIX .. ":cooldown", now + self.LOGIN_GRACE_SECONDS)
end

function JediKnightVisibilityEncounter:playerLoggedOut(pPlayer)
    if (pPlayer == nil) then
        return
    end

    -- Optional: clean up any lingering encounter spawns for safety
    SpawnMobiles.despawnMobiles(pPlayer, JediKnightThugEncounter.taskName, false)
end

-- Called from C++ VisibilityManager::increaseVisibility when 1h gate passes
function JediKnightVisibilityEncounter:onVisibilityIncreased(pPlayer)
    if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
        return
    end

    local co = CreatureObject(pPlayer)
    if (co == nil or not co:hasSkill("force_title_jedi_rank_03")) then
        return -- only for Jedi Knights
    end

    -- Respect login grace (and any existing screenplay-level cooldown if you keep using it)
    local playerID = SceneObject(pPlayer):getObjectID()
    local now = os.time()
    local nextAllowed = readData(playerID .. ":" .. self.STORAGE_PREFIX .. ":cooldown")
    if (nextAllowed ~= nil and now < tonumber(nextAllowed)) then
        return
    end

    -- Start the encounter and message the player
    local started = JediKnightThugEncounter:start(pPlayer)
    if (started) then
        co:sendSystemMessage("\\#FFCC00A bounty hunter has picked up your trail!")
        -- Do NOT set a 1h cooldown here; C++ has already set it.
        -- If you want a post-spawn Lua guard (e.g., suppress duplicates for 10s), you could writeData(...) briefly.
    end
end

function JediKnightVisibilityEncounter:start()
    -- No world spawns on boot; the logic runs from playerTriggers on login.
    -- Defining start() prevents DirectorManager from erroring on load.
    return true
end

return JediKnightVisibilityEncounter