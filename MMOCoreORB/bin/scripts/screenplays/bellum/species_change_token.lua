-- Bellum Gero: Species Change Token
--
-- Lets a player permanently change an EXISTING character's species while preserving name,
-- progression, credits, containers, skills, and all other Bellum Gero custom character state. The
-- actual validation and mutation (naked/state checks, template swap, HAM/appearance/hair reset,
-- character-list DB update, forced relog) all live natively in SpeciesChangeManager, exposed here
-- on CreatureObject as the speciesChange* methods used below -- this screenplay only drives the
-- SUI workflow and guards against duplicate/concurrent use of the token.
--
-- See MMOCoreORB/docs/species_change_token.md for the full design writeup, including why the
-- template swap forces a disconnect instead of updating the player's appearance live.

SpeciesChangeToken = ScreenPlay:new {
	screenplayName = "SpeciesChangeToken",

	-- Radial menu id for this token's "Use" option. Only used on this one object template, so any
	-- value not already used elsewhere on this exact template is fine.
	USE_MENU_ID = 140,

	-- If a workflow is left pending (SUI abandoned, disconnect, etc.) for longer than this, treat it
	-- as stale and allow a fresh attempt rather than permanently locking the player out.
	PENDING_TIMEOUT_SECONDS = 600,
}

registerScreenPlay("SpeciesChangeToken", true)

function SpeciesChangeToken:start()
end

-- ── Display names ────────────────────────────────────────────────────────────
-- speciesChangeGetEligibleSpecies() returns internal species identifiers (Races::Species[] values,
-- e.g. "smc", "chadra_fan") -- these are what must be sent back via speciesChangeApply(), but are
-- not always fit to show a player as-is. Explicit overrides here for identifiers that don't match
-- their real name; anything not listed falls back to a generic underscore-to-space, title-cased
-- rendering (e.g. "chadra_fan" -> "Chadra Fan"), which is already correct for most of them.
SpeciesChangeToken.SPECIES_DISPLAY_NAMES = {
	smc = "Shadow Mountain Clan Witch (SMC)",
	moncal = "Mon Calamari",
	twilek = "Twi'lek",
}

function SpeciesChangeToken:getSpeciesDisplayName(speciesKey)
	local override = self.SPECIES_DISPLAY_NAMES[speciesKey]

	if override ~= nil then
		return override
	end

	local words = {}

	for word in string.gmatch(speciesKey, "[^_]+") do
		table.insert(words, string.upper(string.sub(word, 1, 1)) .. string.sub(word, 2))
	end

	return table.concat(words, " ")
end

-- ── Duplicate/concurrent-use guard ──────────────────────────────────────────
-- Tracked entirely through per-player screenplay data so at most one Species Change Token workflow
-- can be open per player at a time, and a stale or duplicate SUI callback (reconnect, second radial
-- click, expired session) can always be detected and rejected.

function SpeciesChangeToken:isPending(pPlayer)
	if readScreenPlayData(pPlayer, self.screenplayName, "pending") ~= "1" then
		return false
	end

	local since = tonumber(readScreenPlayData(pPlayer, self.screenplayName, "pendingSince"))

	if since ~= nil and (os.time() - since) > self.PENDING_TIMEOUT_SECONDS then
		self:clearPending(pPlayer)
		return false
	end

	return true
end

function SpeciesChangeToken:clearPending(pPlayer)
	deleteScreenPlayData(pPlayer, self.screenplayName, "pending")
	deleteScreenPlayData(pPlayer, self.screenplayName, "pendingSince")
	deleteScreenPlayData(pPlayer, self.screenplayName, "tokenID")
	deleteScreenPlayData(pPlayer, self.screenplayName, "targetSpecies")
end

-- ── Radial menu component ───────────────────────────────────────────────────

SpeciesChangeTokenMenuComponent = { }

function SpeciesChangeTokenMenuComponent:fillObjectMenuResponse(pObject, pMenuResponse, pPlayer)
	if pObject == nil or pPlayer == nil then
		return 0
	end

	LuaObjectMenuResponse(pMenuResponse):addRadialMenuItem(SpeciesChangeToken.USE_MENU_ID, 3, "Use")

	return 0
end

function SpeciesChangeTokenMenuComponent:handleObjectMenuSelect(pObject, pPlayer, selectedID)
	if pObject == nil or pPlayer == nil then
		return 0
	end

	if selectedID ~= SpeciesChangeToken.USE_MENU_ID then
		return 0
	end

	SpeciesChangeToken:beginUse(pPlayer, pObject)

	return 0
end

-- ── Step 1: initial validation (naked + state) ──────────────────────────────

