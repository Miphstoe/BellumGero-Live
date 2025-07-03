-- Round-Trip Teleporter System for Science Outpost <-> Aurillia Village
-- File: scripts/object/tangible/teleporter/dathomir_transport_network.lua

local ObjectManager = require("managers.object.object_manager")

DathomirTransportNetwork = ScreenPlay:new {
	numberOfActs = 1,
	screenplayName = "DathomirTransportNetwork",
}

registerScreenPlay("DathomirTransportNetwork", true)

function DathomirTransportNetwork:start()
	if (isZoneEnabled("dathomir")) then
		self:spawnTeleporters()
	end
end

function DathomirTransportNetwork:spawnTeleporters()
	-- Spawn teleporter at Science Outpost (to Aurillia)
	local scienceTeleporter = spawnSceneObject("dathomir", "object/tangible/terminal/terminal_mission.iff", -49, 18, -1584, 0, 0, 0, 1, 0)
	
	if (scienceTeleporter ~= nil) then
		local teleporter = LuaSceneObject(scienceTeleporter)
		teleporter:setCustomObjectName("\\#00FFFF【Transport Terminal】 → Aurillia Village")
		teleporter:setDetailedDescription("Advanced transport terminal connecting to Aurillia Village. Cost: 150 credits.")
		createObserver(OBJECTRADIALUSED, "DathomirTransportNetwork", "scienceToAurillia", scienceTeleporter)
	end
	
	-- Spawn teleporter at Aurillia Village (to Science Outpost)  
	local aurillaTeleporter = spawnSceneObject("dathomir", "object/tangible/terminal/terminal_mission.iff", 5240, 78, -4069, 0, 0, 0, 1, 0)
	
	if (aurillaTeleporter ~= nil) then
		local teleporter = LuaSceneObject(aurillaTeleporter)
		teleporter:setCustomObjectName("\\#00FFFF【Transport Terminal】 → Science Outpost")
		teleporter:setDetailedDescription("Advanced transport terminal connecting to Science Outpost. Cost: 150 credits.")
		createObserver(OBJECTRADIALUSED, "DathomirTransportNetwork", "aurilliaToScience", aurillaTeleporter)
	end
end

-- Science Outpost to Aurillia Village
function DathomirTransportNetwork:scienceToAurillia(teleporterObject, pPlayer, requestType)
	local player = LuaCreatureObject(pPlayer)
	
	if (player == nil) then
		return 0
	end
	
	if not self:canTeleport(player, teleporterObject) then
		return 0
	end
	
	-- Deduct credits and start teleport
	player:subtractCashCredits(150)
	player:sendSystemMessage("\\#00FFFF🚀 Transport to Aurillia Village initiated...")
	player:playEffect("clienteffect/space_command/shp_hyperspace_begin.cef", "")
	
	-- Teleport with delay
	createEvent(3000, "DathomirTransportNetwork", "teleportToAurillia", pPlayer, "")
	
	return 0
end

-- Aurillia Village to Science Outpost
function DathomirTransportNetwork:aurilliaToScience(teleporterObject, pPlayer, requestType)
	local player = LuaCreatureObject(pPlayer)
	
	if (player == nil) then
		return 0
	end
	
	if not self:canTeleport(player, teleporterObject) then
		return 0
	end
	
	-- Deduct credits and start teleport
	player:subtractCashCredits(150)
	player:sendSystemMessage("\\#00FFFF🚀 Transport to Science Outpost initiated...")
	player:playEffect("clienteffect/space_command/shp_hyperspace_begin.cef", "")
	
	-- Teleport with delay
	createEvent(3000, "DathomirTransportNetwork", "teleportToScience", pPlayer, "")
	
	return 0
end

-- Shared validation function
function DathomirTransportNetwork:canTeleport(player, teleporterObject)
	local teleporter = LuaSceneObject(teleporterObject)
	local playerPos = player:getWorldPosition()
	local teleporterPos = teleporter:getWorldPosition()
	local distance = self:getDistance(playerPos, teleporterPos)
	
	-- Distance check
	if (distance > 10) then
		player:sendSystemMessage("⚠️ You need to be closer to the transport terminal.")
		return false
	end
	
	-- Credit check
	local teleportCost = 150
	local playerCredits = player:getCashCredits()
	
	if (playerCredits < teleportCost) then
		player:sendSystemMessage("⚠️ Insufficient credits. Required: " .. teleportCost .. " credits. You have: " .. playerCredits .. " credits.")
		return false
	end
	
	-- Combat check
	if (player:isInCombat()) then
		player:sendSystemMessage("⚠️ Cannot transport while in combat.")
		return false
	end
	
	return true
end

-- Execute teleport to Aurillia Village
function DathomirTransportNetwork:teleportToAurillia(pPlayer)
	local player = LuaCreatureObject(pPlayer)
	
	if (player == nil) then
		return
	end
	
	-- Aurillia Village coordinates
	player:teleport("dathomir", 5240, 78, -4069)
	
	-- Arrival effects and messages
	player:sendSystemMessage("\\#00FF00✅ Transport complete! Welcome to Aurillia Village!")
	player:playEffect("clienteffect/space_command/shp_hyperspace_end.cef", "")
	
	-- Add waypoint
	player:addWaypoint("dathomir", "Aurillia Village", "", 5240, -4069, WAYPOINTBLUE, true, true, 0)
end

-- Execute teleport to Science Outpost
function DathomirTransportNetwork:teleportToScience(pPlayer)
	local player = LuaCreatureObject(pPlayer)
	
	if (player == nil) then
		return
	end
	
	-- Science Outpost coordinates
	player:teleport("dathomir", -49, 18, -1584)
	
	-- Arrival effects and messages
	player:sendSystemMessage("\\#00FF00✅ Transport complete! Welcome to Science Outpost!")
	player:playEffect("clienteffect/space_command/shp_hyperspace_end.cef", "")
	
	-- Add waypoint
	player:addWaypoint("dathomir", "Science Outpost", "", -49, -1584, WAYPOINTGREEN, true, true, 0)
end

-- Distance calculation helper
function DathomirTransportNetwork:getDistance(pos1, pos2)
	local deltaX = pos1.x - pos2.x
	local deltaY = pos1.y - pos2.y
	return math.sqrt(deltaX * deltaX + deltaY * deltaY)
end