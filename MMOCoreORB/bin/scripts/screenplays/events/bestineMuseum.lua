local ObjectManager = require("managers.object.object_manager")

BestineMuseumScreenPlay = ScreenPlay:new {
	numberOfActs = 1,
	screenplayName = "BestineMuseumScreenPlay",

	restrictSinglePurchase = false -- False during live
}

MUSEUM_VOTING_ENABLED = 1
SIT = 1
STAND = 0

local PHASE_CHANGE_TIME = 3 * 24 * 60 * 60 * 1000 -- 3 days

local artistMobiles = { "vanvi_hotne", "kolka_zteht", "giaal_itotr", "kahfr_oladi", "klepa_laeel", "boulo_siesi" }
local artistPaintings = {
	{ "boffa", "ronka", "mattberry", "blumbush" },
	{ "blueleaf_temple", "house" },
	{ "lucky_despot", "krayt_skeleton" },
	{ "moncal_eye_01", "moncal_eye_02" },
	{ "rainbow_berry_bush", "raventhorn" },
	{ "golden_flower_01", "golden_flower_02", "golden_flower_03" }
}

local artistPaintingZAxis = {
	{ 1, 1.5, 1.5, 1 },
	{ 1.5, 1.5 },
	{ 2.5, 2.5 },
	{ 1, 1 },
	{ 1.5, 1 },
	{ 1, 1, 1 }
}


local artistMobiles = {
	{ template = "vanvi_hotne", x = 3312.29, z = 5, y = -4655.46, direction = 228.889, cellID = 0, position = STAND },
	{ template = "kolka_zteht", x = 1521.78, z = 7, y = 3259.81, direction = 184.256, cellID = 0, position = STAND },
	{ template = "giaal_itotr", x = -3102.7, z = 5, y = 2185, direction = 118, cellID = 0, position = SIT },
	{ template = "kahfr_oladi", x = 3473.4, z = 5, y = -4974.8, direction = 104, cellID = 0, position = SIT },
	{ template = "klepa_laeel", x = -2769.5, z = 5, y = 2111.1, direction = 104, cellID = 0, position = SIT },
	{ template = "boulo_siesi", x = -5240.7, z = 75, y = -6567.7, direction = 59, cellID = 0, position = SIT },
	{ template = "lilas_dinhint", x = 22.6945, z = 0.198179, y = -0.151074, direction = -79, cellID = 1028172, position = STAND }
}

registerScreenPlay("BestineMuseumScreenPlay", true)

-- All purchasable Bestine painting schematics shown in the SUI picker.
BestineMuseumScreenPlay.purchasablePaintings = {
	{ name = "Boffa Painting (Vanvi Hotne)",           schematic = "object/tangible/loot/bestine/bestine_painting_schematic_boffa.iff" },
	{ name = "Ronka Painting (Vanvi Hotne)",           schematic = "object/tangible/loot/bestine/bestine_painting_schematic_ronka.iff" },
	{ name = "Mattberry Painting (Vanvi Hotne)",       schematic = "object/tangible/loot/bestine/bestine_painting_schematic_mattberry.iff" },
	{ name = "Blumbush Painting (Vanvi Hotne)",        schematic = "object/tangible/loot/bestine/bestine_painting_schematic_blumbush.iff" },
	{ name = "Blueleaf Temple (Kolka Zteht)",          schematic = "object/tangible/loot/bestine/bestine_painting_schematic_blueleaf_temple.iff" },
	{ name = "House Painting (Kolka Zteht)",           schematic = "object/tangible/loot/bestine/bestine_painting_schematic_house.iff" },
	{ name = "Lucky Despot (Giaal Itotr)",             schematic = "object/tangible/loot/bestine/bestine_painting_schematic_lucky_despot.iff" },
	{ name = "Krayt Skeleton (Giaal Itotr)",           schematic = "object/tangible/loot/bestine/bestine_painting_schematic_krayt_skeleton.iff" },
	{ name = "Mon Cal Eye I (Kahfr Oladi)",            schematic = "object/tangible/loot/bestine/bestine_painting_schematic_moncal_eye_01.iff" },
	{ name = "Mon Cal Eye II (Kahfr Oladi)",           schematic = "object/tangible/loot/bestine/bestine_painting_schematic_moncal_eye_02.iff" },
	{ name = "Rainbow Berry Bush (Klepa Laeel)",       schematic = "object/tangible/loot/bestine/bestine_painting_schematic_rainbow_berry_bush.iff" },
	{ name = "Raventhorn Painting (Klepa Laeel)",      schematic = "object/tangible/loot/bestine/bestine_painting_schematic_raventhorn.iff" },
	{ name = "Golden Flower I (Boulo Siesi)",          schematic = "object/tangible/loot/bestine/bestine_painting_schematic_golden_flower_01.iff" },
	{ name = "Golden Flower II (Boulo Siesi)",         schematic = "object/tangible/loot/bestine/bestine_painting_schematic_golden_flower_02.iff" },
	{ name = "Golden Flower III (Boulo Siesi)",        schematic = "object/tangible/loot/bestine/bestine_painting_schematic_golden_flower_03.iff" },
}

