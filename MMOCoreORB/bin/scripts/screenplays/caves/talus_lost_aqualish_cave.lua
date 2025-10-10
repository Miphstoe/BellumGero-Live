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
	gcwPointsPerKill = 150,

	-- === Daily task tuning ===
	dailyKillTarget     = 25,
	dailyCooldownSecs   = 72000,   -- 20h
	dailyAwardFaction   = 1500,
	dailyAwardCredits   = 60000,
	dailyRange          = 64,

	-- === Daily loot reward (optional) =========================================
	-- Fill this with your item templates to enable extra rewards on turn-in.
	-- Each entry: { template = "<path.iff>", weight = <number> }  (weight defaults to 1)
	-- Example:
	-- dailyLootPool = {
	--   { template = "object/tangible/loot/loot_schematic/sword_marauder_schematic.iff", weight = 5 },
	--   { template = "object/tangible/loot/collection/krayt_pearls_generic.iff",          weight = 15 },
	--   { template = "object/tangible/loot/generic_usable/armband_s01.iff",                weight = 80 },
	-- },
	dailyLootPool   = {
		{ template = "object/tangible/furniture/all/frn_all_banner_rebel.iff", weight = 5 },
		{ template = "object/tangible/furniture/all/frn_all_banner_imperial.iff", weight = 5 },
		{ template = "object/tangible/furniture/imperial/table_s1.iff", weight = 5 },
		{ template = "object/tangible/furniture/gcw/gcw_rebel_rug_01.iff", weight = 5 },
		{ template = "object/tangible/furniture/gcw/gcw_imperial_rug_01.iff", weight = 5 },
		{ template = "object/tangible/furniture/all/frn_all_jedi_council_seat.iff", weight = 5 },
	},
	dailyLootCount  = 1,     -- how many rolls from the pool to award
	dailyLootMsg    = "You received a reward item from the cave assignment.",
}

registerScreenPlay("TalusLostAqualishScreenPlay", true)

-- === GCW award helpers (group-aware; each player gets points to their own side) ===
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

-- === Daily task helpers (writeData/readData/deleteData; no ObjVars) ===========
local DAILY_PREFIX = "gcwCaveDaily:"
local K_ACTIVE = "active"
local K_KILLS  = "kills"
local K_RESET  = "reset"

function TalusLostAqualishScreenPlay:now()
	return getTimestamp()
end

local function _pid(p) return tostring(SceneObject(p):getObjectID()) end
local function _key(p, tag) return DAILY_PREFIX .. _pid(p) .. ":" .. tag end
local function _dget(p, tag, default) local v = readData(_key(p, tag)); if v == nil then return default end; return v end
local function _dset(p, tag, val) writeData(_key(p, tag), val) end
local function _ddel(p, tag) deleteData(_key(p, tag)) end
local function _dhas(p, tag) local v = readData(_key(p, tag)); return v ~= nil and v ~= 0 end

function TalusLostAqualishScreenPlay:formatTime(secs)
	if secs <= 0 then return "0s" end
	local h = math.floor(secs / 3600)
	local m = math.floor((secs % 3600) / 60)
	local s = secs % 60
	if h > 0 then return string.format("%dh %dm", h, m) end
	if m > 0 then return string.format("%dm %ds", m, s) end
	return string.format("%ds", s)
end

function TalusLostAqualishScreenPlay:_clearDaily(pPlayer)
	_ddel(pPlayer, K_ACTIVE)
	_ddel(pPlayer, K_KILLS)
end

function TalusLostAqualishScreenPlay:_resetIfExpired(pPlayer)
	local resetAt = _dget(pPlayer, K_RESET, 0)
	if resetAt > 0 and self:now() >= resetAt then
		self:_clearDaily(pPlayer)
		_ddel(pPlayer, K_RESET)
	end
end

function TalusLostAqualishScreenPlay:isDailyOnCooldown(pPlayer)
	self:_resetIfExpired(pPlayer)
	local resetAt = _dget(pPlayer, K_RESET, 0)
	return resetAt > 0 and self:now() < resetAt and not _dhas(pPlayer, K_ACTIVE)
end

function TalusLostAqualishScreenPlay:getDailyCooldownRemaining(pPlayer)
	local resetAt = _dget(pPlayer, K_RESET, 0)
	return math.max(0, resetAt - self:now())
