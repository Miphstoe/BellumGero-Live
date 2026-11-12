/*
 * VendorPackupManager.cpp
 *
 * Bellum Gero Persistent Vendor Packup System -- see VendorPackupManager.h.
 */

#include "VendorPackupManager.h"
#include "server/ServerCore.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/Zone.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "server/zone/objects/cell/CellObject.h"
#include "server/zone/objects/scene/SessionFacadeType.h"
#include "server/zone/objects/scene/variables/ContainerPermissions.h"
#include "server/zone/objects/player/sui/messagebox/SuiMessageBox.h"
#include "server/zone/managers/vendor/sui/VendorPackupSuiCallback.h"
#include "server/zone/managers/objectcontroller/ObjectController.h"
#include "server/zone/managers/auction/AuctionManager.h"
#include "server/zone/managers/auction/AuctionsMap.h"
#include "server/zone/objects/tangible/components/vendor/VendorDataComponent.h"
#include "server/zone/objects/transaction/TransactionLog.h"

namespace {
	AtomicInteger vendorPackupOpCounter;

	VendorDataComponent* getVendorData(SceneObject* vendor) {
		if (vendor == nullptr)
			return nullptr;

		DataObjectComponentReference* data = vendor->getDataObjectComponent();

		if (data == nullptr || data->get() == nullptr || !data->get()->isVendorData())
			return nullptr;

		return cast<VendorDataComponent*>(data->get());
	}

	const char* stateName(int state) {
		switch (state) {
		case VendorDataComponent::PACK_ACTIVE: return "ACTIVE";
		case VendorDataComponent::PACK_PACKING: return "PACKING";
		case VendorDataComponent::PACK_PACKED: return "PACKED";
		case VendorDataComponent::PACK_RESTORING: return "RESTORING";
		}
		return "UNKNOWN";
	}
}

uint64 VendorPackupManager::nextOperationId() {
	return ((uint64)time(0) << 16) | (uint64)(vendorPackupOpCounter.increment() & 0xFFFF);
}

void VendorPackupManager::logTransition(const String& what, CreatureObject* player, TangibleObject* vendor, VendorDataComponent* vendorData, int listings, uint64 destStructure) {
	uint32 account = 0;
	uint64 character = 0;

	if (player != nullptr) {
		character = player->getObjectID();
		PlayerObject* ghost = player->getPlayerObject();

		if (ghost != nullptr)
			account = ghost->getAccountID();
	}

	info(true) << "[VENDORPACK] " << what
		<< " account=" << account
		<< " character=" << character
		<< " vendor=" << (vendor != nullptr ? vendor->getObjectID() : 0)
		<< " state=" << (vendorData != nullptr ? stateName(vendorData->getPackState()) : "?")
		<< " op=" << (vendorData != nullptr ? vendorData->getPackOpId() : 0)
		<< " originStructure=" << (vendorData != nullptr ? vendorData->getPackedFromStructureId() : 0)
		<< " destStructure=" << destStructure
		<< " listings=" << listings
		<< " maint=" << (vendorData != nullptr ? vendorData->getMaint() : 0)
		<< " ts=" << (uint32)time(0);
}

// ---------------------------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------------------------

