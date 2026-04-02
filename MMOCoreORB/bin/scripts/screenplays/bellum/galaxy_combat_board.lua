GalaxyCombatBoard = ScreenPlay:new {
	screenplayName = "GalaxyCombatBoard",
	numberOfActs = 1,
}

registerScreenPlay("GalaxyCombatBoard", true)

GalaxyCombatBoard.DATA_NAMESPACE = "galaxy_combat_board"
GalaxyCombatBoard.TERMINAL_TEMPLATE = "object/tangible/terminal/galaxy_combat_board_terminal.iff"
GalaxyCombatBoard.TERMINAL_NAME = "Galaxy Combat Board"

GalaxyCombatBoard.TERMINAL_SPAWNS = {
	-- Placed beside existing `myswg_vendor` world spawns with a small X/Y offset.
	{ planet = "corellia", x = -154, z = 28.0, y = -4722, heading = 35, cell = 0 }, -- coronet
	{ planet = "corellia", x = -5039, z = 21.0, y = -2295, heading = 35, cell = 0 }, -- tyrena
	{ planet = "corellia", x = -3135, z = 31.0, y = 2798, heading = 35, cell = 0 }, -- kor vella
	{ planet = "corellia", x = 3336, z = 308.0, y = 5526, heading = 35, cell = 0 }, -- doaba guerfel
	{ planet = "corellia", x = -5547, z = 15.58, y = -6059, heading = 35, cell = 0 }, -- ventooine
	{ planet = "corellia", x = 6646.02, z = 330.00, y = -5918.87, heading = 35, cell = 0 }, -- bela vistal

	{ planet = "naboo", x = -4869, z = 6.0, y = 4153, heading = 35, cell = 0 }, -- theed
	{ planet = "naboo", x = 4810, z = 4.0, y = -4703, heading = 35, cell = 0 }, -- moenia
	{ planet = "naboo", x = 5203, z = -192.0, y = 6679, heading = 35, cell = 0 }, -- kaadara
	{ planet = "naboo", x = 1447, z = 14.0, y = 2779, heading = 35, cell = 0 }, -- keren
	{ planet = "naboo", x = 5334.16, z = 326.95, y = -1574.12, heading = 35, cell = 0 }, -- dee'ja peak
	{ planet = "naboo", x = -5492.62, z = -150.00, y = -22.69, heading = 35, cell = 0 }, -- lake retreat

	{ planet = "tatooine", x = 3525, z = 5.0, y = -4801, heading = 35, cell = 0 }, -- mos eisley
	{ planet = "tatooine", x = -1278, z = 12.0, y = -3588, heading = 35, cell = 0 }, -- bestine
	{ planet = "tatooine", x = -2911, z = 5.0, y = 2131, heading = 35, cell = 0 }, -- mos espa
	{ planet = "tatooine", x = 1296, z = 7.0, y = 3142, heading = 35, cell = 0 }, -- mos entha
	{ planet = "tatooine", x = 51.33, z = 52.00, y = -5338.53, heading = 35, cell = 0 }, -- anchorhead
	{ planet = "tatooine", x = 3749.6, z = 6.8, y = 2302.5, heading = -90, cell = 0 }, -- mos taike
	{ planet = "tatooine", x = -5029.8, z = 75.0, y = -6570.5, heading = -37, cell = 0 }, -- wayfar
	--{ planet = "tatooine", x = 5850, z = 38, y = 4434, heading = 35, cell = 0 }, -- mos ender krayt

	{ planet = "talus", x = -2190, z = 20.0, y = 2315, heading = 35, cell = 0 }, -- talus imperial outpost
	{ planet = "talus", x = 4450, z = 2.0, y = 5273, heading = 35, cell = 0 }, -- nashal
	{ planet = "talus", x = 341, z = 6.0, y = -2929, heading = 35, cell = 0 }, -- dearic

	{ planet = "rori", x = 5368, z = 80.0, y = 5659, heading = 35, cell = 0 }, -- restuss
	{ planet = "rori", x = -5302, z = 80.0, y = -2226, heading = 35, cell = 0 }, -- narmle
	{ planet = "rori", x = 3686, z = 96.0, y = -6434, heading = 35, cell = 0 }, -- rebel outpost

	{ planet = "endor", x = -945, z = 73.0, y = 1552, heading = 35, cell = 0 }, -- smugglers outpost
	{ planet = "endor", x = 3204, z = 24.0, y = -3499, heading = 35, cell = 0 }, -- research outpost

	{ planet = "dantooine", x = -635, z = 3.0, y = 2507, heading = 35, cell = 0 }, -- mining outpost
	{ planet = "dantooine", x = -4206, z = 3.0, y = -2347, heading = 35, cell = 0 }, -- imperial outpost
	{ planet = "dantooine", x = 1567, z = 4.0, y = -6413, heading = 35, cell = 0 }, -- agro outpost
	--{ planet = "dantooine", x = -509, z = 1, y = -3014, heading = 35, cell = 0 }, -- rose red
	--{ planet = "dantooine", x = -5680.33, z = 2, y = 6887, heading = 35, cell = 0 }, -- new asgard

	{ planet = "dathomir", x = 622, z = 3.0, y = 3092, heading = 35, cell = 0 }, -- trade outpost
	{ planet = "dathomir", x = -44, z = 18.0, y = -1584, heading = 35, cell = 0 }, -- science outpost
	{ planet = "dathomir", x = 5256, z = 78.0, y = -4215, heading = 35, cell = 0 }, -- stronghold village

	{ planet = "yavin4", x = -262, z = 35.0, y = 4899, heading = 35, cell = 0 }, -- mining outpost
	{ planet = "yavin4", x = 4057, z = 37.0, y = -6217, heading = 37, cell = 0 }, -- imperial outpost
	{ planet = "yavin4", x = -6919, z = 73.0, y = -5728, heading = 35, cell = 0 }, -- labor outpost

	{ planet = "lok", x = 482, z = 8.0, y = 5514, heading = 35, cell = 0 }, -- nym's stronghold

	--{ planet = "corellia", x = -2057, z = 23, y = -4538, heading = 35, cell = 0 }, -- valhalla
}

