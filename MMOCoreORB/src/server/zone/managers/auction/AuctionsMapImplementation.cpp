/*
 * AuctionsMap.cpp
 *
 *  Created on: 6/3/2012
 *      Author: kyle
 */

#include "server/zone/managers/auction/AuctionsMap.h"
#include "server/zone/objects/auction/AuctionItem.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/objects/tangible/components/vendor/VendorDataComponent.h"
#include "server/zone/managers/object/ObjectManager.h"
#include "server/zone/packets/auction/ItemSoldMessage.h"

int AuctionsMapImplementation::addItem(CreatureObject* player, SceneObject* vendor, AuctionItem* item) {
	if(vendor == nullptr || vendor->getZone() == nullptr)
		return ItemSoldMessage::VENDORNOTWORKING;

	String planet = vendor->getZone()->getZoneName();

	String region = "@planet_n:" + vendor->getZone()->getZoneName();
	ManagedReference<CityRegion*> cityRegion = vendor->getCityRegion().get();
	if(cityRegion != nullptr)
		region = cityRegion->getCityRegionName();

	if(vendor->isBazaarTerminal())
		return addBazaarItem(player, planet, region, vendor, item);

	return addVendorItem(player, planet, region, vendor, item);
}

int AuctionsMapImplementation::addVendorItem(CreatureObject* player, const String& planet, const String& region, SceneObject* vendor, AuctionItem* item) {
	Locker locker(_this.getReferenceUnsafeStaticCast());

	if(allItems.contains(item->getAuctionedItemObjectID()))
		return ItemSoldMessage::ALREADYFORSALE;

	if(!vendorItemsForSale.contains(vendor->getObjectID()) && !vendorItemsForSale.createTerminalListing(planet, region, vendor))
		return ItemSoldMessage::VENDORNOTWORKING;

	Reference<TerminalItemList*> vendorItems = vendorItemsForSale.get(vendor->getObjectID());
	if(vendorItems->isEmpty()) {

		VendorDataComponent* vendorData = nullptr;
		DataObjectComponentReference* data = vendor->getDataObjectComponent();
		if(data != nullptr && data->get() != nullptr && data->get()->isVendorData()) {
			vendorData = cast<VendorDataComponent*>(data->get());
			if(vendorData == nullptr)
				return ItemSoldMessage::VENDORNOTWORKING;

			vendorItems->setSearchable(vendorData->isVendorSearchEnabled());
		}
	}

	if(vendorItems == nullptr)
		return ItemSoldMessage::INVALIDAUCTIONER;

	//Locker vlocker(vendorItems);

	int result = vendorItems->put(item);

	if(result == -1)
		return ItemSoldMessage::UNKNOWNERROR;

	allItems.put(item->getAuctionedItemObjectID(), item);

	return ItemSoldMessage::SUCCESS;
}

int AuctionsMapImplementation::addBazaarItem(CreatureObject* player, const String& planet, const String& region, SceneObject* vendor, AuctionItem* item) {
	Locker locker(_this.getReferenceUnsafeStaticCast());

	if(allItems.contains(item->getAuctionedItemObjectID()))
		return ItemSoldMessage::ALREADYFORSALE;

	if(!bazaarItemsForSale.contains(vendor->getObjectID()) && !bazaarItemsForSale.createTerminalListing(planet, region, vendor))
		return ItemSoldMessage::VENDORNOTWORKING;

	Reference<TerminalItemList*> bazaarItems = bazaarItemsForSale.get(vendor->getObjectID());

	if(bazaarItems == nullptr)
		return ItemSoldMessage::INVALIDAUCTIONER;

	//Locker blocker(bazaarItems);
	int result = bazaarItems->put(item);

	if(result == -1)
		return ItemSoldMessage::UNKNOWNERROR;

	allItems.put(item->getAuctionedItemObjectID(), item);
	return ItemSoldMessage::SUCCESS;
}

