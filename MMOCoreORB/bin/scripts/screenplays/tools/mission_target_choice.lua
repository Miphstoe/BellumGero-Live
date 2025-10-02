-- Mission Target picker UI for Destroy missions.
-- C++ passes us a newline-delimited list of lair templates and also persists:
--   lastList   -> the templates we showed
--   lastPlanet -> planet name when we opened the list
-- We reconstruct from those in the callback so we aren't sensitive to SUI payload quirks.

mission_target_choice = ScreenPlay:new { numberOfActs = 1 }

local function niceLabel(planet, tmpl)
  local label = tmpl or ""
  planet = string.lower(planet or "")
  label = string.gsub(label, "^" .. planet .. "_", "")
  label = string.gsub(label, "_neutral_.*$", "")
  label = string.gsub(label, "_lair", " lair")
  label = string.gsub(label, "_camp", " camp")
  label = string.gsub(label, "_large_boss_01$", "")
  label = string.gsub(label, "_medium_boss_01$", "")
  label = string.gsub(label, "_boss_01$", "")
  label = string.gsub(label, "_", " ")
  label = string.gsub(label, "^%l", string.upper)
  return label
end

local function trim(s)
  if not s then return "" end
  return (string.match(s, "^%s*(.-)%s*$") or s)
end

local function splitLines(s)
  local t = {}
  if not s or s == "" then return t end
  local start = 1
  while true do
    local i, j = string.find(s, "\n", start, true)
    if not i then
      local seg = string.sub(s, start)
      if seg ~= "" then table.insert(t, seg) end
      break
    else
      table.insert(t, string.sub(s, start, i - 1))
      start = j + 1
    end
  end
  return t
end

-- Build choices as {label=..., template=...}, keeping "Reset Target" as row 1
local function rebuildChoices(pPlayer)
  local planet = trim(readScreenPlayData(pPlayer, "mission_target_choice", "lastPlanet"))
  if planet == "" then
    planet = string.lower(SceneObject(pPlayer):getZoneName() or "tatooine")
  else
    planet = string.lower(planet)
  end

  local listString = readScreenPlayData(pPlayer, "mission_target_choice", "lastList") or ""
  local lines = splitLines(listString)

  local seen = {}
  local choices = { { label = "Reset Target", template = "" } } -- row 1
  for _, tmpl in ipairs(lines) do
    tmpl = trim(tmpl)
    if tmpl ~= "" and not seen[tmpl] then
      seen[tmpl] = true
      table.insert(choices, { label = niceLabel(planet, tmpl), template = tmpl })
    end
  end
  return choices
end

function mission_target_choice:start() end

-- Called from C++: openWithList(player, listString, planetName)
function mission_target_choice:openWithList(pPlayer, listString, planet)
  if pPlayer == nil then return end

  -- UI: we just render from the list; we do NOT stash a session copy.
  local choices = rebuildChoices(pPlayer)

  local sui = SuiListBox.new("mission_target_choice", "targetSelection")
  sui.setTargetNetworkId(SceneObject(pPlayer):getObjectID())
  sui.setTitle("Mission Target Selection")
  sui.setPrompt("Pick a specific Destroy-mission target for this terminal.\nSelect 'Reset Target' to return to normal randomization.")

  for i = 1, #choices do
    -- We don't rely on row values; we resolve in the callback robustly.
    sui.add(choices[i].label, "")
  end

  sui.sendTo(pPlayer)
end

function mission_target_choice:targetSelection(pPlayer, pSui, eventIndex, args)
  if pPlayer == nil or eventIndex == 1 then return end -- cancel

  local choices = rebuildChoices(pPlayer) -- rebuild from persisted list

  -- Resolve selection from ANY payload shape:
  --  • number index (0-based),  • numeric string,  • label string,  • template string,  • our old payloads
  local idx1 = nil
  local tpl  = nil

  if type(args) == "number" then
    idx1 = args + 1
  else
    local s = trim(tostring(args or ""))
    local n = tonumber(s)
    if n then
      idx1 = n + 1
    else
      -- Value string; try old payload "IDX:<n>|TPL:<template>"
      local idxMatch = string.match(s, "^IDX:(%d+)")
      local tplMatch = string.match(s, "TPL:(.+)$")
      if idxMatch then idx1 = tonumber(idxMatch) + 1 end
      if tplMatch then tpl = trim(tplMatch) end

      -- If still unknown, try to match by exact label or template
      if not idx1 then
        for i = 1, #choices do
          if trim(choices[i].label) == s or trim(choices[i].template) == s then
            idx1 = i
            break
          end
        end
      end
    end
  end

  if not idx1 or not choices[idx1] then return end
  if idx1 == 1 then
    -- Reset
    writeScreenPlayData(pPlayer, "mission_target_choice", "lairSelect", "")
    writeScreenPlayData(pPlayer, "mission_target_choice", "lairSelectCRC", "")
    writeScreenPlayData(pPlayer, "mission_target_choice", "lairSelectIndex", "")
    CreatureObject(pPlayer):sendSystemMessage("Mission target has been reset to normal randomization.")
    return
  end

  -- Persist exact template (prefer tpl parsed from payload; else from choices[idx1])
  local selectedTemplate = trim(tpl or choices[idx1].template or "")
  if selectedTemplate == "" then return end

  -- Also persist the 0-based index for extra robustness / reconstruction
  local idx0 = idx1 - 1
  writeScreenPlayData(pPlayer, "mission_target_choice", "lairSelectIndex", tostring(idx0))
  writeScreenPlayData(pPlayer, "mission_target_choice", "lairSelectCRC", "")
  writeScreenPlayData(pPlayer, "mission_target_choice", "lairSelect", selectedTemplate)

  CreatureObject(pPlayer):sendSystemMessage(
    "You have selected '" .. trim(choices[idx1].label or "target") .. "' as your Destroy-mission target.")
end