-- Varn Kessic, the Scourge of Taanab: Taanab world boss as a Norulac raid on the Arcon hex farms.
-- A galaxy warning, two raider waves, then Kessic lands with his honor guard. He cannot be attacked while any guard
-- stands, calls reinforcements at 75/50/25% health and throws thermal detonators below 25%. Unkilled raids retreat
-- after RAID_TIMEOUT. Rewards are per player via WorldBossLootManager (like Rimeclaw).
local TAG = "[TAANAB-KESSIC-WB]"
local function logf(fmt, ...)
	local s = string.format(TAG .. " " .. fmt, ...)
	if printLuaError then printLuaError(s) else print(s) end
end

local WorldBossLootManager = require("screenplays.managers.world_boss_loot_manager")

TaanabNorulacRaidWorldBoss = ScreenPlay:new {
	numberOfActs = 1,
	screenplayName = "TaanabNorulacRaidWorldBoss",

	planet = "taanab",
	x = -2970.0, y = -150.0, -- Arcon hex farms

	bossTemplate = "taanab_varn_kessic",
	bossName = "Varn Kessic, the Scourge of Taanab",
	guardTemplate = "norulac_honor_guard",
	guardCount = 4,

	FIRST_RAID_DELAY = 1800, -- seconds after boot
	RAID_INTERVAL = 10800, -- after a kill or a retreat
	WARNING_LEAD = 300, -- warning -> Kessic lands
	RAID_TIMEOUT = 2700, -- Kessic retreats if still alive
	DETONATOR_EVERY = 15,
	DETONATOR_RADIUS = 8,
	DETONATOR_DAMAGE = 4000,

	waves = {
		{delay = 60, mobs = {{"norulac_raider", 4}, {"norulac_cutthroat", 2}}},
		{delay = 180, mobs = {{"norulac_raider", 3}, {"norulac_cutthroat", 2}, {"norulac_enforcer", 2}}},
	},
	reinforcements = {
		[75] = {{"norulac_enforcer", 2}, {"norulac_cutthroat", 2}},
		[50] = {{"norulac_enforcer", 3}, {"norulac_raider", 2}},
		[25] = {{"norulac_enforcer", 4}},
	},

	-- WorldBossLootManager: 3 items per player, each from a randomly chosen collection (lootChance is ignored)
	lootGroups = {
		{ groups = { {group = "taanab_norulac_loot", chance = 10000000} }, lootChance = 10000000 },
		{
			groups = {
				{group = "krayt_tissue_rare", chance = 3000000},
				{group = "color_crystals", chance = 2000000},
				{group = "power_crystals", chance = 2000000},
				{group = "armor_attachments", chance = 1500000},
				{group = "clothing_attachments", chance = 1500000}
			},
			lootChance = 10000000
		},
		{ groups = { {group = "krayt_pearls", chance = 10000000} }, lootChance = 5000000 },
		{ groups = { {group = "house_deeds", chance = 10000000} }, lootChance = 2000000 },
		{ groups = { {group = "endgame_weapon_schematics", chance = 10000000} }, lootChance = 1500000 },
		{ groups = { {group = "bg_token_group", chance = 10000000} }, lootChance = 350000 }
	},
}

registerScreenPlay("TaanabNorulacRaidWorldBoss", true)

-- Raid state lives in shared memory (screenplay events can run in different Lua states). It is not persisted,
-- and raid mobiles do not respawn, so a restart begins with no raid.
local K = "TaanabKessic:"
local function getN(k) return tonumber(readData(K .. k)) or 0 end
local function setN(k, v) writeData(K .. k, v) end
local function getS(k) return readStringData(K .. k) or "" end
local function setS(k, v) writeStringData(K .. k, v) end

local function addOID(oid)
	local s = getS("adds")
	setS("adds", s == "" and tostring(oid) or (s .. "," .. oid))
end

