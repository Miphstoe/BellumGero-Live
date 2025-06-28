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

function JunkDealer:getEligibleJunk(pPlayer, dealerType, skipItem)
	local junkList = {}

	local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")

	if pInventory == nil then
		return junkList
	end

	for i = 0, SceneObject(pInventory):getContainerObjectsSize() - 1, 1 do
		local pItem = SceneObject(pInventory):getContainerObject(i)

		if pItem ~= nil then
			local tano = TangibleObject(pItem)
			local sceno = SceneObject(pItem)

			if sceno:getObjectID() ~= skipItem then
				-- Get item info first
				local name = sceno:getDisplayedName()
				local craftersName = ""
				
				-- Safely get crafter's name
				if tano.getCraftersName then
					craftersName = tano:getCraftersName() or ""
				end
				
				-- More comprehensive resource container detection
				local isResourceContainer = false
				if name ~= nil then
					local lowerName = string.lower(name)
					
					-- Check for resource container keywords
					local resourceKeywords = {
						"hide", "bone", "meat", "milk", "blood", "hair", "horn", "scalp",
						"wood", "softwood", "hardwood", "conifer", "deciduous", "evergreen",
						"ore", "metal", "iron", "copper", "aluminum", "steel", "radioactive",
						"gas", "inert", "reactive", "chemical", "liquid", "solid",
						"water", "moisture", "condensed", "vapor", "steam",
						"energy", "geothermal", "solar", "tidal", "wind",
						"gemstone", "crystal", "carbonate", "sedimentary", "igneous",
						"fiber", "vegetable", "fruit", "grain", "tuber", "berry",
						"seafood", "fish", "crustacean", "mollusk"
					}
					
					-- Also check for common resource container patterns
					local containerPatterns = {
						"container", "units of", "units", "sample", "batch"
					}
					
					-- Check if name contains resource keywords
					for _, keyword in ipairs(resourceKeywords) do
						if string.find(lowerName, keyword) then
							isResourceContainer = true
							break
						end
					end
					
					-- Additional checks for container patterns
					if not isResourceContainer then
						for _, pattern in ipairs(containerPatterns) do
							if string.find(lowerName, pattern) then
								isResourceContainer = true
								break
							end
						end
					end
					
					-- Check for quantity brackets [number] which almost always indicates resources
					if not isResourceContainer and string.find(name, "%[%d+%]") then
						isResourceContainer = true
					end
					
					-- Check for "wooly hide" specifically since that was your example
					if string.find(lowerName, "wooly") then
						isResourceContainer = true
					end
				end
				
				print("Checking item: " .. (name or "nil") .. ", crafter: " .. craftersName .. ", isResource: " .. tostring(isResourceContainer))
				
				-- Check exclusions
				local isCrafted = (craftersName ~= nil and craftersName ~= "")
				
				if isResourceContainer then
					print("Excluding resource container: " .. name)
				elseif isCrafted then
					print("Excluding crafted item: " .. name .. " by " .. craftersName)
				elseif name ~= nil and name ~= "" then
					-- Item is eligible
					local value = 1 -- Default value
					
					-- Safely get junk value
					if tano.getJunkValue then
						local junkValue = tano:getJunkValue()
						if junkValue ~= nil and junkValue > 0 then
							value = junkValue
						end
					end
					
					local textTable = {"[" .. value .. "] " .. name, sceno:getObjectID()}
					table.insert(junkList, textTable)
					print("Added item to sell list: " .. name .. " for " .. value .. " credits")
				end
			end
		end
	end

	print("Total eligible items found: " .. #junkList)
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

	-- Only sell items that have proper junk values (> 0)
	for i = 0, listBox:getMenuSize() - 1, 1 do
		local oid = listBox:getMenuObjectID(i)
		local pItem = SceneObject(pInventory):getContainerObjectById(oid)

		if pItem ~= nil then
			local value = TangibleObject(pItem):getJunkValue()
			
			-- Only sell items with actual junk values > 0
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
	local pItem = SceneObject(pInventory):getContainerObjectById(oid)

	if pItem == nil or pNpc == nil then
		deleteStringData(SceneObject(pPlayer):getObjectID() .. ":junkDealerType")
		return
	end

	local item = SceneObject(pItem)
	local skipItem = item:getObjectID()
	local name = item:getDisplayedName()
	local value = TangibleObject(pItem):getJunkValue()
	
	-- If item has no junk value, give it a default value of 250 credit
	if value == nil or value <= 0 then
		value = 250 -- Default value for items without a junk value
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