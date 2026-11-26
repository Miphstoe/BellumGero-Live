-- Old Thunderhorn and the Great Herds of Taanab: a roaming elite bull bantha with his herd of banthas and nerfs on the
-- eastern plains. The herd walks a slow loop around the Great Herds together (PATROL_*), keeping its formation. It is
-- docile. When Thunderhorn or any herd member is hurt, every living herd member (and Thunderhorn) within CALL_RANGE
-- joins the fight against the attacker. Thunderhorn's loot is on his corpse (taanab_thunderhorn_trophies).
-- Mobiles respawn as the same objects, so the observers (which return 0) stay attached.
TaanabThunderhornScreenPlay = ScreenPlay:new {
	numberOfActs = 1,
	screenplayName = "TaanabThunderhornScreenPlay",

	planet = "taanab",
	x = 4900.0, y = -4500.0, -- Great Herds (taanab_regions.lua)

	bossTemplate = "taanab_old_thunderhorn",
	bossRespawn = 7200,
	herdTemplate = "taanab_herd_bantha",
	herdCount = 10,
	herdRespawn = 600,
	herdRadius = 45,
	nerfTemplate = "taanab_nerf",
	nerfCount = 8,
	nerfRadius = 60,
	PATROL_RADIUS = 150, -- loop around (x, y)
	PATROL_POINTS = 8,
	PATROL_INTERVAL = 120, -- seconds between legs (a leg is ~115 m)
	CALL_RANGE = 120,
	CALL_COOLDOWN = 20, -- seconds between herd calls
}

registerScreenPlay("TaanabThunderhornScreenPlay", true)

local K = "TaanabThunderhorn:"

local function floorZ(planet, x, y)
	local z = 0
	pcall(function() z = getWorldFloor(x, y, planet) or 0 end)
	return z
end

function TaanabThunderhornScreenPlay:start()
	if not isZoneEnabled(self.planet) then return end

	local members = {}
	local formation = {} -- "oid:dx:dy", offsets from the patrol point
	local pBoss = spawnMobile(self.planet, self.bossTemplate, self.bossRespawn, self.x, floorZ(self.planet, self.x, self.y), self.y, math.random(0, 359), 0)
	if pBoss ~= nil then
		table.insert(members, SceneObject(pBoss):getObjectID())
		table.insert(formation, SceneObject(pBoss):getObjectID() .. ":0:0")
		createObserver(DAMAGERECEIVED, "TaanabThunderhornScreenPlay", "onHerdDamaged", pBoss)
	end

	local function spawnRing(template, count, radius, respawn)
		for i = 1, count do
			local a = (i / count) * 2 * math.pi + math.random() * 0.3
			local r = radius * (0.4 + math.random() * 0.6)
			local dx, dy = r * math.cos(a), r * math.sin(a)
			local x, y = self.x + dx, self.y + dy
			local pMob = spawnMobile(self.planet, template, respawn, x, floorZ(self.planet, x, y), y, math.random(0, 359), 0)
			if pMob ~= nil then
				table.insert(members, SceneObject(pMob):getObjectID())
				table.insert(formation, string.format("%d:%.1f:%.1f", SceneObject(pMob):getObjectID(), dx, dy))
				createObserver(DAMAGERECEIVED, "TaanabThunderhornScreenPlay", "onHerdDamaged", pMob)
			end
		end
	end
	spawnRing(self.herdTemplate, self.herdCount, self.herdRadius, self.herdRespawn)
	spawnRing(self.nerfTemplate, self.nerfCount, self.nerfRadius, self.herdRespawn)

	writeStringData(K .. "members", table.concat(members, ","))
	writeStringData(K .. "formation", table.concat(formation, ","))
	writeData(K .. "patrolLeg", 0)
	createEvent(self.PATROL_INTERVAL * 1000, "TaanabThunderhornScreenPlay", "patrolTick", nil, "")
	print(string.format("[TAANAB-THUNDERHORN] spawned Old Thunderhorn and %d herd members at (%.0f, %.0f)", #members - 1, self.x, self.y))
end

-- Move every idle, living member to the next point on the loop plus its own offset, so the herd walks as one group.
-- Members in combat are left alone and rejoin on a later leg; respawned members (same objects) rejoin too.
function TaanabThunderhornScreenPlay:patrolTick()
	local leg = ((tonumber(readData(K .. "patrolLeg")) or 0) % self.PATROL_POINTS) + 1
	writeData(K .. "patrolLeg", leg)
	local a = (leg / self.PATROL_POINTS) * 2 * math.pi
	local px, py = self.x + self.PATROL_RADIUS * math.cos(a), self.y + self.PATROL_RADIUS * math.sin(a)
	local moved = 0

	for oid, dx, dy in string.gmatch(readStringData(K .. "formation") or "", "(%d+):(-?[%d.]+):(-?[%d.]+)") do
		local pMember = getSceneObject(tonumber(oid))
		if pMember ~= nil then
			pcall(function()
				local co = CreatureObject(pMember)
				if not co:isDead() and not co:isInCombat() then
					local x, y = px + tonumber(dx), py + tonumber(dy)
					local agent = AiAgent(pMember)
					agent:setMovementState(AI_PATROLLING)
					agent:stopWaiting()
					agent:setNextPosition(x, floorZ(self.planet, x, y), y, 0)
					agent:executeBehavior()
					moved = moved + 1
				end
			end)
		end
	end

	if leg == 1 then -- once per loop, so the console shows the herd is moving
		print(string.format("[TAANAB-THUNDERHORN] herd patrol: %d members heading to (%.0f, %.0f)", moved, px, py))
	end
	createEvent(self.PATROL_INTERVAL * 1000, "TaanabThunderhornScreenPlay", "patrolTick", nil, "")
	return 0
end

function TaanabThunderhornScreenPlay:onHerdDamaged(pVictim, pAttacker, _damage)
	if pVictim == nil or pAttacker == nil then return 0 end

	local now = os.time()
	if now - (tonumber(readData(K .. "lastCall")) or 0) < self.CALL_COOLDOWN then return 0 end
	writeData(K .. "lastCall", now)

	local victimOID = SceneObject(pVictim):getObjectID()
	local called = 0
	for oid in string.gmatch(readStringData(K .. "members") or "", "%d+") do
		local pMember = getSceneObject(tonumber(oid))
		if pMember ~= nil and tonumber(oid) ~= victimOID then
			pcall(function()
				local co = CreatureObject(pMember)
				if not co:isDead() and not co:isInCombat() and SceneObject(pMember):isInRangeWithObject(pVictim, self.CALL_RANGE) then
					co:engageCombat(pAttacker)
					called = called + 1
				end
			end)
		end
	end

	if called > 0 and SceneObject(pAttacker):isPlayerCreature() then
		CreatureObject(pAttacker):sendSystemMessage("\\#FFAA00The ground shakes as the Great Herd turns on you!")
	end
	return 0
end
