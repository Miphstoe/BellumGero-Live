-- Mandalorian Trialmaster Conversation Handler
-- Routes player to the correct screen based on progression state

MandoTrialmasterConvoHandler = conv_handler:new {}

function MandoTrialmasterConvoHandler:withRecruiterRetroOptions(pPlayer, pNpc, pScreen)
	if (pScreen == nil or pPlayer == nil or pNpc == nil) then return pScreen end
	if (not MandoWayOfLife:isMandoRecruiterNpc(pNpc)) then
		MandoWayOfLife:logDiagPlayer(pPlayer, "withRecruiterRetroOptions: NOT recruiter NPC, skipping")
		return pScreen
	end

	local pCloned = LuaConversationScreen(pScreen):cloneScreen()
	local cloned = LuaConversationScreen(pCloned)
	local added = false

	MandoWayOfLife:logDiagPlayer(pPlayer, string.format(
		"withRecruiterRetroOptions: isMandoTribesman=%s hasBicepBracerRetroClaimed=%s screenID=%s",
		tostring(MandoWayOfLife:isMandoTribesman(pPlayer)),
		tostring(MandoWayOfLife:hasAccountBicepBracerRetroClaimed(pPlayer)),
		tostring(LuaConversationScreen(pScreen):getScreenID())
	))

	if (not MandoWayOfLife:hasAccountArmorRetroClaimed(pPlayer)) then
		cloned:addOption(
			"Reissue all Way armor sets (once per account).",
			"mando_armor_retro"
		)
		added = true
	end

	if (not MandoWayOfLife:hasAccountTitleRetroClaimed(pPlayer)) then
		local maxChapter = MandoWayOfLife:getHighestEarnedChapter(pPlayer)
		if (maxChapter >= 0 and MandoWayOfLife:countMissingChapterTitleSkills(pPlayer, maxChapter) > 0) then
			cloned:addOption(
				"Restore my Way rank titles (once per account).",
				"mando_title_retro"
			)
			added = true
		end
	end

	if (not MandoWayOfLife:hasAccountSchematicExchangeClaimed(pPlayer)) then
		local oldCount = MandoWayOfLife:countOldMandalorianSchematics(pPlayer)
		if (oldCount > 0) then
			cloned:addOption(
				"Exchange old Mandalorian armor schematics for learnable versions (once per account).",
				"mando_schematic_exchange"
			)
			added = true
		end
	end

	if (MandoWayOfLife:isMandoTribesman(pPlayer)) then
		cloned:addOption(
			"Request Daily Bounty Mission Fob.",
			"mando_daily_bounty_fob"
		)
		added = true
	end

	if (MandoWayOfLife:isMandoTribesman(pPlayer) and not MandoWayOfLife:hasAccountBicepBracerRetroClaimed(pPlayer)) then
		cloned:addOption(
			"Claim missing Tribesman bicep and bracer armor pieces (one-time per account).",
			"mando_bicep_bracer_retro"
		)
		added = true
	end

	if (not added) then return pScreen end
	return pCloned
end

function MandoTrialmasterConvoHandler:getArcAcceptScreen(pPlayer, convoTemplate)
	local pBase = convoTemplate:getScreen("arc_accept")
	if (pPlayer ~= nil and CreatureObject(pPlayer):hasSkill("combat_bountyhunter_novice")) then
		local pCloned = LuaConversationScreen(pBase):cloneScreen()
		LuaConversationScreen(pCloned):setCustomDialogText(
			"Greetings Bounty Hunter, we've heard of your talent and reputation. We welcome you, but you still have to prove yourself with the tribe. This is the Way! "
			.. "Ten worlds. Each one will test a different part of you. Your contact on each planet will give you work. Destroy missions. Delivery runs. Standard terminals only. This is Mandalorian proving, not Guild business. When the last planet is done, come find me."
		)
		return pCloned
	end
	return pBase
end

function MandoTrialmasterConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil) then return nil end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)
	local ch = MandoWayOfLife:getChapter(pPlayer)

	-- Account-wide completion: any character on the account can use the armory shop once the Way is finished.
	MandoWayOfLife:ensureAccountMandoWayComplete(pPlayer)
	if (MandoWayOfLife:isAccountMandoWayComplete(pPlayer)) then
		local pBase = convoTemplate:getScreen("tribesman_hub")
		local pCloned = LuaConversationScreen(pBase):cloneScreen()
		LuaConversationScreen(pCloned):setCustomDialogText(
			"Your account has walked the whole Way. The clan armory is open to you."
		)
		return self:withRecruiterRetroOptions(pPlayer, pNpc, pCloned)
	end

	-- Chapter 5 complete — Mandalorian Tribesman (true final state)
	if (MandoWayOfLife:readInt(pPlayer, "chapter5Complete") == 1) then
		local pBase = convoTemplate:getScreen("clanbound")
		local pCloned = LuaConversationScreen(pBase):cloneScreen()
		LuaConversationScreen(pCloned):setCustomDialogText(
			"You are a Mandalorian Tribesman. There is nothing left here to prove. Well fought."
		)
		-- Armory schematics open only to a finished Tribesman (final phase of the Way).
		LuaConversationScreen(pCloned):addOption("Armory schematics.", "mando_armory_shop")
		return self:withRecruiterRetroOptions(pPlayer, pNpc, pCloned)
	end

	-- Chapter 4 complete — Clanbound. Check Jabba gate for Mandalorian Tribesman title.
	if (MandoWayOfLife:readInt(pPlayer, "chapter4Complete") == 1) then
		local pGhost = CreatureObject(pPlayer):getPlayerObject()
		local pBase = convoTemplate:getScreen("clanbound")
		if (pGhost ~= nil and PlayerObject(pGhost):hasBadge(MandoWayOfLife.JABBA_THEMEPARK_BADGE)) then
			-- Player earned the Jabba badge: grant Mandalorian Tribesman rank now
			MandoWayOfLife:grantMandalorian(pPlayer)
			local pCloned = LuaConversationScreen(pBase):cloneScreen()
			LuaConversationScreen(pCloned):setCustomDialogText(
				"Word of your deeds reached me before you did. The Hunts have spoken. You are a Mandalorian Tribesman. Wear the title."
			)
			return self:withRecruiterRetroOptions(pPlayer, pNpc, pCloned)
		end
		-- No Jabba badge yet: send them to earn it
		local pCloned = LuaConversationScreen(pBase):cloneScreen()
		LuaConversationScreen(pCloned):setCustomDialogText(
			"You are Clanbound. The last trial runs through the Hutts on Tatooine. When you want the full brief, ask me what comes next."
		)
		return self:withRecruiterRetroOptions(pPlayer, pNpc, pCloned)
	end

	-- Arc complete + Novice BH: ready for chapter gate cycle
	if (MandoWayOfLife:isArcComplete(pPlayer)) then
		if (not CreatureObject(pPlayer):hasSkill("combat_bountyhunter_novice")) then
			return self:withRecruiterRetroOptions(pPlayer, pNpc, convoTemplate:getScreen("arc_complete_no_bh"))
		end
		return self:withRecruiterRetroOptions(pPlayer, pNpc, convoTemplate:getScreen("chapter_gate_ready"))
	end

	-- Arc started but not complete: player is mid-arc
	if (MandoWayOfLife:readInt(pPlayer, "chapter0Started") == 1) then
		MandoWayOfLife:ensureFoundlingInformant(pPlayer)
		return self:withRecruiterRetroOptions(pPlayer, pNpc, convoTemplate:getScreen("arc_in_progress"))
	end

	-- Prerequisites not met
	if (not MandoWayOfLife:meetsPrerequisites(pPlayer)) then
		return self:withRecruiterRetroOptions(pPlayer, pNpc, convoTemplate:getScreen("prereqs_missing"))
	end

	-- Ready to start arc
	return self:withRecruiterRetroOptions(pPlayer, pNpc, self:getArcAcceptScreen(pPlayer, convoTemplate))
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

	elseif (screenID == "mando_armor_retro_grant") then
		if (not MandoWayOfLife:isMandoRecruiterNpc(pNpc)) then
			local luaScreen = LuaConversationScreen(pConvScreen)
			local pCloned = luaScreen:cloneScreen()
			local cloned = LuaConversationScreen(pCloned)
			cloned:setCustomDialogText("That reissue is handled by the Mandalorian Recruiter in the Mos Eisley cantina.")
			cloned:setStopConversation(true)
			return pCloned
		end
		local ok, msg = MandoWayOfLife:tryGrantAccountArmorRetro(pPlayer)
		local luaScreen = LuaConversationScreen(pConvScreen)
		local pCloned = luaScreen:cloneScreen()
		local cloned = LuaConversationScreen(pCloned)
		cloned:setCustomDialogText(msg)
		cloned:setStopConversation(true)
		MandoWayOfLife:logDiagPlayer(pPlayer, string.format("Recruiter convo: mando_armor_retro_grant ok=%s.", tostring(ok)))
		return pCloned

	elseif (screenID == "mando_title_retro_grant") then
		if (not MandoWayOfLife:isMandoRecruiterNpc(pNpc)) then
			local luaScreen = LuaConversationScreen(pConvScreen)
			local pCloned = luaScreen:cloneScreen()
			local cloned = LuaConversationScreen(pCloned)
			cloned:setCustomDialogText("That restoration is handled by the Mandalorian Recruiter in the Mos Eisley cantina.")
			cloned:setStopConversation(true)
			return pCloned
		end
		local ok, msg = MandoWayOfLife:tryGrantAccountTitleRetro(pPlayer)
		local luaScreen = LuaConversationScreen(pConvScreen)
		local pCloned = luaScreen:cloneScreen()
		local cloned = LuaConversationScreen(pCloned)
		cloned:setCustomDialogText(msg)
		cloned:setStopConversation(true)
		MandoWayOfLife:logDiagPlayer(pPlayer, string.format("Recruiter convo: mando_title_retro_grant ok=%s.", tostring(ok)))
		return pCloned

	elseif (screenID == "mando_schematic_exchange") then
		if (not MandoWayOfLife:isMandoRecruiterNpc(pNpc)) then
			local luaScreen = LuaConversationScreen(pConvScreen)
			local pCloned = luaScreen:cloneScreen()
			local cloned = LuaConversationScreen(pCloned)
			cloned:setCustomDialogText("That exchange is handled by the Mandalorian Recruiter in the Mos Eisley cantina.")
			cloned:setStopConversation(true)
			return pCloned
		end
		local ok, msg = MandoWayOfLife:tryExchangeMandalorianSchematics(pPlayer)
		local luaScreen = LuaConversationScreen(pConvScreen)
		local pCloned = luaScreen:cloneScreen()
		local cloned = LuaConversationScreen(pCloned)
		cloned:setCustomDialogText(msg)
		cloned:setStopConversation(true)
		MandoWayOfLife:logDiagPlayer(pPlayer, string.format("Recruiter convo: mando_schematic_exchange ok=%s.", tostring(ok)))
		return pCloned

	elseif (screenID == "mando_daily_bounty_fob") then
		if (not MandoWayOfLife:isMandoRecruiterNpc(pNpc)) then
			local luaScreen = LuaConversationScreen(pConvScreen)
			local pCloned = luaScreen:cloneScreen()
			local cloned = LuaConversationScreen(pCloned)
			cloned:setCustomDialogText("That fob is handled by the Mandalorian Recruiter in the Mos Eisley cantina.")
			cloned:setStopConversation(true)
			return pCloned
		end
		local ok, msg = MandoWayOfLife:tryGrantDailyBountyFob(pPlayer)
		local luaScreen = LuaConversationScreen(pConvScreen)
		local pCloned = luaScreen:cloneScreen()
		local cloned = LuaConversationScreen(pCloned)
		cloned:setCustomDialogText(msg)
		cloned:setStopConversation(true)
		MandoWayOfLife:logDiagPlayer(pPlayer, string.format("Recruiter convo: mando_daily_bounty_fob ok=%s.", tostring(ok)))
		return pCloned

	elseif (screenID == "mando_bicep_bracer_retro") then
		if (not MandoWayOfLife:isMandoRecruiterNpc(pNpc)) then
			local luaScreen = LuaConversationScreen(pConvScreen)
			local pCloned = luaScreen:cloneScreen()
			local cloned = LuaConversationScreen(pCloned)
			cloned:setCustomDialogText("That grant is handled by the Mandalorian Recruiter in the Mos Eisley cantina.")
			cloned:setStopConversation(true)
			return pCloned
		end
		local ok, msg = MandoWayOfLife:tryGrantAccountBicepBracerRetro(pPlayer)
		local luaScreen = LuaConversationScreen(pConvScreen)
		local pCloned = luaScreen:cloneScreen()
		local cloned = LuaConversationScreen(pCloned)
		cloned:setCustomDialogText(msg)
		cloned:setStopConversation(true)
		MandoWayOfLife:logDiagPlayer(pPlayer, string.format("Recruiter convo: mando_bicep_bracer_retro ok=%s.", tostring(ok)))
		return pCloned

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
				"You stand as a Mandalorian Tribesman. The Hutts already weighed you. The Guild trail is behind you. What remains is to live the Creed in every contract you take. "
				.. "There is no higher rank here. Walk it, or set the helmet down. This is the Way!"
		else
			local pGhost = CreatureObject(pPlayer):getPlayerObject()
			if (pGhost ~= nil and PlayerObject(pGhost):hasBadge(MandoWayOfLife.JABBA_THEMEPARK_BADGE)) then
				msg =
					"Your proof with the Hutts is already on record. If the Mandalorian Tribesman title did not land, close this talk and speak to me again."
			else
				msg =
					"Seek the Hutts on Tatooine. Complete the work Jabba's people set before you. "
					.. "That labor is your final testament before the Mandalorian Tribesman rank. "
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
