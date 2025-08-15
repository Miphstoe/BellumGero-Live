-- BestineElection.lua (persistent version; 3-day election & office phases)

BestineElection = ScreenPlay:new {
    electionEnabled = true,

    -- Durations are in milliseconds (ms), matching existing server event APIs.
    electionDuration    = 3 * 24 * 60 * 60 * 1000, -- Duration of the election (voting) phase
    timeTilNextElection = 3 * 24 * 60 * 60 * 1000, -- Duration of the office phase between elections

    -- Phase constants
    ELECTION_PHASE = 1,
    OFFICE_PHASE   = 2,

    -- Persistence keys / constants
    PHASE_EVENT_NAME = "ElectionPhaseChange",
    NEXT_AT_KEY      = "bestineElection:nextAtSec", -- stores absolute epoch seconds (os.time())

    -- Evidence templates
    seanEvidence = {
        "object/tangible/loot/quest/sean_questp_ctestimony.iff",
        "object/tangible/loot/quest/sean_questp_mdisk.iff",
        "object/tangible/loot/quest/sean_questp_htestimony.iff"
    },
    seanRivalEvidence = {
        "object/tangible/loot/quest/sean_questn_alog.iff",
        "object/tangible/loot/quest/sean_questn_gpapers.iff",
        "object/tangible/loot/quest/sean_questn_tdisk.iff"
    },
    victorEvidence = {
        "object/tangible/loot/quest/victor_questp_testimony.iff",
        "object/tangible/loot/quest/victor_questp_jregistry.iff",
        "object/tangible/loot/quest/victor_questp_receipt.iff"
    },
    victorRivalEvidence = {
        "object/tangible/loot/quest/victor_questn_dseal.iff",
        "object/tangible/loot/quest/victor_questn_hlist.iff",
        "object/tangible/loot/quest/victor_questn_journal.iff"
    },

    -- Candidates
    NONE   = 0,
    SEAN   = 1,
    VICTOR = 2,

    -- Quest keys / steps
    SEAN_MAIN_QUEST                 = 1,
    SEAN_HISTORY_QUEST              = 2,
    SEAN_RIVAL_QUEST                = 3,
    SEAN_HOUSE_EVIDENCE             = 4,
    SEAN_CURATOR_EVIDENCE           = 5,
    SEAN_MARKET_EVIDENCE            = 6,
    SEAN_RIVAL_CAPITOL_EVIDENCE     = 7,
    SEAN_RIVAL_CANTINA_EVIDENCE     = 8,
    SEAN_MAIN_REWARD                = 9,

    SEAN_HISTORY_QUEST_ACCEPTED        = 1,
    SEAN_HISTORY_QUEST_STARTED_SEARCH  = 2,
    SEAN_HISTORY_QUEST_FOUND_DISK      = 3,
    SEAN_HISTORY_QUEST_DISK_SCREENED   = 4,
    SEAN_HISTORY_QUEST_SENT_TO_CONTACT = 5,
    SEAN_HISTORY_QUEST_DISK_DESTROYED  = 6,
    SEAN_HISTORY_QUEST_GAVE_TO_HUTT    = 7,
    SEAN_HISTORY_QUEST_RECEIVED_REWARD = 8,

    SEAN_RIVAL_QUEST_ACCEPTED = 1,
    SEAN_RIVAL_QUEST_COMPLETED = 2,

    VICTOR_MAIN_QUEST                 = 1,
    VICTOR_RIVAL_QUEST                = 2,
    VICTOR_TUSKEN_QUEST               = 3,
    VICTOR_MAIN_REWARD                = 4,
    VICTOR_TUSKEN_REWARD              = 5,
    VICTOR_RIVAL_UNIVERSITY_EVIDENCE  = 6,
    VICTOR_HOSPITAL_EVIDENCE          = 7,
    VICTOR_SLUMS_EVIDENCE             = 8,
    VICTOR_SMOOTH_STONE               = 9,
    VICTOR_CARVED_STONE               = 10,

    VICTOR_STONE_REWARD_RECEIVED = 1,

    VICTOR_TUSKEN_QUEST_ACCEPTED   = 1,
    VICTOR_TUSKEN_QUEST_COMPLETED  = 2,

    VICTOR_RIVAL_QUEST_ACCEPTED    = 1,
    VICTOR_RIVAL_QUEST_COMPLETED   = 2
}

registerScreenPlay("BestineElection", true)

-- ############################################################
-- Core control / persistence
-- ############################################################

