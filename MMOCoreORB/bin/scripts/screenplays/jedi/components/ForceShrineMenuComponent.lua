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

	if (CreatureObject(pPlayer):isJediSeclusionEligible()) then
		menuResponse:addRadialMenuItem(122, 3, "Toggle PvE Seclusion")
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
	elseif (selectedID == 122) then
		self:showSeclusionChoice(pObject, pPlayer)
	end

	return 0
end

function ForceShrineMenuComponent:doMeditate(pObject, pPlayer)
	if (tonumber(readScreenPlayData(pPlayer, "KnightTrials", "completedTrials")) == 1 and not CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_03")) then
		KnightTrials:resetKnightTrialProgression(pPlayer)
	end

	if (not CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_02") and CreatureObject(pPlayer):hasScreenPlayState(32, "VillageJediProgression")) then
		-- New 5-tier Padawan system: Always call startPadawanTrials
		-- It handles all phase progression internally
		PadawanTrials:startPadawanTrials(pObject, pPlayer)
	else
		-- Check if player has Padawan rank (rank_02) - if so, show Knight Trials
		if (CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_02")) then
			-- Check if player is eligible for Knight Trials (206+ skill points, 2+ trees)
			if (JediTrials:isEligibleForKnightTrials(pPlayer)) then
				-- Check if player has activated Knight Trials at shrine
				-- We check for the "activatedAtShrine" flag specifically, not just "startedTrials"
				-- This prevents confusion with the old auto-start system
				local activatedAtShrine = tonumber(readScreenPlayData(pPlayer, "KnightTrials", "activatedAtShrine"))

				if (activatedAtShrine ~= 1) then
					-- Player hasn't activated at shrine yet - show activation dialog
					KnightTrials:showKnightTrialsActivationDialog(pObject, pPlayer)
				else
					-- Player has activated - register observer and show progress
					printLuaError("ForceShrineMenuComponent:doMeditate - Registering observer for player: " .. SceneObject(pPlayer):getCustomObjectName())
					-- First drop any existing observer to prevent duplicates
					dropObserver(KILLEDCREATURE, "KnightTrials", "notifyKilledForPoints", pPlayer)
					-- Now register the observer
					createObserver(KILLEDCREATURE, "KnightTrials", "notifyKilledForPoints", pPlayer)

					-- Show the progress box for Knight Trials
					KnightTrials:showCurrentTrial(pPlayer)
				end
			else
				-- Not eligible yet - show faction-specific guidance when neutral, otherwise generic requirements
				local playerFaction = CreatureObject(pPlayer):getFaction()
				local sui = SuiMessageBox.new("JediTrials", "emptyCallback")
				sui.setTitle("Knight Trials")
				if (playerFaction ~= FACTIONREBEL and playerFaction ~= FACTIONIMPERIAL) then
					sui.setPrompt("You must choose a faction before beginning the Knight Trials.\n\nVisit a faction recruiter and align with either:\n- Rebel\n- Imperial\n\nOnce aligned, return to a Force Shrine to begin your trials.")
				else
					sui.setPrompt("You are not yet eligible for the Knight Trials.\n\nYou must:\n- Be a Jedi Padawan (Rank 02)\n- Have at least 206 Jedi skill points invested\n- Have completed at least 2 full Force discipline trees\n- Be aligned with the Rebel or Imperial faction\n\nContinue your training, young Padawan.")
				end
				sui.setOkButtonText("Close")
				sui.sendTo(pPlayer)
			end
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

-- ============================================================
-- Jedi PvE Seclusion. Only opens a confirmation SUI here -- state is never
-- changed until the player confirms, and is fully re-validated server-side
-- at that point (see JediSeclusionManager::requestToggle in C++).
-- ============================================================
function ForceShrineMenuComponent:showSeclusionChoice(pObject, pPlayer)
	if (not CreatureObject(pPlayer):isJediSeclusionEligible()) then
		CreatureObject(pPlayer):sendSystemMessage("This choice is available only after becoming a Padawan.")
		return
	end

	-- Remember which shrine this request originated at so the confirm
	-- callback (which only receives pPlayer/pSui/eventIndex/args) can pass
	-- it back to the native shrine-proximity/template revalidation.
	writeScreenPlayData(pPlayer, "JediSeclusion", "pendingShrineID", tostring(SceneObject(pObject):getObjectID()))

	local sui = SuiMessageBox.new("ForceShrineMenuComponent", "seclusionConfirmCallback")
	sui.setTargetNetworkId(SceneObject(pPlayer):getObjectID())

	if (CreatureObject(pPlayer):isJediSecluded()) then
		sui.setTitle("Return to the Galaxy")
		sui.setPrompt(
			"You have chosen to leave Seclusion and once again accept the risks associated with openly walking the path of the Jedi.\n\n" ..
			"Returning to Open status may once again make you eligible for Jedi PvP and Bounty Hunter systems.\n\n" ..
			"Leave PvE Seclusion?"
		)
		sui.setOkButtonText("Return to Open Status")
	else
		sui.setTitle("Path of Seclusion")
		sui.setPrompt(
			"You have chosen to withdraw from the conflicts of the galaxy.\n\n" ..
			"While following the Path of Seclusion:\n" ..
			"- You cannot participate in Jedi-versus-player bounty hunting.\n" ..
			"- You cannot be selected as a Jedi bounty target.\n" ..
			"- You cannot intentionally initiate hostile PvP against another player.\n" ..
			"- Jedi PvP systems will treat you as a PvE Jedi.\n" ..
			"- Your choice persists through logout and server restart.\n\n" ..
			"Choosing Seclusion represents a commitment to withdraw from galactic conflict.\n\n" ..
			"Enter PvE Seclusion?"
		)
		sui.setOkButtonText("Enter Seclusion")
	end

	sui.setCancelButtonText("Cancel")
	sui.sendTo(pPlayer)
end

function ForceShrineMenuComponent:seclusionConfirmCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil) then
		return
	end

	local shrineID = tonumber(readScreenPlayData(pPlayer, "JediSeclusion", "pendingShrineID"))
	deleteScreenPlayData(pPlayer, "JediSeclusion", "pendingShrineID")

	if (eventIndex ~= 0) then
		return -- Cancel or window closed
	end

	local pShrine = shrineID ~= nil and shrineID ~= 0 and getSceneObject(shrineID) or nil

	if (pShrine == nil) then
		CreatureObject(pPlayer):sendSystemMessage("You must be at a Force Shrine to do that.")
		return
	end

	-- All eligibility/cooldown/combat/bounty/faction checks are re-run fresh
	-- here server-side; the result and player-facing message are handled
	-- entirely by JediSeclusionManager on the native side.
	CreatureObject(pPlayer):requestJediSeclusionToggle(pShrine)
end
