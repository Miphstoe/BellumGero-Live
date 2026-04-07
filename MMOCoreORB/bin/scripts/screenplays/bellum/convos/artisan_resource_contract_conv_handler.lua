ArtisanResourceContractConvoHandler = conv_handler:new {}

function ArtisanResourceContractConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	local convoTemplate = LuaConversationTemplate(pConvTemplate)

	if (pPlayer == nil) then
		return convoTemplate:getScreen("arc_hub")
	end

	return convoTemplate:getScreen("arc_hub")
end

function ArtisanResourceContractConvoHandler:getScreenplay()
	if (ArtisanResourceContract ~= nil) then
		return ArtisanResourceContract
	end

	return nil
end

function ArtisanResourceContractConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pConvScreen == nil) then
		if (pPlayer ~= nil) then
			CreatureObject(pPlayer):sendSystemMessage("Unable to open the procurement ledger. Please try again.")
		end
		return pConvScreen
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	if (screenID == "arc_request_contract") then
		return self:handleRequestContract(pConvScreen, pPlayer)
	elseif (screenID == "arc_view_contract") then
		return self:handleViewContract(pConvScreen, pPlayer)
	elseif (screenID == "arc_submit_all") then
		return self:handleSubmitAll(pConvScreen, pPlayer)
	elseif (screenID == "arc_submit_obj_1") then
		return self:handleSubmitObjective(pConvScreen, pPlayer, 1)
	elseif (screenID == "arc_submit_obj_2") then
		return self:handleSubmitObjective(pConvScreen, pPlayer, 2)
	elseif (screenID == "arc_submit_obj_3") then
		return self:handleSubmitObjective(pConvScreen, pPlayer, 3)
	elseif (screenID == "arc_submit_obj_4") then
		return self:handleSubmitObjective(pConvScreen, pPlayer, 4)
	elseif (screenID == "arc_submit_obj_5") then
		return self:handleSubmitObjective(pConvScreen, pPlayer, 5)
	elseif (screenID == "arc_reset_contract") then
		return self:handleResetContract(pConvScreen, pPlayer)
	elseif (screenID == "arc_reset_status") then
		return self:handleResetStatus(pConvScreen, pPlayer)
	elseif (screenID == "arc_rules") then
		return self:handleRules(pConvScreen, pPlayer)
	end

	return pConvScreen
end

function ArtisanResourceContractConvoHandler:cloneScreen(pConvScreen)
	local screen = LuaConversationScreen(pConvScreen)
	local pClonedScreen = screen:cloneScreen()
	local cloned = LuaConversationScreen(pClonedScreen)

	return pClonedScreen, cloned
end

function ArtisanResourceContractConvoHandler:sendResponse(pPlayer, clonedScreen, message)
	if (message == nil or message == "") then
		message = "The procurement ledger could not process that request. Please try again."
	end

	if (pPlayer ~= nil) then
		local player = CreatureObject(pPlayer)
		local sentAny = false

		for line in string.gmatch(message, "([^\n]+)") do
			if (line ~= nil and line ~= "") then
				player:sendSystemMessage(line)
				sentAny = true
			end
		end

		if (not sentAny) then
			player:sendSystemMessage(message)
		end
	end

	local summary = message
	local newlineStart, newlineEnd = string.find(summary, "\n")

	if (newlineStart ~= nil) then
		summary = string.sub(summary, 1, newlineStart - 1)
	end

	if (string.len(summary) > 220) then
		summary = string.sub(summary, 1, 217) .. "..."
	end

	if (summary ~= message) then
		summary = summary .. "\n\nFull contract details have been sent to your chat window."
	end

	clonedScreen:setCustomDialogText(summary)
end

function ArtisanResourceContractConvoHandler:handleRequestContract(pConvScreen, pPlayer)
	local pClonedScreen, cloned = self:cloneScreen(pConvScreen)
	local screenplay = self:getScreenplay()

	if (screenplay == nil) then
		self:sendResponse(pPlayer, cloned, "Artisan Resource Contract is currently unavailable.")
		return pClonedScreen
	end

	if (pPlayer ~= nil) then
		CreatureObject(pPlayer):sendSystemMessage("Processing contract request...")
	end

	local ok, success, message = pcall(function()
		return screenplay:startContract(pPlayer)
	end)

	if (not ok) then
		message = "Error while generating your contract: " .. tostring(success)
	end

	self:sendResponse(pPlayer, cloned, message)
	return pClonedScreen
end