function GalaxyCombatBoard:start()
	for i = 1, #self.TERMINAL_SPAWNS, 1 do
		local spawn = self.TERMINAL_SPAWNS[i]
		if (isZoneEnabled(spawn.planet)) then
			self:spawnTerminal(spawn)
		end
	end
end

function GalaxyCombatBoard:spawnTerminal(spawn)
	local pTerminal = spawnSceneObject(spawn.planet, self.TERMINAL_TEMPLATE, spawn.x, spawn.z, spawn.y, spawn.cell or 0, math.rad(spawn.heading or 0))

	if (pTerminal ~= nil) then
		SceneObject(pTerminal):setCustomObjectName(self.TERMINAL_NAME)
	end
end

function GalaxyCombatBoard:getNumber(pPlayer, key)
	return tonumber(readScreenPlayData(pPlayer, self.DATA_NAMESPACE, key)) or 0
end

function GalaxyCombatBoard:setNumber(pPlayer, key, value)
	writeScreenPlayData(pPlayer, self.DATA_NAMESPACE, key, value)
end

function GalaxyCombatBoard:getString(pPlayer, key)
	return tostring(readScreenPlayData(pPlayer, self.DATA_NAMESPACE, key) or "")
end

function GalaxyCombatBoard:setString(pPlayer, key, value)
	writeScreenPlayData(pPlayer, self.DATA_NAMESPACE, key, value)
end

function GalaxyCombatBoard:encodeTemplateList(templateList)
	return table.concat(templateList, "|")
end

function GalaxyCombatBoard:decodeTemplateList(value)
	local templates = {}
	local text = tostring(value or "")

	for entry in string.gmatch(text, "([^|]+)") do
		table.insert(templates, entry)
	end

	return templates
end

function GalaxyCombatBoard:getStoredContract(pPlayer)
	if (pPlayer == nil) then
		return nil
	end

	local tier = self:getNumber(pPlayer, "contract_tier")
	local contractKey = self:getString(pPlayer, "contract_key")

	if (tier <= 0 or contractKey == "") then
		return nil
	end

	local data = GalaxyCombatBoardData.contractsByKey[contractKey]
	local allowedTemplates = self:decodeTemplateList(self:getString(pPlayer, "allowed_templates"))
	local allowedSocialGroups = {}
	local allowedFactions = {}

	-- Always prefer the current contract definition so active contracts inherit matcher fixes.
	if (data ~= nil) then
		allowedTemplates = data.allowedTemplates or allowedTemplates
		allowedSocialGroups = data.allowedSocialGroups or {}
		allowedFactions = data.allowedFactions or {}
	end

	return {
		key = contractKey,
		tier = tier,
		title = (GalaxyCombatBoardData.tiers[tier] and GalaxyCombatBoardData.tiers[tier].title) or ("Tier " .. tostring(tier)),
		targetName = self:getString(pPlayer, "target_name"),
		allowedSocialGroups = allowedSocialGroups,
		allowedFactions = allowedFactions,
		allowedTemplates = allowedTemplates,
		requiredKills = self:getNumber(pPlayer, "required_kills"),
		currentKills = self:getNumber(pPlayer, "current_kills"),
		rewardCredits = self:getNumber(pPlayer, "reward_credits"),
		locationHint = self:getString(pPlayer, "location_hint"),
		isReady = self:getNumber(pPlayer, "contract_ready") == 1,
	}
