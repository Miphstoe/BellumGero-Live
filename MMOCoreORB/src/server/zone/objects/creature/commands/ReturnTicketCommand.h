#ifndef USERETURNTICKETCOMMAND_H_
#define USERETURNTICKETCOMMAND_H_

#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/ZoneServer.h"

class UseReturnTicketCommand : public QueueCommand {
public:
    UseReturnTicketCommand(const String& name, ZoneProcessServer* server)
        : QueueCommand(name, server) {}

    int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
        // Standard guards
        if (!checkStateMask(creature))
            return INVALIDSTATE;
        if (!checkInvalidLocomotions(creature))
            return INVALIDLOCOMOTION;
        if (creature->isInCombat()) {
            creature->sendSystemMessage("You cannot call for extraction while in combat.");
            return GENERALERROR;
        }
        if (creature->isRidingMount()) {
            creature->sendSystemMessage("Dismount before calling for extraction.");
            return GENERALERROR;
        }

        // NEW: block indoors/underground (buildings, caves, instances — anything with a cell parent)
        if (creature->getParent() != nullptr) {
            creature->sendSystemMessage("You must be outside to call for extraction.");
            return GENERALERROR;
        }

        // ---- destination (update to your exact tutorial spawn if needed) ----
        static const char* DEST_ZONE = "corellia";
        static const float DEST_X = -150.0f;   // TODO: your exact coords
        static const float DEST_Z = 0.0f;  // TODO: your exact coords
        static const float DEST_Y = -4720.0f;
        static const float DEST_YAW = 0.0f;

        // ---- ticket lookup ----
        static const uint32 RETURN_TICKET_CRC = STRING_HASHCODE("object/tangible/item/return_ticket.iff");

        ManagedReference<SceneObject*> inventory = creature->getInventory();
        if (inventory == nullptr)
            return GENERALERROR;

        Locker invLock(inventory, creature);

        ManagedReference<SceneObject*> ticket = nullptr;
        const int count = inventory->getContainerObjectsSize();
        for (int i = 0; i < count; ++i) {
            SceneObject* so = inventory->getContainerObject(i);
            if (so && so->getServerObjectCRC() == RETURN_TICKET_CRC) {
                ticket = so;
                break;
            }
        }

        if (ticket == nullptr) {
            creature->sendSystemMessage("You need a Return Ticket in your inventory to use this command.");
            return GENERALERROR;
        }

        // Consume the ticket (we’ve already passed all failure gates)
        {
            Locker ticketLock(ticket, creature);
            ticket->destroyObjectFromWorld(true);
            ticket->destroyObjectFromDatabase(true);
        }

        invLock.release();

        ZoneServer* zserv = creature->getZoneServer();
        if (zserv == nullptr)
            return GENERALERROR;

        Zone* curZone = creature->getZone();
        if (curZone != nullptr && curZone->getZoneName() == DEST_ZONE) {
            creature->teleport(DEST_X, DEST_Z, DEST_Y);
            creature->setDirection(DEST_YAW);
        } else {
            creature->switchZone(DEST_ZONE, DEST_X, DEST_Z, DEST_Y, DEST_YAW);
        }

        creature->sendSystemMessage("Your Return Ticket has been redeemed. Safe travels to Coronet.");
        return SUCCESS;
    }
};

#endif // USERETURNTICKETCOMMAND_H_
