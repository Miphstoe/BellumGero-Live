#include "server/zone/objects/tangible/misc/FsBuffItem.h"
#include "server/zone/objects/tangible/misc/FsBuffItemDeathObserver.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/packets/scene/AttributeListMessage.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/objects/creature/BuffAttribute.h"
#include "server/zone/objects/creature/buffs/Buff.h"
#include "server/zone/objects/creature/buffs/BuffCRC.h"
#include "server/zone/objects/creature/buffs/BuffType.h"
#include "server/chat/StringIdChatParameter.h"
#include "server/zone/managers/object/ObjectManager.h"
#include "templates/params/ObserverEventType.h"
#include "server/zone/Zone.h"
#include "server/zone/ZoneServer.h"

void FsBuffItemImplementation::fillObjectMenuResponse(ObjectMenuResponse* menuResponse, CreatureObject* player) {
	menuResponse->addRadialMenuItem(68, 3, "@quest/force_sensitive/utils:use_special_effect");
}

int FsBuffItemImplementation::handleObjectMenuSelect(CreatureObject* player, byte selectedID) {
	if (!isASubChildOf(player))
		return 0;

	if (selectedID == 68) {
		// Check if uses are exhausted
		if (usesRemaining <= 0) {
			player->sendSystemMessage("This item has no more uses remaining.");
			return 0;
		}

		// Cannot use while dead or incapacitated
		if (player->isDead() || player->isIncapacitated()) {
			player->sendSystemMessage("You must use this crystal before you die!");
			return 0;
		}

		// Check if this item already has an active observer
		if (deathObserver != nullptr || player->hasBuff(BuffCRC::JEDI_FORCE_PROTECTION_1)) {
			player->sendSystemMessage("You already have the Force resurrection protection active.");
			return 0;
		}

		// Check cooldown
		if (!player->checkCooldownRecovery("fs_buff_item_resurrect")) {
			player->sendSystemMessage("@quest/force_sensitive/utils:timer_not_up");
			return 0;
		}

		// Add visible buff icon to buff window (24 hours duration)
		// Using JEDI_FORCE_PROTECTION_1 which has client-side visuals
		Reference<Buff*> protectionBuff = new Buff(player, BuffCRC::JEDI_FORCE_PROTECTION_1, buffDuration, BuffType::JEDI);

		Locker buffLocker(protectionBuff);

		player->addBuff(protectionBuff);

		// Register death observer
		ManagedReference<FsBuffItem*> item = _this.getReferenceUnsafeStaticCast();
		Reference<FsBuffItemDeathObserver*> observer = new FsBuffItemDeathObserver(item);
		ObjectManager::instance()->persistObject(observer, 1, "observers");

		player->registerObserver(ObserverEventType::PLAYERKILLED, observer);

		// Store references
		setDeathObserver(observer);
		setActivePlayer(player);

		player->sendSystemMessage("The Force Sensitive crystal glows with power! You will be resurrected if you die within the next 24 hours.");

		// Set cooldown (but don't decrease uses yet - that happens on death)
		player->addCooldown("fs_buff_item_resurrect", reuseTime);
	}

	return 1;
}

void FsBuffItemImplementation::fillAttributeList(AttributeListMessage* alm, CreatureObject* player) {
	TangibleObjectImplementation::fillAttributeList(alm, player);

	StringBuffer cooldown;
	if (player != nullptr) {
		if (!player->checkCooldownRecovery("fs_buff_item_resurrect")) {
			const Time* timeRemaining = player->getCooldownTime("fs_buff_item_resurrect");
			cooldown << "\\#D1C870 Cooldown: \\#. " << getTimeString(timeRemaining->miliDifference() * -1);
		} else {
			cooldown << "\\#D1C870 Cooldown: \\#. Ready";
		}
		alm->insertAttribute("exam_resist_heat", cooldown);
	}

	StringBuffer uses;
	uses << "\\#D1C870 Uses Remaining: \\#. " << usesRemaining << " / " << maxUses;
	alm->insertAttribute("cat_stat_mod_bonus.@stat_n", uses);

	StringBuffer healthPool;
	healthPool << "\\#77E077 Health Pool: \\#. +2500 (Health, Strength, Constitution)";
	alm->insertAttribute("cat_attrib_mod.@attrib_health", healthPool);

	StringBuffer actionPool;
	actionPool << "\\#77E077 Action Pool: \\#. +2500 (Action, Quickness, Stamina)";
	alm->insertAttribute("cat_attrib_mod.@attrib_action", actionPool);

	StringBuffer mindPool;
	mindPool << "\\#77E077 Mind Pool: \\#. +1250 (Mind, Focus, Willpower)";
	alm->insertAttribute("cat_attrib_mod.@attrib_mind", mindPool);

	StringBuffer protection;
	protection << "\\#D1C870 Protection Duration: \\#. " << getTimeString(buffDuration * 1000);
	alm->insertAttribute("cat_skill_mod_bonus.@healing_ability", protection);

	alm->insertAttribute("cat_slot.desc", "\\#FFFF00 Use before dying for automatic resurrection \\#.");
}

