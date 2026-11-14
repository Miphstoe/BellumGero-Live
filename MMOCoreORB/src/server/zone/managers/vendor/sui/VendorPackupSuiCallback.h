/*
 * VendorPackupSuiCallback.h
 * Bellum Gero Vendor Packup: confirmation dialog result.
 */

#ifndef VENDORPACKUPSUICALLBACK_H_
#define VENDORPACKUPSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/managers/vendor/VendorPackupManager.h"

class VendorPackupSuiCallback : public SuiCallback {
public:
	VendorPackupSuiCallback(ZoneServer* server) : SuiCallback(server) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		if (!suiBox->isMessageBox() || cancelPressed || player == nullptr)
			return;

		// Never trust the client: the vendor comes from the server-side SUI record and is re-validated.
		ManagedReference<SceneObject*> object = suiBox->getUsingObject().get();

		if (object == nullptr || !object->isVendor())
			return;

		TangibleObject* vendor = cast<TangibleObject*>(object.get());

		if (vendor == nullptr)
			return;

		VendorPackupManager::instance()->packUp(player, vendor);
	}
};

#endif /* VENDORPACKUPSUICALLBACK_H_ */
