JunkDealer = {
	junkTypes = {
		{"generic", 1},
		{"finery", 2},
		{"arms", 4},
		{"geo", 8},
		{"tusken", 16},
		{"jedi", 32},
		{"jawa", 64},
		{"gungan", 128},
		{"corsec", 256}
	}
}

function JunkDealer:sendSellJunkSelection(pPlayer, pNpc, dealerType, skipItem)
	if pPlayer == nil or pNpc == nil then
		return
	end

	local junkList = self:getEligibleJunk(pPlayer, dealerType, skipItem)

	if #junkList == 0 then
		CreatureObject(pPlayer):sendSystemMessage("@loot_dealer:no_items") -- You have no items that the junk dealer wishes to buy.
		deleteStringData(SceneObject(pPlayer):getObjectID() .. ":junkDealerType")
		return
	end

	-- Add some debugging
	print("JunkDealer: Found " .. #junkList .. " eligible items")

	local suiManager = LuaSuiManager()
	-- Restore original 3-button structure: Cancel, Sell All (junk only), Sell (individual any item)
	suiManager:sendListBox(pNpc, pPlayer, "@loot_dealer:sell_title", "@loot_dealer:sell_prompt", 3, "@cancel", "@loot_dealer:btn_sell_all", "@loot_dealer:btn_sell", "JunkDealer", "sellListSuiCallback", 10, junkList)
end

function JunkDealer:getDealerNum(dealerType)
	local dealerNum = 0

	for i = 1, #self.junkTypes, 1 do
		if string.find(dealerType, self.junkTypes[i][1]) ~= nil then
			dealerNum = self.junkTypes[i][2]
		end
	end

	return dealerNum
end

function JunkDealer:findItemInContainers(pPlayer, oid)
	-- Helper function to find an item by ObjectID in inventory and all backpacks
	local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")

	if pInventory == nil then
		return nil
	end

	-- First check main inventory
	local pItem = SceneObject(pInventory):getContainerObjectById(oid)
	if pItem ~= nil then
		return pItem
	end

	-- Then check all backpacks/containers
	for i = 0, SceneObject(pInventory):getContainerObjectsSize() - 1, 1 do
		local pContainer = SceneObject(pInventory):getContainerObject(i)

		if pContainer ~= nil and SceneObject(pContainer):getContainerObjectsSize() > 0 then
			pItem = SceneObject(pContainer):getContainerObjectById(oid)
			if pItem ~= nil then
				return pItem
			end
		end
	end

	return nil
end

function JunkDealer:isSchematic(pItem)
	if pItem == nil then
		return false
	end

	local sceno = SceneObject(pItem)
	local itemName = sceno:getDisplayedName()

	-- Try method 1: getTemplateObjectPath
	local templatePath = sceno:getTemplateObjectPath()

	if templatePath ~= nil and string.find(templatePath, "draft_schematic") then
		return true
	end

	-- Try method 2: Check the object name for schematic indicator
	if itemName ~= nil then
		local lowerName = string.lower(itemName)

		-- Check if it's a schematic by name patterns (most schematics have specific naming)
		if string.find(lowerName, "schematic") or string.find(lowerName, "blueprint") then
			return true
		end
	end

	return false
end

function JunkDealer:isBactaTank(pItem)
	if pItem == nil then
		return false
	end

	local templatePath = SceneObject(pItem):getTemplateObjectPath()

	if templatePath == nil then
		return false
	end

	local bactaTankTemplates = {
		"object/tangible/furniture/all/frn_all_medic_bacta_tank.iff",
		"object/tangible/furniture/all/frn_all_medic_bacta_tank_large.iff",
		"object/tangible/furniture/all/frn_all_medic_bacta_tank_advanced.iff",
		"object/tangible/furniture/all/frn_all_medical_console.iff",
		"object/tangible/furniture/all/frn_all_organichem_stores.iff",
		"object/tangible/loot/loot_schematic/chest_plain_schematic.iff",
		"object/tangible/loot/loot_schematic/chest_technical_schematic.iff",
		"object/tangible/loot/loot_schematic/armoire_plain_schematic.iff",
		"object/tangible/loot/loot_schematic/armoire_technical_schematic.iff",
		"object/tangible/loot/loot_schematic/cabinet_plain_schematic.iff",
		"object/tangible/loot/loot_schematic/cabinet_technical_schematic.iff"
	}

	for _, template in ipairs(bactaTankTemplates) do
		if templatePath == template then
			return true
		end
	end

	return false
end

function JunkDealer:isVillageResource(pItem)
	if pItem == nil then
		return false
	end

	local templatePath = SceneObject(pItem):getTemplateObjectPath()

	if templatePath == nil then
		return false
	end

	local villageResourceTemplates = {
		"object/tangible/loot/quest/endrine.iff",
		"object/tangible/loot/quest/ostrine.iff",
		"object/tangible/loot/quest/rudic.iff",
		"object/tangible/loot/quest/ardanium_ii.iff",
		"object/tangible/loot/quest/wind_crystal.iff"
	}

	for _, template in ipairs(villageResourceTemplates) do
		if templatePath == template then
			return true
		end
	end

	return false
end

function JunkDealer:isCustomBlockedItem(pItem)
	if pItem == nil then
		return false
	end

	local templatePath = SceneObject(pItem):getTemplateObjectPath()

	if templatePath == nil then
		return false
	end

	local blockedTemplates = {
		"object/tangible/tool/sarlacc_trash_can.iff",
		"object/tangible/collection/reward/fish_tank_reward.iff",
	}

	for _, t in ipairs(blockedTemplates) do
		if templatePath == t then
			return true
		end
	end

	return false
end

function JunkDealer:isAttachment(pItem)
	if pItem == nil then
		return false
	end

	local templatePath = SceneObject(pItem):getTemplateObjectPath()

	if templatePath == nil then
		return false
	end

	return templatePath == "object/tangible/gem/armor.iff" or templatePath == "object/tangible/gem/clothing.iff"
end

function JunkDealer:isLightsaberCrystalOrPearl(pItem)
	if pItem == nil then
		return false
	end

	local templatePath = SceneObject(pItem):getTemplateObjectPath()

	if templatePath == nil then
		return false
	end

	local crystalTemplates = {
		"object/tangible/component/weapon/lightsaber/lightsaber_module_force_crystal.iff",
		"object/tangible/component/weapon/lightsaber/lightsaber_lance_module_force_crystal.iff",
		"object/tangible/component/weapon/lightsaber/lightsaber_module_krayt_dragon_pearl.iff"
	}

	for _, template in ipairs(crystalTemplates) do
		if templatePath == template then
			return true
		end
	end

	return false
end

function JunkDealer:getSpecialJunkValue(pItem)
	-- Returns a hardcoded credit value for items with no junk value set but that should be sellable.
	-- Returns 0 if this is not a special item.
	if pItem == nil then
		return 0
	end

	local templatePath = SceneObject(pItem):getTemplateObjectPath()

	if templatePath == nil then
		return 0
	end

	local specialItems = {
		-- Rancor Hides (armor segment enhancement, no junk value in loot def)
		["object/tangible/component/armor/armor_segment_enhancement_rancor.iff"] = 150,
		-- Rancor Bile and Rancor Padded Armor Segment (no junk value in loot def)
		["object/tangible/component/chemistry/rancor_bile.iff"] = 250,
		["object/tangible/component/armor/armor_segment_padded_rancor.iff"] = 250,
		-- Low Quality / Very Low Quality DNA Samples
		["object/tangible/component/dna/dna_sample_low.iff"] = 100,
		["object/tangible/component/dna/dna_sample_very_low.iff"] = 50,
	}

	return specialItems[templatePath] or 0
end

function JunkDealer:isTreasureMap(pItem)
	if pItem == nil then
		return false
	end

	local templatePath = SceneObject(pItem):getTemplateObjectPath()

	if templatePath == nil then
		return false
	end

	if string.find(templatePath, "object/tangible/treasure_map/") then
		return true
	end

	if string.find(templatePath, "object/tangible/loot/quest/treasure_map_") then
		return true
	end

	return false
end

function JunkDealer:scanContainerForJunk(pPlayer, pContainer, dealerType, skipItem, junkList, nameBlacklist)
	-- Helper function to scan a container (inventory or backpack) for junk items
	if pContainer == nil then
		return
	end

	for i = 0, SceneObject(pContainer):getContainerObjectsSize() - 1, 1 do
		local pItem = SceneObject(pContainer):getContainerObject(i)

		if pItem ~= nil then
			local tano = TangibleObject(pItem)
			local sceno = SceneObject(pItem)

			if sceno:getObjectID() ~= skipItem then
				-- Get item info first
				local name = sceno:getDisplayedName()
				local craftersName = ""

				-- IMPORTANT: Skip containers/backpacks - don't sell them!
				if SceneObject(pItem):getContainerObjectsSize() > 0 then
					goto continue
				end

				-- Check if item is in the blacklist by name
				local isBlacklisted = false
				if name ~= nil then
					for _, blacklistedName in ipairs(nameBlacklist) do
						if name == blacklistedName then
							isBlacklisted = true
							break
						end
					end
				end

				-- If blacklisted, skip this item
				if isBlacklisted then
					goto continue
				end

				-- Safely get crafter's name
				if tano.getCraftersName then
					craftersName = tano:getCraftersName() or ""
				end

				-- Resource containers all live at object/resource_container/ — use template path, not name keywords
				local isResourceContainer = false
				local itemTemplatePath = SceneObject(pItem):getTemplateObjectPath()
				if itemTemplatePath ~= nil and string.find(itemTemplatePath, "^object/resource_container/") then
					isResourceContainer = true
				end
				-- Also catch quantity brackets [number] on edge-case containers
				if not isResourceContainer and name ~= nil and string.find(name, "%[%d+%]") then
					isResourceContainer = true
				end

				-- Check if item is a schematic
				local isSchematic = self:isSchematic(pItem)
				local isTreasureMap = self:isTreasureMap(pItem)

				-- Block protected item types
				if self:isCustomBlockedItem(pItem) or self:isAttachment(pItem) or self:isLightsaberCrystalOrPearl(pItem) then
					goto continue
				end

				-- Check exclusions
				local isCrafted = (craftersName ~= nil and craftersName ~= "")

				if isSchematic then
					-- Schematics are always buyable for 2000 credits
					local textTable = {"[2000] " .. name, sceno:getObjectID()}
					table.insert(junkList, textTable)
				elseif isTreasureMap then
					local textTable = {"[1000] " .. name, sceno:getObjectID()}
					table.insert(junkList, textTable)
				elseif self:isBactaTank(pItem) then
					local textTable = {"[2000] " .. name, sceno:getObjectID()}
					table.insert(junkList, textTable)
				elseif self:isVillageResource(pItem) then
					local textTable = {"[250] " .. name, sceno:getObjectID()}
					table.insert(junkList, textTable)
				elseif isResourceContainer then
				elseif isCrafted then
				else
					local specialValue = self:getSpecialJunkValue(pItem)
					if specialValue > 0 then
						local textTable = {"[" .. specialValue .. "] " .. name, sceno:getObjectID()}
						table.insert(junkList, textTable)
					elseif name ~= nil and name ~= "" then
						local value = 250

						if tano.getJunkValue then
							local junkValue = tano:getJunkValue()
							if junkValue ~= nil and junkValue > 0 then
								value = junkValue
							end
						end

						local textTable = {"[" .. value .. "] " .. name, sceno:getObjectID()}
						table.insert(junkList, textTable)
					end
				end
			end
			::continue::
		end
	end
end

function JunkDealer:getEligibleJunk(pPlayer, dealerType, skipItem)
	local junkList = {}

	local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")

	if pInventory == nil then
		return junkList
	end

	-- Items that should NOT be sellable to junk dealers (by custom name)
	local nameBlacklist = {
		"Bellum Gero Token",  -- Cannot be sold to junk dealers
		"Travel Ticket",
		"Jedi Robe",
		"Dark Jedi Robe",
		"Jedi Padawan Robe",
		"Holocron of Destiny"
	}

	-- First scan the main inventory
	self:scanContainerForJunk(pPlayer, pInventory, dealerType, skipItem, junkList, nameBlacklist)

	-- Then scan for backpacks and scan their contents
	for i = 0, SceneObject(pInventory):getContainerObjectsSize() - 1, 1 do
		local pItem = SceneObject(pInventory):getContainerObject(i)

		if pItem ~= nil then
			-- Check if this item is a container (backpack)
			local sceno = SceneObject(pItem)
			local displayName = sceno:getDisplayedName()

			-- Check if it's a container by looking for specific backpack templates or checking if it has container size > 0
			if SceneObject(pItem):getContainerObjectsSize() > 0 then
				-- Recursively scan this container
				self:scanContainerForJunk(pPlayer, pItem, dealerType, skipItem, junkList, nameBlacklist)
			end
		end
	end

	return junkList
end

function JunkDealer:sellListSuiCallback(pPlayer, pSui, eventIndex, otherPressed, rowIndex)
	local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")

	if pInventory == nil or eventIndex == 1 then
		deleteStringData(SceneObject(pPlayer):getObjectID() .. ":junkDealerType")
		return
	end

	if (otherPressed == "true") then
		-- "Sell All" button pressed - only sell actual junk items
		self:sellAllJunkOnly(pPlayer, pSui, pInventory)
	else
		-- "Sell" button pressed - sell individual item (any item)
		rowIndex = tonumber(rowIndex)

		if (rowIndex == -1) then
			deleteStringData(SceneObject(pPlayer):getObjectID() .. ":junkDealerType")
			return
		end

		self:sellItem(pPlayer, pSui, rowIndex, pInventory)
	end
end

function JunkDealer:sellAllJunkOnly(pPlayer, pSui, pInventory)
	deleteStringData(SceneObject(pPlayer):getObjectID() .. ":junkDealerType")
	local listBox = LuaSuiListBox(pSui)
	local pNpc = listBox:getUsingObject()

	if pNpc == nil then
		return
	end

	local name = SceneObject(pNpc):getDisplayedName()
	local amount = 0
	local itemsSold = 0

	-- Sell items that have proper junk values (> 0) or are schematics (2000 credits)
	for i = 0, listBox:getMenuSize() - 1, 1 do
		local oid = listBox:getMenuObjectID(i)
		-- Search for item in inventory and all backpacks
		local pItem = self:findItemInContainers(pPlayer, oid)

		if pItem ~= nil then
			local value = 0

			-- Check if item is a schematic first
			if self:isSchematic(pItem) then
				value = 2000
			elseif self:isTreasureMap(pItem) then
				value = 1000
			elseif self:isBactaTank(pItem) then
				value = 2000
			elseif self:isVillageResource(pItem) then
				value = 250
			else
				local specialValue = self:getSpecialJunkValue(pItem)
				if specialValue > 0 then
					value = specialValue
				else
					value = TangibleObject(pItem):getJunkValue()
				end
			end

			-- Only sell items with actual values > 0
			if value ~= nil and value > 0 then
				createEvent(10, "JunkDealer", "destroyItem", pItem, "")
				amount = amount + value
				itemsSold = itemsSold + 1
			end
		end
	end

	if itemsSold > 0 then
		CreatureObject(pPlayer):addCashCredits(amount, true)

		local messageString = LuaStringIdChatParameter("@loot_dealer:prose_sold_all_junk") -- You sell all of your loot to %TT for %DI credits
		messageString:setTT(name)
		messageString:setDI(amount)
		CreatureObject(pPlayer):sendSystemMessage(messageString:_getObject())
	else
		CreatureObject(pPlayer):sendSystemMessage("You have no actual junk items to sell in bulk.")
	end
end

function JunkDealer:sellAllItems(pPlayer, pSui, pInventory)
	deleteStringData(SceneObject(pPlayer):getObjectID() .. ":junkDealerType")
	local listBox = LuaSuiListBox(pSui)
	local pNpc = listBox:getUsingObject()

	if pNpc == nil then
		return
	end

	local name = SceneObject(pNpc):getDisplayedName()
	local amount = 0

	for i = 0, listBox:getMenuSize() - 1, 1 do
		local oid = listBox:getMenuObjectID(i)
		local pItem = SceneObject(pInventory):getContainerObjectById(oid)

		if pItem ~= nil then
			local value = TangibleObject(pItem):getJunkValue()
			createEvent(10, "JunkDealer", "destroyItem", pItem, "")

			amount = amount + value
		end
	end

	CreatureObject(pPlayer):addCashCredits(amount, true)

	local messageString = LuaStringIdChatParameter("@loot_dealer:prose_sold_all_junk") -- You sell all of your loot to %TT for %DI credits
	messageString:setTT(name)
	messageString:setDI(amount)
	CreatureObject(pPlayer):sendSystemMessage(messageString:_getObject())
end

function JunkDealer:destroyItem(pItem)
	if (pItem == nil) then
		return
	end

	SceneObject(pItem):destroyObjectFromWorld()
	SceneObject(pItem):destroyObjectFromDatabase()
end

function JunkDealer:sellItem(pPlayer, pSui, rowIndex, pInventory)
	local listBox = LuaSuiListBox(pSui)
	local pNpc = listBox:getUsingObject()
	local oid = listBox:getMenuObjectID(rowIndex)

	-- Search for item in inventory and all backpacks
	local pItem = self:findItemInContainers(pPlayer, oid)

	if pItem == nil or pNpc == nil then
		deleteStringData(SceneObject(pPlayer):getObjectID() .. ":junkDealerType")
		return
	end

	local item = SceneObject(pItem)
	local itemName = item:getDisplayedName()

	-- Safety check: prevent selling blacklisted items by name
	local nameBlacklist = {
		"Bellum Gero Token",  -- Cannot be sold to junk dealers
		"Travel Ticket",
		"Jedi Robe",
		"Dark Jedi Robe",
		"Jedi Padawan Robe",
		"Holocron of Destiny"
	}

	if itemName ~= nil then
		for _, blacklistedName in ipairs(nameBlacklist) do
			if itemName == blacklistedName then
				CreatureObject(pPlayer):sendSystemMessage("You cannot sell that item to a junk dealer.")
				deleteStringData(SceneObject(pPlayer):getObjectID() .. ":junkDealerType")
				return
			end
		end
	end

	-- Safety check: prevent selling protected item types by template path
	if self:isCustomBlockedItem(pItem) or self:isAttachment(pItem) or self:isLightsaberCrystalOrPearl(pItem) then
		CreatureObject(pPlayer):sendSystemMessage("You cannot sell that item to a junk dealer.")
		deleteStringData(SceneObject(pPlayer):getObjectID() .. ":junkDealerType")
		return
	end

	local skipItem = item:getObjectID()
	local name = item:getDisplayedName()

	-- Check if this is a schematic - if so, buy for 2000 credits
	local isSchematic = self:isSchematic(pItem)
	local isTreasureMap = self:isTreasureMap(pItem)
	local isBactaTank = self:isBactaTank(pItem)
	local isVillageResource = self:isVillageResource(pItem)

	local value = 250
	if isSchematic then
		value = 2000
	elseif isTreasureMap then
		value = 1000
	elseif isBactaTank then
		value = 2000
	elseif isVillageResource then
		value = 250
	else
		local specialValue = self:getSpecialJunkValue(pItem)
		if specialValue > 0 then
			value = specialValue
		else
			value = TangibleObject(pItem):getJunkValue()

			if value == nil or value <= 0 then
				value = 250
			end
		end
	end

	createEvent(10, "JunkDealer", "destroyItem", pItem, "")

	CreatureObject(pPlayer):addCashCredits(value, true)

	local messageString = LuaStringIdChatParameter("@loot_dealer:prose_sold_junk") -- You sell %TT for %DI credits.
	messageString:setTT(name)
	messageString:setDI(value)
	CreatureObject(pPlayer):sendSystemMessage(messageString:_getObject())

	local dealerType = readStringData(SceneObject(pPlayer):getObjectID() .. ":junkDealerType")
	self:sendSellJunkSelection(pPlayer, pNpc, dealerType, skipItem)
end

return JunkDealer
