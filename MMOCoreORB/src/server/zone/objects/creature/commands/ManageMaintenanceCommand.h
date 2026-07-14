/*
 * ManageMaintenanceCommand.h
 *
 * Displays all maintainable structures owned or administered by the character
 * and allows maintenance to be added remotely through the normal cash/bank flow.
 */

#ifndef MANAGEMAINTENANCECOMMAND_H_
#define MANAGEMAINTENANCECOMMAND_H_

#include "server/zone/managers/structure/StructureManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/installation/InstallationObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/SuiWindowType.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/callbacks/ManageMaintenanceSuiCallback.h"
#include "server/zone/objects/region/CityRegion.h"
#include "server/zone/objects/structure/StructureObject.h"
#include "server/zone/Zone.h"
#include "server/zone/ZoneServer.h"

class ManageMaintenanceCommand : public QueueCommand {
private:
	// Compact time formatting keeps each selectable structure on one readable line.
	// Examples: 48d 13h, 8h 24m, or 35m.
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
	ManageMaintenanceCommand(const String& name, ZoneProcessServer* server) : QueueCommand(name, server) {
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

		Vector<uint64> structureIDs;
		structureManager->getRemoteMaintenanceStructureIDs(creature, &structureIDs);

		if (structureIDs.size() == 0) {
			creature->sendSystemMessage("You do not own or administer any structures that require maintenance.");
			return SUCCESS;
		}

		// Sort by planet, then displayed structure name. Object IDs are stored
		// directly in each SUI row so sorting cannot break selection mapping.
		for (int i = 0; i < structureIDs.size() - 1; ++i) {
			for (int j = i + 1; j < structureIDs.size(); ++j) {
				ManagedReference<StructureObject*> first = zoneServer->getObject(structureIDs.get(i)).castTo<StructureObject*>();
				ManagedReference<StructureObject*> second = zoneServer->getObject(structureIDs.get(j)).castTo<StructureObject*>();

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

		if (ghost->hasSuiBoxWindowType(SuiWindowType::STRUCTURE_REMOTE_MAINTENANCE_LIST))
			ghost->closeSuiWindowType(SuiWindowType::STRUCTURE_REMOTE_MAINTENANCE_LIST);

		ManagedReference<SuiListBox*> box = new SuiListBox(creature, SuiWindowType::STRUCTURE_REMOTE_MAINTENANCE_LIST);
		box->setPromptTitle("Manage Maintenance");

		int ownedCount = 0;
		int administeredCount = 0;

		for (int i = 0; i < structureIDs.size(); ++i) {
			ManagedReference<StructureObject*> structure = zoneServer->getObject(structureIDs.get(i)).castTo<StructureObject*>();

			if (structure != nullptr && structure->getOwnerObjectID() == creature->getObjectID())
				++ownedCount;
			else if (structure != nullptr)
				++administeredCount;
		}

		StringBuffer prompt;
		prompt << "Select a structure you own or administer to add maintenance remotely.\n";
		prompt << "Owned: " << ownedCount << " | Administered: " << administeredCount << "\n";
		prompt << "Available Funds (Cash + Bank): " << (creature->getCashCredits() + creature->getBankCredits());
		box->setPromptText(prompt.toString());
		box->setUsingObject(creature);
		box->setCancelButton(true, "@cancel");
		box->setCallback(new ManageMaintenanceSuiCallback(zoneServer));

		for (int i = 0; i < structureIDs.size(); ++i) {
			uint64 structureID = structureIDs.get(i);
			ManagedReference<StructureObject*> structure = zoneServer->getObject(structureID).castTo<StructureObject*>();

			if (structure == nullptr || !structureManager->hasRemoteMaintenanceAdminRights(structure, creature) ||
					structure->isCivicStructure() || structure->isGCWBase())
				continue;

			Locker structureLocker(structure, creature);

			// Keep the displayed pool and remaining time current even if the
			// structure has not recently processed its maintenance task.
			structure->updateStructureStatus();

			String structureName = structure->getDisplayedName();
			if (structureName.isEmpty())
				structureName = "Unnamed Structure";

			String planet = "Unknown";
			if (structure->getZone() != nullptr)
				planet = structure->getZone()->getZoneName();

			int maintenancePool = (int)floor((float)structure->getSurplusMaintenance());
			float totalRate = structure->getMaintenanceRate();

			ManagedReference<CityRegion*> city = structure->getCityRegion().get();
			if (structure->isBuildingObject() && city != nullptr &&
					!city->isClientRegion() && city->getPropertyTax() > 0) {
				totalRate += totalRate * city->getPropertyTax() / 100.0f;
			}

			String maintenanceRemaining = "N/A";
			if (totalRate > 0.0f) {
				if (maintenancePool > 0) {
					uint64 secondsRemaining = (uint64)(((double)maintenancePool / (double)totalRate) * 3600.0);
					maintenanceRemaining = formatCompactTime(secondsRemaining);
				} else {
					maintenanceRemaining = "EXPIRED";
				}
			}

			StringBuffer row;
			row << structureName << " [" << planet << "]";

			if (maintenancePool > 0 && totalRate > 0.0f)
				row << " | Maint: " << maintenancePool << " (" << maintenanceRemaining << ")";
			else if (totalRate > 0.0f)
				row << " | Maint: EXPIRED (" << maintenancePool << ")";
			else
				row << " | Maint: " << maintenancePool << " (N/A)";

			// Power is only consumed by non-generator installations, such as
			// harvesters and factories. Keep this compact so the row stays readable.
			if (structure->isInstallationObject() && !structure->isGeneratorObject()) {
				InstallationObject* installation = cast<InstallationObject*>(structure.get());

				if (installation != nullptr) {
					int powerPool = installation->getSurplusPower();
					float powerRate = installation->getBasePowerRate();
					String powerRemaining = "N/A";

					if (powerRate > 0.0f) {
						if (powerPool > 0) {
							uint64 powerSecondsRemaining =
								(uint64)(((double)powerPool / (double)powerRate) * 3600.0);

						powerRemaining = formatCompactTime(powerSecondsRemaining);
						} else {
							powerRemaining = "EMPTY";
						}
					}

					row << " | Pwr: " << powerPool << " (" << powerRemaining << ")";
					row << " | " << (installation->isActive() ? "ON" : "OFF");
				}
			}

			box->addMenuItem(row.toString(), structureID);
		}

		ghost->addSuiBox(box);
		creature->sendMessage(box->generateMessage());

		return SUCCESS;
	}
};

#endif // MANAGEMAINTENANCECOMMAND_H_
