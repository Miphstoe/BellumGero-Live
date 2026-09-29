#ifndef DOCTORBUFFDROIDTOGGLESUICALLBACK_H_
#define DOCTORBUFFDROIDTOGGLESUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/tangible/components/DoctorBuffDroidMenuComponent.h"
#include "server/zone/objects/tangible/components/doctorservice/DoctorServiceUnitMenuComponent.h"

class DoctorBuffDroidToggleSuiCallback : public SuiCallback {
	ManagedWeakReference<SceneObject*> droidRef;

public:
	DoctorBuffDroidToggleSuiCallback(
		ZoneServer* serv, SceneObject* droid)
		: SuiCallback(serv), droidRef(droid) {
	}

	void run(
		CreatureObject* player, SuiBox* suiBox,
		uint32 eventIndex, Vector<UnicodeString>* args) override {

		SceneObject* droid = droidRef.get();
		if (droid == nullptr || player == nullptr)
			return;

		bool station =
			DoctorBuffDroidMenuComponent::isDoctorServiceUnit(droid);

		if (eventIndex == 1) {
			if (station)
				DoctorServiceUnitMenuComponent::showOwnerConfigMenu(
					droid, player);
			return;
		}

		if (!suiBox->isListBox() ||
				args == nullptr || args->size() < 1)
			return;

		DoctorBuffDroidDataComponent* data =
			DoctorBuffDroidMenuComponent::getDroidData(droid);

		if (data == nullptr || !data->isOwner(player))
			return;

		int index =
			Integer::valueOf(args->get(0).toString());

		DoctorBuffDroidDataComponent::ServiceType type;

		switch (index) {
		case 0:
			type =
				DoctorBuffDroidDataComponent::SERVICE_BUFFS;
			break;
		case 1:
			type =
				DoctorBuffDroidDataComponent::SERVICE_JANTA;
			break;
		case 2:
			type =
				DoctorBuffDroidDataComponent::SERVICE_WOUNDS;
			break;
		case 3:
			type =
				DoctorBuffDroidDataComponent::SERVICE_POISON;
			break;
		case 4:
			type =
				DoctorBuffDroidDataComponent::SERVICE_DISEASE;
			break;
		default:
			return;
		}

		data->toggleService(type);
		droid->updateToDatabase();

		if (station) {
			String label = "Service";

			if (type ==
					DoctorBuffDroidDataComponent::SERVICE_BUFFS)
				label = "Standard Doctor Buffs";
			else if (type ==
					DoctorBuffDroidDataComponent::SERVICE_JANTA)
				label = "Janta Doctor Buffs";
			else if (type ==
					DoctorBuffDroidDataComponent::SERVICE_WOUNDS)
				label = "Wound Healing";
			else if (type ==
					DoctorBuffDroidDataComponent::SERVICE_POISON)
				label = "Poison Resistance";
			else if (type ==
					DoctorBuffDroidDataComponent::SERVICE_DISEASE)
				label = "Disease Resistance";

			player->sendSystemMessage(
				label + " are now " +
				String(data->isServiceEnabled(type) ?
					"ENABLED." : "DISABLED."));

			DoctorBuffDroidMenuComponent::promptToggleSelection(
				droid, player);
		} else {
			player->sendSystemMessage(
				"Doctor Buff Droid service state updated.");
		}
	}
};

#endif
