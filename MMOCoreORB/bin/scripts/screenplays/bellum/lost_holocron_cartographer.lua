LostHolocronCartographer = ScreenPlay:new {
	screenplayName = "LostHolocronCartographer",
	numberOfActs = 1,
}

registerScreenPlay("LostHolocronCartographer", true)

LostHolocronCartographer.NPC_TEMPLATE = "bg_force_old_man"
LostHolocronCartographer.NPC_NAME = "Holocron Cartographer"
LostHolocronCartographer.NPC_PLANET = "tatooine"
LostHolocronCartographer.NPC_X = -981
LostHolocronCartographer.NPC_Z = 12
LostHolocronCartographer.NPC_Y = -3718
LostHolocronCartographer.NPC_HEADING = 0

LostHolocronCartographer.SURVEY_STONE_TEMPLATE = "object/tangible/jedi/force_shrine_stone.iff"
LostHolocronCartographer.FRAGMENT_TEMPLATE = "object/tangible/loot/misc/holocron_splinters_sith_s01.iff"
LostHolocronCartographer.DESTINY_TEMPLATE = "object/tangible/loot/misc/holocron_of_destiny.iff"
LostHolocronCartographer.REQUIRED_SPLINTERS = 6

LostHolocronCartographer.FINAL_COOLDOWN_SECONDS = 20 * 60 * 60
LostHolocronCartographer.SURVEY_RESPAWN_LOCK_SECONDS = 10 * 60

LostHolocronCartographer.GUARDIAN_TEMPLATES = {
	"sith_shadow_thug",
	"sith_shadow_outlaw",
	"sith_shadow_pirate",
	"sith_shadow_mercenary",
}

LostHolocronCartographer.stageConfig = {
	{ index = 1, planet = "dantooine", name = "Force Anomaly I", x = 4210, z = 8, y = 5258, heading = 0, waypointDesc = "Survey the anomaly near the enclave ruins." },
	{ index = 2, planet = "yavin4", name = "Force Anomaly II", x = 5077, z = 73, y = 5538, heading = 0, waypointDesc = "Survey the anomaly near Exar Kun's temple." },
	{ index = 3, planet = "dathomir", name = "Force Anomaly III", x = -4487, z = 127, y = 2543, heading = 0, waypointDesc = "Survey the anomaly on Dathomir." },
	{ index = 4, planet = "lok", name = "Force Anomaly IV", x = 3099, z = 344, y = -4674, heading = 0, waypointDesc = "Survey the anomaly along the volcanic ridge." },
	{ index = 5, planet = "talus", name = "Force Anomaly V", x = 4093, z = 5, y = 785, heading = 0, waypointDesc = "Survey the anomaly near the Lost City of Durbin." },
	{ index = 6, planet = "endor", name = "Force Anomaly VI", x = -6647, z = 16, y = -2992, heading = 0, waypointDesc = "Survey the final anomaly on Endor." },
}

LostHolocronCartographer.stageStoneIds = {}

function LostHolocronCartographer:start()
	self:spawnCartographer()
	self:spawnSurveyStones()
end

function LostHolocronCartographer:spawnCartographer()
	local pNpc = spawnMobile(self.NPC_PLANET, self.NPC_TEMPLATE, 0, self.NPC_X, self.NPC_Z, self.NPC_Y, self.NPC_HEADING, 0)

	if (pNpc == nil) then
		return
	end

	CreatureObject(pNpc):setPvpStatusBitmask(0)
	CreatureObject(pNpc):setOptionsBitmask(AIENABLED + CONVERSABLE + INVULNERABLE)
	SceneObject(pNpc):setCustomObjectName(self.NPC_NAME)
	AiAgent(pNpc):setConvoTemplate("lostHolocronCartographerConvoTemplate")
	AiAgent(pNpc):addObjectFlag(AI_STATIC)
end

