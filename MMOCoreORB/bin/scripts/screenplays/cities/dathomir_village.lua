--[[
	Dathomir Village Screenplay
	Created for adding mission terminal and other village amenities
--]]

DathomirVillageScreenPlay = ScreenPlay:new {
	numberOfActs = 1,
	planet = "dathomir",
}

registerScreenPlay("DathomirVillageScreenPlay", true)

function DathomirVillageScreenPlay:start()
	if (isZoneEnabled(self.planet)) then
		self:spawnSceneObjects()
	end
end

function DathomirVillageScreenPlay:spawnSceneObjects()
	-- Dathomir Village coordinates
	local villageX = 5257
	local villageY = 78
	local villageZ = -4222
	
	-- Mission Terminal
	local pTerminal = spawnSceneObject(self.planet, "object/tangible/terminal/terminal_mission.iff", villageX, villageY, villageZ, 0, math.rad(180))
	if pTerminal ~= nil then
		SceneObject(pTerminal):setCustomObjectName("Mission Terminal")
		createObserver(OBJECTRADIALUSED, "MissionTerminal", "onTerminalUsed", pTerminal)
	end
	
	-- Shuttleport
	--local pShuttle<<< ShuttleportVillageport = spawnSceneObject(self.planet, "object/building/general/shuttleport_corellia.iff", villageX - 50, villageY, villageZ + 50, 0, math.rad(0))
	--if pShuttleport ~= nil then
	--	SceneObject(pShuttleport):setCustomObjectName("Dathomir Village Shuttleport")
	--end
	
	-- Shuttle Terminal (inside the shuttleport)
	--local pShuttleTerminal = spawnSceneObject(self.planet, "object/tangible/terminal/terminal_travel.iff", villageX - 50, villageY + 0.2, villageZ + 50, getCellId(pShuttleport, 1), math.rad(180))
	--if pShuttleTerminal ~= nil then
	--	SceneObject(pShuttleTerminal):setCustomObjectName("Shuttle Terminal")
	--end
	
	-- Removed terminals (uncomment if needed later):
	--[[
	-- Bank Terminal
	local pBank = spawnSceneObject(self.planet, "object/tangible/terminal/terminal_bank.iff", villageX - 3, villageY, villageZ - 2, 0, math.rad(90))
	if pBank ~= nil then
		SceneObject(pBank):setCustomObjectName("Bank Terminal")
	end
	
	-- Insurance Terminal  
	local pInsurance = spawnSceneObject(self.planet, "object/tangible/terminal/terminal_insurance.iff", villageX + 5, villageY, villageZ + 3, 0, math.rad(270))
	if pInsurance ~= nil then
		SceneObject(pInsurance):setCustomObjectName("Insurance Terminal")
	end
	
	-- Bounty Mission Terminal
	local pBounty = spawnSceneObject(self.planet, "object/tangible/terminal/terminal_mission_bounty.iff", villageX - 8, villageY, villageZ + 1, 0, math.rad(45))
	if pBounty ~= nil then
		SceneObject(pBounty):setCustomObjectName("Bounty Terminal")
		createObserver(OBJECTRADIALUSED, "BountyMissionTerminal", "onTerminalUsed", pBounty)
	end
	
	-- Cloning Facility
	local pCloner = spawnSceneObject(self.planet, "object/tangible/terminal/terminal_cloning.iff", villageX + 10, villageY, villageZ - 8, 0, math.rad(0))
	if pCloner ~= nil then
		SceneObject(pCloner):setCustomObjectName("Cloning Terminal")
	end
	--]]
	
	-- Decorative Objects
	
	-- Some crates for atmosphere
	--spawnSceneObject(self.planet, "object/tangible/container/drum/cargo_drum_1.iff", villageX + 15, villageY, villageZ + 12, 0, math.rad(45))
	--spawnSceneObject(self.planet, "object/tangible/container/drum/cargo_drum_2.iff", villageX + 17, villageY, villageZ + 10, 0, math.rad(90))
	
	-- Landing lights
	--spawnSceneObject(self.planet, "object/static/particle/pt_poi_electricity_2x2.iff", villageX - 20, villageY, villageZ - 20, 0, 0)
	--spawnSceneObject(self.planet, "object/static/particle/pt_poi_electricity_2x2.iff", villageX + 20, villageY, villageZ - 20, 0, 0)
	--spawnSceneObject(self.planet, "object/static/particle/pt_poi_electricity_2x2.iff", villageX - 20, villageY, villageZ + 20, 0, 0)
	--spawnSceneObject(self.planet, "object/static/particle/pt_poi_electricity_2x2.iff", villageX + 20, villageY, villageZ + 20, 0, 0)
	
	-- Some vendor NPCs (optional)
	--local pVendor = spawnMobile(self.planet, "junk_dealer", 300, villageX + 8, villageY, villageZ + 5, math.rad(225), 0)
	--if pVendor ~= nil then
	--	CreatureObject(pVendor):setCustomObjectName("Junk Dealer")
	--end
end