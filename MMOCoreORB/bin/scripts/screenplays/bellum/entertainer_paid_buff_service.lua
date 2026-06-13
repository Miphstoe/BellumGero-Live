-- Entertainer Paid Buff Service (EPBS)
-- Allows performing player entertainers to charge credits for mind buffs.
--
-- Data storage uses PlayerObject screenPlayData (persists per player):
--   Entertainer's ghost: epbs_enabled, epbs_playerPrice, epbs_petPrice, epbs_earnings
--   Patron's ghost:      epbs_auth_<entertainerID>     (expiry timestamp, player buff)
--                        epbs_petAuth_<entertainerID>  (expiry timestamp, pet buff)
--   Pending SUI:         epbs_pending_entertainerID, epbs_pending_price, epbs_pending_isPet
--
-- The C++ hook in EntertainingSessionImplementation::activateEntertainerBuff reads
-- and consumes the auth keys before applying the buff.

require("sui.SuiListBox")
require("sui.SuiInputBox")
require("sui.SuiMessageBox")

EntertainerPaidBuffService = {
    NAMESPACE           = "epbs",
    AUTH_WINDOW_SECONDS = 420,    -- 7 minutes
    MIN_PRICE           = 100,
    MAX_PRICE           = 1000000,
    DEFAULT_PLAYER_PRICE = 5000,
    DEFAULT_PET_PRICE    = 7500,
}

-- ============================================================
-- screenPlayData helpers
-- ============================================================
function EntertainerPaidBuffService:getNum(pObj, key)
    local v = readScreenPlayData(pObj, self.NAMESPACE, key)
    return tonumber(v) or 0
end

function EntertainerPaidBuffService:setNum(pObj, key, val)
    writeScreenPlayData(pObj, self.NAMESPACE, key, tostring(val or 0))
end

function EntertainerPaidBuffService:getString(pObj, key)
    return readScreenPlayData(pObj, self.NAMESPACE, key) or ""
end

function EntertainerPaidBuffService:setString(pObj, key, val)
    writeScreenPlayData(pObj, self.NAMESPACE, key, tostring(val or ""))
end

function EntertainerPaidBuffService:clearKey(pObj, key)
    writeScreenPlayData(pObj, self.NAMESPACE, key, "")
end

-- ============================================================
-- Entertainer state helpers
-- ============================================================
function EntertainerPaidBuffService:isEnabled(pEntertainer)
    return self:getString(pEntertainer, "enabled") == "1"
end

function EntertainerPaidBuffService:getPlayerPrice(pEntertainer)
    local p = self:getNum(pEntertainer, "playerPrice")
    return (p >= self.MIN_PRICE) and p or self.DEFAULT_PLAYER_PRICE
end

function EntertainerPaidBuffService:getPetPrice(pEntertainer)
    local p = self:getNum(pEntertainer, "petPrice")
    return (p >= self.MIN_PRICE) and p or self.DEFAULT_PET_PRICE
end

function EntertainerPaidBuffService:addEarnings(pEntertainer, amount)
    local current = self:getNum(pEntertainer, "earnings")
    self:setNum(pEntertainer, "earnings", current + amount)
end

-- ============================================================
-- Patron auth helpers
-- ============================================================
function EntertainerPaidBuffService:authKey(entertainerID)
    return "auth_" .. tostring(entertainerID)
end

function EntertainerPaidBuffService:petAuthKey(entertainerID)
    return "petAuth_" .. tostring(entertainerID)
end

function EntertainerPaidBuffService:setAuth(pPatron, entertainerID, isPet)
    local key = isPet and self:petAuthKey(entertainerID) or self:authKey(entertainerID)
    local expiry = os.time() + self.AUTH_WINDOW_SECONDS
    self:setNum(pPatron, key, expiry)
end

function EntertainerPaidBuffService:hasValidAuth(pPatron, entertainerID, isPet)
    local key = isPet and self:petAuthKey(entertainerID) or self:authKey(entertainerID)
    local expiry = self:getNum(pPatron, key)
    if expiry <= 0 then return false end
    return os.time() < expiry
end

