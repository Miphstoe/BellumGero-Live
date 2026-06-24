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
--   v2_sui_ent_id, v2_sui_type, v2_sui_player_amt, v2_sui_pet_amt,
--   v2_sui_step, v2_sui_custom_target
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
    SVC_TIP    = "TIP",
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
-- entertainerID is passed directly from the C++ command (the player's current target).
-- ============================================================
function EntertainerPaidBuffService:processPay(pPatron, entertainerID, isPet)
    if pPatron == nil then return end

    if entertainerID == nil or entertainerID == 0 then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] Target the performing entertainer first, then use /epbspay.")
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
--   v2_sess_type    - SVC_PLAYER / SVC_PET / SVC_BOTH / SVC_TIP
--   v2_sess_start   - Unix timestamp when session started
--   v2_sess_mode    - "watch" or "listen"
-- SUI flow keys:
--   v2_sui_ent_id, v2_sui_type
--   v2_sui_player_amt (amt for player buff; also sole amt for PET/TIP)
--   v2_sui_pet_amt    (extra amt for pet buff, BOTH only)
--   v2_sui_step       ("player_amt" or "pet_amt")
--   v2_sui_custom_target ("pet" or "")
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
    self:clearKey(pPatron, "v2_sui_player_amt")
    self:clearKey(pPatron, "v2_sui_pet_amt")
    self:clearKey(pPatron, "v2_sui_step")
    self:clearKey(pPatron, "v2_sui_custom_target")
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
-- V2 Step 1: Service selection menu
-- ============================================================
function EntertainerPaidBuffService:openV2ServiceMenu(pPatron, pEntertainer)
    local entID   = SceneObject(pEntertainer):getObjectID()
    local entName = CreatureObject(pEntertainer):getFirstName()
    self:setString(pPatron, "v2_sui_ent_id", tostring(entID))

    local sui = SuiListBox.new("EntertainerPaidBuffService", "v2ServiceCallback")
    sui.setTargetNetworkId(SceneObject(pPatron):getObjectID())
    sui.setTitle("Entertainer Services Available")
    sui.setPrompt(
        entName .. " offers paid buff services.\n\n" ..
        "What would you like?\n\n" ..
        "All payments are voluntary. Buffs apply after 60 seconds of continuous watching or listening."
    )
    sui.add("Player Mind Buff", "")
    sui.add("Pet Mind Buff", "")
    sui.add("Player + Pet Mind Buff", "")
    sui.add("Custom Tip Only", "")
    sui.add("Continue Without Tipping", "")
    sui.sendTo(pPatron)
end

function EntertainerPaidBuffService:v2ServiceCallback(pPatron, pSui, eventIndex, args)
    if pPatron == nil then return end

    local entIDStr = self:getString(pPatron, "v2_sui_ent_id")
    local entID    = tonumber(entIDStr) or 0
    local pEntertainer = entID > 0 and getSceneObject(entID) or nil

    if eventIndex == 1 or not pEntertainer then
        self:clearV2SuiState(pPatron)
        return
    end

    local sel = tonumber(args)
    if sel == nil then
        self:clearV2SuiState(pPatron)
        return
    end

    if sel == 4 then  -- Continue Without Tipping
        local mode = self:getString(pPatron, "v2_sui_mode")
        if mode == "" then mode = "watch" end
        self:clearV2SuiState(pPatron)
        self:v2StartFreeSession(pPatron, pEntertainer, mode)
        return
    end

    if sel == 0 then   -- Player Mind Buff
        self:setString(pPatron, "v2_sui_type", self.SVC_PLAYER)
        self:openV2AmountMenu(pPatron, pEntertainer, "player_amt")

    elseif sel == 1 then   -- Pet Mind Buff
        if not self:patronHasEligiblePet(pPatron) then
            CreatureObject(pPatron):sendSystemMessage("[EPBS] You do not have an active eligible pet.")
            self:openV2ServiceMenu(pPatron, pEntertainer)
            return
        end
        self:setString(pPatron, "v2_sui_type", self.SVC_PET)
        self:openV2AmountMenu(pPatron, pEntertainer, "player_amt")

    elseif sel == 2 then   -- Player + Pet Mind Buff
        if not self:patronHasEligiblePet(pPatron) then
            CreatureObject(pPatron):sendSystemMessage("[EPBS] You do not have an active eligible pet.")
            self:openV2ServiceMenu(pPatron, pEntertainer)
            return
        end
        self:setString(pPatron, "v2_sui_type", self.SVC_BOTH)
        self:openV2AmountMenu(pPatron, pEntertainer, "player_amt")

    elseif sel == 3 then   -- Custom Tip Only
        self:setString(pPatron, "v2_sui_type", self.SVC_TIP)
        self:openV2CustomTipInput(pPatron, pEntertainer)
    end
