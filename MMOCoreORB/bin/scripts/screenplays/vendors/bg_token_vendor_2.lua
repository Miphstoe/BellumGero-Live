-- Bellum Gero Token Vendor 2 Screenplay
print("[BG-TOKEN-VENDOR-2] Loading screenplay scripts/screenplays/vendors/bg_token_vendor_2.lua")

BGTokenVendor2 = ScreenPlay:new { numberOfActs = 1 }
registerScreenPlay("BGTokenVendor2", true)

local NPC_CFG = {
  planet = "corellia",
  x = -142.0, y = 28.0, z = -4725.0,
  heading = 180, cell = 0,
  template = "bg_token_vendor_2",   -- MUST match addCreatureTemplate key
  customName = "Bellum Gero Token Vendor 2"
}

function BGTokenVendor2:start()
  self:spawnVendor()
end

function BGTokenVendor2:spawnVendor()
  print("[BG-TOKEN-VENDOR-2] About to spawn vendor...")
  local pNpc = spawnMobile(NPC_CFG.planet, NPC_CFG.template, 0,
                           NPC_CFG.x, NPC_CFG.y, NPC_CFG.z,
                           NPC_CFG.heading, NPC_CFG.cell)

  if pNpc == nil then
    print("[BG-TOKEN-VENDOR-2][ERROR] spawnMobile returned nil")
    return
  end

  print("[BG-TOKEN-VENDOR-2] NPC spawned, setting conversation...")
  local ai = AiAgent(pNpc)
  if ai then
    ai:setConvoTemplate("bg_token_vendor_2_conv")
    print("[BG-TOKEN-VENDOR-2] Conversation template set to bg_token_vendor_2_conv")
  else
    print("[BG-TOKEN-VENDOR-2] ERROR: Could not get AiAgent")
  end

  local co = CreatureObject(pNpc)
  if co then
    co:setCustomObjectName(NPC_CFG.customName)
    print("[BG-TOKEN-VENDOR-2] Custom name set")
  end

  local so = SceneObject(pNpc)
  if so then
    local CONVERSE = 128
    local bm = nil
    if so.getOptionBitmask then
      bm = so:getOptionBitmask()
      print("[BG-TOKEN-VENDOR-2] Got option bitmask (no s): " .. tostring(bm))
    elseif so.getOptionsBitmask then
      bm = so:getOptionsBitmask()
      print("[BG-TOKEN-VENDOR-2] Got option bitmask (with s): " .. tostring(bm))
    end

    if bm and (bm & CONVERSE) == 0 then
      if so.setOptionBitmask then
        so:setOptionBitmask(bm + CONVERSE)
        print("[BG-TOKEN-VENDOR-2] Set conversable option (no s)")
      elseif so.setOptionsBitmask then
        so:setOptionsBitmask(bm + CONVERSE)
        print("[BG-TOKEN-VENDOR-2] Set conversable option (with s)")
      end
    end
  end

  print(string.format("[BG-TOKEN-VENDOR-2] Spawned vendor at %s (%.1f, %.1f, %.1f)",
    NPC_CFG.planet, NPC_CFG.x, NPC_CFG.y, NPC_CFG.z))
end