function SpeciesChangeToken:beginUse(pPlayer, pToken)
	if not SceneObject(pToken):isASubChildOf(pPlayer) then
		return
	end

	if self:isPending(pPlayer) then
		CreatureObject(pPlayer):sendSystemMessage("You already have a Species Change Token in progress. Finish or cancel it before using another.")
		return
	end

	local blockedReason = CreatureObject(pPlayer):speciesChangeGetBlockedReason()

	if blockedReason ~= "" then
		CreatureObject(pPlayer):sendSystemMessage(blockedReason)
		return
	end

	if not CreatureObject(pPlayer):speciesChangeIsNaked() then
		CreatureObject(pPlayer):sendSystemMessage("Species Change Failed\nYou must remove all equipped items before using a Species Change Token. Place all weapons, armor, clothing, jewelry, backpacks, and other equipped items into your inventory, then try again.")
		return
	end

	local tokenID = SceneObject(pToken):getObjectID()

	writeScreenPlayData(pPlayer, self.screenplayName, "pending", "1")
	writeScreenPlayData(pPlayer, self.screenplayName, "pendingSince", os.time())
	writeScreenPlayData(pPlayer, self.screenplayName, "tokenID", tokenID)

	self:openSpeciesSelection(pPlayer)
end

-- ── Step 2: species selection ────────────────────────────────────────────────

function SpeciesChangeToken:openSpeciesSelection(pPlayer)
	local species = CreatureObject(pPlayer):speciesChangeGetEligibleSpecies()

	if species == nil or #species == 0 then
		CreatureObject(pPlayer):sendSystemMessage("There are no other species currently available for your character to change into.")
		self:clearPending(pPlayer)
		return
	end

	local sui = SuiListBox.new(self.screenplayName, "speciesSelectionCallback")
	sui.setTitle("Species Change Token")
	sui.setPrompt("Select the species you wish to change into.\n\nYour character progression will be preserved, but your appearance and hairstyle will be reset to valid defaults for your new species. This cannot be undone without another Species Change Token.")

	for i = 1, #species do
		sui.add(self:getSpeciesDisplayName(species[i]), "")
	end

	sui.sendTo(pPlayer)
end

function SpeciesChangeToken:speciesSelectionCallback(pPlayer, pSui, eventIndex, args)
	if pPlayer == nil then
		return
	end

	if not self:isPending(pPlayer) then
		return
	end

	if eventIndex == 1 then
		self:clearPending(pPlayer)
		return
	end

	local selected = tonumber(args)

	if selected == nil then
		CreatureObject(pPlayer):sendSystemMessage("Invalid species selection.")
		self:clearPending(pPlayer)
		return
	end

	-- Re-derive the list rather than trusting anything cached client-side; the row index is only
	-- meaningful against the list as it exists right now.
	local species = CreatureObject(pPlayer):speciesChangeGetEligibleSpecies()
	local targetSpecies = species[selected + 1]

	if targetSpecies == nil then
		CreatureObject(pPlayer):sendSystemMessage("Invalid species selection.")
		self:clearPending(pPlayer)
		return
	end

	writeScreenPlayData(pPlayer, self.screenplayName, "targetSpecies", targetSpecies)

	-- ── Step 3: confirmation ─────────────────────────────────────────────────

	local sui = SuiMessageBox.new(self.screenplayName, "confirmSpeciesChangeCallback")
	sui.setTitle("Confirm Species Change")
	sui.setPrompt("You are about to permanently change your character's species to " .. self:getSpeciesDisplayName(targetSpecies) .. ".\n\nYour character progression will be preserved, but your appearance will be reset to valid settings for your new species.\n\nThis action cannot be reversed without another Species Change Token.\n\nContinue?")
	sui.sendTo(pPlayer)
end

-- ── Step 4: confirmation result -> apply ─────────────────────────────────────

function SpeciesChangeToken:confirmSpeciesChangeCallback(pPlayer, pSui, eventIndex, args)
	if pPlayer == nil then
		return
	end

	if not self:isPending(pPlayer) then
		return
	end

	if eventIndex == 1 then
		CreatureObject(pPlayer):sendSystemMessage("Species change cancelled.")
		self:clearPending(pPlayer)
		return
	end

	local tokenID = readScreenPlayData(pPlayer, self.screenplayName, "tokenID")
	local targetSpecies = readScreenPlayData(pPlayer, self.screenplayName, "targetSpecies")

	if tokenID == nil or tokenID == 0 or targetSpecies == nil or targetSpecies == "" then
		CreatureObject(pPlayer):sendSystemMessage("Your Species Change Token session has expired. Please try again.")
		self:clearPending(pPlayer)
		return
	end

	-- Re-validate the token itself still exists and is still actually the player's (guards against
	-- the token having been traded, moved, or destroyed while this SUI was open).
	local pToken = getSceneObject(tokenID)

	if pToken == nil or not SceneObject(pToken):isASubChildOf(pPlayer) then
		CreatureObject(pPlayer):sendSystemMessage("Your Species Change Token could not be found. Please try again.")
		self:clearPending(pPlayer)
		return
	end

	-- Final, authoritative validation (naked/state/species) happens again natively inside
	-- speciesChangeApply immediately before anything is changed -- this call is safe even if
	-- something changed since the confirmation dialog was opened (e.g. the player re-equipped an
	-- item or entered combat in the meantime).
	local failureReason = CreatureObject(pPlayer):speciesChangeApply(targetSpecies)

	if failureReason ~= "" then
		CreatureObject(pPlayer):sendSystemMessage("Species Change Failed\n" .. failureReason)
		self:clearPending(pPlayer)
		return
	end

	-- Success: the token is consumed only now that the change has actually completed.
	SceneObject(pToken):destroyObjectFromWorld(true)
	SceneObject(pToken):destroyObjectFromDatabase(true)

	self:clearPending(pPlayer)
end
