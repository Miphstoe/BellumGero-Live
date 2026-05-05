PaintingExchangeVendor = ScreenPlay:new {
	screenplayName = "PaintingExchangeVendor",
	numberOfActs = 1,
}

registerScreenPlay("PaintingExchangeVendor", true)

PaintingExchangeVendor.NPC_TEMPLATE    = "painting_exchange_curator"
PaintingExchangeVendor.NPC_NAME        = "Painting Exchange Curator"
PaintingExchangeVendor.NPC_TITLE       = "Rare Painting Exchange"
PaintingExchangeVendor.NPC_PLANET      = "corellia"
PaintingExchangeVendor.NPC_X           = -172
PaintingExchangeVendor.NPC_Z           = 28
PaintingExchangeVendor.NPC_Y           = -4703
PaintingExchangeVendor.NPC_HEADING     = 0
PaintingExchangeVendor.NPC_CELL        = 0
PaintingExchangeVendor.CONVO_TEMPLATE  = "paintingExchangeCuratorConvoTemplate"

PaintingExchangeVendor.REQUIRED_PAINTINGS         = 10
PaintingExchangeVendor.REQUIRED_PAINTINGS_PREMIUM = 50
PaintingExchangeVendor.SCRIPT_NAMESPACE            = "pev"

-- ──────────────────────────────────────────────────────────────────────────────
-- ACCEPTED PAYMENT PAINTINGS
-- All standard painting templates present in the server. Add new entries here
-- using the pattern "object/tangible/painting/<filename>.iff".
-- ──────────────────────────────────────────────────────────────────────────────
PaintingExchangeVendor.acceptedPaintings = {
	["object/tangible/painting/painting_agrilat_s01.iff"]              = true,
	["object/tangible/painting/painting_armor_blueprint.iff"]          = true,
	["object/tangible/painting/painting_bestine_blueleaf_temple.iff"]  = true,
	["object/tangible/painting/painting_bestine_blumbush.iff"]         = true,
	["object/tangible/painting/painting_bestine_boffa.iff"]            = true,
	["object/tangible/painting/painting_bestine_golden_flower_01.iff"] = true,
	["object/tangible/painting/painting_bestine_golden_flower_02.iff"] = true,
	["object/tangible/painting/painting_bestine_golden_flower_03.iff"] = true,
	["object/tangible/painting/painting_bestine_house.iff"]            = true,
	["object/tangible/painting/painting_bestine_krayt_skeleton.iff"]   = true,
	["object/tangible/painting/painting_bestine_lucky_despot.iff"]     = true,
	["object/tangible/painting/painting_bestine_mattberry.iff"]        = true,
	["object/tangible/painting/painting_bestine_moncal_eye_01.iff"]    = true,
	["object/tangible/painting/painting_bestine_moncal_eye_02.iff"]    = true,
	["object/tangible/painting/painting_bestine_rainbow_berry_bush.iff"] = true,
	["object/tangible/painting/painting_bestine_raventhorn.iff"]       = true,
	["object/tangible/painting/painting_bestine_ronka.iff"]            = true,
	["object/tangible/painting/painting_bioengineer_orange.iff"]       = true,
	["object/tangible/painting/painting_bothan_f.iff"]                 = true,
	["object/tangible/painting/painting_bothan_m.iff"]                 = true,
	["object/tangible/painting/painting_bw_stormtrooper.iff"]          = true,
	["object/tangible/painting/painting_cargoport.iff"]                = true,
	["object/tangible/painting/painting_dance_party.iff"]              = true,
	["object/tangible/painting/painting_double_helix.iff"]             = true,
	["object/tangible/painting/painting_droid_bright.iff"]             = true,
	["object/tangible/painting/painting_endor_style_01.iff"]           = true,
	["object/tangible/painting/painting_fighter_pilot_human_01.iff"]   = true,
	["object/tangible/painting/painting_food_baking_s01.iff"]          = true,
	["object/tangible/painting/painting_food_baking_s02.iff"]          = true,
	["object/tangible/painting/painting_freedom.iff"]                  = true,
	["object/tangible/painting/painting_han_wanted.iff"]               = true,
	["object/tangible/painting/painting_human_f.iff"]                  = true,
	["object/tangible/painting/painting_kite_plant.iff"]               = true,
	["object/tangible/painting/painting_leia_wanted.iff"]              = true,
	["object/tangible/painting/painting_luke_wanted.iff"]              = true,
	["object/tangible/painting/painting_nebula_flower.iff"]            = true,
	["object/tangible/painting/painting_palowick_ad_s01.iff"]          = true,
	["object/tangible/painting/painting_palowick_ad_s02.iff"]          = true,
	["object/tangible/painting/painting_palowick_ad_s03.iff"]          = true,
	["object/tangible/painting/painting_palowick_ad_s04.iff"]          = true,
	["object/tangible/painting/painting_planet_s01.iff"]               = true,
	["object/tangible/painting/painting_rodian_f.iff"]                 = true,
	["object/tangible/painting/painting_rodian_f_ad_01.iff"]           = true,
	["object/tangible/painting/painting_rodian_m.iff"]                 = true,
	["object/tangible/painting/painting_schematic_droid.iff"]          = true,
	["object/tangible/painting/painting_schematic_transport_ship.iff"] = true,
	["object/tangible/painting/painting_schematic_weapon.iff"]         = true,
	["object/tangible/painting/painting_schematic_weapon_s03.iff"]     = true,
	["object/tangible/painting/painting_skyscraper.iff"]               = true,
	["object/tangible/painting/painting_smoking_ad.iff"]               = true,
	["object/tangible/painting/painting_starmap.iff"]                  = true,
	["object/tangible/painting/painting_tato_s03.iff"]                 = true,
	["object/tangible/painting/painting_tato_s04.iff"]                 = true,
	["object/tangible/painting/painting_teras_kasi.iff"]               = true,
	["object/tangible/painting/painting_teras_kasi_2.iff"]             = true,
	["object/tangible/painting/painting_trandoshan_m.iff"]             = true,
	["object/tangible/painting/painting_trandoshan_m_01.iff"]          = true,
	["object/tangible/painting/painting_trandoshan_wanted.iff"]        = true,
	["object/tangible/painting/painting_tree.iff"]                     = true,
	["object/tangible/painting/painting_trees_s01.iff"]                = true,
	["object/tangible/painting/painting_twilek_f.iff"]                 = true,
	["object/tangible/painting/painting_twilek_f_lg_s01.iff"]          = true,
	["object/tangible/painting/painting_twilek_f_lg_s02.iff"]          = true,
	["object/tangible/painting/painting_twilek_f_lg_s03.iff"]          = true,
	["object/tangible/painting/painting_twilek_f_lg_s04.iff"]          = true,
	["object/tangible/painting/painting_twilek_f_sm_s01.iff"]          = true,
	["object/tangible/painting/painting_twilek_f_sm_s02.iff"]          = true,
	["object/tangible/painting/painting_twilek_f_sm_s03.iff"]          = true,
	["object/tangible/painting/painting_twilek_f_sm_s04.iff"]          = true,
	["object/tangible/painting/painting_twilek_m.iff"]                 = true,
	["object/tangible/painting/painting_vader_victory.iff"]            = true,
	["object/tangible/painting/painting_valley_view.iff"]              = true,
	["object/tangible/painting/painting_victorious_reign.iff"]         = true,
	["object/tangible/painting/painting_waterfall.iff"]                = true,
	["object/tangible/painting/painting_wookiee_f.iff"]                = true,
	["object/tangible/painting/painting_wookiee_m.iff"]                = true,
	["object/tangible/painting/painting_zabrak_f.iff"]                 = true,
	["object/tangible/painting/painting_zabrak_m.iff"]                 = true,
	["object/tangible/painting/bestine_history_quest_painting.iff"]    = true,
	["object/tangible/painting/bestine_quest_painting.iff"]            = true,
}

