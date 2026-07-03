-- Mandalorian Daily Bounty Mission Fob Menu Component
-- Handles right-click interaction with the daily bounty fob

MandoDailyBountyFobMenuComponent = {}

function MandoDailyBountyFobMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	if (pPlayer == nil or pSceneObject == nil) then
		return
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil) then
		return
	end

	-- Check if player is eligible (Mandalorian Tribesman)
	if (not MandoWayOfLife:isMandoTribesman(pPlayer)) then
		return
	end

	-- Add menu options
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)
	menuResponse:addRadialMenuItem(120, 3, "Mission Status")
	menuResponse:addRadialMenuItem(121, 3, "Accept Next Mission")
end

function MandoDailyBountyFobMenuComponent:handleObjectMenuSelect(pObject, pPlayer, selectedID)
	if (pPlayer == nil or pObject == nil) then
		return 0
	end

	-- Check eligibility
	if (not MandoWayOfLife:isMandoTribesman(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("Only Mandalorian Tribesmen may use this device.")
		return 0
	end

	if (selectedID == 120) then
		-- Show mission status
		MandoWayOfLife:showDailyBountyStatus(pPlayer)
	elseif (selectedID == 121) then
		-- Accept next mission
		local ok, msg = MandoWayOfLife:tryAcceptDailyBountyMission(pPlayer)
		CreatureObject(pPlayer):sendSystemMessage(msg)
	end

	return 0
end
