HeavyOrdinanceTrial = ScreenPlay:new {
	screenplayName = "HeavyOrdinanceTrial",
	numberOfActs = 1,
}

registerScreenPlay("HeavyOrdinanceTrial", true)

HeavyOrdinanceTrial.SCRIPT_NAMESPACE = "heavy_ordinance_trial"
HeavyOrdinanceTrial.NPC_TEMPLATE = "captain_durn_valek"
HeavyOrdinanceTrial.NPC_NAME = "Captain Durn Valek"
HeavyOrdinanceTrial.NPC_PLANET = "tatooine"
HeavyOrdinanceTrial.NPC_X = 3794
HeavyOrdinanceTrial.NPC_Z = 8
HeavyOrdinanceTrial.NPC_Y = 2327
HeavyOrdinanceTrial.NPC_HEADING = 180
HeavyOrdinanceTrial.REQUIRED_SKILL = "combat_commando_novice"
HeavyOrdinanceTrial.COOLDOWN_SECONDS = 20 * 60 * 60
HeavyOrdinanceTrial.MAX_TRACKED_MOBS = 48
HeavyOrdinanceTrial.MAX_TRACKED_OBJECTS = 48
HeavyOrdinanceTrial.REWARD_HOLOCRON_TEMPLATE = "object/tangible/loot/misc/holocron_of_destiny.iff"
HeavyOrdinanceTrial.REWARD_ATTACHMENT_TEMPLATE = "object/tangible/gem/clothing.iff"
HeavyOrdinanceTrial.WAYPOINT_NAME = "Heavy Ordinance Trial"
HeavyOrdinanceTrial.REWARD_RADIUS = 180
HeavyOrdinanceTrial.START_GROUP_RADIUS = 128
HeavyOrdinanceTrial.COMBAT_RADIUS = 256
HeavyOrdinanceTrial.LEAVE_FAIL_SECONDS = 300
HeavyOrdinanceTrial.OPERATION_TIMEOUT_SECONDS = 5400
HeavyOrdinanceTrial.STRUCTURE_TARGET = 3
HeavyOrdinanceTrial.PIRATE_TARGET = 12
HeavyOrdinanceTrial.STRUCTURE_WAVE_SIZE = 1
HeavyOrdinanceTrial.PIRATE_WAVE_SIZE = 4
HeavyOrdinanceTrial.NEXT_WAVE_DELAY_MS = 4000
HeavyOrdinanceTrial.DEBUG_HIT_MESSAGES = true
HeavyOrdinanceTrial.WEAPON_MASK_THROWN = 0x1
HeavyOrdinanceTrial.WEAPON_MASK_HEAVY = 0x2
HeavyOrdinanceTrial.WEAPON_MASK_MINE = 0x4
HeavyOrdinanceTrial.WEAPON_MASK_SPECIAL_HEAVY = 0x8
HeavyOrdinanceTrial.GOTYPE_THROWN = 0x20003
HeavyOrdinanceTrial.GOTYPE_HEAVY = 0x20004
HeavyOrdinanceTrial.GOTYPE_SPECIAL_HEAVY = 0x20006

HeavyOrdinanceTrial.ENCOUNTERS = {
	{
		planet = "tatooine",
		name = "The Dune Battery",
		x = 3520, z = 5, y = 2640,
		waypointDesc = "Pirate siege line entrenched in the dunes.",
		deco = {
			{ template = "object/tangible/lair/base/objective_power_generator.iff", x = 3511, z = 5, y = 2648, heading = 0 },
			{ template = "object/tangible/camp/camp_crate_s1.iff", x = 3529, z = 5, y = 2627, heading = 0 },
			{ template = "object/tangible/camp/campfire_logs_smoldering.iff", x = 3504, z = 5, y = 2661, heading = 0 },
			{ template = "object/static/particle/pt_smoke_large.iff", x = 3508, z = 5, y = 2663, heading = 0 },
			{ template = "object/static/destructible/destructible_item_barrel.iff", x = 3535, z = 5, y = 2646, heading = 0 },
			{ template = "object/static/destructible/destructible_tato_drum_storage1.iff", x = 3537, z = 5, y = 2649, heading = 0 },
		},
		structures = {
			{ template = "hot_emplacement_turret", name = "North Flank Turret", x = 3508, z = 5, y = 2675, heading = 180 },
			{ template = "hot_emplacement_generator", name = "Shield Generator Alpha", x = 3540, z = 5, y = 2636, heading = 0 },
			{ template = "hot_emplacement_artillery", name = "Siege Cannon", x = 3488, z = 5, y = 2628, heading = 90 },
		},
		pirateSpawn = {
			{ x = 3522, z = 5, y = 2658, heading = 180 },
			{ x = 3513, z = 5, y = 2631, heading = 55 },
			{ x = 3496, z = 5, y = 2646, heading = -40 },
			{ x = 3533, z = 5, y = 2670, heading = -120 },
			{ x = 3546, z = 5, y = 2651, heading = 135 },
			{ x = 3487, z = 5, y = 2664, heading = -10 },
		},
		boss = { x = 3518, z = 5, y = 2610, heading = 0 },
	},
	{
		planet = "lok",
		name = "The Sulfur Redoubt",
		x = 1370, z = 12, y = -3720,
		waypointDesc = "A fortified pirate battery dug into the rocks.",
		deco = {
			{ template = "object/tangible/lair/base/objective_power_transformer.iff", x = 1381, z = 12, y = -3710, heading = 0 },
			{ template = "object/tangible/camp/camp_crate_s1.iff", x = 1358, z = 12, y = -3706, heading = 0 },
			{ template = "object/static/particle/pt_lok_volcano_smoke_sm.iff", x = 1376, z = 12, y = -3733, heading = 0 },
			{ template = "object/static/destructible/destructible_item_barrel.iff", x = 1362, z = 12, y = -3727, heading = 0 },
			{ template = "object/tangible/camp/campfire_logs_burnt.iff", x = 1389, z = 12, y = -3721, heading = 0 },
		},
		structures = {
			{ template = "hot_emplacement_turret", name = "Basalt Turret", x = 1395, z = 12, y = -3739, heading = 160 },
			{ template = "hot_emplacement_generator", name = "Shield Generator Beta", x = 1355, z = 12, y = -3742, heading = -40 },
			{ template = "hot_emplacement_artillery", name = "Mortar Nest", x = 1368, z = 12, y = -3692, heading = 0 },
		},
		pirateSpawn = {
			{ x = 1378, z = 12, y = -3748, heading = 150 },
			{ x = 1352, z = 12, y = -3718, heading = -65 },
			{ x = 1400, z = 12, y = -3710, heading = 85 },
			{ x = 1387, z = 12, y = -3688, heading = 120 },
			{ x = 1348, z = 12, y = -3732, heading = -15 },
			{ x = 1360, z = 12, y = -3698, heading = 15 },
		},
		boss = { x = 1374, z = 12, y = -3765, heading = 0 },
	},
	{
		planet = "dantooine",
		name = "The Ridgebreaker Camp",
		x = -2145, z = 7, y = -1390,
		waypointDesc = "Pirate gun pits dominating the ridge line.",
		deco = {
			{ template = "object/tangible/lair/base/objective_power_node.iff", x = -2140, z = 7, y = -1375, heading = 0 },
			{ template = "object/tangible/camp/camp_crate_s1.iff", x = -2160, z = 7, y = -1398, heading = 0 },
			{ template = "object/tangible/camp/campfire_logs_smoldering.iff", x = -2127, z = 7, y = -1406, heading = 0 },
			{ template = "object/static/particle/pt_burning_smokeandembers_md.iff", x = -2128, z = 7, y = -1405, heading = 0 },
			{ template = "object/static/destructible/destructible_tato_crate1.iff", x = -2154, z = 7, y = -1379, heading = 0 },
		},
		structures = {
			{ template = "hot_emplacement_turret", name = "East Slope Turret", x = -2124, z = 7, y = -1382, heading = 180 },
			{ template = "hot_emplacement_generator", name = "Shield Generator Gamma", x = -2168, z = 7, y = -1395, heading = 0 },
			{ template = "hot_emplacement_artillery", name = "Field Artillery", x = -2147, z = 7, y = -1416, heading = 90 },
		},
		pirateSpawn = {
			{ x = -2130, z = 7, y = -1394, heading = 180 },
			{ x = -2163, z = 7, y = -1381, heading = 65 },
			{ x = -2156, z = 7, y = -1410, heading = -35 },
			{ x = -2122, z = 7, y = -1408, heading = -95 },
			{ x = -2174, z = 7, y = -1400, heading = 110 },
			{ x = -2142, z = 7, y = -1368, heading = 25 },
		},
		boss = { x = -2148, z = 7, y = -1446, heading = 0 },
	},
	{
		planet = "endor",
		name = "The Black Timber Battery",
		x = -4635, z = 22, y = 1018,
		waypointDesc = "An entrenched pirate line in the forest burn scar.",
		deco = {
			{ template = "object/tangible/lair/base/objective_power_generator.iff", x = -4623, z = 22, y = 1028, heading = 0 },
			{ template = "object/tangible/camp/camp_crate_s1.iff", x = -4648, z = 22, y = 1001, heading = 0 },
			{ template = "object/static/particle/pt_smoke_large.iff", x = -4653, z = 22, y = 1026, heading = 0 },
			{ template = "object/static/particle/pt_burning_smokeandembers_large.iff", x = -4633, z = 22, y = 1005, heading = 0 },
			{ template = "object/static/destructible/destructible_item_barrel.iff", x = -4627, z = 22, y = 1010, heading = 0 },
		},
		structures = {
			{ template = "hot_emplacement_turret", name = "Timberline Turret", x = -4620, z = 22, y = 1044, heading = 160 },
			{ template = "hot_emplacement_generator", name = "Shield Generator Delta", x = -4658, z = 22, y = 1021, heading = -20 },
			{ template = "hot_emplacement_artillery", name = "Forest Siege Gun", x = -4642, z = 22, y = 989, heading = 15 },
		},
		pirateSpawn = {
			{ x = -4628, z = 22, y = 1032, heading = 160 },
			{ x = -4659, z = 22, y = 1008, heading = -40 },
			{ x = -4667, z = 22, y = 1034, heading = -95 },
			{ x = -4614, z = 22, y = 1001, heading = 55 },
			{ x = -4638, z = 22, y = 976, heading = 10 },
			{ x = -4618, z = 22, y = 1016, heading = 130 },
		},
		boss = { x = -4638, z = 22, y = 958, heading = 0 },
	},
}

