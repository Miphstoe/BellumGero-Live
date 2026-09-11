/*
 * MannequinDeedMenuComponent.cpp
 *
 * Bellum Gero - Persistent Player Display Mannequin (Phase 2 PoC)
 */

#include "MannequinDeedMenuComponent.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/scene/SceneObjectType.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/creature/ai/mannequin/MannequinObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/cell/CellObject.h"
#include "server/zone/objects/structure/StructureObject.h"
#include "server/zone/objects/tangible/deed/Deed.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/managers/radial/RadialOptions.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/objects/transaction/TransactionLog.h"

void MannequinDeedMenuComponent::fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
	TangibleObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);

	if (sceneObject == nullptr || player == nullptr)
		return;

	if (sceneObject->isASubChildOf(player))
		menuResponse->addRadialMenuItem(RadialOptions::SERVER_MENU1, 3, "Deploy Mannequin");
}

int MannequinDeedMenuComponent::handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const {
	if (selectedID != RadialOptions::SERVER_MENU1)
		return TangibleObjectMenuComponent::handleObjectMenuSelect(sceneObject, player, selectedID);

	if (sceneObject == nullptr || player == nullptr || !player->isPlayerCreature())
		return 0;

	ManagedReference<Deed*> deed = sceneObject->isDeedObject() ? cast<Deed*>(sceneObject) : nullptr;

	if (deed == nullptr)
		return 0;

	if (!sceneObject->isASubChildOf(player)) {
		player->sendSystemMessage("The deed must be in your inventory to be deployed.");
		return 0;
	}

	if (player->isInCombat()) {
		player->sendSystemMessage("You cannot deploy a mannequin while in combat.");
		return 0;
	}

	ManagedReference<SceneObject*> parent = player->getParent().get();

	if (parent == nullptr || !parent->isCellObject()) {
		player->sendSystemMessage("A mannequin can only be deployed inside a player structure.");
		return 0;
	}

	ManagedReference<CellObject*> cell = cast<CellObject*>(parent.get());
	ManagedReference<StructureObject*> structure = cast<StructureObject*>(parent->getRootParent());

	if (cell == nullptr || structure == nullptr) {
		player->sendSystemMessage("A mannequin can only be deployed inside a player structure.");
		return 0;
	}

	auto ghost = player->getPlayerObject();
	bool privileged = ghost != nullptr && ghost->isPrivileged();

	if (!privileged && !structure->isOnAdminList(player)) {
		player->sendSystemMessage("You must be on this structure's admin list to deploy a mannequin here.");
		return 0;
	}

	auto zoneServer = player->getZoneServer();

	if (zoneServer == nullptr)
		return 0;

	String mannequinTemplate = deed->getGeneratedObjectTemplate();

	if (mannequinTemplate.isEmpty()) {
		player->sendSystemMessage("This deed is misconfigured (no mannequin template).");
		return 0;
	}

	Locker plocker(player);

	ManagedReference<SceneObject*> mannequinScene = zoneServer->createObject(mannequinTemplate.hashCode(), 2);

	if (mannequinScene == nullptr || !mannequinScene->isMannequinObject()) {
		player->sendSystemMessage("The mannequin could not be created.");

		if (mannequinScene != nullptr) {
			Locker mlock(mannequinScene, player);
			mannequinScene->destroyObjectFromDatabase(true);
		}

		return 0;
	}

	ManagedReference<MannequinObject*> mannequin = cast<MannequinObject*>(mannequinScene.get());

	Locker mlocker(mannequin, player);

	mannequin->setMannequinOwnerID(player->getObjectID());
	mannequin->initializePosition(player->getPositionX(), player->getPositionZ(), player->getPositionY());
	mannequin->setDirection(Math::deg2rad(player->getDirectionAngle()));

	if (!cell->transferObject(mannequin, -1, true)) {
		player->sendSystemMessage("The mannequin could not be placed here.");
		mannequin->destroyObjectFromWorld(true);
		mannequin->destroyObjectFromDatabase(true);
		return 0;
	}

	mannequin->createChildObjects();
	cell->broadcastObject(mannequin, true);

	TransactionLog trx(player, mannequin, deed, TrxCode::PLAYERMISCACTION);
	trx.commit();

	mannequin->info(true) << "PLACE player=" << player->getObjectID() << " mannequin=" << mannequin->getObjectID()
		<< " structure=" << structure->getObjectID() << " template=" << mannequinTemplate;

	Locker dlocker(deed, player);
	deed->destroyObjectFromWorld(true);
	deed->destroyObjectFromDatabase(true);

	player->sendSystemMessage("Mannequin deployed.");

	return 0;
}
