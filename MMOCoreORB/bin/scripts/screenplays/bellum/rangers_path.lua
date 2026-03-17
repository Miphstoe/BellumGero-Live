--[[
	The Ranger's Path
	Core3 screenplay for a 6-stage Ranger/Scout profession questline.

	Implemented gameplay stages:
	- Stage 1: Tracking the Hunter
	- Stage 2: Survival of the Wilds
	- Stage 3: The Missing Scouts
	- Stage 4: The Great Hunt
	- Stage 5: Protect the Frontier
	- Stage 6: The Ranger Trial

	Design notes:
	- Stage objective completion is tracked separately from final quest completion.
	- Stage 6 boss kill only marks the final objective ready.
	- The quest is only fully completed when the player returns to Talren Voss
	  and receives the final reward.
]]

RangersPath = ScreenPlay:new {
	screenplayName = "RangersPath",
	numberOfActs = 1,
}

registerScreenPlay("RangersPath", true)

-- ============================================================================
-- Core constants
-- ============================================================================

RangersPath.DATA_NAMESPACE = "rangers_path"
RangersPath.CONVO_TEMPLATE = "rangersPathConvoTemplate"

RangersPath.MAX_STAGE = 6
RangersPath.MAX_ENCOUNTER_MOBS = 8
RangersPath.MAX_SETTLER_MOBS = 4
RangersPath.ENCOUNTER_TIMEOUT_MS = 15 * 60 * 1000
RangersPath.STAGE5_RESET_DELAY_MS = 20 * 1000
RangersPath.STAGE5_NEXT_WAVE_DELAY_MS = 4 * 1000

RangersPath.REWARD_CREDITS = 25000
RangersPath.REWARD_ITEM_TEMPLATE = "object/tangible/survey_tool/survey_tool_creature.iff"

RangersPath.STAGE_CREDITS = {
	[1] = 10000,
	[2] = 12500,
	[3] = 15000,
	[4] = 17500,
	[5] = 20000,
}

RangersPath.ALLOW_MANUAL_STAGE_READY = true
RangersPath.DEBUG_STAGE2 = false
RangersPath.DEBUG_STAGE3 = false

-- ============================================================================
-- Quest giver configuration
-- ============================================================================

RangersPath.QUEST_GIVER = {
	name = "Master Ranger Talren Voss",
	template = "trainer_ranger",
	planet = "talus",
	x = 900,
	z = 16,
	y = -900,
	heading = 180,
	cell = 0,
}

RangersPath.RANGER_CAMP = {
	planet = "talus",
	objects = {
		{
			template = "object/static/structure/corellia/corl_tent_small.iff",
			x = 894,
			z = 16,
			y = -908,
			heading = 0,
		},
		{
			template = "object/static/structure/corellia/corl_tent_small.iff",
			x = 906,
			z = 16,
			y = -908,
			heading = 180,
		},
		{
			template = "object/static/structure/general/campfire_fresh.iff",
			x = 900,
			z = 16,
			y = -906,
			heading = 0,
		},
		{
			template = "object/static/structure/general/camp_lawn_chair_s01.iff",
			x = 897,
			z = 16,
			y = -904,
			heading = 45,
		},
		{
			template = "object/static/structure/general/camp_lawn_chair_s01.iff",
			x = 903,
			z = 16,
			y = -904,
			heading = -45,
		},
		{
			template = "object/static/structure/general/camp_cot_s01.iff",
			x = 892,
			z = 16,
			y = -900,
			heading = 90,
		},
		{
			template = "object/static/structure/general/camp_cot_s01.iff",
			x = 908,
			z = 16,
			y = -900,
			heading = -90,
		},
		{
			template = "object/static/structure/general/camp_spit_s01.iff",
			x = 904,
			z = 16,
			y = -911,
			heading = 135,
		},
		{
			template = "object/tangible/camp/camp_crate_s1.iff",
			x = 895,
			z = 16,
			y = -912,
			heading = 15,
		},
	},
}

-- ============================================================================
-- Stage configuration
-- ============================================================================
-- TODO: Replace placeholder templates and coordinates with final production data.
-- Stage 6 boss tuning should be adjusted in creature templates/server data if you
-- want truly elite combat stats beyond the template chosen here.
-- ============================================================================

RangersPath.STAGES = {
	[1] = {
		title = "Tracking the Hunter",
		planet = "dantooine",
		x = 5108,
		z = 20,
		y = -2924,
		waypointName = "Tracking the Hunter",
		waypointDesc = "Travel to the hunt region and flush out the predator.",
		hunt = {
			enabled = true,
			regionRadius = 80,
			targetTemplate = "ranger_razor_cat_alpha",
			targetName = "Razor Cat Alpha",
			spawnX = 5108,
			spawnZ = 20,
			spawnY = -2924,
			spawnHeading = 45,
			roamRadius = 0,
			huntMessage = "Your quarry has revealed itself. Finish the hunt.",
			completeMessage = "You have slain the dangerous predator. Return to Talren Voss.",
		},
	},
	[2] = {
		title = "Survival of the Wilds",
		planet = "talus",
		x = 1085,
		z = 26,
		y = -1045,
		waypointName = "Survival of the Wilds",
		waypointDesc = "Find the hidden camp and inspect the supply cache.",
		camp = {
			crateTemplate = "object/tangible/container/drum/warren_drum_skeleton.iff",
			crateName = "Ranger Supply Cache",
			crateX = 1088,
			crateZ = 26,
			crateY = -1041,
			interactionRadius = 8,
			ambushMin = 4,
			ambushMax = 6,
			ambushTemplates = {
				"sludge_panther",
				"sludge_panther",
				"sludge_panther",
				"sludge_panther",
				"sludge_panther",
				"sludge_panther",
			},
			ambushSpawnPoints = {
				{ x = 1079, z = 26, y = -1036, heading = 25 },
				{ x = 1082, z = 26, y = -1052, heading = -50 },
				{ x = 1097, z = 26, y = -1039, heading = 110 },
				{ x = 1094, z = 26, y = -1051, heading = -120 },
				{ x = 1086, z = 26, y = -1058, heading = 165 },
				{ x = 1102, z = 26, y = -1046, heading = -90 },
			},
		},
	},
	[3] = {
		title = "The Missing Scouts",
		planet = "talus",
		x = 1178,
		z = 29,
		y = -1158,
		waypointName = "The Missing Scouts",
		waypointDesc = "Travel to the scouts' last position and investigate the site.",
		investigation = {
			trailRadius = 18,
			trailPoints = {
				{ x = 1134, z = 28, y = -1088, name = "Faint Trail", desc = "Follow the scouts' first signs." },
				{ x = 1156, z = 28, y = -1126, name = "Broken Brush", desc = "Continue following the disturbed trail." },
			},
			site = {
				x = 1178,
				z = 29,
				y = -1158,
				name = "Scout Last Position",
				desc = "Investigate the final site and recover what remains.",
			},
			guards = {
				{ template = "razor_cat", x = 1172, z = 29, y = -1154, heading = 50 },
				{ template = "razor_cat", x = 1184, z = 29, y = -1160, heading = -90 },
				{ template = "razor_cat", x = 1179, z = 29, y = -1167, heading = 145 },
			},
			remainsTemplate = "object/tangible/camp/camp_lantern_s3.iff",
			remainsName = "Scout Remains",
			remainsX = 1178,
			remainsZ = 29,
			remainsY = -1158,
			remainsRadius = 7,
		},
	},
	[4] = {
		title = "The Great Hunt",
		planet = "dathomir",
		x = -3865,
		z = 124,
		y = -115,
		waypointName = "The Great Hunt",
		waypointDesc = "Enter the hunt grounds and bring down the rare beast.",
		hunt = {
			enabled = true,
			regionRadius = 140,
			targetTemplate = "enraged_bull_rancor",
			targetName = "Savage Graul Stalker",
			spawnX = -3898,
			spawnZ = 126,
			spawnY = -76,
			spawnHeading = -90,
			roamRadius = 40,
			huntMessage = "The great beast is moving in the hunt grounds. Bring it down.",
			completeMessage = "The great beast is down. Return to Talren Voss.",
		},
	},
	[5] = {
		title = "Protect the Frontier",
		planet = "talus",
		x = 1285,
		z = 30,
		y = -1240,
		waypointName = "Protect the Frontier",
		waypointDesc = "Travel to the settler camp and hold the frontier line.",
		defense = {
			startRadius = 30,
			settlers = {
				{ template = "farmer", x = 1282, z = 30, y = -1241, heading = 10, name = "Frontier Settler Halen", required = true },
				{ template = "farmer", x = 1287, z = 30, y = -1238, heading = -80, name = "Frontier Settler Mira", required = true },
				{ template = "commoner", x = 1289, z = 30, y = -1244, heading = 140, name = "Frontier Settler Joren", required = false },
			},
			waves = {
				[1] = {
					name = "Smaller Predators",
					mobiles = {
						{ template = "razor_cat", x = 1268, z = 30, y = -1233, heading = 30 },
						{ template = "razor_cat", x = 1270, z = 30, y = -1248, heading = 50 },
						{ template = "razor_cat", x = 1302, z = 30, y = -1235, heading = -110 },
					},
				},
				[2] = {
					name = "Predator Pack",
					mobiles = {
						{ template = "razor_cat", x = 1264, z = 30, y = -1244, heading = 25 },
						{ template = "razor_cat", x = 1267, z = 30, y = -1251, heading = 35 },
						{ template = "razor_cat", x = 1306, z = 30, y = -1238, heading = -120 },
						{ template = "razor_cat", x = 1304, z = 30, y = -1249, heading = -135 },
					},
				},
				[3] = {
					name = "Alpha Attacker",
					mobiles = {
						{ template = "huf_dun_bull", x = 1261, z = 30, y = -1240, heading = 40, name = "Frontier Pack Alpha" },
					},
				},
			},
		},
	},
	[6] = {
		title = "The Ranger Trial",
		planet = "dathomir",
		x = -4487,
		z = 127,
		y = 2543,
		waypointName = "The Ranger Trial",
		waypointDesc = "Enter the proving grounds and face the legendary hunt.",
		hunt = {
			enabled = true,
			regionRadius = 160,
			targetTemplate = "enraged_bull_rancor",
			targetName = "Ancient Shadowclaw",
			spawnX = -4525,
			spawnZ = 128,
			spawnY = 2518,
			spawnHeading = 90,
			roamRadius = 28,
			huntMessage = "Ancient Shadowclaw emerges from the gloom. This is your final proving hunt.",
			completeMessage = "Ancient Shadowclaw has fallen. Return to Master Ranger Talren Voss for judgment.",
			elite = true,
			-- TODO: Use a dedicated elite creature template for Ancient Shadowclaw if you
			-- want higher health/damage than the placeholder template provides.
			-- TODO: Add special attack barks/effects here if you wire custom AI hooks.
		},
	},
}

-- ============================================================================
-- Screenplay lifecycle
-- ============================================================================

function RangersPath:start()
	self:spawnMobiles()
end

function RangersPath:spawnMobiles()
	self:spawnRangerCamp()
	self:spawnQuestGiver()
end

function RangersPath:spawnRangerCamp()
	local camp = self.RANGER_CAMP

	for i = 1, #camp.objects, 1 do
		local obj = camp.objects[i]
		local pObject = spawnSceneObject(
			camp.planet,
			obj.template,
			obj.x,
			obj.z,
			obj.y,
			0,
			math.rad(obj.heading or 0)
		)

		if (pObject == nil) then
			printLuaError("RangersPath: failed to spawn camp object " .. obj.template)
		end
	end

	-- TODO: Tune the camp layout and swap in preferred Talus ranger-camp assets.
end

function RangersPath:spawnQuestGiver()
	local cfg = self.QUEST_GIVER

	local pNpc = spawnMobile(
		cfg.planet,
		cfg.template,
		0,
		cfg.x,
		cfg.z,
		cfg.y,
		cfg.heading,
		cfg.cell
	)

	if (pNpc == nil) then
		return
	end

	CreatureObject(pNpc):setPvpStatusBitmask(0)
	CreatureObject(pNpc):setOptionsBitmask(AIENABLED + CONVERSABLE + INVULNERABLE)
	SceneObject(pNpc):setCustomObjectName(cfg.name)
	AiAgent(pNpc):setConvoTemplate(self.CONVO_TEMPLATE)
	AiAgent(pNpc):addObjectFlag(AI_STATIC)
