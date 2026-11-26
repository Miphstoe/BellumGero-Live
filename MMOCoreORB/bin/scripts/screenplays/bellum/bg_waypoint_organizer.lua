--[[
    Bellum Gero - Waypoint Organizer  (/waypoint organize)

    Player QoL: browse / search / categorize / favorite / rename / bulk-manage the
    player's OWN waypoints through stock SUI list and input boxes (no client TRE change).

    Architecture
      * C++ WaypointCommand ("organize" argument) -> waypointOrganizerRun(pPlayer) (this file).
      * PlayerObject:getWaypointOrganizerData() (C++) returns a fresh read-only snapshot
        of the player's waypoint list. Every mutation re-reads this snapshot and works
        only on waypoint object IDs found in it, so ownership/existence is revalidated
        server-side at execution time. SUI row indexes are never trusted on their own.
      * IMPORTANT: SWGEmu runs scripts in several Lua states, so NO Lua memory (tables,
        closures) may be shared between the command and the SUI callbacks. All state is
        kept in the player's screenplay data (nonce, window generation, selection basket)
        and in each SUI page's stored data (one "action string" per row/button).
        Action strings look like "name|arg|arg" and are executed by BgWaypointOrganizer:dispatch.
      * Mutations reuse existing engine paths (PlayerObject:removeWaypoint,
        updateWaypoint, SceneObject:setCustomObjectName).
      * Organizer metadata lives in screenplay data (persisted with the character):
          catlist            "c1,c4,c7"   custom category ids
          catnext            next custom category number (never reused)
          catname_<cid>      custom category name
          cat_<wpid>         category id assigned to waypoint (d1..d10 / c<n>)
          fav_<wpid>         "1" when favorite
          wpmeta             "id,id,..." index of waypoints holding metadata (orphan pruning)
          basket             "id,id,..." bulk selection
          nonce / gen        current window validation (stale/duplicate window protection)
          pagesize           page size setting
]]--

BgWaypointOrganizer = ScreenPlay:new {
	numberOfActs = 1,
	screenplayName = "BgWaypointOrganizer",
}

registerScreenPlay("BgWaypointOrganizer", true)

local SP = "BgWaypointOrganizer"

local MAX_CUSTOM_CATEGORIES = 25
local MAX_CATEGORY_NAME = 24
local MAX_WAYPOINT_NAME = 150 -- same limit as the stock /setwaypointname command
local DEFAULT_PAGE_SIZE = 20
local MAX_BASKET = 600

local SPECIAL_QUESTTASK = 11
local SPECIAL_RANGERTRACK = 12
local SPECIAL_RESOURCE = 6

local DEFAULT_CATEGORIES = {
	{ id = "d1", name = "General" },
	{ id = "d2", name = "Hunting" },
	{ id = "d3", name = "Resources" },
	{ id = "d4", name = "Vendors" },
	{ id = "d5", name = "Player Cities" },
	{ id = "d6", name = "Housing" },
	{ id = "d7", name = "Missions" },
	{ id = "d8", name = "Dungeons" },
	{ id = "d9", name = "Points of Interest" },
	{ id = "d10", name = "Events" },
}

------------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------------

