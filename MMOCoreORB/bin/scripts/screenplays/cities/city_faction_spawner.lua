--[[
	City Faction Patrol Spawner - Consolidated

	This screenplay automatically spawns faction patrols for all player-created
	cities that have a faction alignment set. It runs when the zones load and
	iterates through all city regions to spawn appropriate NPCs.

	All patrol spawning logic is consolidated into this single file to avoid
	file-loading issues.
]]--

print("DEBUG: city_faction_spawner.lua is starting...")

CityFactionSpawner = ScreenPlay:new {
	screenplayName = "CityFactionSpawner",
	spawnedCities = {}, -- Track which cities already have patrols spawned
	factionPatrolNpcs = {}, -- Store spawned patrol NPCs by faction
}

function CityFactionSpawner:start()
	-- This screenplay runs once when the server starts
	-- NOTE: Periodic zone scanning is disabled because getZone() is not available
	-- in this global Lua context. Patrols will spawn when players enter their cities.

	print("CityFactionSpawner: Started (using on-demand patrol spawning)")
end

function CityFactionSpawner:spawnFactionalPatrolsForZone(zoneName)
	if not isZoneEnabled(zoneName) then
		print("CityFactionSpawner: Zone " .. zoneName .. " is not enabled")
		return false
	end

	local zone = getZone(zoneName)
	if zone == nil then
		print("CityFactionSpawner: Failed to get zone: " .. zoneName)
		return false
	end

	print("CityFactionSpawner: Scanning zone: " .. zoneName)

	-- Get all regions in this zone
	local regions = zone:getRegions()
	if regions == nil then
		print("CityFactionSpawner: Failed to get regions for zone: " .. zoneName)
		return false
	end

	print("CityFactionSpawner: Found " .. regions:size() .. " regions in zone: " .. zoneName)

	local foundCities = false

	-- Iterate through all regions to find cities
	for i = 1, regions:size() do
		local region = regions:get(i - 1)
		if region ~= nil then
			if region:isCityRegion() then
				local cityRegion = region:getCityRegion()
				if cityRegion ~= nil then
					local cityName = cityRegion:getCityRegionName()
					-- Check if this city has a faction alignment set
					local faction = cityRegion:getCityFactionAlignment()
					print("CityFactionSpawner: City found: " .. cityName .. " with faction: " .. (faction or "nil"))

					if faction ~= nil and faction ~= "" then
						foundCities = true
						-- Create unique city ID
						local cityId = zoneName .. ":" .. cityName

						-- Check if we already spawned patrols for this city
						if self.spawnedCities[cityId] ~= faction then
							-- Spawn faction patrols for this city
							print("CityFactionSpawner: Spawning " .. faction .. " patrols for city: " .. cityName)
							self:spawnFactionPatrols(zoneName, cityRegion, faction)
							-- Mark this city as having patrols spawned
							self.spawnedCities[cityId] = faction
						else
							print("CityFactionSpawner: City " .. cityName .. " already has " .. faction .. " patrols spawned")
						end
					else
						print("CityFactionSpawner: City " .. cityName .. " has no faction alignment set")
						-- Clear the spawn record if faction was removed
						local cityId = zoneName .. ":" .. cityName
						self.spawnedCities[cityId] = nil
					end
				else
					print("CityFactionSpawner: cityRegion is nil for city region")
				end
			end
		end
	end

	return foundCities
end

--[[
	Spawn faction patrols for a city
]]--
function CityFactionSpawner:spawnFactionPatrols(zoneName, cityRegion, faction)
	print("CityFactionSpawner: Spawning " .. faction .. " patrols for city: " .. cityRegion:getCityRegionName())

	-- Initialize NPC table for this faction if needed
	if self.factionPatrolNpcs[faction] == nil then
		self.factionPatrolNpcs[faction] = {}
	end

	local patrols = {}

	if faction == "rebel" then
		patrols = {
			{npc = "rebel_soldier_one", x = -100, y = 0, z = 200, heading = 0},
			{npc = "rebel_soldier_two", x = -80, y = 0, z = 220, heading = 45},
			{npc = "rebel_officer", x = 150, y = 0, z = 300, heading = 90},
			{npc = "rebel_commando", x = 170, y = 0, z = 320, heading = 135},
			{npc = "rebel_scout", x = 400, y = 0, z = 500, heading = 180},
			{npc = "rebel_soldier_one", x = 420, y = 0, z = 520, heading = 225},
		}
	elseif faction == "imperial" then
		patrols = {
			{npc = "imperial_trooper_one", x = -100, y = 0, z = 200, heading = 0},
			{npc = "imperial_trooper_two", x = -80, y = 0, z = 220, heading = 45},
			{npc = "imperial_officer", x = 150, y = 0, z = 300, heading = 90},
			{npc = "imperial_commando", x = 170, y = 0, z = 320, heading = 135},
			{npc = "imperial_ensign", x = 400, y = 0, z = 500, heading = 180},
			{npc = "imperial_trooper_one", x = 420, y = 0, z = 520, heading = 225},
		}
	else -- neutral
		patrols = {
			{npc = "corsec_officer", x = -100, y = 0, z = 200, heading = 0},
			{npc = "corsec_trooper", x = -80, y = 0, z = 220, heading = 45},
			{npc = "corsec_commando", x = 150, y = 0, z = 300, heading = 90},
			{npc = "corsec_officer", x = 170, y = 0, z = 320, heading = 135},
			{npc = "corsec_trooper", x = 400, y = 0, z = 500, heading = 180},
			{npc = "corsec_commando", x = 420, y = 0, z = 520, heading = 225},
		}
	end

	-- Spawn each patrol NPC
	for i, patrolData in ipairs(patrols) do
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

			-- Store reference to this NPC
			table.insert(self.factionPatrolNpcs[faction], pNpc)

			print("CityFactionSpawner: Spawned " .. patrolData.npc .. " at (" .. patrolData.x .. ", " .. patrolData.y .. ", " .. patrolData.z .. ")")
		else
			print("CityFactionSpawner: FAILED to spawn " .. patrolData.npc .. " at (" .. patrolData.x .. ", " .. patrolData.y .. ", " .. patrolData.z .. ")")
		end
	end
