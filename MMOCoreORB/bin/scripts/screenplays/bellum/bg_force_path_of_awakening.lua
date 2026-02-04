BgForcePathOfAwakening = ScreenPlay:new {
	screenplayName = "BgForcePathOfAwakening",
	numberOfActs = 1,
}

registerScreenPlay("BgForcePathOfAwakening", true)

local QuestManager = require("managers.quest.quest_manager")

BgForcePathOfAwakening.CRYSTAL_TEMPLATE = "object/tangible/loot/quest/force_sensitive/force_crystal.iff"

-- Config: edit these coordinates and templates as needed.
BgForcePathOfAwakening.shrineConfig = {
	{
		key = "bg_force_shrine_1",
		name = "Shrine of the Call",
		planet = "naboo",
		template = "object/tangible/jedi/force_shrine_stone.iff",
		x = -5467,
		z = 263,
		y = 806,
		heading = 0,
	},
	{
		key = "bg_force_shrine_2",
		name = "Shrine of the Vision",
		planet = "corellia",
		template = "object/tangible/jedi/force_shrine_stone.iff",
		x = 1099,
		z = 34,
		y = -5889,
		heading = 0,
	},
	{
		key = "bg_force_shrine_3",
		name = "Shrine of the Stillness",
		planet = "dantooine",
		template = "object/tangible/jedi/force_shrine_stone.iff",
		x = 4278,
		z = 8,
		y = 2960,
		heading = 0,
	},
}

BgForcePathOfAwakening.hermitConfig = {
	planet = "dathomir",
	mobileTemplate = "bg_force_old_man",
	x = -109,
	z = 18,
	y = -1581,
	heading = 0,
}

BgForcePathOfAwakening.shrineObjectIds = {}

function BgForcePathOfAwakening:start()
	self:spawnShrines()
	self:spawnHermit()
end

function BgForcePathOfAwakening:spawnShrines()
	self.shrineObjectIds = {}

	for i = 1, #self.shrineConfig, 1 do
		local cfg = self.shrineConfig[i]
		local pShrine = spawnSceneObject(cfg.planet, cfg.template, cfg.x, cfg.z, cfg.y, 0, math.rad(cfg.heading))

		if (pShrine ~= nil) then
			SceneObject(pShrine):setObjectMenuComponent("BgForcePathShrineMenuComponent")
			if (cfg.name ~= nil and cfg.name ~= "") then
				SceneObject(pShrine):setCustomObjectName(cfg.name)
			else
				SceneObject(pShrine):setCustomObjectName("Force Shrine")
			end
			local shrineId = SceneObject(pShrine):getObjectID()
			self.shrineObjectIds[i] = shrineId
			writeData("bg_force_path:shrine:" .. shrineId, i)
		end
	end
end

function BgForcePathOfAwakening:spawnHermit()
	local cfg = self.hermitConfig
	local template = cfg.mobileTemplate
	if (template == nil or template == "") then
		template = "bg_force_old_man"
	end

	local pHermit = spawnMobile(cfg.planet, template, 0, cfg.x, cfg.z, cfg.y, cfg.heading, 0)

	if (pHermit ~= nil) then
		CreatureObject(pHermit):setPvpStatusBitmask(0)
		-- Ensure the NPC is conversable and invulnerable.
		CreatureObject(pHermit):setOptionsBitmask(AIENABLED + CONVERSABLE + INVULNERABLE)
		SceneObject(pHermit):setCustomObjectName("The Hermit")
		AiAgent(pHermit):setConvoTemplate("bgForceHermitConvoTemplate")
		AiAgent(pHermit):addObjectFlag(AI_STATIC)
	end
end

function BgForcePathOfAwakening:getDataKey(pPlayer, key)
	if (pPlayer == nil) then
		return nil
	end

	local playerObj = SceneObject(pPlayer)
	if (playerObj == nil) then
		return nil
	end

	return playerObj:getObjectID() .. ":" .. key
end

function BgForcePathOfAwakening:getNumber(pPlayer, key)
	if (pPlayer == nil) then
		return 0
	end

	return tonumber(readScreenPlayData(pPlayer, "bg_force_path", key)) or 0
end

function BgForcePathOfAwakening:setNumber(pPlayer, key, value)
	if (pPlayer == nil) then
		return
	end

	writeScreenPlayData(pPlayer, "bg_force_path", key, value)
end

function BgForcePathOfAwakening:getString(pPlayer, key)
	if (pPlayer == nil) then
		return ""
	end

	return tostring(readScreenPlayData(pPlayer, "bg_force_path", key) or "")
end

