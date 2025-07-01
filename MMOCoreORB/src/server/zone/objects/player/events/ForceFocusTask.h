/*
	Copyright <SWGEmu>
	See file COPYING for copying conditions.
*/

#ifndef FORCEFOCUSTASK_H_
#define FORCEFOCUSTASK_H_

#include "engine/engine.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/chat/StringIdChatParameter.h"
#include "templates/params/creature/CreatureAttribute.h"

class ForceFocusTask : public Task {

	ManagedReference<CreatureObject*> player;
	String moodString;

public:
	ForceFocusTask(CreatureObject* pl) {
		player = pl;
	}

	void setMoodString(const String& ms) {
		moodString = ms;
	}

	String getMoodString() {
		return moodString;
	}

	void run() {
		Locker playerLocker(player);

		try {
			Reference<ForceFocusTask*> ffocusTask = player->getPendingTask("forcefocus").castTo<ForceFocusTask*>();

			if (!player->isMeditating())
				return;

			// Priority system: DoTs first, then wounds, then battle fatigue (only one type per tick)
			if (player->isBleeding() || player->isPoisoned() || player->isDiseased()) {
				// Priority 1: DoT healing
				if (player->isBleeding()) {
					player->healDot(CreatureState::BLEEDING, 20);
					player->sendSystemMessage("Healing bleeding");
				} else if (player->isPoisoned()) {
					player->healDot(CreatureState::POISONED, 20);
					player->sendSystemMessage("Healing poison");
				} else if (player->isDiseased()) {
					player->healDot(CreatureState::DISEASED, 20);
					player->sendSystemMessage("Healing disease");
				}
			} else {
				// Check for wounds (Priority 2)
				Vector<uint8> woundedPools;
				for (uint8 i = 0; i < 9; ++i) {
					if (player->getWounds(i) > 0)
						woundedPools.add(i);
				}

				if (woundedPools.size() > 0) {
					// Priority 2: Wound healing
					uint8 pool = woundedPools.get(System::random(woundedPools.size() - 1));
					int wounds = player->getWounds(pool);
					int heal = 25;
					heal = Math::min(wounds, heal);

					player->healWound(player, pool, heal, true, false);
					player->sendSystemMessage("Healed " + String::valueOf(heal) + " wounds");
				} else {
					// Priority 3: Battle fatigue (only if no DoTs and no wounds)
					int battleFatigue = player->getShockWounds();
					if (battleFatigue > 0) {
						int healAmount = Math::min(10, battleFatigue);
						player->addShockWounds(-healAmount, true, false);
						player->sendSystemMessage("Healed " + String::valueOf(healAmount) + " battle fatigue");
					}
				}
			}

			// Visual effect
			player->playEffect("clienteffect/pl_force_meditate_self.cef", "");

			if (ffocusTask != nullptr)
				ffocusTask->reschedule(3000);
			else
				ffocusTask->schedule(3000);

		} catch (Exception& e) {
			player->error("unreported exception caught in ForceFocusTask::run");
		}
	}
};

#endif /* FORCEFOCUSTASK_H_ */