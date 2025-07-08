/*
    Copyright <SWGEmu>
    See file COPYING for copying conditions.
*/

#ifndef HARVESTAREACOMMAND_H_
#define HARVESTAREACOMMAND_H_

#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/creature/ai/Creature.h"
#include "server/zone/managers/creature/CreatureManager.h"
#include "server/zone/Zone.h"
#include "server/zone/TreeEntry.h"

class HarvestAreaCommand : public QueueCommand {
public:
    HarvestAreaCommand(const String& name, ZoneProcessServer* server)
        : QueueCommand(name, server) {
    }

    int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
        if (!checkStateMask(creature))
            return INVALIDSTATE;

        if (!checkInvalidLocomotions(creature))
            return INVALIDLOCOMOTION;

        if (!creature->isPlayerCreature())
            return INVALIDTARGET;

        ManagedReference<CreatureObject*> player = cast<CreatureObject*>(creature);
        if (player == nullptr)
            return INVALIDTARGET;

        StringTokenizer args(arguments.toString());
        String harvesttype = "";

        if (args.hasMoreTokens())
            args.getStringToken(harvesttype);

        harvesttype = harvesttype.toLowerCase();
        byte type = 0;

        // Parse harvest type argument - matches original harvest command logic
        if (harvesttype == "meat")
            type = 234;
        else if (harvesttype == "hide")
            type = 235;
        else if (harvesttype == "bone")
            type = 236;
        else if (harvesttype != "") {
            player->sendSystemMessage("@error_message:no_resource");
            return GENERALERROR;
        }
        // If harvesttype == "", type remains 0 (random selection like original)

        // Fixed range of 32 units (same as arealoot)
        return performAreaHarvest(player, type, 32.0f);
    }

private:
    int performAreaHarvest(CreatureObject* player, byte harvestType, float range) const {
        Zone* zone = player->getZone();
        
        if (zone == nullptr)
            return GENERALERROR;

        int harvestedCorpses = 0;
        int skippedCorpses = 0;

        // Get all objects in range using the same method as arealoot
        SortedVector<ManagedReference<TreeEntry*>> objectsInRange;
        zone->getInRangeObjects(player->getWorldPositionX(), player->getWorldPositionZ(), player->getWorldPositionY(), range, &objectsInRange, true);

        // Process each nearby object
        for (int i = 0; i < objectsInRange.size(); ++i) {
            TreeEntry* entry = objectsInRange.get(i);
            if (entry == nullptr)
                continue;

            SceneObject* obj = cast<SceneObject*>(entry);
            if (obj == nullptr || !obj->isCreatureObject())
                continue;

            CreatureObject* creo = cast<CreatureObject*>(obj);
            if (creo == nullptr || !creo->isCreature())
                continue;

            Creature* cr = cast<Creature*>(creo);
            if (cr == nullptr)
                continue;

            // Check distance again to be sure
            if (!player->isInRange(cr, range))
                continue;

            // Try to harvest this corpse
            int result = harvestSingleCorpse(player, cr, harvestType);
            if (result == 1) {
                harvestedCorpses++;
            } else if (result == 0) {
                skippedCorpses++;
            }
            // result == -1 means error, but we continue processing other corpses
        }

        // Send feedback to player
        if (harvestedCorpses == 0 && skippedCorpses == 0) {
            player->sendSystemMessage("No harvestable corpses found in range.");
        } else {
            StringBuffer msg;
            msg << "Area harvest complete: " << harvestedCorpses << " corpses harvested";
            if (skippedCorpses > 0) {
                msg << " (" << skippedCorpses << " corpses skipped - no resources or already harvested)";
            }
            msg << ".";
            player->sendSystemMessage(msg.toString());
        }

        return SUCCESS;
    }

    int harvestSingleCorpse(CreatureObject* player, Creature* cr, byte harvestType) const {
        // Apply same validation as original harvest command
        if (!cr->isDead())
            return 0; // Skip alive creatures

        if (cr->getZone() == nullptr)
            return -1; // Error

        if (cr->getDnaState() == CreatureManager::DNADEATH)
            return 0; // Skip already DNA sampled creatures

        if (!cr->canHarvestMe(player))
            return 0; // Skip creatures player cannot harvest

        // Lock the creature for harvesting
        Locker clocker(cr, player);

        byte type = harvestType;

        // If no specific type requested (type == 0), randomly select like original harvest command
        if (type == 0) {
            Vector<int> types;
            if(!cr->getMeatType().isEmpty()) {
                types.add(234);
            }
            if(!cr->getHideType().isEmpty()) {
                types.add(235);
            }
            if(!cr->getBoneType().isEmpty()) {
                types.add(236);
            }
            if(types.size() > 0)
                type = types.get(System::random(types.size() - 1));
        } else {
            // Check if creature has the specifically requested resource type
            bool hasResource = false;
            if (type == 234 && !cr->getMeatType().isEmpty())
                hasResource = true;
            else if (type == 235 && !cr->getHideType().isEmpty())
                hasResource = true;
            else if (type == 236 && !cr->getBoneType().isEmpty())
                hasResource = true;

            if (!hasResource)
                return 0; // Skip creatures without the requested resource
        }

        // Final check - make sure we have a valid type
        if (type == 0)
            return 0; // No harvestable resources found

        // Perform the harvest using the creature manager
        ManagedReference<CreatureManager*> manager = cr->getZone()->getCreatureManager();
        if (manager != nullptr) {
            manager->harvest(cr, player, type);
            return 1; // Success
        }

        return -1; // Error
    }
};

#endif // HARVESTAREACOMMAND_H_