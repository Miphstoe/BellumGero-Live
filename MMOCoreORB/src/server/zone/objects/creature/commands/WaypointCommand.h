/*
	Copyright <SWGEmu>
	See file COPYING for copying conditions.
*/

#ifndef WAYPOINTCOMMAND_H_
#define WAYPOINTCOMMAND_H_

// #define WAYPOINT_DEBUG

#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/waypoint/WaypointObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/Zone.h"

class WaypointCommand : public QueueCommand {
private:
	bool advancedWaypoints = ConfigManager::instance()->getBool("Core3.PlayerManager.AdvancedWaypoints", false);
	String advancedGroundUsage = "Usage: /waypoint X Y <name> [color] or /waypoint <name> [color] or /waypoint <zone> X Z Y [color]";
	String advancedSpaceUsage = "Usage: /waypoint X Z Y <name> [color] or /waypoint <name> [color] or /waypoint <zone> X Z Y [color]";
	String groundUsage = "Usage: /waypoint X Y [color]";
	String spaceUsage = "Usage: /waypoint X Z Y [color]";
	mutable bool isSpaceZone;

public:
	WaypointCommand(const String& name, ZoneProcessServer* server) : QueueCommand(name, server) {}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(creature)) {
			return INVALIDSTATE;
		}

		if (!checkInvalidLocomotions(creature)) {
			return INVALIDLOCOMOTION;
		}

		Zone* zone = creature->getZone();

		if (zone == nullptr) {
			return GENERALERROR;
		}

		auto ghost = creature->getPlayerObject();

		if (ghost == nullptr) {
			return GENERALERROR;
		}

		auto zoneServer = server->getZoneServer();

		if (zoneServer == nullptr) {
			return GENERALERROR;
		}

		isSpaceZone = zone->isSpaceZone();

		String waypointData = arguments.toString();
		String waypointName = "@ui:datapad_new_waypoint"; // New Waypoint
		String planet = zone->getZoneName();
		byte waypointColor = 0xFF; // 0xFF = use default

		float x = creature->getPositionX();
		float y = creature->getPositionY();
		float z = (isSpaceZone) ? creature->getPositionZ() : 0.0f;

		ManagedReference<SceneObject*> rootParent = creature->getRootParent();

		if (rootParent != nullptr) {
			x = rootParent ->getPositionX();
			y = rootParent ->getPositionY();

			if (isSpaceZone) {
				z = rootParent->getPositionZ();
			}
		}

		ManagedReference<SceneObject*> targetObject = zoneServer->getObject(target).get();

		StringTokenizer tokenizer(waypointData);
		tokenizer.setDelimeter(" ");

		if (tokenizer.hasMoreTokens()) {
			String arg;
			tokenizer.getStringToken(arg);

			// Check if the first argument is a valid color (works in both basic and advanced modes)
			byte potentialColor = parseWaypointColor(arg);
			if (potentialColor != 0xFF) {
				// It's a valid color! Use it and create waypoint at current location
				waypointColor = potentialColor;
			} else if (!advancedWaypoints && isalpha(arg[0]) > 0) {
				// First argument was alpha but not a valid color (zone name)
				// This is invalid if advanced waypoints are disabled
				sendSystemMessage(creature);
				return GENERALERROR;
			}

			if (tokenizer.hasMoreTokens()) {
				// The first argument is passed here as a required argument as it can be a planet name or position
				// If the argument is not a valid position value, this condition is false
				if (getValidPosition(creature, &tokenizer, &x, &arg)) {
					// Space zones:
					// /waypoint X Z Y
					if (isSpaceZone) {
						if (!checkHasMoreTokens(creature, &tokenizer, &z)) {
							return GENERALERROR;
						}
						if (!checkHasMoreTokens(creature, &tokenizer, &y)) {
							return GENERALERROR;
						}
					// Ground zones:
					// /waypoint X Y
					} else {
						if (!checkHasMoreTokens(creature, &tokenizer, &y)) {
							return GENERALERROR;
						}
					}

					// Parse remaining arguments for waypoint name and/or color (works in both basic and advanced modes)
					StringBuffer newWaypointName;
					String lastToken;

					while (tokenizer.hasMoreTokens()) {
						String token;
						tokenizer.getStringToken(token);

						if (tokenizer.hasMoreTokens()) {
							// Not the last token, add to name (only in advanced mode)
							if (advancedWaypoints) {
								newWaypointName << token << " ";
							}
						} else {
							// This is the last token - could be color or part of name
							lastToken = token;
						}
					}

					// Check if last token is a valid color
					byte potentialColor = parseWaypointColor(lastToken);
					if (potentialColor != 0xFF) {
						// It's a valid color!
						waypointColor = potentialColor;
						// lastToken is not added to waypoint name
					} else {
						// Not a color, it's part of the name (only in advanced mode)
						if (advancedWaypoints) {
							newWaypointName << lastToken << " ";
						}
					}

					if (advancedWaypoints && newWaypointName.length() > 0) {
						waypointName = newWaypointName.toString();
					}
				} else {
					// A waypoint in the form of /waypoint planet X Z Y - Planetary Map
					if (advancedWaypoints) {
						planet = arg;

						// Not a valid planet name - malformed command
						if (zoneServer->getZone(planet) == nullptr) {
							sendSystemMessage(creature);
							return GENERALERROR;
						}

						if (!checkHasMoreTokens(creature, &tokenizer, &x)) {
							return GENERALERROR;
						}
						if (!checkHasMoreTokens(creature, &tokenizer, &z)) {
							return GENERALERROR;
						}
						if (!checkHasMoreTokens(creature, &tokenizer, &y)) {
							return GENERALERROR;
						}
					}
				}
			} else {
				// Allows for naming the waypoint if the first argument starts with
				// an alpha character and has no additional position arguments
				if (advancedWaypoints) {
					waypointName = arg;
				}
			}
		} else if (targetObject != nullptr) {
			Locker crosslocker(targetObject, creature);

			x = targetObject->getWorldPositionX();
			y = targetObject->getWorldPositionY();
			z = isSpaceZone ? targetObject->getWorldPositionZ() : z;
			waypointName = targetObject->getDisplayedName();
		}

