local QuestManager = require("managers.quest.quest_manager")

BgAureliaRiteOfAwakening = ScreenPlay:new {
	-- ScreenPlay
	screenplayName = "BgAureliaRiteOfAwakening",
	numberOfActs = 1,
}

registerScreenPlay("BgAureliaRiteOfAwakening", true)

-- Config: edit these coordinates as needed.
BgAureliaRiteOfAwakening.RITE_PLANET = "dathomir"
BgAureliaRiteOfAwakening.RITE_STONE_TEMPLATE = "object/tangible/jedi/force_shrine_stone.iff"
BgAureliaRiteOfAwakening.RITE_STONE_NAME = "Ritual Stone"
BgAureliaRiteOfAwakening.RITE_WAYPOINT_NAME = "Aurelia - Rite of Awakening"
BgAureliaRiteOfAwakening.RITE_WAYPOINT_DESC = "Return to the center of Aurelia"
BgAureliaRiteOfAwakening.RITE_ADD_WAYPOINT = true

BgAureliaRiteOfAwakening.stoneConfig = {
	{
		key = "bg_aurelia_rite_stone_1",
		name = "Rite Stone I",
		x = 5280, z = 78, y = -4210, heading = 0,
	},
	{
		key = "bg_aurelia_rite_stone_2",
		name = "Rite Stone II",
		x = 5262, z = 78, y = -4162, heading = 0,
	},
	{
		key = "bg_aurelia_rite_stone_3",
		name = "Rite Stone III",
		x = 5202, z = 78, y = -4188, heading = 0,
	},
	{
		key = "bg_aurelia_rite_stone_4",
		name = "Rite Stone IV",
		x = 5225, z = 78, y = -4256, heading = 0,
	},
	{
		-- Center stone (final trigger)
		key = "bg_aurelia_rite_stone_5",
		name = "Rite Stone V",
		x = 5236, z = 78, y = -4195, heading = 0,
	},
}

BgAureliaRiteOfAwakening.stoneObjectIds = {}

function BgAureliaRiteOfAwakening:start()
	self:spawnStones()
end

--[[
INSTALL NOTES:
1) Register screenplay: add includeFile("bellum/bg_aurelia_rite_of_awakening.lua") to `MMOCoreORB/bin/scripts/screenplays/screenplays.lua`.
2) Place stones: keep this screenplay enabled (it spawns stones on server start) or spawn/place objects manually via the `stoneConfig` coords.
   Each stone must use the menu component `BgAureliaRiteStoneMenuComponent`.
3) Hook trigger: replace the old FsOutro start call in `MMOCoreORB/bin/scripts/managers/jedi/village_jedi_manager.lua` to call
   `BgAureliaRiteOfAwakening:startRite(pPlayer)` when the 6 village branches are complete.
4) Custom Mallichae template: see `MMOCoreORB/bin/scripts/mobile/bellum/mellichae_bg_rite.lua` and include it in
   `MMOCoreORB/bin/scripts/mobile/serverobjects.lua`.
]]

function BgAureliaRiteOfAwakening:spawnStones()
	self.stoneObjectIds = {}

	for i = 1, #self.stoneConfig, 1 do
		local cfg = self.stoneConfig[i]
		local pStone = spawnSceneObject(self.RITE_PLANET, self.RITE_STONE_TEMPLATE, cfg.x, cfg.z, cfg.y, 0, math.rad(cfg.heading or 0))

		if (pStone ~= nil) then
			SceneObject(pStone):setObjectMenuComponent("BgAureliaRiteStoneMenuComponent")
			SceneObject(pStone):setCustomObjectName(cfg.name or self.RITE_STONE_NAME)
			local stoneId = SceneObject(pStone):getObjectID()
			self.stoneObjectIds[i] = stoneId
			writeData("bg_aurelia_rite:stone:" .. stoneId, i)
		end
	end
end

function BgAureliaRiteOfAwakening:getPlayerId(pPlayer)
	if (pPlayer == nil) then
		return nil
	end

	return SceneObject(pPlayer):getObjectID()
end

function BgAureliaRiteOfAwakening:getDataKey(pPlayer, key)
	local playerId = self:getPlayerId(pPlayer)
	if (playerId == nil) then
		return nil
	end

	return playerId .. ":" .. key