local function galaxyBroadcast(msg, ctx)
	if type(broadcastToGalaxy) ~= "function" then return false end
	if ctx and pcall(broadcastToGalaxy, ctx, msg) then return true end
	if pcall(broadcastToGalaxy, nil, msg) then return true end
	return pcall(broadcastToGalaxy, msg)
end

local function floorZ(planet, x, y)
	local z = 0
	pcall(function() z = getWorldFloor(x, y, planet) or 0 end)
	return z
end

function TaanabNorulacRaidWorldBoss:start()
	if not isZoneEnabled(self.planet) then return end
	setN("active", 0)
	self:scheduleRaid(self.FIRST_RAID_DELAY)
end

function TaanabNorulacRaidWorldBoss:scheduleRaid(seconds)
	local id = getN("raidId") + 1
	setN("raidId", id)
	createEvent(seconds * 1000, "TaanabNorulacRaidWorldBoss", "beginRaid", nil, tostring(id))
	logf("raid %d scheduled in %d s", id, seconds)
end

function TaanabNorulacRaidWorldBoss:isLive(arg)
	return tonumber(arg) == getN("raidId") and getN("active") == 1
end

function TaanabNorulacRaidWorldBoss:beginRaid(_p, arg)
	if tonumber(arg) ~= getN("raidId") or getN("active") == 1 then return 0 end
	setN("active", 1)
	setS("adds", "")
	setN("bossOID", 0)
	setN("detonating", 0)
	for _, gate in ipairs({75, 50, 25}) do setN("gate" .. gate, 0) end
	galaxyBroadcast(string.format("[NOTICE] Norulac raiders spotted over the Arcon hex farms on Taanab (%.0f, %.0f)! Varn Kessic is leading the raid.", self.x, self.y))
	for i, wave in ipairs(self.waves) do
		createEvent(wave.delay * 1000, "TaanabNorulacRaidWorldBoss", "spawnWave", nil, arg .. ":" .. i)
	end
	createEvent(self.WARNING_LEAD * 1000, "TaanabNorulacRaidWorldBoss", "spawnBoss", nil, arg)
	logf("raid %s started", arg)
	return 0
end

-- spawn {template, count} groups on a ring around (cx, cy); returns the pointers
function TaanabNorulacRaidWorldBoss:spawnGroup(groups, cx, cy, radius)
	local out = {}
	for _, g in ipairs(groups) do
		for _ = 1, g[2] do
			local a = math.random() * 2 * math.pi
			local r = radius * (0.5 + math.random() * 0.5)
			local x, y = cx + r * math.cos(a), cy + r * math.sin(a)
			local pMob = spawnMobile(self.planet, g[1], 0, x, floorZ(self.planet, x, y), y, math.random(0, 359), 0)
			if pMob ~= nil then
				addOID(SceneObject(pMob):getObjectID())
				table.insert(out, pMob)
			end
		end
	end
	return out
end

function TaanabNorulacRaidWorldBoss:spawnWave(_p, arg)
	local raid, idx = string.match(arg or "", "^(%d+):(%d+)$")
	if not self:isLive(raid) then return 0 end
	self:spawnGroup(self.waves[tonumber(idx)].mobs, self.x, self.y, 30)
	logf("raid %s wave %s spawned", raid, idx)
	return 0
end