void AuctionsMapImplementation::deleteItem(SceneObject* vendor, AuctionItem* item, bool deleteAuctionedObject) {
	Locker locker(_this.getReferenceUnsafeStaticCast());
	removeItem(vendor, item);
	item->destroyAuctionItemFromDatabase(false, deleteAuctionedObject);
}

void AuctionsMapImplementation::removeItem(SceneObject* vendor, AuctionItem* item) {
	Locker locker(_this.getReferenceUnsafeStaticCast());

	if(vendor != nullptr) {
		if(vendor->isBazaarTerminal())
			removeBazaarItem(vendor, item);
		else
			removeVendorItem(vendor, item);
	}

	allItems.drop(item->getAuctionedItemObjectID());
}

void AuctionsMapImplementation::removeVendorItem(SceneObject* vendor, AuctionItem* item) {
	Locker locker(_this.getReferenceUnsafeStaticCast());

	Reference<TerminalItemList*> vendorItems = vendorItemsForSale.get(vendor->getObjectID());

	if(vendorItems == nullptr)
		return;

	//Locker vlocker(vendorItems);

	if(vendorItems->drop(item))
		return;

	logger.error("unable to remove vendor item");
}

void AuctionsMapImplementation::removeBazaarItem(SceneObject* vendor,  AuctionItem* item) {
	Locker locker(_this.getReferenceUnsafeStaticCast());

	Reference<TerminalItemList*> bazaarItems = bazaarItemsForSale.get(vendor->getObjectID());

	if(bazaarItems == nullptr)
		return;

	//Locker blocker(bazaarItems);

	if(!bazaarItems->drop(item))
		logger.error("unable to remove bazaar item");

}

TerminalListVector AuctionsMapImplementation::getVendorTerminalData(const String& planet, const String& region, SceneObject* vendor) {
	Locker locker(_this.getReferenceUnsafeStaticCast());

	return vendorItemsForSale.getTerminalData(planet, region, vendor);
}

TerminalListVector AuctionsMapImplementation::getBazaarTerminalData(const String& planet, const String& region, SceneObject* vendor) {
	Locker locker(_this.getReferenceUnsafeStaticCast());

	return bazaarItemsForSale.getTerminalData(planet, region, vendor);
}
int AuctionsMapImplementation::getPlayerItemCount(CreatureObject* player) {
	ManagedReference<PlayerObject*> ghost = player->getPlayerObject();

	if (ghost == nullptr)
		return 0;

	const SortedVector<unsigned long long>* ownedVendors = ghost->getOwnedVendors();
	int total = 0;

	for (int i = 0; i < ownedVendors->size(); i++) {
		ManagedReference<SceneObject*> vendor = player->getZoneServer()->getObject(ownedVendors->elementAt(i));

		total += getVendorItemCount(vendor);
	}

	return total;
}

int AuctionsMapImplementation::getVendorItemCount(SceneObject* vendor, bool forSaleOnly) {
	Locker locker(_this.getReferenceUnsafeStaticCast());

	if(vendor == nullptr) {
		logger.error("null vendor in AuctionsMapImplementation::getVendorItemCount");
		return 0;
	}

	Reference<TerminalItemList*> vendorItems = vendorItemsForSale.get(vendor->getObjectID());

	if(vendorItems == nullptr) {
		// Vendor Packup: a packed vendor's listings are hidden from the terminal index but must still
		// count toward the owner's item limit (prevents using packup to bypass vendor_item_limit).
		if (!VendorDataComponent::isVendorFrozen(vendor))
			return 0;

		int frozenSize = 0;
		uint64 frozenVendorID = vendor->getObjectID();

		for (int i = 0; i < allItems.size(); ++i) {
			AuctionItem* item = allItems.get(i);

			if (item == nullptr || item->getVendorID() != frozenVendorID)
				continue;

			if (forSaleOnly && item->getStatus() != AuctionItem::FORSALE)
				continue;

			int itemSize = item->getSize();

			if (itemSize > 50)
				frozenSize += 50;
			else if (itemSize > 0)
				frozenSize += itemSize;
			else
				frozenSize++;
		}

		return frozenSize;
	}

	int size = 0;

	ReadLocker rlocker(vendorItems);

	for (int i = 0; i < vendorItems->size(); ++i) {
		AuctionItem* item = vendorItems->get(i);
		if (item == nullptr)
			continue;

		if (forSaleOnly && item->getStatus() != AuctionItem::FORSALE)
			continue;

		int itemSize = item->getSize();

		if (itemSize > 50)
			size += 50;
		else if (itemSize > 0)
			size += itemSize;
		else
			size++;
	}

	return size;
}

