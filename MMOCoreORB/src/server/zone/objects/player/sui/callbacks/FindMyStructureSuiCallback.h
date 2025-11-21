/*
			Copyright <SWGEmu>
	See file COPYING for copying conditions. */

#ifndef FINDMYSTRUCTURESUICALLBACK_H_
#define FINDMYSTRUCTURESUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/structure/StructureObject.h"
#include "server/zone/objects/waypoint/WaypointObject.h"
#include "server/zone/ZoneServer.h"

class FindMyStructureSuiCallback : public SuiCallback {
public:
	FindMyStructureSuiCallback(ZoneServer* server) : SuiCallback(server) {
	}

	void run(CreatureObject* player, SuiBox* sui, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		if (player == nullptr || sui == nullptr || !sui->isListBox() || cancelPressed)
			return;

		SuiListBox* listBox = cast<SuiListBox*>(sui);

		if (listBox == nullptr)
			return;

		// Get selected index from args
		if (args == nullptr || args->size() == 0)
			return;

		int selectedIndex = Integer::valueOf(args->get(0).toString());

		// Get player ghost
		ManagedReference<PlayerObject*> ghost = player->getPlayerObject();

		if (ghost == nullptr)
			return;

		// Get the total structure count
		int structureCount = ghost->getTotalOwnedStructureCount();

		if (selectedIndex < 0 || selectedIndex >= structureCount)
			return;

		if (server == nullptr)
			return;

		ZoneServer* zoneServer = server;

		// Get the selected structure
		ManagedReference<StructureObject*> structure = zoneServer->getObject(ghost->getOwnedStructure(selectedIndex)).castTo<StructureObject*>();

		if (structure == nullptr) {
			player->sendSystemMessage("Structure not found. It may have been destroyed.");
			return;
		}

		// Get structure information
		String structureName = structure->getCustomObjectName().toString();
		String planet = "Unknown";
		float posX = 0.0f;
		float posY = 0.0f;
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

		// Create a waypoint for the structure
		try {
			// Create waypoint object (CRC: 0xc456e788)
			ManagedReference<WaypointObject*> waypoint = (zoneServer->createObject(0xc456e788, 1)).castTo<WaypointObject*>();

			if (waypoint == nullptr) {
				player->sendSystemMessage("Failed to create waypoint.");
				return;
			}

			Locker waypointLocker(waypoint);

			// Set waypoint properties
			waypoint->setPlanetCRC(planet.hashCode());
			waypoint->setPosition(posX, 0.0f, posY);

			// Set waypoint name with structure name and type
			StringBuffer waypointName;
			waypointName << structureName << " [" << structureType << "]";
			waypoint->setCustomObjectName(waypointName.toString(), false);
			waypoint->setActive(true);

			// Add waypoint to player
			ghost->addWaypoint(waypoint, false, true);

			// Send success message to player
			StringBuffer message;
			message << "Waypoint created for " << structureName << " [" << structureType << "] at [" << (int)posX << ", " << (int)posY << "] on " << planet;
			player->sendSystemMessage(message.toString());

		} catch (Exception& e) {
			player->sendSystemMessage("Error creating waypoint: " + String(e.getMessage()));
			return;
		}
	}
};

#endif //FINDMYSTRUCTURESUICALLBACK_H_
