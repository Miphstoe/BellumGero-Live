JediManager = require("managers.jedi.jedi_manager")
local Logger = require("utils.logger")
local QuestManager = require("managers.quest.quest_manager")
VillageJediManagerDestiny = require("screenplays.village.village_jedi_manager_destiny")

jediManagerName = "VillageJediManager"

NOTINABUILDING = 0

NUMBEROFTREESTOMASTER = 6

VillageJediManager = JediManager:new {
	screenplayName = jediManagerName,
	jediManagerName = jediManagerName,
	jediProgressionType = VILLAGEJEDIPROGRESSION,
	startingEvent = nil,
}

-- Handling of the useItem event.
-- @param pSceneObject pointer to the item object.
-- @param itemType the type of item that is used.
-- @param pPlayer pointer to the creature object that used the item.
function VillageJediManager:useItem(pSceneObject, itemType, pPlayer)
	if (pSceneObject == nil or pPlayer == nil) then
		return
	end

	Logger:log("useItem called with item type " .. itemType, LT_INFO)
	if itemType == ITEMHOLOCRON then
		VillageJediManagerHolocron.useHolocron(pSceneObject, pPlayer)
	end
	if itemType == ITEMWAYPOINTDATAPAD then
		SithShadowEncounter:useWaypointDatapad(pSceneObject, pPlayer)
	end
	if itemType == ITEMTHEATERDATAPAD then
		SithShadowIntroTheater:useTheaterDatapad(pSceneObject, pPlayer)
	end
	if itemType == ITEMHOLOCRONDESTINY then
		VillageJediManagerDestiny.useHolocronOfDestiny(pSceneObject, pPlayer)
	end
end