void AuctionsMapImplementation::deleteTerminalItems(SceneObject* vendor) {
	if(vendor->isBazaarTerminal()) {
		return;
	}

	Locker locker(_this.getReferenceUnsafeStaticCast());

	Reference<TerminalItemList*> vendorItems = vendorItemsForSale.get(vendor->getObjectID());
	ZoneServer* zserv = vendor->getZoneServer();

	if(vendorItems != nullptr) {
		ReadLocker rlocker(vendorItems);

		for(int i = 0; i < vendorItems->size(); ++i) {
			Reference<AuctionItem*> item = vendorItems->get(i);

			if(item != nullptr) {
				allItems.drop(item->getAuctionedItemObjectID());
				item->destroyAuctionItemFromDatabase(false, true);
			}
		}
	}

	vendorItemsForSale.dropTerminalListing(vendor);
}

void AuctionsMapImplementation::updateUID(SceneObject* vendor, const String& oldUID, const String& newUID) {
	Locker locker(_this.getReferenceUnsafeStaticCast());

	if (vendor == nullptr) {
		logger.error("nullptr vendor while updating UID");
		return;
	}

	Zone* zone = vendor->getZone();

	if (zone == nullptr) {
		logger.error("nullptr zone while updating UID  Vendor Is Bazaar: " + String::valueOf(vendor->isBazaarTerminal()));
		return;
	}

	String planet = zone->getZoneName();

	String region = "@planet_n:" + planet;
	ManagedReference<CityRegion*> cityRegion = vendor->getCityRegion().get();
	if(cityRegion != nullptr)
		region = cityRegion->getCityRegionName();

	if(vendor->isVendor())
		vendorItemsForSale.updateTerminalUID(planet, region, vendor, newUID);
	else
		bazaarItemsForSale.updateTerminalUID(planet, region, vendor, newUID);
}

void AuctionsMapImplementation::updateVendorSearch(SceneObject* vendor, bool enabled) {
	Locker locker(_this.getReferenceUnsafeStaticCast());

	if (vendor == nullptr)
		return;

	vendorItemsForSale.updateTerminalSearch(vendor, enabled);
}

int AuctionsMapImplementation::getCommodityCount(CreatureObject* player) {

	Locker locker(&commoditiesLimit);

	if(!commoditiesLimit.contains(player->getObjectID()))
		return 0;

	Vector<ManagedWeakReference<AuctionItem*> >* items = &commoditiesLimit.get(player->getObjectID());

	for(int i = items->size() -1; i >= 0; --i) {
		ManagedReference<AuctionItem*> item = items->get(i);
		if(item == nullptr || item->getOwnerID() != player->getObjectID() ||
				item->getStatus() == AuctionItem::RETRIEVED) {
			items->remove(i);
		}
	}

	return items->size();
}

void AuctionsMapImplementation::addToCommodityLimit(AuctionItem* item) {

	Locker locker(&commoditiesLimit);

	if(!commoditiesLimit.contains(item->getOwnerID())) {
		Vector<ManagedWeakReference<AuctionItem*> > newItems;
		commoditiesLimit.put(item->getOwnerID(), newItems);
	}

	Vector<ManagedWeakReference<AuctionItem*> >* items = &commoditiesLimit.get(item->getOwnerID());
	if(items != nullptr)
		items->add(item);

}

