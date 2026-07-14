/*
 * ManagePowerCommand.h
 *
 * Displays all power-consuming harvesters and factories owned or administered
 * by the character and allows inventory power to be deposited remotely.
 */

#ifndef MANAGEPOWERCOMMAND_H_
#define MANAGEPOWERCOMMAND_H_

#include "server/zone/managers/resource/ResourceManager.h"
#include "server/zone/managers/structure/StructureManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/installation/InstallationObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/SuiWindowType.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/callbacks/ManagePowerSuiCallback.h"
#include "server/zone/Zone.h"
#include "server/zone/ZoneServer.h"

class ManagePowerCommand : public QueueCommand {
private:
	static String formatCompactTime(uint64 totalSeconds) {
		uint64 days = totalSeconds / 86400;
		totalSeconds %= 86400;
		uint64 hours = totalSeconds / 3600;
		totalSeconds %= 3600;
		uint64 minutes = totalSeconds / 60;

		StringBuffer time;

		if (days > 0) {
			time << days << "d";

			if (hours > 0)
				time << " " << hours << "h";
		} else if (hours > 0) {
			time << hours << "h";

			if (minutes > 0)
				time << " " << minutes << "m";
		} else {
			time << minutes << "m";
		}

		return time.toString();
	}

public:
	ManagePowerCommand(const String& name, ZoneProcessServer* server) : QueueCommand(name, server) {
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		if (creature == nullptr || !creature->isPlayerCreature())
			return GENERALERROR;

		ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();
		if (ghost == nullptr)
			return GENERALERROR;

		ZoneServer* zoneServer = creature->getZoneServer();
		if (zoneServer == nullptr)
			return GENERALERROR;

		StructureManager* structureManager = StructureManager::instance();
		if (structureManager == nullptr)
			return GENERALERROR;

		ManagedReference<ResourceManager*> resourceManager = zoneServer->getResourceManager();
		if (resourceManager == nullptr)
			return GENERALERROR;

		Vector<uint64> structureIDs;
		structureManager->getRemotePowerStructureIDs(creature, &structureIDs);

		if (structureIDs.size() == 0) {
			creature->sendSystemMessage("You do not own or administer any harvesters or factories that require power.");
			return SUCCESS;
		}

		// Sort by planet, then displayed structure name. The object ID is stored
		// directly in each row, so the selection remains correct after sorting.
		for (int i = 0; i < structureIDs.size() - 1; ++i) {
			for (int j = i + 1; j < structureIDs.size(); ++j) {
				ManagedReference<InstallationObject*> first = zoneServer->getObject(structureIDs.get(i)).castTo<InstallationObject*>();
				ManagedReference<InstallationObject*> second = zoneServer->getObject(structureIDs.get(j)).castTo<InstallationObject*>();

				if (first == nullptr || second == nullptr)
					continue;

				String firstPlanet = "Unknown";
				String secondPlanet = "Unknown";

				if (first->getZone() != nullptr)
					firstPlanet = first->getZone()->getZoneName();

				if (second->getZone() != nullptr)
					secondPlanet = second->getZone()->getZoneName();

				String firstName = first->getDisplayedName();
				String secondName = second->getDisplayedName();

				int planetCompare = firstPlanet.compareTo(secondPlanet);
				if (planetCompare > 0 || (planetCompare == 0 && firstName.compareTo(secondName) > 0)) {
					uint64 temp = structureIDs.elementAt(i);
					structureIDs.elementAt(i) = structureIDs.elementAt(j);
					structureIDs.elementAt(j) = temp;
				}
			}
		}

		if (ghost->hasSuiBoxWindowType(SuiWindowType::STRUCTURE_REMOTE_POWER_LIST))
			ghost->closeSuiWindowType(SuiWindowType::STRUCTURE_REMOTE_POWER_LIST);

		ManagedReference<SuiListBox*> box = new SuiListBox(creature, SuiWindowType::STRUCTURE_REMOTE_POWER_LIST);
		box->setPromptTitle("Manage Power");

		int ownedCount = 0;
		int administeredCount = 0;

		for (int i = 0; i < structureIDs.size(); ++i) {
			ManagedReference<InstallationObject*> installation = zoneServer->getObject(structureIDs.get(i)).castTo<InstallationObject*>();

			if (installation != nullptr && installation->getOwnerObjectID() == creature->getObjectID())
				++ownedCount;
			else if (installation != nullptr)
				++administeredCount;
		}

		uint32 availablePower = resourceManager->getAvailablePowerFromPlayer(creature);

		StringBuffer prompt;
		prompt << "Select a harvester or factory you own or administer to add power remotely.\n";
		prompt << "Owned: " << ownedCount << " | Administered: " << administeredCount << "\n";
		prompt << "Available Inventory Power: " << availablePower << " units";
		box->setPromptText(prompt.toString());
		box->setUsingObject(creature);
		box->setCancelButton(true, "@cancel");
		box->setCallback(new ManagePowerSuiCallback(zoneServer));

		for (int i = 0; i < structureIDs.size(); ++i) {
			uint64 structureID = structureIDs.get(i);
			ManagedReference<InstallationObject*> installation = zoneServer->getObject(structureID).castTo<InstallationObject*>();

			if (installation == nullptr || !structureManager->hasRemotePowerAdminRights(installation, creature) ||
					installation->isGeneratorObject() ||
					(!installation->isHarvesterObject() && !installation->isFactory()) ||
					installation->getBasePowerRate() <= 0)
				continue;

			Locker installationLocker(installation, creature);

			// Keep the displayed reserve current if an active installation has
			// consumed power since its last maintenance task.
			installation->updateStructureStatus();

			String structureName = installation->getDisplayedName();
			if (structureName.isEmpty())
				structureName = "Unnamed Installation";

			String planet = "Unknown";
			if (installation->getZone() != nullptr)
				planet = installation->getZone()->getZoneName();

			int powerPool = (int)floor((float)installation->getSurplusPower());
			float powerRate = installation->getBasePowerRate();
			String powerRemaining = "N/A";

			if (powerRate > 0.0f) {
				if (powerPool > 0) {
					uint64 secondsRemaining =
						(uint64)(((double)powerPool / (double)powerRate) * 3600.0);

					powerRemaining = formatCompactTime(secondsRemaining);
				} else {
					powerRemaining = "EMPTY";
				}
			}

			StringBuffer row;
			row << structureName << " [" << planet << "]";
			row << " | Pwr: " << powerPool << " (" << powerRemaining << ")";
			row << " | " << (installation->isActive() ? "ON" : "OFF");

			box->addMenuItem(row.toString(), structureID);
		}

		ghost->addSuiBox(box);
		creature->sendMessage(box->generateMessage());

		return SUCCESS;
	}
};

#endif // MANAGEPOWERCOMMAND_H_
