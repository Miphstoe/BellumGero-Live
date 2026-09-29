#ifndef DOCTORBUFFDROIDDISCOUNTSUICALLBACK_H_
#define DOCTORBUFFDROIDDISCOUNTSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/tangible/components/DoctorBuffDroidMenuComponent.h"
#include "server/zone/objects/tangible/components/doctorservice/DoctorServiceUnitMenuComponent.h"
#include "server/zone/objects/guild/GuildObject.h"

class DoctorBuffDroidDiscountSuiCallback : public SuiCallback {
	ManagedWeakReference<SceneObject*> droidRef;

public:
	DoctorBuffDroidDiscountSuiCallback(
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

		if (!suiBox->isInputBox() ||
				args == nullptr || args->size() < 1)
			return;

		DoctorBuffDroidDataComponent* data =
			DoctorBuffDroidMenuComponent::getDroidData(droid);

		if (data == nullptr || !data->isOwner(player))
			return;

		try {
			int discount =
				Integer::valueOf(args->get(0).toString());

			data->setGuildDiscountPercent(discount);

			if (station) {
				GuildObject* ownerGuild =
					player->getGuildObject().get();

				data->setOwnerGuildId(
					ownerGuild != nullptr ?
						ownerGuild->getObjectID() : 0);
			}

			droid->updateToDatabase();

			if (station) {
				player->sendSystemMessage(
					"Automated Medical Station guild discount updated to " +
					String::valueOf(
						data->getGuildDiscountPercent()) +
					"%. Current owner guild affiliation was cached for offline use.");

				DoctorServiceUnitMenuComponent::showOwnerConfigMenu(
					droid, player);
			} else {
				player->sendSystemMessage(
					"Doctor Buff Droid guild discount updated.");
			}
		} catch (Exception& e) {
			player->sendSystemMessage(
				"Invalid discount entered.");

			if (station)
				DoctorBuffDroidMenuComponent::promptDiscountInput(
					droid, player);
		}
	}
};

#endif
