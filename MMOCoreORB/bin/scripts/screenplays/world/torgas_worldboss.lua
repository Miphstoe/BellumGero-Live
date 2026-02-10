--[[======================================================================
  Tatooine World Boss: Torgas the Enslaver
  - Random spawn in SE Tatooine
  - Per-player loot distribution via WorldBossLootManager
  - Galaxy broadcast at 3m30s after spawn/startup, then every 3 hours while alive
  - Respawns after cooldown at a new random SE point
========================================================================]]

if rawget(_G, "TORGAS_WB_LOADED") then return end
TORGAS_WB_LOADED = true
print("[TORGAS] loading screenplay: torgas_worldboss")

local WorldBossLootManager = require("screenplays.managers.world_boss_loot_manager")

TorgasBossScreenPlay = ScreenPlay:new{
	numberOfActs = 1,
	screenplayName = "TorgasBossScreenPlay"
}
registerScreenPlay("TorgasBossScreenPlay", true)

local function _try(f, ...) return pcall(f, ...) end

local function trySpawnMobile(planet, tpl, respawn, x, z, y, dir, cell)
	local ok, mob
	ok,mob=pcall(spawnMobile,planet,tpl,respawn,x,z,y,dir,cell)  if ok and mob then return mob,"A" end
	ok,mob=pcall(spawnMobile,planet,tpl,respawn,x,z,y,cell,dir)  if ok and mob then return mob,"B" end
	ok,mob=pcall(spawnMobile,planet,tpl,respawn,x,y,z,dir,cell)  if ok and mob then return mob,"C" end
	ok,mob=pcall(spawnMobile,planet,tpl,respawn,x,y,z,cell,dir)  if ok and mob then return mob,"D" end
	ok,mob=pcall(spawnMobile,planet,tpl,respawn,x,z,y,dir)       if ok and mob then return mob,"E" end
	ok,mob=pcall(spawnMobile,planet,tpl,respawn,x,y,z,dir)       if ok and mob then return mob,"F" end
	ok,mob=pcall(spawnMobile,planet,tpl,respawn,x,z,y,cell)      if ok and mob then return mob,"G" end
	ok,mob=pcall(spawnMobile,planet,tpl,respawn,x,y,z,cell)      if ok and mob then return mob,"H" end
	return nil,"NONE"
end

local function galaxyBroadcast(msg, ctx)
	msg = tostring(msg or "")
	if type(broadcastToGalaxy) == "function" then
		if ctx and _try(broadcastToGalaxy, ctx, msg) then return true end
		if _try(broadcastToGalaxy, nil, msg) then return true end
		if _try(broadcastToGalaxy, msg) then return true end
	end
	print("[TORGAS][BCAST-FAIL] " .. msg)
	return false
end

TorgasBoss = {
	TAG = "[TORGAS]",
	PLANET = "tatooine",
	BOSS_TEMPLATE = "torgas_the_enslaver",
	BOSS_NAME = "Torgas the Enslaver",
	LEASH_RADIUS = 180,

	LOOP_INTERVAL = 5,
	RESPAWN_SECONDS = 86400, -- 24h
	FIRST_BROADCAST_DELAY = 210, -- 3m30s
	REPEAT_EVERY_SECONDS = 10800, -- 3h

	-- SE quadrant points (x positive, y negative)
	SPAWN_POINTS = {
		{6100, -6900}, {6700, -6200}, {7350, -5900},
		{5600, -7600}, {5000, -6900}, {4600, -6200},
		{4200, -5600}, {3600, -7400}, {3000, -6500},
		{2500, -7100}, {1900, -6000}, {1200, -6800}
	},

	DATA_STATE = "TORGAS.state", -- 0 idle, 1 alive, 3 cooldown
	DATA_NEXT_SPAWN = "TORGAS.nextSpawnAt",
	DATA_BOSS_OID = "TORGAS.bossOID",
	DATA_LOOP_STARTED = "TORGAS.loopStarted",
	DATA_LAST_X = "TORGAS.lastX",
	DATA_LAST_Y = "TORGAS.lastY",
	DATA_NEXT_BCAST_AT = "TORGAS.nextGalaxyBcastAt",

	bossPtr = nil,
	bossOID = nil
}

