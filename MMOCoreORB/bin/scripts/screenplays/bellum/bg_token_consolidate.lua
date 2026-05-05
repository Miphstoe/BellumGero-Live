-- BG Token Consolidate Menu Component
-- Adds a "Consolidate Tokens" right-click option to Bellum Gero Tokens.
-- When selected, all BG tokens in the player's main inventory
-- are merged into the clicked token via useCount (getCount/setCount).
-- Only appears on items named "Bellum Gero Token" — actual jewelry settings
-- used by crafters are unaffected.

local BG_TOKEN_CONSOLIDATE_MENU_ID = 125

local BG_TOKEN_TEMPLATE_SET = {
    ["object/tangible/component/clothing/jewelry_setting.iff"] = true,
    ["object/tangible/component/clothing/shared_jewelry_setting.iff"] = true,
    ["object/token/token.iff"] = true,
    ["object/token/shared_token.iff"] = true,
}

local function isBgToken(pObject)
    if pObject == nil then return false end

    local obj = LuaSceneObject(pObject)
    if obj == nil then return false end

    local nameOk, name = pcall(function() return obj:getCustomObjectName() end)
    if not nameOk or name == nil or name == "" then
        nameOk, name = pcall(function() return obj:getDisplayedName() end)
    end
    if not nameOk or name == nil or name == "" then return false end

    if not string.find(string.lower(name), "bellum gero token") then
        return false
    end

    local tmplOk, tmpl = pcall(function() return obj:getTemplateObjectPath() end)
    if not tmplOk or tmpl == nil then return false end

    return BG_TOKEN_TEMPLATE_SET[string.lower(tmpl)] == true
end

local function isDirectChildOfInventory(pObject, pInventory)
    if pObject == nil or pInventory == nil then return false end

    local object = SceneObject(pObject)
    if object == nil then return false end

    return object:getParent() == pInventory
end

-- Returns total count of all BG tokens found directly in the main inventory.
local function countTokensInInventory(container)
    local total = 0
    local containerObj = LuaSceneObject(container)
    if containerObj == nil then return 0 end

    local sizeOk, size = pcall(function() return containerObj:getContainerObjectsSize() end)
    if not sizeOk or size == nil or size == 0 then return 0 end

    for i = 0, size - 1 do
        local pObj = containerObj:getContainerObject(i)
        if pObj then
            if isBgToken(pObj) then
                local cntOk, cnt = pcall(function() return LuaTangibleObject(pObj):getCount() end)
                total = total + ((cntOk and cnt and cnt > 0) and cnt or 1)
            end
        end
    end
    return total
end

-- Returns true if any BG tokens are found in subcontainers of the main inventory.
local function hasTokensInSubcontainers(container)
    local containerObj = LuaSceneObject(container)
    if containerObj == nil then return false end

    local sizeOk, size = pcall(function() return containerObj:getContainerObjectsSize() end)
    if not sizeOk or size == nil or size == 0 then return false end

    for i = 0, size - 1 do
        local pObj = containerObj:getContainerObject(i)
        if pObj and not isBgToken(pObj) then
            local childObj = LuaSceneObject(pObj)
            if childObj then
                local childSizeOk, childSize = pcall(function() return childObj:getContainerObjectsSize() end)
                if childSizeOk and childSize and childSize > 0 then
                    for j = 0, childSize - 1 do
                        local pChild = childObj:getContainerObject(j)
                        if pChild then
                            if isBgToken(pChild) or hasTokensInSubcontainers(pChild) then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end

    return false
end

-- Destroys all BG tokens in the main inventory except the one with keeperOID.
-- Iterates backwards so destruction doesn't shift indices.
local function destroyTokensExceptKeeper(container, keeperOID)
    local containerObj = LuaSceneObject(container)
    if containerObj == nil then return end

    local sizeOk, size = pcall(function() return containerObj:getContainerObjectsSize() end)
    if not sizeOk or size == nil or size == 0 then return end

    for i = size - 1, 0, -1 do
        local pObj = containerObj:getContainerObject(i)
        if pObj then
            local obj = LuaSceneObject(pObj)
            if obj then
                if isBgToken(pObj) then
                    if obj:getObjectID() ~= keeperOID then
                        pcall(function() obj:destroyObjectFromWorld(true) end)
                        pcall(function() obj:destroyObjectFromDatabase(true) end)
                    end
                end
            end
        end
    end
end

-- ── Menu Component ──────────────────────────────────────────────────────────

BgTokenMenuComponent = {}

function BgTokenMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
    if pSceneObject == nil or pPlayer == nil then return end

    -- Only show the option on actual BG tokens, not on crafting jewelry settings
    if not isBgToken(pSceneObject) then return end

    local menuResponse = LuaObjectMenuResponse(pMenuResponse)
    menuResponse:addRadialMenuItem(BG_TOKEN_CONSOLIDATE_MENU_ID, 3, "Consolidate Tokens")
end

function BgTokenMenuComponent:handleObjectMenuSelect(pObject, pPlayer, selectedID)
    if pObject == nil or pPlayer == nil then return 0 end
    if selectedID ~= BG_TOKEN_CONSOLIDATE_MENU_ID then return 0 end

    if not isBgToken(pObject) then return 0 end

    -- Verify the item is actually somewhere in the player's inventory tree
    if not SceneObject(pObject):isASubChildOf(pPlayer) then
        CreatureObject(pPlayer):sendSystemMessage("The token must be in your inventory.")
        return 0
    end

    local pCreature = LuaCreatureObject(pPlayer)
    if pCreature == nil then return 0 end

    local pInventory = pCreature:getSlottedObject("inventory")
    if pInventory == nil then return 0 end

    if not isDirectChildOfInventory(pObject, pInventory) then
        CreatureObject(pPlayer):sendSystemMessage("Bellum Gero Tokens must be in your main inventory to consolidate.")
        return 0
    end

    if hasTokensInSubcontainers(pInventory) then
        CreatureObject(pPlayer):sendSystemMessage("Bellum Gero Tokens must be in your main inventory to consolidate.")
        return 0
    end

    local keeperOID = SceneObject(pObject):getObjectID()

    -- Count every BG token directly in the main inventory only
    local total = countTokensInInventory(pInventory)

    if total <= 1 then
        CreatureObject(pPlayer):sendSystemMessage("You have no other Bellum Gero Tokens to consolidate.")
        return 0
    end

    -- Destroy all tokens except the keeper
    destroyTokensExceptKeeper(pInventory, keeperOID)

    -- Set the keeper's stack count to the total
    pcall(function() LuaTangibleObject(pObject):setCount(total) end)

    CreatureObject(pPlayer):sendSystemMessage("Consolidated " .. total .. " Bellum Gero Tokens into one.")
    return 0
end
