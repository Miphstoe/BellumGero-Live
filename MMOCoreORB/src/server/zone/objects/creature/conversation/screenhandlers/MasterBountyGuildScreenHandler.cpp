/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#include "MasterBountyGuildScreenHandler.h"
#include "server/zone/managers/mission/MissionManager.h"
#include "server/zone/ZoneServer.h"

const String MasterBountyGuildScreenHandler::STARTSCREENHANDLERID = "give_mission";

ConversationScreen* MasterBountyGuildScreenHandler::handleScreen(
		CreatureObject* conversingPlayer,
		SceneObject* conversingNPC,
		int selectedOption,
		ConversationScreen* conversationScreen) {

	if (conversingPlayer == nullptr || conversationScreen == nullptr)
		return conversationScreen;

	// Only handle the "give_mission" screen
	if (conversationScreen->getScreenID() != "give_mission")
		return conversationScreen;

	ZoneServer* zoneServer = conversingPlayer->getZoneServer();
	if (zoneServer == nullptr)
		return conversationScreen;

	MissionManager* missionManager = zoneServer->getMissionManager();
	if (missionManager == nullptr)
		return conversationScreen;

	// Ask MissionManager to create the mission
	Reference<MissionObject*> mission =
		missionManager->getGuildTier3BountyMission(conversingPlayer);

	if (mission == nullptr) {
		conversationScreen->setCustomDialogText(
			UnicodeString("You cannot take a Guild contract right now. Check your missions and try again."));
	} else {
		// ⭐ Critical: Ensure the mission appears in the datapad immediately
		mission->sendTo(conversingPlayer, true);

		conversationScreen->setCustomDialogText(
			UnicodeString("Here is a Guild contract in the local system. Good Luck Bounty Hunter!"));
	}

	conversationScreen->setStopConversation(true);
	return conversationScreen;
}
