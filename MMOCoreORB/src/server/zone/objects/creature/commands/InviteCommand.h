/* Copyright <SWGEmu> See file COPYING for copying conditions.*/

#ifndef INVITECOMMAND_H_
#define INVITECOMMAND_H_

#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/managers/group/GroupManager.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/Zone.h"

class InviteCommand : public QueueCommand {
public:
    InviteCommand(const String& name, ZoneProcessServer* server)
        : QueueCommand(name, server) {
    }

    int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
        if (!checkStateMask(creature))
            return INVALIDSTATE;

        if (!checkInvalidLocomotions(creature))
            return INVALIDLOCOMOTION;

        auto ghost = creature->getPlayerObject();
        bool godMode = false;
        
        if (ghost != nullptr && ghost->isPrivileged()) {
            godMode = true;
        }

        auto zoneServer = server->getZoneServer();
        if (zoneServer == nullptr)
            return GENERALERROR;

        // Check if this is an area invite command
        StringTokenizer args(arguments.toString());
        String firstArg;
        
        if (args.hasMoreTokens()) {
            args.getStringToken(firstArg);
            
            // Check for "area" keyword
            if (firstArg.toLowerCase() == "area") {
                return doAreaInvite(creature, args, godMode, zoneServer);
            }
        }

        // Original single player invite logic
        auto object = zoneServer->getObject(target);

        // if they didn't target a player/ship, always try lookup by typed name
        if (object == nullptr || (!object->isPlayerCreature() && !object->isShipObject())) {
            if (zoneServer == nullptr)
                return GENERALERROR;

            auto playerMan = zoneServer->getPlayerManager();
            if (playerMan == nullptr)
                return GENERALERROR;

            object = playerMan->getPlayer(firstArg);
        }

        auto groupManager = GroupManager::instance();
        if (object == nullptr || groupManager == nullptr)
            return GENERALERROR;

        if (!object->isPlayerCreature() && !object->isShipObject()) {
            return GENERALERROR;
        }

        CreatureObject* player = nullptr;
        if (object->isShipObject()) {
            auto ship = object->asShipObject();
            if (ship != nullptr) {
                player = ship->getOwner().get();
            }
        } else {
            player = object->asCreatureObject();
        }

        if (player == nullptr)
            return GENERALERROR;

        auto invitedGhost = player->getPlayerObject();
        if (invitedGhost == nullptr)
            return GENERALERROR;

        // Cannot be invite by a player that they ignore, does not apply to privileged players
        if (!godMode && invitedGhost->isIgnoring(creature->getFirstName()))
            return GENERALERROR;

        groupManager->inviteToGroup(creature, player);
        return SUCCESS;
    }

private:
    int doAreaInvite(CreatureObject* creature, StringTokenizer& args, bool godMode, ZoneServer* zoneServer) const {
        auto groupManager = GroupManager::instance();
        if (groupManager == nullptr)
            return GENERALERROR;

        // Parse range argument (default to 64 meters)
        float range = 64.0f;
        
        if (args.hasMoreTokens()) {
            String rangeStr;
            args.getStringToken(rangeStr);
            
            try {
                float parsedRange = Float::valueOf(rangeStr);
                if (parsedRange > 0 && parsedRange <= 512.0f) { // Cap at 512 meters
                    range = parsedRange;
                }
            } catch (...) {
                // Invalid range, use default
                creature->sendSystemMessage("Invalid range specified. Using default range of 64 meters.");
            }
        }

        // Get creature's zone
        auto zone = creature->getZone();
        if (zone == nullptr)
            return GENERALERROR;

        int inviteCount = 0;
        int maxInvites = godMode ? 50 : 20;

        // Use a simpler approach - iterate through all players in the zone
        auto playerManager = zoneServer->getPlayerManager();
        if (playerManager == nullptr)
            return GENERALERROR;

        // Get all online player IDs
        auto onlinePlayerIds = playerManager->getOnlinePlayerList();
        
        for (int i = 0; i < onlinePlayerIds.size() && inviteCount < maxInvites; ++i) {
            uint64 playerId = onlinePlayerIds.get(i);
            
            // Get the actual player object using ZoneServer
            auto playerObject = zoneServer->getObject(playerId);
            if (playerObject == nullptr || !playerObject->isPlayerCreature())
                continue;
                
            auto player = playerObject->asCreatureObject();
            if (player == nullptr || player == creature)
                continue; // Skip null or self

            // Check if player is in the same zone
            if (player->getZone() != zone)
                continue;

            // Check distance
            float distance = creature->getDistanceTo(player);
            if (distance > range)
                continue;

            auto playerGhost = player->getPlayerObject();
            if (playerGhost == nullptr)
                continue;

            // Skip if player is ignoring the inviter (unless godMode)
            if (!godMode && playerGhost->isIgnoring(creature->getFirstName()))
                continue;

            // Check if player is already in the same group
            auto creatureGroup = creature->getGroup();
            auto playerGroup = player->getGroup();
            
            if (creatureGroup != nullptr && playerGroup != nullptr && creatureGroup == playerGroup)
                continue; // Already in same group

            // Send the group invite
            groupManager->inviteToGroup(creature, player);
            inviteCount++;

            // Debug message for each invite sent
            StringBuffer inviteMsg;
            inviteMsg << "Sent invite to: " << player->getFirstName() << " (distance: " << String::valueOf(distance) << "m)";
            creature->sendSystemMessage(inviteMsg.toString());
        }

        // Send feedback to the inviter
        StringBuffer msg;
        if (inviteCount > 0) {
            msg << "Sent group invites to " << inviteCount << " player";
            if (inviteCount > 1) msg << "s";
            msg << " within " << range << " meters.";
        } else {
            msg << "No eligible players found within " << range << " meters to invite.";
        }
        
        creature->sendSystemMessage(msg.toString());

        return SUCCESS;
    }
};

#endif //INVITECOMMAND_H_