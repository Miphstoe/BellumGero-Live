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
	local count = MandoWayOfLife:getDailyBountyCount(pPlayer)
	if (count == 0) then
		menuResponse:addRadialMenuItem(121, 3, "Begin Daily Hunt")
	elseif (count < MandoWayOfLife.DAILY_BOUNTY_MAX_MISSIONS and MandoWayOfLife:getDailyBountyReadyTier(pPlayer) == count) then
		menuResponse:addRadialMenuItem(122, 3, "Recall Guild Contact")
	end
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
		local ok, msg = MandoWayOfLife:tryAcceptDailyBountyMission(pPlayer, "fob")
		CreatureObject(pPlayer):sendSystemMessage(msg)
	elseif (selectedID == 122) then
		local count = MandoWayOfLife:getDailyBountyCount(pPlayer)
		if (count > 0 and count < MandoWayOfLife.DAILY_BOUNTY_MAX_MISSIONS and MandoWayOfLife:getDailyBountyReadyTier(pPlayer) == count) then
			MandoDailyHoloStory:onCampCompleted(pPlayer, count)
		end
	end

	return 0
end
