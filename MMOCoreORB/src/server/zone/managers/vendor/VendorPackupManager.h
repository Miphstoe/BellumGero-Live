/*
 * VendorPackupManager.h
 *
 * Bellum Gero Persistent Vendor Packup System.
 *
 * A vendor is "packed" by moving the ORIGINAL vendor object into its owner's inventory
 * (exactly where vendors live before they are first placed) and hiding its listings.
 * Nothing is deleted or recreated: the vendor object ID, customization, name, maintenance
 * balance, and every AuctionItem (price, description, listed object ID) stay as they are.
 *
 * State machine (VendorDataComponent::packState, persisted):
 *   ACTIVE -> PACKING -> PACKED -> RESTORING -> ACTIVE
 * Only transitions made under the vendor lock are allowed, so one operation runs at a time.
 * Recovery decides from the persisted marker plus where the vendor physically is.
 */

#ifndef VENDORPACKUPMANAGER_H_
#define VENDORPACKUPMANAGER_H_

#include "engine/engine.h"

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/tangible/TangibleObject.h"

class VendorDataComponent;

class VendorPackupManager : public Singleton<VendorPackupManager>, public Logger, public Object {
public:
	VendorPackupManager() {
		setLoggingName("VendorPackupManager");
	}

	// Owner entry points (radial menu)
	void promptPackUp(CreatureObject* player, TangibleObject* vendor);
	void packUp(CreatureObject* player, TangibleObject* vendor); // after SUI confirmation
	void redeploy(CreatureObject* player, TangibleObject* vendor);

	// Recovery of interrupted operations. Never creates objects.
	// reason: "startup" | "login" | "admin"
	bool recoverVendor(uint64 vendorID, const String& reason);
	void recoverPlayerVendors(uint64 playerID);

	// Admin support
	String describeVendor(uint64 vendorID);

private:
	bool validatePack(CreatureObject* player, TangibleObject* vendor, String& error);
	bool validateRedeploy(CreatureObject* player, TangibleObject* vendor, String& error);

	// Shared completion helpers (used by redeploy and recovery). Vendor must be locked.
	bool completeRestore(TangibleObject* vendor, VendorDataComponent* vendorData, const String& why);
	void rollbackPack(TangibleObject* vendor, VendorDataComponent* vendorData, const String& why);
	void rehideAfterFailedRestore(TangibleObject* vendor, VendorDataComponent* vendorData, const String& why);

	void logTransition(const String& what, CreatureObject* player, TangibleObject* vendor, VendorDataComponent* vendorData, int listings, uint64 destStructure = 0);

	static uint64 nextOperationId();
};

#endif /* VENDORPACKUPMANAGER_H_ */