end

-- ============================================================================
-- Low-level persistent data helpers
-- ============================================================================

function RangersPath:getNumber(pPlayer, key)
	if (pPlayer == nil) then
		return 0
	end

	return tonumber(readScreenPlayData(pPlayer, self.DATA_NAMESPACE, key)) or 0
end

function RangersPath:setNumber(pPlayer, key, value)
	if (pPlayer == nil) then
		return
	end

	writeScreenPlayData(pPlayer, self.DATA_NAMESPACE, key, value)
end

function RangersPath:getString(pPlayer, key)
	if (pPlayer == nil) then
		return ""
	end

	return tostring(readScreenPlayData(pPlayer, self.DATA_NAMESPACE, key) or "")
end

function RangersPath:setString(pPlayer, key, value)
	if (pPlayer == nil) then
		return
	end

	writeScreenPlayData(pPlayer, self.DATA_NAMESPACE, key, value)
end

function RangersPath:getPlayerId(pPlayer)
	if (pPlayer == nil) then
		return 0
	end

	return SceneObject(pPlayer):getObjectID()
end

function RangersPath:getPlayerGhost(pPlayer)
	if (pPlayer == nil) then
		return nil
	end

	return CreatureObject(pPlayer):getPlayerObject()
end

function RangersPath:getInventory(pPlayer)
	if (pPlayer == nil) then
		return nil
	end

	return SceneObject(pPlayer):getSlottedObject("inventory")
end

function RangersPath:hasInventorySpace(pPlayer)
	local pInventory = self:getInventory(pPlayer)

	if (pInventory == nil) then
		return false
	end

	return not SceneObject(pInventory):isContainerFullRecursive()
end

-- ============================================================================
-- Public quest state helpers
-- ============================================================================

function RangersPath:hasStarted(pPlayer)
	return self:getNumber(pPlayer, "started") == 1
end

function RangersPath:isCompleted(pPlayer)
	return self:getNumber(pPlayer, "completed") == 1
end

function RangersPath:isRewarded(pPlayer)
	return self:getNumber(pPlayer, "rewarded") == 1
end

function RangersPath:getStage(pPlayer)
	local stage = self:getNumber(pPlayer, "current_stage")

	if (stage < 0) then
		return 0
	end

	if (stage > self.MAX_STAGE) then
		return self.MAX_STAGE
	end

	return stage
end

function RangersPath:setStage(pPlayer, stage)
	if (stage < 0) then
		stage = 0
	elseif (stage > self.MAX_STAGE) then
		stage = self.MAX_STAGE
	end

	self:setNumber(pPlayer, "current_stage", stage)
end

function RangersPath:isRewardPending(pPlayer)
	return self:hasFinalObjectiveComplete(pPlayer) and not self:isRewarded(pPlayer)
end

function RangersPath:isStageActive(pPlayer, stage)
	return self:hasStarted(pPlayer) and not self:isCompleted(pPlayer) and self:getStage(pPlayer) == stage
end

function RangersPath:hasFinalObjectiveComplete(pPlayer)
	return self:getStage(pPlayer) == 6 and self:isStageReady(pPlayer, 6)
end

-- ============================================================================
-- Conversation helpers
-- ============================================================================

function RangersPath:conversationState(pPlayer)
	if (pPlayer == nil) then
		return "intro"
	end

	if (self:isRewarded(pPlayer)) then
		return "already_completed"
	end

	if (self:hasFinalObjectiveComplete(pPlayer) or self:isCompleted(pPlayer)) then
		return "final_completion"
	end

	if (not self:hasStarted(pPlayer)) then
		return "intro"
	end

	local stage = self:getStage(pPlayer)

	if (self:isStageReady(pPlayer, stage)) then
		return "stage_" .. tostring(stage) .. "_ready"
	end

	return "stage_" .. tostring(stage) .. "_progress"
end

-- ============================================================================
-- Stage metadata helpers
-- ============================================================================

function RangersPath:getStageData(stage)
	return self.STAGES[stage]
end

function RangersPath:getCurrentStageData(pPlayer)
	return self:getStageData(self:getStage(pPlayer))
end

function RangersPath:getStageTitle(stage)
	local data = self:getStageData(stage)

	if (data == nil) then
		return "Unknown Stage"
	end

	return data.title
end

function RangersPath:getStageReadyKey(stage)
	return "stage_" .. tostring(stage) .. "_ready"
end

function RangersPath:getStageCompleteKey(stage)
	return "stage_" .. tostring(stage) .. "_complete"
end

function RangersPath:stageRequiresObjectiveFlag(stage)
	return stage == 1 or stage == 2 or stage == 3 or stage == 4 or stage == 5 or stage == 6
end

function RangersPath:isStageReady(pPlayer, stage)
	if (self:stageRequiresObjectiveFlag(stage)) then
		return self:getNumber(pPlayer, self:getStageReadyKey(stage)) == 1
	end

	if (self.ALLOW_MANUAL_STAGE_READY) then
		return true
	end

	return self:getNumber(pPlayer, self:getStageReadyKey(stage)) == 1
end

function RangersPath:setStageReady(pPlayer, stage, value)
	self:setNumber(pPlayer, self:getStageReadyKey(stage), value)
end

function RangersPath:isStageMarkedComplete(pPlayer, stage)
	return self:getNumber(pPlayer, self:getStageCompleteKey(stage)) == 1
end

function RangersPath:setStageMarkedComplete(pPlayer, stage, value)
	self:setNumber(pPlayer, self:getStageCompleteKey(stage), value)
end

-- ============================================================================
-- Waypoint helpers
-- ============================================================================

function RangersPath:removeWaypointByKey(pPlayer, key)
	local pGhost = self:getPlayerGhost(pPlayer)

	if (pGhost == nil) then
		self:setNumber(pPlayer, key, 0)
		return
	end

	local waypointId = self:getNumber(pPlayer, key)

	if (waypointId ~= nil and waypointId ~= 0) then
		PlayerObject(pGhost):removeWaypoint(waypointId, true)
	end

	self:setNumber(pPlayer, key, 0)
end

function RangersPath:addWaypointByKey(pPlayer, key, planet, name, description, x, z, y)
	local pGhost = self:getPlayerGhost(pPlayer)

	if (pGhost == nil) then
		return 0
	end

	self:removeWaypointByKey(pPlayer, key)

	local waypointId = PlayerObject(pGhost):addWaypoint(planet, name, description, x, z, y, WAYPOINT_YELLOW, true, true, WAYPOINTQUESTTASK)

	if (waypointId ~= nil and waypointId ~= 0) then
		self:setNumber(pPlayer, key, waypointId)
		return waypointId
	end

	return 0
end

function RangersPath:addStageWaypoint(pPlayer, stage)
	local data = self:getStageData(stage)

	if (data == nil) then
		return 0
	end

	return self:addWaypointByKey(
		pPlayer,
		"stage_waypoint_id",
		data.planet,
		data.waypointName,
		data.waypointDesc,
		data.x,
		0,
		data.y
	)
end

function RangersPath:addCustomStageWaypoint(pPlayer, planet, name, description, x, y)
	return self:addWaypointByKey(pPlayer, "stage_waypoint_id", planet, name, description, x, 0, y)
end

function RangersPath:removeStageWaypoint(pPlayer)
	self:removeWaypointByKey(pPlayer, "stage_waypoint_id")
end

function RangersPath:addQuestGiverWaypoint(pPlayer, description)
	local cfg = self.QUEST_GIVER

	return self:addWaypointByKey(
		pPlayer,
		"return_waypoint_id",
		cfg.planet,
		cfg.name,
		description,
		cfg.x,
		0,
		cfg.y
	)
end

function RangersPath:removeQuestGiverWaypoint(pPlayer)
	self:removeWaypointByKey(pPlayer, "return_waypoint_id")
end

function RangersPath:refreshStage3Waypoint(pPlayer)
	local stageData = self:getStageData(3)
	local info = stageData.investigation

	self:removeQuestGiverWaypoint(pPlayer)

	if (self:getNumber(pPlayer, "stage3_site_reached") == 1) then
		self:addCustomStageWaypoint(pPlayer, stageData.planet, info.site.name, info.site.desc, info.site.x, info.site.y)
		return
	end

	local step = self:getStage3TrailStep(pPlayer)
	local point = info.trailPoints[step]

	if (point == nil) then
		point = info.site
	end

	self:addCustomStageWaypoint(pPlayer, stageData.planet, point.name, point.desc, point.x, point.y)
end

function RangersPath:rebuildCurrentStageEncounter(pPlayer)
	if (pPlayer == nil or not self:hasStarted(pPlayer) or self:isCompleted(pPlayer)) then
		return
	end

	local stage = self:getStage(pPlayer)

	if (self:isStageReady(pPlayer, stage)) then
		return
	end

	if (stage == 2) then
		self:resetEncounter(pPlayer)
		self:setupStage2Objectives(pPlayer, false)
	elseif (stage == 3) then
		self:resetEncounter(pPlayer)
		self:setupStage3Objectives(pPlayer, false)
	elseif (stage == 5) then
		self:resetEncounter(pPlayer)
		self:setupStage5Objectives(pPlayer, false)
	elseif (stage == 6) then
		self:resetEncounter(pPlayer)
		self:setupStage6Objectives(pPlayer)
	end
end

function RangersPath:refreshQuestWaypoint(pPlayer)
	if (pPlayer == nil) then
		return
	end

	if (self:isRewardPending(pPlayer)) then
		self:removeStageWaypoint(pPlayer)
		self:addQuestGiverWaypoint(pPlayer, "Return to Talren Voss for your reward.")
		return
	end

	local stage = self:getStage(pPlayer)

	if (not self:hasStarted(pPlayer) or self:isCompleted(pPlayer)) then
		return
	end

	self:rebuildCurrentStageEncounter(pPlayer)

	if (stage == 3) then
		self:refreshStage3Waypoint(pPlayer)
	else
		self:removeQuestGiverWaypoint(pPlayer)
		self:addStageWaypoint(pPlayer, stage)
	end
end

-- ============================================================================
-- Generic encounter bookkeeping
-- ============================================================================

function RangersPath:getEncounterMobKey(index)
	return "encounter_mob_id_" .. tostring(index)
end

function RangersPath:getSettlerMobKey(index)
	return "settler_mob_id_" .. tostring(index)
end

function RangersPath:clearEncounterMobKeys(pPlayer)
	for i = 1, self.MAX_ENCOUNTER_MOBS, 1 do
		self:setNumber(pPlayer, self:getEncounterMobKey(i), 0)
	end
end

function RangersPath:clearSettlerMobKeys(pPlayer)
	for i = 1, self.MAX_SETTLER_MOBS, 1 do
		self:setNumber(pPlayer, self:getSettlerMobKey(i), 0)
	end
end

function RangersPath:getEncounterAreaId(pPlayer)
	return self:getNumber(pPlayer, "encounter_area_id")
end

function RangersPath:setEncounterAreaId(pPlayer, areaId)
	self:setNumber(pPlayer, "encounter_area_id", areaId)
end

function RangersPath:getEncounterAuxAreaId(pPlayer)
	return self:getNumber(pPlayer, "encounter_aux_area_id")
end

function RangersPath:setEncounterAuxAreaId(pPlayer, areaId)
	self:setNumber(pPlayer, "encounter_aux_area_id", areaId)
end

function RangersPath:getEncounterObjectId(pPlayer)
	return self:getNumber(pPlayer, "encounter_object_id")
end

function RangersPath:setEncounterObjectId(pPlayer, objectId)
	self:setNumber(pPlayer, "encounter_object_id", objectId)
end

function RangersPath:getEncounterCount(pPlayer)
	return self:getNumber(pPlayer, "encounter_count")
end

function RangersPath:setEncounterCount(pPlayer, count)
	self:setNumber(pPlayer, "encounter_count", count)
end

function RangersPath:getEncounterRemaining(pPlayer)
	return self:getNumber(pPlayer, "encounter_remaining")
end

function RangersPath:setEncounterRemaining(pPlayer, remaining)
	self:setNumber(pPlayer, "encounter_remaining", remaining)
end

function RangersPath:getEncounterType(pPlayer)
	return self:getString(pPlayer, "encounter_type")
end

