-- Simple pool you can maintain by hand (or auto-generate later)
BOSS_PLAYER_NAME_POOL = {
  "Humdinger", "Hellguard", "Slug", "Mafo", "Adan", "Pastorius", "Udon", "Vinzent", "Valmor", "Cas-Wan", "GrumpyOptimism", "Chyna", "EnderWookie","Chuckertons",
  -- add as many as you like...
}

-- seed once per process
if not _G.__BOSS_NAME_SEEDED then
  math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,9)))
  _G.__BOSS_NAME_SEEDED = true
end

function randomBossName()
  local pool = BOSS_PLAYER_NAME_POOL
  if type(pool) ~= "table" or #pool == 0 then
    return "Nameless Terror"
  end
  return pool[math.random(#pool)]
end
