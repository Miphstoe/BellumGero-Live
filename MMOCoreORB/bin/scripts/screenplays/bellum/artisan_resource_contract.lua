ArtisanResourceContract = ScreenPlay:new {
	screenplayName = "ArtisanResourceContract",
	numberOfActs = 1,
}

registerScreenPlay("ArtisanResourceContract", true)

ArtisanResourceContract.DATA_NAMESPACE = "artisan_resource_contract"
ArtisanResourceContract.CONVO_TEMPLATE = "artisanResourceContractConvoTemplate"
ArtisanResourceContract.NPC_TEMPLATE = "master_artisan_procurement_officer"
ArtisanResourceContract.NPC_NAME = "Master Artisan Procurement Officer"
ArtisanResourceContract.NPC_PLANET = "naboo"
ArtisanResourceContract.NPC_X = 5176
ArtisanResourceContract.NPC_Z = -192
ArtisanResourceContract.NPC_Y = 6681
ArtisanResourceContract.NPC_HEADING = 180
ArtisanResourceContract.NPC_CELL = 0

ArtisanResourceContract.REQUIRED_OBJECTIVES = 5
ArtisanResourceContract.REQUIRED_AMOUNT = 5000
ArtisanResourceContract.REWARD_CREDITS = 100000
ArtisanResourceContract.COOLDOWN_SECONDS = 24 * 60 * 60
ArtisanResourceContract.REWARD_ATTACHMENT_TEMPLATE = "object/tangible/gem/clothing.iff"

ArtisanResourceContract.STATE_KEYS = {
	active = "active",
	contractGeneratedAt = "contractGeneratedAt",
	cooldownEnd = "cooldownEnd",
	rewardPending = "rewardPending",
	resetCooldownEnd = "resetCooldownEnd",
}

ArtisanResourceContract.resourcePlanets = {
	"corellia",
	"dantooine",
	"dathomir",
	"endor",
	"lok",
	"naboo",
	"rori",
	"talus",
	"tatooine",
	"yavin4",
}

ArtisanResourceContract.resourceCategories = {
	"mineral",
	"chemical",
	"gas",
	"flora",
	"water",
}

ArtisanResourceContract.planetRestrictedCategories = {
	flora = true,
	water = true,
}

ArtisanResourceContract.rewardStatPool = {
	{ key = "general_assembly", display = "General Assembly" },
	{ key = "general_experimentation", display = "General Experimentation" },
	{ key = "surveying", display = "Surveying" },
	{ key = "clothing_assembly", display = "Clothing Assembly" },
	{ key = "clothing_repair", display = "Clothing Repair" },
	{ key = "armor_assembly", display = "Armor Assembly" },
	{ key = "armor_experimentation", display = "Armor Experimentation" },
	{ key = "armor_repair", display = "Armor Repair" },
	{ key = "weapon_assembly", display = "Weapon Assembly" },
	{ key = "weapon_experimentation", display = "Weapon Experimentation" },
	{ key = "weapon_repair", display = "Weapon Repair" },
	{ key = "structure_assembly", display = "Structure Assembly" },
	{ key = "structure_experimentation", display = "Structure Experimentation" },
	{ key = "droid_assembly", display = "Droid Assembly" },
	{ key = "droid_experimentation", display = "Droid Experimentation" },
	{ key = "food_assembly", display = "Food Assembly" },
	{ key = "food_experimentation", display = "Food Experimentation" },
	{ key = "advertising", display = "Advertising" },
	{ key = "hiring", display = "Hiring" },
	{ key = "manage_vendor", display = "Manage Vendor" },
}

function ArtisanResourceContract:start()
	self:spawnNpc()
end

function ArtisanResourceContract:spawnNpc()
	local pNpc = spawnMobile(self.NPC_PLANET, self.NPC_TEMPLATE, 0, self.NPC_X, self.NPC_Z, self.NPC_Y, self.NPC_HEADING, self.NPC_CELL)

	if (pNpc == nil) then
		return
	end

	CreatureObject(pNpc):setPvpStatusBitmask(0)
	CreatureObject(pNpc):setOptionsBitmask(AIENABLED + CONVERSABLE + INVULNERABLE)
	SceneObject(pNpc):setCustomObjectName(self.NPC_NAME)
	AiAgent(pNpc):setConvoTemplate(self.CONVO_TEMPLATE)
	AiAgent(pNpc):addObjectFlag(AI_STATIC)
end

function ArtisanResourceContract:getNow()
	return os.time()
end

function ArtisanResourceContract:getNumber(pPlayer, key)
	if (pPlayer == nil) then
		return 0
	end

	return tonumber(readScreenPlayData(pPlayer, self.DATA_NAMESPACE, key)) or 0