function RangersPath:setEncounterType(pPlayer, encounterType)
	self:setString(pPlayer, "encounter_type", encounterType)
end

function RangersPath:isEncounterActive(pPlayer)
	return self:getNumber(pPlayer, "active_encounter") == 1
end

function RangersPath:setEncounterActive(pPlayer, value)
	self:setNumber(pPlayer, "active_encounter", value)
end

function RangersPath:getEncounterStage(pPlayer)
	return self:getNumber(pPlayer, "encounter_stage")
end

function RangersPath:setEncounterStage(pPlayer, stage)
	self:setNumber(pPlayer, "encounter_stage", stage)
end

function RangersPath:getEncounterSerial(pPlayer)
	return self:getNumber(pPlayer, "encounter_serial")
end

function RangersPath:bumpEncounterSerial(pPlayer)
	local nextSerial = self:getEncounterSerial(pPlayer) + 1
	self:setNumber(pPlayer, "encounter_serial", nextSerial)
	return nextSerial
end

function RangersPath:scheduleEncounterTimeout(pPlayer)
	local serial = self:getEncounterSerial(pPlayer)
	createEvent(self.ENCOUNTER_TIMEOUT_MS, "RangersPath", "handleEncounterTimeout", pPlayer, tostring(serial))
end

function RangersPath:handleEncounterTimeout(pPlayer, eventData)
	if (pPlayer == nil) then
		return 0
	end

	local serial = tonumber(eventData) or 0

	if (serial == 0 or serial ~= self:getEncounterSerial(pPlayer)) then
		return 0
	end

	if (self:isRewardPending(pPlayer) or self:isCompleted(pPlayer)) then
		return 0
	end

	local stage = self:getStage(pPlayer)

	CreatureObject(pPlayer):sendSystemMessage("The encounter has reset.")
	self:resetEncounter(pPlayer)
	self:setupStageObjectives(pPlayer, stage, false)
	return 0
end

-- ============================================================================
-- Generic object / area cleanup helpers
-- ============================================================================

function RangersPath:destroyActiveAreaById(areaId)
	if (areaId == nil or areaId == 0) then
		return
	end

	local pArea = getSceneObject(areaId)

	if (pArea ~= nil) then
		SceneObject(pArea):destroyObjectFromWorld()
	end
end

function RangersPath:destroyEncounterAreas(pPlayer)
	local areaId = self:getEncounterAreaId(pPlayer)
	local auxAreaId = self:getEncounterAuxAreaId(pPlayer)

	if (areaId ~= nil and areaId ~= 0) then
		deleteData(areaId .. ":RangersPath:ownerID")
		deleteData(areaId .. ":RangersPath:stage")
		deleteData(areaId .. ":RangersPath:type")
		deleteData(areaId .. ":RangersPath:step")
		self:destroyActiveAreaById(areaId)
	end

	if (auxAreaId ~= nil and auxAreaId ~= 0) then
		deleteData(auxAreaId .. ":RangersPath:ownerID")
		deleteData(auxAreaId .. ":RangersPath:stage")
		deleteData(auxAreaId .. ":RangersPath:type")
		deleteData(auxAreaId .. ":RangersPath:step")
		self:destroyActiveAreaById(auxAreaId)
	end

	self:setEncounterAreaId(pPlayer, 0)
	self:setEncounterAuxAreaId(pPlayer, 0)
end

function RangersPath:destroyEncounterObject(pPlayer)
	local objectId = self:getEncounterObjectId(pPlayer)

	if (objectId ~= nil and objectId ~= 0) then
		local pObject = getSceneObject(objectId)

		deleteData(objectId .. ":RangersPath:ownerID")
		deleteData(objectId .. ":RangersPath:stage")
		deleteData(objectId .. ":RangersPath:type")

		if (pObject ~= nil) then
			pcall(function()
				SceneObject(pObject):destroyObjectFromWorld()
			end)
			pcall(function()
				SceneObject(pObject):destroyObjectFromDatabase()
			end)
		end
	end

	self:setEncounterObjectId(pPlayer, 0)
end

function RangersPath:despawnEncounterMobiles(pPlayer)
	for i = 1, self.MAX_ENCOUNTER_MOBS, 1 do
		local mobId = self:getNumber(pPlayer, self:getEncounterMobKey(i))

		if (mobId ~= nil and mobId ~= 0) then
			local pMobile = getSceneObject(mobId)

			deleteData(mobId .. ":RangersPath:ownerID")
			deleteData(mobId .. ":RangersPath:stage")
			deleteData(mobId .. ":RangersPath:type")
			deleteData(mobId .. ":RangersPath:index")

			if (pMobile ~= nil) then
				pcall(function()
					SceneObject(pMobile):destroyObjectFromWorld()
				end)
				pcall(function()
					SceneObject(pMobile):destroyObjectFromDatabase()
				end)
			end
		end
	end

	self:clearEncounterMobKeys(pPlayer)
	self:setEncounterCount(pPlayer, 0)
	self:setEncounterRemaining(pPlayer, 0)
end

function RangersPath:despawnSettlers(pPlayer)
	for i = 1, self.MAX_SETTLER_MOBS, 1 do
		local mobId = self:getNumber(pPlayer, self:getSettlerMobKey(i))

		if (mobId ~= nil and mobId ~= 0) then
			local pMobile = getSceneObject(mobId)

			deleteData(mobId .. ":RangersPath:ownerID")
			deleteData(mobId .. ":RangersPath:stage")
			deleteData(mobId .. ":RangersPath:type")
			deleteData(mobId .. ":RangersPath:required")

			if (pMobile ~= nil) then
				pcall(function()
					SceneObject(pMobile):destroyObjectFromWorld()
				end)
				pcall(function()
					SceneObject(pMobile):destroyObjectFromDatabase()
				end)
			end
		end
	end

	self:clearSettlerMobKeys(pPlayer)
	self:setNumber(pPlayer, "stage5_required_settlers_alive", 0)
	self:setNumber(pPlayer, "stage5_total_settlers", 0)
end

function RangersPath:resetEncounter(pPlayer)
	if (pPlayer == nil) then
		return
	end

	dropObserver(KILLEDCREATURE, "RangersPath", "notifyKilledRangerHuntTarget", pPlayer)
	dropObserver(KILLEDCREATURE, "RangersPath", "notifyKilledStage2Ambusher", pPlayer)
	self:destroyEncounterAreas(pPlayer)
	self:destroyEncounterObject(pPlayer)
	self:despawnEncounterMobiles(pPlayer)
	self:despawnSettlers(pPlayer)
	self:setEncounterType(pPlayer, "")
	self:setEncounterActive(pPlayer, 0)
	self:setEncounterStage(pPlayer, 0)
end

-- ============================================================================
-- Stage-specific persistent state helpers
-- ============================================================================

function RangersPath:resetStage2State(pPlayer)
	self:setNumber(pPlayer, "stage2_crate_used", 0)
	self:setNumber(pPlayer, "stage2_kill_count", 0)
	self:setEncounterRemaining(pPlayer, 0)
end

function RangersPath:getStage3TrailStep(pPlayer)
	local step = self:getNumber(pPlayer, "stage3_trail_step")
	if (step < 1) then
		return 1
	end
	return step
end

function RangersPath:setStage3TrailStep(pPlayer, step)
	if (step < 1) then
		step = 1
	end
	self:setNumber(pPlayer, "stage3_trail_step", step)
end

function RangersPath:resetStage3State(pPlayer)
	self:setNumber(pPlayer, "stage3_trail_step", 1)
	self:setNumber(pPlayer, "stage3_site_reached", 0)
	self:setNumber(pPlayer, "stage3_datapad_retrieved", 0)
	self:setEncounterRemaining(pPlayer, 0)
end

function RangersPath:resetStage5State(pPlayer)
	self:setNumber(pPlayer, "stage5_defense_started", 0)
	self:setNumber(pPlayer, "stage5_wave", 0)
	self:setNumber(pPlayer, "stage5_reset_pending", 0)
	self:setNumber(pPlayer, "stage5_required_settlers_alive", 0)
	self:setNumber(pPlayer, "stage5_total_settlers", 0)
end

-- ============================================================================
-- Hunt helpers for Stage 1 / 4 / 6
-- ============================================================================

function RangersPath:getRandomOffset(radius)
	if (radius == nil or radius <= 0) then
		return 0
	end

	return math.random(-radius, radius)
end

function RangersPath:getHuntSpawnPoint(stage)
	local data = self:getStageData(stage)

	if (data == nil or data.hunt == nil) then
		return nil
	end

	local hunt = data.hunt
	local x = hunt.spawnX
	local y = hunt.spawnY

	if (hunt.roamRadius ~= nil and hunt.roamRadius > 0) then
		x = x + self:getRandomOffset(hunt.roamRadius)
		y = y + self:getRandomOffset(hunt.roamRadius)
	end

	return {
		x = x,
		z = hunt.spawnZ,
		y = y,
		heading = hunt.spawnHeading or 0,
	}
end

function RangersPath:setupHuntKillObserver(pPlayer)
	if (pPlayer == nil) then
		return
	end

	dropObserver(KILLEDCREATURE, "RangersPath", "notifyKilledRangerHuntTarget", pPlayer)
	createObserver(KILLEDCREATURE, "RangersPath", "notifyKilledRangerHuntTarget", pPlayer)
end

