#ifndef DOCTORBUFFDROIDPRICEINPUTSUICALLBACK_H_
#define DOCTORBUFFDROIDPRICEINPUTSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/tangible/components/DoctorBuffDroidMenuComponent.h"

class DoctorBuffDroidPriceInputSuiCallback : public SuiCallback {
	ManagedWeakReference<SceneObject*> droidRef;
	DoctorBuffDroidDataComponent::ServiceType service;

public:
	DoctorBuffDroidPriceInputSuiCallback(
		ZoneServer* serv, SceneObject* droid,
		DoctorBuffDroidDataComponent::ServiceType type)
		: SuiCallback(serv), droidRef(droid), service(type) {
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
				DoctorBuffDroidMenuComponent::promptPriceSelection(
					droid, player);
			return;
		}

		if (!suiBox->isInputBox() ||
				args == nullptr || args->size() < 1)
			return;

		DoctorBuffDroidDataComponent* data =
			DoctorBuffDroidMenuComponent::getDroidData(droid);

		if (data == nullptr || !data->isOwner(player))
			return;

		try {
			int price =
				Integer::valueOf(args->get(0).toString());

			data->setPrice(service, price);
			droid->updateToDatabase();

			if (station) {
				String serviceLabel =
					"Automated Medical Station service";

				if (service ==
						DoctorBuffDroidDataComponent::SERVICE_BUFFS)
					serviceLabel = "Standard Doctor Buff";
				else if (service ==
						DoctorBuffDroidDataComponent::SERVICE_JANTA)
					serviceLabel = "Janta Doctor Buff";
				else if (service ==
						DoctorBuffDroidDataComponent::SERVICE_WOUNDS)
					serviceLabel = "Wound Healing";
				else if (service ==
						DoctorBuffDroidDataComponent::SERVICE_POISON)
					serviceLabel = "Poison Resistance";
				else if (service ==
						DoctorBuffDroidDataComponent::SERVICE_DISEASE)
					serviceLabel = "Disease Resistance";

				player->sendSystemMessage(
					serviceLabel +
					" price updated to " +
					String::valueOf(data->getPrice(service)) +
					" credits.");

				DoctorBuffDroidMenuComponent::promptPriceSelection(
					droid, player);
			} else {
				player->sendSystemMessage(
					"Doctor Buff Droid price updated.");
			}
		} catch (Exception& e) {
			player->sendSystemMessage(
				"Invalid price entered.");

			if (station)
				DoctorBuffDroidMenuComponent::promptPriceInput(
					droid, player, service);
		}
	}
};

#endif