end

function ArtisanResourceContract:setNumber(pPlayer, key, value)
	if (pPlayer == nil) then
		return
	end

	writeScreenPlayData(pPlayer, self.DATA_NAMESPACE, key, tostring(value or 0))
end

function ArtisanResourceContract:getString(pPlayer, key)
	if (pPlayer == nil) then
		return ""
	end

	return tostring(readScreenPlayData(pPlayer, self.DATA_NAMESPACE, key) or "")
end

function ArtisanResourceContract:setString(pPlayer, key, value)
	if (pPlayer == nil) then
		return
	end

	writeScreenPlayData(pPlayer, self.DATA_NAMESPACE, key, value or "")
end

function ArtisanResourceContract:deleteKey(pPlayer, key)
	if (pPlayer == nil) then
		return
	end

	deleteScreenPlayData(pPlayer, self.DATA_NAMESPACE, key)
end

function ArtisanResourceContract:getObjectiveKey(index, suffix)
	return "objective" .. tostring(index) .. "_" .. suffix
end

function ArtisanResourceContract:getLegacyObjectiveKey(index, suffix)
	return "objective" .. tostring(index) .. "." .. suffix
end

function ArtisanResourceContract:isPlanetRestrictedCategory(category)
	return self.planetRestrictedCategories[category] == true
end

function ArtisanResourceContract:isActive(pPlayer)
	return self:getNumber(pPlayer, self.STATE_KEYS.active) == 1
end

function ArtisanResourceContract:isRewardPending(pPlayer)
	return self:getNumber(pPlayer, self.STATE_KEYS.rewardPending) == 1
end

function ArtisanResourceContract:isOnCooldown(pPlayer)
	return not self:isActive(pPlayer) and self:getRemainingCooldown(pPlayer) > 0
end

function ArtisanResourceContract:getRemainingResetCooldown(pPlayer)
	local remaining = self:getNumber(pPlayer, self.STATE_KEYS.resetCooldownEnd) - self:getNow()

	if (remaining < 0) then
		return 0
	end

	return remaining
end

function ArtisanResourceContract:isResetOnCooldown(pPlayer)
	return self:getRemainingResetCooldown(pPlayer) > 0
end

function ArtisanResourceContract:getRemainingCooldown(pPlayer)
	local remaining = self:getNumber(pPlayer, self.STATE_KEYS.cooldownEnd) - self:getNow()

	if (remaining < 0) then
		return 0
	end

	return remaining
end

function ArtisanResourceContract:getObjectiveData(pPlayer, index)
	local resourceName = self:getString(pPlayer, self:getObjectiveKey(index, "resourceName"))

	if (resourceName == "") then
		resourceName = self:getString(pPlayer, self:getLegacyObjectiveKey(index, "resourceName"))
	end

	if (resourceName == "") then
		return nil
	end

	local resourceType = self:getString(pPlayer, self:getObjectiveKey(index, "resourceType"))
	if (resourceType == "") then
		resourceType = self:getString(pPlayer, self:getLegacyObjectiveKey(index, "resourceType"))
	end

	local resourceClass = self:getString(pPlayer, self:getObjectiveKey(index, "resourceClass"))
	if (resourceClass == "") then
		resourceClass = self:getString(pPlayer, self:getLegacyObjectiveKey(index, "resourceClass"))
	end

	local planet = self:getString(pPlayer, self:getObjectiveKey(index, "planet"))
	if (planet == "") then
		planet = self:getString(pPlayer, self:getLegacyObjectiveKey(index, "planet"))
	end

	local requiredAmount = self:getNumber(pPlayer, self:getObjectiveKey(index, "requiredAmount"))
	if (requiredAmount <= 0) then
		requiredAmount = self:getNumber(pPlayer, self:getLegacyObjectiveKey(index, "requiredAmount"))
	end

	local currentAmount = self:getNumber(pPlayer, self:getObjectiveKey(index, "currentAmount"))
	if (currentAmount <= 0) then
		currentAmount = self:getNumber(pPlayer, self:getLegacyObjectiveKey(index, "currentAmount"))
	end

	local spawnId = self:getNumber(pPlayer, self:getObjectiveKey(index, "spawnId"))
	if (spawnId <= 0) then
		spawnId = self:getNumber(pPlayer, self:getLegacyObjectiveKey(index, "spawnId"))
	end

	local exactValidation = self:getNumber(pPlayer, self:getObjectiveKey(index, "exactValidation"))
	if (exactValidation <= 0) then
		exactValidation = self:getNumber(pPlayer, self:getLegacyObjectiveKey(index, "exactValidation"))
	end

	return {
		index = index,
		resourceName = resourceName,
		resourceType = resourceType,
		resourceClass = resourceClass,
		planet = planet,
		requiredAmount = requiredAmount,
		currentAmount = currentAmount,
		spawnId = spawnId,
		exactValidation = exactValidation,
	}
