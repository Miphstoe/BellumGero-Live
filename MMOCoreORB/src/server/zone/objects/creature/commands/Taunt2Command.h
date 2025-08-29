/*
                Copyright <SWGEmu>
        See file COPYING for copying conditions.*/
#ifndef TAUNT2COMMAND_H_
#define TAUNT2COMMAND_H_
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/tangible/threat/ThreatMap.h"

class Taunt2Command : public CombatQueueCommand {
public:
    Taunt2Command(const String& name, ZoneProcessServer* server) : CombatQueueCommand(name, server) {
    }

    int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
        if (!checkStateMask(creature))
            return INVALIDSTATE;

        if (!checkInvalidLocomotions(creature))
            return INVALIDLOCOMOTION;

        // Define taunt area radius (in meters)
        const float TAUNT_RADIUS = 15.0f;
        
        // Get creature's current position
        Vector3 creaturePosition = creature->getWorldPosition();
        Zone* zone = creature->getZone();
        
        if (zone == nullptr)
            return GENERALERROR;

        int res = doCombatAction(creature, target);
        if (res != SUCCESS)
            return res;

        // Get all objects in range
        SortedVector<ManagedReference<TreeEntry*>>* closeObjects = new SortedVector<ManagedReference<TreeEntry*>>();
        
        zone->getInRangeObjects(creaturePosition.getX(), 
                               creaturePosition.getZ(), 
                               creaturePosition.getY(), 
                               TAUNT_RADIUS, 
                               closeObjects, 
                               true);

        int tauntedCount = 0;
        int failedCount = 0;
        int tauntMod = creature->getSkillMod("taunt");

        // Iterate through all objects in range
        for (int i = 0; i < closeObjects->size(); ++i) {
            TreeEntry* entry = closeObjects->get(i).get();
            SceneObject* obj = static_cast<SceneObject*>(entry);
            
            if (obj == nullptr || !obj->isCreatureObject() || obj->isPlayerCreature())
                continue;

            CreatureObject* targetCreature = cast<CreatureObject*>(obj);
            
            if (targetCreature == nullptr || targetCreature == creature)
                continue;

            // Check if target is attackable
            if (!targetCreature->isAttackableBy(creature))
                continue;

            AiAgent* agent = targetCreature->asAiAgent();
            if (agent == nullptr)
                continue;

            // Lock the target creature
            Locker clocker(targetCreature, creature);
            
            // Check if target is tauntable
            if (!agent->isTauntable()) {
                failedCount++;
                continue;
            }

            ThreatMap* threatMap = targetCreature->getThreatMap();
            if (threatMap != nullptr) {
                int levelCombine = targetCreature->getLevel() + creature->getLevel();
                
                // Taunt calculation with reduced area penalty for better success rate
                int areaModifier = tauntMod * 0.9f; // Only 10% penalty for area effect
                
                // Improved success calculation - add base bonus for better hit rate
                int baseBonus = 25; // Base success bonus
                int attackerAdvantage = levelCombine + areaModifier + baseBonus;
                int defenderResistance = Math::max(1, levelCombine - areaModifier - (baseBonus / 2));
                
                if (System::random(attackerAdvantage) >= System::random(defenderResistance)) {
                    threatMap->setThreatState(creature, ThreatStates::TAUNTED, 
                                            (uint64)areaModifier * 1000, 
                                            (uint64)areaModifier * 1000);
                    threatMap->addAggro(creature, areaModifier * 10, (uint64)areaModifier * 1000);
                    tauntedCount++;
                } else {
                    failedCount++;
                }
            }
        }

        delete closeObjects;

        // Send appropriate system messages based on results
        if (tauntedCount > 0 && failedCount == 0) {
            if (creature->isPlayerCreature()) {
                StringBuffer message;
                message << "@cbt_spam:taunt_success_area You successfully taunt " << tauntedCount << " enemies!";
                creature->sendSystemMessage(message.toString());
            }
        } else if (tauntedCount > 0 && failedCount > 0) {
            if (creature->isPlayerCreature()) {
                StringBuffer message;
                message << "@cbt_spam:taunt_partial_area You taunt " << tauntedCount 
                       << " enemies, but " << failedCount << " resist your taunt.";
                creature->sendSystemMessage(message.toString());
            }
        } else if (tauntedCount == 0 && failedCount > 0) {
            if (creature->isPlayerCreature()) {
                creature->sendSystemMessage("@cbt_spam:taunt_fail_area All enemies in the area resist your taunt!");
            }
        } else {
            if (creature->isPlayerCreature()) {
                creature->sendSystemMessage("@cbt_spam:taunt_no_targets No valid enemies found in the area.");
            }
        }

        return SUCCESS;
    }
};

#endif // TAUNT2COMMAND_H_