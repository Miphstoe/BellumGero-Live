/*
 * FsResurrectBuffObserverImplementation.cpp
 *
 *  Created on: Custom FS Resurrect Buff
 */

#include "server/zone/objects/creature/buffs/FsResurrectBuffObserver.h"
#include "server/zone/objects/creature/buffs/FsResurrectBuff.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "templates/params/creature/CreatureAttribute.h"
#include "templates/params/creature/CreaturePosture.h"
#include "server/zone/objects/creature/buffs/Buff.h"
#include "server/zone/objects/creature/buffs/BuffCRC.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/SuiWindowType.h"
#include "server/zone/objects/tangible/misc/FsBuffItem.h"
#include "templates/params/ObserverEventType.h"
#include "server/zone/Zone.h"
#include "server/zone/ZoneServer.h"

int FsResurrectBuffObserverImplementation::notifyObserverEvent(unsigned int eventType, Observable* observable, ManagedObject* arg1, int64 arg2) {
	if (eventType != ObserverEventType::PLAYERKILLED)
		return 0;

	ManagedReference<FsResurrectBuff*> strongBuff = buff.get();

	if (strongBuff == nullptr)
		return 0;

	ManagedReference<CreatureObject*> player = strongBuff->getPlayer();

	if (player == nullptr)
		return 0;

	player->sendSystemMessage("DEBUG: FS Resurrect observer triggered!");

	ManagedReference<FsBuffItem*> item = strongBuff->getSourceItem();

	// Resurrect the player
	Core::getTaskManager()->scheduleTask([player, item, strongBuff] () {
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

		// Apply stat buffs (Health: 2500, Action: 2500, Mind: 1250)
		Reference<Buff*> healthBuff = new Buff(player, BuffCRC::MEDICAL_ENHANCE_HEALTH, 3600, BuffType::MEDICAL);
		Locker healthLocker(healthBuff);
		healthBuff->setAttributeModifier(CreatureAttribute::HEALTH, 2500);
		player->addBuff(healthBuff);

		Reference<Buff*> actionBuff = new Buff(player, BuffCRC::MEDICAL_ENHANCE_ACTION, 3600, BuffType::MEDICAL);
		Locker actionLocker(actionBuff);
		actionBuff->setAttributeModifier(CreatureAttribute::ACTION, 2500);
		player->addBuff(actionBuff);

		Reference<Buff*> mindBuff = new Buff(player, BuffCRC::PERFORMANCE_ENHANCE_DANCE_MIND, 3600, BuffType::MEDICAL);
		Locker mindLocker(mindBuff);
		mindBuff->setAttributeModifier(CreatureAttribute::MIND, 1250);
		player->addBuff(mindBuff);

		player->sendSystemMessage("The Force Sensitive crystal has resurrected you with powerful buffs!");

		// Remove the resurrection buff
		if (strongBuff != nullptr) {
			Locker buffLocker(strongBuff, player);
			player->removeBuff(BuffCRC::FS_CRYSTAL_RESURRECT);
		}

		// Decrease item uses and destroy if exhausted
		if (item != nullptr) {
			Locker itemLocker(item, player);
			item->decreaseUses();

			if (item->getUsesRemaining() <= 0) {
				player->sendSystemMessage("The Force Sensitive crystal crumbles to dust, its power exhausted.");
				item->destroyObjectFromWorld(true);
				item->destroyObjectFromDatabase(true);
			}
		}
	}, "FsResurrectBuffTask", 500); // Delay to ensure death is fully processed

	// Don't remove the observer yet - let the task handle it
	return 0;
}