end

-- ============================================================
-- V2 Step 2: Amount selection menu
-- step: "player_amt" = first amount (player buff, or sole for PET/TIP)
--       "pet_amt"    = second amount (pet buff, BOTH only)
-- ============================================================
function EntertainerPaidBuffService:openV2AmountMenu(pPatron, pEntertainer, step)
    local svcType = self:getString(pPatron, "v2_sui_type")
    self:setString(pPatron, "v2_sui_step", step)

    local isPetLabel = (step == "pet_amt") or (svcType == self.SVC_PET)
    local label   = isPetLabel and "Pet Mind Buff" or "Player Mind Buff"
    local entName = CreatureObject(pEntertainer):getFirstName()

    local sui = SuiListBox.new("EntertainerPaidBuffService", "v2AmountCallback")
    sui.setTargetNetworkId(SceneObject(pPatron):getObjectID())
    sui.setTitle(label .. " — Select Amount")
    sui.setPrompt("How much would you like to tip " .. entName .. " for the " .. label .. "?")
    sui.add(tostring(self.V2_PRESET_LOW) .. " credits", "")
    sui.add(tostring(self.V2_PRESET_HIGH) .. " credits", "")
    sui.add("Custom Amount", "")
    sui.add("Back", "")
    sui.sendTo(pPatron)
end

function EntertainerPaidBuffService:v2AmountCallback(pPatron, pSui, eventIndex, args)
    if pPatron == nil then return end

    local entIDStr = self:getString(pPatron, "v2_sui_ent_id")
    local entID    = tonumber(entIDStr) or 0
    local pEntertainer = entID > 0 and getSceneObject(entID) or nil
    local step    = self:getString(pPatron, "v2_sui_step")
    local svcType = self:getString(pPatron, "v2_sui_type")

    local function goBack()
        if not pEntertainer then
            self:clearV2SuiState(pPatron)
        elseif step == "pet_amt" then
            self:openV2AmountMenu(pPatron, pEntertainer, "player_amt")
        else
            self:openV2ServiceMenu(pPatron, pEntertainer)
        end
    end

    if eventIndex == 1 then
        goBack()
        return
    end

    if not pEntertainer then
        self:clearV2SuiState(pPatron)
        return
    end

    local sel = tonumber(args)
    if sel == nil then
        self:clearV2SuiState(pPatron)
        return
    end

    if sel == 3 then   -- Back
        goBack()
        return
    end

    local amount
    if sel == 0 then
        amount = self.V2_PRESET_LOW
    elseif sel == 1 then
        amount = self.V2_PRESET_HIGH
    elseif sel == 2 then   -- Custom Amount
        local isPet = (step == "pet_amt") or (svcType == self.SVC_PET)
        self:openV2CustomAmountInput(pPatron, pEntertainer, isPet)
        return
    end

    self:v2StoreAmount(pPatron, pEntertainer, step, svcType, amount)
end

-- Helper: store amount and advance the SUI flow
function EntertainerPaidBuffService:v2StoreAmount(pPatron, pEntertainer, step, svcType, amount)
    if step == "pet_amt" then
        self:setNum(pPatron, "v2_sui_pet_amt", amount)
        self:openV2Confirm(pPatron, pEntertainer)
    else
        self:setNum(pPatron, "v2_sui_player_amt", amount)
        if svcType == self.SVC_BOTH then
            self:openV2AmountMenu(pPatron, pEntertainer, "pet_amt")
        else
            self:openV2Confirm(pPatron, pEntertainer)
        end
    end
end

-- ============================================================
-- V2 Step 2b: Custom amount input (shared by player, pet, tip)
-- ============================================================
function EntertainerPaidBuffService:openV2CustomAmountInput(pPatron, pEntertainer, isPet)
    self:setString(pPatron, "v2_sui_custom_target", isPet and "pet" or "")
    local entName = CreatureObject(pEntertainer):getFirstName()
    local label   = isPet and "Pet Mind Buff" or "Player Mind Buff"

    local sui = SuiInputBox.new("EntertainerPaidBuffService", "v2CustomAmountCallback")
    sui.setTargetNetworkId(SceneObject(pPatron):getObjectID())
    sui.setTitle("Custom Amount — " .. label)
    sui.setPrompt(
        "Enter a custom credit amount for the " .. label .. " tip to " .. entName .. ".\n" ..
        "Min: " .. tostring(self.MIN_PRICE) .. "  Max: " .. tostring(self.MAX_PRICE)
    )
    sui.setOkButtonText("Set Amount")
    sui.sendTo(pPatron)
end

