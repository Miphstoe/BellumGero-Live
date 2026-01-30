-- bsv_quiz_convo_handler.lua
-- Blue Shadow Virus quiz conversation handler

bsv_quiz_convo_handler = conv_handler:new {}

---------------------------------------
-- CONFIG
---------------------------------------

-- Total number of question screens defined (q001 .. qNN)
local BSV_TOTAL_QUESTIONS   = 50      -- adjust if you add/remove questions
local BSV_QUESTIONS_PER_RUN = 5       -- number of questions per quiz run

-- Cooldown in seconds (20 hours)
local BSV_COOLDOWN_SECS     = 72000

-- Cooldown and session key prefixes
local BSV_CD_PREFIX         = "bsvQuizDaily:"
local BSV_CD_TAG_RESET      = "reset"

local BSV_SESSION_PREFIX    = "bsvQuizSession:"
local BSV_INDEX_SUFFIX      = ":idx"    -- current question index (0..5)
local BSV_SLOT_SUFFIX       = ":slot:"  -- slot->questionNumber

-- Reward pool (weighted)
local BSV_REWARD_ITEMS = {
    { template = "object/tangible/furniture/all/frn_all_medic_bacta_tank.iff",           weight = 5 },
    { template = "object/tangible/furniture/all/frn_all_medic_bacta_tank_large.iff",     weight = 5 },
    { template = "object/tangible/furniture/all/frn_all_medic_bacta_tank_advanced.iff",  weight = 5 },
    { template = "object/tangible/furniture/all/frn_all_organichem_stores.iff",          weight = 5 },
    { template = "object/tangible/furniture/all/frn_all_medical_console.iff",            weight = 5 },
    { template = "object/tangible/furniture/jedi/frn_all_dark_chair_s01.iff",            weight = 5 },
    { template = "object/tangible/furniture/jedi/frn_all_light_chair_s01.iff",           weight = 5 },
    { template = "object/tangible/furniture/all/frn_all_scrolling_screen.iff",           weight = 5 },
    { template = "object/tangible/loot/loot_schematic/armoire_plain_schematic.iff",      weight = 3 },
    { template = "object/tangible/loot/loot_schematic/armoire_technical_schematic.iff",  weight = 3 },
    { template = "object/tangible/loot/loot_schematic/cabinet_plain_schematic.iff",      weight = 3 },
    { template = "object/tangible/loot/loot_schematic/cabinet_technical_schematic.iff",  weight = 3 },
    { template = "object/tangible/loot/loot_schematic/chest_plain_schematic.iff",        weight = 3 },
    { template = "object/tangible/loot/loot_schematic/chest_technical_schematic.iff",    weight = 3 },
    { template = "object/tangible/furniture/all/frn_all_droideka.iff",                   weight = 2 },
    { template = "object/tangible/furniture/all/frn_all_super_battle_droid.iff",         weight = 2 },
    { template = "object/tangible/furniture/all/frn_all_battle_droid.iff",               weight = 2 },
    { template = "object/tangible/furniture/all/frn_all_21b_surgical_droid.iff",         weight = 2 },
    { template = "object/tangible/furniture/all/frn_all_ito_droid.iff",                  weight = 2 },
    --{ template = "object/tangible/veteran_reward/frn_vet_holo_corvette.iff",             weight = 2 },
    --{ template = "object/tangible/veteran_reward/frn_vet_holo_darth_vader.iff",          weight = 2 },
    --{ template = "object/tangible/veteran_reward/frn_vet_holo_deathstar.iff",            weight = 2 },
    { template = "object/tangible/veteran_reward/frn_vet_holo_imperial_guard.iff",       weight = 2 },
    --{ template = "object/tangible/veteran_reward/frn_vet_holo_jawa.iff",                 weight = 2 },
    --{ template = "object/tangible/veteran_reward/frn_vet_holo_lambda.iff",               weight = 2 },
    { template = "object/tangible/veteran_reward/frn_vet_holo_leia.iff",                 weight = 2 },
    { template = "object/tangible/veteran_reward/frn_vet_holo_luke_skywalker.iff",       weight = 2 },
    --{ template = "object/tangible/veteran_reward/frn_vet_holo_sandcrawler.iff",          weight = 2 },
    --{ template = "object/tangible/veteran_reward/frn_vet_holo_starfighter.iff",          weight = 2 },
    { template = "object/tangible/veteran_reward/frn_vet_holo_yoda.iff",                 weight = 2 },
    -- add more if you like
}

---------------------------------------
-- INTERNAL HELPERS
---------------------------------------

local function bsvNow()
    return getTimestamp() -- SWGEmu global for current time
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

local function bsvClearSession(pPlayer)
    if pPlayer == nil then
        return
    end

    -- clear index
    deleteData(bsvIdxKey(pPlayer))

    -- clear slot assignments
    for slot = 1, BSV_QUESTIONS_PER_RUN do
        deleteData(bsvSlotKey(pPlayer, slot))
    end
end

local function bsvClearExpiredCooldown(pPlayer)
    local key = bsvCdKey(pPlayer)
    local reset = readData(key)
    if reset ~= nil and reset ~= 0 and reset <= bsvNow() then
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
    if pPlayer == nil then
        return
    end

    local resetTime = bsvNow() + BSV_COOLDOWN_SECS
    writeData(bsvCdKey(pPlayer), resetTime)
end

local function bsvFormatTime(seconds)
    local s = tonumber(seconds) or 0
    if s < 0 then s = 0 end

    local hours   = math.floor(s / 3600)
    local minutes = math.floor((s % 3600) / 60)

    if hours > 0 and minutes > 0 then
        return hours .. "h " .. minutes .. "m"
    elseif hours > 0 then
        return hours .. "h"
    elseif minutes > 0 then
        return minutes .. "m"
    else
        return s .. "s"
    end
