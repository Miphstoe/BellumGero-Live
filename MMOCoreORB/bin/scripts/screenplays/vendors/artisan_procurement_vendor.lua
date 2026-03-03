ArtisanProcurementVendor = ScreenPlay:new {
  numberOfActs = 1,
  screenplayName = "ArtisanProcurementVendor",

  phaseDurationSeconds = 3 * 60 * 60,
  phasePollMilliseconds = 60 * 1000,
  requiredQuantity = 20,
  rewardCredits = 900,
  difficultyBasePayouts = {
    [1] = 2500,
    [2] = 5000,
    [3] = 10000
  },
  payoutVariancePercent = 15,
  payoutRoundingStep = 25,
  maxContractsPerPhase = 3,

  dataPrefix = "ArtisanProcurementVendor:",

  npc = {
    planet = "corellia",
    x = -171,
    y = 28,
    z = -4708,
    heading = 180,
    cell = 0,
    template = "artisan_procurement_vendor",
    customName = "Artisan Procurement Trader"
  },

  artisanPoolCache = nil
}

registerScreenPlay("ArtisanProcurementVendor", true)

function ArtisanProcurementVendor:start()
  self:spawnVendor()
  self:ensureCurrentContract(true)
  createEvent(self.phasePollMilliseconds, self.screenplayName, "pollForContractRotation", nil, "")
end

function ArtisanProcurementVendor:pollForContractRotation()
  self:ensureCurrentContract(true)
  createEvent(self.phasePollMilliseconds, self.screenplayName, "pollForContractRotation", nil, "")
  return 0
end

function ArtisanProcurementVendor:getCurrentPhaseId()
  return math.floor(os.time() / self.phaseDurationSeconds)
end

function ArtisanProcurementVendor:getPhaseEndTimestamp(phaseId)
  return (phaseId + 1) * self.phaseDurationSeconds
end

function ArtisanProcurementVendor:getContractDataKey(suffix)
  return self.dataPrefix .. suffix
end

function ArtisanProcurementVendor:templateToDisplayName(templatePath)
  local file = string.match(templatePath or "", "([^/]+)%.iff$") or "crafted item"
  local words = {}

  for token in string.gmatch(file, "[^_]+") do
    if token ~= "" then
      table.insert(words, string.upper(string.sub(token, 1, 1)) .. string.sub(token, 2))
    end
  end

  if #words == 0 then
    return "Crafted Item"
  end

  return table.concat(words, " ")
end

function ArtisanProcurementVendor:getSchematicCode(draftPath)
  local code = string.match(draftPath or "", "([^/]+)%.iff$") or "unknown"
  return code
end

function ArtisanProcurementVendor:getDisplayNameFromDraft(draftPath, tangiblePath)
  if draftPath ~= nil and draftPath ~= "" and type(getSchematicItemName) == "function" then
    local ok, displayName = pcall(function()
      return getSchematicItemName(draftPath)
    end)

    if ok and displayName ~= nil and displayName ~= "" then
      return displayName
    end
  end

  return self:templateToDisplayName(tangiblePath)
end

function ArtisanProcurementVendor:normalizeTemplatePath(templatePath)
  local path = string.lower(templatePath or "")

  if path == "" then
    return path
  end

  -- SWG object paths often differ by shared/non-shared prefix.
  path = string.gsub(path, "/shared_", "/")

  return path
end

function ArtisanProcurementVendor:getTemplateToken(templatePath)
  local normalized = self:normalizeTemplatePath(templatePath)
  return string.match(normalized or "", "([^/]+)%.iff$") or ""
end

function ArtisanProcurementVendor:ensureScanState(state)
  if type(state) ~= "table" then
    state = {}
  end

  if type(state.visited) ~= "table" then
    state.visited = {}
  end

  if type(state.nodes) ~= "number" then
    state.nodes = 0
  end

  if type(state.maxNodes) ~= "number" then
    state.maxNodes = 10000
  end

  if type(state.maxDepth) ~= "number" then
    state.maxDepth = 32
  end

  if type(state.depth) ~= "number" then
    state.depth = 0
  end

  return state
end

