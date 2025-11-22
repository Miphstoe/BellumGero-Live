/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#include "MasterBountyGuildScreenHandler.h"
#include "server/zone/managers/mission/MissionManager.h"
#include "server/zone/ZoneServer.h"

const String MasterBountyGuildScreenHandler::STARTSCREENHANDLERID = "bounty_guild_start";

ConversationScreen* MasterBountyGuildScreenHandler::handleScreen(
		CreatureObject* conversingPlayer,
		SceneObject* conversingNPC,
		int selectedOption,
		ConversationScreen* conversationScreen) {

	if (conversingPlayer == nullptr || conversationScreen == nullptr)
		return conversationScreen;

	ZoneServer* zoneServer = conversingPlayer->getZoneServer();
	if (zoneServer == nullptr)
		return conversationScreen;

	MissionManager* missionManager = zoneServer->getMissionManager();
	if (missionManager == nullptr)
		return conversationScreen;

	// Log for debugging so you can confirm this is actually running
	info("Handling screen: " + conversationScreen->getScreenID(), true);

	// We only do special work on the 'give_mission' screen
	String screenID = conversationScreen->getScreenID();
	if (screenID != "give_mission")
		return conversationScreen;

	// Try to create the Guild Tier 3 same-planet bounty
	Reference<MissionObject*> mission = missionManager->getGuildTier3BountyMission(conversingPlayer);

	if (mission == nullptr) {
		// MissionManager already sent specific system messages; show a readable failure line.
		conversationScreen->setDialogText(String("You cannot take a Guild contract right now. Check your missions and try again."));
	} else {
		// Success
		conversationScreen->setDialogText(String("A Tier 3 Guild contract has been added to your datapad."));
	}

	// Always close the convo after attempting to assign a mission
	conversationScreen->setStopConversation(true);

	return conversationScreen;
}
