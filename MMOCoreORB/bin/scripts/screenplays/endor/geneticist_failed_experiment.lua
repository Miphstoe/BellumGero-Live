GeneticistsFailedExperiment = ScreenPlay:new {
	numberOfActs = 1,
	screenplayName = "GeneticistsFailedExperiment",

	QUEST_NOT_STARTED = 0,
	STAGE_1_COLLECT_DNA = 1,
	STAGE_1_COMPLETE = 2,
	STAGE_2_ANALYZE_DNA = 3,
	STAGE_2_COMPLETE = 4,
	STAGE_3_CRAFT_COMPONENT = 5,
	STAGE_3_COMPLETE = 6,
	STAGE_4_HUNT_EXPERIMENT = 7,
	QUEST_COMPLETE = 8,

	planet = "endor",
	npcTemplate = "dr_kaelen_varr",
	npcX = 3259,
	npcZ = 24,
	npcY = -3450,
	npcHeading = 90,
	terminalTemplate = "object/tangible/terminal/geneticists_failed_experiment_terminal.iff",
	terminalX = 3263,
	terminalZ = 24,
	terminalY = -3450,
	terminalHeading = 0,
	stage1Goal = 5,
	stage3TemplatePath = "object/tangible/component/dna/dna_template_",
	stageRewards = {
		[2] = 10000,
		[4] = 12500,
		[6] = 15000,
		[8] = 20000
	},
	allowedStage1SocialGroups = {
		["bordok"] = true,
		["gurreck"] = true,
		["lantern"] = true,
		["squall"] = true,
		["arachne"] = true
	},
	allowedStage1Names = {
		"bordok",
		"gurreck",
		"lantern_bird",
		"squall",
		"venom_filled_arachne"
	},
	stage4Spawn = {
		x = 3338,
		y = -3621
	},
	cooldownSeconds = 3600,
}

registerScreenPlay("GeneticistsFailedExperiment", true)

GeneticistsFailedExperimentTerminalMenuComponent = {}

function GeneticistsFailedExperimentTerminalMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	if (pSceneObject == nil or pMenuResponse == nil or pPlayer == nil) then
		return
	end

	if (GeneticistsFailedExperiment:getState(pPlayer) ~= GeneticistsFailedExperiment.STAGE_2_ANALYZE_DNA) then
		return
	end

	LuaObjectMenuResponse(pMenuResponse):addRadialMenuItem(20, 3, "Run Genetic Stability Scan")
end

function GeneticistsFailedExperimentTerminalMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (selectedID == 20 and pSceneObject ~= nil and pPlayer ~= nil) then
		GeneticistsFailedExperiment:useResearchTerminal(pPlayer)
	end

	return 0
end

function GeneticistsFailedExperiment:start()
	if (isZoneEnabled(self.planet)) then
		self:spawnStaticWorld()
	end
end

function GeneticistsFailedExperiment:spawnStaticWorld()
	local pNpc = spawnMobile(self.planet, self.npcTemplate, 0, self.npcX, self.npcZ, self.npcY, self.npcHeading, 0)
	if (pNpc ~= nil) then
		CreatureObject(pNpc):setMoodString("npc_imperial")
	end

	local pTerminal = spawnSceneObject(self.planet, self.terminalTemplate, self.terminalX, self.terminalZ, self.terminalY, 0, math.rad(self.terminalHeading))
	if (pTerminal ~= nil) then
		SceneObject(pTerminal):setCustomObjectName("Research Terminal")
	end
end

function GeneticistsFailedExperiment:getState(pPlayer)
	return tonumber(readScreenPlayData(pPlayer, self.screenplayName, "state")) or self.QUEST_NOT_STARTED
end

function GeneticistsFailedExperiment:setState(pPlayer, state)
	writeScreenPlayData(pPlayer, self.screenplayName, "state", state)
	self:refreshObservers(pPlayer)
end

function GeneticistsFailedExperiment:getDataNumber(pPlayer, key)
	return tonumber(readScreenPlayData(pPlayer, self.screenplayName, key)) or 0
end

function GeneticistsFailedExperiment:setDataNumber(pPlayer, key, value)
	writeScreenPlayData(pPlayer, self.screenplayName, key, value)
