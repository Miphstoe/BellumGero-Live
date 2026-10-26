#include "ImageDesignStationDeedMenuComponent.h"
#include "ImageDesignStationMenuComponent.h"
#include "ImageDesignStationDataComponent.h"

#include "server/zone/ZoneServer.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/cell/CellObject.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "server/zone/objects/tangible/TangibleObject.h"
#include "server/zone/objects/tangible/deed/Deed.h"
#include "server/zone/objects/transaction/TransactionLog.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/managers/radial/RadialOptions.h"

namespace {
const String kMasterImageDesignerSkill = "social_imagedesigner_master";
}

void ImageDesignStationDeedMenuComponent::fillObjectMenuResponse(
	SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {

	TangibleObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);

	if (sceneObject != nullptr && player != nullptr && sceneObject->isASubChildOf(player))
		menuResponse->addRadialMenuItem(
			RadialOptions::SERVER_MENU1, 3, "Deploy Image Designer Station");
}

int ImageDesignStationDeedMenuComponent::handleObjectMenuSelect(
	SceneObject* sceneObject, CreatureObject* player, byte selectedID) const {

	if (selectedID != RadialOptions::SERVER_MENU1)
		return TangibleObjectMenuComponent::handleObjectMenuSelect(sceneObject, player, selectedID);

	if (sceneObject == nullptr || player == nullptr || !player->isPlayerCreature())
		return 0;

	ManagedReference<Deed*> deed =
		sceneObject->isDeedObject() ? cast<Deed*>(sceneObject) : nullptr;

	if (deed == nullptr)
		return 0;

	if (!sceneObject->isASubChildOf(player)) {
		player->sendSystemMessage("The Image Designer Station deed must be in your inventory.");
		return 0;
	}

	// FMIDStation grants temporary Image Designer skill boxes while a customer
	// is using a station so the stock client UI can function. Those temporary
	// boxes must never satisfy the permanent Master Image Designer requirement
	// for deploying another station.
	if (!player->getLuaStringData(
			"fmidstation_temp_id_skills").isEmpty()) {
		player->sendSystemMessage(
			"You cannot deploy an Image Designer Station while an "
			"Image Designer Station session is active.");
		return 0;
	}

	if (!player->hasSkill(kMasterImageDesignerSkill)) {
		player->sendSystemMessage("You must be a Master Image Designer to deploy an Image Designer Station.");
		return 0;
	}

	if (player->isInCombat()) {
		player->sendSystemMessage("You cannot deploy an Image Designer Station while in combat.");
		return 0;
	}

	ManagedReference<SceneObject*> parent = player->getParent().get();
	if (parent == nullptr || !parent->isCellObject()) {
		player->sendSystemMessage("Image Designer Stations may only be deployed inside a structure.");
		return 0;
	}

	ManagedReference<CellObject*> cell = cast<CellObject*>(parent.get());
	ManagedReference<SceneObject*> root = parent->getRootParent();
	ManagedReference<BuildingObject*> building =
		(root != nullptr && root->isBuildingObject()) ? cast<BuildingObject*>(root.get()) : nullptr;

	if (cell == nullptr || building == nullptr) {
		player->sendSystemMessage("Image Designer Stations may only be deployed inside a valid structure.");
		return 0;
	}

	PlayerObject* ghost = player->getPlayerObject();
	bool privileged = ghost != nullptr && ghost->isPrivileged();

	if (!privileged && !building->isOnAdminList(player)) {
		player->sendSystemMessage(
			"You must be on this structure's admin list to deploy an Image Designer Station.");
		return 0;
	}

	if ((building->getCurrentNumberOfPlayerItems() + 1) > building->getMaximumNumberOfPlayerItems()) {
		player->sendSystemMessage("@container_error_message:container13");
		return 0;
	}

	ZoneServer* zoneServer = player->getZoneServer();
	if (zoneServer == nullptr)
		return 0;

	String stationTemplate = deed->getGeneratedObjectTemplate();
	if (stationTemplate.isEmpty()) {
		player->sendSystemMessage("This Image Designer Station deed is misconfigured.");
		return 0;
	}

	Locker playerLocker(player);

	ManagedReference<SceneObject*> stationScene =
		zoneServer->createObject(stationTemplate.hashCode(), 2);
	ManagedReference<TangibleObject*> station =
		(stationScene != nullptr && stationScene->isTangibleObject()) ?
			cast<TangibleObject*>(stationScene.get()) : nullptr;

	if (station == nullptr || !ImageDesignStationMenuComponent::isImageDesignStation(station)) {
		if (stationScene != nullptr) {
			Locker cleanupLocker(stationScene, player);
			stationScene->destroyObjectFromDatabase(true);
		}
		player->sendSystemMessage("The Image Designer Station could not be created.");
		return 0;
	}

	Locker buildingLocker(building, player);
	Locker stationLocker(station, building);

	if (building->getHousePackState() != 0) {
		station->destroyObjectFromDatabase(true);
		player->sendSystemMessage(
			"This structure is currently being packed or otherwise changed. "
			"The Image Designer Station was not deployed and the deed was not consumed.");
		return 0;
	}

	ManagedReference<SceneObject*> currentPlayerParent = player->getParent().get();
	ManagedReference<SceneObject*> currentCellRoot = cell->getRootParent();

	bool placementStillValid =
		building->getZone() != nullptr &&
		currentPlayerParent != nullptr &&
		currentPlayerParent->getObjectID() == cell->getObjectID() &&
		currentCellRoot != nullptr &&
		currentCellRoot->getObjectID() == building->getObjectID() &&
		(privileged || building->isOnAdminList(player));

	if (!placementStillValid) {
		station->destroyObjectFromDatabase(true);
		player->sendSystemMessage(
			"The structure changed while the station was being deployed. "
			"Placement was cancelled safely and the deed was not consumed.");
		return 0;
	}

	if ((building->getCurrentNumberOfPlayerItems() + 1) > building->getMaximumNumberOfPlayerItems()) {
		station->destroyObjectFromDatabase(true);
		player->sendSystemMessage("@container_error_message:container13");
		return 0;
	}

	ImageDesignStationDataComponent* data = ImageDesignStationMenuComponent::getStationData(station);
	if (data == nullptr) {
		station->destroyObjectFromDatabase(true);
		player->sendSystemMessage("The Image Designer Station has an invalid data component.");
		return 0;
	}

	data->setOwnerId(player->getObjectID());
	data->setOwnerGuildId(player->getGuildID());
	data->snapshotSkills(player);
	data->setServicePrice(10000);

	station->initializePosition(
		player->getPositionX(), player->getPositionZ(), player->getPositionY());
	station->setDirection(Math::deg2rad(player->getDirectionAngle()));

	station->setLuaStringData("item_secured", String::valueOf(building->getObjectID()));
	station->addMagicBit(true);

	String placementError;
	if (cell->canAddObject(station, -1, placementError) != 0) {
		if (placementError.isEmpty())
			player->sendSystemMessage("The Image Designer Station cannot be placed here.");
		else
			player->sendSystemMessage(placementError);

		station->destroyObjectFromWorld(true);
		station->destroyObjectFromDatabase(true);
		return 0;
	}

	if (!cell->transferObject(station, -1, true, false)) {
		player->sendSystemMessage("The Image Designer Station could not be placed here.");
		station->destroyObjectFromWorld(true);
		station->destroyObjectFromDatabase(true);
		return 0;
	}

	station->updateToDatabase();

	stationLocker.release();
	buildingLocker.release();

	TransactionLog trx(player, station, deed, TrxCode::PLAYERMISCACTION);
	trx.addState("feature", String("FMIDStation"));
	trx.addState("buildingId", (uint64)building->getObjectID());
	trx.addState("cellId", (uint64)cell->getObjectID());
	trx.commit();

	station->info(true)
		<< "FMIDStation PLACE owner=" << player->getObjectID()
		<< " station=" << station->getObjectID()
		<< " building=" << building->getObjectID()
		<< " cell=" << cell->getObjectID();

	Locker deedLocker(deed, player);
	deed->destroyObjectFromWorld(true);
	deed->destroyObjectFromDatabase(true);

	player->sendSystemMessage(
		"Image Designer Station deployed. It is secured to this building and will remain when you log out.");

	return 0;
}