function BestineElection:isElectionEnabled()
    return self.electionEnabled
end

-- Persistent init: restore/schedule timer on boot, seed if first time.
function BestineElection:doPhaseInit()
    if not self:isElectionEnabled() then
        return
    end

    -- Bootstrap once (fresh server with no saved election number)
    local electionNum = tonumber(getQuestStatus("bestineElection:electionNumber"))
    if electionNum == nil then
        self:setElectionNumber(1)
        self:setCurrentPhase(self.ELECTION_PHASE) -- start in election (voting) phase
        self:createNewVoterList()
        setQuestStatus(self.NEXT_AT_KEY, os.time() + math.floor(self.electionDuration / 1000))
    end

    local now    = os.time()
    local nextAt = tonumber(getQuestStatus(self.NEXT_AT_KEY))
    local phase  = self:getCurrentPhase()

    -- If NEXT_AT missing/invalid, reconstruct from the current phase.
    if nextAt == nil or nextAt <= 0 then
        if phase == self.ELECTION_PHASE then
            nextAt = now + math.floor(self.electionDuration / 1000)
        else
            nextAt = now + math.floor(self.timeTilNextElection / 1000)
        end
        setQuestStatus(self.NEXT_AT_KEY, nextAt)
    end

    local delayMs = (nextAt - now) * 1000

    -- If overdue (server down longer than remaining), advance immediately.
    if delayMs <= 0 then
        self:doPhaseChange()
        return
    end

    -- (Re)schedule to fire when NEXT_AT is due.
    if not hasServerEvent(self.PHASE_EVENT_NAME) then
        createServerEvent(delayMs, "BestineElection", "doPhaseChange", self.PHASE_EVENT_NAME)
    else
        rescheduleServerEvent(self.PHASE_EVENT_NAME, delayMs)
    end
end

function BestineElection:start()
    if not isZoneEnabled("tatooine") then
        return
    end

    self:doPhaseInit()
    self:spawnElectionMobiles()
    self:initTerminals()
end

-- Phase transition with persistence update.
function BestineElection:doPhaseChange()
    if not self:isElectionEnabled() then
        return
    end

    local now          = os.time()
    local electionNum  = self:getElectionNumber()
    local currentPhase = self:getCurrentPhase()

    if currentPhase == self.ELECTION_PHASE then
        -- End of election -> tally winner -> switch to office phase.
        self:determineWinner()
        self:setCurrentPhase(self.OFFICE_PHASE)
        setQuestStatus(self.NEXT_AT_KEY, now + math.floor(self.timeTilNextElection / 1000))

        local delayMs = self.timeTilNextElection
        if hasServerEvent(self.PHASE_EVENT_NAME) then
            rescheduleServerEvent(self.PHASE_EVENT_NAME, delayMs)
        else
            createServerEvent(delayMs, "BestineElection", "doPhaseChange", self.PHASE_EVENT_NAME)
        end
    else
        -- End of office -> new election.
        self:setElectionNumber(electionNum + 1)
        self:setCurrentPhase(self.ELECTION_PHASE)
        self:createNewVoterList()
        setQuestStatus(self.NEXT_AT_KEY, now + math.floor(self.electionDuration / 1000))

        local delayMs = self.electionDuration
        if hasServerEvent(self.PHASE_EVENT_NAME) then
            rescheduleServerEvent(self.PHASE_EVENT_NAME, delayMs)
        else
            createServerEvent(delayMs, "BestineElection", "doPhaseChange", self.PHASE_EVENT_NAME)
        end
    end
end

-- ############################################################
-- Spawning / terminals
-- ############################################################

