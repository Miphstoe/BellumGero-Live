-- bsv_quiz_convo_handler.lua
-- Randomized static quiz handler:
-- - You define many question screens: q001, q002, ..., qNN in bsv_quiz_convo.lua
-- - Each question's correct answer goes to "q_correct", wrong answers go to "q_failed"
-- - On each attempt, the handler picks 5 unique question numbers at random
-- - Player must go through all 5 correctly in a row
-- - Wrong answer -> immediate failure, no cooldown
-- - All 5 correct -> reward + 20-hour cooldown

bsv_quiz_convo_handler = conv_handler:new {}

---------------------------------------------------------
-- CONFIG
---------------------------------------------------------

-- How many total question screens you define (q001 .. qNN).
-- This must match the highest question number you actually create.
local BSV_TOTAL_QUESTIONS   = 50      -- <<< set this to how many qXXX screens you have
local BSV_QUESTIONS_PER_RUN = 5       -- always 5 as you requested

local BSV_COOLDOWN_SECS     = 72000   -- 20 hours

local BSV_CD_PREFIX         = "bsvQuizDaily:"
local BSV_CD_TAG_RESET      = "reset"

local BSV_SESSION_PREFIX    = "bsvQuizSession:"
local BSV_INDEX_SUFFIX      = ":idx"  -- current question index (1..5)
local BSV_SLOT_SUFFIX       = ":slot:" -- slot->questionNumber

-- Weighted reward pool: fill this with your actual templates.
-- Example entries:
-- { template = "object/tangible/furniture/technical/chair_s01.iff", weight = 30 },
local BSV_REWARD_ITEMS = {
    -- TODO: add your rewards here
    { template = "object/tangible/furniture/all/frn_all_medic_bacta_tank.iff",         weight = 10 },
    { template = "object/tangible/furniture/all/frn_all_medic_bacta_tank_large.iff",   weight = 10 },
    { template = "object/tangible/furniture/all/frn_all_medic_bacta_tank_advanced.iff",weight = 10 },
    { template = "object/tangible/furniture/all/frn_all_organichem_stores.iff",         weight = 10 },
    { template = "object/tangible/furniture/all/frn_all_medical_console.iff",           weight = 10 },
    { template = "object/tangible/furniture/all/frn_all_droideka.iff",                 weight = 2 },
    { template = "object/tangible/furniture/all/frn_all_super_battle_droid.iff",       weight = 2 },
    { template = "object/tangible/furniture/all/frn_all_battle_droid.iff",             weight = 2 },
    { template = "object/tangible/furniture/all/frn_all_21b_surgical_droid.iff",       weight = 2 },
    { template = "object/tangible/furniture/all/frn_all_ito_droid.iff",                weight = 2 },
    -- { template = "object/tangible/furniture/technical/coffee_table_s01.iff",  weight = 25 },
    -- { template = "object/tangible/furniture/jedi/frn_all_dark_throne.iff",    weight = 4 },
    -- { template = "object/tangible/furniture/space/frn_couch_falcon_corner_s01.iff", weight = 2 },
}

---------------------------------------------------------
-- TIME / KEY HELPERS
---------------------------------------------------------

local function bsvNow()
    return getTimestamp()
end

local function bsvCdKey(pPlayer)
    return BSV_CD_PREFIX .. tostring(SceneObject(pPlayer):getObjectID()) .. ":" .. BSV_CD_TAG_RESET
end

local function bsvIdxKey(pPlayer)
    return BSV_SESSION_PREFIX .. tostring(SceneObject(pPlayer):getObjectID()) .. BSV_INDEX_SUFFIX
end

local function bsvSlotKey(pPlayer, slot)
    return BSV_SESSION_PREFIX .. tostring(SceneObject(pPlayer):getObjectID()) .. BSV_SLOT_SUFFIX .. tostring(slot)
end

local function bsvFormatTime(secs)
    if secs <= 0 then return "0s" end
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    if h > 0 then
        return string.format("%dh %dm", h, m)
    elseif m > 0 then
        return string.format("%dm", m)
    else
        return string.format("%ds", secs)
    end
end

---------------------------------------------------------
-- COOLDOWN HELPERS
---------------------------------------------------------

