-- Entertainer Paid Buff Service (EPBS)
-- Allows performing player entertainers to charge credits for mind buffs.
--
-- Data storage uses PlayerObject screenPlayData (persists per player):
--   Entertainer's ghost: epbs_enabled, epbs_playerPrice, epbs_petPrice, epbs_earnings
--   Patron's ghost:      epbs_auth_<entertainerID>     (expiry timestamp, player buff)
--                        epbs_petAuth_<entertainerID>  (expiry timestamp, pet buff)
--   Pending SUI:         epbs_pending_entertainerID, epbs_pending_price, epbs_pending_isPet
--
-- V2 session keys (patron):
--   v2_sess_ent_id, v2_sess_type, v2_sess_start, v2_sess_mode
--   v2_sui_ent_id, v2_sui_type, v2_sui_amount, v2_sui_mode
--   v2_early_stop  (signals C++ gate to suppress its message)
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

    -- V2 constants
    V2_READY_SECS         = 60,
    V2_REMINDER_SECS      = 180,
    V2_STALE_SECS         = 600,    -- sessions older than 10 min are stale on re-watch
    V2_AUTH_WINDOW_SECONDS = 86400, -- auth key valid for 24 hrs; cleared by handleStop
    V2_PRESET_LOW         = 5000,
    V2_PRESET_HIGH        = 10000,

    -- V2 service type constants
    SVC_PLAYER = "PLAYER",
    SVC_PET    = "PET",
    SVC_BOTH   = "BOTH",
    SVC_FREE   = "FREE",  -- watch/listen without paying; still earns the buff
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

-- V2 variant: auth key lives for 24 hours so it survives long watch/listen sessions
function EntertainerPaidBuffService:setV2Auth(pPatron, entertainerID, isPet)
    local key = isPet and self:petAuthKey(entertainerID) or self:authKey(entertainerID)
    local expiry = os.time() + self.V2_AUTH_WINDOW_SECONDS
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
-- entertainerID is passed from the C++ command, preferring the active watch/listen target.
-- ============================================================
function EntertainerPaidBuffService:processPay(pPatron, entertainerID, isPet)
    if pPatron == nil then return end

    if entertainerID == nil or entertainerID == 0 then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] Target the performing entertainer first, then use /epbspay.")
        return
    end

    if entertainerID == SceneObject(pPatron):getObjectID() then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] You must watch or listen to another entertainer before using /epbspay.")
        print("[EPBS V1] ABORT self-target before payment menu: patron ID=" .. tostring(SceneObject(pPatron):getObjectID()))
        return
    end

    local pEntertainer = getSceneObject(entertainerID)
    if pEntertainer == nil or not SceneObject(pEntertainer):isPlayerCreature() then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] Target a performing entertainer first, then use /epbspay.")
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
    if pEntertainer == nil or not SceneObject(pEntertainer):isPlayerCreature() then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] Entertainer is no longer available. Payment canceled.")
        return
    end

    local entCreo = CreatureObject(pEntertainer)

    -- SAFETY GUARD: never let the patron pay themselves.
    if SceneObject(pEntertainer):getObjectID() == SceneObject(pPatron):getObjectID() then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] Internal error: could not identify the entertainer. Payment canceled.")
        print("[EPBS V1] ABORT self-pay: entertainerID=" .. tostring(entertainerID) ..
              " resolved to patron (ID=" .. tostring(SceneObject(pPatron):getObjectID()) .. ").")
        return
    end

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

    local enabled  = self:isEnabled(pEntertainer)
    local earnings = self:getNum(pEntertainer, "earnings")

    local sui = SuiListBox.new("EntertainerPaidBuffService", "setupMenuCallback")
    sui.setTargetNetworkId(SceneObject(pEntertainer):getObjectID())
    sui.setTitle("Entertainer Paid Buff Service — Setup")
    sui.setPrompt(
        "Status: " .. (enabled and "ENABLED" or "DISABLED") ..
        "\nTotal Earnings: " .. tostring(earnings) .. " credits"
    )

    sui.add(enabled and "Disable Service" or "Enable Service", "")

    sui.sendTo(pEntertainer)
end

