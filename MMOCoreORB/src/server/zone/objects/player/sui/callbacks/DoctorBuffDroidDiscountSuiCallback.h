#ifndef DOCTORBUFFDROIDDISCOUNTSUICALLBACK_H_
#define DOCTORBUFFDROIDDISCOUNTSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/tangible/components/DoctorBuffDroidMenuComponent.h"

class DoctorBuffDroidDiscountSuiCallback : public SuiCallback {
	ManagedWeakReference<SceneObject*> droidRef;

public:
	DoctorBuffDroidDiscountSuiCallback(ZoneServer* serv, SceneObject* droid) : SuiCallback(serv), droidRef(droid) {
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
			int discount = Integer::valueOf(args->get(0).toString());
			data->setGuildDiscountPercent(discount);
			droid->updateToDatabase();
			player->sendSystemMessage("Doctor Buff Droid guild discount updated.");
		} catch (Exception& e) {
			player->sendSystemMessage("Invalid discount entered.");
		}
	}
};

#endif