function EntertainerPaidBuffService:openV2CustomTipInput(pPatron, pEntertainer)
    self:clearKey(pPatron, "v2_sui_custom_target")
    local entName = CreatureObject(pEntertainer):getFirstName()

    local sui = SuiInputBox.new("EntertainerPaidBuffService", "v2CustomAmountCallback")
    sui.setTargetNetworkId(SceneObject(pPatron):getObjectID())
    sui.setTitle("Custom Tip Only")
    sui.setPrompt(
        "Enter a tip amount for " .. entName .. ".\n" ..
        "Min: " .. tostring(self.MIN_PRICE) .. "  Max: " .. tostring(self.MAX_PRICE) ..
        "\n\nCustom Tip does not include a buff session."
    )
    sui.setOkButtonText("Continue")
    sui.sendTo(pPatron)
end

function EntertainerPaidBuffService:v2CustomAmountCallback(pPatron, pSui, eventIndex, args)
    if pPatron == nil then return end

    local entIDStr     = self:getString(pPatron, "v2_sui_ent_id")
    local entID        = tonumber(entIDStr) or 0
    local pEntertainer = entID > 0 and getSceneObject(entID) or nil
    local customTarget = self:getString(pPatron, "v2_sui_custom_target")
    local isPet        = (customTarget == "pet")
    local svcType      = self:getString(pPatron, "v2_sui_type")
    local step         = self:getString(pPatron, "v2_sui_step")
    self:clearKey(pPatron, "v2_sui_custom_target")

    if eventIndex ~= 0 then   -- Cancel = back
        if pEntertainer then
            if svcType == self.SVC_TIP then
                self:openV2ServiceMenu(pPatron, pEntertainer)
            else
                self:openV2AmountMenu(pPatron, pEntertainer, step)
            end
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

    local amount = tonumber(args)
    if amount == nil or amount <= 0 then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] Please enter a valid positive amount.")
        if svcType == self.SVC_TIP then
            self:openV2CustomTipInput(pPatron, pEntertainer)
        else
            self:openV2CustomAmountInput(pPatron, pEntertainer, isPet)
        end
        return
    end

    amount = math.max(self.MIN_PRICE, math.min(self.MAX_PRICE, math.floor(amount)))
    self:v2StoreAmount(pPatron, pEntertainer, isPet and "pet_amt" or "player_amt", svcType, amount)
end

-- ============================================================
-- V2 Step 3: Confirmation dialog
-- ============================================================
function EntertainerPaidBuffService:openV2Confirm(pPatron, pEntertainer)
    local svcType = self:getString(pPatron, "v2_sui_type")
    local amt1    = self:getNum(pPatron, "v2_sui_player_amt")
    local amt2    = self:getNum(pPatron, "v2_sui_pet_amt")
    local entName = CreatureObject(pEntertainer):getFirstName()
    local prompt

    if svcType == self.SVC_PLAYER then
        prompt = "Pay " .. tostring(amt1) .. " credits to " .. entName .. " for a Player Mind Buff?\n\n" ..
                 "Buff becomes ready after 60 seconds of watching or listening."
    elseif svcType == self.SVC_PET then
        prompt = "Pay " .. tostring(amt1) .. " credits to " .. entName .. " for a Pet Mind Buff?\n\n" ..
                 "Buff becomes ready after 60 seconds of watching or listening."
    elseif svcType == self.SVC_BOTH then
        local total = amt1 + amt2
        prompt = "Player Mind Buff: " .. tostring(amt1) .. " credits\n" ..
                 "Pet Mind Buff:    " .. tostring(amt2) .. " credits\n" ..
                 "Total:            " .. tostring(total) .. " credits\n\n" ..
                 "Pay " .. tostring(total) .. " credits to " .. entName .. "?\n\n" ..
                 "Both buffs become ready after 60 seconds of watching or listening."
    elseif svcType == self.SVC_TIP then
        prompt = "Tip " .. tostring(amt1) .. " credits to " .. entName .. "?\n\n" ..
                 "Custom Tip does not include a buff session."
    end

    local sui = SuiMessageBox.new("EntertainerPaidBuffService", "v2ConfirmCallback")
    sui.setTargetNetworkId(SceneObject(pPatron):getObjectID())
    sui.setTitle("Confirm EPBS Payment")
    sui.setPrompt(prompt or "")
    sui.setOkButtonText("Confirm")
    sui.sendTo(pPatron)
end