end

registerScreenPlay("CityFactionSpawner", true)

--[[
	Global function that city screenplays can call to spawn faction patrols
	Usage: In your city screenplay's start() function, call:
	  spawnCityFactionPatrols(zoneName)
]]--
function spawnCityFactionPatrols(zoneName)
	print("DEBUG spawnCityFactionPatrols: Called with zoneName: " .. (zoneName or "nil"))

	if CityFactionSpawner == nil then
		print("DEBUG spawnCityFactionPatrols: ERROR - CityFactionSpawner is nil!")
		return false
	end

	local zone = getZone(zoneName)
	if zone == nil then
		print("DEBUG spawnCityFactionPatrols: ERROR - Failed to get zone: " .. zoneName)
		return false
	end

	print("DEBUG spawnCityFactionPatrols: Got zone successfully: " .. zoneName)

	local regions = zone:getRegions()
	if regions == nil then
		print("DEBUG spawnCityFactionPatrols: ERROR - Failed to get regions for zone: " .. zoneName)
		return false
	end

	print("DEBUG spawnCityFactionPatrols: Found " .. regions:size() .. " regions in zone")

	-- Find the city region and check for faction alignment
	for i = 1, regions:size() do
		local region = regions:get(i - 1)
		print("DEBUG spawnCityFactionPatrols: Checking region " .. i .. " of " .. regions:size())
		if region ~= nil and region:isCityRegion() then
			local cityRegion = region:getCityRegion()
			if cityRegion ~= nil then
				local cityName = cityRegion:getCityRegionName()
				local faction = cityRegion:getCityFactionAlignment()
				print("DEBUG spawnCityFactionPatrols: Found city '" .. cityName .. "' with faction: " .. (faction or "nil"))
				if faction ~= nil and faction ~= "" then
					print("DEBUG spawnCityFactionPatrols: SPAWNING " .. faction .. " patrols for city: " .. cityName)
					CityFactionSpawner:spawnFactionPatrols(zoneName, cityRegion, faction)
					return true
				end
			end
			break
		end
	end

	print("DEBUG spawnCityFactionPatrols: No cities with faction alignment found")
	return false
end

--[[
	Called from C++ when a city with faction alignment is loaded from database
]]--
function onCityFactionAlignmentLoaded(zoneName, factionAlignment, cityObjectID)
	print("onCityFactionAlignmentLoaded: Zone=" .. zoneName .. " Faction=" .. factionAlignment .. " CityID=" .. cityObjectID)

	if factionAlignment == nil or factionAlignment == "" or factionAlignment == "neutral" then
		print("onCityFactionAlignmentLoaded: City has no faction alignment, skipping patrol spawn")
		return
	end

	-- Safely spawn patrols using pcall to catch errors
	local success, result = pcall(function()
		local zone = getZone(zoneName)
		if zone == nil then
			print("onCityFactionAlignmentLoaded: Failed to get zone: " .. zoneName)
			return false
		end

		local regions = zone:getRegions()
		if regions == nil then
			print("onCityFactionAlignmentLoaded: Failed to get regions")
			return false
		end

		-- Find the matching city region and spawn patrols
		for i = 1, regions:size() do
			local region = regions:get(i - 1)
			if region ~= nil and region:isCityRegion() then
				local cityRegion = region:getCityRegion()
				if cityRegion ~= nil and cityRegion:getCityFactionAlignment() == factionAlignment then
					print("onCityFactionAlignmentLoaded: Spawning " .. factionAlignment .. " patrols for city: " .. cityRegion:getCityRegionName())
					CityFactionSpawner:spawnFactionPatrols(zoneName, cityRegion, factionAlignment)
					return true
				end
			end
		end

		return false
	end)

	if not success then
		print("onCityFactionAlignmentLoaded: Error during patrol spawn: " .. tostring(result))
	end
end

print("DEBUG: city_faction_spawner.lua loaded successfully!")
