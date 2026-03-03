artisan_procurement_conv_handler = conv_handler:new {}

function artisan_procurement_conv_handler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if pConvScreen == nil then
		return pConvScreen
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenId = screen:getScreenID()

	if screenId == "procurement_contract_status" then
		return self:handleStatus(pConvScreen, pPlayer)
	end

	if screenId == "procurement_submit_contract" then
		return self:handleTurnIn(pConvScreen, pPlayer)
	end

	return pConvScreen
end

function artisan_procurement_conv_handler:getScreenplay()
	if ArtisanProcurementVendor ~= nil then
		return ArtisanProcurementVendor
	end

	return nil
end

function artisan_procurement_conv_handler:handleStatus(pConvScreen, pPlayer)
	local screen = LuaConversationScreen(pConvScreen)
	local screenplay = self:getScreenplay()

	if screenplay == nil then
		screen:setCustomDialogText("Artisan Procurement is currently unavailable.")
		if pPlayer ~= nil then
			CreatureObject(pPlayer):sendSystemMessage("Artisan Procurement is currently unavailable.")
		end
		return pConvScreen
	end

	local ok, text = pcall(function()
		return screenplay:getStatusDialogText(pPlayer)
	end)

	if not ok or text == nil or text == "" then
		text = "Unable to read current contract status. Please try again."
	end

	screen:setCustomDialogText(text)

	if pPlayer ~= nil then
		CreatureObject(pPlayer):sendSystemMessage(text)
	end

	return pConvScreen
end

function artisan_procurement_conv_handler:handleTurnIn(pConvScreen, pPlayer)
	local screen = LuaConversationScreen(pConvScreen)
	local screenplay = self:getScreenplay()

	if screenplay == nil then
		screen:setCustomDialogText("Artisan Procurement is currently unavailable.")
		if pPlayer ~= nil then
			CreatureObject(pPlayer):sendSystemMessage("Artisan Procurement is currently unavailable.")
		end
		return pConvScreen
	end

	local ok, success, message = pcall(function()
		local turnInSuccess, turnInMessage = screenplay:handleTurnIn(pPlayer)
		return turnInSuccess, turnInMessage
	end)

	if not ok then
		message = "Error while processing contract turn-in. Please try again."
	end

	if message == nil or message == "" then
		if success then
			message = "Contract completed."
		else
			message = "Contract turn-in failed."
		end
	end

	screen:setCustomDialogText(message)
	if pPlayer ~= nil then
		CreatureObject(pPlayer):sendSystemMessage(message)
	end

	return pConvScreen
end
