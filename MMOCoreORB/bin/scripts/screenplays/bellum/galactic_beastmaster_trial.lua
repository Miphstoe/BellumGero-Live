GalacticBeastmasterTrial = ScreenPlay:new {
	screenplayName = "GalacticBeastmasterTrial",
	numberOfActs = 1,
}

registerScreenPlay("GalacticBeastmasterTrial", true)

GalacticBeastmasterTrial.NPC_TEMPLATE = "trainer_creaturehandler"
GalacticBeastmasterTrial.NPC_NAME = "Jorvik Tal"
GalacticBeastmasterTrial.NPC_PLANET = "naboo"
GalacticBeastmasterTrial.NPC_X = -5254
GalacticBeastmasterTrial.NPC_Z = 6
GalacticBeastmasterTrial.NPC_Y = 4608
GalacticBeastmasterTrial.NPC_HEADING = 180

GalacticBeastmasterTrial.SCRIPT_NAMESPACE = "galactic_beastmaster_trial"
GalacticBeastmasterTrial.REWARD_CREDITS = 150000
GalacticBeastmasterTrial.REWARD_ITEM_TEMPLATE = "object/tangible/loot/misc/holocron_of_destiny.iff"
GalacticBeastmasterTrial.COOLDOWN_SECONDS = 168 * 60 * 60
GalacticBeastmasterTrial.REQUIRED_SKILL = "outdoors_creaturehandler_novice"

GalacticBeastmasterTrial.STATE_KEYS = {
	active = "galacticBeastmasterTrialActive",
	cooldown = "galacticBeastmasterTrialCooldown",
	startedAt = "galacticBeastmasterTrialStartedAt",
	rewardLock = "galacticBeastmasterTrialRewardLock",
	corellia = "galacticBeastmasterTrial_corellia",
	naboo = "galacticBeastmasterTrial_naboo",
	rori = "galacticBeastmasterTrial_rori",
	talus = "galacticBeastmasterTrial_talus",
	endor = "galacticBeastmasterTrial_endor",
	tatooine = "galacticBeastmasterTrial_tatooine",
	lok = "galacticBeastmasterTrial_lok",
	dantooine = "galacticBeastmasterTrial_dantooine",
	dathomir = "galacticBeastmasterTrial_dathomir",
	yavin4 = "galacticBeastmasterTrial_yavin4",
}

GalacticBeastmasterTrial.planetOrder = {
	{ key = "corellia", display = "Corellia", flavor = "You have bonded with the resilient creatures of Corellia." },
	{ key = "naboo", display = "Naboo", flavor = "You have earned the trust of Naboo's gentle wilds." },
	{ key = "rori", display = "Rori", flavor = "You have calmed the restless beasts of Rori." },
	{ key = "talus", display = "Talus", flavor = "You have mastered the rugged creatures of Talus." },
	{ key = "endor", display = "Endor", flavor = "You have formed a bond within Endor's untamed forests." },
	{ key = "tatooine", display = "Tatooine", flavor = "You have bonded with the harsh life of the desert." },
	{ key = "lok", display = "Lok", flavor = "You have endured the brutal wildlife of Lok." },
	{ key = "dantooine", display = "Dantooine", flavor = "You have gained the confidence of Dantooine's frontier creatures." },
	{ key = "dathomir", display = "Dathomir", flavor = "Even the wild forces of Dathomir bend to your will." },
	{ key = "yavin4", display = "Yavin4", flavor = "You have connected with the ancient wilds of Yavin 4." },
}

function GalacticBeastmasterTrial:start()
	self:spawnNpc()
end

function GalacticBeastmasterTrial:spawnNpc()
	-- Static quest giver location in Theed, Naboo.
	local pNpc = spawnMobile(self.NPC_PLANET, self.NPC_TEMPLATE, 0, self.NPC_X, self.NPC_Z, self.NPC_Y, self.NPC_HEADING, 0)

	if (pNpc == nil) then
		return
	end

	CreatureObject(pNpc):setPvpStatusBitmask(0)
	CreatureObject(pNpc):setOptionsBitmask(AIENABLED + CONVERSABLE + INVULNERABLE)
	SceneObject(pNpc):setCustomObjectName(self.NPC_NAME)
	AiAgent(pNpc):setConvoTemplate("galacticBeastmasterTrialConvoTemplate")
	AiAgent(pNpc):addObjectFlag(AI_STATIC)
end

function GalacticBeastmasterTrial:getNow()
	return os.time()
end

function GalacticBeastmasterTrial:getNumber(pPlayer, key)
	if (pPlayer == nil) then
		return 0
	end

	return tonumber(readScreenPlayData(pPlayer, self.SCRIPT_NAMESPACE, key)) or 0
end

function GalacticBeastmasterTrial:setNumber(pPlayer, key, value)
	if (pPlayer == nil) then
		return
	end

	writeScreenPlayData(pPlayer, self.SCRIPT_NAMESPACE, key, value)
end

function GalacticBeastmasterTrial:isActive(pPlayer)
	return self:getNumber(pPlayer, self.STATE_KEYS.active) == 1
