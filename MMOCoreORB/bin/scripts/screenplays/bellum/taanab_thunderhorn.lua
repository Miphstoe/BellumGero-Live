-- Old Thunderhorn and the Great Herds of Taanab: a roaming elite bull bantha with his herd on the eastern plains.
-- The herd is docile. When Thunderhorn or any herd member is hurt, every living herd member (and Thunderhorn) within
-- CALL_RANGE joins the fight against the attacker. Thunderhorn's loot is on his corpse (taanab_thunderhorn_trophies).
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
	local pBoss = spawnMobile(self.planet, self.bossTemplate, self.bossRespawn, self.x, floorZ(self.planet, self.x, self.y), self.y, math.random(0, 359), 0)
	if pBoss ~= nil then
		table.insert(members, SceneObject(pBoss):getObjectID())
		createObserver(DAMAGERECEIVED, "TaanabThunderhornScreenPlay", "onHerdDamaged", pBoss)
	end

	for i = 1, self.herdCount do
		local a = (i / self.herdCount) * 2 * math.pi
		local r = self.herdRadius * (0.4 + math.random() * 0.6)
		local x, y = self.x + r * math.cos(a), self.y + r * math.sin(a)
		local pMob = spawnMobile(self.planet, self.herdTemplate, self.herdRespawn, x, floorZ(self.planet, x, y), y, math.random(0, 359), 0)
		if pMob ~= nil then
			table.insert(members, SceneObject(pMob):getObjectID())
			createObserver(DAMAGERECEIVED, "TaanabThunderhornScreenPlay", "onHerdDamaged", pMob)
		end
	end

	writeStringData(K .. "members", table.concat(members, ","))
	print(string.format("[TAANAB-THUNDERHORN] spawned Old Thunderhorn and %d herd members at (%.0f, %.0f)", #members - 1, self.x, self.y))
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
