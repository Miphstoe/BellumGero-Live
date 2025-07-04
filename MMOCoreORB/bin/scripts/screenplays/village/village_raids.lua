-- Add these new variables to the VillageRaids table
VillageRaids = ScreenPlay:new {
	-- ... existing variables ...
	
	-- NEW: Break system variables
	raidBreakData = {
		minBreakTime = 2700 * 1000, -- 45 minutes break between raids
		maxBreakTime = 3600 * 1000, -- 60 minutes break between raids
		raidDuration = 2500 * 1000,  -- 41.7 minutes (how long a raid lasts)
	},
	
	-- ... rest of existing variables ...
}

-- MODIFIED: Update doEnemySpawnPulse to include break system
function VillageRaids:doEnemySpawnPulse()
	local pMaster = VillageJediManagerTownship:getMasterObject()

	if (pMaster == nil) then
		printLuaError("VillageRaids:doEnemySpawnPulse(), unable to get master village object.")
		return
	end

	local currentPhase = VillageJediManagerTownship.getCurrentPhase()

	if (currentPhase ~= 4) then
		return
	end

	self:despawnTurrets()
	self:spawnTurrets()

	self:spawnVictims(pMaster)

	local numPlayers = self:getPlayersInVillage(pMaster)
	local spawnWaveData

	if (numPlayers >= self.playerWaveSizeThresholds.mega) then
		spawnWaveData = self.enemyWaveData.mega
	elseif (numPlayers >= self.playerWaveSizeThresholds.large) then
		spawnWaveData = self.enemyWaveData.large
	elseif (numPlayers >= self.playerWaveSizeThresholds.medium) then
		spawnWaveData = self.enemyWaveData.medium
	else
		spawnWaveData = self.enemyWaveData.small
	end

	local usedLocs = { }

	for i = 1,  #self.enemySpawnLocs, 1 do
		table.insert(usedLocs, false)
	end

	for i = 1, #spawnWaveData, 1 do
		local randomLoc = getRandomNumber(1, #self.enemySpawnLocs)

		while usedLocs[randomLoc] == true do
			randomLoc = getRandomNumber(1, #self.enemySpawnLocs)
		end

		usedLocs[randomLoc] = true
		local waveInfo = self[spawnWaveData[i]]
		local loc = getSpawnPoint("dathomir", self.enemySpawnLocs[randomLoc][1], self.enemySpawnLocs[randomLoc][2], self.enemyData.minDistance, self.enemyData.maxDistance, true)
		QuestSpawner:createQuestSpawner("VillageRaids", waveInfo[1], waveInfo[2], loc[1], loc[2], loc[3], 0, "dathomir", pMaster)
	end

	-- CHANGED: Instead of immediately scheduling next raid, schedule the break period
	local breakTime = getRandomNumber(self.raidBreakData.minBreakTime, self.raidBreakData.maxBreakTime)
	createEvent(breakTime, "VillageRaids", "doEnemySpawnPulse", pMaster, "")
	
	-- Optional: Print message for debugging
	printLuaError("VillageRaids: Raid spawned, next raid in " .. (breakTime / 60000) .. " minutes")
end