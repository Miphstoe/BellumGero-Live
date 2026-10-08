#include "ImageDesignStationMenuComponent.h"
#include "ImageDesignStationDataComponent.h"

#include "server/zone/ZoneServer.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/scene/components/DataObjectComponentReference.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sessions/ImageDesignStationSession.h"
#include "server/zone/objects/player/sessions/MigrateStatsSession.h"
#include "server/zone/objects/player/sessions/ImageDesignStationStatMigrationObserver.h"
#include "server/zone/objects/player/events/ImageDesignStationStatMigrationTimeoutTask.h"
#include "server/zone/objects/tangible/TangibleObject.h"
#include "server/zone/objects/transaction/TransactionLog.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/managers/credit/CreditManager.h"
#include "server/zone/objects/creature/credits/CreditObject.h"
#include "system/lang/Time.h"

namespace {
const String kMasterImageDesignerSkill = "social_imagedesigner_master";
const String kStationTemplate = "object/tangible/terminal/image_design_station.iff";
const String kStationDeedTemplate = "object/tangible/deed/image_design_station_deed.iff";
const float kUseRange = 10.0f;
}

bool ImageDesignStationMenuComponent::isImageDesignStation(SceneObject* object) {
	return object != nullptr &&
		object->getServerObjectCRC() == kStationTemplate.hashCode();
}

ImageDesignStationDataComponent*
ImageDesignStationMenuComponent::getStationData(SceneObject* object) {
	if (object == nullptr)
		return nullptr;

	DataObjectComponentReference* dataRef =
		object->getDataObjectComponent();

	if (dataRef == nullptr || dataRef->get() == nullptr)
		return nullptr;

	return dynamic_cast<ImageDesignStationDataComponent*>(
		dataRef->get());
}

bool ImageDesignStationMenuComponent::isPlayerWithinUseRange(
	SceneObject* station, CreatureObject* player, bool notify) {

	if (station == nullptr || player == nullptr)
		return false;

	bool valid =
		player->getZone() != nullptr &&
		station->getZone() == player->getZone() &&
		player->getParentID() == station->getParentID() &&
		station->getDistanceTo(player) <= kUseRange;

	if (!valid && notify)
		player->sendSystemMessage(
			"You must remain in the same room and within 10 meters "
			"of the Image Designer Station to use it.");

	return valid;
}

bool ImageDesignStationMenuComponent::isPlacementValid(
	SceneObject* station, String* reason) {

	if (reason != nullptr)
		*reason = "";

	if (!isImageDesignStation(station)) {
		if (reason != nullptr)
			*reason = "Object is not an Image Designer Station.";
		return false;
	}

	SceneObject* parent = station->getParent().get();

	if (parent == nullptr || !parent->isCellObject()) {
		if (reason != nullptr)
			*reason = "Station is not inside a valid structure cell.";
		return false;
	}

	SceneObject* root = parent->getRootParent();

	if (root == nullptr ||
			!root->isBuildingObject() ||
			root->getZone() == nullptr) {
		if (reason != nullptr)
			*reason = "Station structure is unavailable.";
		return false;
	}

	TangibleObject* tangibleStation =
		station->isTangibleObject() ?
			cast<TangibleObject*>(station) :
			nullptr;

	if (tangibleStation == nullptr) {
		if (reason != nullptr)
			*reason = "Station is not a valid tangible object.";
		return false;
	}

	String securedTo =
		tangibleStation->getLuaStringData("item_secured");

	if (securedTo != String::valueOf(root->getObjectID())) {
		if (reason != nullptr)
			*reason = "Station security binding is invalid.";
		return false;
	}

	if (getStationData(station) == nullptr) {
		if (reason != nullptr)
			*reason = "Station data component is missing.";
		return false;
	}

	return true;
}