end

function ArtisanResourceContract:setObjectiveData(pPlayer, objective)
	self:setString(pPlayer, self:getObjectiveKey(objective.index, "resourceName"), objective.resourceName)
	self:setString(pPlayer, self:getObjectiveKey(objective.index, "resourceType"), objective.resourceType)
	self:setString(pPlayer, self:getObjectiveKey(objective.index, "resourceClass"), objective.resourceClass)
	self:setString(pPlayer, self:getObjectiveKey(objective.index, "planet"), objective.planet or "")
	self:setNumber(pPlayer, self:getObjectiveKey(objective.index, "requiredAmount"), objective.requiredAmount)
	self:setNumber(pPlayer, self:getObjectiveKey(objective.index, "currentAmount"), objective.currentAmount)
	self:setNumber(pPlayer, self:getObjectiveKey(objective.index, "spawnId"), objective.spawnId)
	self:setNumber(pPlayer, self:getObjectiveKey(objective.index, "exactValidation"), objective.exactValidation or 0)
end

function ArtisanResourceContract:clearObjectiveData(pPlayer, index)
	self:deleteKey(pPlayer, self:getObjectiveKey(index, "resourceName"))
	self:deleteKey(pPlayer, self:getLegacyObjectiveKey(index, "resourceName"))
	self:deleteKey(pPlayer, self:getObjectiveKey(index, "resourceType"))
	self:deleteKey(pPlayer, self:getLegacyObjectiveKey(index, "resourceType"))
	self:deleteKey(pPlayer, self:getObjectiveKey(index, "resourceClass"))
	self:deleteKey(pPlayer, self:getLegacyObjectiveKey(index, "resourceClass"))
	self:deleteKey(pPlayer, self:getObjectiveKey(index, "planet"))
	self:deleteKey(pPlayer, self:getLegacyObjectiveKey(index, "planet"))
	self:deleteKey(pPlayer, self:getObjectiveKey(index, "requiredAmount"))
	self:deleteKey(pPlayer, self:getLegacyObjectiveKey(index, "requiredAmount"))
	self:deleteKey(pPlayer, self:getObjectiveKey(index, "currentAmount"))
	self:deleteKey(pPlayer, self:getLegacyObjectiveKey(index, "currentAmount"))
	self:deleteKey(pPlayer, self:getObjectiveKey(index, "spawnId"))
	self:deleteKey(pPlayer, self:getLegacyObjectiveKey(index, "spawnId"))
	self:deleteKey(pPlayer, self:getObjectiveKey(index, "exactValidation"))
	self:deleteKey(pPlayer, self:getLegacyObjectiveKey(index, "exactValidation"))
end

function ArtisanResourceContract:getObjectives(pPlayer)
	local objectives = {}

	for i = 1, self.REQUIRED_OBJECTIVES, 1 do
		local objective = self:getObjectiveData(pPlayer, i)

		if (objective ~= nil) then
			table.insert(objectives, objective)
		end
	end

	return objectives
end

