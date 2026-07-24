/*
 * ManageStructuresSuiCallback.h
 *
 * Handles the three-button /managestructures list:
 *   OK/Pay Maintenance -> opens the combined maintenance transfer window
 *   Other/Deposit Power -> opens the combined power transfer window
 *   Cancel -> closes the list
 */

#ifndef MANAGESTRUCTURESSUICALLBACK_H_
#define MANAGESTRUCTURESSUICALLBACK_H_

#include "server/zone/Zone.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/managers/resource/ResourceManager.h"
#include "server/zone/managers/structure/StructureManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/installation/InstallationObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/SuiWindowType.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/transferbox/SuiTransferBox.h"
#include "server/zone/objects/player/sui/callbacks/ManageStructuresPayMaintenanceSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/ManageStructuresAddPowerSuiCallback.h"
#include "server/zone/objects/region/CityRegion.h"
#include "server/zone/objects/structure/StructureObject.h"

class ManageStructuresSuiCallback : public SuiCallback {
private:
	void reopenManagementList(CreatureObject* creature) const {
		if (creature != nullptr)
			creature->enqueueCommand(STRING_HASHCODE("managestructures"), 0, 0, "");
	}

	void promptMaintenanceDeposit(StructureObject* structure, CreatureObject* creature) const {
		if (structure == nullptr || creature == nullptr)
			return;

		StructureManager* structureManager = StructureManager::instance();
		if (structureManager == nullptr)
			return;

		ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();
		if (ghost == nullptr)
			return;

		if (!structureManager->hasRemoteMaintenanceAdminRights(structure, creature)) {
			creature->sendSystemMessage("You are no longer an administrator for that structure.");
			reopenManagementList(creature);
			return;
		}

		if (structure->isCivicStructure() || structure->isGCWBase()) {
			creature->sendSystemMessage("That structure cannot be funded through remote structure management.");
			reopenManagementList(creature);
			return;
		}

		int availableCredits = creature->getCashCredits() + creature->getBankCredits();
		if (availableCredits <= 0) {
			creature->sendSystemMessage("@player_structure:no_money");
			reopenManagementList(creature);
			return;
		}

		structure->updateStructureStatus();

		String structureName = structure->getDisplayedName();
		if (structureName.isEmpty())
			structureName = "Unnamed Structure";

		String planet = "Unknown";
		if (structure->getZone() != nullptr)
			planet = structure->getZone()->getZoneName();

		int surplusMaintenance = (int)floor((float)structure->getSurplusMaintenance());
		float totalMaintenanceRate = structure->getMaintenanceRate();

		ManagedReference<CityRegion*> city = structure->getCityRegion().get();
		if (structure->isBuildingObject() && city != nullptr &&
				!city->isClientRegion() && city->getPropertyTax() > 0) {
			totalMaintenanceRate += totalMaintenanceRate * city->getPropertyTax() / 100.0f;
		}

		String maintenanceRemaining = "No maintenance required";
		if (totalMaintenanceRate > 0.0f) {
			if (surplusMaintenance > 0) {
				uint64 secondsRemaining =
					(uint64)(((double)surplusMaintenance / (double)totalMaintenanceRate) * 3600.0);

				maintenanceRemaining = StructureManager::getTimeString((uint32)secondsRemaining);
			} else {
				maintenanceRemaining = "Expired";
			}
		}

		if (ghost->hasSuiBoxWindowType(SuiWindowType::STRUCTURE_REMOTE_MANAGEMENT_PAY))
			ghost->closeSuiWindowType(SuiWindowType::STRUCTURE_REMOTE_MANAGEMENT_PAY);

		ManagedReference<SuiTransferBox*> sui =
			new SuiTransferBox(creature, SuiWindowType::STRUCTURE_REMOTE_MANAGEMENT_PAY);
		sui->setCallback(new ManageStructuresPayMaintenanceSuiCallback(server));
		sui->setPromptTitle("Manage Structures - Maintenance");

		// Keep the client-side SUI target on the player so distant and off-planet
		// structures do not fail the client's range validation. The structure is
		// retained separately for the server callback.
		sui->setUsingObject(creature);
		sui->setStructureObject(structure);
		sui->setForceCloseDisabled();

		StringBuffer prompt;
		prompt << "Add maintenance to " << structureName << " [" << planet << "].\n\n";
		prompt << "Maintenance Pool: " << surplusMaintenance << " credits\n";
		prompt << "Maintenance Rate: " << (int)ceil(totalMaintenanceRate) << " credits per hour\n";
		prompt << "Maintenance Remaining: " << maintenanceRemaining;

		if (structure->isInstallationObject() && !structure->isGeneratorObject()) {
			InstallationObject* installation = cast<InstallationObject*>(structure);

			if (installation != nullptr) {
				int powerPool = installation->getSurplusPower();
				float powerRate = installation->getBasePowerRate();
				String powerRemaining = "No power required";

				if (powerRate > 0.0f) {
					if (powerPool > 0) {
						uint64 powerSecondsRemaining =
							(uint64)(((double)powerPool / (double)powerRate) * 3600.0);

						powerRemaining = StructureManager::getTimeString((uint32)powerSecondsRemaining);
					} else {
						powerRemaining = "Depleted";
					}
				}

				prompt << "\n\nPower Reserve: " << powerPool << " units\n";
				prompt << "Power Consumption: " << (int)ceil(powerRate) << " units per hour\n";
				prompt << "Power Remaining: " << powerRemaining << "\n";
				prompt << "Installation Status: " << (installation->isActive() ? "Active" : "Inactive");
			}
		} else if (structure->isGeneratorObject()) {
			prompt << "\n\nPower Deposit: Not required for generators";
		}

		prompt << "\n\nAvailable Funds (Cash + Bank): " << availableCredits << " credits\n";
		prompt << "Enter the amount of maintenance to add below.";
		sui->setPromptText(prompt.toString());

		sui->addFrom("@player_structure:total_funds", String::valueOf(availableCredits), String::valueOf(availableCredits), "1");
		sui->addTo("@player_structure:to_pay", "0", "0", "1");

		ghost->addSuiBox(sui);
		creature->sendMessage(sui->generateMessage());
	}