void ImageDesignStationMenuComponent::fillObjectMenuResponse(
	SceneObject* sceneObject,
	ObjectMenuResponse* menuResponse,
	CreatureObject* player) const {

	if (sceneObject == nullptr ||
			menuResponse == nullptr ||
			player == nullptr)
		return;

	ImageDesignStationDataComponent* data =
		getStationData(sceneObject);

	if (data == nullptr)
		return;

	menuResponse->addRadialMenuItem(
		MENU_ROOT, 3, "Image Designer Station");

	menuResponse->addRadialMenuItemToRadialID(
		MENU_ROOT, MENU_USE, 3,
		"Use Image Designer (10,000 credits)");

	menuResponse->addRadialMenuItemToRadialID(
		MENU_ROOT, MENU_STAT_MIGRATION, 3,
		"Stat Migration");

	if (player->getLuaStringData(
			"fmidstation_stat_migration_station_id") ==
			String::valueOf(sceneObject->getObjectID()) &&
			player->getLuaStringData(
				"fmidstation_stat_migration_ready") == "1" &&
			!player->getLuaStringData(
				"fmidstation_stat_migration_token").isEmpty()) {
		menuResponse->addRadialMenuItemToRadialID(
			MENU_ROOT, MENU_APPLY_STAT_MIGRATION, 3,
			"Apply Stat Migration (10,000 credits)");
	}

	menuResponse->addRadialMenuItemToRadialID(
		MENU_ROOT, MENU_STATUS, 3,
		"Station Status");

	if (data->isOwner(player)) {
		// Preserve secured/no-pickup behavior while allowing the owner
		// to reposition the station inside its current structure cell.
		menuResponse->addRadialMenuItem(
			54, 1, "@ui_radial:item_move");
		menuResponse->addRadialMenuItemToRadialID(
			54, 55, 3, "@ui_radial:item_move_forward");
		menuResponse->addRadialMenuItemToRadialID(
			54, 56, 3, "@ui_radial:item_move_back");
		menuResponse->addRadialMenuItemToRadialID(
			54, 57, 3, "@ui_radial:item_move_up");
		menuResponse->addRadialMenuItemToRadialID(
			54, 58, 3, "@ui_radial:item_move_down");

		menuResponse->addRadialMenuItem(
			51, 1, "@ui_radial:item_rotate");
		menuResponse->addRadialMenuItemToRadialID(
			51, 52, 3, "@ui_radial:item_rotate_left");
		menuResponse->addRadialMenuItemToRadialID(
			51, 53, 3, "@ui_radial:item_rotate_right");

		menuResponse->addRadialMenuItemToRadialID(
			MENU_ROOT, MENU_REFRESH, 3,
			"Refresh Stored Image Designer Skills");

		menuResponse->addRadialMenuItemToRadialID(
			MENU_ROOT, MENU_DECOMMISSION, 3,
			"Decommission Station");
	}
}

int ImageDesignStationMenuComponent::handleObjectMenuSelect(
	SceneObject* sceneObject,
	CreatureObject* player,
	byte selectedID) const {

	if (sceneObject == nullptr || player == nullptr)
		return 0;

	if (!isPlayerWithinUseRange(sceneObject, player))
		return 0;

	switch (selectedID) {
	case MENU_ROOT:
		return 0;
	case MENU_USE:
		startImageDesign(sceneObject, player);
		return 0;
	case MENU_STAT_MIGRATION:
		startStatMigration(sceneObject, player);
		return 0;
	case MENU_APPLY_STAT_MIGRATION:
		applyStatMigration(sceneObject, player);
		return 0;
	case MENU_STATUS:
		sendStatus(sceneObject, player);
		return 0;
	case MENU_REFRESH:
		refreshOwnerSkills(sceneObject, player);
		return 0;
	case MENU_DECOMMISSION:
		decommission(sceneObject, player);
		return 0;
	default:
		// Stock Move/Rotate radials are handled by the base object menu path.
		// Pick Up / Secure / Unsecure remain suppressed because we never expose
		// those radials from this station component.
		return ObjectMenuComponent::handleObjectMenuSelect(
			sceneObject, player, selectedID);
	}
}

void ImageDesignStationMenuComponent::startImageDesign(
	SceneObject* station,
	CreatureObject* player) {

	if (station == nullptr ||
			player == nullptr ||
			!player->isPlayerCreature())
		return;

	String reason;

	if (!isPlacementValid(station, &reason)) {
		player->sendSystemMessage(
			"Image Designer Station is safety locked: " + reason);
		return;
	}

	if (!isPlayerWithinUseRange(station, player))
		return;

	if (player->isDead()) {
		player->sendSystemMessage(
			"You cannot use the Image Designer Station while dead.");
		return;
	}

	if (player->isInvisible()) {
		player->sendSystemMessage(
			"You cannot use the Image Designer Station while invisible.");
		return;
	}

	if (player->isInCombat()) {
		player->sendSystemMessage(
			"You cannot use the Image Designer Station while in combat.");
		return;
	}

	if (player->containsActiveSession(SessionFacadeType::IMAGEDESIGN)) {
		player->sendSystemMessage(
			"@image_designer:already_image_designing");
		return;
	}

	ImageDesignStationDataComponent* data =
		getStationData(station);

	if (data == nullptr)
		return;

	int price = data->getServicePrice();

	int64 totalCredits =
		(int64)player->getCashCredits() +
		(int64)player->getBankCredits();

	if (totalCredits < price) {
		player->sendSystemMessage(
			"You need 10,000 credits to use this "
			"Image Designer Station.");
		return;
	}

	ManagedReference<ImageDesignStationSession*> session =
		new ImageDesignStationSession(player);

	session->deploy();

	session->startStationImageDesign(
		player,
		station->getObjectID(),
		data->getOwnerId(),
		price);
}

