/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef REQUESTWAYPOINTATPOSITIONCOMMAND_H_
#define REQUESTWAYPOINTATPOSITIONCOMMAND_H_

#include "server/zone/managers/auction/AuctionManager.h"
#include "server/zone/managers/auction/AuctionsMap.h"
#include "server/zone/objects/auction/AuctionItem.h"
#include <cstdio>

class RequestWaypointAtPositionCommand : public QueueCommand {
private:
	String getListingName(AuctionItem* item) const {
		String listingName = item->getItemName();
		listingName.trim();

		if (listingName.isEmpty()) {
			ManagedReference<SceneObject*> object = server->getZoneServer()->getObject(item->getAuctionedItemObjectID());
			if (object != nullptr)
				listingName = object->getDisplayedName();
			listingName.trim();
		}

		if (listingName.isEmpty() || listingName.length() > 127 || listingName[0] == '@')
			return "";

		for (int i = 0; i < listingName.length(); ++i) {
			unsigned char character = listingName[i];
			if (character < 32 || character == 127)
				return "";
		}

		return listingName;
	}

	bool isListedAtPosition(AuctionItem* item, const String& planet, float x, float y) const {
		if (item == nullptr || item->getStatus() != AuctionItem::FORSALE)
			return false;

		String uid = item->getVendorUID();
		int planetEnd = uid.indexOf('.');
		int hash = uid.lastIndexOf('#');
		int locationX = 0;
		int locationY = 0;
		char extra = 0;

		return planetEnd > 0 && hash >= 0 && uid.subString(0, planetEnd) == planet &&
				std::sscanf(uid.toCharArray() + hash + 1, "%d,%d%c", &locationX, &locationY, &extra) == 2 &&
				(int)x == locationX && (int)y == locationY;
	}

	String getSearchListingName(CreatureObject* creature, uint64 target, const String& planet, float x, float y) const {
		uint32 searchTime = creature->getAuctionWaypointSearchTime();
		uint32 now = time(0);

		AuctionManager* auctionManager = server->getZoneServer()->getAuctionManager();
		if (auctionManager == nullptr)
			return "";

		AuctionsMap* auctionMap = auctionManager->getAuctionMap();
		if (auctionMap == nullptr)
			return "";

		// Prefer the listing the player last clicked in the bazaar window, if it is at this location.
		uint64 selectedItemID = creature->getAuctionWaypointSelectedItem();
		uint32 selectedTime = creature->getAuctionWaypointSelectedTime();

		if (selectedItemID != 0 && selectedTime != 0 && now >= selectedTime && now - selectedTime <= 300) {
			ManagedReference<AuctionItem*> selectedItem = auctionMap->getItem(selectedItemID);

			if (isListedAtPosition(selectedItem, planet, x, y)) {
				String listingName = getListingName(selectedItem);

				if (!listingName.isEmpty())
					return listingName;
			}
		}

		if (searchTime == 0 || now < searchTime || now - searchTime > 300)
			return "";

		String selectedName;

		for (int i = 0; i < creature->getAuctionWaypointResultCount(); ++i) {
			uint64 itemID = creature->getAuctionWaypointResult(i);

			if (target != 0 && target != itemID)
				continue;

			ManagedReference<AuctionItem*> item = auctionMap->getItem(itemID);

			if (!isListedAtPosition(item, planet, x, y))
				continue;

			String listingName = getListingName(item);

			if (listingName.isEmpty())
				continue;

			if (target == itemID)
				return listingName;

			// The client sends no listing ID, so only rename when every search result at this location has the same name.
			if (!selectedName.isEmpty() && selectedName != listingName)
				return "";

			selectedName = listingName;
		}

		return selectedName;
	}

public:

	RequestWaypointAtPositionCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {

	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {

		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		//'naboo 2527.300049 0.000000 1696.300049 parking garage general'

		if (!creature->isPlayerCreature())
			return GENERALERROR;

		UnicodeTokenizer tokenizer(arguments);

		try {
			String planet;
			tokenizer.getStringToken(planet);

			float x = tokenizer.getFloatToken();
			float z = tokenizer.getFloatToken();
			float y = tokenizer.getFloatToken();

			UnicodeString name;
			tokenizer.finalToken(name);

			String requestedName = name.toString();
			requestedName.trim();
			// TEMP DEBUG: remove once vendor waypoint naming is confirmed working
			Logger::console.info(true) << "[VendorWaypoint] name='" << requestedName << "' target=" << target << " planet=" << planet << " x=" << x << " y=" << y
				<< " results=" << creature->getAuctionWaypointResultCount() << " selected=" << creature->getAuctionWaypointSelectedItem()
				<< " selectedAge=" << (uint32)(time(0) - creature->getAuctionWaypointSelectedTime()) << " searchAge=" << (uint32)(time(0) - creature->getAuctionWaypointSearchTime());

			if (requestedName == "Waypoint to Vendor") {
				String listingName = getSearchListingName(creature, target, planet, x, y);
				Logger::console.info(true) << "[VendorWaypoint] resolved='" << listingName << "'";
				if (!listingName.isEmpty())
					name = listingName;
			}

			x = (x < -8192) ? -8192 : x;
			x = (x > 8192) ? 8192 : x;

			y = (y < -8192) ? -8192 : y;
			y = (y > 8192) ? 8192 : y;

			Reference<PlayerObject*> playerObject = creature->getSlottedObject("ghost").castTo<PlayerObject*>( );

			ManagedReference<WaypointObject*> obj = ( server->getZoneServer()->createObject(0xc456e788, 1)).castTo<WaypointObject*>();

			Locker locker(obj);

			obj->setPlanetCRC(planet.hashCode());
			obj->setPosition(x, z, y);
			obj->setCustomObjectName(name, false);
			obj->setActive(true);

			playerObject->addWaypoint(obj, false, true); // Should second argument be true, and waypoints with the same name thus remove their old version?

		} catch (Exception& e) {

		}

		return SUCCESS;
	}

};

#endif //REQUESTWAYPOINTATPOSITIONCOMMAND_H_
