-- ##############################################################
-- item_lock_manager.lua
-- Allows players to lock items to prevent deletion and trading
-- Locked items show with a blue highlight in inventory
-- ##############################################################

ItemLockManager = {}

-- Check if an item is locked
function ItemLockManager:isLocked(pItem)
  if not pItem then return false end

  local item = LuaSceneObject(pItem)
  if not item then return false end

  return item:hasObjVar("item_locked") and item:getObjectVariable("item_locked") == 1
end

-- Lock an item
function ItemLockManager:lockItem(pItem, pPlayer)
  if not pItem or not pPlayer then return false end

  local item = LuaSceneObject(pItem)
  if not item then return false end

  -- Set the locked flag
  item:setObjVar("item_locked", 1)

  -- Try to set blue highlight (optionsBitmask might control this)
  -- This sets the BLUE option bit if available
  pcall(function()
    local tangible = LuaTangibleObject(pItem)
    if tangible then
      local currentOptions = tangible:getOptionsBitmask()
      -- Bit 0x00000100 (256) is often used for blue/special highlighting
      tangible:setOptionBit(0x00000100, true)
    end
  end)

  -- Notify player
  local player = LuaCreatureObject(pPlayer)
  if player then
    local itemName = item:getCustomObjectName()
    if not itemName or itemName == "" then
      itemName = item:getObjectName()
    end
    player:sendSystemMessage("Item locked: " .. itemName .. " - This item cannot be deleted or traded.")
  end

  return true
end

-- Unlock an item
function ItemLockManager:unlockItem(pItem, pPlayer)
  if not pItem or not pPlayer then return false end

  local item = LuaSceneObject(pItem)
  if not item then return false end

  -- Remove the locked flag
  item:removeObjVar("item_locked")

  -- Remove blue highlight
  pcall(function()
    local tangible = LuaTangibleObject(pItem)
    if tangible then
      tangible:setOptionBit(0x00000100, false)
    end
  end)

  -- Notify player
  local player = LuaCreatureObject(pPlayer)
  if player then
    local itemName = item:getCustomObjectName()
    if not itemName or itemName == "" then
      itemName = item:getObjectName()
    end
    player:sendSystemMessage("Item unlocked: " .. itemName .. " - This item can now be deleted or traded normally.")
  end

  return true
end

-- Check if player can destroy an item (called from destroy handler)
function ItemLockManager:canDestroy(pItem, pPlayer)
  if self:isLocked(pItem) then
    if pPlayer then
      local player = LuaCreatureObject(pPlayer)
      if player then
        player:sendSystemMessage("@base_player:cannot_destroy_locked_item") -- "You cannot destroy a locked item."
      end
    end
    return false
  end
  return true
end

-- Check if player can trade an item (called from trade handler)
function ItemLockManager:canTrade(pItem, pPlayer)
  if self:isLocked(pItem) then
    if pPlayer then
      local player = LuaCreatureObject(pPlayer)
      if player then
        player:sendSystemMessage("@base_player:cannot_trade_locked_item") -- "You cannot trade a locked item."
      end
    end
    return false
  end
  return true
end

return ItemLockManager
