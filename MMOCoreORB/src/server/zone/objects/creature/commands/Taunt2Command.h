#ifndef TAUNT2COMMAND_H_
#define TAUNT2COMMAND_H_

#include "CombatQueueCommand.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/creature/ai/AiAgent.h"
#include "server/zone/objects/tangible/threat/ThreatMap.h"
#include "server/zone/objects/tangible/threat/ThreatStates.h"
#include "server/zone/managers/combat/CombatManager.h"
#include "server/zone/managers/combat/CreatureAttackData.h"

class Taunt2Command : public CombatQueueCommand {
public:
    Taunt2Command(const String& name, ZoneProcessServer* server)
        : CombatQueueCommand(name, server) {}

    int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
        if (!checkStateMask(creature)) return INVALIDSTATE;
        if (!checkInvalidLocomotions(creature)) return INVALIDLOCOMOTION;

        // Validate primary target (standard Taunt behavior)
        ManagedReference<SceneObject*> targetObj = server->getZoneServer()->getObject(target, false);
        if (targetObj == nullptr || !targetObj->isCreatureObject()) return INVALIDTARGET;

        CreatureObject* targetCreature = cast<CreatureObject*>(targetObj.get());
        if (!targetCreature->isAttackableBy(creature)) return INVALIDTARGET;

        AiAgent* agent = targetCreature->asAiAgent();
        if (agent == nullptr) return INVALIDTARGET;

        // Do the action (handles animations, costs defined in Lua, etc.)
        int res = doCombatAction(creature, target);
        if (res != SUCCESS) return res;

        // Single-target taunt roll (same as base Taunt)
        {
            Locker lock(targetCreature, creature);

            if (agent->isTauntable()) {
                ThreatMap* threatMap = targetCreature->getThreatMap();
                if (threatMap != nullptr) {
                    int tauntMod = creature->getSkillMod("taunt");
                    int levelCombine = targetCreature->getLevel() + creature->getLevel();

                    if (System::random(levelCombine + tauntMod) >= System::random(levelCombine - tauntMod)) {
                        threatMap->setThreatState(creature, ThreatStates::TAUNTED, (uint64)tauntMod * 1000, (uint64)tauntMod * 1000);
                        threatMap->addAggro(creature, tauntMod * 10, (uint64)tauntMod * 1000);
                        if (creature->isPlayerCreature())
                            creature->sendSystemMessage("@cbt_spam:taunt_success_single");
                    } else {
                        creature->sendSystemMessage("@cbt_spam:taunt_fail_single");
                    }
                }
            } else {
                creature->sendSystemMessage("@cbt_spam:taunt_fail_single");
            }
        }

        // AoE extension guarded by Lua areaAction (mirrors Intimidate design)
        if (isAreaAction()) {
            CreatureAttackData data("", this, target);
            auto targets = CombatManager::instance()->getAreaTargets(creature, creature->getWeapon(), targetCreature, data);

            if (targets != nullptr && targets->size() > 0) {
                int tauntMod = creature->getSkillMod("taunt");

                for (int i = targets->size() - 1; i >= 0; --i) {
                    TangibleObject* tano = targets->get(i);
                    if (tano == nullptr || tano == creature) continue;

                    CreatureObject* other = tano->asCreatureObject();
                    if (other == nullptr || other == targetCreature) continue;
                    if (!other->isAttackableBy(creature)) continue;

                    AiAgent* otherAgent = other->asAiAgent();
                    if (otherAgent == nullptr) continue;

                    Locker lockOther(other, creature);

                    if (!otherAgent->isTauntable()) continue;

                    ThreatMap* otherThreat = other->getThreatMap();
                    if (otherThreat == nullptr) continue;

                    int levelCombine = other->getLevel() + creature->getLevel();
                    if (System::random(levelCombine + tauntMod) >= System::random(levelCombine - tauntMod)) {
                        otherThreat->setThreatState(creature, ThreatStates::TAUNTED, (uint64)tauntMod * 1000, (uint64)tauntMod * 1000);
                        otherThreat->addAggro(creature, tauntMod * 10, (uint64)tauntMod * 1000);
                    }
                }
            }
        }

        return res;
    }
};

#endif // TAUNT2COMMAND_H_