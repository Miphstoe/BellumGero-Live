/*
 * DoctorServiceUnitDeedMenuComponent.cpp
 *
 * Bellum Gero - FMDoctorBot
 *
 * Safety-first stationary deployment. There is deliberately no VehicleDeed,
 * VehicleControlDevice, datapad control device, spawn/store lifecycle, or logout cleanup.
 */

#include "DoctorServiceUnitDeedMenuComponent.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/cell/CellObject.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "server/zone/objects/tangible/TangibleObject.h"
#include "server/zone/objects/tangible/deed/Deed.h"
#include "server/zone/objects/tangible/components/DoctorBuffDroidMenuComponent.h"
#include "server/zone/objects/tangible/components/DoctorBuffDroidDataComponent.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/managers/radial/RadialOptions.h"
#include "server/zone/objects/transaction/TransactionLog.h"
#include "templates/SharedObjectTemplate.h"

namespace {
const String kDoctorSkill = "science_doctor_master";
const String kHopperTemplate = "object/tangible/hopper/doctor_service_supply_hopper.iff";

bool isApprovedDoctorServiceVenue(SceneObject* root) {
	if (root == nullptr || !root->isBuildingObject() || root->getObjectTemplate() == nullptr)
		return false;

	String path = root->getObjectTemplate()->getFullTemplateString();

	// Phase 1 is intentionally limited to player-city Hospitals and Cantinas.
	if (!path.contains("object/building/player/city/"))
		return false;

	return path.contains("/hospital_") || path.contains("/cantina_");
}
}

void DoctorServiceUnitDeedMenuComponent::fillObjectMenuResponse(
	SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {

	TangibleObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);

	if (sceneObject == nullptr || player == nullptr)
		return;

	if (sceneObject->isASubChildOf(player))
		menuResponse->addRadialMenuItem(RadialOptions::SERVER_MENU1, 3, "Deploy Automated Medical Station");
}