bool VendorPackupManager::validatePack(CreatureObject* player, TangibleObject* vendor, String& error) {
	if (player == nullptr || vendor == nullptr || !vendor->isVendor()) {
		error = "That is not a valid vendor.";
		return false;
	}

	VendorDataComponent* vendorData = getVendorData(vendor);

	if (vendorData == nullptr) {
		error = "That vendor cannot be packed up.";
		return false;
	}

	if (vendorData->getOwnerId() != player->getObjectID()) {
		error = "Only the vendor owner can pack up this vendor.";
		return false;
	}

	if (!vendorData->isInitialized()) {
		error = "Initialize the vendor first. An uninitialized vendor can simply be picked up.";
		return false;
	}

	if (vendorData->isPacked()) {
		error = "This vendor is already packed up.";
		return false;
	}

	if (!vendorData->isPackActive()) {
		error = "This vendor is currently being packed up or restored. Please try again shortly.";
		return false;
	}

	if (player->isDead() || player->isIncapacitated()) {
		error = "You cannot do that right now.";
		return false;
	}

	ManagedReference<SceneObject*> parent = vendor->getParent().get();

	if (vendor->getZone() == nullptr || parent == nullptr || !parent->isCellObject()) {
		error = "The vendor must be placed inside a structure to be packed up.";
		return false;
	}

	ManagedReference<SceneObject*> root = vendor->getRootParent();

	if (root == nullptr || root != player->getRootParent()) {
		error = "You must be in the same building as the vendor.";
		return false;
	}

	if (!vendor->isInRange(player, 10.f)) {
		error = "You are too far from the vendor.";
		return false;
	}

	if (root->isBuildingObject()) {
		BuildingObject* building = cast<BuildingObject*>(root.get());

		if (building != nullptr && building->getHousePackState() != 0) {
			error = "That structure is being packed up and cannot be used right now.";
			return false;
		}
	}

	if (player->containsActiveSession(SessionFacadeType::IMAGEDESIGN) || player->containsActiveSession(SessionFacadeType::VENDORADBARKING)
			|| player->containsActiveSession(SessionFacadeType::TRADE)) {
		error = "Finish your current vendor, image design or trade activity first.";
		return false;
	}

	ManagedReference<SceneObject*> inventory = player->getInventory();

	if (inventory == nullptr || inventory->isContainerFullRecursive()) {
		error = "Your inventory is full. Make room before packing up the vendor.";
		return false;
	}

	ManagedReference<AuctionManager*> auctionManager = player->getZoneServer()->getAuctionManager();

	if (auctionManager == nullptr || auctionManager->getAuctionMap() == nullptr) {
		error = "The market is unavailable right now.";
		return false;
	}

	if (auctionManager->getAuctionMap()->countPackBlockingItems(vendor) > 0) {
		error = "This vendor has pending offers or auctions. Resolve them before packing up the vendor.";
		return false;
	}

	return true;
}

bool VendorPackupManager::validateRedeploy(CreatureObject* player, TangibleObject* vendor, String& error) {
	if (player == nullptr || vendor == nullptr || !vendor->isVendor()) {
		error = "That is not a valid vendor.";
		return false;
	}

	VendorDataComponent* vendorData = getVendorData(vendor);

	if (vendorData == nullptr) {
		error = "That vendor cannot be redeployed.";
		return false;
	}

	if (vendorData->getOwnerId() != player->getObjectID()) {
		error = "Only the vendor owner can redeploy this vendor.";
		return false;
	}

	if (!vendorData->isPacked()) {
		error = vendorData->isPackTransitional() ? "This vendor is currently being packed up or restored. Please try again shortly." : "This vendor is not packed up.";
		return false;
	}

	if (player->isDead() || player->isIncapacitated()) {
		error = "You cannot do that right now.";
		return false;
	}

	ManagedReference<SceneObject*> parent = vendor->getParent().get();

	if (vendor->getZone() == nullptr || parent == nullptr || !parent->isCellObject()) {
		error = "Place the vendor inside a structure first, then choose Redeploy Vendor.";
		return false;
	}

	ManagedReference<SceneObject*> root = vendor->getRootParent();

	if (root == nullptr || !root->isBuildingObject() || root != player->getRootParent()) {
		error = "You must be in the same building as the vendor.";
		return false;
	}

	if (!vendor->isInRange(player, 15.f)) {
		error = "You are too far from the vendor.";
		return false;
	}

	BuildingObject* building = cast<BuildingObject*>(root.get());

	if (building == nullptr || building->getHousePackState() != 0) {
		error = "That structure cannot host a vendor right now.";
		return false;
	}

	// Same permission the normal vendor drop requires (public structure + VENDOR permission or admin).
	if (!building->checkContainerPermission(player, ContainerPermissions::MOVEVENDOR)) {
		error = "You do not have vendor permission in this building.";
		return false;
	}

	PlayerObject* ghost = player->getPlayerObject();

	if (ghost == nullptr || ghost->getVendorCount() > player->getSkillMod("manage_vendor")) {
		error = "You are managing more vendors than your merchant skills allow. Fire someone or remove a terminal first!";
		return false;
	}

	return true;
}