end

local function bsvAssignRandomQuestions(pPlayer)
    if pPlayer == nil then
        return
    end

    if BSV_TOTAL_QUESTIONS < BSV_QUESTIONS_PER_RUN then
        printLuaError("BSV QUIZ: not enough questions defined (have " ..
            BSV_TOTAL_QUESTIONS .. ", need at least " .. BSV_QUESTIONS_PER_RUN .. ").")
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

    -- start index at 0; first correct answer bumps to 1
    writeData(bsvIdxKey(pPlayer), 0)
end

local function bsvGetQuestionNumberForSlot(pPlayer, slot)
    return readData(bsvSlotKey(pPlayer, slot))
end

local function bsvQuestionIdForNumber(qnum)
    -- qnum = 1 -> "q001", 12 -> "q012", etc.
    if qnum == nil then
        return nil
    end
    if qnum < 10 then
        return "q00" .. tostring(qnum)
    elseif qnum < 100 then
        return "q0" .. tostring(qnum)
    else
        return "q" .. tostring(qnum)
    end
end

-- reward selection

local function bsvSelectWeightedReward()
    if BSV_REWARD_ITEMS == nil or #BSV_REWARD_ITEMS == 0 then
        return nil
    end

    local totalWeight = 0
    for _, entry in ipairs(BSV_REWARD_ITEMS) do
        totalWeight = totalWeight + (entry.weight or 1)
    end

    if totalWeight <= 0 then
        return nil
    end

    local roll = getRandomNumber(1, totalWeight)
    local accum = 0

    for _, entry in ipairs(BSV_REWARD_ITEMS) do
        accum = accum + (entry.weight or 1)
        if roll <= accum then
            return entry.template
        end
    end

    return BSV_REWARD_ITEMS[#BSV_REWARD_ITEMS].template
end

local function bsvGiveReward(pPlayer)
    if pPlayer == nil then
        return
    end

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

---------------------------------------
-- CONVERSATION HANDLER
---------------------------------------

function bsv_quiz_convo_handler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
    local convo = LuaConversationTemplate(pConvTemplate)
    if convo == nil or pPlayer == nil then
        return nil
    end

    -- Check cooldown
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

        return convo:getScreen("intro")
    end

    -- New session
    bsvClearSession(pPlayer)
    bsvAssignRandomQuestions(pPlayer)

    return convo:getScreen("intro")
end

function bsv_quiz_convo_handler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
    local screen = LuaConversationScreen(pConvScreen)
    if screen == nil or pPlayer == nil then
        return pConvScreen
    end

    local screenId = screen:getScreenID()
    local convo    = LuaConversationTemplate(pConvTemplate)

    -- PLAYER CHOSE A CORRECT ANSWER (or is starting the quiz)
    if screenId == "q_correct" then
        local idx = readData(bsvIdxKey(pPlayer))
        if idx == nil then
            idx = 0
        end

        --------------------------------------------------
        -- FIRST TIME: idx == 0 → JUST START THE QUIZ
        -- We haven't answered any questions yet; this is
        -- the "Begin the assessment." click from intro.
        --------------------------------------------------
        if idx == 0 then
            idx = 1
            writeData(bsvIdxKey(pPlayer), idx)

            local qnum = bsvGetQuestionNumberForSlot(pPlayer, idx)
            local qid  = bsvQuestionIdForNumber(qnum)

            if convo ~= nil and qid ~= nil then
                local nextScreen = convo:getScreen(qid)
                if nextScreen ~= nil then
                    return nextScreen
                end
            end

            printLuaError("BSV QUIZ: could not resolve first question for idx 1")
            return pConvScreen
        end

        --------------------------------------------------
        -- SUBSEQUENT TIMES: we've just answered question
        -- 'idx' correctly, so move to the next one.
        --------------------------------------------------
        idx = idx + 1

        -- If we've just gone past the last question slot,
        -- that means we answered all QUESTIONS_PER_RUN correctly.
        if idx > BSV_QUESTIONS_PER_RUN then
            -- Lock in "completed this run"
            writeData(bsvIdxKey(pPlayer), BSV_QUESTIONS_PER_RUN)

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

            -- Show the nice success screen
            if convo ~= nil then
                local succ = convo:getScreen("quiz_success")
                if succ ~= nil then
                    return succ
                end
            end

            return pConvScreen
        end

        -- Not done yet: move on to the next question
        writeData(bsvIdxKey(pPlayer), idx)

        local qnum = bsvGetQuestionNumberForSlot(pPlayer, idx)
        local qid  = bsvQuestionIdForNumber(qnum)

        if convo ~= nil and qid ~= nil then
            local nextScreen = convo:getScreen(qid)
            if nextScreen ~= nil then
                return nextScreen
            end
        end

        printLuaError("BSV QUIZ: could not resolve next question for idx " .. tostring(idx))
        return pConvScreen
    end

    --------------------------------------------------
    -- WRONG ANSWER → IMMEDIATE FAILURE, NO COOLDOWN
    --------------------------------------------------
    if screenId == "q_failed" then
        bsvClearSession(pPlayer)
        CreatureObject(pPlayer):sendSystemMessage("Incorrect answer. Please try again.")

        if convo ~= nil then
            local fail = convo:getScreen("quiz_failed")
            if fail ~= nil then
                return fail
            end
        end

        return pConvScreen
    end

    --------------------------------------------------
    -- SUCCESS SCREEN (flavor only; logic handled above)
    --------------------------------------------------
    if screenId == "quiz_success" then
        -- No extra logic here; reward and cooldown handled in q_correct.
        return pConvScreen
    end

    return pConvScreen
end

