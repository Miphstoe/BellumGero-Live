-- Mandalorian Daily Bounty: holographic guild contact + generated storyline.
--
-- A holo bounty hunter (mando_holo_bh) materializes in front of the player
-- when a daily mission is accepted and again when each camp is cleared.
-- The day's storyline is composed from pools (intro x dossier x twist x
-- finale), deterministically seeded per player per day, so lines stay
-- consistent across the 5 tiers but change every day and differ per player.

MandoDailyHoloStory = ScreenPlay:new {
	numberOfActs = 1,
	screenplayName = "MandoDailyHoloStory",

	HOLO_TEMPLATE = "mando_holo_bh",
	HOLO_LIFETIME_MS = 120 * 1000,
	LINE_GAP_MS = 5 * 1000,
}

-- ---------------------------------------------------------------------------
-- Story pools
-- ---------------------------------------------------------------------------

MandoDailyHoloStory.INTROS = {
	"Su cuy'gar, hunter. The guild transmits under clan seal today.",
	"Your fob woke me from a dead sleep. This one is worth it, verd.",
	"Copy your signet, hunter. The tracking net has a fresh scent.",
	"The guild owes a favor and you get to collect it. Listen close.",
	"Three hunters refused this chain already. I told them you wouldn't.",
	"Signal's weak out here, so I'll be quick. We have a runner.",
	"The bounty board lit up an hour ago. Yours if you want it.",
	"Hunter. The clan council flagged this one personally.",
	"I don't like holocalls either. But credits are credits, verd.",
	"You picked a good day to keep your fob charged.",
}

MandoDailyHoloStory.DOSSIERS = {
	{ name = "Vekk 'Redline' Tarsi", desc = "a swoop-gang enforcer who torched a guild depot on Corellia" },
	{ name = "Mirla Deshkin", desc = "a slicer who sold clan patrol routes to the Black Sun" },
	{ name = "Gor the Hutt's pet 'Kaadu'", desc = "a Trandoshan skip-tracer who hunts our foundlings for sport" },
	{ name = "Captain Ordo Vray", desc = "a deserter who left his squad to die at the Roche asteroids" },
	{ name = "Ledda Prin", desc = "a spice courier moving death sticks through sacred clan ground" },
	{ name = "'Six-Fingers' Sallo", desc = "a fence who moved stolen beskar off-world" },
	{ name = "Dr. Emhet Kaas", desc = "a rogue geneticist buying captured wildlife from poacher camps" },
	{ name = "Rennik Var", desc = "a bounty jumper who's skipped four postings and killed two hunters" },
	{ name = "Thessa Kyne", desc = "an arms dealer supplying blasters to anti-Mandalorian militias" },
	{ name = "Brel 'The Quiet One' Themm", desc = "an assassin who took a contract on a clan elder" },
	{ name = "Juno Halvek", desc = "a crime boss taxing settlers under a false clan banner" },
	{ name = "Xac Wonn", desc = "a saboteur who rigged a guild transport to blow" },
	{ name = "Marda Grell", desc = "a slaver running captives through the outer settlements" },
	{ name = "Odun Rask", desc = "a mercenary captain who broke a sworn contract with the clan" },
	{ name = "'Whisper' Tayn", desc = "an informant selling guild fob frequencies to the highest bidder" },
}

MandoDailyHoloStory.TWISTS = {
	"That wasn't the target. A body double - paid in fresh credits. We're close though. Stand by for the next waypoint.",
	"Bad news: that was a decoy camp. Good news: they burned their reserve muscle hiding the trail. Next waypoint incoming.",
	"The mark slipped the net minutes before you hit the camp. Their protection detail is thinning. Stand by, hunter.",
	"Our target paid that crew to slow you down. It cost them dearly and bought them nothing. New coordinates soon.",
	"Interrogated survivors confirm it: the real mark is one step ahead. One. Stand by for the next waypoint.",
	"That camp was a cutout - hired through a shell contract. But we pulled a fresh signal off their comms. Stand by.",
	"Wrong face, right trail. The mark's inner circle is starting to panic. Next camp will be tougher, verd.",
	"They're feeding us decoys, which means we're expensive to avoid. Keep the pressure on. Waypoint soon.",
	"The trail forked and we took the wrong tine. Correcting now. The next lot won't die so easily.",
	"That crew knew the mark personally - and the fear in their comm logs says we're closing in. Stand by.",
}

