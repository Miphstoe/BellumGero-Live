/*
 * CitySpecializationSessionImplementation.cpp
 *
 *  Created on: Feb 13, 2012
 *      Author: xyborn
 */

#include "server/zone/objects/player/sessions/CitySpecializationSession.h"
#include "server/zone/managers/city/CityManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/region/CityRegion.h"
#include "server/zone/objects/player/sui/SuiWindowType.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/messagebox/SuiMessageBox.h"
#include "server/zone/objects/player/variables/AbilityList.h"
#include "server/zone/objects/player/variables/Ability.h"
#include "server/zone/objects/player/sui/callbacks/CitySpecializationSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/CitySpecializationConfirmSuiCallback.h"

int CitySpecializationSessionImplementation::initializeSession() {
	PlayerObject* ghost = creatureObject->getPlayerObject();
	if (ghost == nullptr)
		return cancelSession();

	// Only the mayor (or admin) can change the spec
	if (!cityRegion->isMayor(creatureObject->getObjectID()) && !ghost->isAdmin())
		return cancelSession();

	ManagedReference<SuiListBox*> sui = new SuiListBox(creatureObject, SuiWindowType::CITY_SPEC, 0x00);
	sui->setPromptTitle("@city/city:city_specs_t"); // City Specialization
	sui->setPromptText("@city/city:city_specs_d");
	sui->setCallback(new CitySpecializationSuiCallback(creatureObject->getZoneServer()));
	sui->setUsingObject(terminalObject);
	sui->setForceCloseDistance(16.f);

	// Get current city rank and city manager
	int cityRank = cityRegion->getCityRank();
	CityManager* cityManager = creatureObject->getZoneServer()->getCityManager();

	if (cityManager != nullptr) {
		// Get all available specializations for this city's rank
		Vector<String> specNames;
		cityManager->getAvailableSpecializations(cityRank, specNames);

		// Add each specialization to the menu
		for (int i = 0; i < specNames.size(); ++i) {
			const String& specName = specNames.get(i);
			const CitySpecialization* spec = cityManager->getCitySpecialization(specName);

			// Use displayName if available, otherwise use the string ID name
			if (spec != nullptr && !spec->getDisplayName().isEmpty()) {
				sui->addMenuItem(spec->getDisplayName());
			} else {
				sui->addMenuItem(specName);
			}
		}
	}

	// Offer "None" only if a specialization is currently set
	if (!cityRegion->getCitySpecialization().isEmpty())
		sui->addMenuItem("@city/city:null", -1);

	// If nothing to choose, tell the user and bail
	if (sui->getMenuSize() <= 0) {
		creatureObject->sendSystemMessage("@city/city:no_specs");
		return cancelSession();
	}

	ghost->addSuiBox(sui);
	creatureObject->sendMessage(sui->generateMessage());
	return 1;
}

int CitySpecializationSessionImplementation::sendConfirmationBox(const String& choice) {
	PlayerObject* ghost = creatureObject->getPlayerObject();
	if (ghost == nullptr)
		return cancelSession();

	if (choice != "@city/city:null") {
		if (cityRegion->getCityRank() < CityRegion::RANK_TOWNSHIP) {
			creatureObject->sendSystemMessage("@city/city:no_rank_spec");
			return cancelSession();
		}

		if (!creatureObject->checkCooldownRecovery("city_specialization")) {
			StringIdChatParameter params("city/city", "spec_time"); // cooldown message
			const Time* timeRemaining = creatureObject->getCooldownTime("city_specialization");
			params.setTO(String::valueOf(round(fabs(timeRemaining->miliDifference() / 1000.f))) + " seconds");
			creatureObject->sendSystemMessage(params);
			return cancelSession();
		}
	}

	SuiMessageBox* confirm = new SuiMessageBox(creatureObject, SuiWindowType::CITY_SPEC_CONFIRM);
	confirm->setPromptTitle("@city/city:confirm_spec_t"); // Confirm Specialization

	if (choice == "@city/city:null") {
		confirm->setPromptText(choice + "_d");
		specialization = "";
	} else {
		// Convert displayName back to actual specialization name (string ID)
		CityManager* cityManager = creatureObject->getZoneServer()->getCityManager();
		String actualName = choice;
		if (cityManager != nullptr) {
			actualName = cityManager->getCitySpecializationNameByDisplay(choice);
		}

		confirm->setPromptText(choice + "_d\n\n@city/city:confirm_spec_d");
		specialization = actualName;
	}

	confirm->setOkButton(true, "@yes");
	confirm->setCancelButton(true, "@no");
	confirm->setCallback(new CitySpecializationConfirmSuiCallback(creatureObject->getZoneServer()));

	ghost->addSuiBox(confirm);
	creatureObject->sendMessage(confirm->generateMessage());
	return 1;
}

int CitySpecializationSessionImplementation::acceptChoice() {
	CityManager* cityManager = creatureObject->getZoneServer()->getCityManager();
	cityManager->changeCitySpecialization(cityRegion, creatureObject, specialization);
	return cancelSession();
}
