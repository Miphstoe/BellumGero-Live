-- SOLUTION 1: Manual kickstart function
function VillageRaids:kickstartRaidSystem()
	local currentPhase = VillageJediManagerTownship.getCurrentPhase()
	
	if (currentPhase ~= 4) then
		printLuaError("VillageRaids:kickstartRaidSystem() - Village not in Phase 4, current phase: " .. tostring(currentPhase))
		return false
	end
	
	local pMaster = VillageJediManagerTownship:getMasterObject()
	if (pMaster == nil) then
		printLuaError("VillageRaids:kickstartRaidSystem() - Cannot get master village object")
		return false
	end
	
	-- Check if raids are already running by looking for existing events
	-- (This is optional - you can remove this check if you want to force restart)
	
	printLuaError("VillageRaids:kickstartRaidSystem() - Starting raid system...")
	
	-- Start the first raid immediately (or with a short delay)
	createEvent(30 * 1000, "VillageRaids", "doEnemySpawnPulse", pMaster, "")
	
	printLuaError("VillageRaids:kickstartRaidSystem() - First raid will start in 30 seconds")
	return true
end

-- SOLUTION 2: Add a periodic check to ensure raids are running
function VillageRaids:ensureRaidsRunning()
	local currentPhase = VillageJediManagerTownship.getCurrentPhase()
	
	if (currentPhase ~= 4) then
		-- Schedule next check in 5 minutes
		createEvent(5 * 60 * 1000, "VillageRaids", "ensureRaidsRunning", nil, "")
		return
	end
	
	local pMaster = VillageJediManagerTownship:getMasterObject()
	if (pMaster == nil) then
		-- Schedule next check in 1 minute
		createEvent(60 * 1000, "VillageRaids", "ensureRaidsRunning", nil, "")
		return
	end
	
	-- Check if there are any active enemy spawners or recent raid activity
	-- If not, restart the raid system
	local phaseID = VillageJediManagerTownship:getCurrentPhaseID()
	local foundActiveTurret = false
	
	for i = 1, #self.turretSpawnLocs, 1 do
		local turretID = readData("Village:Turret:" .. phaseID .. ":" .. i)
		local pTurret = getSceneObject(turretID)
		if (pTurret ~= nil) then
			foundActiveTurret = true
			break
		end
	end
	
	if (not foundActiveTurret) then
		printLuaError("VillageRaids:ensureRaidsRunning() - No active turrets found, restarting raid system...")
		self:doPhaseInit()
	end
	
	-- Schedule next check in 10 minutes
	createEvent(10 * 60 * 1000, "VillageRaids", "ensureRaidsRunning", nil, "")
end

-- SOLUTION 3: Enhanced doPhaseInit that handles Phase 4 transitions better
function VillageRaids:doPhaseInit()
	local currentPhase = VillageJediManagerTownship.getCurrentPhase()
	
	printLuaError("VillageRaids:doPhaseInit() called - Current Phase: " .. tostring(currentPhase))

	if (currentPhase ~= 3 and currentPhase ~= 4) then
		printLuaError("VillageRaids:doPhaseInit() - Not in Phase 3 or 4, exiting")
		return
	end

	printLuaError("VillageRaids:doPhaseInit() - Spawning turrets...")
	self:despawnTurrets()
	self:spawnTurrets()

	if (currentPhase == 4) then
		printLuaError("VillageRaids:doPhaseInit() - Phase 4 detected, starting enemy spawn pulse in 2 minutes...")
		local pMaster = VillageJediManagerTownship:getMasterObject()
		if (pMaster ~= nil) then
			-- Start raids in 2 minutes to give turrets time to fully spawn
			createEvent(2 * 60 * 1000, "VillageRaids", "doEnemySpawnPulse", pMaster, "")
			
			-- Also start the monitoring system
			createEvent(10 * 60 * 1000, "VillageRaids", "ensureRaidsRunning", nil, "")
		else
			printLuaError("VillageRaids:doPhaseInit() - Cannot get master object for Phase 4 raids")
		end
	else
		printLuaError("VillageRaids:doPhaseInit() - Phase 3 detected, turrets only (no raids)")
	end
end

-- SOLUTION 4: Server restart recovery function
function VillageRaids:serverStartupCheck()
	local currentPhase = VillageJediManagerTownship.getCurrentPhase()
	
	printLuaError("VillageRaids:serverStartupCheck() - Current Phase: " .. tostring(currentPhase))
	
	if (currentPhase == 4) then
		printLuaError("VillageRaids:serverStartupCheck() - Village in Phase 4, starting raid system...")
		self:kickstartRaidSystem()
		
		-- Start monitoring
		createEvent(10 * 60 * 1000, "VillageRaids", "ensureRaidsRunning", nil, "")
	elseif (currentPhase == 3) then
		printLuaError("VillageRaids:serverStartupCheck() - Village in Phase 3, spawning turrets only...")
		self:despawnTurrets()
		self:spawnTurrets()
	end
end