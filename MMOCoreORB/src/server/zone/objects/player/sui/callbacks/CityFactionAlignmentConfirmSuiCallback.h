/*
 * CityFactionAlignmentConfirmSuiCallback.h
 *
 *  Created on: Oct 31, 2025
 *      Author: Miphstoe
 */

#ifndef CITYFACTIONALIGNMENTCONFIRMSUICALLBACK_H_
#define CITYFACTIONALIGNMENTCONFIRMSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sessions/CityFactionAlignmentSession.h"
#include "server/zone/objects/scene/SessionFacadeType.h"

class CityFactionAlignmentConfirmSuiCallback : public SuiCallback {
public:
	CityFactionAlignmentConfirmSuiCallback(ZoneServer* server) : SuiCallback(server) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		// eventIndex == 0 means OK button, eventIndex == 1 means Cancel button
		bool okPressed = (eventIndex == 0);

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
			return;
		}

		if (!okPressed) {
			// User pressed Cancel
			session->cancelSession();
			return;
		}

		// Accept the choice and apply the faction alignment
		session->acceptChoice();
	}
};

#endif /* CITYFACTIONALIGNMENTCONFIRMSUICALLBACK_H_ */