function BestineElection:spawnElectionMobiles()
    local mobileTable = electionMobiles

    for i = 1, #mobileTable do
        local mobile = mobileTable[i]
        local pMobile = spawnMobile("tatooine", mobile[1], 0, mobile[2], mobile[3], mobile[4], mobile[5], mobile[6])

        if pMobile ~= nil then
            CreatureObject(pMobile):setPvpStatusBitmask(0)

            if mobile[7] ~= "" then
                self:setMoodString(pMobile, mobile[7])
            end

            -- Spawn trigger area for FaceTo & conversations (only if election is enabled)
            if self:isElectionEnabled() then
                if mobile[8] > 0 then
                    local pActiveArea = spawnActiveArea(
                        "tatooine",
                        "object/active_area.iff",
                        SceneObject(pMobile):getWorldPositionX(),
                        SceneObject(pMobile):getWorldPositionZ(),
                        SceneObject(pMobile):getWorldPositionY(),
                        mobile[8],
                        0
                    )

                    if pActiveArea ~= nil then
                        if mobile[1] == "hutt_informant_quest" then
                            createObserver(ENTEREDAREA, "BestineElection", "enteredInformantArea", pActiveArea)
                        else
                            createObserver(ENTEREDAREA, "BestineElection", "enteredMobileArea", pActiveArea)
                        end
                        local areaID   = SceneObject(pActiveArea):getObjectID()
                        local mobileID = SceneObject(pMobile):getObjectID()
                        writeData(mobileID .. ":activeArea", areaID)
                        writeData(areaID .. ":mobileID", mobileID)
                    end
                end

                if mobile[1] == "tour_aryon" then
                    SceneObject(pMobile):setContainerComponent("TourContainerComponent")
                end

                if mobile[9] ~= "" then
                    CreatureObject(pMobile):setOptionsBitmask(136)
                    AiAgent(pMobile):setConvoTemplate(mobile[9])
                end
            end
        end
    end

    local electionNum    = self:getElectionNumber()
    local electionWinner = self:getElectionWinner(electionNum)
    local curPhase       = self:getCurrentPhase()

    if curPhase == self.ELECTION_PHASE then
        electionWinner = self:getElectionWinner(electionNum - 1)
    end

    self:spawnCandidateMobiles(electionWinner)
end

function BestineElection:spawnCandidateMobiles(candidate)
    local candidateTable

    if candidate == self.SEAN then
        candidateTable = seanMerchants
    else
        candidateTable = victorImperials
    end

    for i = 1, #candidateTable do
        local npcData = candidateTable[i]
        local pMobile = spawnMobile("tatooine", npcData[1], 0, npcData[2], npcData[3], npcData[4], npcData[5], 0)

        if pMobile ~= nil then
            local mobileID = SceneObject(pMobile):getObjectID()
            writeData("bestineElection:candidateMobile:" .. i, mobileID)
        end
    end

    if candidate == self.SEAN then
        local pSnd = spawnSceneObject("tatooine", "object/soundobject/soundobject_marketplace_large.iff", -1124, 12, -3695, 0, 0)
        if pSnd ~= nil then
            local soundID = SceneObject(pSnd):getObjectID()
            writeData("bestineElection:marketSound", soundID)
        end
    end
end

function BestineElection:despawnCandidateMobiles()
    for i = 1, #seanMerchants do
        local objectID = readData("bestineElection:candidateMobile:" .. i)
        local pMobile = getSceneObject(objectID)
        if pMobile ~= nil then
            SceneObject(pMobile):destroyObjectFromWorld()
        end
        deleteData("bestineElection:candidateMobile:" .. i)
    end

    for i = 1, #victorImperials do
        local objectID = readData("bestineElection:candidateMobile:" .. i)
        local pMobile = getSceneObject(objectID)
        if pMobile ~= nil then
            SceneObject(pMobile):destroyObjectFromWorld()
        end
        deleteData("bestineElection:candidateMobile:" .. i)
    end

    local marketSoundID = readData("bestineElection:marketSound")
    local pSnd = getSceneObject(marketSoundID)
    if pSnd ~= nil then
        SceneObject(pSnd):destroyObjectFromWorld()
    end
    deleteData("bestineElection:marketSound")
end

function BestineElection:initTerminals()
    if not self:isElectionEnabled() then
        return
    end

    local pTerminal = getSceneObject(5565564) -- victor office terminal -> victor_questp_jregistry
    if pTerminal ~= nil then
        SceneObject(pTerminal):setObjectMenuComponent("BestineEvidenceMenuComponent")
        writeStringData(SceneObject(pTerminal):getObjectID() .. ":name", "victor_questp_jregistry")
    end

    pTerminal = getSceneObject(4475517) -- victor desk -> victor_questn_journal
    if pTerminal ~= nil then
        SceneObject(pTerminal):setObjectMenuComponent("BestineEvidenceMenuComponent")
        writeStringData(SceneObject(pTerminal):getObjectID() .. ":name", "victor_questn_journal")
    end

    pTerminal = getSceneObject(5565563) -- sean office terminal -> sean_questn_tdisk
    if pTerminal ~= nil then
        SceneObject(pTerminal):setObjectMenuComponent("BestineEvidenceMenuComponent")
        writeStringData(SceneObject(pTerminal):getObjectID() .. ":name", "sean_questn_tdisk")
    end

    pTerminal = getSceneObject(5565562) -- sean desk -> sean_questn_alog
    if pTerminal ~= nil then
        SceneObject(pTerminal):setObjectMenuComponent("BestineEvidenceMenuComponent")
        writeStringData(SceneObject(pTerminal):getObjectID() .. ":name", "sean_questn_alog")
    end

    pTerminal = getSceneObject(3195507)
    if pTerminal ~= nil then
        local pActiveArea = spawnActiveArea(
            "tatooine",
            "object/active_area.iff",
            SceneObject(pTerminal):getWorldPositionX(),
            SceneObject(pTerminal):getWorldPositionZ(),
            SceneObject(pTerminal):getWorldPositionY(),
            2,
            0
        )
        if pActiveArea ~= nil then
            createObserver(ENTEREDAREA, "BestineElection", "enteredHistoryTerminalArea", pActiveArea)
        end
    end
