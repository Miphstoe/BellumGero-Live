/* Curated static ship scenery for Bellum Gero World Builder. */
#ifndef WORLDBUILDERSHIPSCENERYLIBRARY_H_
#define WORLDBUILDERSHIPSCENERYLIBRARY_H_

#include "templates/manager/TemplateManager.h"

class WorldBuilderShipSceneryLibraryCallback;

class WorldBuilderShipSceneryLibrary {
private:
	friend class WorldBuilderShipSceneryLibraryCallback;
	struct Entry {
		const char* category;
		const char* name;
		const char* serverTemplate;
		float groundOffset;
	};

	inline static const Entry entries[] = {
		{ "Republic", "ARC-170", "object/static/worldbuilder/ship/republic/arc170.iff", 0.f },
		{ "Rebel", "A-Wing", "object/static/worldbuilder/ship/rebel/awing.iff", 0.f },
		{ "Rebel", "B-Wing", "object/static/worldbuilder/ship/rebel/bwing.iff", 0.f },
		{ "Separatist", "Droid Fighter", "object/static/worldbuilder/ship/separatist/droid_fighter.iff", 0.f },
		{ "Separatist", "Grievous Starship", "object/static/worldbuilder/ship/separatist/grievous_starship.iff", 0.f },
		{ "Republic", "Jedi Fighter", "object/static/worldbuilder/ship/republic/jedifighter.iff", 0.f },
		{ "Civilian", "KSE Firespray", "object/static/worldbuilder/ship/civilian/kse_firespray.iff", 0.f },
		{ "Imperial", "Lambda Shuttle", "object/static/worldbuilder/ship/imperial/lambda_shuttle.iff", 0.f },
		{ "Republic", "Naboo Starfighter", "object/static/worldbuilder/ship/republic/naboo_starfighter.iff", 0.f },
		{ "Civilian", "SoroSuub Space Yacht", "object/static/worldbuilder/ship/civilian/soorosuub_space_yacht.iff", 0.f },
		{ "Imperial", "TIE Advanced", "object/static/worldbuilder/ship/imperial/tie_advanced.iff", 0.f },
		{ "Imperial", "TIE Aggressor", "object/static/worldbuilder/ship/imperial/tie_aggressor.iff", 0.f },
		{ "Imperial", "TIE Bomber", "object/static/worldbuilder/ship/imperial/tie_bomber.iff", 0.f },
		{ "Imperial", "TIE Fighter", "object/static/worldbuilder/ship/imperial/tie_fighter.iff", 0.f },
		{ "Imperial", "TIE Interceptor", "object/static/worldbuilder/ship/imperial/tie_interceptor.iff", 0.f },
		{ "Imperial", "TIE Oppressor", "object/static/worldbuilder/ship/imperial/tie_oppressor.iff", 0.f },
		{ "Republic", "V-Wing", "object/static/worldbuilder/ship/republic/v_wing.iff", 0.f },
		{ "Rebel", "X-Wing", "object/static/worldbuilder/ship/rebel/xwing.iff", 0.f },
		{ "Rebel", "Y-Wing", "object/static/worldbuilder/ship/rebel/ywing.iff", 0.f },
		{ "Civilian", "YKL-37R", "object/static/worldbuilder/ship/civilian/ykl37r.iff", 0.f },
		{ "Civilian", "YT-1300", "object/static/worldbuilder/ship/civilian/yt1300.iff", 0.f },
		{ "Civilian", "YT-2400", "object/static/worldbuilder/ship/civilian/yt2400.iff", 0.f },
		{ "Rebel", "Z-95", "object/static/worldbuilder/ship/rebel/z95.iff", 0.f },
	};

	static bool isRegistered(const String& path) {
		TemplateManager* manager = TemplateManager::instance();
		if (manager == nullptr || manager->getTemplate(path.hashCode()) == nullptr)
			return false;
		return manager->getTemplateFile(path.hashCode()) == path;
	}

	static float getGroundOffset(const String& path) {
		for (const Entry& entry : entries)
			if (path == entry.serverTemplate) return entry.groundOffset;
		return 0.f;
	}

public:
	static void showRoot(CreatureObject* player);
	static void showCategory(CreatureObject* player, const String& category);
};

