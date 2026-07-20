/*
 * ManageStructuresCommand.h
 *
 * Combined remote structure-management list. The player selects one owned or
 * administered structure, then chooses Pay Maintenance, Deposit Power, or
 * Cancel from the same three-button list box.
 */

#ifndef MANAGESTRUCTURESCOMMAND_H_
#define MANAGESTRUCTURESCOMMAND_H_

#include "server/zone/Zone.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/managers/resource/ResourceManager.h"
#include "server/zone/managers/structure/StructureManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/installation/InstallationObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/SuiWindowType.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/callbacks/ManageStructuresSuiCallback.h"
#include "server/zone/objects/region/CityRegion.h"
#include "server/zone/objects/structure/StructureObject.h"

class ManageStructuresCommand : public QueueCommand {
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
	ManageStructuresCommand(const String& name, ZoneProcessServer* server) : QueueCommand(name, server) {
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

		// The maintenance discovery list already contains the complete set of
		// non-civic, non-GCW structures that the character owns or administers.
		// Eligible harvesters and factories are therefore naturally included
		// without performing a second playerstructures database scan.
		Vector<uint64> structureIDs;
		structureManager->getRemoteMaintenanceStructureIDs(creature, &structureIDs);

		if (structureIDs.size() == 0) {
			creature->sendSystemMessage("You do not own or administer any structures that can be remotely managed.");
			return SUCCESS;
		}

		// Sort by planet, then displayed structure name. Each row retains its
		// structure object ID, so sorting cannot break the callback selection.
		for (int i = 0; i < structureIDs.size() - 1; ++i) {
			for (int j = i + 1; j < structureIDs.size(); ++j) {
				ManagedReference<StructureObject*> first =
					zoneServer->getObject(structureIDs.get(i)).castTo<StructureObject*>();
				ManagedReference<StructureObject*> second =
					zoneServer->getObject(structureIDs.get(j)).castTo<StructureObject*>();

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

		if (ghost->hasSuiBoxWindowType(SuiWindowType::STRUCTURE_REMOTE_MANAGEMENT_LIST))
			ghost->closeSuiWindowType(SuiWindowType::STRUCTURE_REMOTE_MANAGEMENT_LIST);

		ManagedReference<SuiListBox*> box = new SuiListBox(
			creature,
			SuiWindowType::STRUCTURE_REMOTE_MANAGEMENT_LIST,
			SuiListBox::HANDLETHREEBUTTON
		);

		box->setPromptTitle("Manage Structures");

		int ownedCount = 0;
		int administeredCount = 0;

		for (int i = 0; i < structureIDs.size(); ++i) {
			ManagedReference<StructureObject*> structure =
				zoneServer->getObject(structureIDs.get(i)).castTo<StructureObject*>();

			if (structure != nullptr && structure->getOwnerObjectID() == creature->getObjectID())
				++ownedCount;
			else if (structure != nullptr)
				++administeredCount;
		}

		int availableCredits = creature->getCashCredits() + creature->getBankCredits();
		uint32 availablePower = resourceManager->getAvailablePowerFromPlayer(creature);

		StringBuffer prompt;
		prompt << "Select a structure, then choose Pay Maintenance or Deposit Power.\n";
		prompt << "Power is available only for eligible harvesters and factories.\n";
		prompt << "Owned: " << ownedCount << " | Administered: " << administeredCount << "\n";
		prompt << "Available Funds (Cash + Bank): " << availableCredits << " credits\n";
		prompt << "Available Inventory Power: " << availablePower << " units";
		box->setPromptText(prompt.toString());

		box->setUsingObject(creature);
		box->setOkButton(true, "@player_structure:management_pay");
		box->setOtherButton(true, "@player_structure:management_power");
		box->setCancelButton(true, "@cancel");
		box->setCallback(new ManageStructuresSuiCallback(zoneServer));

		for (int i = 0; i < structureIDs.size(); ++i) {
			uint64 structureID = structureIDs.get(i);
			ManagedReference<StructureObject*> structure =
				zoneServer->getObject(structureID).castTo<StructureObject*>();

			if (structure == nullptr ||
					!structureManager->hasRemoteMaintenanceAdminRights(structure, creature) ||
					structure->isCivicStructure() || structure->isGCWBase())
				continue;

			Locker structureLocker(structure, creature);

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
					uint64 secondsRemaining =
						(uint64)(((double)maintenancePool / (double)totalRate) * 3600.0);

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

			// Display power details only when the Power button is valid for the row.
			if (structure->isInstallationObject() && !structure->isGeneratorObject() &&
					(structure->isHarvesterObject() || structure->isFactory()) &&
					structure->getBasePowerRate() > 0) {
				InstallationObject* installation = cast<InstallationObject*>(structure.get());

				if (installation != nullptr) {
					int powerPool = installation->getSurplusPower();
					float powerRate = installation->getBasePowerRate();
					String powerRemaining = "N/A";

					if (powerPool > 0) {
						uint64 powerSecondsRemaining =
							(uint64)(((double)powerPool / (double)powerRate) * 3600.0);

						powerRemaining = formatCompactTime(powerSecondsRemaining);
					} else {
						powerRemaining = "EMPTY";
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

#endif // MANAGESTRUCTURESCOMMAND_H_
