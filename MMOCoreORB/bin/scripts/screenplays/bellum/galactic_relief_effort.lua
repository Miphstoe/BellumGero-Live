GalacticReliefEffort = ScreenPlay:new {
	screenplayName = "GalacticReliefEffort",
	numberOfActs = 1,
}

registerScreenPlay("GalacticReliefEffort", true)

GalacticReliefEffort.SCRIPT_NAMESPACE = "galactic_relief_effort"
GalacticReliefEffort.PATIENT_STATE_NAME = "galactic_relief_effort"
GalacticReliefEffort.PATIENT_STATE_VALID = 1

GalacticReliefEffort.NPC_TEMPLATE = "trainer_medic"
GalacticReliefEffort.NPC_NAME = "Relief Coordinator Teren Vahl"
GalacticReliefEffort.NPC_PLANET = "tatooine"
GalacticReliefEffort.NPC_X = 3490
GalacticReliefEffort.NPC_Z = 5
GalacticReliefEffort.NPC_Y = -4842
GalacticReliefEffort.NPC_HEADING = 95

GalacticReliefEffort.REWARD_CREDITS = 150000
GalacticReliefEffort.REWARD_ITEM_TEMPLATE = "object/tangible/loot/misc/holocron_of_destiny.iff"
GalacticReliefEffort.BONUS_REWARD_ITEM_TEMPLATE = "object/tangible/deed/vehicle_deed/doctor_buff_droid_deed.iff"
GalacticReliefEffort.COOLDOWN_SECONDS = 20 * 60 * 60
GalacticReliefEffort.ASSIGNED_CITIES_PER_RUN = 5
GalacticReliefEffort.PATIENTS_REQUIRED_PER_CITY = 5
GalacticReliefEffort.ACTIVE_PATIENT_POOL = 10
GalacticReliefEffort.SPAWN_POINT_SELECTIONS = 10
GalacticReliefEffort.MAX_SPAWN_POINTS = 12

GalacticReliefEffort.PATIENT_TEMPLATES = {
	"commoner",
	"commoner_old",
	"commoner_fat",
	"commoner_male",
	"medic",
	"scientist",
}

GalacticReliefEffort.PATIENT_RECOVERY_LINES = {
	"Thank you. The stars watch over you, medic.",
	"The pain has passed. I owe you my life.",
	"That bacta touch steadied me. Thank you.",
	"The relief teams were right to send you.",
	"I can stand again. May the Force guide you.",
}

GalacticReliefEffort.COORDINATOR_INTRO = "The war leaves wounds far from the front, medic. Our relief network has five active emergencies across the Mid and Outer Rim. Travel where I direct you, speak with each assigned civilian, choose the correct treatment, and return when the circuit is complete."

GalacticReliefEffort.cityPool = {
	{
		id = "moenia",
		displayName = "Moenia",
		planet = "naboo",
		waypointX = 4810,
		waypointY = -4703,
		spawnPoints = {
			{4795, 4, -4722, 45, 0},
			{4825, 4, -4679, 180, 0},
			{4852, 4, -4677, 255, 0},
			{4667.6, 3.8, -4785.3, -20, 0},
			{4667.9, 3.8, -4783.4, 170, 0},
			{4744, 3.8, -4847, 0, 0},
			{4825, 3.8, -4829, 235, 0},
			{4810, 4.2, -4627, 0, 0},
			{4721, 4.2, -4614, 180, 0},
			{4808, 4.17, -4724, 0, 0},
			{4772, 3.7, -4814, 164, 0},
			{4810.44, 4.17, -4663.38, 112, 0},
		},
	},
	{
		id = "theed",
		displayName = "Theed",
		planet = "naboo",
		waypointX = -4869,
		waypointY = 4153,
		spawnPoints = {
			{-4877, 6, 4154, 100, 0},
			{-4924, 6, 4034, 112, 0},
			{-4896, 6, 4167, 352, 0},
			{-5054, 6, 4228, 0, 0},
			{-5082.41, 6, 4261.15, 180, 0},
			{-5258.93, 6, 4187.17, 180, 0},
			{-5281.75, 6, 4325.98, 47, 0},
			{-5309.23, 6, 4307.01, 78, 0},
			{-5371.2, 6, 4337.4, 57, 0},
			{-4968.55, 6, 4158.78, 56, 0},
			{-4978.62, 6, 4119.77, 158, 0},
			{-4901.7, 6, 4197.5, 55, 0},
		},
	},
	{
		id = "tyrena",
		displayName = "Tyrena",
		planet = "corellia",
		waypointX = -5039,
		waypointY = -2295,
		spawnPoints = {
			{-5003, 21, -2342, 284, 0},
			{-4965, 21, -2383, 227, 0},
			{-5064, 21, -2392, 128, 0},
			{-5063, 21, -2482, 295, 0},
			{-5090, 21, -2580, 208, 0},
			{-5200, 21, -2594, 332, 0},
			{-5291, 21, -2479, 323, 0},
			{-5156, 21, -2376, 186, 0},
			{-5411, 21, -2655, 7, 0},
			{-5079.26, 21, -2445.52, 106, 0},
			{-5025.37, 21, -2453.92, 175, 0},
			{-5014.32, 21, -2560.74, 19, 0},
		},
	},
	{
		id = "mos_espa",
		displayName = "Mos Espa",
		planet = "tatooine",
		waypointX = -2911,
		waypointY = 2131,
		spawnPoints = {
			{-2905, 5, 2163, 180, 0},
			{-2952, 5, 2087, 46, 0},
			{-2914, 5, 1984, 26, 0},
			{-2754, 5, 1981, 94, 0},
			{-2715, 5, 2040, 144, 0},
			{-3046, 5, 2133, 249, 0},
			{-2954, 5, 2235, 232, 0},
			{-2914, 5, 2466, 163, 0},
			{-2770, 5, 2245, 214, 0},
			{-2918.94, 5, 2169.6, 0, 0},
			{-3019.69, 5, 2114.97, 73.4692, 0},
			{-2897.39, 5, 2323.06, 54.7434, 0},
		},
	},
	{
		id = "dearic",
		displayName = "Dearic",
		planet = "talus",
		waypointX = 341,
		waypointY = -2929,
		spawnPoints = {
			{319, 6, -3001, 222, 0},
			{397, 6, -2971, 265, 0},
			{363, 6, -3101, 116, 0},
			{315, 6, -3159, 102, 0},
			{410, 6, -3168, 248, 0},
			{414, 6, -3135, 92, 0},
			{443, 6, -3086, 280, 0},
			{481, 6, -2854, 110, 0},
			{394, 6, -2881, 326, 0},
			{445, 6, -2804, 34, 0},
			{330.621, 6, -2942.68, 46, 0},
			{420.006, 6, -2986.86, 200, 0},
		},
	},
	{
		id = "narmle",
		displayName = "Narmle",
		planet = "rori",
		waypointX = -5302,
		waypointY = -2226,
		spawnPoints = {
			{-5496.0, 80.0, -2168.2, 97, 0},
			{-5465.4, 80.0, -2104.6, 45, 0},
			{-5325.8, 80.0, -2103.1, -110, 0},
			{-5323.4, 80.1, -2231.5, 125, 0},
			{-5300.6, 80.1, -2209.6, 125, 0},
			{-5285.3, 80.0, -2260.8, 0, 0},
			{-5243.9, 80.7, -2169.4, -50, 0},
			{-5237.2, 80.7, -2123.4, 133, 0},
			{-5158.3, 80.0, -2252.5, 180, 0},
			{-5135.5, 80.0, -2307.7, 0, 0},
			{-5187.95, 80, -2224.44, 176, 0},
			{-4980.14, 80, -2284.88, -90, 0},
		},
	},
}

