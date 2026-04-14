/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef CITYBANCOMMAND_H_
#define CITYBANCOMMAND_H_

#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/SuiWindowType.h"
#include "server/zone/objects/player/sui/callbacks/CityUnbanListSuiCallback.h"
#include "server/zone/managers/player/PlayerManager.h"

class CitybanCommand : public QueueCommand {
public:

	CitybanCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {

	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {

		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		ZoneServer* zserv = creature->getZoneServer();

		ManagedReference<CityRegion*> city = creature->getCityRegion().get();

		// Self-target: mayor opens the banned-players list to pick someone to unban
		if (target == creature->getObjectID() || target == 0) {
			if (city == nullptr) {
				creature->sendSystemMessage("@city/city:not_in_city"); // You must be in a city to use this command.
				return GENERALERROR;
			}

			if (!city->isMayor(creature->getObjectID())) {
				creature->sendSystemMessage("Only the city mayor can manage the ban list. Target another player to ban them.");
				return GENERALERROR;
			}

			ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

			if (ghost == nullptr)
				return GENERALERROR;

			Locker cityLock(city, creature);

			CitizenList* bannedList = city->getBannedList();

			if (bannedList == nullptr || bannedList->size() == 0) {
				creature->sendSystemMessage("There are no banned players in " + city->getCityRegionName() + ".");
				return SUCCESS;
			}

			ManagedReference<PlayerManager*> playerManager = zserv->getPlayerManager();

			ghost->closeSuiWindowType(SuiWindowType::CITY_UNBAN_LIST);

			ManagedReference<SuiListBox*> suiBox = new SuiListBox(creature, SuiWindowType::CITY_UNBAN_LIST);
			suiBox->setCallback(new CityUnbanListSuiCallback(zserv, city));
			suiBox->setPromptTitle("Banned Players - " + city->getCityRegionName());
			suiBox->setPromptText("Select a player to unban:");
			suiBox->setCancelButton(true, "@cancel");
			suiBox->setOkButton(true, "Unban");

			for (int i = 0; i < bannedList->size(); ++i) {
				uint64 oid = bannedList->get(i);
				String playerName = (playerManager != nullptr) ? playerManager->getPlayerName(oid) : String::valueOf(oid);

				if (playerName.isEmpty())
					playerName = String::valueOf(oid);

				suiBox->addMenuItem(playerName, oid);
			}

			ghost->addSuiBox(suiBox);
			creature->sendMessage(suiBox->generateMessage());

			return SUCCESS;
		}

		// Normal target-based ban behavior
		ManagedReference<SceneObject*> targetObject = zserv->getObject(target);

		if (targetObject == nullptr || !targetObject->isPlayerCreature() || targetObject == creature) {
			return INVALIDTARGET;
		}

		CreatureObject* targetCreature = cast<CreatureObject*>(targetObject.get());

		if (city == nullptr || city != targetObject->getCityRegion().get()) {
			creature->sendSystemMessage("@city/city:not_in_city"); //You must be in a city to use this command.
			return GENERALERROR;
		}

		Locker lock(city, creature);

		if (city->isBanned(targetCreature->getObjectID()))
			return INVALIDTARGET; //They are already banned.

		if (!city->isMilitiaMember(creature->getObjectID())) {
			creature->sendSystemMessage("@city/city:not_militia"); //You must be a member of the city militia to use this command.
			return GENERALERROR;
		}

		ManagedReference<PlayerObject*> ghost = targetCreature->getPlayerObject();

		if (ghost != nullptr && ghost->hasGodMode()) {
			//Can't ban a CSR
			creature->sendSystemMessage("@city/city:not_csr_ban"); //You cannot ban a Customer Service Representative from the city!

			StringIdChatParameter params("city/city", "csr_ban_attempt_msg");
			params.setTT(creature->getDisplayedName());
			params.setTO(city->getCityRegionName());

			targetCreature->sendSystemMessage(params); //%TT tried to /cityBan you from %TO!
			return GENERALERROR;
		}

		if (city->isCitizen(targetCreature->getObjectID())) {
			creature->sendSystemMessage("@city/city:not_citizen_ban"); //You can't city ban a citizen of the city!
			return GENERALERROR;
		}

		city->addBannedPlayer(targetCreature->getObjectID());
		city->removeSpecializationModifiers(targetCreature);

		targetCreature->sendSystemMessage("@city/city:city_banned"); //You have been banned from the this city.  You may no longer use any city services.

		StringIdChatParameter params("city/city", "city_ban_done");
		params.setTT(targetCreature->getDisplayedName());
		creature->sendSystemMessage(params); //%TT has been banned from the city and is no longer able to access city services.

		return SUCCESS;
	}

};

#endif //CITYBANCOMMAND_H_