#ifdef WAYPOINT_DEBUG
		info(true) << "waypoint name: " << waypointName.toCharArray();
		info(true) << "X: " << x << ", Z: " << z << ", Y: " << y;
#endif

		x = (x < -8192) ? -8192 : x;
		x = (x > 8192) ? 8192 : x;

		y = (y < -8192) ? -8192 : y;
		y = (y > 8192) ? 8192 : y;

		z = (z < -8192) ? -8192 : z;
		z = (z > 8192) ? 8192 : z;

		// Determine the final waypoint color to use (user specified or default)
		byte finalWaypointColor = waypointColor;
		if (finalWaypointColor == 0xFF) {
			// Use default based on zone type
			finalWaypointColor = isSpaceZone ? WaypointObject::COLOR_SPACE : WaypointObject::COLOR_BLUE;
		}

		// Get the template CRC for the waypoint based on color
		uint32_t waypointTemplateCRC = getWaypointTemplateCRC(finalWaypointColor);

		// Create waypoint with the appropriate colored template
		ManagedReference<WaypointObject*> waypoint = zoneServer->createObject(waypointTemplateCRC, 1).castTo<WaypointObject*>();

		if (waypoint == nullptr) {
			return GENERALERROR;
		}

		Locker locker(waypoint, creature);

		waypoint->setPlanetCRC(planet.hashCode());
		waypoint->setPosition(x, z, y);
		waypoint->setCustomObjectName(waypointName, false);

		// Set waypoint color (using the final color determined above)
		waypoint->setColor(finalWaypointColor);

		waypoint->setActive(true);

		// Should the second argument be true, and waypoints with the same name thus remove their old version?
		ghost->addWaypoint(waypoint, false, true);

		return SUCCESS;
	}

	bool checkHasMoreTokens(CreatureObject* creature, StringTokenizer* tokenizer, float* position) const {
		if (tokenizer->hasMoreTokens()) {
			if (!getValidPosition(creature, tokenizer, position)) {
				return false;
			}
		} else {
			sendSystemMessage(creature);
			return false;
		}

		return true;
	}

	bool getValidPosition(CreatureObject* creature, StringTokenizer* tokenizer, float* position, String* requiredArg = nullptr) const {
		String arg;

		if (requiredArg == nullptr) {
			tokenizer->getStringToken(arg);
		}

#ifdef WAYPOINT_DEBUG
		if (!arg.isEmpty()) {
			info(true) << "Arg: " << arg.toCharArray();
		}
		if (requiredArg != nullptr) {
			info(true) << "Passed arg: " << requiredArg->toCharArray();
		}
#endif

		bool isValid = false;
	
		if (requiredArg != nullptr) {
			if (isalpha(requiredArg->toCharArray()[0]) == 0) {
				*position = atof(requiredArg->toCharArray());
				isValid = true;
			}
		} else {
			if (isalpha(arg[0]) == 0) {
				*position = atof(arg.toCharArray());
				isValid = true;
			}
		}

		if (isValid) {
#ifdef WAYPOINT_DEBUG
			info(true) << "Returned position: " << *position;
#endif
		} else {
			if (advancedWaypoints) {
				// Only necessary if requiredArg is null since it is allowed to be alpha
				if (requiredArg == nullptr) {
					sendSystemMessage(creature);
				}
			} else {
				sendSystemMessage(creature);
			}
		}

		return isValid;
	}

	void sendSystemMessage(CreatureObject* creature) const {
		if (advancedWaypoints) {
			creature->sendSystemMessage((isSpaceZone) ? advancedSpaceUsage : advancedGroundUsage);
		} else {
			creature->sendSystemMessage((isSpaceZone) ? spaceUsage : groundUsage);
		}
	}

	byte parseWaypointColor(const String& colorArg) const {
		String colorLower = colorArg;
		colorLower.toLowerCase();

		// Try parsing as a number first
		if (isdigit(colorLower[0])) {
			int colorID = atoi(colorLower.toCharArray());
			if (colorID >= 0 && colorID <= 7)
				return (byte)colorID;
		}

		// Parse as color name
		if (colorLower == "white" || colorLower == "white1")
			return WaypointObject::COLOR_WHITE;
		else if (colorLower == "blue")
			return WaypointObject::COLOR_BLUE;
		else if (colorLower == "green")
			return WaypointObject::COLOR_GREEN;
		else if (colorLower == "orange")
			return WaypointObject::COLOR_ORANGE;
		else if (colorLower == "yellow")
			return WaypointObject::COLOR_YELLOW;
		else if (colorLower == "purple")
			return WaypointObject::COLOR_PURPLE;
		else if (colorLower == "white2")
			return WaypointObject::COLOR_WHITE2;
		else if (colorLower == "space")
			return WaypointObject::COLOR_SPACE;

		// Return 0xFF for invalid (we'll use default instead)
		return 0xFF;
	}

	uint32_t getWaypointTemplateCRC(byte color) const {
		// Uses the universal waypoint template
		// The color is applied to the waypoint object and synchronized to the client
		// The client will render the correct colored light beam based on the color field
		return 0xc456e788;  // shared_world_waypoint (universal template)
	}
};

#endif // WAYPOINTCOMMAND_H_
