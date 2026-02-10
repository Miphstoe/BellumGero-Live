local ObjectManager = require("managers.object.object_manager")
local Logger = require("utils.logger")

VillageJediManagerDestiny = ScreenPlay:new {}

VillageJediManagerDestiny.branchCategories = {
	crafting = {
		name = "Crafting Mastery",
		prefix = "force_sensitive_crafting_mastery_",
	},
	senses = {
		name = "Heightened Senses",
		prefix = "force_sensitive_heightened_senses_",
	},
	reflexes = {
		name = "Enhanced Reflexes",
		prefix = "force_sensitive_enhanced_reflexes_",
	},
	combat = {
		name = "Combat Prowess",
		prefix = "force_sensitive_combat_prowess_",
	},
}

-- Handle use of Holocron of Destiny
-- @param pSceneObject pointer to the holocron object.
-- @param pPlayer pointer to the creature object that used the holocron.
function VillageJediManagerDestiny.useHolocronOfDestiny(pSceneObject, pPlayer)
	if (pSceneObject == nil or pPlayer == nil) then
		return
	end

	Logger:log("useHolocronOfDestiny called", LT_INFO)

	-- Check if player has village access (is Force Sensitive and completed village intro)
	if not VillageJediManagerCommon.isVillageEligible(pPlayer) then
		CreatureObject(pPlayer):sendSystemMessage("The holocron remains inert. Only those strong in the Force can unlock its secrets.")
		return
	end

	-- Check if holocron is in player's inventory
	if not SceneObject(pSceneObject):isASubChildOf(pPlayer) then
		CreatureObject(pPlayer):sendSystemMessage("You must be holding the Holocron of Destiny to use it.")
		return
	end

	-- Get list of locked branches
	local lockedBranches = VillageJediManagerDestiny.getLockedBranches(pPlayer)

	-- If no locked branches remain, don't consume the item
	if #lockedBranches == 0 then
		CreatureObject(pPlayer):sendSystemMessage("The holocron pulses briefly, but you have already unlocked all the knowledge it contains.")
		return
	end

	VillageJediManagerDestiny.sendCategoryChoiceSui(pSceneObject, pPlayer)
end

function VillageJediManagerDestiny.sendCategoryChoiceSui(pSceneObject, pPlayer)
	if (pSceneObject == nil or pPlayer == nil) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	writeData(playerID .. ":holocronDestinyOid", SceneObject(pSceneObject):getObjectID())

	local sui = SuiListBox.new("VillageJediManagerDestiny", "categoryChoiceCallback")
	sui.setTitle("Holocron of Destiny")
	sui.setPrompt("Choose a path. The Holocron will reveal a random branch within the path you select.")

	local hasOptions = false

	for key, data in pairs(VillageJediManagerDestiny.branchCategories) do
		local locked = VillageJediManagerDestiny.getLockedBranchesByCategory(pPlayer, data.prefix)
		if (#locked > 0) then
			hasOptions = true
			sui.add(data.name, key)
		end
	end

	if (not hasOptions) then
		deleteData(playerID .. ":holocronDestinyOid")
		CreatureObject(pPlayer):sendSystemMessage("The holocron pulses briefly, but you have already unlocked all the knowledge it contains.")
		return
	end

	sui.sendTo(pPlayer)
end

function VillageJediManagerDestiny:categoryChoiceCallback(pPlayer, pSui, eventIndex, args)
	local cancelPressed = (eventIndex == 1)

	if (pPlayer == nil) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local holocronOid = readData(playerID .. ":holocronDestinyOid")

	if (cancelPressed or args == nil or tonumber(args) < 0) then
		deleteData(playerID .. ":holocronDestinyOid")
		return
	end

	local pPageData = LuaSuiBoxPage(pSui):getSuiPageData()
	if (pPageData == nil) then
		deleteData(playerID .. ":holocronDestinyOid")
		return
	end

	local suiPageData = LuaSuiPageData(pPageData)
	local selection = suiPageData:getStoredData(tostring(args))
	if (selection == nil or selection == "") then
		deleteData(playerID .. ":holocronDestinyOid")
		return
	end

	local category = VillageJediManagerDestiny.branchCategories[selection]
	if (category == nil) then
		deleteData(playerID .. ":holocronDestinyOid")
		return
	end

	local locked = VillageJediManagerDestiny.getLockedBranchesByCategory(pPlayer, category.prefix)
	if (#locked == 0) then
		deleteData(playerID .. ":holocronDestinyOid")
		CreatureObject(pPlayer):sendSystemMessage("The holocron grows quiet. There are no locked branches in that path.")
		return
	end

	local pSceneObject = getSceneObject(holocronOid)
	if (pSceneObject == nil or not SceneObject(pSceneObject):isASubChildOf(pPlayer)) then
		deleteData(playerID .. ":holocronDestinyOid")
		CreatureObject(pPlayer):sendSystemMessage("You must be holding the Holocron of Destiny to use it.")
		return
	end

	local randomIndex = getRandomNumber(1, #locked)
	local selectedBranch = locked[randomIndex]

	Logger:log("Unlocking branch: " .. selectedBranch, LT_INFO)
	VillageJediManagerCommon.unlockBranch(pPlayer, selectedBranch)

	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if not CreatureObject(pPlayer):hasSkill("force_title_jedi_novice") then
		awardSkill(pPlayer, "force_title_jedi_novice")
		CreatureObject(pPlayer):sendSystemMessage("You have become attuned to the Force!")
	end

	if (pGhost ~= nil and not PlayerObject(pGhost):isJedi()) then
		PlayerObject(pGhost):setJediState(1)
	end

	CreatureObject(pPlayer):sendSystemMessage("The Holocron of Destiny glows with ancient power as it reveals new knowledge!")

	SceneObject(pSceneObject):destroyObjectFromWorld(true)
	SceneObject(pSceneObject):destroyObjectFromDatabase(true)
	deleteData(playerID .. ":holocronDestinyOid")
end

-- Get list of branches that are NOT yet unlocked for the player
-- @param pPlayer pointer to the creature object.
-- @return table of locked branch names.
function VillageJediManagerDestiny.getLockedBranches(pPlayer)
	if (pPlayer == nil) then
		return {}
	end

	local lockedBranches = {}

	-- Iterate through all 16 force sensitive branches
	for i = 1, #VillageJediManagerCommon.forceSensitiveBranches, 1 do
		local branch = VillageJediManagerCommon.forceSensitiveBranches[i]

		-- If branch is NOT unlocked, add it to the locked list
		if not VillageJediManagerCommon.hasUnlockedBranch(pPlayer, branch) then
			table.insert(lockedBranches, branch)
		end
	end

	return lockedBranches
end

function VillageJediManagerDestiny.getLockedBranchesByCategory(pPlayer, prefix)
	if (pPlayer == nil or prefix == nil) then
		return {}
	end

	local lockedBranches = {}

	for i = 1, #VillageJediManagerCommon.forceSensitiveBranches, 1 do
		local branch = VillageJediManagerCommon.forceSensitiveBranches[i]
		if (string.find(branch, "^" .. prefix) and not VillageJediManagerCommon.hasUnlockedBranch(pPlayer, branch)) then
			table.insert(lockedBranches, branch)
		end
	end

	return lockedBranches
end

return VillageJediManagerDestiny