function TaanabNorulacRaidWorldBoss:spawnBoss(_p, arg)
	if not self:isLive(arg) then return 0 end
	local z = floorZ(self.planet, self.x, self.y)
	local pBoss = spawnMobile(self.planet, self.bossTemplate, 0, self.x, z, self.y, 0, 0)
	if pBoss == nil then
		logf("FATAL: spawnMobile %s failed", self.bossTemplate)
		self:endRaid(false)
		return 0
	end
	setN("bossOID", SceneObject(pBoss):getObjectID())
	-- not attackable while the honor guard stands
	TangibleObject(pBoss):setPvpStatusBitmask(AGGRESSIVE + ENEMY)
	createObserver(DAMAGERECEIVED, "TaanabNorulacRaidWorldBoss", "onBossDamaged", pBoss)
	createObserver(OBJECTDESTRUCTION, "TaanabNorulacRaidWorldBoss", "onBossDeath", pBoss)

	local guards = self:spawnGroup({{self.guardTemplate, self.guardCount}}, self.x, self.y, 8)
	setN("guardsLeft", #guards)
	for _, pGuard in ipairs(guards) do
		createObserver(OBJECTDESTRUCTION, "TaanabNorulacRaidWorldBoss", "onGuardDeath", pGuard)
	end
	if #guards == 0 then self:exposeBoss(pBoss) end

	pcall(spatialChat, pBoss, "Taanab remembers Lando's little victory. Let's see if it remembers me. Burn the fields!")
	galaxyBroadcast("[NOTICE] Varn Kessic has landed at the Arcon hex farms on Taanab! Break his honor guard to reach him.", pBoss)
	createEvent(self.RAID_TIMEOUT * 1000, "TaanabNorulacRaidWorldBoss", "raidTimeout", nil, arg)
	logf("raid %s: Kessic landed at (%.1f, %.1f, %.1f) with %d guards", arg, self.x, z, self.y, #guards)
	return 0
end

function TaanabNorulacRaidWorldBoss:getBoss()
	local oid = getN("bossOID")
	if oid == 0 then return nil end
	return getSceneObject(oid)
end

local function messagePlayersNear(pObject, range, msg)
	for _, pPlayer in ipairs(SceneObject(pObject):getPlayersInRange(range) or {}) do
		pcall(function() CreatureObject(pPlayer):sendSystemMessage(msg) end)
	end
end

function TaanabNorulacRaidWorldBoss:exposeBoss(pBoss)
	if pBoss == nil then return end
	TangibleObject(pBoss):setPvpStatusBitmask(AGGRESSIVE + ATTACKABLE + ENEMY)
	pcall(spatialChat, pBoss, "Useless! Fine, I'll gut you myself.")
	messagePlayersNear(pBoss, 128, "\\#FFAA00Kessic's honor guard has fallen. Varn Kessic is exposed!")
end

function TaanabNorulacRaidWorldBoss:onGuardDeath(_pGuard, _pKiller)
	if getN("active") ~= 1 then return 1 end
	local left = getN("guardsLeft") - 1
	setN("guardsLeft", left)
	if left <= 0 then self:exposeBoss(self:getBoss()) end
	return 1
end

function TaanabNorulacRaidWorldBoss:onBossDamaged(pBoss, pAttacker, _damage)
	if pBoss == nil then return 0 end
	if pAttacker ~= nil then WorldBossLootManager:trackDamage(pBoss, pAttacker) end
	local co = CreatureObject(pBoss)
	local max = co:getMaxHAM(0) or 0
	if max <= 0 then return 0 end
	local pct = (co:getHAM(0) or 0) * 100 / max
	for _, gate in ipairs({75, 50, 25}) do
		if pct <= gate and getN("gate" .. gate) == 0 then
			setN("gate" .. gate, 1)
			local so = SceneObject(pBoss)
			self:spawnGroup(self.reinforcements[gate], so:getWorldPositionX(), so:getWorldPositionY(), 25)
			pcall(spatialChat, pBoss, gate == 25 and "Bring the detonators! Leave nothing standing!" or "Raiders, to me!")
			if gate == 25 and getN("detonating") == 0 then
				setN("detonating", 1)
				createEvent(3000, "TaanabNorulacRaidWorldBoss", "detonatorTick", nil, tostring(getN("raidId")))
			end
		end
	end
	return 0
end

-- telegraphed detonator: mark a random nearby player's spot, warn the players there, explode 3 s later
function TaanabNorulacRaidWorldBoss:detonatorTick(_p, arg)
	if not self:isLive(arg) then return 0 end
	local pBoss = self:getBoss()
	if pBoss == nil or CreatureObject(pBoss):isDead() then return 0 end
	local players = SceneObject(pBoss):getPlayersInRange(60) or {}
	if #players > 0 then
		local pTarget = players[math.random(#players)]
		local so = SceneObject(pTarget)
		local x, z, y = so:getWorldPositionX(), so:getWorldPositionZ(), so:getWorldPositionY()
		writeVector3Data(K .. "det", x, z, y)
		pcall(playClientEffectLoc, pBoss, "clienteffect/combat_grenade_proton.cef", self.planet, x, z, y, 0)
		messagePlayersNear(pTarget, self.DETONATOR_RADIUS + 4, "\\#FF3300Kessic hurls a thermal detonator at your position. Move!")
		createEvent(3000, "TaanabNorulacRaidWorldBoss", "detonate", nil, arg)
	end
	createEvent(self.DETONATOR_EVERY * 1000, "TaanabNorulacRaidWorldBoss", "detonatorTick", nil, arg)
	return 0
end

function TaanabNorulacRaidWorldBoss:detonate(_p, arg)
	if not self:isLive(arg) then return 0 end
	local pBoss = self:getBoss()
	if pBoss == nil or CreatureObject(pBoss):isDead() then return 0 end
	local v = readVector3Data(K .. "det")
	if v == nil then return 0 end
	local x, z, y = v[1], v[2], v[3]
	pcall(playClientEffectLoc, pBoss, "clienteffect/combat_grenade_thermal_detonator.cef", self.planet, x, z, y, 0)
	local r2 = self.DETONATOR_RADIUS * self.DETONATOR_RADIUS
	for _, pPlayer in ipairs(SceneObject(pBoss):getPlayersInRange(80) or {}) do
		local so = SceneObject(pPlayer)
		local dx, dy = so:getWorldPositionX() - x, so:getWorldPositionY() - y
		if dx * dx + dy * dy <= r2 then
			pcall(function()
				local co = CreatureObject(pPlayer)
				if not co:isDead() then
					co:inflictDamage(pBoss, 0, self.DETONATOR_DAMAGE, 0)
					co:inflictDamage(pBoss, 3, self.DETONATOR_DAMAGE, 0)
				end
			end)
		end
	end
	return 0
end

function TaanabNorulacRaidWorldBoss:onBossDeath(pBoss, _pKiller)
	if pBoss == nil or getN("active") ~= 1 then return 1 end
	WorldBossLootManager:onBossDeath(pBoss, self.lootGroups, self.bossName)
	galaxyBroadcast("\\#00FF00" .. self.bossName .. " has been slain on Taanab! The Norulac raid is broken.", pBoss)
	self:endRaid(true)
	return 1
end

function TaanabNorulacRaidWorldBoss:raidTimeout(_p, arg)
	if not self:isLive(arg) then return 0 end
	local pBoss = self:getBoss()
	if pBoss ~= nil then
		pcall(spatialChat, pBoss, "Enough. Back to the ships, we'll be back for the harvest.")
	end
	galaxyBroadcast("[NOTICE] Varn Kessic and the Norulac raiders have pulled back from Taanab... for now.")
	self:endRaid(false)
	return 0
end

-- leftover raiders leave after a short delay; on a retreat the boss leaves with them
function TaanabNorulacRaidWorldBoss:endRaid(killed)
	setN("active", 0)
	setN("detonating", 0)
	local oids = getS("adds")
	if not killed and getN("bossOID") ~= 0 then oids = oids .. "," .. getN("bossOID") end
	setS("adds", "")
	setN("bossOID", 0)
	createEvent((killed and 120 or 5) * 1000, "TaanabNorulacRaidWorldBoss", "cleanup", nil, oids)
	self:scheduleRaid(self.RAID_INTERVAL)
end

function TaanabNorulacRaidWorldBoss:cleanup(_p, list)
	for oid in string.gmatch(tostring(list or ""), "%d+") do
		local pMob = getSceneObject(tonumber(oid))
		if pMob ~= nil and not CreatureObject(pMob):isDead() then
			SceneObject(pMob):destroyObjectFromWorld()
		end
	end
	return 0
end
