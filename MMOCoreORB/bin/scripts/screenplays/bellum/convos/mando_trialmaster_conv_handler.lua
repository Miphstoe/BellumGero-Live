-- Mandalorian Trialmaster Conversation Handler
-- Routes player to the correct screen based on progression state

MandoTrialmasterConvoHandler = conv_handler:new {}

function MandoTrialmasterConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil) then return nil end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)
	local ch = MandoWayOfLife:getChapter(pPlayer)

	-- Chapter 5 complete — Mandalorian (true final state)
	if (MandoWayOfLife:readInt(pPlayer, "chapter5Complete") == 1) then
		local pBase = convoTemplate:getScreen("clanbound")
		local pCloned = LuaConversationScreen(pBase):cloneScreen()
		LuaConversationScreen(pCloned):setCustomDialogText(
			"You are Mandalorian. There is nothing left here to prove. Well fought."
		)
		return pCloned
	end

	-- Chapter 4 complete — Clanbound. Check Jabba gate for Mandalorian title.
	if (MandoWayOfLife:readInt(pPlayer, "chapter4Complete") == 1) then
		local pGhost = CreatureObject(pPlayer):getPlayerObject()
		local pBase = convoTemplate:getScreen("clanbound")
		if (pGhost ~= nil and PlayerObject(pGhost):hasBadge(MandoWayOfLife.JABBA_THEMEPARK_BADGE)) then
			-- Player earned the Jabba badge: grant Mandalorian rank now
			MandoWayOfLife:grantMandalorian(pPlayer)
			local pCloned = LuaConversationScreen(pBase):cloneScreen()
			LuaConversationScreen(pCloned):setCustomDialogText(
				"Word of your deeds reached me before you did. The Hunts have spoken. You are Mandalorian. Wear the title."
			)
			return pCloned
		end
		-- No Jabba badge yet: send them to earn it
		local pCloned = LuaConversationScreen(pBase):cloneScreen()
		LuaConversationScreen(pCloned):setCustomDialogText(
			"You are Clanbound. The last trial runs through the Hutts on Tatooine. When you want the full brief, ask me what comes next."
		)
		return pCloned
	end

	-- Arc complete + Novice BH: ready for chapter gate cycle
	if (MandoWayOfLife:isArcComplete(pPlayer)) then
		if (not CreatureObject(pPlayer):hasSkill("combat_bountyhunter_novice")) then
			return convoTemplate:getScreen("arc_complete_no_bh")
		end
		return convoTemplate:getScreen("chapter_gate_ready")
	end

	-- Arc started but not complete: player is mid-arc
	if (MandoWayOfLife:readInt(pPlayer, "chapter0Started") == 1) then
		MandoWayOfLife:ensureFoundlingInformant(pPlayer)
		return convoTemplate:getScreen("arc_in_progress")
	end

	-- Prerequisites not met
	if (not MandoWayOfLife:meetsPrerequisites(pPlayer)) then
		return convoTemplate:getScreen("prereqs_missing")
	end

	-- Ready to start arc
	return convoTemplate:getScreen("arc_accept")
end

function MandoTrialmasterConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then return pConvScreen end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	if (screenID == "arc_start") then
		MandoWayOfLife:logDiagPlayer(pPlayer, "Trialmaster convo: arc_start (Foundling arc).")
		MandoWayOfLife:startFoundlingArc(pPlayer)

	elseif (screenID == "foundling_status") then
		-- Player asked for Foundling arc status while mid-arc; details go to system messages (no multi-line sendSystemMessage).
		MandoWayOfLife:sendFoundlingStatusReportToPlayer(pPlayer)

	elseif (screenID == "mando_way_status") then
		-- Same report as spatial !foundling / !mando (stock clients block /slash aliases).
		MandoWayOfLife:sendFoundlingStatusReportToPlayer(pPlayer)

	elseif (screenID == "foundling_resync") then
		-- Force despawn + respawn informant and re-grant waypoints for current planetIndex (stuck contact / bad OID).
		MandoWayOfLife:resyncFoundlingContactAndWaypoints(pPlayer)

	elseif (screenID == "buy_mando_armory_1" or screenID == "buy_mando_armory_2" or screenID == "buy_mando_armory_3") then
		local tier = 1
		if (screenID == "buy_mando_armory_2") then tier = 2 end
		if (screenID == "buy_mando_armory_3") then tier = 3 end
		local ok, msg = MandoWayOfLife:trySellMandoArmorySchematic(pPlayer, tier)
		local luaScreen = LuaConversationScreen(pConvScreen)
		local pCloned = luaScreen:cloneScreen()
		local cloned = LuaConversationScreen(pCloned)
		cloned:setCustomDialogText(msg)
		cloned:setStopConversation(true)
		if (ok) then
			MandoWayOfLife:logDiagPlayer(pPlayer, string.format("Trialmaster: armory schematic sale OK tier=%s.", tostring(tier)))
		else
			MandoWayOfLife:logDiagPlayer(pPlayer, string.format("Trialmaster: armory schematic sale blocked tier=%s.", tostring(tier)))
		end
		return pCloned

	elseif (screenID == "clanbound_whats_next") then
		local luaScreen = LuaConversationScreen(pConvScreen)
		local pCloned = luaScreen:cloneScreen()
		local cloned = LuaConversationScreen(pCloned)
		local msg

		if (MandoWayOfLife:readInt(pPlayer, "chapter5Complete") == 1) then
			msg =
				"The Hutts already weighed you. The Guild trail is behind you. What remains is to live the Creed in every contract you take. "
				.. "There is no higher rank here. Walk it, or set the helmet down. This is the Way!"
		else
			local pGhost = CreatureObject(pPlayer):getPlayerObject()
			if (pGhost ~= nil and PlayerObject(pGhost):hasBadge(MandoWayOfLife.JABBA_THEMEPARK_BADGE)) then
				msg =
					"Your proof with the Hutts is already on record. If the Mandalorian title did not land, close this talk and speak to me again."
			else
				msg =
					"Seek the Hutts on Tatooine. Complete the work Jabba's people set before you. "
					.. "That labor is your final testament to your dedication to the religion. "
					.. "When their operations are finished, return to me. This is the Way!"
			end
		end

		cloned:setCustomDialogText(msg)
		cloned:setStopConversation(true)
		MandoWayOfLife:logDiagPlayer(pPlayer, "Trialmaster convo: clanbound_whats_next.")
		return pCloned

	elseif (screenID == "chapter_gate_ready") then
		local luaScreen = LuaConversationScreen(pConvScreen)
		local counting = MandoWayOfLife:readInt(pPlayer, "countingEnabled")
		local needTrial = MandoWayOfLife:readInt(pPlayer, "needsCustomContract")
		local trialing = MandoWayOfLife:readInt(pPlayer, "privateContractActive")

		if (trialing == 1) then
			MandoWayOfLife:logDiagPlayer(pPlayer, "Trialmaster convo: chapter_gate_ready (private trial active).")
			local pCloned = luaScreen:cloneScreen()
			local cloned = LuaConversationScreen(pCloned)
			cloned:setCustomDialogText("You already have a private trial running. Finish that contract before we speak of the next step.")
			return pCloned
		end

		if (needTrial == 1) then
			MandoWayOfLife:logDiagPlayer(pPlayer, "Trialmaster convo: chapter_gate_ready (5/5 done — trial at operative).")
			MandoWayOfLife:grantChapterGateBriefingWaypoints(pPlayer, true)
			local pCloned = luaScreen:cloneScreen()
			local cloned = LuaConversationScreen(pCloned)
			cloned:setCustomDialogText("Your five Spynet contracts are logged. Return to the Mandalorian Operative on Corellia for the one private trial, solo, Foundling helmet on. I refreshed your datapad waypoints.")
			return pCloned
		end

		if (counting == 1) then
			MandoWayOfLife:logDiagPlayer(pPlayer, "Trialmaster convo: chapter_gate_ready (Spynet count in progress).")
			MandoWayOfLife:grantChapterGateBriefingWaypoints(pPlayer, true)
			local pCloned = luaScreen:cloneScreen()
			local cloned = LuaConversationScreen(pCloned)
			cloned:setCustomDialogText("Your Spynet count is already open. Keep pulling NPC bounties from Bounty Hunter mission terminals until your system shows five confirmed. I refreshed your Corellia waypoints.")
			return pCloned
		end

		MandoWayOfLife:logDiagPlayer(pPlayer, "Trialmaster convo: chapter_gate_ready (first briefing + waypoints).")
		MandoWayOfLife:grantChapterGateBriefingWaypoints(pPlayer, false)
	end

	return pConvScreen
end
