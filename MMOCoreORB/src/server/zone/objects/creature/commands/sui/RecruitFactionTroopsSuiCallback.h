/*
 * RecruitFactionTroopsSuiCallback.h
 */

#ifndef RECRUITFACTIONTROOPSSUICALLBACK_H_
#define RECRUITFACTIONTROOPSSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/Zone.h"
#include "server/zone/managers/creature/CreatureManager.h"
#include "server/zone/managers/city/CityManager.h"
#include "server/zone/managers/city/CityFactionTroopObserver.h"
#include "templates/params/ObserverEventType.h"

class RecruitFactionTroopsSuiCallback : public SuiCallback {
public:
	RecruitFactionTroopsSuiCallback(ZoneServer* server)
		: SuiCallback(server) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		if (cancelPressed)
			return;

		if (args->size() < 1)
			return;

		// Must be placed outdoors.
		if (player->getParent() != nullptr)
			return;

		ManagedReference<CityRegion*> city = player->getCityRegion().get();
		CityManager* cityManager = player->getZoneServer()->getCityManager();
		if (city == nullptr || cityManager == nullptr)
			return;

		if (!city->isMayor(player->getObjectID()))
			return;

		Zone* zone = player->getZone();
		if (zone == nullptr)
			return;

		PlayerObject* ghost = player->getPlayerObject();
		if (ghost == nullptr)
			return;

		if (!ghost->hasAbility("recruitfactiontroops"))
			return;

		const String alignment = city->getCityFactionAlignment();
		if (alignment != "imperial" && alignment != "rebel") {
			player->sendSystemMessage("Your city must be faction-aligned (Rebel or Imperial) to recruit faction troops.");
			return;
		}

		if (!cityManager->canSupportMoreFactionTroops(city)) {
			player->sendSystemMessage("Your city can't support any more faction troops at the current cap.");
			return;
		}

		int option = Integer::valueOf(args->get(0).toString());
		String troopTemplatePath = "";
		uint32 recruitCost = 1000; // basic default

		// Placement costs (city treasury):
		// - Basic:  1,000
		// - Mid:    2,500
		// - Elite:  5,000
		if (alignment == "imperial") {
			switch (option) {
			case 0:
				troopTemplatePath = "city_imperial_stormtrooper";
				recruitCost = 2000;
				break;
			case 1:
				troopTemplatePath = "city_imperial_assault_trooper";
				recruitCost = 5000;
				break;
			case 2:
				troopTemplatePath = "city_imperial_dark_trooper";
				recruitCost = 10000;
				break;
			default:
				break;
			}
		} else {
			switch (option) {
			case 0:
				troopTemplatePath = "city_rebel_trooper";
				recruitCost = 2000;
				break;
			case 1:
				troopTemplatePath = "city_rebel_grenadier";
				recruitCost = 5000;
				break;
			case 2:
				troopTemplatePath = "city_rebel_specforce_sergeant";
				recruitCost = 10000;
				break;
			default:
				break;
			}
		}

		if (troopTemplatePath == "")
			return;

		Locker clocker(city, player);

		if (city->getCityTreasury() < (int)recruitCost) {
			StringIdChatParameter msg;
			msg.setStringId("@city/city:action_no_money");
			msg.setDI(recruitCost);
			player->sendSystemMessage(msg);
			return;
		}

		if (player->isSwimming() || player->isIncapacitated() || player->isDead())
			return;

		CreatureObject* troop = zone->getCreatureManager()->spawnCreature(
			troopTemplatePath.hashCode(),
			0,
			player->getWorldPositionX(),
			player->getWorldPositionZ(),
			player->getWorldPositionY(),
			0,
			true
		);

		if (troop == nullptr) {
			player->sendSystemMessage("Failed to recruit the troop. Try again.");
			return;
		}

		// Ensure command-placed NPCs are removable via radial
		troop->setObjectMenuComponent("CityFactionTroopMenuComponent");

		// Ensure city tracking is cleaned up if the troop is killed.
		ManagedReference<CityFactionTroopObserver*> observer = new CityFactionTroopObserver();
		troop->registerObserver(ObserverEventType::OBJECTDESTRUCTION, observer);

		troop->rotate(player->getDirectionAngle());
		city->subtractFromCityTreasury(recruitCost);
		city->addFactionTroop(troop);

		if (!city->isRegistered()) {
			zone->unregisterObjectWithPlanetaryMap(troop);
		}
	}
};

#endif /* RECRUITFACTIONTROOPSSUICALLBACK_H_ */