function EntertainerPaidBuffService:setupMenuCallback(pEntertainer, pSui, eventIndex, args)
    if pEntertainer == nil then return end
    if eventIndex == 1 or args == "-1" then return end

    local sel = tonumber(args)
    if sel == nil then return end

    if sel == 0 then
        local enabled = self:isEnabled(pEntertainer)
        self:setString(pEntertainer, "enabled", enabled and "0" or "1")
        local msg = enabled and "[EPBS] Paid buff service DISABLED." or "[EPBS] Paid buff service ENABLED."
        CreatureObject(pEntertainer):sendSystemMessage(msg)
        self:openSetupMenu(pEntertainer)
    end
end


-- ============================================================
-- V2: Session state helpers
-- Session keys stored in epbs namespace on patron:
--   v2_sess_ent_id  - OID string of entertainer ("" = none)
--   v2_sess_type    - SVC_PLAYER / SVC_PET / SVC_BOTH / SVC_FREE
--   v2_sess_start   - Unix timestamp when session started
--   v2_sess_mode    - "watch" or "listen"
-- SUI flow keys:
--   v2_sui_ent_id  - OID string of entertainer
--   v2_sui_type    - SVC_PLAYER / SVC_PET / SVC_BOTH (chosen buff)
--   v2_sui_amount  - confirmed custom tip amount (custom flow only)
--   v2_sui_mode    - "watch" or "listen"
-- Early stop signal for C++ gate:
--   v2_early_stop   - "1" = Lua sent the message; C++ should return silently
-- ============================================================

function EntertainerPaidBuffService:clearV2Session(pPatron)
    self:clearKey(pPatron, "v2_sess_ent_id")
    self:clearKey(pPatron, "v2_sess_type")
    self:clearKey(pPatron, "v2_sess_start")
    self:clearKey(pPatron, "v2_sess_mode")
end

function EntertainerPaidBuffService:clearV2SuiState(pPatron)
    self:clearKey(pPatron, "v2_sui_ent_id")
    self:clearKey(pPatron, "v2_sui_type")
    self:clearKey(pPatron, "v2_sui_amount")
    self:clearKey(pPatron, "v2_sui_mode")
end

function EntertainerPaidBuffService:hasV2Session(pPatron)
    return self:getString(pPatron, "v2_sess_ent_id") ~= ""
end

function EntertainerPaidBuffService:getV2SessEntID(pPatron)
    return tonumber(self:getString(pPatron, "v2_sess_ent_id")) or 0
end

function EntertainerPaidBuffService:isV2SessStale(pPatron)
    local start = self:getNum(pPatron, "v2_sess_start")
    if start <= 0 then return true end
    return (os.time() - start) > self.V2_STALE_SECS
end

-- ============================================================
-- V2: Entry point called when /watch or /listen starts
-- ============================================================
function EntertainerPaidBuffService:onWatchOrListenStart(pPatron, entID, mode)
    if pPatron == nil or entID == nil or entID == 0 then return end

    if entID == SceneObject(pPatron):getObjectID() then
        print("[EPBS V2] Ignoring self " .. tostring(mode) ..
              " start for patron ID=" .. tostring(SceneObject(pPatron):getObjectID()))
        return
    end

    -- Clear stale session for a different entertainer or one that timed out
    local sessID = self:getV2SessEntID(pPatron)
    if sessID ~= 0 and (sessID ~= entID or self:isV2SessStale(pPatron)) then
        self:clearV2Session(pPatron)
        self:clearV2SuiState(pPatron)
        sessID = 0
    end

    -- Already have active session with this entertainer — no new menu
    if sessID == entID then return end

    -- SUI flow already in progress for this entertainer — no new menu
    local suiID = tonumber(self:getString(pPatron, "v2_sui_ent_id")) or 0
    if suiID == entID then return end

    -- Clear stale SUI state for a different entertainer
    if suiID ~= 0 then
        self:clearV2SuiState(pPatron)
    end

    -- Validate entertainer
    local pEntertainer = getSceneObject(entID)
    if pEntertainer == nil or not SceneObject(pEntertainer):isPlayerCreature() then return end
    if not self:isEnabled(pEntertainer) then return end

    local entCreo = CreatureObject(pEntertainer)
    if not entCreo:isDancing() and not entCreo:isPlayingMusic() then return end

    self:setString(pPatron, "v2_sui_mode", mode)
    self:openV2ServiceMenu(pPatron, pEntertainer)