end

function TalusLostAqualishScreenPlay:startDaily(pPlayer, side)
	self:_resetIfExpired(pPlayer)
	if self:isDailyOnCooldown(pPlayer) then return false end
	_dset(pPlayer, K_ACTIVE, 1)
	_dset(pPlayer, K_KILLS, 0)
	_dset(pPlayer, K_RESET, self:now() + (self.dailyCooldownSecs or 72000))
	return true
end

function TalusLostAqualishScreenPlay:getDailyProgress(pPlayer)
	self:_resetIfExpired(pPlayer)
	local active = _dhas(pPlayer, K_ACTIVE)
	local kills  = _dget(pPlayer, K_KILLS, 0)
	local target = self.dailyKillTarget or 25
	local rem    = self:getDailyCooldownRemaining(pPlayer)
	return kills, target, active, rem
end

function TalusLostAqualishScreenPlay:_incDaily(pPlayer)
	if not _dhas(pPlayer, K_ACTIVE) then return end
	local k = _dget(pPlayer, K_KILLS, 0) + 1
	_dset(pPlayer, K_KILLS, k)
	if (k % 5) == 0 then
		CreatureObject(pPlayer):sendSystemMessage(string.format("Daily progress: %d / %d.", k, self.dailyKillTarget or 25))
	end
end

function TalusLostAqualishScreenPlay:_advanceDailyGroup(pSource, pVictim)
	if pSource == nil or pVictim == nil then return end
	local range = self.dailyRange or 64
	local function tick(pTgt)
		if SceneObject(pTgt):isPlayerCreature() and SceneObject(pTgt):isInRangeWithObject(pVictim, range) then
			self:_incDaily(pTgt)
		end
	end
	local co = CreatureObject(pSource)
	if co.isGrouped and co:isGrouped() then
		for i = 0, co:getGroupSize() - 1 do tick(co:getGroupMember(i)) end
	else
		tick(pSource)
	end
end

-- === Daily loot helpers ======================================================
function TalusLostAqualishScreenPlay:_rollFromPool(pool)
	if pool == nil or #pool == 0 then return nil end
	local total = 0
	for _, e in ipairs(pool) do total = total + (e.weight or 1) end
	if total <= 0 then return nil end
	local r = getRandomNumber(total - 1) + 1
	local acc = 0
	for _, e in ipairs(pool) do
		acc = acc + (e.weight or 1)
		if r <= acc then return e.template end
	end
	return nil
end

function TalusLostAqualishScreenPlay:_giveDailyLoot(pPlayer)
	local pool = self.dailyLootPool
	if pool == nil or #pool == 0 then return false, "No daily loot configured." end

	local pInv = SceneObject(pPlayer):getSlottedObject("inventory")
	if pInv == nil then return false, "Inventory not found." end

	local count = math.max(1, self.dailyLootCount or 1)
	local awarded = 0
	for i = 1, count do
		local tpl = self:_rollFromPool(pool)
		if tpl ~= nil then
			local pItem = giveItem(pInv, tpl, -1)
			if pItem ~= nil then
				awarded = awarded + 1
			end
		end
	end

	if awarded > 0 then
		CreatureObject(pPlayer):sendSystemMessage(self.dailyLootMsg or "You received a reward item.")
		return true
	else
		return false, "Could not create the reward item (inventory full?)."
	end
end

function TalusLostAqualishScreenPlay:completeDaily(pPlayer)
	local kills, target, active, _ = self:getDailyProgress(pPlayer)
	if not active then
		return false, "No active assignment. Speak to your liaison to begin."
	end
	if kills < target then
		return false, string.format("Assignment incomplete: %d / %d.", kills, target)
	end

	local side = _playerSideString(pPlayer)
	if side ~= nil then
		local ghost = CreatureObject(pPlayer):getPlayerObject()
		if ghost ~= nil then
			PlayerObject(ghost):increaseFactionStanding(side, self.dailyAwardFaction or 1500)
		end
	end
	CreatureObject(pPlayer):addCashCredits(self.dailyAwardCredits or 25000, true)

	-- Optional loot reward from the pool (harmless if not configured)
	local okLoot, why = self:_giveDailyLoot(pPlayer)
	if not okLoot and why then
		CreatureObject(pPlayer):sendSystemMessage(why)
	end

	self:_clearDaily(pPlayer)
	return true, "Assignment complete. Debrief recorded and rewards issued."
