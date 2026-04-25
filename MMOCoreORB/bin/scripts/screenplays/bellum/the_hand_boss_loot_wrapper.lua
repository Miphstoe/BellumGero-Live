-- ##############################################################
-- the_hand_boss_loot_wrapper.lua
-- Wraps RoriRestussScreenPlay so that every player who damages
-- The Hand receives exactly 1 piece of loot upon death.
-- No loot is placed on the corpse.
-- ##############################################################

local WorldBossLootManager = require("screenplays.managers.world_boss_loot_manager")

-- Store the stubs defined in rori_restuss.lua so we can chain them.
local originalOnDamage = RoriRestussScreenPlay.onHandDamage
local originalOnDeath  = RoriRestussScreenPlay.onTheHandKilled

local THE_HAND_LOOT_GROUPS = {
	{
		groups = {
			{ group = "color_crystals",       chance = 2000000 },
			{ group = "clothing_attachments",  chance = 2500000 },
			{ group = "armor_attachments",     chance = 2500000 },
			{ group = "holocron_dark",         chance = 2000000 },
			{ group = "the_hand",              chance = 1000000 }
		},
		lootChance = 10000000
	}
}

-- Distribute exactly one loot item to a single eligible player.
local function giveOneLootItem(pPlayer, bossLevel)
	local pInventory = nil
	pcall(function()
		local creature = CreatureObject(pPlayer)
		if creature then
			pInventory = creature:getSlottedObject("inventory")
		end
	end)
	if not pInventory then return end

	-- Pick a random loot group table entry, then a random group within it.
	local entry = THE_HAND_LOOT_GROUPS[math.random(#THE_HAND_LOOT_GROUPS)]
	if not entry or not entry.groups then return end

	local totalWeight = 0
	for _, g in ipairs(entry.groups) do totalWeight = totalWeight + (g.chance or 0) end
	if totalWeight == 0 then return end

	local roll = math.random(totalWeight)
	local cumulative = 0
	local chosenGroup = nil
	for _, g in ipairs(entry.groups) do
		cumulative = cumulative + (g.chance or 0)
		if roll <= cumulative then
			chosenGroup = g.group
			break
		end
	end
	if not chosenGroup then return end

	local itemOID = nil
	pcall(function() itemOID = createLoot(pInventory, chosenGroup, bossLevel, true) end)

	local itemName = "an item"
	if itemOID and itemOID ~= 0 then
		local pItem = getSceneObject(itemOID)
		if pItem then
			local so = SceneObject(pItem)
			if so then itemName = so:getDisplayedName() or itemName end
		end
	end

	pcall(function()
		CreatureObject(pPlayer):sendSystemMessage(
			"\\#00FF00You received from The Hand: " .. itemName .. "!")
	end)
end

-- Override: track every damager via WorldBossLootManager.
function RoriRestussScreenPlay:onHandDamage(pBoss, pAttacker, damage)
	WorldBossLootManager:trackDamage(pBoss, pAttacker)

	if originalOnDamage then
		return originalOnDamage(self, pBoss, pAttacker, damage)
	end
	return 0
end

-- Override: give exactly 1 item to each tracked damager on death.
function RoriRestussScreenPlay:onTheHandKilled(pVictim, pKiller)
	pcall(function()
		local soBoss = SceneObject(pVictim)
		if not soBoss then return end

		local bossOID = soBoss:getObjectID()
		local bossLevel = 1
		pcall(function()
			local co = CreatureObject(pVictim)
			if co and co.getLevel then bossLevel = co:getLevel() or 1 end
		end)

		local damagers = _G.__WB_DAMAGE_TRACKING and _G.__WB_DAMAGE_TRACKING[bossOID] or {}
		for playerOID, _ in pairs(damagers) do
			pcall(function()
				local pPlayer = getSceneObject(tonumber(playerOID))
				if pPlayer and SceneObject(pPlayer):isPlayerCreature() then
					giveOneLootItem(pPlayer, bossLevel)
				end
			end)
		end

		-- Clear tracking for this boss.
		if _G.__WB_DAMAGE_TRACKING then
			_G.__WB_DAMAGE_TRACKING[bossOID] = nil
		end

		-- Clear corpse loot/credits and schedule destruction.
		pcall(function()
			local corpse = SceneObject(pVictim)
			if not corpse then return end

			local containerSize = corpse:getContainerObjectsSize()
			if containerSize and containerSize > 0 then
				for i = containerSize - 1, 0, -1 do
					pcall(function()
						local pItem = corpse:getContainerObject(i)
						if pItem then
							local item = SceneObject(pItem)
							if item then
								item:destroyObjectFromWorld()
								item:destroyObjectFromDatabase()
							end
						end
					end)
				end
			end

			pcall(function()
				local co = CreatureObject(pVictim)
				if co then
					local cash = co:getCashCredits()
					if cash and cash > 0 then co:subtractCashCredits(cash) end
					co:setCashCredits(0)
				end
			end)

			local corpseOID = corpse:getObjectID()
			if corpseOID and corpseOID > 0 then
				writeData("TheHand:corpse:" .. tostring(bossOID), tonumber(corpseOID))
				createEvent(5000, "RoriRestussScreenPlay", "destroyHandCorpse", nil, tostring(bossOID))
			end
		end)
	end)

	if originalOnDeath then
		return originalOnDeath(self, pVictim, pKiller)
	end
	return 1
end

-- Corpse destruction event called 5s after death.
function RoriRestussScreenPlay:destroyHandCorpse(_, bossOIDStr)
	local corpseOID = tonumber(readData("TheHand:corpse:" .. bossOIDStr))
	if not corpseOID or corpseOID == 0 then return 1 end
	deleteData("TheHand:corpse:" .. bossOIDStr)

	local pCorpse = getSceneObject(corpseOID)
	if pCorpse then
		pcall(function()
			local so = SceneObject(pCorpse)
			if so then
				so:destroyObjectFromWorld()
				so:destroyObjectFromDatabase()
			end
		end)
	end
	return 1
end

print("[THE-HAND-LOOT] Loot wrapper loaded - 1 item per damager on death")
