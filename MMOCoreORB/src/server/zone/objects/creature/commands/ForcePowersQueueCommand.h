/*
 * ForcePowersQueueCommand.h
 *
 *  Created on: 24/05/2010
 *      Author: Valkyra
 */

#ifndef FORCEPOWERSQUEUECOMMAND_H_
#define FORCEPOWERSQUEUECOMMAND_H_

#include"server/zone/ZoneServer.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/managers/combat/CombatManager.h"
#include "server/zone/managers/combat/CreatureAttackData.h"
#include "server/zone/managers/collision/CollisionManager.h"
#include "CombatQueueCommand.h"
#include "server/zone/managers/visibility/VisibilityManager.h"

class ForcePowersQueueCommand : public CombatQueueCommand {
private:
	// Bellum Gero Force Powers Revamp - Phase 1A
	int getRevampBranchTier(CreatureObject* creature, uint32 commandCRC) const {
		if (creature == nullptr || !creature->isPlayerCreature() ||
				!creature->hasSkill("force_discipline_powers_novice")) {
			return 0;
		}

		bool lightningCommand =
			commandCRC == STRING_HASHCODE("forcelightningsingle1") ||
			commandCRC == STRING_HASHCODE("forcelightningsingle2") ||
			commandCRC == STRING_HASHCODE("forcelightningcone1") ||
			commandCRC == STRING_HASHCODE("forcelightningcone2");

		bool mentalCommand =
			commandCRC == STRING_HASHCODE("mindblast1") ||
			commandCRC == STRING_HASHCODE("mindblast2");

		bool pushCommand =
			commandCRC == STRING_HASHCODE("forcethrow1") ||
			commandCRC == STRING_HASHCODE("forcethrow2");

		if (lightningCommand) {
			if (creature->hasSkill("force_discipline_powers_lightning_04")) return 4;
			if (creature->hasSkill("force_discipline_powers_lightning_03")) return 3;
			if (creature->hasSkill("force_discipline_powers_lightning_02")) return 2;
			if (creature->hasSkill("force_discipline_powers_lightning_01")) return 1;
		}

		if (mentalCommand) {
			if (creature->hasSkill("force_discipline_powers_mental_04")) return 4;
			if (creature->hasSkill("force_discipline_powers_mental_03")) return 3;
			if (creature->hasSkill("force_discipline_powers_mental_02")) return 2;
			if (creature->hasSkill("force_discipline_powers_mental_01")) return 1;
		}

		if (pushCommand) {
			if (creature->hasSkill("force_discipline_powers_push_04")) return 4;
			if (creature->hasSkill("force_discipline_powers_push_03")) return 3;
			if (creature->hasSkill("force_discipline_powers_push_02")) return 2;
			if (creature->hasSkill("force_discipline_powers_push_01")) return 1;
		}

		if (commandCRC == STRING_HASHCODE("forcechoke") &&
				creature->hasSkill("force_discipline_powers_master")) {
			return 4;
		}

		return 0;
	}

	bool isRevampSingleTargetDamagePower(uint32 commandCRC) const {
		return commandCRC == STRING_HASHCODE("forcelightningsingle1") ||
			commandCRC == STRING_HASHCODE("forcelightningsingle2") ||
			commandCRC == STRING_HASHCODE("mindblast1") ||
			commandCRC == STRING_HASHCODE("forcethrow1") ||
			commandCRC == STRING_HASHCODE("forcethrow2") ||
			commandCRC == STRING_HASHCODE("forcechoke");
	}

	bool isRevampAreaDamagePower(uint32 commandCRC) const {
		return commandCRC == STRING_HASHCODE("forcelightningcone1") ||
			commandCRC == STRING_HASHCODE("forcelightningcone2") ||
			commandCRC == STRING_HASHCODE("mindblast2");
	}

	float getRevampTierMultiplier(int tier, bool usePvpTable) const {
		if (usePvpTable) {
			if (tier == 2) return 1.05f;
			if (tier == 3) return 1.10f;
			if (tier >= 4) return 1.15f;
			return 1.0f;
		}

		if (tier == 2) return 1.10f;
		if (tier == 3) return 1.25f;
		if (tier >= 4) return 1.40f;
		return 1.0f;
	}

