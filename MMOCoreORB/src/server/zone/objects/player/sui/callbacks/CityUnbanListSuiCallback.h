/*
			Copyright <SWGEmu>
	See file COPYING for copying conditions.*/

#ifndef CITYUNBANLISTSUICALLBACK_H_
#define CITYUNBANLISTSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/region/CityRegion.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/managers/player/PlayerManager.h"

class CityUnbanListSuiCallback : public SuiCallback {
	ManagedWeakReference<CityRegion*> cityRegion;

public:
	CityUnbanListSuiCallback(ZoneServer* server, CityRegion* city)
		: SuiCallback(server) {
		cityRegion = city;
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		if (cancelPressed || player == nullptr || !suiBox->isListBox() || args->size() <= 0)
			return;

		ManagedReference<CityRegion*> city = cityRegion.get();

		if (city == nullptr)
			return;

		if (!city->isMayor(player->getObjectID()))
			return;

		int index = Integer::valueOf(args->get(0).toString());
		SuiListBox* listBox = cast<SuiListBox*>(suiBox);

		if (index < 0 || index >= listBox->getMenuSize())
			return;

		uint64 bannedOID = listBox->getMenuObjectID(index);

		if (bannedOID == 0)
			return;

		Locker lock(city, player);

		if (!city->isBanned(bannedOID)) {
			player->sendSystemMessage("That player is no longer banned from this city.");
			return;
		}

		city->removeBannedPlayer(bannedOID);

		// Apply city specialization modifiers if the player is currently loaded
		ManagedReference<SceneObject*> targetObject = server->getObject(bannedOID);

		if (targetObject != nullptr && targetObject->isPlayerCreature()) {
			CreatureObject* targetCreature = cast<CreatureObject*>(targetObject.get());
			city->applySpecializationModifiers(targetCreature);
			targetCreature->sendSystemMessage("@city/city:city_pardoned"); // You have been pardoned and are once again able to use city services.
		}

		// Look up canonical name for the success message
		ManagedReference<PlayerManager*> playerManager = server->getPlayerManager();
		String bannedName = (playerManager != nullptr) ? playerManager->getPlayerName(bannedOID) : String::valueOf(bannedOID);

		StringIdChatParameter params("city/city", "city_pardon_done"); // %TT has been pardoned and is now able to use city services.
		params.setTT(bannedName);
		player->sendSystemMessage(params);
	}
};

#endif /* CITYUNBANLISTSUICALLBACK_H_ */