function LostHolocronCartographer:spawnSurveyStones()
	self.stageStoneIds = {}

	for i = 1, #self.stageConfig, 1 do
		local stage = self.stageConfig[i]
		local pStone = spawnSceneObject(stage.planet, self.SURVEY_STONE_TEMPLATE, stage.x, stage.z, stage.y, 0, math.rad(stage.heading or 0))

		if (pStone ~= nil) then
			local stoneObj = SceneObject(pStone)
			stoneObj:setObjectMenuComponent("LostHolocronSurveyStoneMenuComponent")
			stoneObj:setCustomObjectName("Survey Stone - " .. tostring(stage.name))

			local stoneId = stoneObj:getObjectID()
			self.stageStoneIds[stage.index] = stoneId
			writeData("lost_holocron_cartographer:stone:" .. stoneId, stage.index)
		end
	end
end

function LostHolocronCartographer:getNow()
	return os.time()
end

function LostHolocronCartographer:getNumber(pPlayer, key)
	if (pPlayer == nil) then
		return 0
	end

	return tonumber(readScreenPlayData(pPlayer, "lost_holocron_cartographer", key)) or 0
end

function LostHolocronCartographer:setNumber(pPlayer, key, value)
	if (pPlayer == nil) then
		return
	end

	writeScreenPlayData(pPlayer, "lost_holocron_cartographer", key, value)
end

function LostHolocronCartographer:getString(pPlayer, key)
	if (pPlayer == nil) then
		return ""
	end

	return tostring(readScreenPlayData(pPlayer, "lost_holocron_cartographer", key) or "")
end

function LostHolocronCartographer:setString(pPlayer, key, value)
	if (pPlayer == nil) then
		return
	end

	writeScreenPlayData(pPlayer, "lost_holocron_cartographer", key, value)
end

function LostHolocronCartographer:getPlayerId(pPlayer)
	if (pPlayer == nil or SceneObject(pPlayer) == nil) then
		return 0
	end

	return SceneObject(pPlayer):getObjectID()
end

function LostHolocronCartographer:getStage(pPlayer)
	local stage = self:getNumber(pPlayer, "stage")
	if (stage < 1) then
		return 1
	end
	if (stage > 6) then
		return 6
	end
	return stage
end

function LostHolocronCartographer:isQuestActive(pPlayer)
	return self:getNumber(pPlayer, "active") == 1
end

function LostHolocronCartographer:isRewardPending(pPlayer)
	return self:getNumber(pPlayer, "reward_pending") == 1
end

function LostHolocronCartographer:isQuestCompleted(pPlayer)
	return self:getNumber(pPlayer, "completed") == 1
end

function LostHolocronCartographer:getRemainingCooldown(pPlayer)
	local expires = self:getNumber(pPlayer, "cooldown_until")
	local remaining = expires - self:getNow()
	if (remaining < 0) then
		return 0
	end
	return remaining
end

function LostHolocronCartographer:isOnCompletionCooldown(pPlayer)
	return self:getRemainingCooldown(pPlayer) > 0
end

function LostHolocronCartographer:isCooldownNotified(pPlayer)
	return self:getNumber(pPlayer, "cooldown_notified") == 1
end

function LostHolocronCartographer:formatDuration(seconds)
	if (seconds <= 0) then
		return "0m"
	end

	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)

	if (hours > 0) then
		return tostring(hours) .. "h " .. tostring(minutes) .. "m"
	end

	return tostring(minutes) .. "m"
end

function LostHolocronCartographer:formatDurationWords(seconds)
	if (seconds <= 0) then
		return "0 minutes"
	end

	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)

	if (hours <= 0) then
		if (minutes == 1) then
			return "1 minute"
		end
		return tostring(minutes) .. " minutes"
	end

	local hourWord = "hours"
	if (hours == 1) then
		hourWord = "hour"
	end

	if (minutes <= 0) then
		return tostring(hours) .. " " .. hourWord
	end

	local minuteWord = "minutes"
	if (minutes == 1) then
		minuteWord = "minute"
	end

	return tostring(hours) .. " " .. hourWord .. " " .. tostring(minutes) .. " " .. minuteWord
end

