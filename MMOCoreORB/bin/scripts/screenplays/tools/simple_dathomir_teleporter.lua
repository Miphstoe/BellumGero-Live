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
function SimpleDathomirTeleporter:doTeleportToAurillia(pPlayer)
	local player = LuaCreatureObject(pPlayer)
	
	if (player == nil) then
		return
	end
	
	-- Use the correct teleport format for your Core3 build: X Y Planet (no Z)
	player:teleport("dathomir", 5240, -4069)
	player:sendSystemMessage("Welcome to Aurillia Village!")
end

-- Execute teleport to Science Outpost
function SimpleDathomirTeleporter:doTeleportToScience(pPlayer)
	local player = LuaCreatureObject(pPlayer)
	
	if (player == nil) then
		return
	end
	
	-- Use the correct teleport format for your Core3 build: X Y Planet (no Z)
	player:teleport("dathomir", -49, -1584)
	player:sendSystemMessage("Welcome to Science Outpost!")
end