HeavyOrdinanceTrial.PIRATE_TEMPLATES = {
	"hot_pirate_heavy_raider",
	"hot_pirate_flame_trooper",
	"hot_pirate_shield_technician",
	"hot_pirate_berserker_bruiser",
	"hot_pirate_mortar_specialist",
}

HeavyOrdinanceTrial.rewardStatPool = {
	{ key = "heavy_flame_thrower_accuracy", display = "Heavy Flame Thrower Accuracy" },
	{ key = "heavy_acid_beam_accuracy", display = "Heavy Acid Beam Accuracy" },
	{ key = "heavy_lightning_beam_accuracy", display = "Heavy Lightning Beam Accuracy" },
	{ key = "heavy_particle_beam_accuracy", display = "Heavy Particle Beam Accuracy" },
	{ key = "heavy_rocket_launcher_accuracy", display = "Heavy Rocket Launcher Accuracy" },
	{ key = "heavy_weapon_accuracy", display = "Heavy Weapon Accuracy" },
	{ key = "heavy_weapon_speed", display = "Heavy Weapon Speed" },
	{ key = "heavy_flame_thrower_speed", display = "Heavy Flame Thrower Speed" },
	{ key = "heavy_acid_beam_speed", display = "Heavy Acid Beam Speed" },
	{ key = "heavy_lightning_beam_speed", display = "Heavy Lightning Beam Speed" },
	{ key = "heavy_particle_beam_speed", display = "Heavy Particle Beam Speed" },
	{ key = "heavy_rocket_launcher_speed", display = "Heavy Rocket Launcher Speed" },
}

function HeavyOrdinanceTrial:start()
	self:spawnNpc()
end

function HeavyOrdinanceTrial:resolveGroundZ(planet, x, y, fallback)
	local resolvers = {}

	if (type(getWorldFloor) == "function") then
		table.insert(resolvers, function()
			return getWorldFloor(x, y, planet)
		end)
	end

	if (type(getTerrainHeight) == "function") then
		table.insert(resolvers, function()
			return getTerrainHeight(x, y)
		end)
		table.insert(resolvers, function()
			return getTerrainHeight(planet, x, y)
		end)
	end

	for index = 1, #resolvers, 1 do
		local ok, z = pcall(resolvers[index])
		if (ok and type(z) == "number" and z == z) then
			return z, true
		end
	end

	return fallback or 0, false
end

function HeavyOrdinanceTrial:getTerrainZ(planet, x, y, fallback)
	local z = self:resolveGroundZ(planet, x, y, fallback)
	return z
end

function HeavyOrdinanceTrial:getStableSpawnZ(planet, x, y, preferredZ)
	local groundZ, foundGround = self:resolveGroundZ(planet, x, y, preferredZ)

	if (foundGround) then
		return groundZ
	end

	return preferredZ or groundZ
end

function HeavyOrdinanceTrial:spawnNpc()
	local npcZ = self:getStableSpawnZ(self.NPC_PLANET, self.NPC_X, self.NPC_Y, self.NPC_Z)
	local pNpc = spawnMobile(self.NPC_PLANET, self.NPC_TEMPLATE, 0, self.NPC_X, npcZ, self.NPC_Y, self.NPC_HEADING, 0)

	if (pNpc == nil) then
		return
	end

	CreatureObject(pNpc):setPvpStatusBitmask(0)
	CreatureObject(pNpc):setOptionsBitmask(AIENABLED + CONVERSABLE + INVULNERABLE)
	SceneObject(pNpc):setCustomObjectName(self.NPC_NAME)
	AiAgent(pNpc):setConvoTemplate("heavyOrdinanceTrialConvoTemplate")
	AiAgent(pNpc):addObjectFlag(AI_STATIC)
end

function HeavyOrdinanceTrial:getNow()
	return os.time()
end

function HeavyOrdinanceTrial:getNumber(pPlayer, key)
	if (pPlayer == nil) then
		return 0
	end

	return tonumber(readScreenPlayData(pPlayer, self.SCRIPT_NAMESPACE, key)) or 0
end

function HeavyOrdinanceTrial:setNumber(pPlayer, key, value)
	if (pPlayer ~= nil) then
		writeScreenPlayData(pPlayer, self.SCRIPT_NAMESPACE, key, value)
	end
end

function HeavyOrdinanceTrial:getString(pPlayer, key)
	if (pPlayer == nil) then
		return ""
	end

	return tostring(readScreenPlayData(pPlayer, self.SCRIPT_NAMESPACE, key) or "")
end

function HeavyOrdinanceTrial:setString(pPlayer, key, value)
	if (pPlayer ~= nil) then
		writeScreenPlayData(pPlayer, self.SCRIPT_NAMESPACE, key, value or "")
	end
end

function HeavyOrdinanceTrial:getDataNumber(key, fallback)
	return tonumber(readData(key)) or (fallback or 0)
end

function HeavyOrdinanceTrial:setDataNumber(key, value)
	writeData(key, tonumber(value) or 0)
end

function HeavyOrdinanceTrial:deleteDataKey(key)
	deleteData(key)
end

function HeavyOrdinanceTrial:isValidPlayer(pPlayer)
	return pPlayer ~= nil and SceneObject(pPlayer):isPlayerCreature()
end

function HeavyOrdinanceTrial:getPlayerId(pPlayer)
	if (pPlayer == nil) then
		return 0
	end

	return SceneObject(pPlayer):getObjectID()
end

function HeavyOrdinanceTrial:isEligibleCommando(pPlayer)
	return self:isValidPlayer(pPlayer) and CreatureObject(pPlayer):hasSkill(self.REQUIRED_SKILL)
end

function HeavyOrdinanceTrial:getRemainingCooldown(pPlayer)
	local remaining = self:getNumber(pPlayer, "cooldown_until") - self:getNow()
	if (remaining < 0) then
		return 0
	end
	return remaining
end

function HeavyOrdinanceTrial:isOnCooldown(pPlayer)
	return self:getRemainingCooldown(pPlayer) > 0
end

function HeavyOrdinanceTrial:isActive(pPlayer)
	return self:getNumber(pPlayer, "active") == 1
end

function HeavyOrdinanceTrial:isRewardPending(pPlayer)
	return self:isActive(pPlayer) and self:getNumber(pPlayer, "reward_pending") == 1
end

function HeavyOrdinanceTrial:getOwnerId(pPlayer)
	local ownerId = self:getNumber(pPlayer, "owner_id")
	if (ownerId <= 0) then
		return self:getPlayerId(pPlayer)
	end
	return ownerId
end

function HeavyOrdinanceTrial:isOwner(pPlayer)
	return self:getPlayerId(pPlayer) == self:getOwnerId(pPlayer)
end

function HeavyOrdinanceTrial:getEncounterIndex(pPlayer)
	return self:getNumber(pPlayer, "encounter_index")
end

function HeavyOrdinanceTrial:getEncounterDataByIndex(index)
	return self.ENCOUNTERS[index]
end

function HeavyOrdinanceTrial:getEncounterData(pPlayer)
	return self:getEncounterDataByIndex(self:getEncounterIndex(pPlayer))
end

function HeavyOrdinanceTrial:getEncounterKey(ownerId, suffix)
	return "heavy_ordinance_trial:" .. tostring(ownerId) .. ":" .. suffix
end

function HeavyOrdinanceTrial:getTrackedIdKey(prefix, index)
	return prefix .. "_" .. tostring(index)
end

function HeavyOrdinanceTrial:formatDuration(seconds)
	if (seconds <= 0) then
		return "0 minutes"
	end

	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	if ((seconds % 60) > 0) then
		minutes = minutes + 1
	end
	if (minutes >= 60) then
		minutes = minutes - 60
		hours = hours + 1
	end

	if (hours <= 0) then
		return tostring(minutes) .. " minutes"
	elseif (minutes <= 0) then
		return tostring(hours) .. " hours"
	end

	return tostring(hours) .. " hours and " .. tostring(minutes) .. " minutes"
end

function HeavyOrdinanceTrial:isPlayerGrouped(pPlayer)
	return self:isValidPlayer(pPlayer) and CreatureObject(pPlayer):isGrouped()
end