	void applyRevampDamage(
			CreatureObject* creature,
			CreatureObject* targetCreature,
			CreatureAttackData& attackData) const {

		if (creature == nullptr || targetCreature == nullptr ||
				!creature->isPlayerCreature() || !attackData.isForceAttack()) {
			return;
		}

		float baseMinDamage = attackData.getMinDamage();
		float baseMaxDamage = attackData.getMaxDamage();

		if (baseMinDamage <= 0.f || baseMaxDamage <= 0.f)
			return;

		uint32 commandCRC = getNameCRC();
		bool singleTargetPower = isRevampSingleTargetDamagePower(commandCRC);
		bool areaPower = isRevampAreaDamagePower(commandCRC);

		if (!singleTargetPower && !areaPower)
			return;

		int tier = getRevampBranchTier(creature, commandCRC);

		if (tier <= 0)
			return;

		bool pvpTarget = targetCreature->isPlayerCreature();

		// Area/cone attacks use the conservative PvP table in Phase 1A because
		// CreatureAttackData is shared across all area targets.
		bool usePvpTable = pvpTarget || areaPower;
		float multiplier = getRevampTierMultiplier(tier, usePvpTable);

		if (creature->hasSkill("force_discipline_powers_master"))
			multiplier *= usePvpTable ? 1.10f : 1.15f;

		// Force Weaken vulnerability is restricted to supported single-target
		// attacks until per-defender area scaling is implemented safely.
		if (singleTargetPower) {
			if (targetCreature->hasBuff(STRING_HASHCODE("forceweaken2")))
				multiplier *= pvpTarget ? 1.08f : 1.15f;
			else if (targetCreature->hasBuff(STRING_HASHCODE("forceweaken1")))
				multiplier *= pvpTarget ? 1.04f : 1.08f;
		}

		int scaledMinDamage = (int)((baseMinDamage * multiplier) + 0.5f);
		int scaledMaxDamage = (int)((baseMaxDamage * multiplier) + 0.5f);

		attackData.setVariable("minDamage", String::valueOf(scaledMinDamage));
		attackData.setVariable("maxDamage", String::valueOf(scaledMaxDamage));
	}

public:

	ForcePowersQueueCommand(const String& name, ZoneProcessServer* server) : CombatQueueCommand(name, server) {
		visMod = 25;
	}

	int doCombatAction(CreatureObject* creature, const uint64& target, const UnicodeString& arguments = "") const {
		ManagedReference<SceneObject*> targetObject = server->getZoneServer()->getObject(target);

		if (targetObject == nullptr || !targetObject->isTangibleObject() || targetObject == creature)
			return INVALIDTARGET;

		float checkRange = range;

		if (creature->isProne())
			return NOPRONE;

		if(!checkDistance(creature, targetObject, checkRange))
			return TOOFAR;

		if (!CollisionManager::checkLineOfSight(creature, targetObject)) {
			creature->sendSystemMessage("@cbt_spam:los_fail");// "You lost sight of your target."
			return GENERALERROR;
		}

		if (!playerEntryCheck(creature, targetObject->asTangibleObject())) {
			return GENERALERROR;
		}

		ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

		if (ghost != nullptr && ghost->getForcePower() < getFrsModifiedForceCost(creature)) {
			creature->sendSystemMessage("@jedi_spam:no_force_power"); //"You do not have enough Force Power to peform that action.
			return GENERALERROR;
		}

		CombatManager* combatManager = CombatManager::instance();

		try {
			CreatureAttackData attackData(arguments, this, target);
			CreatureObject* targetCreature = targetObject->isCreatureObject() ? targetObject->asCreatureObject() : nullptr;

			applyRevampDamage(creature, targetCreature, attackData);

			int res = combatManager->doCombatAction(
				creature,
				creature->getWeapon(),
				cast<TangibleObject*>(targetObject.get()),
				attackData);

			switch (res) {
			case -1:
				return INVALIDTARGET;
			case -3:
				return GENERALERROR;
			}

			if (ghost != nullptr)
				ghost->setForcePower(ghost->getForcePower() - getFrsModifiedForceCost(creature));

		} catch (Exception& e) {
			error("unreported exception caught in ForcePowersQueueCommand::doCombatAction");
			error(e.getMessage());
			e.printStackTrace();
		}

		// Increase Visibility for Force Power.
		if (ghost != nullptr)
			VisibilityManager::instance()->increaseVisibility(creature, visMod);

		return SUCCESS;
	}

	int getFrsModifiedForceCost(CreatureObject* creature) const {
		ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

		if (ghost == nullptr)
			return forceCost;

		Locker locker(creature);

		FrsData* playerData = ghost->getFrsData();
		int councilType = playerData->getCouncilType();

		locker.release();

		int manipulationMod = 0;
		float frsModifier = 0;

		if (councilType == FrsManager::COUNCIL_LIGHT) {
			manipulationMod = creature->getSkillMod("force_manipulation_light");
			frsModifier = frsLightForceCostModifier;
		} else if (councilType == FrsManager::COUNCIL_DARK) {
			manipulationMod = creature->getSkillMod("force_manipulation_dark");
			frsModifier = frsDarkForceCostModifier;
		}

		if (manipulationMod == 0 || frsModifier == 0)
			return forceCost;

		return forceCost + (int)((manipulationMod * frsModifier) + .5);
	}

	float getCommandDuration(CreatureObject *object, const UnicodeString& arguments) const {
		float combatHaste = object->getSkillMod("combat_haste");

		if (combatHaste > 0)
			return speed * (1.f - (combatHaste / 100.f));
		else
			return speed;
	}

	virtual bool isJediCombatQueueCommand() {
		return true;
	}

};

#endif /* FORCEPOWERSQUEUECOMMAND_H_ */
