-- Mandalorian Foundling Informant Conversation Handler
-- Routes based on assignment state: assign / already assigned / turn in / not done

MandoFoundlingInformantConvoHandler = conv_handler:new {}

function MandoFoundlingInformantConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil) then return nil end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)

	local npcOid    = SceneObject(pNpc):getObjectID()
	local npcStr    = tostring(npcOid)
	local storedStr = MandoWayOfLife:readStr(pPlayer, "foundling.informantId")
	local ch0          = MandoWayOfLife:readInt(pPlayer, "chapter0Started")
	local arcComplete  = MandoWayOfLife:readInt(pPlayer, "foundling.arcComplete")
	local inArc        = (ch0 == 1 and arcComplete ~= 1)
	local tpl          = AiAgent(pNpc):getCreatureTemplateName()
	local isInformant  = (tpl == "mando_foundling_informant")

	MandoWayOfLife:logDiagPlayer(pPlayer, string.format(
		"Foundling informant getInitialScreen: ch0=%s arcComplete=%s inArc=%s isInformant=%s npcOid=%s",
		tostring(ch0), tostring(arcComplete), tostring(inArc), tostring(isInformant), tostring(npcOid)
	))

	if (not inArc) then
		return nil
	end

	-- Per-player dynamic spawn: stored OID must match. Static hub (city screenplay): key by current arc planet.
	local linked = (storedStr ~= "" and storedStr ~= "0" and npcStr == storedStr)
	local curPlanet = MandoWayOfLife:readStr(pPlayer, "foundling.currentPlanet")
	if (curPlanet == "") then
		local idx = MandoWayOfLife:readInt(pPlayer, "foundling.planetIndex")
		local pdata = MandoWayOfLife.planetData[idx]
		if (pdata ~= nil) then
			curPlanet = pdata.planet
		end
	end
	-- Compare OIDs as strings: Lua numbers can lose precision on 64-bit object ids.
	local staticKey = "mando_way:foundling_informant_static:" .. curPlanet
	local staticOidRaw = readData(staticKey)
	local staticOidStr = (staticOidRaw ~= nil and staticOidRaw ~= "") and tostring(staticOidRaw) or "0"
	local atStaticHub = (staticOidStr ~= "0" and npcStr == staticOidStr)

	-- Must be our template or the registered static hub object for this planet (OID match).
	if (not isInformant and not atStaticHub) then
		return nil
	end

	if (not linked) then
		-- Re-link if: (a) static hub OID matches, or (b) NPC template matches and player is in arc.
		-- Case (b) handles stale static keys after server restart or spawn failure on any planet.
		if (atStaticHub or isInformant) then
			MandoWayOfLife:writeStr(pPlayer, "foundling.informantId", npcStr)
			MandoWayOfLife:writeInt(pPlayer, "foundling.informantStatic", 1)
			-- Heal the static key so future lookups work without re-linking
			writeData(staticKey, npcOid)
			MandoWayOfLife:logDiagPlayer(pPlayer, string.format(
				"Foundling informant: re-linked to NPC oid=%s planet=%s (atStaticHub=%s isInformant=%s).",
				npcStr, tostring(curPlanet), tostring(atStaticHub), tostring(isInformant)
			))
			-- Re-grant waypoint in case it was lost
			local countingEnabled = MandoWayOfLife:readInt(pPlayer, "foundling.planetCountingEnabled")
			local planetDone = MandoWayOfLife:readInt(pPlayer, "foundling.planetDone")
			if (countingEnabled ~= 1) then
				local idx = MandoWayOfLife:readInt(pPlayer, "foundling.planetIndex")
				local pdata = MandoWayOfLife.planetData[idx]
				if (pdata ~= nil) then
					MandoWayOfLife:grantInformantWaypoint(pPlayer, pdata)
				end
			elseif (planetDone == 1) then
				MandoWayOfLife:grantReturnToInformantWaypoint(pPlayer)
			end
			linked = true
		end
	end

	if (not linked) then
		MandoWayOfLife:logDiagPlayer(pPlayer, "Foundling informant: no link established — returning nil.")
		return nil
	end

	local countingEnabled = MandoWayOfLife:readInt(pPlayer, "foundling.planetCountingEnabled")
	local planetDone      = MandoWayOfLife:readInt(pPlayer, "foundling.planetDone")

	if (countingEnabled == 1 and planetDone == 1) then
		-- Quota met — ready to turn in
		local index = MandoWayOfLife:readInt(pPlayer, "foundling.planetIndex")
		if (index >= 10) then
			return convoTemplate:getScreen("turnin_final")
		end
		return convoTemplate:getScreen("turnin")
	end

	if (countingEnabled == 1 and planetDone == 0) then
		-- Still working — send remaining count as a system message, then show already_assigned screen
		local done   = MandoWayOfLife:readInt(pPlayer, "foundling.planetCompleted")
		local target = MandoWayOfLife:readInt(pPlayer, "foundling.planetTarget")
		local remaining = math.max(0, target - done)
		CreatureObject(pPlayer):sendSystemMessage(string.format(
			"[Mandalorian contact] You have your assignment. Missions completed: %s/%s. %s remaining.",
			tostring(done), tostring(target), tostring(remaining)
		))
		return convoTemplate:getScreen("already_assigned")
	end

	-- Not yet accepted assignment
	return convoTemplate:getScreen("intro")
end

function MandoFoundlingInformantConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then return pConvScreen end

	local screen   = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	if (screenID == "assign_confirm") then
		MandoWayOfLife:logDiagPlayer(pPlayer, "Foundling informant convo: assign_confirm (planet mission quota).")
		MandoWayOfLife:acceptPlanetAssignment(pPlayer)

	elseif (screenID == "check_turnin") then
		local convoTemplate = LuaConversationTemplate(pConvTemplate)
		if (MandoWayOfLife:readInt(pPlayer, "foundling.planetDone") == 1) then
			local index = MandoWayOfLife:readInt(pPlayer, "foundling.planetIndex")
			if (index >= 10) then
				return convoTemplate:getScreen("turnin_final")
			end
			return convoTemplate:getScreen("turnin")
		else
			return convoTemplate:getScreen("not_done")
		end

	elseif (screenID == "turnin" or screenID == "turnin_final") then
		MandoWayOfLife:logDiagPlayer(pPlayer, "Foundling informant convo: " .. screenID .. " (planet turn-in).")
		MandoWayOfLife:turnInPlanet(pPlayer)
	end

	return pConvScreen
end