void ImageDesignStationMenuComponent::cancelStationStatMigration(
	CreatureObject* player,
	uint64 stationObjectId,
	bool notifyPlayer,
	const String& expectedToken) {

	if (player == nullptr)
		return;

	String marker =
		player->getLuaStringData(
			"fmidstation_stat_migration_station_id");

	if (marker.isEmpty())
		return;

	if (stationObjectId != 0 &&
			marker != String::valueOf(stationObjectId)) {
		return;
	}

	String activeToken =
		player->getLuaStringData(
			"fmidstation_stat_migration_token");

	if (!expectedToken.isEmpty() &&
			activeToken != expectedToken) {
		return;
	}

	ManagedReference<Facade*> facade =
		player->getActiveSession(
			SessionFacadeType::MIGRATESTATS);

	ManagedReference<MigrateStatsSession*> session =
		dynamic_cast<MigrateStatsSession*>(
			facade.get());

	if (session != nullptr)
		session->cancelSession();

	player->deleteLuaStringData(
		"fmidstation_stat_migration_station_id");

	player->deleteLuaStringData(
		"fmidstation_stat_migration_ready");

	player->deleteLuaStringData(
		"fmidstation_stat_migration_token");

	if (notifyPlayer) {
		player->sendSystemMessage(
			"Image Designer Station Stat Migration cancelled.");
	}
}

bool ImageDesignStationMenuComponent::chargeStationService(
	SceneObject* station,
	CreatureObject* player,
	ImageDesignStationDataComponent* data) {

	if (station == nullptr || player == nullptr || data == nullptr)
		return false;

	int price = Math::max(0, data->getServicePrice());

	int64 totalCredits =
		(int64)player->getCashCredits() +
		(int64)player->getBankCredits();

	if (totalCredits < price) {
		player->sendSystemMessage(
			"You do not have enough credits for this "
			"Image Designer Station service.");
		return false;
	}

	uint64 ownerId = data->getOwnerId();

	Reference<CreditObject*> ownerCredits =
		CreditManager::getCreditObject(ownerId);

	if (ownerId == 0 || ownerCredits == nullptr) {
		player->sendSystemMessage(
			"The station owner cannot currently receive payment. "
			"No credits were charged.");
		return false;
	}

	int cash = player->getCashCredits();

	if (cash >= price) {
		player->subtractCashCredits(price);
	} else {
		if (cash > 0)
			player->subtractCashCredits(cash);

		player->subtractBankCredits(price - cash);
	}

	CreditManager::addBankCredits(ownerId, price, true);

	TransactionLog trx(
		player, TrxCode::IMAGEDESIGN,
		(uint)price, false);

	trx.addState(
		"feature",
		String("FMIDStationStatMigration"));
	trx.addState("stationId", station->getObjectID());
	trx.addState("stationOwnerId", ownerId);
	trx.addState("price", price);
	trx.commit();

	data->recordCompletedSession(price);
	station->updateToDatabase();

	return true;
}

