--[[
	Faction-Based City Patrols Screenplay
	Spawns faction-specific NPCs based on city faction alignment

	Usage: Include this in your city screenplays and call spawnFactionPatrols()
]]--

print("DEBUG: faction_patrols.lua is loading...")

CityFactionPatrols = ScreenPlay:new {
	screenplayName = "CityFactionPatrols",

	-- Store spawned patrol NPCs by city so we can despawn them later
	factionPatrolNpcs = {},
	currentFaction = "neutral",
}

--[[
	spawnFactionPatrols(zoneName, cityRegion)
	Spawns faction-appropriate patrols based on city's faction alignment
]]--
function CityFactionPatrols:spawnFactionPatrols(zoneName, cityRegion)
	if zoneName == nil or cityRegion == nil then
		return
	end

	-- Get the city's faction alignment
	local faction = cityRegion:getCityFactionAlignment()

	if faction == nil or faction == "" then
		faction = "neutral"
	end

	self.currentFaction = faction

	print("CityFactionPatrols: Spawning " .. faction .. " patrols for city: " .. cityRegion:getCityRegionName())

	-- Spawn appropriate patrols
	if faction == "rebel" then
		self:spawnRebelPatrols(zoneName, cityRegion)
	elseif faction == "imperial" then
		self:spawnImperialPatrols(zoneName, cityRegion)
	else -- neutral
		self:spawnNeutralPatrols(zoneName, cityRegion)
	end
end

--[[
	Rebel Patrol Spawns
]]--
function CityFactionPatrols:spawnRebelPatrols(zoneName, cityRegion)
	local patrols = {
		-- Patrol Group 1 - Rebel Soldiers
		{
			npc = "rebel_soldier_one",
			x = -100, y = 0, z = 200,
			heading = 0,
		},
		{
			npc = "rebel_soldier_two",
			x = -80, y = 0, z = 220,
			heading = 45,
		},

		-- Patrol Group 2 - Rebel Officers
		{
			npc = "rebel_officer",
			x = 150, y = 0, z = 300,
			heading = 90,
		},
		{
			npc = "rebel_commando",
			x = 170, y = 0, z = 320,
			heading = 135,
		},

		-- Patrol Group 3 - Rebel Scouts
		{
			npc = "rebel_scout",
			x = 400, y = 0, z = 500,
			heading = 180,
		},
		{
			npc = "rebel_soldier_one",
			x = 420, y = 0, z = 520,
			heading = 225,
		},
	}

	self:spawnPatrols(zoneName, patrols, "rebel")
end

--[[
	Imperial Patrol Spawns
]]--
function CityFactionPatrols:spawnImperialPatrols(zoneName, cityRegion)
	local patrols = {
		-- Patrol Group 1 - Imperial Troopers
		{
			npc = "imperial_trooper_one",
			x = -100, y = 0, z = 200,
			heading = 0,
		},
		{
			npc = "imperial_trooper_two",
			x = -80, y = 0, z = 220,
			heading = 45,
		},

		-- Patrol Group 2 - Imperial Officers
		{
			npc = "imperial_officer",
			x = 150, y = 0, z = 300,
			heading = 90,
		},
		{
			npc = "imperial_commando",
			x = 170, y = 0, z = 320,
			heading = 135,
		},

		-- Patrol Group 3 - Imperial Enforcers
		{
			npc = "imperial_ensign",
			x = 400, y = 0, z = 500,
			heading = 180,
		},
		{
			npc = "imperial_trooper_one",
			x = 420, y = 0, z = 520,
			heading = 225,
		},
	}

	self:spawnPatrols(zoneName, patrols, "imperial")
end

--[[
	Neutral/Corsec Patrol Spawns
]]--
function CityFactionPatrols:spawnNeutralPatrols(zoneName, cityRegion)
	local patrols = {
		-- Patrol Group 1 - Corsec Officers
		{
			npc = "corsec_officer",
			x = -100, y = 0, z = 200,
			heading = 0,
		},
		{
			npc = "corsec_trooper",
			x = -80, y = 0, z = 220,
			heading = 45,
		},

		-- Patrol Group 2 - Corsec Commandos
		{
			npc = "corsec_commando",
			x = 150, y = 0, z = 300,
			heading = 90,
		},
		{
			npc = "corsec_officer",
			x = 170, y = 0, z = 320,
			heading = 135,
		},

		-- Patrol Group 3 - Corsec Squad
		{
			npc = "corsec_trooper",
			x = 400, y = 0, z = 500,
			heading = 180,
		},
		{
			npc = "corsec_commando",
			x = 420, y = 0, z = 520,
			heading = 225,
		},
	}

	self:spawnPatrols(zoneName, patrols, "neutral")
