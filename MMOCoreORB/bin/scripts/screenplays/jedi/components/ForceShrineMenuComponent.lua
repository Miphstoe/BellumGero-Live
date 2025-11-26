ForceShrineMenuComponent = {}

local function give_socketed(pInventory, template, sockets)
    local pItem = giveItem(pInventory, template, -1)
    if pItem ~= nil then
        TangibleObject(pItem):setMaxSockets(sockets)
    end
    return pItem
end

function ForceShrineMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)

	if (CreatureObject(pPlayer):hasSkill("force_title_jedi_novice")) then
		menuResponse:addRadialMenuItem(120, 3, "@jedi_trials:meditate") -- Meditate
	end

	if (CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_02")) then
		menuResponse:addRadialMenuItem(121, 3, "@force_rank:recover_jedi_items") -- Recover Jedi Items
	end

end

function ForceShrineMenuComponent:handleObjectMenuSelect(pObject, pPlayer, selectedID)
	if (pPlayer == nil or pObject == nil) then
		return 0
	end

	if (selectedID == 120 and CreatureObject(pPlayer):hasSkill("force_title_jedi_novice")) then
		if (CreatureObject(pPlayer):getPosture() ~= CROUCHED) then
			CreatureObject(pPlayer):sendSystemMessage("@jedi_trials:show_respect") -- Must respect
		else
			self:doMeditate(pObject, pPlayer)
		end
	elseif (selectedID == 121 and CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_02")) then
		self:recoverRobe(pPlayer)
	end

	return 0
end

function ForceShrineMenuComponent:doMeditate(pObject, pPlayer)
	if (tonumber(readScreenPlayData(pPlayer, "KnightTrials", "completedTrials")) == 1 and not CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_03")) then
		KnightTrials:resetCompletedTrialsToStart(pPlayer)
	end

	if (not CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_02") and CreatureObject(pPlayer):hasScreenPlayState(32, "VillageJediProgression")) then
		-- New 5-tier Padawan system: Always call startPadawanTrials
		-- It handles all phase progression internally
		PadawanTrials:startPadawanTrials(pObject, pPlayer)
	else
		-- Check if player has Padawan rank (rank_02) - if so, show Knight Trials
		if (CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_02")) then
			local currentPoints = JediTrials:getKnightTrialPoints(pPlayer)
			local currentTrial = JediTrials:getCurrentTrial(pPlayer)
			local trialsCompleted = JediTrials:getTrialsCompleted(pPlayer)

			-- Register the observer to ensure points are tracked
			printLuaError("ForceShrineMenuComponent:doMeditate - Registering observer for player: " .. SceneObject(pPlayer):getCustomObjectName())
			createObserver(KILLEDCREATURE, "KnightTrials", "notifyKilledForPoints", pPlayer)

			-- Always show the progress box for Knight Trials
			KnightTrials:showCurrentTrial(pPlayer)
		else
			CreatureObject(pPlayer):sendSystemMessage("@jedi_trials:force_shrine_wisdom_" .. getRandomNumber(1, 15))
		end
	end
end

function ForceShrineMenuComponent:recoverRobe(pPlayer)
	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")

	if (pInventory == nil) then
		return
	end

	if (SceneObject(pInventory):isContainerFullRecursive()) then
		CreatureObject(pPlayer):sendSystemMessage("@jedi_spam:inventory_full_jedi_robe")
		return
	end

	if (CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_03")) then
		-- Rank 3+: Give Council-specific robe (light or dark jedi master robes)
		local councilType = JediTrials:getJediCouncil(pPlayer)
		local robeTemplate

		if (councilType == JediTrials.COUNCIL_LIGHT) then
			robeTemplate = "object/tangible/wearables/robe/robe_jedi_light_s01.iff"
		else
			robeTemplate = "object/tangible/wearables/robe/robe_jedi_dark_s01.iff"
		end

		local pItem = give_socketed(pInventory, robeTemplate, 4)
	else
		-- Rank 2 (Padawan): Give BOTH light and dark padawan robes
		give_socketed(pInventory, "object/tangible/wearables/robe/robe_jedi_padawan.iff", 4)

		-- Check if inventory has room for second robe
		if (not SceneObject(pInventory):isContainerFullRecursive()) then
			give_socketed(pInventory, "object/tangible/wearables/robe/robe_jedi_padawan_dark.iff", 4)
		end
	end

	CreatureObject(pPlayer):sendSystemMessage("@force_rank:items_recovered")
end