MandoDailyHoloStory.ESCALATIONS = {
	"Word of warning: the next posting is a tougher foe. Bring more than confidence.",
	"The next camp is dug in deeper. They know you're coming now.",
	"Whoever's next on the chain fights like a cornered gundark. Stay sharp.",
	"The guild raised the hazard rating on the next waypoint. Take that seriously.",
	"They're paying veterans now, not thugs. Expect a real fight.",
}

MandoDailyHoloStory.FINALES = {
	"Confirmed kill on the primary. The chain is closed, the ledger is settled. The guild will remember this hunt. This is the Way.",
	"That was the mark - the real one. Bounty confirmed, payment released to your clan account. Rest well, hunter.",
	"Target down, contract sealed. Five camps in one day... the guild is already telling stories. This is the Way.",
	"It's done. The mark's operation dies with them. Your name carries weight in the guild hall tonight.",
	"Kill confirmed. The council sends its respect - they don't do that often. This is the Way.",
	"The chain ends here. Contract complete. Keep the fob charged, hunter - there will always be another name.",
	"Primary target eliminated. The families they wronged will hear justice was done by Mandalorian hands.",
	"Clean finish, hunter. The guild seal goes on the contract, and your legend grows a little heavier.",
}

-- ---------------------------------------------------------------------------
-- Deterministic per-player per-day selection
-- ---------------------------------------------------------------------------

function MandoDailyHoloStory:storySeed(pPlayer)
	local oid = SceneObject(pPlayer):getObjectID()
	local day = MandoWayOfLife:getTodayDateString() or "0"
	local seed = 0
	local text = tostring(oid) .. day
	for i = 1, #text do
		seed = (seed * 31 + string.byte(text, i)) % 2147483647
	end
	return seed
end

function MandoDailyHoloStory:pick(pool, seed, salt)
	local n = #pool
	if (n == 0) then return nil end
	local v = (seed + salt * 7919) % 2147483647
	return pool[(v % n) + 1]
end

function MandoDailyHoloStory:getDossier(pPlayer)
	local dossier = self:pick(self.DOSSIERS, self:storySeed(pPlayer), 1)
	if (dossier == nil) then
		dossier = { name = "the mark", desc = "a fugitive flagged by the guild" }
	end
	return dossier
end

-- ---------------------------------------------------------------------------
-- Holo spawn / despawn
-- ---------------------------------------------------------------------------

function MandoDailyHoloStory:spawnHolo(pPlayer)
	if (pPlayer == nil) then return nil end

	-- one holo at a time per player
	self:despawnHoloForPlayer(pPlayer)

	local zone = SceneObject(pPlayer):getZoneName()
	local x = SceneObject(pPlayer):getPositionX()
	local z = SceneObject(pPlayer):getPositionZ()
	local y = SceneObject(pPlayer):getPositionY()
	local cell = SceneObject(pPlayer):getParentID()
	local heading = SceneObject(pPlayer):getDirectionAngle()
	local radians = math.rad(heading)
	local spawnX = x + math.sin(radians) * 2
	local spawnY = y + math.cos(radians) * 2

	-- materialize ~2m in front of the player's current position
	local pHolo = spawnMobile(zone, self.HOLO_TEMPLATE, 0, spawnX, z, spawnY, heading + 180, cell)
	if (pHolo == nil) then
		MandoWayOfLife:logDiagPlayer(pPlayer, "HoloStory: spawnMobile FAILED zone=" .. tostring(zone))
		return nil
	end

	SceneObject(pHolo):faceObject(pPlayer, true)
	local holoID = SceneObject(pHolo):getObjectID()
	local playerID = SceneObject(pPlayer):getObjectID()
	writeData("mando_way:holo_story:" .. tostring(playerID) .. ":holoId", holoID)
	writeData("mando_way:holo_story:" .. tostring(holoID) .. ":ownerId", playerID)

	createEvent(self.HOLO_LIFETIME_MS, "MandoDailyHoloStory", "despawnHoloEvent", pHolo, "")
	return pHolo
