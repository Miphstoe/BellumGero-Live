/*
 * Bellum Gero Force Powers Revamp - Phase 3
 * Master Powers combat Force regeneration channel.
 */
#ifndef FORCERENEWALCOMMAND_H_
#define FORCERENEWALCOMMAND_H_

#include "server/zone/objects/player/events/ForceRenewalTask.h"

class ForceRenewalCommand : public QueueCommand {
public:
	ForceRenewalCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		if (!creature->isPlayerCreature())
			return GENERALERROR;

		if (!creature->hasSkill("force_discipline_powers_master")) {
			creature->sendSystemMessage("You must be a Master of Force Powers to use Force Renewal.");
			return GENERALERROR;
		}

		if (!creature->isInCombat()) {
			creature->sendSystemMessage("Force Renewal can only be used while in combat.");
			return GENERALERROR;
		}

		if (isWearingArmor(creature))
			return NOJEDIARMOR;

		ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();
		if (ghost == nullptr)
			return GENERALERROR;

		if (ghost->getForcePowerMax() <= 0 || ghost->getForcePower() >= ghost->getForcePowerMax()) {
			creature->sendSystemMessage("Your Force Power is already full.");
			return GENERALERROR;
		}

		Reference<Task*> existing = creature->getPendingTask("forcerenewal");
		if (existing != nullptr) {
			creature->sendSystemMessage("You are already channeling Force Renewal.");
			return GENERALERROR;
		}

		const String cooldownKey = "fm_phase3_force_renewal";
		if (!creature->checkCooldownRecovery(cooldownKey)) {
			creature->sendSystemMessage("Force Renewal is still recovering.");
			return GENERALERROR;
		}

		// Enter the vulnerable channel posture before registering interruption
		// observers so the activation posture change does not cancel itself.
		creature->setMoodString("meditating");
		creature->setPosture(CreaturePosture::SITTING);
		creature->setState(CreatureState::ALERT);
		creature->playEffect("clienteffect/pl_force_meditate_self.cef", "");
		creature->sendSystemMessage("You begin channeling Force Renewal.");

		Reference<ForceRenewalTask*> renewalTask = new ForceRenewalTask(creature);
		creature->addPendingTask("forcerenewal", renewalTask, 1000);

		PlayerManager* playermgr = server->getZoneServer()->getPlayerManager();
		creature->registerObserver(ObserverEventType::POSTURECHANGED, playermgr);
		creature->registerObserver(ObserverEventType::DAMAGERECEIVED, playermgr);

		// Cooldown begins on activation. Being interrupted still consumes it.
		creature->addCooldown(cooldownKey, 10000);

		return SUCCESS;
	}
};

#endif // FORCERENEWALCOMMAND_H_