end

--[[
	Generic patrol spawning function
]]--
function CityFactionPatrols:spawnPatrols(zoneName, patrolList, faction)
	-- Initialize NPC table for this faction if needed
	if self.factionPatrolNpcs[faction] == nil then
		self.factionPatrolNpcs[faction] = {}
	end

	-- Spawn each patrol NPC
	for i, patrolData in ipairs(patrolList) do
		local npcTemplate = "npc/" .. patrolData.npc

		local pNpc = spawnMobile(
			zoneName,
			npcTemplate,
			0,
			patrolData.x,
			patrolData.z,
			patrolData.y,
			patrolData.heading,
			0
		)

		if pNpc ~= nil then
			-- Make the NPC static (no wandering)
			local aiAgent = AiAgent(pNpc)
			aiAgent:addObjectFlag(AI_STATIC)

			-- Set up despawn observer so we can track when they die
			createObserver(CREATUREDESPAWNED, self.screenplayName, "onPatrolDespawn", pNpc)

			-- Store reference to this NPC
			table.insert(self.factionPatrolNpcs[faction], pNpc)

			print("CityFactionPatrols: Spawned " .. patrolData.npc .. " at (" .. patrolData.x .. ", " .. patrolData.y .. ", " .. patrolData.z .. ")")
		end
	end
end

--[[
	despawnFactionPatrols(faction)
	Despawn all patrols of a given faction
]]--
function CityFactionPatrols:despawnFactionPatrols(faction)
	if self.factionPatrolNpcs[faction] == nil then
		return
	end

	print("CityFactionPatrols: Despawning " .. faction .. " patrols")

	for i, npc in ipairs(self.factionPatrolNpcs[faction]) do
		if npc ~= nil then
			local creatureObject = CreatureObject(npc)
			if creatureObject ~= nil then
				creatureObject:destroyObjectFromWorld(true)
			end
		end
	end

	self.factionPatrolNpcs[faction] = {}
end

--[[
	respawnFactionPatrols(zoneName, cityRegion, oldFaction)
	Call this when city faction alignment changes
	Despawns old faction patrols and spawns new ones
]]--
function CityFactionPatrols:respawnFactionPatrols(zoneName, cityRegion, oldFaction)
	-- Despawn old faction patrols
	if oldFaction ~= nil and oldFaction ~= "" then
		self:despawnFactionPatrols(oldFaction)
	end

	-- Spawn new faction patrols
	self:spawnFactionPatrols(zoneName, cityRegion)
end

--[[
	Observer callback when a patrol NPC despawns (dies or is removed)
]]--
function CityFactionPatrols:onPatrolDespawn(pAiAgent)
	-- Could respawn the NPC here if desired
	-- For now, just log it
	if pAiAgent ~= nil then
		local creatureName = CreatureObject(pAiAgent):getFirstName()
		print("CityFactionPatrols: Patrol NPC " .. creatureName .. " despawned")
	end
end

registerScreenPlay("CityFactionPatrols", true)

function CityFactionPatrols:start()
	-- This screenplay is typically called from city screenplays
	-- Not started independently
	print("CityFactionPatrols screenplay loaded")
end

--[[
	Global handler function called when a city's faction alignment changes
	This is called from C++ when the mayor sets the faction alignment
]]--
function onCityFactionAlignmentChanged(zoneName, factionAlignment)
	print("onCityFactionAlignmentChanged called for zone: " .. zoneName .. " with faction: " .. factionAlignment)

	if not isZoneEnabled(zoneName) then
		print("Zone " .. zoneName .. " is not enabled")
		return
	end

	local zone = getZone(zoneName)
	if zone == nil then
		print("Failed to get zone: " .. zoneName)
		return
	end

	-- Get all regions in this zone to find the city that changed
	local regions = zone:getRegions()
	if regions == nil then
		print("Failed to get regions for zone: " .. zoneName)
		return
	end

	-- Find cities with this faction alignment and spawn patrols
	for i = 1, regions:size() do
		local region = regions:get(i - 1)
		if region ~= nil and region:isCityRegion() then
			local cityRegion = region:getCityRegion()
			if cityRegion ~= nil then
				local currentFaction = cityRegion:getCityFactionAlignment()
				if currentFaction == factionAlignment then
					print("Spawning " .. factionAlignment .. " patrols for city: " .. cityRegion:getCityRegionName())
					CityFactionPatrols:spawnFactionPatrols(zoneName, cityRegion)
				end
			end
		end
	end
end