function GalacticReliefEffort:start()
	self:spawnCoordinator()
end

function GalacticReliefEffort:spawnCoordinator()
	local pNpc = spawnMobile(self.NPC_PLANET, self.NPC_TEMPLATE, 0, self.NPC_X, self.NPC_Z, self.NPC_Y, self.NPC_HEADING, 0)

	if (pNpc == nil) then
		return
	end

	CreatureObject(pNpc):setPvpStatusBitmask(0)
	CreatureObject(pNpc):setOptionsBitmask(AIENABLED + CONVERSABLE + INVULNERABLE)
	SceneObject(pNpc):setCustomObjectName(self.NPC_NAME)
	AiAgent(pNpc):setConvoTemplate("galacticReliefEffortConvoTemplate")
	AiAgent(pNpc):addObjectFlag(AI_STATIC)
end

function GalacticReliefEffort:getNow()
	return os.time()
end

function GalacticReliefEffort:getNumber(pPlayer, key)
	if (pPlayer == nil) then
		return 0
	end

	return tonumber(readScreenPlayData(pPlayer, self.SCRIPT_NAMESPACE, key)) or 0
end

function GalacticReliefEffort:setNumber(pPlayer, key, value)
	if (pPlayer == nil) then
		return
	end

	writeScreenPlayData(pPlayer, self.SCRIPT_NAMESPACE, key, value)
end

function GalacticReliefEffort:getString(pPlayer, key)
	if (pPlayer == nil) then
		return ""
	end

	return tostring(readScreenPlayData(pPlayer, self.SCRIPT_NAMESPACE, key) or "")
end

function GalacticReliefEffort:setString(pPlayer, key, value)
	if (pPlayer == nil) then
		return
	end

	writeScreenPlayData(pPlayer, self.SCRIPT_NAMESPACE, key, value)
end

function GalacticReliefEffort:deleteKey(pPlayer, key)
	if (pPlayer == nil) then
		return
	end

	deleteScreenPlayData(pPlayer, self.SCRIPT_NAMESPACE, key)
end

