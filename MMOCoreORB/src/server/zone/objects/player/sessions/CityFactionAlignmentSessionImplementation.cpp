/*
 * CityFactionAlignmentSessionImplementation.cpp
 *
 *  Created on: Oct 31, 2025
 *      Author: Miphstoe
 */

#include "server/zone/objects/player/sessions/CityFactionAlignmentSession.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/region/CityRegion.h"
#include "server/zone/objects/player/sui/SuiWindowType.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/messagebox/SuiMessageBox.h"
#include "server/zone/objects/player/sui/callbacks/CityFactionAlignmentSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/CityFactionAlignmentConfirmSuiCallback.h"
#include "system/thread/Locker.h"

int CityFactionAlignmentSessionImplementation::initializeSession() {
	if (creatureObject == nullptr || cityRegion == nullptr) {
		warning("CityFactionAlignmentSession::initializeSession() - creatureObject or cityRegion is nullptr");
		return cancelSession();
	}

	PlayerObject* ghost = creatureObject->getPlayerObject();
	if (ghost == nullptr) {
		warning("CityFactionAlignmentSession::initializeSession() - player ghost is nullptr");
		return cancelSession();
	}

	// Only the mayor (or admin) can change the faction alignment
	if (!cityRegion->isMayor(creatureObject->getObjectID()) && !ghost->isAdmin()) {
		creatureObject->sendSystemMessage("Only the mayor can set city faction alignment.");
		return cancelSession();
	}

	// Only allow faction alignment for Metropolis rank and above
	if (cityRegion->getCityRank() < CityRegion::RANK_METROPOLIS) {
		creatureObject->sendSystemMessage("City must be Metropolis rank or higher to set faction alignment.");
		return cancelSession();
	}

	info("Initializing CityFactionAlignmentSession for city: " + cityRegion->getCityRegionName());

	ManagedReference<SuiListBox*> sui = new SuiListBox(creatureObject, SuiWindowType::CITY_FACTION, 0x00);
	sui->setPromptTitle("City Faction Alignment");
	sui->setPromptText("Choose the faction alignment for your city. This will determine which NPCs patrol your city.");
	sui->setCallback(new CityFactionAlignmentSuiCallback(creatureObject->getZoneServer()));
	sui->setUsingObject(terminalObject);
	sui->setForceCloseDistance(16.f);

	// Add the three faction options
	sui->addMenuItem("Rebel", 0);
	sui->addMenuItem("Imperial", 1);
	sui->addMenuItem("Neutral (Corsec)", 2);

	ghost->addSuiBox(sui);
	creatureObject->sendMessage(sui->generateMessage());
	return 1;
}

int CityFactionAlignmentSessionImplementation::sendConfirmationBox(const String& choice) {

	PlayerObject* ghost = creatureObject->getPlayerObject();
	if (ghost == nullptr) {
		creatureObject->sendSystemMessage("ERROR: Player ghost is nullptr");
		return cancelSession();
	}

	SuiMessageBox* confirm = new SuiMessageBox(creatureObject, SuiWindowType::CITY_FACTION_CONFIRM);
	confirm->setPromptTitle("Confirm Faction Alignment");

	String confirmText = "Are you sure you want to set your city's faction alignment to ";

	if (choice == "Rebel") {
		factionAlignment = "rebel";
		confirmText += "Rebel? Rebel NPCs will patrol your city.";
	} else if (choice == "Imperial") {
		factionAlignment = "imperial";
		confirmText += "Imperial? Imperial NPCs will patrol your city.";
	} else if (choice == "Neutral (Corsec)") {
		factionAlignment = "neutral";
		confirmText += "Neutral? Corsec troopers will patrol your city.";
	} else {
		creatureObject->sendSystemMessage("ERROR: Unknown faction choice: " + choice);
		return cancelSession();
	}


	confirm->setPromptText(confirmText);
	confirm->setOkButton(true, "@yes");
	confirm->setCancelButton(true, "@no");
	confirm->setCallback(new CityFactionAlignmentConfirmSuiCallback(creatureObject->getZoneServer()));

	ghost->addSuiBox(confirm);
	creatureObject->sendMessage(confirm->generateMessage());

	return 1;
}

int CityFactionAlignmentSessionImplementation::acceptChoice() {
	if (cityRegion == nullptr || creatureObject == nullptr) {
		warning("CityFactionAlignmentSession::acceptChoice() - cityRegion or creatureObject is nullptr");
		return cancelSession();
	}

	// Lock both the city region and creature object before making changes
	Locker locker(cityRegion, creatureObject);

	// Apply the faction alignment to the city
	info("Setting city faction alignment to: " + factionAlignment);
	cityRegion->setCityFactionAlignment(factionAlignment);

	// Verify it was set
	String currentAlignment = cityRegion->getCityFactionAlignment();
	info("City faction alignment is now: " + currentAlignment);

	// Send confirmation message to mayor
	creatureObject->sendSystemMessage("City faction alignment has been successfully set.");

	return cancelSession();
}
