SmugglerDeliveryNpcs = ScreenPlay:new {
	screenplayName = "SmugglerDeliveryNpcs",
	numberOfActs = 1,
}

registerScreenPlay("SmugglerDeliveryNpcs", true)

function SmugglerDeliveryNpcs:start()
	if (SmugglerDeliveryQuest == nil) then
		return
	end

	for _, destination in pairs(SmugglerDeliveryQuest.destinations) do
		self:spawnReceiver(destination)
	end
end

function SmugglerDeliveryNpcs:spawnReceiver(destination)
	local pNpc = spawnMobile(destination.planet, destination.template, 0, destination.x, destination.z, destination.y, destination.heading, destination.cell)

	if (pNpc == nil) then
		return
	end

	CreatureObject(pNpc):setPvpStatusBitmask(0)
	CreatureObject(pNpc):setOptionsBitmask(AIENABLED + CONVERSABLE + INVULNERABLE)
	SceneObject(pNpc):setCustomObjectName(destination.name)
	AiAgent(pNpc):setConvoTemplate(SmugglerDeliveryQuest.RECEIVER_CONVO_TEMPLATE)
	AiAgent(pNpc):addObjectFlag(AI_STATIC)
	writeData(SceneObject(pNpc):getObjectID() .. ":SmugglerDeliveryQuest:receiverKey", destination.key)

	if (SmugglerDeliveryQuest.soSetVar ~= nil) then
		SmugglerDeliveryQuest:soSetVar(pNpc, "smugglerReceiverKey", destination.key)
	end
end

SmugglerReceiverConvoHandler = conv_handler:new {}

function SmugglerReceiverConvoHandler:getReceiverKey(pNpc)
	if (pNpc == nil) then
		return ""
	end

	local receiverKey = tostring(readData(SceneObject(pNpc):getObjectID() .. ":SmugglerDeliveryQuest:receiverKey") or "")

	if (receiverKey ~= "" and receiverKey ~= "0") then
		return receiverKey
	end

	if (SmugglerDeliveryQuest ~= nil and SmugglerDeliveryQuest.soGetVar ~= nil) then
		receiverKey = tostring(SmugglerDeliveryQuest:soGetVar(pNpc, "smugglerReceiverKey") or "")

		if (receiverKey ~= "" and receiverKey ~= "0" and SmugglerDeliveryQuest:getDestination(receiverKey) ~= nil) then
			return receiverKey
		end
	end

	if (SmugglerDeliveryQuest == nil) then
		return ""
	end

	local zoneName = tostring(SceneObject(pNpc):getZoneName() or "")
	local customName = string.lower(tostring(SceneObject(pNpc):getCustomObjectName() or ""))
	local worldX = tonumber(SceneObject(pNpc):getWorldPositionX()) or 0
	local worldY = tonumber(SceneObject(pNpc):getWorldPositionY()) or 0

	for key, destination in pairs(SmugglerDeliveryQuest.destinations) do
		if (destination.planet == zoneName and string.lower(destination.name) == customName) then
			return key
		end
	end

	for key, destination in pairs(SmugglerDeliveryQuest.destinations) do
		if (destination.planet == zoneName) then
			local dx = worldX - destination.x
			local dy = worldY - destination.y

			if ((dx * dx) + (dy * dy) <= (32 * 32)) then
				return key
			end
		end
	end

	return ""
end

function SmugglerReceiverConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	local convoTemplate = LuaConversationTemplate(pConvTemplate)

	if (pPlayer == nil or SmugglerDeliveryQuest == nil) then
		return convoTemplate:getScreen("receiver_idle")
	end

	if (not SmugglerDeliveryQuest:isActive(pPlayer)) then
		return convoTemplate:getScreen("receiver_idle")
	end

	local receiverKey = self:getReceiverKey(pNpc)
	local missionKey = SmugglerDeliveryQuest:getString(pPlayer, SmugglerDeliveryQuest.STATE_KEYS.destinationKey)

	if (receiverKey == missionKey) then
		return convoTemplate:getScreen("receiver_ready")
	end

	return convoTemplate:getScreen("receiver_suspicious")
end

function SmugglerReceiverConvoHandler:cloneScreen(pConvScreen)
	local screen = LuaConversationScreen(pConvScreen)
	local pCloned = screen:cloneScreen()
	return pCloned, LuaConversationScreen(pCloned)
end

function SmugglerReceiverConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pConvScreen == nil or pPlayer == nil or SmugglerDeliveryQuest == nil) then
		return pConvScreen
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenId = screen:getScreenID()
	local receiverKey = self:getReceiverKey(pNpc)

	if (screenId == "receiver_handoff") then
		local pCloned, cloned = self:cloneScreen(pConvScreen)
		local _, message = SmugglerDeliveryQuest:completeMission(pPlayer, receiverKey)
		cloned:setCustomDialogText(message)
		return pCloned
	end

	if (screenId == "receiver_wrong") then
		local pCloned, cloned = self:cloneScreen(pConvScreen)
		SmugglerDeliveryQuest:failMission(pPlayer, "Wrong NPC turn-in. Your cargo is compromised.", true)
		cloned:setCustomDialogText("You're late, and worse, you're talking to the wrong person. The run is dead.")
		return pCloned
	end

	return pConvScreen
end