void ImageDesignStationMenuComponent::startStatMigration(
	SceneObject* station,
	CreatureObject* player) {

	if (station == nullptr ||
			player == nullptr ||
			!player->isPlayerCreature())
		return;

	String previousStation =
		player->getLuaStringData(
			"fmidstation_stat_migration_station_id");

	if (!previousStation.isEmpty()) {
		cancelStationStatMigration(
			player,
			0,
			false);
	}

	String reason;

	if (!isPlacementValid(station, &reason)) {
		player->sendSystemMessage(
			"Image Designer Station is safety locked: " + reason);
		return;
	}

	if (!isPlayerWithinUseRange(station, player))
		return;

	if (player->isDead() ||
			player->isInCombat() ||
			player->isInvisible()) {
		player->sendSystemMessage(
			"You cannot start Stat Migration in your current state.");
		return;
	}

	ManagedReference<Facade*> existingFacade =
		player->getActiveSession(
			SessionFacadeType::MIGRATESTATS);

	ManagedReference<MigrateStatsSession*> existingSession =
		dynamic_cast<MigrateStatsSession*>(
			existingFacade.get());

	if (existingSession != nullptr)
		existingSession->cancelSession();

	Time tokenTime;
	String migrationToken =
		String::valueOf(tokenTime.getMiliTime()) + "-" +
		String::valueOf(player->getObjectID()) + "-" +
		String::valueOf(station->getObjectID());

	player->setLuaStringData(
		"fmidstation_stat_migration_station_id",
		String::valueOf(station->getObjectID()));

	player->setLuaStringData(
		"fmidstation_stat_migration_token",
		migrationToken);

	player->deleteLuaStringData(
		"fmidstation_stat_migration_ready");

	ManagedReference<ImageDesignStationStatMigrationObserver*> observer =
		new ImageDesignStationStatMigrationObserver(
			player,
			station->getObjectID(),
			migrationToken);

	player->registerObserver(
		ObserverEventType::POSITIONCHANGED,
		observer);

	player->registerObserver(
		ObserverEventType::LOGGEDOUT,
		observer);

	Reference<ImageDesignStationStatMigrationTimeoutTask*> timeoutTask =
		new ImageDesignStationStatMigrationTimeoutTask(
			player,
			station->getObjectID(),
			migrationToken);

	timeoutTask->schedule(15 * 60 * 1000);

	player->sendSystemMessage(
		"Stat Migration service started. Open your Character Sheet "
		"(Ctrl+C), choose Stat Migration, set your target stats, and "
		"press OK to close that window. Then radial this Image Designer "
		"Station again and choose Apply Stat Migration. You are not "
		"charged until Apply is selected.");
}

void ImageDesignStationMenuComponent::applyStatMigration(
	SceneObject* station,
	CreatureObject* player) {

	if (station == nullptr ||
			player == nullptr ||
			!player->isPlayerCreature())
		return;

	String reason;

	if (!isPlacementValid(station, &reason)) {
		player->sendSystemMessage(
			"Image Designer Station is safety locked: " + reason);
		return;
	}

	if (!isPlayerWithinUseRange(station, player))
		return;

	if (player->getLuaStringData(
			"fmidstation_stat_migration_station_id") !=
			String::valueOf(station->getObjectID())) {
		player->sendSystemMessage(
			"Start Stat Migration from this Image Designer Station "
			"before applying it.");
		return;
	}

	if (player->getLuaStringData(
			"fmidstation_stat_migration_ready") != "1") {
		player->sendSystemMessage(
			"Your Stat Migration targets have not been submitted yet. "
			"Open Character Sheet (Ctrl+C), choose Stat Migration, set "
			"your targets, and press OK first.");
		return;
	}

	if (player->getLuaStringData(
			"fmidstation_stat_migration_token").isEmpty()) {
		cancelStationStatMigration(
			player,
			station->getObjectID(),
			false);

		player->sendSystemMessage(
			"This Stat Migration session is no longer valid. "
			"Please start it again from the station.");
		return;
	}

	ManagedReference<Facade*> facade =
		player->getActiveSession(
			SessionFacadeType::MIGRATESTATS);

	ManagedReference<MigrateStatsSession*> session =
		dynamic_cast<MigrateStatsSession*>(facade.get());

	if (session == nullptr) {
		player->deleteLuaStringData(
			"fmidstation_stat_migration_station_id");
		player->deleteLuaStringData(
			"fmidstation_stat_migration_ready");
		player->deleteLuaStringData(
			"fmidstation_stat_migration_token");

		player->sendSystemMessage(
			"There is no pending Stat Migration to apply.");
		return;
	}

	ImageDesignStationDataComponent* data =
		getStationData(station);

	if (data == nullptr)
		return;

	if (!chargeStationService(station, player, data))
		return;

	session->migrateStats();

	player->deleteLuaStringData(
		"fmidstation_stat_migration_station_id");
	player->deleteLuaStringData(
		"fmidstation_stat_migration_ready");
	player->deleteLuaStringData(
		"fmidstation_stat_migration_token");

	player->sendSystemMessage(
		"Stat Migration completed. "
		+ String::valueOf(data->getServicePrice())
		+ " credits were paid to the station owner.");
}