// ---------------------------------------------------------------------------------------------
// Pack up
// ---------------------------------------------------------------------------------------------

void VendorPackupManager::promptPackUp(CreatureObject* player, TangibleObject* vendor) {
	if (player == nullptr || vendor == nullptr)
		return;

	String errText;

	{
		Locker clocker(vendor, player);

		if (!validatePack(player, vendor, errText)) {
			player->sendSystemMessage(errText);
			return;
		}
	}

	ManagedReference<SuiMessageBox*> box = new SuiMessageBox(player, SuiWindowType::VENDOR_PACKUP_CONFIRM);
	box->setCallback(new VendorPackupSuiCallback(player->getZoneServer()));
	box->setUsingObject(vendor);
	box->setPromptTitle("Pack Up Vendor");
	box->setPromptText("Pack up this vendor?\n\n"
		"The vendor moves into your inventory with all of its merchandise, prices, name, appearance and maintenance credits intact. "
		"While packed, nothing can be bought from it, it will not appear in vendor searches, and listing timers and maintenance charges are paused.\n\n"
		"It still counts toward your vendor limit. To use it again, place it in a structure where you have vendor permission and choose Redeploy Vendor.");
	box->setOkButton(true, "@yes");
	box->setCancelButton(true, "@no");

	PlayerObject* ghost = player->getPlayerObject();

	if (ghost != nullptr)
		ghost->addSuiBox(box);

	player->sendMessage(box->generateMessage());
}

void VendorPackupManager::packUp(CreatureObject* player, TangibleObject* vendor) {
	if (player == nullptr || vendor == nullptr)
		return;

	ZoneServer* zoneServer = player->getZoneServer();

	if (zoneServer == nullptr)
		return;

	Locker clocker(vendor, player);

	String errText;

	// Re-validate everything: the dialog may have been open for a while.
	if (!validatePack(player, vendor, errText)) {
		player->sendSystemMessage(errText);
		info(true) << "[VENDORPACK] pack refused vendor=" << vendor->getObjectID() << " character=" << player->getObjectID() << " reason=" << errText;
		return;
	}

	VendorDataComponent* vendorData = getVendorData(vendor);
	AuctionsMap* auctionMap = zoneServer->getAuctionManager()->getAuctionMap();
	ManagedReference<SceneObject*> inventory = player->getInventory();
	ManagedReference<SceneObject*> parent = vendor->getParent().get();
	ManagedReference<SceneObject*> root = vendor->getRootParent();

	uint64 originStructure = root != nullptr ? root->getObjectID() : 0;
	uint64 opId = nextOperationId();

	// 1) Durable marker FIRST. From here on every purchase/list/cancel/retrieve entry point refuses this vendor.
	vendorData->setPackState(VendorDataComponent::PACK_PACKING, opId, originStructure);
	logTransition("ACTIVE->PACKING", player, vendor, vendorData, 0);

	// 2) Hide listings and record the remaining listing time (item-lock barrier inside).
	int listings = auctionMap->freezeVendorListings(vendor);

	// 3) Planetary map entry (registration preference stays on the vendor, restored on redeploy).
	Zone* zone = vendor->getZone();

	if (vendorData->isRegistered() && zone != nullptr)
		zone->unregisterObjectWithPlanetaryMap(vendor);

	vendorData->cancelVendorCheckTask();
	vendorData->removeAllVendorBarks();

	// 4) Move the ORIGINAL vendor object into the owner's inventory.
	bool moved = false;

	{
		Locker plocker(parent, vendor);

		ObjectController* objectController = zoneServer->getObjectController();

		if (objectController != nullptr)
			moved = objectController->transferObject(vendor, inventory, -1, true);
	}

	if (!moved) {
		error() << "[VENDORPACK] transfer to inventory failed vendor=" << vendor->getObjectID();
		rollbackPack(vendor, vendorData, "transfer failed");
		player->sendSystemMessage("The vendor could not be packed up. Nothing was changed.");
		return;
	}

	// 5) Commit.
	vendorData->setPackStateOnly(VendorDataComponent::PACK_PACKED);
	logTransition("PACKING->PACKED", player, vendor, vendorData, listings);

	{
		TransactionLog trx(player, vendor, TrxCode::VENDORLIFECYCLE);
		trx.addState("vendorPackup", String("pack"));
		trx.addState("listings", (uint64)listings);
	}

	StringBuffer msg;
	msg << "Your vendor has been packed up with " << listings << " listing(s). It is now in your inventory. "
		<< "Place it in a structure and choose Vendor Control -> Redeploy Vendor to use it again.";
	player->sendSystemMessage(msg.toString());
}

