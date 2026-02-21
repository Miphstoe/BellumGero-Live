/*
 * FsBuffItemDeathObserverImplementation.cpp
 */

#include "server/zone/objects/tangible/misc/FsBuffItemDeathObserver.h"
#include "server/zone/objects/tangible/misc/FsBuffItem.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "templates/params/creature/CreatureAttribute.h"
#include "templates/params/creature/CreaturePosture.h"
#include "server/zone/objects/creature/buffs/Buff.h"
#include "server/zone/objects/creature/buffs/BuffCRC.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/SuiWindowType.h"
#include "templates/params/ObserverEventType.h"

int FsBuffItemDeathObserverImplementation::notifyObserverEvent(unsigned int eventType, Observable* observable, ManagedObject* arg1, int64 arg2) {
	if (eventType != ObserverEventType::PLAYERKILLED)
		return 0;

	ManagedReference<FsBuffItem*> strongItem = item.get();

	if (strongItem == nullptr)
		return 1;

	ManagedReference<CreatureObject*> player = cast<CreatureObject*>(observable);

	if (player == nullptr)
		return 1;

	// Schedule resurrection task
	Core::getTaskManager()->scheduleTask([player, strongItem] () {
		Locker locker(player);

		// Make sure player is actually dead
		if (!player->isDead())
			return;

		ManagedReference<PlayerObject*> playerGhost = player->getPlayerObject();

		if (playerGhost != nullptr) {
			// Restore force power for Jedi
			if (playerGhost->getJediState() > 1)
				playerGhost->setForcePower(playerGhost->getForcePowerMax());

			// Remove clone request dialog
			playerGhost->removeSuiBoxType(SuiWindowType::CLONE_REQUEST);
		}

		// Heal the player
		player->healDamage(player, CreatureAttribute::HEALTH, 5000);
		player->healDamage(player, CreatureAttribute::ACTION, 5000);
		player->healDamage(player, CreatureAttribute::MIND, 5000);

		// Clear wounds, dots, and negative states
		for (int i = 0; i < 9; ++i) {
			player->setWounds(i, 0);
		}
		player->setShockWounds(0);
		player->clearDots();
		player->removeFeignedDeath();

		// Set player upright
		player->setPosture(CreaturePosture::UPRIGHT);
		player->notifyObservers(ObserverEventType::CREATUREREVIVED, player, 0);
		player->broadcastPvpStatusBitmask();

		// Apply stat buffs - Health pool (2500 each)
		Reference<Buff*> healthBuff = new Buff(player, BuffCRC::MEDICAL_ENHANCE_HEALTH, 3600, BuffType::MEDICAL);
		Locker healthLocker(healthBuff);
		healthBuff->setAttributeModifier(CreatureAttribute::HEALTH, 2500);
		player->addBuff(healthBuff);

		Reference<Buff*> strengthBuff = new Buff(player, BuffCRC::MEDICAL_ENHANCE_STRENGTH, 3600, BuffType::MEDICAL);
		Locker strengthLocker(strengthBuff);
		strengthBuff->setAttributeModifier(CreatureAttribute::STRENGTH, 2500);
		player->addBuff(strengthBuff);

		Reference<Buff*> constitutionBuff = new Buff(player, BuffCRC::MEDICAL_ENHANCE_CONSTITUTION, 3600, BuffType::MEDICAL);
		Locker constitutionLocker(constitutionBuff);
		constitutionBuff->setAttributeModifier(CreatureAttribute::CONSTITUTION, 2500);
		player->addBuff(constitutionBuff);

		// Apply stat buffs - Action pool (2500 each)
		Reference<Buff*> actionBuff = new Buff(player, BuffCRC::MEDICAL_ENHANCE_ACTION, 3600, BuffType::MEDICAL);
		Locker actionLocker(actionBuff);
		actionBuff->setAttributeModifier(CreatureAttribute::ACTION, 2500);
		player->addBuff(actionBuff);

		Reference<Buff*> quicknessBuff = new Buff(player, BuffCRC::MEDICAL_ENHANCE_QUICKNESS, 3600, BuffType::MEDICAL);
		Locker quicknessLocker(quicknessBuff);
		quicknessBuff->setAttributeModifier(CreatureAttribute::QUICKNESS, 2500);
		player->addBuff(quicknessBuff);

		Reference<Buff*> staminaBuff = new Buff(player, BuffCRC::MEDICAL_ENHANCE_STAMINA, 3600, BuffType::MEDICAL);
		Locker staminaLocker(staminaBuff);
		staminaBuff->setAttributeModifier(CreatureAttribute::STAMINA, 2500);
		player->addBuff(staminaBuff);

		// Apply stat buffs - Mind pool (1250 each)
		Reference<Buff*> mindBuff = new Buff(player, BuffCRC::PERFORMANCE_ENHANCE_DANCE_MIND, 3600, BuffType::MEDICAL);
		Locker mindLocker(mindBuff);
		mindBuff->setAttributeModifier(CreatureAttribute::MIND, 1250);
		player->addBuff(mindBuff);

		Reference<Buff*> focusBuff = new Buff(player, BuffCRC::PERFORMANCE_ENHANCE_MUSIC_FOCUS, 3600, BuffType::MEDICAL);
		Locker focusLocker(focusBuff);
		focusBuff->setAttributeModifier(CreatureAttribute::FOCUS, 1250);
		player->addBuff(focusBuff);

		Reference<Buff*> willpowerBuff = new Buff(player, BuffCRC::PERFORMANCE_ENHANCE_MUSIC_WILLPOWER, 3600, BuffType::MEDICAL);
		Locker willpowerLocker(willpowerBuff);
		willpowerBuff->setAttributeModifier(CreatureAttribute::WILLPOWER, 1250);
		player->addBuff(willpowerBuff);

		player->sendSystemMessage("The Force Sensitive crystal has resurrected you with powerful buffs!");

		// Remove the protection buff icon
		player->removeBuff(BuffCRC::JEDI_FORCE_PROTECTION_1);

		// Decrease item uses and destroy if exhausted
		if (strongItem != nullptr) {
			Locker itemLocker(strongItem, player);

			// Remove observer from player
			strongItem->removeObserverFromPlayer();

			strongItem->decreaseUses();

			if (strongItem->getUsesRemaining() <= 0) {
				player->sendSystemMessage("The Force Sensitive crystal crumbles to dust, its power exhausted.");
				strongItem->destroyObjectFromWorld(true);
				strongItem->destroyObjectFromDatabase(true);
			}
		}
	}, "FsResurrectTask", 500);

	// Don't remove observer yet - task will handle it
	return 0;
}
