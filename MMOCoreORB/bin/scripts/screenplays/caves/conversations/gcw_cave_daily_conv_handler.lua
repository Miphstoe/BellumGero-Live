-- GCW Cave Daily Conversation Handler (screenplays loader; uses conv_handler)
gcwCaveDailyConvoHandler = conv_handler:new {}

local function npcSide(pNpc)
  local nco = CreatureObject(pNpc)
  if nco:isImperial() then return "imperial" end
  if nco:isRebel() then return "rebel" end
  return "neutral"
end

local function isRightSide(pPlayer, side)
  local co = CreatureObject(pPlayer)
  return (side == "imperial" and co:isImperial()) or (side == "rebel" and co:isRebel())
end

-- First open: faction gate
function gcwCaveDailyConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
  local tmpl = LuaConversationTemplate(pConvTemplate)
  if not isRightSide(pPlayer, npcSide(pNpc)) then
    return tmpl:getScreen("not_faction")
  end
  return tmpl:getScreen("start")
end

-- Effects for each screen
function gcwCaveDailyConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
  local screen = LuaConversationScreen(pConvScreen)
  local id     = screen:getScreenID()
  local side   = npcSide(pNpc)
  local sp     = TalusLostAqualishScreenPlay
  local tmpl   = LuaConversationTemplate(pConvTemplate)

  if id == "accept" then
    if not isRightSide(pPlayer, side) then
      return tmpl:getScreen("not_faction")
    end

    -- If they already started today, remind them instead of showing the "Acknowledged" text
    local _, target, active, _ = sp:getDailyProgress(pPlayer)
    if active then
      CreatureObject(pPlayer):sendSystemMessage(string.format("Assignment already active: %d required. Good hunting.", target))
      return tmpl:getScreen("already_active")
    end

    -- If they finished and are on cooldown, show cooldown text instead of the accept text
    if sp:isDailyOnCooldown(pPlayer) then
      local rem = sp:getDailyCooldownRemaining(pPlayer)
      CreatureObject(pPlayer):sendSystemMessage(string.format("Daily is on cooldown. Time remaining: %s.", sp:formatTime(rem)))
      return tmpl:getScreen("cooldown")
    end

    -- Start fresh
    sp:startDaily(pPlayer, side)
    CreatureObject(pPlayer):sendSystemMessage("Daily assignment accepted: Suppress 25 defectors in the cave.")
    return tmpl:getScreen("accept")

  elseif id == "status" then
    local k, target, active, rem = sp:getDailyProgress(pPlayer)
    if active then
      CreatureObject(pPlayer):sendSystemMessage(string.format("Daily progress: %d / %d. Cooldown in: %s.", k, target, sp:formatTime(rem)))
    else
      if sp:isDailyOnCooldown(pPlayer) then
        CreatureObject(pPlayer):sendSystemMessage(string.format("You have already completed today's order. Cooldown in: %s.", sp:formatTime(rem)))
        return tmpl:getScreen("cooldown")
      else
        CreatureObject(pPlayer):sendSystemMessage("No active assignment. Ask for today's order to begin.")
      end
    end
    return pConvScreen

  elseif id == "turnin" then
    local ok, msg = sp:completeDaily(pPlayer)
    CreatureObject(pPlayer):sendSystemMessage(msg)
    return pConvScreen
  end

  return pConvScreen
end