void AuctionsMapImplementation::removeFromCommodityLimit(AuctionItem* item) {

	Locker locker(&commoditiesLimit);

	if(!commoditiesLimit.contains(item->getOwnerID()))
		return;

	Vector<ManagedWeakReference<AuctionItem*> >* items = &commoditiesLimit.get(item->getOwnerID());
	if(items != nullptr)
		items->removeElement(item);

	if(items->isEmpty())
		commoditiesLimit.drop(item->getOwnerID());
}


int AuctionsMapImplementation::updatePlayerName(uint64 playerID, const String& oldFirstName, const String& newFirstName) {
	Vector<ManagedReference<AuctionItem*> > snapshot;

	{
		// Snapshot under the map lock, then release it before locking individual items
		Locker locker(_this.getReferenceUnsafeStaticCast());

		for (int i = 0; i < allItems.size(); ++i) {
			ManagedReference<AuctionItem*> item = allItems.elementAt(i).getValue();

			if (item != nullptr)
				snapshot.add(item);
		}
	}

	String oldLower = oldFirstName.toLowerCase();
	String newLower = newFirstName.toLowerCase();
	int updated = 0;

	for (int i = 0; i < snapshot.size(); ++i) {
		AuctionItem* item = snapshot.get(i);

		Locker itemLocker(item);

		bool changed = false;

		// Owner is tracked by object ID; the stored name is used for mail and search
		if (item->getOwnerID() == playerID && item->getOwnerName() != newFirstName) {
			item->setOwnerName(newFirstName);
			changed = true;
		}

		// Active bids are tracked by (lowercase) name only
		if (!oldLower.isEmpty() && item->getBidderName().toLowerCase() == oldLower) {
			item->setBidderName(newLower);
			changed = true;
		}

		if (changed)
			updated++;
	}

	return updated;
}

// ============================================================================
// Bellum Gero Vendor Packup
// ============================================================================

int AuctionsMapImplementation::freezeVendorListings(SceneObject* vendor) {
	if (vendor == nullptr || vendor->isBazaarTerminal())
		return 0;

	// 1) Snapshot the vendor's listings under the map lock.
	Vector<Reference<AuctionItem*> > snapshot;

	{
		Locker locker(_this.getReferenceUnsafeStaticCast());

		Reference<TerminalItemList*> vendorItems = vendorItemsForSale.get(vendor->getObjectID());

		if (vendorItems != nullptr) {
			ReadLocker rlocker(vendorItems);

			for (int i = 0; i < vendorItems->size(); ++i) {
				Reference<AuctionItem*> item = vendorItems->get(i);

				if (item != nullptr)
					snapshot.add(item);
			}
		}
	}

	// 2) Take each item lock once (barrier against in-flight purchases; the vendor is
	//    already flagged PACKING so every entry point refuses new work) and record the
	//    remaining listing time so it can be resumed on redeploy.
	uint32 now = (uint32)time(0);

	for (int i = 0; i < snapshot.size(); ++i) {
		Reference<AuctionItem*>& item = snapshot.get(i);

		Locker ilocker(item);

		uint32 expire = item->getExpireTime();
		uint32 remaining = (expire > now) ? (expire - now) : 1;

		item->setPausedRemaining(remaining);
	}

	// 3) Hide the listing from search and from periodic maintenance. Items stay in allItems
	//    so they cannot be listed twice and the DB records are untouched.
	{
		Locker locker(_this.getReferenceUnsafeStaticCast());
		vendorItemsForSale.dropTerminalListing(vendor);
	}

	return snapshot.size();
}

