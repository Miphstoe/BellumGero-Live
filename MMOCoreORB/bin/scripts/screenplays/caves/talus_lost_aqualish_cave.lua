TalusLostAqualishScreenPlay = ScreenPlay:new {
	numberOfActs = 1,

	screenplayName = "TalusLostAqualishScreenPlay",

	lootContainers = {
		178362,
		6075911,
		6075912,
		6075913,
		6075914
	},

	lootLevel = 150,

	lootGroups = {
		{
			groups = {
				{group = "color_crystals", chance = 160000},
				{group = "junk", chance = 8240000},
				{group = "weapons_all", chance = 1000000},
				{group = "clothing_attachments", chance = 300000},
				{group = "armor_attachments", chance = 300000}
			},
			lootChance = 8000000
		}
	},

	lootContainerRespawn = 1800,

	-- === GCW award tuning ===
	gcwPointsPerKill = 150,   -- per-kill standing awarded (now fan-out to group)
}

registerScreenPlay("TalusLostAqualishScreenPlay", true)

-- === GCW award helpers (group-aware; each player gets points to their own side) =========
local function _validPlayer(p)
	return p ~= nil and SceneObject(p):isPlayerCreature()
end

local function _killerOrMaster(pAttacker)
	if pAttacker == nil then return nil end
	if SceneObject(pAttacker):isPlayerCreature() then return pAttacker end
	local pMaster = CreatureObject(pAttacker):getMaster()
	if pMaster ~= nil and SceneObject(pMaster):isPlayerCreature() then return pMaster end
	return nil
end

local function _playerSideString(pPlayer)
	if pPlayer == nil then return nil end
	local co = CreatureObject(pPlayer)
	if co:isRebel() then return "rebel" end
	if co:isImperial() then return "imperial" end
	return nil
end

-- Award to killer or group members within range of the victim.
-- Each recipient is awarded to THEIR OWN side (rebel/imperial). Unaffiliated players are skipped.
local function _awardFactionNearby(self, pSource, pVictim, amount, range)
	if pSource == nil or pVictim == nil then return end
	local function grant(pTgt)
		if not _validPlayer(pTgt) then return end
		if not SceneObject(pTgt):isInRangeWithObject(pVictim, range or 64) then return end
		local side = _playerSideString(pTgt)
		if side == nil then return end
		local ghost = CreatureObject(pTgt):getPlayerObject()
		if ghost ~= nil then PlayerObject(ghost):increaseFactionStanding(side, amount) end
	end
	local co = CreatureObject(pSource)
	if co.isGrouped and co:isGrouped() then
		for i = 0, co:getGroupSize() - 1 do grant(co:getGroupMember(i)) end
	else
		grant(pSource)
	end
end

function TalusLostAqualishScreenPlay:onMobDead(pVictim, pAttacker)
	local pKiller = _killerOrMaster(pAttacker)
	if not _validPlayer(pKiller) then return 0 end

	local pts = self.gcwPointsPerKill or 15
	_awardFactionNearby(self, pKiller, pVictim, pts, 64)
	-- Optional toast per recipient can be added inside _awardFactionNearby if desired.
	return 0
end
-- =====================================================================

function TalusLostAqualishScreenPlay:start()
	if (isZoneEnabled("talus")) then
		self:spawnMobiles()
		self:initializeLootContainers()
	end
end