	void promptPowerDeposit(StructureObject* structure, CreatureObject* creature) const {
		if (structure == nullptr || creature == nullptr)
			return;

		StructureManager* structureManager = StructureManager::instance();
		if (structureManager == nullptr)
			return;

		ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();
		if (ghost == nullptr)
			return;

		if (!structureManager->hasRemotePowerAdminRights(structure, creature)) {
			creature->sendSystemMessage("You are no longer an administrator for that installation.");
			reopenManagementList(creature);
			return;
		}

		if (!structure->isInstallationObject() || structure->isGeneratorObject() ||
				(!structure->isHarvesterObject() && !structure->isFactory()) ||
				structure->getBasePowerRate() <= 0) {
			creature->sendSystemMessage("The selected structure does not require deposited power. Power can only be added to eligible harvesters and factories.");
			reopenManagementList(creature);
			return;
		}

		ManagedReference<ResourceManager*> resourceManager = creature->getZoneServer()->getResourceManager();
		if (resourceManager == nullptr)
			return;

		uint32 availablePower = resourceManager->getAvailablePowerFromPlayer(creature);
		if (availablePower == 0) {
			creature->sendSystemMessage("You do not have any usable energy resources in your inventory.");
			reopenManagementList(creature);
			return;
		}

		InstallationObject* installation = cast<InstallationObject*>(structure);
		if (installation == nullptr)
			return;

		installation->updateStructureStatus();

		String structureName = installation->getDisplayedName();
		if (structureName.isEmpty())
			structureName = "Unnamed Installation";

		String planet = "Unknown";
		if (installation->getZone() != nullptr)
			planet = installation->getZone()->getZoneName();

		int powerPool = (int)floor((float)installation->getSurplusPower());
		float powerRate = installation->getBasePowerRate();
		String powerRemaining = "Depleted";

		if (powerPool > 0 && powerRate > 0.0f) {
			uint64 secondsRemaining =
				(uint64)(((double)powerPool / (double)powerRate) * 3600.0);

			powerRemaining = StructureManager::getTimeString((uint32)secondsRemaining);
		}

		if (ghost->hasSuiBoxWindowType(SuiWindowType::STRUCTURE_REMOTE_MANAGEMENT_POWER))
			ghost->closeSuiWindowType(SuiWindowType::STRUCTURE_REMOTE_MANAGEMENT_POWER);

		ManagedReference<SuiTransferBox*> sui =
			new SuiTransferBox(creature, SuiWindowType::STRUCTURE_REMOTE_MANAGEMENT_POWER);
		sui->setCallback(new ManageStructuresAddPowerSuiCallback(server));
		sui->setPromptTitle("Manage Structures - Power");

		sui->setUsingObject(creature);
		sui->setStructureObject(installation);
		sui->setForceCloseDisabled();

		StringBuffer prompt;
		prompt << "Add inventory power to " << structureName << " [" << planet << "].\n\n";
		prompt << "Power Reserve: " << powerPool << " units\n";
		prompt << "Power Consumption: " << (int)ceil(powerRate) << " units per hour\n";
		prompt << "Power Remaining: " << powerRemaining << "\n";
		prompt << "Installation Status: " << (installation->isActive() ? "Active" : "Inactive") << "\n\n";
		prompt << "Available Inventory Power: " << availablePower << " units\n\n";
		prompt << "Enter the amount of power to add below.";
		sui->setPromptText(prompt.toString());

		sui->addFrom("@player_structure:total_energy", String::valueOf(availablePower), String::valueOf(availablePower), "1");
		sui->addTo("@player_structure:to_deposit", "0", "0", "1");

		ghost->addSuiBox(sui);
		creature->sendMessage(sui->generateMessage());
	}

public:
	ManageStructuresSuiCallback(ZoneServer* server) : SuiCallback(server) {
	}

