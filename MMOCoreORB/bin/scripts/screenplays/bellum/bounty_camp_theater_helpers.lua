-- Shared logic for Bellum bounty camp GoToTheater chapters (Mellichae-style camp spawn, simplified).
-- No power shrines, no healing pulses. Credits are granted on kill via screenplay (creatures have empty loot).

local SpawnMobiles = require("utils.spawn_mobiles")

local BellumBountyCampTheaterHelpers = {}

-- Decorative camp only (Mellichae outro theater props minus green/red Jedi shrines).
BellumBountyCampTheaterHelpers.CAMP_DECOR = {
	{ template = "object/tangible/furniture/all/frn_all_light_lamp_table_s03.iff", xDiff = 0.52, zDiff = 1.14, yDiff = -3.37, heading = 0 },
	{ template = "object/tangible/camp/camp_crate_s1.iff", xDiff = -3.78, zDiff = 0, yDiff = 0.91, heading = -18.91 },
	{ template = "object/weapon/ranged/pistol/pistol_dl44_metal.iff", xDiff = 0.13, zDiff = 1.17, yDiff = -2.9, heading = -9.74 },
	{ template = "object/tangible/camp/camp_crate_s1.iff", xDiff = 1.74, zDiff = 0, yDiff = -2.84, heading = -80.214 },
	{ template = "object/static/structure/general/camp_lawn_chair_s01.iff", xDiff = 3.74, zDiff = 0, yDiff = 2.42, heading = -47.74 },
	{ template = "object/static/structure/general/camp_lawn_chair_s01.iff", xDiff = 2.04, zDiff = 0, yDiff = 1.55, heading = 0.39 },
	{ template = "object/static/structure/general/camp_lawn_chair_s01.iff", xDiff = -0.26, zDiff = 0, yDiff = 5.28, heading = 111.15 },
	{ template = "object/static/structure/general/campfire_fresh.iff", xDiff = 2.30, zDiff = 0, yDiff = 4.01, heading = 0 },
	{ template = "object/static/structure/general/camp_spit_s01.iff", xDiff = 1.72, zDiff = 0, yDiff = 3.92, heading = 83.59 },
	{ template = "object/static/structure/general/camp_spit_s01.iff", xDiff = 2.76, zDiff = 0, yDiff = 4.21, heading = 63.79 },
	{ template = "object/static/structure/general/camp_spit_s01.iff", xDiff = 2.33, zDiff = 0, yDiff = 3.3, heading = -24.13 },
	{ template = "object/static/structure/general/trash_pile_s01.iff", xDiff = -3.48, zDiff = 0, yDiff = 2.61, heading = -120.3 },
	{ template = "object/static/structure/tatooine/debris_tatt_crate_1.iff", xDiff = 1.78, zDiff = 0, yDiff = -2.7, heading = 7.45 },
	{ template = "object/static/structure/tatooine/debris_tatt_drum_dented_1.iff", xDiff = 1.61, zDiff = 0, yDiff = -3.92, heading = -82.51 },
	{ template = "object/static/structure/tatooine/debris_tatt_crate_metal_1.iff", xDiff = -2.18, zDiff = 0, yDiff = 1.27, heading = -12.03 },
	{ template = "object/static/structure/general/camp_cot_s01.iff", xDiff = -1.2, zDiff = 0, yDiff = -4.84, heading = -20.05 },
	{ template = "object/static/structure/tatooine/tent_house_tatooine_style_01.iff", xDiff = -2.46, zDiff = 0, yDiff = -2.15, heading = -140.38 },
	{ template = "object/static/structure/tatooine/debris_tatt_drum_dented_1.iff", xDiff = 0.32, zDiff = 0, yDiff = -3.04, heading = 9.74 },
	{ template = "object/static/structure/general/trash_pile_s01.iff", xDiff = -3.64, zDiff = 0, yDiff = 2.997, heading = 156.99 },
	{ template = "object/static/structure/tatooine/debris_tatt_crate_1.iff", xDiff = -2.3, zDiff = 0, yDiff = 1.28, heading = -110.58 },
	{ template = "object/static/structure/general/camp_cot_s01.iff", xDiff = -4.51, zDiff = 0, yDiff = -4.41, heading = 39.53 },
	{ template = "object/static/structure/general/camp_cot_s01.iff", xDiff = -5.42, zDiff = 0, yDiff = -1.45, heading = 99.69 },
	{ template = "object/static/structure/tatooine/debris_tatt_crate_metal_1.iff", xDiff = 1.92, zDiff = 0, yDiff = -1.88, heading = -12.03 },
	{ template = "object/static/item/item_container_organic_food.iff", xDiff = -3.13, zDiff = 0, yDiff = 1.086, heading = 137.69 },
}

