-- Arcon Farm Overseer: status text on the first screen, raid start on "overseer_start_raid".
TaanabArconOverseerConvoHandler = conv_handler:new {}

function TaanabArconOverseerConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil) then
		return nil
	end

	return self:buildScreen(pConvTemplate, "overseer_hub", TaanabNorulacRaidWorldBoss:getOverseerStatus())
end

function TaanabArconOverseerConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pNpc == nil or pConvScreen == nil) then
		return pConvScreen
	end

	if (LuaConversationScreen(pConvScreen):getScreenID() == "overseer_start_raid") then
		local _, message = TaanabNorulacRaidWorldBoss:startFromOverseer(pPlayer)
		return self:buildScreen(pConvTemplate, "overseer_start_raid", message)
	end

	return pConvScreen
end

function TaanabArconOverseerConvoHandler:buildScreen(pConvTemplate, screenName, text)
	local pScreen = LuaConversationTemplate(pConvTemplate):getScreen(screenName)
	local pCloned = LuaConversationScreen(pScreen):cloneScreen()
	LuaConversationScreen(pCloned):setCustomDialogText(text)
	return pCloned
end