end

function GalaxyCombatBoard:hasActiveContract(pPlayer)
	return self:getStoredContract(pPlayer) ~= nil
end

function GalaxyCombatBoard:clearContractData(pPlayer)
	self:setNumber(pPlayer, "contract_tier", 0)
	self:setString(pPlayer, "contract_key", "")
	self:setString(pPlayer, "target_name", "")
	self:setString(pPlayer, "allowed_templates", "")
	self:setNumber(pPlayer, "required_kills", 0)
	self:setNumber(pPlayer, "current_kills", 0)
	self:setNumber(pPlayer, "reward_credits", 0)
	self:setString(pPlayer, "location_hint", "")
	self:setNumber(pPlayer, "contract_ready", 0)

	-- TODO: Replace with a real cooldown timestamp when you add cooldowns.
	self:setNumber(pPlayer, "cooldown_placeholder", 0)

	self:refreshObservers(pPlayer)
end

function GalaxyCombatBoard:refreshObservers(pPlayer)
	if (pPlayer == nil) then
		return
	end

	dropObserver(LOGGEDIN, self.screenplayName, "onLoggedIn", pPlayer)
	dropObserver(KILLEDCREATURE, self.screenplayName, "notifyKilledCreature", pPlayer)

	createObserver(LOGGEDIN, self.screenplayName, "onLoggedIn", pPlayer, 1)

	if (self:hasActiveContract(pPlayer)) then
		createObserver(KILLEDCREATURE, self.screenplayName, "notifyKilledCreature", pPlayer)
	end
end

function GalaxyCombatBoard:onLoggedIn(pPlayer)
	if (pPlayer == nil) then
		return 0
	end

	self:refreshObservers(pPlayer)
	return 0
end

function GalaxyCombatBoard:onPlayerLoggedIn(pPlayer)
	self:onLoggedIn(pPlayer)
end

function GalaxyCombatBoard:getMenuPrompt(pPlayer)
	local contract = self:getStoredContract(pPlayer)

	if (contract == nil) then
		return "Select a tier to receive a random combat contract.\n\nOnly one active contract is allowed per player."
	end

	local body = "Active Contract:\n"
	body = body .. contract.title .. "\n"
	body = body .. "Target: " .. contract.targetName .. "\n"
	body = body .. "Progress: " .. contract.currentKills .. " / " .. contract.requiredKills .. "\n"
	body = body .. "Reward: " .. contract.rewardCredits .. " credits\n"
	body = body .. "Location: " .. contract.locationHint

	if (contract.isReady) then
		body = body .. "\n\nReturn here and choose Complete Contract to claim your reward."
	end

	return body
end

function GalaxyCombatBoard:getProgressReport(pPlayer)
	local contract = self:getStoredContract(pPlayer)

	if (contract == nil) then
		return "You do not have an active contract."
	end

	local body = contract.title .. "\n"
	body = body .. "Target: " .. contract.targetName .. "\n"
	body = body .. "Allowed Templates: " .. self:encodeTemplateList(contract.allowedTemplates) .. "\n"
	body = body .. "Progress: " .. contract.currentKills .. " / " .. contract.requiredKills .. "\n"
	body = body .. "Reward: " .. contract.rewardCredits .. " credits\n"
	body = body .. "Location Hint: " .. contract.locationHint

	if (contract.isReady) then
		body = body .. "\n\nContract complete. Return to the board to turn it in."
	end

	return body
end