void VendorPackupManager::rollbackPack(TangibleObject* vendor, VendorDataComponent* vendorData, const String& why) {
	// Vendor is still in the world (or recovery decided it never left): make it exactly as before.
	ZoneServer* zoneServer = vendor->getZoneServer();

	if (zoneServer == nullptr || vendorData == nullptr)
		return;

	AuctionsMap* auctionMap = zoneServer->getAuctionManager()->getAuctionMap();

	int restored = 0;

	if (vendor->getZone() != nullptr) {
		restored = auctionMap->thawVendorListings(vendor, vendorData->isVendorSearchEnabled());

		if (vendorData->isRegistered())
			vendor->getZone()->registerObjectWithPlanetaryMap(vendor);
	}

	vendorData->setPackStateOnly(VendorDataComponent::PACK_ACTIVE);
	vendorData->scheduleVendorCheckTask(VendorDataComponent::VENDORCHECKINTERVAL);

	info(true) << "[VENDORPACK] ROLLBACK to ACTIVE vendor=" << vendor->getObjectID() << " listings=" << restored << " reason=" << why;
}

// ---------------------------------------------------------------------------------------------
// Redeploy
// ---------------------------------------------------------------------------------------------

void VendorPackupManager::redeploy(CreatureObject* player, TangibleObject* vendor) {
	if (player == nullptr || vendor == nullptr)
		return;

	Locker clocker(vendor, player);

	String errText;

	if (!validateRedeploy(player, vendor, errText)) {
		player->sendSystemMessage(errText);
		info(true) << "[VENDORPACK] redeploy refused vendor=" << vendor->getObjectID() << " character=" << player->getObjectID() << " reason=" << errText;
		return;
	}

	VendorDataComponent* vendorData = getVendorData(vendor);
	ManagedReference<SceneObject*> root = vendor->getRootParent();

	vendorData->setPackState(VendorDataComponent::PACK_RESTORING, nextOperationId(), 0);
	logTransition("PACKED->RESTORING", player, vendor, vendorData, 0, root != nullptr ? root->getObjectID() : 0);

	if (!completeRestore(vendor, vendorData, "redeploy")) {
		player->sendSystemMessage("The vendor could not be redeployed. Nothing was lost; it is still packed up.");
		return;
	}

	{
		TransactionLog trx(player, vendor, TrxCode::VENDORLIFECYCLE);
		trx.addState("vendorPackup", String("redeploy"));
	}

	player->sendSystemMessage("Your vendor has been redeployed. Its listings and maintenance have resumed.");
}