end

function GeneticistsFailedExperiment:isBioEngineer(pPlayer)
	return CreatureObject(pPlayer):hasSkill("outdoors_bio_engineer_novice")
end

function GeneticistsFailedExperiment:clearWaypoint(pPlayer)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil) then
		return
	end

	local waypointId = self:getDataNumber(pPlayer, "waypointId")
	if (waypointId ~= 0) then
		PlayerObject(pGhost):removeWaypoint(waypointId, true)
		self:setDataNumber(pPlayer, "waypointId", 0)
	end
end

function GeneticistsFailedExperiment:updateWaypoint(pPlayer)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil) then
		return
	end

	self:clearWaypoint(pPlayer)

	local state = self:getState(pPlayer)
	if (state == self.QUEST_NOT_STARTED or state == self.QUEST_COMPLETE) then
		return
	end

	local label, x, y
	if (state == self.STAGE_2_ANALYZE_DNA or state == self.STAGE_2_COMPLETE) then
		label, x, y = "Dr. Varr's Research Terminal", self.terminalX, self.terminalY
	elseif (state == self.STAGE_4_HUNT_EXPERIMENT and self:getDataNumber(pPlayer, "mutationKilled") == 0) then
		label, x, y = "Mutated Gurreck Alpha", self.stage4Spawn.x, self.stage4Spawn.y
	else
		label, x, y = "Dr. Kaelen Varr", self.npcX, self.npcY
	end

	local waypointId = PlayerObject(pGhost):addWaypoint(self.planet, label, "", x, 0, y, WAYPOINT_YELLOW, true, true, 0, 0)
	self:setDataNumber(pPlayer, "waypointId", waypointId)
end

function GeneticistsFailedExperiment:sendObjective(pPlayer)
	local state = self:getState(pPlayer)

	if (state == self.STAGE_1_COLLECT_DNA) then
		CreatureObject(pPlayer):sendSystemMessage("Objective updated: Collect DNA samples from Endor wildlife (" .. self:getDataNumber(pPlayer, "dnaCount") .. "/" .. self.stage1Goal .. ").")
	elseif (state == self.STAGE_1_COMPLETE) then
		CreatureObject(pPlayer):sendSystemMessage("Objective updated: Return to Dr. Varr with the harvested DNA samples.")
	elseif (state == self.STAGE_2_ANALYZE_DNA) then
		CreatureObject(pPlayer):sendSystemMessage("Objective updated: Analyze the samples at Dr. Varr's research terminal.")
	elseif (state == self.STAGE_2_COMPLETE) then
		CreatureObject(pPlayer):sendSystemMessage("Objective updated: Return to Dr. Varr with the scan results.")
	elseif (state == self.STAGE_3_CRAFT_COMPONENT) then
		CreatureObject(pPlayer):sendSystemMessage("Objective updated: Craft an experimental DNA component.")
	elseif (state == self.STAGE_3_COMPLETE) then
		CreatureObject(pPlayer):sendSystemMessage("Objective updated: Return to Dr. Varr with the finished component.")
	elseif (state == self.STAGE_4_HUNT_EXPERIMENT and self:getDataNumber(pPlayer, "mutationKilled") == 0) then
		CreatureObject(pPlayer):sendSystemMessage("Objective updated: Hunt down the escaped mutation.")
	elseif (state == self.STAGE_4_HUNT_EXPERIMENT) then
		CreatureObject(pPlayer):sendSystemMessage("Objective updated: Return to Dr. Varr. The escaped mutation has been neutralized.")
	end

	self:updateWaypoint(pPlayer)
end

