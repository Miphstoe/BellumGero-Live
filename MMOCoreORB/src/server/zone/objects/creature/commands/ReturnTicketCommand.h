/*
                Copyright <SWGEmu>
        See file COPYING for copying conditions.
*/

#ifndef USERETURNTICKETCOMMAND_H_
#define USERETURNTICKETCOMMAND_H_

#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/managers/stringid/StringIdManager.h"

class UseReturnTicketCommand : public QueueCommand {
public:
    UseReturnTicketCommand(const String& name, ZoneProcessServer* server)
        : QueueCommand(name, server) {}

    int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
        // Standard command guards
        if (!checkStateMask(creature))
            return INVALIDSTATE;

        if (!checkInvalidLocomotions(creature))
            return INVALIDLOCOMOTION;

        if (creature->isInCombat()) {
            creature->sendSystemMessage("You cannot use a Return Ticket while in combat.");
            return GENERALERROR;
        }

        if (creature->isRidingMount()) {
            creature->sendSystemMessage("Dismount before using a Return Ticket.");
            return GENERALERROR;
        }

        // ---- CONFIG: destination for the return teleport ----
        // Replace these three numbers with the exact starter spawn you use for Coronet.
        // (Yaw is in radians; 0 = facing east. Adjust if you care about orientation.)
        static const char* DEST_ZONE = "corellia";
        static const float DEST_X = -150.0f;     // EXAMPLE placeholder near Coronet starport
        static const float DEST_Z = 28.0f;    // EXAMPLE placeholder near Coronet starport
        static const float DEST_Y = -4720.0f;        // terrain height; 0 lets the server clamp to ground
        static const float DEST_YAW = 0.0f;      // radians

        // ---- ticket lookup (by server template CRC) ----
        // Set this to the ACTUAL server template path for your return ticket.
        // If your item template file is server-side "object/tangible/item/return_ticket.iff",
        // keep this. If it's elsewhere, change the path string below.
        static const uint32 RETURN_TICKET_CRC = STRING_HASHCODE("object/tangible/item/return_ticket.iff");

        ManagedReference<SceneObject*> inventory = creature->getInventory();
        if (inventory == nullptr)
            return GENERALERROR;

        Locker invLock(inventory, creature);

        ManagedReference<SceneObject*> ticket = nullptr;
        const int count = inventory->getContainerObjectsSize();

        for (int i = 0; i < count; ++i) {
            SceneObject* so = inventory->getContainerObject(i);
            if (so == nullptr)
                continue;

            if (so->getServerObjectCRC() == RETURN_TICKET_CRC) {
                ticket = so;
                break;
            }
        }

        if (ticket == nullptr) {
            creature->sendSystemMessage("You need a Return Ticket in your inventory to use this command.");
            return GENERALERROR;
        }

        // Optional: prevent use in interiors, instances, or special scenes if desired
        // if (creature->getParent() != nullptr) { ... }

        // Consume the ticket FIRST (so if zoning fails we still spent the item).
        // If you prefer atomic "consume only on success", move these after a successful switchZone/teleport.
        {
            Locker ticketLock(ticket, creature);
            ticket->destroyObjectFromWorld(true);
            ticket->destroyObjectFromDatabase(true);
        }

        invLock.release();

        // Perform the teleport / planet switch.
        ZoneServer* zserv = creature->getZoneServer();
        if (zserv == nullptr)
            return GENERALERROR;

        // If already on Corellia, use intra-zone teleport; otherwise switchZone.
        Zone* curZone = creature->getZone();
        if (curZone != nullptr && curZone->getZoneName() == DEST_ZONE) {
            // Same planet: teleport within the zone.
            creature->teleport(DEST_X, DEST_Z, DEST_Y);
            creature->setDirection(DEST_YAW);
        } else {
            // Cross-planet: switch zone (drops to ground if Y=0).
            creature->switchZone(DEST_ZONE, DEST_X, DEST_Z, DEST_Y, DEST_YAW);
        }

        creature->sendSystemMessage("Your Return Ticket has been redeemed. Safe travels to Coronet.");
        return SUCCESS;
    }
};

#endif // USERETURNTICKETCOMMAND_H_