function BestineMuseumScreenPlay:start()
	if (isZoneEnabled("tatooine")) then
		self:spawnMobiles()
		self:doPhaseInit()
	end
end

function BestineMuseumScreenPlay:doPhaseInit()
	if (MUSEUM_VOTING_ENABLED == 0) then
		return 0
	end

	local phase = self:getCurrentPhase()

	if (phase == nil) then
		self:setCurrentPhase(1)
		self:resetAllVotes()
		self:resetVotedList()
		self:resetAllTalkedToLists()
		self:resetPurchasedList()
		self:chooseArtists()
	end

	local winningArtist = self:getWinningArtistID()
	local winningPainting = self:getWinningPainting()
	if (winningArtist ~= "" and winningPainting ~= "") then
		self:spawnVisualPainting(winningArtist, winningPainting)
	end

	if (not hasServerEvent("MuseumPhaseChange")) then
		BestineMuseumScreenPlay:createEvent()
	end

	local phaseChangeTimeLeft = self.getPhaseTimeLeft()
	if (phaseChangeTimeLeft > PHASE_CHANGE_TIME or phaseChangeTimeLeft < 0) then
		rescheduleServerEvent("MuseumPhaseChange", PHASE_CHANGE_TIME)
	end
end

function BestineMuseumScreenPlay:createEvent()
	local eventID = createServerEvent(PHASE_CHANGE_TIME, "BestineMuseumScreenPlay", "doPhaseChange", "MuseumPhaseChange")
	setQuestStatus("bestine_museum:event_id", eventID)
end

function BestineMuseumScreenPlay:spawnMobiles()
	for i = 1, # artistMobiles do
		local npcData = artistMobiles[i]
		local pNpc = spawnMobile("tatooine", npcData.template, 1, npcData.x, npcData.z, npcData.y, npcData.direction, npcData.cellID)
		if pNpc ~= nil and npcData.position == SIT then
			CreatureObject(pNpc):setState(SITTINGONCHAIR)
		end
	end
end

function BestineMuseumScreenPlay:doPhaseChange()
	if (MUSEUM_VOTING_ENABLED == 0) then
		return 0
	end

	printf("[BestineMuseum] Initiating phase change.\n")

	local currentPhase = self:getCurrentPhase()
	if (currentPhase == 1) then
		self:determinePhaseWinner()
		self:setCurrentPhase(2)
	else
		self:setCurrentPhase(1)
		self:resetAllVotes()
		self:resetVotedList()
		self:resetAllTalkedToLists()
		self:resetPurchasedList()
		self:chooseArtists()
	end

	if (not hasServerEvent("MuseumPhaseChange")) then
		BestineMuseumScreenPlay:createEvent()
	else
		rescheduleServerEvent("MuseumPhaseChange", PHASE_CHANGE_TIME)
	end
end

function BestineMuseumScreenPlay:chooseArtists()
	local artists
	local artistCount = 0
	while artistCount < 3 do
		local randomArtist = getRandomNumber(1,6)
		if artists == nil then
			artists = randomArtist
			artistCount = artistCount + 1
		elseif(string.find(artists, randomArtist) == nil) then
			artists = artists .. "," .. randomArtist
			artistCount = artistCount + 1
		end
	end
	setQuestStatus("bestine_museum:current_artists", artists)