end

-- ############################################################
-- Area observers / interactions
-- ############################################################

function BestineElection:enteredHistoryTerminalArea(pActiveArea, pPlayer)
    if pPlayer == nil or pActiveArea == nil or not SceneObject(pPlayer):isPlayerCreature() then
        return 0
    end

    if self:getQuestStep(pPlayer, self.SEAN, self.SEAN_HISTORY_QUEST) == self.SEAN_HISTORY_QUEST_FOUND_DISK then
        CreatureObject(pPlayer):sendSystemMessage("@city/bestine/terminal_items:history_disk_found_already")
        return 0
    end

    if self:getQuestStep(pPlayer, self.SEAN, self.SEAN_HISTORY_QUEST) == self.SEAN_HISTORY_QUEST_STARTED_SEARCH then
        local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")
        if pInventory == nil or SceneObject(pInventory):isContainerFullRecursive() then
            CreatureObject(pPlayer):sendSystemMessage("@city/bestine/terminal_items:inv_full")
            return 0
        end

        local pDisk = giveItem(pInventory, "object/tangible/loot/quest/sean_history_disk.iff", -1)
        if pDisk == nil then
            CreatureObject(pPlayer):sendSystemMessage("Error: Unable to generate item:sean_history_disk.iff")
            return 0
        end

        CreatureObject(pPlayer):sendSystemMessage("@city/bestine/terminal_items:history_disk_found")
        self:setQuestStep(pPlayer, self.SEAN, self.SEAN_HISTORY_QUEST, self.SEAN_HISTORY_QUEST_FOUND_DISK)
    end

    return 0
end

function BestineElection:enteredMobileArea(pActiveArea, pPlayer)
    if pActiveArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature() then
        return 0
    end

    local areaID = SceneObject(pActiveArea):getObjectID()
    local mobileID = readData(areaID .. ":mobileID")
    local pMobile = getSceneObject(mobileID)

    if pMobile == nil then
        return 1
    end

    SceneObject(pMobile):faceObject(pPlayer, true)
    return 0
end

-- BUGFIX: use pMovingObject (the player in this callback), not pPlayer.
function BestineElection:enteredInformantArea(pActiveArea, pMovingObject)
    if pMovingObject == nil or pActiveArea == nil or not SceneObject(pMovingObject):isPlayerCreature() then
        return 0
    end

    local areaID  = SceneObject(pActiveArea):getObjectID()
    local mobileID = readData(areaID .. ":mobileID")
    local pMobile = getSceneObject(mobileID)
    if pMobile == nil then
        return 1
    end

    local electionNum    = self:getElectionNumber()
    local electionWinner = self:getElectionWinner(electionNum)
    local curPhase       = self:getCurrentPhase()
    if curPhase == self.ELECTION_PHASE then
        electionWinner = self:getElectionWinner(electionNum - 1)
    end

    if electionWinner ~= self.SEAN or
       self:getQuestStep(pMovingObject, self.SEAN, self.SEAN_HISTORY_QUEST) ~= self.SEAN_HISTORY_QUEST_SENT_TO_CONTACT then
        return 0
    end

    local pInventory = CreatureObject(pMovingObject):getSlottedObject("inventory")
    if pInventory ~= nil and getContainerObjectByTemplate(pInventory, "object/tangible/loot/quest/sean_history_disk.iff", true) ~= nil then
        SceneObject(pMobile):faceObject(pMovingObject, true)
        spatialChat(pMobile, "@bestine:come_here")
    end

    return 0