end

-- ============================================================
-- V2 display helpers
-- ============================================================
function EntertainerPaidBuffService:formatCredits(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    while true do
        local k
        s, k = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return s
end

function EntertainerPaidBuffService:v2BuffLabel(svcType)
    if svcType == self.SVC_PET then
        return "Pet Buff"
    elseif svcType == self.SVC_BOTH then
        return "Player and Pet Buff"
    end
    return "Player Buff"
end

-- ============================================================
-- V2 Step 1: Buff selection menu
--   0 Player Buff   1 Pet Buff   2 Player and Pet Buff   3 Cancel
-- ============================================================
function EntertainerPaidBuffService:openV2ServiceMenu(pPatron, pEntertainer)
    local entID   = SceneObject(pEntertainer):getObjectID()
    local entName = CreatureObject(pEntertainer):getFirstName()
    self:setString(pPatron, "v2_sui_ent_id", tostring(entID))

    local sui = SuiListBox.new("EntertainerPaidBuffService", "v2ServiceCallback")
    sui.setTargetNetworkId(SceneObject(pPatron):getObjectID())
    sui.setTitle("Entertainer Services Available")
    sui.setPrompt(
        entName .. " offers mind buff services.\n\n" ..
        "Which buff would you like?\n\n" ..
        "Buffs apply after 60 seconds of continuous watching or listening."
    )
    sui.add("Player Buff", "")
    sui.add("Pet Buff", "")
    sui.add("Player and Pet Buff", "")
    sui.add("Cancel", "")
    sui.sendTo(pPatron)
end

function EntertainerPaidBuffService:v2ServiceCallback(pPatron, pSui, eventIndex, args)
    if pPatron == nil then return end

    local entID        = tonumber(self:getString(pPatron, "v2_sui_ent_id")) or 0
    local pEntertainer = entID > 0 and getSceneObject(entID) or nil

    -- Escape / window closed
    if eventIndex == 1 or not pEntertainer then
        self:clearV2SuiState(pPatron)
        return
    end

    local sel = tonumber(args)
    if sel == nil or sel == 3 then    -- Cancel: close, do nothing
        self:clearV2SuiState(pPatron)
        return
    end

    local svcType
    if sel == 0 then
        svcType = self.SVC_PLAYER
    elseif sel == 1 or sel == 2 then
        if not self:patronHasEligiblePet(pPatron) then
            CreatureObject(pPatron):sendSystemMessage("[EPBS] You do not have an active, eligible pet.")
            self:openV2ServiceMenu(pPatron, pEntertainer)
            return
        end
        svcType = (sel == 1) and self.SVC_PET or self.SVC_BOTH
    else
        self:clearV2SuiState(pPatron)
        return
    end

    self:setString(pPatron, "v2_sui_type", svcType)
    self:openV2TipMenu(pPatron, pEntertainer)
end

-- ============================================================
-- V2 Step 2: Tip selection menu
--   0 preset low (pay now)   1 preset high (pay now)
--   2 custom amount (input -> confirm)   3 continue without paying
-- ============================================================
function EntertainerPaidBuffService:openV2TipMenu(pPatron, pEntertainer)
    local entName   = CreatureObject(pEntertainer):getFirstName()
    local svcType   = self:getString(pPatron, "v2_sui_type")
    local buffLabel = self:v2BuffLabel(svcType)

    local sui = SuiListBox.new("EntertainerPaidBuffService", "v2TipCallback")
    sui.setTargetNetworkId(SceneObject(pPatron):getObjectID())
    sui.setTitle(buffLabel .. " - Tip " .. entName)
    sui.setPrompt(
        "Would you like to tip " .. entName .. " for your " .. buffLabel .. "?\n\n" ..
        "Tipping is voluntary. You will receive your buff either way after 60 seconds " ..
        "of watching or listening."
    )
    sui.add(self:formatCredits(self.V2_PRESET_LOW) .. " Credits", "")
    sui.add(self:formatCredits(self.V2_PRESET_HIGH) .. " Credits", "")
    sui.add("Custom Amount", "")
    sui.add("Continue without paying", "")
    sui.sendTo(pPatron)
end

function EntertainerPaidBuffService:v2TipCallback(pPatron, pSui, eventIndex, args)
    if pPatron == nil then return end

    local entID        = tonumber(self:getString(pPatron, "v2_sui_ent_id")) or 0
    local pEntertainer = entID > 0 and getSceneObject(entID) or nil
    local svcType      = self:getString(pPatron, "v2_sui_type")
    local mode         = self:getString(pPatron, "v2_sui_mode")
    if mode == "" then mode = "watch" end

    -- Escape / window closed = safely cancel without charging
    if eventIndex == 1 or not pEntertainer then
        self:clearV2SuiState(pPatron)
        return
    end

    local sel = tonumber(args)
    if sel == nil then
        self:clearV2SuiState(pPatron)
        return
    end

    if sel == 0 or sel == 1 then          -- preset amount: pay immediately
        local amount = (sel == 0) and self.V2_PRESET_LOW or self.V2_PRESET_HIGH
        self:clearV2SuiState(pPatron)
        self:v2ProcessPayment(pPatron, entID, svcType, amount, mode)
    elseif sel == 2 then                  -- custom amount: ask for input
        self:openV2CustomAmountInput(pPatron, pEntertainer)
    elseif sel == 3 then                  -- continue without paying
        self:clearV2SuiState(pPatron)
        self:v2StartFreeSession(pPatron, pEntertainer, svcType, mode)
    else
        self:clearV2SuiState(pPatron)
    end
end

-- ============================================================
-- V2 Step 2b: Custom amount input
-- ============================================================
function EntertainerPaidBuffService:openV2CustomAmountInput(pPatron, pEntertainer)
    local entName = CreatureObject(pEntertainer):getFirstName()

    local sui = SuiInputBox.new("EntertainerPaidBuffService", "v2CustomAmountCallback")
    sui.setTargetNetworkId(SceneObject(pPatron):getObjectID())
    sui.setTitle("Custom Tip Amount")
    sui.setPrompt(
        "Enter the amount you would like to tip " .. entName .. ".\n" ..
        "Minimum " .. self:formatCredits(self.MIN_PRICE) .. ", maximum " ..
        self:formatCredits(self.MAX_PRICE) .. " credits."
    )
    sui.setOkButtonText("Continue")
    sui.sendTo(pPatron)
end

function EntertainerPaidBuffService:v2CustomAmountCallback(pPatron, pSui, eventIndex, args)
    if pPatron == nil then return end

    local entID        = tonumber(self:getString(pPatron, "v2_sui_ent_id")) or 0
    local pEntertainer = entID > 0 and getSceneObject(entID) or nil

    -- Cancel / closed input -> back to the tip menu, no charge
    if eventIndex ~= 0 then
        if pEntertainer then
            self:openV2TipMenu(pPatron, pEntertainer)
        else
            self:clearV2SuiState(pPatron)
        end
        return
    end

    if not pEntertainer then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] Entertainer is no longer available.")
        self:clearV2SuiState(pPatron)
        return
    end

    -- Reject blank, non-numeric, zero, or negative amounts
    local amount = tonumber(args)
    if amount == nil or amount < self.MIN_PRICE then
        CreatureObject(pPatron):sendSystemMessage(
            "[EPBS] Please enter a valid amount of at least " ..
            self:formatCredits(self.MIN_PRICE) .. " credits.")
        self:openV2CustomAmountInput(pPatron, pEntertainer)
        return
    end

    amount = math.min(self.MAX_PRICE, math.floor(amount))

    -- Make sure the player can actually afford the tip before confirming
    local creo = CreatureObject(pPatron)
    if (creo:getBankCredits() + creo:getCashCredits()) < amount then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] You do not have enough credits for that tip.")
        self:openV2CustomAmountInput(pPatron, pEntertainer)
        return
    end

    self:setNum(pPatron, "v2_sui_amount", amount)
    self:openV2Confirm(pPatron, pEntertainer, amount)
