/*
 * VendorGuildDiscountSuiCallback.h
 */

#ifndef VENDORGUILDDISCOUNTSUICALLBACK_H_
#define VENDORGUILDDISCOUNTSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/inputbox/SuiInputBox.h"
#include "server/zone/objects/player/sui/messagebox/SuiMessageBox.h"
#include "server/zone/managers/vendor/VendorManager.h"
#include "server/zone/managers/guild/GuildManager.h"
#include "server/zone/objects/guild/GuildObject.h"
#include "server/zone/objects/tangible/components/vendor/VendorDataComponent.h"

class VendorGuildDiscountMenuSuiCallback : public SuiCallback {
public:
	VendorGuildDiscountMenuSuiCallback(ZoneServer* server) : SuiCallback(server) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (!suiBox->isListBox() || eventIndex == 1 || args->size() < 1)
			return;

		ManagedReference<SceneObject*> object = suiBox->getUsingObject().get();
		TangibleObject* vendor = object != nullptr ? cast<TangibleObject*>(object.get()) : nullptr;

		if (vendor == nullptr || !vendor->isVendor() || !VendorManager::instance()->canManageGuildDiscounts(player, vendor))
			return;

		int index = Integer::valueOf(args->get(0).toString());

		switch (index) {
		case 0:
			VendorManager::instance()->promptAddGuildDiscount(player, vendor);
			break;
		case 1:
			VendorManager::instance()->sendEditGuildDiscountsTo(player, vendor);
			break;
		case 2:
			VendorManager::instance()->sendRemoveGuildDiscountsTo(player, vendor);
			break;
		default:
			break;
		}
	}
};

class VendorGuildDiscountGuildSuiCallback : public SuiCallback {
public:
	VendorGuildDiscountGuildSuiCallback(ZoneServer* server) : SuiCallback(server) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (!suiBox->isInputBox() || eventIndex == 1 || args->size() < 1)
			return;

		ManagedReference<SceneObject*> object = suiBox->getUsingObject().get();
		TangibleObject* vendor = object != nullptr ? cast<TangibleObject*>(object.get()) : nullptr;

		if (vendor == nullptr || !vendor->isVendor() || !VendorManager::instance()->canManageGuildDiscounts(player, vendor))
			return;

		String guildAbbrev = args->get(0).toString();
		guildAbbrev.trim();

		if (guildAbbrev.isEmpty()) {
			player->sendSystemMessage("Guild abbreviation is required.");
			return;
		}

		ManagedReference<GuildManager*> guildManager = server->getGuildManager();
		ManagedReference<GuildObject*> guild = guildManager != nullptr ? guildManager->getGuildFromAbbrev(guildAbbrev) : nullptr;

		if (guild == nullptr && guildManager != nullptr)
			guild = guildManager->getGuildFromAbbrev(guildAbbrev.toUpperCase());

		if (guild == nullptr) {
			player->sendSystemMessage("No guild exists with that abbreviation.");
			return;
		}

		VendorManager::instance()->promptGuildDiscountPercent(player, vendor, guild->getObjectID());
	}
};

class VendorGuildDiscountSelectSuiCallback : public SuiCallback {
	bool removeMode;

public:
	VendorGuildDiscountSelectSuiCallback(ZoneServer* server, bool remove) : SuiCallback(server), removeMode(remove) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (!suiBox->isListBox() || eventIndex == 1 || args->size() < 1)
			return;

		ManagedReference<SceneObject*> object = suiBox->getUsingObject().get();
		TangibleObject* vendor = object != nullptr ? cast<TangibleObject*>(object.get()) : nullptr;

		if (vendor == nullptr || !vendor->isVendor() || !VendorManager::instance()->canManageGuildDiscounts(player, vendor))
			return;

		SuiListBox* listBox = cast<SuiListBox*>(suiBox);
		int index = Integer::valueOf(args->get(0).toString());

		if (index < 0 || index >= listBox->getMenuSize())
			return;

		uint64 guildID = listBox->getMenuObjectID(index);

		if (removeMode)
			VendorManager::instance()->confirmRemoveGuildDiscount(player, vendor, guildID);
		else
			VendorManager::instance()->promptGuildDiscountPercent(player, vendor, guildID);
	}
};

class VendorGuildDiscountPercentSuiCallback : public SuiCallback {
	uint64 guildID;

public:
	VendorGuildDiscountPercentSuiCallback(ZoneServer* server, uint64 guild) : SuiCallback(server), guildID(guild) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (!suiBox->isInputBox() || eventIndex == 1 || args->size() < 1)
			return;

		ManagedReference<SceneObject*> object = suiBox->getUsingObject().get();
		TangibleObject* vendor = object != nullptr ? cast<TangibleObject*>(object.get()) : nullptr;

		if (vendor == nullptr || !vendor->isVendor() || !VendorManager::instance()->canManageGuildDiscounts(player, vendor))
			return;

		int percent = 0;

		try {
			percent = Integer::valueOf(args->get(0).toString());
		} catch (Exception& e) {
			player->sendSystemMessage("Guild discounts must be between 1% and 50%.");
			return;
		}

		if (percent < VendorDataComponent::MINGUILDDISCOUNT || percent > VendorDataComponent::MAXGUILDDISCOUNT) {
			player->sendSystemMessage("Guild discounts must be between 1% and 50%.");
			return;
		}

		VendorManager::instance()->confirmGuildDiscount(player, vendor, guildID, percent);
	}
};

class VendorGuildDiscountConfirmSuiCallback : public SuiCallback {
	uint64 guildID;
	int percent;

public:
	VendorGuildDiscountConfirmSuiCallback(ZoneServer* server, uint64 guild, int discount) : SuiCallback(server), guildID(guild), percent(discount) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (!suiBox->isMessageBox() || eventIndex == 1)
			return;

		ManagedReference<SceneObject*> object = suiBox->getUsingObject().get();
		TangibleObject* vendor = object != nullptr ? cast<TangibleObject*>(object.get()) : nullptr;

		if (vendor == nullptr || !vendor->isVendor() || !VendorManager::instance()->canManageGuildDiscounts(player, vendor))
			return;

		VendorManager::instance()->setGuildDiscount(player, vendor, guildID, percent);
	}
};

class VendorGuildDiscountRemoveConfirmSuiCallback : public SuiCallback {
	uint64 guildID;

public:
	VendorGuildDiscountRemoveConfirmSuiCallback(ZoneServer* server, uint64 guild) : SuiCallback(server), guildID(guild) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (!suiBox->isMessageBox() || eventIndex == 1)
			return;

		ManagedReference<SceneObject*> object = suiBox->getUsingObject().get();
		TangibleObject* vendor = object != nullptr ? cast<TangibleObject*>(object.get()) : nullptr;

		if (vendor == nullptr || !vendor->isVendor() || !VendorManager::instance()->canManageGuildDiscounts(player, vendor))
			return;

		VendorManager::instance()->removeGuildDiscount(player, vendor, guildID);
	}
};

#endif /* VENDORGUILDDISCOUNTSUICALLBACK_H_ */