end

function BgAureliaRiteOfAwakening:getNumber(pPlayer, key)
	local dataKey = self:getDataKey(pPlayer, key)
	if (dataKey == nil) then
		return 0
	end

	return tonumber(readData(dataKey)) or 0
end

function BgAureliaRiteOfAwakening:setNumber(pPlayer, key, value)
	local dataKey = self:getDataKey(pPlayer, key)
	if (dataKey == nil) then
		return
	end

	writeData(dataKey, value)
end

function BgAureliaRiteOfAwakening:clearData(pPlayer, key)
	local dataKey = self:getDataKey(pPlayer, key)
	if (dataKey == nil) then
		return
	end

	deleteData(dataKey)
end

function BgAureliaRiteOfAwakening:isRiteActive(pPlayer)
	return self:getNumber(pPlayer, "bg_aurelia_rite_active") == 1
end

function BgAureliaRiteOfAwakening:startRite(pPlayer)
	if (pPlayer == nil) then
		return
	end

	if (self:isRiteActive(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("The Rite of Awakening awaits in Aurelia.")
		return
	end

	self:setNumber(pPlayer, "bg_aurelia_rite_active", 1)
	self:setNumber(pPlayer, "bg_aurelia_rite_meditating", 0)
	self:setNumber(pPlayer, "bg_aurelia_rite_malichae_spawned", 0)
	self:setNumber(pPlayer, "bg_aurelia_rite_malichae_oid", 0)

	for i = 1, 5 do
		self:setNumber(pPlayer, "bg_aurelia_rite_stone_" .. i, 0)
	end

	CreatureObject(pPlayer):sendSystemMessage("The Elders have taken notice. Return to Aurelia. The Rite of Awakening awaits.")
	self:addRiteWaypoint(pPlayer)
end

function BgAureliaRiteOfAwakening:addRiteWaypoint(pPlayer)
	if (pPlayer == nil or not self.RITE_ADD_WAYPOINT) then
		return
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil) then
		return
	end

	local center = self.stoneConfig[5]
	if (center == nil) then
		return
	end

	PlayerObject(pGhost):addWaypoint(self.RITE_PLANET, self.RITE_WAYPOINT_NAME, self.RITE_WAYPOINT_DESC, center.x, 0, center.y, WAYPOINT_YELLOW, true, true, 0)
end

function BgAureliaRiteOfAwakening:getStoneIndexById(stoneId)
	if (stoneId == nil) then
		return nil
	end

	local idx = tonumber(readData("bg_aurelia_rite:stone:" .. stoneId))
	if (idx == nil or idx < 1) then
		return nil
	end

	return idx
end

function BgAureliaRiteOfAwakening:parseMeditationParam(param)
	if (param == nil) then
		return nil, nil
	end

	local playerIdStr, stoneIdStr = string.match(tostring(param), "^(%d+):(%d+)$")
	if (playerIdStr == nil or stoneIdStr == nil) then
		return nil, nil
	end

	return tonumber(playerIdStr), tonumber(stoneIdStr)
end

function BgAureliaRiteOfAwakening:parseDeathblowParam(param)
	if (param == nil) then
		return nil, nil
	end

	local playerIdStr, malIdStr = string.match(tostring(param), "^(%d+):(%d+)$")
	if (playerIdStr == nil or malIdStr == nil) then
		return nil, nil
	end

	return tonumber(playerIdStr), tonumber(malIdStr)
end

function BgAureliaRiteOfAwakening:allStonesComplete(pPlayer)
	for i = 1, 5 do
		if (self:getNumber(pPlayer, "bg_aurelia_rite_stone_" .. i) ~= 1) then
			return false
		end
	end

	return true
end

function BgAureliaRiteOfAwakening:beginMeditation(pPlayer, stoneId)
	if (pPlayer == nil or stoneId == nil) then
		return
	end

	if (not self:isRiteActive(pPlayer)) then
		if (VillageJediManagerCommon ~= nil
			and VillageJediManagerCommon.hasJediProgressionScreenPlayState(pPlayer, VILLAGE_JEDI_PROGRESSION_COMPLETED_VILLAGE)
			and not VillageJediManagerCommon.hasJediProgressionScreenPlayState(pPlayer, VILLAGE_JEDI_PROGRESSION_DEFEATED_MELLIACHAE)) then
			self:startRite(pPlayer)
		else
			CreatureObject(pPlayer):sendSystemMessage("The Rite has not yet been offered to you.")
			return
		end
	end

	if (CreatureObject(pPlayer):getPosture() ~= CROUCHED) then
		CreatureObject(pPlayer):sendSystemMessage("@jedi_trials:show_respect")
		return
	end

	if (self:getNumber(pPlayer, "bg_aurelia_rite_meditating") == 1) then
		CreatureObject(pPlayer):sendSystemMessage("You are already meditating. Remain still.")
		return
	end

	local stoneIndex = self:getStoneIndexById(stoneId)
	if (stoneIndex == nil) then
		CreatureObject(pPlayer):sendSystemMessage("This stone is silent.")
		return
	end

	local stoneKey = "bg_aurelia_rite_stone_" .. stoneIndex
	if (self:getNumber(pPlayer, stoneKey) == 1) then
		if (stoneIndex == 5 and self:getNumber(pPlayer, "bg_aurelia_rite_malichae_spawned") == 0) then
			CreatureObject(pPlayer):sendSystemMessage("You focus on the final stone once more.")
		else
			CreatureObject(pPlayer):sendSystemMessage("You have already meditated here.")
			return
		end
	end

	if (stoneIndex == 5) then
		for i = 1, 4 do
			if (self:getNumber(pPlayer, "bg_aurelia_rite_stone_" .. i) ~= 1) then
				CreatureObject(pPlayer):sendSystemMessage("The final stone remains silent. Seek the others first.")
				return
			end
		end
	end

	self:setNumber(pPlayer, "bg_aurelia_rite_meditating", 1)
	CreatureObject(pPlayer):sendSystemMessage("You begin to meditate. Remain within 10 meters for 30 seconds.")

	local playerId = self:getPlayerId(pPlayer)
	local param = tostring(playerId) .. ":" .. tostring(stoneId)
	createEvent(30000, self.screenplayName, "finishMeditation", pPlayer, param)
	createEvent(1000, self.screenplayName, "meditationTick", pPlayer, param)
end

function BgAureliaRiteOfAwakening:meditationTick(pPlayer, pParam)
	local ok, err = xpcall(function()
		local screenplay = self
		if (screenplay == nil) then
			screenplay = BgAureliaRiteOfAwakening
		end
		if (screenplay == nil or pParam == nil) then
			return
		end

		local playerId, stoneId = screenplay:parseMeditationParam(pParam)
		if (pPlayer == nil or SceneObject(pPlayer) == nil) then
			if (playerId ~= nil) then
				pPlayer = getSceneObject(playerId)
			end
		end
		if (pPlayer == nil or SceneObject(pPlayer) == nil or stoneId == nil) then
			return
		end

		if (screenplay:getNumber(pPlayer, "bg_aurelia_rite_meditating") ~= 1) then
			return
		end

		if (CreatureObject(pPlayer):isDead() or CreatureObject(pPlayer):isIncapacitated()) then
			screenplay:setNumber(pPlayer, "bg_aurelia_rite_meditating", 0)
			return
		end

		if (CreatureObject(pPlayer):getPosture() ~= CROUCHED) then
			screenplay:setNumber(pPlayer, "bg_aurelia_rite_meditating", 0)
			CreatureObject(pPlayer):sendSystemMessage("@jedi_trials:show_respect")
			return
		end

		local pStone = getSceneObject(stoneId)
		if (pStone == nil) then
			screenplay:setNumber(pPlayer, "bg_aurelia_rite_meditating", 0)
			return
		end

		local distance = SceneObject(pPlayer):getDistanceTo(pStone)
		if (distance > 10) then
			screenplay:setNumber(pPlayer, "bg_aurelia_rite_meditating", 0)
			CreatureObject(pPlayer):sendSystemMessage("Your meditation fails as you drift too far from the stone.")
			return
		end

		createEvent(1000, screenplay.screenplayName, "meditationTick", pPlayer, tostring(playerId) .. ":" .. tostring(stoneId))
	end, debug.traceback)

	if (not ok) then
		printLuaError("BgAureliaRiteOfAwakening:meditationTick error: " .. tostring(err) .. " pPlayer=" .. tostring(pPlayer) .. " pParam=" .. tostring(pParam))
	end
end

function BgAureliaRiteOfAwakening:finishMeditation(pPlayer, pParam)
	local ok, err = xpcall(function()
		local screenplay = self
		if (screenplay == nil) then
			screenplay = BgAureliaRiteOfAwakening
		end
		if (screenplay == nil or pParam == nil) then
			return
		end

		local playerId, stoneId = screenplay:parseMeditationParam(pParam)
		if (pPlayer == nil or SceneObject(pPlayer) == nil) then
			if (playerId ~= nil) then
				pPlayer = getSceneObject(playerId)
			end
		end
		if (pPlayer == nil or SceneObject(pPlayer) == nil or stoneId == nil) then
			return
		end

		if (screenplay:getNumber(pPlayer, "bg_aurelia_rite_meditating") ~= 1) then
			return
		end

		local pStone = getSceneObject(stoneId)
		if (pStone == nil) then
			screenplay:setNumber(pPlayer, "bg_aurelia_rite_meditating", 0)
			return
		end

		if (CreatureObject(pPlayer):isDead() or CreatureObject(pPlayer):isIncapacitated()) then
			screenplay:setNumber(pPlayer, "bg_aurelia_rite_meditating", 0)
			return
		end

		if (CreatureObject(pPlayer):getPosture() ~= CROUCHED) then
			screenplay:setNumber(pPlayer, "bg_aurelia_rite_meditating", 0)
			CreatureObject(pPlayer):sendSystemMessage("@jedi_trials:show_respect")
			return
		end

		local distance = SceneObject(pPlayer):getDistanceTo(pStone)
		if (distance > 10) then
			screenplay:setNumber(pPlayer, "bg_aurelia_rite_meditating", 0)
			CreatureObject(pPlayer):sendSystemMessage("Your meditation fails as you drift too far from the stone.")
			return
		end

		local stoneIndex = screenplay:getStoneIndexById(stoneId)
		if (stoneIndex == nil) then
			screenplay:setNumber(pPlayer, "bg_aurelia_rite_meditating", 0)
			return
		end

		local stoneKey = "bg_aurelia_rite_stone_" .. stoneIndex
		screenplay:setNumber(pPlayer, stoneKey, 1)
		screenplay:setNumber(pPlayer, "bg_aurelia_rite_meditating", 0)

		if (stoneIndex == 5) then
			CreatureObject(pPlayer):sendSystemMessage("The Rite is complete. A presence stirs nearby.")
			screenplay:checkRiteCompletion(pPlayer)
		else
			CreatureObject(pPlayer):sendSystemMessage("A quiet warmth settles in your mind.")
		end
	end, debug.traceback)

	if (not ok) then
		printLuaError("BgAureliaRiteOfAwakening:finishMeditation error: " .. tostring(err) .. " pPlayer=" .. tostring(pPlayer) .. " pParam=" .. tostring(pParam))
	end
end

function BgAureliaRiteOfAwakening:checkRiteCompletion(pPlayer)
	if (pPlayer == nil) then
		return
	end

	if (not self:allStonesComplete(pPlayer)) then
		return
	end

	if (self:getNumber(pPlayer, "bg_aurelia_rite_malichae_spawned") == 1) then
		return
	end

	self:spawnRiteMallichae(pPlayer)
end

function BgAureliaRiteOfAwakening:resolvePlayerFromKiller(pKiller)
	if (pKiller == nil) then
		return nil
	end
	if (SceneObject(pKiller) ~= nil) then
		if (SceneObject(pKiller):isPlayerCreature()) then
			return pKiller
		end
		-- Avoid CreatureObject on non-creature objects (turrets, installations, etc.)
		if (not SceneObject(pKiller):isCreatureObject()) then
			return nil
		end
	end

	local try = {
		function() local co = CreatureObject(pKiller); return co and co.getPlayerOwner and co:getPlayerOwner() end,
		function() local co = CreatureObject(pKiller); return co and co.getMaster and co:getMaster() end,
		function() local co = CreatureObject(pKiller); return co and co.getLinkedCreature and co:getLinkedCreature() end,
		function() local so = SceneObject(pKiller); return so and so.getOwner and so:getOwner() end,
	}

	for _, getter in ipairs(try) do
		local ok, owner = pcall(getter)
		if (ok and owner ~= nil and SceneObject(owner) ~= nil and SceneObject(owner):isPlayerCreature()) then
			return owner
		end
	end

	return nil
end

function BgAureliaRiteOfAwakening:spawnRiteMallichae(pPlayer)
	if (pPlayer == nil) then
		return
	end

	if (self:getNumber(pPlayer, "bg_aurelia_rite_malichae_spawned") == 1) then
		return
	end

	local zoneName = CreatureObject(pPlayer):getZoneName()
	if (zoneName == nil or zoneName == "") then
		return
	end

	local x = SceneObject(pPlayer):getWorldPositionX()
	local y = SceneObject(pPlayer):getWorldPositionY()
	local z = SceneObject(pPlayer):getWorldPositionZ()
	local dx = getRandomNumber(-6, 6)
	local dy = getRandomNumber(-6, 6)
	local heading = getRandomNumber(0, 359)

	local pMallichae = spawnMobile(zoneName, "mallichae_bg_rite", 0, x + dx, z, y + dy, heading, 0)
	if (pMallichae == nil) then
		return
	end

	-- Make village turrets ignore him by using the non-aggro faction.
	CreatureObject(pMallichae):setFaction("sith_shadow_nonaggro")

	local playerId = self:getPlayerId(pPlayer)
	local malId = SceneObject(pMallichae):getObjectID()

	writeData(malId .. "questOwner", playerId)
	self:setNumber(pPlayer, "bg_aurelia_rite_malichae_spawned", 1)
	self:setNumber(pPlayer, "bg_aurelia_rite_malichae_oid", malId)

	createObserver(PLAYERKILLED, self.screenplayName, "onPlayerKilled", pPlayer)
	createObserver(OBJECTDESTRUCTION, self.screenplayName, "onMallichaeKilled", pMallichae)

	AiAgent(pMallichae):setDefender(pPlayer)

	local param = tostring(playerId) .. ":" .. tostring(malId)
	createEvent(1000, self.screenplayName, "deathblowTick", pPlayer, param)
end

function BgAureliaRiteOfAwakening:deathblowTick(pPlayer, pParam)
	local ok, err = xpcall(function()
		local screenplay = self
		if (screenplay == nil) then
			screenplay = BgAureliaRiteOfAwakening
		end
		if (screenplay == nil or pParam == nil) then
			return
		end

		local playerId, malId = screenplay:parseDeathblowParam(pParam)
		if (pPlayer == nil or SceneObject(pPlayer) == nil) then
			if (playerId ~= nil) then
				pPlayer = getSceneObject(playerId)
			end
		end

		if (pPlayer == nil or SceneObject(pPlayer) == nil or malId == nil) then
			return
		end

		local pMallichae = getSceneObject(malId)
		if (pMallichae == nil or CreatureObject(pMallichae):isDead()) then
			return
		end

		if (CreatureObject(pPlayer):isDead()) then
			return
		end

		if (CreatureObject(pPlayer):isIncapacitated()) then
			CreatureObject(pMallichae):inflictDamage(pPlayer, 0, 1000000, 1)
			return
		end

		createEvent(1000, screenplay.screenplayName, "deathblowTick", pPlayer, tostring(playerId) .. ":" .. tostring(malId))
	end, debug.traceback)

	if (not ok) then
		printLuaError("BgAureliaRiteOfAwakening:deathblowTick error: " .. tostring(err) .. " pPlayer=" .. tostring(pPlayer) .. " pParam=" .. tostring(pParam))
	end
end

function BgAureliaRiteOfAwakening:cleanupMallichae(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local malId = self:getNumber(pPlayer, "bg_aurelia_rite_malichae_oid")
	if (malId ~= nil and malId > 0) then
		local pMallichae = getSceneObject(malId)
		if (pMallichae ~= nil) then
			SceneObject(pMallichae):destroyObjectFromWorld()
		end
		deleteData(malId .. "questOwner")
	end

	self:setNumber(pPlayer, "bg_aurelia_rite_malichae_spawned", 0)
	self:setNumber(pPlayer, "bg_aurelia_rite_malichae_oid", 0)
end

function BgAureliaRiteOfAwakening:clearRiteData(pPlayer)
	if (pPlayer == nil) then
		return
	end

	self:setNumber(pPlayer, "bg_aurelia_rite_active", 0)
	self:setNumber(pPlayer, "bg_aurelia_rite_meditating", 0)
	self:setNumber(pPlayer, "bg_aurelia_rite_malichae_spawned", 0)
	self:setNumber(pPlayer, "bg_aurelia_rite_malichae_oid", 0)

	for i = 1, 5 do
		self:setNumber(pPlayer, "bg_aurelia_rite_stone_" .. i, 0)
	end
end

function BgAureliaRiteOfAwakening:onMallichaeKilled(pMallichae, pKiller)
	if (pMallichae == nil) then
		return 1
	end

	local ownerID = readData(SceneObject(pMallichae):getObjectID() .. "questOwner")
	if (ownerID == nil or ownerID == 0) then
		return 1
	end

	local pOwner = getSceneObject(ownerID)
	if (pOwner == nil) then
		return 1
	end

	local pResolvedKiller = self:resolvePlayerFromKiller(pKiller)
	if (pResolvedKiller == nil or SceneObject(pResolvedKiller):getObjectID() ~= ownerID) then
		CreatureObject(pOwner):sendSystemMessage("Another has slain your foe. Return to the final stone to call him again.")
		self:cleanupMallichae(pOwner)
		return 1
	end

	QuestManager.completeQuest(pOwner, QuestManager.quests.FS_THEATER_FINAL)
	CreatureObject(pOwner):sendSystemMessage("@quest/force_sensitive/exit:final_complete")
	VillageJediManagerCommon.setJediProgressionScreenPlayState(pOwner, VILLAGE_JEDI_PROGRESSION_DEFEATED_MELLIACHAE)
	FsOutro:setCurrentStep(pOwner, 4)
	PadawanTrials:doPadawanTrialsSetup(pOwner)

	dropObserver(PLAYERKILLED, self.screenplayName, "onPlayerKilled", pOwner)
	deleteData(SceneObject(pMallichae):getObjectID() .. "questOwner")

	-- Remove the corpse immediately after crediting.
	SceneObject(pMallichae):destroyObjectFromWorld()

	self:clearRiteData(pOwner)

	return 1
end

function BgAureliaRiteOfAwakening:onPlayerKilled(pPlayer, pKiller, nothing)
	if (pPlayer == nil) then
		return 1
	end

	-- Some destruction events fire on incapacitation; only clean up on true death.
	if (not CreatureObject(pPlayer):isDead()) then
		return 0
	end

	if (self:getNumber(pPlayer, "bg_aurelia_rite_malichae_spawned") == 1) then
		CreatureObject(pPlayer):sendSystemMessage("You have fallen. The Rite awaits your return.")
		-- Make sure Mallichae is removed even if the player death event doesn't have cleanup side effects.
		self:cleanupMallichae(pPlayer)
	end

	return 1
end

function BgAureliaRiteOfAwakening:onLoggedOut(pPlayer)
	if (pPlayer == nil) then
		return
	end

	if (self:getNumber(pPlayer, "bg_aurelia_rite_malichae_spawned") == 1) then
		self:cleanupMallichae(pPlayer)
	end
end

-- Stone menu component
BgAureliaRiteStoneMenuComponent = {}

function BgAureliaRiteStoneMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)
	menuResponse:addRadialMenuItem(120, 3, "@jedi_trials:meditate")
end

function BgAureliaRiteStoneMenuComponent:handleObjectMenuSelect(pObject, pPlayer, selectedID)
	if (pObject == nil or pPlayer == nil) then
		return 0
	end

	if (selectedID == 120) then
		BgAureliaRiteOfAwakening:beginMeditation(pPlayer, SceneObject(pObject):getObjectID())
	end

	return 0
end

return BgAureliaRiteOfAwakening
