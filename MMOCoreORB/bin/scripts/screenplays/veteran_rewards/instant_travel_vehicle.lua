InstantTravelVehicle = ScreenPlay:new {
	screenplayName = "InstantTravelVehicle",

	ITV_REQUIRED_ACCOUNT_DAYS = 545,
	ITV_COOLDOWN_SECONDS = 3600,
	ITV_LIFETIME_SECONDS = 300,
	ITV_LANDING_DELAY_SECONDS = 30,
	ITV_GROUP_USE_RANGE = 10,
	ITV_MIN_LANDING_DISTANCE = 20,
	ITV_MAX_LANDING_DISTANCE = 35,
	ITV_TRAVEL_COST = 0,

	ITV_TRANSPONDER_TEMPLATE = "object/tangible/harvesting/instant_travel_vehicle_transponder.iff",
	ITV_SHUTTLE_TEMPLATE = "object/tangible/event_perk/player_shuttle.iff",
	ITV_SHUTTLE_TEMPLATES = {
		"object/tangible/event_perk/player_shuttle.iff",
		"object/tangible/event_perk/lambda_shuttle.iff",
		"object/tangible/event_perk/xwing.iff",
		"object/tangible/event_perk/tie_bomber.iff",
	},

	STATE_NONE = 0,
	STATE_REQUESTED = 1,
	STATE_LANDING = 2,
	STATE_ACTIVE = 3,
	STATE_DEPARTING = 4,
	STATE_CLEANUP = 5,
}

registerScreenPlay("InstantTravelVehicle", true)

function InstantTravelVehicle:start()
end

InstantTravelVehicleTransponderMenuComponent = { }
InstantTravelVehicleShuttleMenuComponent = { }

function InstantTravelVehicleTransponderMenuComponent:fillObjectMenuResponse(pObject, pMenuResponse, pPlayer)
	if (pObject == nil or pPlayer == nil) then
		return
	end

	LuaObjectMenuResponse(pMenuResponse):addRadialMenuItem(120, 3, "Call Instant Travel Vehicle")
end

function InstantTravelVehicleTransponderMenuComponent:handleObjectMenuSelect(pObject, pPlayer, selectedID)
	if (selectedID == 120) then
		InstantTravelVehicle:activateTransponder(pPlayer, pObject)
	end

	return 0
end

function InstantTravelVehicleShuttleMenuComponent:fillObjectMenuResponse(pShuttle, pMenuResponse, pPlayer)
	if (pShuttle == nil or pPlayer == nil) then
		return
	end

	LuaObjectMenuResponse(pMenuResponse):addRadialMenuItem(120, 3, "Select Travel Destination")
end

function InstantTravelVehicleShuttleMenuComponent:handleObjectMenuSelect(pShuttle, pPlayer, selectedID)
	if (selectedID == 120) then
		InstantTravelVehicle:openTravelMenu(pPlayer, pShuttle)
	end

	return 0
end

