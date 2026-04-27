if rawget(_G, "PRIMORDIAL_GRAK_WB_LOADED") then return end
PRIMORDIAL_GRAK_WB_LOADED = true

print("[GRAK] loading screenplay: primordial_warlord_grak_worldboss")

PrimordialWarlordGrakBossScreenPlay = ScreenPlay:new{
	numberOfActs = 1,
	screenplayName = "PrimordialWarlordGrakBossScreenPlay"
}
registerScreenPlay("PrimordialWarlordGrakBossScreenPlay", true)

local function _try(f, ...)
	return pcall(f, ...)
end

local function galaxyBroadcast(msg, ctx)
	msg = tostring(msg or "")
	if type(broadcastToGalaxy) == "function" then
		if ctx and _try(broadcastToGalaxy, ctx, msg) then return true end
		if _try(broadcastToGalaxy, nil, msg) then return true end
		if _try(broadcastToGalaxy, msg) then return true end
	end
	print("[GRAK][BCAST-FAIL] " .. msg)
	return false
end

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

PrimordialWarlordGrakBoss = {
	TAG = "[GRAK]",
	PLANET = "endor",
	BOSS_TEMPLATE = "primordial_warlord_grak",
	BOSS_NAME = "Primordial Warlord Grak",
	SPAWN_X = 4656,
	SPAWN_Z = 8,
	SPAWN_Y = 1181,
	SPAWN_HEADING = 0,
	LEASH_RADIUS = 180,
	LOOP_INTERVAL = 5,
	RESPAWN_SECONDS = 6 * 60 * 60,
	FIRST_BROADCAST_DELAY = 6 * 60,
	REPEAT_EVERY_SECONDS = 3 * 60 * 60,

	DATA_STATE = "GRAK.state",
	DATA_NEXT_SPAWN = "GRAK.nextSpawnAt",
	DATA_BOSS_OID = "GRAK.bossOID",
	DATA_LOOP_STARTED = "GRAK.loopStarted",
	DATA_NEXT_BCAST_AT = "GRAK.nextGalaxyBcastAt",

	bossPtr = nil,
	bossOID = nil
}

function PrimordialWarlordGrakBoss:d(msg)
	print(self.TAG .. " " .. tostring(msg))
end

function PrimordialWarlordGrakBoss:getState()
	local value = readData(self.DATA_STATE)
	if value == nil then return 0 end
	return tonumber(value) or 0
end

function PrimordialWarlordGrakBoss:setState(state)
	writeData(self.DATA_STATE, state)
end

function PrimordialWarlordGrakBossScreenPlay:start()
	if readData(PrimordialWarlordGrakBoss.DATA_LOOP_STARTED) == 1 then return end
	writeData(PrimordialWarlordGrakBoss.DATA_LOOP_STARTED, 1)

	local savedOID = tonumber(readData(PrimordialWarlordGrakBoss.DATA_BOSS_OID) or 0) or 0
	if savedOID > 0 then
		local pBoss = getSceneObject(savedOID)
		if pBoss ~= nil then
			PrimordialWarlordGrakBoss.bossPtr = pBoss
			PrimordialWarlordGrakBoss.bossOID = savedOID
			PrimordialWarlordGrakBoss:setState(1)
			PrimordialWarlordGrakBoss:attachObservers(pBoss)
		end
	end

	if PrimordialWarlordGrakBoss.bossPtr == nil and PrimordialWarlordGrakBoss:getState() ~= 3 then
		PrimordialWarlordGrakBoss:doSpawn()
	end

	createEvent(PrimordialWarlordGrakBoss.LOOP_INTERVAL * 1000, "PrimordialWarlordGrakBoss", "loop", nil, "")
end

function PrimordialWarlordGrakBoss:bindOID(pBoss)
	local oid = nil
	_try(function()
		local co = LuaCreatureObject(pBoss)
		if co then oid = co:getObjectID() end
	end)
	if not oid or tonumber(oid) == 0 then
		_try(function()
			local so = LuaSceneObject(pBoss)
			if so then oid = so:getObjectID() end
		end)
	end
	if oid and tonumber(oid) and tonumber(oid) > 0 then
		self.bossOID = tonumber(oid)
		writeData(self.DATA_BOSS_OID, self.bossOID)
		return true
	end
	return false
end

