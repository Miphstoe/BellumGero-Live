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
	gcwPointsPerKill = 150,   -- per-kill standing awarded to the killer's own side
}

registerScreenPlay("TalusLostAqualishScreenPlay", true)

-- === GCW award helpers (killer's own faction) =========================
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

function TalusLostAqualishScreenPlay:onMobDead(pVictim, pAttacker)
	local pKiller = _killerOrMaster(pAttacker)
	if not _validPlayer(pKiller) then return 0 end

	local side = nil
	if CreatureObject(pKiller):isRebel() then
		side = "rebel"
	elseif CreatureObject(pKiller):isImperial() then
		side = "imperial"
	else
		return 0 -- unaffiliated player: no award
	end

	local ghost = CreatureObject(pKiller):getPlayerObject()
	if ghost == nil then return 0 end

	local pts = self.gcwPointsPerKill or 15
	PlayerObject(ghost):increaseFactionStanding(side, pts)

	-- Optional toast:
	-- CreatureObject(pKiller):sendSystemMessage(string.format("+%d %s faction points (GCW Cave)", pts, side))
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

	-- Cell 4255649 (Rebel defectors)
	spawnMobile("talus", "defector_rebel_commando",   300, -27.5, -80.0, -149.6, 31, 4255649)   -- captain
	spawnMobile("talus", "defector_rebel_trooper",    300, -19.9, -79.8, -147.5, -35, 4255649)  -- marksman
	spawnMobile("talus", "defector_rebel_trooper",    300, -28.9, -79.8, -141.8, 167, 4255649)  -- marksman

	-- Cell 4255648 (Storm defectors)
	spawnMobile("talus", "defector_storm_commando",   300, -29.9, -70.5, -83.9, -87, 4255648)   -- commando
	spawnMobile("talus", "defector_storm_commando",   300, -37.2, -70.8, -87.8, -19, 4255648)   -- commando
	spawnMobile("talus", "defector_stormtrooper",     300, -43.2, -70.2, -83.2, 70, 4255648)    -- marksman
	spawnMobile("talus", "defector_storm_commando",   300, -54.7, -68.5, -110.3, -78, 4255648)  -- commando
	spawnMobile("talus", "defector_stormtrooper",     300, -60.1, -68.2, -105.2, 159, 4255648)  -- marksman

	-- Cell 4255647 (Storm defectors – second cluster)
	spawnMobile("talus", "defector_storm_commando",   300, -98.5, -70.1, -112.5, 174, 4255647)  -- captain
	spawnMobile("talus", "defector_storm_commando",   300, -91.2, -70.4, -124.9, -157, 4255647) -- commando
	spawnMobile("talus", "defector_storm_commando",   300, -118.5, -69.3, -121.0, -100, 4255647) -- commando
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
	spawnMobile("talus", "defector_stormtrooper",     300, 46.4, -46.2, -94.8, -14, 4255643)    -- lookout
	spawnMobile("talus", "defector_stormtrooper",     300, 41.2, -46.2, -56.1, -102, 4255643)   -- lookout
	spawnMobile("talus", "defector_stormtrooper",     300, 36.5, -45.5, -48.2, -115, 4255643)   -- scout
	spawnMobile("talus", "defector_stormtrooper",     300, 51.5, -46, -93.7, -40, 4255643)   -- scout

	-- Cell 4255642 (Storm defectors)
	spawnMobile("talus", "defector_stormtrooper",     300, 9.8, -40.5, -75.7, -140, 4255642)    -- outrider
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