function HeavyOrdinanceTrial:getGroupMembers(pPlayer)
	local members = {}
	local seen = {}

	if (self:isPlayerGrouped(pPlayer) ~= true) then
		table.insert(members, pPlayer)
		return members
	end

	local creature = CreatureObject(pPlayer)
	local groupSize = tonumber(creature:getGroupSize()) or 0

	for index = 0, groupSize - 1, 1 do
		local pMember = creature:getGroupMember(index)
		if (self:isValidPlayer(pMember)) then
			local memberId = self:getPlayerId(pMember)
			if (seen[memberId] ~= true) then
				seen[memberId] = true
				table.insert(members, pMember)
			end
		end
	end

	if (#members <= 0) then
		table.insert(members, pPlayer)
	end

	return members
end

function HeavyOrdinanceTrial:getStartEligibleMembers(pPlayer)
	local candidates = self:getGroupMembers(pPlayer)
	local eligible = {}
	local encounterEligible = 0

	for index = 1, #candidates, 1 do
		local pMember = candidates[index]
		if (self:isEligibleCommando(pMember) and not self:isActive(pMember) and not self:isOnCooldown(pMember) and SceneObject(pMember):isInRangeWithObject(pPlayer, self.START_GROUP_RADIUS)) then
			table.insert(eligible, pMember)
			encounterEligible = encounterEligible + 1
		end
	end

	if (encounterEligible <= 0 and self:isEligibleCommando(pPlayer) and not self:isActive(pPlayer) and not self:isOnCooldown(pPlayer)) then
		table.insert(eligible, pPlayer)
	end

	return eligible
end

function HeavyOrdinanceTrial:getOwnerParticipants(pOwner)
	local participants = {}

	if (pOwner == nil) then
		return participants
	end

	local ownerId = self:getPlayerId(pOwner)
	local members = self:getGroupMembers(pOwner)

	for index = 1, #members, 1 do
		local pMember = members[index]
		if (self:isActive(pMember) and self:getOwnerId(pMember) == ownerId) then
			table.insert(participants, pMember)
		end
	end

	if (#participants <= 0 and self:isActive(pOwner)) then
		table.insert(participants, pOwner)
	end

	return participants
end

function HeavyOrdinanceTrial:updateWaypoint(pPlayer)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil) then
		return
	end

	local oldWaypoint = self:getNumber(pPlayer, "waypoint_id")
	if (not self:isActive(pPlayer)) then
		if (oldWaypoint > 0) then
			PlayerObject(pGhost):removeWaypoint(oldWaypoint, true)
			self:setNumber(pPlayer, "waypoint_id", 0)
		end
		return
	end

	local encounter = self:getEncounterData(pPlayer)
	if (encounter == nil) then
		return
	end

	local desc = encounter.waypointDesc
	local waypointId = 0
	if (self:isRewardPending(pPlayer)) then
		desc = "Return to Captain Durn Valek for debrief."
		local npcZ = self:getTerrainZ(self.NPC_PLANET, self.NPC_X, self.NPC_Y, self.NPC_Z)
		waypointId = PlayerObject(pGhost):addWaypoint(self.NPC_PLANET, self.NPC_NAME, desc, self.NPC_X, npcZ, self.NPC_Y, WAYPOINT_YELLOW, true, true, 0, 0)
		if (waypointId ~= nil and tonumber(waypointId) ~= nil and tonumber(waypointId) > 0) then
			if (oldWaypoint > 0) then
				PlayerObject(pGhost):removeWaypoint(oldWaypoint, true)
			end
			self:setNumber(pPlayer, "waypoint_id", waypointId)
		end
		return
	end

	local phase = self:getString(pPlayer, "phase")
	if (phase == "boss") then
		desc = encounter.waypointDesc .. " Kragg the Siegebreaker is in the field."
	elseif (phase == "pirates") then
		desc = encounter.waypointDesc .. " Eliminate pirate resistance with heavy weapons."
	else
		desc = encounter.waypointDesc .. " Destroy pirate emplacements."
	end

	local encounterZ = self:getTerrainZ(encounter.planet, encounter.x, encounter.y, encounter.z)
	waypointId = PlayerObject(pGhost):addWaypoint(encounter.planet, self.WAYPOINT_NAME, desc, encounter.x, encounterZ, encounter.y, WAYPOINT_YELLOW, true, true, 0, 0)

	if (waypointId ~= nil and tonumber(waypointId) ~= nil and tonumber(waypointId) > 0) then
		if (oldWaypoint > 0) then
			PlayerObject(pGhost):removeWaypoint(oldWaypoint, true)
		end
		self:setNumber(pPlayer, "waypoint_id", waypointId)
	end
end

function HeavyOrdinanceTrial:removeWaypoint(pPlayer)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil) then
		return
	end

	local oldWaypoint = self:getNumber(pPlayer, "waypoint_id")
	if (oldWaypoint > 0) then
		PlayerObject(pGhost):removeWaypoint(oldWaypoint, true)
	end

	self:setNumber(pPlayer, "waypoint_id", 0)
end

function HeavyOrdinanceTrial:getRulesText()
	return "Heavy Ordinance Trial Doctrine\n\n"
		.. "Only Commandos may undertake this contract.\n"
		.. "Only heavy methods count: rocket launchers, flamethrowers, acid beams, heavy lightning beams, grenades, and mines.\n"
		.. "Pistols, carbines, rifles, Jedi weapons, pets, and droids earn no credit.\n"
		.. "Destroy 3 pirate emplacements, eliminate 12 pirates with valid heavy weapon kills, and break Kragg the Siegebreaker.\n"
		.. "Grouped commandos can share field progress, but every trooper must contribute valid heavy damage to earn the debrief reward.\n"
		.. "Operational lockout: 20 hours after reward issue."
end

function HeavyOrdinanceTrial:getCooldownText(pPlayer)
	if (not self:isOnCooldown(pPlayer)) then
		return "Your heavy assault record is clear. You are authorized for another siege run."
	end

	return "Your last battlefield operation is still on lockout. Remaining cooldown: " .. self:formatDuration(self:getRemainingCooldown(pPlayer)) .. "."
end

function HeavyOrdinanceTrial:getPhaseLabel(pPlayer)
	local phase = self:getString(pPlayer, "phase")
	if (phase == "structures") then
		return "Destroy emplacements"
	elseif (phase == "pirates") then
		return "Eliminate pirate forces"
	elseif (phase == "boss") then
		return "Neutralize Kragg the Siegebreaker"
	elseif (phase == "complete") then
		return "Return for debrief"
	end
	return "Awaiting orders"
end

function HeavyOrdinanceTrial:getProgressText(pPlayer, refreshWaypoint)
	if (not self:isEligibleCommando(pPlayer)) then
		return "You are not on the heavy assault roster. This trial is reserved for Commandos."
	end

	if (not self:isActive(pPlayer)) then
		if (self:isOnCooldown(pPlayer)) then
			return self:getCooldownText(pPlayer)
		end

		return "Captain Durn Valek is holding a live-fire assault brief. If you can break fortifications with heavy weapons, report for deployment."
	end

	if (refreshWaypoint == true) then
		self:updateWaypoint(pPlayer)
		if (self:isOwner(pPlayer)) then
			self:ensureEncounterForOwner(pPlayer)
		end
	end

	local structures = self:getNumber(pPlayer, "structure_count")
	local pirates = self:getNumber(pPlayer, "pirate_count")
	local contributions = self:getNumber(pPlayer, "valid_kills") + self:getNumber(pPlayer, "structure_contrib")
	local lines = {
		"Heavy Ordinance Trial Field Report",
		"",
		"Operation: " .. tostring((self:getEncounterData(pPlayer) or {}).name or "Unknown battlefield"),
		"Phase: " .. self:getPhaseLabel(pPlayer),
		"Emplacements destroyed: " .. tostring(structures) .. "/" .. tostring(self.STRUCTURE_TARGET),
		"Pirates eliminated: " .. tostring(pirates) .. "/" .. tostring(self.PIRATE_TARGET),
		"Your valid heavy contributions: " .. tostring(contributions),
	}

	if (self:isRewardPending(pPlayer)) then
		table.insert(lines, "Debrief status: ready for reward issue.")
	else
		table.insert(lines, "Debrief status: operation still live.")
	end

	return table.concat(lines, "\n")
end

function HeavyOrdinanceTrial:getIntroText(pPlayer)
	if (not self:isEligibleCommando(pPlayer)) then
		return "Any fool can pull a trigger. I need a Commando who can turn a pirate redoubt into a crater. Come back when you belong to the heavy assault line."
	end

	if (self:isRewardPending(pPlayer)) then
		return "You broke their line and lived. Debrief now and I'll issue your battlefield pay.\n\n" .. self:getProgressText(pPlayer, false)
	end

	if (self:isActive(pPlayer)) then
		return "Your siege operation is still underway. If you lost the line of advance, ask for a battlefield report and I'll push the waypoint again.\n\n" .. self:getProgressText(pPlayer, false)
	end

	if (self:isOnCooldown(pPlayer)) then
		return "You already burned one pirate camp to the bedrock. I will not authorize another assault until the logistics chain catches up.\n\n" .. self:getCooldownText(pPlayer)
	end

	return "Any fool can pull a trigger. I need someone who can level an entire battlefield. Pirates have fortified assault camps across the frontier. You will deploy, break their emplacements with heavy weapons, butcher their line troops, and drag their demolitions commander back to me in pieces."
end

function HeavyOrdinanceTrial:isValidHeavyWeaponType(weaponType)
	local validMask = self.WEAPON_MASK_HEAVY + self.WEAPON_MASK_SPECIAL_HEAVY + self.WEAPON_MASK_THROWN + self.WEAPON_MASK_MINE
	return weaponType ~= nil and bit32.band(weaponType, validMask) ~= 0
end