int AuctionsMapImplementation::thawVendorListings(SceneObject* vendor, bool searchable) {
	if (vendor == nullptr || vendor->getZone() == nullptr || vendor->isBazaarTerminal())
		return 0;

	String uid = "";

	DataObjectComponentReference* data = vendor->getDataObjectComponent();

	if (data != nullptr && data->get() != nullptr && data->get()->isAuctionTerminalData()) {
		AuctionTerminalDataComponent* terminalData = cast<AuctionTerminalDataComponent*>(data->get());

		if (terminalData != nullptr)
			uid = terminalData->getUID();
	}

	String planet = vendor->getZone()->getZoneName();
	String region = "@planet_n:" + planet;

	ManagedReference<CityRegion*> cityRegion = vendor->getCityRegion().get();

	if (cityRegion != nullptr)
		region = cityRegion->getCityRegionName();

	uint64 vendorID = vendor->getObjectID();

	// Collect this vendor's listings from the master index.
	Vector<Reference<AuctionItem*> > items;

	{
		Locker locker(_this.getReferenceUnsafeStaticCast());

		for (int i = 0; i < allItems.size(); ++i) {
			Reference<AuctionItem*> item = allItems.get(i);

			if (item != nullptr && item->getVendorID() == vendorID)
				items.add(item);
		}
	}

	uint32 now = (uint32)time(0);

	for (int i = 0; i < items.size(); ++i) {
		Reference<AuctionItem*>& item = items.get(i);

		Locker ilocker(item);

		uint32 paused = item->getPausedRemaining();

		if (paused > 0) {
			item->setExpireTime(now + paused);
			item->setPausedRemaining(0);
		}

		if (!uid.isEmpty())
			item->setVendorUID(uid);
	}

	Locker locker(_this.getReferenceUnsafeStaticCast());

	if (!vendorItemsForSale.createTerminalListing(planet, region, vendor)) {
		logger.error("thawVendorListings: unable to create terminal listing for vendor " + String::valueOf(vendorID));
		return -1;
	}

	Reference<TerminalItemList*> vendorItems = vendorItemsForSale.get(vendorID);

	if (vendorItems == nullptr)
		return -1;

	vendorItems->setSearchable(searchable);

	int added = 0;

	for (int i = 0; i < items.size(); ++i) {
		if (vendorItems->put(items.get(i)) != -1)
			added++;
	}

	return added;
}

int AuctionsMapImplementation::addFrozenItem(AuctionItem* item) {
	Locker locker(_this.getReferenceUnsafeStaticCast());

	if (allItems.contains(item->getAuctionedItemObjectID()))
		return ItemSoldMessage::ALREADYFORSALE;

	allItems.put(item->getAuctionedItemObjectID(), item);

	return ItemSoldMessage::SUCCESS;
}

int AuctionsMapImplementation::countPackBlockingItems(SceneObject* vendor) {
	if (vendor == nullptr)
		return 0;

	Locker locker(_this.getReferenceUnsafeStaticCast());

	Reference<TerminalItemList*> vendorItems = vendorItemsForSale.get(vendor->getObjectID());

	if (vendorItems == nullptr)
		return 0;

	int blocking = 0;

	ReadLocker rlocker(vendorItems);

	for (int i = 0; i < vendorItems->size(); ++i) {
		AuctionItem* item = vendorItems->get(i);

		if (item == nullptr)
			continue;

		if (item->getStatus() == AuctionItem::OFFERED || item->isAuction())
			blocking++;
	}

	return blocking;
}

int AuctionsMapImplementation::countAllVendorItems(SceneObject* vendor) {
	if (vendor == nullptr)
		return 0;

	uint64 vendorID = vendor->getObjectID();
	int count = 0;

	Locker locker(_this.getReferenceUnsafeStaticCast());

	for (int i = 0; i < allItems.size(); ++i) {
		AuctionItem* item = allItems.get(i);

		if (item != nullptr && item->getVendorID() == vendorID)
			count++;
	}

	return count;
}
