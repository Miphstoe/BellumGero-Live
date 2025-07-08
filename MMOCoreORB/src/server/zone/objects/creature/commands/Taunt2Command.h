/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef TAUNT2COMMAND_H_
#define TAUNT2COMMAND_H_

#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/tangible/threat/ThreatStates.h"
#include "server/zone/managers/combat/CombatManager.h"
#include "server/zone/managers/combat/CreatureAttackData.h"

class Taunt2Command : public CombatQueueCommand {
public:
	Taunt2Command(const String& name, ZoneProcessServer* server) : CombatQueueCommand(name, server) {
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		ManagedReference<SceneObject*> targetObject = creature->getZoneServer()->getObject(target);

		if (targetObject == nullptr || !targetObject->isAiAgent())
			return INVALIDTARGET;

		ManagedReference<AiAgent*> agent = cast<AiAgent*>(targetObject.get());

		if (agent == nullptr)
			return INVALIDTARGET;

		if (!agent->isAttackableBy(creature))
			return INVALIDTARGET;

		if (!agent->isTauntable()) {
			if (creature->isPlayerCreature()) {
				creature->sendSystemMessage("@cbt_spam:taunt_fail_single");
			}
			return INVALIDTARGET;
		}

		int res = doCombatAction(creature, target);

		if (res == SUCCESS) {
			int numberTaunted = 0;
			
			// Get area targets using the combat framework
			CreatureAttackData data = CreatureAttackData("", this, target);
			Reference<SortedVector<ManagedReference<TangibleObject*>>*> targets = CombatManager::instance()->getAreaTargets(creature, creature->getWeapon(), agent, data);

			// Apply taunt to all targets (getAreaTargets already includes primary target)
			for (int i = 0; i < targets->size(); ++i) {
				ManagedReference<TangibleObject*> targetTano = targets->get(i);
				
				if (targetTano == nullptr)
					continue;

				ManagedReference<AiAgent*> areaAgent = targetTano->asAiAgent();
				if (areaAgent == nullptr)
					continue;

				if (!areaAgent->isTauntable())
					continue;

				if (!areaAgent->isAttackableBy(creature))
					continue;

				if (areaAgent->isDead() || areaAgent->isIncapacitated())
					continue;

				Locker alocker(areaAgent, creature);
				auto threatMap = areaAgent->getThreatMap();

				if (threatMap != nullptr) {
					int tauntMod = creature->getSkillMod("taunt");
					
					int baseChance = 70; // 70% minimum always
					int skillBonus = (int)(tauntMod * 0.5); // Each skill point = +0.5%
					int successChance = baseChance + skillBonus;
					
					// Cap at 95% maximum
					if (successChance > 95) successChance = 95;

					if (System::random(100) < successChance) {
						threatMap->setThreatState(creature, ThreatStates::TAUNTED, (uint64)tauntMod * 1000, (uint64)tauntMod * 1000);
						threatMap->addAggro(creature, tauntMod * 100, (uint64)tauntMod * 1000);
						
						CombatManager* combatManager = CombatManager::instance();
						if (combatManager != nullptr && (!areaAgent->hasDefender(creature) || !areaAgent->isInCombat())) {
							combatManager->startCombat(creature, areaAgent);
						}
						numberTaunted++;
					}
				}
			}

			if (numberTaunted > 0) {
				if (creature->isPlayerCreature())
					creature->sendSystemMessage("You successfully taunted a total of " + String::valueOf(numberTaunted) + " targets.");
				return SUCCESS;
			}
			else {
				if (creature->isPlayerCreature())
					creature->sendSystemMessage("You were unable to successfully taunt any targets.");	
				return res;
			}
		}

		return res;
	}
};

#endif // TAUNT2COMMAND_H_