#ifndef DOCTORBUFFDROIADTEXTSUICALLBACK_H_
#define DOCTORBUFFDROIADTEXTSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/inputbox/SuiInputBox.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/scene/components/DataObjectComponentReference.h"
#include "server/zone/objects/tangible/components/DoctorBuffDroidDataComponent.h"
#include "server/zone/managers/name/NameManager.h"

class DoctorBuffDroidAdTextSuiCallback : public SuiCallback {
	ManagedReference<SceneObject*> droid;

public:
	DoctorBuffDroidAdTextSuiCallback(ZoneServer* serv, SceneObject* droidObject)
		: SuiCallback(serv), droid(droidObject) {}

	void run(CreatureObject* player, SuiBox* sui, uint32 eventIndex, Vector<UnicodeString>* args) override {
		if (eventIndex == 1 || player == nullptr || droid == nullptr)
			return;

		if (args == nullptr || args->size() < 1)
			return;

		String message = args->get(0).toString();
		message = message.trim();

		if (message.isEmpty()) {
			player->sendSystemMessage("Ad message cannot be empty.");
			return;
		}

		if (message.length() > 200) {
			player->sendSystemMessage("Ad message is too long (max 200 characters).");
			return;
		}

		auto zoneServer = player->getZoneServer();
		if (zoneServer != nullptr) {
			auto nameManager = zoneServer->getNameManager();
			if (nameManager != nullptr && nameManager->isProfane(message)) {
				player->sendSystemMessage("Ad message rejected by language filter, please try again.");
				return;
			}
		}

		Locker locker(droid, player);

		DataObjectComponentReference* dataRef = droid->getDataObjectComponent();
		if (dataRef == nullptr || dataRef->get() == nullptr || !dataRef->get()->isDoctorBuffDroidData())
			return;

		DoctorBuffDroidDataComponent* data = cast<DoctorBuffDroidDataComponent*>(dataRef->get());
		if (data == nullptr)
			return;

		data->setAdBarkText(message);
		data->setAdBarkEnabled(true);
		droid->updateToDatabase();

		player->sendSystemMessage("Doctor Buff Droid ad message set. Ad barking is now enabled.");
	}
};

#endif /* DOCTORBUFFDROIADTEXTSUICALLBACK_H_ */