end

-- ============================================================
-- V2 Step 3: Custom amount confirmation (no charge until confirmed)
-- ============================================================
function EntertainerPaidBuffService:openV2Confirm(pPatron, pEntertainer, amount)
    local entName = CreatureObject(pEntertainer):getFirstName()

    local sui = SuiMessageBox.new("EntertainerPaidBuffService", "v2ConfirmCallback")
    sui.setTargetNetworkId(SceneObject(pPatron):getObjectID())
    sui.setTitle("Confirm EPBS Payment")
    sui.setPrompt("Confirm payment of " .. self:formatCredits(amount) .. " credits to " .. entName .. "?")
    sui.setOkButtonText("Confirm")
    sui.sendTo(pPatron)
end

function EntertainerPaidBuffService:v2ConfirmCallback(pPatron, pSui, eventIndex, args)
    if pPatron == nil then return end

    local entID        = tonumber(self:getString(pPatron, "v2_sui_ent_id")) or 0
    local pEntertainer = entID > 0 and getSceneObject(entID) or nil
    local svcType      = self:getString(pPatron, "v2_sui_type")
    local amount       = self:getNum(pPatron, "v2_sui_amount")
    local mode         = self:getString(pPatron, "v2_sui_mode")
    if mode == "" then mode = "watch" end

    -- Cancel -> back to the tip menu, no charge
    if eventIndex ~= 0 then
        if pEntertainer then
            self:openV2TipMenu(pPatron, pEntertainer)
        else
            self:clearV2SuiState(pPatron)
        end
        return
    end

    self:clearV2SuiState(pPatron)

    if not pEntertainer or amount <= 0 or svcType == "" then return end

    self:v2ProcessPayment(pPatron, entID, svcType, amount, mode)
