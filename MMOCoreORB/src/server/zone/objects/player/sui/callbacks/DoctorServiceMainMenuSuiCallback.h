#ifndef DOCTORSERVICEMAINMENUSUICALLBACK_H_
#define DOCTORSERVICEMAINMENUSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/tangible/components/doctorservice/DoctorServiceUnitMenuComponent.h"

class DoctorServiceMainMenuSuiCallback : public SuiCallback {
	ManagedWeakReference<SceneObject*> stationRef;

public:
	DoctorServiceMainMenuSuiCallback(
		ZoneServer* server, SceneObject* station)
		: SuiCallback(server), stationRef(station) {
	}

	void run(
		CreatureObject* player, SuiBox* suiBox,
		uint32 eventIndex, Vector<UnicodeString>* args) override {

		if (eventIndex == 1 || player == nullptr ||
				suiBox == nullptr || !suiBox->isListBox() ||
				args == nullptr || args->size() < 1)
			return;

		SceneObject* station = stationRef.get();
		if (station == nullptr)
			return;

		SuiListBox* listBox =
			cast<SuiListBox*>(suiBox);

		if (listBox == nullptr)
			return;

		try {
			int index =
				Integer::valueOf(args->get(0).toString());

			if (index < 0 ||
					index >= listBox->getMenuSize())
				return;

			uint64 actionId =
				listBox->getMenuObjectID(index);

			DoctorServiceUnitMenuComponent::handleMainMenuSelection(
				station, player, actionId);
		} catch (Exception& e) {
			player->sendSystemMessage(
				"Unable to select that station option.");
		}
	}
};

#endif
