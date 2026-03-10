LostHolocronCartographerConvoHandler = conv_handler:new {}

function LostHolocronCartographerConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)
	local state = LostHolocronCartographer:conversationState(pPlayer)

	if (state == "reward_pending") then
		return convoTemplate:getScreen("reward_pending")
	end

	if (state == "in_progress") then
		return convoTemplate:getScreen("in_progress")
	end

	if (state == "cooldown") then
		local pBaseScreen = convoTemplate:getScreen("cooldown")
		local baseScreen = LuaConversationScreen(pBaseScreen)
		local pCloned = baseScreen:cloneScreen()
		local cloned = LuaConversationScreen(pCloned)
		local remaining = LostHolocronCartographer:getRemainingCooldown(pPlayer)
		local durationText = LostHolocronCartographer:formatDurationWords(remaining)
		cloned:setCustomDialogText("The anomaly lattice needs time to recover. Return after your cooldown expires in " .. durationText .. ".")
		return pCloned
	end

	return convoTemplate:getScreen("intro")
end

function LostHolocronCartographerConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return pConvScreen
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	if (screenID == "accept_quest") then
		LostHolocronCartographer:startQuest(pPlayer)
	elseif (screenID == "refresh_waypoint") then
		LostHolocronCartographer:addOrUpdateStageWaypoint(pPlayer)
		CreatureObject(pPlayer):sendSystemMessage("Current anomaly waypoint refreshed.")
	elseif (screenID == "claim_reward") then
		LostHolocronCartographer:tryGrantFinalReward(pPlayer)
	end

	return pConvScreen
end
