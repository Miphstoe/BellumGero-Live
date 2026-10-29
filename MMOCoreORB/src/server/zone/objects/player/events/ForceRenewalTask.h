/*
 * Bellum Gero Force Powers Revamp - Phase 3
 * Four-second Master Powers Force Renewal channel.
 */
#ifndef FORCERENEWALTASK_H_
#define FORCERENEWALTASK_H_

#include "engine/engine.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"

class ForceRenewalTask : public Task {
	ManagedReference<CreatureObject*> player;
	int ticksCompleted;
	bool ending;

	void endChannel(bool completed, const String& message) {
		if (ending || player == nullptr)
			return;

		ending = true;

		Reference<Task*> pending = player->getPendingTask("forcerenewal");
		if (pending != nullptr)
			player->removePendingTask("forcerenewal");

		if (player->hasState(CreatureState::ALERT))
			player->clearState(CreatureState::ALERT, true);

		player->setMood(player->getMoodID(), true);

		if (player->getPosture() == CreaturePosture::SITTING)
			player->setPosture(CreaturePosture::UPRIGHT);

		if (!message.isEmpty())
			player->sendSystemMessage(message);
	}

public:
	ForceRenewalTask(CreatureObject* pl) : Task() {
		player = pl;
		ticksCompleted = 0;
		ending = false;
	}

	void interrupt(const String& message) {
		if (isScheduled())
			cancel();

		endChannel(false, message);
	}

	void run() {
		ManagedReference<CreatureObject*> strongPlayer = player;
		if (strongPlayer == nullptr)
			return;

		Locker playerLocker(strongPlayer);

		try {
			Reference<ForceRenewalTask*> pending = strongPlayer->getPendingTask("forcerenewal").castTo<ForceRenewalTask*>();
			if (pending == nullptr || pending.get() != this)
				return;

			// Defense in depth for skill loss/respec or state manipulation mid-channel.
			if (!strongPlayer->hasSkill("force_discipline_powers_master") || !strongPlayer->isInCombat() || strongPlayer->getPosture() != CreaturePosture::SITTING) {
				endChannel(false, "Your Force Renewal was interrupted.");
				return;
			}

			ManagedReference<PlayerObject*> ghost = strongPlayer->getPlayerObject();
			if (ghost == nullptr) {
				endChannel(false, "Your Force Renewal ends.");
				return;
			}

			int forceMax = ghost->getForcePowerMax();
			int forceCurrent = ghost->getForcePower();

			if (forceMax <= 0 || forceCurrent >= forceMax) {
				endChannel(true, "Your Force Renewal is complete.");
				return;
			}

			// Four one-second ticks at 12.5% maximum Force each. A full uninterrupted
			// channel therefore restores 50% maximum Force, capped at the bar maximum.
			int restore = Math::max(1, forceMax / 8);
			restore = Math::min(restore, forceMax - forceCurrent);
			ghost->setForcePower(forceCurrent + restore);
			strongPlayer->playEffect("clienteffect/pl_force_meditate_self.cef", "");

			ticksCompleted++;

			if (ticksCompleted >= 4 || ghost->getForcePower() >= forceMax) {
				endChannel(true, "Your Force Renewal is complete.");
				return;
			}

			reschedule(1000);
		} catch (Exception& e) {
			strongPlayer->error("unreported exception caught in ForceRenewalTask::run");
		}
	}
};

#endif // FORCERENEWALTASK_H_
