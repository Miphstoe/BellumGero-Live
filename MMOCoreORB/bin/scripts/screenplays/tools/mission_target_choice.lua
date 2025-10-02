-- Mission Target picker UI for Destroy missions — uses TARGET names with [CLxxx].
-- Order: preserved from C++ lastList (planet file order), or switch to difficulty sort via SORT_MODE.

mission_target_choice = ScreenPlay:new { numberOfActs = 1 }

-- Change this if you ever want a different sort:
--   "fileOrder"          -> keep the order from lastList (planet file order)  [DEFAULT]
--   "byDifficultyDesc"   -> highest CL first
--   "byDifficultyAsc"    -> lowest CL first
local SORT_MODE = "fileOrder"

-- Target name overrides for special/global entries.
local OVERRIDES_TARGET = {
  ["global_dark_jedi_master"]                 = "Dark Jedi Master",
  ["global_dark_jedi_knight"]                 = "Dark Jedi Knight",
  ["global_dark_jedi_camp_dark_jedi_theater"] = "Dark Jedi Knight",
}

local function trim(s) return (string.match(s or "", "^%s*(.-)%s*$") or "") end

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

-- Extract "template" and optional maxCL from a line ("tmpl|123" or "tmpl\t123" or just "tmpl").
local function parseLine(line)
  line = trim(line)
  if line == "" then return "", 0 end
  local t, n = string.match(line, "^([^|\t]+)[|\t](%d+)$")
  if t then return trim(t), tonumber(n) or 0 end
  return line, 0
end

-- Convert lair template -> TARGET-ONLY label (no camp/lair words).
local function targetLabel(planet, tmpl)
  local raw = trim(tmpl)
  if OVERRIDES_TARGET[raw] then return OVERRIDES_TARGET[raw] end

  local label = raw
  planet = string.lower(planet or "")

  -- strip planet/global prefixes
  label = string.gsub(label, "^" .. planet .. "_", "")
  label = string.gsub(label, "^global_", "")

  -- drop neutral/boss suffix noise
  label = string.gsub(label, "_neutral_.*$", "")
  label = string.gsub(label, "_large_boss_01$", "")
  label = string.gsub(label, "_medium_boss_01$", "")
  label = string.gsub(label, "_boss_01$", "")

  -- Middle markers: keep only prefix before "_camp_" or "_lair_"
  local cut = string.match(label, "^(.-)_camp_") or string.match(label, "^(.-)_lair_")
  if cut and cut ~= "" then label = cut end

  -- Trailing markers: drop exact _camp or _lair
  label = string.gsub(label, "_camp$", "")
  label = string.gsub(label, "_lair$", "")

  label = string.gsub(label, "_", " ")
  label = string.gsub(label, "^%l", string.upper)
  return label
end

-- Build choices from lastList.
-- We preserve the incoming order by default; can optionally sort by CL.
local function rebuildChoices(pPlayer)
  local planet = trim(readScreenPlayData(pPlayer, "mission_target_choice", "lastPlanet"))
  if planet == "" then planet = string.lower(SceneObject(pPlayer):getZoneName() or "tatooine")
  else planet = string.lower(planet) end

  local listString = readScreenPlayData(pPlayer, "mission_target_choice", "lastList") or ""
  local lines = splitLines(listString)

  -- Convert lines to entries preserving order
  local entries = {}  -- { tmpl=..., cl=number, label=... }
  local seen = {}     -- guard against any accidental dupes
  for _, line in ipairs(lines) do
    local tmpl, maxCL = parseLine(line)
    if tmpl ~= "" and not seen[tmpl] then
      seen[tmpl] = true
      local lbl = targetLabel(planet, tmpl)
      table.insert(entries, { tmpl = tmpl, cl = maxCL or 0, label = lbl })
    end
  end

  -- Optional sorting
  if SORT_MODE == "byDifficultyDesc" then
    table.sort(entries, function(a, b)
      if a.cl ~= b.cl then return (a.cl or 0) > (b.cl or 0) end
      return (a.label or "") < (b.label or "")
    end)
  elseif SORT_MODE == "byDifficultyAsc" then
    table.sort(entries, function(a, b)
      if a.cl ~= b.cl then return (a.cl or 0) < (b.cl or 0) end
      return (a.label or "") < (b.label or "")
    end)
  else
    -- fileOrder: do nothing; 'entries' are already in planet file order
  end

  -- Build SUI choices with CL tag if present
  local choices = { { label = "Reset Target", template = "" } } -- row 1
  for _, e in ipairs(entries) do
    local lbl = e.label
    if (e.cl or 0) > 0 then
      lbl = string.format("%s [CL%d]", lbl, e.cl)
    end
    table.insert(choices, { label = lbl, template = e.tmpl })
  end

  return choices
end

function mission_target_choice:start() end

-- Called from C++: openWithList(player, listString, planetName)
function mission_target_choice:openWithList(pPlayer, listString, planet)
  if pPlayer == nil then return end
  local choices = rebuildChoices(pPlayer)

  local sui = SuiListBox.new("mission_target_choice", "targetSelection")
  sui.setTargetNetworkId(SceneObject(pPlayer):getObjectID())
  sui.setTitle("Mission Target Selection")
  sui.setPrompt("Pick a specific Destroy-mission target for this terminal.\nSelect 'Reset Target' to return to normal randomization.")

  for i = 1, #choices do
    sui.add(choices[i].label, "")
  end

  sui.sendTo(pPlayer)
end

function mission_target_choice:targetSelection(pPlayer, pSui, eventIndex, args)
  if pPlayer == nil or eventIndex == 1 then return end

  local choices = rebuildChoices(pPlayer)

  -- Resolve selection from ANY payload shape
  local idx1, tpl = nil, nil
  if type(args) == "number" then
    idx1 = args + 1
  else
    local s = trim(tostring(args or ""))
    local n = tonumber(s)
    if n then
      idx1 = n + 1
    else
      local idxMatch = string.match(s, "^IDX:(%d+)")
      local tplMatch = string.match(s, "TPL:(.+)$")
      if idxMatch then idx1 = tonumber(idxMatch) + 1 end
      if tplMatch then tpl = trim(tplMatch) end
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
    writeScreenPlayData(pPlayer, "mission_target_choice", "lairSelect", "")
    writeScreenPlayData(pPlayer, "mission_target_choice", "lairSelectCRC", "")
    writeScreenPlayData(pPlayer, "mission_target_choice", "lairSelectIndex", "")
    CreatureObject(pPlayer):sendSystemMessage("Mission target has been reset to normal randomization.")
    return
  end

  local selectedTemplate = trim(tpl or choices[idx1].template or "")
  if selectedTemplate == "" then return end

  local idx0 = idx1 - 1
  writeScreenPlayData(pPlayer, "mission_target_choice", "lairSelectIndex", tostring(idx0))
  writeScreenPlayData(pPlayer, "mission_target_choice", "lairSelectCRC", "")
  writeScreenPlayData(pPlayer, "mission_target_choice", "lairSelect", selectedTemplate)

  CreatureObject(pPlayer):sendSystemMessage(
    "You have selected '" .. trim(choices[idx1].label or "target") .. "' as your Destroy-mission target.")
end