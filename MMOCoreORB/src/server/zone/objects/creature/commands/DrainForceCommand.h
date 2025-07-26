/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef DRAINFORCECOMMAND_H_
#define DRAINFORCECOMMAND_H_

#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/managers/frs/FrsManager.h"
#include "CombatQueueCommand.h"

class DrainForceCommand : public CombatQueueCommand {
public:

	DrainForceCommand(const String& name, ZoneProcessServer* server) : CombatQueueCommand(name, server) {
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		if (isWearingArmor(creature)) {
			return NOJEDIARMOR;
		}

		if (!creature->checkCooldownRecovery("drainforce")) {
			creature->sendSystemMessage("You cannot drain force again yet.");
			return GENERALERROR;
		}

		ManagedReference<SceneObject*> object = server->getZoneServer()->getObject(target);

		// Modified: Allow NPCs to be targeted (removed !object->isPlayerCreature() check)
		if (object == nullptr)
			return INVALIDTARGET;

		CreatureObject* targetCreature = cast<CreatureObject*>( object.get());

		if (targetCreature == nullptr || targetCreature->isDead() || (targetCreature->isIncapacitated() && !targetCreature->isFeigningDeath()) || !targetCreature->isAttackableBy(creature))
			return INVALIDTARGET;

		if (!checkDistance(creature, targetCreature, range))
			return TOOFAR;

		if (!CollisionManager::checkLineOfSight(creature, targetCreature)) {
			creature->sendSystemMessage("@combat_effects:cansee_fail");//You cannot see your target.
			return GENERALERROR;
		}

		if (!playerEntryCheck(creature, targetCreature)) {
			return GENERALERROR;
		}

		Locker clocker(targetCreature, creature);

		ManagedReference<PlayerObject*> targetGhost = targetCreature->getPlayerObject();
		ManagedReference<PlayerObject*> playerGhost = creature->getPlayerObject();

		if (playerGhost == nullptr)
			return GENERALERROR;

		CombatManager* manager = CombatManager::instance();

		if (manager == nullptr)
			return GENERALERROR;

		if (manager->startCombat(creature, targetCreature, false)) { //lockDefender = false because already locked above.
			// Handle NPCs differently - check if they're Force-sensitive
			if (targetGhost == nullptr) {
				// This is an NPC - check if it has Force powers
				bool isForceNPC = false;
				
				// Only AiAgents have attack maps, regular NPCs don't
				if (targetCreature->isAiAgent()) {
					AiAgent* aiAgent = cast<AiAgent*>(targetCreature);
					const CreatureAttackMap* attackMap = aiAgent->getAttackMap();
					if (attackMap != nullptr) {
						for (int i = 0; i < attackMap->size(); i++) {
							String attackName = attackMap->getCommand(i);
							if (attackName == "forcelightningsingle1" || 
								attackName == "forcelightningsingle2" ||
								attackName == "forcelightningcone1" ||
								attackName == "forcelightningcone2" ||
								attackName == "mindblast1" || 
								attackName == "mindblast2" ||
								attackName == "forceknockdown1" ||
								attackName == "forceknockdown2" ||
								attackName == "forceweaken1" ||
								attackName == "forceweaken2" ||
								attackName == "forcethrow2" ||
								attackName == "forcechoke" ||
								attackName == "forceintimidate1" ||
								attackName == "forceintimidate2") {
								isForceNPC = true;
								break; // Found Force power, no need to check more
							}
						}
					}
				}
				
				if (!isForceNPC) {
					creature->sendSystemMessage("Target is not Force-sensitive");
					return GENERALERROR;
				}
				
				// NPC Force draining - use Mind HAM as "Force"
				int npcMind = targetCreature->getHAM(CreatureAttribute::MIND);
				if (npcMind <= 0) {
					creature->sendSystemMessage("@jedi_spam:target_no_force"); // That target does not have any Force Power.
					return GENERALERROR;
				}
				
				// Calculate drain amount with FRS integration
				int drain = 50 + System::random(151); // Base 50-200
				
				// Get attacker's FRS power bonus
				int attackerPowerMod = 0;
				FrsData* attackerData = playerGhost->getFrsData();
				int attackerCouncilType = attackerData->getCouncilType();
				
				if (attackerCouncilType == FrsManager::COUNCIL_LIGHT) {
					attackerPowerMod = creature->getSkillMod("force_power_light");
				} else if (attackerCouncilType == FrsManager::COUNCIL_DARK) {
					attackerPowerMod = creature->getSkillMod("force_power_dark");
				}
				
				// Apply attacker's power multiplier
				if (attackerPowerMod > 0) {
					float powerMultiplier = 1.0f + (attackerPowerMod / 100.0f);
					drain = (int)(drain * powerMultiplier);
				}
				
				// Apply 500 damage cap
				if (drain > 500) {
					drain = 500;
				}
				
				int forceDrain = npcMind >= drain ? drain : npcMind; // Drain whatever Mind the NPC has, up to max
				
				// Check if player can hold the drained Force
				int forceSpace = playerGhost->getForcePowerMax() - playerGhost->getForcePower();
				if (forceSpace <= 0) {
					creature->sendSystemMessage("You cannot hold any more Force power");
					return GENERALERROR;
				}
				
				if (forceDrain > forceSpace) {
					forceDrain = forceSpace; // Drain only what attacker can hold
				}
				
				// Apply the drain
				playerGhost->setForcePower(playerGhost->getForcePower() + (forceDrain - forceCost));
				targetCreature->inflictDamage(creature, CreatureAttribute::MIND, forceDrain, true, true);
				
				// Combat effects
				uint32 animCRC = getAnimationString().hashCode();
				creature->doCombatAnimation(targetCreature, animCRC, 0x1, 0xFF);
				manager->broadcastCombatSpam(creature, targetCreature, nullptr, forceDrain, "cbt_spam", combatSpam, 1);
				
				VisibilityManager::instance()->increaseVisibility(creature, visMod);
				
				// Set cooldown with FRS manipulation bonus
				int manipulationMod = 0;
				if (attackerCouncilType == FrsManager::COUNCIL_LIGHT) {
					manipulationMod = creature->getSkillMod("force_manipulation_light");
				} else if (attackerCouncilType == FrsManager::COUNCIL_DARK) {
					manipulationMod = creature->getSkillMod("force_manipulation_dark");
				}
				
				int cooldown = 7000; // Base 7 seconds
				if (manipulationMod > 0) {
					cooldown = Math::max(7000 / (1 + manipulationMod / 100), 3000); // Min 3 seconds
				}
				creature->updateCooldownTimer("drainforce", cooldown);
				
				return SUCCESS;
			}

			// Player vs Player logic
			int forceSpace = playerGhost->getForcePowerMax() - playerGhost->getForcePower();

			if (forceSpace <= 0) //Cannot Force Drain if attacker can't hold any more Force.
				return GENERALERROR;

			if (playerGhost->getForcePower() < forceCost) {
				creature->sendSystemMessage("@jedi_spam:no_force_power"); //You do not have sufficient Force power to perform that action.
				return GENERALERROR;
			}

			// Calculate drain amount with FRS integration
			int drain = 50 + System::random(151); // Base 50-200
			
			// Get attacker's FRS power bonus
			int attackerPowerMod = 0;
			FrsData* attackerData = playerGhost->getFrsData();
			int attackerCouncilType = attackerData->getCouncilType();
			
			if (attackerCouncilType == FrsManager::COUNCIL_LIGHT) {
				attackerPowerMod = creature->getSkillMod("force_power_light");
			} else if (attackerCouncilType == FrsManager::COUNCIL_DARK) {
				attackerPowerMod = creature->getSkillMod("force_power_dark");
			}
			
			// Apply attacker's power multiplier
			if (attackerPowerMod > 0) {
				float powerMultiplier = 1.0f + (attackerPowerMod / 100.0f);
				drain = (int)(drain * powerMultiplier);
			}
			
			// Get target's FRS control resistance (for players only)
			int targetControlMod = 0;
			FrsData* targetData = targetGhost->getFrsData();
			int targetCouncilType = targetData->getCouncilType();
			
			if (targetCouncilType == FrsManager::COUNCIL_LIGHT) {
				targetControlMod = targetCreature->getSkillMod("force_control_light");
			} else if (targetCouncilType == FrsManager::COUNCIL_DARK) {
				targetControlMod = targetCreature->getSkillMod("force_control_dark");
			}
			
			// Apply target's control resistance
			if (targetControlMod > 0) {
				float controlMultiplier = 1.0f + (targetControlMod / 100.0f);
				drain = (int)(drain / controlMultiplier);
			}
			
			// Apply 500 damage cap
			if (drain > 500) {
				drain = 500;
			}

			int targetForce = targetGhost->getForcePower();
			if (targetForce <= 0) {
				creature->sendSystemMessage("@jedi_spam:target_no_force"); //That target does not have any Force Power.
				return GENERALERROR;
			}

			int forceDrain = targetForce >= drain ? drain : targetForce; //Drain whatever Force the target has, up to max.

			if (forceDrain > forceSpace) {
				forceDrain = forceSpace; //Drain only what attacker can hold in their own Force pool.
			}

			playerGhost->setForcePower(playerGhost->getForcePower() + (forceDrain - forceCost));
			targetGhost->setForcePower(targetGhost->getForcePower() - forceDrain);

			uint32 animCRC = getAnimationString().hashCode();
			creature->doCombatAnimation(targetCreature, animCRC, 0x1, 0xFF);
			manager->broadcastCombatSpam(creature, targetCreature, nullptr, forceDrain, "cbt_spam", combatSpam, 1);

			if (targetCreature->getSkillMod("force_absorb") > 0) {
				float drainAbsorb = forceDrain * 0.4f;
				targetCreature->notifyObservers(ObserverEventType::FORCEABSORB, targetCreature, drainAbsorb);
				manager->sendMitigationCombatSpam(targetCreature, nullptr, drainAbsorb, 0x04); // FORCEABSORB
			}

			VisibilityManager::instance()->increaseVisibility(creature, visMod);

			bool shouldGcwCrackdownTef = false, shouldGcwTef = false, shouldBhTef = false;

			manager->checkForTefs(creature, targetCreature, &shouldGcwCrackdownTef, &shouldGcwTef, &shouldBhTef);
			if (shouldGcwCrackdownTef || shouldGcwTef || shouldBhTef) {
				playerGhost->updateLastCombatActionTimestamp(shouldGcwCrackdownTef, shouldGcwTef, shouldBhTef);
			}

			// Set cooldown with FRS manipulation bonus
			int manipulationMod = 0;
			if (attackerCouncilType == FrsManager::COUNCIL_LIGHT) {
				manipulationMod = creature->getSkillMod("force_manipulation_light");
			} else if (attackerCouncilType == FrsManager::COUNCIL_DARK) {
				manipulationMod = creature->getSkillMod("force_manipulation_dark");
			}
			
			int cooldown = 7000; // Base 7 seconds
			if (manipulationMod > 0) {
				cooldown = Math::max(7000 / (1 + manipulationMod / 100), 3000); // Min 3 seconds
			}
			creature->updateCooldownTimer("drainforce", cooldown);

			return SUCCESS;
		}

		return GENERALERROR;

	}

	float getCommandDuration(CreatureObject* object, const UnicodeString& arguments) const {
		float combatHaste = object->getSkillMod("combat_haste");

		if (combatHaste > 0) {
			return defaultTime * (1.f - (combatHaste / 100.f));
		} else {
			return defaultTime;
		}
	}

};

#endif //DRAINFORCECOMMAND_H_