function GalacticReliefEffort:isEligibleMedic(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	local player = CreatureObject(pPlayer)
	return player:getSkillMod("healing_injury_treatment") > 0 and player:getSkillMod("healing_wound_treatment") > 0
end

function GalacticReliefEffort:isActive(pPlayer)
	return self:getNumber(pPlayer, "active") == 1
end

function GalacticReliefEffort:isRewardPending(pPlayer)
	return self:getNumber(pPlayer, "reward_pending") == 1
end

function GalacticReliefEffort:isRewardLocked(pPlayer)
	return self:getNumber(pPlayer, "reward_lock") == 1
end

function GalacticReliefEffort:hasClaimedBonusReward(pPlayer)
	return self:getNumber(pPlayer, "doctor_buff_droid_deed_claimed") == 1
end

function GalacticReliefEffort:shouldGrantBonusReward(pPlayer)
	return not self:hasClaimedBonusReward(pPlayer)
end

function GalacticReliefEffort:getCurrentCityIndex(pPlayer)
	local index = self:getNumber(pPlayer, "current_city_index")
	if (index < 1) then
		return 1
	end
	return index
end

function GalacticReliefEffort:getRemainingCooldown(pPlayer)
	local remaining = self:getNumber(pPlayer, "cooldown_until") - self:getNow()
	if (remaining < 0) then
		return 0
	end
	return remaining
end

function GalacticReliefEffort:isOnCooldown(pPlayer)
	return self:getRemainingCooldown(pPlayer) > 0
end

function GalacticReliefEffort:formatDurationWords(seconds)
	if (seconds <= 0) then
		return "0 minutes"
	end

	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local parts = {}

	if (hours > 0) then
		local hourWord = "hours"
		if (hours == 1) then
			hourWord = "hour"
		end
		table.insert(parts, tostring(hours) .. " " .. hourWord)
	end

	if (minutes > 0 or #parts == 0) then
		local minuteWord = "minutes"
		if (minutes == 1) then
			minuteWord = "minute"
		end
		table.insert(parts, tostring(minutes) .. " " .. minuteWord)
	end

	if (#parts == 1) then
		return parts[1]
	end

	return parts[1] .. " and " .. parts[2]
end

function GalacticReliefEffort:shuffleArray(source)
	local copy = {}

	for i = 1, #source, 1 do
		copy[i] = source[i]
	end

	for i = #copy, 2, -1 do
		local j = getRandomNumber(1, i)
		copy[i], copy[j] = copy[j], copy[i]
	end

	return copy
end

function GalacticReliefEffort:getCityById(cityId)
	for i = 1, #self.cityPool, 1 do
		if (self.cityPool[i].id == cityId) then
			return self.cityPool[i]
		end
	end

	return nil
end

function GalacticReliefEffort:getAssignedCityId(pPlayer, index)
	return self:getString(pPlayer, "city_" .. index .. "_id")
end

function GalacticReliefEffort:getAssignedCityData(pPlayer, index)
	return self:getCityById(self:getAssignedCityId(pPlayer, index))
end

function GalacticReliefEffort:getCurrentCityData(pPlayer)
	return self:getAssignedCityData(pPlayer, self:getCurrentCityIndex(pPlayer))
end

function GalacticReliefEffort:getCurrentCityName(pPlayer)
	local city = self:getCurrentCityData(pPlayer)
	if (city == nil) then
		return "Unknown"
	end
	return city.displayName
end

function GalacticReliefEffort:getCompletedCityCount(pPlayer)
	local count = 0

	for i = 1, self.ASSIGNED_CITIES_PER_RUN, 1 do
		if (self:getNumber(pPlayer, "city_" .. i .. "_complete") == 1) then
			count = count + 1
		end
	end

	return count
end

function GalacticReliefEffort:getCurrentCityHealedCount(pPlayer)
	return self:getNumber(pPlayer, "city_" .. self:getCurrentCityIndex(pPlayer) .. "_healed_count")
end

function GalacticReliefEffort:clearWaypoint(pPlayer)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil) then
		return
	end

	local waypointId = self:getNumber(pPlayer, "waypoint_id")
	if (waypointId ~= 0) then
		PlayerObject(pGhost):removeWaypoint(waypointId, true)
		self:setNumber(pPlayer, "waypoint_id", 0)
	end
end

function GalacticReliefEffort:updateWaypoint(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil) then
		return
	end

	self:clearWaypoint(pPlayer)

	local planet = self.NPC_PLANET
	local name = self.NPC_NAME
	local desc = "Return to Relief Coordinator Teren Vahl."
	local x = self.NPC_X
	local y = self.NPC_Y

	if (self:isActive(pPlayer) and not self:isRewardPending(pPlayer)) then
		local city = self:getCurrentCityData(pPlayer)
		if (city ~= nil) then
			planet = city.planet
			name = "Relief Assignment: " .. city.displayName
			desc = "Travel to " .. city.displayName .. " and stabilize five assigned patients."
			x = city.waypointX
			y = city.waypointY
		end
	elseif (self:isRewardPending(pPlayer)) then
		desc = "Return for mission debriefing and payment."
	end

	local waypointId = PlayerObject(pGhost):addWaypoint(planet, name, desc, x, 0, y, WAYPOINT_YELLOW, true, true, WAYPOINTQUESTTASK)
	self:setNumber(pPlayer, "waypoint_id", waypointId)
end

function GalacticReliefEffort:buildProgressReportText(pPlayer)
	local currentCity = self:getCurrentCityName(pPlayer)
	local cityHealed = self:getCurrentCityHealedCount(pPlayer)
	local completedCities = self:getCompletedCityCount(pPlayer)

	return "Galactic Relief Effort\n\nCurrent Assignment: " .. currentCity
		.. "\n" .. currentCity .. " Patients Healed: " .. cityHealed .. " / " .. self.PATIENTS_REQUIRED_PER_CITY
		.. "\nOverall Cities Completed: " .. completedCities .. " / " .. self.ASSIGNED_CITIES_PER_RUN
end

function GalacticReliefEffort:clearActivePatientMirror(pPlayer)
	self:setNumber(pPlayer, "activePatientCount", 0)

	for slot = 1, self.ACTIVE_PATIENT_POOL, 1 do
		self:setString(pPlayer, "activePatient" .. slot .. "Condition", "")
		self:setNumber(pPlayer, "activePatient" .. slot .. "ObjectId", 0)
		self:setNumber(pPlayer, "activePatient" .. slot .. "Healed", 0)
	end
end

function GalacticReliefEffort:syncActivePatientMirror(pPlayer)
	self:clearActivePatientMirror(pPlayer)

	if (pPlayer == nil or not self:isActive(pPlayer) or self:isRewardPending(pPlayer)) then
		return
	end

	local cityIndex = self:getCurrentCityIndex(pPlayer)
	self:setNumber(pPlayer, "activePatientCount", self.ACTIVE_PATIENT_POOL)

	for slot = 1, self.ACTIVE_PATIENT_POOL, 1 do
		self:setString(pPlayer, "activePatient" .. slot .. "Condition", self:getString(pPlayer, "city_" .. cityIndex .. "_patient_" .. slot .. "_condition"))
		self:setNumber(pPlayer, "activePatient" .. slot .. "ObjectId", self:getNumber(pPlayer, "city_" .. cityIndex .. "_patient_" .. slot .. "_object_id"))
		self:setNumber(pPlayer, "activePatient" .. slot .. "Healed", self:getNumber(pPlayer, "city_" .. cityIndex .. "_patient_" .. slot .. "_healed"))
	end
end

function GalacticReliefEffort:resetRunData(pPlayer)
	for cityIdx = 1, self.ASSIGNED_CITIES_PER_RUN, 1 do
		self:releaseSpawnPointsForCity(pPlayer, cityIdx)
	end
	self:setNumber(pPlayer, "active", 0)
	self:setNumber(pPlayer, "reward_pending", 0)
	self:setNumber(pPlayer, "reward_lock", 0)
	self:setNumber(pPlayer, "current_city_index", 0)
	self:setNumber(pPlayer, "waypoint_id", 0)
	self:clearActivePatientMirror(pPlayer)

	for cityIndex = 1, self.ASSIGNED_CITIES_PER_RUN, 1 do
		self:setString(pPlayer, "city_" .. cityIndex .. "_id", "")
		self:setNumber(pPlayer, "city_" .. cityIndex .. "_complete", 0)
		self:setNumber(pPlayer, "city_" .. cityIndex .. "_healed_count", 0)

		for slot = 1, self.ACTIVE_PATIENT_POOL, 1 do
			self:setNumber(pPlayer, "city_" .. cityIndex .. "_patient_" .. slot .. "_spawn_index", 0)
			self:setString(pPlayer, "city_" .. cityIndex .. "_patient_" .. slot .. "_condition", "")
			self:setString(pPlayer, "city_" .. cityIndex .. "_patient_" .. slot .. "_damage_pool", "")
			self:setNumber(pPlayer, "city_" .. cityIndex .. "_patient_" .. slot .. "_healed", 0)
			self:setNumber(pPlayer, "city_" .. cityIndex .. "_patient_" .. slot .. "_object_id", 0)
		end
	end
end

function GalacticReliefEffort:buildAssignmentData(pPlayer)
	local shuffledCities = self:shuffleArray(self.cityPool)
	local playerOid = SceneObject(pPlayer):getObjectID()

	for cityIndex = 1, self.ASSIGNED_CITIES_PER_RUN, 1 do
		local city = shuffledCities[cityIndex]
		self:setString(pPlayer, "city_" .. cityIndex .. "_id", city.id)
		self:setNumber(pPlayer, "city_" .. cityIndex .. "_complete", 0)
		self:setNumber(pPlayer, "city_" .. cityIndex .. "_healed_count", 0)

		local allIndexes = {}
		for i = 1, #city.spawnPoints, 1 do
			table.insert(allIndexes, i)
		end
		allIndexes = self:shuffleArray(allIndexes)

		-- Prefer spawn points not already claimed by another active player
		local spawnIndexes = {}
		for i = 1, #allIndexes, 1 do
			if #spawnIndexes >= self.ACTIVE_PATIENT_POOL then break end
			local owner = readData("gre:city:" .. city.id .. ":spawn:" .. allIndexes[i])
			if owner == nil or owner == 0 then
				table.insert(spawnIndexes, allIndexes[i])
			end
		end
		-- Fall back to any remaining points if the pool is exhausted
		for i = 1, #allIndexes, 1 do
			if #spawnIndexes >= self.ACTIVE_PATIENT_POOL then break end
			local alreadyIn = false
			for j = 1, #spawnIndexes, 1 do
				if spawnIndexes[j] == allIndexes[i] then alreadyIn = true; break end
			end
			if not alreadyIn then
				table.insert(spawnIndexes, allIndexes[i])
			end
		end

		self:claimCitySpawnPoints(city.id, playerOid, spawnIndexes)

		for slot = 1, self.ACTIVE_PATIENT_POOL, 1 do
			self:setNumber(pPlayer, "city_" .. cityIndex .. "_patient_" .. slot .. "_spawn_index", spawnIndexes[slot])
			if (getRandomNumber(1, 100) <= 50) then
				self:setString(pPlayer, "city_" .. cityIndex .. "_patient_" .. slot .. "_condition", "wound")
				self:setString(pPlayer, "city_" .. cityIndex .. "_patient_" .. slot .. "_damage_pool", "")
			else
				self:setString(pPlayer, "city_" .. cityIndex .. "_patient_" .. slot .. "_condition", "damage")
				if (getRandomNumber(1, 100) <= 50) then
					self:setString(pPlayer, "city_" .. cityIndex .. "_patient_" .. slot .. "_damage_pool", "health")
				else
					self:setString(pPlayer, "city_" .. cityIndex .. "_patient_" .. slot .. "_damage_pool", "action")
				end
			end

			self:setNumber(pPlayer, "city_" .. cityIndex .. "_patient_" .. slot .. "_healed", 0)
			self:setNumber(pPlayer, "city_" .. cityIndex .. "_patient_" .. slot .. "_object_id", 0)
		end
	end
end

function GalacticReliefEffort:choosePatientTemplate(city)
	if (city ~= nil and city.planet == "tatooine") then
		return "commoner_tatooine"
	end

	if (city ~= nil and city.planet == "naboo") then
		return "commoner_naboo"
	end

	return self.PATIENT_TEMPLATES[getRandomNumber(1, #self.PATIENT_TEMPLATES)]
end

function GalacticReliefEffort:applyPatientCondition(pMobile, condition, damagePool)
	if (pMobile == nil) then
		return
	end

	local mobile = CreatureObject(pMobile)
	local maxHealth = mobile:getMaxHAM(HEALTH)
	local maxAction = mobile:getMaxHAM(ACTION)

	if (condition == "wound") then
		mobile:setWounds(HEALTH, getRandomNumber(12, 22))
	else
		if (damagePool == "action") then
			mobile:setHAM(ACTION, math.max(1, maxAction - getRandomNumber(12, 24)))
		else
			mobile:setHAM(HEALTH, math.max(1, maxHealth - getRandomNumber(12, 24)))
		end
	end
end

function GalacticReliefEffort:stylePatient(pMobile, condition)
	if (pMobile == nil) then
		return
	end

	local mobile = CreatureObject(pMobile)
	local moodRoll = getRandomNumber(1, 100)

	if (moodRoll <= 40) then
		mobile:setMoodString("worried")
		mobile:setPosture(CROUCHED)
	elseif (moodRoll <= 75) then
		mobile:setMoodString("sad")
		mobile:setPosture(POSTURESITTING)
	else
		mobile:setMoodString("npc_sitting_ground")
		mobile:setPosture(POSTURESITTING)
	end

	if (condition == "wound") then
		SceneObject(pMobile):setCustomObjectName("Wounded Civilian")
	else
		SceneObject(pMobile):setCustomObjectName("Injured Civilian")
	end
end

function GalacticReliefEffort:spawnPatientForSlot(pPlayer, cityIndex, slot)
	local city = self:getAssignedCityData(pPlayer, cityIndex)
	if (city == nil) then
		return nil
	end

	local spawnIndex = self:getNumber(pPlayer, "city_" .. cityIndex .. "_patient_" .. slot .. "_spawn_index")
	local point = city.spawnPoints[spawnIndex]
	if (point == nil) then
		return nil
	end

	local template = self:choosePatientTemplate(city)
	local condition = self:getString(pPlayer, "city_" .. cityIndex .. "_patient_" .. slot .. "_condition")
	local damagePool = self:getString(pPlayer, "city_" .. cityIndex .. "_patient_" .. slot .. "_damage_pool")
	local jitterX = (getRandomNumber(1, 41) - 21) / 10.0
	local jitterZ = (getRandomNumber(1, 41) - 21) / 10.0
	local pMobile = spawnMobile(city.planet, template, 0, point[1] + jitterX, point[2], point[3] + jitterZ, point[4], point[5] or 0)

	if (pMobile == nil) then
		return nil
	end

	CreatureObject(pMobile):setPvpStatusBitmask(0)
	CreatureObject(pMobile):setOptionsBitmask(AIENABLED + INVULNERABLE + CONVERSABLE)
	CreatureObject(pMobile):setScreenPlayState(self.PATIENT_STATE_NAME, self.PATIENT_STATE_VALID)
	AiAgent(pMobile):addObjectFlag(AI_STATIC)
	AiAgent(pMobile):setConvoTemplate("galacticReliefPatientConvoTemplate")

	self:stylePatient(pMobile, condition)
	self:applyPatientCondition(pMobile, condition, damagePool)
	self:setNumber(pPlayer, "city_" .. cityIndex .. "_patient_" .. slot .. "_object_id", SceneObject(pMobile):getObjectID())

	return pMobile
end

function GalacticReliefEffort:ensureCurrentCityPatients(pPlayer)
	if (pPlayer == nil or not self:isActive(pPlayer) or self:isRewardPending(pPlayer)) then
		return
	end

	local cityIndex = self:getCurrentCityIndex(pPlayer)

	for slot = 1, self.ACTIVE_PATIENT_POOL, 1 do
		if (self:getNumber(pPlayer, "city_" .. cityIndex .. "_patient_" .. slot .. "_healed") == 0) then
			local objectId = self:getNumber(pPlayer, "city_" .. cityIndex .. "_patient_" .. slot .. "_object_id")
			local pMobile = nil

			if (objectId ~= 0) then
				pMobile = getSceneObject(objectId)
			end

			if (pMobile == nil) then
				self:spawnPatientForSlot(pPlayer, cityIndex, slot)
			end
		end
	end

	self:syncActivePatientMirror(pPlayer)
end

function GalacticReliefEffort:claimCitySpawnPoints(cityId, playerOid, indices)
	for i = 1, #indices, 1 do
		writeData("gre:city:" .. cityId .. ":spawn:" .. indices[i], playerOid)
	end
end

function GalacticReliefEffort:releaseSpawnPointsForCity(pPlayer, cityIndex)
	if pPlayer == nil then
		return
	end
	local cityData = self:getAssignedCityData(pPlayer, cityIndex)
	if cityData == nil then
		return
	end
	local playerOid = SceneObject(pPlayer):getObjectID()
	for slot = 1, self.ACTIVE_PATIENT_POOL, 1 do
		local spawnIndex = self:getNumber(pPlayer, "city_" .. cityIndex .. "_patient_" .. slot .. "_spawn_index")
		if spawnIndex ~= 0 then
			local key = "gre:city:" .. cityData.id .. ":spawn:" .. spawnIndex
			if readData(key) == playerOid then
				deleteData(key)
			end
		end
	end
end

function GalacticReliefEffort:destroyPatientById(objectId)
	if (objectId == nil or objectId == 0) then
		return
	end

	local pMobile = getSceneObject(objectId)
	if (pMobile == nil) then
		return
	end

	SceneObject(pMobile):destroyObjectFromWorld()
end

function GalacticReliefEffort:cleanupCityPatients(pPlayer, cityIndex)
	self:releaseSpawnPointsForCity(pPlayer, cityIndex)
	for slot = 1, self.ACTIVE_PATIENT_POOL, 1 do
		local keyBase = "city_" .. cityIndex .. "_patient_" .. slot
		self:destroyPatientById(self:getNumber(pPlayer, keyBase .. "_object_id"))
		self:setNumber(pPlayer, keyBase .. "_object_id", 0)
	end

	self:syncActivePatientMirror(pPlayer)
end

function GalacticReliefEffort:refreshObservers(pPlayer)
	if (pPlayer == nil) then
		return
	end

	dropObserver(LOGGEDIN, self.screenplayName, "onLoggedIn", pPlayer)
	dropObserver(ABILITYUSED, self.screenplayName, "notifyAbilityUsed", pPlayer)

	if (self:isActive(pPlayer) or self:isRewardPending(pPlayer)) then
		createObserver(LOGGEDIN, self.screenplayName, "onLoggedIn", pPlayer, 1)
	end

	if (self:isActive(pPlayer) and not self:isRewardPending(pPlayer)) then
		createObserver(ABILITYUSED, self.screenplayName, "notifyAbilityUsed", pPlayer)
	end
end

function GalacticReliefEffort:onLoggedIn(pPlayer)
	if (pPlayer == nil) then
		return 0
	end

	self:refreshObservers(pPlayer)

	if (self:isActive(pPlayer) and not self:isRewardPending(pPlayer)) then
		local currentIndex = self:getCurrentCityIndex(pPlayer)
		if (self:getNumber(pPlayer, "city_" .. currentIndex .. "_complete") == 1) then
			if (currentIndex >= self.ASSIGNED_CITIES_PER_RUN) then
				self:finalizeQuestReady(pPlayer)
			else
				self:cleanupCityPatients(pPlayer, currentIndex)
				self:setNumber(pPlayer, "current_city_index", currentIndex + 1)
			end
		end
		self:ensureCurrentCityPatients(pPlayer)
	end

	if (self:isActive(pPlayer) or self:isRewardPending(pPlayer)) then
		self:updateWaypoint(pPlayer)
	end

	return 0
end

function GalacticReliefEffort:conversationState(pPlayer)
	if (not self:isEligibleMedic(pPlayer)) then
		return "ineligible"
	end

	if (self:isRewardPending(pPlayer)) then
		return "reward_pending"
	end

	if (self:isActive(pPlayer)) then
		return "in_progress"
	end

	if (self:isOnCooldown(pPlayer)) then
		return "cooldown"
	end

	return "available"
end

function GalacticReliefEffort:getRulesText()
	return "Relief Assignment Protocols\n\n"
		.. "- Five cities are assigned at random for each run.\n"
		.. "- Stabilize five patients in the active city before the next city is cleared for duty.\n"
		.. "- Speak with each assigned patient and choose the correct treatment.\n"
		.. "- Wounded patients require the wound treatment choice.\n"
		.. "- Damaged patients require the damage treatment choice.\n"
		.. "- Only your assigned relief patients count.\n"
		.. "- Return to Teren Vahl after all five cities are complete."
end

function GalacticReliefEffort:startAssignment(pPlayer)
	if (pPlayer == nil) then
		return false, "I cannot process an assignment without a registered medic."
	end

	if (not self:isEligibleMedic(pPlayer)) then
		return false, "This relief circuit is reserved for medics trained to use both /tendDamage and /tendWound."
	end

	if (self:isActive(pPlayer) or self:isRewardPending(pPlayer)) then
		self:ensureCurrentCityPatients(pPlayer)
		self:updateWaypoint(pPlayer)
		return false, "Your current relief assignment is already active.\n\n" .. self:buildProgressReportText(pPlayer)
	end

	if (self:isOnCooldown(pPlayer)) then
		return false, "You must wait " .. self:formatDurationWords(self:getRemainingCooldown(pPlayer)) .. " before undertaking another relief assignment."
	end

	self:resetRunData(pPlayer)
	self:buildAssignmentData(pPlayer)
	self:setNumber(pPlayer, "active", 1)
	self:setNumber(pPlayer, "current_city_index", 1)
	self:ensureCurrentCityPatients(pPlayer)
	self:refreshObservers(pPlayer)
	self:updateWaypoint(pPlayer)

	local firstCity = self:getCurrentCityName(pPlayer)
	return true, "The relief circuit is live. Your first priority world is " .. firstCity .. ". Travel there and stabilize five assigned civilians."
end

function GalacticReliefEffort:getPatientSlotForTarget(pPlayer, targetId)
	if (pPlayer == nil or targetId == nil or targetId == 0) then
		return 0
	end

	local cityIndex = self:getCurrentCityIndex(pPlayer)

	for slot = 1, self.ACTIVE_PATIENT_POOL, 1 do
		if (self:getNumber(pPlayer, "city_" .. cityIndex .. "_patient_" .. slot .. "_object_id") == targetId) then
			return slot
		end
	end

	return 0
end

function GalacticReliefEffort:recoveryCleanupEvent(pPatient)
	if (pPatient == nil) then
		return 0
	end

	SceneObject(pPatient):destroyObjectFromWorld()
	return 0
end

function GalacticReliefEffort:finalizeQuestReady(pPlayer)
	self:setNumber(pPlayer, "reward_pending", 1)
	self:clearActivePatientMirror(pPlayer)
	self:refreshObservers(pPlayer)
	self:updateWaypoint(pPlayer)

	local rewardText = "All five worlds are stabilized. Return to Relief Coordinator Teren Vahl for payment and a Holocron of Destiny."

	if (self:shouldGrantBonusReward(pPlayer)) then
		rewardText = rewardText .. " Your one-time doctor buff droid deed is also ready."
	end

	CreatureObject(pPlayer):sendSystemMessage(rewardText)
end

function GalacticReliefEffort:advanceToNextCityEvent(pPlayer)
	if (pPlayer == nil) then
		return 0
	end

	local currentIndex = self:getCurrentCityIndex(pPlayer)
	self:cleanupCityPatients(pPlayer, currentIndex)

	if (currentIndex >= self.ASSIGNED_CITIES_PER_RUN) then
		self:finalizeQuestReady(pPlayer)
		return 0
	end

	local nextIndex = currentIndex + 1
	self:setNumber(pPlayer, "current_city_index", nextIndex)
	self:ensureCurrentCityPatients(pPlayer)
	self:updateWaypoint(pPlayer)

	local nextCity = self:getCurrentCityName(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("Relief network update: " .. nextCity .. " is now your active assignment. Stabilize five patients there.")
	return 0
end

function GalacticReliefEffort:handleSuccessfulTreatment(pPlayer, pTarget, abilityHash)
	if (pPlayer == nil or pTarget == nil or not self:isActive(pPlayer) or self:isRewardPending(pPlayer)) then
		return 0
	end

	local targetId = SceneObject(pTarget):getObjectID()
	local slot = self:getPatientSlotForTarget(pPlayer, targetId)
	if (slot == 0) then
		return 0
	end

	local cityIndex = self:getCurrentCityIndex(pPlayer)
	if (self:getNumber(pPlayer, "city_" .. cityIndex .. "_complete") == 1) then
		return 0
	end

	local keyBase = "city_" .. cityIndex .. "_patient_" .. slot
	if (self:getNumber(pPlayer, keyBase .. "_healed") == 1) then
		return 0
	end

	local expectedCondition = self:getString(pPlayer, keyBase .. "_condition")
	if (expectedCondition == "wound" and abilityHash ~= getHashCode("tendwound") and abilityHash ~= getHashCode("conversation_wound")) then
		return 0
	end

	if (expectedCondition == "damage" and abilityHash ~= getHashCode("tenddamage") and abilityHash ~= getHashCode("conversation_damage")) then
		return 0
	end

	self:setNumber(pPlayer, keyBase .. "_healed", 1)
	local healedCount = self:getNumber(pPlayer, "city_" .. cityIndex .. "_healed_count") + 1
	self:setNumber(pPlayer, "city_" .. cityIndex .. "_healed_count", healedCount)
	self:syncActivePatientMirror(pPlayer)

	spatialChat(pTarget, self.PATIENT_RECOVERY_LINES[getRandomNumber(1, #self.PATIENT_RECOVERY_LINES)])
	CreatureObject(pPlayer):sendSystemMessage(self:getCurrentCityName(pPlayer) .. " relief progress: " .. healedCount .. " / " .. self.PATIENTS_REQUIRED_PER_CITY .. ".")
	createEvent(3500, self.screenplayName, "recoveryCleanupEvent", pTarget, "")

	if (healedCount >= self.PATIENTS_REQUIRED_PER_CITY) then
		self:setNumber(pPlayer, "city_" .. cityIndex .. "_complete", 1)

		local completedCities = self:getCompletedCityCount(pPlayer)
		CreatureObject(pPlayer):sendSystemMessage(self:getCurrentCityName(pPlayer) .. " has been stabilized. Worlds completed: " .. completedCities .. " / " .. self.ASSIGNED_CITIES_PER_RUN .. ".")
		createEvent(1000, self.screenplayName, "advanceToNextCityEvent", pPlayer, "")
	end

	return 1
end

function GalacticReliefEffort:getPatientExpectedCondition(pPlayer, pTarget)
	if (pPlayer == nil or pTarget == nil) then
		return "", 0, 0
	end

	if (not self:isActive(pPlayer) or self:isRewardPending(pPlayer)) then
		return "", 0, 0
	end

	local targetId = SceneObject(pTarget):getObjectID()
	local slot = self:getPatientSlotForTarget(pPlayer, targetId)
	if (slot == 0) then
		return "", 0, 0
	end

	local cityIndex = self:getCurrentCityIndex(pPlayer)
	local keyBase = "city_" .. cityIndex .. "_patient_" .. slot

	if (self:getNumber(pPlayer, "city_" .. cityIndex .. "_complete") == 1 or self:getNumber(pPlayer, keyBase .. "_healed") == 1) then
		return "healed", cityIndex, slot
	end

	return self:getString(pPlayer, keyBase .. "_condition"), cityIndex, slot
end

function GalacticReliefEffort:getPatientPromptText(pPlayer, pTarget)
	if (pPlayer == nil or pTarget == nil) then
		return "The civilian is in no state to answer."
	end

	if (not self:isEligibleMedic(pPlayer)) then
		return "You do not have the medical training to help me."
	end

	if (self:isRewardPending(pPlayer)) then
		return "You have already stabilized this circuit. Return to Teren Vahl."
	end

	if (not self:isActive(pPlayer)) then
		return "If you are a medic, speak with Relief Coordinator Teren Vahl first."
	end

	local condition = self:getPatientExpectedCondition(pPlayer, pTarget)
	if (condition == "") then
		return "I am not part of your assigned relief circuit. Please help the patients marked by your coordinator."
	elseif (condition == "healed") then
		return "Your treatment already steadied me. Others still need your hands."
	elseif (condition == "wound") then
		return "Everything aches. Please close these wounds before I collapse again."
	end

	return "I can still breathe, but the damage is spreading. Please stabilize me."
end

function GalacticReliefEffort:attemptConversationTreatment(pPlayer, pTarget, treatmentType)
	if (pPlayer == nil or pTarget == nil) then
		return false, "The treatment cannot be performed right now."
	end

	if (not self:isEligibleMedic(pPlayer)) then
		return false, "You lack the medical training required for relief duty."
	end

	if (self:isRewardPending(pPlayer)) then
		return false, "Your circuit is already complete. Return to Teren Vahl."
	end

	if (not self:isActive(pPlayer)) then
		return false, "You do not have an active Galactic Relief Effort assignment."
	end

	local expectedCondition = self:getPatientExpectedCondition(pPlayer, pTarget)

	if (expectedCondition == "") then
		return false, "This civilian is not assigned to your current relief circuit."
	end

	if (expectedCondition == "healed") then
		return false, "This civilian has already been stabilized."
	end

	if (expectedCondition ~= treatmentType) then
		if (expectedCondition == "wound") then
			return false, "That diagnosis is wrong. This patient needs wound treatment."
		end

		return false, "That diagnosis is wrong. This patient needs damage treatment."
	end

	CreatureObject(pPlayer):doAnimation("heal_other")
	self:handleSuccessfulTreatment(pPlayer, pTarget, getHashCode("conversation_" .. treatmentType))

	if (treatmentType == "wound") then
		return true, "You close the civilian's wounds and restore their strength."
	end

	return true, "You stabilize the civilian's injuries and restore their balance."
end

function GalacticReliefEffort:notifyAbilityUsed(pPlayer, pTarget, abilityHash)
	if (abilityHash ~= getHashCode("tendwound") and abilityHash ~= getHashCode("tenddamage")) then
		return 0
	end

	return self:handleSuccessfulTreatment(pPlayer, pTarget, abilityHash)
end

function GalacticReliefEffort:canGrantReward(pPlayer)
	if (pPlayer == nil) then
		return false, "I cannot verify your relief ledger."
	end

	if (not self:isRewardPending(pPlayer)) then
		if (self:isActive(pPlayer)) then
			return false, "The relief circuit is still active.\n\n" .. self:buildProgressReportText(pPlayer)
		end

		if (self:isOnCooldown(pPlayer)) then
			return false, "You must wait " .. self:formatDurationWords(self:getRemainingCooldown(pPlayer)) .. " before undertaking another relief assignment."
		end

		return false, "You do not have a completed Galactic Relief Effort assignment ready for turn-in."
	end

	if (self:isRewardLocked(pPlayer)) then
		return false, "Your relief compensation is already being processed."
	end

	local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil) then
		return false, "I cannot locate your inventory manifest."
	end

	local inventory = SceneObject(pInventory)
	local freeSlots = inventory:getContainerVolumeLimit() - inventory:getCountableObjectsRecursive()
	local requiredSlots = 1

	if (self:shouldGrantBonusReward(pPlayer)) then
		requiredSlots = 2
	end

	if (freeSlots < requiredSlots) then
		if (requiredSlots == 1) then
			return false, "Make room in your inventory before I hand over the Holocron of Destiny."
		end

		return false, "Make room for at least two inventory items before I hand over your Holocron of Destiny and one-time doctor buff droid deed."
	end

	return true, ""
end

function GalacticReliefEffort:grantReward(pPlayer)
	local canGrant, message = self:canGrantReward(pPlayer)
	if (not canGrant) then
		return false, message
	end

	local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")
	local now = self:getNow()

	self:setNumber(pPlayer, "reward_lock", 1)
	self:setNumber(pPlayer, "cooldown_until", now + self.COOLDOWN_SECONDS)

	local pReward = giveItem(pInventory, self.REWARD_ITEM_TEMPLATE, -1, true)
	if (pReward == nil) then
		self:setNumber(pPlayer, "reward_lock", 0)
		self:setNumber(pPlayer, "cooldown_until", 0)
		return false, "I could not place the Holocron of Destiny into your inventory. Free a slot and speak to me again."
	end

	SceneObject(pReward):setCustomObjectName("Holocron of Destiny")

	local grantedBonusReward = false

	if (self:shouldGrantBonusReward(pPlayer)) then
		local pBonusReward = giveItem(pInventory, self.BONUS_REWARD_ITEM_TEMPLATE, -1, true)
		if (pBonusReward == nil) then
			SceneObject(pReward):destroyObjectFromWorld()
			SceneObject(pReward):destroyObjectFromDatabase()
			self:setNumber(pPlayer, "reward_lock", 0)
			self:setNumber(pPlayer, "cooldown_until", 0)
			return false, "I could not place your one-time doctor buff droid deed into your inventory. Free enough space and speak to me again."
		end

		grantedBonusReward = true
		self:setNumber(pPlayer, "doctor_buff_droid_deed_claimed", 1)
	end

	CreatureObject(pPlayer):addBankCredits(self.REWARD_CREDITS, true)
	self:cleanupCityPatients(pPlayer, self:getCurrentCityIndex(pPlayer))
	self:clearWaypoint(pPlayer)
	self:resetRunData(pPlayer)
	self:setNumber(pPlayer, "cooldown_until", now + self.COOLDOWN_SECONDS)
	self:refreshObservers(pPlayer)

	local rewardMessage = "Your relief circuit is complete. The Alliance of medics across the stars recognizes your service.\n\nRewarded:\n- 150,000 credits\n- 1 Holocron of Destiny"

	if (grantedBonusReward) then
		rewardMessage = rewardMessage .. "\n- 1 Doctor Buff Droid Deed"
	end

	return true, rewardMessage
end