end

-- ############################################################
-- Election logic
-- ############################################################

function BestineElection:determineWinner()
    local electionNum = self:getElectionNumber()
    local pMap = self:getVoterList(electionNum)
    if pMap == nil then
        printLuaError("Error in BestineElection:determineWinner, attempting to get non existent vote map.")
        return false
    end

    local voterMap = LuaQuestVectorMap(pMap)
    local victorVotes, seanVotes = 0, 0
    local totalPlayers = voterMap:getMapSize()

    if totalPlayers > 0 then
        for i = 1, totalPlayers do
            local playerID = voterMap:getMapKeyAtIndex(i - 1)
            local playerVote = tonumber(voterMap:getMapRow(playerID))
            if playerVote == self.SEAN then
                seanVotes = seanVotes + 1
            elseif playerVote == self.VICTOR then
                victorVotes = victorVotes + 1
            end
        end
    end

    local electionWinner = self.NONE
    if seanVotes > victorVotes then
        electionWinner = self.SEAN
    elseif seanVotes == victorVotes then
        local chance = getRandomNumber(0, 200) -- Tie-break
        if chance <= 100 then
            electionWinner = self.SEAN
        else
            electionWinner = self.VICTOR
        end
    else
        electionWinner = self.VICTOR
    end

    self:despawnCandidateMobiles()
    self:spawnCandidateMobiles(electionWinner)
    self:setElectionWinner(electionNum, electionWinner)
end

-- ############################################################
-- Inventory / voting helpers
-- ############################################################

function BestineElection:hasCandidateEvidence(pPlayer, candidate, rivalEvidence)
    if pPlayer == nil then
        return false
    end

    local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")
    if pInventory == nil then
        return false
    end

    local templates = {}
    if candidate == self.SEAN then
        templates = rivalEvidence and self.victorRivalEvidence or self.seanEvidence
    elseif candidate == self.VICTOR then
        templates = rivalEvidence and self.seanRivalEvidence or self.victorEvidence
    else
        return false
    end

    for i = 1, #templates do
        local pInvItem = getContainerObjectByTemplate(pInventory, templates[i], true)
        if pInvItem ~= nil then
            return true
        end
    end
    return false
end

function BestineElection:canVoteForCandidate(pPlayer, candidate)
    return self:hasJoinedCampaign(pPlayer, candidate) and self:hasCandidateEvidence(pPlayer, candidate)
end

function BestineElection:removeCandidateEvidence(pPlayer, candidate)
    if pPlayer == nil then
        return false
    end

    local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")
    if pInventory == nil then
        return false
    end

    local templates = {}
    if candidate == self.SEAN then
        templates = self.seanEvidence
    elseif candidate == self.VICTOR then
        templates = self.victorEvidence
    else
        return false
    end

    local foundEvidence = false
    for i = 1, #templates do
        local pInvItem = getContainerObjectByTemplate(pInventory, templates[i], true)
        if pInvItem ~= nil then
            SceneObject(pInvItem):destroyObjectFromWorld()
            SceneObject(pInvItem):destroyObjectFromDatabase()
            foundEvidence = true
        end
    end

    return foundEvidence
end

function BestineElection:hasFullInventory(pPlayer)
    if pPlayer == nil then
        return true
    end
    local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
    return pInventory == nil or SceneObject(pInventory):isContainerFullRecursive()
end

function BestineElection:hasItemInInventory(pPlayer, template)
    if pPlayer == nil then
        return false
    end
    local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
    if pInventory == nil then
        return false
    end
    return getContainerObjectByTemplate(pInventory, template, true) ~= nil
end

function BestineElection:giveCampaignReward(pPlayer, candidate)
    if self:getPlayerVote(pPlayer) ~= candidate then
        return
    end

    local rewardChance  = getRandomNumber(1, 1000)
    local rewardTemplate

    -- No evidence of these rewards being given during 14.1.
    --[[ if rewardChance <= 50 then
        if candidate == self.SEAN then
            rewardTemplate = "object/tangible/painting/bestine_quest_painting.iff"
        else
            rewardTemplate = "object/weapon/melee/sword/bestine_quest_sword.iff"
        end
    else ]]
    if rewardChance <= 300 then
        if candidate == self.SEAN then
            rewardTemplate = "object/tangible/furniture/modern/bestine_quest_rug.iff"
        else
            rewardTemplate = "object/tangible/furniture/all/bestine_quest_imp_banner.iff"
        end
    else
        if candidate == self.SEAN then
            rewardTemplate = "object/tangible/furniture/all/bestine_quest_statue.iff"
        else
            rewardTemplate = "object/tangible/wearables/necklace/bestine_quest_badge.iff"
        end
    end

    local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
    if pInventory == nil then
        return
    end

    local pReward = giveItem(pInventory, rewardTemplate, -1)
    if pReward == nil then
        printLuaError("Error creating campaign reward for player " .. CreatureObject(pPlayer):getFirstName() .. " for candidate " .. candidate)
        return
    end

    self:setReceivedElectionReward(pPlayer)