-- ──────────────────────────────────────────────────────────────────────────────
-- REWARD PAINTINGS
-- Players choose one reward after paying 10 accepted paintings. Add new entries
-- by appending to this table. The name field is shown in the SUI selection list.
-- ──────────────────────────────────────────────────────────────────────────────
PaintingExchangeVendor.rewardPaintings = {
	{ name = "Vader's Victory",            template = "object/tangible/painting/painting_vader_victory.iff" },
	{ name = "Stormtrooper (Black & White)", template = "object/tangible/painting/painting_bw_stormtrooper.iff" },
	{ name = "Han Solo - Wanted Poster",   template = "object/tangible/painting/painting_han_wanted.iff" },
	{ name = "Princess Leia - Wanted Poster", template = "object/tangible/painting/painting_leia_wanted.iff" },
	{ name = "Luke Skywalker - Wanted Poster", template = "object/tangible/painting/painting_luke_wanted.iff" },
	{ name = "Victorious Reign",           template = "object/tangible/painting/painting_victorious_reign.iff" },
	{ name = "Freedom",                    template = "object/tangible/painting/painting_freedom.iff" },
	{ name = "Teras Kasi Master",          template = "object/tangible/painting/painting_teras_kasi.iff" },
	{ name = "Teras Kasi II",              template = "object/tangible/painting/painting_teras_kasi_2.iff" },
	{ name = "Valley View",                template = "object/tangible/painting/painting_valley_view.iff" },
	{ name = "Starmap",                    template = "object/tangible/painting/painting_starmap.iff" },
	{ name = "Nebula Flower",              template = "object/tangible/painting/painting_nebula_flower.iff" },
	{ name = "Krayt Dragon Skeleton",      template = "object/tangible/painting/painting_bestine_krayt_skeleton.iff" },
	{ name = "Lucky Despot Painting",      template = "object/tangible/painting/painting_bestine_lucky_despot.iff" },
	{ name = "Agrilat Landscape",          template = "object/tangible/painting/painting_agrilat_s01.iff" },
	{ name = "Double Helix",               template = "object/tangible/painting/painting_double_helix.iff" },
	{ name = "Bioengineer Orange",         template = "object/tangible/painting/painting_bioengineer_orange.iff" },
	{ name = "Droid (Bright)",             template = "object/tangible/painting/painting_droid_bright.iff" },
	{ name = "Fighter Pilot Portrait",     template = "object/tangible/painting/painting_fighter_pilot_human_01.iff" },
	{ name = "Waterfall",                  template = "object/tangible/painting/painting_waterfall.iff" },
	{ name = "Planet Landscape",           template = "object/tangible/painting/painting_planet_s01.iff" },
	{ name = "Endor Style",                template = "object/tangible/painting/painting_endor_style_01.iff" },
	{ name = "Schematic - Droid",          template = "object/tangible/painting/painting_schematic_droid.iff" },
	{ name = "Schematic - Transport Ship", template = "object/tangible/painting/painting_schematic_transport_ship.iff" },
	{ name = "Armor Blueprint",            template = "object/tangible/painting/painting_armor_blueprint.iff" },
	{ name = "Dance Party",                template = "object/tangible/painting/painting_dance_party.iff" },
	{ name = "Cargoport",                  template = "object/tangible/painting/painting_cargoport.iff" },
	{ name = "Skyscraper",                 template = "object/tangible/painting/painting_skyscraper.iff" },
}