end

function BestineMuseumScreenPlay:determinePhaseWinner()
	local artistVotes = { }
	local winningArtist
	local artists = self:getCurrentArtists()
	local currentArtists = self:splitString(artists, ",")
	for i = 1, 3, 1 do
		if winningArtist == nil then
			winningArtist = tonumber(currentArtists[i])
		elseif self:getArtistVotes(currentArtists[i]) > self:getArtistVotes(winningArtist) then
			winningArtist = tonumber(currentArtists[i])
		end
	end
	self:setWinningArtistID(winningArtist)
	local winningPainting = self:getNextArtistPainting(winningArtist)
	self:setWinningPainting(winningPainting)
	self:incrementNextArtistPainting(winningArtist)
	self:spawnVisualPainting(winningArtist, winningPainting)
end

function BestineMuseumScreenPlay:spawnVisualPainting(winningArtist, winningPainting)
	local paintingDisplayID = tonumber(getQuestStatus("bestine_museum:winning_painting_display"))
	local pPainting = getSceneObject(paintingDisplayID)

	if (pPainting ~= nil) then
		SceneObject(pPainting):destroyObjectFromWorld()
	end

	local template = self:getPaintingTemplate(tonumber(winningArtist), tonumber(winningPainting))

	pPainting = spawnSceneObject("tatooine", template, 10.7, 1.0 + artistPaintingZAxis[tonumber(winningArtist)][tonumber(winningPainting)], 9.9, 1028169, 0.7071067811865476, 0, -0.7071067811865475, 0)
	if (pPainting ~= nil) then
		setQuestStatus("bestine_museum:winning_painting_display", SceneObject(pPainting):getObjectID())
	end
end