-- ============================================================
-- Credit deduction: bank first, then cash
-- ============================================================
function EntertainerPaidBuffService:deductCredits(pPlayer, amount)
    local creo = CreatureObject(pPlayer)
    local bank = creo:getBankCredits()
    local cash = creo:getCashCredits()
    if (bank + cash) < amount then
        return false
    end
    if bank >= amount then
        creo:subtractBankCredits(amount)
    else
        if bank > 0 then creo:subtractBankCredits(bank) end
        creo:subtractCashCredits(amount - bank)
    end
    return true
end

-- ============================================================
-- Validate active pet on patron (used before charging for pet buff)
-- ============================================================
function EntertainerPaidBuffService:patronHasEligiblePet(pPatron)
    local pGhost = CreatureObject(pPatron):getPlayerObject()
    if pGhost == nil then return false end
    local numPets = PlayerObject(pGhost):getActivePetsSize()
    if numPets <= 0 then return false end
    local pPet = PlayerObject(pGhost):getActivePet(0)
    if pPet == nil then return false end
    if CreatureObject(pPet):isDead() or CreatureObject(pPet):isIncapacitated() then return false end
    return true
end

-- ============================================================
-- Payment entry point (called by /epbspay and /epbspetpay)
-- entertainerID is passed directly from the C++ command (the player's current target).
-- ============================================================
function EntertainerPaidBuffService:processPay(pPatron, entertainerID, isPet)
    if pPatron == nil then return end

    if entertainerID == nil or entertainerID == 0 then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] Target the performing entertainer first, then use /epbspay.")
        return
    end

    local pEntertainer = getSceneObject(entertainerID)
    if pEntertainer == nil then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] Entertainer not found.")
        return
    end

    local entCreo = CreatureObject(pEntertainer)

    if not entCreo:isDancing() and not entCreo:isPlayingMusic() then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] That entertainer is not currently performing.")
        return
    end

    if not self:isEnabled(pEntertainer) then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] That entertainer has not enabled their paid buff service.")
        return
    end

    if not SceneObject(pEntertainer):isInRangeWithObject(pPatron, 60) then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] You are too far from the entertainer (max 60m).")
        return
    end

    if isPet and not self:patronHasEligiblePet(pPatron) then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] You do not have an active, eligible controlled creature.")
        return
    end

    -- Prevent double-charging for the same window
    if self:hasValidAuth(pPatron, entertainerID, isPet) then
        local label = isPet and "pet buff" or "mind buff"
        CreatureObject(pPatron):sendSystemMessage("[EPBS] You have already paid for a " .. label .. ". Watch the performance for at least 1 minute to receive it.")
        return
    end

    local price = isPet and self:getPetPrice(pEntertainer) or self:getPlayerPrice(pEntertainer)
    local label = isPet and "Pet Mind Buff" or "Mind Buff"
    local entName = entCreo:getFirstName()

    -- Store pending payment context for the SUI callback
    self:setNum(pPatron, "pending_entertainerID", entertainerID)
    self:setNum(pPatron, "pending_price", price)
    self:setString(pPatron, "pending_isPet", isPet and "1" or "0")

    local sui = SuiMessageBox.new("EntertainerPaidBuffService", "payConfirmCallback")
    sui.setTargetNetworkId(SceneObject(pPatron):getObjectID())
    sui.setTitle("Entertainer Paid Buff Service")
    sui.setPrompt(
        "Pay " .. tostring(price) .. " credits to " .. entName .. " for a " .. label .. "?\n\n" ..
        "After payment, continue watching or listening for at least 1 minute to receive your buff.\n" ..
        "Authorization expires in " .. tostring(math.floor(self.AUTH_WINDOW_SECONDS / 60)) .. " minutes."
    )
    sui.setOkButtonText("Pay")
    sui.sendTo(pPatron)
end

