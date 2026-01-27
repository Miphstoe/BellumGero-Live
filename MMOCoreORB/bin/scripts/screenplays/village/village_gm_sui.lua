local Logger = require("utils.logger")

VillageGmSui = ScreenPlay:new {
	productionServer = false
}

function VillageGmSui:showMainPage(pPlayer)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil or not PlayerObject(pGhost):isPrivileged()) then
		local msg = SceneObject(pPlayer):getCustomObjectName() .. " ID: " .. SceneObject(pPlayer):getObjectID() .. " non Privileged player attempted to acces GMFSVillage -- VillageGmSui:showMainPage."
		Logger:log(msg, LT_WARNING)
		return
	end

	local curPhase = VillageJediManagerTownship:getCurrentPhase()
	local phaseID = VillageJediManagerTownship:getCurrentPhaseID()
	local nextPhaseChange = VillageJediManagerTownship.getNextPhaseChangeTime()
	local phaseTimeLeft = self:getPhaseDuration()

	local suiPrompt = " \\#pcontrast1 " .. "Current Phase:" .. " \\#pcontrast2 " .. curPhase .. " (id " .. phaseID .. ")\n" .. " \\#pcontrast1 " .. "Current Server Time:" .. " \\#pcontrast2 " .. os.date("%c") .. "\n"
	local suiPrompt = suiPrompt .. " \\#pcontrast1 " .. "Next Phase Change: " .. " \\#pcontrast2 " .. os.date("%c", nextPhaseChange)  .. "\n \\#pcontrast1 " .. "Phase Time Left: " .. " \\#pcontrast2 " .. phaseTimeLeft

	local pMaster = VillageJediManagerTownship:getMasterObject()

	if (pMaster ~= nil) then
		local playerTable = SceneObject(pMaster):getPlayersInRange(192)
		suiPrompt = suiPrompt .. "\n \\#pcontrast1 " .. "Players in Village: " .. " \\#pcontrast2 " .. #playerTable
	end

	local sui = SuiListBox.new("VillageGmSui", "mainCallback")
	sui.setTitle("Village GM Panel")
	sui.setPrompt(suiPrompt)

	sui.add("Lookup player by target", "playerLookupByTarget")
	sui.add("Lookup player by name", "playerLookupByName")
	sui.add("Lookup player by oid", "playerLookupByOID")
	sui.add("List players in village", "listOnlineVillagePlayers")

	if (curPhase == 3) then
		sui.add("Manage CounterStrike Bases", "manageCounterStrikeBases")
	end

	sui.add("Output LUA os.time() (Debugging)", "getOSTime")

	if (not self.productionServer) then
		sui.add("Change to next phase", "changePhase")
	end

	sui.add("Show Light Council Ranks", "showLightRanks")
	sui.add("Show Dark Council Ranks", "showDarkRanks")

	sui.sendTo(pPlayer)
end

function VillageGmSui:mainCallback(pPlayer, pSui, eventIndex, args)
	local cancelPressed = (eventIndex == 1)

	if (cancelPressed or args == nil or tonumber(args) < 0) then
		return
	end

	local pPageData = LuaSuiBoxPage(pSui):getSuiPageData()

	if (pPageData == nil) then
		return
	end

	local suiPageData = LuaSuiPageData(pPageData)
	local menuOption = suiPageData:getStoredData(tostring(args))

	local targetID

	if (string.find(menuOption, "%d")) then
		targetID = string.match(menuOption, '%d+')
		menuOption = string.gsub(menuOption, targetID, "")

		local pTarget = getSceneObject(targetID)

		if (pTarget == nil) then
			Logger:log("Unable to find player for VillageGmSui function " .. menuOption .. " using oid " .. targetID, LT_ERROR)
			return
		end
	end

	if (self[menuOption] == nil) then
		Logger:log("Tried to execute invalid function " .. menuOption .. " in VillageGmSui", LT_ERROR)
		return
	end

	self[menuOption](pPlayer, targetID)
end

function VillageGmSui.getOSTime(pPlayer)
	if (pPlayer == nil) then
		return
	end

	CreatureObject(pPlayer):sendSystemMessage("Current OS time is: " .. os.time())
end