function GeneticistsFailedExperiment:refreshObservers(pPlayer)
	dropObserver(LOGGEDIN, self.screenplayName, "onLoggedIn", pPlayer)
	dropObserver(DNASAMPLED, self.screenplayName, "notifyDnaSampled", pPlayer)
	dropObserver(PROTOTYPECREATED, self.screenplayName, "notifyPrototypeCreated", pPlayer)
	dropObserver(KILLEDCREATURE, self.screenplayName, "notifyKilledCreature", pPlayer)

	local state = self:getState(pPlayer)
	if (state == self.QUEST_NOT_STARTED or state == self.QUEST_COMPLETE) then
		return
	end

	createObserver(LOGGEDIN, self.screenplayName, "onLoggedIn", pPlayer, 1)

	if (state == self.STAGE_1_COLLECT_DNA) then
		createObserver(DNASAMPLED, self.screenplayName, "notifyDnaSampled", pPlayer)
	elseif (state == self.STAGE_3_CRAFT_COMPONENT) then
		createObserver(PROTOTYPECREATED, self.screenplayName, "notifyPrototypeCreated", pPlayer)
	elseif (state == self.STAGE_4_HUNT_EXPERIMENT and self:getDataNumber(pPlayer, "mutationKilled") == 0) then
		createObserver(KILLEDCREATURE, self.screenplayName, "notifyKilledCreature", pPlayer)
	end
end

function GeneticistsFailedExperiment:onLoggedIn(pPlayer)
	if (pPlayer == nil) then
		return 0
	end

	self:refreshObservers(pPlayer)
	self:updateWaypoint(pPlayer)

	if (self:getState(pPlayer) == self.STAGE_4_HUNT_EXPERIMENT and self:getDataNumber(pPlayer, "mutationKilled") == 0) then
		self:ensureStage4Spawn(pPlayer)
	end

	return 0
end