-- ============================================================
-- SUI callback for payment confirmation (OK=0, Cancel=1)
-- ============================================================
function EntertainerPaidBuffService:payConfirmCallback(pPatron, pSui, eventIndex, args)
    if pPatron == nil then return end

    local entertainerID = self:getNum(pPatron, "pending_entertainerID")
    local price         = self:getNum(pPatron, "pending_price")
    local isPet         = self:getString(pPatron, "pending_isPet") == "1"

    -- Clear pending regardless of outcome
    self:clearKey(pPatron, "pending_entertainerID")
    self:clearKey(pPatron, "pending_price")
    self:clearKey(pPatron, "pending_isPet")

    if eventIndex ~= 0 then return end  -- Cancel/close
    if entertainerID == 0 or price == 0 then return end

    self:completePay(pPatron, entertainerID, price, isPet)
end

-- ============================================================
-- Complete payment after SUI confirmation (re-validates state)
-- ============================================================
function EntertainerPaidBuffService:completePay(pPatron, entertainerID, price, isPet)
    if pPatron == nil then return end

    local pEntertainer = getSceneObject(entertainerID)
    if pEntertainer == nil then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] Entertainer is no longer available. Payment canceled.")
        return
    end

    local entCreo = CreatureObject(pEntertainer)

    if not entCreo:isDancing() and not entCreo:isPlayingMusic() then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] The entertainer stopped performing. Payment canceled.")
        return
    end

    if not self:isEnabled(pEntertainer) then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] The entertainer disabled their service. Payment canceled.")
        return
    end

    if not SceneObject(pEntertainer):isInRangeWithObject(pPatron, 60) then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] You moved too far from the entertainer. Payment canceled.")
        return
    end

    if isPet and not self:patronHasEligiblePet(pPatron) then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] Your pet is no longer eligible. Payment canceled.")
        return
    end

    -- Prevent double-charging (in case SUI was slow)
    if self:hasValidAuth(pPatron, entertainerID, isPet) then
        local label = isPet and "pet buff" or "mind buff"
        CreatureObject(pPatron):sendSystemMessage("[EPBS] Already authorized for a " .. label .. ". No charge.")
        return
    end

    if not self:deductCredits(pPatron, price) then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] Insufficient credits.")
        return
    end

    -- Pay the entertainer in cash
    CreatureObject(pEntertainer):addCashCredits(price, true)
    self:addEarnings(pEntertainer, price)

    -- Authorize the patron for the buff
    self:setAuth(pPatron, entertainerID, isPet)

    local label   = isPet and "pet mind buff" or "mind buff"
    local entName = entCreo:getFirstName()
    local patronName = CreatureObject(pPatron):getFirstName()

    CreatureObject(pPatron):sendSystemMessage(
        "[EPBS] Paid " .. tostring(price) .. " credits to " .. entName ..
        " for a " .. label .. ". Watch the performance for at least 1 minute to receive your buff!"
    )
    CreatureObject(pEntertainer):sendSystemMessage(
        "[EPBS] " .. patronName .. " paid " .. tostring(price) .. " credits for a " .. label .. "."
    )
end

-- ============================================================
-- Entertainer setup menu (called by /epbssetup)
-- ============================================================
function EntertainerPaidBuffService:openSetupMenu(pEntertainer)
    if pEntertainer == nil then return end

    local entCreo = CreatureObject(pEntertainer)
    if not entCreo:isDancing() and not entCreo:isPlayingMusic() then
        entCreo:sendSystemMessage("[EPBS] You must be actively dancing or playing music to manage your buff service.")
        return
    end

    local enabled     = self:isEnabled(pEntertainer)
    local playerPrice = self:getPlayerPrice(pEntertainer)
    local petPrice    = self:getPetPrice(pEntertainer)
    local earnings    = self:getNum(pEntertainer, "earnings")

    local sui = SuiListBox.new("EntertainerPaidBuffService", "setupMenuCallback")
    sui.setTargetNetworkId(SceneObject(pEntertainer):getObjectID())
    sui.setTitle("Entertainer Paid Buff Service — Setup")
    sui.setPrompt(
        "Status: " .. (enabled and "ENABLED" or "DISABLED") ..
        "\nPlayer Buff Price: " .. tostring(playerPrice) .. " credits" ..
        "\nPet Buff Price: " .. tostring(petPrice) .. " credits" ..
        "\nTotal Earnings: " .. tostring(earnings) .. " credits"
    )

    sui.add(enabled and "Disable Service" or "Enable Service", "")
    sui.add("Set Player Buff Price (" .. tostring(playerPrice) .. ")", "")
    sui.add("Set Pet Buff Price (" .. tostring(petPrice) .. ")", "")
    sui.add("View Earnings Details", "")

    sui.sendTo(pEntertainer)