function HeavyOrdinanceTrial:getEquippedWeaponInfo(pPlayer)
	local info = {
		mask = 0,
		gameType = 0,
		path = "",
		slot = "",
	}

	if (not self:isValidPlayer(pPlayer)) then
		return info
	end

	info.mask = tonumber(CreatureObject(pPlayer):getWeaponType()) or 0

	local slotNames = { "hold_r", "default_weapon" }
	for index = 1, #slotNames, 1 do
		local slotName = slotNames[index]
		local pWeapon = SceneObject(pPlayer):getSlottedObject(slotName)
		if (pWeapon ~= nil) then
			info.gameType = tonumber(SceneObject(pWeapon):getGameObjectType()) or 0
			info.path = string.lower(tostring(SceneObject(pWeapon):getTemplateObjectPath() or ""))
			info.slot = slotName
			if (info.gameType ~= 0 or info.path ~= "") then
				return info
			end
		end
	end

	return info
end

function HeavyOrdinanceTrial:isRecognizedHeavyWeaponPath(templatePath)
	if (templatePath == nil or templatePath == "") then
		return false
	end

	return string.find(templatePath, "weapon/ranged/heavy/", 1, true) ~= nil
		or string.find(templatePath, "rifle_flame_thrower", 1, true) ~= nil
		or string.find(templatePath, "rifle_lightning", 1, true) ~= nil
		or string.find(templatePath, "rifle_lightning_heavy", 1, true) ~= nil
		or string.find(templatePath, "rifle_beam", 1, true) ~= nil
		or string.find(templatePath, "rifle_acid_beam", 1, true) ~= nil
		or string.find(templatePath, "weapon/ranged/grenade/", 1, true) ~= nil
		or string.find(templatePath, "weapon/mine/", 1, true) ~= nil
end

function HeavyOrdinanceTrial:isValidHeavyWeaponUser(pPlayer)
	if (not self:isValidPlayer(pPlayer)) then
		return false
	end

	local weaponInfo = self:getEquippedWeaponInfo(pPlayer)

	if (self:isValidHeavyWeaponType(weaponInfo.mask)) then
		return true
	end

	if (weaponInfo.gameType == self.GOTYPE_HEAVY or weaponInfo.gameType == self.GOTYPE_SPECIAL_HEAVY or weaponInfo.gameType == self.GOTYPE_THROWN) then
		return true
	end

	return self:isRecognizedHeavyWeaponPath(weaponInfo.path)
end