end

-- ============================================================
-- V2 Payment processing
-- amount = single tip the patron agreed to pay for the chosen buff
-- mode   = "watch" or "listen" (drives the session)
-- ============================================================
function EntertainerPaidBuffService:v2ProcessPayment(pPatron, entID, svcType, amount, mode)
    if pPatron == nil then return end
    if mode == nil or mode == "" then mode = "watch" end

    local pEntertainer = getSceneObject(entID)
    if pEntertainer == nil or not SceneObject(pEntertainer):isPlayerCreature() then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] Entertainer is no longer available. Payment canceled.")
        return
    end

    local entCreo = CreatureObject(pEntertainer)

    -- SAFETY GUARD: never let the patron pay themselves.
    if SceneObject(pEntertainer):getObjectID() == SceneObject(pPatron):getObjectID() then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] Internal error: could not identify the entertainer. Payment canceled.")
        print("[EPBS V2] ABORT self-pay: entID=" .. tostring(entID) ..
              " resolved to patron (ID=" .. tostring(SceneObject(pPatron):getObjectID()) .. ").")
        return
    end

    if not entCreo:isDancing() and not entCreo:isPlayingMusic() then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] The entertainer stopped performing. Payment canceled.")
        return
    end

    if not self:isEnabled(pEntertainer) then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] The entertainer disabled their service. Payment canceled.")
        return
    end

    if not SceneObject(pEntertainer):isInRangeWithObject(pPatron, 60) then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] You are too far from the entertainer. Payment canceled.")
        return
    end

    if (svcType == self.SVC_PET or svcType == self.SVC_BOTH) and not self:patronHasEligiblePet(pPatron) then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] Your pet is no longer eligible. Payment canceled.")
        return
    end

    -- Prevent duplicate session / double charge
    if self:hasV2Session(pPatron) and self:getV2SessEntID(pPatron) == entID then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] You already have an active session with this entertainer.")
        return
    end

    if amount <= 0 or amount > self.MAX_PRICE then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] Invalid payment amount.")
        return
    end

    -- Snapshot balances so we can detect a wallet conflict (patron and
    -- entertainer resolving to the same credit account) and refund instead of
    -- shuffling the patron's own money (the "pay yourself" bug).
    -- Snapshot balances so we can detect a wallet conflict (patron and
    -- entertainer resolving to the same credit account) and refund instead of
    -- shuffling the patron's own money (the "pay yourself" bug).
    local patronCreo = CreatureObject(pPatron)
    local patronBank0, patronCash0 = patronCreo:getBankCredits(), patronCreo:getCashCredits()
    local entBank0,    entCash0    = entCreo:getBankCredits(),    entCreo:getCashCredits()

    if not self:deductCredits(pPatron, amount) then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] Insufficient credits.")
        return
    end

    -- WALLET-CONFLICT GUARD: if the entertainer's balance moved when we deducted
    -- from the patron, both share one account. Refund the patron and abort.
    if entCreo:getBankCredits() ~= entBank0 or entCreo:getCashCredits() ~= entCash0 then
        local bankBack = patronBank0 - patronCreo:getBankCredits()
        local cashBack = patronCash0 - patronCreo:getCashCredits()
        if bankBack > 0 then patronCreo:addBankCredits(bankBack, false) end
        if cashBack > 0 then patronCreo:addCashCredits(cashBack, false) end
        CreatureObject(pPatron):sendSystemMessage(
            "[EPBS] Payment canceled: could not deliver credits to the entertainer. You were not charged.")
        print("[EPBS] WALLET-CONFLICT ABORT: patron OID=" .. tostring(SceneObject(pPatron):getObjectID()) ..
              " ent OID=" .. tostring(SceneObject(pEntertainer):getObjectID()) ..
              " | amount=" .. tostring(amount) ..
              " | patron bank " .. tostring(patronBank0) .. "->" .. tostring(patronCreo:getBankCredits()) ..
              " cash " .. tostring(patronCash0) .. "->" .. tostring(patronCreo:getCashCredits()) ..
              " | ent bank " .. tostring(entBank0) .. "->" .. tostring(entCreo:getBankCredits()) ..
              " cash " .. tostring(entCash0) .. "->" .. tostring(entCreo:getCashCredits()))
        return
    end

    entCreo:addCashCredits(amount, true)
    self:addEarnings(pEntertainer, amount)

    -- Start the buff session for the chosen buff type
    self:v2StartSession(pPatron, entID, svcType, mode)

    local patronName = patronCreo:getFirstName()
    local entName    = entCreo:getFirstName()
    local amtStr     = self:formatCredits(amount)

    patronCreo:sendSystemMessage(
        patronName .. " pays " .. entName .. " " .. amtStr ..
        " credits. Please watch or listen for at least 1 minute to receive your buff."
    )
    entCreo:sendSystemMessage(
        "[EPBS] " .. patronName .. " paid you " .. amtStr .. " credits for a " ..
        self:v2BuffLabel(svcType) .. "."
    )
    print("[EPBS V2] Paid: patron=" .. patronName .. " ent=" .. entName ..
          " type=" .. svcType .. " amount=" .. tostring(amount))