local function bsvClearExpiredCooldown(pPlayer)
    local key   = bsvCdKey(pPlayer)
    local reset = readData(key)
    if reset ~= nil and reset ~= 0 and bsvNow() >= reset then
        deleteData(key)
    end
end

local function bsvGetCooldownRemaining(pPlayer)
    bsvClearExpiredCooldown(pPlayer)
    local key   = bsvCdKey(pPlayer)
    local reset = readData(key)
    if reset == nil or reset == 0 then
        return 0
    end
    local rem = reset - bsvNow()
    if rem < 0 then rem = 0 end
    return rem
end

local function bsvStartCooldown(pPlayer)
    writeData(bsvCdKey(pPlayer), bsvNow() + BSV_COOLDOWN_SECS)
end

---------------------------------------------------------
-- REWARD HELPERS (WEIGHTED)
---------------------------------------------------------

local function bsvSelectWeightedReward()
    if BSV_REWARD_ITEMS == nil or #BSV_REWARD_ITEMS == 0 then
        return nil
    end

    local total = 0
    for _, entry in ipairs(BSV_REWARD_ITEMS) do
        total = total + (entry.weight or 0)
    end
    if total <= 0 then
        return nil
    end

    local roll = getRandomNumber(1, total)
    local sum  = 0
    for _, entry in ipairs(BSV_REWARD_ITEMS) do
        sum = sum + (entry.weight or 0)
        if roll <= sum then
            return entry.template
        end
    end
    return nil
end

local function bsvGiveReward(pPlayer)
    local template = bsvSelectWeightedReward()
    if template == nil then
        CreatureObject(pPlayer):sendSystemMessage("No quiz rewards are configured.")
        printLuaError("BSV QUIZ: reward pool is empty or invalid.")
        return
    end

    local pInv = SceneObject(pPlayer):getSlottedObject("inventory")
    if pInv == nil then
        CreatureObject(pPlayer):sendSystemMessage("You have no inventory space for rewards.")
        printLuaError("BSV QUIZ: player has no inventory.")
        return
    end

    local pItem = giveItem(pInv, template, -1)
    if pItem == nil then
        CreatureObject(pPlayer):sendSystemMessage("Your inventory is full. No reward could be granted.")
        printLuaError("BSV QUIZ: giveItem failed for template " .. template)
        return
    end

    printLuaError("BSV QUIZ: granted reward " .. template .. " to player " .. SceneObject(pPlayer):getObjectID())
end

---------------------------------------------------------
-- SESSION HELPERS (RANDOM QUESTION SELECTION)
---------------------------------------------------------

local function bsvClearSession(pPlayer)
    deleteData(bsvIdxKey(pPlayer))
    for slot = 1, BSV_QUESTIONS_PER_RUN do
        deleteData(bsvSlotKey(pPlayer, slot))
    end
end

local function bsvAssignRandomQuestions(pPlayer)
    if BSV_TOTAL_QUESTIONS < BSV_QUESTIONS_PER_RUN then
        printLuaError("BSV QUIZ: not enough questions defined. Need " ..
            BSV_QUESTIONS_PER_RUN .. ", have " .. BSV_TOTAL_QUESTIONS .. ".")
        return
    end

    local used = {}

    for slot = 1, BSV_QUESTIONS_PER_RUN do
        local qnum
        repeat
            qnum = getRandomNumber(1, BSV_TOTAL_QUESTIONS)
        until not used[qnum]

        used[qnum] = true
        writeData(bsvSlotKey(pPlayer, slot), qnum)
    end

    -- start at 0 so first q_correct bumps to 1
    writeData(bsvIdxKey(pPlayer), 0)
end

local function bsvGetQuestionNumberForSlot(pPlayer, slot)
    return readData(bsvSlotKey(pPlayer, slot))
end

local function bsvQuestionIdForNumber(qnum)
    -- q001, q002, ..., q050
    if qnum < 10 then
        return "q00" .. tostring(qnum)
    elseif qnum < 100 then
        return "q0" .. tostring(qnum)
    else
        return "q" .. tostring(qnum)
    end
end

---------------------------------------------------------
-- INITIAL SCREEN
---------------------------------------------------------

