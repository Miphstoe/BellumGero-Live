/*
    Copyright <SWGEmu>
    See file COPYING for copying conditions.
*/

#ifndef AREALOOTCOMMAND_H_
#define AREALOOTCOMMAND_H_

#include "server/zone/objects/creature/commands/QueueCommand.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/managers/player/PlayerManager.h"
#include "server/zone/objects/transaction/TransactionLog.h"
#include "server/zone/Zone.h"
#include "server/zone/TreeEntry.h"

class AreaLootCommand : public QueueCommand {
public:
    AreaLootCommand(const String& name, ZoneProcessServer* server)
        : QueueCommand(name, server) {
    }

    int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
        if (!checkStateMask(creature))
            return INVALIDSTATE;

        if (!checkInvalidLocomotions(creature))
            return INVALIDLOCOMOTION;

        ZoneServer* zoneServer = server->getZoneServer();
        if (zoneServer == nullptr)
            return GENERALERROR;

        // Fixed range of 32 units
        return performAreaLoot(creature, 32.0f);
    }

private:
    int performAreaLoot(CreatureObject* creature, float range) const {
        Zone* zone = creature->getZone();
        
        if (zone == nullptr)
            return GENERALERROR;

        int lootedCorpses = 0;
        int totalItems = 0;
        int skippedCorpses = 0;

        // Get all objects in range using the correct function signature
        SortedVector<ManagedReference<TreeEntry*>> objectsInRange;
        zone->getInRangeObjects(creature->getWorldPositionX(), creature->getWorldPositionZ(), creature->getWorldPositionY(), range, &objectsInRange, true);

        // Process each nearby object
        for (int i = 0; i < objectsInRange.size(); ++i) {
            TreeEntry* entry = objectsInRange.get(i);
            if (entry == nullptr)
                continue;

            SceneObject* obj = cast<SceneObject*>(entry);
            if (obj == nullptr || !obj->isAiAgent())
                continue;

            AiAgent* agent = cast<AiAgent*>(obj);
            if (agent == nullptr || !agent->isDead())
                continue;

            // Check distance again to be sure
            if (!creature->isInRange(agent, range))
                continue;

            // Try to loot this corpse
            int result = lootSingleCorpse(creature, agent);
            if (result > 0) {
                lootedCorpses++;
                totalItems += result;
            } else if (result == -1) {
                skippedCorpses++; // Corpse had no permission or was skipped
            }
        }

        // Send feedback to player
        if (lootedCorpses == 0 && skippedCorpses == 0) {
            creature->sendSystemMessage("No lootable corpses found in range.");
        } else {
            StringBuffer msg;
            msg << "Area loot complete: " << totalItems << " items from " << lootedCorpses << " corpses";
            if (skippedCorpses > 0) {
                msg << " (" << skippedCorpses << " corpses skipped - no permission or lottery in progress)";
            }
            msg << ".";
            creature->sendSystemMessage(msg.toString());
        }

        return SUCCESS;
    }

    int lootSingleCorpse(CreatureObject* creature, AiAgent* agent) const {
        SceneObject* lootContainer = agent->getSlottedObject("inventory");
        
        if (lootContainer == nullptr)
            return 0;

        const ContainerPermissions* permissions = lootContainer->getContainerPermissions();
        if (permissions == nullptr)
            return 0;

        uint64 ownerID = permissions->getOwnerID();
        bool looterIsOwner = (ownerID == creature->getObjectID());
        bool groupIsOwner = (ownerID == creature->getGroupID());

        int itemsLooted = 0;

        if (looterIsOwner) {
            // Player owns corpse - loot everything
            itemsLooted = lootAllFromCorpse(creature, agent, lootContainer);
        } else if (groupIsOwner) {
            // Group owns corpse - handle based on group loot rule
            ManagedReference<GroupObject*> group = creature->getGroup();
            if (group != nullptr) {
                switch (group->getLootRule()) {
                case GroupManager::FREEFORALL:
                    // Pick up individual items only
                    itemsLooted = pickupOwnedItemsOnly(creature, agent, lootContainer);
                    break;
                case GroupManager::MASTERLOOTER:
                    // Only master looter can area loot group corpses
                    if (group->checkMasterLooter(creature)) {
                        itemsLooted = lootAllFromCorpse(creature, agent, lootContainer);
                    } else {
                        itemsLooted = pickupOwnedItemsOnly(creature, agent, lootContainer);
                    }
                    break;
                case GroupManager::LOTTERY:
                case GroupManager::RANDOM:
                    // Skip these corpses - too complex for batch processing
                    // But still pick up individual items
                    itemsLooted = pickupOwnedItemsOnly(creature, agent, lootContainer);
                    if (itemsLooted == 0 && lootContainer->getContainerObjectsSize() > 0) {
                        return -1; // Signal that corpse was skipped
                    }
                    break;
                }
            }
        } else {
            // No permission - only individual items
            itemsLooted = pickupOwnedItemsOnly(creature, agent, lootContainer);
            if (itemsLooted == 0 && lootContainer->getContainerObjectsSize() > 0) {
                return -1; // Signal that corpse was skipped
            }
        }

        return itemsLooted;
    }

    int lootAllFromCorpse(CreatureObject* creature, AiAgent* agent, SceneObject* lootContainer) const {
        PlayerManager* playerManager = creature->getZoneServer()->getPlayerManager();
        if (playerManager == nullptr)
            return 0;
        
        int originalCount = lootContainer->getContainerObjectsSize();
        int originalCredits = agent->getCashCredits();
        
        // Use the existing lootAll function
        playerManager->lootAll(creature, agent);
        
        int itemsLooted = originalCount - lootContainer->getContainerObjectsSize();
        
        // Count credits as an "item" for feedback purposes
        if (originalCredits > 0)
            itemsLooted++;
        
        return itemsLooted;
    }

    int pickupOwnedItemsOnly(CreatureObject* creature, AiAgent* agent, SceneObject* lootContainer) const {
        int itemsPickedUp = 0;
        int totalItems = lootContainer->getContainerObjectsSize();
        
        if (totalItems < 1) 
            return 0;

        SceneObject* playerInventory = creature->getSlottedObject("inventory");
        if (playerInventory == nullptr)
            return 0;

        ContainerPermissions* contPerms = lootContainer->getContainerPermissionsForUpdate();
        if (contPerms == nullptr)
            return 0;

        // Check each item for player ownership
        for (int i = totalItems - 1; i >= 0; --i) {
            SceneObject* object = lootContainer->getContainerObject(i);
            if (object == nullptr) continue;

            ContainerPermissions* itemPerms = object->getContainerPermissionsForUpdate();
            if (itemPerms == nullptr) continue;

            // Only pick up items owned by this player
            if (itemPerms->getOwnerID() == creature->getObjectID()) {
                if (playerInventory->isContainerFullRecursive()) {
                    // Inventory full - stop here and notify player
                    StringIdChatParameter full("group", "you_are_full");
                    creature->sendSystemMessage(full);
                    break;
                }

                uint64 originalOwner = contPerms->getOwnerID();
                contPerms->setOwner(creature->getObjectID());
                TransactionLog trx(agent, creature, object, TrxCode::NPCLOOTCLAIM);

                if (creature->getZoneServer()->getObjectController()->transferObject(object, playerInventory, -1, true)) {
                    itemPerms->clearDenyPermission("player", ContainerPermissions::OPEN);
                    itemPerms->clearDenyPermission("player", ContainerPermissions::MOVECONTAINER);
                    trx.commit();
                    itemsPickedUp++;
                } else {
                    trx.abort() << "Failed to transferObject to player";
                }

                contPerms->setOwner(originalOwner);
            }
        }

        return itemsPickedUp;
    }
};

#endif // AREALOOTCOMMAND_H_