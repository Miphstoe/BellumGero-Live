/*
 * CreateMannequinSuiCallback.h
 *
 * Bellum Gero - Persistent Player Display Mannequin (Phase 2)
 *
 * "Create Mannequin" from the Structure Management terminal: dispenses the chosen
 * mannequin deed into the requesting player's inventory. The deed itself is then
 * deployed via MannequinDeedMenuComponent (which re-checks structure permission).
 *
 * The species/gender table is the single source of truth for both the SUI list order
 * and the index->deed resolution.
 */

#ifndef CREATEMANNEQUINSUICALLBACK_H_
#define CREATEMANNEQUINSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/ZoneServer.h"

class MannequinSpecies {
public:
	// { display name , deed template }  -- order defines the SUI list index
	static const int COUNT = 16;

	static const char* const entries[COUNT][2];

	static void fillListBox(SuiListBox* box) {
		for (int i = 0; i < COUNT; ++i)
			box->addMenuItem(entries[i][0]);
	}

	// Returns the deed template for a list index, or empty string if out of range.
	static String deedTemplateForIndex(int index) {
		if (index < 0 || index >= COUNT)
			return "";

		return entries[index][1];
	}
};

inline const char* const MannequinSpecies::entries[MannequinSpecies::COUNT][2] = {
	{ "Human Male Mannequin",          "object/tangible/deed/mannequin/mannequin_human_male_deed.iff" },
	{ "Human Female Mannequin",        "object/tangible/deed/mannequin/mannequin_human_female_deed.iff" },
	{ "Bothan Male Mannequin",         "object/tangible/deed/mannequin/mannequin_bothan_male_deed.iff" },
	{ "Bothan Female Mannequin",       "object/tangible/deed/mannequin/mannequin_bothan_female_deed.iff" },
	{ "Mon Calamari Male Mannequin",   "object/tangible/deed/mannequin/mannequin_moncal_male_deed.iff" },
	{ "Mon Calamari Female Mannequin", "object/tangible/deed/mannequin/mannequin_moncal_female_deed.iff" },
	{ "Rodian Male Mannequin",         "object/tangible/deed/mannequin/mannequin_rodian_male_deed.iff" },
	{ "Rodian Female Mannequin",       "object/tangible/deed/mannequin/mannequin_rodian_female_deed.iff" },
	{ "Trandoshan Male Mannequin",     "object/tangible/deed/mannequin/mannequin_trandoshan_male_deed.iff" },
	{ "Trandoshan Female Mannequin",   "object/tangible/deed/mannequin/mannequin_trandoshan_female_deed.iff" },
	{ "Twi'lek Male Mannequin",        "object/tangible/deed/mannequin/mannequin_twilek_male_deed.iff" },
	{ "Twi'lek Female Mannequin",      "object/tangible/deed/mannequin/mannequin_twilek_female_deed.iff" },
	{ "Zabrak Male Mannequin",         "object/tangible/deed/mannequin/mannequin_zabrak_male_deed.iff" },
	{ "Zabrak Female Mannequin",       "object/tangible/deed/mannequin/mannequin_zabrak_female_deed.iff" },
	{ "Wookiee Male Mannequin",        "object/tangible/deed/mannequin/mannequin_wookiee_male_deed.iff" },
	{ "Wookiee Female Mannequin",      "object/tangible/deed/mannequin/mannequin_wookiee_female_deed.iff" }
};

class CreateMannequinSuiCallback : public SuiCallback {
public:
	CreateMannequinSuiCallback(ZoneServer* serv) : SuiCallback(serv) {
	}

	void run(CreatureObject* player, SuiBox* sui, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || sui == nullptr || eventIndex == 1)
			return;

		if (args == nullptr || args->size() < 1)
			return;

		SuiListBox* listBox = cast<SuiListBox*>(sui);

		if (listBox == nullptr)
			return;

		int index = Integer::valueOf(args->get(0).toString());

		String deedTemplate = MannequinSpecies::deedTemplateForIndex(index);

		if (deedTemplate.isEmpty())
			return;

		auto zoneServer = player->getZoneServer();

		if (zoneServer == nullptr)
			return;

		ManagedReference<SceneObject*> inventory = player->getInventory();

		if (inventory == nullptr || inventory->isContainerFullRecursive()) {
			player->sendSystemMessage("Your inventory is full, so the mannequin deed could not be created.");
			return;
		}

		Locker plocker(player);

		ManagedReference<SceneObject*> deed = zoneServer->createObject(deedTemplate.hashCode(), 1);

		if (deed == nullptr) {
			player->sendSystemMessage("The mannequin deed could not be created.");
			return;
		}

		Locker dlocker(deed, player);

		deed->createChildObjects();

		if (!inventory->transferObject(deed, -1, true)) {
			deed->destroyObjectFromDatabase(true);
			player->sendSystemMessage("The mannequin deed could not be placed in your inventory.");
			return;
		}

		inventory->broadcastObject(deed, true);

		player->info(true) << "CREATE_MANNEQUIN_DEED player=" << player->getObjectID()
			<< " deed=" << deed->getObjectID() << " template=" << deedTemplate;

		player->sendSystemMessage("A mannequin deed has been placed in your inventory. Use it while standing inside your structure to deploy the mannequin.");
	}
};

#endif /* CREATEMANNEQUINSUICALLBACK_H_ */