function GalaxyCombatBoard:assignRandomContract(pPlayer, tier)
	if (pPlayer == nil) then
		return false
	end

	if (self:hasActiveContract(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("You already have an active Galaxy Combat Board contract.")
		return false
	end

	local tierInfo = GalaxyCombatBoardData.tiers[tier]
	local pool = GalaxyCombatBoardData.contracts[tier]

	if (tierInfo == nil or pool == nil or #pool == 0) then
		CreatureObject(pPlayer):sendSystemMessage("That contract tier is not configured.")
		return false
	end

	local selected = pool[math.random(1, #pool)]

	self:setNumber(pPlayer, "contract_tier", tier)
	self:setString(pPlayer, "contract_key", selected.key)
	self:setString(pPlayer, "target_name", selected.targetName)
	self:setString(pPlayer, "allowed_templates", self:encodeTemplateList(selected.allowedTemplates))
	self:setNumber(pPlayer, "required_kills", selected.requiredKills)
	self:setNumber(pPlayer, "current_kills", 0)
	self:setNumber(pPlayer, "reward_credits", selected.rewardCredits)
	self:setString(pPlayer, "location_hint", selected.locationHint)
	self:setNumber(pPlayer, "contract_ready", 0)

	self:refreshObservers(pPlayer)

	CreatureObject(pPlayer):sendSystemMessage("Contract accepted: " .. selected.targetName .. ".")
	CreatureObject(pPlayer):sendSystemMessage("Objective: Eliminate " .. selected.requiredKills .. " targets in " .. selected.locationHint .. ".")
	CreatureObject(pPlayer):sendSystemMessage("Reward: " .. selected.rewardCredits .. " credits.")

	return true
end

function GalaxyCombatBoard:getVictimMatchStrings(pVictim)
	local values = {}
	local objectName = string.lower(tostring(SceneObject(pVictim):getObjectName() or ""))
	local customName = string.lower(tostring(SceneObject(pVictim):getCustomObjectName() or ""))
	local templatePath = ""
	local socialGroup = ""
	local factionString = ""

	local templateSuccess, templateResult = pcall(function()
		return SceneObject(pVictim):getTemplateObjectPath()
	end)

	if (templateSuccess and templateResult ~= nil) then
		templatePath = string.lower(tostring(templateResult))
	end

	if (SceneObject(pVictim):isAiAgent()) then
		socialGroup = string.lower(tostring(AiAgent(pVictim):getSocialGroup() or ""))
		factionString = string.lower(tostring(AiAgent(pVictim):getFactionString() or ""))
	end

	values[1] = objectName
	values[2] = customName
	values[3] = templatePath
	values[4] = socialGroup
	values[5] = factionString

	return values
end

function GalaxyCombatBoard:isVictimAllowed(contract, pVictim)
	if (contract == nil or pVictim == nil) then
		return false
	end

	local matchStrings = self:getVictimMatchStrings(pVictim)
	local socialGroup = matchStrings[4] or ""
	local factionString = matchStrings[5] or ""

	for i = 1, #(contract.allowedSocialGroups or {}), 1 do
		local allowedGroup = string.lower(tostring(contract.allowedSocialGroups[i] or ""))

		if (allowedGroup ~= "" and socialGroup == allowedGroup) then
			return true
		end
	end

	for i = 1, #(contract.allowedFactions or {}), 1 do
		local allowedFaction = string.lower(tostring(contract.allowedFactions[i] or ""))

		if (allowedFaction ~= "" and factionString == allowedFaction) then
			return true
		end
	end

	for i = 1, #contract.allowedTemplates, 1 do
		local allowed = string.lower(tostring(contract.allowedTemplates[i] or ""))

		if (allowed ~= "") then
			for j = 1, #matchStrings, 1 do
				if (string.find(matchStrings[j], allowed, 1, true) ~= nil) then
					return true
				end
			end
		end
	end

	return false
end

function GalaxyCombatBoard:notifyKilledCreature(pPlayer, pVictim)
	if (pPlayer == nil or pVictim == nil) then
		return 0
	end

	local contract = self:getStoredContract(pPlayer)
	if (contract == nil or contract.isReady) then
		return 0
	end

	if (not self:isVictimAllowed(contract, pVictim)) then
		return 0
	end

	local newCount = contract.currentKills + 1
	if (newCount > contract.requiredKills) then
		newCount = contract.requiredKills
	end

	self:setNumber(pPlayer, "current_kills", newCount)
	CreatureObject(pPlayer):sendSystemMessage("Progress: " .. newCount .. " / " .. contract.requiredKills .. " targets eliminated")

	if (newCount >= contract.requiredKills) then
		self:setNumber(pPlayer, "contract_ready", 1)
		dropObserver(KILLEDCREATURE, self.screenplayName, "notifyKilledCreature", pPlayer)
		CreatureObject(pPlayer):sendSystemMessage("Contract complete. Return to the Galaxy Combat Board terminal.")
	end

	return 0
end

function GalaxyCombatBoard:completeContract(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	local contract = self:getStoredContract(pPlayer)

	if (contract == nil) then
		CreatureObject(pPlayer):sendSystemMessage("You do not have an active contract.")
		return false
	end

	if (not contract.isReady) then
		CreatureObject(pPlayer):sendSystemMessage("You have not completed your current contract yet.")
		return false
	end

	CreatureObject(pPlayer):addBankCredits(contract.rewardCredits, true)

	-- TODO: Apply cooldown timestamp here when cooldown rules are finalized.
	self:setNumber(pPlayer, "cooldown_placeholder", 0)

	self:clearContractData(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("Contract completed. Reward granted: " .. contract.rewardCredits .. " credits.")
	return true
end

function GalaxyCombatBoard:abandonContract(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	if (not self:hasActiveContract(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("You do not have an active contract to abandon.")
		return false
	end

	self:clearContractData(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("Your active Galaxy Combat Board contract has been abandoned.")
	return true
end