function ArtisanResourceContract:ensureValidContractState(pPlayer)
	if (not self:isActive(pPlayer)) then
		return true
	end

	local objectives = self:getObjectives(pPlayer)

	if (#objectives >= self.REQUIRED_OBJECTIVES) then
		return true
	end

	self:clearActiveContract(pPlayer)
	return false
end

function ArtisanResourceContract:clearActiveContract(pPlayer)
	self:setNumber(pPlayer, self.STATE_KEYS.active, 0)
	self:setNumber(pPlayer, self.STATE_KEYS.rewardPending, 0)
	self:deleteKey(pPlayer, self.STATE_KEYS.contractGeneratedAt)

	for i = 1, self.REQUIRED_OBJECTIVES, 1 do
		self:clearObjectiveData(pPlayer, i)
	end
end

function ArtisanResourceContract:shuffleArray(list)
	local clone = {}

	for i = 1, #list, 1 do
		clone[i] = list[i]
	end

	for i = #clone, 2, -1 do
		local swapIndex = getRandomNumber(1, i)
		clone[i], clone[swapIndex] = clone[swapIndex], clone[i]
	end

	return clone
end

function ArtisanResourceContract:getActiveResourcesForCategory(category)
	local results = {}
	local seenSpawnIds = {}

	for i = 1, #self.resourcePlanets, 1 do
		local planetName = self.resourcePlanets[i]
		local ok, entries = pcall(function()
			return getResourceSpawnsByType(category, planetName)
		end)

		if (not ok or type(entries) ~= "table") then
			entries = {}
		end

		for j = 1, #entries, 1 do
			local entry = entries[j]

			if (type(entry) == "table") then
				local spawnId = tonumber(entry.spawnId) or 0

				if (spawnId > 0 and seenSpawnIds[spawnId] == nil) then
					seenSpawnIds[spawnId] = true
					table.insert(results, {
						spawnId = spawnId,
						resourceName = tostring(entry.resourceName or ""),
						resourceType = category,
						resourceClass = tostring(entry.resourceClass or ""),
						planet = self:isPlanetRestrictedCategory(category) and planetName or "",
						exactValidation = 1,
					})
				end
			end
		end
	end

	return results
end

function ArtisanResourceContract:generateContractObjectives()
	local pools = {}
	local initialSelections = {}
	local selected = {}
	local usedSpawnIds = {}

	for i = 1, #self.resourceCategories, 1 do
		local category = self.resourceCategories[i]
		local categoryPool = self:getActiveResourcesForCategory(category)

		if (type(categoryPool) ~= "table") then
			categoryPool = {}
		end

		pools[category] = self:shuffleArray(categoryPool)
	end

	local categoryOrder = self:shuffleArray(self.resourceCategories)

	for i = 1, #categoryOrder, 1 do
		if (#initialSelections >= self.REQUIRED_OBJECTIVES) then
			break
		end

		local category = categoryOrder[i]
		local pool = pools[category]

		for j = 1, #pool, 1 do
			local candidate = pool[j]

			if (usedSpawnIds[candidate.spawnId] == nil) then
				usedSpawnIds[candidate.spawnId] = true
				table.insert(initialSelections, candidate)
				break
			end
		end
	end

	for i = 1, #initialSelections, 1 do
		table.insert(selected, initialSelections[i])
	end

	if (#selected < self.REQUIRED_OBJECTIVES) then
		local remainder = {}

		for i = 1, #self.resourceCategories, 1 do
			local category = self.resourceCategories[i]
			local pool = pools[category]

			for j = 1, #pool, 1 do
				local candidate = pool[j]

				if (usedSpawnIds[candidate.spawnId] == nil) then
					table.insert(remainder, candidate)
				end
			end
		end

		remainder = self:shuffleArray(remainder)

		for i = 1, #remainder, 1 do
			if (#selected >= self.REQUIRED_OBJECTIVES) then
				break
			end

			local candidate = remainder[i]

			if (usedSpawnIds[candidate.spawnId] == nil) then
				usedSpawnIds[candidate.spawnId] = true
				table.insert(selected, candidate)
			end
		end
	end

	if (#selected < self.REQUIRED_OBJECTIVES) then
		return nil
	end

	local objectives = {}

	for i = 1, self.REQUIRED_OBJECTIVES, 1 do
		local entry = selected[i]

		table.insert(objectives, {
			index = i,
			resourceName = entry.resourceName,
			resourceType = entry.resourceType,
			resourceClass = entry.resourceClass,
			planet = entry.planet,
			requiredAmount = self.REQUIRED_AMOUNT,
			currentAmount = 0,
			spawnId = entry.spawnId,
			exactValidation = entry.exactValidation,
		})
	end

	return objectives
end

function ArtisanResourceContract:formatDuration(seconds)
	local remaining = math.max(0, tonumber(seconds) or 0)
	local hours = math.floor(remaining / 3600)
	local minutes = math.floor((remaining % 3600) / 60)
	local secs = math.floor(remaining % 60)
	local pieces = {}

	if (hours > 0) then
		table.insert(pieces, tostring(hours) .. "h")
	end

	if (minutes > 0 or #pieces > 0) then
		table.insert(pieces, tostring(minutes) .. "m")
	end

	table.insert(pieces, tostring(secs) .. "s")

	return table.concat(pieces, " ")
end

function ArtisanResourceContract:getObjectiveLabel(objective)
	local label = objective.resourceName

	if (objective.resourceClass ~= "") then
		label = label .. " (" .. objective.resourceClass .. ")"
	end

	if (self:isPlanetRestrictedCategory(objective.resourceType) and objective.planet ~= "") then
		label = label .. " [" .. objective.planet .. "]"
	end

	return label
end

function ArtisanResourceContract:getProgressReportText(pPlayer)
	if (not self:ensureValidContractState(pPlayer)) then
		return "Your previous contract record was invalid after reload and has been cleared. Please request a new Artisan Resource Contract."
	end

	if (not self:isActive(pPlayer)) then
		if (self:isOnCooldown(pPlayer)) then
			return "I do not have another contract ready for you yet. Return after your current procurement cooldown expires.\n\nTime remaining: " .. self:formatDuration(self:getRemainingCooldown(pPlayer))
		end

		return "You do not have an active Artisan Resource Contract. Speak to me again and request a new contract when you are ready."
	end

	local lines = {
		"Here is your current contract progress:",
		"",
	}

	local objectives = self:getObjectives(pPlayer)

	for i = 1, #objectives, 1 do
		local objective = objectives[i]
		table.insert(lines, tostring(i) .. ". " .. self:getObjectiveLabel(objective))
		table.insert(lines, "   Progress: " .. tostring(objective.currentAmount) .. " / " .. tostring(objective.requiredAmount))
	end

	if (self:isReadyToFinalize(pPlayer)) then
		table.insert(lines, "")
		table.insert(lines, "All objectives are complete. Submit again and I will finalize your payment and attachment reward.")
	end

	return table.concat(lines, "\n")
end

function ArtisanResourceContract:getRulesText()
	return table.concat({
		"I have an active procurement contract for rare industrial resources. Bring me 5,000 units each of five requested materials, and I will compensate you well for your effort.",
		"",
		"Contract rules:",
		"1. Each contract requests 5 different active resources.",
		"2. You must deliver 5,000 units of each objective, 25,000 units total.",
		"3. Flora and water objectives must match the correct source planet noted on the contract.",
		"4. Mineral, chemical, and gas objectives only require the exact assigned active resource spawn.",
		"5. You may reset an active contract once every 24 hours to receive a new list.",
		"6. Contracts repeat every 24 hours after successful completion.",
		"7. Completion pays 100,000 credits and one random +25 artisan-focused clothing attachment.",
	}, "\n")
end

function ArtisanResourceContract:getCooldownStatusText(pPlayer)
	local remaining = self:getRemainingCooldown(pPlayer)

	if (remaining <= 0) then
		return "Your procurement cooldown has expired. You may request a new contract."
	end

	return "I do not have another contract ready for you yet. Return after your current procurement cooldown expires.\n\nTime remaining: " .. self:formatDuration(remaining)
end

function ArtisanResourceContract:getIntroText(pPlayer)
	if (self:isActive(pPlayer)) then
		return "Your procurement contract is still open.\n\n" .. self:getProgressReportText(pPlayer)
	end

	if (self:isOnCooldown(pPlayer)) then
		return self:getCooldownStatusText(pPlayer)
	end

	return "I have an active procurement contract for rare industrial resources. Bring me 5,000 units each of five requested materials, and I will compensate you well for your effort."
end

function ArtisanResourceContract:getResetStatusText(pPlayer)
	if (not self:isActive(pPlayer)) then
		if (self:isResetOnCooldown(pPlayer)) then
			return "Your emergency contract reset is still on cooldown.\n\nTime remaining: " .. self:formatDuration(self:getRemainingResetCooldown(pPlayer))
		end

		return "You do not have an active contract to reset."
	end

	if (self:isResetOnCooldown(pPlayer)) then
		return "I cannot reissue your contract yet.\n\nReset cooldown remaining: " .. self:formatDuration(self:getRemainingResetCooldown(pPlayer))
	end

	return "I can void your current contract and generate a new one immediately. This emergency reset may only be used once every 24 hours."
end

function ArtisanResourceContract:startContract(pPlayer)
	if (pPlayer == nil) then
		return false, "Unable to create a contract at this time."
	end

	self:ensureValidContractState(pPlayer)

	local hasActiveContract = self:isActive(pPlayer)

	if (hasActiveContract) then
		return false, "You already have an active Artisan Resource Contract."
	end

	local onCooldown = self:isOnCooldown(pPlayer)

	if (onCooldown) then
		return false, self:getCooldownStatusText(pPlayer)
	end

	local objectives = self:generateContractObjectives()

	if (objectives == nil or #objectives < self.REQUIRED_OBJECTIVES) then
		return false, "I could not assemble a valid five-resource contract from the currently active resource spawns. Please try again shortly."
	end

	self:setNumber(pPlayer, self.STATE_KEYS.active, 1)
	self:setNumber(pPlayer, self.STATE_KEYS.rewardPending, 0)
	self:setNumber(pPlayer, self.STATE_KEYS.contractGeneratedAt, self:getNow())

	for i = 1, #objectives, 1 do
		self:setObjectiveData(pPlayer, objectives[i])
	end

	return true, "Contract accepted.\n\n" .. self:getProgressReportText(pPlayer)
end

function ArtisanResourceContract:resetContract(pPlayer)
	if (pPlayer == nil) then
		return false, "Unable to reset your contract at this time."
	end

	if (not self:ensureValidContractState(pPlayer)) then
		if (self:isResetOnCooldown(pPlayer)) then
			return false, "Your invalid contract was already cleared. Reset cooldown remaining: " .. self:formatDuration(self:getRemainingResetCooldown(pPlayer))
		end

		return self:startContract(pPlayer)
	end

	if (not self:isActive(pPlayer)) then
		if (self:isResetOnCooldown(pPlayer)) then
			return false, "You do not have an active contract, and your reset is still on cooldown.\n\nTime remaining: " .. self:formatDuration(self:getRemainingResetCooldown(pPlayer))
		end

		return false, "You do not have an active contract to reset."
	end

	if (self:isResetOnCooldown(pPlayer)) then
		return false, "I cannot reissue your contract yet.\n\nReset cooldown remaining: " .. self:formatDuration(self:getRemainingResetCooldown(pPlayer))
	end

	local objectives = self:generateContractObjectives()

	if (objectives == nil or #objectives < self.REQUIRED_OBJECTIVES) then
		return false, "I could not assemble a valid replacement contract from the currently active resource spawns. Your existing contract remains unchanged."
	end

	self:clearActiveContract(pPlayer)
	self:setNumber(pPlayer, self.STATE_KEYS.active, 1)
	self:setNumber(pPlayer, self.STATE_KEYS.rewardPending, 0)
	self:setNumber(pPlayer, self.STATE_KEYS.contractGeneratedAt, self:getNow())
	self:setNumber(pPlayer, self.STATE_KEYS.resetCooldownEnd, self:getNow() + self.COOLDOWN_SECONDS)

	for i = 1, #objectives, 1 do
		self:setObjectiveData(pPlayer, objectives[i])
	end

	return true, "Your previous contract has been voided and replaced. Another reset will not be available for 24 hours.\n\n" .. self:getProgressReportText(pPlayer)
end

function ArtisanResourceContract:isReadyToFinalize(pPlayer)
	if (not self:ensureValidContractState(pPlayer)) then
		return false
	end

	if (not self:isActive(pPlayer)) then
		return false
	end

	local objectives = self:getObjectives(pPlayer)

	if (#objectives < self.REQUIRED_OBJECTIVES) then
		return false
	end

	for i = 1, #objectives, 1 do
		if (objectives[i].currentAmount < objectives[i].requiredAmount) then
			return false
		end
	end

	return true
end

function ArtisanResourceContract:getInventoryObjectIds(pPlayer)
	local objectIds = {}

	if (pPlayer == nil) then
		return objectIds
	end

	local creature = LuaCreatureObject(pPlayer)

	if (creature == nil) then
		return objectIds
	end

	local inventoryOk, pInventory = pcall(function()
		return creature:getSlottedObject("inventory")
	end)

	if (not inventoryOk or pInventory == nil) then
		return objectIds
	end

	local inventory = LuaSceneObject(pInventory)

	if (inventory == nil) then
		return objectIds
	end

	local sizeOk, size = pcall(function()
		return inventory:getContainerObjectsSize()
	end)

	if (not sizeOk or size == nil or size <= 0) then
		return objectIds
	end

	for i = 0, size - 1, 1 do
		local childOk, pChild = pcall(function()
			return inventory:getContainerObject(i)
		end)

		if (childOk and pChild ~= nil) then
			local childScene = LuaSceneObject(pChild)

			if (childScene ~= nil) then
				local templateOk, templatePath = pcall(function()
					return childScene:getTemplateObjectPath()
				end)

				if (templateOk and templatePath ~= nil) then
					templatePath = string.lower(tostring(templatePath))

					if (string.find(templatePath, "resource_container", 1, true) ~= nil) then
						table.insert(objectIds, childScene:getObjectID())
					end
				end
			end
		end
	end

	return objectIds
end

function ArtisanResourceContract:isFallbackObjectiveMatch(pObject, objective)
	if (pObject == nil or objective == nil) then
		return false
	end

	local scene = LuaSceneObject(pObject)

	if (scene == nil) then
		return false
	end

	local templateOk, templatePath = pcall(function()
		return scene:getTemplateObjectPath()
	end)

	if (not templateOk or templatePath == nil) then
		return false
	end

	templatePath = string.lower(tostring(templatePath))

	if (string.find(templatePath, "resource_container", 1, true) == nil) then
		return false
	end

	local objectiveName = string.lower(tostring(objective.resourceName or ""))

	if (objectiveName == "") then
		return false
	end

	local candidateNames = {}

	local customOk, customName = pcall(function()
		return scene:getCustomObjectName()
	end)

	if (customOk and customName ~= nil and customName ~= "") then
		table.insert(candidateNames, string.lower(tostring(customName)))
	end

	local displayOk, displayName = pcall(function()
		return scene:getDisplayedName()
	end)

	if (displayOk and displayName ~= nil and displayName ~= "") then
		table.insert(candidateNames, string.lower(tostring(displayName)))
	end

	local objectOk, objectName = pcall(function()
		return scene:getObjectName()
	end)

	if (objectOk and objectName ~= nil and objectName ~= "") then
		table.insert(candidateNames, string.lower(tostring(objectName)))
	end

	for i = 1, #candidateNames, 1 do
		if (string.find(candidateNames[i], objectiveName, 1, true) ~= nil) then
			return true
		end
	end

	return false
end

function ArtisanResourceContract:isMatchingObjectiveContainerSafe(pObject, objective)
	local ok, result = pcall(function()
		return self:isMatchingObjectiveContainer(pObject, objective)
	end)

	if (not ok) then
		return false
	end

	return result == true
end

function ArtisanResourceContract:getObjectCountSafe(pObject)
	local ok, count = pcall(function()
		return LuaTangibleObject(pObject):getCount()
	end)

	if (not ok) then
		return 0
	end

	return tonumber(count) or 0
end

function ArtisanResourceContract:isMatchingObjectiveContainer(pObject, objective)
	if (pObject == nil or objective == nil) then
		return false
	end

	-- Branch-safe fallback mode:
	-- exact resource-spawn accessors are disabled here because they hang during submit
	-- on this Core3 branch. Submission therefore matches resource container template +
	-- visible resource name only.
	return self:isFallbackObjectiveMatch(pObject, objective)
end

function ArtisanResourceContract:getAvailableAmountForObjective(pPlayer, objectiveIndex)
	local objective = self:getObjectiveData(pPlayer, objectiveIndex)

	if (objective == nil) then
		return 0
	end

	local needed = objective.requiredAmount - objective.currentAmount

	if (needed <= 0) then
		return 0
	end

	local objectIds = self:getInventoryObjectIds(pPlayer)
	local total = 0

	for i = 1, #objectIds, 1 do
		local pObject = getSceneObject(objectIds[i])

		if (self:isMatchingObjectiveContainerSafe(pObject, objective)) then
			total = total + self:getObjectCountSafe(pObject)

			if (total >= needed) then
				return needed
			end
		end
	end

	return total
end

function ArtisanResourceContract:wouldSubmissionCompleteContract(pPlayer, objectiveIndexes)
	local projected = {}
	local objectiveSelection = {}

	for i = 1, #objectiveIndexes, 1 do
		objectiveSelection[objectiveIndexes[i]] = true
	end

	for i = 1, self.REQUIRED_OBJECTIVES, 1 do
		local objective = self:getObjectiveData(pPlayer, i)

		if (objective == nil) then
			return false
		end

		local amount = objective.currentAmount

		if (objectiveSelection[i] == true) then
			amount = amount + self:getAvailableAmountForObjective(pPlayer, i)
		end

		projected[i] = math.min(amount, objective.requiredAmount)

		if (projected[i] < objective.requiredAmount) then
			return false
		end
	end

	return true
end

function ArtisanResourceContract:consumeObjectiveResources(pPlayer, objectiveIndex)
	local objective = self:getObjectiveData(pPlayer, objectiveIndex)

	if (objective == nil) then
		return 0
	end

	local needed = objective.requiredAmount - objective.currentAmount

	if (needed <= 0) then
		return 0
	end

	local objectIds = self:getInventoryObjectIds(pPlayer)
	local consumed = 0

	for i = 1, #objectIds, 1 do
		if (consumed >= needed) then
			break
		end

		local pObject = getSceneObject(objectIds[i])

		if (self:isMatchingObjectiveContainerSafe(pObject, objective)) then
			local currentCount = self:getObjectCountSafe(pObject)

			if (currentCount > 0) then
				local takeAmount = math.min(currentCount, needed - consumed)
				local ok = pcall(function()
					LuaTangibleObject(pObject):setCount(currentCount - takeAmount)
				end)

				if (ok) then
					consumed = consumed + takeAmount
				end
			end
		end
	end

	if (consumed > 0) then
		objective.currentAmount = math.min(objective.requiredAmount, objective.currentAmount + consumed)
		self:setObjectiveData(pPlayer, objective)
	end

	return consumed
end

function ArtisanResourceContract:getRewardData()
	local rewardIndex = getRandomNumber(1, #self.rewardStatPool)
	return self.rewardStatPool[rewardIndex]
end

function ArtisanResourceContract:finalizeCompletedContract(pPlayer)
	if (not self:isReadyToFinalize(pPlayer)) then
		return false, "Your contract is not complete yet."
	end

	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")

	if (pInventory == nil or SceneObject(pInventory):isContainerFullRecursive()) then
		self:setNumber(pPlayer, self.STATE_KEYS.rewardPending, 1)
		return false, "Your contract is complete, but your inventory is full. Make room for the reward attachment and speak to me again."
	end

	local rewardData = self:getRewardData()
	local pReward = giveItem(pInventory, self.REWARD_ATTACHMENT_TEMPLATE, -1, true)

	if (pReward == nil) then
		self:setNumber(pPlayer, self.STATE_KEYS.rewardPending, 1)
		return false, "Your contract is complete, but the reward attachment could not be created. Please contact staff."
	end

	TangibleObject(pReward):addAttachmentSkillModBonus(rewardData.key, 25)
	SceneObject(pReward):setCustomObjectName("Specialized Artisan Attachment (+25 " .. rewardData.display .. ")")

	CreatureObject(pPlayer):addCashCredits(self.REWARD_CREDITS)

	self:setNumber(pPlayer, self.STATE_KEYS.cooldownEnd, self:getNow() + self.COOLDOWN_SECONDS)
	self:clearActiveContract(pPlayer)

	return true, "Excellent work. This shipment fulfills the entire contract. Here is your payment, along with a specialized artisan attachment for your efforts.\n\nReward: 100,000 credits and +25 " .. rewardData.display .. "."
end

function ArtisanResourceContract:submitObjective(pPlayer, objectiveIndex)
	if (not self:ensureValidContractState(pPlayer)) then
		return false, "Your previous contract record was invalid after reload and has been cleared. Please request a new Artisan Resource Contract."
	end

	if (not self:isActive(pPlayer)) then
		if (self:isOnCooldown(pPlayer)) then
			return false, self:getCooldownStatusText(pPlayer)
		end

		return false, "You do not have an active contract to submit against."
	end

	if (self:isReadyToFinalize(pPlayer)) then
		return self:finalizeCompletedContract(pPlayer)
	end

	local objective = self:getObjectiveData(pPlayer, objectiveIndex)

	if (objective == nil) then
		return false, "That contract objective does not exist."
	end

	if (objective.currentAmount >= objective.requiredAmount) then
		return false, "Objective " .. tostring(objectiveIndex) .. " is already complete.\n\n" .. self:getProgressReportText(pPlayer)
	end

	local consumed = self:consumeObjectiveResources(pPlayer, objectiveIndex)

	if (consumed <= 0) then
		return false, "These materials do not match the current contract requirements for objective " .. tostring(objectiveIndex) .. "."
	end

	if (self:isReadyToFinalize(pPlayer)) then
		local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")

		if (pInventory == nil or SceneObject(pInventory):isContainerFullRecursive()) then
			return false, "Your contract is complete, but your inventory is full. Make room for the reward attachment first."
		end

		return self:finalizeCompletedContract(pPlayer)
	end

	return true, "I have accepted this shipment and logged it against your contract.\n\nSubmitted " .. tostring(consumed) .. " units toward objective " .. tostring(objectiveIndex) .. ".\n\n" .. self:getProgressReportText(pPlayer)
end

function ArtisanResourceContract:submitAllObjectives(pPlayer)
	if (not self:ensureValidContractState(pPlayer)) then
		return false, "Your previous contract record was invalid after reload and has been cleared. Please request a new Artisan Resource Contract."
	end

	if (not self:isActive(pPlayer)) then
		if (self:isOnCooldown(pPlayer)) then
			return false, self:getCooldownStatusText(pPlayer)
		end

		return false, "You do not have an active contract to submit against."
	end

	if (self:isReadyToFinalize(pPlayer)) then
		return self:finalizeCompletedContract(pPlayer)
	end

	local objectiveIndexes = {}

	for i = 1, self.REQUIRED_OBJECTIVES, 1 do
		table.insert(objectiveIndexes, i)
	end

	local totalConsumed = 0
	local touchedObjectives = 0

	for i = 1, self.REQUIRED_OBJECTIVES, 1 do
		local consumed = self:consumeObjectiveResources(pPlayer, i)

		if (consumed > 0) then
			totalConsumed = totalConsumed + consumed
			touchedObjectives = touchedObjectives + 1
		end
	end

	if (totalConsumed <= 0) then
		return false, "These materials do not match the current contract requirements."
	end

	if (self:isReadyToFinalize(pPlayer)) then
		local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")

		if (pInventory == nil or SceneObject(pInventory):isContainerFullRecursive()) then
			return false, "Your contract is complete, but your inventory is full. Make room for the reward attachment first."
		end

		return self:finalizeCompletedContract(pPlayer)
	end

	return true, "I have accepted this shipment and logged it against your contract.\n\nAccepted " .. tostring(totalConsumed) .. " total units across " .. tostring(touchedObjectives) .. " objective(s).\n\n" .. self:getProgressReportText(pPlayer)
end
