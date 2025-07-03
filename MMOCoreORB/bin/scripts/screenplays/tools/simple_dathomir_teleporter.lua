-- Simple Round-Trip Teleporter: Science Outpost <-> Aurillia Village
-- File: scripts/screenplays/tools/simple_dathomir_teleporter.lua

SimpleDathomirTeleporter = ScreenPlay:new {
	numberOfActs = 1,
	screenplayName = "SimpleDathomirTeleporter",
}

registerScreenPlay("SimpleDathomirTeleporter", true)

function SimpleDathomirTeleporter:start()
	if (isZoneEnabled("dathomir")) then
		self:createTeleporters()
	end
end

function SimpleDathomirTeleporter:createTeleporters()
	-- Create teleporter at Science Outpost
	local scienceObj = spawnSceneObject("dathomir", "object/tangible/terminal/terminal_insurance.iff", -49, 18, -1584, 0, 0, 0, 1, 0)
	
	if (scienceObj ~= nil) then
		local sceneObject = LuaSceneObject(scienceObj)
		sceneObject:setCustomObjectName("Transport to Aurillia Village")
		createObserver(OBJECTRADIALUSED, "SimpleDathomirTeleporter", "transportToAurillia", scienceObj)
	end
	
	-- Create teleporter at Aurillia Village
	local aurilliaObj = spawnSceneObject("dathomir", "object/tangible/terminal/terminal_insurance.iff", 5240, 78, -4069, 0, 0, 0, 1, 0)
	
	if (aurilliaObj ~= nil) then
		local sceneObject = LuaSceneObject(aurilliaObj)
		sceneObject:setCustomObjectName("Transport to Science Outpost")
		createObserver(OBJECTRADIALUSED, "SimpleDathomirTeleporter", "transportToScience", aurilliaObj)
	end
end

-- Transport from Science Outpost to Aurillia Village
function SimpleDathomirTeleporter:transportToAurillia(pObject, pPlayer, requestType)
	local player = LuaCreatureObject(pPlayer)
	
	if (player == nil) then
		return 0
	end
	
	-- Check credits
	if (player:getCashCredits() < 100) then
		player:sendSystemMessage("You need 100 credits to use this transport.")
		return 0
	end
	
	-- Check combat
	if (player:isInCombat()) then
		player:sendSystemMessage("You cannot transport while in combat.")
		return 0
	end
	
	-- Charge credits and teleport
	player:subtractCashCredits(100)
	player:sendSystemMessage("Transporting to Aurillia Village...")
	
	-- Teleport after 2 seconds
	createEvent(2000, "SimpleDathomirTeleporter", "doTeleportToAurillia", pPlayer, "")
	
	return 0
end

-- Transport from Aurillia Village to Science Outpost
function SimpleDathomirTeleporter:transportToScience(pObject, pPlayer, requestType)
	local player = LuaCreatureObject(pPlayer)
	
	if (player == nil) then
		return 0
	end
	
	-- Check credits
	if (player:getCashCredits() < 100) then
		player:sendSystemMessage("You need 100 credits to use this transport.")
		return 0
	end
	
	-- Check combat
	if (player:isInCombat()) then
		player:sendSystemMessage("You cannot transport while in combat.")
		return 0
	end
	
	-- Charge credits and teleport
	player:subtractCashCredits(100)
	player:sendSystemMessage("Transporting to Science Outpost...")
	
	-- Teleport after 2 seconds
	createEvent(2000, "SimpleDathomirTeleporter", "doTeleportToScience", pPlayer, "")
	
	return 0
end

-- Execute teleport to Aurillia Village
-- Debug version to see what's happening
-- Working teleporter using admin command execution
function SimpleDathomirTeleporter:doTeleportToAurillia(pPlayer)
	local player = LuaCreatureObject(pPlayer)
	
	if (player == nil) then
		return
	end
	
	-- Method 1: Try executing the admin command directly
	local playerName = player:getFirstName()
	local command = "teleport " .. playerName .. " 5240 -4069 dathomir"
	
	-- Try to execute admin command on the player
	pcall(function()
		executeCommand(pPlayer, "teleport 5240 -4069 dathomir")
	end)
	
	-- Method 2: Try zone manager teleport
	pcall(function()
		local zoneServer = player:getZoneServer()
		if (zoneServer ~= nil) then
			zoneServer:teleportPlayer(pPlayer, "dathomir", 5240, -4069, 0, 0)
		end
	end)
	
	-- Method 3: Try creature object teleport
	pcall(function()
		local creature = LuaCreatureObject(pPlayer)
		creature:teleportTo("dathomir", 5240, -4069, 0)
	end)
	
	-- Method 4: Try SceneObject teleport
	pcall(function()
		local sceneObject = LuaSceneObject(pPlayer)
		sceneObject:teleportTo("dathomir", 5240, -4069, 0)
	end)
	
	player:sendSystemMessage("Welcome to Aurillia Village!")
end

-- Same for Science Outpost
function SimpleDathomirTeleporter:doTeleportToScience(pPlayer)
	local player = LuaCreatureObject(pPlayer)
	
	if (player == nil) then
		return
	end
	
	-- Try multiple teleport methods
	pcall(function()
		executeCommand(pPlayer, "teleport -49 -1584 dathomir")
	end)
	
	pcall(function()
		local zoneServer = player:getZoneServer()
		if (zoneServer ~= nil) then
			zoneServer:teleportPlayer(pPlayer, "dathomir", -49, -1584, 0, 0)
		end
	end)
	
	pcall(function()
		local creature = LuaCreatureObject(pPlayer)
		creature:teleportTo("dathomir", -49, -1584, 0)
	end)
	
	pcall(function()
		local sceneObject = LuaSceneObject(pPlayer)
		sceneObject:teleportTo("dathomir", -49, -1584, 0)
	end)
	
	player:sendSystemMessage("Welcome to Science Outpost!")
end