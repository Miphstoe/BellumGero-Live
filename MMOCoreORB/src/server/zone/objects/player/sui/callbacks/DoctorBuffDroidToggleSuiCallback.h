#ifndef DOCTORBUFFDROIDTOGGLESUICALLBACK_H_
#define DOCTORBUFFDROIDTOGGLESUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/tangible/components/DoctorBuffDroidMenuComponent.h"

class DoctorBuffDroidToggleSuiCallback : public SuiCallback {
	ManagedWeakReference<SceneObject*> droidRef;

public:
	DoctorBuffDroidToggleSuiCallback(ZoneServer* serv, SceneObject* droid) : SuiCallback(serv), droidRef(droid) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) override {
		if (eventIndex == 1 || !suiBox->isListBox() || args->size() < 1)
			return;

		SceneObject* droid = droidRef.get();
		if (droid == nullptr)
			return;

		DoctorBuffDroidDataComponent* data = DoctorBuffDroidMenuComponent::getDroidData(droid);
		if (data == nullptr || !data->isOwner(player))
			return;

		int index = Integer::valueOf(args->get(0).toString());

		switch (index) {
		case 0:
			data->toggleService(DoctorBuffDroidDataComponent::SERVICE_BUFFS);
			break;
		case 1:
			data->toggleService(DoctorBuffDroidDataComponent::SERVICE_WOUNDS);
			break;
		case 2:
			data->toggleService(DoctorBuffDroidDataComponent::SERVICE_POISON);
			break;
		case 3:
			data->toggleService(DoctorBuffDroidDataComponent::SERVICE_DISEASE);
			break;
		default:
			return;
		}

		droid->updateToDatabase();
		player->sendSystemMessage("Doctor Buff Droid service state updated.");
	}
};

#endif