function BestineMuseumScreenPlay:showPaintingSelection(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local sui = SuiListBox.new("BestineMuseumScreenPlay", "paintingSelectionCallback")
	sui.setTargetNetworkId(SceneObject(pPlayer):getObjectID())
	sui.setTitle("Museum Painting Purchase")
	sui.setPrompt("Select the painting schematic you wish to purchase for 48,000 credits.\n\nYou will be asked to confirm before credits are charged.")

	for i = 1, #self.purchasablePaintings do
		sui.add(self.purchasablePaintings[i].name, "")
	end

	sui.sendTo(pPlayer)
end

function BestineMuseumScreenPlay:paintingSelectionCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil) then
		return
	end

	if (eventIndex == 1 or args == "-1") then
		CreatureObject(pPlayer):sendSystemMessage("Purchase cancelled.")
		return
	end

	local selectedIndex = tonumber(args)
	if (selectedIndex == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Invalid selection. Purchase cancelled.")
		return
	end

	selectedIndex = selectedIndex + 1

	local painting = self.purchasablePaintings[selectedIndex]
	if (painting == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Invalid selection. Purchase cancelled.")
		return
	end

	writeScreenPlayData(pPlayer, "bestineMuseum", "pendingPaintingIndex", tostring(selectedIndex))

	local sui = SuiMessageBox.new("BestineMuseumScreenPlay", "confirmPaintingPurchaseCallback")
	sui.setTargetNetworkId(SceneObject(pPlayer):getObjectID())
	sui.setTitle("Confirm Painting Purchase")
	sui.setPrompt("You are about to purchase:\n\n" .. painting.name .. "\n\nCost: 48,000 credits\n\nConfirm purchase?")
	sui.sendTo(pPlayer)
end

function BestineMuseumScreenPlay:confirmPaintingPurchaseCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil) then
		return
	end

	if (eventIndex == 1) then
		CreatureObject(pPlayer):sendSystemMessage("Purchase cancelled.")
		writeScreenPlayData(pPlayer, "bestineMuseum", "pendingPaintingIndex", "")
		return
	end

	local pendingStr = readScreenPlayData(pPlayer, "bestineMuseum", "pendingPaintingIndex")
	writeScreenPlayData(pPlayer, "bestineMuseum", "pendingPaintingIndex", "")

	local paintingIndex = tonumber(pendingStr)
	if (paintingIndex == nil or paintingIndex < 1 or paintingIndex > #self.purchasablePaintings) then
		CreatureObject(pPlayer):sendSystemMessage("Purchase failed: selection data was lost. Please try again.")
		return
	end

	self:completePaintingPurchase(pPlayer, paintingIndex)
end

function BestineMuseumScreenPlay:completePaintingPurchase(pPlayer, paintingIndex)
	if (pPlayer == nil) then
		return
	end

	local playerID = tostring(SceneObject(pPlayer):getObjectID())
	local painting = self.purchasablePaintings[paintingIndex]
	if (painting == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Purchase failed: invalid selection. Please contact staff.")
		return
	end

	if (CreatureObject(pPlayer):getCashCredits() < 48000) then
		CreatureObject(pPlayer):sendSystemMessage("Purchase failed: insufficient credits.")
		return
	end

	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil or SceneObject(pInventory):isContainerFullRecursive()) then
		CreatureObject(pPlayer):sendSystemMessage("Purchase failed: your inventory is full. Free at least one slot and try again.")
		return
	end

	CreatureObject(pPlayer):subtractCashCredits(48000)
	CreatureObject(pPlayer):sendSystemMessage("You successfully make a payment of 48000 credits.")
	self:writeToPurchasedList(pPlayer)

	local pItem = giveItem(pInventory, painting.schematic, -1)
	if (pItem ~= nil) then
		CreatureObject(pPlayer):sendSystemMessage("@system_msg:give_item_success")
	else
		CreatureObject(pPlayer):sendSystemMessage("Purchase failed: could not create your schematic. Your credits were consumed. Please contact staff for a refund.")
		print("[BestineMuseum] CRITICAL: schematic creation failed for player " .. playerID .. " after deducting 48000 credits. Schematic: " .. tostring(painting.schematic))
	end
end

function BestineMuseumScreenPlay:doSchematicPurchase(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local winningArtist = self:getWinningArtistID()
	local winningPainting = self:getWinningPainting()
	local schematic = self:getSchematicTemplate(tonumber(winningArtist), tonumber(winningPainting))

	CreatureObject(pPlayer):subtractCashCredits(48000)
	CreatureObject(pPlayer):sendSystemMessage("You successfully make a payment of 48000 credits.")
	self:writeToPurchasedList(pPlayer)

	local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")

	if (pInventory ~= nil) then
		local pItem = giveItem(pInventory, schematic, -1)

		if (pItem ~= nil) then
			CreatureObject(pPlayer):sendSystemMessage("@system_msg:give_item_success")
		end
	end
end

function BestineMuseumScreenPlay:getWinningArtistID()
	local winner = getQuestStatus("bestine_museum:winning_artist")
	if winner ~= nil then
		return winner
	else
		return ""
	end
end

function BestineMuseumScreenPlay:getPhaseTimeLeft()
	local eventID = tonumber(getQuestStatus("bestine_museum:event_id"))
	return getServerEventTimeLeft(eventID)
end

function BestineMuseumScreenPlay:setWinningArtistID(id)
	setQuestStatus("bestine_museum:winning_artist", id)
end

function BestineMuseumScreenPlay:getCurrentPhase()
	return tonumber(getQuestStatus("bestine_museum:currentPhase"))
end

function BestineMuseumScreenPlay:setCurrentPhase(phase)
	setQuestStatus("bestine_museum:currentPhase", phase)
end

function BestineMuseumScreenPlay:getWinningPainting()
	local previousWinner = getQuestStatus("bestine_museum:winning_painting")
	if previousWinner ~= nil then
		return previousWinner
	else
		return ""
	end
end

function BestineMuseumScreenPlay:setWinningPainting(painting)
	setQuestStatus("bestine_museum:winning_painting", painting)
end

function BestineMuseumScreenPlay:getCurrentArtists()
	local currentArtists = getQuestStatus("bestine_museum:current_artists")
	if currentArtists ~= nil then
		return currentArtists
	else
		return ""
	end
end

function BestineMuseumScreenPlay:isMuseumEnabled()
	return MUSEUM_VOTING_ENABLED == 1
end

function BestineMuseumScreenPlay:getArtistVotes(artist)
	local votes = getQuestStatus("bestine_museum:votes:artist_" .. artist)
	if votes ~= nil then
		return tonumber(votes)
	else
		return 0
	end
end

function BestineMuseumScreenPlay:resetAllVotes()
	for i = 1, 6, 1 do
		removeQuestStatus("bestine_museum:votes:artist_" .. i)
	end
end

function BestineMuseumScreenPlay:doVote(pPlayer, artistid)
	if (pPlayer == nil) then
		return
	end

	self:writeToVotedList(pPlayer)
	self:incrementArtistVotes(artistid)
end

function BestineMuseumScreenPlay:writeToVotedList(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()
	local list = getQuestStatus("bestine_museum:votedList")

	if (list == nil or list == "") then
		list = playerID
	else
		list = list .. "," .. playerID
	end

	setQuestStatus("bestine_museum:votedList", list)
end

function BestineMuseumScreenPlay:hasAlreadyVoted(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	local playerID = CreatureObject(pPlayer):getObjectID()
	local voteList = getQuestStatus("bestine_museum:votedList")

	if (voteList == nil or voteList == "") then
		return false
	end

	local list = self:splitString(voteList, ",")

	for i = 1, #list, 1 do
		if tonumber(list[i]) == playerID then
			return true
		end
	end

	return false
end

function BestineMuseumScreenPlay:resetVotedList()
	removeQuestStatus("bestine_museum:votedList")
end

function BestineMuseumScreenPlay:writeToPurchasedList(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()
	local list = getQuestStatus("bestine_museum:purchasedList")

	if (list == nil or list == "") then
		list = playerID
	else
		list = list .. "," .. playerID
	end

	setQuestStatus("bestine_museum:purchasedList", list)
end

function BestineMuseumScreenPlay:hasAlreadyPurchased(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	local playerID = CreatureObject(pPlayer):getObjectID()
	local purchaseList = getQuestStatus("bestine_museum:purchasedList")
	if (purchaseList == nil or purchaseList == "") then
		return false
	end

	local list = self:splitString(purchaseList, ",")
	for i = 1, #list, 1 do
		if tonumber(list[i]) == playerID then
			return true
		end
	end
	return false
end

function BestineMuseumScreenPlay:resetPurchasedList()
	removeQuestStatus("bestine_museum:purchasedList")
end

function BestineMuseumScreenPlay:writeToTalkedList(pPlayer, artistid)
	if (pPlayer == nil) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()
	local list = getQuestStatus("bestine_museum:talkedList_" .. artistid)
	if (list == nil or list == "") then
		list = playerID
	else
		list = list .. "," .. playerID
	end
	setQuestStatus("bestine_museum:talkedList_" .. artistid, list)
end

function BestineMuseumScreenPlay:hasTalkedToArtist(pPlayer, artistid)
	if (pPlayer == nil) then
		return false
	end

	local playerID = CreatureObject(pPlayer):getObjectID()
	local talkedList = getQuestStatus("bestine_museum:talkedList_" .. artistid)
	if (talkedList == nil or talkedList == "") then
		return false
	end

	local list = self:splitString(talkedList, ",")
	for i = 1, #list, 1 do
		if tonumber(list[i]) == playerID then
			return true
		end
	end
	return false
end

function BestineMuseumScreenPlay:hasTalkedToAnyArtist(pPlayer)
	if (pPlayer == nil) then
		return false
	end

	for i = 1, 6, 1 do
		if self:hasTalkedToArtist(pPlayer, i) == true then
			return true
		end
	end
	return false
end

function BestineMuseumScreenPlay:resetAllTalkedToLists()
	for i = 1, 6, 1 do
		removeQuestStatus("bestine_museum:talkedList_" .. i)
	end
end

function BestineMuseumScreenPlay:incrementArtistVotes(artist)
	local votes = getQuestStatus("bestine_museum:votes:artist_" .. artist)
	if votes ~= nil then
		setQuestStatus("bestine_museum:votes:artist_" .. artist, tonumber(votes) + 1)
	else
		setQuestStatus("bestine_museum:votes:artist_" .. artist, 1)
	end
end

function BestineMuseumScreenPlay:getNextArtistPainting(artistid)
	local nextPainting = getQuestStatus("bestine_museum:next_painting_" .. artistid)
	if nextPainting ~= nil then
		return tonumber(nextPainting)
	else
		setQuestStatus("bestine_museum:next_painting_" .. artistid, 1)
		return 1
	end
end

function BestineMuseumScreenPlay:incrementNextArtistPainting(artistid)
	local nextPainting = tonumber(getQuestStatus("bestine_museum:next_painting_" .. artistid))
	local totalArtistPaintings = #artistPaintings[artistid]
	if nextPainting == totalArtistPaintings then
		setQuestStatus("bestine_museum:next_painting_" .. artistid, 1)
	else
		setQuestStatus("bestine_museum:next_painting_" .. artistid, nextPainting + 1)
	end
end

function BestineMuseumScreenPlay:isCurrentArtist(id)
	local currentArtists = self:getCurrentArtists()
	if currentArtists == "" then
		return false
	end

	local list = self:splitString(currentArtists, ",")
	for i = 1, 3, 1 do
		if tonumber(list[i]) == tonumber(id) then
			return true
		end
	end
	return false
end

function BestineMuseumScreenPlay:createArtistWaypoint(pPlayer, id)
	local artistTemplate = self:getArtistTemplate(id)
	local artistData = artistMobiles[id]
	local artistName = string.gsub(artistTemplate, "_", " ")
	artistName = string.gsub(" "..artistName, "%W%l", string.upper):sub(2)

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost ~= nil) then
		local pWaypoint = PlayerObject(pGhost):getWaypointAt(artistData.x, artistData.y, "tatooine")

		if pWaypoint ~= nil then
			local waypoint = LuaWaypointObject(pWaypoint)

			if not waypoint:isActive() then
				waypoint:setActive(1)
				PlayerObject(pGhost):updateWaypoint(SceneObject(pWaypoint):getObjectID())
			end
		else
			PlayerObject(pGhost):addWaypoint("tatooine", artistName, "", artistData.x, 0, artistData.y, WAYPOINT_PURPLE, true, true, 0, 0)
		end
	end
end

function BestineMuseumScreenPlay:getArtistID(mobile)
	for i = 1, #artistMobiles, 1 do
		if artistMobiles[i].template == mobile then
			return i
		end
	end
	return 0
end

function BestineMuseumScreenPlay:getArtistMobile(id)
	return artistMobiles[id]
end

function BestineMuseumScreenPlay:getArtistTemplate(id)
	return artistMobiles[id].template
end

function BestineMuseumScreenPlay:getSchematicTemplate(npc, id)
	if (artistPaintings[npc][id] ~= nil) then
		return "object/tangible/loot/bestine/bestine_painting_schematic_" .. artistPaintings[npc][id] .. ".iff"
	else
		return ""
	end
end

function BestineMuseumScreenPlay:getPaintingTemplate(npc, id)
	if (artistPaintings[npc][id] ~= nil) then
		return "object/tangible/painting/painting_bestine_" .. artistPaintings[npc][id] .. ".iff"
	else
		return ""
	end
end

function BestineMuseumScreenPlay:splitString(string, delimiter)
	local outResults = { }
	local start = 1
	local splitStart, splitEnd = string.find( string, delimiter, start )
	while splitStart do
		table.insert( outResults, string.sub( string, start, splitStart-1 ) )
		start = splitEnd + 1
		splitStart, splitEnd = string.find( string, delimiter, start )
	end
	table.insert( outResults, string.sub( string, start ) )
	return outResults
end

bestine_museum_artist_conv_handler = BestineArtistConvoHandler:new {
	themePark = BestineMuseum
}

museum_curator_conv_handler = MuseumCuratorConvoHandler:new {
	themePark = BestineMuseum
}