function BgForcePathOfAwakening:parseMeditationParam(param)
	if (param == nil) then
		return nil, nil
	end

	local playerIdStr, shrineIdStr = string.match(tostring(param), "^(%d+):(%d+)$")
	if (playerIdStr == nil or shrineIdStr == nil) then
		return nil, nil
	end

	return tonumber(playerIdStr), tonumber(shrineIdStr)
end

function BgForcePathOfAwakening:setString(pPlayer, key, value)
	if (pPlayer == nil) then
		return
	end

	writeScreenPlayData(pPlayer, "bg_force_path", key, value)
end

function BgForcePathOfAwakening:getShrineIndexById(shrineId)
	for i = 1, #self.shrineObjectIds, 1 do
		if (self.shrineObjectIds[i] == shrineId) then
			return i
		end
	end

	local mapped = readData("bg_force_path:shrine:" .. shrineId)
	if (mapped ~= nil) then
		return tonumber(mapped)
	end

	return nil
end

function BgForcePathOfAwakening:getStep(pPlayer)
	return self:getNumber(pPlayer, "bg_force_path_step")
end

function BgForcePathOfAwakening:giveShrineWaypoints(pPlayer)
	if (pPlayer == nil) then
		return
	end
	if (self:isComplete(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("The path is already complete.")
		return
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil) then
		return
	end

	local waypoints = {
		{ key = "bg_force_wp_naboo", planet = "naboo", name = "Shrine of the Call", desc = "Meditate here first.", x = -5467, z = 0, y = 806 },
		{ key = "bg_force_wp_corellia", planet = "corellia", name = "Shrine of the Vision", desc = "Meditate here second.", x = 1099, z = 0, y = -5889 },
		{ key = "bg_force_wp_dantooine", planet = "dantooine", name = "Shrine of the Stillness", desc = "Meditate here last.", x = 4278, z = 0, y = 2960 },
	}

	for i = 1, #waypoints, 1 do
		local wp = waypoints[i]
		local wpKey = wp.key
		local existingId = readScreenPlayData(pPlayer, "bg_force_path", wpKey)

		if (existingId == nil or getSceneObject(existingId) == nil) then
			local waypointID = PlayerObject(pGhost):addWaypoint(wp.planet, wp.name, wp.desc, wp.x, wp.z, wp.y, WAYPOINT_BLUE, true, true, 0)
			if (waypointID ~= nil) then
				writeScreenPlayData(pPlayer, "bg_force_path", wpKey, waypointID)
			end
		end
	end

	self:setNumber(pPlayer, "bg_force_path_started", 1)
end

function BgForcePathOfAwakening:getCrystalKey(pPlayer)
	if (pPlayer == nil or SceneObject(pPlayer) == nil) then
		return nil
	end

	return SceneObject(pPlayer):getObjectID() .. ":bg_force_crystal_id"
end

function BgForcePathOfAwakening:getStoredCrystalId(pPlayer)
	if (pPlayer == nil) then
		return nil
	end

	return readScreenPlayData(pPlayer, "bg_force_path", "bg_force_crystal_id")
end

function BgForcePathOfAwakening:setStoredCrystalId(pPlayer, crystalId)
	if (pPlayer == nil) then
		return
	end

	writeScreenPlayData(pPlayer, "bg_force_path", "bg_force_crystal_id", crystalId)
end

function BgForcePathOfAwakening:clearStoredCrystalId(pPlayer)
	if (pPlayer == nil) then
		return
	end

	writeScreenPlayData(pPlayer, "bg_force_path", "bg_force_crystal_id", 0)
end

function BgForcePathOfAwakening:giveForceCrystal(pPlayer)
	if (pPlayer == nil) then
		return
	end

	if (self:isComplete(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("The path is already open to you.")
		return
	end

	local existingId = self:getStoredCrystalId(pPlayer)
	if (existingId ~= nil and getSceneObject(existingId) ~= nil) then
		CreatureObject(pPlayer):sendSystemMessage("You already carry a Force crystal.")
		return
	end

	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil) then
		return
	end

	if (SceneObject(pInventory):isContainerFullRecursive()) then
		CreatureObject(pPlayer):sendSystemMessage("Your inventory is full.")
		return
	end

	local pCrystal = giveItem(pInventory, self.CRYSTAL_TEMPLATE, -1)
	if (pCrystal == nil) then
		return
	end

	SceneObject(pCrystal):setObjectMenuComponent("BgForceCrystalMenuComponent")
	self:setStoredCrystalId(pPlayer, SceneObject(pCrystal):getObjectID())
	self:setNumber(pPlayer, "bg_force_crystal_given", 1)
	self:setStep(pPlayer, 4)
	CreatureObject(pPlayer):sendSystemMessage("@quest/force_sensitive/intro:crystal_message")
end

function BgForcePathOfAwakening:useForceCrystal(pPlayer, pCrystal)
	if (pPlayer == nil or pCrystal == nil) then
		return
	end

	if (self:isComplete(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("The crystal is quiet. You already have access.")
		return
	end

	local storedId = self:getStoredCrystalId(pPlayer)
	local storedIdNum = tonumber(storedId) or 0
	if (storedIdNum ~= 0 and storedIdNum ~= SceneObject(pCrystal):getObjectID()) then
		CreatureObject(pPlayer):sendSystemMessage("The crystal does not respond to you.")
		return
	end

	QuestManager.activateQuest(pPlayer, QuestManager.quests.FS_VILLAGE_ELDER)
	QuestManager.completeQuest(pPlayer, QuestManager.quests.FS_VILLAGE_ELDER)
	VillageJediManagerCommon.setJediProgressionScreenPlayState(pPlayer, VILLAGE_JEDI_PROGRESSION_HAS_VILLAGE_ACCESS)
	CreatureObject(pPlayer):sendSystemMessage("@quest/force_sensitive/intro:force_sensitive")

	self:setNumber(pPlayer, "bg_force_path_step", 5)
	self:setNumber(pPlayer, "bg_force_path_complete", 1)
	self:setNumber(pPlayer, "bg_force_meditating", 0)
	self:clearStoredCrystalId(pPlayer)

	SceneObject(pCrystal):destroyObjectFromWorld()
	SceneObject(pCrystal):destroyObjectFromDatabase()
end

function BgForcePathOfAwakening:setStep(pPlayer, step)
	local current = self:getStep(pPlayer)
	if (step > current) then
		self:setNumber(pPlayer, "bg_force_path_step", step)
	end
end

function BgForcePathOfAwakening:isComplete(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	if (VillageJediManagerCommon ~= nil and VillageJediManagerCommon.hasJediProgressionScreenPlayState(pPlayer, VILLAGE_JEDI_PROGRESSION_HAS_VILLAGE_ACCESS)) then
		return true
	end

	if (CreatureObject(pPlayer):hasSkill("force_title_jedi_novice")) then
		return true
	end

	return self:getNumber(pPlayer, "bg_force_path_complete") == 1
end

function BgForcePathOfAwakening:allShrinesComplete(pPlayer)
	return self:getNumber(pPlayer, "bg_force_shrine_1") == 1
		and self:getNumber(pPlayer, "bg_force_shrine_2") == 1
		and self:getNumber(pPlayer, "bg_force_shrine_3") == 1
end

function BgForcePathOfAwakening:handleShrineInteract(pPlayer, shrineId)
	if (pPlayer == nil or shrineId == nil) then
		return
	end

	local pShrine = getSceneObject(shrineId)
	if (pShrine == nil) then
		return
	end

	if (CreatureObject(pPlayer):getPosture() ~= CROUCHED) then
		CreatureObject(pPlayer):sendSystemMessage("@jedi_trials:show_respect")
		return
	end

	if (self:isComplete(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("You have already completed the Path of Awakening.")
		return
	end

	if (self:getNumber(pPlayer, "bg_force_meditating") == 1) then
		CreatureObject(pPlayer):sendSystemMessage("You are already meditating. Remain still.")
		return
	end

	local shrineIndex = self:getShrineIndexById(shrineId)
	if (shrineIndex == nil) then
		CreatureObject(pPlayer):sendSystemMessage("This shrine is silent.")
		return
	end

	local shrineKey = self.shrineConfig[shrineIndex].key
	if (self:getNumber(pPlayer, shrineKey) == 1) then
		CreatureObject(pPlayer):sendSystemMessage("You have already meditated at this shrine.")
		return
	end

	if (shrineIndex == 2 and self:getNumber(pPlayer, "bg_force_shrine_1") == 0) then
		CreatureObject(pPlayer):sendSystemMessage("A faint pull urges you to seek the first shrine on Naboo.")
		return
	elseif (shrineIndex == 3 and self:getNumber(pPlayer, "bg_force_shrine_2") == 0) then
		CreatureObject(pPlayer):sendSystemMessage("The stillness eludes you. The second shrine on Corellia awaits.")
		return
	end

	self:setNumber(pPlayer, "bg_force_meditating", 1)
	CreatureObject(pPlayer):sendSystemMessage("You begin to meditate. Remain within 10 meters for 30 seconds.")

	local playerId = SceneObject(pPlayer):getObjectID()
	local param = tostring(playerId) .. ":" .. tostring(shrineId)
	createEvent(30000, self.screenplayName, "finishMeditation", pPlayer, param)
	createEvent(1000, self.screenplayName, "meditationTick", pPlayer, param)
end

function BgForcePathOfAwakening:meditationTick(pPlayer, pParam)
	local ok, err = xpcall(function()
		local screenplay = self
		if (screenplay == nil) then
			screenplay = BgForcePathOfAwakening
		end
		if (screenplay == nil) then
			return
		end
		if (pParam == nil) then
			return
		end

		local playerId, shrineId = screenplay:parseMeditationParam(pParam)
		if (pPlayer == nil or SceneObject(pPlayer) == nil) then
			if (playerId ~= nil) then
				pPlayer = getSceneObject(playerId)
			end
		end
		if (pPlayer == nil or SceneObject(pPlayer) == nil or shrineId == nil) then
			return
		end
		local pPlayerObj = SceneObject(pPlayer)

		if (screenplay:getNumber(pPlayer, "bg_force_meditating") ~= 1) then
			return
		end

		local pShrine = getSceneObject(shrineId)
		if (pShrine == nil) then
			screenplay:setNumber(pPlayer, "bg_force_meditating", 0)
			return
		end

		if (CreatureObject(pPlayer):getPosture() ~= CROUCHED) then
			screenplay:setNumber(pPlayer, "bg_force_meditating", 0)
			CreatureObject(pPlayer):sendSystemMessage("@jedi_trials:show_respect")
			return
		end

		local distance = pPlayerObj:getDistanceTo(pShrine)
		if (distance > 10) then
			screenplay:setNumber(pPlayer, "bg_force_meditating", 0)
			CreatureObject(pPlayer):sendSystemMessage("Your concentration breaks as you move away from the shrine.")
			return
		end

		createEvent(1000, screenplay.screenplayName, "meditationTick", pPlayer, tostring(playerId) .. ":" .. tostring(shrineId))
	end, debug.traceback)

	if (not ok) then
		printLuaError("BgForcePathOfAwakening:meditationTick error: " .. tostring(err) .. " pPlayer=" .. tostring(pPlayer) .. " pParam=" .. tostring(pParam))
	end
end

function BgForcePathOfAwakening:finishMeditation(pPlayer, pParam)
	local ok, err = xpcall(function()
		local screenplay = self
		if (screenplay == nil) then
			screenplay = BgForcePathOfAwakening
		end
		if (screenplay == nil) then
			return
		end
		if (pParam == nil) then
			return
		end

		local playerId, shrineId = screenplay:parseMeditationParam(pParam)
		if (pPlayer == nil or SceneObject(pPlayer) == nil) then
			if (playerId ~= nil) then
				pPlayer = getSceneObject(playerId)
			end
		end
		if (pPlayer == nil or SceneObject(pPlayer) == nil or shrineId == nil) then
			return
		end
		local pPlayerObj = SceneObject(pPlayer)

		if (screenplay:getNumber(pPlayer, "bg_force_meditating") ~= 1) then
			return
		end

		local pShrine = getSceneObject(shrineId)
		if (pShrine == nil) then
			screenplay:setNumber(pPlayer, "bg_force_meditating", 0)
			return
		end

		if (CreatureObject(pPlayer):getPosture() ~= CROUCHED) then
			screenplay:setNumber(pPlayer, "bg_force_meditating", 0)
			CreatureObject(pPlayer):sendSystemMessage("@jedi_trials:show_respect")
			return
		end

		local distance = pPlayerObj:getDistanceTo(pShrine)
		if (distance > 10) then
			screenplay:setNumber(pPlayer, "bg_force_meditating", 0)
			CreatureObject(pPlayer):sendSystemMessage("Your meditation fails as you drift too far from the shrine.")
			return
		end

		local shrineIndex = screenplay:getShrineIndexById(shrineId)
		if (shrineIndex == nil or screenplay.shrineConfig == nil or screenplay.shrineConfig[shrineIndex] == nil) then
			screenplay:setNumber(pPlayer, "bg_force_meditating", 0)
			return
		end

		local shrineKey = screenplay.shrineConfig[shrineIndex].key
		screenplay:setNumber(pPlayer, shrineKey, 1)
		screenplay:setNumber(pPlayer, "bg_force_meditating", 0)
		screenplay:setStep(pPlayer, shrineIndex)

		if (shrineIndex == 1) then
			CreatureObject(pPlayer):sendSystemMessage("A quiet call echoes within you. Seek the next shrine on Corellia.")
		elseif (shrineIndex == 2) then
			CreatureObject(pPlayer):sendSystemMessage("A vision takes shape. The final shrine awaits on Dantooine.")
		elseif (shrineIndex == 3) then
			CreatureObject(pPlayer):sendSystemMessage("Stillness settles. Return to the Hermit on Dathomir.")
		end
	end, debug.traceback)

	if (not ok) then
		printLuaError("BgForcePathOfAwakening:finishMeditation error: " .. tostring(err) .. " pPlayer=" .. tostring(pPlayer) .. " pParam=" .. tostring(pParam))
	end
end

	function BgForcePathOfAwakening:completePath(pPlayer, alignment)
		if (pPlayer == nil) then
			return
		end

		self:setString(pPlayer, "bg_force_alignment_choice", alignment)
		self:giveForceCrystal(pPlayer)
	end

-- Shrine menu component
BgForcePathShrineMenuComponent = {}

function BgForcePathShrineMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)
	menuResponse:addRadialMenuItem(120, 3, "@jedi_trials:meditate")
end

function BgForcePathShrineMenuComponent:handleObjectMenuSelect(pObject, pPlayer, selectedID)
	if (pObject == nil or pPlayer == nil) then
		return 0
	end

	if (selectedID == 120) then
		BgForcePathOfAwakening:handleShrineInteract(pPlayer, SceneObject(pObject):getObjectID())
	end

	return 0
end

-- Force crystal menu component
BgForceCrystalMenuComponent = {}

function BgForceCrystalMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)
	menuResponse:addRadialMenuItem(20, 3, "@ui_radial:item_use")
	menuResponse:addRadialMenuItem(120, 3, "@quest/quest_journal/fs_quests_sad:instructions_title")
end

function BgForceCrystalMenuComponent:handleObjectMenuSelect(pObject, pPlayer, selectedID)
	if (pObject == nil or pPlayer == nil) then
		return 0
	end

	if (selectedID == 20 or selectedID == 120) then
		BgForcePathOfAwakening:useForceCrystal(pPlayer, pObject)
	end

	return 0
end

-- Bridge the stock quest crystal to our unlock logic.
ForceCrystalMenuComponent = {}

function ForceCrystalMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)
	menuResponse:addRadialMenuItem(20, 3, "@ui_radial:item_use")
	menuResponse:addRadialMenuItem(120, 3, "@quest/quest_journal/fs_quests_sad:instructions_title")
end

function ForceCrystalMenuComponent:handleObjectMenuSelect(pObject, pPlayer, selectedID)
	if (pObject == nil or pPlayer == nil) then
		return 0
	end

	if (selectedID == 20 or selectedID == 120) then
		BgForcePathOfAwakening:useForceCrystal(pPlayer, pObject)
	end

	return 0
end

-- Conversation handler
BgForceHermitConversationHandler = conv_handler:new {}

function BgForceHermitConversationHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil) then
		return nil
	end
	local convoTemplate = LuaConversationTemplate(pConvTemplate)

	if (BgForcePathOfAwakening:isComplete(pPlayer)) then
		return convoTemplate:getScreen("completed")
	end

	if (BgForcePathOfAwakening:allShrinesComplete(pPlayer)) then
		if (BgForcePathOfAwakening:getStep(pPlayer) < 4) then
			BgForcePathOfAwakening:setStep(pPlayer, 4)
		end
		return convoTemplate:getScreen("choice")
	end

	return convoTemplate:getScreen("intro")
end

function BgForceHermitConversationHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return pConvScreen
	end

	local convoScreen = LuaConversationScreen(pConvScreen)
	local screenID = convoScreen:getScreenID()
	if (screenID == "choose_light") then
		BgForcePathOfAwakening:setString(pPlayer, "bg_force_alignment_choice", "light")
		BgForcePathOfAwakening:giveForceCrystal(pPlayer)
	elseif (screenID == "choose_dark") then
		BgForcePathOfAwakening:setString(pPlayer, "bg_force_alignment_choice", "dark")
		BgForcePathOfAwakening:giveForceCrystal(pPlayer)
	elseif (screenID == "accept") then
		BgForcePathOfAwakening:giveShrineWaypoints(pPlayer)
	end

	return pConvScreen
end

--[[
Registration / Placement Notes:
- Register this screenplay in scripts/screenplays/screenplays.lua:
  includeFile("bellum/bg_force_path_of_awakening.lua")
- Ensure the conversation template file is available and loaded by the server.
- Spawn the Hermit NPC by enabling this screenplay (auto-start is true above) or by calling BgForcePathOfAwakening:start().
- Place shrine objects via this screenplay (auto-spawn in start) or manually using spawnSceneObject with the same template and coordinates.
]]