function RangersPath:createHuntTriggerArea(pPlayer, stage)
	local stageData = self:getStageData(stage)

	if (stageData == nil or stageData.hunt == nil or stageData.hunt.enabled ~= true) then
		return 0
	end

	local hunt = stageData.hunt
	local pArea = spawnActiveArea(stageData.planet, "object/active_area.iff", stageData.x, stageData.z, stageData.y, hunt.regionRadius, 0)

	if (pArea == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Failed to create the hunt region. Please contact staff.")
		return 0
	end

	local areaId = SceneObject(pArea):getObjectID()
	writeData(areaId .. ":RangersPath:ownerID", self:getPlayerId(pPlayer))
	writeData(areaId .. ":RangersPath:stage", stage)
	writeData(areaId .. ":RangersPath:type", "hunt_trigger")

	createObserver(ENTEREDAREA, "RangersPath", "notifyEnteredEncounterArea", pArea)

	self:setEncounterAreaId(pPlayer, areaId)
	self:setEncounterType(pPlayer, "hunt_trigger")
	self:setEncounterActive(pPlayer, 1)
	self:setEncounterStage(pPlayer, stage)
	self:bumpEncounterSerial(pPlayer)
	self:scheduleEncounterTimeout(pPlayer)
	self:scheduleHuntTriggerCheck(pPlayer)
	return areaId
end

function RangersPath:scheduleHuntTriggerCheck(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local serial = self:getEncounterSerial(pPlayer)
	createEvent(2000, "RangersPath", "checkHuntTriggerProgress", pPlayer, tostring(serial))
end

function RangersPath:checkHuntTriggerProgress(pPlayer, eventData)
	if (pPlayer == nil) then
		return 0
	end

	local serial = tonumber(eventData) or 0

	if (serial == 0 or serial ~= self:getEncounterSerial(pPlayer)) then
		return 0
	end

	local stage = self:getStage(pPlayer)

	if (not self:isStageActive(pPlayer, stage) or self:isStageReady(pPlayer, stage)) then
		return 0
	end

	if (self:getEncounterType(pPlayer) ~= "hunt_trigger") then
		return 0
	end

	local stageData = self:getStageData(stage)

	if (stageData == nil or stageData.hunt == nil or stageData.hunt.enabled ~= true) then
		return 0
	end

	local px = SceneObject(pPlayer):getWorldPositionX()
	local py = SceneObject(pPlayer):getWorldPositionY()
	local dx = px - stageData.x
	local dy = py - stageData.y
	local dist = math.sqrt(dx * dx + dy * dy)

	if (dist <= stageData.hunt.regionRadius) then
		self:destroyEncounterAreas(pPlayer)
		self:spawnHuntTarget(pPlayer, stage)
		return 0
	end

	self:scheduleHuntTriggerCheck(pPlayer)
	return 0
end

function RangersPath:spawnHuntTarget(pPlayer, stage)
	local stageData = self:getStageData(stage)

	if (stageData == nil or stageData.hunt == nil or stageData.hunt.enabled ~= true) then
		return nil
	end

	local hunt = stageData.hunt
	local spawnPoint = self:getHuntSpawnPoint(stage)

	if (spawnPoint == nil) then
		return nil
	end

	local pTarget = spawnMobile(
		stageData.planet,
		hunt.targetTemplate,
		0,
		spawnPoint.x,
		spawnPoint.z,
		spawnPoint.y,
		spawnPoint.heading,
		0
	)

	if (pTarget == nil) then
		CreatureObject(pPlayer):sendSystemMessage("The hunt target failed to appear. Please contact staff.")
		return nil
	end

	local targetId = SceneObject(pTarget):getObjectID()

	SceneObject(pTarget):setCustomObjectName(hunt.targetName)
	writeData(targetId .. ":RangersPath:ownerID", self:getPlayerId(pPlayer))
	writeData(targetId .. ":RangersPath:stage", stage)
	writeData(targetId .. ":RangersPath:type", "hunt_target")
	writeData(targetId .. ":RangersPath:index", 1)
	createObserver(OBJECTDESTRUCTION, "RangersPath", "notifyEncounterMobileKilled", pTarget)

	self:setNumber(pPlayer, self:getEncounterMobKey(1), targetId)
	self:setEncounterCount(pPlayer, 1)
	self:setEncounterRemaining(pPlayer, 1)
	self:setEncounterType(pPlayer, "hunt_target")
	self:setEncounterActive(pPlayer, 1)
	self:setEncounterStage(pPlayer, stage)
	self:setupHuntKillObserver(pPlayer)
	self:bumpEncounterSerial(pPlayer)
	self:scheduleEncounterTimeout(pPlayer)

	if (hunt.elite == true) then
		-- TODO: Add elite combat setup hooks here if you wire custom AI behavior,
		-- damage modifiers, or special ability scripting for Ancient Shadowclaw.
	end

	CreatureObject(pPlayer):sendSystemMessage(hunt.huntMessage or "Your quarry has revealed itself. Finish the hunt.")
	return pTarget
end

function RangersPath:completeHuntObjective(pPlayer, stage)
	if (pPlayer == nil or not self:isStageActive(pPlayer, stage) or self:isStageReady(pPlayer, stage)) then
		return false
	end

	local hunt = self:getStageData(stage).hunt

	self:setStageReady(pPlayer, stage, 1)
	self:removeStageWaypoint(pPlayer)
	self:addQuestGiverWaypoint(pPlayer, "Return to Talren Voss and report your success.")
	self:setEncounterActive(pPlayer, 0)
	self:setEncounterStage(pPlayer, 0)
	self:setEncounterType(pPlayer, "")
	self:clearEncounterMobKeys(pPlayer)
	self:setEncounterCount(pPlayer, 0)
	self:setEncounterRemaining(pPlayer, 0)
	dropObserver(KILLEDCREATURE, "RangersPath", "notifyKilledRangerHuntTarget", pPlayer)

	CreatureObject(pPlayer):sendSystemMessage(hunt.completeMessage or "Your quarry has fallen. Return to Talren Voss.")
	return true
end

function RangersPath:notifyKilledRangerHuntTarget(pPlayer, pVictim)
	if (pPlayer == nil or pVictim == nil) then
		return 0
	end

	local stage = self:getStage(pPlayer)

	if (stage ~= 1 and stage ~= 4 and stage ~= 6) then
		return 0
	end

	if (not self:isStageActive(pPlayer, stage) or self:isStageReady(pPlayer, stage)) then
		return 0
	end

	local victimId = SceneObject(pVictim):getObjectID()
	local targetId = self:getNumber(pPlayer, self:getEncounterMobKey(1))

	if (targetId == 0 or victimId ~= targetId) then
		return 0
	end

	if (SceneObject(pVictim):getZoneName() ~= SceneObject(pPlayer):getZoneName()) then
		return 0
	end

	self:completeHuntObjective(pPlayer, stage)
	return 1
end

-- ============================================================================
-- Stage 2 helpers
-- ============================================================================

function RangersPath:spawnStage2CampObject(pPlayer)
	local stageData = self:getStageData(2)
	local camp = stageData.camp

	local pObject = spawnSceneObject(stageData.planet, camp.crateTemplate, camp.crateX, camp.crateZ, camp.crateY, 0, 1, 0, 0)

	if (pObject == nil) then
		if (self.DEBUG_STAGE2 and pPlayer ~= nil) then
			CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 2: supply cache spawn returned nil at " .. tostring(camp.crateX) .. ", " .. tostring(camp.crateY) .. ".")
		end
		return nil
	end

	SceneObject(pObject):setCustomObjectName(camp.crateName)
	writeData(SceneObject(pObject):getObjectID() .. ":RangersPath:ownerID", self:getPlayerId(pPlayer))
	writeData(SceneObject(pObject):getObjectID() .. ":RangersPath:stage", 2)
	writeData(SceneObject(pObject):getObjectID() .. ":RangersPath:type", "stage2_crate")
	self:setEncounterObjectId(pPlayer, SceneObject(pObject):getObjectID())

	if (self.DEBUG_STAGE2 and pPlayer ~= nil) then
		CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 2: supply cache spawned successfully.")
	end

	return pObject
end

function RangersPath:createStage2CrateArea(pPlayer)
	local stageData = self:getStageData(2)
	local camp = stageData.camp

	local pObject = self:spawnStage2CampObject(pPlayer)

	local pArea = spawnActiveArea(stageData.planet, "object/active_area.iff", camp.crateX, camp.crateZ, camp.crateY, camp.interactionRadius, 0)

	if (pArea == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Failed to create the camp interaction.")
		return 0
	end

	local areaId = SceneObject(pArea):getObjectID()
	writeData(areaId .. ":RangersPath:ownerID", self:getPlayerId(pPlayer))
	writeData(areaId .. ":RangersPath:stage", 2)
	writeData(areaId .. ":RangersPath:type", "stage2_crate_area")

	createObserver(ENTEREDAREA, "RangersPath", "notifyEnteredEncounterArea", pArea)

	self:setEncounterAreaId(pPlayer, areaId)
	self:setEncounterType(pPlayer, "stage2_crate_area")
	self:setEncounterActive(pPlayer, 1)
	self:setEncounterStage(pPlayer, 2)
	self:bumpEncounterSerial(pPlayer)
	self:scheduleEncounterTimeout(pPlayer)
	self:scheduleStage2TriggerCheck(pPlayer)

	if (self.DEBUG_STAGE2) then
		CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 2: crate trigger area created at " .. tostring(camp.crateX) .. ", " .. tostring(camp.crateY) .. " radius " .. tostring(camp.interactionRadius) .. ".")
	end

	local pFallbackArea = spawnActiveArea(stageData.planet, "object/active_area.iff", stageData.x, stageData.z, stageData.y, 28, 0)

	if (pFallbackArea ~= nil) then
		local fallbackId = SceneObject(pFallbackArea):getObjectID()
		writeData(fallbackId .. ":RangersPath:ownerID", self:getPlayerId(pPlayer))
		writeData(fallbackId .. ":RangersPath:stage", 2)
		writeData(fallbackId .. ":RangersPath:type", "stage2_camp_area")
		createObserver(ENTEREDAREA, "RangersPath", "notifyEnteredEncounterArea", pFallbackArea)
		self:setEncounterAuxAreaId(pPlayer, fallbackId)

		if (self.DEBUG_STAGE2) then
			CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 2: fallback camp area created at " .. tostring(stageData.x) .. ", " .. tostring(stageData.y) .. " radius 28.")
		end
	elseif (self.DEBUG_STAGE2) then
		CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 2: fallback camp area creation failed.")
	end

	return areaId
end

function RangersPath:chooseRandomAmbushTemplate(stage)
	local stageData = self:getStageData(stage)
	local camp = stageData.camp
	local templates = camp.ambushTemplates
	local idx = math.random(1, #templates)
	return templates[idx]
end

function RangersPath:setupStage2KillObserver(pPlayer)
	if (pPlayer == nil) then
		return
	end

	dropObserver(KILLEDCREATURE, "RangersPath", "notifyKilledStage2Ambusher", pPlayer)
	createObserver(KILLEDCREATURE, "RangersPath", "notifyKilledStage2Ambusher", pPlayer)
end

function RangersPath:scheduleStage2ProgressCheck(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local serial = self:getEncounterSerial(pPlayer)
	createEvent(2000, "RangersPath", "checkStage2AmbushStatus", pPlayer, tostring(serial))
end

function RangersPath:scheduleStage2TriggerCheck(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local serial = self:getEncounterSerial(pPlayer)
	createEvent(2000, "RangersPath", "checkStage2TriggerProgress", pPlayer, tostring(serial))
end

function RangersPath:checkStage2TriggerProgress(pPlayer, eventData)
	if (pPlayer == nil) then
		return 0
	end

	local serial = tonumber(eventData) or 0

	if (serial == 0 or serial ~= self:getEncounterSerial(pPlayer)) then
		return 0
	end

	if (self:getStage(pPlayer) ~= 2 or not self:isStageActive(pPlayer, 2) or self:isStageReady(pPlayer, 2)) then
		return 0
	end

	if (self:getNumber(pPlayer, "stage2_crate_used") == 1) then
		return 0
	end

	local stageData = self:getStageData(2)
	local px = SceneObject(pPlayer):getWorldPositionX()
	local py = SceneObject(pPlayer):getWorldPositionY()
	local dx = px - stageData.x
	local dy = py - stageData.y
	local dist = math.sqrt(dx * dx + dy * dy)

	if (dist <= stageData.camp.interactionRadius + 20) then
		self:spawnStage2Ambush(pPlayer)
		return 0
	end

	self:scheduleStage2TriggerCheck(pPlayer)
	return 0
end

function RangersPath:spawnStage2Ambush(pPlayer)
	local stageData = self:getStageData(2)
	local camp = stageData.camp
	local count = math.random(camp.ambushMin, camp.ambushMax)
	local spawnedCount = 0

	if (self.DEBUG_STAGE2 and pPlayer ~= nil) then
		CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 2: spawning ambush with " .. tostring(count) .. " attackers at fixed camp positions.")
	end

	self:destroyEncounterAreas(pPlayer)
	self:destroyEncounterObject(pPlayer)
	self:despawnEncounterMobiles(pPlayer)

	for i = 1, count, 1 do
		local spawn = camp.ambushSpawnPoints[i]
		local template = self:chooseRandomAmbushTemplate(2)
		local pMobile = spawnMobile(stageData.planet, template, 0, spawn.x, spawn.z, spawn.y, spawn.heading or 0, 0)

		if (pMobile ~= nil) then
			local mobId = SceneObject(pMobile):getObjectID()
			writeData(mobId .. ":RangersPath:ownerID", self:getPlayerId(pPlayer))
			writeData(mobId .. ":RangersPath:stage", 2)
			writeData(mobId .. ":RangersPath:type", "stage2_ambusher")
			writeData(mobId .. ":RangersPath:index", i)
			createObserver(OBJECTDESTRUCTION, "RangersPath", "notifyEncounterMobileKilled", pMobile)
			self:setNumber(pPlayer, self:getEncounterMobKey(i), mobId)
			spawnedCount = spawnedCount + 1
			if (self.DEBUG_STAGE2 and pPlayer ~= nil) then
				CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 2: ambusher " .. tostring(i) .. " spawned as " .. template .. ".")
			end
		elseif (self.DEBUG_STAGE2 and pPlayer ~= nil) then
			CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 2: failed to spawn ambusher " .. tostring(i) .. " as " .. template .. ".")
		end
	end

	self:setEncounterCount(pPlayer, spawnedCount)
	self:setEncounterRemaining(pPlayer, spawnedCount)
	self:setNumber(pPlayer, "stage2_kill_count", 0)
	self:setEncounterType(pPlayer, "stage2_ambush")
	self:setEncounterActive(pPlayer, 1)
	self:setEncounterStage(pPlayer, 2)
	self:setNumber(pPlayer, "stage2_crate_used", 1)
	self:setupStage2KillObserver(pPlayer)
	self:bumpEncounterSerial(pPlayer)
	self:scheduleEncounterTimeout(pPlayer)
	self:scheduleStage2ProgressCheck(pPlayer)

	if (self.DEBUG_STAGE2 and pPlayer ~= nil) then
		CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 2: " .. tostring(spawnedCount) .. " ambushers successfully spawned.")
	end

	if (spawnedCount <= 0) then
		CreatureObject(pPlayer):sendSystemMessage("No ambushers could be spawned. Stage 2 cannot progress.")
		return
	end

	CreatureObject(pPlayer):sendSystemMessage("The cache was bait. Predators are closing in.")
end

function RangersPath:completeStage2Objective(pPlayer)
	dropObserver(KILLEDCREATURE, "RangersPath", "notifyKilledStage2Ambusher", pPlayer)
	self:setStageReady(pPlayer, 2, 1)
	self:removeStageWaypoint(pPlayer)
	self:addQuestGiverWaypoint(pPlayer, "Return to Talren Voss and report your survival.")
	CreatureObject(pPlayer):sendSystemMessage("You survived the ambush. Return to Talren Voss.")
end

function RangersPath:countStage2AmbusherKill(pPlayer, victimId, sourceLabel, validatedByObserver)
	if (pPlayer == nil or victimId == nil or victimId == 0) then
		return false
	end

	if (self:getStage(pPlayer) ~= 2 or not self:isStageActive(pPlayer, 2) or self:isStageReady(pPlayer, 2)) then
		return false
	end

	if (tonumber(readData(victimId .. ":RangersPath:stage2KillCounted")) == 1) then
		return false
	end

	local matched = validatedByObserver == true

	for i = 1, self.MAX_ENCOUNTER_MOBS, 1 do
		if (self:getNumber(pPlayer, self:getEncounterMobKey(i)) == victimId) then
			self:setNumber(pPlayer, self:getEncounterMobKey(i), 0)
			matched = true
			break
		end
	end

	if (not matched and validatedByObserver ~= true) then
		local ownerId = tonumber(readData(victimId .. ":RangersPath:ownerID")) or 0
		local stage = tonumber(readData(victimId .. ":RangersPath:stage")) or 0
		local encounterType = tostring(readData(victimId .. ":RangersPath:type") or "")

		if (ownerId == self:getPlayerId(pPlayer) and stage == 2 and encounterType == "stage2_ambusher") then
			matched = true
		end
	end

	if (not matched) then
		return false
	end

	writeData(victimId .. ":RangersPath:stage2KillCounted", 1)

	local killCount = self:getNumber(pPlayer, "stage2_kill_count") + 1
	local totalCount = self:getEncounterCount(pPlayer)
	local remaining = totalCount - killCount
	if (remaining < 0) then
		remaining = 0
	end

	self:setNumber(pPlayer, "stage2_kill_count", killCount)
	self:setEncounterRemaining(pPlayer, remaining)

	if (self.DEBUG_STAGE2) then
		CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 2: " .. sourceLabel .. " counted a kill, " .. tostring(killCount) .. "/" .. tostring(totalCount) .. " defeated, " .. tostring(remaining) .. " remaining.")
	end

	if (totalCount > 0 and killCount >= totalCount) then
		self:despawnEncounterMobiles(pPlayer)
		self:setEncounterActive(pPlayer, 0)
		self:setEncounterStage(pPlayer, 0)
		self:setEncounterType(pPlayer, "")
		self:completeStage2Objective(pPlayer)
	end

	return true
end

function RangersPath:notifyKilledStage2Ambusher(pPlayer, pVictim)
	if (pPlayer == nil or pVictim == nil) then
		return 0
	end

	local victimId = SceneObject(pVictim):getObjectID()
	return self:countStage2AmbusherKill(pPlayer, victimId, "player kill observer", false) and 1 or 0
end

function RangersPath:checkStage2AmbushStatus(pPlayer, eventData)
	if (pPlayer == nil) then
		return 0
	end

	local serial = tonumber(eventData) or 0

	if (serial == 0 or serial ~= self:getEncounterSerial(pPlayer)) then
		return 0
	end

	if (self:getStage(pPlayer) ~= 2 or not self:isStageActive(pPlayer, 2) or self:isStageReady(pPlayer, 2)) then
		return 0
	end

	local livingCount = 0

	for i = 1, self.MAX_ENCOUNTER_MOBS, 1 do
		local mobId = self:getNumber(pPlayer, self:getEncounterMobKey(i))

		if (mobId ~= nil and mobId ~= 0) then
			local pMobile = getSceneObject(mobId)

			if (pMobile ~= nil and not CreatureObject(pMobile):isDead()) then
				livingCount = livingCount + 1
			else
				self:setNumber(pPlayer, self:getEncounterMobKey(i), 0)
			end
		end
	end

	self:setEncounterRemaining(pPlayer, livingCount)

	if (self.DEBUG_STAGE2) then
		CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 2: progress check sees " .. tostring(livingCount) .. " ambushers still alive.")
	end

	if (livingCount <= 0) then
		self:despawnEncounterMobiles(pPlayer)
		self:setEncounterActive(pPlayer, 0)
		self:setEncounterStage(pPlayer, 0)
		self:setEncounterType(pPlayer, "")
		self:completeStage2Objective(pPlayer)
		return 0
	end

	self:scheduleStage2ProgressCheck(pPlayer)
	return 0
end

-- ============================================================================
-- Stage 3 helpers
-- ============================================================================

function RangersPath:getStage3TrailCount()
	local stageData = self:getStageData(3)
	return #stageData.investigation.trailPoints
end

function RangersPath:spawnStage3TrailMarkerObject(pPlayer, point)
	local stageData = self:getStageData(3)

	if (point == nil) then
		return nil
	end

	self:destroyEncounterObject(pPlayer)

	local pObject = spawnSceneObject(stageData.planet, "object/tangible/camp/camp_lantern_s3.iff", point.x, point.z, point.y, 0, 1, 0, 0)

	if (pObject == nil) then
		if (self.DEBUG_STAGE3 and pPlayer ~= nil) then
			CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 3: trail marker object failed to spawn at " .. tostring(point.x) .. ", " .. tostring(point.y) .. ".")
		end
		return nil
	end

	SceneObject(pObject):setCustomObjectName(point.name)
	writeData(SceneObject(pObject):getObjectID() .. ":RangersPath:ownerID", self:getPlayerId(pPlayer))
	writeData(SceneObject(pObject):getObjectID() .. ":RangersPath:stage", 3)
	writeData(SceneObject(pObject):getObjectID() .. ":RangersPath:type", "stage3_trail_marker")
	self:setEncounterObjectId(pPlayer, SceneObject(pObject):getObjectID())

	if (self.DEBUG_STAGE3 and pPlayer ~= nil) then
		CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 3: trail marker object spawned for " .. point.name .. ".")
	end

	return pObject
end

function RangersPath:createStage3TrailArea(pPlayer)
	local stageData = self:getStageData(3)
	local info = stageData.investigation
	local step = self:getStage3TrailStep(pPlayer)
	local point = info.trailPoints[step]

	if (point == nil) then
		return 0
	end

	if (self.DEBUG_STAGE3) then
		CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 3: creating trail step " .. tostring(step) .. " at " .. tostring(point.x) .. ", " .. tostring(point.y) .. ".")
	end

	self:refreshStage3Waypoint(pPlayer)
	self:spawnStage3TrailMarkerObject(pPlayer, point)

	local pArea = spawnActiveArea(stageData.planet, "object/active_area.iff", point.x, point.z, point.y, info.trailRadius, 0)

	if (pArea == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Failed to create the trail marker.")
		if (self.DEBUG_STAGE3) then
			CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 3: trail active area creation failed.")
		end
		return 0
	end

	local areaId = SceneObject(pArea):getObjectID()
	writeData(areaId .. ":RangersPath:ownerID", self:getPlayerId(pPlayer))
	writeData(areaId .. ":RangersPath:stage", 3)
	writeData(areaId .. ":RangersPath:type", "stage3_trail")
	writeData(areaId .. ":RangersPath:step", step)

	createObserver(ENTEREDAREA, "RangersPath", "notifyEnteredEncounterArea", pArea)

	self:setEncounterAreaId(pPlayer, areaId)
	self:setEncounterType(pPlayer, "stage3_trail")
	self:setEncounterActive(pPlayer, 1)
	self:setEncounterStage(pPlayer, 3)
	self:bumpEncounterSerial(pPlayer)
	self:scheduleEncounterTimeout(pPlayer)
	self:scheduleStage3TrailCheck(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("Stage 3 trail marker placed at " .. tostring(point.x) .. ", " .. tostring(point.y) .. ".")
	if (self.DEBUG_STAGE3) then
		CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 3: trail active area created successfully.")
	end
	return areaId
end

function RangersPath:scheduleStage3TrailCheck(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local serial = self:getEncounterSerial(pPlayer)
	createEvent(2000, "RangersPath", "checkStage3TrailProgress", pPlayer, tostring(serial))
end

function RangersPath:checkStage3TrailProgress(pPlayer, eventData)
	if (pPlayer == nil) then
		return 0
	end

	local serial = tonumber(eventData) or 0

	if (serial == 0 or serial ~= self:getEncounterSerial(pPlayer)) then
		return 0
	end

	if (self:getStage(pPlayer) ~= 3 or not self:isStageActive(pPlayer, 3) or self:isStageReady(pPlayer, 3)) then
		return 0
	end

	if (self:getNumber(pPlayer, "stage3_site_reached") == 1) then
		return 0
	end

	local stageData = self:getStageData(3)
	local info = stageData.investigation
	local step = self:getStage3TrailStep(pPlayer)
	local point = info.trailPoints[step]

	if (point == nil) then
		return 0
	end

	local px = SceneObject(pPlayer):getWorldPositionX()
	local py = SceneObject(pPlayer):getWorldPositionY()
	local dx = px - point.x
	local dy = py - point.y
	local dist = math.sqrt(dx * dx + dy * dy)

	if (self.DEBUG_STAGE3) then
		CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 3: proximity check step " .. tostring(step) .. " dist=" .. tostring(math.floor(dist)) .. " radius=" .. tostring(info.trailRadius) .. ".")
	end

	if (dist <= info.trailRadius) then
		if (self.DEBUG_STAGE3) then
			CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 3: proximity check triggered trail step " .. tostring(step) .. ".")
		end

		self:destroyEncounterAreas(pPlayer)

		if (step < self:getStage3TrailCount()) then
			self:setStage3TrailStep(pPlayer, step + 1)
			self:createStage3TrailArea(pPlayer)
			CreatureObject(pPlayer):sendSystemMessage("You find more signs ahead. Continue following the trail.")
		else
			self:spawnStage3FinalSite(pPlayer)
		end

		return 0
	end

	self:scheduleStage3TrailCheck(pPlayer)
	return 0
end

function RangersPath:spawnStage3RemainsObject(pPlayer)
	local stageData = self:getStageData(3)
	local info = stageData.investigation

	local pObject = spawnSceneObject(stageData.planet, info.remainsTemplate, info.remainsX, info.remainsZ, info.remainsY, 0, 1, 0, 0)

	if (pObject == nil) then
		return nil
	end

	SceneObject(pObject):setCustomObjectName(info.remainsName)
	writeData(SceneObject(pObject):getObjectID() .. ":RangersPath:ownerID", self:getPlayerId(pPlayer))
	writeData(SceneObject(pObject):getObjectID() .. ":RangersPath:stage", 3)
	writeData(SceneObject(pObject):getObjectID() .. ":RangersPath:type", "stage3_remains")
	self:setEncounterObjectId(pPlayer, SceneObject(pObject):getObjectID())
	return pObject
end

function RangersPath:createStage3RemainsArea(pPlayer)
	local stageData = self:getStageData(3)
	local info = stageData.investigation

	self:spawnStage3RemainsObject(pPlayer)

	local pArea = spawnActiveArea(stageData.planet, "object/active_area.iff", info.remainsX, info.remainsZ, info.remainsY, info.remainsRadius, 0)

	if (pArea == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Failed to create the remains interaction area.")
		return 0
	end

	local areaId = SceneObject(pArea):getObjectID()
	writeData(areaId .. ":RangersPath:ownerID", self:getPlayerId(pPlayer))
	writeData(areaId .. ":RangersPath:stage", 3)
	writeData(areaId .. ":RangersPath:type", "stage3_remains_area")

	createObserver(ENTEREDAREA, "RangersPath", "notifyEnteredEncounterArea", pArea)
	self:setEncounterAuxAreaId(pPlayer, areaId)
	return areaId
end

function RangersPath:spawnStage3Guards(pPlayer)
	local stageData = self:getStageData(3)
	local guards = stageData.investigation.guards
	local count = #guards

	self:despawnEncounterMobiles(pPlayer)

	for i = 1, count, 1 do
		local spawn = guards[i]
		local pMobile = spawnMobile(stageData.planet, spawn.template, 0, spawn.x, spawn.z, spawn.y, spawn.heading or 0, 0)

		if (pMobile ~= nil) then
			local mobId = SceneObject(pMobile):getObjectID()
			writeData(mobId .. ":RangersPath:ownerID", self:getPlayerId(pPlayer))
			writeData(mobId .. ":RangersPath:stage", 3)
			writeData(mobId .. ":RangersPath:type", "stage3_guard")
			writeData(mobId .. ":RangersPath:index", i)
			createObserver(OBJECTDESTRUCTION, "RangersPath", "notifyEncounterMobileKilled", pMobile)
			self:setNumber(pPlayer, self:getEncounterMobKey(i), mobId)
		end
	end

	self:setEncounterCount(pPlayer, count)
	self:setEncounterRemaining(pPlayer, count)
	self:setEncounterType(pPlayer, "stage3_site")
	self:setEncounterActive(pPlayer, 1)
	self:setEncounterStage(pPlayer, 3)
end

function RangersPath:spawnStage3FinalSite(pPlayer)
	local stageData = self:getStageData(3)
	local site = stageData.investigation.site

	self:setNumber(pPlayer, "stage3_site_reached", 1)
	self:removeStageWaypoint(pPlayer)
	self:addCustomStageWaypoint(pPlayer, stageData.planet, site.name, site.desc, site.x, site.y)

	self:spawnStage3Guards(pPlayer)
	self:createStage3RemainsArea(pPlayer)

	self:bumpEncounterSerial(pPlayer)
	self:scheduleEncounterTimeout(pPlayer)
	self:scheduleStage3GuardCheck(pPlayer)

	CreatureObject(pPlayer):sendSystemMessage("You found the scouts' last position. Clear the creatures and inspect the remains.")
end

function RangersPath:completeStage3Objective(pPlayer)
	self:setNumber(pPlayer, "stage3_datapad_retrieved", 1)
	self:setStageReady(pPlayer, 3, 1)
	self:removeStageWaypoint(pPlayer)
	self:addQuestGiverWaypoint(pPlayer, "Return to Talren Voss with the recovered datapad.")
	CreatureObject(pPlayer):sendSystemMessage("You recovered the scout datapad. Return to Talren Voss.")
end

function RangersPath:scheduleStage3GuardCheck(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local serial = self:getEncounterSerial(pPlayer)
	createEvent(2000, "RangersPath", "checkStage3GuardStatus", pPlayer, tostring(serial))
end

function RangersPath:checkStage3GuardStatus(pPlayer, eventData)
	if (pPlayer == nil) then
		return 0
	end

	local serial = tonumber(eventData) or 0

	if (serial == 0 or serial ~= self:getEncounterSerial(pPlayer)) then
		return 0
	end

	if (self:getStage(pPlayer) ~= 3 or not self:isStageActive(pPlayer, 3) or self:isStageReady(pPlayer, 3)) then
		return 0
	end

	local encounterType = self:getEncounterType(pPlayer)

	if (encounterType == "stage3_cleared") then
		if (self:getNumber(pPlayer, "stage3_datapad_retrieved") == 0) then
			self:scheduleStage3RemainsCheck(pPlayer)
		end
		return 0
	end

	if (encounterType ~= "stage3_site") then
		return 0
	end

	local livingCount = 0

	for i = 1, self.MAX_ENCOUNTER_MOBS, 1 do
		local mobId = self:getNumber(pPlayer, self:getEncounterMobKey(i))

		if (mobId ~= nil and mobId ~= 0) then
			local pMobile = getSceneObject(mobId)

			if (pMobile ~= nil and not CreatureObject(pMobile):isDead()) then
				livingCount = livingCount + 1
			else
				self:setNumber(pPlayer, self:getEncounterMobKey(i), 0)
			end
		end
	end

	self:setEncounterRemaining(pPlayer, livingCount)

	if (self.DEBUG_STAGE3) then
		CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 3: guard check sees " .. tostring(livingCount) .. " guards still alive.")
	end

	if (livingCount <= 0) then
		self:despawnEncounterMobiles(pPlayer)
		self:setEncounterType(pPlayer, "stage3_cleared")
		self:setEncounterActive(pPlayer, 1)
		self:setEncounterStage(pPlayer, 3)
		CreatureObject(pPlayer):sendSystemMessage("The site is clear. Search the remains and recover the scouts' datapad.")
		self:scheduleStage3RemainsCheck(pPlayer)
		return 0
	end

	self:scheduleStage3GuardCheck(pPlayer)
	return 0
end

function RangersPath:scheduleStage3RemainsCheck(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local serial = self:getEncounterSerial(pPlayer)
	createEvent(2000, "RangersPath", "checkStage3RemainsProgress", pPlayer, tostring(serial))
end

function RangersPath:checkStage3RemainsProgress(pPlayer, eventData)
	if (pPlayer == nil) then
		return 0
	end

	local serial = tonumber(eventData) or 0

	if (serial == 0 or serial ~= self:getEncounterSerial(pPlayer)) then
		return 0
	end

	if (self:getStage(pPlayer) ~= 3 or not self:isStageActive(pPlayer, 3) or self:isStageReady(pPlayer, 3)) then
		return 0
	end

	if (self:getNumber(pPlayer, "stage3_datapad_retrieved") == 1) then
		return 0
	end

	if (self:getEncounterType(pPlayer) ~= "stage3_cleared") then
		return 0
	end

	local stageData = self:getStageData(3)
	local info = stageData.investigation

	local px = SceneObject(pPlayer):getWorldPositionX()
	local py = SceneObject(pPlayer):getWorldPositionY()
	local dx = px - info.remainsX
	local dy = py - info.remainsY
	local dist = math.sqrt(dx * dx + dy * dy)

	if (self.DEBUG_STAGE3) then
		CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 3: remains check dist=" .. tostring(math.floor(dist)) .. " radius=" .. tostring(info.remainsRadius) .. ".")
	end

	if (dist <= info.remainsRadius) then
		self:destroyEncounterObject(pPlayer)
		self:destroyEncounterAreas(pPlayer)
		self:completeStage3Objective(pPlayer)
		return 0
	end

	self:scheduleStage3RemainsCheck(pPlayer)
	return 0
end

-- ============================================================================
-- Stage 5 helpers
-- ============================================================================

function RangersPath:getStage5Wave(pPlayer)
	return self:getNumber(pPlayer, "stage5_wave")
end

function RangersPath:setStage5Wave(pPlayer, wave)
	self:setNumber(pPlayer, "stage5_wave", wave)
end

function RangersPath:isStage5DefenseStarted(pPlayer)
	return self:getNumber(pPlayer, "stage5_defense_started") == 1
end

function RangersPath:setStage5DefenseStarted(pPlayer, value)
	self:setNumber(pPlayer, "stage5_defense_started", value)
end

function RangersPath:isStage5ResetPending(pPlayer)
	return self:getNumber(pPlayer, "stage5_reset_pending") == 1
end

function RangersPath:setStage5ResetPending(pPlayer, value)
	self:setNumber(pPlayer, "stage5_reset_pending", value)
end

function RangersPath:getStage5RequiredSettlersAlive(pPlayer)
	return self:getNumber(pPlayer, "stage5_required_settlers_alive")
end

function RangersPath:setStage5RequiredSettlersAlive(pPlayer, count)
	self:setNumber(pPlayer, "stage5_required_settlers_alive", count)
end

function RangersPath:spawnStage5Settlers(pPlayer)
	local stageData = self:getStageData(5)
	local settlers = stageData.defense.settlers
	local total = #settlers
	local requiredAlive = 0

	self:despawnSettlers(pPlayer)

	for i = 1, total, 1 do
		local settler = settlers[i]
		local pMobile = spawnMobile(stageData.planet, settler.template, 0, settler.x, settler.z, settler.y, settler.heading or 0, 0)

		if (pMobile ~= nil) then
			local mobId = SceneObject(pMobile):getObjectID()

			SceneObject(pMobile):setCustomObjectName(settler.name)
			CreatureObject(pMobile):setPvpStatusBitmask(0)
			CreatureObject(pMobile):setOptionsBitmask(AIENABLED)

			writeData(mobId .. ":RangersPath:ownerID", self:getPlayerId(pPlayer))
			writeData(mobId .. ":RangersPath:stage", 5)
			writeData(mobId .. ":RangersPath:type", "stage5_settler")
			writeData(mobId .. ":RangersPath:required", settler.required and 1 or 0)

			createObserver(OBJECTDESTRUCTION, "RangersPath", "notifyEncounterMobileKilled", pMobile)
			self:setNumber(pPlayer, self:getSettlerMobKey(i), mobId)

			if (settler.required) then
				requiredAlive = requiredAlive + 1
			end
		end
	end

	self:setNumber(pPlayer, "stage5_total_settlers", total)
	self:setStage5RequiredSettlersAlive(pPlayer, requiredAlive)
end

function RangersPath:createStage5DefenseArea(pPlayer)
	local stageData = self:getStageData(5)
	local defense = stageData.defense

	local pArea = spawnActiveArea(stageData.planet, "object/active_area.iff", stageData.x, stageData.z, stageData.y, defense.startRadius, 0)

	if (pArea == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Failed to create the frontier defense area.")
		return 0
	end

	local areaId = SceneObject(pArea):getObjectID()
	writeData(areaId .. ":RangersPath:ownerID", self:getPlayerId(pPlayer))
	writeData(areaId .. ":RangersPath:stage", 5)
	writeData(areaId .. ":RangersPath:type", "stage5_defense_start")

	createObserver(ENTEREDAREA, "RangersPath", "notifyEnteredEncounterArea", pArea)

	self:setEncounterAreaId(pPlayer, areaId)
	self:setEncounterType(pPlayer, "stage5_defense_start")
	self:setEncounterActive(pPlayer, 1)
	self:setEncounterStage(pPlayer, 5)
	self:bumpEncounterSerial(pPlayer)
	self:scheduleEncounterTimeout(pPlayer)
	self:scheduleStage5DefenseCheck(pPlayer)
	return areaId
end

function RangersPath:scheduleStage5DefenseCheck(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local serial = self:getEncounterSerial(pPlayer)
	createEvent(2000, "RangersPath", "checkStage5DefenseStart", pPlayer, tostring(serial))
end

function RangersPath:checkStage5DefenseStart(pPlayer, eventData)
	if (pPlayer == nil) then
		return 0
	end

	local serial = tonumber(eventData) or 0

	if (serial == 0 or serial ~= self:getEncounterSerial(pPlayer)) then
		return 0
	end

	if (not self:isStageActive(pPlayer, 5) or self:isStageReady(pPlayer, 5)) then
		return 0
	end

	if (self:getEncounterType(pPlayer) ~= "stage5_defense_start") then
		return 0
	end

	if (self:isStage5DefenseStarted(pPlayer)) then
		return 0
	end

	local stageData = self:getStageData(5)
	local px = SceneObject(pPlayer):getWorldPositionX()
	local py = SceneObject(pPlayer):getWorldPositionY()
	local dx = px - stageData.x
	local dy = py - stageData.y
	local dist = math.sqrt(dx * dx + dy * dy)

	if (dist <= stageData.defense.startRadius) then
		self:startStage5Defense(pPlayer)
		return 0
	end

	self:scheduleStage5DefenseCheck(pPlayer)
	return 0
end

function RangersPath:scheduleStage5WaveCheck(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local serial = self:getEncounterSerial(pPlayer)
	createEvent(2000, "RangersPath", "checkStage5WaveStatus", pPlayer, tostring(serial))
end

function RangersPath:checkStage5WaveStatus(pPlayer, eventData)
	if (pPlayer == nil) then
		return 0
	end

	local serial = tonumber(eventData) or 0

	if (serial == 0 or serial ~= self:getEncounterSerial(pPlayer)) then
		return 0
	end

	if (not self:isStageActive(pPlayer, 5) or self:isStageReady(pPlayer, 5)) then
		return 0
	end

	if (self:getEncounterType(pPlayer) ~= "stage5_wave") then
		return 0
	end

	local livingCount = 0

	for i = 1, self.MAX_ENCOUNTER_MOBS, 1 do
		local mobId = self:getNumber(pPlayer, self:getEncounterMobKey(i))

		if (mobId ~= nil and mobId ~= 0) then
			local pMobile = getSceneObject(mobId)

			if (pMobile ~= nil and not CreatureObject(pMobile):isDead()) then
				livingCount = livingCount + 1
			else
				self:setNumber(pPlayer, self:getEncounterMobKey(i), 0)
			end
		end
	end

	self:setEncounterRemaining(pPlayer, livingCount)

	if (livingCount <= 0) then
		self:despawnEncounterMobiles(pPlayer)

		if (self:getStage5RequiredSettlersAlive(pPlayer) <= 0) then
			self:failStage5Defense(pPlayer)
			return 0
		end

		local currentWave = self:getStage5Wave(pPlayer)
		local totalWaves = #self:getStageData(5).defense.waves

		if (currentWave >= totalWaves) then
			self:completeStage5Objective(pPlayer)
		else
			local nextSerial = self:bumpEncounterSerial(pPlayer)
			createEvent(self.STAGE5_NEXT_WAVE_DELAY_MS, "RangersPath", "startStage5NextWave", pPlayer, tostring(nextSerial))
			CreatureObject(pPlayer):sendSystemMessage("The next wave is closing in.")
		end

		return 0
	end

	self:scheduleStage5WaveCheck(pPlayer)
	return 0
end

function RangersPath:spawnStage5Wave(pPlayer, wave)
	local stageData = self:getStageData(5)
	local defense = stageData.defense
	local waveData = defense.waves[wave]

	if (waveData == nil) then
		return false
	end

	self:despawnEncounterMobiles(pPlayer)

	local count = #waveData.mobiles

	for i = 1, count, 1 do
		local mob = waveData.mobiles[i]
		local pMobile = spawnMobile(stageData.planet, mob.template, 0, mob.x, mob.z, mob.y, mob.heading or 0, 0)

		if (pMobile ~= nil) then
			local mobId = SceneObject(pMobile):getObjectID()

			if (mob.name ~= nil and mob.name ~= "") then
				SceneObject(pMobile):setCustomObjectName(mob.name)
			end

			writeData(mobId .. ":RangersPath:ownerID", self:getPlayerId(pPlayer))
			writeData(mobId .. ":RangersPath:stage", 5)
			writeData(mobId .. ":RangersPath:type", "stage5_attacker")
			writeData(mobId .. ":RangersPath:index", i)

			createObserver(OBJECTDESTRUCTION, "RangersPath", "notifyEncounterMobileKilled", pMobile)
			self:setNumber(pPlayer, self:getEncounterMobKey(i), mobId)
		end
	end

	self:setEncounterCount(pPlayer, count)
	self:setEncounterRemaining(pPlayer, count)
	self:setEncounterType(pPlayer, "stage5_wave")
	self:setEncounterActive(pPlayer, 1)
	self:setEncounterStage(pPlayer, 5)
	self:setStage5Wave(pPlayer, wave)
	self:bumpEncounterSerial(pPlayer)
	self:scheduleEncounterTimeout(pPlayer)
	self:scheduleStage5WaveCheck(pPlayer)

	CreatureObject(pPlayer):sendSystemMessage("Wave " .. tostring(wave) .. " incoming: " .. waveData.name .. ".")
	return true
end

function RangersPath:startStage5Defense(pPlayer)
	if (self:isStage5DefenseStarted(pPlayer)) then
		return false
	end

	self:setStage5DefenseStarted(pPlayer, 1)
	self:setStage5ResetPending(pPlayer, 0)
	self:destroyEncounterAreas(pPlayer)
	self:spawnStage5Wave(pPlayer, 1)

	CreatureObject(pPlayer):sendSystemMessage("The camp is under attack. Keep at least one settler alive.")
	return true
end

function RangersPath:startStage5NextWave(pPlayer, eventData)
	if (pPlayer == nil) then
		return 0
	end

	local serial = tonumber(eventData) or 0

	if (serial == 0 or serial ~= self:getEncounterSerial(pPlayer)) then
		return 0
	end

	if (not self:isStageActive(pPlayer, 5) or self:isStageReady(pPlayer, 5)) then
		return 0
	end

	if (self:getStage5RequiredSettlersAlive(pPlayer) <= 0) then
		return 0
	end

	local nextWave = self:getStage5Wave(pPlayer) + 1
	self:spawnStage5Wave(pPlayer, nextWave)
	return 0
end

function RangersPath:completeStage5Objective(pPlayer)
	self:despawnEncounterMobiles(pPlayer)
	self:despawnSettlers(pPlayer)
	self:destroyEncounterAreas(pPlayer)
	self:setEncounterType(pPlayer, "")
	self:setEncounterActive(pPlayer, 0)
	self:setEncounterStage(pPlayer, 0)
	self:setStage5DefenseStarted(pPlayer, 0)
	self:setStage5Wave(pPlayer, 0)
	self:setStage5ResetPending(pPlayer, 0)

	self:setStageReady(pPlayer, 5, 1)
	self:removeStageWaypoint(pPlayer)
	self:addQuestGiverWaypoint(pPlayer, "Return to Talren Voss and report the frontier secured.")
	CreatureObject(pPlayer):sendSystemMessage("The settler camp survived the attack. Return to Talren Voss.")
end

function RangersPath:failStage5Defense(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	if (self:isStage5ResetPending(pPlayer)) then
		return false
	end

	self:setStage5ResetPending(pPlayer, 1)
	self:setStage5DefenseStarted(pPlayer, 0)
	self:setEncounterType(pPlayer, "")
	self:setEncounterActive(pPlayer, 0)
	self:setEncounterStage(pPlayer, 5)

	self:despawnEncounterMobiles(pPlayer)
	self:despawnSettlers(pPlayer)
	self:destroyEncounterAreas(pPlayer)

	local serial = self:bumpEncounterSerial(pPlayer)
	createEvent(self.STAGE5_RESET_DELAY_MS, "RangersPath", "resetStage5DefenseAfterFailure", pPlayer, tostring(serial))

	CreatureObject(pPlayer):sendSystemMessage("All required settlers were lost. Regroup and prepare to defend the camp again.")
	return true
end

function RangersPath:resetStage5DefenseAfterFailure(pPlayer, eventData)
	if (pPlayer == nil) then
		return 0
	end

	local serial = tonumber(eventData) or 0

	if (serial == 0 or serial ~= self:getEncounterSerial(pPlayer)) then
		return 0
	end

	if (not self:isStageActive(pPlayer, 5) or self:isStageReady(pPlayer, 5)) then
		return 0
	end

	self:setStage5ResetPending(pPlayer, 0)
	self:setStage5Wave(pPlayer, 0)
	self:setStage5DefenseStarted(pPlayer, 0)
	self:setupStage5Objectives(pPlayer, false)

	CreatureObject(pPlayer):sendSystemMessage("The frontier camp has been re-established. Try the defense again.")
	return 0
end

-- ============================================================================
-- Shared encounter callbacks
-- ============================================================================

function RangersPath:notifyEnteredEncounterArea(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	local areaId = SceneObject(pArea):getObjectID()
	local ownerId = tonumber(readData(areaId .. ":RangersPath:ownerID")) or 0
	local stage = tonumber(readData(areaId .. ":RangersPath:stage")) or 0
	local encounterType = tostring(readData(areaId .. ":RangersPath:type") or "")
	local step = tonumber(readData(areaId .. ":RangersPath:step")) or 0

	if (ownerId == 0 or self:getPlayerId(pPlayer) ~= ownerId) then
		return 0
	end

	if (not self:isStageActive(pPlayer, stage)) then
		self:resetEncounter(pPlayer)
		return 1
	end

	if (encounterType == "hunt_trigger") then
		self:destroyEncounterAreas(pPlayer)
		self:spawnHuntTarget(pPlayer, stage)
		return 1
	end

	if (encounterType == "stage2_crate_area" or encounterType == "stage2_camp_area") then
		if (self.DEBUG_STAGE2) then
			CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 2: entered trigger area type " .. encounterType .. ".")
		end

		if (self:getNumber(pPlayer, "stage2_crate_used") == 1) then
			if (self.DEBUG_STAGE2) then
				CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 2: ambush already triggered, ignoring area entry.")
			end
			return 1
		end

		self:spawnStage2Ambush(pPlayer)
		return 1
	end

	if (encounterType == "stage3_trail") then
		if (self.DEBUG_STAGE3) then
			CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 3: entered trail area for step " .. tostring(step) .. ".")
		end

		self:destroyEncounterAreas(pPlayer)

		if (step < self:getStage3TrailCount()) then
			self:setStage3TrailStep(pPlayer, step + 1)
			self:createStage3TrailArea(pPlayer)
			CreatureObject(pPlayer):sendSystemMessage("You find more signs ahead. Continue following the trail.")
		else
			self:spawnStage3FinalSite(pPlayer)
		end

		return 1
	end

	if (encounterType == "stage3_remains_area") then
		if (self.DEBUG_STAGE3) then
			CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 3: entered remains interaction area.")
		end

		if (self:getEncounterRemaining(pPlayer) > 0) then
			CreatureObject(pPlayer):sendSystemMessage("The territorial creatures still guard the site.")
			return 1
		end

		if (self:getNumber(pPlayer, "stage3_datapad_retrieved") == 1) then
			return 1
		end

		-- TODO: Replace this area-based pickup with a radial/object interaction if desired.
		self:destroyEncounterObject(pPlayer)
		self:destroyEncounterAreas(pPlayer)
		self:completeStage3Objective(pPlayer)
		return 1
	end

	if (encounterType == "stage5_defense_start") then
		self:startStage5Defense(pPlayer)
		return 1
	end

	return 1
end

function RangersPath:notifyEncounterMobileKilled(pVictim, pAttacker)
	if (pVictim == nil) then
		return 1
	end

	local victimId = SceneObject(pVictim):getObjectID()
	local ownerId = tonumber(readData(victimId .. ":RangersPath:ownerID")) or 0
	local stage = tonumber(readData(victimId .. ":RangersPath:stage")) or 0
	local encounterType = tostring(readData(victimId .. ":RangersPath:type") or "")
	local wasRequired = tonumber(readData(victimId .. ":RangersPath:required")) or 0

	deleteData(victimId .. ":RangersPath:ownerID")
	deleteData(victimId .. ":RangersPath:stage")
	deleteData(victimId .. ":RangersPath:type")
	deleteData(victimId .. ":RangersPath:index")
	deleteData(victimId .. ":RangersPath:required")

	if (ownerId == 0 or stage == 0) then
		return 1
	end

	local pOwner = getSceneObject(ownerId)

	if (pOwner == nil) then
		return 1
	end

	if (not self:isStageActive(pOwner, stage)) then
		return 1
	end

	if (encounterType == "hunt_target") then
		self:completeHuntObjective(pOwner, stage)
		return 1
	end

	if (encounterType == "stage2_ambusher") then
		if (self.DEBUG_STAGE2) then
			CreatureObject(pOwner):sendSystemMessage("DEBUG Stage 2: ambusher destruction observer fired.")
		end

		self:countStage2AmbusherKill(pOwner, victimId, "destruction observer", true)

		return 1
	end

	if (encounterType == "stage3_guard") then
		local remaining = self:getEncounterRemaining(pOwner) - 1
		if (remaining < 0) then
			remaining = 0
		end
		self:setEncounterRemaining(pOwner, remaining)

		if (remaining <= 0) then
			self:despawnEncounterMobiles(pOwner)
			self:setEncounterType(pOwner, "stage3_cleared")
			self:setEncounterActive(pOwner, 1)
			self:setEncounterStage(pOwner, 3)
			CreatureObject(pOwner):sendSystemMessage("The site is clear. Search the remains and recover the scouts' datapad.")
			self:scheduleStage3RemainsCheck(pOwner)
		end

		return 1
	end

	if (encounterType == "stage5_settler") then
		if (wasRequired == 1) then
			local alive = self:getStage5RequiredSettlersAlive(pOwner) - 1
			if (alive < 0) then
				alive = 0
			end
			self:setStage5RequiredSettlersAlive(pOwner, alive)

			if (alive <= 0) then
				self:failStage5Defense(pOwner)
			end
		end

		return 1
	end

	if (encounterType == "stage5_attacker") then
		local remaining = self:getEncounterRemaining(pOwner) - 1
		if (remaining < 0) then
			remaining = 0
		end
		self:setEncounterRemaining(pOwner, remaining)

		if (remaining <= 0) then
			self:despawnEncounterMobiles(pOwner)

			if (self:getStage5RequiredSettlersAlive(pOwner) <= 0) then
				self:failStage5Defense(pOwner)
				return 1
			end

			local currentWave = self:getStage5Wave(pOwner)
			local totalWaves = #self:getStageData(5).defense.waves

			if (currentWave >= totalWaves) then
				self:completeStage5Objective(pOwner)
			else
				local serial = self:bumpEncounterSerial(pOwner)
				createEvent(self.STAGE5_NEXT_WAVE_DELAY_MS, "RangersPath", "startStage5NextWave", pOwner, tostring(serial))
				CreatureObject(pOwner):sendSystemMessage("The next wave is closing in.")
			end
		end

		return 1
	end

	return 1
end

-- ============================================================================
-- Cleanup helpers
-- ============================================================================

function RangersPath:cleanupPlayerWaypoints(pPlayer)
	self:removeStageWaypoint(pPlayer)
	self:removeQuestGiverWaypoint(pPlayer)
end

function RangersPath:cleanupPlayerState(pPlayer)
	self:cleanupPlayerWaypoints(pPlayer)
	self:resetEncounter(pPlayer)
end

function RangersPath:resetQuestState(pPlayer, preserveRewarded)
	local rewarded = 0

	if (preserveRewarded == true and self:isRewarded(pPlayer)) then
		rewarded = 1
	end

	self:cleanupPlayerState(pPlayer)

	self:setNumber(pPlayer, "started", 0)
	self:setNumber(pPlayer, "current_stage", 0)
	self:setNumber(pPlayer, "completed", 0)
	self:setNumber(pPlayer, "rewarded", rewarded)
	self:setNumber(pPlayer, "active_encounter", 0)
	self:setNumber(pPlayer, "encounter_stage", 0)
	self:setNumber(pPlayer, "encounter_serial", 0)
	self:setEncounterType(pPlayer, "")
	self:setEncounterCount(pPlayer, 0)
	self:setEncounterRemaining(pPlayer, 0)
	self:setEncounterAreaId(pPlayer, 0)
	self:setEncounterAuxAreaId(pPlayer, 0)
	self:setEncounterObjectId(pPlayer, 0)
	self:clearEncounterMobKeys(pPlayer)
	self:clearSettlerMobKeys(pPlayer)

	self:resetStage2State(pPlayer)
	self:resetStage3State(pPlayer)
	self:resetStage5State(pPlayer)

	for stage = 1, self.MAX_STAGE, 1 do
		self:setStageReady(pPlayer, stage, 0)
		self:setStageMarkedComplete(pPlayer, stage, 0)
	end
end

-- ============================================================================
-- Stage objective setup
-- ============================================================================

function RangersPath:setupStage1Objectives(pPlayer)
	self:createHuntTriggerArea(pPlayer, 1)

	-- Stage 1 is the player's first quest step, so spawn the target immediately
	-- as a fallback instead of relying only on the active-area trigger.
	if (self:spawnHuntTarget(pPlayer, 1) == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Search the hunt region. The predator will reveal itself once you press into its territory.")
		return
	end

	CreatureObject(pPlayer):sendSystemMessage("Razor Cat Alpha has been sighted near the marked hunt waypoint. Find and kill it.")
end

function RangersPath:setupStage2Objectives(pPlayer, initialSetup)
	if (initialSetup == true) then
		self:resetStage2State(pPlayer)
	end

	if (self.DEBUG_STAGE2) then
		CreatureObject(pPlayer):sendSystemMessage("DEBUG Stage 2: setupStage2Objectives running.")
	end

	self:createStage2CrateArea(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("Find the hidden camp and inspect the supply cache near 1088, -1041.")
end

function RangersPath:setupStage3Objectives(pPlayer, initialSetup)
	if (initialSetup == true) then
		self:resetStage3State(pPlayer)
	end

	if (self:getNumber(pPlayer, "stage3_site_reached") == 1) then
		self:spawnStage3FinalSite(pPlayer)
	else
		self:createStage3TrailArea(pPlayer)
	end

	CreatureObject(pPlayer):sendSystemMessage("Investigate the scouts' last position, defeat the creatures guarding it, and recover the datapad.")
end

function RangersPath:setupStage4Objectives(pPlayer)
	self:createHuntTriggerArea(pPlayer, 4)
	CreatureObject(pPlayer):sendSystemMessage("Sweep the wider hunt grounds. This beast will not reveal itself easily.")
end

function RangersPath:setupStage5Objectives(pPlayer, initialSetup)
	if (initialSetup == true) then
		self:resetStage5State(pPlayer)
	end

	self:spawnStage5Settlers(pPlayer)
	self:createStage5DefenseArea(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("Move into the camp to begin the defense. At least one required settler must survive.")
end

function RangersPath:setupStage6Objectives(pPlayer)
	self:createHuntTriggerArea(pPlayer, 6)
	CreatureObject(pPlayer):sendSystemMessage("This is the final proving hunt. Enter the region and face Ancient Shadowclaw.")
end

function RangersPath:setupStageObjectives(pPlayer, stage, initialSetup)
	if (stage == 1) then
		self:setupStage1Objectives(pPlayer)
	elseif (stage == 2) then
		self:setupStage2Objectives(pPlayer, initialSetup)
	elseif (stage == 3) then
		self:setupStage3Objectives(pPlayer, initialSetup)
	elseif (stage == 4) then
		self:setupStage4Objectives(pPlayer)
	elseif (stage == 5) then
		self:setupStage5Objectives(pPlayer, initialSetup)
	elseif (stage == 6) then
		self:setupStage6Objectives(pPlayer)
	else
		CreatureObject(pPlayer):sendSystemMessage("Proceed to the marked location and complete the objective.")
	end
end

-- ============================================================================
-- Quest flow helpers
-- ============================================================================

function RangersPath:beginStage(pPlayer, stage)
	local data = self:getStageData(stage)

	if (pPlayer == nil or data == nil) then
		return false
	end

	self:resetEncounter(pPlayer)
	self:setStage(pPlayer, stage)
	self:setStageReady(pPlayer, stage, 0)
	self:setStageMarkedComplete(pPlayer, stage, 0)
	self:removeQuestGiverWaypoint(pPlayer)
	self:removeStageWaypoint(pPlayer)
	self:addStageWaypoint(pPlayer, stage)
	self:setupStageObjectives(pPlayer, stage, true)

	CreatureObject(pPlayer):sendSystemMessage("Quest stage updated: " .. data.title)
	return true
end

function RangersPath:startStage1(pPlayer)
	return self:beginStage(pPlayer, 1)
end

function RangersPath:startStage2(pPlayer)
	return self:beginStage(pPlayer, 2)
end

function RangersPath:startStage3(pPlayer)
	return self:beginStage(pPlayer, 3)
end

function RangersPath:startStage4(pPlayer)
	return self:beginStage(pPlayer, 4)
end

function RangersPath:startStage5(pPlayer)
	return self:beginStage(pPlayer, 5)
end

function RangersPath:startStage6(pPlayer)
	return self:beginStage(pPlayer, 6)
end

function RangersPath:advanceToNextStage(pPlayer, completedStage)
	local nextStage = completedStage + 1

	if (nextStage == 2) then
		return self:startStage2(pPlayer)
	elseif (nextStage == 3) then
		return self:startStage3(pPlayer)
	elseif (nextStage == 4) then
		return self:startStage4(pPlayer)
	elseif (nextStage == 5) then
		return self:startStage5(pPlayer)
	elseif (nextStage == 6) then
		return self:startStage6(pPlayer)
	end

	return false
end

function RangersPath:canCompleteStage(pPlayer, stage)
	if (pPlayer == nil) then
		return false
	end

	if (not self:hasStarted(pPlayer)) then
		return false
	end

	if (self:isCompleted(pPlayer)) then
		return false
	end

	if (self:getStage(pPlayer) ~= stage) then
		return false
	end

	if (not self:isStageReady(pPlayer, stage)) then
		return false
	end

	return true
end

function RangersPath:completeStage(pPlayer, stage)
	if (not self:canCompleteStage(pPlayer, stage)) then
		return false
	end

	self:setStageMarkedComplete(pPlayer, stage, 1)
	self:setStageReady(pPlayer, stage, 0)
	self:removeStageWaypoint(pPlayer)
	self:removeQuestGiverWaypoint(pPlayer)
	self:resetEncounter(pPlayer)

	local stageCredits = self.STAGE_CREDITS[stage]

	if (stageCredits ~= nil and stageCredits > 0) then
		CreatureObject(pPlayer):addBankCredits(stageCredits, true)
		CreatureObject(pPlayer):sendSystemMessage("You have been awarded " .. tostring(stageCredits) .. " credits for completing " .. self:getStageTitle(stage) .. ".")
	end

	if (stage >= self.MAX_STAGE) then
		return true
	end

	return self:advanceToNextStage(pPlayer, stage)
end

function RangersPath:handleStageTurnIn(pPlayer, stage)
	if (stage == 6) then
		return self:hasFinalObjectiveComplete(pPlayer)
	end

	if (self:completeStage(pPlayer, stage)) then
		return true
	end

	CreatureObject(pPlayer):sendSystemMessage("You are not ready to turn in " .. self:getStageTitle(stage) .. ".")
	return false
end

-- ============================================================================
-- External objective hooks
-- ============================================================================

function RangersPath:markStageObjectiveReady(pPlayer, stage)
	if (pPlayer == nil or not self:isStageActive(pPlayer, stage)) then
		return false
	end

	self:setStageReady(pPlayer, stage, 1)
	self:removeStageWaypoint(pPlayer)
	self:addQuestGiverWaypoint(pPlayer, "Return to Talren Voss and report in.")
	CreatureObject(pPlayer):sendSystemMessage(self:getStageTitle(stage) .. " is ready to turn in.")
	return true
end

function RangersPath:markCurrentStageReady(pPlayer)
	return self:markStageObjectiveReady(pPlayer, self:getStage(pPlayer))
end

-- ============================================================================
-- Quest start / reset helpers
-- ============================================================================

function RangersPath:startQuest(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	if (self:isRewarded(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("You have already completed The Ranger's Path on this character.")
		return false
	end

	self:resetQuestState(pPlayer, false)
	self:setNumber(pPlayer, "started", 1)
	self:setNumber(pPlayer, "completed", 0)
	self:setNumber(pPlayer, "rewarded", 0)

	return self:startStage1(pPlayer)
end

function RangersPath:restartQuest(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	if (self:isRewarded(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("This character has already claimed the final reward and cannot restart the quest.")
		return false
	end

	return self:startQuest(pPlayer)
end

function RangersPath:abandonQuest(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	self:resetQuestState(pPlayer, true)
	CreatureObject(pPlayer):sendSystemMessage("The Ranger's Path has been reset.")
	return true
end

-- ============================================================================
-- Final reward helper
-- ============================================================================

function RangersPath:giveFinalReward(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	if (self:isRewarded(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("You have already claimed the Ranger's Path reward.")
		return false
	end

	if (not self:hasFinalObjectiveComplete(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("You have not yet completed the Ranger Trial.")
		return false
	end

	if (not self:hasInventorySpace(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("Your inventory is full. Clear space and try again.")
		return false
	end

	local pInventory = self:getInventory(pPlayer)
	local pItem = giveItem(pInventory, self.REWARD_ITEM_TEMPLATE, -1, true)

	if (pItem == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Unable to grant the final reward item.")
		return false
	end

	CreatureObject(pPlayer):addBankCredits(self.REWARD_CREDITS, true)

	self:setNumber(pPlayer, "completed", 1)
	self:setNumber(pPlayer, "rewarded", 1)
	self:setStageMarkedComplete(pPlayer, 6, 1)

	self:cleanupPlayerWaypoints(pPlayer)
	self:resetEncounter(pPlayer)

	CreatureObject(pPlayer):sendSystemMessage("Reward received: 25000 bank credits and a creature survey tool.")
	return true
end

function RangersPath:grantFinalReward(pPlayer)
	return self:giveFinalReward(pPlayer)
end
