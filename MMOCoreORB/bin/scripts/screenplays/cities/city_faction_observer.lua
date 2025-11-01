--[[
	City Faction Observer

	This handles spawning faction patrols when players enter faction-aligned cities.
	Fires when any player enters a city, checks if patrols are needed.
]]--

CityFactionObserver = ScreenPlay:new {
	screenplayName = "CityFactionObserver",
	spawnedCities = {}, -- Track which cities already have patrols
	factionPatrolNpcs = {}, -- Store patrol NPC references
}

function CityFactionObserver:start()
	print("CityFactionObserver: Started")
end

--[[
	Check and spawn faction patrols when player enters a city
]]--
function CityFactionObserver:onPlayerEnteredCity(player, cityRegion)
	if player == nil or cityRegion == nil then
		return
	end

	local cityName = cityRegion:getCityRegionName()
	local zoneName = player:getZoneName()
	local faction = cityRegion:getCityFactionAlignment()

	print("CityFactionObserver: Player " .. player:getFirstName() .. " entered city: " .. cityName .. " (faction: " .. (faction or "nil") .. ")")

	-- Check if city has a faction alignment
	if faction == nil or faction == "" then
		print("CityFactionObserver: City " .. cityName .. " has no faction alignment")
		return
	end

	-- Check if we've already spawned patrols for this city
	local cityId = zoneName .. ":" .. cityName
	if self.spawnedCities[cityId] == faction then
		print("CityFactionObserver: City " .. cityName .. " already has " .. faction .. " patrols spawned")
		return
	end

	-- Spawn patrols for this city
	print("CityFactionObserver: Spawning " .. faction .. " patrols for city: " .. cityName)
	self:spawnFactionPatrols(zoneName, cityRegion, faction)
	self.spawnedCities[cityId] = faction
end

--[[
	Spawn faction patrols for a city
]]--
function CityFactionObserver:spawnFactionPatrols(zoneName, cityRegion, faction)
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

			print("CityFactionObserver: Spawned " .. patrolData.npc .. " at (" .. patrolData.x .. ", " .. patrolData.y .. ", " .. patrolData.z .. ")")
		else
			print("CityFactionObserver: FAILED to spawn " .. patrolData.npc)
		end
	end
end

registerScreenPlay("CityFactionObserver", false)