local function resolveCreditRecipient(pAttacker)
	if (pAttacker == nil) then
		return nil
	end
	if (SceneObject(pAttacker):isPlayerCreature()) then
		return pAttacker
	end
	return nil
end

local function spynetDbg(pPlayer, msg)
	if (MandoWayOfLife == nil or MandoWayOfLife.SPYNET_BOUNTY_DEBUG_VERBOSE ~= true) then
		return
	end
	if (MandoWayOfLife.logSpynetDebug ~= nil) then
		MandoWayOfLife:logSpynetDebug(pPlayer, msg)
	end
end

function BellumBountyCampTheaterHelpers.applyBountyMobPresentation(theater, pPlayer, spawnedList, markIndex)
	if (spawnedList == nil or markIndex == nil or markIndex < 1) then
		return
	end
	local markLevel = tonumber(theater.markLevel) or 50
	local henchLevel = tonumber(theater.henchLevel) or 42
	local markName = theater.markDisplayName or "Wanted Outlaw"
	local henchName = theater.henchDisplayName or "Outlaw Thief"

	for i = 1, #spawnedList, 1 do
		local pMob = spawnedList[i]
		if (SpawnMobiles.isValidMobile(pMob)) then
			if (i == markIndex) then
				AiAgent(pMob):setLevel(markLevel)
				CreatureObject(pMob):setCustomObjectName(markName)
			else
				AiAgent(pMob):setLevel(henchLevel)
				CreatureObject(pMob):setCustomObjectName(henchName)
			end
		end
	end
	local pOwn = spawnedList and spawnedList[markIndex]
	if (pOwn ~= nil and SpawnMobiles.isValidMobile(pOwn)) then
		spynetDbg(pPlayer, string.format(
			"bountyCamp applyPresentation: task=%s markOid=%s markLevel=%s henchLevel=%s",
			tostring(theater.taskName),
			tostring(SceneObject(pOwn):getObjectID()),
			tostring(theater.markLevel),
			tostring(theater.henchLevel)
		))
	end
end

function BellumBountyCampTheaterHelpers.setupKillObservers(theater, pPlayer, spawnedList, markIndex)
	if (pPlayer == nil or spawnedList == nil or markIndex == nil or markIndex < 1) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local taskName = theater.taskName

	for i = 1, #spawnedList, 1 do
		local pMob = spawnedList[i]
		if (SpawnMobiles.isValidMobile(pMob)) then
			local mobID = SceneObject(pMob):getObjectID()
			writeData(mobID .. taskName .. ":bountyOwner", playerID)
			writeData(mobID .. taskName .. ":isMark", (i == markIndex) and 1 or 0)
			createObserver(OBJECTDESTRUCTION, taskName, "notifyBountyMobileKilled", pMob)
		end
	end
	local obs = 0
	for j = 1, #spawnedList, 1 do
		if (SpawnMobiles.isValidMobile(spawnedList[j])) then
			obs = obs + 1
		end
	end
	spynetDbg(pPlayer, string.format("bountyCamp setupKillObservers: task=%s validMobiles=%s markIndex=%s", taskName, tostring(obs), tostring(markIndex)))
end