end

-- ############################################################
-- Combat / observers
-- ############################################################

function BestineElection:notifyKilledCreature(pPlayer, pVictim)
    if pVictim == nil then
        return 0
    end
    if pPlayer == nil then
        return 1
    end
    if not self:isElectionEnabled() then
        return 1
    end
    if self:getQuestStep(pPlayer, self.VICTOR, self.VICTOR_TUSKEN_QUEST) ~= self.VICTOR_TUSKEN_QUEST_ACCEPTED then
        return 1
    end

    local pVictimInv = CreatureObject(pVictim):getSlottedObject("inventory")
    if pVictimInv == nil then
        return 0
    end

    local victimName = SceneObject(pVictim):getObjectName()
    local playerID = SceneObject(pPlayer):getObjectID()

    if victimName == "tusken_executioner" and not self:hasItemInInventory(pPlayer, "object/tangible/loot/quest/tusken_head.iff") then
        SceneObject(pVictimInv):setContainerOwnerID(playerID)
        createLoot(pVictimInv, "bestine_election_tusken_head", 0, true)
    end

    if victimName == "tusken_executioner" or victimName == "tusken_observer" or victimName == "tusken_witch_doctor" then
        SceneObject(pVictimInv):setContainerOwnerID(playerID)
        local chance = getRandomNumber(10000)
        if chance < 100 then
            createLoot(pVictimInv, "bestine_election_carved_stone", 0, true)
        elseif chance < 400 then
            createLoot(pVictimInv, "bestine_election_smooth_stone", 0, true)
        elseif chance < 800 then
            createLoot(pVictimInv, "bestine_election_baton", 0, true)
        end
    end

    return 0
end

function BestineElection:playerLoggedIn(pPlayer)
    if self:getQuestStep(pPlayer, self.VICTOR, self.VICTOR_TUSKEN_QUEST) == self.VICTOR_TUSKEN_QUEST_ACCEPTED then
        dropObserver(KILLEDCREATURE, "BestineElection", "notifyKilledCreature", pPlayer)
        createObserver(KILLEDCREATURE, "BestineElection", "notifyKilledCreature", pPlayer)
    end
end

-- ############################################################
-- Phase / election state getters & setters (persistent)
-- ############################################################

function BestineElection:getCurrentPhase()
    local curPhase = tonumber(getQuestStatus("bestineElection:currentPhase"))
    if curPhase == nil or curPhase == 0 then
        self:setCurrentPhase(self.ELECTION_PHASE)
        return self.ELECTION_PHASE
    end
    return curPhase
end

function BestineElection:setCurrentPhase(newPhase)
    setQuestStatus("bestineElection:currentPhase", newPhase)
end

function BestineElection:getElectionNumber()
    local electionNum = tonumber(getQuestStatus("bestineElection:electionNumber"))
    if electionNum == nil then
        self:setElectionNumber(1)
        return 1
    end
    return electionNum
end

function BestineElection:setElectionNumber(newNum)
    setQuestStatus("bestineElection:electionNumber", newNum)
end

function BestineElection:getElectionWinner(electionNumber)
    if electionNumber <= 0 then
        return self.NONE
    end
    local winner = tonumber(getQuestStatus("bestineElection:electionWinner:" .. electionNumber))
    if winner == nil then
        self:setElectionWinner(electionNumber, self.NONE)
        return self.NONE
    end
    return winner
end

function BestineElection:setElectionWinner(electionNumber, newWinner)
    setQuestStatus("bestineElection:electionWinner:" .. electionNumber, newWinner)
end

-- Persisted time remaining (seconds). Falls back to server event if needed.
function BestineElection:getPhaseTimeLeft()
    local nextAt = tonumber(getQuestStatus(self.NEXT_AT_KEY))
    if nextAt ~= nil then
        local remain = nextAt - os.time()
        if remain > 0 then
            return remain
        end
    end

    local eventID = getServerEventID(self.PHASE_EVENT_NAME)
    if eventID == nil then
        return 0
    end

    local ms = getServerEventTimeLeft(eventID)
    return (ms and math.floor(ms / 1000)) or 0