function InstantTravelVehicle:activateTransponder(pPlayer, pTransponder)
	if (pPlayer == nil or pTransponder == nil) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	if (SceneObject(pTransponder):isASubChildOf(pPlayer) == false) then
		CreatureObject(pPlayer):sendSystemMessage("You must have the Instant Travel Vehicle Transponder in your inventory to activate it.")
		self:log("activation denied: transponder not carried by owner " .. playerID)
		return
	end

	if (SceneObject(pTransponder):getTemplateObjectPath() ~= self.ITV_TRANSPONDER_TEMPLATE) then
		CreatureObject(pPlayer):sendSystemMessage("This transponder cannot call an Instant Travel Vehicle.")
		self:log("activation denied: invalid template for owner " .. playerID)
		return
	end

	local ok, message = self:canDeploy(pPlayer)
	if (not ok) then
		CreatureObject(pPlayer):sendSystemMessage(message)
		self:log("deployment denied for owner " .. playerID .. ": " .. message)
		return
	end

	local cooldownRemaining = self:getCooldownRemaining(pPlayer)
	if (cooldownRemaining > 0) then
		local text = "Your Instant Travel Vehicle Transponder is recharging. It will be available again in " .. self:formatTime(cooldownRemaining) .. "."
		CreatureObject(pPlayer):sendSystemMessage(text)
		self:log("cooldown denial for owner " .. playerID .. ": " .. cooldownRemaining .. " seconds remaining")
		return
	end

	local landing = self:findLandingPosition(pPlayer)
	if (landing == nil) then
		CreatureObject(pPlayer):sendSystemMessage("There is not enough room nearby for the shuttle to land.")
		self:clearDeploymentState(pPlayer)
		self:log("deployment denied for owner " .. playerID .. ": no safe landing position")
		return
	end

	writeScreenPlayData(pPlayer, self.screenplayName, "state", self.STATE_LANDING)
	writeScreenPlayData(pPlayer, self.screenplayName, "cooldownUntil", os.time() + self.ITV_COOLDOWN_SECONDS)
	writeScreenPlayData(pPlayer, self.screenplayName, "landingRequestedAt", os.time())
	writeScreenPlayData(pPlayer, self.screenplayName, "landingPlanet", landing.planet)
	writeScreenPlayData(pPlayer, self.screenplayName, "landingX", landing.x)
	writeScreenPlayData(pPlayer, self.screenplayName, "landingZ", landing.z)
	writeScreenPlayData(pPlayer, self.screenplayName, "landingY", landing.y)
	writeScreenPlayData(pPlayer, self.screenplayName, "landingHeading", landing.heading)

	CreatureObject(pPlayer):sendSystemMessage("You activate your Instant Travel Vehicle Transponder.")
	CreatureObject(pPlayer):sendSystemMessage("Your Shuttle will arrive in 30 seconds")

	createEvent(self.ITV_LANDING_DELAY_SECONDS * 1000, self.screenplayName, "finishLanding", pPlayer, "")
	self:log("landing requested owner=" .. playerID .. " planet=" .. landing.planet .. " x=" .. landing.x .. " z=" .. landing.z .. " y=" .. landing.y)
end

