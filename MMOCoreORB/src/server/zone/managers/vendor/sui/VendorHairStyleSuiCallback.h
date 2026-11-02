/*
 * VendorHairStyleSuiCallback.h
 */

#ifndef VENDORHAIRSTYLESUICALLBACK_H_
#define VENDORHAIRSTYLESUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/managers/vendor/VendorManager.h"

class VendorHairStyleSuiCallback : public SuiCallback {
public:
	VendorHairStyleSuiCallback(ZoneServer* server) : SuiCallback(server) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (!suiBox->isListBox() || eventIndex == 1 || args->size() < 1)
			return;

		ManagedReference<SceneObject*> object = suiBox->getUsingObject().get();
		TangibleObject* vendor = object != nullptr ? cast<TangibleObject*>(object.get()) : nullptr;

		if (vendor == nullptr || !vendor->isVendor())
			return;

		int index = Integer::valueOf(args->get(0).toString());

		VendorManager::instance()->handleVendorHairStyleSelection(player, vendor, index);
	}
};

#endif /* VENDORHAIRSTYLESUICALLBACK_H_ */