uint32 FsBuffItemImplementation::getBuffCRC() {
	switch (buffAttribute) {
	case 0: return BuffCRC::MEDICAL_ENHANCE_HEALTH;
	case 1: return BuffCRC::MEDICAL_ENHANCE_STRENGTH;
	case 2: return BuffCRC::MEDICAL_ENHANCE_CONSTITUTION;
	case 3: return BuffCRC::MEDICAL_ENHANCE_ACTION;
	case 4: return BuffCRC::MEDICAL_ENHANCE_QUICKNESS;
	case 5: return BuffCRC::MEDICAL_ENHANCE_STAMINA;
	case 6: return BuffCRC::PERFORMANCE_ENHANCE_DANCE_MIND;
	case 7: return BuffCRC::PERFORMANCE_ENHANCE_MUSIC_FOCUS;
	case 8: return BuffCRC::PERFORMANCE_ENHANCE_MUSIC_WILLPOWER;
	case 9: return BuffCRC::MEDICAL_ENHANCE_POISON;
	case 10: return BuffCRC::MEDICAL_ENHANCE_DISEASE;
	default: return BuffCRC::MEDICAL_ENHANCE_HEALTH;
	}
}

void FsBuffItemImplementation::decreaseUses() {
	if (usesRemaining > 0)
		usesRemaining--;
}

CreatureObject* FsBuffItemImplementation::getActivePlayer() {
	return activePlayer.get();
}

void FsBuffItemImplementation::removeObserverFromPlayer() {
	ManagedReference<CreatureObject*> player = activePlayer.get();
	if (player != nullptr && deathObserver != nullptr) {
		player->dropObserver(ObserverEventType::PLAYERKILLED, deathObserver);
		deathObserver = nullptr;
		activePlayer = nullptr;
	}
}

void FsBuffItemImplementation::restoreObserverOnLogin(CreatureObject* player) {
	if (player == nullptr)
		return;

	// Only restore if player has the resurrection buff and this item has them as active player
	ManagedReference<CreatureObject*> savedPlayer = activePlayer.get();
	if (savedPlayer == nullptr || savedPlayer != player)
		return;

	if (!player->hasBuff(BuffCRC::JEDI_FORCE_PROTECTION_1))
		return;

	// Observer was lost on restart, re-register it
	if (deathObserver == nullptr) {
		ManagedReference<FsBuffItem*> item = _this.getReferenceUnsafeStaticCast();
		Reference<FsBuffItemDeathObserver*> observer = new FsBuffItemDeathObserver(item);
		ObjectManager::instance()->persistObject(observer, 1, "observers");

		player->registerObserver(ObserverEventType::PLAYERKILLED, observer);
		setDeathObserver(observer);

		player->sendSystemMessage("Force Resurrection protection restored.");
	}
}

String FsBuffItemImplementation::getTimeString(uint32 timestamp) {
	int seconds = timestamp / 1000;

	int hours = seconds / 3600;
	seconds -= hours * 3600;

	int minutes = seconds / 60;
	seconds -= minutes * 60;

	StringBuffer buffer;

	if (hours > 0)
		buffer << hours << "h ";

	if (minutes > 0)
		buffer << minutes << "m ";

	if (seconds > 0)
		buffer << seconds << "s";

	return buffer.toString();
}