function ArtisanResourceContractConvoHandler:handleViewContract(pConvScreen, pPlayer)
	local pClonedScreen, cloned = self:cloneScreen(pConvScreen)
	local screenplay = self:getScreenplay()

	if (screenplay == nil) then
		self:sendResponse(pPlayer, cloned, "Artisan Resource Contract is currently unavailable.")
		return pClonedScreen
	end

	if (pPlayer ~= nil) then
		CreatureObject(pPlayer):sendSystemMessage("Loading current contract status...")
	end

	local ok, message = pcall(function()
		return screenplay:getProgressReportText(pPlayer)
	end)

	if (not ok) then
		message = "Unable to read your current contract status: " .. tostring(message)
	end

	self:sendResponse(pPlayer, cloned, message)
	return pClonedScreen
end

function ArtisanResourceContractConvoHandler:handleSubmitAll(pConvScreen, pPlayer)
	local pClonedScreen, cloned = self:cloneScreen(pConvScreen)
	local screenplay = self:getScreenplay()

	if (screenplay == nil) then
		self:sendResponse(pPlayer, cloned, "Artisan Resource Contract is currently unavailable.")
		return pClonedScreen
	end

	if (pPlayer ~= nil) then
		CreatureObject(pPlayer):sendSystemMessage("Processing shipment turn-in...")
	end

	local ok, success, message = pcall(function()
		return screenplay:submitAllObjectives(pPlayer)
	end)

	if (not ok) then
		message = "Error while processing shipment turn-in: " .. tostring(success)
	end

	self:sendResponse(pPlayer, cloned, message)
	return pClonedScreen
end

function ArtisanResourceContractConvoHandler:handleSubmitObjective(pConvScreen, pPlayer, objectiveIndex)
	local pClonedScreen, cloned = self:cloneScreen(pConvScreen)
	local screenplay = self:getScreenplay()

	if (screenplay == nil) then
		self:sendResponse(pPlayer, cloned, "Artisan Resource Contract is currently unavailable.")
		return pClonedScreen
	end

	if (pPlayer ~= nil) then
		CreatureObject(pPlayer):sendSystemMessage("Processing objective " .. tostring(objectiveIndex) .. " shipment...")
	end

	local ok, success, message = pcall(function()
		return screenplay:submitObjective(pPlayer, objectiveIndex)
	end)

	if (not ok) then
		message = "Error while processing that objective shipment: " .. tostring(success)
	end

	self:sendResponse(pPlayer, cloned, message)
	return pClonedScreen
end

function ArtisanResourceContractConvoHandler:handleResetContract(pConvScreen, pPlayer)
	local pClonedScreen, cloned = self:cloneScreen(pConvScreen)
	local screenplay = self:getScreenplay()

	if (screenplay == nil) then
		self:sendResponse(pPlayer, cloned, "Artisan Resource Contract is currently unavailable.")
		return pClonedScreen
	end

	if (pPlayer ~= nil) then
		CreatureObject(pPlayer):sendSystemMessage("Processing contract reset...")
	end

	local ok, success, message = pcall(function()
		return screenplay:resetContract(pPlayer)
	end)

	if (not ok) then
		message = "Error while reissuing your contract: " .. tostring(success)
	end

	self:sendResponse(pPlayer, cloned, message)
	return pClonedScreen
end

function ArtisanResourceContractConvoHandler:handleResetStatus(pConvScreen, pPlayer)
	local pClonedScreen, cloned = self:cloneScreen(pConvScreen)
	local screenplay = self:getScreenplay()

	if (screenplay == nil) then
		self:sendResponse(pPlayer, cloned, "Artisan Resource Contract is currently unavailable.")
		return pClonedScreen
	end

	local ok, message = pcall(function()
		return screenplay:getResetStatusText(pPlayer)
	end)

	if (not ok) then
		message = "Unable to read your contract reset status. Please try again."
	end

	self:sendResponse(pPlayer, cloned, message)
	return pClonedScreen
end

function ArtisanResourceContractConvoHandler:handleRules(pConvScreen, pPlayer)
	local pClonedScreen, cloned = self:cloneScreen(pConvScreen)
	local screenplay = self:getScreenplay()

	if (screenplay == nil) then
		self:sendResponse(pPlayer, cloned, "Artisan Resource Contract is currently unavailable.")
		return pClonedScreen
	end

	local ok, message = pcall(function()
		return screenplay:getRulesText()
	end)

	if (not ok) then
		message = "Unable to retrieve contract rules. Please try again."
	end

	self:sendResponse(pPlayer, cloned, message)
	return pClonedScreen
end