-- ──────────────────────────────────────────────────────────────────────────────
-- PREMIUM REWARDS (50 paintings)
-- ──────────────────────────────────────────────────────────────────────────────
PaintingExchangeVendor.premiumRewards = {
	{ name = "Holocron of Destiny",   template = "object/tangible/loot/misc/holocron_of_destiny.iff" },
	{ name = "30k Stack Resource Deed", template = "object/tangible/veteran_reward/resource.iff" },
}

-- ──────────────────────────────────────────────────────────────────────────────

function PaintingExchangeVendor:start()
	self:spawnCurator()
end

function PaintingExchangeVendor:spawnCurator()
	local pNpc = spawnMobile(
		self.NPC_PLANET,
		self.NPC_TEMPLATE,
		0,
		self.NPC_X,
		self.NPC_Z,
		self.NPC_Y,
		self.NPC_HEADING,
		self.NPC_CELL
	)

	if (pNpc == nil) then
		print("[PaintingExchangeVendor] ERROR: Failed to spawn NPC on " .. self.NPC_PLANET)
		return
	end

	CreatureObject(pNpc):setPvpStatusBitmask(0)
	CreatureObject(pNpc):setOptionsBitmask(AIENABLED + CONVERSABLE + INVULNERABLE)
	SceneObject(pNpc):setCustomObjectName(self.NPC_NAME)
	AiAgent(pNpc):setConvoTemplate(self.CONVO_TEMPLATE)
	AiAgent(pNpc):addObjectFlag(AI_STATIC)

	print("[PaintingExchangeVendor] Spawned curator at " .. self.NPC_PLANET .. " " .. self.NPC_X .. " " .. self.NPC_Z .. " " .. self.NPC_Y)
