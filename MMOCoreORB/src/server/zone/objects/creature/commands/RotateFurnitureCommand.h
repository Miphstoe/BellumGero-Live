     Copyright <SWGEmu>
        See file COPYING for copying conditions.*/

/*
Usage:
  /rotateFurniture yaw <degrees>
  /rotateFurniture pitch <degrees>
  /rotateFurniture roll <degrees>
  /rotateFurniture left <degrees>   (legacy yaw)
  /rotateFurniture right <degrees>  (legacy yaw)
  /rotateFurniture reset 1          (resets orientation)

Notes:
  - Axis forms allow degrees in [-180, 180].
  - Legacy left/right requires degrees in [1, 180].
  - Event Perks and Vendors: yaw-only (no pitch/roll).
*/

#ifndef ROTATEFURNITURECOMMAND_H_
#define ROTATEFURNITURECOMMAND_H_

#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/tangible/components/EventPerkDataComponent.h"

class RotateFurnitureCommand : public QueueCommand {
public:
    RotateFurnitureCommand(const String& name, ZoneProcessServer* server) : QueueCommand(name, server) { }

    int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
        if (!checkStateMask(creature))
            return INVALIDSTATE;

        if (!checkInvalidLocomotions(creature))
            return INVALIDLOCOMOTION;

        ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();
        if (ghost == nullptr)
            return GENERALERROR;

        String dir;
        int degrees = 0;
        bool rotateYaw = false;
        bool rotatePitch = false;
        bool rotateRoll = false;
        bool resetRotate = false;

        // Parse: accept axis+degrees, legacy left/right+degrees, or reset.
        try {
            UnicodeTokenizer tokenizer(arguments.toString());
            tokenizer.getStringToken(dir);
            dir = dir.toLowerCase();

            if (dir == "reset") {
                if (tokenizer.hasMoreTokens())
                    degrees = tokenizer.getIntToken();
                resetRotate = true;
            } else {
                if (!tokenizer.hasMoreTokens())
                    throw Exception();

                degrees = tokenizer.getIntToken();

                if (dir == "yaw" || dir == "right" || dir == "left")
                    rotateYaw = true;
                else if (dir == "pitch")
                    rotatePitch = true;
                else if (dir == "roll")
                    rotateRoll = true;
                else
                    throw Exception();
            }
        } catch (Exception& e) {
            creature->sendSystemMessage("[YPR] Format: /rotateFurniture <yaw|pitch|roll|left|right> <degrees>");
            creature->sendSystemMessage("[YPR] Reset:  /rotateFurniture reset 1");
            return INVALIDPARAMETERS;
        }

        // Validate ranges
        if (!resetRotate) {
            if (rotateYaw && (dir == "left" || dir == "right")) {
                if (degrees < 1 || degrees > 180) {
                    creature->sendSystemMessage("@player_structure:rotate_params");
                    return INVALIDPARAMETERS;
                }
            } else {
                if (degrees < -180 || degrees > 180) {
                    creature->sendSystemMessage("The amount to rotate must be between -180 and 180.");
                    return INVALIDPARAMETERS;
                }
            }
        }

        ZoneServer* zoneServer = creature->getZoneServer();
        ManagedReference<SceneObject*> obj = zoneServer->getObject(target);

        if (obj == nullptr) {
            creature->sendSystemMessage("@player_structure:rotate_what");
            return GENERALERROR;
        }

        if (!isValidMoveable(creature, obj, rotateYaw, rotatePitch, rotateRoll, resetRotate))
            return GENERALERROR;

        // Apply rotation
        if (rotateYaw) {
            if (dir == "right")
                obj->rotate(-degrees); // maintain legacy direction
            else
                obj->rotate(degrees);  // yaw (dir == "left" or "yaw")
        } else if (rotatePitch) {
            obj->rotatePitch(degrees);
        } else if (rotateRoll) {
            obj->rotateRoll(degrees);
        } else if (resetRotate) {
            obj->setDirection(1, 0, 0, 0);
        }

        obj->incrementMovementCounter();

        ManagedReference<SceneObject*> objParent = obj->getParent().get();
        if (objParent != nullptr)
            obj->teleport(obj->getPositionX(), obj->getPositionZ(), obj->getPositionY(), objParent->getObjectID());
        else
            obj->teleport(obj->getPositionX(), obj->getPositionZ(), obj->getPositionY());

        return SUCCESS;
    }

    bool isValidMoveable(CreatureObject* player, SceneObject* object, bool rotateYaw, bool rotatePitch, bool rotateRoll, bool resetRotate) const {
        EventPerkDataComponent* data = cast<EventPerkDataComponent*>(object->getDataObjectComponent()->get());

        if (data != nullptr) {
            EventPerkDeed* deed = data->getDeed();

            if (deed == nullptr)
                return false;

            ManagedReference<CreatureObject*> owner = deed->getOwner().get();

            if (owner == nullptr || owner != player) {
                player->sendSystemMessage("@player_structure:cant_manipulate");
                return false;
            }

            if (!rotateYaw && !resetRotate) {
                player->sendSystemMessage("Event perks can only be rotated by yaw.");
                return false;
            }

            return true;
        }

        if (object->isPlayerCreature() || (object->isCreatureObject() && !object->isVendor())) {
            player->sendSystemMessage("@player_structure:cant_manipulate");
            return false;
        }

        ManagedReference<SceneObject*> rootParent = player->getRootParent();

        if (rootParent == nullptr || (!rootParent->isBuildingObject() && !rootParent->isPobShip())) {
            player->sendSystemMessage("@player_structure:must_be_in_building");
            return false;
        }

        bool onAdmin = false;
        bool onVendor = false;

        if (rootParent->isPobShip()) {
            PobShipObject* pobShip = rootParent->asPobShip();

            if (pobShip == nullptr) {
                player->sendSystemMessage("@player_structure:must_be_in_building");
                return false;
            }

            if (!pobShip->containsChildObject(object)) {
                player->sendSystemMessage("@player_structure:item_not_in_building");
                return false;
            }

            onAdmin = pobShip->isOnAdminList(player);
        } else {
            BuildingObject* buildingObject = cast<BuildingObject*>(rootParent.get());

            if (buildingObject == nullptr) {
                player->sendSystemMessage("@player_structure:must_be_in_building");
                return false;
            }

            if (buildingObject->isGCWBase()) {
                player->sendSystemMessage("@player_structure:no_move_hq");
                return false;
            }

            if (!buildingObject->containsChildObject(object)) {
                player->sendSystemMessage("@player_structure:item_not_in_building");
                return false;
            }

            onAdmin = buildingObject->isOnAdminList(player);
            onVendor = buildingObject->isOnPermissionList("VENDOR", player);
        }

        if (object->isVendor()) {
            if (!onAdmin && !onVendor) {
                player->sendSystemMessage("@player_structure:admin_move_only");
                return false;
            }
            if (!rotateYaw && !resetRotate) {
                player->sendSystemMessage("Vendors can only be rotated by yaw.");
                return false;
            }
        } else if (!onAdmin) {
            player->sendSystemMessage("@player_structure:admin_move_only");
            return false;
        }

        ManagedReference<SceneObject*> objectRootParent = object->getRootParent();
        if (objectRootParent == nullptr || objectRootParent != rootParent) {
            player->sendSystemMessage("@player_structure:item_not_in_building");
            return false;
        }

        return true;
    }
};

#endif // ROTATEFURNITURECOMMAND_H