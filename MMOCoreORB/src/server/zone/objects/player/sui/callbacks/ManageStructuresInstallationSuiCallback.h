/*
 * ManageStructuresInstallationSuiCallback.h
 *
 * Backs "/managestructures status|on|off". Lists the caller's eligible
 * harvesters and generators (read-only for status; select-to-act for on/off).
 * The installation ID of each row is stored server-side on the SUI; ownership,
 * rights and current state are revalidated when a selection is submitted.
 */

#ifndef MANAGESTRUCTURESINSTALLATIONSUICALLBACK_H_
#define MANAGESTRUCTURESINSTALLATIONSUICALLBACK_H_

#include "server/zone/Zone.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/managers/structure/StructureManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/installation/InstallationObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/SuiWindowType.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/resource/ResourceSpawn.h"
#include "server/zone/objects/structure/StructureObject.h"

class ManageStructuresInstallationSuiCallback : public SuiCallback {
	String mode; // "on" or "off"

	static bool isEligible(StructureObject* structure) {
		return structure != nullptr && structure->isInstallationObject() &&
				(structure->isHarvesterObject() || structure->isGeneratorObject()) &&
				!structure->isCivicStructure() && !structure->isGCWBase();
	}

	static String getName(StructureObject* structure) {
		String name = structure->getDisplayedName();
		return name.isEmpty() ? String("Unnamed Installation") : name;
	}

public:
	ManageStructuresInstallationSuiCallback(ZoneServer* server, const String& modeName) : SuiCallback(server), mode(modeName) {
	}

	static void openInstallationWindow(CreatureObject* creature, ZoneServer* zoneServer, const String& subcommand) {
		StructureManager* structureManager = StructureManager::instance();
		ManagedReference<PlayerObject*> ghost = creature != nullptr ? creature->getPlayerObject() : nullptr;

		if (ghost == nullptr || zoneServer == nullptr || structureManager == nullptr)
			return;

		bool statusOnly = (subcommand == "status");
		bool wantOn = (subcommand == "on");

		Vector<uint64> ids;
		structureManager->getRemoteMaintenanceStructureIDs(creature, &ids);

		if (ghost->hasSuiBoxWindowType(SuiWindowType::STRUCTURE_REMOTE_MANAGEMENT_ACTIONS))
			ghost->closeSuiWindowType(SuiWindowType::STRUCTURE_REMOTE_MANAGEMENT_ACTIONS);

		ManagedReference<SuiListBox*> box = new SuiListBox(creature, SuiWindowType::STRUCTURE_REMOTE_MANAGEMENT_ACTIONS,
				statusOnly ? SuiListBox::HANDLETWOBUTTON : SuiListBox::HANDLETWOBUTTON);
		box->setUsingObject(creature);
		box->setCancelButton(true, "@cancel");

		if (statusOnly) {
			box->setPromptTitle("Remote Installation Status");
			box->setOkButton(true, "@ok");
		} else {
			box->setPromptTitle(wantOn ? "Activate Installation" : "Deactivate Installation");
			box->setOkButton(true, wantOn ? "Turn ON" : "Turn OFF");
			box->setCallback(new ManageStructuresInstallationSuiCallback(zoneServer, subcommand));
		}

		int count = 0;

		for (int i = 0; i < ids.size(); ++i) {
			ManagedReference<StructureObject*> structure = zoneServer->getObject(ids.get(i)).castTo<StructureObject*>();

			if (!isEligible(structure) || !structureManager->hasRemotePowerAdminRights(structure, creature))
				continue;

			Locker structureLocker(structure, creature);

			structure->updateStructureStatus();

			InstallationObject* installation = cast<InstallationObject*>(structure.get());
			if (installation == nullptr)
				continue;

			bool active = installation->isActive();

			if (!statusOnly && active == wantOn)
				continue;

			String planet = structure->getZone() != nullptr ? structure->getZone()->getZoneName() : String("Unknown");

			StringBuffer row;
			row << getName(structure) << " - " << planet << " - " << (active ? "ON" : "OFF");

			if (statusOnly) {
				String resource = "None";
				ManagedReference<ResourceSpawn*> spawn = zoneServer->getObject(installation->getActiveResourceSpawnID()).castTo<ResourceSpawn*>();

				if (spawn != nullptr)
					resource = spawn->getName();

				row << " - Resource: " << resource;
			}

			box->addMenuItem(row.toString(), structure->getObjectID());
			++count;
		}

		if (count == 0) {
			if (statusOnly)
				creature->sendSystemMessage("You do not own or administer any harvesters or generators.");
			else
				creature->sendSystemMessage(wantOn ? "You have no eligible installations that are currently OFF." : "You have no eligible installations that are currently ON.");

			return;
		}

		StringBuffer prompt;
		if (statusOnly)
			prompt << "Your harvesters and generators (read-only).";
		else
			prompt << "Select an installation to turn " << (wantOn ? "ON" : "OFF") << ".";
		box->setPromptText(prompt.toString());

		ghost->addSuiBox(box);
		creature->sendMessage(box->generateMessage());
	}

