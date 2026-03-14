-- Mandalorian Foundling Informant Conversation Handler
-- Routes based on assignment state: assign / already assigned / turn in / not done

MandoFoundlingInformantConvoHandler = conv_handler:new {}

function MandoFoundlingInformantConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil) then return nil end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)

	-- Verify this informant belongs to this player via global data
	local informantId = SceneObject(pNpc):getObjectID()
	local ownerId     = tonumber(readData("mando_way:informant:" .. informantId .. ":player")) or 0
	local playerId    = SceneObject(pPlayer):getObjectID()

	if (ownerId ~= playerId) then
		-- This informant belongs to a different player — show nothing
		return nil
	end

	local countingEnabled = MandoWayOfLife:readInt(pPlayer, "foundling.planetCountingEnabled")
	local planetDone      = MandoWayOfLife:readInt(pPlayer, "foundling.planetDone")

	if (countingEnabled == 1 and planetDone == 1) then
		-- Quota met — ready to turn in
		local index = MandoWayOfLife:readInt(pPlayer, "foundling.planetIndex")
		if (index >= 10) then
			return convoTemplate:getScreen("turnin_final")
		end
		return convoTemplate:getScreen("turnin")
	end

	if (countingEnabled == 1 and planetDone == 0) then
		-- Still working — offer update
		return convoTemplate:getScreen("already_assigned")
	end

	-- Not yet accepted assignment
	return convoTemplate:getScreen("intro")
end

function MandoFoundlingInformantConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then return pConvScreen end

	local screen   = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	if (screenID == "assign_confirm") then
		MandoWayOfLife:acceptPlanetAssignment(pPlayer)

	elseif (screenID == "check_turnin") then
		-- Redirect to correct screen in getInitialScreen logic above;
		-- if we reach here it means planetDone was not set — show not_done
		local convoTemplate = LuaConversationTemplate(pConvTemplate)
		if (MandoWayOfLife:readInt(pPlayer, "foundling.planetDone") ~= 1) then
			return convoTemplate:getScreen("not_done")
		end

	elseif (screenID == "turnin" or screenID == "turnin_final") then
		MandoWayOfLife:turnInPlanet(pPlayer)
	end

	return pConvScreen
end
