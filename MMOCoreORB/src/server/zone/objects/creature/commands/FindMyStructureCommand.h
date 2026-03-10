/*
			Copyright <SWGEmu>
	See file COPYING for copying conditions. */

#ifndef FINDMYSTRUCTURECOMMAND_H_
#define FINDMYSTRUCTURECOMMAND_H_

#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/managers/structure/StructureManager.h"
#include "server/zone/objects/structure/StructureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/waypoint/WaypointObject.h"
#include "server/zone/objects/player/sui/callbacks/FindMyStructureSuiCallback.h"

class FindMyStructureCommand : public QueueCommand {
public:
	FindMyStructureCommand(const String& name, ZoneProcessServer* server) : QueueCommand(name, server) {
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {

		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		if (!creature->isPlayerCreature())
			return GENERALERROR;

		ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

		if (ghost == nullptr)
			return GENERALERROR;

		auto zoneServer = creature->getZoneServer();

		if (zoneServer == nullptr)
			return GENERALERROR;

		// Get the total number of owned structures
		int structureCount = ghost->getTotalOwnedStructureCount();

		if (structureCount == 0) {
			creature->sendSystemMessage("You do not own any structures.");
			return SUCCESS;
		}

		// Get all structures and calculate total lots
		Vector<uint64> sortedIndices;
		int totalLots = 0;

		for (int i = 0; i < structureCount; i++) {
			ManagedReference<StructureObject*> structure = zoneServer->getObject(ghost->getOwnedStructure(i)).castTo<StructureObject*>();

			if (structure != nullptr) {
				sortedIndices.add(i);
				totalLots += structure->getLotSize();
			}
		}

		// Sort indices by planet, then by structure name
		for (int i = 0; i < sortedIndices.size() - 1; i++) {
			for (int j = i + 1; j < sortedIndices.size(); j++) {
				int idx1 = sortedIndices.elementAt(i);
				int idx2 = sortedIndices.elementAt(j);

				ManagedReference<StructureObject*> struct1 = zoneServer->getObject(ghost->getOwnedStructure(idx1)).castTo<StructureObject*>();
				ManagedReference<StructureObject*> struct2 = zoneServer->getObject(ghost->getOwnedStructure(idx2)).castTo<StructureObject*>();

				if (struct1 == nullptr || struct2 == nullptr)
					continue;

				String planet1 = "Unknown";
				String planet2 = "Unknown";
				String name1 = struct1->getCustomObjectName().toString();
				String name2 = struct2->getCustomObjectName().toString();

				Zone* zone1 = struct1->getZone();
				Zone* zone2 = struct2->getZone();

				if (zone1 != nullptr)
					planet1 = zone1->getZoneName();
				if (zone2 != nullptr)
					planet2 = zone2->getZoneName();

				int planetCompare = planet1.compareTo(planet2);
				if (planetCompare > 0 ||
					(planetCompare == 0 && name1.compareTo(name2) > 0)) {
					uint64 temp = sortedIndices.elementAt(i);
					sortedIndices.elementAt(i) = sortedIndices.elementAt(j);
					sortedIndices.elementAt(j) = temp;
				}
			}
		}

		// Create SUI ListBox for displaying structures
		ManagedReference<SuiListBox*> box = new SuiListBox(creature, SuiWindowType::STRUCTURE_STATUS);
		box->setPromptTitle("My Structures");

		StructureManager* structureManager = StructureManager::instance();

		if (structureManager == nullptr)
			return GENERALERROR;

		StringBuffer promptText;
		promptText << "You own " << sortedIndices.size() << " structure(s). Click on a structure to create a waypoint.\n";
		promptText << "Account Lot Usage: " << ghost->getLotsUsed() << " / " << structureManager->getAccountLotCap() << " lots";

		box->setPromptText(promptText.toString());
		box->setUsingObject(creature);
		box->setForceCloseDisabled();

		// Set callback for waypoint creation when player clicks on a structure
		box->setCallback(new FindMyStructureSuiCallback(zoneServer));

		// Add sorted structures to the list
		for (int i = 0; i < sortedIndices.size(); i++) {
			int structIndex = sortedIndices.elementAt(i);
			ManagedReference<StructureObject*> structure = zoneServer->getObject(ghost->getOwnedStructure(structIndex)).castTo<StructureObject*>();

			if (structure == nullptr)
				continue;

			String structureName = structure->getCustomObjectName().toString();
			String planet = "Unknown";
			float posX = 0.0f;
			float posY = 0.0f;
			int lotSize = structure->getLotSize();
			String structureType = "Unknown";

			// Extract structure type from StringId
			const StringId* objName = structure->getObjectName();
			if (objName != nullptr) {
				String fullPath = objName->getFullPath();
				// fullPath format: "@installation_n:clothing_factory"
				// Extract part after the colon
				int colonPos = fullPath.lastIndexOf(':');
				if (colonPos >= 0 && colonPos < fullPath.length() - 1) {
					structureType = fullPath.subString(colonPos + 1);
					// Replace underscores with spaces for readability
					structureType = structureType.replaceAll("_", " ");
				}
			}

			Zone* zone = structure->getZone();
			if (zone != nullptr) {
				planet = zone->getZoneName();
				posX = structure->getWorldPositionX();
				posY = structure->getWorldPositionY();
			}

			// Format: "Name [Type] (Planet) [Lots: X] [X, Y]"
			StringBuffer displayString;
			displayString << structureName << " [" << structureType << "] (" << planet << ") ";
			displayString << "[Lots: " << lotSize << "] ";
			displayString << "[" << (int)posX << ", " << (int)posY << "]";

			box->addMenuItem(displayString.toString());
		}

		ghost->addSuiBox(box);
		creature->sendMessage(box->generateMessage());

		return SUCCESS;
	}
};

#endif //FINDMYSTRUCTURECOMMAND_H_