function bsv_quiz_convo_handler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
    if pPlayer == nil or pConvTemplate == nil then
        return nil
    end

    local convo = LuaConversationTemplate(pConvTemplate)

    -- Cooldown?
    local remaining = bsvGetCooldownRemaining(pPlayer)
    if remaining > 0 then
        CreatureObject(pPlayer):sendSystemMessage(
            "You have already completed a quiz recently. You may attempt another in " ..
            bsvFormatTime(remaining) .. "."
        )
        local cd = convo:getScreen("on_cooldown")
        if cd ~= nil then
            return cd
        end
        -- fallback
        return convo:getScreen("intro")
    end

    -- New session: randomize 5 questions
    bsvClearSession(pPlayer)
    bsvAssignRandomQuestions(pPlayer)

    -- Intro screen where player chooses "Begin the quiz."
    local intro = convo:getScreen("intro")
    if intro == nil then
        printLuaError("BSV QUIZ: missing 'intro' screen, falling back to q001.")
        local firstId = bsvQuestionIdForNumber(1)
        return convo:getScreen(firstId)
    end

    return intro
end

---------------------------------------------------------
-- SCREEN HANDLERS
---------------------------------------------------------

function bsv_quiz_convo_handler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
    if pPlayer == nil or pConvScreen == nil then
        return pConvScreen
    end

    local convo    = LuaConversationTemplate(pConvTemplate)
    local screen   = LuaConversationScreen(pConvScreen)
    local screenId = screen:getScreenID()

    -------------------------------------------------
    -- Failure screen: nothing special, just clear
    -------------------------------------------------
    if screenId == "quiz_failed" then
        bsvClearSession(pPlayer)
        return pConvScreen
    end

    -------------------------------------------------
    -- Success screen: cooldown + reward handled here
    -------------------------------------------------
    if screenId == "quiz_success" then
        local remaining = bsvGetCooldownRemaining(pPlayer)
        if remaining == 0 then
            bsvStartCooldown(pPlayer)
            bsvGiveReward(pPlayer)
            CreatureObject(pPlayer):sendSystemMessage(
                "You answered all questions correctly and receive a reward."
            )
        else
            CreatureObject(pPlayer):sendSystemMessage(
                "You have already received a reward for a quiz recently. You may earn another in " ..
                bsvFormatTime(remaining) .. "."
            )
        end
        bsvClearSession(pPlayer)
        return pConvScreen
    end

    -------------------------------------------------
    -- q_failed: generic wrong answer route
    -------------------------------------------------
    if screenId == "q_failed" then
        bsvClearSession(pPlayer)
        CreatureObject(pPlayer):sendSystemMessage("Incorrect answer. Please try again.")
        -- send them to quiz_failed convo screen
        local fail = convo:getScreen("quiz_failed")
        if fail ~= nil then
            return fail
        end
        return pConvScreen
    end

    -------------------------------------------------
    -- q_correct: advance to next randomized question
    -------------------------------------------------
    if screenId == "q_correct" then
        -- current index (0..5)
        local idx = readData(bsvIdxKey(pPlayer))
        if idx == nil then
            idx = 0
        end

        idx = idx + 1

        if idx > BSV_QUESTIONS_PER_RUN then
            -- All questions answered correctly -> success
            local succ = convo:getScreen("quiz_success")
            if succ ~= nil then
                return succ
            end
            return pConvScreen
        end

        writeData(bsvIdxKey(pPlayer), idx)

        local qnum = bsvGetQuestionNumberForSlot(pPlayer, idx)
        if qnum == nil or qnum == 0 then
            printLuaError("BSV QUIZ: missing question number for slot " .. tostring(idx))
            local fail = convo:getScreen("quiz_failed")
            if fail ~= nil then
                return fail
            end
            return pConvScreen
        end

        local qid = bsvQuestionIdForNumber(qnum)
        local nextScreen = convo:getScreen(qid)
        if nextScreen == nil then
            printLuaError("BSV QUIZ: missing ConvoScreen '" .. qid .. "'; check bsv_quiz_convo.lua.")
            local fail = convo:getScreen("quiz_failed")
            if fail ~= nil then
                return fail
            end
            return pConvScreen
        end

        return nextScreen
    end

    -------------------------------------------------
    -- All other screens (intro, question screens) – no special logic
    -------------------------------------------------
    return pConvScreen
end