local TORGAS_LOOT_GROUPS = {
	{
		groups = {
			{group = "krayt_tissue_rare", chance = 3000000},
			{group = "krayt_dragon_common", chance = 3000000},
			{group = "krayt_pearls", chance = 2000000},
			{group = "armor_attachments", chance = 1000000},
			{group = "clothing_attachments", chance = 1000000},
		},
		lootChance = 10000000,
	},
	{
		groups = {
			{group = "krayt_tissue_rare", chance = 2500000},
			{group = "krayt_dragon_common", chance = 3500000},
			{group = "krayt_pearls", chance = 2000000},
			{group = "armor_attachments", chance = 1000000},
			{group = "clothing_attachments", chance = 1000000},
		},
		lootChance = 7000000,
	},
	{
		groups = {
			{group = "krayt_tissue_rare", chance = 2500000},
			{group = "krayt_dragon_common", chance = 3500000},
			{group = "krayt_pearls", chance = 2000000},
			{group = "armor_attachments", chance = 1000000},
			{group = "clothing_attachments", chance = 1000000},
		},
		lootChance = 5000000,
	},
	{
		groups = {
			{group = "krayt_tissue_rare", chance = 2500000},
			{group = "krayt_dragon_common", chance = 3500000},
			{group = "krayt_pearls", chance = 2000000},
			{group = "armor_attachments", chance = 1000000},
			{group = "clothing_attachments", chance = 1000000},
		},
		lootChance = 2500000,
	},
	{
		groups = {
			{group = "krayt_pearls", chance = 10000000},
		},
		lootChance = 1500000,
	},
	{
		groups = {
			{group = "krayt_pearls", chance = 10000000},
		},
		lootChance = 1000000,
	},
	{
		groups = {
			{group = "endgame_weapon_schematics", chance = 10000000},
		},
		lootChance = 1500000,
	},
	{
		groups = {
			{group = "bg_token_group", chance = 10000000},
		},
		lootChance = 350000,
	}
}

function TorgasBoss:d(m) print(self.TAG .. " " .. tostring(m)) end
function TorgasBoss:getState() local v = readData(self.DATA_STATE); if v == nil then return 0 end; return tonumber(v) or 0 end
function TorgasBoss:setState(s) writeData(self.DATA_STATE, s) end

function TorgasBossScreenPlay:start()
	if readData(TorgasBoss.DATA_LOOP_STARTED) == 1 then return end
	writeData(TorgasBoss.DATA_LOOP_STARTED, 1)

	-- Spawn immediately on startup so the first broadcast is aligned to startup timing.
	if TorgasBoss:getState() ~= 1 then
		TorgasBoss:doSpawn()
	end

	print("[TORGAS] ScreenPlay boot -> starting main loop in 5s")
	createEvent(5, "TorgasBoss", "loop", nil, "")
end

local function bindOID(self, pBoss)
	local oid = nil
	_try(function() local co = LuaCreatureObject(pBoss); if co then oid = co:getObjectID() end end)
	if not oid or tonumber(oid) == 0 then
		_try(function() local so = LuaSceneObject(pBoss); if so then oid = so:getObjectID() end end)
	end
	if oid and tonumber(oid) and tonumber(oid) > 0 then
		self.bossOID = tonumber(oid)
		writeData(self.DATA_BOSS_OID, self.bossOID)
		return true
	end
	return false
end

local function attachObservers(self, pBoss)
	local dmgCands = {"DAMAGERECEIVED", "COMBATDAMAGE", "DAMAGE"}
	local deathCands = {"CREATUREDEATH", "OBJECTDESTRUCTION", "OBJECT_DESTROYED"}
	for _, nm in ipairs(dmgCands) do
		local ev = rawget(_G, nm)
		if type(ev) == "number" then pcall(createObserver, ev, "TorgasBoss", "onDamage", pBoss) end
	end
	for _, nm in ipairs(deathCands) do
		local ev = rawget(_G, nm)
		if type(ev) == "number" then pcall(createObserver, ev, "TorgasBoss", "onDeath", pBoss) end
	end
end