function HeavyOrdinanceTrial:markLastInvalidMethodMessage(pPlayer)
	local now = self:getNow()
	local lastAt = self:getNumber(pPlayer, "invalid_method_message_at")
	if ((now - lastAt) < 5) then
		return
	end

	self:setNumber(pPlayer, "invalid_method_message_at", now)
	local weaponInfo = self:getEquippedWeaponInfo(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("Only heavy ordinance counts for this operation. Weapon mask: " .. tostring(weaponInfo.mask) .. ", game type: " .. tostring(weaponInfo.gameType) .. ", slot: " .. tostring(weaponInfo.slot) .. ", template: " .. tostring(weaponInfo.path) .. ".")
end

function HeavyOrdinanceTrial:refreshObservers(pPlayer)
	if (pPlayer == nil) then
		return
	end

	dropObserver(LOGGEDIN, self.screenplayName, "onLoggedIn", pPlayer)
	dropObserver(KILLEDCREATURE, self.screenplayName, "notifyKilledCreature", pPlayer)

	if (self:isActive(pPlayer)) then
		createObserver(LOGGEDIN, self.screenplayName, "onLoggedIn", pPlayer, 1)
		createObserver(KILLEDCREATURE, self.screenplayName, "notifyKilledCreature", pPlayer)
	end
end

function HeavyOrdinanceTrial:clearPlayerState(pPlayer, keepCooldown)
	self:removeWaypoint(pPlayer)
	self:setNumber(pPlayer, "active", 0)
	self:setNumber(pPlayer, "reward_pending", 0)
	self:setNumber(pPlayer, "encounter_index", 0)
	self:setNumber(pPlayer, "owner_id", 0)
	self:setNumber(pPlayer, "structure_count", 0)
	self:setNumber(pPlayer, "pirate_count", 0)
	self:setNumber(pPlayer, "valid_kills", 0)
	self:setNumber(pPlayer, "structure_contrib", 0)
	self:setNumber(pPlayer, "boss_contrib", 0)
	self:setNumber(pPlayer, "reward_eligible", 0)
	self:setNumber(pPlayer, "leave_started_at", 0)
	self:setNumber(pPlayer, "invalid_method_message_at", 0)
	self:setString(pPlayer, "phase", "")
	if (keepCooldown ~= true) then
		self:setNumber(pPlayer, "cooldown_until", 0)
	end
	self:refreshObservers(pPlayer)
end

function HeavyOrdinanceTrial:clearEncounterTracking(ownerId)
	for index = 1, self.MAX_TRACKED_MOBS, 1 do
		self:deleteDataKey(self:getEncounterKey(ownerId, "mob_" .. tostring(index)))
	end

	for index = 1, self.MAX_TRACKED_OBJECTS, 1 do
		self:deleteDataKey(self:getEncounterKey(ownerId, "obj_" .. tostring(index)))
	end

	self:deleteDataKey(self:getEncounterKey(ownerId, "deco_count"))
	self:deleteDataKey(self:getEncounterKey(ownerId, "mob_count"))
	self:deleteDataKey(self:getEncounterKey(ownerId, "area_id"))
	self:deleteDataKey(self:getEncounterKey(ownerId, "structures_live"))
	self:deleteDataKey(self:getEncounterKey(ownerId, "structures_spawned"))
	self:deleteDataKey(self:getEncounterKey(ownerId, "next_structure_wave_pending"))
	self:deleteDataKey(self:getEncounterKey(ownerId, "pirates_live"))
	self:deleteDataKey(self:getEncounterKey(ownerId, "pirates_spawned"))
	self:deleteDataKey(self:getEncounterKey(ownerId, "next_pirate_wave_pending"))
	self:deleteDataKey(self:getEncounterKey(ownerId, "boss_id"))
	self:deleteDataKey(self:getEncounterKey(ownerId, "boss70"))
	self:deleteDataKey(self:getEncounterKey(ownerId, "boss40"))
	self:deleteDataKey(self:getEncounterKey(ownerId, "boss20"))
	self:deleteDataKey(self:getEncounterKey(ownerId, "zone_engaged"))
	self:deleteDataKey(self:getEncounterKey(ownerId, "started_at"))
end

function HeavyOrdinanceTrial:destroySceneObjectById(objectId)
	if (objectId == nil or objectId <= 0) then
		return
	end

	self:clearEncounterObjectData(objectId)

	local pObject = getSceneObject(objectId)
	if (pObject ~= nil) then
		SceneObject(pObject):destroyObjectFromWorld()
		SceneObject(pObject):destroyObjectFromDatabase()
	end
end

function HeavyOrdinanceTrial:destroyTrackedObjectById(_, eventData)
	local objectId = tonumber(eventData) or 0
	if (objectId <= 0) then
		return 0
	end

	self:destroySceneObjectById(objectId)
	return 0
end

function HeavyOrdinanceTrial:cleanupEncounterForOwner(ownerId)
	if (ownerId == nil or ownerId <= 0) then
		return
	end

	for index = 1, self.MAX_TRACKED_MOBS, 1 do
		self:destroySceneObjectById(self:getDataNumber(self:getEncounterKey(ownerId, "mob_" .. tostring(index)), 0))
	end

	for index = 1, self.MAX_TRACKED_OBJECTS, 1 do
		self:destroySceneObjectById(self:getDataNumber(self:getEncounterKey(ownerId, "obj_" .. tostring(index)), 0))
	end

	self:destroySceneObjectById(self:getDataNumber(self:getEncounterKey(ownerId, "area_id"), 0))
	self:clearEncounterTracking(ownerId)
end

function HeavyOrdinanceTrial:getEncounterCenterDistance(pPlayer)
	local encounter = self:getEncounterData(pPlayer)
	if (encounter == nil) then
		return 999999
	end

	local px = SceneObject(pPlayer):getWorldPositionX()
	local py = SceneObject(pPlayer):getWorldPositionY()
	local dx = px - encounter.x
	local dy = py - encounter.y
	return math.sqrt(dx * dx + dy * dy)
end

function HeavyOrdinanceTrial:isSameEncounterVictim(pVictim, ownerId)
	if (pVictim == nil) then
		return false
	end

	return tonumber(readData(SceneObject(pVictim):getObjectID() .. ":hot_owner")) == ownerId
end

function HeavyOrdinanceTrial:chooseRandomEncounterIndex()
	return getRandomNumber(1, #self.ENCOUNTERS)
end

function HeavyOrdinanceTrial:chooseRandomPirateTemplate()
	return self.PIRATE_TEMPLATES[getRandomNumber(1, #self.PIRATE_TEMPLATES)]
end

function HeavyOrdinanceTrial:registerTrackedMobile(ownerId, pMobile)
	if (pMobile == nil) then
		return
	end

	local countKey = self:getEncounterKey(ownerId, "mob_count")
	local count = self:getDataNumber(countKey, 0) + 1
	if (count > self.MAX_TRACKED_MOBS) then
		return
	end

	self:setDataNumber(countKey, count)
	self:setDataNumber(self:getEncounterKey(ownerId, "mob_" .. tostring(count)), SceneObject(pMobile):getObjectID())
end

function HeavyOrdinanceTrial:registerTrackedObject(ownerId, pObject)
	if (pObject == nil) then
		return
	end

	local countKey = self:getEncounterKey(ownerId, "deco_count")
	local count = self:getDataNumber(countKey, 0) + 1
	if (count > self.MAX_TRACKED_OBJECTS) then
		return
	end

	self:setDataNumber(countKey, count)
	self:setDataNumber(self:getEncounterKey(ownerId, "obj_" .. tostring(count)), SceneObject(pObject):getObjectID())
end

function HeavyOrdinanceTrial:spawnDecorations(ownerId, encounter)
	for index = 1, #encounter.deco, 1 do
		local deco = encounter.deco[index]
		local decoZ = self:getTerrainZ(encounter.planet, deco.x, deco.y, deco.z)
		local pObject = spawnSceneObject(encounter.planet, deco.template, deco.x, decoZ, deco.y, 0, math.rad(deco.heading or 0))
		if (pObject ~= nil) then
			self:registerTrackedObject(ownerId, pObject)
		end
	end
end

function HeavyOrdinanceTrial:spawnBattleArea(ownerId, encounter)
	local centerZ = self:getTerrainZ(encounter.planet, encounter.x, encounter.y, encounter.z)
	local pArea = spawnActiveArea(encounter.planet, "object/active_area.iff", encounter.x, centerZ, encounter.y, self.COMBAT_RADIUS, 0)
	if (pArea ~= nil) then
		self:setDataNumber(self:getEncounterKey(ownerId, "area_id"), SceneObject(pArea):getObjectID())
	end
end

function HeavyOrdinanceTrial:tagEncounterObject(pObject, ownerId, objectType, index)
	if (pObject == nil) then
		return
	end

	local objectId = SceneObject(pObject):getObjectID()
	writeData(objectId .. ":hot_owner", ownerId)
	writeStringData(objectId .. ":hot_type", objectType)
	writeData(objectId .. ":hot_index", index or 0)
	writeData(objectId .. ":hot_valid_hits", 0)
	writeData(objectId .. ":hot_contrib_count", 0)
	writeData(objectId .. ":hot_awarded", 0)
end

function HeavyOrdinanceTrial:getEncounterContributorKey(objectId, index)
	return tostring(objectId) .. ":hot_contrib_" .. tostring(index)
end

function HeavyOrdinanceTrial:markEncounterContributor(objectId, playerId)
	if (objectId == nil or objectId <= 0 or playerId == nil or playerId <= 0) then
		return
	end

	local countKey = tostring(objectId) .. ":hot_contrib_count"
	local currentCount = tonumber(readData(countKey)) or 0

	for index = 1, currentCount, 1 do
		if ((tonumber(readData(self:getEncounterContributorKey(objectId, index))) or 0) == playerId) then
			return
		end
	end

	currentCount = currentCount + 1
	writeData(countKey, currentCount)
	writeData(self:getEncounterContributorKey(objectId, currentCount), playerId)
end

function HeavyOrdinanceTrial:getEncounterContributors(objectId)
	local contributors = {}
	local count = tonumber(readData(tostring(objectId) .. ":hot_contrib_count")) or 0

	for index = 1, count, 1 do
		local playerId = tonumber(readData(self:getEncounterContributorKey(objectId, index))) or 0
		if (playerId > 0) then
			table.insert(contributors, playerId)
		end
	end

	return contributors
end

function HeavyOrdinanceTrial:clearEncounterObjectData(objectId)
	if (objectId == nil or objectId <= 0) then
		return
	end

	local count = tonumber(readData(tostring(objectId) .. ":hot_contrib_count")) or 0
	for index = 1, count, 1 do
		self:deleteDataKey(self:getEncounterContributorKey(objectId, index))
	end

	self:deleteDataKey(tostring(objectId) .. ":hot_owner")
	self:deleteDataKey(tostring(objectId) .. ":hot_type")
	self:deleteDataKey(tostring(objectId) .. ":hot_index")
	self:deleteDataKey(tostring(objectId) .. ":hot_valid_hits")
	self:deleteDataKey(tostring(objectId) .. ":hot_contrib_count")
	self:deleteDataKey(tostring(objectId) .. ":hot_awarded")
end

function HeavyOrdinanceTrial:spawnStructureSet(pOwner)
	local ownerId = self:getPlayerId(pOwner)
	local encounter = self:getEncounterData(pOwner)
	if (encounter == nil) then
		return
	end

	local spawnedCountKey = self:getEncounterKey(ownerId, "structures_spawned")
	local liveCountKey = self:getEncounterKey(ownerId, "structures_live")
	local alreadySpawned = self:getDataNumber(spawnedCountKey, 0)
	local remaining = math.max(0, self.STRUCTURE_TARGET - self:getNumber(pOwner, "structure_count") - self:getDataNumber(liveCountKey, 0))
	local toSpawn = math.min(self.STRUCTURE_WAVE_SIZE, remaining, #encounter.structures - alreadySpawned)

	if (toSpawn <= 0) then
		return
	end

	local spawned = 0

	for offset = 1, toSpawn, 1 do
		local index = alreadySpawned + offset
		local cfg = encounter.structures[index]
		local structureZ = self:getStableSpawnZ(encounter.planet, cfg.x, cfg.y, cfg.z)
		local pStructure = spawnMobile(encounter.planet, cfg.template, 0, cfg.x, structureZ, cfg.y, cfg.heading or 0, 0)
		if (pStructure ~= nil) then
			SceneObject(pStructure):setCustomObjectName(cfg.name)
			self:tagEncounterObject(pStructure, ownerId, "structure", index)
			self:registerTrackedMobile(ownerId, pStructure)
			createObserver(OBJECTDESTRUCTION, self.screenplayName, "notifyEncounterObjectDestroyed", pStructure)
			createObserver(DAMAGERECEIVED, self.screenplayName, "notifyEncounterObjectDamaged", pStructure)
			self:setDataNumber(liveCountKey, self:getDataNumber(liveCountKey, 0) + 1)
			spawned = spawned + 1
		end
	end

	self:setDataNumber(spawnedCountKey, alreadySpawned + spawned)
	self:setDataNumber(self:getEncounterKey(ownerId, "next_structure_wave_pending"), 0)
end

function HeavyOrdinanceTrial:spawnPirateWave(pOwner, count)
	local ownerId = self:getPlayerId(pOwner)
	local encounter = self:getEncounterData(pOwner)
	if (encounter == nil) then
		return 0
	end

	local liveCountKey = self:getEncounterKey(ownerId, "pirates_live")
	local spawnedCountKey = self:getEncounterKey(ownerId, "pirates_spawned")
	local spawned = 0

	for index = 1, count, 1 do
		local point = encounter.pirateSpawn[getRandomNumber(1, #encounter.pirateSpawn)]
		local template = self:chooseRandomPirateTemplate()
		local spawnX = point.x + getRandomNumber(-6, 6)
		local spawnY = point.y + getRandomNumber(-6, 6)
		local spawnZ = self:getStableSpawnZ(encounter.planet, spawnX, spawnY, point.z)
		local pMobile = spawnMobile(encounter.planet, template, 0, spawnX, spawnZ, spawnY, point.heading or 0, 0)
		if (pMobile ~= nil) then
			self:tagEncounterObject(pMobile, ownerId, "pirate", index)
			self:registerTrackedMobile(ownerId, pMobile)
			createObserver(OBJECTDESTRUCTION, self.screenplayName, "notifyEncounterObjectDestroyed", pMobile)
			createObserver(DAMAGERECEIVED, self.screenplayName, "notifyEncounterObjectDamaged", pMobile)
			spawned = spawned + 1
			self:setDataNumber(liveCountKey, self:getDataNumber(liveCountKey, 0) + 1)
		end
	end

	if (spawned > 0) then
		self:setDataNumber(spawnedCountKey, self:getDataNumber(spawnedCountKey, 0) + spawned)
	end
	self:setDataNumber(self:getEncounterKey(ownerId, "next_pirate_wave_pending"), 0)

	return spawned
end

function HeavyOrdinanceTrial:spawnCurrentStructureWave(pOwner)
	if (pOwner == nil) then
		return
	end

	self:spawnStructureSet(pOwner)
end

function HeavyOrdinanceTrial:spawnCurrentPirateWave(pOwner)
	if (pOwner == nil) then
		return
	end

	local ownerId = self:getPlayerId(pOwner)
	local remaining = math.max(0, self.PIRATE_TARGET - self:getNumber(pOwner, "pirate_count") - self:getDataNumber(self:getEncounterKey(ownerId, "pirates_live"), 0))
	local toSpawn = math.min(self.PIRATE_WAVE_SIZE, remaining)

	if (toSpawn > 0) then
		self:spawnPirateWave(pOwner, toSpawn)
	end
end

function HeavyOrdinanceTrial:scheduleNextStructureWave(pOwner)
	if (pOwner == nil) then
		return
	end

	local ownerId = self:getPlayerId(pOwner)
	local pendingKey = self:getEncounterKey(ownerId, "next_structure_wave_pending")

	if (self:getDataNumber(pendingKey, 0) == 1) then
		return
	end

	self:setDataNumber(pendingKey, 1)
	createEvent(self.NEXT_WAVE_DELAY_MS, self.screenplayName, "startNextStructureWave", pOwner, tostring(ownerId))
end

function HeavyOrdinanceTrial:scheduleNextPirateWave(pOwner)
	if (pOwner == nil) then
		return
	end

	local ownerId = self:getPlayerId(pOwner)
	local pendingKey = self:getEncounterKey(ownerId, "next_pirate_wave_pending")

	if (self:getDataNumber(pendingKey, 0) == 1) then
		return
	end

	self:setDataNumber(pendingKey, 1)
	createEvent(self.NEXT_WAVE_DELAY_MS, self.screenplayName, "startNextPirateWave", pOwner, tostring(ownerId))
end

function HeavyOrdinanceTrial:startNextStructureWave(pOwner, eventData)
	if (pOwner == nil or not self:isOwner(pOwner) or not self:isActive(pOwner)) then
		return 0
	end

	local ownerId = tonumber(eventData) or 0
	if (ownerId ~= self:getPlayerId(pOwner)) then
		return 0
	end

	self:setDataNumber(self:getEncounterKey(ownerId, "next_structure_wave_pending"), 0)

	if (self:getString(pOwner, "phase") ~= "structures") then
		return 0
	end

	if (self:getDataNumber(self:getEncounterKey(ownerId, "structures_live"), 0) > 0) then
		return 0
	end

	self:spawnCurrentStructureWave(pOwner)
	return 0
end

function HeavyOrdinanceTrial:startNextPirateWave(pOwner, eventData)
	if (pOwner == nil or not self:isOwner(pOwner) or not self:isActive(pOwner)) then
		return 0
	end

	local ownerId = tonumber(eventData) or 0
	if (ownerId ~= self:getPlayerId(pOwner)) then
		return 0
	end

	self:setDataNumber(self:getEncounterKey(ownerId, "next_pirate_wave_pending"), 0)

	if (self:getString(pOwner, "phase") ~= "pirates") then
		return 0
	end

	if (self:getDataNumber(self:getEncounterKey(ownerId, "pirates_live"), 0) > 0) then
		return 0
	end

	self:spawnCurrentPirateWave(pOwner)
	return 0
end

function HeavyOrdinanceTrial:spawnBoss(pOwner)
	local ownerId = self:getPlayerId(pOwner)
	local encounter = self:getEncounterData(pOwner)
	if (encounter == nil) then
		return nil
	end

	if (self:getDataNumber(self:getEncounterKey(ownerId, "boss_id"), 0) > 0) then
		local pExisting = getSceneObject(self:getDataNumber(self:getEncounterKey(ownerId, "boss_id"), 0))
		if (pExisting ~= nil) then
			return pExisting
		end
	end

	local bossZ = self:getStableSpawnZ(encounter.planet, encounter.boss.x, encounter.boss.y, encounter.boss.z)
	local pBoss = spawnMobile(encounter.planet, "hot_pirate_kragg_siegebreaker", 0, encounter.boss.x, bossZ, encounter.boss.y, encounter.boss.heading or 0, 0)
	if (pBoss == nil) then
		return nil
	end

	self:tagEncounterObject(pBoss, ownerId, "boss", 1)
	self:registerTrackedMobile(ownerId, pBoss)
	self:setDataNumber(self:getEncounterKey(ownerId, "boss_id"), SceneObject(pBoss):getObjectID())
	createObserver(OBJECTDESTRUCTION, self.screenplayName, "notifyEncounterObjectDestroyed", pBoss)
	createObserver(DAMAGERECEIVED, self.screenplayName, "notifyEncounterObjectDamaged", pBoss)
	return pBoss
end

function HeavyOrdinanceTrial:syncParticipantPhase(pOwner, phase)
	local participants = self:getOwnerParticipants(pOwner)
	for index = 1, #participants, 1 do
		local pParticipant = participants[index]
		self:setString(pParticipant, "phase", phase)
		self:updateWaypoint(pParticipant)
	end
end

function HeavyOrdinanceTrial:ensureEncounterForOwner(pOwner)
	if (pOwner == nil or not self:isOwner(pOwner) or not self:isActive(pOwner)) then
		return
	end

	local ownerId = self:getPlayerId(pOwner)
	local encounter = self:getEncounterData(pOwner)
	if (encounter == nil) then
		return
	end

	local areaId = self:getDataNumber(self:getEncounterKey(ownerId, "area_id"), 0)
	if (areaId <= 0 or getSceneObject(areaId) == nil) then
		self:cleanupEncounterForOwner(ownerId)
		self:setDataNumber(self:getEncounterKey(ownerId, "started_at"), self:getNow())
		self:spawnDecorations(ownerId, encounter)
		self:spawnBattleArea(ownerId, encounter)
		local phase = self:getString(pOwner, "phase")
		if (phase == "" or phase == "structures") then
			self:setDataNumber(self:getEncounterKey(ownerId, "structures_spawned"), self:getNumber(pOwner, "structure_count"))
			self:spawnCurrentStructureWave(pOwner)
		elseif (phase == "pirates") then
			self:spawnCurrentPirateWave(pOwner)
		elseif (phase == "boss") then
			self:spawnBoss(pOwner)
		end
	end
end

function HeavyOrdinanceTrial:startAssignmentFromNpc(pPlayer)
	if (not self:isEligibleCommando(pPlayer)) then
		return false, "You are not on the Commando heavy assault roster."
	end

	if (self:isRewardPending(pPlayer)) then
		return false, "Your operation is complete. Process your debrief before requesting another deployment."
	end

	if (self:isActive(pPlayer)) then
		self:ensureEncounterForOwner(self:isOwner(pPlayer) and pPlayer or getSceneObject(self:getOwnerId(pPlayer)))
		self:updateWaypoint(pPlayer)
		return false, "You already have a live assault package. Stay on task."
	end

	if (self:isOnCooldown(pPlayer)) then
		return false, self:getCooldownText(pPlayer)
	end

	local eligible = self:getStartEligibleMembers(pPlayer)
	if (#eligible <= 0) then
		return false, "No eligible Commandos are in position. Group members must be nearby, off cooldown, and free of another active siege."
	end

	local encounterIndex = self:chooseRandomEncounterIndex()
	local ownerId = self:getPlayerId(pPlayer)

	for index = 1, #eligible, 1 do
		local pMember = eligible[index]
		self:setNumber(pMember, "active", 1)
		self:setNumber(pMember, "reward_pending", 0)
		self:setNumber(pMember, "encounter_index", encounterIndex)
		self:setNumber(pMember, "owner_id", ownerId)
		self:setNumber(pMember, "structure_count", 0)
		self:setNumber(pMember, "pirate_count", 0)
		self:setNumber(pMember, "valid_kills", 0)
		self:setNumber(pMember, "structure_contrib", 0)
		self:setNumber(pMember, "boss_contrib", 0)
		self:setNumber(pMember, "reward_eligible", 0)
		self:setNumber(pMember, "leave_started_at", 0)
		self:setString(pMember, "phase", "structures")
		self:updateWaypoint(pMember)
		self:refreshObservers(pMember)
		CreatureObject(pMember):sendSystemMessage("Captain Durn Valek has assigned you to the Heavy Ordinance Trial.")
	end

	self:cleanupEncounterForOwner(ownerId)
	self:ensureEncounterForOwner(pPlayer)
	self:scheduleOperationCheck(pPlayer)
	return true, "Deployment approved. Move on the pirate encampment, break the emplacements, then level everything that remains."
end

function HeavyOrdinanceTrial:abortAssignment(pPlayer)
	if (not self:isActive(pPlayer)) then
		return false, "You have no active siege operation to stand down."
	end

	local ownerId = self:getOwnerId(pPlayer)
	local pOwner = getSceneObject(ownerId)

	if (pOwner == nil) then
		pOwner = pPlayer
	end

	local participants = self:getOwnerParticipants(pOwner)
	for index = 1, #participants, 1 do
		local pParticipant = participants[index]
		self:clearPlayerState(pParticipant, false)
		CreatureObject(pParticipant):sendSystemMessage("Heavy Ordinance Trial aborted.")
	end

	self:cleanupEncounterForOwner(ownerId)
	return true, "Operation stood down. The battlefield has been scrubbed."
end

function HeavyOrdinanceTrial:failOperation(ownerId, message)
	if (ownerId == nil or ownerId <= 0) then
		return
	end

	local pOwner = getSceneObject(ownerId)
	if (pOwner == nil) then
		return
	end

	local participants = self:getOwnerParticipants(pOwner)
	for index = 1, #participants, 1 do
		local pParticipant = participants[index]
		self:clearPlayerState(pParticipant, false)
		if (message ~= nil and message ~= "") then
			CreatureObject(pParticipant):sendSystemMessage(message)
		end
	end

	self:cleanupEncounterForOwner(ownerId)
end

function HeavyOrdinanceTrial:advanceStructureProgress(ownerId)
	local pOwner = getSceneObject(ownerId)
	if (pOwner == nil) then
		return
	end

	local participants = self:getOwnerParticipants(pOwner)
	local completed = 0

	for index = 1, #participants, 1 do
		local pParticipant = participants[index]
		local total = math.min(self.STRUCTURE_TARGET, self:getNumber(pParticipant, "structure_count") + 1)
		self:setNumber(pParticipant, "structure_count", total)
		completed = total
		CreatureObject(pParticipant):sendSystemMessage("Emplacement destroyed. Objective progress: " .. tostring(total) .. "/" .. tostring(self.STRUCTURE_TARGET) .. ".")
	end

	if (completed >= self.STRUCTURE_TARGET) then
		local pirateProgress = self:getNumber(pOwner, "pirate_count")
		if (pirateProgress >= self.PIRATE_TARGET) then
			self:syncParticipantPhase(pOwner, "boss")
			self:spawnBoss(pOwner)
			for index = 1, #participants, 1 do
				CreatureObject(participants[index]):sendSystemMessage("Kragg the Siegebreaker is on the field. Finish the assault.")
			end
		else
			self:syncParticipantPhase(pOwner, "pirates")
			self:spawnCurrentPirateWave(pOwner)
		end
	else
		if (self:getDataNumber(self:getEncounterKey(ownerId, "structures_live"), 0) <= 0) then
			self:scheduleNextStructureWave(pOwner)
		end
	end
end

function HeavyOrdinanceTrial:advancePirateProgress(pOwner)
	local ownerId = self:getPlayerId(pOwner)
	local participants = self:getOwnerParticipants(pOwner)
	local maxProgress = 0

	for index = 1, #participants, 1 do
		local pParticipant = participants[index]
		local total = math.min(self.PIRATE_TARGET, self:getNumber(pParticipant, "pirate_count") + 1)
		self:setNumber(pParticipant, "pirate_count", total)
		if (total > maxProgress) then
			maxProgress = total
		end
		CreatureObject(pParticipant):sendSystemMessage("Pirate neutralized with heavy ordinance. Objective progress: " .. tostring(total) .. "/" .. tostring(self.PIRATE_TARGET) .. ".")
	end

	if (maxProgress >= self.PIRATE_TARGET) then
		self:syncParticipantPhase(pOwner, "boss")
		self:spawnBoss(pOwner)
		for index = 1, #participants, 1 do
			CreatureObject(participants[index]):sendSystemMessage("Kragg the Siegebreaker is on the field. Finish the assault.")
		end
	elseif (self:getDataNumber(self:getEncounterKey(ownerId, "pirates_live"), 0) <= 0) then
		self:scheduleNextPirateWave(pOwner)
	end
end

function HeavyOrdinanceTrial:markPlayerContribution(pPlayer, contributionType)
	if (pPlayer == nil) then
		return
	end

	if (contributionType == "structure") then
		self:setNumber(pPlayer, "structure_contrib", self:getNumber(pPlayer, "structure_contrib") + 1)
	elseif (contributionType == "boss") then
		self:setNumber(pPlayer, "boss_contrib", 1)
	elseif (contributionType == "kill") then
		self:setNumber(pPlayer, "valid_kills", self:getNumber(pPlayer, "valid_kills") + 1)
	end
end

function HeavyOrdinanceTrial:getEligibleRewardPlayersFromOwner(pOwner, pBoss)
	local eligible = {}
	local participants = self:getOwnerParticipants(pOwner)

	for index = 1, #participants, 1 do
		local pParticipant = participants[index]
		local hasFieldContribution = self:getNumber(pParticipant, "valid_kills") > 0 or self:getNumber(pParticipant, "structure_contrib") > 0
		local hasBossContribution = self:getNumber(pParticipant, "boss_contrib") == 1
		if (hasFieldContribution and hasBossContribution and SceneObject(pParticipant):isInRangeWithObject(pBoss, self.REWARD_RADIUS)) then
			table.insert(eligible, pParticipant)
		end
	end

	return eligible
end

function HeavyOrdinanceTrial:isValidHeavyKillCredit(pKiller, ownerId)
	return self:isValidPlayer(pKiller)
		and self:isActive(pKiller)
		and self:getOwnerId(pKiller) == ownerId
		and self:isValidHeavyWeaponUser(pKiller)
end

function HeavyOrdinanceTrial:hasEncounterKillBeenAwarded(victimId)
	return tonumber(readData(tostring(victimId) .. ":hot_awarded")) == 1
end

function HeavyOrdinanceTrial:markEncounterKillAwarded(victimId)
	writeData(tostring(victimId) .. ":hot_awarded", 1)
end

function HeavyOrdinanceTrial:sendDebugHitMessage(pAttacker, objectType)
	if (self.DEBUG_HIT_MESSAGES ~= true or pAttacker == nil or objectType == nil or objectType == "") then
		return
	end

	local label = objectType
	if (objectType == "structure") then
		label = "emplacement"
	elseif (objectType == "pirate") then
		label = "pirate"
	elseif (objectType == "boss") then
		label = "Kragg"
	end

	CreatureObject(pAttacker):sendSystemMessage("Heavy Ordinance Trial registered a valid hit on " .. label .. ".")
end

function HeavyOrdinanceTrial:awardPirateKillCredit(ownerId, victimId, pKiller)
	if (ownerId <= 0 or victimId == nil or victimId <= 0 or self:hasEncounterKillBeenAwarded(victimId)) then
		return false
	end

	local pOwner = getSceneObject(ownerId)
	if (pOwner == nil) then
		return false
	end

	local contributors = self:getEncounterContributors(victimId)
	if (#contributors <= 0 and self:isValidHeavyKillCredit(pKiller, ownerId)) then
		contributors = { self:getPlayerId(pKiller) }
	end

	for index = 1, #contributors, 1 do
		local pContributor = getSceneObject(contributors[index])
		if (self:isValidPlayer(pContributor) and self:isActive(pContributor) and self:getOwnerId(pContributor) == ownerId) then
			self:markPlayerContribution(pContributor, "kill")
		end
	end

	self:setDataNumber(self:getEncounterKey(ownerId, "pirates_live"), math.max(0, self:getDataNumber(self:getEncounterKey(ownerId, "pirates_live"), 0) - 1))
	self:markEncounterKillAwarded(victimId)
	self:advancePirateProgress(pOwner)
	return true
end

function HeavyOrdinanceTrial:awardStructureKillCredit(ownerId, victimId, pVictim)
	if (ownerId <= 0 or victimId == nil or victimId <= 0 or pVictim == nil or self:hasEncounterKillBeenAwarded(victimId)) then
		return false
	end

	local pOwner = getSceneObject(ownerId)
	if (pOwner == nil) then
		return false
	end

	self:setDataNumber(self:getEncounterKey(ownerId, "structures_live"), math.max(0, self:getDataNumber(self:getEncounterKey(ownerId, "structures_live"), 0) - 1))
	self:advanceStructureProgress(ownerId)

	local encounter = self:getEncounterData(pOwner)
	if (encounter ~= nil) then
		local fxZ = self:getTerrainZ(encounter.planet, SceneObject(pVictim):getWorldPositionX(), SceneObject(pVictim):getWorldPositionY(), encounter.z)
		local pFx = spawnSceneObject(encounter.planet, "object/static/particle/particle_lg_explosion.iff", SceneObject(pVictim):getWorldPositionX(), fxZ, SceneObject(pVictim):getWorldPositionY(), 0, 0)
		if (pFx ~= nil) then
			createEvent(10000, self.screenplayName, "destroyTemporaryObject", pFx, "")
		end
	end

	self:markEncounterKillAwarded(victimId)

	-- These emplacements should not leave a corpse/debris mobile behind once destroyed.
	pcall(function()
		SceneObject(pVictim):destroyObjectFromWorld()
	end)
	pcall(function()
		SceneObject(pVictim):destroyObjectFromDatabase()
	end)

	-- Fallback cleanup by object id in case the direct removal races the destruction pipeline.
	createEvent(250, self.screenplayName, "destroyTrackedObjectById", nil, tostring(victimId))
	return true
end

function HeavyOrdinanceTrial:awardBossKillCredit(ownerId, victimId, pVictim)
	if (ownerId <= 0 or victimId == nil or victimId <= 0 or pVictim == nil or self:hasEncounterKillBeenAwarded(victimId)) then
		return false
	end

	local pOwner = getSceneObject(ownerId)
	if (pOwner == nil) then
		return false
	end

	local eligible = self:getEligibleRewardPlayersFromOwner(pOwner, pVictim)
	local participants = self:getOwnerParticipants(pOwner)

	for index = 1, #participants, 1 do
		local pParticipant = participants[index]
		self:setNumber(pParticipant, "reward_pending", 0)
		self:setNumber(pParticipant, "reward_eligible", 0)
		self:setString(pParticipant, "phase", "complete")
	end

	for index = 1, #eligible, 1 do
		local pParticipant = eligible[index]
		self:setNumber(pParticipant, "reward_pending", 1)
		self:setNumber(pParticipant, "reward_eligible", 1)
		self:updateWaypoint(pParticipant)
		CreatureObject(pParticipant):sendSystemMessage("Kragg is down. Return to Captain Durn Valek for debrief.")
	end

	for index = 1, #participants, 1 do
		local pParticipant = participants[index]
		if (self:getNumber(pParticipant, "reward_pending") ~= 1) then
			CreatureObject(pParticipant):sendSystemMessage("You were outside the debrief envelope or did not contribute enough valid heavy damage. No reward authorization was logged.")
			self:clearPlayerState(pParticipant, false)
		end
	end

	self:markEncounterKillAwarded(victimId)
	self:cleanupEncounterForOwner(ownerId)
	return true
end

function HeavyOrdinanceTrial:notifyEncounterObjectDamaged(pVictim, pAttacker, damage)
	if (pVictim == nil or pAttacker == nil) then
		return 0
	end

	local ownerId = tonumber(readData(SceneObject(pVictim):getObjectID() .. ":hot_owner")) or 0
	if (ownerId <= 0 or not self:isValidPlayer(pAttacker) or not self:isActive(pAttacker) or self:getOwnerId(pAttacker) ~= ownerId) then
		return 0
	end

	if (not self:isValidHeavyWeaponUser(pAttacker)) then
		return 0
	end

	local victimId = SceneObject(pVictim):getObjectID()
	local hitCountKey = victimId .. ":hot_valid_hits"
	local objectType = tostring(readStringData(victimId .. ":hot_type") or "")
	local currentHits = tonumber(readData(hitCountKey)) or 0

	if (objectType == "structure") then
		writeData(hitCountKey, currentHits + 1)
		self:markEncounterContributor(victimId, self:getPlayerId(pAttacker))
		self:markPlayerContribution(pAttacker, "structure")
	elseif (objectType == "pirate") then
		writeData(hitCountKey, currentHits + 1)
		self:markEncounterContributor(victimId, self:getPlayerId(pAttacker))
	elseif (objectType == "boss") then
		writeData(hitCountKey, currentHits + 1)
		self:markEncounterContributor(victimId, self:getPlayerId(pAttacker))
		self:markPlayerContribution(pAttacker, "boss")

		local pOwner = getSceneObject(ownerId)
		if (pOwner ~= nil) then
			local healthPct = CreatureObject(pVictim):getHAM(HEALTH) / CreatureObject(pVictim):getMaxHAM(HEALTH)
			if (healthPct <= 0.70 and self:getDataNumber(self:getEncounterKey(ownerId, "boss70"), 0) == 0) then
				self:setDataNumber(self:getEncounterKey(ownerId, "boss70"), 1)
			elseif (healthPct <= 0.40 and self:getDataNumber(self:getEncounterKey(ownerId, "boss40"), 0) == 0) then
				self:setDataNumber(self:getEncounterKey(ownerId, "boss40"), 1)
			elseif (healthPct <= 0.20 and self:getDataNumber(self:getEncounterKey(ownerId, "boss20"), 0) == 0) then
				self:setDataNumber(self:getEncounterKey(ownerId, "boss20"), 1)
			end
		end
	end

	if (currentHits == 0) then
		self:sendDebugHitMessage(pAttacker, objectType)
	end

	return 0
end

function HeavyOrdinanceTrial:notifyEncounterObjectDestroyed(pVictim, pKiller)
	if (pVictim == nil) then
		return 0
	end

	local victimId = SceneObject(pVictim):getObjectID()
	local ownerId = tonumber(readData(victimId .. ":hot_owner")) or 0
	local objectType = tostring(readStringData(victimId .. ":hot_type") or "")
	local validHits = tonumber(readData(victimId .. ":hot_valid_hits")) or 0
	local validKillCredit = validHits > 0 or self:isValidHeavyKillCredit(pKiller, ownerId)

	if (ownerId <= 0) then
		self:clearEncounterObjectData(victimId)
		return 0
	end

	if (objectType == "structure" and validKillCredit) then
		self:awardStructureKillCredit(ownerId, victimId, pVictim)
	elseif (objectType == "pirate" and validKillCredit) then
		self:awardPirateKillCredit(ownerId, victimId, pKiller)
	elseif (objectType == "boss" and validKillCredit) then
		self:awardBossKillCredit(ownerId, victimId, pVictim)
	end

	if ((objectType == "structure" or objectType == "pirate") and not self:hasEncounterKillBeenAwarded(victimId)) then
		createEvent(250, self.screenplayName, "destroyTrackedObjectById", nil, tostring(victimId))
	end

	self:clearEncounterObjectData(victimId)

	return 0
end

function HeavyOrdinanceTrial:destroyTemporaryObject(pObject)
	if (pObject ~= nil) then
		SceneObject(pObject):destroyObjectFromWorld()
		SceneObject(pObject):destroyObjectFromDatabase()
	end

	return 0
end

function HeavyOrdinanceTrial:notifyKilledCreature(pPlayer, pVictim)
	if (pPlayer == nil or pVictim == nil or not self:isActive(pPlayer)) then
		return 0
	end

	local ownerId = self:getOwnerId(pPlayer)
	if (not self:isSameEncounterVictim(pVictim, ownerId)) then
		return 0
	end

	local victimId = SceneObject(pVictim):getObjectID()
	local objectType = tostring(readStringData(victimId .. ":hot_type") or "")

	if (objectType ~= "structure" and objectType ~= "pirate" and objectType ~= "boss") then
		return 0
	end

	if (not self:isValidHeavyWeaponUser(pPlayer)) then
		self:markLastInvalidMethodMessage(pPlayer)
		return 0
	end

	if (objectType == "structure") then
		self:awardStructureKillCredit(ownerId, victimId, pVictim)
	elseif (objectType == "pirate") then
		self:awardPirateKillCredit(ownerId, victimId, pPlayer)
	elseif (objectType == "boss") then
		self:awardBossKillCredit(ownerId, victimId, pVictim)
	end

	return 0
end

function HeavyOrdinanceTrial:onLoggedIn(pPlayer)
	if (pPlayer == nil) then
		return 0
	end

	self:refreshObservers(pPlayer)
	self:updateWaypoint(pPlayer)

	if (self:isActive(pPlayer) and self:isOwner(pPlayer)) then
		self:ensureEncounterForOwner(pPlayer)
		self:scheduleOperationCheck(pPlayer)
	end

	return 0
end

function HeavyOrdinanceTrial:scheduleOperationCheck(pOwner)
	if (pOwner == nil or not self:isOwner(pOwner) or not self:isActive(pOwner)) then
		return
	end

	createEvent(30000, self.screenplayName, "operationCheckTick", pOwner, tostring(self:getPlayerId(pOwner)))
end

function HeavyOrdinanceTrial:operationCheckTick(pOwner, eventData)
	if (pOwner == nil or not self:isOwner(pOwner) or not self:isActive(pOwner)) then
		return 0
	end

	local ownerId = tonumber(eventData) or 0
	if (ownerId ~= self:getPlayerId(pOwner)) then
		return 0
	end

	local startedAt = self:getDataNumber(self:getEncounterKey(ownerId, "started_at"), 0)
	if (startedAt > 0 and (self:getNow() - startedAt) >= self.OPERATION_TIMEOUT_SECONDS) then
		self:failOperation(ownerId, "Heavy Ordinance Trial failed. Your siege window collapsed and the battlefield has been reset.")
		return 0
	end

	local participants = self:getOwnerParticipants(pOwner)
	local anyoneInZone = false
	local zoneEngaged = self:getDataNumber(self:getEncounterKey(ownerId, "zone_engaged"), 0) == 1
	local allExpired = (#participants > 0)

	for index = 1, #participants, 1 do
		local pParticipant = participants[index]
		local distance = self:getEncounterCenterDistance(pParticipant)
		if (distance <= self.COMBAT_RADIUS) then
			anyoneInZone = true
			zoneEngaged = true
			self:setNumber(pParticipant, "leave_started_at", 0)
		else
			local leaveAt = self:getNumber(pParticipant, "leave_started_at")
			if (leaveAt <= 0) then
				self:setNumber(pParticipant, "leave_started_at", self:getNow())
				if (zoneEngaged) then
					CreatureObject(pParticipant):sendSystemMessage("Return to the assault zone or command will scrub the operation.")
				end
			end

			if (leaveAt <= 0 or (self:getNow() - leaveAt) < self.LEAVE_FAIL_SECONDS) then
				allExpired = false
			end
		end
	end

	if (zoneEngaged) then
		self:setDataNumber(self:getEncounterKey(ownerId, "zone_engaged"), 1)
	end

	if (zoneEngaged ~= true) then
		self:ensureEncounterForOwner(pOwner)
		self:scheduleOperationCheck(pOwner)
		return 0
	end

	if (anyoneInZone ~= true and allExpired == true) then
		self:failOperation(ownerId, "Heavy Ordinance Trial failed. No assaulters remained in the combat area.")
		return 0
	end

	if (anyoneInZone ~= true and allExpired ~= true) then
		self:ensureEncounterForOwner(pOwner)
		self:scheduleOperationCheck(pOwner)
		return 0
	end

	self:ensureEncounterForOwner(pOwner)
	self:scheduleOperationCheck(pOwner)
	return 0
end

function HeavyOrdinanceTrial:canGrantRewardItems(pPlayer)
	local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil) then
		return false, "Your inventory could not be read. Try again."
	end

	if (SceneObject(pInventory):getContainerObjectsSize() >= 78) then
		return false, "Clear at least two inventory slots before I issue your battlefield package."
	end

	return true, ""
end

function HeavyOrdinanceTrial:getRewardData()
	local rewardIndex = getRandomNumber(1, #self.rewardStatPool)
	return self.rewardStatPool[rewardIndex]
end

function HeavyOrdinanceTrial:grantAttachmentReward(pInventory)
	local rewardData = self:getRewardData()
	local pReward = giveItem(pInventory, self.REWARD_ATTACHMENT_TEMPLATE, -1, true)

	if (pReward == nil) then
		return nil, nil
	end

	TangibleObject(pReward):addAttachmentSkillModBonus(rewardData.key, 25)
	SceneObject(pReward):setCustomObjectName("+25 " .. rewardData.display)

	return pReward, rewardData
end

function HeavyOrdinanceTrial:claimReward(pPlayer)
	if (not self:isEligibleCommando(pPlayer)) then
		return false, "You are not authorized for this debrief."
	end

	if (not self:isRewardPending(pPlayer) or self:getNumber(pPlayer, "reward_eligible") ~= 1) then
		if (self:isActive(pPlayer)) then
			return false, self:getProgressText(pPlayer, true)
		end
		return false, "No battlefield reward is ready for issue."
	end

	local canGrant, message = self:canGrantRewardItems(pPlayer)
	if (not canGrant) then
		return false, message
	end

	local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")
	local pHolocron = giveItem(pInventory, self.REWARD_HOLOCRON_TEMPLATE, -1, true)
	if (pHolocron == nil) then
		return false, "I could not place the Holocron of Destiny into your inventory. Clear space and report again."
	end

	SceneObject(pHolocron):setCustomObjectName("Holocron of Destiny")

	local pAttachment, rewardData = self:grantAttachmentReward(pInventory)
	if (pAttachment == nil or pAttachment == 0) then
		SceneObject(pHolocron):destroyObjectFromWorld()
		SceneObject(pHolocron):destroyObjectFromDatabase()
		return false, "The attachment requisition failed. Clear space and report again."
	end

	CreatureObject(pPlayer):addBankCredits(getRandomNumber(150000, 300000), true)
	self:setNumber(pPlayer, "cooldown_until", self:getNow() + self.COOLDOWN_SECONDS)
	self:clearPlayerState(pPlayer, true)
	return true, "Debrief complete. You are credited for the assault and issued one Holocron of Destiny plus one +25 " .. rewardData.display .. " attachment from Bellum Gero stock."
end