function TalusLostAqualishScreenPlay:spawnMobiles()
	-- Attach a death observer to every spawn in this function (positions unchanged)
	local _spawnMobile_engine = spawnMobile
	local function spawnMobile(planet, template, respawn, x, y, z, heading, cellOrWorld)
		local pMob = _spawnMobile_engine(planet, template, respawn, x, y, z, heading, cellOrWorld)
		if pMob ~= nil then
			createObserver(OBJECTDESTRUCTION, "TalusLostAqualishScreenPlay", "onMobDead", pMob)
		end
		return pMob
	end

	-- Cell 4255650 (Rebel defectors)
	spawnMobile("talus", "defector_rebel_commando", 300, -94.5, -100.8, -101.9, 171, 4255650)   -- warchief
	spawnMobile("talus", "defector_rebel_commando", 300, -101.6, -99.1, -106.2, 148, 4255650)   -- commando
	spawnMobile("talus", "defector_rebel_commando", 300, -85.6, -101.7, -111.7, -177, 4255650)  -- commando

	-- Cell 4255647 (Storm defectors)
	spawnMobile("talus", "defector_storm_commando",   300, -72.1, -98.0, -150.8, 149, 4255647)  -- captain
	spawnMobile("talus", "defector_stormtrooper",     300, -64.2, -94.4, -153.2, -94, 4255647)  -- infiltrator
	spawnMobile("talus", "defector_stormtrooper",     300, -70.9, -97.3, -145.3, -160, 4255647) -- infiltrator
	spawnMobile("talus", "defector_stormtrooper",     300, -78.2, -99.6, -132.2, 177, 4255647)  -- outrider
	spawnMobile("talus", "defector_stormtrooper",     300, -77.2, -99.6, -143.4, -4, 4255647)   -- outrider
	spawnMobile("talus", "defector_stormtrooper",     300, -86.2, -102.8, -133.3, 60, 4255647)  -- outrider
	spawnMobile("talus", "defector_stormtrooper",     300, -89.8, -104.8, -131.2, 21, 4255647)  -- outrider
	spawnMobile("talus", "defector_storm_commando",   300, -77.5, -97.0, -145.9, -160, 4255647) -- commando
	spawnMobile("talus", "defector_stormtrooper",     300, -83.0, -94.6, -149.0, -90, 4255647)  -- scout

	-- Cell 4255649 (Rebel defectors)
	spawnMobile("talus", "defector_rebel_commando",   300, -103.0, -94.9, -110.6, 152, 4255649) -- commando
	spawnMobile("talus", "defector_rebel_commando",   300, -108.7, -94.1, -120.4, -146, 4255649) -- commando
	spawnMobile("talus", "defector_rebel_trooper",    300, -102.7, -92.5, -128.7, -154, 4255649) -- outrider
	spawnMobile("talus", "defector_rebel_trooper",    300, -93.6, -91.0, -125.2, 89, 4255649)    -- outrider
	spawnMobile("talus", "defector_rebel_commando",   300, -103.1, -92.4, -126.7, -68, 4255649)  -- captain

	-- Cell 4255648 (Rebel defectors)
	spawnMobile("talus", "defector_rebel_trooper",    300, -120.2, -76.2, -130.9, -142, 4255648) -- outrider
	spawnMobile("talus", "defector_rebel_trooper",    300, -107.4, -74.7, -119.2, 46, 4255648)   -- outrider
	spawnMobile("talus", "defector_rebel_commando",   300, -99.5, -75.4, -119.4, -54, 4255648)   -- commando
	spawnMobile("talus", "defector_rebel_commando",   300, -112.6, -77.3, -136.0, -36, 4255648)  -- captain
	spawnMobile("talus", "defector_rebel_trooper",    300, -106.0, -72.3, -149.9, -141, 4255648) -- outrider
	spawnMobile("talus", "defector_rebel_trooper",    300, -101.0, -71.7, -153.2, -114, 4255648) -- outrider
	spawnMobile("talus", "defector_rebel_commando",   300, -94.5, -71.2, -154.7, -77, 4255648)   -- commando

	-- Cell 4255647 (Storm defectors)
	spawnMobile("talus", "defector_stormtrooper",     300, -98.1, -70.1, -152.9, -88, 4255647)  -- outrider
	spawnMobile("talus", "defector_stormtrooper",     300, -106.1, -69.8, -151.8, 53, 4255647)  -- outrider
	spawnMobile("talus", "defector_storm_commando",   300, -119.5, -69.6, -125.7, 33, 4255647)  -- commando
	spawnMobile("talus", "defector_stormtrooper",     300, -116.8, -69.5, -123.9, -55, 4255647) -- marksman
	spawnMobile("talus", "defector_storm_commando",   300, -123.4, -69.2, -170.0, 98, 4255647)  -- captain
	spawnMobile("talus", "defector_stormtrooper",     300, -119.4, -69.5, -173.1, 37, 4255647)  -- outrider
	spawnMobile("talus", "defector_stormtrooper",     300, -116.5, -69.2, -172.5, -36, 4255647) -- outrider
	spawnMobile("talus", "defector_storm_commando",   300, -116.2, -68.9, -170.1, -118, 4255647) -- commando
	spawnMobile("talus", "defector_storm_commando",   300, -118.9, -69.0, -167.9, 171, 4255647) -- captain
	spawnMobile("talus", "defector_stormtrooper",     300, -39.8, -67.6, -180.9, -90, 4255647)  -- outrider
	spawnMobile("talus", "defector_rebel_commando",     300, -66.3, -70.1, -198.1, 119, 4255647)  -- outrider
	spawnMobile("talus", "defector_rebel_commando",     300, -60.2, -70, -195.7, -107, 4255647)  -- outrider
	spawnMobile("talus", "defector_rebel_commando",     300, -64.1, -69.5, -190.8, -178, 4255647)  -- outrider

	-- Cell 4255646 (Rebel defectors)
	spawnMobile("talus", "defector_rebel_commando",   300, -18.5, -63.7, -258.8, -38, 4255646)  -- warchief
	spawnMobile("talus", "defector_rebel_commando",   300, -20.3, -65.6, -242.0, 29, 4255646)   -- commando
	spawnMobile("talus", "defector_rebel_trooper",    300, -7.9, -64.0, -227.5, -16, 4255646)   -- marksman
	spawnMobile("talus", "defector_rebel_trooper",    300, -16.5, -65.2, -218.6, -77, 4255646)  -- outrider

	-- Cell 4255644 (Storm defectors)
	spawnMobile("talus", "defector_stormtrooper",     300, 45.3, -56.3, -181.2, 138, 4255644)   -- scout
	spawnMobile("talus", "defector_stormtrooper",     300, 63.7, -56.9, -176.5, 61, 4255644)    -- scout
	spawnMobile("talus", "defector_stormtrooper",     300, 61.6, -55.4, -154.0, -62, 4255644)   -- outrider
	spawnMobile("talus", "defector_storm_commando",   300, 38.6, -56.0, -157.3, -131, 4255644)  -- captain
	spawnMobile("talus", "defector_storm_commando",   300, -9.2, -45.6, -147.3, 63, 4255644)    -- captain
	spawnMobile("talus", "defector_stormtrooper",     300, -10.8, -45.0, -131.2, -60, 4255644)  -- outrider
	spawnMobile("talus", "defector_stormtrooper",     300, 4.7, -44.9, -131.6, 36, 4255644)     -- scout
	spawnMobile("talus", "defector_storm_commando",     300, 50, -48.2, -125.9, -33, 4255644)     -- scout
	spawnMobile("talus", "defector_storm_commando",     300, 46.8, -47.9, -121.3, 132, 4255644)     -- scout

	-- Cell 4255643 (Storm defectors)
	spawnMobile("talus", "defector_stormtrooper",     300, 62.0, -49.9, -110.3, -157, 4255643)  -- outrider
	spawnMobile("talus", "defector_stormtrooper",     300, 55.8, -48.6, -116.3, -28, 4255643)   -- outrider
	spawnMobile("talus", "defector_stormtrooper",     300, 64.8, -49.7, -100.1, 138, 4255643)   -- scout
	spawnMobile("talus", "defector_stormtrooper",     300, 57.9, -48.0, -94.4, 92, 4255643)     -- scout
	spawnMobile("talus", "defector_stormtrooper",     300, 73.5, -51.7, -97.7, -42, 4255643)    -- outrider
	spawnMobile("talus", "defector_stormtrooper",     300, 49.7, -47.4, -101.3, -173, 4255643)  -- outrider
	spawnMobile("talus", "defector_stormtrooper",     300, 44.2, -45.7, -99.8, 142, 4255643)    -- scout
	spawnMobile("talus", "defector_stormtrooper",     300, 36.7, -44.7, -93.9, -150, 4255643)   -- outrider
	spawnMobile("talus", "defector_stormtrooper",     300, 40.6, -44.9, -102.1, -124, 4255643)  -- outrider
	spawnMobile("talus", "defector_stormtrooper",     300, 30.5, -42.8, -104.7, -12, 4255643)   -- outrider

	-- Cell 4255642 (Storm defectors)
	spawnMobile("talus", "defector_stormtrooper",     300, -8.7, -41.1, -92.5, -48, 4255642)    -- outrider
	spawnMobile("talus", "defector_stormtrooper",     300, -8.1, -40.6, -86.1, -129, 4255642)   -- outrider
	spawnMobile("talus", "defector_stormtrooper",     300, -1.0, -39.9, -80.8, -57, 4255642)    -- outrider
	spawnMobile("talus", "defector_stormtrooper",     300, 3.4, -40.4, -65.0, -44, 4255642)     -- lookout
	spawnMobile("talus", "defector_stormtrooper",     300, -9.8, -40.9, -66.7, -12, 4255642)    -- lookout
	spawnMobile("talus", "defector_storm_commando",     300, -8.8, -40.4, -81.3, 15, 4255642)    -- lookout

	-- Cell 4255641 (Storm defectors)
	spawnMobile("talus", "defector_stormtrooper",     300, -8.3, -30.9, -31.2, 28, 4255641)     -- scout
	spawnMobile("talus", "defector_stormtrooper",     300, 10.3, -23.3, -23.5, 170, 4255641)    -- lookout

	-- Outside (Storm defectors)
	spawnMobile("talus", "defector_stormtrooper",     300, -4330.4, 35.1, -1415.0, 82, 0)       -- lookout
	spawnMobile("talus", "defector_stormtrooper",     300, -4346.2, 32.4, -1447.3, 157, 0)      -- lookout
	spawnMobile("talus", "defector_stormtrooper",     300, -4348.2, 32.4, -1448.2, 178, 0)      -- lookout
	spawnMobile("talus", "defector_rebel_trooper",     300, -4332.6, 30.8, -1438.1, 128, 0)      -- lookout
	spawnMobile("talus", "defector_rebel_trooper",     300, -4328.5, 32.9, -1421.3, 48, 0)      -- lookout
end