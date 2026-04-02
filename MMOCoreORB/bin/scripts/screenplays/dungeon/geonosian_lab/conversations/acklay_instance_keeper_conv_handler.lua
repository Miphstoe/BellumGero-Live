acklay_instance_keeper_conv_handler = conv_handler:new {}

function acklay_instance_keeper_conv_handler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	local convoTemplate = LuaConversationTemplate(pConvTemplate)
	return convoTemplate:getScreen("intro")
end

function acklay_instance_keeper_conv_handler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pConvScreen == nil) then
		return pConvScreen
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenId = screen:getScreenID()

	if (screenId ~= "enter_instance") then
		return pConvScreen
	end

	local clonedScreen = screen:cloneScreen()
	local conversation = LuaConversationScreen(clonedScreen)
	local message = "The Acklay challenge is currently unavailable."

	if (AcklayPrivateInstance ~= nil and AcklayPrivateInstance.handleConversationEntryRequest ~= nil) then
		message = AcklayPrivateInstance:handleConversationEntryRequest(pPlayer)
	end

	conversation:setCustomDialogText(message)
	return clonedScreen
end
