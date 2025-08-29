#ifndef FORCETAUNTCOMMAND_H_
#define FORCETAUNTCOMMAND_H_

#include "ForcePowersQueueCommand.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/creature/ai/AiAgent.h"
#include "server/zone/objects/tangible/threat/ThreatMap.h"
#include "server/zone/objects/tangible/threat/ThreatStates.h"

class ForceTauntCommand : public ForcePowersQueueCommand {
public:
    ForceTauntCommand(const String& name, ZoneProcessServer* server)
        : ForcePowersQueueCommand(name, server) {}

    int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
        if (!checkStateMask(creature)) return INVALIDSTATE;
        if (!checkInvalidLocomotions(creature)) return INVALIDLOCOMOTION;

        ManagedReference<SceneObject*> targetObj = server->getZoneServer()->getObject(target, false);
        if (targetObj == nullptr || !targetObj->isCreatureObject()) return INVALIDTARGET;

        CreatureObject* targetCreature = cast<CreatureObject*>(targetObj.get());
        if (!targetCreature->isAttackableBy(creature)) return INVALIDTARGET;

        AiAgent* agent = targetCreature->asAiAgent();
        if (agent == nullptr) return INVALIDTARGET;

        // Force path (handles FP cost + visibility from Lua fields)
        int res = doCombatAction(creature, target);
        if (res != SUCCESS) return res;

        Locker lock(targetCreature, creature);

        if (!agent->isTauntable()) {
            creature->sendSystemMessage("@cbt_spam:taunt_fail_single");
            return res;
        }

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

        return res;
    }
};

#endif // FORCETAUNTCOMMAND_H_