function ArtisanProcurementVendor:getArtisanItemPool()
  if self.artisanPoolCache ~= nil then
    return self.artisanPoolCache
  end

  local pool = {}
  local seen = {}

  if CraftingContractor ~= nil and CraftingContractor.quests ~= nil and CraftingContractor.quests.artisan ~= nil then
    for difficulty = 1, 3, 1 do
      local entries = CraftingContractor.quests.artisan[difficulty]
      if type(entries) == "table" then
        for i = 1, #entries, 1 do
          local entry = entries[i]
          local draftPath = entry and entry[1] or nil
          local tangiblePath = entry and entry[2] or nil

          if tangiblePath ~= nil and tangiblePath ~= "" and seen[tangiblePath] == nil then
            seen[tangiblePath] = #pool + 1
            table.insert(pool, {
              template = tangiblePath,
              draft = draftPath,
              schematicCode = self:getSchematicCode(draftPath),
              name = self:getDisplayNameFromDraft(draftPath, tangiblePath),
              difficulty = difficulty
            })
          elseif tangiblePath ~= nil and tangiblePath ~= "" then
            local existingIndex = seen[tangiblePath]
            local existing = pool[existingIndex]
            if existing ~= nil and (existing.difficulty == nil or difficulty > existing.difficulty) then
              existing.difficulty = difficulty
              if draftPath ~= nil and draftPath ~= "" then
                existing.draft = draftPath
                existing.schematicCode = self:getSchematicCode(draftPath)
                existing.name = self:getDisplayNameFromDraft(draftPath, tangiblePath)
              end
            end
          end
        end
      end
    end
  end

  if #pool == 0 then
    table.insert(pool, {
      template = "object/tangible/survey_tool/survey_tool_mineral.iff",
      draft = "object/draft_schematic/item/item_survey_tool_mineral.iff",
      schematicCode = "item_survey_tool_mineral",
      name = "Survey Tool Mineral",
      difficulty = 1
    })
  end

  self.artisanPoolCache = pool
  return pool
end

function ArtisanProcurementVendor:getDeterministicHashWithSalt(phaseId, salt)
  local saltHash = 0
  local text = tostring(salt or "")

  for i = 1, string.len(text), 1 do
    saltHash = (saltHash * 33 + string.byte(text, i)) % 2147483647
  end

  return ((phaseId * 48271) + (saltHash * 69621) + 12345) % 2147483647
end

function ArtisanProcurementVendor:roundCredits(value)
  local step = tonumber(self.payoutRoundingStep or 25) or 25
  if step <= 1 then
    return math.floor(value)
  end

  return math.floor((value + math.floor(step / 2)) / step) * step
end

function ArtisanProcurementVendor:calculatePayout(choice, phaseId)
  local difficulty = tonumber(choice and choice.difficulty or nil) or 2
  local base = tonumber(self.difficultyBasePayouts[difficulty] or self.rewardCredits) or 900
  local varianceRange = math.floor(base * ((tonumber(self.payoutVariancePercent) or 0) / 100))

  if varianceRange < 0 then
    varianceRange = 0
  end

  local templateToken = self:getTemplateToken(choice and choice.template or "")
  local hash = self:getDeterministicHashWithSalt(phaseId, templateToken)
  local variance = 0

  if varianceRange > 0 then
    variance = (hash % (varianceRange * 2 + 1)) - varianceRange
  end

  local payout = base + variance
  local minimum = math.floor(base * 0.70)
  if payout < minimum then
    payout = minimum
  end

  payout = self:roundCredits(payout)
  if payout < 100 then
    payout = 100
  end

  return payout
end

function ArtisanProcurementVendor:getDeterministicPoolIndex(phaseId, poolSize)
  -- Deterministic pseudo-random index by phase, so contracts survive restarts.
  local hash = ((phaseId * 48271) + 12345) % 2147483647
  local idx = (hash % poolSize) + 1

  if poolSize > 1 then
    local prevHash = (((phaseId - 1) * 48271) + 12345) % 2147483647
    local prevIdx = (prevHash % poolSize) + 1
    if idx == prevIdx then
      idx = (idx % poolSize) + 1
    end
  end

  return idx
end

