#ifndef DOCTORBUFFDROIADTEXTSUICALLBACK_H_
#define DOCTORBUFFDROIADTEXTSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/inputbox/SuiInputBox.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/scene/components/DataObjectComponentReference.h"
#include "server/zone/objects/tangible/components/DoctorBuffDroidDataComponent.h"
#include "server/zone/objects/tangible/components/DoctorBuffDroidMenuComponent.h"
#include "server/zone/objects/tangible/components/doctorservice/DoctorServiceUnitMenuComponent.h"
#include "server/zone/managers/name/NameManager.h"

class DoctorBuffDroidAdTextSuiCallback : public SuiCallback {
	ManagedReference<SceneObject*> droid;

public:
	DoctorBuffDroidAdTextSuiCallback(
		ZoneServer* serv, SceneObject* droidObject)
		: SuiCallback(serv), droid(droidObject) {
	}

	void run(
		CreatureObject* player, SuiBox* sui,
		uint32 eventIndex, Vector<UnicodeString>* args) override {

		if (player == nullptr || droid == nullptr)
			return;

		bool station =
			DoctorBuffDroidMenuComponent::isDoctorServiceUnit(droid);

		if (eventIndex == 1) {
			if (station)
				DoctorServiceUnitMenuComponent::showOwnerConfigMenu(
					droid, player);
			return;
		}

		if (args == nullptr || args->size() < 1)
			return;

		String message =
			args->get(0).toString().trim();

		Locker locker(droid, player);

		DataObjectComponentReference* dataRef =
			droid->getDataObjectComponent();

		if (dataRef == nullptr ||
				dataRef->get() == nullptr ||
				!dataRef->get()->isDoctorBuffDroidData())
			return;

		DoctorBuffDroidDataComponent* data =
			cast<DoctorBuffDroidDataComponent*>(
				dataRef->get());

		if (data == nullptr)
			return;

		if (message.isEmpty()) {
			if (station) {
				data->setAdBarkText("");
				data->setAdBarkEnabled(false);
				droid->updateToDatabase();

				player->sendSystemMessage(
					"Automated Medical Station message cleared.");

				DoctorServiceUnitMenuComponent::showOwnerConfigMenu(
					droid, player);
			} else {
				player->sendSystemMessage(
					"Message cannot be empty.");
			}

			return;
		}

		if (message.length() > 200) {
			player->sendSystemMessage(
				"Message is too long (max 200 characters).");

			if (station)
				DoctorBuffDroidMenuComponent::promptAdTextInput(
					droid, player);
			return;
		}

		auto zoneServer = player->getZoneServer();

		if (zoneServer != nullptr) {
			auto nameManager =
				zoneServer->getNameManager();

			if (nameManager != nullptr &&
					nameManager->isProfane(message)) {
				player->sendSystemMessage(
					"Message rejected by language filter, please try again.");

				if (station)
					DoctorBuffDroidMenuComponent::promptAdTextInput(
						droid, player);
				return;
			}
		}

		data->setAdBarkText(message);

		if (station) {
			data->setAdBarkEnabled(false);
			droid->updateToDatabase();

			player->sendSystemMessage(
				"Automated Medical Station message updated. "
				"It will appear in Services / Availability.");

			DoctorServiceUnitMenuComponent::showOwnerConfigMenu(
				droid, player);
		} else {
			data->setAdBarkEnabled(true);
			droid->updateToDatabase();

			player->sendSystemMessage(
				"Doctor Buff Droid ad message set. "
				"Ad barking is now enabled.");
		}
	}
};

#endif
