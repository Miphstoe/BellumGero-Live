-- Apprentice Experience Coin Vendor Screenplay
-- NOTE: Vendor spawning is now handled in corellia_static_spawns.lua
print("[APPRENTICE-VENDOR] Loading screenplay scripts/screenplays/vendors/apprentice_coin_vendor.lua")

ApprenticeXpCoinVendor = ScreenPlay:new { numberOfActs = 1 }
registerScreenPlay("ApprenticeXpCoinVendor", true)

function ApprenticeXpCoinVendor:start()
  print("[APPRENTICE-VENDOR] start() called")
end

print("[APPRENTICE-VENDOR] Screenplay loaded successfully")