end

function MandoDailyHoloStory:despawnHoloForPlayer(pPlayer)
	if (pPlayer == nil) then return end
	local key = "mando_way:holo_story:" .. tostring(SceneObject(pPlayer):getObjectID()) .. ":holoId"
	local oid = tonumber(readData(key)) or 0
	if (oid ~= 0) then
		local pOld = getSceneObject(oid)
		deleteData("mando_way:holo_story:" .. tostring(oid) .. ":ownerId")
		if (pOld ~= nil) then
			SceneObject(pOld):destroyObjectFromWorld()
		end
		deleteData(key)
	end
end

function MandoDailyHoloStory:despawnHoloEvent(pHolo)
	if (pHolo ~= nil) then
		local holoID = SceneObject(pHolo):getObjectID()
		local ownerID = readData("mando_way:holo_story:" .. tostring(holoID) .. ":ownerId") or 0
		if (ownerID ~= 0) then
			local ownerKey = "mando_way:holo_story:" .. tostring(ownerID) .. ":holoId"
			if ((readData(ownerKey) or 0) == holoID) then deleteData(ownerKey) end
		end
		deleteData("mando_way:holo_story:" .. tostring(holoID) .. ":ownerId")
		SceneObject(pHolo):destroyObjectFromWorld()
	end
end

function MandoDailyHoloStory:isOwner(pHolo, pPlayer)
	if (pHolo == nil or pPlayer == nil) then return false end
	local holoID = SceneObject(pHolo):getObjectID()
	local ownerID = readData("mando_way:holo_story:" .. tostring(holoID) .. ":ownerId") or 0
	return ownerID == SceneObject(pPlayer):getObjectID()
end

function MandoDailyHoloStory:sayLineEvent(pHolo, line)
	if (pHolo == nil or line == nil or line == "") then return end
	spatialChat(pHolo, line)
end

function MandoDailyHoloStory:deliverLines(pHolo, lines)
	if (pHolo == nil) then return 0 end
	local delay = 1000
	local finishDelay = delay
	for i = 1, #lines do
		if (lines[i] ~= nil and lines[i] ~= "") then
			createEvent(delay, "MandoDailyHoloStory", "sayLineEvent", pHolo, lines[i])
			finishDelay = delay + 3000
			delay = delay + self.LINE_GAP_MS
		end
	end
	return finishDelay
end

-- ---------------------------------------------------------------------------
-- Story beats
-- ---------------------------------------------------------------------------