	void run(CreatureObject* creature, SuiBox* sui, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (creature == nullptr || sui == nullptr || !sui->isListBox() || eventIndex == 1)
			return;

		if (args == nullptr || args->size() < 1 || server == nullptr)
			return;

		SuiListBox* listBox = cast<SuiListBox*>(sui);
		int selected = Integer::valueOf(args->get(0).toString());

		if (listBox == nullptr || selected < 0 || selected >= listBox->getMenuSize())
			return;

		StructureManager* structureManager = StructureManager::instance();
		ManagedReference<StructureObject*> structure = server->getObject(listBox->getMenuObjectID(selected)).castTo<StructureObject*>();

		if (structureManager == nullptr || structure == nullptr) {
			creature->sendSystemMessage("That installation could not be found. It may have been destroyed or redeeded.");
			return;
		}

		Locker structureLocker(structure, creature);

		if (!structureManager->hasRemotePowerAdminRights(structure, creature)) {
			creature->sendSystemMessage("You do not have permission to manage this installation.");
			return;
		}

		if (!isEligible(structure)) {
			creature->sendSystemMessage("That structure does not support remote ON/OFF control.");
			return;
		}

		InstallationObject* installation = cast<InstallationObject*>(structure.get());
		if (installation == nullptr)
			return;

		String name = getName(structure);
		bool wantOn = (mode == "on");

		// Bring maintenance, power and hopper current before judging the rules.
		installation->updateStructureStatus();

		if (installation->isActive() == wantOn) {
			creature->sendSystemMessage(name + (wantOn ? " is already operating." : " is already off."));
			return;
		}

		if (!wantOn) {
			installation->setActive(false);

			if (installation->isActive())
				creature->sendSystemMessage("Unable to deactivate " + name + ".");
			else
				creature->sendSystemMessage(name + " deactivated successfully.");

			return;
		}

		// setActive() enforces resource, density, power and maintenance rules but
		// reports failures only to local operators, so verify the outcome.
		installation->setActive(true);

		if (installation->isActive())
			creature->sendSystemMessage(name + " activated successfully.");
		else if (installation->getBasePowerRate() != 0 && installation->getSurplusPower() <= 0)
			creature->sendSystemMessage("Unable to activate " + name + ": insufficient power.");
		else if (installation->getMaintenanceRate() != 0 && installation->getSurplusMaintenance() <= 0)
			creature->sendSystemMessage("Unable to activate " + name + ": insufficient maintenance.");
		else
			creature->sendSystemMessage("Unable to activate " + name + ": no valid resource selected, or the resource has too little density at this location.");
	}
};

#endif // MANAGESTRUCTURESINSTALLATIONSUICALLBACK_H_