function InstantTravelVehicle:finishLanding(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local state = tonumber(readScreenPlayData(pPlayer, self.screenplayName, "state")) or self.STATE_NONE

	if (state ~= self.STATE_LANDING) then
		self:log("landing aborted owner=" .. playerID .. " reason=state_changed")
		return
	end

	local landing = {
		planet = readScreenPlayData(pPlayer, self.screenplayName, "landingPlanet"),
		x = tonumber(readScreenPlayData(pPlayer, self.screenplayName, "landingX")),
		z = tonumber(readScreenPlayData(pPlayer, self.screenplayName, "landingZ")),
		y = tonumber(readScreenPlayData(pPlayer, self.screenplayName, "landingY")),
		heading = tonumber(readScreenPlayData(pPlayer, self.screenplayName, "landingHeading")) or 0,
	}

	local ok, message = self:canCompleteLanding(pPlayer, landing)
	if (not ok) then
		CreatureObject(pPlayer):sendSystemMessage(message)
		self:clearDeploymentState(pPlayer)
		self:log("landing aborted owner=" .. playerID .. " reason=" .. message)
		return
	end

	CreatureObject(pPlayer):sendSystemMessage("Your Instant Travel Vehicle is approaching. A temporary waypoint has been added to your datapad.")
	self:deployShuttle(pPlayer, landing)
end

function InstantTravelVehicle:deployShuttle(pPlayer, landing)
	local playerID = SceneObject(pPlayer):getObjectID()
	local shuttleTemplate = self:getRandomShuttleTemplate()
	local pShuttle = spawnSceneObject(landing.planet, shuttleTemplate, landing.x, landing.z, landing.y, 0, landing.heading)

	if (pShuttle == nil) then
		CreatureObject(pPlayer):sendSystemMessage("There is not enough room nearby for the shuttle to land.")
		self:clearDeploymentState(pPlayer)
		self:log("deployment failed for owner " .. playerID .. ": spawnSceneObject returned nil")
		return
	end

	SceneObject(pShuttle):setCustomObjectName("Instant Travel Vehicle")
	SceneObject(pShuttle):setObjectMenuComponent("InstantTravelVehicleShuttleMenuComponent")
	SceneObject(pShuttle):setContainerOwnerID(playerID)

	local shuttleID = SceneObject(pShuttle):getObjectID()
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	local waypointID = 0

	if (pGhost ~= nil) then
		waypointID = PlayerObject(pGhost):addWaypoint(landing.planet, "Instant Travel Vehicle", "Temporary veteran reward shuttle.", landing.x, landing.z, landing.y, WAYPOINT_BLUE, true, true, 0, 0)
	end

	writeScreenPlayData(pPlayer, self.screenplayName, "state", self.STATE_ACTIVE)
	writeScreenPlayData(pPlayer, self.screenplayName, "shuttleID", shuttleID)
	writeScreenPlayData(pPlayer, self.screenplayName, "waypointID", waypointID)
	writeScreenPlayData(pPlayer, self.screenplayName, "planet", landing.planet)
	writeScreenPlayData(pPlayer, self.screenplayName, "expiresAt", os.time() + self.ITV_LIFETIME_SECONDS)
	writeData(shuttleID .. ":ITV:ownerID", playerID)
	writeData(shuttleID .. ":ITV:expiresAt", os.time() + self.ITV_LIFETIME_SECONDS)

	playClientEffectLoc(pPlayer, "clienteffect/space_command/shuttle_recall.cef", landing.planet, landing.x, landing.z, landing.y, 0)

	createEvent((self.ITV_LIFETIME_SECONDS - 120) * 1000, self.screenplayName, "warnTwoMinutes", pPlayer, "")
	createEvent((self.ITV_LIFETIME_SECONDS - 60) * 1000, self.screenplayName, "warnOneMinute", pPlayer, "")
	createEvent((self.ITV_LIFETIME_SECONDS - 30) * 1000, self.screenplayName, "warnThirtySeconds", pPlayer, "")
	createEvent(self.ITV_LIFETIME_SECONDS * 1000, self.screenplayName, "departShuttle", pPlayer, "")

	self:sendEligibleMessage(pPlayer, "The Instant Travel Vehicle has landed and is ready for travel.")
	self:log("deployed owner=" .. playerID .. " shuttle=" .. shuttleID .. " template=" .. shuttleTemplate .. " planet=" .. landing.planet .. " x=" .. landing.x .. " z=" .. landing.z .. " y=" .. landing.y)
end

function InstantTravelVehicle:getRandomShuttleTemplate()
	if (self.ITV_SHUTTLE_TEMPLATES == nil or #self.ITV_SHUTTLE_TEMPLATES == 0) then
		return self.ITV_SHUTTLE_TEMPLATE
	end

	return self.ITV_SHUTTLE_TEMPLATES[getRandomNumber(1, #self.ITV_SHUTTLE_TEMPLATES)]
end

function InstantTravelVehicle:canDeploy(pPlayer)
	if (CreatureObject(pPlayer):isInCombat()) then
		return false, "You cannot call your Instant Travel Vehicle while in combat."
	end

	if (CreatureObject(pPlayer):isIncapacitated() or CreatureObject(pPlayer):isDead()) then
		return false, "You cannot call your Instant Travel Vehicle while incapacitated or dead."
	end

	if (SceneObject(pPlayer):getParentID() ~= 0) then
		return false, "You cannot call your Instant Travel Vehicle from inside a structure or interior area."
	end

	if (CreatureObject(pPlayer):isRidingMount() or CreatureObject(pPlayer):isPilotingShip()) then
		return false, "You cannot call your Instant Travel Vehicle while mounted or operating another vehicle."
	end

	local planet = SceneObject(pPlayer):getZoneName()
	if (planet == nil or string.find(planet, "space_") == 1) then
		return false, "You cannot call your Instant Travel Vehicle from space."
	end

	if (self:getDestinationCount(planet) == 0) then
		return false, "No valid shuttleports or starports are available on this planet."
	end

	local state = tonumber(readScreenPlayData(pPlayer, self.screenplayName, "state")) or self.STATE_NONE
	local shuttleID = tonumber(readScreenPlayData(pPlayer, self.screenplayName, "shuttleID")) or 0

	if (state == self.STATE_REQUESTED or state == self.STATE_LANDING) then
		local requestedAt = tonumber(readScreenPlayData(pPlayer, self.screenplayName, "landingRequestedAt")) or 0
		if (requestedAt ~= 0 and requestedAt + self.ITV_LANDING_DELAY_SECONDS + 60 > os.time()) then
			return false, "Your Instant Travel Vehicle is already en route."
		end
	end

	if (state ~= self.STATE_NONE and state ~= "" and shuttleID ~= 0 and getSceneObject(shuttleID) ~= nil) then
		return false, "You already have an Instant Travel Vehicle deployed."
	end

	if (state ~= self.STATE_NONE and state ~= "") then
		self:clearDeploymentState(pPlayer)
	end

	return true, ""
end

function InstantTravelVehicle:canCompleteLanding(pPlayer, landing)
	if (landing == nil or landing.planet == nil or landing.x == nil or landing.z == nil or landing.y == nil) then
		return false, "There is not enough room nearby for the shuttle to land."
	end

	if (SceneObject(pPlayer):getZoneName() ~= landing.planet) then
		return false, "Your Instant Travel Vehicle could not land because you changed planets."
	end

	if (CreatureObject(pPlayer):isInCombat()) then
		return false, "You cannot call your Instant Travel Vehicle while in combat."
	end

	if (CreatureObject(pPlayer):isIncapacitated() or CreatureObject(pPlayer):isDead()) then
		return false, "You cannot call your Instant Travel Vehicle while incapacitated or dead."
	end

	if (SceneObject(pPlayer):getParentID() ~= 0) then
		return false, "You cannot call your Instant Travel Vehicle from inside a structure or interior area."
	end

	if (CreatureObject(pPlayer):isRidingMount() or CreatureObject(pPlayer):isPilotingShip()) then
		return false, "You cannot call your Instant Travel Vehicle while mounted or operating another vehicle."
	end

	return true, ""
end

function InstantTravelVehicle:findLandingPosition(pPlayer)
	local planet = SceneObject(pPlayer):getZoneName()
	local px = SceneObject(pPlayer):getWorldPositionX()
	local py = SceneObject(pPlayer):getWorldPositionY()

	for attempt = 1, 16, 1 do
		local point = getSpawnPoint(planet, px, py, self.ITV_MIN_LANDING_DISTANCE, self.ITV_MAX_LANDING_DISTANCE, true)

		if (point ~= nil and point[1] ~= nil and point[3] ~= nil) then
			local z = getTerrainHeight(pPlayer, point[1], point[3])

			if (z ~= nil) then
				local atan2 = math.atan2 or math.atan
				local heading = atan2(py - point[3], px - point[1])
				return { planet = planet, x = point[1], z = z, y = point[3], heading = heading }
			end
		end
	end

	return nil
end

function InstantTravelVehicle:openTravelMenu(pPlayer, pShuttle)
	if (pPlayer == nil or pShuttle == nil) then
		return
	end

	local ownerID = readData(SceneObject(pShuttle):getObjectID() .. ":ITV:ownerID")
	local pOwner = getSceneObject(ownerID)
	if (not self:canUseShuttle(pPlayer, pShuttle, pOwner)) then
		return
	end

	local planet = SceneObject(pShuttle):getZoneName()
	local destinations = self:getDestinations(planet)

	if (#destinations == 0) then
		CreatureObject(pPlayer):sendSystemMessage("No valid shuttleports or starports are available on this planet.")
		return
	end

	local sui = SuiListBox.new(self.screenplayName, "travelSelectionCallback")
	sui.setTargetNetworkId(SceneObject(pShuttle):getObjectID())
	sui.setTitle("Select Travel Destination")
	sui.setPrompt("Select an Instant Travel Vehicle destination on this planet.")

	for i = 1, #destinations, 1 do
		sui.add(destinations[i].name, "")
	end

	sui.sendTo(pPlayer)
	self:log("opened destination list user=" .. SceneObject(pPlayer):getObjectID() .. " owner=" .. ownerID .. " shuttle=" .. SceneObject(pShuttle):getObjectID() .. " planet=" .. planet)
end

function InstantTravelVehicle:travelSelectionCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1) then
		return
	end

	local shuttleID = readData(SceneObject(pPlayer):getObjectID() .. ":ITV:lastShuttleID")
	if (shuttleID == 0) then
		shuttleID = self:findNearbyOwnedShuttle(pPlayer)
	end

	local pShuttle = getSceneObject(shuttleID)
	if (pShuttle == nil) then
		CreatureObject(pPlayer):sendSystemMessage("This Instant Travel Vehicle is no longer available.")
		self:log("invalid destination callback: no shuttle for user=" .. SceneObject(pPlayer):getObjectID())
		return
	end

	local ownerID = readData(shuttleID .. ":ITV:ownerID")
	local pOwner = getSceneObject(ownerID)
	if (not self:canUseShuttle(pPlayer, pShuttle, pOwner)) then
		return
	end

	local selected = tonumber(args)
	if (selected == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Invalid Instant Travel Vehicle destination.")
		self:log("invalid destination callback: nonnumeric args user=" .. SceneObject(pPlayer):getObjectID())
		return
	end

	local planet = SceneObject(pShuttle):getZoneName()
	local destinations = self:getDestinations(planet)
	local destination = destinations[selected + 1]

	if (destination == nil or destination.incomingTravelAllowed ~= 1) then
		CreatureObject(pPlayer):sendSystemMessage("Invalid Instant Travel Vehicle destination.")
		self:log("invalid destination callback: index=" .. selected .. " user=" .. SceneObject(pPlayer):getObjectID() .. " planet=" .. planet)
		return
	end

	if (self.ITV_TRAVEL_COST > 0 and CreatureObject(pPlayer):getCashCredits() < self.ITV_TRAVEL_COST) then
		CreatureObject(pPlayer):sendSystemMessage("@travel:short_funds")
		return
	end

	if (self.ITV_TRAVEL_COST > 0) then
		CreatureObject(pPlayer):subtractCashCredits(self.ITV_TRAVEL_COST)
	end

	SceneObject(pPlayer):switchZone(planet, destination.x, destination.z, destination.y, 0)
	CreatureObject(pPlayer):sendSystemMessage("You travel by Instant Travel Vehicle.")
	self:log("travel user=" .. SceneObject(pPlayer):getObjectID() .. " owner=" .. ownerID .. " destination=" .. destination.name .. " planet=" .. planet)
end

function InstantTravelVehicle:canUseShuttle(pPlayer, pShuttle, pOwner)
	if (pOwner == nil or pShuttle == nil) then
		CreatureObject(pPlayer):sendSystemMessage("This Instant Travel Vehicle is no longer available.")
		return false
	end

	if ((tonumber(readData(SceneObject(pShuttle):getObjectID() .. ":ITV:expiresAt")) or 0) < os.time()) then
		CreatureObject(pPlayer):sendSystemMessage("This Instant Travel Vehicle is no longer available.")
		return false
	end

	if (SceneObject(pPlayer):getZoneName() ~= SceneObject(pShuttle):getZoneName()) then
		CreatureObject(pPlayer):sendSystemMessage("Only the shuttle owner and current members of the owner's group may use this Instant Travel Vehicle.")
		return false
	end

	if (not SceneObject(pShuttle):isInRangeWithObject(pPlayer, self.ITV_GROUP_USE_RANGE)) then
		CreatureObject(pPlayer):sendSystemMessage("You must be closer to the shuttle to use it.")
		return false
	end

	if (CreatureObject(pPlayer):isInCombat()) then
		CreatureObject(pPlayer):sendSystemMessage("You cannot use the Instant Travel Vehicle while in combat.")
		return false
	end

	if (CreatureObject(pPlayer):isIncapacitated() or CreatureObject(pPlayer):isDead()) then
		CreatureObject(pPlayer):sendSystemMessage("You cannot use the Instant Travel Vehicle while incapacitated or dead.")
		return false
	end

	if (SceneObject(pPlayer):getParentID() ~= 0 or CreatureObject(pPlayer):isRidingMount() or CreatureObject(pPlayer):isPilotingShip()) then
		CreatureObject(pPlayer):sendSystemMessage("You cannot use the Instant Travel Vehicle in your current state.")
		return false
	end

	if (SceneObject(pPlayer):getObjectID() == SceneObject(pOwner):getObjectID()) then
		writeData(SceneObject(pPlayer):getObjectID() .. ":ITV:lastShuttleID", SceneObject(pShuttle):getObjectID())
		return true
	end

	if (CreatureObject(pOwner):isGroupedWith(pPlayer)) then
		writeData(SceneObject(pPlayer):getObjectID() .. ":ITV:lastShuttleID", SceneObject(pShuttle):getObjectID())
		return true
	end

	CreatureObject(pPlayer):sendSystemMessage("Only the shuttle owner and current members of the owner's group may use this Instant Travel Vehicle.")
	return false
end

function InstantTravelVehicle:getDestinations(planet)
	local planetNames = { "corellia", "dantooine", "dathomir", "endor", "lok", "naboo", "rori", "talus", "tatooine", "yavin4" }
	local previousPlanetData = {}

	for i = 1, #planetNames, 1 do
		previousPlanetData[planetNames[i]] = _G[planetNames[i]]
	end

	dofile("scripts/managers/planet/planet_manager.lua")

	local planetData = _G[planet]
	local destinations = {}

	for i = 1, #planetNames, 1 do
		_G[planetNames[i]] = previousPlanetData[planetNames[i]]
	end

	if (planetData == nil or planetData.planetTravelPoints == nil) then
		self:log("no destination table for planet=" .. tostring(planet))
		return destinations
	end

	for i = 1, #planetData.planetTravelPoints, 1 do
		local point = planetData.planetTravelPoints[i]
		if (point.incomingTravelAllowed == 1) then
			table.insert(destinations, point)
		end
	end

	return destinations
end

function InstantTravelVehicle:getDestinationCount(planet)
	return #self:getDestinations(planet)
end

function InstantTravelVehicle:getCooldownRemaining(pPlayer)
	local cooldownUntil = tonumber(readScreenPlayData(pPlayer, self.screenplayName, "cooldownUntil")) or 0
	local remaining = cooldownUntil - os.time()

	if (remaining < 0) then
		return 0
	end

	return remaining
end

function InstantTravelVehicle:formatTime(seconds)
	seconds = math.max(0, tonumber(seconds) or 0)

	if (seconds >= 3600) then
		local hours = math.floor(seconds / 3600)
		local minutes = math.ceil((seconds % 3600) / 60)
		return hours .. " hour" .. (hours == 1 and "" or "s") .. (minutes > 0 and " " .. minutes .. " minute" .. (minutes == 1 and "" or "s") or "")
	end

	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60
	return minutes .. " minute" .. (minutes == 1 and "" or "s") .. (secs > 0 and " " .. secs .. " second" .. (secs == 1 and "" or "s") or "")
end

function InstantTravelVehicle:warnTwoMinutes(pPlayer)
	self:sendEligibleMessage(pPlayer, "The Instant Travel Vehicle will depart in two minutes.")
end

function InstantTravelVehicle:warnOneMinute(pPlayer)
	self:sendEligibleMessage(pPlayer, "The Instant Travel Vehicle will depart in one minute.")
end

function InstantTravelVehicle:warnThirtySeconds(pPlayer)
	self:sendEligibleMessage(pPlayer, "The Instant Travel Vehicle will depart in thirty seconds.")
end

function InstantTravelVehicle:sendEligibleMessage(pOwner, message)
	if (pOwner == nil) then
		return
	end

	CreatureObject(pOwner):sendSystemMessage(message)

	if (CreatureObject(pOwner):isGrouped()) then
		for i = 0, CreatureObject(pOwner):getGroupSize() - 1, 1 do
			local pMember = CreatureObject(pOwner):getGroupMember(i)
			if (pMember ~= nil and SceneObject(pMember):getObjectID() ~= SceneObject(pOwner):getObjectID()) then
				CreatureObject(pMember):sendSystemMessage(message)
			end
		end
	end
end

function InstantTravelVehicle:departShuttle(pPlayer)
	if (pPlayer == nil) then
		return
	end

	writeScreenPlayData(pPlayer, self.screenplayName, "state", self.STATE_DEPARTING)
	self:sendEligibleMessage(pPlayer, "The Instant Travel Vehicle has departed.")
	self:cleanupForOwner(pPlayer)
end

function InstantTravelVehicle:cleanupForOwner(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local shuttleID = tonumber(readScreenPlayData(pPlayer, self.screenplayName, "shuttleID")) or 0
	local waypointID = tonumber(readScreenPlayData(pPlayer, self.screenplayName, "waypointID")) or 0
	local pShuttle = getSceneObject(shuttleID)

	if (pShuttle ~= nil) then
		playClientEffectLoc(pPlayer, "clienteffect/space_command/shuttle_recall.cef", SceneObject(pShuttle):getZoneName(), SceneObject(pShuttle):getWorldPositionX(), SceneObject(pShuttle):getWorldPositionZ(), SceneObject(pShuttle):getWorldPositionY(), 0)
		SceneObject(pShuttle):destroyObjectFromWorld()
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost ~= nil and waypointID ~= 0) then
		PlayerObject(pGhost):removeWaypoint(waypointID, true)
	end

	deleteData(shuttleID .. ":ITV:ownerID")
	deleteData(shuttleID .. ":ITV:expiresAt")
	self:clearDeploymentState(pPlayer)
	self:log("cleanup owner=" .. SceneObject(pPlayer):getObjectID() .. " shuttle=" .. shuttleID)
end

function InstantTravelVehicle:clearDeploymentState(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	deleteData(playerID .. ":ITV:lastShuttleID")
	deleteScreenPlayData(pPlayer, self.screenplayName, "state")
	deleteScreenPlayData(pPlayer, self.screenplayName, "shuttleID")
	deleteScreenPlayData(pPlayer, self.screenplayName, "waypointID")
	deleteScreenPlayData(pPlayer, self.screenplayName, "planet")
	deleteScreenPlayData(pPlayer, self.screenplayName, "expiresAt")
	deleteScreenPlayData(pPlayer, self.screenplayName, "landingRequestedAt")
	deleteScreenPlayData(pPlayer, self.screenplayName, "landingPlanet")
	deleteScreenPlayData(pPlayer, self.screenplayName, "landingX")
	deleteScreenPlayData(pPlayer, self.screenplayName, "landingZ")
	deleteScreenPlayData(pPlayer, self.screenplayName, "landingY")
	deleteScreenPlayData(pPlayer, self.screenplayName, "landingHeading")
end

function InstantTravelVehicle:findNearbyOwnedShuttle(pPlayer)
	local playerID = SceneObject(pPlayer):getObjectID()
	local ownerID = playerID
	local pOwner = pPlayer

	for i = 0, CreatureObject(pPlayer):getGroupSize() - 1, 1 do
		local pMember = CreatureObject(pPlayer):getGroupMember(i)
		if (pMember ~= nil) then
			local shuttleID = tonumber(readScreenPlayData(pMember, self.screenplayName, "shuttleID")) or 0
			local pShuttle = getSceneObject(shuttleID)
			if (pShuttle ~= nil and SceneObject(pShuttle):isInRangeWithObject(pPlayer, self.ITV_GROUP_USE_RANGE)) then
				ownerID = SceneObject(pMember):getObjectID()
				pOwner = pMember
				writeData(playerID .. ":ITV:lastShuttleID", shuttleID)
				self:log("resolved nearby shuttle user=" .. playerID .. " owner=" .. ownerID .. " shuttle=" .. shuttleID)
				return shuttleID
			end
		end
	end

	local shuttleID = tonumber(readScreenPlayData(pOwner, self.screenplayName, "shuttleID")) or 0
	return shuttleID
end

function InstantTravelVehicle:log(message)
	printLuaError("[ITV] " .. message)
end