end

function GalacticBeastmasterTrial:isEligibleCreatureHandler(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	return CreatureObject(pPlayer):hasSkill(self.REQUIRED_SKILL)
end

function GalacticBeastmasterTrial:isRewardLocked(pPlayer)
	return self:getNumber(pPlayer, self.STATE_KEYS.rewardLock) == 1
end

function GalacticBeastmasterTrial:getRemainingCooldown(pPlayer)
	local expiresAt = self:getNumber(pPlayer, self.STATE_KEYS.cooldown)
	local remaining = expiresAt - self:getNow()

	if (remaining < 0) then
		return 0
	end

	return remaining
end

function GalacticBeastmasterTrial:isOnCooldown(pPlayer)
	return self:getRemainingCooldown(pPlayer) > 0
end

function GalacticBeastmasterTrial:resetRunData(pPlayer)
	self:setNumber(pPlayer, self.STATE_KEYS.active, 0)
	self:setNumber(pPlayer, self.STATE_KEYS.startedAt, 0)
	self:setNumber(pPlayer, self.STATE_KEYS.rewardLock, 0)

	for i = 1, #self.planetOrder, 1 do
		local planet = self.planetOrder[i]
		self:setNumber(pPlayer, self.STATE_KEYS[planet.key], 0)
	end
end

function GalacticBeastmasterTrial:startTrial(pPlayer)
	if (pPlayer == nil) then
		return false, "I cannot begin the trial without a registered hunter."
	end

	if (not self:isEligibleCreatureHandler(pPlayer)) then
		return false, "Only Creature Handlers with at least Novice Creature Handler training may undertake the Galactic Beastmaster Trial."
	end

	if (self:isActive(pPlayer)) then
		return false, "Your Galactic Beastmaster Trial is already active."
	end

	local remaining = self:getRemainingCooldown(pPlayer)

	if (remaining > 0) then
		return false, "You must wait " .. self:formatDuration(remaining) .. " before attempting the trial again."
	end

	self:resetRunData(pPlayer)
	self:setNumber(pPlayer, self.STATE_KEYS.active, 1)
	self:setNumber(pPlayer, self.STATE_KEYS.startedAt, self:getNow())

	return true, "The Galactic Beastmaster Trial has begun. Personally tame one baby creature from each required planet, and return to me when all ten are complete."
end

function GalacticBeastmasterTrial:getPlanetCompleted(pPlayer, planetKey)
	return self:getNumber(pPlayer, self.STATE_KEYS[planetKey]) == 1
end

function GalacticBeastmasterTrial:getCompletedCount(pPlayer)
	local count = 0

	for i = 1, #self.planetOrder, 1 do
		local planet = self.planetOrder[i]
		if (self:getPlanetCompleted(pPlayer, planet.key)) then
			count = count + 1
		end
	end

	return count
end

function GalacticBeastmasterTrial:hasCompletedAllPlanets(pPlayer)
	return self:getCompletedCount(pPlayer) >= #self.planetOrder
end

function GalacticBeastmasterTrial:getCompletedPlanetNames(pPlayer)
	local names = {}

	for i = 1, #self.planetOrder, 1 do
		local planet = self.planetOrder[i]
		if (self:getPlanetCompleted(pPlayer, planet.key)) then
			table.insert(names, planet.display)
		end
	end

	return names
end

function GalacticBeastmasterTrial:getRemainingPlanetNames(pPlayer)
	local names = {}

	for i = 1, #self.planetOrder, 1 do
		local planet = self.planetOrder[i]
		if (not self:getPlanetCompleted(pPlayer, planet.key)) then
			table.insert(names, planet.display)
		end
	end

	return names
end

function GalacticBeastmasterTrial:joinNames(names)
	if (names == nil or #names == 0) then
		return "None"
	end

	return table.concat(names, ", ")
end

function GalacticBeastmasterTrial:getProgressReportText(pPlayer)
	if (pPlayer == nil) then
		return "No hunter data found."
	end

	local completed = self:getCompletedPlanetNames(pPlayer)
	local remaining = self:getRemainingPlanetNames(pPlayer)
	local total = self:getCompletedCount(pPlayer)

	return "Galactic Beastmaster Trial Progress\n\nCompleted:\n- "
		.. table.concat((#completed > 0 and completed or { "None" }), "\n- ")
		.. "\n\nRemaining:\n- "
		.. table.concat((#remaining > 0 and remaining or { "None" }), "\n- ")
		.. "\n\nTotal Progress: "
		.. total
		.. "/"
		.. tostring(#self.planetOrder)
end

function GalacticBeastmasterTrial:getRulesText()
	return "Rules of the Galactic Beastmaster Trial:\n\n"
		.. "- Personally tame one baby creature from each required planet.\n"
		.. "- Only fresh tame successes during an active trial count.\n"
		.. "- Traded, gifted, or previously owned pets do not count.\n"
		.. "- Bio-engineered pets do not count.\n"
		.. "- Only one credit per planet is granted each run."
end

function GalacticBeastmasterTrial:formatDuration(seconds)
	if (seconds <= 0) then
		return "0 minutes"
	end

	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local minutes = math.floor((seconds % 3600) / 60)

	if (seconds % 60 > 0) then
		minutes = minutes + 1
		if (minutes >= 60) then
			minutes = minutes - 60
			hours = hours + 1
		end
		if (hours >= 24) then
			hours = hours - 24
			days = days + 1
		end
	end

	local parts = {}

	if (days > 0) then
		table.insert(parts, tostring(days) .. "d")
	end

	if (hours > 0) then
		table.insert(parts, tostring(hours) .. "h")
	end

	if (minutes > 0 or #parts == 0) then
		table.insert(parts, tostring(minutes) .. "m")
	end

	return table.concat(parts, " ")
end

function GalacticBeastmasterTrial:getCooldownStatusText(pPlayer)
	local remaining = self:getRemainingCooldown(pPlayer)

	if (remaining <= 0) then
		return "The Galactic Beastmaster Trial is ready to begin."
	end

	return "You may attempt the Galactic Beastmaster Trial again in " .. self:formatDuration(remaining) .. "."
end

function GalacticBeastmasterTrial:getPlanetDataByKey(planetKey)
	for i = 1, #self.planetOrder, 1 do
		local planet = self.planetOrder[i]
		if (planet.key == planetKey) then
			return planet
		end
	end

	return nil
end

function GalacticBeastmasterTrial:onSuccessfulTame(pPlayer, pCreature)
	if (pPlayer == nil or pCreature == nil) then
		return 0
	end

	if (not self:isEligibleCreatureHandler(pPlayer) or not self:isActive(pPlayer) or self:isOnCooldown(pPlayer)) then
		return 0
	end

	local planetKey = SceneObject(pCreature):getZoneName()
	local planetData = self:getPlanetDataByKey(planetKey)

	if (planetData == nil) then
		return 0
	end

	if (self:getPlanetCompleted(pPlayer, planetKey)) then
		return 0
	end

	self:setNumber(pPlayer, self.STATE_KEYS[planetKey], 1)

	local completedCount = self:getCompletedCount(pPlayer)
	local player = CreatureObject(pPlayer)

	player:sendSystemMessage(planetData.flavor)
	player:sendSystemMessage("Galactic Beastmaster Trial Progress: " .. completedCount .. "/" .. tostring(#self.planetOrder) .. " planets completed.")

	if (completedCount >= #self.planetOrder) then
		player:sendSystemMessage("All required planets are complete. Return to Jorvik Tal in Theed for your reward.")
	end

	return 1
end

function GalacticBeastmasterTrial:canGrantReward(pPlayer)
	if (pPlayer == nil) then
		return false, "I cannot verify your trial records."
	end

	if (not self:isActive(pPlayer)) then
		if (self:isOnCooldown(pPlayer)) then
			return false, "You have already completed this trial. " .. self:getCooldownStatusText(pPlayer)
		end

		return false, "You do not have an active Galactic Beastmaster Trial."
	end

	if (not self:hasCompletedAllPlanets(pPlayer)) then
		return false, "You have not yet completed every required planet.\n\n" .. self:getProgressReportText(pPlayer)
	end

	if (self:isRewardLocked(pPlayer)) then
		return false, "Your completion reward is already being processed."
	end

	local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")

	if (pInventory == nil) then
		return false, "Your inventory could not be found."
	end

	if (SceneObject(pInventory):isContainerFullRecursive()) then
		return false, "Make room in your inventory before I hand over the Holocron of Destiny."
	end

	return true, ""
end

function GalacticBeastmasterTrial:completeTrial(pPlayer)
	local canGrant, reason = self:canGrantReward(pPlayer)

	if (not canGrant) then
		return false, reason
	end

	local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")
	local now = self:getNow()

	self:setNumber(pPlayer, self.STATE_KEYS.rewardLock, 1)
	self:setNumber(pPlayer, self.STATE_KEYS.cooldown, now + self.COOLDOWN_SECONDS)
	self:setNumber(pPlayer, self.STATE_KEYS.active, 0)

	local pReward = giveItem(pInventory, self.REWARD_ITEM_TEMPLATE, -1, true)

	if (pReward == nil) then
		self:setNumber(pPlayer, self.STATE_KEYS.cooldown, 0)
		self:setNumber(pPlayer, self.STATE_KEYS.active, 1)
		self:setNumber(pPlayer, self.STATE_KEYS.rewardLock, 0)
		return false, "I could not place the Holocron of Destiny into your inventory. Free some space and try again."
	end

	CreatureObject(pPlayer):addBankCredits(self.REWARD_CREDITS, true)
	self:resetRunData(pPlayer)
	self:setNumber(pPlayer, self.STATE_KEYS.cooldown, now + self.COOLDOWN_SECONDS)

	CreatureObject(pPlayer):sendSystemMessage("You have completed the Galactic Beastmaster Trial and proven your mastery across the galaxy.")

	return true, "You have completed the Galactic Beastmaster Trial and proven your mastery across the galaxy.\n\nRewarded:\n- 150,000 credits\n- 1 Holocron of Destiny"
end