	void run(CreatureObject* creature, SuiBox* sui, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		if (creature == nullptr || sui == nullptr || !sui->isListBox() || cancelPressed)
			return;

		// HANDLETHREEBUTTON sends two callback values:
		//   args[0] = whether the Other button was pressed
		//   args[1] = selected list row
		if (args == nullptr || args->size() < 2)
			return;

		SuiListBox* listBox = cast<SuiListBox*>(sui);
		if (listBox == nullptr)
			return;

		bool powerPressed = Bool::valueOf(args->get(0).toString());
		int selectedIndex = Integer::valueOf(args->get(1).toString());

		if (selectedIndex < 0 || selectedIndex >= listBox->getMenuSize()) {
			creature->sendSystemMessage("Select a structure before choosing Maintenance or Power.");
			reopenManagementList(creature);
			return;
		}

		uint64 structureID = listBox->getMenuObjectID(selectedIndex);
		if (structureID == 0 || server == nullptr)
			return;

		ManagedReference<StructureObject*> structure = server->getObject(structureID).castTo<StructureObject*>();
		if (structure == nullptr) {
			creature->sendSystemMessage("That structure could not be found. It may have been destroyed or transferred.");
			reopenManagementList(creature);
			return;
		}

		StructureManager* structureManager = StructureManager::instance();
		if (structureManager == nullptr)
			return;

		Locker structureLocker(structure, creature);

		if (!structureManager->hasRemoteMaintenanceAdminRights(structure, creature)) {
			creature->sendSystemMessage("You are no longer an administrator for that structure.");
			reopenManagementList(creature);
			return;
		}

		if (structure->isCivicStructure() || structure->isGCWBase()) {
			creature->sendSystemMessage("That structure cannot be managed through the remote structure-management command.");
			reopenManagementList(creature);
			return;
		}

		if (powerPressed)
			promptPowerDeposit(structure, creature);
		else
			promptMaintenanceDeposit(structure, creature);
	}
};

#endif // MANAGESTRUCTURESSUICALLBACK_H_
