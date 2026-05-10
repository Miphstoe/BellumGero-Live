PaintingExchangeConvoHandler = conv_handler:new {}

function PaintingExchangeConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	local convoTemplate = LuaConversationTemplate(pConvTemplate)
	return convoTemplate:getScreen("pec_hub")
end

function PaintingExchangeConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pConvScreen == nil) then
		if (pPlayer ~= nil) then
			CreatureObject(pPlayer):sendSystemMessage("Unable to open the exchange menu. Please try again.")
		end
		return pConvScreen
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	if (screenID == "pec_start_exchange") then
		return self:handleStartExchange(pConvScreen, pPlayer)
	end

	if (screenID == "pec_start_premium_exchange") then
		return self:handleStartPremiumExchange(pConvScreen, pPlayer)
	end

	return pConvScreen
end

function PaintingExchangeConvoHandler:cloneScreen(pConvScreen)
	local screen = LuaConversationScreen(pConvScreen)
	local pCloned = screen:cloneScreen()
	return pCloned, LuaConversationScreen(pCloned)
end

function PaintingExchangeConvoHandler:handleStartExchange(pConvScreen, pPlayer)
	local pCloned, cloned = self:cloneScreen(pConvScreen)

	if (PaintingExchangeVendor == nil) then
		cloned:setCustomDialogText("The exchange system is temporarily unavailable. Please try again later.")
		return pCloned
	end

	if (pPlayer == nil) then
		return pCloned
	end

	local count = PaintingExchangeVendor:countEligiblePaintings(pPlayer)
	local required = PaintingExchangeVendor.REQUIRED_PAINTINGS
	local playerID = tostring(SceneObject(pPlayer):getObjectID())

	print("[PaintingExchangeVendor] Player " .. playerID .. " started exchange with " .. tostring(count) .. " eligible paintings")

	if (count < required) then
		local needed = required - count
		cloned:setCustomDialogText(
			"You need " .. tostring(required) .. " eligible paintings in your main inventory to complete an exchange. " ..
			"You currently have " .. tostring(count) .. ". You need " .. tostring(needed) .. " more."
		)
		print("[PaintingExchangeVendor] Player " .. playerID .. " lacks paintings: has " .. tostring(count) .. ", needs " .. tostring(required))
		return pCloned
	end

	-- Player has enough paintings — open the SUI reward selection.
	-- The conversation screen text is updated as a fallback in case SUI fails to send.
	cloned:setCustomDialogText("You have " .. tostring(count) .. " eligible paintings. Please select your reward from the list.")

	createEvent(100, "PaintingExchangeVendor", "showRewardSelection", pPlayer, "")

	return pCloned
end

function PaintingExchangeConvoHandler:handleStartPremiumExchange(pConvScreen, pPlayer)
	local pCloned, cloned = self:cloneScreen(pConvScreen)

	if (PaintingExchangeVendor == nil) then
		cloned:setCustomDialogText("The exchange system is temporarily unavailable. Please try again later.")
		return pCloned
	end

	if (pPlayer == nil) then
		return pCloned
	end

	local count = PaintingExchangeVendor:countEligiblePaintings(pPlayer)
	local required = PaintingExchangeVendor.REQUIRED_PAINTINGS_PREMIUM
	local playerID = tostring(SceneObject(pPlayer):getObjectID())

	print("[PaintingExchangeVendor] Player " .. playerID .. " started premium exchange with " .. tostring(count) .. " eligible paintings")

	if (count < required) then
		local needed = required - count
		cloned:setCustomDialogText(
			"You need " .. tostring(required) .. " eligible paintings in your main inventory for this exchange. " ..
			"You currently have " .. tostring(count) .. ". You need " .. tostring(needed) .. " more."
		)
		print("[PaintingExchangeVendor] Player " .. playerID .. " lacks paintings for premium exchange: has " .. tostring(count) .. ", needs " .. tostring(required))
		return pCloned
	end

	cloned:setCustomDialogText("You have " .. tostring(count) .. " eligible paintings. Please select your rare reward from the list.")

	createEvent(100, "PaintingExchangeVendor", "showPremiumRewardSelection", pPlayer, "")

	return pCloned
end
