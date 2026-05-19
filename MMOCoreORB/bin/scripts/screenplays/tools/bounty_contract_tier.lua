-- Bounty hunter terminal: choose NPC contract tier (mirrors mission_direction_choice pattern).
-- Preference stored on PlayerObject screenplay data: bounty_contract_tier / tierChoice
-- Values: auto | 1 | 2 | 3 | 4  (consumed by MissionManagerImplementation::randomizeGenericBountyMission)

bounty_contract_tier = ScreenPlay:new {
	numberOfActs = 1,

	-- Fixed row order must match tierSelection() keys below.
	rows = {
		{ key = "auto", label = "Automatic. Use highest tier my Investigation skills allow" },
		{ key = "1",    label = "Easy: Tier 1 (Novice contracts)" },
		{ key = "2",    label = "Standard: Tier 2 (requires Investigation I)" },
		{ key = "3",    label = "Hard: Tier 3 (requires Investigation III)" },
		{ key = "4",    label = "Elite: Tier 3 pool + higher guild mark odds (Investigation IV)" },
	},
}

function bounty_contract_tier:start()
end

function bounty_contract_tier:openWindow(pPlayer)
	if pPlayer == nil then
		return
	end

	local creo = CreatureObject(pPlayer)
	if creo == nil or not creo:hasSkill("combat_bountyhunter_novice") then
		return
	end

	local sui = SuiListBox.new("bounty_contract_tier", "tierSelection")
	sui.setTargetNetworkId(SceneObject(pPlayer):getObjectID())
	sui.setTitle("Bounty contract tier")
	sui.setPrompt(
		"Choose what difficulty the bounty terminal should roll when you use List Missions.\n\n" ..
		"Mandalorian Spynet chapter progress (the five NPC terminal bounties after the operative opens your count) still counts " ..
		"any NPC mark from a Bounty Hunter terminal. Easy, Standard, or Hard: your tier choice does not change that.\n\n" ..
		"Automatic matches classic behavior (highest tier your Investigation skills support).\n\n" ..
		"Fixed tiers let you stay on easier contracts after training, or pick Hard once you have Investigation III. " ..
		"Your choice is saved until you change it here."
	)

	for i = 1, #self.rows, 1 do
		sui.add(self.rows[i].label, "")
	end

	sui.sendTo(pPlayer)
end

function bounty_contract_tier:tierSelection(pPlayer, pSui, eventIndex, args)
	if eventIndex == 1 then
		return
	end

	if args == "-1" then
		CreatureObject(pPlayer):sendSystemMessage("No contract tier was selected.")
		return
	end

	local selectedIndex = tonumber(args) + 1
	if selectedIndex < 1 or selectedIndex > #bounty_contract_tier.rows then
		return
	end

	local row = bounty_contract_tier.rows[selectedIndex]
	local key = row.key
	local creo = CreatureObject(pPlayer)

	if key == "2" and not creo:hasSkill("combat_bountyhunter_investigation_01") then
		creo:sendSystemMessage("You need Investigation I before you can request standard (Tier 2) contracts.")
		return
	end

	if key == "3" and not creo:hasSkill("combat_bountyhunter_investigation_03") then
		creo:sendSystemMessage("You need Investigation III before you can request hard (Tier 3) contracts.")
		return
	end

	if key == "4" and not creo:hasSkill("combat_bountyhunter_investigation_04") then
		creo:sendSystemMessage("You need Investigation IV before you can select the elite listing.")
		return
	end

	writeScreenPlayData(pPlayer, "bounty_contract_tier", "tierChoice", key)

	if key == "auto" then
		creo:sendSystemMessage("Bounty terminal difficulty: Automatic (matches your Investigation training). Use List Missions to refresh offers.")
	else
		creo:sendSystemMessage("Bounty terminal difficulty locked to: " .. row.label .. ". Use List Missions to refresh offers.")
	end
end