// Vendor locked, state RESTORING, vendor inside a cell with a zone.
bool VendorPackupManager::completeRestore(TangibleObject* vendor, VendorDataComponent* vendorData, const String& why) {
	ZoneServer* zoneServer = vendor->getZoneServer();

	if (zoneServer == nullptr || vendor->getZone() == nullptr) {
		rehideAfterFailedRestore(vendor, vendorData, why + ": no zone");
		return false;
	}

	AuctionsMap* auctionMap = zoneServer->getAuctionManager()->getAuctionMap();

	// New location / region -> new vendor UID (listings pick it up inside thaw).
	vendorData->updateUID();

	int thawed = auctionMap->thawVendorListings(vendor, vendorData->isVendorSearchEnabled());

	if (thawed < 0) {
		rehideAfterFailedRestore(vendor, vendorData, why + ": thaw failed");
		return false;
	}

	if (vendorData->isRegistered())
		vendor->getZone()->registerObjectWithPlanetaryMap(vendor);

	// Maintenance and idle clocks restart now: nothing was charged while packed.
	vendorData->resetClocksAfterRestore();
	vendorData->setOriginalDirection(vendor->getDirectionAngle());
	vendorData->scheduleVendorCheckTask(VendorDataComponent::VENDORCHECKINTERVAL);

	// Commit marker last.
	vendorData->setPackStateOnly(VendorDataComponent::PACK_ACTIVE);

	info(true) << "[VENDORPACK] RESTORING->ACTIVE vendor=" << vendor->getObjectID() << " op=" << vendorData->getPackOpId()
		<< " listings=" << thawed << " maint=" << vendorData->getMaint() << " via=" << why << " ts=" << (uint32)time(0);

	return true;
}

void VendorPackupManager::rehideAfterFailedRestore(TangibleObject* vendor, VendorDataComponent* vendorData, const String& why) {
	ZoneServer* zoneServer = vendor->getZoneServer();

	if (zoneServer != nullptr) {
		AuctionsMap* auctionMap = zoneServer->getAuctionManager()->getAuctionMap();
		auctionMap->freezeVendorListings(vendor);
	}

	vendorData->setPackStateOnly(VendorDataComponent::PACK_PACKED);

	error() << "[VENDORPACK] restore failed, vendor stays PACKED vendor=" << vendor->getObjectID() << " reason=" << why;
}

// ---------------------------------------------------------------------------------------------
// Recovery
// ---------------------------------------------------------------------------------------------

bool VendorPackupManager::recoverVendor(uint64 vendorID, const String& reason) {
	ZoneServer* zoneServer = ServerCore::getZoneServer();

	if (zoneServer == nullptr)
		return false;

	ManagedReference<TangibleObject*> vendor = zoneServer->getObject(vendorID).castTo<TangibleObject*>();

	if (vendor == nullptr || !vendor->isVendor())
		return false;

	Locker locker(vendor);

	VendorDataComponent* vendorData = getVendorData(vendor);

	if (vendorData == nullptr)
		return false;

	int state = vendorData->getPackState();

	if (state == VendorDataComponent::PACK_ACTIVE || state == VendorDataComponent::PACK_PACKED)
		return true; // nothing to resolve

	// Do not interfere with an operation that is genuinely in flight.
	if (reason != "admin" && reason != "startup" && ((uint32)time(0) - vendorData->getPackTime()) < 60)
		return false;

	ManagedReference<SceneObject*> owner = zoneServer->getObject(vendorData->getOwnerId());
	ManagedReference<SceneObject*> inventory = owner != nullptr && owner->isCreatureObject() ? owner->asCreatureObject()->getInventory() : nullptr;
	ManagedReference<SceneObject*> parent = vendor->getParent().get();

	bool inInventory = inventory != nullptr && parent == inventory;
	bool inCell = parent != nullptr && parent->isCellObject() && vendor->getZone() != nullptr;

	info(true) << "[VENDORPACK] RECOVERY begin vendor=" << vendorID << " state=" << stateName(state) << " inInventory=" << inInventory
		<< " inCell=" << inCell << " reason=" << reason;

	if (state == VendorDataComponent::PACK_PACKING) {
		if (inInventory) {
			// The move happened; finish the commit. Make sure the listings are hidden.
			zoneServer->getAuctionManager()->getAuctionMap()->freezeVendorListings(vendor);
			vendorData->setPackStateOnly(VendorDataComponent::PACK_PACKED);
			info(true) << "[VENDORPACK] RECOVERY PACKING->PACKED vendor=" << vendorID;
			return true;
		}

		if (inCell) {
			rollbackPack(vendor, vendorData, "recovery: interrupted before move");
			return true;
		}

		error() << "[VENDORPACK] RECOVERY cannot place vendor=" << vendorID << " (neither in owner inventory nor in a cell); left PACKING for admin review";
		return false;
	}

	if (state == VendorDataComponent::PACK_RESTORING) {
		if (inCell) {
			return completeRestore(vendor, vendorData, "recovery");
		}

		if (inInventory) {
			zoneServer->getAuctionManager()->getAuctionMap()->freezeVendorListings(vendor);
			vendorData->setPackStateOnly(VendorDataComponent::PACK_PACKED);
			info(true) << "[VENDORPACK] RECOVERY RESTORING->PACKED vendor=" << vendorID;
			return true;
		}

		error() << "[VENDORPACK] RECOVERY cannot place vendor=" << vendorID << " (neither in owner inventory nor in a cell); left RESTORING for admin review";
		return false;
	}

	return false;
}

