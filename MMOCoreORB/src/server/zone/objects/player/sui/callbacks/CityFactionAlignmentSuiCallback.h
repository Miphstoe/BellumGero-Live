/*
 * CityFactionAlignmentSuiCallback.h
 *
 *  Created on: Oct 31, 2025
 *      Author: Miphstoe
 */

#ifndef CITYFACTIONALIGNMENTSUICALLBACK_H_
#define CITYFACTIONALIGNMENTSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sessions/CityFactionAlignmentSession.h"
#include "server/zone/objects/scene/SessionFacadeType.h"

class CityFactionAlignmentSuiCallback : public SuiCallback {
public:
	CityFactionAlignmentSuiCallback(ZoneServer* server) : SuiCallback(server) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		if (player == nullptr) {
			return;
		}

		// Get the active session
		ManagedReference<CityFactionAlignmentSession*> session = nullptr;
		ManagedReference<Facade*> facade = player->getActiveSession(SessionFacadeType::CITYFACTION);

		if (facade != nullptr) {
			session = cast<CityFactionAlignmentSession*>(facade.get());
		}

		if (session == nullptr) {
			player->sendSystemMessage("ERROR: Session is nullptr in callback");
			return;
		}

		if (cancelPressed) {
			player->sendSystemMessage("Faction alignment selection cancelled");
			session->cancelSession();
			return;
		}

		if (args == nullptr || args->size() <= 0) {
			player->sendSystemMessage("ERROR: No selection data in callback");
			session->cancelSession();
			return;
		}

		// Get the selected choice - could be index or text
		String selectedText = args->get(0).toString();

		// Convert index to faction name if needed
		if (selectedText == "0") {
			selectedText = "Rebel";
		} else if (selectedText == "1") {
			selectedText = "Imperial";
		} else if (selectedText == "2") {
			selectedText = "Neutral (Corsec)";
		}


		// Send confirmation box with the selected choice
		session->sendConfirmationBox(selectedText);
	}
};

#endif /* CITYFACTIONALIGNMENTSUICALLBACK_H_ */
