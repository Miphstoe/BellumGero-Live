/*
			Copyright <SWGEmu>
	See file COPYING for copying conditions. */

#ifndef FINDPLAYERSTRUCTURECOMMAND_H_
#define FINDPLAYERSTRUCTURECOMMAND_H_

#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/structure/StructureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/messagebox/SuiMessageBox.h"
#include "server/zone/managers/player/PlayerManager.h"

class FindPlayerStructureCommand : public QueueCommand {
public:
	FindPlayerStructureCommand(const String& name, ZoneProcessServer* server) : QueueCommand(name, server) {
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {

		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		// Admin check
		PlayerObject* adminGhost = creature->getPlayerObject();
		if (adminGhost == nullptr || !adminGhost->isAdmin()) {
			creature->sendSystemMessage("You do not have permission to use this command.");
			return GENERALERROR;
		}

		// Get arguments
		StringTokenizer args(arguments.toString());

		if (!args.hasMoreTokens()) {
			creature->sendSystemMessage("SYNTAX: /findplayerstructure <player_name>");
			return INVALIDPARAMETERS;
		}

		String targetPlayerName;
		args.getStringToken(targetPlayerName);

		// Get the target player
		auto zoneServer = creature->getZoneServer();
		if (zoneServer == nullptr)
			return GENERALERROR;

		PlayerManager* playerManager = zoneServer->getPlayerManager();
		if (playerManager == nullptr)
			return GENERALERROR;

		ManagedReference<CreatureObject*> targetPlayer = playerManager->getPlayer(targetPlayerName);

		if (targetPlayer == nullptr) {
			creature->sendSystemMessage("Player '" + targetPlayerName + "' not found online.");
			return INVALIDTARGET;
		}

		if (!targetPlayer->isPlayerCreature()) {
			creature->sendSystemMessage("Target is not a valid player.");
			return INVALIDTARGET;
		}

		ManagedReference<PlayerObject*> targetGhost = targetPlayer->getPlayerObject();

		if (targetGhost == nullptr) {
			creature->sendSystemMessage("Target player has no ghost object.");
			return GENERALERROR;
		}

		// Get the total number of structures owned by target
		int structureCount = targetGhost->getTotalOwnedStructureCount();

		if (structureCount == 0) {
			creature->sendSystemMessage("Player '" + targetPlayerName + "' does not own any structures.");
			return SUCCESS;
		}

		// Create sorted indices array to avoid serialization issues
		Vector<uint64> sortedIndices;
		int totalLots = 0;

		// Gather valid structure indices
		for (int i = 0; i < structureCount; i++) {
			ManagedReference<StructureObject*> structure = zoneServer->getObject(targetGhost->getOwnedStructure(i)).castTo<StructureObject*>();

			if (structure != nullptr) {
				sortedIndices.add(i);
				totalLots += structure->getLotSize();
			}
		}

		// Sort indices by planet name, then by structure name
		for (int i = 0; i < sortedIndices.size() - 1; i++) {
			for (int j = i + 1; j < sortedIndices.size(); j++) {
				int idx1 = sortedIndices.elementAt(i);
				int idx2 = sortedIndices.elementAt(j);

				ManagedReference<StructureObject*> struct1 = zoneServer->getObject(targetGhost->getOwnedStructure(idx1)).castTo<StructureObject*>();
				ManagedReference<StructureObject*> struct2 = zoneServer->getObject(targetGhost->getOwnedStructure(idx2)).castTo<StructureObject*>();

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

		// Build the message box content
		StringBuffer body;
		body << "Player: " << targetPlayer->getFirstName() << endl;
		body << "Total Structures: " << structureCount << endl << endl;
		body << "Lot Usage: " << totalLots << " / " << targetGhost->getLotsRemaining() + totalLots << " lots" << endl << endl;

		body << "======== STRUCTURES ========" << endl << endl;

		// Add each structure to the message
		for (int i = 0; i < sortedIndices.size(); i++) {
			int structIndex = sortedIndices.elementAt(i);
			ManagedReference<StructureObject*> structure = zoneServer->getObject(targetGhost->getOwnedStructure(structIndex)).castTo<StructureObject*>();

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

			int num = i + 1;
			body << num << ". " << structureName << endl;
			body << "   Type: " << structureType << endl;
			body << "   Planet: " << planet << endl;
			body << "   Lots: " << lotSize << endl;
			body << "   Position: [" << (int)posX << ", " << (int)posY << "]" << endl;
			body << "   ObjectID: " << structure->getObjectID() << endl << endl;
		}

		// Create and display message box
		ManagedReference<PlayerObject*> adminGhost2 = creature->getPlayerObject();
		if (adminGhost2 == nullptr)
			return GENERALERROR;

		ManagedReference<SuiMessageBox*> box = new SuiMessageBox(creature, 0);
		box->setPromptTitle("Player Structures - " + targetPlayer->getFirstName());
		box->setPromptText(body.toString());
		box->setUsingObject(targetPlayer);
		box->setForceCloseDisabled();

		adminGhost2->addSuiBox(box);
		creature->sendMessage(box->generateMessage());

		return SUCCESS;
	}
};

#endif //FINDPLAYERSTRUCTURECOMMAND_H_
