local ObjectManager = require("managers.object.object_manager")
local Logger = require("utils.logger")

VillageJediManagerDestiny = ScreenPlay:new {}

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

	-- Select a random locked branch
	local randomIndex = getRandomNumber(1, #lockedBranches)
	local selectedBranch = lockedBranches[randomIndex]

	Logger:log("Unlocking branch: " .. selectedBranch, LT_INFO)

	-- Unlock the selected branch
	VillageJediManagerCommon.unlockBranch(pPlayer, selectedBranch)

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	-- Grant force_title_jedi_novice if they don't have it (needed to train FS skills)
	if not CreatureObject(pPlayer):hasSkill("force_title_jedi_novice") then
		awardSkill(pPlayer, "force_title_jedi_novice")
		CreatureObject(pPlayer):sendSystemMessage("You have become attuned to the Force!")
	end

	-- Ensure Jedi state is set so skill prerequisites pass.
	if (pGhost ~= nil and not PlayerObject(pGhost):isJedi()) then
		PlayerObject(pGhost):setJediState(1)
	end

	-- Send success message
	CreatureObject(pPlayer):sendSystemMessage("The Holocron of Destiny glows with ancient power as it reveals new knowledge!")

	-- Destroy the holocron
	SceneObject(pSceneObject):destroyObjectFromWorld(true)
	SceneObject(pSceneObject):destroyObjectFromDatabase(true)
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

return VillageJediManagerDestiny