function BellumBountyCampTheaterHelpers.notifyBountyMobileKilled(theater, pVictim, pAttacker)
	if (pVictim == nil) then
		return 1
	end

	local mobileID = SceneObject(pVictim):getObjectID()
	local taskName = theater.taskName
	local ownerID = readData(mobileID .. taskName .. ":bountyOwner")

	if (ownerID == nil or ownerID == 0) then
		return 1
	end

	if (readData(ownerID .. taskName .. ":campFinished") == 1) then
		deleteData(mobileID .. taskName .. ":bountyOwner")
		deleteData(mobileID .. taskName .. ":isMark")
		return 1
	end

	local isMark = readData(mobileID .. taskName .. ":isMark")
	local pOwner = getSceneObject(ownerID)

	spynetDbg(pOwner, string.format(
		"bountyCamp notifyKilled: task=%s victimOid=%s isMark=%s attackerIsPlayer=%s",
		tostring(taskName),
		tostring(mobileID),
		tostring(isMark),
		tostring(pAttacker ~= nil and SceneObject(pAttacker):isPlayerCreature())
	))

	deleteData(mobileID .. taskName .. ":bountyOwner")
	deleteData(mobileID .. taskName .. ":isMark")

	local pPayee = resolveCreditRecipient(pAttacker)
	if (pPayee ~= nil) then
		local loH = tonumber(theater.bountyHenchCreditMin) or 500
		local hiH = tonumber(theater.bountyHenchCreditMax) or 1000
		local loM = tonumber(theater.bountyMarkCreditMin) or 7500
		local hiM = tonumber(theater.bountyMarkCreditMax) or 12000

		if (isMark == 1) then
			local amt = getRandomNumber(loM, hiM)
			CreatureObject(pPayee):addCashCredits(amt, true)
			CreatureObject(pPayee):sendSystemMessage("Spynet bounty paid: " .. tostring(amt) .. " credits (mark).")
		else
			local amt = getRandomNumber(loH, hiH)
			CreatureObject(pPayee):addCashCredits(amt, true)
			CreatureObject(pPayee):sendSystemMessage("Spynet bounty paid: " .. tostring(amt) .. " credits (associate).")
		end
	end

	if (isMark == 1 and pOwner ~= nil) then
		-- Only complete the Spynet trial while the private contract is active. Setting :campFinished before
		-- completePrivateContract could soft-lock the player (campFinished=1 but chapter never advanced).
		local active = (MandoWayOfLife ~= nil and MandoWayOfLife.readInt ~= nil and MandoWayOfLife:readInt(pOwner, "privateContractActive") == 1)
		if (not active) then
			CreatureObject(pOwner):sendSystemMessage(
				"[Spynet trial] The mark fell but your trial was not active. Speak with the Mandalorian Operative on Corellia."
			)
			if (MandoWayOfLife ~= nil and MandoWayOfLife.logDiagPlayer ~= nil) then
				MandoWayOfLife:logDiagPlayer(pOwner, string.format(
					"notifyBountyMobileKilled: mark kill skipped (privateContractActive~=1) task=%s ownerOid=%s",
					tostring(taskName),
					tostring(ownerID)
				))
			end
		else
			if (theater.onSpynetMarkDown ~= nil) then
				spynetDbg(pOwner, string.format("bountyCamp markDown: task=%s -> onSpynetMarkDown (completePrivateContract path)", tostring(taskName)))
				theater:onSpynetMarkDown(pOwner)
			else
				spynetDbg(pOwner, string.format("bountyCamp markDown: task=%s -> theater:finish only", tostring(taskName)))
				theater:finish(pOwner)
			end
			writeData(ownerID .. taskName .. ":campFinished", 1)
		end
	end

	return 1
end

function BellumBountyCampTheaterHelpers.clearCampFlags(theater, pPlayer)
	if (pPlayer == nil) then
		return
	end
	deleteData(SceneObject(pPlayer):getObjectID() .. theater.taskName .. ":campFinished")
end

return BellumBountyCampTheaterHelpers
