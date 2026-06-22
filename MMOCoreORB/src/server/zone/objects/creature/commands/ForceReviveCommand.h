/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions. */

#ifndef FORCEREVIVECOMMAND_H_
#define FORCEREVIVECOMMAND_H_

#include "JediQueueCommand.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/creature/buffs/PrivateBuff.h"
#include "templates/params/creature/CreatureAttribute.h"

class ForceReviveCommand : public JediQueueCommand {
	int reviveHealAmount;
	float reviveRange;

public:
	ForceReviveCommand(const String& name, ZoneProcessServer* server)
		: JediQueueCommand(name, server) {
		forceCost = 300;
		reviveHealAmount = 500;
		reviveRange = 32.0f;
		visMod = 15;
		setCooldown(30000); // 30 seconds in milliseconds
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (creature == nullptr || !creature->isPlayerCreature())
			return GENERALERROR;

		// Standard state/locomotion checks (caster must be alive, not prone, etc.)
		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		if (creature->isProne() || creature->isMeditating() || creature->isSwimming()) {
			creature->sendSystemMessage("@error_message:wrong_state");
			return GENERALERROR;
		}

		if (creature->isRidingMount()) {
			creature->sendSystemMessage("@error_message:survey_on_mount");
			return GENERALERROR;
		}

		// Jedi cannot use Force abilities in armor
		if (isWearingArmor(creature))
			return NOJEDIARMOR;

		// Must have enough Force Power (uses JediQueueCommand base check)
		int forceResult = doJediForceCostCheck(creature);
		if (forceResult != SUCCESS)
			return forceResult;

		// Resolve target — try the command-queue target first, then the
		// creature's server-side selected target (chat-dispatched commands send targetID=0)
		uint64 effectiveTarget = (target != 0) ? target : creature->getTargetID();

		if (effectiveTarget == 0) {
			creature->sendSystemMessage("You must select a target to revive.");
			return INVALIDTARGET;
		}

		ManagedReference<SceneObject*> scObj = server->getZoneServer()->getObject(effectiveTarget);

		if (scObj == nullptr || !scObj->isCreatureObject()) {
			creature->sendSystemMessage("@healing_response:healing_response_a2"); // invalid target
			return INVALIDTARGET;
		}

		CreatureObject* targetCreature = scObj.castTo<CreatureObject*>();

		if (targetCreature == creature) {
			creature->sendSystemMessage("@error_message:target_self_disallowed");
			return GENERALERROR;
		}

		if (!targetCreature->isPlayerCreature()) {
			creature->sendSystemMessage("@healing_response:healing_response_a3"); // non-player entity
			return GENERALERROR;
		}

		Locker crossLocker(targetCreature, creature);

		if (!targetCreature->isDead() && !targetCreature->isIncapacitated()) {
			creature->sendSystemMessage("@healing_response:healing_response_a4"); // target does not require resuscitation
			return GENERALERROR;
		}

		if (!targetCreature->isResuscitable()) {
			creature->sendSystemMessage("@healing_response:too_dead_to_resuscitate");
			return GENERALERROR;
		}

		if (!checkDistance(creature, targetCreature, reviveRange))
			return TOOFAR;

		if (!targetCreature->isHealableBy(creature)) {
			creature->sendSystemMessage("@healing:pvp_no_help");
			return GENERALERROR;
		}

		// All validation passed — check/start cooldown now so a valid cast consumes it
		if (!checkCooldown(creature))
			return GENERALERROR;

		// Restore HAM pools enough to revive; healDamage triggers posturechange when
		// health crosses 0 on a dead/incapacitated creature automatically
		targetCreature->healDamage(creature, CreatureAttribute::HEALTH, reviveHealAmount);
		targetCreature->healDamage(creature, CreatureAttribute::ACTION, reviveHealAmount);
		targetCreature->healDamage(creature, CreatureAttribute::MIND, reviveHealAmount);

		targetCreature->setPosture(CreaturePosture::UPRIGHT);
		targetCreature->removeFeignedDeath();

		applyGroggyDebuff(targetCreature);

		// Deduct Force Power only after a successful revive
		doForceCost(creature);

		targetCreature->notifyObservers(ObserverEventType::CREATUREREVIVED, creature, 0);

		// Animations and effects
		creature->doAnimation("heal_other");
		targetCreature->playEffect("clienteffect/healing_healwound.cef", "");

		// System messages
		StringBuffer casterMsg;
		casterMsg << "You channel the Force and revive " << targetCreature->getFirstName() << ".";
		creature->sendSystemMessage(casterMsg.toString());

		StringBuffer targetMsg;
		targetMsg << "The Force flows through you as " << creature->getFirstName() << " revives you.";
		targetCreature->sendSystemMessage(targetMsg.toString());

		checkForTef(creature, targetCreature);

		return SUCCESS;
	}

private:
	void applyGroggyDebuff(CreatureObject* target) const {
		ManagedReference<PrivateBuff*> debuff = new PrivateBuff(target, STRING_HASHCODE("private_groggy_debuff"), 60, BuffType::JEDI);
		Locker locker(debuff);

		for (int i = 0; i < CreatureAttribute::ARRAYSIZE; i++)
			debuff->setAttributeModifier(i, -100);

		target->sendSystemMessage("Your grogginess will expire in 60.0 seconds.");
		target->addBuff(debuff);
	}
};

#endif // FORCEREVIVECOMMAND_H_
