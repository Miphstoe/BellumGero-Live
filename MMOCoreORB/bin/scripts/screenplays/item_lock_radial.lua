-- ##############################################################
-- item_lock_radial.lua
-- Adds "Lock Item" and "Unlock Item" radial menu options to all items
-- ##############################################################

local ItemLockManager = require("screenplays.managers.item_lock_manager")

ItemLockRadial = ScreenPlay:new {
  numberOfActs = 1,
  screenplayName = "ItemLockRadial"
}

registerScreenPlay("ItemLockRadial", true)

-- Radial menu options
local RADIAL_LOCK_ITEM = 220  -- Custom radial option ID
local RADIAL_UNLOCK_ITEM = 221  -- Custom radial option ID

function ItemLockRadial:start()
  print("[ITEM-LOCK] Item locking system enabled")
end

-- Add radial menu options to items
function ItemLockRadial:addRadialOptions(pCreatureObject, pTarget, pRadialMenu)
  if not pCreatureObject or not pTarget then
    return
  end

  -- Check if target is an item (TangibleObject)
  local targetObject = LuaSceneObject(pTarget)
  if not targetObject then
    return
  end

  -- Only add options to items in player's inventory
  local player = LuaCreatureObject(pCreatureObject)
  if not player then
    return
  end

  -- Check if item is in player's inventory or equipped
  local parent = targetObject:getParent()
  if not parent then
    return
  end

  local parentObj = LuaSceneObject(parent)
  if not parentObj then
    return
  end

  -- Check if parent is the player or player's inventory
  local playerOID = SceneObject(pCreatureObject):getObjectID()
  local parentOID = parentObj:getObjectID()

  -- Simple check: if parent is player or owned by player
  local isPlayerOwned = false
  if parentOID == playerOID then
    isPlayerOwned = true
  else
    -- Check if parent is player's inventory
    local grandParent = parentObj:getParent()
    if grandParent then
      local grandParentOID = SceneObject(grandParent):getObjectID()
      if grandParentOID == playerOID then
        isPlayerOwned = true
      end
    end
  end

  if not isPlayerOwned then
    return
  end

  -- Add lock/unlock option based on current state
  if ItemLockManager:isLocked(pTarget) then
    pRadialMenu:addOption(RADIAL_UNLOCK_ITEM, "Unlock Item", 3)
  else
    pRadialMenu:addOption(RADIAL_LOCK_ITEM, "Lock Item", 3)
  end
end

-- Handle radial menu selection
function ItemLockRadial:handleObjectMenuSelect(pCreatureObject, pTarget, selectedID)
  if not pCreatureObject or not pTarget then
    return 0
  end

  if selectedID == RADIAL_LOCK_ITEM then
    ItemLockManager:lockItem(pTarget, pCreatureObject)
    return 1
  elseif selectedID == RADIAL_UNLOCK_ITEM then
    ItemLockManager:unlockItem(pTarget, pCreatureObject)
    return 1
  end

  return 0
end

print("[ITEM-LOCK] Item lock radial menu loaded")