function VillageGmSui.changePhase(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local sui = SuiMessageBox.new("VillageGmSui", "changePhaseCallback")

	sui.setTitle("Village Phase Change")
	sui.setPrompt("Are you sure you want to change the village to the next phase? Doing so will reset the progress of all players in the current phase.")
	sui.setOkButtonText("Yes")
	sui.setCancelButtonText("No")

	sui.sendTo(pPlayer)
end

function VillageGmSui:changePhaseCallback(pPlayer, pSui, eventIndex, args)
	local cancelPressed = (eventIndex == 1)

	if (cancelPressed) then
		VillageGmSui:showMainPage(pPlayer)
		return
	end

	local curPhase = VillageJediManagerTownship:getCurrentPhase()
	local nextPhase = curPhase + 1

	if nextPhase == 5 then
		nextPhase = 1
	end

	CreatureObject(pPlayer):sendSystemMessage("Changing the Village from phase " .. curPhase .. " to phase " .. nextPhase .. ".")
	VillageJediManagerTownship:switchToNextPhase(true)
end

function VillageGmSui.playerLookupByTarget(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local targetID = CreatureObject(pPlayer):getTargetID()

	local pTarget = getSceneObject(targetID)

	if (pTarget == nil or not SceneObject(pTarget):isPlayerCreature()) then
		CreatureObject(pPlayer):sendSystemMessage("Invalid target, must be a valid player.")
		VillageGmSui:showMainPage(pPlayer)
		return
	end

	VillageGmSui.playerInfo(pPlayer, targetID)
end

function VillageGmSui.playerLookupByName(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local sui = SuiInputBox.new("VillageGmSui", "playerLookupByNameCallback")

	sui.setTitle("Village Player Lookup (Name)")
	sui.setPrompt("Enter the name of the player you are looking for below.")

	sui.sendTo(pPlayer)
end

function VillageGmSui:playerLookupByNameCallback(pPlayer, pSui, eventIndex, args)
	local cancelPressed = (eventIndex == 1)

	if (cancelPressed) then
		VillageGmSui:showMainPage(pPlayer)
		return
	end

	if (args == nil or args == "") then
		CreatureObject(pPlayer):sendSystemMessage("Invalid string entered, please try again.")
		VillageGmSui.playerLookupByName(pPlayer)
		return
	end

	local pTarget = getPlayerByName(args)

	if (pTarget == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Unable to find player using the string: " .. args .. ".")
		VillageGmSui.playerLookupByName(pPlayer)
		return
	end

	local targetID = SceneObject(pTarget):getObjectID()
	VillageGmSui.playerInfo(pPlayer, targetID)
end

function VillageGmSui.playerLookupByOID(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local sui = SuiInputBox.new("VillageGmSui", "playerLookupByOIDCallback")

	sui.setTitle("Village Player Lookup (Object ID)")
	sui.setPrompt("Enter the object id of the player you are looking for below.")

	sui.sendTo(pPlayer)
end

function VillageGmSui:playerLookupByOIDCallback(pPlayer, pSui, eventIndex, args)
	local cancelPressed = (eventIndex == 1)

	if (cancelPressed) then
		VillageGmSui:showMainPage(pPlayer)
		return
	end

	if (args == nil or args == "") then
		CreatureObject(pPlayer):sendSystemMessage("Invalid oid entered, please try again.")
		VillageGmSui.playerLookupByOID(pPlayer)
		return
	end

	local pTarget = getSceneObject(args)

	if (pTarget == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Unable to find player using the oid: " .. args .. ".")
		VillageGmSui.playerLookupByOID(pPlayer)
		return
	end

	VillageGmSui.playerInfo(pPlayer, tonumber(args))
end

function VillageGmSui.listOnlineVillagePlayers(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local pMaster = VillageJediManagerTownship:getMasterObject()

	if (pMaster == nil) then
		printLuaError("Null village master object in VillageGmSui:listOnlineVillagePlayers")
		return
	end

	local playerTable = SceneObject(pMaster):getPlayersInRange(192)

	local sui = SuiListBox.new("VillageGmSui", "mainCallback")
	sui.setTitle("Village GM Panel")
	sui.setPrompt("These are the online players within 192 meters of the center of the Village:")

	for i = 1, #playerTable, 1 do
		if (playerTable[i] ~= nil) then
			sui.add(SceneObject(playerTable[i]):getCustomObjectName(), "playerInfo" .. SceneObject(playerTable[i]):getObjectID())
		end
	end

	sui.sendTo(pPlayer)
end

function VillageGmSui.playerInfo(pPlayer, targetID)
	local pTarget = getCreatureObject(targetID)

	if (pTarget == nil) then
		return
	end

	local pGhost = CreatureObject(pTarget):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	local jediState = PlayerObject(pGhost):getJediState()

	local promptBuf = " \\#pcontrast1 " .. "Player:" .. " \\#pcontrast2 " .. SceneObject(pTarget):getCustomObjectName() .. " (" .. targetID .. ")\n"
	promptBuf = promptBuf .. " \\#pcontrast1 " .. "Jedi State:" .. " \\#pcontrast2 " .. jediState .. "\n"
	promptBuf = promptBuf .. " \\#pcontrast1 " .. "Progression:" .. " \\#pcontrast2 "

	if (CreatureObject(pTarget):hasSkill("force_title_jedi_rank_03")) then
		promptBuf = promptBuf.. "Knight Trials Completed\n"
	elseif (VillageJediManagerCommon.hasJediProgressionScreenPlayState(pTarget, VILLAGE_JEDI_PROGRESSION_COMPLETED_PADAWAN_TRIALS)) then
		if (JediTrials:isOnKnightTrials(pTarget)) then
			promptBuf = promptBuf .. "Knight Trials (" .. JediTrials:getTrialsCompleted(pTarget) .. " completed)\n"
		else
			promptBuf = promptBuf.. "Padawan Trials Completed\n"
		end
	elseif (VillageJediManagerCommon.hasJediProgressionScreenPlayState(pTarget, VILLAGE_JEDI_PROGRESSION_DEFEATED_MELLIACHAE)) then
		if (JediTrials:isOnPadawanTrials(pTarget)) then
			promptBuf = promptBuf .. "Padawan Trials (" .. JediTrials:getTrialsCompleted(pTarget) .. " completed)\n"
		else
			promptBuf = promptBuf .. "Mellichae (Defeated)\n"
		end
	elseif (VillageJediManagerCommon.hasJediProgressionScreenPlayState(pTarget, VILLAGE_JEDI_PROGRESSION_ACCEPTED_MELLICHAE)) then
		promptBuf = promptBuf .. "Mellichae\n"
	elseif (FsOutro:isOnOutro(pTarget)) then
		local curStep = FsOutro:getCurrentStep(pTarget)

		if (curStep == FsOutro.OLDMANWAIT) then
			promptBuf = promptBuf .. "Outro (Waiting for Old Man)\n"
			if (FsOutro:hasDelayPassed(pTarget)) then
				promptBuf = promptBuf .. " \\#pcontrast1 " .. "Has Delay Passed: \\#pcontrast2 YES \n"
			else
				promptBuf = promptBuf .. " \\#pcontrast1 " .. "Has Delay Passed: \\#pcontrast2 NO \n"
			end

			local timeTilVisit = readScreenPlayData(pTarget, "VillageJediProgression", "FsOutroDelay") - os.time()

			if (not PlayerObject(pGhost):isOnline()) then
				promptBuf = promptBuf .. " \\#pcontrast1 " .. "Time until visit:" .. " \\#pcontrast2 Player Offline\n"
			elseif (timeTilVisit > 0) then
				promptBuf = promptBuf .. " \\#pcontrast1 " .. "Time until visit:" .. " \\#pcontrast2 " .. VillageGmSui:getTimeString(timeTilVisit * 1000) .. "\n"
			else
				promptBuf = promptBuf .. " \\#pcontrast1 " .. "Time until visit:" .. " \\#pcontrast2 Soon\n"
			end
		elseif (curStep == FsOutro.OLDMANMEET) then
			promptBuf = promptBuf .. "Outro (Old Man Visit)\n"
		end
	elseif (VillageJediManagerCommon.hasJediProgressionScreenPlayState(pTarget, VILLAGE_JEDI_PROGRESSION_HAS_VILLAGE_ACCESS)) then
		promptBuf = promptBuf .. "Village Phase Quests\n"
	elseif (FsIntro:isOnIntro(pTarget)) then
		local curStep = FsIntro:getCurrentStep(pTarget)

		if (curStep == FsIntro.OLDMANWAIT) then
			promptBuf = promptBuf .. "Intro (Waiting for Old Man)\n"
			if (FsIntro:hasDelayPassed(pTarget)) then
				promptBuf = promptBuf .. " \\#pcontrast1 " .. "Has Delay Passed: \\#pcontrast2 YES \n"
			else
				promptBuf = promptBuf .. " \\#pcontrast1 " .. "Has Delay Passed: \\#pcontrast2 NO \n"
			end
			local timeTilVisit = readScreenPlayData(pTarget, "VillageJediProgression", "FsIntroDelay") - os.time()

			if (not PlayerObject(pGhost):isOnline()) then
				promptBuf = promptBuf .. " \\#pcontrast1 " .. "Time until visit:" .. " \\#pcontrast2 Player Offline\n"
			elseif (timeTilVisit > 0) then
				promptBuf = promptBuf .. " \\#pcontrast1 " .. "Time until visit:" .. " \\#pcontrast2 " .. VillageGmSui:getTimeString(timeTilVisit * 1000) .. "\n"
			else
				promptBuf = promptBuf .. " \\#pcontrast1 " .. "Time until visit:" .. " \\#pcontrast2 Soon\n"
			end
			local totalVisits = tonumber(readScreenPlayData(pTarget, "VillageJediProgression", "FsIntroOldManVisits"))

			if (totalVisits == nil) then totalVisits = 0 end
			promptBuf = promptBuf .. " \\#pcontrast1 " .. "Old Man Visits So Far:" .. " \\#pcontrast2 " .. totalVisits .. "\n"
		elseif (curStep == FsIntro.OLDMANMEET) then
			promptBuf = promptBuf .. "Intro (Old Man Visit)\n"
		elseif (curStep == FsIntro.SITHWAIT) then
			promptBuf = promptBuf .. "Intro (Waiting for Sith Attack)\n"
			if (FsIntro:hasDelayPassed(pTarget)) then
				promptBuf = promptBuf .. " \\#pcontrast1 " .. "Has Delay Passed: \\#pcontrast2 YES \n"
			else
				promptBuf = promptBuf .. " \\#pcontrast1 " .. "Has Delay Passed: \\#pcontrast2 NO \n"
			end
			local timeTilAttack = readScreenPlayData(pTarget, "VillageJediProgression", "FsIntroDelay") - os.time()

			if (not PlayerObject(pGhost):isOnline()) then
				promptBuf = promptBuf .. " \\#pcontrast1 " .. "Time Until Attack:" .. " \\#pcontrast2 Player Offline\n"
			elseif (timeTilAttack > 0) then
				promptBuf = promptBuf .. " \\#pcontrast1 " .. "Time Until Attack:" .. " \\#pcontrast2 " .. VillageGmSui:getTimeString(timeTilAttack * 1000) .. "\n"
			else
				promptBuf = promptBuf .. " \\#pcontrast1 " .. "Time Until Attack:" .. " \\#pcontrast2 Soon\n"
			end
		elseif (curStep == FsIntro.SITHATTACK) then
			promptBuf = promptBuf .. "Intro (Sith Attack)\n"
		elseif (curStep == FsIntro.USEDATAPADONE) then
			promptBuf = promptBuf .. "Intro (First Datapad Looted)\n"
		elseif (curStep == FsIntro.SITHTHEATER) then
			promptBuf = promptBuf .. "Intro (Sith Camp)\n"
		elseif (curStep == FsIntro.USEDATAPADTWO) then
			promptBuf = promptBuf .. "Intro (Second Datapad Looted)\n"
		elseif (curStep == FsIntro.VILLAGE) then
			promptBuf = promptBuf .. "Intro (Sent to Village)\n"
		end

		if (curStep == FsIntro.OLDMANWAIT or curStep == FsIntro.OLDMANMEET or curStep == FsIntro.SITHWAIT or curStep == FsIntro.SITHATTACK) then
			promptBuf = promptBuf .. " -- Encounter Checks --\n" .. "\\#pcontrast1 " .. "InPositionForEncounter:" .. " \\#pcontrast2 " .. tostring(Encounter:isPlayerInPositionForEncounter(pTarget)) .. "\n"

			if (not Encounter:isPlayerInPositionForEncounter(pTarget)) then
				promptBuf = promptBuf .. " \\#pcontrast1 " .. "Player Online:" .. " \\#pcontrast2 " .. tostring(Encounter:isPlayerOnline(pTarget)) .. "\n"
				if (PlayerObject(pGhost):isOnline()) then
					promptBuf = promptBuf .. " \\#pcontrast1 " .. "Player In a Building:" .. " \\#pcontrast2 " .. tostring(Encounter:isPlayerInABuilding(pTarget)) .. "\n"
					promptBuf = promptBuf .. " \\#pcontrast1 " .. "Player In NPC City:" .. " \\#pcontrast2 " .. tostring(Encounter:isPlayerInNpcCity(pTarget)) .. "\n"
				end
			end
			promptBuf = promptBuf .. " ----\n"
		end
	elseif (Glowing:isGlowing(pTarget)) then
		promptBuf = promptBuf .. "Glowing\n"
	else
		promptBuf = promptBuf .. "Not Glowing\n"
	end

	if (VillageJediManagerCommon.hasActiveQuestThisPhase(pTarget)) then
		promptBuf = promptBuf .. " \\#pcontrast1 " .. "Has Active Quest This Phase:" .. " \\#pcontrast2 YES\n"
	else
		promptBuf = promptBuf .. " \\#pcontrast1 " .. "Has Active Quest This Phase:" .. " \\#pcontrast2 NO\n"
	end

	if (VillageJediManagerCommon.hasCompletedQuestThisPhase(pTarget)) then
		promptBuf = promptBuf .. " \\#pcontrast1 " .. "Has Completed Quest This Phase:" .. " \\#pcontrast2 YES\n"
	else
		promptBuf = promptBuf .. " \\#pcontrast1 " .. "Has Completed Quest This Phase:" .. " \\#pcontrast2 NO\n"
	end

	if (VillageJediManagerCommon.hasJediProgressionScreenPlayState(pTarget, VILLAGE_JEDI_PROGRESSION_HAS_VILLAGE_ACCESS) or VillageJediManagerCommon.getUnlockedBranchCount(pTarget) > 0) then
		promptBuf = promptBuf .. " \\#pcontrast1 " .. "Unlocked Branches:" .. " \\#pcontrast2 " .. VillageJediManagerCommon.getUnlockedBranchCount(pTarget) .. "\n"
	end

	local sui = SuiListBox.new("VillageGmSui", "mainCallback")
	sui.setTitle("Village GM Panel")
	sui.setPrompt(promptBuf)

	sui.add("FS Branch Management", "branchManagement" .. targetID)

	if (not Glowing:isGlowing(pTarget)) then
		sui.add("Grant FS Badges (Make Glowing)", "grantFsBadges" .. targetID)
	elseif (not VillageJediManagerCommon.isVillageEligible(pTarget)) then
		sui.add("Unlock Village Access", "unlockVillageAccess" .. targetID)
	end

	if (CreatureObject(pTarget):hasSkill("force_title_jedi_rank_03")) then
		sui.add("Manage Player FRS", "frsManagement" .. targetID)
	elseif (jediState >= 4) then
		sui.add("Unlock Light FRS", "unlockLightFrs" .. targetID)
		sui.add("Unlock Dark FRS", "unlockDarkFrs" .. targetID)
	end

	if (VillageJediManagerCommon.hasActiveQuestThisPhase(pTarget)) then
		sui.add("Manage Active Village Quest", "manageActiveVillageQuest" .. targetID)
		sui.add("Reset Active Quest This Phase", "resetActiveQuest" .. targetID)
	end

	if (VillageJediManagerCommon.hasCompletedQuestThisPhase(pTarget)) then
		sui.add("Reset Completed Quest This Phase", "resetCompletedQuest" .. targetID)
	end

	if (FsIntro:isOnIntro(pTarget)) then
		local curStep = FsIntro:getCurrentStep(pTarget)

		if (curStep == FsIntro.SITHWAIT or curStep == FsIntro.SITHATTACK) then
			sui.add("Force Start Sith Attack Intro Encounter", "forceIntroSithAttackEvent" .. targetID)
		elseif (curStep == FsIntro.OLDMANWAIT or curStep == FsIntro.OLDMANMEET) then
			sui.add("Force Start Old Man Intro Encounter", "forceIntroOldManEvent" .. targetID)
		end
	elseif (FsOutro:isOnOutro(pTarget)) then
		local curStep = FsOutro:getCurrentStep(pTarget)

		if (curStep == FsOutro.OLDMANWAIT or curStep == FsIntro.OLDMANMEET) then
			sui.add("Force Start Old Man Outro Encounter", "forceOutroOldManEvent" .. targetID)
		end
	end

	if (PlayerObject(pGhost):getVisibility() > 0 or CreatureObject(pTarget):hasSkill("force_title_jedi_rank_02")) then
		sui.add("Manage Visibility", "manageVisibility" .. targetID)
	end

	sui.add("Padawan Trials", "padawanTrialsMenu" .. targetID)
	sui.add("Knight Trials", "knightTrialsMenu" .. targetID)

	sui.sendTo(pPlayer)
end

function VillageGmSui.manageActiveVillageQuest(pPlayer, targetID)
	local pTarget = getSceneObject(targetID)

	if (pTarget == nil) then
		return
	end

	local pGhost = CreatureObject(pTarget):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	if (not VillageJediManagerCommon.hasActiveQuestThisPhase(pTarget) or VillageJediManagerCommon.hasCompletedQuestThisPhase(pTarget)) then
		CreatureObject(pPlayer):sendSystemMessage("Player does not have an active quest this phase.")
		return
	end

	local sui = SuiListBox.new("VillageGmSui", "manageVillageQuestCallback")
	sui.setTitle("Village Quest Management")

	local curQuest = VillageJediManagerCommon.getActiveQuestIdThisPhase(pTarget)
	local questGiver = ""
	local promptAdd = ""

	if (curQuest == VILLAGE_PHASE1_SARGUILLO) then
		questGiver = "Sarguillo (Phase 1)"
		sui.add("Reset Current Patrol", "resetSarguilloPatrol" .. targetID)
		sui.add("Complete Current Patrol", "completeSarguilloPatrol" .. targetID)
	elseif (curQuest == VILLAGE_PHASE1_QUHAREK) then
		questGiver = "Quharek (Phase 1)"
		sui.add("No current available functions for this quest", "noAvailableFunctions" .. targetID)
	elseif (curQuest == VILLAGE_PHASE1_SIVARRA) then
		questGiver = "Sivarra (Phase 1)"
		sui.add("No current available functions for this quest", "noAvailableFunctions" .. targetID)
	elseif (curQuest == VILLAGE_PHASE1_WHIP) then
		questGiver = "Whip (Phase 1)"
		sui.add("Complete Current Escort", "completeWhipEscort" .. targetID)
	elseif (curQuest == VILLAGE_PHASE2_DAGEERIN) then
		questGiver = "Dageerin (Phase 2)"
		sui.add("Reset task limit", "resetDageerinTaskLimit" .. targetID)
		promptAdd = " \\#pcontrast1 " .. "Tasks towards limit:" .. " \\#pcontrast2 " .. readScreenPlayData(pTarget, "VillageJediProgression", "FsSadTasksSinceLastTimestamp") .. "\n"
	elseif (curQuest == VILLAGE_PHASE2_QUHAREK) then
		questGiver = "Quharek (Phase 2)"
		sui.add("No current available functions for this quest", "noAvailableFunctions" .. targetID)
	elseif (curQuest == VILLAGE_PHASE2_WHIP) then
		questGiver = "Whip (Phase 2)"
		sui.add("No current available functions for this quest", "noAvailableFunctions" .. targetID)
	elseif (curQuest == VILLAGE_PHASE2_SURVEYOR) then
		questGiver = "Surveyor (Phase 2)"
		sui.add("No current available functions for this quest", "noAvailableFunctions" .. targetID)
	elseif (curQuest == VILLAGE_PHASE3_DAGEERIN) then
		questGiver = "Dageerin (Phase 3)"
		sui.add("Reset task limit", "resetDageerinTaskLimit" .. targetID)
		promptAdd = " \\#pcontrast1 " .. "Tasks towards limit:" .. " \\#pcontrast2 " .. readScreenPlayData(pTarget, "VillageJediProgression", "FsSad2TasksSinceLastTimestamp") .. "\n"
	elseif (curQuest == VILLAGE_PHASE3_QUHAREK) then
		questGiver = "Quharek (Phase 3)"
		sui.add("No current available functions for this quest", "noAvailableFunctions" .. targetID)
	elseif (curQuest == VILLAGE_PHASE3_SARGUILLO) then
		questGiver = "Sarguillo (Phase 3)"
		sui.add("No current available functions for this quest", "noAvailableFunctions" .. targetID)
	elseif (curQuest == VILLAGE_PHASE3_SURVEYOR) then
		questGiver = "Surveyor (Phase 3)"
		sui.add("No current available functions for this quest", "noAvailableFunctions" .. targetID)
	elseif (curQuest == VILLAGE_PHASE4_ENGINEER) then
		questGiver = "Chief Engineer (Phase 4)"
		sui.add("No current available functions for this quest", "noAvailableFunctions" .. targetID)
	elseif (curQuest == VILLAGE_PHASE4_SARGUILLO_CP) then
		questGiver = "Sarguillo - Combat Prowess (Phase 4)"
		sui.add("No current available functions for this quest", "noAvailableFunctions" .. targetID)
	elseif (curQuest == VILLAGE_PHASE4_SARGUILLO_ER) then
		questGiver = "Sarguillo - Enhanced Reflexes (Phase 4)"
		sui.add("No current available functions for this quest", "noAvailableFunctions" .. targetID)
	elseif (curQuest == VILLAGE_PHASE4_SIVARRA) then
		questGiver = "Sivarra (Phase 4)"
		sui.add("No current available functions for this quest", "noAvailableFunctions" .. targetID)
	end

	local promptBuf = " \\#pcontrast1 " .. "Player:" .. " \\#pcontrast2 " .. SceneObject(pTarget):getCustomObjectName() .. " (" .. targetID .. ")\n"
	promptBuf = promptBuf .. " \\#pcontrast1 " .. "Current Quest:" .. " \\#pcontrast2 " .. questGiver .. "\n"
	promptBuf = promptBuf .. promptAdd

	sui.setPrompt(promptBuf)


	sui.sendTo(pPlayer)
end

function VillageGmSui:manageVillageQuestCallback(pPlayer, pSui, eventIndex, args)
	local cancelPressed = (eventIndex == 1)

	if (cancelPressed) then
		return
	end

	local pPageData = LuaSuiBoxPage(pSui):getSuiPageData()

	if (pPageData == nil) then
		return
	end

	local suiPageData = LuaSuiPageData(pPageData)
	local menuOption =  suiPageData:getStoredData(tostring(args))

	local targetID, pTarget
	local curPhase = VillageJediManagerTownship:getCurrentPhase()

	if (string.find(menuOption, "%d")) then
		targetID = string.match(menuOption, '%d+')
		menuOption = string.gsub(menuOption, targetID, "")

		if (menuOption == "noAvailableFunctions") then
			return
		end

		pTarget = getSceneObject(targetID)

		if (pTarget == nil) then
			printLuaError("Unable to find player for VillageGmSui function " .. menuOption .. " using oid " .. targetID)
			return
		end
	end

	if (curPhase == 1) then
		if (menuOption == "resetSarguilloPatrol") then
			FsPatrol:resetFsPatrol(pTarget)
			CreatureObject(pPlayer):sendSystemMessage("Player's current Sarguillo Phase 1 patrol has been reset.")
		elseif (menuOption == "completeSarguilloPatrol") then
			CreatureObject(pPlayer):sendSystemMessage("Player's current Sarguillo Phase 1 patrol has been completed.")
			villageSarguilloPhase1ConvoHandler:completeCurrentPatrol(pTarget)
		elseif (menuOption == "completeWhipEscort") then
			CreatureObject(pPlayer):sendSystemMessage("Player's current Whip Phase 1 escort has been completed.")
			FsReflex1:completeVillagerEscort(pTarget)
		end
	elseif (curPhase == 2) then
		if (menuOption == "resetDageerinTaskLimit") then
			FsSad:setTasksSinceLastTimestamp(pTarget, 0)
			CreatureObject(pPlayer):sendSystemMessage("Player's SAD task count towards limit has been reset back to 0.")
		end
	elseif (curPhase == 3) then
		if (menuOption == "resetDageerinTaskLimit") then
			FsSad2:setTasksSinceLastTimestamp(pTarget, 0)
			CreatureObject(pPlayer):sendSystemMessage("Player's SAD2 task count towards limit has been reset back to 0.")
		end
	end
end

function VillageGmSui.forceIntroSithAttackEvent(pPlayer, targetID)
	local pTarget = getSceneObject(targetID)

	if (pTarget == nil) then
		return
	end

	local curStep = FsIntro:getCurrentStep(pTarget)
	local playerName = CreatureObject(pTarget):getFirstName()
	if (not FsIntro:isOnIntro(pTarget) or (curStep ~= FsIntro.SITHWAIT and curStep ~= FsIntro.SITHATTACK)) then
		CreatureObject(pPlayer):sendSystemMessage("Unable to force the sith attack intro event for " .. playerName .. ", they are not on the correct step.")
		return
	end

	CreatureObject(pPlayer):sendSystemMessage("Now forcing the sith attack intro event to start for " .. playerName .. ".")
	FsIntro:startSithAttack(pTarget)
end

function VillageGmSui.forceIntroOldManEvent(pPlayer, targetID)
	local pTarget = getSceneObject(targetID)

	if (pTarget == nil) then
		return
	end

	local curStep = FsIntro:getCurrentStep(pTarget)
	local playerName = CreatureObject(pTarget):getFirstName()
	if (not FsIntro:isOnIntro(pTarget) or (curStep ~= FsIntro.OLDMANWAIT and curStep ~= FsIntro.OLDMANMEET)) then
		CreatureObject(pPlayer):sendSystemMessage("Unable to force the old man intro event for " .. playerName .. ", they are not on the correct step.")
		return
	end

	CreatureObject(pPlayer):sendSystemMessage("Now forcing the old man event intro to start for " .. playerName .. ".")
	FsIntro:startOldMan(pTarget)
end

function VillageGmSui.forceOutroOldManEvent(pPlayer, targetID)
	local pTarget = getSceneObject(targetID)

	if (pTarget == nil) then
		return
	end

	local curStep = FsOutro:getCurrentStep(pTarget)

	if (not FsOutro:isOnOutro(pTarget) or (curStep ~= FsOutro.OLDMANWAIT and curStep ~= FsOutro.OLDMANMEET)) then
		CreatureObject(pPlayer):sendSystemMessage("Unable to force the old man outro event for " .. CreatureObject(pTarget):getFirstName() .. ", they are not on the correct step.")
		return
	end

	CreatureObject(pPlayer):sendSystemMessage("Now forcing the old man event outro to start for " .. CreatureObject(pTarget):getFirstName() .. ".")
	FsOutro:doOldManSpawn(pTarget)
end

function VillageGmSui.resetActiveQuest(pPlayer, targetID)
	local pTarget = getSceneObject(targetID)

	if (pTarget == nil) then
		return
	end

	local sui = SuiMessageBox.new("VillageGmSui", "resetActiveQuestCallback")

	sui.setTitle("Reset Active Quest")
	sui.setPrompt("Are you sure you want to reset the player's active quest status? This could potentially allow a player to have two active quests at the same time.")
	sui.setOkButtonText("Yes")
	sui.setCancelButtonText("No")
	sui.setTargetNetworkId(targetID)

	sui.sendTo(pPlayer)
end

function VillageGmSui:resetActiveQuestCallback(pPlayer, pSui, eventIndex, args)
	local pPageData = LuaSuiBoxPage(pSui):getSuiPageData()

	if (pPageData == nil) then
		return
	end

	local suiPageData = LuaSuiPageData(pPageData)

	local targetID = suiPageData:getTargetNetworkId()

	local pTarget = getSceneObject(targetID)

	if (pTarget == nil) then
		return
	end

	local cancelPressed = (eventIndex == 1)

	if (cancelPressed) then
		VillageGmSui.playerInfo(pPlayer, targetID)
		return
	end

	local phaseID = VillageJediManagerTownship:getCurrentPhaseID()
	VillageJediManagerCommon.removeFromActiveQuestList(pTarget)
	removeQuestStatus(targetID .. ":village:lastActiveQuest")

	CreatureObject(pPlayer):sendSystemMessage("Player has been removed from this phase's active quest list.")

	VillageGmSui.playerInfo(pPlayer, targetID)
end

function VillageGmSui.resetCompletedQuest(pPlayer, targetID)
	local pTarget = getSceneObject(targetID)

	if (pTarget == nil) then
		return
	end

	local sui = SuiMessageBox.new("VillageGmSui", "resetCompletedQuestCallback")

	sui.setTitle("Reset Completed Quest")
	sui.setPrompt("Are you sure you want to reset the player's completed quest status? This will allow the player to complete a second quest this phase.")
	sui.setOkButtonText("Yes")
	sui.setCancelButtonText("No")
	sui.setTargetNetworkId(targetID)

	sui.sendTo(pPlayer)
end

function VillageGmSui:resetCompletedQuestCallback(pPlayer, pSui, eventIndex, args)
	local pPageData = LuaSuiBoxPage(pSui):getSuiPageData()

	if (pPageData == nil) then
		return
	end

	local suiPageData = LuaSuiPageData(pPageData)

	local targetID = suiPageData:getTargetNetworkId()

	local pTarget = getSceneObject(targetID)

	if (pTarget == nil) then
		return
	end

	local cancelPressed = (eventIndex == 1)

	if (cancelPressed) then
		VillageGmSui.playerInfo(pPlayer, targetID)
		return
	end

	local phaseID = VillageJediManagerTownship:getCurrentPhaseID()
	removeQuestStatus(targetID .. ":village:lastCompletedQuest")

	CreatureObject(pPlayer):sendSystemMessage("Player has had their completed quest status for this phase reset.")

	VillageGmSui.playerInfo(pPlayer, targetID)
end

function VillageGmSui.manageVisibility(pPlayer, targetID)
	local pTarget = getSceneObject(targetID)

	if (pTarget == nil) then
		return
	end

	local pGhost = CreatureObject(pTarget):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	includeFile("../managers/jedi/visibility_manager.lua")

	local sui = SuiListBox.new("VillageGmSui", "manageVisibilityCallback")
	sui.setTitle("Visibility Management")

	local promptBuf = " \\#pcontrast1 " .. "Player:" .. " \\#pcontrast2 " .. SceneObject(pTarget):getCustomObjectName() .. " (" .. targetID .. ")\n"
	promptBuf = promptBuf .. " \\#pcontrast1 " .. "Current Visibility: " .. " \\#pcontrast2 " .. PlayerObject(pGhost):getVisibility() .. "\n"
	promptBuf = promptBuf .. " \\#pcontrast1 (Cap: " .. maxVisibility .. ") \n"

	sui.setPrompt(promptBuf)

	--sui.add("Set Visibility Value", "setVisibility" .. targetID)

	sui.sendTo(pPlayer)
end

function VillageGmSui:manageVisibilityCallback(pPlayer, pSui, eventIndex, args)
	local cancelPressed = (eventIndex == 1)

	if (cancelPressed) then
		return
	end
end

function VillageGmSui.padawanTrialsMenu(pPlayer, targetID)
	local pTarget = getSceneObject(targetID)

	if (pTarget == nil) then
		return
	end

	local sui = SuiListBox.new("VillageGmSui", "padawanTrialsCallback")
	sui.setTitle("Padawan Trials Management")

	local promptBuf = " \\#pcontrast1 " .. "Player:" .. " \\#pcontrast2 " .. SceneObject(pTarget):getCustomObjectName() .. " (" .. targetID .. ")\n"
	promptBuf = promptBuf .. "Select the Padawan Trials phase to start, or complete the trials."
	sui.setPrompt(promptBuf)

	sui.add("Advance to Phase 1", "padawanPhase1:" .. targetID)
	sui.add("Advance to Phase 2", "padawanPhase2:" .. targetID)
	sui.add("Advance to Phase 3", "padawanPhase3:" .. targetID)
	sui.add("Advance to Phase 4", "padawanPhase4:" .. targetID)
	sui.add("Advance to Phase 5", "padawanPhase5:" .. targetID)
	sui.add("Make Eligible to Start Padawan Trials", "padawanEligible:" .. targetID)
	sui.add("Complete Padawan Trials", "padawanComplete:" .. targetID)
	sui.add("Back", "padawanBack:" .. targetID)

	sui.sendTo(pPlayer)
end

function VillageGmSui:padawanTrialsCallback(pPlayer, pSui, eventIndex, args)
	local cancelPressed = (eventIndex == 1)

	if (cancelPressed or args == nil or tonumber(args) < 0) then
		return
	end

	local pPageData = LuaSuiBoxPage(pSui):getSuiPageData()

	if (pPageData == nil) then
		return
	end

	local suiPageData = LuaSuiPageData(pPageData)
	local menuOption = suiPageData:getStoredData(tostring(args))
	local targetID, pTarget
	local optionBase, optionTarget = string.match(menuOption, "^(.*):(%d+)$")

	if (optionBase ~= nil and optionTarget ~= nil) then
		menuOption = optionBase
		targetID = optionTarget
		pTarget = getSceneObject(targetID)
	end

	if (pTarget == nil or not SceneObject(pTarget):isPlayerCreature()) then
		Logger:log("Unable to find player for VillageGmSui function padawanTrialsCallback - " .. menuOption .. " using oid " .. targetID, LT_ERROR)
		return
	end

	if (menuOption == "padawanBack") then
		VillageGmSui.playerInfo(pPlayer, targetID)
		return
	end

	local phase = tonumber(string.match(menuOption, "^padawanPhase(%d)$"))

	if (phase ~= nil) then
		PadawanTrials:resetAllPadawanTrials(pTarget)
		PadawanTrials:startPhase(pTarget, phase)
		CreatureObject(pPlayer):sendSystemMessage("Padawan Trials set to Phase " .. phase .. " for " .. SceneObject(pTarget):getCustomObjectName() .. ".")
		VillageGmSui.playerInfo(pPlayer, targetID)
		return
	end

	if (menuOption == "padawanComplete") then
		PadawanTrials:unlockPadawan(pTarget)
		CreatureObject(pPlayer):sendSystemMessage("Padawan Trials completed for " .. SceneObject(pTarget):getCustomObjectName() .. ".")
		VillageGmSui.playerInfo(pPlayer, targetID)
		return
	end

	if (menuOption == "padawanEligible") then
		PadawanTrials:resetAllPadawanTrials(pTarget)
		VillageJediManagerCommon.setJediProgressionScreenPlayState(pTarget, VILLAGE_JEDI_PROGRESSION_DEFEATED_MELLIACHAE)
		CreatureObject(pPlayer):sendSystemMessage("Padawan Trials eligibility set for " .. SceneObject(pTarget):getCustomObjectName() .. ".")
		VillageGmSui.playerInfo(pPlayer, targetID)
		return
	end
end

function VillageGmSui.knightTrialsMenu(pPlayer, targetID)
	local pTarget = getSceneObject(targetID)

	if (pTarget == nil) then
		return
	end

	local sui = SuiListBox.new("VillageGmSui", "knightTrialsCallback")
	sui.setTitle("Knight Trials Management")

	local promptBuf = " \\#pcontrast1 " .. "Player:" .. " \\#pcontrast2 " .. SceneObject(pTarget):getCustomObjectName() .. " (" .. targetID .. ")\n"
	promptBuf = promptBuf .. "Select which Jedi Knight path to grant."
	sui.setPrompt(promptBuf)

	sui.add("Make Light Jedi Knight", "knightLight:" .. targetID)
	sui.add("Make Dark Jedi Knight", "knightDark:" .. targetID)
	sui.add("Back", "knightBack:" .. targetID)

	sui.sendTo(pPlayer)
end

function VillageGmSui:knightTrialsCallback(pPlayer, pSui, eventIndex, args)
	local cancelPressed = (eventIndex == 1)

	if (cancelPressed or args == nil or tonumber(args) < 0) then
		return
	end

	local pPageData = LuaSuiBoxPage(pSui):getSuiPageData()

	if (pPageData == nil) then
		return
	end

	local suiPageData = LuaSuiPageData(pPageData)
	local menuOption = suiPageData:getStoredData(tostring(args))
	local targetID, pTarget
	local optionBase, optionTarget = string.match(menuOption, "^(.*):(%d+)$")

	if (optionBase ~= nil and optionTarget ~= nil) then
		menuOption = optionBase
		targetID = optionTarget
		pTarget = getSceneObject(targetID)
	end

	if (pTarget == nil or not SceneObject(pTarget):isPlayerCreature()) then
		Logger:log("Unable to find player for VillageGmSui function knightTrialsCallback - " .. menuOption .. " using oid " .. targetID, LT_ERROR)
		return
	end

	if (menuOption == "knightBack") then
		VillageGmSui.playerInfo(pPlayer, targetID)
		return
	end

	if (menuOption == "knightLight" or menuOption == "knightDark") then
		local councilType = menuOption == "knightLight" and JediTrials.COUNCIL_LIGHT or JediTrials.COUNCIL_DARK
		writeScreenPlayData(pTarget, "KnightTrials", "startedTrials", 1)
		writeScreenPlayData(pTarget, "KnightTrials", "activatedAtShrine", 1)
		JediTrials:setJediCouncil(pTarget, councilType)
		JediTrials:unlockJediKnight(pTarget)
		CreatureObject(pPlayer):sendSystemMessage("Knight Trials completed for " .. SceneObject(pTarget):getCustomObjectName() .. ".")
		VillageGmSui.playerInfo(pPlayer, targetID)
		return
	end
end

--[[

	FRS Management

]]

function VillageGmSui.frsManagement(pPlayer, targetID)
	local pTarget = getSceneObject(targetID)

	if (pTarget == nil) then
		return
	end

	local pGhost = CreatureObject(pTarget):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	local councilType = PlayerObject(pGhost):getFrsCouncil()
	local luaCouncil = JediTrials:getJediCouncil(pTarget)
	local councilRank = PlayerObject(pGhost):getFrsRank()

	local sui = SuiListBox.new("VillageGmSui", "frsManageCallback")
	sui.setTitle("FRS Info")

	local promptBuf = " \\#pcontrast1 " .. "Player:" .. " \\#pcontrast2 " .. SceneObject(pTarget):getCustomObjectName() .. " (" .. targetID .. ")\n"
	promptBuf = promptBuf .. " \\#pcontrast1 " .. "Council:" .. " \\#pcontrast2 "

	if (councilType == JediTrials.COUNCIL_LIGHT) then
		promptBuf = promptBuf .. "Light\n"
	elseif (councilType == JediTrials.COUNCIL_DARK) then
		promptBuf = promptBuf .. "Dark\n"
	else
		promptBuf = promptBuf .. "Invalid\n"
	end

	if (luaCouncil == nil or councilType == nil or luaCouncil ~= councilType) then
		promptBuf = promptBuf .. " \\#pcontrast1 " .. "WARNING:" .. " \\#pcontrast2 Trials council choice does not match council type stored on player. Use menu option below to fix.\n"
	end

	promptBuf = promptBuf .. " \\#pcontrast1 " .. "Rank:" .. " \\#pcontrast2 " .. councilRank .. "\n"

	sui.setPrompt(promptBuf)

	sui.add("Set FRS Rank", "setFrsRank" .. targetID)
	sui.add("Set FRS XP", "setFrsXp" .. targetID)

	sui.sendTo(pPlayer)
end

function VillageGmSui:frsManageCallback(pPlayer, pSui, eventIndex, args)
	local cancelPressed = (eventIndex == 1)

	if (cancelPressed or args == nil or tonumber(args) < 0) then
		return
	end

	local pPageData = LuaSuiBoxPage(pSui):getSuiPageData()

	if (pPageData == nil) then
		return
	end

	local suiPageData = LuaSuiPageData(pPageData)
	local menuOption = suiPageData:getStoredData(tostring(args))
	local targetID, pTarget

	if (string.find(menuOption, "%d")) then
		targetID = string.match(menuOption, '%d+')
		menuOption = string.gsub(menuOption, targetID, "")

		pTarget = getSceneObject(targetID)
	end

	if (pTarget == nil or not SceneObject(pTarget):isPlayerCreature()) then
		Logger:log("Unable to find player for VillageGmSui function frsManageCallback - " .. menuOption .. " using oid " .. targetID, LT_ERROR)
		return
	end

	if (menuOption == "setFrsRank") then
		local sui = SuiInputBox.new("VillageGmSui", "suiSetFrsRankCallback")

		sui.setTargetNetworkId(SceneObject(pTarget):getObjectID())

		local suiBody = "\r\\#FFFFFF Target Player: \r\\#pcontrast1 " .. CreatureObject(pTarget):getFirstName() .. "\r\\#FFFFFF \n"
		suiBody = suiBody .. " Target Player ID: \r\\#pcontrast1 " .. targetID .. "\r\\#FFFFFF \n\n"
		suiBody = suiBody .. " Enter the FRS Rank you wish to set on the target:"

		sui.setTitle("Set Player FRS Rank")
		sui.setPrompt(suiBody)

		sui.sendTo(pPlayer)

	elseif (menuOption == "setFrsXp") then
		local sui = SuiInputBox.new("VillageGmSui", "suiSetFrsXpCallback")

		sui.setTargetNetworkId(SceneObject(pTarget):getObjectID())

		local suiBody = "Enter the amount of FRS XP you wish to grant:"
		sui.setTitle("Set Player FRS XP")
		sui.setPrompt(suiBody)

		sui.sendTo(pPlayer)
	end
end

function VillageGmSui:suiSetFrsRankCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil) then
		return
	end

	local cancelPressed = (eventIndex == 1)

	if (cancelPressed or args == "") then
		return
	end

	local pPageData = LuaSuiBoxPage(pSui):getSuiPageData()

	if (pPageData == nil) then
		return
	end

	local suiPageData = LuaSuiPageData(pPageData)
	local targetID = suiPageData:getTargetNetworkId()

	local pTarget = getSceneObject(targetID)

	if (pTarget == nil or not SceneObject(pTarget):isPlayerCreature()) then
		local msg = SceneObject(pPlayer):getCustomObjectName() .. " ID: " .. SceneObject(pPlayer):getObjectID() .. " attempted to use GMFSVillage:suiSetFrsRankCallback on an improper target."
		Logger:log(msg, LT_ERROR)

		CreatureObject(pPlayer):sendSystemMessage("Please select a proper target to set their FRS Rank.")
		return
	end

	local pGhost = CreatureObject(pTarget):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	local rank = tonumber(args)

	if (rank < 0 or rank > 11) then
		local msg = SceneObject(pPlayer):getCustomObjectName() .. " ID: " .. SceneObject(pPlayer):getObjectID() .. " attempted to use GMFSVillage:suiSetFrsRankCallback and input an improper rank number."
		Logger:log(msg, LT_ERROR)

		CreatureObject(pPlayer):sendSystemMessage("Please input a FRS Rank ranging from 0 to 11.")
		return
	end

	-- Set the rank
	PlayerObject(pGhost):setFrsRank(rank)

	local msg = SceneObject(pPlayer):getCustomObjectName() .. " ID: " .. SceneObject(pPlayer):getObjectID() .. " used GMFSVillage:suiSetFrsRankCallback on " .. SceneObject(pTarget):getCustomObjectName() .. " ID: " .. targetID
	msg = msg .. " granting them Rank " .. rank
	Logger:log(msg, LT_WARNING)

	CreatureObject(pPlayer):sendSystemMessage(msg)
end

function VillageGmSui:suiSetFrsXpCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil) then
		return
	end

	local cancelPressed = (eventIndex == 1)

	if (cancelPressed or args == "") then
		return
	end

	local pPageData = LuaSuiBoxPage(pSui):getSuiPageData()

	if (pPageData == nil) then
		return
	end

	local suiPageData = LuaSuiPageData(pPageData)
	local targetID = suiPageData:getTargetNetworkId()

	local pTarget = getSceneObject(targetID)

	if (pTarget == nil or not SceneObject(pTarget):isPlayerCreature()) then
		local msg = SceneObject(pPlayer):getCustomObjectName() .. " ID: " .. SceneObject(pPlayer):getObjectID() .. " attempted to use GMFSVillage:suiSetFrsRankCallback on an improper target."
		Logger:log(msg, LT_ERROR)

		CreatureObject(pPlayer):sendSystemMessage("Please select a proper target to set their FRS Rank.")
		return
	end

	local amount = tonumber(args)

	CreatureObject(pTarget):awardExperience("force_rank_xp", amount, true)

	local msg = SceneObject(pPlayer):getCustomObjectName() .. " ID: " .. SceneObject(pPlayer):getObjectID() .. " used GMFSVillage:suiSetFrsXpCallback on " .. SceneObject(pTarget):getCustomObjectName() .. " ID: " .. targetID
	msg = msg .. " granting them " .. amount .. " Force Rank Experience"
	Logger:log(msg, LT_WARNING)

	CreatureObject(pPlayer):sendSystemMessage(msg)
end

function VillageGmSui.unlockLightFrs(pPlayer, targetID)
	if (pPlayer == nil) then
		return
	end

	local pTarget = getSceneObject(targetID)

	if (pTarget == nll or not SceneObject(pTarget):isPlayerCreature()) then
		return
	end

	local pGhost = CreatureObject(pTarget):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	local jediState = PlayerObject(pGhost):getJediState()

	-- Player must have manually completed the trials
	if (jediState ~= 4) then
		local msg = SceneObject(pPlayer):getCustomObjectName() .. " ID: " .. SceneObject(pPlayer):getObjectID() .. " attempted to use GMFSVillage:unlockLightFrs on Player: " .. SceneObject(pTarget):getCustomObjectName() .. " ID: " .. targetID
		msg = msg .. " with an invalid Jedi State of " .. jediState
		Logger:log(msg, LT_ERROR)

		CreatureObject(pPlayer):sendSystemMessage(SceneObject(pTarget):getCustomObjectName() .. " ID: " .. targetID .. " must have have completed the Jedi Knight Trials and have a Jedi State of 4 to Unlock Light FRS.")
		return
	end

	JediTrials:unlockJediKnight(pTarget)

	local msg = SceneObject(pPlayer):getCustomObjectName() .. " ID: " .. SceneObject(pPlayer):getObjectID() .. " used GMFSVillage:unlockLightFrs on Player: " .. SceneObject(pTarget):getCustomObjectName() .. " ID: " .. targetID
	Logger:log(msg, LT_WARNING)

	CreatureObject(pPlayer):sendSystemMessage(SceneObject(pTarget):getCustomObjectName() .. " ID: " .. targetID .. " is now a member of the Light Jedi Enclave.")
end

function VillageGmSui.unlockDarkFrs(pPlayer, targetID)
	if (pPlayer == nil) then
		return
	end

	local pTarget = getSceneObject(targetID)

	if (pTarget == nll or not SceneObject(pTarget):isPlayerCreature()) then
		return
	end

	local pGhost = CreatureObject(pTarget):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	local jediState = PlayerObject(pGhost):getJediState()

	-- Player must have manually completed the trials
	if (jediState ~= 8) then
		local msg = SceneObject(pPlayer):getCustomObjectName() .. " ID: " .. SceneObject(pPlayer):getObjectID() .. " attempted to use GMFSVillage:unlockDarkFrs on Player: " .. SceneObject(pTarget):getCustomObjectName() .. " ID: " .. targetID
		msg = msg .. " with an invalid Jedi State of " .. jediState
		Logger:log(msg, LT_ERROR)

		CreatureObject(pPlayer):sendSystemMessage(SceneObject(pTarget):getCustomObjectName() .. " ID: " .. targetID .. " must have have completed the Jedi Knight Trials and have a Jedi State of 8 to Unlock Dark FRS.")
		return
	end

	JediTrials:unlockJediKnight(pTarget)

	local msg = SceneObject(pPlayer):getCustomObjectName() .. " ID: " .. SceneObject(pPlayer):getObjectID() .. " used GMFSVillage:unlockDarkFrs on Player: " .. SceneObject(pTarget):getCustomObjectName() .. " ID: " .. targetID
	Logger:log(msg, LT_WARNING)

	CreatureObject(pPlayer):sendSystemMessage(SceneObject(pTarget):getCustomObjectName() .. " ID: " .. targetID .. " is now a member of the Dark Jedi Enclave.")
end

function VillageGmSui.showLightRanks(pPlayer)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	PlayerObject(pGhost):showCouncilRank(JediTrials.COUNCIL_LIGHT)

	local msg = SceneObject(pPlayer):getCustomObjectName() .. " ID: " .. SceneObject(pPlayer):getObjectID() .. " used GMFSVillage:showLightRanks."
	Logger:log(msg, LT_WARNING)
end

function VillageGmSui.showDarkRanks(pPlayer)
	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	PlayerObject(pGhost):showCouncilRank(JediTrials.COUNCIL_DARK)

	local msg = SceneObject(pPlayer):getCustomObjectName() .. " ID: " .. SceneObject(pPlayer):getObjectID() .. " used GMFSVillage:showDarkRanks."
	Logger:log(msg, LT_WARNING)
end

--[[

	End of FRS Management

]]

function VillageGmSui.branchManagement(pPlayer, targetID)
	local pTarget = getSceneObject(targetID)

	if (pTarget == nil) then
		return
	end

	local sui = SuiListBox.new("VillageGmSui", "branchManagementCallback")
	sui.setTitle("Village Branch Management")
	sui.setPrompt("The statuses of " .. SceneObject(pTarget):getCustomObjectName() .. "'s force sensitive branches are listed below. Branches can be locked and unlocked from this window.")

	for i = 1, #VillageJediManagerCommon.forceSensitiveBranches, 1 do
		local rowString = getStringId("@quest/force_sensitive/utils:" .. VillageJediManagerCommon.forceSensitiveBranches[i])

		if (VillageJediManagerCommon.hasUnlockedBranch(pTarget, VillageJediManagerCommon.forceSensitiveBranches[i])) then
			rowString = rowString .. " \\#pcontrast1 (UNLOCKED)"
		else
			rowString = rowString .. " \\#pcontrast2 (Locked)"
		end

		sui.add(rowString, VillageJediManagerCommon.forceSensitiveBranches[i] .. targetID)
	end

	sui.setOkButtonText("Lock/Unlock")
	sui.sendTo(pPlayer)
end

function VillageGmSui:branchManagementCallback(pPlayer, pSui, eventIndex, args)
	local cancelPressed = (eventIndex == 1)

	if (cancelPressed) then
		return
	end

	local pPageData = LuaSuiBoxPage(pSui):getSuiPageData()

	if (pPageData == nil) then
		return
	end

	local suiPageData = LuaSuiPageData(pPageData)
	local menuOption = suiPageData:getStoredData(tostring(args))

	local targetID = string.match(menuOption, '%d+')
	local branchName = string.gsub(menuOption, targetID, "")

	local pTarget = getSceneObject(targetID)

	if (pTarget == nil) then
		printLuaError("Unable to find player in VillageGmSui:branchManagementCallback using oid " .. targetID)
		return
	end

	if (VillageJediManagerCommon.hasUnlockedBranch(pTarget, branchName)) then
		CreatureObject(pPlayer):sendSystemMessage(SceneObject(pTarget):getCustomObjectName() .. "'s " .. getStringId("@quest/force_sensitive/utils:" .. branchName) .. " has been LOCKED.")
		CreatureObject(pTarget):sendSystemMessage("Your unlock of the branch " .. getStringId("@quest/force_sensitive/utils:" .. branchName) .. " has been removed by a GM.")
		CreatureObject(pTarget):removeScreenPlayState(2, "VillageUnlockScreenPlay:" .. branchName)
	else
		CreatureObject(pPlayer):sendSystemMessage(SceneObject(pTarget):getCustomObjectName() .. "'s " .. getStringId("@quest/force_sensitive/utils:" .. branchName) .. " has been UNLOCKED.")
		VillageJediManagerCommon.unlockBranch(pTarget, branchName)
	end

	VillageGmSui.branchManagement(pPlayer, targetID)
end

function VillageGmSui.grantFsBadges(pPlayer, targetID)
	local pTarget = getSceneObject(targetID)

	if (pTarget == nil) then
		return
	end

	local pGhost = CreatureObject(pTarget):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	if (Glowing:isGlowing(pTarget)) then
		CreatureObject(pPlayer):sendSystemMessage(SceneObject(pTarget):getCustomObjectName() .. " is already Force Sensitive.")
		VillageGmSui.playerInfo(pPlayer, targetID)
		return
	end

	local badgesGranted = 0

	-- Grant 3 Jedi Exploration badges
	local jediExpBadges = getBadgeListByType("exploration_jedi")
	for i = 1, math.min(3, #jediExpBadges), 1 do
		if not PlayerObject(pGhost):hasBadge(jediExpBadges[i]) then
			PlayerObject(pGhost):awardBadge(jediExpBadges[i])
			badgesGranted = badgesGranted + 1
		end
	end

	-- Grant 2 Dangerous Exploration badges
	local dangerousBadges = getBadgeListByType("exploration_dangerous")
	for i = 1, math.min(2, #dangerousBadges), 1 do
		if not PlayerObject(pGhost):hasBadge(dangerousBadges[i]) then
			PlayerObject(pGhost):awardBadge(dangerousBadges[i])
			badgesGranted = badgesGranted + 1
		end
	end

	-- Grant 5 Easy Exploration badges
	local easyBadges = getBadgeListByType("exploration_easy")
	for i = 1, math.min(5, #easyBadges), 1 do
		if not PlayerObject(pGhost):hasBadge(easyBadges[i]) then
			PlayerObject(pGhost):awardBadge(easyBadges[i])
			badgesGranted = badgesGranted + 1
		end
	end

	-- Grant 1 Master badge
	local masterBadges = getBadgeListByType("master")
	if #masterBadges > 0 and not PlayerObject(pGhost):hasBadge(masterBadges[1]) then
		PlayerObject(pGhost):awardBadge(masterBadges[1])
		badgesGranted = badgesGranted + 1
	end

	-- Grant 3 Content badges
	local contentBadges = getBadgeListByType("content")
	for i = 1, math.min(3, #contentBadges), 1 do
		if not PlayerObject(pGhost):hasBadge(contentBadges[i]) then
			PlayerObject(pGhost):awardBadge(contentBadges[i])
			badgesGranted = badgesGranted + 1
		end
	end

	-- Set glowing state and start intro
	VillageJediManagerCommon.setJediProgressionScreenPlayState(pTarget, VILLAGE_JEDI_PROGRESSION_GLOWING)
	FsIntro:startPlayerOnIntro(pTarget)

	CreatureObject(pPlayer):sendSystemMessage(SceneObject(pTarget):getCustomObjectName() .. " has been granted " .. badgesGranted .. " badges and is now Force Sensitive (glowing).")
	CreatureObject(pTarget):sendSystemMessage("You have been granted Force Sensitive status by a GM.")

	local msg = SceneObject(pPlayer):getCustomObjectName() .. " ID: " .. SceneObject(pPlayer):getObjectID() .. " used GMFSVillage:grantFsBadges on " .. SceneObject(pTarget):getCustomObjectName() .. " ID: " .. targetID .. " granting " .. badgesGranted .. " badges"
	Logger:log(msg, LT_WARNING)

	VillageGmSui.playerInfo(pPlayer, targetID)
end

function VillageGmSui.unlockVillageAccess(pPlayer, targetID)
	local pTarget = getSceneObject(targetID)

	if (pTarget == nil) then
		return
	end

	if (not Glowing:isGlowing(pTarget)) then
		CreatureObject(pPlayer):sendSystemMessage(SceneObject(pTarget):getCustomObjectName() .. " is not Force Sensitive and cannot be granted village access.")
		return
	end

	if (VillageJediManagerCommon.isVillageEligible(pTarget)) then
		CreatureObject(pPlayer):sendSystemMessage(SceneObject(pTarget):getCustomObjectName() .. " already has village access.")
		VillageGmSui.playerInfo(pPlayer, targetID)
		return
	end

	-- Set village access state
	VillageJediManagerCommon.setJediProgressionScreenPlayState(pTarget, VILLAGE_JEDI_PROGRESSION_HAS_VILLAGE_ACCESS)

	-- Complete the village elder quest
	local QuestManager = require("managers.quest.quest_manager")
	QuestManager.completeQuest(pTarget, QuestManager.quests.FS_VILLAGE_ELDER)

	-- Grant jedi novice skill if they don't have it
	if (not CreatureObject(pTarget):hasSkill("force_title_jedi_novice")) then
		awardSkill(pTarget, "force_title_jedi_novice")
	end

	CreatureObject(pPlayer):sendSystemMessage(SceneObject(pTarget):getCustomObjectName() .. " has been granted village access.")
	CreatureObject(pTarget):sendSystemMessage("You have been granted access to the Force Sensitive village by a GM.")

	local msg = SceneObject(pPlayer):getCustomObjectName() .. " ID: " .. SceneObject(pPlayer):getObjectID() .. " used GMFSVillage:unlockVillageAccess on " .. SceneObject(pTarget):getCustomObjectName() .. " ID: " .. targetID
	Logger:log(msg, LT_WARNING)

	VillageGmSui.playerInfo(pPlayer, targetID)
end

function VillageGmSui.manageCounterStrikeBases(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local curPhase = VillageJediManagerTownship:getCurrentPhase()

	if (curPhase ~= 3) then
		return
	end

	local sui = SuiListBox.new("VillageGmSui", "manageCounterStrikeBasesCallback")
	sui.setTitle("Village CounterStrike Bases")
	sui.setPrompt("Below are the currently spawned CounterStrike bases. Select a base to get more detailed information.")

	local campList = FsCounterStrike:getPhaseCampList()
	local campTable = HelperFuncs:splitString(campList, ",")

	for i = 1, #campTable, 1 do
		local campNum = tonumber(campTable[i])
		local campLoc = FsCounterStrike.campSpawns[campNum]
		local campName = campLoc[1]

		local suiText = campName
		local theaterID = readData("VillageCounterStrikeCampID:" .. campName)
		local pTheater = getSceneObject(theaterID)

		if (pTheater == nil) then
			suiText = suiText .. " \\#pcontrast1 (CAMP OBJECT MISSING)"
		else
			if (not FsCsBaseControl:isShieldPoweredDown(pTheater)) then
				suiText = suiText .. " \\#pcontrast1 (SHIELD UP)"
			else
				suiText = suiText .. " \\#pcontrast2 (SHIELD DOWN)"
			end
		end

		sui.add(suiText, campNum)
	end

	sui.sendTo(pPlayer)
end

function VillageGmSui:manageCounterStrikeBasesCallback(pPlayer, pSui, eventIndex, args)
	local curPhase = VillageJediManagerTownship:getCurrentPhase()

	if (curPhase ~= 3) then
		return
	end

	local cancelPressed = (eventIndex == 1)

	if (cancelPressed or args == nil or tonumber(args) < 0) then
		return
	end

	local pPageData = LuaSuiBoxPage(pSui):getSuiPageData()

	if (pPageData == nil) then
		return
	end

	local suiPageData = LuaSuiPageData(pPageData)
	local campNum = tonumber(suiPageData:getStoredData(tostring(args)))

	local campLoc = FsCounterStrike.campSpawns[campNum]

	if (campLoc == nil) then
		printLuaError("Invalid camp info grabbed in VillageGmSui:manageCounterStrikeBasesCallback using camp number " .. campNum)
		return
	end

	local campName = campLoc[1]

	local sui = SuiListBox.new("VillageGmSui", "manageCounterStrikeBaseCallback")
	sui.setTitle("Village CounterStrike Base - " .. campName)

	local suiPrompt = " \\#pcontrast1 " .. "Base Name:" .. " \\#pcontrast2 " .. campName .. "\n"

	local theaterID = readData("VillageCounterStrikeCampID:" .. campName)
	local pTheater = getSceneObject(theaterID)

	if (pTheater == nil) then
		suiPrompt = suiPrompt .. " \\#pcontrast1 " .. "Theater Object:" .. " \\#pcontrast2 MISSING\n"
		sui.setPrompt(suiPrompt)
		sui.sendTo(pPlayer)
	else
		suiPrompt = suiPrompt .. " \\#pcontrast1 " .. "Theater Object:" .. " \\#pcontrast2 " .. theaterID .. "\n"
	end

	if (not FsCsBaseControl:isShieldPoweredDown(pTheater)) then
		suiPrompt = suiPrompt .. " \\#pcontrast1 " .. "Shield Status:" .. " \\#pcontrast2 UP\n"
	else
		suiPrompt = suiPrompt .. " \\#pcontrast1 " .. "Shield Status:" .. " \\#pcontrast2 DOWN\n"

		local powerDownTime = readData(theaterID .. ":shieldPowerDownTime")
		local powerDownDiff = os.time() - powerDownTime
		local diffString = self:getTimeString(powerDownDiff * 1000)
		suiPrompt = suiPrompt .. " \\#pcontrast1 " .. "Shield Taken Down At:" .. " \\#pcontrast2 " .. os.date("%c", powerDownTime) .. " (" .. diffString ..  " ago)\n"
		local storedAttackerID = readData(theaterID .. ":attackerID")

		local pAttacker = getCreatureObject(storedAttackerID)

		if (pAttacker == nil) then
			suiPrompt = suiPrompt .. " \\#pcontrast1 " .. "Current Attacker:" .. " \\#pcontrast2 UNKNOWN\n"
		else
			suiPrompt = suiPrompt .. " \\#pcontrast1 " .. "Current Attacker:" .. " \\#pcontrast2 " .. CreatureObject(pAttacker):getFirstName() .. "\n"
		end
	end

	sui.add("Reset Base", "resetCounterStrikeBase" .. theaterID)
	sui.setPrompt(suiPrompt)
	sui.sendTo(pPlayer)
end

function VillageGmSui:manageCounterStrikeBaseCallback(pPlayer, pSui, eventIndex, args)
	local cancelPressed = (eventIndex == 1)

	if (cancelPressed) then
		return
	end

	local pPageData = LuaSuiBoxPage(pSui):getSuiPageData()

	if (pPageData == nil) then
		return
	end

	local suiPageData = LuaSuiPageData(pPageData)
	local menuOption =  suiPageData:getStoredData(tostring(args))

	local targetID, pTheater
	local curPhase = VillageJediManagerTownship:getCurrentPhase()

	if (curPhase ~= 3) then
		return
	end

	if (string.find(menuOption, "%d")) then
		targetID = string.match(menuOption, '%d+')
		menuOption = string.gsub(menuOption, targetID, "")

		if (menuOption == nil) then
			return
		end

		pTheater = getSceneObject(targetID)

		if (pTheater == nil) then
			printLuaError("Unable to find theater for VillageGmSui function " .. menuOption .. " using oid " .. targetID)
			return
		end

		if (menuOption == "resetCounterStrikeBase") then
			FsCsBaseControl:resetCamp(pTheater, 0, true)
			CreatureObject(pPlayer):sendSystemMessage("Base reset.")
		end
	end
end

function VillageGmSui:getPhaseDuration()
	local eventID = getServerEventID("VillagePhaseChange")

	if (eventID == nil) then
		return
	end

	return self:getTimeString(getServerEventTimeLeft(eventID))
end

function VillageGmSui:getTimeString(miliTime)
	local timeLeft = miliTime / 1000
	local daysLeft = math.floor(timeLeft / (24 * 60 * 60))
	local hoursLeft = math.floor((timeLeft / 3600) % 24)
	local minutesLeft = math.floor((timeLeft / 60) % 60)
	local secondsLeft = math.floor(timeLeft % 60)

	return daysLeft .. "d " .. hoursLeft .. "h " .. minutesLeft .. "m " .. secondsLeft .. "s"
end
