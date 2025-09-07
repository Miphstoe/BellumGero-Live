/*
 * ThrowTrapTask.h
 *
 *	Created on: Nov 20, 2010
 *	Author: da
 *
 *	Refactored on: 2024-04-14
 *	By: Hakry
 *
 *  Updated on: 2025-09-07
 *  By: you & ChatGPT — add AoE support with safe defaults.
 */

#ifndef THROWTRAPTASK_H_
#define THROWTRAPTASK_H_

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/managers/combat/CombatManager.h"
#include "server/zone/managers/objectcontroller/ObjectController.h"
#include "templates/tangible/TrapTemplate.h"
#include "server/zone/objects/creature/buffs/TrapBuff.h"

namespace server {
namespace zone {
namespace objects {
namespace creature {
namespace events {

class ThrowTrapTask : public Task, public Logger {
	ManagedWeakReference<CreatureObject*> weakAttacker;
	ManagedWeakReference<CreatureObject*> weakTarget;
	ManagedWeakReference<TangibleObject*> weakTrap;

public:
	ThrowTrapTask(CreatureObject* attacker, CreatureObject* target, TangibleObject* trap) : Task() {
		weakAttacker = attacker;
		weakTarget = target;
		weakTrap = trap;

		setLoggingName("ThrowTrapTask");
	}

	virtual ~ThrowTrapTask() {
	}

