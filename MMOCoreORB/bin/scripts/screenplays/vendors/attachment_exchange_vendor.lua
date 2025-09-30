print("[ATTACH-EXCH] loading screenplay scripts/screenplays/vendors/attachment_exchange_vendor.lua")

AttachmentExchangeVendor = ScreenPlay:new { numberOfActs = 1 }
registerScreenPlay("AttachmentExchangeVendor", true)

local NPC_CFG = {
  planet = "corellia",
  x = -140.0, y = 28.0, z = -4727.0,
  heading = 180, cell = 0,
  template = "attachment_exchange_vendor",   -- MUST match addCreatureTemplate key
  customName = "Attachment Exchange Vendor"
}

function AttachmentExchangeVendor:start()
  self:spawnVendor()
end

function AttachmentExchangeVendor:spawnVendor()
  print("[DEBUG] About to spawn vendor...")
  local pNpc = spawnMobile(NPC_CFG.planet, NPC_CFG.template, 0,
                           NPC_CFG.x, NPC_CFG.y, NPC_CFG.z,
                           NPC_CFG.heading, NPC_CFG.cell)
 
  if pNpc == nil then
    print("[ATTACH-EXCH][ERROR] spawnMobile returned nil")
    return
  end
 
  print("[DEBUG] NPC spawned, setting conversation...")
  local ai = AiAgent(pNpc)
  if ai then
    --ai:setConvoTemplate("sea_attachment_vendor_conv")
    print("[DEBUG] Conversation template set to sea_attachment_vendor_conv")
  else
    print("[DEBUG] ERROR: Could not get AiAgent")
  end
 
  local co = CreatureObject(pNpc)
  if co then 
    co:setCustomObjectName(NPC_CFG.customName)
    print("[DEBUG] Custom name set")
  end
  
  local so = SceneObject(pNpc)
  if so then
    local CONVERSE = 128
    -- Try both method names to be compatible with different server versions
    local bm = nil
    if so.getOptionBitmask then
      bm = so:getOptionBitmask()  -- Without 's'
      print("[DEBUG] Got option bitmask (no s): " .. tostring(bm))
    elseif so.getOptionsBitmask then
      bm = so:getOptionsBitmask() -- With 's'
      print("[DEBUG] Got option bitmask (with s): " .. tostring(bm))
    end
    
    if bm and (bm & CONVERSE) == 0 then
      if so.setOptionBitmask then
        so:setOptionBitmask(bm + CONVERSE)
        print("[DEBUG] Set conversable option (no s)")
      elseif so.setOptionsBitmask then
        so:setOptionsBitmask(bm + CONVERSE)
        print("[DEBUG] Set conversable option (with s)")
      end
    end
  end
 
  print(string.format("[ATTACH-EXCH] Spawned vendor at %s (%.1f, %.1f, %.1f)",
    NPC_CFG.planet, NPC_CFG.x, NPC_CFG.y, NPC_CFG.z))
end