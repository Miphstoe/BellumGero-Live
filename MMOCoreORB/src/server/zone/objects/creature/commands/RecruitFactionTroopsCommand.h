/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef RECRUITFACTIONTROOPSCOMMAND_H_
#define RECRUITFACTIONTROOPSCOMMAND_H_

#include <system/thread/Locker.h>

#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/creature/commands/sui/RecruitFactionTroopsSuiCallback.h"
#include "server/zone/objects/region/CityRegion.h"
#include "server/zone/objects/structure/StructureObject.h"

class RecruitFactionTroopsCommand : public QueueCommand {
public:

	RecruitFactionTroopsCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {

		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		PlayerObject* ghost = creature->getPlayerObject();
		if (ghost == nullptr)
			return GENERALERROR;

		if (!ghost->hasAbility("recruitfactiontroops"))
			return GENERALERROR;

		if (creature->isIncapacitated() || creature->isDead())
			return GENERALERROR;

		ManagedReference<CityRegion*> city = creature->getCityRegion().get();
		if (city == nullptr)
			return GENERALERROR;

		if (!city->isMayor(creature->getObjectID()))
			return GENERALERROR;

		const String alignment = city->getCityFactionAlignment();
		if (alignment != "imperial" && alignment != "rebel") {
			creature->sendSystemMessage("Your city must be faction-aligned (Rebel or Imperial) to recruit faction troops.");
			return GENERALERROR;
		}

		// Optional admin-style utilities for mayors (helps recover from runaway troops):
		//  - /recruitFactionTroops cleanup  -> removes any faction troops that are currently outside city radius
		//  - /recruitFactionTroops purge    -> removes ALL faction troops in the city list
		const String arg = arguments.toString().trim().toLowerCase();

		if (arg == "cleanup" || arg == "clean") {
			Locker locker(city, creature);

			ManagedReference<StructureObject*> hall = city->getCityHall();
			if (hall == nullptr) {
				creature->sendSystemMessage("City Hall not found. Unable to cleanup faction troops.");
				return GENERALERROR;
			}

			const float cx = hall->getPositionX();
			const float cy = hall->getPositionY();
			const float radius = (float) city->getRadius();
			const float r2 = radius * radius;

			int removed = 0;

			for (int i = city->getFactionTroopCount() - 1; i >= 0; --i) {
				ManagedReference<SceneObject*> troop = city->getCityFactionTroop(i);
				if (troop == nullptr) {
					// Null reference; drop it
					// (removeFactionTroop expects a SceneObject but drop-by-index isn't available here)
					continue;
				}

				const float dx = troop->getPositionX() - cx;
				const float dy = troop->getPositionY() - cy;

				if ((dx * dx + dy * dy) > r2) {
					city->removeFactionTroop(troop);

					Locker clocker(troop, city);
					troop->destroyObjectFromWorld(true);
					troop->destroyObjectFromDatabase(true);

					removed++;
				}
			}

			creature->sendSystemMessage("Cleanup complete. Removed " + String::valueOf(removed) + " faction troops outside city limits.");
			return SUCCESS;
		}

		if (arg == "purge" || arg == "removeall") {
			Locker locker(city, creature);

			const int count = city->getFactionTroopCount();
			city->removeAllFactionTroops();

			creature->sendSystemMessage("Removed " + String::valueOf(count) + " faction troops from your city.");
			return SUCCESS;
		}

		// Normal recruit UI
		ManagedReference<SuiListBox*> suiTroopType = new SuiListBox(creature, SuiWindowType::RECRUIT_FACTION_TROOPS, 0);
		suiTroopType->setCallback(new RecruitFactionTroopsSuiCallback(server->getZoneServer()));

		suiTroopType->setPromptTitle("Recruit Faction Troops");
		suiTroopType->setPromptText("Select the troop type to recruit. The listed cost will be deducted from the city treasury.");

		// Placement costs (city treasury):
		// - Basic:  1,000
		// - Mid:    2,500
		// - Elite:  5,000
		if (alignment == "imperial") {
			suiTroopType->addMenuItem("Stormtrooper (1,000c)", 0);
			suiTroopType->addMenuItem("Assault Trooper (2,500c)", 1);
			suiTroopType->addMenuItem("Dark Trooper (5,000c)", 2);
		} else {
			suiTroopType->addMenuItem("Rebel Trooper (1,000c)", 0);
			suiTroopType->addMenuItem("Rebel Grenadier (2,500c)", 1);
			suiTroopType->addMenuItem("Rebel Specforce Sergeant (5,000c)", 2);
		}

		ghost->addSuiBox(suiTroopType);
		creature->sendMessage(suiTroopType->generateMessage());

		return SUCCESS;
	}

};

#endif // RECRUITFACTIONTROOPSCOMMAND_H_
