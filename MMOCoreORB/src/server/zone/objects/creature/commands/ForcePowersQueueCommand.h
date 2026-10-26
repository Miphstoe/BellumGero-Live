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
#include "server/zone/managers/jedi/JediSeclusionManager.h"

class ForcePowersQueueCommand : public CombatQueueCommand {
private:
	// Bellum Gero Force Powers Revamp - Phase 1
	int getRevampBranchTier(CreatureObject* creature, uint32 crc) const {
		if (creature == nullptr || !creature->isPlayerCreature() || !creature->hasSkill("force_discipline_powers_novice")) return 0;
		bool lightning = crc == STRING_HASHCODE("forcelightningsingle1") || crc == STRING_HASHCODE("forcelightningsingle2") || crc == STRING_HASHCODE("forcelightningcone1") || crc == STRING_HASHCODE("forcelightningcone2");
		bool mental = crc == STRING_HASHCODE("mindblast1") || crc == STRING_HASHCODE("mindblast2");
		bool push = crc == STRING_HASHCODE("forcethrow1") || crc == STRING_HASHCODE("forcethrow2");
		if (lightning) {
			if (creature->hasSkill("force_discipline_powers_lightning_04")) return 4;
			if (creature->hasSkill("force_discipline_powers_lightning_03")) return 3;
			if (creature->hasSkill("force_discipline_powers_lightning_02")) return 2;
			if (creature->hasSkill("force_discipline_powers_lightning_01")) return 1;
		}
		if (mental) {
			if (creature->hasSkill("force_discipline_powers_mental_04")) return 4;
			if (creature->hasSkill("force_discipline_powers_mental_03")) return 3;
			if (creature->hasSkill("force_discipline_powers_mental_02")) return 2;
			if (creature->hasSkill("force_discipline_powers_mental_01")) return 1;
		}
		if (push) {
			if (creature->hasSkill("force_discipline_powers_push_04")) return 4;
			if (creature->hasSkill("force_discipline_powers_push_03")) return 3;
			if (creature->hasSkill("force_discipline_powers_push_02")) return 2;
			if (creature->hasSkill("force_discipline_powers_push_01")) return 1;
		}
		return 0;
	}

	bool isRevampDamagePower(uint32 crc) const {
		return crc == STRING_HASHCODE("forcelightningsingle1") || crc == STRING_HASHCODE("forcelightningsingle2") ||
			crc == STRING_HASHCODE("forcelightningcone1") || crc == STRING_HASHCODE("forcelightningcone2") ||
			crc == STRING_HASHCODE("mindblast1") || crc == STRING_HASHCODE("mindblast2") ||
			crc == STRING_HASHCODE("forcethrow1") || crc == STRING_HASHCODE("forcethrow2");
	}

	bool isRevampResponsivePower(uint32 crc) const {
		return crc == STRING_HASHCODE("forcethrow1") || crc == STRING_HASHCODE("forcethrow2") ||
			crc == STRING_HASHCODE("forceknockdown1") || crc == STRING_HASHCODE("forceknockdown2") || crc == STRING_HASHCODE("forceknockdown3") ||
			crc == STRING_HASHCODE("forceweaken1") || crc == STRING_HASHCODE("forceweaken2");
	}

	float getRevampTierMultiplier(int tier, bool conservative) const {
		if (conservative) {
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
public:
	void adjustCommandDamageForDefender(CreatureObject* attacker, CreatureObject* defender, float& minDmg, float& maxDmg) const override {
		if (attacker == nullptr || defender == nullptr || !attacker->isPlayerCreature() || minDmg <= 0.f || maxDmg <= 0.f) return;
		uint32 crc = getNameCRC();
		// Force Choke is intentionally excluded: its damage-of-hit DOT derives strength from the hit basis.
		if (!isRevampDamagePower(crc)) return;
		int tier = getRevampBranchTier(attacker, crc);
		if (tier <= 0) return;
		bool genuinePve = JediSeclusionManager::isValidOvertJediPveDamageTarget(attacker, defender);
		bool conservative = !genuinePve;
		float mult = getRevampTierMultiplier(tier, conservative);
		if (attacker->hasSkill("force_discipline_powers_master")) mult *= conservative ? 1.10f : 1.15f;
		if (defender->hasBuff(STRING_HASHCODE("forceweaken2"))) mult *= genuinePve ? 1.15f : 1.08f;
		else if (defender->hasBuff(STRING_HASHCODE("forceweaken1"))) mult *= genuinePve ? 1.08f : 1.04f;
		minDmg *= mult;
		maxDmg *= mult;
	}

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
			int res = combatManager->doCombatAction(
				creature,
				creature->getWeapon(),
				cast<TangibleObject*>(targetObject.get()),
				CreatureAttackData(arguments, this, target));

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

	float getCommandDuration(CreatureObject *object, const UnicodeString& arguments) const override {
		float baseSpeed = speed;

		// Phase 1 responsiveness is player-only; NPCs stay on the Live Lua cadence.
		if (object != nullptr && object->isPlayerCreature() && isRevampResponsivePower(getNameCRC()))
			baseSpeed = 3.0f;

		float combatHaste = object->getSkillMod("combat_haste");

		if (combatHaste > 0)
			return baseSpeed * (1.f - (combatHaste / 100.f));
		else
			return baseSpeed;
	}

	virtual bool isJediCombatQueueCommand() {
		return true;
	}

};

#endif /* FORCEPOWERSQUEUECOMMAND_H_ */
