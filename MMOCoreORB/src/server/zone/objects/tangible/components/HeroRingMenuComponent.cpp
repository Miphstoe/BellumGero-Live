#include "HeroRingMenuComponent.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "templates/params/creature/CreatureAttribute.h"
#include "server/zone/objects/tangible/wearables/WearableObject.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/objects/tangible/components/HeroRingDataComponent.h"
#include "server/zone/packets/object/PlayClientEffectObjectMessage.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/SuiWindowType.h"

WearableObject* HeroRingMenuComponent::getEquippedHeroRing(CreatureObject* player) {
	if (player == nullptr)
		return nullptr;

	SceneObject* rightRing = player->getSlottedObject("ring_r");
	WearableObject* wearable = cast<WearableObject*>(rightRing);

	if (wearable != nullptr) {
		HeroRingDataComponent* data = cast<HeroRingDataComponent*>(wearable->getDataObjectComponent()->get());

		if (data != nullptr && data->isHeroRingData())
			return wearable;
	}

	SceneObject* leftRing = player->getSlottedObject("ring_l");
	wearable = cast<WearableObject*>(leftRing);

	if (wearable != nullptr) {
		HeroRingDataComponent* data = cast<HeroRingDataComponent*>(wearable->getDataObjectComponent()->get());

		if (data != nullptr && data->isHeroRingData())
			return wearable;
	}

	return nullptr;
}

bool HeroRingMenuComponent::canActivateHeroRing(CreatureObject* player, WearableObject* wearable, bool sendMessages) {
	if (player == nullptr || wearable == nullptr)
		return false;

	if (!wearable->isASubChildOf(player))
		return false;

	HeroRingDataComponent* data = cast<HeroRingDataComponent*>(wearable->getDataObjectComponent()->get());

	if (data == nullptr || !data->isHeroRingData())
		return false;

	if (data->getCharges() <= 0)
		return false;

	if (!wearable->isEquipped()) {
		if (sendMessages)
			player->sendSystemMessage("@quest/hero_of_tatooine/system_messages:restore_not_equipped");

		return false;
	}

	if (!player->isDead()) {
		if (sendMessages)
			player->sendSystemMessage("@quest/hero_of_tatooine/system_messages:restore_not_dead");

		return false;
	}

	if (!player->checkCooldownRecovery("mark_of_hero")) {
		if (sendMessages) {
			const Time* timeRemaining = player->getCooldownTime("mark_of_hero");
			StringIdChatParameter cooldown("quest/hero_of_tatooine/system_messages", "restore_not_yet");
			cooldown.setTO(getCooldownString(timeRemaining->miliDifference() * -1));
			player->sendSystemMessage(cooldown);
		}

		return false;
	}

	return true;
}

bool HeroRingMenuComponent::activateHeroRing(CreatureObject* player, WearableObject* wearable, bool sendMessages) {
	if (!canActivateHeroRing(player, wearable, sendMessages))
		return false;

	HeroRingDataComponent* data = cast<HeroRingDataComponent*>(wearable->getDataObjectComponent()->get());

	if (data == nullptr || !data->isHeroRingData())
		return false;

	player->healDamage(player, CreatureAttribute::HEALTH, 200);
	player->healDamage(player, CreatureAttribute::ACTION, 200);
	player->healDamage(player, CreatureAttribute::MIND, 200);

	player->removeFeignedDeath();

	data->setCharges(data->getCharges() - 1);

	ManagedReference<PlayerObject*> ghost = player->getPlayerObject();

	if (ghost != nullptr)
		ghost->removeSuiBoxType(SuiWindowType::CLONE_REQUEST);

	String hardpoint = "";

	if (player->getSlottedObject("ring_r") != nullptr && player->getSlottedObject("ring_r")->getObjectID() == wearable->getObjectID())
		hardpoint = "hold_r";
	else if (player->getSlottedObject("ring_l") != nullptr && player->getSlottedObject("ring_l")->getObjectID() == wearable->getObjectID())
		hardpoint = "hold_l";

	PlayClientEffectObjectMessage* effect = new PlayClientEffectObjectMessage(player, "clienteffect/item_ring_hero_mark.cef", hardpoint);
	player->broadcastMessage(effect, false);

	player->sendSystemMessage("@quest/hero_of_tatooine/system_messages:restore_msg");
	player->addCooldown("mark_of_hero", 23 * 3600 * 1000); // 23 hours

	return true;
}

void HeroRingMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {

	TangibleObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);

	TangibleObject* ring = cast<TangibleObject*>(sceneObject);

	if (ring == nullptr)
		return;

	HeroRingDataComponent* data = cast<HeroRingDataComponent*>(ring->getDataObjectComponent()->get());

	if (data == nullptr || !data->isHeroRingData())
		return;

	if (data->getCharges() > 0)
		menuResponse->addRadialMenuItem(20, 3, "@quest/hero_of_tatooine/system_messages:menu_restore"); // Restore Life

}

int HeroRingMenuComponent::handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const {

	if (selectedID == 20) { // Restore Life

		WearableObject* wearable = cast<WearableObject*>(sceneObject);

		activateHeroRing(player, wearable, true);
		return 0;
	} else {
		return TangibleObjectMenuComponent::handleObjectMenuSelect(sceneObject, player, selectedID);
	}

}

String HeroRingMenuComponent::getCooldownString(uint32 delta) {

	int seconds = delta / 1000;

	int hours = seconds / 3600;
	seconds -= hours * 3600;

	int minutes = seconds / 60;
	seconds -= minutes * 60;

	StringBuffer buffer;

	if (hours > 0) {
		buffer << hours << " hour";

		if (hours > 1)
			buffer << "s";

		if (minutes > 0 || seconds > 0)
			buffer << ", ";
	}

	if (minutes > 0) {
		buffer << minutes << " minute";

		if (minutes > 1)
			buffer << "s";

		if (seconds > 0)
			buffer << ", ";
	}

	if (seconds > 0) {
		buffer << seconds << " second";

		if (seconds > 1)
			buffer << "s";
	}

	return buffer.toString();
}