local function trim(value)
	if value == nil then
		return ""
	end
	return (tostring(value):gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Strip control chars, SUI/markup-significant chars and our action separator, collapse whitespace.
local function sanitizeName(value, maxLen)
	local s = trim(value)
	s = s:gsub("[%c]", " ")
	s = s:gsub("[<>\\|]", "")
	s = s:gsub("%s+", " ")
	s = trim(s)
	if #s > maxLen then
		s = trim(s:sub(1, maxLen))
	end
	return s
end

local function capitalize(s)
	if s == nil or s == "" then
		return "Unknown"
	end
	return s:sub(1, 1):upper() .. s:sub(2)
end

local function oidOf(pPlayer)
	return SceneObject(pPlayer):getObjectID()
end

local function getGhost(pPlayer)
	if pPlayer == nil then
		return nil
	end
	return CreatureObject(pPlayer):getPlayerObject()
end

local function readKey(pPlayer, key)
	local v = readScreenPlayData(pPlayer, SP, key)
	if v == nil or v == "" then
		return nil
	end
	return tostring(v)
end

local function writeKey(pPlayer, key, value)
	writeScreenPlayData(pPlayer, SP, key, tostring(value))
end

local function deleteKey(pPlayer, key)
	deleteScreenPlayData(pPlayer, SP, key)
end

local function splitCsv(s)
	local out = {}
	if s == nil then
		return out
	end
	for token in string.gmatch(s, "[^,]+") do
		out[#out + 1] = token
	end
	return out
end

-- Split on "|" keeping empty fields.
local function splitAction(s)
	local out = {}
	local pos = 1
	while true do
		local i = string.find(s, "|", pos, true)
		if i == nil then
			out[#out + 1] = string.sub(s, pos)
			break
		end
		out[#out + 1] = string.sub(s, pos, i - 1)
		pos = i + 1
	end
	return out
end

local function join(...)
	local t = { ... }
	for i = 1, #t do
		t[i] = tostring(t[i])
	end
	return table.concat(t, "|")
end

local function makeFilter(kind, value)
	return { kind = kind or "all", value = value or "" }
end

-- Filter + page travel through action strings as three fields: kind|value|page
local function ctxTail(kind, value, page)
	return join(kind, value, page)
end

------------------------------------------------------------------------------
-- Session (screenplay data only)
------------------------------------------------------------------------------

function BgWaypointOrganizer:newSession(pPlayer)
	local nonce = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
	writeKey(pPlayer, "nonce", nonce)
	writeKey(pPlayer, "gen", "0")
end

function BgWaypointOrganizer:endSession(pPlayer)
	deleteKey(pPlayer, "nonce")
	deleteKey(pPlayer, "gen")
	deleteKey(pPlayer, "basket")
end

-- Bump the window generation; returns nonce, gen (both strings) to store into the SUI page.
function BgWaypointOrganizer:nextWindow(pPlayer)
	local nonce = readKey(pPlayer, "nonce")
	if nonce == nil then
		return nil
	end
	local gen = (tonumber(readKey(pPlayer, "gen") or "0") or 0) + 1
	writeKey(pPlayer, "gen", tostring(gen))
	return nonce, tostring(gen)
end

-- Returns the page data accessor only if this SUI window is the live one.
function BgWaypointOrganizer:validate(pPlayer, pSui)
	if pPlayer == nil or pSui == nil then
		return nil
	end
	local nonce, gen = readKey(pPlayer, "nonce"), readKey(pPlayer, "gen")
	if nonce == nil or gen == nil then
		return nil
	end
	local pPageData = LuaSuiBoxPage(pSui):getSuiPageData()
	if pPageData == nil then
		return nil
	end
	local pageData = LuaSuiPageData(pPageData)
	if tostring(pageData:getStoredData("nonce")) ~= nonce or tostring(pageData:getStoredData("gen")) ~= gen then
		return nil
	end
	return pageData
end

-- Selection basket
function BgWaypointOrganizer:getBasket(pPlayer)
	local set = {}
	for _, id in ipairs(splitCsv(readKey(pPlayer, "basket"))) do
		set[id] = true
	end
	return set
end

function BgWaypointOrganizer:saveBasket(pPlayer, set)
	local ids = {}
	for id, _ in pairs(set) do
		ids[#ids + 1] = id
		if #ids >= MAX_BASKET then
			break
		end
	end
	if #ids == 0 then
		deleteKey(pPlayer, "basket")
	else
		writeKey(pPlayer, "basket", table.concat(ids, ","))
	end
end

------------------------------------------------------------------------------
-- Data layer: snapshot + metadata
------------------------------------------------------------------------------

function BgWaypointOrganizer:snapshot(pPlayer)
	local pGhost = getGhost(pPlayer)
	if pGhost == nil then
		return {}, {}
	end
	local raw = PlayerObject(pGhost):getWaypointOrganizerData()
	local list, byId = {}, {}
	if raw == nil then
		return list, byId
	end
	for i = 1, #raw do
		local w = raw[i]
		if w ~= nil and w.id ~= nil then
			w.name = (w.name ~= nil and w.name ~= "") and w.name or "(unnamed)"
			w.planetName = capitalize(w.planet)
			w.temporary = (w.special == SPECIAL_RANGERTRACK)
			-- Read-only: system-controlled waypoints whose lifecycle belongs to another system.
			w.protected = (w.mission == true) or (w.special == SPECIAL_QUESTTASK) or (w.special == SPECIAL_RANGERTRACK)
			list[#list + 1] = w
			byId[tostring(w.id)] = w
		end
	end
	return list, byId
end

function BgWaypointOrganizer:getCategories(pPlayer)
	local cats = {}
	for _, c in ipairs(DEFAULT_CATEGORIES) do
		cats[#cats + 1] = { id = c.id, name = c.name, default = true }
	end
	for _, cid in ipairs(splitCsv(readKey(pPlayer, "catlist"))) do
		local name = readKey(pPlayer, "catname_" .. cid)
		if name ~= nil then
			cats[#cats + 1] = { id = cid, name = name, default = false }
		end
	end
	return cats
end

function BgWaypointOrganizer:categoryMap(pPlayer)
	local map = {}
	for _, c in ipairs(self:getCategories(pPlayer)) do
		map[c.id] = c
	end
	return map
end

-- Effective category: explicit assignment (if the category still exists), else reliable
-- source detection (mission / survey resource), else General.
function BgWaypointOrganizer:categoryOf(pPlayer, w, catMap)
	local assigned = readKey(pPlayer, "cat_" .. tostring(w.id))
	if assigned ~= nil and catMap[assigned] ~= nil then
		return assigned
	end
	if w.mission then
		return "d7"
	end
	if w.special == SPECIAL_RESOURCE then
		return "d3"
	end
	return "d1"
end

function BgWaypointOrganizer:isFavorite(pPlayer, w)
	return readKey(pPlayer, "fav_" .. tostring(w.id)) == "1"
end

local function addToMeta(pPlayer, wpId)
	local list = splitCsv(readKey(pPlayer, "wpmeta"))
	local s = tostring(wpId)
	for _, v in ipairs(list) do
		if v == s then
			return
		end
	end
	list[#list + 1] = s
	writeKey(pPlayer, "wpmeta", table.concat(list, ","))
end

function BgWaypointOrganizer:clearMeta(pPlayer, wpId)
	local s = tostring(wpId)
	deleteKey(pPlayer, "cat_" .. s)
	deleteKey(pPlayer, "fav_" .. s)
	local keep = {}
	for _, v in ipairs(splitCsv(readKey(pPlayer, "wpmeta"))) do
		if v ~= s then
			keep[#keep + 1] = v
		end
	end
	if #keep == 0 then
		deleteKey(pPlayer, "wpmeta")
	else
		writeKey(pPlayer, "wpmeta", table.concat(keep, ","))
	end
end

function BgWaypointOrganizer:pruneOrphans(pPlayer, byId)
	for _, v in ipairs(splitCsv(readKey(pPlayer, "wpmeta"))) do
		if byId[v] == nil then
			self:clearMeta(pPlayer, v)
		end
	end
end

function BgWaypointOrganizer:setFavorite(pPlayer, w, value)
	if value then
		writeKey(pPlayer, "fav_" .. tostring(w.id), "1")
		addToMeta(pPlayer, w.id)
	else
		deleteKey(pPlayer, "fav_" .. tostring(w.id))
	end
end

function BgWaypointOrganizer:setCategory(pPlayer, w, cid)
	if cid == "d1" then
		deleteKey(pPlayer, "cat_" .. tostring(w.id))
	else
		writeKey(pPlayer, "cat_" .. tostring(w.id), cid)
		addToMeta(pPlayer, w.id)
	end
end

function BgWaypointOrganizer:getPageSize(pPlayer)
	local n = tonumber(readKey(pPlayer, "pagesize") or "")
	if n == nil or n < 5 or n > 40 then
		return DEFAULT_PAGE_SIZE
	end
	return math.floor(n)
end

------------------------------------------------------------------------------
-- SUI plumbing. Every button/row carries an action string in the page's stored data.
------------------------------------------------------------------------------

-- rows: array of { label=, act= }. back: action string or nil.
function BgWaypointOrganizer:showList(pPlayer, title, prompt, rows, back, okText)
	local nonce, gen = self:nextWindow(pPlayer)
	if nonce == nil then
		return
	end

	local sui = SuiListBox.new(SP, "listCallback")
	sui.setTargetNetworkId(oidOf(pPlayer))
	sui.setTitle("Bellum Gero - " .. title)
	sui.setPrompt(prompt)
	for i, r in ipairs(rows) do
		sui.add(r.label, "")
		sui.setStoredData("r" .. i, r.act)
	end
	sui.setOkButtonText(okText or "Select")
	sui.setCancelButtonText("Close")
	if back ~= nil then
		sui.showOtherButton()
		sui.setOtherButtonText("Back")
		sui.setStoredData("back", back)
	end
	sui.setStoredData("nonce", nonce)
	sui.setStoredData("gen", gen)
	sui.sendTo(pPlayer)
end

function BgWaypointOrganizer:listCallback(pPlayer, pSui, eventIndex, rowIndex, otherPressed)
	local pageData = self:validate(pPlayer, pSui)
	if pageData == nil then
		return
	end

	if otherPressed == "true" then
		local back = pageData:getStoredData("back")
		if back ~= nil and back ~= "" then
			self:dispatch(pPlayer, back)
		end
		return
	end

	if eventIndex == 1 then
		self:endSession(pPlayer)
		return
	end

	local idx = tonumber(rowIndex)
	if idx == nil then
		self:showMain(pPlayer, "Invalid selection.")
		return
	end

	local act = pageData:getStoredData("r" .. tostring(math.floor(idx) + 1))
	if act == nil or act == "" then
		self:showMain(pPlayer, "That entry is no longer available.")
		return
	end

	self:dispatch(pPlayer, act)
end

-- ok: action string run with the typed text as extra argument. back: action string.
function BgWaypointOrganizer:showInput(pPlayer, title, prompt, initial, maxLen, ok, back)
	local nonce, gen = self:nextWindow(pPlayer)
	if nonce == nil then
		return
	end

	local sui = SuiInputBox.new(SP, "inputCallback")
	sui.setTargetNetworkId(oidOf(pPlayer))
	sui.setTitle("Bellum Gero - " .. title)
	sui.setPrompt(prompt)
	sui.setOkButtonText("OK")
	sui.setCancelButtonText("Back")
	sui.setProperty("txtInput", "MaxLength", tostring(maxLen))
	if initial ~= nil and initial ~= "" then
		sui.setProperty("txtInput", "Text", initial)
	end
	sui.setStoredData("ok", ok)
	sui.setStoredData("back", back)
	sui.setStoredData("nonce", nonce)
	sui.setStoredData("gen", gen)
	sui.sendTo(pPlayer)
end

function BgWaypointOrganizer:inputCallback(pPlayer, pSui, eventIndex, args)
	local pageData = self:validate(pPlayer, pSui)
	if pageData == nil then
		return
	end

	if eventIndex == 1 then
		local back = pageData:getStoredData("back")
		if back ~= nil and back ~= "" then
			self:dispatch(pPlayer, back)
		else
			self:showMain(pPlayer)
		end
		return
	end

	local ok = pageData:getStoredData("ok")
	if ok ~= nil and ok ~= "" then
		self:dispatch(pPlayer, ok, args)
	end
end

-- Only an explicit OK confirms. Closing/cancelling NEVER performs the action.
function BgWaypointOrganizer:showConfirm(pPlayer, title, prompt, confirmText, ok, cancel)
	local nonce, gen = self:nextWindow(pPlayer)
	if nonce == nil then
		return
	end

	local sui = SuiMessageBox.new(SP, "confirmCallback")
	sui.setTargetNetworkId(oidOf(pPlayer))
	sui.setTitle("Bellum Gero - " .. title)
	sui.setPrompt(prompt)
	sui.setOkButtonText(confirmText)
	sui.setCancelButtonText("Cancel")
	sui.setStoredData("ok", ok)
	sui.setStoredData("cancel", cancel)
	sui.setStoredData("nonce", nonce)
	sui.setStoredData("gen", gen)
	sui.sendTo(pPlayer)
end

function BgWaypointOrganizer:confirmCallback(pPlayer, pSui, eventIndex, args)
	local pageData = self:validate(pPlayer, pSui)
	if pageData == nil then
		return
	end

	local ok = pageData:getStoredData("ok")
	local cancel = pageData:getStoredData("cancel")

	-- Invalidate this window first so a duplicate confirm can never run twice.
	self:nextWindow(pPlayer)

	if eventIndex == 1 then
		if cancel ~= nil and cancel ~= "" then
			self:dispatch(pPlayer, cancel)
		end
		return
	end

	if ok ~= nil and ok ~= "" then
		self:dispatch(pPlayer, ok)
	end
end

function BgWaypointOrganizer:showNotice(pPlayer, title, text, done)
	local nonce, gen = self:nextWindow(pPlayer)
	if nonce == nil then
		return
	end

	local sui = SuiMessageBox.new(SP, "noticeCallback")
	sui.setTargetNetworkId(oidOf(pPlayer))
	sui.setTitle("Bellum Gero - " .. title)
	sui.setPrompt(text)
	sui.setOkButtonText("OK")
	sui.hideCancelButton()
	sui.setStoredData("done", done or "main")
	sui.setStoredData("nonce", nonce)
	sui.setStoredData("gen", gen)
	sui.sendTo(pPlayer)
end

function BgWaypointOrganizer:noticeCallback(pPlayer, pSui, eventIndex, args)
	local pageData = self:validate(pPlayer, pSui)
	if pageData == nil then
		return
	end
	local done = pageData:getStoredData("done")
	if done == nil or done == "" then
		done = "main"
	end
	self:dispatch(pPlayer, done)
end

------------------------------------------------------------------------------
-- Dispatcher: action string -> screen/operation
------------------------------------------------------------------------------

function BgWaypointOrganizer:dispatch(pPlayer, action, extra)
	if pPlayer == nil or action == nil or action == "" then
		return
	end

	local f = splitAction(action)
	local name = f[1]

	if name == "main" then
		self:showMain(pPlayer, f[2])
	elseif name == "wps" then
		self:showWaypoints(pPlayer, makeFilter(f[2], f[3]), tonumber(f[4]) or 1)
	elseif name == "planets" then
		self:showPlanets(pPlayer)
	elseif name == "catbrowse" then
		self:showCategoryBrowse(pPlayer)
	elseif name == "search" then
		self:showSearch(pPlayer, f[2])
	elseif name == "searchok" then
		local text = sanitizeName(extra, 60)
		if text == "" then
			self:showSearch(pPlayer, "Please enter some text to search for.")
		else
			self:showWaypoints(pPlayer, makeFilter("search", text), 1)
		end
	elseif name == "bulk" then
		self:showBulk(pPlayer, f[2])
	elseif name == "catmanage" then
		self:showCategoryManage(pPlayer, f[2])
	elseif name == "settings" then
		self:showSettings(pPlayer, f[2])
	elseif name == "setpage" then
		local n = math.floor(tonumber(f[2]) or DEFAULT_PAGE_SIZE)
		writeKey(pPlayer, "pagesize", tostring(n))
		self:showSettings(pPlayer, "Page size set to " .. tostring(n) .. ".")
	elseif name == "detail" then
		-- detail|wpid|kind|value|page|message
		self:showDetail(pPlayer, f[2], makeFilter(f[3], f[4]), tonumber(f[5]) or 1, f[6])
	elseif name == "fav" then
		self:doFavorite(pPlayer, f)
	elseif name == "sel" then
		self:doSelect(pPlayer, f)
	elseif name == "selpage" or name == "selall" then
		self:doSelectMany(pPlayer, f, name == "selall")
	elseif name == "assign" then
		-- assign|wpid|kind|value|page
		self:showAssignCategory(pPlayer, "single", f[2], makeFilter(f[3], f[4]), tonumber(f[5]) or 1)
	elseif name == "setcat" then
		self:doSetCategory(pPlayer, f)
	elseif name == "toggle" then
		-- toggle|wpid|0or1|kind|value|page
		local ok, why = self:applyActive(pPlayer, f[2], f[3] == "1")
		self:showDetail(pPlayer, f[2], makeFilter(f[4], f[5]), tonumber(f[6]) or 1, ok and "Waypoint updated." or why)
	elseif name == "rename" then
		self:showRename(pPlayer, f[2], makeFilter(f[3], f[4]), tonumber(f[5]) or 1, nil)
	elseif name == "renameok" then
		self:doRename(pPlayer, f, extra)
	elseif name == "delask" then
		self:askDelete(pPlayer, f)
	elseif name == "delok" then
		local ok, why = self:applyDelete(pPlayer, f[2])
		self:showNotice(pPlayer, "Delete Waypoint", ok and "Waypoint deleted." or why, join("wps", f[3], f[4], f[5]))
	elseif name == "bulkrun" then
		self:bulkRun(pPlayer, f[2])
	elseif name == "bulkexec" then
		self:bulkExecute(pPlayer, f[2])
	elseif name == "bulkclear" then
		self:saveBasket(pPlayer, {})
		self:showBulk(pPlayer, "Selection cleared.")
	elseif name == "catnew" then
		self:showCreateCategory(pPlayer, f[2])
	elseif name == "catcreate" then
		self:doCreateCategory(pPlayer, extra)
	elseif name == "catopt" then
		self:showCategoryOptions(pPlayer, f[2])
	elseif name == "catren" then
		self:showRenameCategory(pPlayer, f[2], f[3])
	elseif name == "catrenok" then
		self:doRenameCategory(pPlayer, f[2], extra)
	elseif name == "catpick" then
		self:showCategoryPick(pPlayer, f[2], tonumber(f[3]) or 1, f[4])
	elseif name == "catpickset" then
		self:doCategoryPick(pPlayer, f)
	elseif name == "catdelask" then
		self:askDeleteCategory(pPlayer, f[2])
	elseif name == "catdelok" then
		self:deleteCategory(pPlayer, f[2])
	else
		self:showMain(pPlayer, "Unknown action.")
	end
end

------------------------------------------------------------------------------
-- Entry + main menu
------------------------------------------------------------------------------

function BgWaypointOrganizer:start(pPlayer)
	if pPlayer == nil then
		return
	end

	if not SceneObject(pPlayer):isPlayerCreature() or getGhost(pPlayer) == nil then
		return
	end

	-- Re-running the command starts a new session: any older window becomes inert.
	self:newSession(pPlayer)
	self:showMain(pPlayer)
end

function BgWaypointOrganizer:showMain(pPlayer, message)
	local list, byId = self:snapshot(pPlayer)
	self:pruneOrphans(pPlayer, byId)

	local active, favs = 0, 0
	for _, w in ipairs(list) do
		if w.active then
			active = active + 1
		end
		if self:isFavorite(pPlayer, w) then
			favs = favs + 1
		end
	end

	local basket = self:getBasket(pPlayer)
	local basketCount = 0
	for id, _ in pairs(basket) do
		if byId[id] == nil then
			basket[id] = nil
		else
			basketCount = basketCount + 1
		end
	end
	self:saveBasket(pPlayer, basket)

	local prompt = "WAYPOINT ORGANIZER\n\n" ..
		"Your Waypoints: " .. #list .. "\n" ..
		"Active Waypoints: " .. active .. "\n" ..
		"Favorite Waypoints: " .. favs .. "\n" ..
		"Selected for bulk actions: " .. basketCount
	if message ~= nil and message ~= "" then
		prompt = prompt .. "\n\n" .. message
	end

	local rows = {
		{ label = "Browse All Waypoints", act = "wps|all||1" },
		{ label = "Browse by Planet", act = "planets" },
		{ label = "Browse by Category", act = "catbrowse" },
		{ label = "Search Waypoints", act = "search" },
		{ label = "Favorite Waypoints", act = "wps|fav||1" },
		{ label = "Bulk Management (" .. basketCount .. " selected)", act = "bulk" },
		{ label = "Manage Categories", act = "catmanage" },
		{ label = "Organizer Settings", act = "settings" },
	}

	self:showList(pPlayer, "Waypoint Organizer", prompt, rows, nil, "Open")
end

------------------------------------------------------------------------------
-- Filtering / waypoint lists
------------------------------------------------------------------------------

function BgWaypointOrganizer:filterTitle(filter, pPlayer)
	if filter.kind == "planet" then
		return "Planet: " .. capitalize(filter.value)
	elseif filter.kind == "cat" then
		local c = self:categoryMap(pPlayer)[filter.value]
		return "Category: " .. (c and c.name or "General")
	elseif filter.kind == "fav" then
		return "Favorites"
	elseif filter.kind == "search" then
		return "Search: " .. tostring(filter.value)
	elseif filter.kind == "basket" then
		return "Selected Waypoints"
	end
	return "All Waypoints"
end

function BgWaypointOrganizer:applyFilter(pPlayer, filter, list)
	local out = {}
	local catMap = nil
	local basket = nil
	local needle = nil
	if filter.kind == "cat" then
		catMap = self:categoryMap(pPlayer)
	elseif filter.kind == "basket" then
		basket = self:getBasket(pPlayer)
	elseif filter.kind == "search" then
		needle = string.lower(filter.value)
	end

	for _, w in ipairs(list) do
		local keep = true
		if filter.kind == "planet" then
			keep = (w.planet == filter.value)
		elseif filter.kind == "cat" then
			keep = (self:categoryOf(pPlayer, w, catMap) == filter.value)
		elseif filter.kind == "fav" then
			keep = self:isFavorite(pPlayer, w)
		elseif filter.kind == "search" then
			-- plain-text find: player text is never treated as a Lua pattern
			keep = (string.find(string.lower(w.name), needle, 1, true) ~= nil)
		elseif filter.kind == "basket" then
			keep = (basket[tostring(w.id)] ~= nil)
		end
		if keep then
			out[#out + 1] = w
		end
	end

	table.sort(out, function(a, b)
		local an, bn = string.lower(a.name), string.lower(b.name)
		if an == bn then
			return a.id < b.id
		end
		return an < bn
	end)
	return out
end

function BgWaypointOrganizer:describe(pPlayer, basket, w, showPlanet)
	local flags = ""
	if basket[tostring(w.id)] ~= nil then
		flags = flags .. "[x] "
	end
	if self:isFavorite(pPlayer, w) then
		flags = flags .. "[F] "
	end
	local label = flags .. w.name
	if showPlanet then
		label = label .. " - " .. w.planetName
	end
	if not w.active then
		label = label .. " (off)"
	end
	if w.temporary then
		label = label .. " (temporary)"
	elseif w.protected then
		label = label .. " (locked)"
	end
	return label
end

function BgWaypointOrganizer:showWaypoints(pPlayer, filter, page)
	local all = self:snapshot(pPlayer)
	local list = self:applyFilter(pPlayer, filter, all)
	local basket = self:getBasket(pPlayer)
	local pageSize = self:getPageSize(pPlayer)
	local pages = math.max(1, math.ceil(#list / pageSize))
	if page < 1 then page = 1 end
	if page > pages then page = pages end

	local first = (page - 1) * pageSize + 1
	local last = math.min(#list, first + pageSize - 1)

	local back = "main"
	if filter.kind == "planet" then
		back = "planets"
	elseif filter.kind == "cat" then
		back = "catbrowse"
	elseif filter.kind == "basket" then
		back = "bulk"
	end

	local prompt = self:filterTitle(filter, pPlayer) .. "\n" ..
		#list .. " waypoint(s) - page " .. page .. " of " .. pages ..
		"\n[x] selected  [F] favorite  (off) inactive  (locked/temporary) managed by another system"

	if #list == 0 then
		if filter.kind == "search" then
			prompt = prompt .. "\n\nNo waypoints matched your search."
		else
			prompt = prompt .. "\n\nNo waypoints here."
		end
	end

	local rows = {}
	for i = first, last do
		local w = list[i]
		rows[#rows + 1] = {
			label = self:describe(pPlayer, basket, w, filter.kind ~= "planet"),
			act = join("detail", w.id, filter.kind, filter.value, page, ""),
		}
	end

	if #list > 0 then
		rows[#rows + 1] = { label = "> Select all on this page", act = join("selpage", filter.kind, filter.value, page) }
		rows[#rows + 1] = { label = "> Select all " .. #list .. " matching waypoints", act = join("selall", filter.kind, filter.value, page) }
	end
	if page > 1 then
		rows[#rows + 1] = { label = "<< Previous Page", act = join("wps", filter.kind, filter.value, page - 1) }
	end
	if page < pages then
		rows[#rows + 1] = { label = "Next Page >>", act = join("wps", filter.kind, filter.value, page + 1) }
	end

	self:showList(pPlayer, self:filterTitle(filter, pPlayer), prompt, rows, back, "Open")
end

-- selpage|kind|value|page   /   selall|kind|value|page
function BgWaypointOrganizer:doSelectMany(pPlayer, f, everything)
	local filter = makeFilter(f[2], f[3])
	local page = tonumber(f[4]) or 1
	local list = self:applyFilter(pPlayer, filter, (self:snapshot(pPlayer)))
	local basket = self:getBasket(pPlayer)

	local first, last = 1, #list
	if not everything then
		local pageSize = self:getPageSize(pPlayer)
		first = (page - 1) * pageSize + 1
		last = math.min(#list, first + pageSize - 1)
	end

	for i = first, last do
		basket[tostring(list[i].id)] = true
	end
	self:saveBasket(pPlayer, basket)
	self:showWaypoints(pPlayer, filter, page)
end

function BgWaypointOrganizer:showPlanets(pPlayer)
	local list = self:snapshot(pPlayer)
	local counts, order = {}, {}
	for _, w in ipairs(list) do
		if counts[w.planet] == nil then
			counts[w.planet] = 0
			order[#order + 1] = w.planet
		end
		counts[w.planet] = counts[w.planet] + 1
	end
	table.sort(order)

	local rows = {}
	for _, planet in ipairs(order) do
		rows[#rows + 1] = {
			label = capitalize(planet) .. "  (" .. counts[planet] .. ")",
			act = join("wps", "planet", planet, 1),
		}
	end

	local prompt = "SELECT PLANET"
	if #rows == 0 then
		prompt = prompt .. "\n\nYou have no waypoints."
	end
	self:showList(pPlayer, "Browse by Planet", prompt, rows, "main", "Open")
end

function BgWaypointOrganizer:showCategoryBrowse(pPlayer)
	local list = self:snapshot(pPlayer)
	local cats = self:getCategories(pPlayer)
	local catMap = self:categoryMap(pPlayer)
	local counts = {}
	for _, w in ipairs(list) do
		local cid = self:categoryOf(pPlayer, w, catMap)
		counts[cid] = (counts[cid] or 0) + 1
	end

	local rows = {}
	for _, c in ipairs(cats) do
		rows[#rows + 1] = {
			label = c.name .. "  (" .. (counts[c.id] or 0) .. ")",
			act = join("wps", "cat", c.id, 1),
		}
	end
	self:showList(pPlayer, "Browse by Category", "SELECT CATEGORY", rows, "main", "Open")
end

------------------------------------------------------------------------------
-- Search
------------------------------------------------------------------------------

function BgWaypointOrganizer:showSearch(pPlayer, message)
	local prompt = "SEARCH WAYPOINTS\n\nEnter part of a waypoint name (not case sensitive)."
	if message ~= nil and message ~= "" then
		prompt = prompt .. "\n\n" .. message
	end
	self:showInput(pPlayer, "Search Waypoints", prompt, "", 60, "searchok", "main")
end

------------------------------------------------------------------------------
-- Waypoint detail / single actions
------------------------------------------------------------------------------

function BgWaypointOrganizer:showDetail(pPlayer, wpId, filter, page, message)
	local _, byId = self:snapshot(pPlayer)
	local w = byId[tostring(wpId)]
	local ctx = ctxTail(filter.kind, filter.value, page)
	local back = join("wps", ctx)

	if w == nil then
		self:showNotice(pPlayer, "Waypoint", "That waypoint no longer exists.", back)
		return
	end

	local catMap = self:categoryMap(pPlayer)
	local cid = self:categoryOf(pPlayer, w, catMap)
	local fav = self:isFavorite(pPlayer, w)
	local selected = self:getBasket(pPlayer)[tostring(w.id)] ~= nil

	local prompt = w.name .. "\n\n" ..
		"Planet: " .. w.planetName .. "\n" ..
		string.format("Location: %d, %d\n", math.floor(w.x + 0.5), math.floor(w.y + 0.5)) ..
		"Status: " .. (w.active and "Active" or "Inactive") .. "\n" ..
		"Category: " .. (catMap[cid] and catMap[cid].name or "General") .. "\n" ..
		"Favorite: " .. (fav and "Yes" or "No")
	if w.temporary then
		prompt = prompt .. "\n\nThis is a temporary tracking waypoint. It cannot be modified here."
	elseif w.protected then
		prompt = prompt .. "\n\nThis waypoint belongs to a mission or quest and cannot be modified here."
	end
	if message ~= nil and message ~= "" then
		prompt = prompt .. "\n\n" .. message
	end

	local rows = {
		{ label = fav and "Remove from Favorites" or "Add to Favorites", act = join("fav", w.id, fav and 0 or 1, ctx) },
		{ label = selected and "Remove from Selection (bulk)" or "Add to Selection (bulk)", act = join("sel", w.id, selected and 0 or 1, ctx) },
		{ label = "Set Category", act = join("assign", w.id, ctx) },
	}

	if not w.protected then
		rows[#rows + 1] = {
			label = w.active and "Deactivate Waypoint" or "Activate Waypoint",
			act = join("toggle", w.id, w.active and 0 or 1, ctx),
		}
		if w.special == 0 then
			rows[#rows + 1] = { label = "Rename Waypoint", act = join("rename", w.id, ctx) }
		end
		rows[#rows + 1] = { label = "Delete Waypoint", act = join("delask", w.id, ctx) }
	end

	self:showList(pPlayer, "Waypoint", prompt, rows, back, "Select")
end

-- fav|wpid|0or1|kind|value|page
function BgWaypointOrganizer:doFavorite(pPlayer, f)
	local _, byId = self:snapshot(pPlayer)
	local w = byId[tostring(f[2])]
	local filter, page = makeFilter(f[4], f[5]), tonumber(f[6]) or 1
	if w ~= nil then
		self:setFavorite(pPlayer, w, f[3] == "1")
	end
	self:showDetail(pPlayer, f[2], filter, page, w and (f[3] == "1" and "Added to favorites." or "Removed from favorites.") or nil)
end

-- sel|wpid|0or1|kind|value|page
function BgWaypointOrganizer:doSelect(pPlayer, f)
	local _, byId = self:snapshot(pPlayer)
	local filter, page = makeFilter(f[4], f[5]), tonumber(f[6]) or 1
	local id = tostring(f[2])
	if byId[id] ~= nil then
		local basket = self:getBasket(pPlayer)
		basket[id] = (f[3] == "1") or nil
		self:saveBasket(pPlayer, basket)
	end
	self:showDetail(pPlayer, f[2], filter, page, f[3] == "1" and "Added to selection." or "Removed from selection.")
end

-- Re-validated single-waypoint lookups. Return waypoint, ghost, error.
function BgWaypointOrganizer:resolveOwned(pPlayer, wpId)
	local pGhost = getGhost(pPlayer)
	if pGhost == nil then
		return nil, nil, "Your character data is unavailable."
	end
	local _, byId = self:snapshot(pPlayer)
	local w = byId[tostring(wpId)]
	if w == nil then
		return nil, nil, "That waypoint no longer exists."
	end
	return w, pGhost, nil
end

function BgWaypointOrganizer:applyActive(pPlayer, wpId, makeActive)
	local w, pGhost, err = self:resolveOwned(pPlayer, wpId)
	if w == nil then
		return false, err
	end
	if w.protected then
		return false, "Mission, quest and tracking waypoints cannot be modified here."
	end
	local pWp = getSceneObject(w.id)
	if pWp == nil then
		return false, "That waypoint no longer exists."
	end
	WaypointObject(pWp):setActive(makeActive and 1 or 0)
	PlayerObject(pGhost):updateWaypoint(w.id)
	return true
end

function BgWaypointOrganizer:applyDelete(pPlayer, wpId)
	local w, pGhost, err = self:resolveOwned(pPlayer, wpId)
	if w == nil then
		return false, err
	end
	if w.protected then
		return false, "Mission, quest and tracking waypoints cannot be deleted here."
	end
	-- Stock removal path: client delta, client-path cleanup and database destroy
	PlayerObject(pGhost):removeWaypoint(w.id, true)
	self:clearMeta(pPlayer, w.id)
	local basket = self:getBasket(pPlayer)
	basket[tostring(w.id)] = nil
	self:saveBasket(pPlayer, basket)
	return true
end

-- delask|wpid|kind|value|page
function BgWaypointOrganizer:askDelete(pPlayer, f)
	local w, _, err = self:resolveOwned(pPlayer, f[2])
	if w == nil then
		self:showNotice(pPlayer, "Delete Waypoint", err, join("wps", f[3], f[4], f[5]))
		return
	end
	self:showConfirm(pPlayer, "Delete Waypoint?",
		"You are about to delete:\n\n" .. w.name .. " (" .. w.planetName .. ")\n\nThis action cannot be undone.",
		"Confirm Delete",
		join("delok", f[2], f[3], f[4], f[5]),
		join("detail", f[2], f[3], f[4], f[5], ""))
end

-- rename|wpid|kind|value|page
function BgWaypointOrganizer:showRename(pPlayer, wpId, filter, page, message)
	local w, _, err = self:resolveOwned(pPlayer, wpId)
	local ctx = ctxTail(filter.kind, filter.value, page)
	if w == nil then
		self:showNotice(pPlayer, "Rename Waypoint", err, join("wps", ctx))
		return
	end
	if w.protected or w.special ~= 0 then
		self:showNotice(pPlayer, "Rename Waypoint", "This waypoint cannot be renamed.", join("detail", wpId, ctx, ""))
		return
	end

	local prompt = "RENAME WAYPOINT\n\nCurrent:\n" .. w.name .. "\n\nNew Name:"
	if message ~= nil and message ~= "" then
		prompt = prompt .. "\n\n" .. message
	end
	self:showInput(pPlayer, "Rename Waypoint", prompt, w.name, MAX_WAYPOINT_NAME,
		join("renameok", wpId, ctx), join("detail", wpId, ctx, ""))
end

-- renameok|wpid|kind|value|page  (+ typed text)
function BgWaypointOrganizer:doRename(pPlayer, f, text)
	local filter, page = makeFilter(f[3], f[4]), tonumber(f[5]) or 1
	local listBack = join("wps", f[3], f[4], f[5])
	local newName = sanitizeName(text, MAX_WAYPOINT_NAME)
	if newName == "" then
		self:showRename(pPlayer, f[2], filter, page, "The name cannot be empty.")
		return
	end

	local w, pGhost, err = self:resolveOwned(pPlayer, f[2])
	if w == nil then
		self:showNotice(pPlayer, "Rename Waypoint", err, listBack)
		return
	end
	if w.protected or w.special ~= 0 then
		self:showNotice(pPlayer, "Rename Waypoint", "This waypoint cannot be renamed.", listBack)
		return
	end
	local pWp = getSceneObject(w.id)
	if pWp == nil then
		self:showNotice(pPlayer, "Rename Waypoint", "That waypoint no longer exists.", listBack)
		return
	end
	SceneObject(pWp):setCustomObjectName(newName)
	PlayerObject(pGhost):updateWaypoint(w.id)
	self:showDetail(pPlayer, f[2], filter, page, "Waypoint renamed.")
end

------------------------------------------------------------------------------
-- Categories
------------------------------------------------------------------------------

-- mode "single": wpId + filter/page for returning; mode "bulk": applies to the basket.
function BgWaypointOrganizer:showAssignCategory(pPlayer, mode, wpId, filter, page)
	local rows = {}
	for _, c in ipairs(self:getCategories(pPlayer)) do
		if mode == "single" then
			rows[#rows + 1] = { label = c.name, act = join("setcat", "single", c.id, wpId, filter.kind, filter.value, page) }
		else
			rows[#rows + 1] = { label = c.name, act = join("setcat", "bulk", c.id) }
		end
	end
	local back = (mode == "single") and join("detail", wpId, filter.kind, filter.value, page, "") or "bulk"
	self:showList(pPlayer, "Set Category", "Choose a category.", rows, back, "Assign")
end

-- setcat|single|cid|wpid|kind|value|page   /   setcat|bulk|cid
function BgWaypointOrganizer:doSetCategory(pPlayer, f)
	local mode, cid = f[2], f[3]
	local _, byId = self:snapshot(pPlayer)
	local catMap = self:categoryMap(pPlayer)
	local ids, done = {}, "main"

	if mode == "single" then
		ids = { tostring(f[4]) }
		done = join("detail", f[4], f[5], f[6], f[7], "")
	else
		for id, _ in pairs(self:getBasket(pPlayer)) do
			ids[#ids + 1] = id
		end
		done = "bulk"
	end

	local n = 0
	if catMap[cid] ~= nil then
		for _, id in ipairs(ids) do
			local w = byId[id]
			if w ~= nil then
				self:setCategory(pPlayer, w, cid)
				n = n + 1
			end
		end
	end
	self:showNotice(pPlayer, "Set Category", n .. " waypoint(s) moved to " .. (catMap[cid] and catMap[cid].name or "General") .. ".", done)
end

function BgWaypointOrganizer:showCategoryManage(pPlayer, message)
	local cats = self:getCategories(pPlayer)
	local custom = 0
	for _, c in ipairs(cats) do
		if not c.default then
			custom = custom + 1
		end
	end

	local prompt = "MANAGE CATEGORIES\n\nCustom categories: " .. custom .. " / " .. MAX_CUSTOM_CATEGORIES ..
		"\nSelect a category to assign waypoints to it, browse it, or (custom only) rename/delete it." ..
		"\nWaypoints are General until you assign them. Deleting a category moves its waypoints back to General."
	if message ~= nil and message ~= "" then
		prompt = prompt .. "\n\n" .. message
	end

	local list = self:snapshot(pPlayer)
	local catMap = self:categoryMap(pPlayer)
	local counts = {}
	for _, w in ipairs(list) do
		local cid = self:categoryOf(pPlayer, w, catMap)
		counts[cid] = (counts[cid] or 0) + 1
	end

	local rows = { { label = "> Create New Category", act = "catnew" } }
	for _, c in ipairs(cats) do
		rows[#rows + 1] = { label = c.name .. "  (" .. (counts[c.id] or 0) .. ")", act = join("catopt", c.id) }
	end
	self:showList(pPlayer, "Manage Categories", prompt, rows, "main", "Open")
end

-- Case-insensitive, whitespace-trimmed comparison against defaults and existing customs.
function BgWaypointOrganizer:categoryNameTaken(pPlayer, name, exceptId)
	local lower = string.lower(name)
	for _, c in ipairs(self:getCategories(pPlayer)) do
		if c.id ~= exceptId and string.lower(c.name) == lower then
			return true
		end
	end
	return false
end

function BgWaypointOrganizer:showCreateCategory(pPlayer, message)
	local prompt = "CREATE CATEGORY\n\nEnter a name (max " .. MAX_CATEGORY_NAME .. " characters). Names are not case sensitive and must be unique."
	if message ~= nil and message ~= "" then
		prompt = prompt .. "\n\n" .. message
	end
	self:showInput(pPlayer, "Create Category", prompt, "", MAX_CATEGORY_NAME, "catcreate", "catmanage")
end

function BgWaypointOrganizer:doCreateCategory(pPlayer, text)
	local name = sanitizeName(text, MAX_CATEGORY_NAME)
	if name == "" then
		self:showCreateCategory(pPlayer, "The name cannot be empty.")
		return
	end
	if self:categoryNameTaken(pPlayer, name, nil) then
		self:showCreateCategory(pPlayer, "A category with that name already exists.")
		return
	end
	local list = splitCsv(readKey(pPlayer, "catlist"))
	if #list >= MAX_CUSTOM_CATEGORIES then
		self:showCategoryManage(pPlayer, "You have reached the limit of " .. MAX_CUSTOM_CATEGORIES .. " custom categories.")
		return
	end
	local n = math.floor(tonumber(readKey(pPlayer, "catnext") or "1") or 1)
	local cid = "c" .. tostring(n)
	writeKey(pPlayer, "catnext", tostring(n + 1))
	writeKey(pPlayer, "catname_" .. cid, name)
	list[#list + 1] = cid
	writeKey(pPlayer, "catlist", table.concat(list, ","))
	self:showCategoryManage(pPlayer, "Created category: " .. name)
end

function BgWaypointOrganizer:showCategoryOptions(pPlayer, cid, message)
	cid = tostring(cid)
	local c = self:categoryMap(pPlayer)[cid]
	if c == nil then
		self:showCategoryManage(pPlayer, "That category no longer exists.")
		return
	end
	local selectedCount = #self:basketIds(pPlayer)
	local rows = {
		{ label = "Browse Waypoints", act = join("wps", "cat", cid, 1) },
		{ label = "Assign Waypoints to this Category", act = join("catpick", cid, 1, "") },
		{ label = "Assign Selected Waypoints (" .. selectedCount .. ") to this Category", act = join("setcat", "bulk", cid) },
	}
	if not c.default then
		rows[#rows + 1] = { label = "Rename Category", act = join("catren", cid, "") }
		rows[#rows + 1] = { label = "Delete Category", act = join("catdelask", cid) }
	end
	local prompt = "Category: " .. c.name
	if message ~= nil and message ~= "" then
		prompt = prompt .. "\n\n" .. message
	end
	self:showList(pPlayer, "Category: " .. c.name, prompt, rows, "catmanage", "Select")
end

-- Pick waypoints one at a time to assign to a category. catpick|cid|page|message
function BgWaypointOrganizer:showCategoryPick(pPlayer, cid, page, message)
	cid = tostring(cid)
	local catMap = self:categoryMap(pPlayer)
	local c = catMap[cid]
	if c == nil then
		self:showCategoryManage(pPlayer, "That category no longer exists.")
		return
	end

	local list = self:applyFilter(pPlayer, makeFilter("all", ""), (self:snapshot(pPlayer)))
	local pageSize = self:getPageSize(pPlayer)
	local pages = math.max(1, math.ceil(#list / pageSize))
	if page < 1 then page = 1 end
	if page > pages then page = pages end
	local first = (page - 1) * pageSize + 1
	local last = math.min(#list, first + pageSize - 1)

	local prompt = "Assign waypoints to: " .. c.name .. "\nPage " .. page .. " of " .. pages ..
		"\nSelect a waypoint to assign it. [*] = already in this category."
	if message ~= nil and message ~= "" then
		prompt = prompt .. "\n\n" .. message
	end

	local rows = {}
	for i = first, last do
		local w = list[i]
		local inCat = (self:categoryOf(pPlayer, w, catMap) == cid)
		rows[#rows + 1] = {
			label = (inCat and "[*] " or "") .. w.name .. " - " .. w.planetName,
			act = join("catpickset", cid, w.id, page),
		}
	end
	if page > 1 then
		rows[#rows + 1] = { label = "<< Previous Page", act = join("catpick", cid, page - 1, "") }
	end
	if page < pages then
		rows[#rows + 1] = { label = "Next Page >>", act = join("catpick", cid, page + 1, "") }
	end
	self:showList(pPlayer, "Assign to " .. c.name, prompt, rows, join("catopt", cid), "Assign")
end

-- catpickset|cid|wpid|page
function BgWaypointOrganizer:doCategoryPick(pPlayer, f)
	local cid, page = tostring(f[2]), tonumber(f[4]) or 1
	local _, byId = self:snapshot(pPlayer)
	local c = self:categoryMap(pPlayer)[cid]
	local w = byId[tostring(f[3])]
	local msg
	if c == nil then
		self:showCategoryManage(pPlayer, "That category no longer exists.")
		return
	elseif w == nil then
		msg = "That waypoint no longer exists."
	else
		self:setCategory(pPlayer, w, cid)
		msg = "Assigned \"" .. w.name .. "\" to " .. c.name .. "."
	end
	self:showCategoryPick(pPlayer, cid, page, msg)
end

function BgWaypointOrganizer:showRenameCategory(pPlayer, cid, message)
	local name = readKey(pPlayer, "catname_" .. tostring(cid))
	if name == nil then
		self:showCategoryManage(pPlayer, "That category no longer exists.")
		return
	end
	local prompt = "RENAME CATEGORY\n\nCurrent: " .. name
	if message ~= nil and message ~= "" then
		prompt = prompt .. "\n\n" .. message
	end
	self:showInput(pPlayer, "Rename Category", prompt, name, MAX_CATEGORY_NAME, join("catrenok", cid), join("catopt", cid))
end

function BgWaypointOrganizer:doRenameCategory(pPlayer, cid, text)
	local newName = sanitizeName(text, MAX_CATEGORY_NAME)
	if newName == "" then
		self:showRenameCategory(pPlayer, cid, "The name cannot be empty.")
		return
	end
	if readKey(pPlayer, "catname_" .. tostring(cid)) == nil then
		self:showCategoryManage(pPlayer, "That category no longer exists.")
		return
	end
	if self:categoryNameTaken(pPlayer, newName, cid) then
		self:showRenameCategory(pPlayer, cid, "A category with that name already exists.")
		return
	end
	writeKey(pPlayer, "catname_" .. tostring(cid), newName)
	self:showCategoryManage(pPlayer, "Category renamed to: " .. newName)
end

function BgWaypointOrganizer:askDeleteCategory(pPlayer, cid)
	local name = readKey(pPlayer, "catname_" .. tostring(cid))
	if name == nil then
		self:showCategoryManage(pPlayer, "That category no longer exists.")
		return
	end
	self:showConfirm(pPlayer, "Delete Category?",
		"Delete the category \"" .. name .. "\"?\n\nIts waypoints are NOT deleted; they return to General.",
		"Confirm Delete", join("catdelok", cid), join("catopt", cid))
end

function BgWaypointOrganizer:deleteCategory(pPlayer, cid)
	cid = tostring(cid)
	if readKey(pPlayer, "catname_" .. cid) == nil then
		self:showCategoryManage(pPlayer, "That category no longer exists.")
		return
	end
	-- Ids are never reused (catnext only grows), and categoryOf() resolves unknown ids to General,
	-- so stale assignments can never attach to a different category. Clear them anyway for tidiness.
	local _, byId = self:snapshot(pPlayer)
	for id, _ in pairs(byId) do
		if readKey(pPlayer, "cat_" .. id) == cid then
			deleteKey(pPlayer, "cat_" .. id)
		end
	end
	deleteKey(pPlayer, "catname_" .. cid)
	local keep = {}
	for _, v in ipairs(splitCsv(readKey(pPlayer, "catlist"))) do
		if v ~= cid then
			keep[#keep + 1] = v
		end
	end
	if #keep == 0 then
		deleteKey(pPlayer, "catlist")
	else
		writeKey(pPlayer, "catlist", table.concat(keep, ","))
	end
	self:showCategoryManage(pPlayer, "Category deleted. Its waypoints moved to General.")
end

------------------------------------------------------------------------------
-- Bulk management (selection basket stored in screenplay data)
------------------------------------------------------------------------------

function BgWaypointOrganizer:basketIds(pPlayer)
	local _, byId = self:snapshot(pPlayer)
	local basket = self:getBasket(pPlayer)
	local ids = {}
	for id, _ in pairs(basket) do
		if byId[id] ~= nil then
			ids[#ids + 1] = id
		else
			basket[id] = nil
		end
	end
	self:saveBasket(pPlayer, basket)
	table.sort(ids, function(a, b) return tonumber(a) < tonumber(b) end)
	return ids
end

function BgWaypointOrganizer:showBulk(pPlayer, message)
	local ids = self:basketIds(pPlayer)

	local prompt = "BULK MANAGEMENT\n\nSelected waypoints: " .. #ids ..
		"\n\nAdd waypoints to the selection from any waypoint list (use the \"Select all\" rows or a waypoint's detail menu)." ..
		" Mission, quest and temporary tracking waypoints are skipped by bulk actions."
	if message ~= nil and message ~= "" then
		prompt = prompt .. "\n\n" .. message
	end

	local rows = {
		{ label = "View Selected Waypoints", act = "wps|basket||1" },
		{ label = "Activate Selected", act = "bulkrun|activate" },
		{ label = "Deactivate Selected", act = "bulkrun|deactivate" },
		{ label = "Assign Selected to Category", act = "bulkrun|category" },
		{ label = "Delete Selected", act = "bulkrun|delete" },
		{ label = "Clear Selection", act = "bulkclear" },
	}
	self:showList(pPlayer, "Bulk Management", prompt, rows, "main", "Select")
end

function BgWaypointOrganizer:bulkRun(pPlayer, action)
	local ids = self:basketIds(pPlayer)
	if #ids == 0 then
		self:showBulk(pPlayer, "No waypoints are selected.")
		return
	end

	if action == "category" then
		self:showAssignCategory(pPlayer, "bulk", "", makeFilter("all", ""), 1)
		return
	end

	if action == "delete" then
		self:showConfirm(pPlayer, "Delete Waypoints?",
			"You are about to delete " .. #ids .. " waypoint(s).\n\nMission, quest and tracking waypoints will be skipped.\n\nThis action cannot be undone.",
			"Confirm Delete",
			"bulkexec|delete",
			"bulk|Delete cancelled. Nothing was deleted.")
		return
	end

	self:bulkExecute(pPlayer, action)
end

-- Executes against the CURRENT basket, revalidating each id. Reports done / skipped / missing.
function BgWaypointOrganizer:bulkExecute(pPlayer, action)
	local ids = self:basketIds(pPlayer)
	local done, skipped, missing = 0, 0, 0

	for _, id in ipairs(ids) do
		local ok, why
		if action == "delete" then
			ok, why = self:applyDelete(pPlayer, id)
		elseif action == "activate" then
			ok, why = self:applyActive(pPlayer, id, true)
		else
			ok, why = self:applyActive(pPlayer, id, false)
		end

		if ok then
			done = done + 1
		elseif why == "That waypoint no longer exists." then
			missing = missing + 1
		else
			skipped = skipped + 1
		end
	end

	local verb = (action == "delete") and "Deleted" or ((action == "activate") and "Activated" or "Deactivated")
	self:showNotice(pPlayer, "Bulk Result",
		verb .. ": " .. done .. "\nSkipped (protected): " .. skipped .. "\nNo longer existed: " .. missing, "bulk")
end

------------------------------------------------------------------------------
-- Settings
------------------------------------------------------------------------------

function BgWaypointOrganizer:showSettings(pPlayer, message)
	local size = self:getPageSize(pPlayer)
	local prompt = "ORGANIZER SETTINGS\n\nWaypoints per page: " .. size ..
		"\nCustom category limit: " .. MAX_CUSTOM_CATEGORIES ..
		"\n\nOrganizer data (categories and favorites) is saved with your character."
	if message ~= nil and message ~= "" then
		prompt = prompt .. "\n\n" .. message
	end

	local rows = {}
	for _, n in ipairs({ 10, 20, 30 }) do
		rows[#rows + 1] = {
			label = "Show " .. n .. " waypoints per page" .. (n == size and " (current)" or ""),
			act = "setpage|" .. n,
		}
	end
	self:showList(pPlayer, "Organizer Settings", prompt, rows, "main", "Apply")
end

------------------------------------------------------------------------------
-- Command entry point (called from C++ WaypointCommand "organize")
------------------------------------------------------------------------------

function waypointOrganizerRun(pPlayer)
	BgWaypointOrganizer:start(pPlayer)
end
