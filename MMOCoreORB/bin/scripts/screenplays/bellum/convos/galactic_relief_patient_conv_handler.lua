GalacticReliefPatientConvoHandler = conv_handler:new {}

function GalacticReliefPatientConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)
	local pScreen = convoTemplate:getScreen("patient_hub")
	local screen = LuaConversationScreen(pScreen)
	local pCloned = screen:cloneScreen()
	local cloned = LuaConversationScreen(pCloned)
	local text = GalacticReliefEffort:getPatientPromptText(pPlayer, pNpc)
	cloned:setCustomDialogText(text)
	return pCloned
end

function GalacticReliefPatientConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pNpc == nil or pConvScreen == nil) then
		return pConvScreen
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	if (screenID == "treat_wounds") then
		local success, message = GalacticReliefEffort:attemptConversationTreatment(pPlayer, pNpc, "wound")
		return self:buildScreen(pConvTemplate, "treat_wounds", message)
	elseif (screenID == "treat_damage") then
		local success, message = GalacticReliefEffort:attemptConversationTreatment(pPlayer, pNpc, "damage")
		return self:buildScreen(pConvTemplate, "treat_damage", message)
	end

	return pConvScreen
end

function GalacticReliefPatientConvoHandler:buildScreen(pConvTemplate, screenName, text)
	local convoTemplate = LuaConversationTemplate(pConvTemplate)
	local pScreen = convoTemplate:getScreen(screenName)
	local screen = LuaConversationScreen(pScreen)
	local pCloned = screen:cloneScreen()
	local cloned = LuaConversationScreen(pCloned)
	cloned:setCustomDialogText(text)
	return pCloned
end
