/*
			Copyright <SWGEmu>
	See file COPYING for copying conditions.*/

#ifndef GOHOMECOMMAND_H_
#define GOHOMECOMMAND_H_

#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/structure/StructureObject.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/managers/collision/CollisionManager.h"

class GohomeCommand : public QueueCommand {
public:

	GohomeCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {

	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		// Check if player is in combat
		if (creature->isInCombat()) {
			creature->sendSystemMessage("You cannot use /gohome while in combat.");
			return GENERALERROR;
		}

		// Check if player is indoors (inside a building or cave)
		if (creature->getParentID() != 0) {
			creature->sendSystemMessage("You must be outdoors to use /gohome.");
			return GENERALERROR;
		}

		// Check cooldown (4 hours)
		if (!creature->checkCooldownRecovery("gohome")) {
			const Time* cdTime = creature->getCooldownTime("gohome");

			if (cdTime != nullptr) {
				// Calculate remaining time in seconds
				int timeLeft = floor((float)cdTime->miliDifference() / 1000) * -1;

				// Convert to hours and minutes for display
				int hoursLeft = timeLeft / 3600;
				int minutesLeft = (timeLeft % 3600) / 60;

				String msg = "You must wait ";
				if (hoursLeft > 0) {
					msg += String::valueOf(hoursLeft) + " hour";
					if (hoursLeft > 1) msg += "s";
					if (minutesLeft > 0) msg += " and ";
				}
				if (minutesLeft > 0 || hoursLeft == 0) {
					msg += String::valueOf(minutesLeft) + " minute";
					if (minutesLeft != 1) msg += "s";
				}
				msg += " before using /gohome again.";

				creature->sendSystemMessage(msg);
			} else {
				creature->sendSystemMessage("You must wait before using /gohome again.");
			}
			return GENERALERROR;
		}

		// Get player object to access declared residence
		ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();
		if (ghost == nullptr) {
			creature->sendSystemMessage("Error: Unable to retrieve player data.");
			return GENERALERROR;
		}

		// Get declared residence ID
		uint64 residenceID = ghost->getDeclaredResidence();
		if (residenceID == 0) {
			creature->sendSystemMessage("You have not declared a residence. Use /declareresidence inside your home first.");
			return GENERALERROR;
		}

		// Get the residence object
		ZoneServer* zoneServer = creature->getZoneServer();
		if (zoneServer == nullptr) {
			creature->sendSystemMessage("Error: Unable to access zone server.");
			return GENERALERROR;
		}

		ManagedReference<SceneObject*> residenceObject = zoneServer->getObject(residenceID);
		if (residenceObject == nullptr) {
			creature->sendSystemMessage("Error: Your declared residence could not be found.");
			return GENERALERROR;
		}

		// Get the residence zone
		Zone* residenceZone = residenceObject->getZone();
		if (residenceZone == nullptr) {
			creature->sendSystemMessage("Error: Your residence is not in a valid zone.");
			return GENERALERROR;
		}

		// Get the residence position and zone name
		float residenceX = residenceObject->getPositionX();
		float residenceY = residenceObject->getPositionY();
		String zoneName = residenceZone->getZoneName();

		// Offset the teleport position 15 meters in front of the building (south)
		// This helps ensure we land on the ground, not on or under the building
		float teleportX = residenceX;
		float teleportY = residenceY + 15.0f;  // Offset 15 meters

		// Get the proper ground level Z coordinate at the offset position
		float residenceZ = CollisionManager::getWorldFloorCollision(teleportX, teleportY, residenceZone, false);

		// Add cooldown (4 hours = 14400 seconds = 14400000 milliseconds)
		creature->addCooldown("gohome", 14400 * 1000);

		// Send a message to the player
		creature->sendSystemMessage("Teleporting to your declared residence...");

		// Teleport the player to their residence (outside, not inside)
		// Using the offset coordinates and parentID = 0 to ensure player appears outside the building
		creature->switchZone(zoneName, teleportX, residenceZ, teleportY, 0);

		return SUCCESS;
	}

};

#endif //GOHOMECOMMAND_H_