end

-- ============================================================
-- V2 Free session: player opted out of payment but still gets the buff
-- ============================================================
function EntertainerPaidBuffService:v2StartFreeSession(pPatron, pEntertainer, svcType, mode)
    if pPatron == nil or pEntertainer == nil then return end

    -- Don't start a free session if one is already active
    if self:hasV2Session(pPatron) then return end

    if svcType == nil or svcType == "" then svcType = self.SVC_PLAYER end
    if mode == nil or mode == "" then mode = "watch" end

    local entID     = SceneObject(pEntertainer):getObjectID()
    local buffLabel = self:v2BuffLabel(svcType)
    CreatureObject(pPatron):sendSystemMessage(
        "[EPBS] No tip given. Please watch or listen for at least 1 minute to receive your " ..
        buffLabel .. "."
    )
    self:v2StartSession(pPatron, entID, svcType, mode)
    print("[EPBS V2] Free session started: patron=" .. CreatureObject(pPatron):getFirstName() .. " type=" .. svcType)
end

-- ============================================================
-- V2 Session start: stores state and schedules ready/reminder events
-- ============================================================
function EntertainerPaidBuffService:v2StartSession(pPatron, entID, svcType, mode)
    self:setString(pPatron, "v2_sess_ent_id", tostring(entID))
    self:setString(pPatron, "v2_sess_type", svcType)
    self:setNum(pPatron, "v2_sess_start", os.time())
    self:setString(pPatron, "v2_sess_mode", mode)

    local entIDStr = tostring(entID)
    createEvent(self.V2_READY_SECS * 1000,    "EntertainerPaidBuffService", "v2ReadyEvent",    pPatron, entIDStr)
    createEvent(self.V2_REMINDER_SECS * 1000, "EntertainerPaidBuffService", "v2ReminderEvent", pPatron, entIDStr)
