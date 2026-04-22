#ifndef DOCTORBUFFDROIDPRICEINPUTSUICALLBACK_H_
#define DOCTORBUFFDROIDPRICEINPUTSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/tangible/components/DoctorBuffDroidMenuComponent.h"

class DoctorBuffDroidPriceInputSuiCallback : public SuiCallback {
	ManagedWeakReference<SceneObject*> droidRef;
	DoctorBuffDroidDataComponent::ServiceType service;

public:
	DoctorBuffDroidPriceInputSuiCallback(ZoneServer* serv, SceneObject* droid, DoctorBuffDroidDataComponent::ServiceType type)
		: SuiCallback(serv), droidRef(droid), service(type) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) override {
		if (eventIndex == 1 || !suiBox->isInputBox() || args->size() < 1)
			return;

		SceneObject* droid = droidRef.get();
		if (droid == nullptr)
			return;

		DoctorBuffDroidDataComponent* data = DoctorBuffDroidMenuComponent::getDroidData(droid);
		if (data == nullptr || !data->isOwner(player))
			return;

		try {
			int price = Integer::valueOf(args->get(0).toString());
			data->setPrice(service, price);
			droid->updateToDatabase();
			player->sendSystemMessage("Doctor Buff Droid price updated.");
		} catch (Exception& e) {
			player->sendSystemMessage("Invalid price entered.");
		}
	}
};

#endif