void VendorPackupManager::recoverPlayerVendors(uint64 playerID) {
	ZoneServer* zoneServer = ServerCore::getZoneServer();

	if (zoneServer == nullptr)
		return;

	ManagedReference<CreatureObject*> player = zoneServer->getObject(playerID).castTo<CreatureObject*>();

	if (player == nullptr)
		return;

	PlayerObject* ghost = player->getPlayerObject();

	if (ghost == nullptr)
		return;

	// Copy: recovery may take other locks.
	SortedVector<unsigned long long> ids = *ghost->getOwnedVendors();

	for (int i = 0; i < ids.size(); ++i) {
		ManagedReference<SceneObject*> vendor = zoneServer->getObject(ids.get(i));

		if (vendor == nullptr || !VendorDataComponent::isVendorFrozen(vendor))
			continue;

		VendorDataComponent* vendorData = getVendorData(vendor);

		if (vendorData != nullptr && vendorData->isPackTransitional())
			recoverVendor(ids.get(i), "login");
	}
}

String VendorPackupManager::describeVendor(uint64 vendorID) {
	ZoneServer* zoneServer = ServerCore::getZoneServer();

	if (zoneServer == nullptr)
		return "no zone server";

	ManagedReference<SceneObject*> vendor = zoneServer->getObject(vendorID);

	if (vendor == nullptr || !vendor->isVendor())
		return "Object " + String::valueOf(vendorID) + " is not a vendor.";

	VendorDataComponent* vendorData = getVendorData(vendor);

	if (vendorData == nullptr)
		return "Vendor has no vendor data.";

	ManagedReference<SceneObject*> parent = vendor->getParent().get();

	StringBuffer out;
	out << "Vendor " << vendorID << " owner=" << vendorData->getOwnerId()
		<< " state=" << stateName(vendorData->getPackState())
		<< " op=" << vendorData->getPackOpId()
		<< " packedAt=" << vendorData->getPackTime()
		<< " originStructure=" << vendorData->getPackedFromStructureId()
		<< " parent=" << (parent != nullptr ? parent->getObjectID() : 0)
		<< " inZone=" << (vendor->getZone() != nullptr ? "yes" : "no")
		<< " maint=" << vendorData->getMaint();

	AuctionManager* auctionManager = zoneServer->getAuctionManager();

	if (auctionManager != nullptr && auctionManager->getAuctionMap() != nullptr)
		out << " listings=" << auctionManager->getAuctionMap()->countAllVendorItems(vendor);

	return out.toString();
}