function GeneticistsFailedExperiment:beginQuest(pPlayer)
	if (not self:isBioEngineer(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("Only Bio-Engineers can take on Dr. Varr's work.")
		return
	end

	if (self:getState(pPlayer) ~= self.QUEST_NOT_STARTED) then
		return
	end

	self:setDataNumber(pPlayer, "dnaCount", 0)
	self:setDataNumber(pPlayer, "mutationKilled", 0)
	self:setDataNumber(pPlayer, "mutationSpawnId", 0)
	self:setState(pPlayer, self.STAGE_1_COLLECT_DNA)
	self:sendObjective(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("Quest accepted: The Geneticist's Failed Experiment.")
end

function GeneticistsFailedExperiment:isStage1CreatureValid(pCreature)
	if (pCreature == nil) then
		return false
	end

	if (SceneObject(pCreature):isAiAgent()) then
		local socialGroup = string.lower(tostring(AiAgent(pCreature):getSocialGroup() or ""))
		if (self.allowedStage1SocialGroups[socialGroup] == true) then
			return true
		end
	end

	local objectName = string.lower(tostring(SceneObject(pCreature):getObjectName() or ""))

	for i = 1, #self.allowedStage1Names, 1 do
		if (string.find(objectName, self.allowedStage1Names[i], 1, true) ~= nil) then
			return true
		end
	end

	return false
end

function GeneticistsFailedExperiment:notifyDnaSampled(pPlayer, pCreature, quality)
	if (pPlayer == nil or pCreature == nil or self:getState(pPlayer) ~= self.STAGE_1_COLLECT_DNA) then
		return 0
	end

	if (not self:isStage1CreatureValid(pCreature)) then
		return 0
	end

	local creatureKey = "sampledCreature_" .. SceneObject(pCreature):getObjectID()
	if (self:getDataNumber(pPlayer, creatureKey) == 1) then
		return 0
	end

	local current = self:getDataNumber(pPlayer, "dnaCount")
	if (current >= self.stage1Goal) then
		return 0
	end

	self:setDataNumber(pPlayer, creatureKey, 1)
	current = current + 1
	self:setDataNumber(pPlayer, "dnaCount", current)
	CreatureObject(pPlayer):sendSystemMessage("Collected qualifying DNA samples: " .. current .. "/" .. self.stage1Goal .. ".")

	if (current >= self.stage1Goal) then
		self:setState(pPlayer, self.STAGE_1_COMPLETE)
		CreatureObject(pPlayer):sendSystemMessage("Stage complete: Field DNA Collection.")
		self:sendObjective(pPlayer)
	end

	return 0
end

function GeneticistsFailedExperiment:useResearchTerminal(pPlayer)
	if (self:getState(pPlayer) ~= self.STAGE_2_ANALYZE_DNA) then
		CreatureObject(pPlayer):sendSystemMessage("The terminal rejects your authorization key.")
		return
	end

	CreatureObject(pPlayer):sendSystemMessage("The terminal completes a genetic stability scan of the submitted DNA samples.")
	self:setState(pPlayer, self.STAGE_2_COMPLETE)
	CreatureObject(pPlayer):sendSystemMessage("Stage complete: Genetic Analysis.")
	self:sendObjective(pPlayer)
end

function GeneticistsFailedExperiment:notifyPrototypeCreated(pPlayer, pItem, practice)
	if (pPlayer == nil or pItem == nil or self:getState(pPlayer) ~= self.STAGE_3_CRAFT_COMPONENT) then
		return 0
	end

	if (practice == 1 or practice == true) then
		return 0
	end

	if (string.find(SceneObject(pItem):getTemplateObjectPath(), self.stage3TemplatePath, 1, true) == nil) then
		return 0
	end

	self:setState(pPlayer, self.STAGE_3_COMPLETE)
	CreatureObject(pPlayer):sendSystemMessage("Stage complete: Experimental DNA Creation.")
	self:sendObjective(pPlayer)
	return 0
end

function GeneticistsFailedExperiment:despawnMutationSpawn(pPlayer)
	local spawnId = self:getDataNumber(pPlayer, "mutationSpawnId")
	if (spawnId == 0) then
		return
	end

	local pSpawn = getSceneObject(spawnId)
	if (pSpawn ~= nil) then
		SceneObject(pSpawn):destroyObjectFromWorld()
	end

	self:setDataNumber(pPlayer, "mutationSpawnId", 0)
end

function GeneticistsFailedExperiment:ensureStage4Spawn(pPlayer)
	if (self:getState(pPlayer) ~= self.STAGE_4_HUNT_EXPERIMENT or self:getDataNumber(pPlayer, "mutationKilled") == 1) then
		return
	end

	local spawnId = self:getDataNumber(pPlayer, "mutationSpawnId")
	if (spawnId ~= 0 and getSceneObject(spawnId) ~= nil) then
		return
	end

	local spawnZ = getTerrainHeight(self.planet, self.stage4Spawn.x, self.stage4Spawn.y) or self.npcZ
	local pSpawn = spawnMobile(self.planet, "mutated_gurreck_alpha", 0, self.stage4Spawn.x, spawnZ, self.stage4Spawn.y, getRandomNumber(360) - 180, 0)

	if (pSpawn ~= nil) then
		SceneObject(pSpawn):setCustomObjectName("Mutated Gurreck Alpha")
		self:setDataNumber(pPlayer, "mutationSpawnId", SceneObject(pSpawn):getObjectID())
	end
end

function GeneticistsFailedExperiment:isStage4VictimMatch(pPlayer, pVictim)
	if (pVictim == nil) then
		return false
	end

	local trackedSpawnId = self:getDataNumber(pPlayer, "mutationSpawnId")
	if (trackedSpawnId ~= 0 and SceneObject(pVictim):getObjectID() == trackedSpawnId) then
		return true
	end

	local victimCustomName = string.lower(tostring(SceneObject(pVictim):getCustomObjectName() or ""))
	return victimCustomName == "mutated gurreck alpha"
end

function GeneticistsFailedExperiment:notifyKilledCreature(pPlayer, pVictim)
	if (pPlayer == nil or pVictim == nil or self:getState(pPlayer) ~= self.STAGE_4_HUNT_EXPERIMENT or self:getDataNumber(pPlayer, "mutationKilled") == 1) then
		return 0
	end

	if (not self:isStage4VictimMatch(pPlayer, pVictim)) then
		return 0
	end

	self:setDataNumber(pPlayer, "mutationKilled", 1)
	self:despawnMutationSpawn(pPlayer)
	dropObserver(KILLEDCREATURE, self.screenplayName, "notifyKilledCreature", pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("Stage complete: Escaped Experiment.")
	self:sendObjective(pPlayer)
	return 0
end

function GeneticistsFailedExperiment:awardCredits(pPlayer, amount)
	CreatureObject(pPlayer):addBankCredits(amount, true)
	CreatureObject(pPlayer):sendSystemMessage("Reward granted: " .. amount .. " credits.")
end

function GeneticistsFailedExperiment:grantFinalItem(pPlayer)
	local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil or SceneObject(pInventory):isContainerFullRecursive()) then
		CreatureObject(pPlayer):sendSystemMessage("You need space in your inventory for the Rare Mutation DNA Sample.")
		return false
	end

	-- quality 1 = VHQ, armorRating 2 = Medium
	local pItem = createQuestDnaSample(pPlayer, 1, 2, "Rare Mutation DNA Sample")
	if (pItem == nil) then
		CreatureObject(pPlayer):sendSystemMessage("The reward sample could not be delivered.")
		return false
	end

	CreatureObject(pPlayer):sendSystemMessage("Reward granted: Rare Mutation DNA Sample.")
	return true
end

function GeneticistsFailedExperiment:completeStage1TurnIn(pPlayer)
	if (self:getState(pPlayer) ~= self.STAGE_1_COMPLETE) then
		return
	end

	self:awardCredits(pPlayer, self.stageRewards[self.STAGE_1_COMPLETE])
	self:setState(pPlayer, self.STAGE_2_ANALYZE_DNA)
	CreatureObject(pPlayer):sendSystemMessage("Stage advanced: Genetic Analysis.")
	self:sendObjective(pPlayer)
end

function GeneticistsFailedExperiment:completeStage2TurnIn(pPlayer)
	if (self:getState(pPlayer) ~= self.STAGE_2_COMPLETE) then
		return
	end

	self:awardCredits(pPlayer, self.stageRewards[self.STAGE_2_COMPLETE])
	self:setState(pPlayer, self.STAGE_3_CRAFT_COMPONENT)
	CreatureObject(pPlayer):sendSystemMessage("Stage advanced: Experimental DNA Creation.")
	self:sendObjective(pPlayer)
end

function GeneticistsFailedExperiment:completeStage3TurnIn(pPlayer)
	if (self:getState(pPlayer) ~= self.STAGE_3_COMPLETE) then
		return
	end

	self:awardCredits(pPlayer, self.stageRewards[self.STAGE_3_COMPLETE])
	self:setDataNumber(pPlayer, "mutationKilled", 0)
	self:setState(pPlayer, self.STAGE_4_HUNT_EXPERIMENT)
	self:ensureStage4Spawn(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("Stage advanced: Escaped Experiment.")
	self:sendObjective(pPlayer)
end

function GeneticistsFailedExperiment:completeQuest(pPlayer)
	if (self:getState(pPlayer) ~= self.STAGE_4_HUNT_EXPERIMENT or self:getDataNumber(pPlayer, "mutationKilled") ~= 1) then
		return false
	end

	if (not self:grantFinalItem(pPlayer)) then
		return false
	end

	self:awardCredits(pPlayer, self.stageRewards[self.QUEST_COMPLETE])
	self:clearWaypoint(pPlayer)
	self:despawnMutationSpawn(pPlayer)
	self:setDataNumber(pPlayer, "completedTime", os.time())
	self:setState(pPlayer, self.QUEST_COMPLETE)
	CreatureObject(pPlayer):sendSystemMessage("Quest complete: The Geneticist's Failed Experiment.")
	return true
end

function GeneticistsFailedExperiment:checkAndResetCooldown(pPlayer)
	if (self:getState(pPlayer) ~= self.QUEST_COMPLETE) then
		return
	end

	local completedTime = self:getDataNumber(pPlayer, "completedTime")
	if (completedTime == 0 or (os.time() - completedTime) >= self.cooldownSeconds) then
		self:setDataNumber(pPlayer, "dnaCount", 0)
		self:setDataNumber(pPlayer, "mutationKilled", 0)
		self:setDataNumber(pPlayer, "mutationSpawnId", 0)
		self:setDataNumber(pPlayer, "completedTime", 0)
		self:setState(pPlayer, self.QUEST_NOT_STARTED)
	end
end

function GeneticistsFailedExperiment:getCooldownRemaining(pPlayer)
	local completedTime = self:getDataNumber(pPlayer, "completedTime")
	if (completedTime == 0) then
		return 0
	end
	local remaining = self.cooldownSeconds - (os.time() - completedTime)
	if (remaining < 0) then
		return 0
	end
	return remaining
end