-- Called when the player accepts a daily mission from the fob.
function MandoDailyHoloStory:onMissionAccepted(pPlayer, tier)
	if (pPlayer == nil) then return end
	local pHolo = self:spawnHolo(pPlayer)
	if (pHolo == nil) then return end

	local seed = self:storySeed(pPlayer)
	local dossier = self:getDossier(pPlayer)
	local lines = {}

	if (tier <= 1) then
		lines[#lines + 1] = self:pick(self.INTROS, seed, 2)
		lines[#lines + 1] = string.format(
			"The mark: %s - %s. Their operation runs deep; expect layers of hired muscle between you and them.",
			dossier.name, dossier.desc)
		lines[#lines + 1] = "First waypoint is on your fob. Work the chain, hunter. This is the Way."
	elseif (tier >= 5) then
		lines[#lines + 1] = string.format(
			"This is it, verd. %s has nowhere left to run. Final camp - their best people, their last credits.",
			dossier.name)
		lines[#lines + 1] = "Finish the chain. The guild is watching."
	else
		lines[#lines + 1] = string.format(
			"The trail on %s stays warm. Camp %s of the chain is marked on your fob.",
			dossier.name, tostring(tier))
		lines[#lines + 1] = self:pick(self.ESCALATIONS, seed, 10 + tier)
	end

	local finishDelay = self:deliverLines(pHolo, lines)
	createEvent(finishDelay, "MandoDailyHoloStory", "despawnHoloEvent", pHolo, "")
end

-- Called when a daily camp's mark goes down.
function MandoDailyHoloStory:onCampCompleted(pPlayer, tier)
	if (pPlayer == nil) then return end
	MandoWayOfLife:markDailyBountyTierComplete(pPlayer, tier)
	local pHolo = self:spawnHolo(pPlayer)
	if (pHolo == nil) then
		if (tier < MandoWayOfLife.DAILY_BOUNTY_MAX_MISSIONS) then
			local ok, msg = MandoWayOfLife:tryAcceptDailyBountyMission(pPlayer, "auto")
			CreatureObject(pPlayer):sendSystemMessage(msg)
		end
		return
	end

	local seed = self:storySeed(pPlayer)
	local dossier = self:getDossier(pPlayer)
	local lines = {}

	if (tier >= 5) then
		lines[#lines + 1] = "Good job, hunter. You took out the rogue IG88 trader."
		lines[#lines + 1] = self:pick(self.FINALES, seed, 50)
		lines[#lines + 1] = "This is the Way."
	else
		-- twist: not the real target; chain continues
		lines[#lines + 1] = self:pick(self.TWISTS, seed, 20 + tier)
		lines[#lines + 1] = string.format(
			"%s is still out there - but running out of places to hide. The next waypoint will follow this transmission.",
			dossier.name)
		lines[#lines + 1] = "This is the Way."
	end

	local finishDelay = self:deliverLines(pHolo, lines)
	local holoID = SceneObject(pHolo):getObjectID()
	createEvent(finishDelay, "MandoDailyHoloStory", "finishCompletionEvent", pPlayer, tostring(tier) .. ":" .. tostring(holoID))
end

function MandoDailyHoloStory:finishCompletionEvent(pPlayer, args)
	if (pPlayer == nil) then return end
	local tierText, holoText = string.match(args or "", "^(%d+):(%d+)$")
	local tier = tonumber(tierText)
	local holoID = tonumber(holoText)
	if (tier == nil or holoID == nil) then return end

	local playerID = SceneObject(pPlayer):getObjectID()
	local currentHoloID = tonumber(readData("mando_way:holo_story:" .. tostring(playerID) .. ":holoId")) or 0
	if (currentHoloID ~= holoID) then return end

	self:despawnHoloForPlayer(pPlayer)
	if (tier >= MandoWayOfLife.DAILY_BOUNTY_MAX_MISSIONS) then return end
	if (MandoWayOfLife:getDailyBountyCount(pPlayer) ~= tier or MandoWayOfLife:getDailyBountyReadyTier(pPlayer) ~= tier) then return end

	local ok, msg = MandoWayOfLife:tryAcceptDailyBountyMission(pPlayer, "auto")
	CreatureObject(pPlayer):sendSystemMessage(msg)
end

MandoDailyHoloMenuComponent = {}

function MandoDailyHoloMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	if (not MandoDailyHoloStory:isOwner(pSceneObject, pPlayer)) then return end
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)
	menuResponse:addRadialMenuItem(120, 3, "Mission Status")
end

function MandoDailyHoloMenuComponent:handleObjectMenuSelect(pObject, pPlayer, selectedID)
	if (not MandoDailyHoloStory:isOwner(pObject, pPlayer)) then
		if (pPlayer ~= nil) then CreatureObject(pPlayer):sendSystemMessage("This transmission is keyed to another hunter.") end
		return 0
	end
	SceneObject(pObject):faceObject(pPlayer, true)
	if (selectedID == 120) then
		MandoWayOfLife:showDailyBountyStatus(pPlayer)
	end
	return 0
end
