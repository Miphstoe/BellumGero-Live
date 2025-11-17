-- bsv_quiz_convo_handler.lua
-- Conversation handler for the Blue Shadow Virus random quiz droids.
-- - Chooses a random quiz variant (1–3) on start
-- - Enforces a per-character 20 hour cooldown on SUCCESS ONLY
-- - Awards a random item from a weighted reward pool when successful

bsv_quiz_convo_handler = conv_handler:new {}

-- ============================================================================
--  CONFIG: WEIGHTED REWARD POOL
-- ============================================================================
-- Each entry must be:
--   { template = "<object template path>", weight = <number> }
--
-- The chance of each item is proportional to its weight, just like loot groups.
-- Example:
--   80 = common, 15 = uncommon, 5 = rare
--
-- NOTE: Replace the examples below with your real item templates.

local BSV_REWARD_ITEMS = {
    -- { template = "object/tangible/loot/quest/bsv_common_datapad.iff", weight = 80 },
    -- { template = "object/tangible/loot/quest/bsv_uncommon_patch.iff", weight = 15 },
    -- { template = "object/tangible/loot/quest/bsv_rare_research_tool.iff", weight = 5 },
}

-- ============================================================================
--  PER-CHARACTER COOLDOWN (20 hours)
-- ============================================================================

local BSV_DAILY_PREFIX   = "bsvQuizDaily:"
local BSV_TAG_RESET      = "reset"
local BSV_COOLDOWN_SECS  = 72000   -- 20 hours

local function bsv_now()
    return getTimestamp()
end

local function bsv_key(pPlayer)
    -- Keyed by player object ID
    return BSV_DAILY_PREFIX .. tostring(SceneObject(pPlayer):getObjectID()) .. ":" .. BSV_TAG_RESET
end

local function bsv_clearIfExpired(pPlayer)
    local key     = bsv_key(pPlayer)
    local resetAt = readData(key)

    if resetAt ~= nil and resetAt ~= 0 and bsv_now() >= resetAt then
        deleteData(key)
    end
end

local function bsv_getCooldownRemaining(pPlayer)
    bsv_clearIfExpired(pPlayer)

    local key     = bsv_key(pPlayer)
    local resetAt = readData(key)

    if resetAt == nil or resetAt == 0 then
        return 0
    end

    local rem = resetAt - bsv_now()
    if rem < 0 then rem = 0 end
    return rem
end

local function bsv_startCooldown(pPlayer)
    local key = bsv_key(pPlayer)
    writeData(key, bsv_now() + BSV_COOLDOWN_SECS)
end

local function bsv_formatTime(secs)
    if secs <= 0 then
        return "0s"
    end

    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    local s = secs % 60

    if h > 0 then
        return string.format("%dh %dm", h, m)
    end

    if m > 0 then
        return string.format("%dm %ds", m, s)
    end

    return string.format("%ds", s)
end

-- ============================================================================
--  WEIGHTED REWARD SELECTION
-- ============================================================================

local function bsv_selectWeightedReward()
    if BSV_REWARD_ITEMS == nil or #BSV_REWARD_ITEMS == 0 then
        return nil
    end

    -- Calculate total weight
    local totalWeight = 0
    for _, entry in ipairs(BSV_REWARD_ITEMS) do
        local w = entry.weight or 0
        if w > 0 then
            totalWeight = totalWeight + w
        end
    end

    if totalWeight <= 0 then
        return nil
    end

    -- Roll within total weight
    local roll       = getRandomNumber(1, totalWeight)
    local cumulative = 0

    for _, entry in ipairs(BSV_REWARD_ITEMS) do
        local w = entry.weight or 0
        if w > 0 then
            cumulative = cumulative + w
            if roll <= cumulative then
                return entry.template
            end
        end
    end

    return nil
end

