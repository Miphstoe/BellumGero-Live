ThePathConvoHandler = conv_handler:new {}

local COST = 250000
local COOLDOWN_NAME = "the_path_identity"
local COOLDOWN_MS = 20 * 60 * 60 * 1000

local function isJediPlayer(pPlayer)
	if pPlayer == nil then return false end
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if pGhost == nil then return false end
	return PlayerObject(pGhost):isJedi()
end

local function hasEnoughCredits(pPlayer, amount)
	local cash = CreatureObject(pPlayer):getCashCredits()
	local bank = CreatureObject(pPlayer):getBankCredits()
	return (cash + bank) >= amount
end

local function takeCredits(pPlayer, amount)
	-- Prefer bank first, then cash remainder
	local bank = CreatureObject(pPlayer):getBankCredits()
	if bank >= amount then
		CreatureObject(pPlayer):subtractBankCredits(amount)
		return
	end

	if bank > 0 then
		CreatureObject(pPlayer):subtractBankCredits(bank)
		amount = amount - bank
	end

	CreatureObject(pPlayer):subtractCashCredits(amount)
end

function ThePathConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	local conv = LuaConversationTemplate(pConvTemplate)

	if not isJediPlayer(pPlayer) then
		return conv:getScreen("not_jedi")
	end

	-- We *allow* them to open convo; we only enforce cooldown at purchase time
	return conv:getScreen("start")
end

function ThePathConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	local screen = LuaConversationScreen(pConvScreen)
	local screenId = screen:getScreenID()

	if screenId ~= "do_identity" then
		return pConvScreen
	end

	local conv = LuaConversationTemplate(pConvTemplate)

	if not isJediPlayer(pPlayer) then
		return conv:getScreen("not_jedi")
	end

	if not CreatureObject(pPlayer):checkCooldownRecovery(COOLDOWN_NAME) then
		return conv:getScreen("cooldown")
	end

	if not hasEnoughCredits(pPlayer, COST) then
		return conv:getScreen("no_money")
	end

	-- Charge + cooldown
	takeCredits(pPlayer, COST)
	CreatureObject(pPlayer):addCooldown(COOLDOWN_NAME, COOLDOWN_MS)

    -- break any already-pulled BH missions
    CreatureObject(pPlayer):invalidatePlayerBountyMissions()

	-- This is the key call (requires the C++ Lua binding we added)
	CreatureObject(pPlayer):clearVisibility()

	return conv:getScreen("success")
end
