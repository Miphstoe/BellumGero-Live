-- Bellum Gero Token Vendor 3 - Veteran Rewards Screenplay
print("[BG-TOKEN-VENDOR-3] Loading screenplay scripts/screenplays/vendors/bg_token_vendor_3.lua")

BGTokenVendor3 = ScreenPlay:new { numberOfActs = 1 }
registerScreenPlay("BGTokenVendor3", true)

local NPC_CFG = {
  planet = "corellia",
  x = -180, y = 28, z = -4708,
  heading = 180, cell = 0,
  template = "bg_token_vendor_3",   -- MUST match addCreatureTemplate key
  customName = "Bellum Gero Veteran Rewards Vendor"
}

function BGTokenVendor3:start()
  self:spawnVendor()
end

function BGTokenVendor3:spawnVendor()
  print("[BG-TOKEN-VENDOR-3] About to spawn vendor...")
  local pNpc = spawnMobile(NPC_CFG.planet, NPC_CFG.template, 0,
                           NPC_CFG.x, NPC_CFG.y, NPC_CFG.z,
                           NPC_CFG.heading, NPC_CFG.cell)

  if pNpc == nil then
    print("[BG-TOKEN-VENDOR-3][ERROR] spawnMobile returned nil")
    return
  end

  print("[BG-TOKEN-VENDOR-3] NPC spawned, setting conversation...")
  local ai = AiAgent(pNpc)
  if ai then
    ai:setConvoTemplate("bg_token_vendor_3_conv")
    print("[BG-TOKEN-VENDOR-3] Conversation template set to bg_token_vendor_3_conv")
  else
    print("[BG-TOKEN-VENDOR-3] ERROR: Could not get AiAgent")
  end

  local co = CreatureObject(pNpc)
  if co then
    co:setCustomObjectName(NPC_CFG.customName)
    print("[BG-TOKEN-VENDOR-3] Custom name set")
  end

  local so = SceneObject(pNpc)
  if so then
    local CONVERSE = 128
    local bm = nil
    if so.getOptionBitmask then
      bm = so:getOptionBitmask()
      print("[BG-TOKEN-VENDOR-3] Got option bitmask (no s): " .. tostring(bm))
    elseif so.getOptionsBitmask then
      bm = so:getOptionsBitmask()
      print("[BG-TOKEN-VENDOR-3] Got option bitmask (with s): " .. tostring(bm))
    end

    if bm and (bm & CONVERSE) == 0 then
      if so.setOptionBitmask then
        so:setOptionBitmask(bm + CONVERSE)
        print("[BG-TOKEN-VENDOR-3] Set conversable option (no s)")
      elseif so.setOptionsBitmask then
        so:setOptionsBitmask(bm + CONVERSE)
        print("[BG-TOKEN-VENDOR-3] Set conversable option (with s)")
      end
    end
  end

  print(string.format("[BG-TOKEN-VENDOR-3] Spawned vendor at %s (%.1f, %.1f, %.1f)",
    NPC_CFG.planet, NPC_CFG.x, NPC_CFG.y, NPC_CFG.z))
end
