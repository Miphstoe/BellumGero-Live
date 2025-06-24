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
		if (player == nullptr) {
			return;
		}

		Locker playerLocker(player);

		try {
			Reference<ForceFocusTask*> ffocusTask = player->getPendingTask("forcefocus").castTo<ForceFocusTask*>();

			if (!player->isMeditating()) {
				return;
			}

			bool healPerformed = false;

			// Wound healing
			Vector<uint8> woundedPools;
			Vector<uint8> hamPools;
			Vector<uint8> regenPools;

			for (uint8 i = 0; i < 9; ++i) {
				if (player->getWounds(i) > 0) {
					woundedPools.add(i);
					if ((i == 0) || (i == 3) || (i == 6)) {
						hamPools.add(i);
					}
					else if ((i == 2) || (i == 5) || (i == 8)) {
						regenPools.add(i);
					}
				}
			}

			if (woundedPools.size() > 0) {
				uint8 pool;
				if (hamPools.size() > 0) {
					pool = hamPools.get(System::random(hamPools.size() - 1));
				}
				else if (regenPools.size() > 0) {
					pool = regenPools.get(System::random(regenPools.size() - 1));
				}
				else {
					pool = woundedPools.get(System::random(woundedPools.size() - 1));
				}

				int wounds = player->getWounds(pool);
				int heal = 25;
				heal = Math::min(wounds, heal);

				player->healWound(player, pool, heal, true, false);
				healPerformed = true;
			}

			// DoT healing
			if (player->isBleeding() || player->isPoisoned() || player->isDiseased()) {
				if (player->isBleeding())
					player->healDot(CreatureState::BLEEDING, 20);
				else if (player->isPoisoned())
					player->healDot(CreatureState::POISONED, 20);
				else if (player->isDiseased())
					player->healDot(CreatureState::DISEASED, 20);

				healPerformed = true;
			}

			// Battle fatigue healing 
			int fixedHealAmount = 10;
			int battleFatigue = player->getShockWounds();

			if (battleFatigue > 0) {
				int healAmount = Math::min(fixedHealAmount, battleFatigue);
				player->addShockWounds(-healAmount, true, false);
				healPerformed = true;
			}

			// Client effect throttling using custom var so animation won't spam
			uint64 currentTime = System::getMilliseconds();
			uint64 lastEffectTime = 0;

			player->getCustomVar("focus.lastEffectTime", lastEffectTime); // Different var name

			if (currentTime - lastEffectTime >= 6000) {
				player->playEffect("clienteffect/pl_force_meditate_self.cef", "");
				player->setCustomVar("focus.lastEffectTime", currentTime);
			}

			// Reschedule task - faster tick rate than meditate
			if (ffocusTask != nullptr)
				ffocusTask->reschedule(2000);
			else
				ffocusTask->schedule(2000);

		} catch (Exception& e) {
			player->error("unreported exception caught in ForceFocusTask::run");
		}
	}
};

#endif /* FORCEFOCUSTASK_H_ */