end
-- ============================================================================

function TalusLostAqualishScreenPlay:onMobDead(pVictim, pAttacker)
	local pKiller = _killerOrMaster(pAttacker)
	if not _validPlayer(pKiller) then return 0 end

	local pts = self.gcwPointsPerKill or 15
	_awardFactionNearby(self, pKiller, pVictim, pts, 64)

	self:_advanceDailyGroup(pKiller, pVictim)
	return 0
end
-- ============================================================================

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
	spawnMobile("talus", "defector_rebel_commando",   300, -66.3, -70.1, -198.1, 119, 4255647)  -- outrider
	spawnMobile("talus", "defector_rebel_commando",   300, -60.2, -70, -195.7, -107, 4255647)   -- outrider
	spawnMobile("talus", "defector_rebel_commando",   300, -64.1, -69.5, -190.8, -178, 4255647) -- outrider

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
	spawnMobile("talus", "defector_storm_commando",   300, 50, -48.2, -125.9, -33, 4255644)     -- scout
	spawnMobile("talus", "defector_storm_commando",   300, 46.8, -47.9, -121.3, 132, 4255644)   -- scout

	-- Cell 4255643 (Storm defectors)
	spawnMobile("talus", "defector_stormtrooper",     300, 46.4, -46.2, -94.8, -14, 4255643)    -- lookout
	spawnMobile("talus", "defector_stormtrooper",     300, 41.2, -46.2, -56.1, -102, 4255643)   -- lookout
	spawnMobile("talus", "defector_stormtrooper",     300, 36.5, -45.5, -48.2, -115, 4255643)   -- scout
	spawnMobile("talus", "defector_stormtrooper",     300, 51.5, -46, -93.7, -40, 4255643)      -- scout

	-- Cell 4255642 (Storm defectors)
	spawnMobile("talus", "defector_stormtrooper",     300, 9.8, -40.5, -75.7, -140, 4255642)    -- outrider
	spawnMobile("talus", "defector_stormtrooper",     300, 3.4, -40.4, -65.0, -44, 4255642)     -- lookout
	spawnMobile("talus", "defector_stormtrooper",     300, -9.8, -40.9, -66.7, -12, 4255642)    -- lookout
	spawnMobile("talus", "defector_storm_commando",   300, -8.8, -40.4, -81.3, 15, 4255642)     -- lookout

	-- Cell 4255641 (Storm defectors)
	spawnMobile("talus", "defector_stormtrooper",     300, -8.3, -30.9, -31.2, 28, 4255641)     -- scout
	spawnMobile("talus", "defector_stormtrooper",     300, 10.3, -23.3, -23.5, 170, 4255641)    -- lookout

	-- Outside (Storm defectors)
	spawnMobile("talus", "defector_stormtrooper",     300, -4330.4, 35.1, -1415.0, 82, 0)       -- lookout
	spawnMobile("talus", "defector_stormtrooper",     300, -4346.2, 32.4, -1447.3, 157, 0)      -- lookout
	spawnMobile("talus", "defector_stormtrooper",     300, -4348.2, 32.4, -1448.2, 178, 0)      -- lookout
	spawnMobile("talus", "defector_rebel_trooper",     300, -4332.6, 30.8, -1438.1, 128, 0)     -- lookout
	spawnMobile("talus", "defector_rebel_trooper",     300, -4328.5, 32.9, -1421.3, 48, 0)      -- lookout

	-- === Convenience NPCs outside (updated coords) ===
	-- Imperial recruiter + daily liaison
	spawnMobile("talus", "imperial_recruiter", 0, -4394.9, 80.4, -1468.9, 59, 0)
	spawnMobile("talus", "gcw_cave_imperial_officer", 0, -4393.8, 79.4, -1466.3, 59, 0)

	-- Rebel recruiter + daily liaison
	spawnMobile("talus", "rebel_recruiter", 0, -4341.1, 85.5, -1358.3, 171, 0)
	spawnMobile("talus", "gcw_cave_rebel_officer", 0, -4344.0, 85.4, -1358.9, 179, 0)
end