function LostHolocronCartographer:resetQuestState(pPlayer)
	self:setNumber(pPlayer, "active", 0)
	self:setNumber(pPlayer, "stage", 1)
	self:setNumber(pPlayer, "reward_pending", 0)
	self:setNumber(pPlayer, "completed", 0)
	self:setNumber(pPlayer, "reward_grant_lock_until", 0)
	self:setNumber(pPlayer, "cooldown_notified", 0)
	self:setNumber(pPlayer, "survey_active", 0)
	self:setNumber(pPlayer, "survey_lock_until", 0)
	self:setNumber(pPlayer, "survey_active_stage", 0)
	self:setNumber(pPlayer, "survey_active_count", 0)
	self:setNumber(pPlayer, "survey_instance", 0)
	self:setNumber(pPlayer, "survey_waypoint", 0)
end

function LostHolocronCartographer:startQuest(pPlayer)
	if (pPlayer == nil) then
		return
	end

	if (self:isOnCompletionCooldown(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("You must wait " .. self:formatDuration(self:getRemainingCooldown(pPlayer)) .. " before attempting this quest again.")
		return
	end

	self:setNumber(pPlayer, "active", 1)
	self:setNumber(pPlayer, "stage", 1)
	self:setNumber(pPlayer, "reward_pending", 0)
	self:setNumber(pPlayer, "completed", 0)
	self:setNumber(pPlayer, "reward_grant_lock_until", 0)
	self:setNumber(pPlayer, "survey_active", 0)
	self:setNumber(pPlayer, "survey_lock_until", 0)
	self:setNumber(pPlayer, "survey_active_stage", 0)
	self:setNumber(pPlayer, "survey_active_count", 0)
	self:setNumber(pPlayer, "survey_instance", 0)
	self:addOrUpdateStageWaypoint(pPlayer)

	CreatureObject(pPlayer):sendSystemMessage("The first anomaly location has been uploaded to your datapad.")
end

function LostHolocronCartographer:scheduleCooldownExpiryNotice(pPlayer)
	if (pPlayer == nil or SceneObject(pPlayer) == nil) then
		return
	end

	if (self:getNumber(pPlayer, "cooldown_until") <= 0) then
		return
	end

	if (self:isCooldownNotified(pPlayer)) then
		return
	end

	local remaining = self:getRemainingCooldown(pPlayer)
	if (remaining <= 0) then
		self:sendCooldownExpiredMessage(pPlayer)
		return
	end

	local playerId = self:getPlayerId(pPlayer)
	createEvent(remaining * 1000, self.screenplayName, "cooldownExpiredEvent", pPlayer, tostring(playerId))
end

function LostHolocronCartographer:sendCooldownExpiredMessage(pPlayer)
	if (pPlayer == nil) then
		return
	end

	if (self:getNumber(pPlayer, "cooldown_until") <= 0) then
		return
	end

	if (self:isCooldownNotified(pPlayer)) then
		return
	end

	if (self:getRemainingCooldown(pPlayer) > 0) then
		return
	end

	self:setNumber(pPlayer, "cooldown_notified", 1)
	CreatureObject(pPlayer):sendSystemMessage("The Lost Holocron Cartographer quest cooldown has expired. You may begin again.")
end

function LostHolocronCartographer:cooldownExpiredEvent(pPlayer, pParam)
	local player = pPlayer
	if ((player == nil or SceneObject(player) == nil) and pParam ~= nil and pParam ~= "") then
		player = getSceneObject(tonumber(pParam))
	end

	if (player == nil) then
		return 0
	end

	local remaining = self:getRemainingCooldown(player)
	if (remaining > 0) then
		createEvent(remaining * 1000, self.screenplayName, "cooldownExpiredEvent", player, tostring(self:getPlayerId(player)))
		return 0
	end

	self:sendCooldownExpiredMessage(player)
	return 0
end

function LostHolocronCartographer:onLoggedIn(pPlayer)
	if (pPlayer == nil) then
		return
	end

	if (self:getNumber(pPlayer, "cooldown_until") <= 0) then
		return
	end

	local remaining = self:getRemainingCooldown(pPlayer)
	if (remaining <= 0) then
		self:sendCooldownExpiredMessage(pPlayer)
	else
		self:scheduleCooldownExpiryNotice(pPlayer)
	end
end

function LostHolocronCartographer:getCurrentStageData(pPlayer)
	local stage = self:getStage(pPlayer)
	return self.stageConfig[stage]
end

function LostHolocronCartographer:addOrUpdateStageWaypoint(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil) then
		return
	end

	local oldWaypointId = self:getNumber(pPlayer, "survey_waypoint")
	if (oldWaypointId ~= nil and oldWaypointId ~= 0) then
		PlayerObject(pGhost):removeWaypoint(oldWaypointId, true)
		self:setNumber(pPlayer, "survey_waypoint", 0)
	end

	local stageData = self:getCurrentStageData(pPlayer)
	if (stageData == nil) then
		return
	end

	local waypointName = "Anomaly Survey " .. tostring(stageData.index) .. "/6"
	local waypointId = PlayerObject(pGhost):addWaypoint(stageData.planet, waypointName, stageData.waypointDesc, stageData.x, 0, stageData.y, WAYPOINT_YELLOW, true, true, WAYPOINTQUESTTASK)
	if (waypointId ~= nil and waypointId ~= 0) then
		self:setNumber(pPlayer, "survey_waypoint", waypointId)
	end
end

function LostHolocronCartographer:getStoneStageById(stoneId)
	if (stoneId == nil or stoneId == 0) then
		return 0
	end

	local stage = tonumber(readData("lost_holocron_cartographer:stone:" .. stoneId)) or 0
	if (stage < 1 or stage > 6) then
		return 0
	end

	return stage
end

function LostHolocronCartographer:surveyRespawnLocked(pPlayer)
	local lockUntil = self:getNumber(pPlayer, "survey_lock_until")
	if (self:getNow() < lockUntil) then
		return true, lockUntil - self:getNow()
	end

	return false, 0
end

function LostHolocronCartographer:hasFreeInventorySlot(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil) then
		return false
	end

	return not SceneObject(pInventory):isContainerFullRecursive()
end

function LostHolocronCartographer:giveFragment(pPlayer)
	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil or SceneObject(pInventory):isContainerFullRecursive()) then
		CreatureObject(pPlayer):sendSystemMessage("Your inventory is full. Clear space before completing another survey stage.")
		return false
	end

	local pItem = giveItem(pInventory, self.FRAGMENT_TEMPLATE, -1)
	if (pItem == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Unable to grant your holocron splinter. Please contact staff.")
		return false
	end

	return true
end

function LostHolocronCartographer:countFragmentsInContainer(pContainer)
	if (pContainer == nil) then
		return 0
	end

	local containerObj = SceneObject(pContainer)
	if (containerObj == nil) then
		return 0
	end

	local total = 0
	local size = containerObj:getContainerObjectsSize()

	for i = 0, size - 1, 1 do
		local pItem = containerObj:getContainerObject(i)
		if (pItem ~= nil) then
			local itemObj = SceneObject(pItem)
			if (itemObj ~= nil) then
				local template = itemObj:getTemplateObjectPath()
				if (template == self.FRAGMENT_TEMPLATE) then
					total = total + 1
				elseif (itemObj:getContainerObjectsSize() > 0) then
					total = total + self:countFragmentsInContainer(pItem)
				end
			end
		end
	end

	return total
end

function LostHolocronCartographer:removeFragmentsFromContainer(pContainer, toRemove)
	if (pContainer == nil or toRemove <= 0) then
		return 0
	end

	local containerObj = SceneObject(pContainer)
	if (containerObj == nil) then
		return 0
	end

	local removed = 0
	local size = containerObj:getContainerObjectsSize()

	for i = size - 1, 0, -1 do
		if (removed >= toRemove) then
			break
		end

		local pItem = containerObj:getContainerObject(i)
		if (pItem ~= nil) then
			local itemObj = SceneObject(pItem)
			if (itemObj ~= nil) then
				local template = itemObj:getTemplateObjectPath()
				if (template == self.FRAGMENT_TEMPLATE) then
					itemObj:destroyObjectFromWorld()
					itemObj:destroyObjectFromDatabase()
					removed = removed + 1
				elseif (itemObj:getContainerObjectsSize() > 0) then
					removed = removed + self:removeFragmentsFromContainer(pItem, toRemove - removed)
				end
			end
		end
	end

	return removed
end

function LostHolocronCartographer:countFragments(pPlayer)
	if (pPlayer == nil) then
		return 0
	end

	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil) then
		return 0
	end

	return self:countFragmentsInContainer(pInventory)
end

function LostHolocronCartographer:removeRequiredFragments(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil) then
		return false
	end

	local removed = self:removeFragmentsFromContainer(pInventory, self.REQUIRED_SPLINTERS)
	return removed == self.REQUIRED_SPLINTERS
end

function LostHolocronCartographer:spawnGuardiansForPlayer(pPlayer, stage)
	local zoneName = SceneObject(pPlayer):getZoneName()
	if (zoneName == nil or zoneName == "") then
		return false
	end

	local px = SceneObject(pPlayer):getWorldPositionX()
	local py = SceneObject(pPlayer):getWorldPositionY()
	local pz = SceneObject(pPlayer):getWorldPositionZ()

	local guardianCount = getRandomNumber(3, 5)
	local aliveCount = 0

	local instance = self:getNumber(pPlayer, "survey_instance") + 1
	self:setNumber(pPlayer, "survey_instance", instance)
	self:setNumber(pPlayer, "survey_active", 1)
	self:setNumber(pPlayer, "survey_active_stage", stage)
	self:setNumber(pPlayer, "survey_active_count", guardianCount)
	self:setNumber(pPlayer, "survey_lock_until", self:getNow() + self.SURVEY_RESPAWN_LOCK_SECONDS)

	local ownerId = self:getPlayerId(pPlayer)

	for i = 1, guardianCount, 1 do
		local templateIndex = getRandomNumber(1, #self.GUARDIAN_TEMPLATES)
		local template = self.GUARDIAN_TEMPLATES[templateIndex]
		local dx = getRandomNumber(-8, 8)
		local dy = getRandomNumber(-8, 8)
		local heading = getRandomNumber(0, 359)

		local pGuardian = spawnMobile(zoneName, template, 0, px + dx, pz, py + dy, heading, 0)
		if (pGuardian ~= nil) then
			aliveCount = aliveCount + 1
			local guardId = SceneObject(pGuardian):getObjectID()
			writeData("lost_holocron_cartographer:guardian:" .. guardId .. ":owner", ownerId)
			writeData("lost_holocron_cartographer:guardian:" .. guardId .. ":stage", stage)
			writeData("lost_holocron_cartographer:guardian:" .. guardId .. ":instance", instance)
			createObserver(OBJECTDESTRUCTION, self.screenplayName, "onGuardianKilled", pGuardian)
			AiAgent(pGuardian):setDefender(pPlayer)
		end
	end

	if (aliveCount <= 0) then
		self:setNumber(pPlayer, "survey_active", 0)
		self:setNumber(pPlayer, "survey_active_stage", 0)
		self:setNumber(pPlayer, "survey_active_count", 0)
		return false
	end

	self:setNumber(pPlayer, "survey_active_count", aliveCount)
	CreatureObject(pPlayer):sendSystemMessage("The survey stirs hostile guardians. Defeat them to stabilize the anomaly.")
	return true
end

function LostHolocronCartographer:performSurvey(pPlayer, stoneId)
	if (pPlayer == nil or stoneId == nil or stoneId == 0) then
		return
	end

	if (not self:isQuestActive(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("Speak with the Holocron Cartographer in Bestine to begin this quest.")
		return
	end

	if (self:isRewardPending(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("Return to the Holocron Cartographer for your final reward.")
		return
	end

	local stageFromStone = self:getStoneStageById(stoneId)
	local currentStage = self:getStage(pPlayer)

	if (stageFromStone ~= currentStage) then
		CreatureObject(pPlayer):sendSystemMessage("This anomaly does not match your current survey objective.")
		return
	end

	local locked, remaining = self:surveyRespawnLocked(pPlayer)
	if (locked) then
		CreatureObject(pPlayer):sendSystemMessage("This anomaly is unstable. Try surveying again in " .. self:formatDuration(remaining) .. ".")
		return
	end

	if (self:getNumber(pPlayer, "survey_active") == 1) then
		self:setNumber(pPlayer, "survey_active", 0)
		self:setNumber(pPlayer, "survey_active_count", 0)
		self:setNumber(pPlayer, "survey_active_stage", 0)
	end

	self:spawnGuardiansForPlayer(pPlayer, currentStage)
end

function LostHolocronCartographer:resolvePlayerFromKiller(pKiller)
	if (pKiller == nil) then
		return nil
	end

	if (SceneObject(pKiller):isPlayerCreature()) then
		return pKiller
	end

	if (SceneObject(pKiller):isPet()) then
		local pMaster = CreatureObject(pKiller):getLinkedCreature()
		if (pMaster ~= nil and SceneObject(pMaster):isPlayerCreature()) then
			return pMaster
		end
	end

	return nil
end

function LostHolocronCartographer:advanceStageAfterSurvey(pPlayer, stage)
	if (pPlayer == nil) then
		return
	end

	local currentStage = self:getStage(pPlayer)
	if (currentStage ~= stage) then
		return
	end

	if (not self:giveFragment(pPlayer)) then
		return
	end

	if (stage >= 6) then
		local oldWaypointId = self:getNumber(pPlayer, "survey_waypoint")
		self:setNumber(pPlayer, "active", 0)
		self:setNumber(pPlayer, "reward_pending", 1)
		self:setNumber(pPlayer, "survey_waypoint", 0)

		local pGhost = CreatureObject(pPlayer):getPlayerObject()
		if (pGhost ~= nil) then
			if (oldWaypointId ~= nil and oldWaypointId ~= 0) then
				PlayerObject(pGhost):removeWaypoint(oldWaypointId, true)
			end
			PlayerObject(pGhost):addWaypoint(self.NPC_PLANET, self.NPC_NAME, "Return for your reward.", self.NPC_X, 0, self.NPC_Y, WAYPOINT_YELLOW, true, true, WAYPOINTQUESTTASK)
		end

		CreatureObject(pPlayer):sendSystemMessage("All anomaly surveys are complete. Return to the Holocron Cartographer for your reward.")
		return
	end

	self:setNumber(pPlayer, "stage", stage + 1)
	self:addOrUpdateStageWaypoint(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("Survey complete. A new anomaly location has been uploaded.")
end

function LostHolocronCartographer:onGuardianKilled(pGuardian, pKiller)
	if (pGuardian == nil) then
		return 1
	end

	local guardId = SceneObject(pGuardian):getObjectID()
	local ownerId = tonumber(readData("lost_holocron_cartographer:guardian:" .. guardId .. ":owner")) or 0
	local stage = tonumber(readData("lost_holocron_cartographer:guardian:" .. guardId .. ":stage")) or 0
	local instance = tonumber(readData("lost_holocron_cartographer:guardian:" .. guardId .. ":instance")) or 0

	deleteData("lost_holocron_cartographer:guardian:" .. guardId .. ":owner")
	deleteData("lost_holocron_cartographer:guardian:" .. guardId .. ":stage")
	deleteData("lost_holocron_cartographer:guardian:" .. guardId .. ":instance")

	if (ownerId == 0 or stage == 0 or instance == 0) then
		return 1
	end

	local pOwner = getSceneObject(ownerId)
	if (pOwner == nil) then
		return 1
	end

	if (self:getNumber(pOwner, "survey_instance") ~= instance) then
		return 1
	end

	if (self:getNumber(pOwner, "survey_active") ~= 1) then
		return 1
	end

	if (self:getNumber(pOwner, "survey_active_stage") ~= stage) then
		return 1
	end

	local currentCount = self:getNumber(pOwner, "survey_active_count") - 1
	if (currentCount < 0) then
		currentCount = 0
	end
	self:setNumber(pOwner, "survey_active_count", currentCount)

	if (currentCount <= 0) then
		self:setNumber(pOwner, "survey_active", 0)
		self:setNumber(pOwner, "survey_active_stage", 0)
		self:setNumber(pOwner, "survey_lock_until", 0)
		self:advanceStageAfterSurvey(pOwner, stage)
	end

	return 1
end

function LostHolocronCartographer:tryGrantFinalReward(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	if (not self:isRewardPending(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("You have no pending reward from this quest.")
		return false
	end

	local now = self:getNow()
	if (self:getNumber(pPlayer, "reward_grant_lock_until") > now) then
		CreatureObject(pPlayer):sendSystemMessage("Reward processing already in progress.")
		return false
	end

	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil or SceneObject(pInventory):isContainerFullRecursive()) then
		CreatureObject(pPlayer):sendSystemMessage("Your inventory is full. Make space and speak to me again.")
		return false
	end

	local splinterCount = self:countFragments(pPlayer)
	if (splinterCount < self.REQUIRED_SPLINTERS) then
		CreatureObject(pPlayer):sendSystemMessage("You need " .. tostring(self.REQUIRED_SPLINTERS) .. " Holocron Splinters to claim this reward.")
		return false
	end

	self:setNumber(pPlayer, "reward_grant_lock_until", now + 30)

	if (not self:removeRequiredFragments(pPlayer)) then
		self:setNumber(pPlayer, "reward_grant_lock_until", 0)
		CreatureObject(pPlayer):sendSystemMessage("Could not consume required Holocron Splinters. Please try again.")
		return false
	end

	local pReward = giveItem(pInventory, self.DESTINY_TEMPLATE, -1)
	if (pReward == nil) then
		self:setNumber(pPlayer, "reward_grant_lock_until", 0)
		CreatureObject(pPlayer):sendSystemMessage("Reward could not be granted after consuming splinters. Please contact staff.")
		return false
	end

	self:setNumber(pPlayer, "reward_pending", 0)
	self:setNumber(pPlayer, "completed", 1)
	self:setNumber(pPlayer, "active", 0)
	self:setNumber(pPlayer, "stage", 1)
	self:setNumber(pPlayer, "survey_active", 0)
	self:setNumber(pPlayer, "survey_active_stage", 0)
	self:setNumber(pPlayer, "survey_active_count", 0)
	self:setNumber(pPlayer, "survey_lock_until", 0)
	self:setNumber(pPlayer, "cooldown_until", now + self.FINAL_COOLDOWN_SECONDS)
	self:setNumber(pPlayer, "last_completed", now)
	self:setNumber(pPlayer, "reward_grant_lock_until", 0)
	self:setNumber(pPlayer, "cooldown_notified", 0)
	self:scheduleCooldownExpiryNotice(pPlayer)

	CreatureObject(pPlayer):sendSystemMessage("You receive a Holocron of Destiny.")
	return true
end

function LostHolocronCartographer:conversationState(pPlayer)
	if (pPlayer == nil) then
		return "intro"
	end

	if (self:isRewardPending(pPlayer)) then
		return "reward_pending"
	end

	if (self:isQuestActive(pPlayer)) then
		return "in_progress"
	end

	if (self:isOnCompletionCooldown(pPlayer)) then
		return "cooldown"
	end

	return "intro"
end

LostHolocronSurveyStoneMenuComponent = {}

function LostHolocronSurveyStoneMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)
	menuResponse:addRadialMenuItem(120, 3, "Survey")
end

function LostHolocronSurveyStoneMenuComponent:handleObjectMenuSelect(pObject, pPlayer, selectedID)
	if (pObject == nil or pPlayer == nil) then
		return 0
	end

	if (selectedID == 120) then
		LostHolocronCartographer:performSurvey(pPlayer, SceneObject(pObject):getObjectID())
	end

	return 0
end

return LostHolocronCartographer