int DoctorServiceUnitDeedMenuComponent::handleObjectMenuSelect(
	SceneObject* sceneObject, CreatureObject* player, byte selectedID) const {

	if (selectedID != RadialOptions::SERVER_MENU1)
		return TangibleObjectMenuComponent::handleObjectMenuSelect(sceneObject, player, selectedID);

	if (sceneObject == nullptr || player == nullptr || !player->isPlayerCreature())
		return 0;

	ManagedReference<Deed*> deed = sceneObject->isDeedObject() ? cast<Deed*>(sceneObject) : nullptr;
	if (deed == nullptr)
		return 0;

	if (!sceneObject->isASubChildOf(player)) {
		player->sendSystemMessage("The Automated Medical Station deed must be in your inventory.");
		return 0;
	}

	if (!player->hasSkill(kDoctorSkill)) {
		player->sendSystemMessage("You must be a Master Doctor to deploy an Automated Medical Station.");
		return 0;
	}

	if (player->isInCombat()) {
		player->sendSystemMessage("You cannot deploy an Automated Medical Station while in combat.");
		return 0;
	}

	ManagedReference<SceneObject*> parent = player->getParent().get();
	if (parent == nullptr || !parent->isCellObject()) {
		player->sendSystemMessage("Automated Medical Stations may only be deployed inside an approved player-city Hospital or Cantina.");
		return 0;
	}

	ManagedReference<CellObject*> cell = cast<CellObject*>(parent.get());
	ManagedReference<SceneObject*> root = parent->getRootParent();
	ManagedReference<BuildingObject*> building =
		(root != nullptr && root->isBuildingObject()) ? cast<BuildingObject*>(root.get()) : nullptr;

	if (cell == nullptr || building == nullptr || !isApprovedDoctorServiceVenue(building)) {
		player->sendSystemMessage("Automated Medical Stations may only be deployed inside a player-city Hospital or Cantina.");
		return 0;
	}

	PlayerObject* ghost = player->getPlayerObject();
	bool privileged = ghost != nullptr && ghost->isPrivileged();

	if (!privileged && !building->isOnAdminList(player)) {
		player->sendSystemMessage("You must be on this Hospital/Cantina's admin list to deploy an Automated Medical Station.");
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
		player->sendSystemMessage("This Automated Medical Station deed is misconfigured.");
		return 0;
	}

	Locker playerLocker(player);

	ManagedReference<SceneObject*> stationScene = zoneServer->createObject(stationTemplate.hashCode(), 2);
	ManagedReference<TangibleObject*> station =
		(stationScene != nullptr && stationScene->isTangibleObject()) ? cast<TangibleObject*>(stationScene.get()) : nullptr;

	if (station == nullptr || !DoctorBuffDroidMenuComponent::isDoctorServiceUnit(station)) {
		if (stationScene != nullptr) {
			Locker cleanupLocker(stationScene, player);
			stationScene->destroyObjectFromDatabase(true);
		}

		player->sendSystemMessage("The Automated Medical Station could not be created.");
		return 0;
	}

	// FMDoctorBot final placement gate.
	Locker buildingLocker(building, player);
	Locker stationLocker(station, building);

	if (building->getHousePackState() != 0) {
		station->destroyObjectFromDatabase(true);
		player->sendSystemMessage(
			"This structure is currently being packed or otherwise changed. "
			"The Automated Medical Station was not deployed and the deed was not consumed.");
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
		isApprovedDoctorServiceVenue(building) &&
		(privileged || building->isOnAdminList(player));

	if (!placementStillValid) {
		station->destroyObjectFromDatabase(true);
		player->sendSystemMessage(
			"The Hospital/Cantina changed while the station was being deployed. "
			"Placement was cancelled safely and the deed was not consumed.");
		return 0;
	}

	if ((building->getCurrentNumberOfPlayerItems() + 1) >
			building->getMaximumNumberOfPlayerItems()) {
		station->destroyObjectFromDatabase(true);
		player->sendSystemMessage("@container_error_message:container13");
		return 0;
	}

	DoctorBuffDroidDataComponent* data = DoctorBuffDroidMenuComponent::getDroidData(station);
	if (data == nullptr) {
		station->destroyObjectFromDatabase(true);
		player->sendSystemMessage("The Automated Medical Station has an invalid data component.");
		return 0;
	}

	data->setOwnerId(player->getObjectID());
	DoctorBuffDroidMenuComponent::refreshOwnerHealingMod(station, player, data);

	station->initializePosition(player->getPositionX(), player->getPositionZ(), player->getPositionY());
	station->setDirection(Math::deg2rad(player->getDirectionAngle()));

	// Core3's existing secured-item mechanism prevents any normal/direct transfer
	// from removing this object from the building. Decommission is the only supported exit.
	station->setLuaStringData("item_secured", String::valueOf(building->getObjectID()));
	station->addMagicBit(true);

	String placementError;
	if (cell->canAddObject(station, -1, placementError) != 0) {
		if (placementError.isEmpty())
			player->sendSystemMessage("The Automated Medical Station cannot be placed here.");
		else
			player->sendSystemMessage(placementError);

		station->destroyObjectFromWorld(true);
		station->destroyObjectFromDatabase(true);
		return 0;
	}

	if (!cell->transferObject(station, -1, true, false)) {
		player->sendSystemMessage("The Automated Medical Station could not be placed here.");
		station->destroyObjectFromWorld(true);
		station->destroyObjectFromDatabase(true);
		return 0;
	}

	ManagedReference<SceneObject*> hopper = zoneServer->createObject(kHopperTemplate.hashCode(), 2);
	if (hopper == nullptr) {
		player->sendSystemMessage("Medical Supply Hopper creation failed. The station placement was rolled back.");
		station->destroyObjectFromWorld(true);
		station->destroyObjectFromDatabase(true);
		return 0;
	}

	Locker hopperLocker(hopper, station);

	String hopperError;
	if (station->canAddObject(hopper, -1, hopperError) != 0 ||
			!station->transferObject(hopper, -1, true)) {

		if (hopper->getParentID() != station->getObjectID())
			hopper->destroyObjectFromDatabase(true);

		player->sendSystemMessage("Medical Supply Hopper attachment failed. The station placement was rolled back.");
		station->destroyObjectFromWorld(true);
		station->destroyObjectFromDatabase(true);
		return 0;
	}

	station->updateToDatabase();
	hopper->updateToDatabase();

	hopperLocker.release();
	stationLocker.release();
	buildingLocker.release();

	// FMDoctorBot fresh-deploy hopper client sync.
	//
	// transferObject(..., notifyClient=true) only sends the containment link.
	// Because this hopper was created AFTER the station was already sent to the
	// deploying client, the client does not yet know the hopper object/baselines.
	// Send the newly-created child explicitly to the owner so Open Container works
	// immediately without requiring logout/login.
	hopper->sendTo(player, true, true);

	TransactionLog trx(player, station, deed, TrxCode::PLAYERMISCACTION);
	trx.addState("feature", String("FMDoctorBot"));
	trx.addState("buildingId", (uint64)building->getObjectID());
	trx.addState("cellId", (uint64)cell->getObjectID());
	trx.addState("hopperId", (uint64)hopper->getObjectID());
	trx.commit();

	station->info(true)
		<< "FMDoctorBot PLACE owner=" << player->getObjectID()
		<< " station=" << station->getObjectID()
		<< " hopper=" << hopper->getObjectID()
		<< " building=" << building->getObjectID()
		<< " cell=" << cell->getObjectID();

	Locker deedLocker(deed, player);
	deed->destroyObjectFromWorld(true);
	deed->destroyObjectFromDatabase(true);

	player->sendSystemMessage(
		"Automated Medical Station deployed. It is secured to this building and will remain when you log out.");

	return 0;
}