end

-- ############################################################
-- Voter map storage
-- ############################################################

function BestineElection:createNewVoterList()
    local electionNum = self:getElectionNumber()
    return createQuestVectorMap("BestineElectionVoterList" .. electionNum)
end

function BestineElection:getVoterList(electionNum)
    return getQuestVectorMap("BestineElectionVoterList" .. electionNum)
end

function BestineElection:addPlayerVote(pPlayer, vote)
    local electionNum = self:getElectionNumber()
    local pMap = self:getVoterList(electionNum)
    if pMap == nil then
        pMap = self:createNewVoterList()
    end

    local voterMap = LuaQuestVectorMap(pMap)
    local playerID = tostring(SceneObject(pPlayer):getObjectID())

    if not voterMap:hasMapRow(playerID) then
        voterMap:addMapRow(playerID, tostring(vote))
    else
        printLuaError("Error in BestineElection:addPlayerVote, attempting to add existing player " ..
            SceneObject(pPlayer):getCustomObjectName() .. " to voter map.")
    end
end

function BestineElection:hasPlayerVoted(pPlayer)
    local electionNum = self:getElectionNumber()
    local pMap = self:getVoterList(electionNum)
    if pMap == nil then
        printLuaError("Error in BestineElection:hasPlayerVoted, voter map does not exist for player " ..
            SceneObject(pPlayer):getCustomObjectName())
        return false
    end

    local voterMap = LuaQuestVectorMap(pMap)
    local playerID = tostring(SceneObject(pPlayer):getObjectID())
    return voterMap:hasMapRow(playerID)
end

function BestineElection:getPlayerVote(pPlayer, electionNumOverride)
    local electionNum = self:getElectionNumber()
    if electionNumOverride ~= nil and electionNumOverride ~= "" then
        electionNum = electionNumOverride
    end

    local pMap = self:getVoterList(electionNum)
    if pMap == nil then
        printLuaError("Error in BestineElection:getPlayerVote, voter map does not exist for player " ..
            SceneObject(pPlayer):getCustomObjectName())
        return self.NONE
    end

    local voterMap = LuaQuestVectorMap(pMap)
    local playerID = tostring(SceneObject(pPlayer):getObjectID())

    if not voterMap:hasMapRow(playerID) then
        return self.NONE
    end

    local playerVote = voterMap:getMapRow(playerID)
    return tonumber(playerVote)
end

-- ############################################################
-- Campaign joins / per-player screenplay data
-- ############################################################

function BestineElection:joinCampaign(pPlayer, candidate)
    if pPlayer == nil then
        return
    end

    local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
    if pInventory == nil then
        return
    end

    local electionNum = self:getElectionNumber()

    local keyString
    local campObj
    if candidate == self.SEAN then
        keyString = "joinedSeanCampaign"
        campObj = "object/tangible/loot/quest/sean_campaign_disk.iff"
    elseif candidate == self.VICTOR then
        keyString = "joinedVictorCampaign"
        campObj = "object/tangible/loot/quest/victor_campaign_disk.iff"
    else
        return
    end

    local pCampObj = giveItem(pInventory, campObj, -1)
    if pCampObj == nil then
        printLuaError("Error creating campaign disk for player " .. CreatureObject(pPlayer):getFirstName() ..
            " joining campaign " .. candidate)
        return
    end

    if candidate == self.SEAN and self:hasJoinedCampaign(pPlayer, self.VICTOR) then
        deleteScreenPlayData(pPlayer, "BestineElection", "joinedVictorCampaign")
    elseif candidate == self.VICTOR and self:hasJoinedCampaign(pPlayer, self.SEAN) then
        deleteScreenPlayData(pPlayer, "BestineElection", "joinedSeanCampaign")
    end

    writeScreenPlayData(pPlayer, "BestineElection", keyString, electionNum)
end

function BestineElection:hasJoinedCampaign(pPlayer, candidate)
    local electionNum = self:getElectionNumber()
    local keyString
    if candidate == self.SEAN then
        keyString = "joinedSeanCampaign"
    elseif candidate == self.VICTOR then
        keyString = "joinedVictorCampaign"
    else
        return
    end
    local lastVoteNum = tonumber(readScreenPlayData(pPlayer, "BestineElection", keyString))
    return lastVoteNum ~= nil and lastVoteNum == electionNum