	void run() {
		auto attacker = weakAttacker.get();
		auto target = weakTarget.get();

		if (attacker == nullptr || target == nullptr) {
			return;
		}

		// Lock the attacker
		Locker lock(attacker);

		// Remove any trap tasks from attacker
		attacker->removePendingTask("throwtrap");

		auto trap = weakTrap.get();

		if (trap == nullptr) {
			return;
		}

		auto zoneServer = attacker->getZoneServer();

		if (zoneServer == nullptr) {
			return;
		}

		auto combatManager = CombatManager::instance();

		if (combatManager == nullptr) {
			return;
		}

		auto trapData = cast<TrapTemplate*>(TemplateManager::instance()->getTemplate(trap->getServerObjectCRC()));

		if (trapData == nullptr) {
			error() << "Trap Template has a nullptr";
			return;
		}

		auto objectController = zoneServer->getObjectController();

		if (objectController == nullptr) {
			return;
		}

		const auto trapCommand = cast<const CombatQueueCommand*>(objectController->getQueueCommand(STRING_HASHCODE("throwtrap")));

		if (trapCommand == nullptr) {
			return;
		}

		// Cross lock the target to the attacker
		Locker targetLock(target, attacker);

		SortedVector<ManagedReference<TreeEntry*> > closeObjects;

		// Find nearby objects to our target using the target's COV
		CloseObjectsVector* closeObjectsVector = (CloseObjectsVector*) target->getCloseObjects();

		if (closeObjectsVector != nullptr) {
			closeObjectsVector->safeCopyReceiversTo(closeObjects, CloseObjectsVector::CREOTYPE);
		}

		// Release the lock on the target
		targetLock.release();

		// Trap Data from template
		uint64 state = trapData->getState();
		const auto defenseString = trapData->getDefenseMod();
		const auto animationString = trapData->getAnimation();
		uint32 trapCrc = animationString.hashCode();

		// ---- AoE settings ----------------------------------------------------
		// Primary source of truth:
		bool isAoeTrap = trapData->isAoeTrap();

		// Fallback: if your template flag isn't hooked up yet, enable AoE for the
		// specific trap by template name (noise maker) so this works immediately.
		if (!isAoeTrap) {
			auto* tmpl = trap->getObjectTemplate();
			if (tmpl != nullptr) {
				String t = tmpl->toString(); // e.g. "object/tangible/scout/trap/trap_noise_maker.iff"
				if (t.indexOf("trap_noise_maker") != -1) {
					isAoeTrap = true;
				}
			}
		}

		// Radius & cap: tune as you like. If you later add TrapTemplate getters
		// for these (e.g., getAoeRadius(), getAoeMaxTargets()), just read them here.
		const float aoeRadius = isAoeTrap ? 32.0f : 5.0f; // 10m AoE, 5m keeps single-target range check as before
		const int   aoeCap    = 12;                        // safety cap
		// ----------------------------------------------------------------------

		int debuffDuration = trapData->getDuration();
		short hamPool = trapData->getPoolToDamage();
		const auto skillMods = trapData->getSkillMods();
		float maxDamage = trapData->getMaxDamage();
		float minDamage = trapData->getMinDamage();

		// Trap Messages
		const auto successMsg = trapData->getSuccessMessage();
		const auto failMsg = trapData->getFailMessage();
		const auto startSpam = trapData->getStartSpam();
		const auto stopSpam = trapData->getStopSpam();

		// Trapping skill mod
		int trappingSkill = attacker->getSkillMod("trapping");
		uint64 targetID = target->getObjectID();

		int totalXP = 0;
		bool hasHit = false;
		int hitsApplied = 0;

		try {
			// Iterate the nearby eligible targets
			for (int i = 0; i < closeObjects.size(); ++i) {
				auto objectCreature = closeObjects.get(i).castTo<CreatureObject*>();

				if (objectCreature == nullptr || !objectCreature->isCreature() || objectCreature->isPet()) {
					continue;
				}

				bool isPrimaryTarget = objectCreature->getObjectID() == targetID;

				// If not AoE, only process the primary target
				if (!isAoeTrap && !isPrimaryTarget) {
					continue;
				}

				// If AoE, respect a conservative target cap (skip extras that aren't primary)
				if (isAoeTrap && !isPrimaryTarget && hitsApplied >= aoeCap) {
					continue;
				}

				auto targetAgent = objectCreature->asAiAgent();

				if (targetAgent == nullptr || !targetAgent->isAttackableBy(attacker) || !targetAgent->isCreature() || !targetAgent->isMonster()) {
					continue;
				}

				Locker agentLock(targetAgent, attacker);

				// Radius around the *primary* target (feels natural for thrown traps)
				if (!targetAgent->isInRange(target, aoeRadius)) {
					continue;
				}

				// Handle combat start
				combatManager->startCombat(attacker, attacker->getWeapon(), targetAgent, false);

				int targetDefense = targetAgent->getSkillMod(defenseString);

				int attackRoll = System::random(199) + 1;
				int defendRoll = System::random(199) + 1;

				float hitChance = combatManager->hitChanceEquation(trappingSkill + attackRoll, targetDefense + defendRoll);

				if (hitChance > 100) {
					hitChance = 100.f;
				} else if (hitChance < 0) {
					hitChance = 0.f;
				}

				int roll = System::random(100);
				bool hit = roll < hitChance;

				// Broadcast combat action for main target only (avoid spam)
				if (isPrimaryTarget) {
					auto action = new CombatAction(attacker, targetAgent, trapCrc, hit, 0L);
					if (action != nullptr) {
						attacker->broadcastMessage(action, true, false);
					}
				}

				if (hit) {
					// Calculate and apply damage
					float damage = System::random(maxDamage - minDamage) + minDamage;
					targetAgent->inflictDamage(attacker, hamPool, damage, true, true);

					// Prevent duplicate / redundant state
					if ((state > CreatureState::INVALID && targetAgent->hasState(state)) || targetAgent->hasBuff(trapCrc)) {
						continue;
					}

					ManagedReference<TrapBuff*> buff = new TrapBuff(targetAgent, trapCrc, state, debuffDuration);

					if (buff != nullptr) {
						if (isPrimaryTarget) {
							hasHit = true;
						}

						Locker locker(buff, attacker);

						if (state > CreatureState::INVALID) {
							buff->addState(state);
						}

						// Add skill mods to the buff
						for (int i = 0; i < skillMods->size(); ++i) {
							buff->setSkillModifier(skillMods->elementAt(i).getKey(), skillMods->get(i));
						}

						if (!startSpam.isEmpty()) {
							buff->setStartFlyText("trap/trap", startSpam, 0, 0xFF, 0);
						}

						if (!stopSpam.isEmpty()) {
							buff->setEndFlyText("trap/trap", stopSpam, 0xFF, 0, 0);
						}

						// Add buff to the target
						targetAgent->addBuff(buff);

						// Count applied hits for AoE cap bookkeeping
						++hitsApplied;

						if (!targetAgent->isEventMob()) {
							totalXP += targetAgent->getLevel() * 15;
						}
					}
				}
			}
		} catch(Exception& e) {
			error() << "Issue in ThrowTrapTask";
			e.printStackTrace();
		}

		// Send out trap message
		StringIdChatParameter message;

		if (hasHit) {
			message.setStringId("trap/trap", successMsg);
		} else if (!trapData->getFailMessage().isEmpty()) {
			message.setStringId("trap/trap", trapData->getFailMessage());
		}

		message.setTT(target->getDisplayedName());

		// Send trap message to the attacking player
		attacker->sendSystemMessage(message);

		// Lock the trap and reduce the use count (consume ONCE)
		Locker trapLock(trap, attacker);
		trap->decreaseUseCount();
		trapLock.release();

		// Reduce cost based upon player's strength, quickness, and focus if any are over 300
		int healthCost = attacker->calculateCostAdjustment(CreatureAttribute::STRENGTH, trapData->getHealthCost());
		int actionCost = attacker->calculateCostAdjustment(CreatureAttribute::QUICKNESS, trapData->getActionCost());
		int mindCost = attacker->calculateCostAdjustment(CreatureAttribute::FOCUS, trapData->getMindCost());

		attacker->inflictDamage(attacker, CreatureAttribute::HEALTH, healthCost, false);
		attacker->inflictDamage(attacker, CreatureAttribute::ACTION, actionCost, false);
		attacker->inflictDamage(attacker, CreatureAttribute::MIND, mindCost, false);

		// Award the XP for trapping
		if (totalXP > 0) {
			auto playerManager = zoneServer->getPlayerManager();

			if (playerManager != nullptr) {
				playerManager->awardExperience(attacker, "trapping", totalXP, true);
			}
		}
	}
};

} // namespace events
} // namespace creature
} // namespace objects
} // namespace zone
} // namespace server

using namespace server::zone::objects::creature::events;

#endif /* THROWTRAPTASK_H_ */