function EntertainerPaidBuffService:v2ConfirmCallback(pPatron, pSui, eventIndex, args)
    if pPatron == nil then return end

    local entID   = tonumber(self:getString(pPatron, "v2_sui_ent_id")) or 0
    local svcType = self:getString(pPatron, "v2_sui_type")
    local amt1    = self:getNum(pPatron, "v2_sui_player_amt")
    local amt2    = self:getNum(pPatron, "v2_sui_pet_amt")

    self:clearV2SuiState(pPatron)

    if eventIndex ~= 0 or entID == 0 or svcType == "" then return end

    self:v2ProcessPayment(pPatron, entID, svcType, amt1, amt2)
end

-- ============================================================
-- V2 Payment processing
-- amt1 = player buff cost (or pet cost for SVC_PET, or tip for SVC_TIP)
-- amt2 = pet buff cost (SVC_BOTH only)
-- ============================================================
function EntertainerPaidBuffService:v2ProcessPayment(pPatron, entID, svcType, amt1, amt2)
    if pPatron == nil then return end

    local pEntertainer = getSceneObject(entID)
    if pEntertainer == nil or not SceneObject(pEntertainer):isPlayerCreature() then
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
        CreatureObject(pPatron):sendSystemMessage("[EPBS] You are too far from the entertainer. Payment canceled.")
        return
    end

    if (svcType == self.SVC_PET or svcType == self.SVC_BOTH) and not self:patronHasEligiblePet(pPatron) then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] Your pet is no longer eligible. Payment canceled.")
        return
    end

    -- Prevent duplicate session
    if self:hasV2Session(pPatron) and self:getV2SessEntID(pPatron) == entID then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] You already have an active session with this entertainer.")
        return
    end

    -- Calculate total
    local totalAmount = (svcType == self.SVC_BOTH) and (amt1 + amt2) or amt1

    if totalAmount <= 0 or totalAmount > self.MAX_PRICE * 2 then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] Invalid payment amount.")
        return
    end

    if not self:deductCredits(pPatron, totalAmount) then
        CreatureObject(pPatron):sendSystemMessage("[EPBS] Insufficient credits.")
        return
    end

    entCreo:addCashCredits(totalAmount, true)
    self:addEarnings(pEntertainer, totalAmount)

    local patronName = CreatureObject(pPatron):getFirstName()
    local entName    = entCreo:getFirstName()

    if svcType == self.SVC_TIP then
        CreatureObject(pPatron):sendSystemMessage(
            "[EPBS] You tipped " .. entName .. " " .. tostring(totalAmount) .. " credits. Thank you!"
        )
        entCreo:sendSystemMessage(
            "[EPBS] " .. patronName .. " tipped you " .. tostring(totalAmount) .. " credits."
        )
        print("[EPBS V2] TIP: patron=" .. patronName .. " ent=" .. entName .. " amt=" .. tostring(totalAmount))
        return
    end

    -- Start V2 session for buff services
    local patronCreo = CreatureObject(pPatron)
    local mode = self:getString(pPatron, "v2_sui_mode")
    if mode == "" then mode = "watch" end
    self:v2StartSession(pPatron, entID, svcType, mode)

    local buffDesc
    if svcType == self.SVC_PLAYER then
        buffDesc = "Player Mind Buff (" .. tostring(amt1) .. " cr)"
    elseif svcType == self.SVC_PET then
        buffDesc = "Pet Mind Buff (" .. tostring(amt1) .. " cr)"
    else
        buffDesc = "Player + Pet Mind Buff (" .. tostring(totalAmount) .. " cr total)"
    end

    patronCreo:sendSystemMessage(
        "[EPBS] " .. patronName .. " paid " .. entName .. " " .. tostring(totalAmount) .. " credits for " .. buffDesc .. ". " ..
        "Your service will be ready in 60 seconds — feel free to stay and enjoy the show!"
    )
    entCreo:sendSystemMessage(
        "[EPBS] " .. patronName .. " paid you " .. tostring(totalAmount) .. " credits for " .. buffDesc .. "."
    )
    print("[EPBS V2] Session started: patron=" .. patronName .. " type=" .. svcType .. " total=" .. tostring(totalAmount))
end

-- ============================================================
-- V2 Free session: player opted out of payment but still gets the buff
-- ============================================================
function EntertainerPaidBuffService:v2StartFreeSession(pPatron, pEntertainer, mode)
    if pPatron == nil or pEntertainer == nil then return end

    -- Don't start a free session if one is already active
    if self:hasV2Session(pPatron) then return end

    local entID = SceneObject(pEntertainer):getObjectID()
    CreatureObject(pPatron):sendSystemMessage(
        "[EPBS] You are watching freely. Your mind buff will be ready in 60 seconds — " ..
        "use /stopwatching or /stoplistening when you are ready to receive it."
    )
    self:v2StartSession(pPatron, entID, self.SVC_FREE, mode)
    print("[EPBS V2] Free session started: patron=" .. CreatureObject(pPatron):getFirstName())
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