end

function EntertainerPaidBuffService:setupMenuCallback(pEntertainer, pSui, eventIndex, args)
    if pEntertainer == nil then return end
    if eventIndex == 1 or args == "-1" then return end

    local sel = tonumber(args)
    if sel == nil then return end

    if sel == 0 then
        -- Toggle enable/disable
        local enabled = self:isEnabled(pEntertainer)
        self:setString(pEntertainer, "enabled", enabled and "0" or "1")
        local msg = enabled and "[EPBS] Paid buff service DISABLED." or "[EPBS] Paid buff service ENABLED. Players can now pay for buffs with /epbspay."
        CreatureObject(pEntertainer):sendSystemMessage(msg)
        self:openSetupMenu(pEntertainer)

    elseif sel == 1 then
        self:openPriceInput(pEntertainer, false)

    elseif sel == 2 then
        self:openPriceInput(pEntertainer, true)

    elseif sel == 3 then
        local earnings = self:getNum(pEntertainer, "earnings")
        CreatureObject(pEntertainer):sendSystemMessage(
            "[EPBS] Total buff service earnings: " .. tostring(earnings) .. " credits."
        )
        self:openSetupMenu(pEntertainer)
    end
end

-- ============================================================
-- Price input box
-- ============================================================
function EntertainerPaidBuffService:openPriceInput(pEntertainer, isPet)
    if pEntertainer == nil then return end
    local label   = isPet and "Pet Buff" or "Player Buff"
    local current = isPet and self:getPetPrice(pEntertainer) or self:getPlayerPrice(pEntertainer)

    -- Store which price is being edited
    self:setString(pEntertainer, "price_edit_target", isPet and "pet" or "player")

    local sui = SuiInputBox.new("EntertainerPaidBuffService", "priceInputCallback")
    sui.setTargetNetworkId(SceneObject(pEntertainer):getObjectID())
    sui.setTitle("Set " .. label .. " Price")
    sui.setPrompt(
        "Enter the credit price for a " .. label .. ".\n" ..
        "Min: " .. tostring(self.MIN_PRICE) .. "   Max: " .. tostring(self.MAX_PRICE) ..
        "\nCurrent: " .. tostring(current) .. " credits"
    )
    sui.setOkButtonText("Set Price")
    sui.sendTo(pEntertainer)
end

function EntertainerPaidBuffService:priceInputCallback(pEntertainer, pSui, eventIndex, args)
    if pEntertainer == nil then return end

    local isPet = self:getString(pEntertainer, "price_edit_target") == "pet"
    self:clearKey(pEntertainer, "price_edit_target")

    if eventIndex ~= 0 then
        self:openSetupMenu(pEntertainer)
        return
    end

    local price = tonumber(args)
    if price == nil then
        CreatureObject(pEntertainer):sendSystemMessage("[EPBS] Invalid input — please enter a number.")
        self:openSetupMenu(pEntertainer)
        return
    end

    price = math.max(self.MIN_PRICE, math.min(self.MAX_PRICE, math.floor(price)))
    local key   = isPet and "petPrice" or "playerPrice"
    local label = isPet and "Pet Buff" or "Player Buff"
    self:setNum(pEntertainer, key, price)
    CreatureObject(pEntertainer):sendSystemMessage("[EPBS] " .. label .. " price set to " .. tostring(price) .. " credits.")
    self:openSetupMenu(pEntertainer)
end

-- ============================================================
-- Global entry points called by C++ commands
-- entertainerID is the C++ target OID (0 if player has no target).
-- ============================================================
function epbsPayRun(pPlayer, entertainerID)
    EntertainerPaidBuffService:processPay(pPlayer, entertainerID, false)
end

function epbsPetPayRun(pPlayer, entertainerID)
    EntertainerPaidBuffService:processPay(pPlayer, entertainerID, true)
end

function epbsSetupRun(pEntertainer)
    EntertainerPaidBuffService:openSetupMenu(pEntertainer)
end