void ImageDesignStationMenuComponent::sendStatus(
	SceneObject* station,
	CreatureObject* player) {

	if (station == nullptr || player == nullptr)
		return;

	ImageDesignStationDataComponent* data =
		getStationData(station);

	if (data == nullptr)
		return;

	String reason;
	bool valid =
		isPlacementValid(station, &reason);

	StringBuffer msg;

	msg
		<< "Image Designer Station"
		<< " | Price: " << data->getServicePrice()
		<< " credits"
		<< " | Status: "
		<< (valid ? "READY" : "SAFETY LOCKED");

	if (!valid)
		msg << " (" << reason << ")";

	if (data->isOwner(player) ||
			(player->getPlayerObject() != nullptr &&
			 player->getPlayerObject()->isPrivileged())) {

		msg
			<< " | Owner ID: " << data->getOwnerId()
			<< " | Hair: " << data->getHairSkill()
			<< " | Face: " << data->getFaceSkill()
			<< " | Body: " << data->getBodySkill()
			<< " | Markings: " << data->getMarkingsSkill()
			<< " | Completed Services: "
			<< data->getLifetimeSessions()
			<< " | Lifetime Revenue "
			<< "(auto-deposited to owner bank): "
			<< data->getLifetimeRevenue();
	}

	player->sendSystemMessage(msg.toString());
}

void ImageDesignStationMenuComponent::refreshOwnerSkills(
	SceneObject* station,
	CreatureObject* player) {

	if (station == nullptr || player == nullptr)
		return;

	ImageDesignStationDataComponent* data =
		getStationData(station);

	if (data == nullptr || !data->isOwner(player)) {
		player->sendSystemMessage(
			"Only the station owner can refresh its "
			"Image Designer skills.");
		return;
	}

	if (!player->getLuaStringData(
			"fmidstation_temp_id_skills").isEmpty()) {
		player->sendSystemMessage(
			"You cannot refresh this station while an "
			"Image Designer Station session is active.");
		return;
	}

	if (!player->hasSkill(kMasterImageDesignerSkill)) {
		player->sendSystemMessage(
			"You must currently be a Master Image Designer "
			"to refresh this station.");
		return;
	}

	data->snapshotSkills(player);
	data->setOwnerGuildId(player->getGuildID());
	station->updateToDatabase();

	player->sendSystemMessage(
		"Image Designer Station skills refreshed from "
		"your current character.");

	sendStatus(station, player);
}

void ImageDesignStationMenuComponent::decommission(
	SceneObject* station,
	CreatureObject* player) {

	if (station == nullptr || player == nullptr)
		return;

	ImageDesignStationDataComponent* data =
		getStationData(station);

	if (data == nullptr || !data->isOwner(player)) {
		player->sendSystemMessage(
			"Only the station owner can decommission it.");
		return;
	}

	ManagedReference<SceneObject*> inventory =
		player->getInventory();

	ZoneServer* zoneServer =
		player->getZoneServer();

	if (inventory == nullptr ||
			zoneServer == nullptr ||
			inventory->isContainerFullRecursive()) {
		player->sendSystemMessage(
			"You need inventory space for the replacement "
			"Image Designer Station deed.");
		return;
	}

	ManagedReference<SceneObject*> deed =
		zoneServer->createObject(
			kStationDeedTemplate.hashCode(), 1);

	if (deed == nullptr) {
		player->sendSystemMessage(
			"Decommission failed before any station data "
			"was changed.");
		return;
	}

	Locker playerLocker(player);
	Locker stationLocker(station, player);
	Locker deedLocker(deed, player);

	TransactionLog trx(
		station, player, deed,
		TrxCode::PLAYERMISCACTION);

	trx.addState("feature", String("FMIDStation"));
	trx.addState("action", String("decommission"));

	if (!inventory->transferObject(deed, -1, true)) {
		trx.abort()
			<< "FMIDStation deed transfer failed; "
			<< "station left intact.";

		deed->destroyObjectFromDatabase(true);

		player->sendSystemMessage(
			"Decommission failed while delivering the replacement deed. "
			"The station was left intact.");
		return;
	}

	inventory->broadcastObject(deed, true);
	trx.commit();

	station->info(true)
		<< "FMIDStation DECOMMISSION owner="
		<< player->getObjectID()
		<< " station="
		<< station->getObjectID();

	station->destroyObjectFromWorld(true);
	station->destroyObjectFromDatabase(true);

	player->sendSystemMessage(
		"Image Designer Station decommissioned and deed "
		"returned to your inventory.");
}