function ArtisanProcurementVendor:rollContractForPhase(phaseId)
  local pool = self:getArtisanItemPool()
  local choice = pool[self:getDeterministicPoolIndex(phaseId, #pool)]
  local difficulty = tonumber(choice and choice.difficulty or nil) or 2

  return {
    template = choice.template,
    draft = choice.draft,
    schematicCode = choice.schematicCode,
    name = choice.name,
    difficulty = difficulty,
    quantity = self.requiredQuantity,
    payout = self:calculatePayout(choice, phaseId)
  }
end

function ArtisanProcurementVendor:ensureCurrentContract(allowBroadcast)
  local phaseId = self:getCurrentPhaseId()
  local lastBroadcasted = tonumber(getQuestStatus(self:getContractDataKey("lastBroadcastedPhase")) or "-1") or -1

  if allowBroadcast and lastBroadcasted ~= phaseId then
    local contract = self:rollContractForPhase(phaseId)
    self:broadcastContract(contract)
    setQuestStatus(self:getContractDataKey("lastBroadcastedPhase"), tostring(phaseId))
  end
end

function ArtisanProcurementVendor:getCurrentContract()
  local phaseId = self:getCurrentPhaseId()
  local contract = self:rollContractForPhase(phaseId)
  contract.phaseId = phaseId
  return contract
end

function ArtisanProcurementVendor:formatTimeRemaining(seconds)
  if seconds < 0 then
    seconds = 0
  end

  local hours = math.floor(seconds / 3600)
  local minutes = math.floor((seconds % 3600) / 60)

  return tostring(hours) .. "h " .. tostring(minutes) .. "m"
end

function ArtisanProcurementVendor:getPlayerCompletionKey(playerId, phaseId)
  return self:getContractDataKey("completedCount:" .. tostring(playerId) .. ":" .. tostring(phaseId))
end

function ArtisanProcurementVendor:getCompletedCountCurrentPhase(pPlayer, contract)
  if pPlayer == nil or contract == nil then
    return 0
  end

  local playerId = SceneObject(pPlayer):getObjectID()
  local completedCount = tonumber(getQuestStatus(self:getPlayerCompletionKey(playerId, contract.phaseId)) or "0") or 0

  if completedCount < 0 then
    completedCount = 0
  end

  return completedCount
end

function ArtisanProcurementVendor:hasCompletedCurrentPhase(pPlayer, contract)
  return self:getCompletedCountCurrentPhase(pPlayer, contract) >= self.maxContractsPerPhase
end

function ArtisanProcurementVendor:markCompletedCurrentPhase(pPlayer, contract)
  if pPlayer == nil or contract == nil then
    return
  end

  local playerId = SceneObject(pPlayer):getObjectID()
  local currentCount = self:getCompletedCountCurrentPhase(pPlayer, contract)
  setQuestStatus(self:getPlayerCompletionKey(playerId, contract.phaseId), tostring(currentCount + 1))
end

function ArtisanProcurementVendor:getStatusDialogText(pPlayer)
  local contract = self:getCurrentContract()

  if contract == nil then
    return "No procurement order is posted at this time. Check back shortly."
  end

  local remaining = self:getPhaseEndTimestamp(contract.phaseId) - os.time()
  local statusLine = "Status: Open for delivery"
  local completedCount = self:getCompletedCountCurrentPhase(pPlayer, contract)

  if self:hasCompletedCurrentPhase(pPlayer, contract) then
    statusLine = "Status: Delivery limit reached (" .. tostring(self.maxContractsPerPhase) .. "/" .. tostring(self.maxContractsPerPhase) .. ")"
  elseif completedCount > 0 then
    statusLine = "Status: Deliveries completed this rotation: " .. tostring(completedCount) .. "/" .. tostring(self.maxContractsPerPhase)
  end

  return "Procurement Ledger:\n" ..
    "- Order: " .. tostring(contract.quantity) .. "x " .. contract.name .. "\n" ..
    "- Complexity Tier: " .. tostring(contract.difficulty or 2) .. "\n" ..
    "- Bounty: " .. tostring(contract.payout) .. " credits\n" ..
    "- Rotation: Every 3 hours\n" ..
    "- Time Remaining: " .. self:formatTimeRemaining(remaining) .. "\n" ..
    "- Completed This Rotation: " .. tostring(completedCount) .. "/" .. tostring(self.maxContractsPerPhase) .. "\n" ..
    "- " .. statusLine .. "\n\n" ..
    "Terms: Goods must be player-crafted and match the exact requested template. Up to " .. tostring(self.maxContractsPerPhase) .. " deliveries per artisan each rotation.\n" ..
    "Note: Build from the exact schematic code shown in brackets."
end

function ArtisanProcurementVendor:isContainerTemplate(templatePath)
  if templatePath == nil then
    return false
  end

  return string.find(templatePath, "container/") ~= nil
    or string.find(templatePath, "backpack/") ~= nil
    or string.find(templatePath, "wearables/backpack") ~= nil
    or string.find(templatePath, "factory_crate") ~= nil
end

function ArtisanProcurementVendor:isCraftedItem(pObj)
  if pObj == nil then
    return false
  end

  local craftersName = nil
  local tano = TangibleObject(pObj)

  if tano ~= nil and tano.getCraftersName ~= nil then
    local ok, name = pcall(function()
      return tano:getCraftersName()
    end)

    if ok then
      craftersName = name
    end
  end

  if craftersName ~= nil and craftersName ~= "" then
    return true
  end

  -- Some forks do not persist crafter names on all craftables.
  return true
end

function ArtisanProcurementVendor:itemMatchesContract(pItem, itemObj, match)
  if pItem == nil or itemObj == nil or match == nil then
    return false
  end

  local okTemplate, templatePath = pcall(function()
    return itemObj:getTemplateObjectPath()
  end)
  if not okTemplate or templatePath == nil or templatePath == "" then
    return false
  end

  local itemTemplate = self:normalizeTemplatePath(templatePath)
  local itemToken = self:getTemplateToken(itemTemplate)

  if itemTemplate == match.requiredTemplate then
    return true
  end

  -- Accept closely-related template variants (shared/non-shared and crafted suffix variants).
  if match.requiredToken ~= "" and string.find(itemToken, match.requiredToken, 1, true) ~= nil then
    return true
  end

  return false
end

function ArtisanProcurementVendor:consumeItemsFromContainer(pContainer, match, neededAmount, state, depth)
  if pContainer == nil or neededAmount <= 0 then
    return 0
  end

  local removed = 0
  local containerObj = LuaSceneObject(pContainer)
  if containerObj == nil then
    return 0
  end

  local okSize, count = pcall(function()
    return containerObj:getContainerObjectsSize()
  end)
  if not okSize or count == nil then
    return 0
  end
  if count == nil or count < 0 then
    return 0
  end
  if count > 512 then
    count = 512
  end

  for i = count - 1, 0, -1 do
    if removed >= neededAmount then
      break
    end

    local okObj, pItem = pcall(function() return containerObj:getContainerObject(i) end)
    if pItem ~= nil then
      local okItem, itemObj = pcall(function()
        return LuaSceneObject(pItem)
      end)
      if okItem and itemObj ~= nil and itemObj.getTemplateObjectPath ~= nil then
        local okTemplate, rawTemplate = pcall(function()
          return itemObj:getTemplateObjectPath()
        end)
        local templatePath = self:normalizeTemplatePath(okTemplate and rawTemplate or "")

        if (not self:isContainerTemplate(templatePath)) and self:itemMatchesContract(pItem, itemObj, match) then
          pcall(function() itemObj:destroyObjectFromWorld(true) end)
          pcall(function() itemObj:destroyObjectFromDatabase(true) end)
          removed = removed + 1
        end
      end
    end
  end

  return removed
end

function ArtisanProcurementVendor:countItemsInContainer(pContainer, match, visited)
  if pContainer == nil then
    return 0
  end

  local total = 0
  local containerObj = LuaSceneObject(pContainer)
  if containerObj == nil then
    return 0
  end

  local okSize, count = pcall(function()
    return containerObj:getContainerObjectsSize()
  end)
  if not okSize or count == nil then
    return 0
  end
  if count == nil or count < 0 then
    return 0
  end
  if count > 512 then
    count = 512
  end

  for i = 0, count - 1, 1 do
    local okObj, pItem = pcall(function() return containerObj:getContainerObject(i) end)
    if pItem ~= nil then
      local okItem, itemObj = pcall(function()
        return LuaSceneObject(pItem)
      end)
      if okItem and itemObj ~= nil and itemObj.getTemplateObjectPath ~= nil then
        local okTemplate, rawTemplate = pcall(function()
          return itemObj:getTemplateObjectPath()
        end)
        local templatePath = self:normalizeTemplatePath(okTemplate and rawTemplate or "")

        if (not self:isContainerTemplate(templatePath)) and self:itemMatchesContract(pItem, itemObj, match) then
          total = total + 1
        end
      end
    end
  end

  return total
end

function ArtisanProcurementVendor:handleTurnIn(pPlayer)
  if pPlayer == nil then
    return false, "I cannot process this delivery right now."
  end

  local contract = self:getCurrentContract()
  if contract == nil then
    return false, "No procurement order is posted at this time. Check back shortly."
  end

  if self:hasCompletedCurrentPhase(pPlayer, contract) then
    return false, "You have reached your delivery limit for this rotation. Return when the next order is posted."
  end

  local pCreature = LuaCreatureObject(pPlayer)
  if pCreature == nil then
    return false, "I cannot inspect your inventory right now."
  end

  local pInventory = pCreature:getSlottedObject("inventory")
  if pInventory == nil then
    return false, "I cannot inspect your inventory right now."
  end

  local requiredTemplate = self:normalizeTemplatePath(contract.template)
  local match = {
    requiredTemplate = requiredTemplate,
    requiredToken = self:getTemplateToken(requiredTemplate)
  }
  local available = self:countItemsInContainer(pInventory, match, {})

  if available < contract.quantity then
    return false, "Delivery incomplete. I need " .. tostring(contract.quantity) .. "x " .. contract.name ..
      " [" .. tostring(contract.schematicCode or "unknown") .. "], and you carry " .. tostring(available) .. ". " ..
      "Craft from the exact schematic code shown in brackets."
  end
  local removed = self:consumeItemsFromContainer(pInventory, match, contract.quantity, {})

  if removed < contract.quantity then
    return false, "The ledger failed to finalize your delivery. Please contact a staff officer."
  end

  CreatureObject(pPlayer):addCashCredits(contract.payout, true)
  self:markCompletedCurrentPhase(pPlayer, contract)

  return true, "Delivery accepted. " .. tostring(contract.quantity) .. "x " .. contract.name .. " received. " ..
    tostring(contract.payout) .. " credits have been transferred to your account."
end

function ArtisanProcurementVendor:broadcastContract(contract)
  local message = "\\#66CCFF[Artisan Procurement]\\#FFFFFF New order posted: " .. tostring(contract.quantity) .. "x " .. contract.name ..
    " [" .. tostring(contract.schematicCode or "unknown") .. "]"
    .. " for " .. tostring(contract.payout) .. " credits. Up to " .. tostring(self.maxContractsPerPhase) .. " deliveries per artisan this rotation."

  local pContext = nil
  local vendorId = readData(self:getContractDataKey("vendorOid"))
  if vendorId ~= nil and vendorId ~= 0 then
    pContext = getSceneObject(vendorId)
  end

  if type(broadcastToGalaxy) == "function" then
    if pcall(broadcastToGalaxy, pContext, message) then
      return
    end
    if pcall(broadcastToGalaxy, nil, message) then
      return
    end
    if pcall(broadcastToGalaxy, message) then
      return
    end
  end

  if type(broadcastGalaxy) == "function" then
    if pcall(broadcastGalaxy, pContext, message) then
      return
    end
    if pcall(broadcastGalaxy, message) then
      return
    end
  end

  if type(galaxyBroadcast) == "function" then
    if pcall(galaxyBroadcast, pContext, message) then
      return
    end
    if pcall(galaxyBroadcast, message) then
      return
    end
  end

  if type(broadcastMessage) == "function" then
    pcall(broadcastMessage, message)
  end
end

function ArtisanProcurementVendor:spawnVendor()
  local pNpc = spawnMobile(
    self.npc.planet,
    self.npc.template,
    0,
    self.npc.x,
    self.npc.y,
    self.npc.z,
    self.npc.heading,
    self.npc.cell
  )

  if pNpc == nil then
    return
  end

  writeData(self:getContractDataKey("vendorOid"), SceneObject(pNpc):getObjectID())

  local ai = AiAgent(pNpc)
  if ai ~= nil then
    ai:setConvoTemplate("artisan_procurement_vendor_conv")
  end

  local co = CreatureObject(pNpc)
  if co ~= nil then
    co:setCustomObjectName(self.npc.customName)
  end
end
