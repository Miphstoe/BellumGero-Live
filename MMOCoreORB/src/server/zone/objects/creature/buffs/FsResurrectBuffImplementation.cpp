/*
 * FsResurrectBuffImplementation.cpp
 */

#include "server/zone/objects/creature/buffs/FsResurrectBuff.h"
#include "server/zone/objects/creature/buffs/FsResurrectBuffObserver.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/managers/object/ObjectManager.h"
#include "templates/params/ObserverEventType.h"

void FsResurrectBuffImplementation::activate() {
	BuffImplementation::activate();

	if (player != nullptr) {
		player->sendSystemMessage("DEBUG: FsResurrectBuff activate() called!");
	}

	addObservers();
}

void FsResurrectBuffImplementation::deactivate() {
	BuffImplementation::deactivate();
	dropObservers();
}

void FsResurrectBuffImplementation::addObservers() {
	if (player == nullptr)
		return;

	observer = new FsResurrectBuffObserver(_this.getReferenceUnsafeStaticCast());
	ObjectManager::instance()->persistObject(observer, 1, "buffs");
	player->registerObserver(ObserverEventType::PLAYERKILLED, observer);

	player->sendSystemMessage("DEBUG: Observer registered for PLAYERKILLED event!");
}

void FsResurrectBuffImplementation::dropObservers() {
	if (player != nullptr && observer != nullptr) {
		player->dropObserver(ObserverEventType::PLAYERKILLED, observer);
	}
}