end

-- Returns the number of eligible paintings in the player's top-level inventory.
-- Only the direct children of the "inventory" slot are checked — paintings inside
-- backpacks, containers, houses, banks, or other slots are intentionally excluded.
function PaintingExchangeVendor:countEligiblePaintings(pPlayer)
	if (pPlayer == nil) then
		return 0
	end

	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil) then
		return 0
	end

	local total = 0
	local sizeOk, size = pcall(function() return SceneObject(pInventory):getContainerObjectsSize() end)
	if (not sizeOk or size == nil) then
		return 0
	end

	for i = 0, size - 1, 1 do
		local pItem = SceneObject(pInventory):getContainerObject(i)
		if (pItem ~= nil) then
			local templateOk, tmpl = pcall(function() return SceneObject(pItem):getTemplateObjectPath() end)
			if (templateOk and tmpl ~= nil and self.acceptedPaintings[tmpl] == true) then
				total = total + 1
			end
		end
	end

	return total
end

-- Returns an array of object pointers for eligible paintings in top-level inventory.
-- Used internally by removePaymentPaintings to avoid double-counting.
function PaintingExchangeVendor:getEligiblePaintingObjects(pPlayer)
	if (pPlayer == nil) then
		return {}
	end

	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil) then
		return {}
	end

	local found = {}
	local sizeOk, size = pcall(function() return SceneObject(pInventory):getContainerObjectsSize() end)
	if (not sizeOk or size == nil) then
		return found
	end

	for i = 0, size - 1, 1 do
		local pItem = SceneObject(pInventory):getContainerObject(i)
		if (pItem ~= nil) then
			local templateOk, tmpl = pcall(function() return SceneObject(pItem):getTemplateObjectPath() end)
			if (templateOk and tmpl ~= nil and self.acceptedPaintings[tmpl] == true) then
				found[#found + 1] = pItem
			end
		end
	end

	return found
end

-- Opens the SUI reward selection list for the player.
function PaintingExchangeVendor:showRewardSelection(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local sui = SuiListBox.new("PaintingExchangeVendor", "rewardSelectionCallback")
	sui.setTargetNetworkId(SceneObject(pPlayer):getObjectID())
	sui.setTitle("Painting Exchange - Choose Your Reward")
	sui.setPrompt("Select 1 painting to receive in exchange for your 10 eligible paintings.\n\nYou will be asked to confirm before the trade is finalized.")

	for i = 1, #self.rewardPaintings, 1 do
		sui.add(self.rewardPaintings[i].name, "")
	end

	sui.sendTo(pPlayer)
	print("[PaintingExchangeVendor] Opened reward selection SUI for player " .. tostring(SceneObject(pPlayer):getObjectID()))
end

-- SUI callback: player selected a reward. Store the choice and open confirmation.
function PaintingExchangeVendor:rewardSelectionCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil) then
		return
	end

	-- eventIndex 1 = cancelled
	if (eventIndex == 1 or args == "-1") then
		CreatureObject(pPlayer):sendSystemMessage("Exchange cancelled.")
		return
	end

	local selectedIndex = tonumber(args)
	if (selectedIndex == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Invalid selection. Exchange cancelled.")
		return
	end

	-- Convert from 0-based SUI index to 1-based Lua index
	selectedIndex = selectedIndex + 1

	local reward = self.rewardPaintings[selectedIndex]
	if (reward == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Invalid reward choice. Exchange cancelled.")
		print("[PaintingExchangeVendor] ERROR: Invalid reward index " .. tostring(selectedIndex) .. " for player " .. tostring(SceneObject(pPlayer):getObjectID()))
		return
	end

	-- Store pending reward index so the confirmation callback can retrieve it.
	-- Using writeScreenPlayData ties the state to the player and survives brief disconnects.
	writeScreenPlayData(pPlayer, self.SCRIPT_NAMESPACE, "pendingRewardIndex", tostring(selectedIndex))

	self:showConfirmation(pPlayer, reward.name)
end

-- Opens a confirmation dialog showing the player what they are about to trade.
function PaintingExchangeVendor:showConfirmation(pPlayer, rewardName)
	if (pPlayer == nil) then
		return
	end

	local sui = SuiMessageBox.new("PaintingExchangeVendor", "confirmExchangeCallback")
	sui.setTargetNetworkId(SceneObject(pPlayer):getObjectID())
	sui.setTitle("Confirm Painting Exchange")
	sui.setPrompt("You are about to trade 10 eligible paintings for:\n\n" .. rewardName .. "\n\nThis cannot be undone. Confirm the exchange?")
	sui.sendTo(pPlayer)
end

-- SUI callback: player confirmed or cancelled the exchange.
function PaintingExchangeVendor:confirmExchangeCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil) then
		return
	end

	-- eventIndex 1 = cancelled / closed
	if (eventIndex == 1) then
		CreatureObject(pPlayer):sendSystemMessage("Exchange cancelled.")
		writeScreenPlayData(pPlayer, self.SCRIPT_NAMESPACE, "pendingRewardIndex", "")
		return
	end

	-- Retrieve and clear the pending reward index atomically.
	-- The index is cleared before the exchange to prevent duplicate triggers
	-- if the player somehow fires the callback twice.
	local pendingStr = readScreenPlayData(pPlayer, self.SCRIPT_NAMESPACE, "pendingRewardIndex")
	writeScreenPlayData(pPlayer, self.SCRIPT_NAMESPACE, "pendingRewardIndex", "")

	local rewardIndex = tonumber(pendingStr)
	if (rewardIndex == nil or rewardIndex < 1 or rewardIndex > #self.rewardPaintings) then
		CreatureObject(pPlayer):sendSystemMessage("Exchange failed: reward data was lost. Please try again.")
		print("[PaintingExchangeVendor] ERROR: Missing or invalid pendingRewardIndex for player " .. tostring(SceneObject(pPlayer):getObjectID()))
		return
	end

	self:completeExchange(pPlayer, rewardIndex)
end

-- Final exchange: validate, remove 10 paintings, give reward.
function PaintingExchangeVendor:completeExchange(pPlayer, rewardIndex)
	if (pPlayer == nil) then
		return
	end

	local playerID = tostring(SceneObject(pPlayer):getObjectID())
	local reward = self.rewardPaintings[rewardIndex]
	if (reward == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Exchange failed: invalid reward. Please contact staff.")
		print("[PaintingExchangeVendor] ERROR: reward nil at index " .. tostring(rewardIndex) .. " for player " .. playerID)
		return
	end

	-- Re-validate painting count at confirmation — the player may have traded or
	-- dropped paintings between opening the SUI and confirming.
	local paintings = self:getEligiblePaintingObjects(pPlayer)
	local count = #paintings

	if (count < self.REQUIRED_PAINTINGS) then
		CreatureObject(pPlayer):sendSystemMessage("Exchange failed: you only have " .. tostring(count) .. " eligible painting(s) in your inventory. You need " .. tostring(self.REQUIRED_PAINTINGS) .. ".")
		print("[PaintingExchangeVendor] Exchange aborted for player " .. playerID .. ": only " .. tostring(count) .. " paintings at confirmation")
		return
	end

	-- Validate inventory space before removing anything.
	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Exchange failed: could not access your inventory.")
		print("[PaintingExchangeVendor] ERROR: inventory nil for player " .. playerID)
		return
	end

	-- After removing 10 the net slot change is +1 (10 out, 1 in = -9 slots used).
	-- We only need to confirm there is at least 1 free slot in case the inventory
	-- is exactly full (all slots occupied by the 10 paintings being traded).
	if (SceneObject(pInventory):isContainerFullRecursive()) then
		local freeSlots = SceneObject(pInventory):getContainerVolumeLimit() - SceneObject(pInventory):getCountableObjectsRecursive()
		-- If the only free space would come from removing the 10 paintings (net -9),
		-- giveItem will succeed because paintings are removed first. Still, guard
		-- against genuinely-full inventories where no paintings are present.
		if (freeSlots <= 0 and count < 10) then
			CreatureObject(pPlayer):sendSystemMessage("Exchange failed: your inventory is full. Free at least one slot and try again.")
			print("[PaintingExchangeVendor] Exchange aborted for player " .. playerID .. ": inventory full")
			return
		end
	end

	-- Remove exactly REQUIRED_PAINTINGS eligible paintings.
	local removed = self:removePaymentPaintings(pPlayer, self.REQUIRED_PAINTINGS)
	if (removed < self.REQUIRED_PAINTINGS) then
		-- Partial removal occurred — this should not happen under normal conditions.
		-- Log prominently for admin review.
		CreatureObject(pPlayer):sendSystemMessage("Exchange failed: could only remove " .. tostring(removed) .. " painting(s). Please contact staff.")
		print("[PaintingExchangeVendor] CRITICAL: partial removal for player " .. playerID .. ": removed " .. tostring(removed) .. "/" .. tostring(self.REQUIRED_PAINTINGS))
		return
	end

	-- Give the reward painting.
	local ok = self:giveRewardPainting(pPlayer, reward.template, reward.name)
	if (not ok) then
		-- Reward creation failed after paintings were already removed. Log for admin.
		CreatureObject(pPlayer):sendSystemMessage("Exchange failed: could not create your reward painting. Your 10 paintings were consumed. Please contact staff for a refund.")
		print("[PaintingExchangeVendor] CRITICAL: reward creation failed for player " .. playerID .. " after removing 10 paintings. Reward template: " .. tostring(reward.template))
		return
	end

	CreatureObject(pPlayer):sendSystemMessage("Your painting exchange is complete. Enjoy your new artwork.")
	print("[PaintingExchangeVendor] Exchange complete for player " .. playerID .. " — reward: " .. tostring(reward.template))
end

-- Removes up to `count` accepted paintings from the player's top-level inventory.
-- Returns the number actually removed.
function PaintingExchangeVendor:removePaymentPaintings(pPlayer, count)
	if (pPlayer == nil or count <= 0) then
		return 0
	end

	local paintings = self:getEligiblePaintingObjects(pPlayer)
	local removed = 0

	for i = 1, #paintings, 1 do
		if (removed >= count) then
			break
		end

		local pItem = paintings[i]
		if (pItem ~= nil) then
			local ok1 = pcall(function() SceneObject(pItem):destroyObjectFromWorld(true) end)
			local ok2 = pcall(function() SceneObject(pItem):destroyObjectFromDatabase(true) end)
			if (ok1 and ok2) then
				removed = removed + 1
			end
		end
	end

	return removed
end

-- Creates the reward painting in the player's inventory.
-- Returns true on success, false on failure.
function PaintingExchangeVendor:giveRewardPainting(pPlayer, template, name)
	if (pPlayer == nil or template == nil) then
		return false
	end

	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil) then
		return false
	end

	local pReward = giveItem(pInventory, template, -1, true)
	if (pReward == nil) then
		return false
	end

	if (name ~= nil and name ~= "") then
		SceneObject(pReward):setCustomObjectName(name)
	end

	return true
end

-- ──────────────────────────────────────────────────────────────────────────────
-- PREMIUM EXCHANGE FLOW (50 paintings → Holocron of Destiny or Resource Deed)
-- ──────────────────────────────────────────────────────────────────────────────

function PaintingExchangeVendor:showPremiumRewardSelection(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local sui = SuiListBox.new("PaintingExchangeVendor", "premiumRewardSelectionCallback")
	sui.setTargetNetworkId(SceneObject(pPlayer):getObjectID())
	sui.setTitle("Painting Exchange - Premium Reward (50 Paintings)")
	sui.setPrompt("Select 1 rare item to receive in exchange for your 50 eligible paintings.\n\nYou will be asked to confirm before the trade is finalized.")

	for i = 1, #self.premiumRewards, 1 do
		sui.add(self.premiumRewards[i].name, "")
	end

	sui.sendTo(pPlayer)
	print("[PaintingExchangeVendor] Opened premium reward selection SUI for player " .. tostring(SceneObject(pPlayer):getObjectID()))
end

function PaintingExchangeVendor:premiumRewardSelectionCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil) then
		return
	end

	if (eventIndex == 1 or args == "-1") then
		CreatureObject(pPlayer):sendSystemMessage("Exchange cancelled.")
		return
	end

	local selectedIndex = tonumber(args)
	if (selectedIndex == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Invalid selection. Exchange cancelled.")
		return
	end

	selectedIndex = selectedIndex + 1

	local reward = self.premiumRewards[selectedIndex]
	if (reward == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Invalid reward choice. Exchange cancelled.")
		print("[PaintingExchangeVendor] ERROR: Invalid premium reward index " .. tostring(selectedIndex) .. " for player " .. tostring(SceneObject(pPlayer):getObjectID()))
		return
	end

	writeScreenPlayData(pPlayer, self.SCRIPT_NAMESPACE, "pendingPremiumRewardIndex", tostring(selectedIndex))

	self:showPremiumConfirmation(pPlayer, reward.name)
end

function PaintingExchangeVendor:showPremiumConfirmation(pPlayer, rewardName)
	if (pPlayer == nil) then
		return
	end

	local sui = SuiMessageBox.new("PaintingExchangeVendor", "confirmPremiumExchangeCallback")
	sui.setTargetNetworkId(SceneObject(pPlayer):getObjectID())
	sui.setTitle("Confirm Premium Painting Exchange")
	sui.setPrompt("You are about to trade 50 eligible paintings for:\n\n" .. rewardName .. "\n\nThis cannot be undone. Confirm the exchange?")
	sui.sendTo(pPlayer)
end

function PaintingExchangeVendor:confirmPremiumExchangeCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil) then
		return
	end

	if (eventIndex == 1) then
		CreatureObject(pPlayer):sendSystemMessage("Exchange cancelled.")
		writeScreenPlayData(pPlayer, self.SCRIPT_NAMESPACE, "pendingPremiumRewardIndex", "")
		return
	end

	local pendingStr = readScreenPlayData(pPlayer, self.SCRIPT_NAMESPACE, "pendingPremiumRewardIndex")
	writeScreenPlayData(pPlayer, self.SCRIPT_NAMESPACE, "pendingPremiumRewardIndex", "")

	local rewardIndex = tonumber(pendingStr)
	if (rewardIndex == nil or rewardIndex < 1 or rewardIndex > #self.premiumRewards) then
		CreatureObject(pPlayer):sendSystemMessage("Exchange failed: reward data was lost. Please try again.")
		print("[PaintingExchangeVendor] ERROR: Missing or invalid pendingPremiumRewardIndex for player " .. tostring(SceneObject(pPlayer):getObjectID()))
		return
	end

	self:completePremiumExchange(pPlayer, rewardIndex)
end

function PaintingExchangeVendor:completePremiumExchange(pPlayer, rewardIndex)
	if (pPlayer == nil) then
		return
	end

	local playerID = tostring(SceneObject(pPlayer):getObjectID())
	local reward = self.premiumRewards[rewardIndex]
	if (reward == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Exchange failed: invalid reward. Please contact staff.")
		print("[PaintingExchangeVendor] ERROR: premium reward nil at index " .. tostring(rewardIndex) .. " for player " .. playerID)
		return
	end

	local paintings = self:getEligiblePaintingObjects(pPlayer)
	local count = #paintings

	if (count < self.REQUIRED_PAINTINGS_PREMIUM) then
		CreatureObject(pPlayer):sendSystemMessage("Exchange failed: you only have " .. tostring(count) .. " eligible painting(s) in your inventory. You need " .. tostring(self.REQUIRED_PAINTINGS_PREMIUM) .. ".")
		print("[PaintingExchangeVendor] Premium exchange aborted for player " .. playerID .. ": only " .. tostring(count) .. " paintings at confirmation")
		return
	end

	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Exchange failed: could not access your inventory.")
		print("[PaintingExchangeVendor] ERROR: inventory nil for player " .. playerID)
		return
	end

	local removed = self:removePaymentPaintings(pPlayer, self.REQUIRED_PAINTINGS_PREMIUM)
	if (removed < self.REQUIRED_PAINTINGS_PREMIUM) then
		CreatureObject(pPlayer):sendSystemMessage("Exchange failed: could only remove " .. tostring(removed) .. " painting(s). Please contact staff.")
		print("[PaintingExchangeVendor] CRITICAL: partial premium removal for player " .. playerID .. ": removed " .. tostring(removed) .. "/" .. tostring(self.REQUIRED_PAINTINGS_PREMIUM))
		return
	end

	local ok = self:giveRewardPainting(pPlayer, reward.template, reward.name)
	if (not ok) then
		CreatureObject(pPlayer):sendSystemMessage("Exchange failed: could not create your reward. Your 50 paintings were consumed. Please contact staff for a refund.")
		print("[PaintingExchangeVendor] CRITICAL: premium reward creation failed for player " .. playerID .. " after removing 50 paintings. Reward template: " .. tostring(reward.template))
		return
	end

	CreatureObject(pPlayer):sendSystemMessage("Your premium painting exchange is complete. A rare treasure now awaits you.")
	print("[PaintingExchangeVendor] Premium exchange complete for player " .. playerID .. " — reward: " .. tostring(reward.template))
end
