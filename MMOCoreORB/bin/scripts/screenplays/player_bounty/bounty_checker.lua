----------------------------------------------------------------------
-- Bounty Checker - Debug Tool
-- Call this to check bounty status on any player
----------------------------------------------------------------------

BountyChecker = {}

-- Check if a specific player has a bounty
function BountyChecker:checkPlayerBounty(playerName)
	local pPlayer = getPlayerByName(playerName)

	if pPlayer == nil then
		print("ERROR: Player '" .. playerName .. "' not found or not online")
		return false
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local pZone = SceneObject(pPlayer):getZone()

	if pZone == nil then
		print("ERROR: Could not get Zone")
		return false
	end

	local pZoneServer = pZone:getZoneServer()

	if pZoneServer == nil then
		print("ERROR: Could not get ZoneServer")
		return false
	end

	local missionManager = pZoneServer:getMissionManager()

	if missionManager == nil then
		print("ERROR: Could not get MissionManager")
		return false
	end

	print("===== BOUNTY CHECK: " .. playerName .. " =====")
	print("Player ID: " .. playerID)

	local hasBounty = missionManager:hasPlayerBountyTargetInList(playerID)
	print("Has Active Bounty: " .. tostring(hasBounty))

	-- Check Jedi status
	local creature = CreatureObject(pPlayer)
	local isJediRank2 = creature:hasSkill("force_title_jedi_rank_02")
	local isJediRank3 = creature:hasSkill("force_title_jedi_rank_03")

	print("Is Jedi Rank 2+: " .. tostring(isJediRank2))
	print("Is Jedi Rank 3+: " .. tostring(isJediRank3))

	-- Check visibility (for Jedi)
	local pGhost = creature:getPlayerObject()
	if pGhost ~= nil then
		local visibility = PlayerObject(pGhost):getVisibility()
		print("Jedi Visibility: " .. visibility)
	end

	-- Check if online
	print("Is Online: true (player is loaded)")

	print("=====================================")

	return hasBounty
end

-- Check if a bounty hunter can see a target
function BountyChecker:checkBountyHunterView(hunterName, targetName)
	local pHunter = getPlayerByName(hunterName)
	local pTarget = getPlayerByName(targetName)

	if pHunter == nil then
		print("ERROR: Hunter '" .. hunterName .. "' not found")
		return
	end

	if pTarget == nil then
		print("ERROR: Target '" .. targetName .. "' not found")
		return
	end

	local hunterCreature = CreatureObject(pHunter)
	local targetCreature = CreatureObject(pTarget)

	print("===== BOUNTY HUNTER VIEW CHECK =====")
	print("Hunter: " .. hunterName)
	print("Target: " .. targetName)
	print("")

	-- Check hunter skills
	local hasBHNovice = hunterCreature:hasSkill("combat_bountyhunter_novice")
	local hasBHInv1 = hunterCreature:hasSkill("combat_bountyhunter_investigation_01")
	local hasBHInv2 = hunterCreature:hasSkill("combat_bountyhunter_investigation_02")
	local hasBHInv3 = hunterCreature:hasSkill("combat_bountyhunter_investigation_03")

	print("Hunter BH Novice: " .. tostring(hasBHNovice))
	print("Hunter BH Investigation 1: " .. tostring(hasBHInv1))
	print("Hunter BH Investigation 2: " .. tostring(hasBHInv2))
	print("Hunter BH Investigation 3: " .. tostring(hasBHInv3))
	print("")

	if not hasBHInv3 then
		print("WARNING: Player bounties only show for Investigation 3!")
		print("Hunter needs: combat_bountyhunter_investigation_03")
		print("")
	end

	-- Check account restriction
	local hunterGhost = hunterCreature:getPlayerObject()
	local targetGhost = targetCreature:getPlayerObject()

	if hunterGhost ~= nil and targetGhost ~= nil then
		local hunterAccountID = PlayerObject(hunterGhost):getAccountID()
		local targetAccountID = PlayerObject(targetGhost):getAccountID()
		local sameAccount = (hunterAccountID == targetAccountID)

		print("Same Account: " .. tostring(sameAccount))
		print("Same Account Missions Enabled: " .. tostring(enable_same_account_bounty_missions == "true"))

		if sameAccount and enable_same_account_bounty_missions ~= "true" then
			print("BLOCKED: Same account bounties are disabled!")
		end
		print("")
	end

	-- Check if target has bounty
	local targetID = SceneObject(pTarget):getObjectID()
	local pZone = SceneObject(pTarget):getZone()

	if pZone ~= nil then
		local pZoneServer = pZone:getZoneServer()

		if pZoneServer ~= nil then
			local missionManager = pZoneServer:getMissionManager()

			if missionManager ~= nil then
				local hasBounty = missionManager:hasPlayerBountyTargetInList(targetID)
				print("Target Has Bounty: " .. tostring(hasBounty))
			end
		end
	end

	print("=====================================")
end

-- List all active bounties
function BountyChecker:listAllBounties()
	print("===== ALL ACTIVE BOUNTIES =====")
	print("Note: This requires server-side support to iterate playerBountyList")
	print("Try using: /bountyDebug <playerName> in-game")
	print("================================")
end

return BountyChecker