function PrimordialWarlordGrakBoss:attachObservers(pBoss)
	local dmgCands = {"DAMAGERECEIVED", "COMBATDAMAGE", "DAMAGE"}
	local deathCands = {"CREATUREDEATH", "OBJECTDESTRUCTION", "OBJECT_DESTROYED"}
	for _, name in ipairs(dmgCands) do
		local eventType = rawget(_G, name)
		if type(eventType) == "number" then
			pcall(createObserver, eventType, "PrimordialWarlordGrakBoss", "onDamage", pBoss)
		end
	end
	for _, name in ipairs(deathCands) do
		local eventType = rawget(_G, name)
		if type(eventType) == "number" then
			pcall(createObserver, eventType, "PrimordialWarlordGrakBoss", "onDeath", pBoss)
		end
	end
end

function PrimordialWarlordGrakBoss:doSpawn()
	local pBoss, sig = trySpawnMobile(
		self.PLANET,
		self.BOSS_TEMPLATE,
		0,
		self.SPAWN_X,
		self.SPAWN_Z,
		self.SPAWN_Y,
		self.SPAWN_HEADING,
		0
	)

	if not pBoss then
		self:d("spawn failed; retrying in 60s")
		createEvent(60 * 1000, "PrimordialWarlordGrakBoss", "doSpawn", nil, "")
		return false
	end

	self.bossPtr = pBoss
	self:bindOID(pBoss)
	self:attachObservers(pBoss)
	self:setState(1)
	writeData(self.DATA_NEXT_SPAWN, 0)
	writeData(self.DATA_NEXT_BCAST_AT, os.time() + self.FIRST_BROADCAST_DELAY)

	local co = LuaCreatureObject(pBoss)
	if co and co.setCustomObjectName then
		co:setCustomObjectName(self.BOSS_NAME)
	end
	if co and co.setHomeLocation then
		co:setHomeLocation(self.SPAWN_X, self.SPAWN_Z, self.SPAWN_Y, self.LEASH_RADIUS)
	end

	if broadcastMessage then
		broadcastMessage("\\#FF9933" .. self.BOSS_NAME .. " has emerged on Endor at waypoint 4656 1181.")
	end

	self:d(string.format("SPAWNED @ (%d, %d, %d) [sig=%s]", self.SPAWN_X, self.SPAWN_Z, self.SPAWN_Y, tostring(sig)))
	return true
end

function PrimordialWarlordGrakBoss:handleBossDefeated()
	self.bossPtr = nil
	self.bossOID = nil
	writeData(self.DATA_BOSS_OID, 0)
	writeData(self.DATA_NEXT_SPAWN, os.time() + self.RESPAWN_SECONDS)
	writeData(self.DATA_NEXT_BCAST_AT, 0)
	self:setState(3)

	if broadcastMessage then
		broadcastMessage("\\#00FF00" .. self.BOSS_NAME .. " has been defeated. It will return in 6 hours.")
	end
end

function PrimordialWarlordGrakBoss:loop()
	if self.bossPtr == nil then
		local savedOID = tonumber(readData(self.DATA_BOSS_OID) or 0) or 0
		if savedOID > 0 then
			local obj = getSceneObject(savedOID)
			if obj ~= nil then
				self.bossPtr = obj
				self.bossOID = savedOID
			end
		end
	end

	local now = os.time()
	local state = self:getState()
	local nextSpawnAt = tonumber(readData(self.DATA_NEXT_SPAWN) or 0) or 0

	if self.bossPtr ~= nil then
		local activeOID = tonumber(readData(self.DATA_BOSS_OID) or 0) or 0
		if activeOID > 0 and getSceneObject(activeOID) == nil then
			self:handleBossDefeated()
		end
		local nextBcastAt = tonumber(readData(self.DATA_NEXT_BCAST_AT) or 0) or 0
		if nextBcastAt > 0 and now >= nextBcastAt then
			local msg = string.format("[NOTICE] %s is located at (%d, %d) on Endor.",
				self.BOSS_NAME, self.SPAWN_X, self.SPAWN_Y)
			galaxyBroadcast(msg, self.bossPtr)
			writeData(self.DATA_NEXT_BCAST_AT, now + self.REPEAT_EVERY_SECONDS)
		end
	elseif state == 1 then
		self:handleBossDefeated()
	elseif state == 3 and nextSpawnAt > 0 and now >= nextSpawnAt then
		self:doSpawn()
	elseif state == 0 and nextSpawnAt == 0 then
		self:doSpawn()
	end

	createEvent(self.LOOP_INTERVAL * 1000, "PrimordialWarlordGrakBoss", "loop", nil, "")
	return 0
end

function PrimordialWarlordGrakBoss:onDamage(_pBoss, _pAttacker, _damage)
	return 0
end

function PrimordialWarlordGrakBoss:onDeath(_pBoss, _pKiller)
	self:handleBossDefeated()
	return 0
end