local function bsv_giveRandomReward(pPlayer)
    local template = bsv_selectWeightedReward()

    if template == nil or template == "" then
        CreatureObject(pPlayer):sendSystemMessage("Blue Shadow Virus reward configuration error. No item granted.")
        printLuaError("BSV QUIZ: Weighted reward selection failed (empty pool or invalid weights).")
        return
    end

    local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
    if pInventory == nil then
        CreatureObject(pPlayer):sendSystemMessage("You have no inventory space for the reward.")
        printLuaError("BSV QUIZ: Player has no inventory; cannot give reward.")
        return
    end

    local pItem = giveItem(pInventory, template, -1)
    if pItem == nil then
        CreatureObject(pPlayer):sendSystemMessage("Your inventory is full. No reward could be granted.")
        printLuaError("BSV QUIZ: giveItem failed for template " .. template .. " (inventory full or invalid template?).")
        return
    end

    -- Optional debug
    printLuaError("BSV QUIZ: Granted weighted reward item " .. template .. " to player " .. SceneObject(pPlayer):getObjectID())
end

-- ============================================================================
--  CONVERSATION ENTRY
-- ============================================================================

function bsv_quiz_convo_handler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
    if pConvTemplate == nil or pPlayer == nil then
        printLuaError("BSV QUIZ: getInitialScreen called with nil convTemplate or player.")
        return nil
    end

    local convoTemplate = LuaConversationTemplate(pConvTemplate)
    if convoTemplate == nil then
        printLuaError("BSV QUIZ: LuaConversationTemplate is nil in getInitialScreen.")
        return nil
    end

    -- Check cooldown first
    local remaining = bsv_getCooldownRemaining(pPlayer)
    if remaining > 0 then
        local cdScreen = convoTemplate:getScreen("on_cooldown")
        if cdScreen ~= nil then
            local msg = string.format("You have already completed a Blue Shadow Virus quiz recently. You may attempt another in %s.",
                                      bsv_formatTime(remaining))
            CreatureObject(pPlayer):sendSystemMessage(msg)
            return cdScreen
        end
    end

    -- Not on cooldown: pick a random quiz variant
    -- 1 = characters, 2 = virus, 3 = Iego/cure
    local quizIndex     = getRandomNumber(1, 3)
    local startScreenId = "quiz" .. quizIndex .. "_start"

    local startScreen = convoTemplate:getScreen(startScreenId)
    if startScreen == nil then
        printLuaError("BSV QUIZ: Failed to find start screen '" .. tostring(startScreenId) .. "'. Falling back to quiz1_start.")
        startScreen = convoTemplate:getScreen("quiz1_start")
    end

    return startScreen
end

-- ============================================================================
--  SCREEN HANDLERS (APPLY COOLDOWN + REWARD ON SUCCESS ONLY)
-- ============================================================================

function bsv_quiz_convo_handler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
    if pConvScreen == nil or pPlayer == nil then
        printLuaError("BSV QUIZ: runScreenHandlers called with nil screen or player.")
        return pConvScreen
    end

    local screen   = LuaConversationScreen(pConvScreen)
    local screenId = screen:getScreenID()

    -- Only care about success screens (any quiz's all_correct)
    if string.find(screenId, "_all_correct", 1, true) ~= nil then
        local remaining = bsv_getCooldownRemaining(pPlayer)

        if remaining > 0 then
            -- Already rewarded within last 20h: do NOT give another reward
            local msg = string.format("You have already received a reward for a Blue Shadow Virus quiz recently. You may earn another in %s.",
                                      bsv_formatTime(remaining))
            CreatureObject(pPlayer):sendSystemMessage(msg)
            printLuaError("BSV QUIZ: player reached '" .. screenId .. "' but is on cooldown; reward skipped.")
            return pConvScreen
        end

        -- Start cooldown and give reward
        bsv_startCooldown(pPlayer)

        CreatureObject(pPlayer):sendSystemMessage("You answered all Blue Shadow Virus questions correctly and receive a reward.")
        printLuaError("BSV QUIZ: player reached '" .. screenId .. "'; reward and cooldown applied.")

        bsv_giveRandomReward(pPlayer)
    end

    return pConvScreen
end