class WorldBuilderShipSceneryLibraryCallback : public SuiCallback {
	String category;
	Vector<String> actions;

public:
	WorldBuilderShipSceneryLibraryCallback(ZoneServer* server, const String& selectedCategory, const Vector<String>& menuActions)
		: SuiCallback(server), category(selectedCategory), actions(menuActions) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr || !suiBox->isListBox()) return;
		if (eventIndex == 1) {
			if (category.isEmpty()) WorldBuilderCommandUi::showMenu(player);
			else WorldBuilderShipSceneryLibrary::showRoot(player);
			return;
		}
		if (args == nullptr || args->size() < 1) return;
		int selected = -1;
		try { selected = Integer::valueOf(args->get(0).toString()); } catch (Exception& e) { return; }
		if (selected < 0 || selected >= actions.size()) return;
		String action = actions.get(selected);
		if (action == "@back") {
			if (category.isEmpty()) WorldBuilderCommandUi::showMenu(player);
			else WorldBuilderShipSceneryLibrary::showRoot(player);
			return;
		}
		if (category.isEmpty()) {
			WorldBuilderShipSceneryLibrary::showCategory(player, action);
			return;
		}
		if (!WorldBuilderShipSceneryLibrary::isRegistered(action)) {
			player->sendSystemMessage("[World Builder] ERROR: Ship scenery template is unavailable. Rebuild/deploy bg_worldbuilder.tre and restart Core3: " + action);
			WorldBuilderShipSceneryLibrary::showCategory(player, category);
			return;
		}
		String message;
		bool result = WorldBuilderManager::instance()->spawnShipScenery(player, action, 10.f,
			WorldBuilderShipSceneryLibrary::getGroundOffset(action), message);
		player->sendSystemMessage(String("[World Builder] ") + (result ? "" : "ERROR: ") + message);
		WorldBuilderShipSceneryLibrary::showCategory(player, category);
	}
};

inline void WorldBuilderShipSceneryLibrary::showRoot(CreatureObject* player) {
	if (player == nullptr || player->getPlayerObject() == nullptr) return;
	WorldBuilderManager* manager = WorldBuilderManager::instance();
	if (manager == nullptr || !manager->hasSession(player)) {
		WorldBuilderCommandUi::sendMessage(player, "World Builder Ship Scenery", "Open or create a World Builder project first.");
		return;
	}
	ManagedReference<SuiListBox*> box = new SuiListBox(player, SuiWindowType::NONE, SuiListBox::HANDLESINGLEBUTTON);
	box->setPromptTitle("World Builder Ship Scenery Library");
	box->setPromptText("Curated STATIC ground scenery only. This library never spawns object/ship/player ShipObjects. Generated wrappers require the current bg_worldbuilder.tre and a Core3 restart.");
	box->setUsingObject(player); box->setCancelButton(true, "@cancel"); box->setOkButton(true, "@ok");
	Vector<String> actions;
	box->addMenuItem("Republic", actions.size() + 1); actions.add("Republic");
	box->addMenuItem("Rebel", actions.size() + 1); actions.add("Rebel");
	box->addMenuItem("Imperial", actions.size() + 1); actions.add("Imperial");
	box->addMenuItem("Separatist", actions.size() + 1); actions.add("Separatist");
	box->addMenuItem("Civilian", actions.size() + 1); actions.add("Civilian");
	box->addMenuItem("Back to World Builder", actions.size() + 1); actions.add("@back");
	box->setCallback(new WorldBuilderShipSceneryLibraryCallback(player->getZoneServer(), "", actions));
	player->getPlayerObject()->addSuiBox(box); player->sendMessage(box->generateMessage());
}

inline void WorldBuilderShipSceneryLibrary::showCategory(CreatureObject* player, const String& category) {
	if (player == nullptr || player->getPlayerObject() == nullptr) return;
	WorldBuilderManager* manager = WorldBuilderManager::instance();
	if (manager == nullptr || !manager->hasSession(player)) {
		WorldBuilderCommandUi::sendMessage(player, "World Builder Ship Scenery", "The World Builder project is no longer open.");
		return;
	}
	ManagedReference<SuiListBox*> box = new SuiListBox(player, SuiWindowType::NONE, SuiListBox::HANDLESINGLEBUTTON);
	box->setPromptTitle("Ship Scenery - " + category);
	box->setPromptText("Select a registered STATIC template to place it 10m ahead through the normal World Builder object path. [Unavailable] wrappers require a rebuilt/deployed bg_worldbuilder.tre and restart.");
	box->setUsingObject(player); box->setCancelButton(true, "@cancel"); box->setOkButton(true, "@ok");
	Vector<String> actions;
	box->addMenuItem("Back to Ship Categories", actions.size() + 1); actions.add("@back");
	for (const Entry& entry : entries) {
		if (category != entry.category) continue;
		String path(entry.serverTemplate);
		String label(entry.name);
		if (!isRegistered(path)) label += " [Unavailable]";
		box->addMenuItem(label, actions.size() + 1); actions.add(path);
	}
	box->setCallback(new WorldBuilderShipSceneryLibraryCallback(player->getZoneServer(), category, actions));
	player->getPlayerObject()->addSuiBox(box); player->sendMessage(box->generateMessage());
}

#endif /* WORLDBUILDERSHIPSCENERYLIBRARY_H_ */