end

-- ============================================================
-- V2 60-second ready event: sets auth keys and notifies patron
-- ============================================================
function EntertainerPaidBuffService:v2ReadyEvent(pPatron, entIDStr)
    if pPatron == nil then return end

    local entID = tonumber(entIDStr) or 0
    if entID == 0 then return end

    -- Verify session is still active for this entertainer
    if self:getV2SessEntID(pPatron) ~= entID then return end

    local patronCreo = CreatureObject(pPatron)

    -- Validate entertainer
    local pEntertainer = getSceneObject(entID)
    if pEntertainer == nil or not SceneObject(pEntertainer):isPlayerCreature() then
        patronCreo:sendSystemMessage("[EPBS] The entertainer is no longer available. Your session has ended.")
        self:clearV2Session(pPatron)
        return
    end

    local entCreo = CreatureObject(pEntertainer)

    if not entCreo:isDancing() and not entCreo:isPlayingMusic() then
        patronCreo:sendSystemMessage("[EPBS] The entertainer stopped performing. Your session has ended.")
        self:clearV2Session(pPatron)
        return
    end

    if not self:isEnabled(pEntertainer) then
        patronCreo:sendSystemMessage("[EPBS] The entertainer disabled their paid service. Your session has ended.")
        self:clearV2Session(pPatron)
        return
    end

    -- Set auth keys based on service type
    local svcType  = self:getString(pPatron, "v2_sess_type")
    local petOK    = (svcType == self.SVC_PET or svcType == self.SVC_BOTH) and self:patronHasEligiblePet(pPatron)
    local buffDesc

    if svcType == self.SVC_PLAYER then
        self:setV2Auth(pPatron, entID, false)
        buffDesc = "Player Mind Buff is"

    elseif svcType == self.SVC_PET then
        if not petOK then
            patronCreo:sendSystemMessage("[EPBS] Your pet is no longer eligible. Pet buff session canceled.")
            self:clearV2Session(pPatron)
            return
        end
        self:setV2Auth(pPatron, entID, true)
        buffDesc = "Pet Mind Buff is"

    elseif svcType == self.SVC_BOTH then
        self:setV2Auth(pPatron, entID, false)   -- always set player auth
        if petOK then
            self:setV2Auth(pPatron, entID, true)
            buffDesc = "Player and Pet Mind Buffs are"
        else
            buffDesc = "Player Mind Buff is (your pet is no longer eligible)"
        end

    elseif svcType == self.SVC_FREE then
        self:setV2Auth(pPatron, entID, false)
        buffDesc = "free Mind Buff is"
    end

    patronCreo:sendSystemMessage(
        "[EPBS] Your " .. (buffDesc or "buff is") .. " ready! " ..
        "You may /stopwatching or /stoplistening to receive your buff. " ..
        "You are welcome to stay and enjoy the entertainment until you are ready to leave."
    )
    if svcType ~= self.SVC_FREE then
        entCreo:sendSystemMessage("[EPBS] " .. patronCreo:getFirstName() .. "'s service is now ready.")
    end

    print("[EPBS V2] Ready: patron=" .. patronCreo:getFirstName() .. " type=" .. svcType)
end