function TorgasBoss:pickSpawnPoint()
	if not self.SPAWN_POINTS or #self.SPAWN_POINTS == 0 then return nil end
	return self.SPAWN_POINTS[math.random(#self.SPAWN_POINTS)]
end

function TorgasBoss:doSpawn()
	local tries = #self.SPAWN_POINTS
	for _ = 1, tries do
		local pt = self:pickSpawnPoint()
		local x = tonumber(pt[1]) or 0
		local y = tonumber(pt[2]) or 0
		local z = 0
		if type(getTerrainHeight) == "function" then z = getTerrainHeight(x, y) or 0 end

		local pBoss, sig = trySpawnMobile(self.PLANET, self.BOSS_TEMPLATE, 0, x, z, y, 0, 0)
		if pBoss then
			self.bossPtr = pBoss
			bindOID(self, pBoss)
			attachObservers(self, pBoss)
			self:setState(1)

			local co = LuaCreatureObject(pBoss)
			if co and co.setCustomObjectName then co:setCustomObjectName(self.BOSS_NAME) end
			if co and co.setHomeLocation then co:setHomeLocation(x, z, y, self.LEASH_RADIUS) end

			writeData(self.DATA_LAST_X, x)
			writeData(self.DATA_LAST_Y, y)
			writeData(self.DATA_NEXT_BCAST_AT, os.time() + self.FIRST_BROADCAST_DELAY)

			self:d(string.format("SPAWNED @ (%.0f, %.0f, %.0f) [sig=%s]", x, z, y, sig))
			if broadcastMessage then
				broadcastMessage("\\#FF9933A dark shadow rises in the southeast wastes of Tatooine...")
			end
			return true
		end
	end

	self:d("spawn failed at all configured SE points")
	return false
end

function TorgasBoss:loop()
	if not self.bossPtr then
		local savedOID = readData(self.DATA_BOSS_OID)
		if savedOID and tonumber(savedOID) and tonumber(savedOID) > 0 then
			local obj = getSceneObject(tonumber(savedOID))
			if obj then self.bossPtr = obj end
		end
	end

	local state = self:getState()
	local now = os.time()
	local nextSpawnAt = tonumber(readData(self.DATA_NEXT_SPAWN) or 0) or 0

	if self.bossPtr then
		local nextGal = tonumber(readData(self.DATA_NEXT_BCAST_AT) or 0) or 0
		if nextGal > 0 and now >= nextGal then
			local x = tonumber(readData(self.DATA_LAST_X) or 0) or 0
			local y = tonumber(readData(self.DATA_LAST_Y) or 0) or 0
			local msg = string.format("[NOTICE] %s is located (%.0f, %.0f) on Tatooine.",
				self.BOSS_NAME, x, y)
			galaxyBroadcast(msg, self.bossPtr)
			writeData(self.DATA_NEXT_BCAST_AT, now + self.REPEAT_EVERY_SECONDS)
		end
	else
		if state == 1 then
			writeData(self.DATA_NEXT_SPAWN, now + self.RESPAWN_SECONDS)
			writeData(self.DATA_NEXT_BCAST_AT, 0)
			writeData(self.DATA_BOSS_OID, 0)
			self:setState(3)
		elseif state ~= 3 then
			self:doSpawn()
		elseif nextSpawnAt <= now then
			if self:doSpawn() then
				writeData(self.DATA_NEXT_SPAWN, 0)
			else
				writeData(self.DATA_NEXT_SPAWN, now + 60)
			end
		end
	end

	createEvent(self.LOOP_INTERVAL, "TorgasBoss", "loop", nil, "")
	return 0
end

function TorgasBoss:onDamage(pBoss, pAttacker, damage)
	WorldBossLootManager:trackDamage(pBoss, pAttacker)
	return 0
end

function TorgasBoss:onDeath(pBoss, pKiller)
	WorldBossLootManager:onBossDeath(pBoss, TORGAS_LOOT_GROUPS, self.BOSS_NAME)

	self.bossPtr = nil
	self.bossOID = nil
	writeData(self.DATA_BOSS_OID, 0)
	writeData(self.DATA_NEXT_BCAST_AT, 0)
	writeData(self.DATA_NEXT_SPAWN, os.time() + self.RESPAWN_SECONDS)
	self:setState(3)

	if broadcastMessage then
		broadcastMessage("\\#00FF00Torgas the Enslaver has been defeated! A treasure chest appears at his feet.")
	end
	return 0
end