end

function BestineElection:setReceivedElectionReward(pPlayer)
    local electionNum = self:getElectionNumber()
    writeScreenPlayData(pPlayer, "BestineElection", "ReceivedReward", electionNum)
end

function BestineElection:hasReceivedElectionReward(pPlayer)
    local curPhase = self:getCurrentPhase()
    if curPhase ~= self.OFFICE_PHASE then
        return true
    end
    local electionNum = self:getElectionNumber()
    return tonumber(readScreenPlayData(pPlayer, "BestineElection", "ReceivedReward")) == electionNum
end

function BestineElection:setInvFull(pPlayer, candidate, quest)
    if pPlayer == nil then
        return
    end

    local electionNum = self:getElectionNumber()
    local keyString
    if candidate == self.SEAN then
        keyString = "invFullSean"
    elseif candidate == self.VICTOR then
        keyString = "invFullVictor"
    else
        return
    end

    writeScreenPlayData(pPlayer, "BestineElection", keyString .. tostring(quest), tostring(electionNum))
end

function BestineElection:hadInvFull(pPlayer, candidate, quest)
    if pPlayer == nil then
        return false
    end

    local electionNum = self:getElectionNumber()
    local keyString
    if candidate == self.SEAN then
        keyString = "invFullSean"
    elseif candidate == self.VICTOR then
        keyString = "invFullVictor"
    else
        return
    end

    if readScreenPlayData(pPlayer, "BestineElection", keyString .. tostring(quest)) ~= tostring(electionNum) then
        self:clearInvFull(pPlayer, candidate, quest)
        return false
    else
        return true
    end
end

function BestineElection:clearInvFull(pPlayer, candidate, quest)
    if pPlayer == nil then
        return
    end

    local keyString
    if candidate == self.SEAN then
        keyString = "invFullSean"
    elseif candidate == self.VICTOR then
        keyString = "invFullVictor"
    else
        return
    end

    deleteScreenPlayData(pPlayer, "BestineElection", keyString .. tostring(quest))
end

function BestineElection:setQuestStep(pPlayer, candidate, quest, questStep)
    if pPlayer == nil then
        return
    end

    local keyString
    if candidate == self.SEAN then
        keyString = "seanQuest"
    elseif candidate == self.VICTOR then
        keyString = "victorQuest"
    else
        return
    end

    keyString = keyString .. ":" .. tostring(quest)
    local electionNum = self:getElectionNumber()

    if readScreenPlayData(pPlayer, "BestineElection", keyString) ~= tostring(electionNum) then
        writeScreenPlayData(pPlayer, "BestineElection", keyString, tostring(electionNum))
    end

    writeScreenPlayData(pPlayer, "BestineElection", keyString .. "Step", tostring(questStep))
end

function BestineElection:getQuestStep(pPlayer, candidate, quest)
    if pPlayer == nil then
        return 0
    end

    local keyString
    if candidate == self.SEAN then
        keyString = "seanQuest"
    elseif candidate == self.VICTOR then
        keyString = "victorQuest"
    else
        return
    end

    local electionNum = self:getElectionNumber()
    keyString = keyString .. ":" .. tostring(quest)

    if readScreenPlayData(pPlayer, "BestineElection", keyString) ~= tostring(electionNum) then
        return 0
    end

    local questStep = readScreenPlayData(pPlayer, "BestineElection", keyString .. "Step")
    if questStep == nil or questStep == "" then
        return 0
    end

    return tonumber(questStep)
end

function BestineElection:setSearchedObject(pPlayer, objectName)
    local electionNum = self:getElectionNumber()
    writeScreenPlayData(pPlayer, "BestineElection", "searched_" .. objectName, electionNum)
end

function BestineElection:hasSearchedObject(pPlayer, objectName)
    local electionNum = self:getElectionNumber()
    return tonumber(readScreenPlayData(pPlayer, "BestineElection", "searched_" .. objectName)) == electionNum
end

-- ############################################################
-- Container component (tour NPC)
-- ############################################################

TourContainerComponent = {}

function TourContainerComponent:transferObject(pContainer, pObj, slot)
    if pContainer == nil then
        return 0
    end

    spatialChat(pContainer, "@bestine:give_governor_item")
    return 0
end

function TourContainerComponent:canAddObject(pContainer, pObj, slot)
    return false
end