-- ============================================================
-- V2 180-second reminder event
-- ============================================================
function EntertainerPaidBuffService:v2ReminderEvent(pPatron, entIDStr)
    if pPatron == nil then return end

    local entID = tonumber(entIDStr) or 0
    if entID == 0 then return end

    if self:getV2SessEntID(pPatron) ~= entID then return end

    local patronCreo = CreatureObject(pPatron)

    -- Only remind if the ready event successfully set an auth key
    local svcType = self:getString(pPatron, "v2_sess_type")
    local hasReady = false
    if svcType == self.SVC_PLAYER or svcType == self.SVC_BOTH or svcType == self.SVC_FREE then
        hasReady = self:hasValidAuth(pPatron, entID, false)
    end
    if not hasReady and (svcType == self.SVC_PET or svcType == self.SVC_BOTH) then
        hasReady = self:hasValidAuth(pPatron, entID, true)
    end

    if not hasReady then return end

    local buffDesc
    if svcType == self.SVC_BOTH then
        buffDesc = "Player and Pet Mind Buffs are"
    elseif svcType == self.SVC_PET then
        buffDesc = "Pet Mind Buff is"
    elseif svcType == self.SVC_FREE then
        buffDesc = "free Mind Buff is"
    else
        buffDesc = "Player Mind Buff is"
    end

    local thankYou = (svcType ~= self.SVC_FREE) and " Thank you for supporting the entertainer!" or ""
    patronCreo:sendSystemMessage(
        "[EPBS] Your " .. buffDesc .. " fully prepared. " ..
        "You may /stopwatching or /stoplistening to receive your buff." .. thankYou
    )
end

-- ============================================================
-- V2 Stop handler: called BEFORE stopWatch/stopListen executes
-- Checks session readiness, sends early-stop message if needed,
-- sets v2_early_stop flag so C++ gate suppresses its message.
-- ============================================================
function EntertainerPaidBuffService:handleStop(pPatron)
    if pPatron == nil then return end

    local sessEntIDStr = self:getString(pPatron, "v2_sess_ent_id")
    if sessEntIDStr == "" then
        self:clearV2SuiState(pPatron)
        return
    end

    local entID    = tonumber(sessEntIDStr) or 0
    local svcType  = self:getString(pPatron, "v2_sess_type")
    local sessStart = self:getNum(pPatron, "v2_sess_start")
    local elapsed  = os.time() - sessStart

    -- Check whether auth keys were set by the ready event
    local playerReady = (svcType == self.SVC_PLAYER or svcType == self.SVC_BOTH or svcType == self.SVC_FREE) and
                         self:hasValidAuth(pPatron, entID, false)
    local petReady    = (svcType == self.SVC_PET    or svcType == self.SVC_BOTH) and
                         self:hasValidAuth(pPatron, entID, true)

    local isReady = (svcType == self.SVC_PLAYER and playerReady) or
                    (svcType == self.SVC_PET    and petReady) or
                    (svcType == self.SVC_BOTH   and (playerReady or petReady)) or
                    (svcType == self.SVC_FREE   and playerReady)

    if not isReady then
        local earlyMsg = (svcType == self.SVC_FREE)
            and "[EPBS] You ended the session too early. Watch or listen for at least 60 seconds to receive your buff."
            or  "[EPBS] You ended the session before your EPBS service was ready. No buff will be applied."
        CreatureObject(pPatron):sendSystemMessage(earlyMsg)
        -- Tell C++ gate to suppress its own "requires payment" message
        self:setString(pPatron, "v2_early_stop", "1")
        -- Clean up any stale auth keys
        if entID > 0 then
            self:clearKey(pPatron, self:authKey(entID))
            self:clearKey(pPatron, self:petAuthKey(entID))
        end
    end
    -- If isReady, auth keys exist and C++ will consume them and apply the buff normally

    self:clearV2Session(pPatron)
    self:clearV2SuiState(pPatron)

    print("[EPBS V2] Stop handled: elapsed=" .. tostring(elapsed) .. "s ready=" .. tostring(isReady))
end

-- ============================================================
-- Global entry points called by C++ commands (V1)
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

-- ============================================================
-- Global entry points called by C++ watch/listen hooks (V2)
-- ============================================================
function epbsOnWatchStart(pPatron, entertainerID)
    if pPatron == nil or entertainerID == nil or entertainerID == 0 then return end
    EntertainerPaidBuffService:onWatchOrListenStart(pPatron, entertainerID, "watch")
end

function epbsOnListenStart(pPatron, entertainerID)
    if pPatron == nil or entertainerID == nil or entertainerID == 0 then return end
    EntertainerPaidBuffService:onWatchOrListenStart(pPatron, entertainerID, "listen")
end

function epbsOnStopWatch(pPatron)
    EntertainerPaidBuffService:handleStop(pPatron)
end

function epbsOnStopListen(pPatron)
    EntertainerPaidBuffService:handleStop(pPatron)
end