-- Handling of the checkForceStatus command.
-- @param pPlayer pointer to the creature object of the player who performed the command
function VillageJediManager:checkForceStatusCommand(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local playerId = SceneObject(pPlayer):getObjectID()
	local started = readData(playerId .. ":bg_force_path_started")
	local shrine1 = readData(playerId .. ":bg_force_shrine_1")
	local shrine2 = readData(playerId .. ":bg_force_shrine_2")
	local shrine3 = readData(playerId .. ":bg_force_shrine_3")
	local crystalGiven = readData(playerId .. ":bg_force_crystal_given")

	if (crystalGiven == 1) then
		CreatureObject(pPlayer):sendSystemMessage("You feel the Force running through you, seek out Holocron's of Destiny to learn the way.")
		return
	end

	if (started == 1) then
		if (shrine1 ~= 1) then
			CreatureObject(pPlayer):sendSystemMessage("Go seek the Shrine of the Call.")
			return
		elseif (shrine2 ~= 1) then
			CreatureObject(pPlayer):sendSystemMessage("Go seek the Shrine of the Vision.")
			return
		elseif (shrine3 ~= 1) then
			CreatureObject(pPlayer):sendSystemMessage("Go seek the Shrine of the Stillness.")
			return
		else
			CreatureObject(pPlayer):sendSystemMessage("You feel Inner Peace, go seek the advice of The Hermit on Dathomir.")
			return
		end
	end

	Glowing:checkForceStatusCommand(pPlayer)
end

-- Handling of the onPlayerLoggedIn event. The progression of the player will be checked and observers will be registered.
-- @param pPlayer pointer to the creature object of the player who logged in.
function VillageJediManager:onPlayerLoggedIn(pPlayer)
	if (pPlayer == nil) then
		return
	end

	Glowing:onPlayerLoggedIn(pPlayer)

	if (VillageJediManagerCommon.isVillageEligible(pPlayer) and not CreatureObject(pPlayer):hasSkill("force_title_jedi_novice")) then
		awardSkill(pPlayer, "force_title_jedi_novice")
	end

	if (FsIntro:isOnIntro(pPlayer)) then
		FsIntro:onLoggedIn(pPlayer)
	end

	if (FsOutro:isOnOutro(pPlayer)) then
		FsOutro:onLoggedIn(pPlayer)
	end

	-- Disabled: Village quests are no longer active
	-- FsPhase1:onLoggedIn(pPlayer)
	-- FsPhase2:onLoggedIn(pPlayer)
	-- FsPhase3:onLoggedIn(pPlayer)
	-- FsPhase4:onLoggedIn(pPlayer)

	if (not VillageCommunityCrafting:isOnActiveCrafterList(pPlayer)) then
		VillageCommunityCrafting:removeSchematics(pPlayer, 2)
		VillageCommunityCrafting:removeSchematics(pPlayer, 3)
	end

	JediTrials:onPlayerLoggedIn(pPlayer)
end

function VillageJediManager:onPlayerLoggedOut(pPlayer)
	if (pPlayer == nil) then
		return
	end

	if (FsIntro:isOnIntro(pPlayer)) then
		FsIntro:onLoggedOut(pPlayer)
	end

	if (FsOutro:isOnOutro(pPlayer)) then
		FsOutro:onLoggedOut(pPlayer)
	end

	-- Disabled: Village quests are no longer active
	-- FsPhase1:onLoggedOut(pPlayer)
	-- FsPhase2:onLoggedOut(pPlayer)
	-- FsPhase3:onLoggedOut(pPlayer)
end

--Check for force skill prerequisites
function VillageJediManager:canLearnSkill(pPlayer, skillName)
	if string.find(skillName, "force_sensitive") ~= nil then
		local branchName = string.match(skillName, "^(force_sensitive_.+)_%d%d$")
		if branchName ~= nil then
			if not VillageJediManagerCommon.hasUnlockedBranch(pPlayer, branchName) then
				return false
			end
			return true
		end

		local treePrefix = string.match(skillName, "^(force_sensitive_.+)_novice$")
		if treePrefix == nil then
			treePrefix = string.match(skillName, "^(force_sensitive_.+)_master$")
		end
		if treePrefix ~= nil then
			for i = 1, #VillageJediManagerCommon.forceSensitiveBranches, 1 do
				local branch = VillageJediManagerCommon.forceSensitiveBranches[i]
				if (string.find(branch, treePrefix .. "_", 1, true) == 1 and VillageJediManagerCommon.hasUnlockedBranch(pPlayer, branch)) then
					return true
				end
			end

			return false
		end

		-- Default deny for any other force_sensitive skills.
		return false
	end

	if skillName == "force_title_jedi_rank_01" and CreatureObject(pPlayer):getForceSensitiveSkillCount(false) < 24 then
		return false
	end

	if skillName == "force_title_jedi_rank_03" and not CreatureObject(pPlayer):villageKnightPrereqsMet("") then
		return false
	end

	return true
end

--Check to ensure force skill prerequisites are maintained
function VillageJediManager:canSurrenderSkill(pPlayer, skillName)

	if skillName == "force_title_jedi_rank_02" or skillName == "force_title_jedi_novice" then
		CreatureObject(pPlayer):sendSystemMessage("@jedi_spam:revoke_force_title")
		return false
	end

	if string.find(skillName, "force_sensitive_") and CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_02") and CreatureObject(pPlayer):getForceSensitiveSkillCount(false) <= 24 then
		CreatureObject(pPlayer):sendSystemMessage("@jedi_spam:revoke_force_sensitive")
		return false
	end

	if string.find(skillName, "force_discipline_") and CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_03") and not CreatureObject(pPlayer):villageKnightPrereqsMet(skillName) then
		return false
	end

	return true
end

-- Handling of the onFSTreesCompleted event.
-- @param pPlayer pointer to the creature object of the player
function VillageJediManager:onFSTreeCompleted(pPlayer, branch)
	if (pPlayer == nil) then
		return
	end

	if (QuestManager.hasCompletedQuest(pPlayer, QuestManager.quests.OLD_MAN_FINAL) or VillageJediManagerCommon.hasJediProgressionScreenPlayState(pPlayer, VILLAGE_JEDI_PROGRESSION_COMPLETED_VILLAGE) or VillageJediManagerCommon.hasJediProgressionScreenPlayState(pPlayer, VILLAGE_JEDI_PROGRESSION_DEFEATED_MELLIACHAE)) then
		return
	end

	if (VillageJediManagerCommon.getLearnedForceSensitiveBranches(pPlayer) >= NUMBEROFTREESTOMASTER) then
		VillageJediManagerCommon.setJediProgressionScreenPlayState(pPlayer, VILLAGE_JEDI_PROGRESSION_COMPLETED_VILLAGE)
		FsOutro:startOldMan(pPlayer)
	end
end

function VillageJediManager:onSkillRevoked(pPlayer, pSkill)
	if (pPlayer == nil) then
		return
	end

	if (JediTrials:isOnPadawanTrials(pPlayer) or JediTrials:isOnKnightTrials(pPlayer)) then
		JediTrials:droppedSkillDuringTrials(pPlayer, pSkill)
	end
end

registerScreenPlay("VillageJediManager", true)

return VillageJediManager
