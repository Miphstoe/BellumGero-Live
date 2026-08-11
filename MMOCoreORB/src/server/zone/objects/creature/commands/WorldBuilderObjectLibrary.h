/*
 * WorldBuilderObjectLibrary.h
 *
 * Bellum Gero World Builder V1.5 object-library browser.
 *
 * The library is generated at runtime from the server's registered
 * object/static/ tree templates. No separate hand-maintained asset list is
 * required, and newly registered Bellum Gero static templates automatically
 * become available after the next server restart.
 */

#ifndef WORLDBUILDEROBJECTLIBRARY_H_
#define WORLDBUILDEROBJECTLIBRARY_H_

#include "templates/manager/TemplateManager.h"
#include "templates/manager/TemplateCRCMap.h"

#include <algorithm>
#include <cctype>
#include <map>
#include <string>
#include <vector>

class WorldBuilderObjectLibraryRootSuiCallback;
class WorldBuilderObjectLibraryListSuiCallback;
class WorldBuilderObjectLibrarySearchSuiCallback;

class WorldBuilderObjectLibrary {
private:
	static const int PAGE_SIZE = 60;

	static std::string toLower(const std::string& value) {
		std::string result = value;
		for (size_t i = 0; i < result.size(); ++i)
			result[i] = static_cast<char>(std::tolower(static_cast<unsigned char>(result[i])));
		return result;
	}

	static std::string humanize(const std::string& value) {
		std::string result;
		bool capitalize = true;

		for (size_t i = 0; i < value.size(); ++i) {
			char c = value[i];
			if (c == '_' || c == '-' || c == '/') {
				if (!result.empty() && result[result.size() - 1] != ' ')
					result += ' ';
				capitalize = true;
				continue;
			}

			if (capitalize && c >= 'a' && c <= 'z')
				c = static_cast<char>(c - 'a' + 'A');

			result += c;
			capitalize = (c == ' ');
		}

		while (!result.empty() && result[result.size() - 1] == ' ')
			result.erase(result.size() - 1);

		return result;
	}

	static std::string categoryFromPath(const std::string& path) {
		static const std::string prefix = "object/static/";
		if (path.compare(0, prefix.size(), prefix) != 0)
			return "";

		size_t start = prefix.size();
		size_t slash = path.find('/', start);
		if (slash == std::string::npos || slash <= start)
			return "other";

		return path.substr(start, slash - start);
	}

	static std::string displayNameFromPath(const std::string& path, bool includeCategory) {
		size_t slash = path.find_last_of('/');
		std::string fileName = slash == std::string::npos ? path : path.substr(slash + 1);
		if (fileName.size() > 4 && fileName.substr(fileName.size() - 4) == ".iff")
			fileName.erase(fileName.size() - 4);

		std::string label = humanize(fileName);

		static const std::string prefix = "object/static/";
		if (path.compare(0, prefix.size(), prefix) == 0 && slash != std::string::npos && slash > prefix.size()) {
			std::string folder = path.substr(prefix.size(), slash - prefix.size());
			if (!includeCategory) {
				size_t categorySlash = folder.find('/');
				if (categorySlash == std::string::npos)
					folder.clear();
				else
					folder = folder.substr(categorySlash + 1);
			}

			if (!folder.empty())
				label += "  [" + folder + "]";
		}

		return label;
	}

	static void collectStaticTemplatePaths(std::vector<std::string>& paths) {
		paths.clear();

		TemplateManager* templateManager = TemplateManager::instance();
		if (templateManager == nullptr)
			return;

		TemplateCRCMap& crcMap = templateManager->getTemplateCRCMap();
		auto iterator = crcMap.iterator();

		while (iterator.hasNext()) {
			uint32 crc = iterator.getNextKey();
			const String& templateFile = templateManager->getTemplateFile(crc);
			if (templateFile.isEmpty())
				continue;

			std::string path(templateFile.toCharArray());
			if (path.compare(0, 14, "object/static/") != 0)
				continue;
			if (path.size() < 4 || path.substr(path.size() - 4) != ".iff")
				continue;

			paths.push_back(path);
		}

		std::sort(paths.begin(), paths.end());
		paths.erase(std::unique(paths.begin(), paths.end()), paths.end());
	}

	static void collectMatches(const String& category, const String& query,
		Vector<String>& templatePaths, Vector<String>& labels) {
		templatePaths.removeAll();
		labels.removeAll();

		std::vector<std::string> paths;
		collectStaticTemplatePaths(paths);

		std::string categoryFilter = toLower(std::string(category.toCharArray()));
		std::string queryFilter = toLower(std::string(query.toCharArray()));
		bool includeCategoryInLabel = categoryFilter.empty() || categoryFilter == "all";

		std::vector<std::pair<std::string, std::string> > matches;
		for (size_t i = 0; i < paths.size(); ++i) {
			const std::string& path = paths[i];
			std::string pathCategory = toLower(categoryFromPath(path));

			if (!categoryFilter.empty() && categoryFilter != "all" && pathCategory != categoryFilter)
				continue;

			std::string label = displayNameFromPath(path, includeCategoryInLabel);
			if (!queryFilter.empty()) {
				std::string searchable = toLower(path + " " + label);
				if (searchable.find(queryFilter) == std::string::npos)
					continue;
			}

			matches.push_back(std::make_pair(label, path));
		}

		std::sort(matches.begin(), matches.end(), [](const std::pair<std::string, std::string>& a,
			const std::pair<std::string, std::string>& b) {
				if (a.first == b.first)
					return a.second < b.second;
				return a.first < b.first;
			});

		for (size_t i = 0; i < matches.size(); ++i) {
			labels.add(String(matches[i].first.c_str()));
			templatePaths.add(String(matches[i].second.c_str()));
		}
	}

public:
	static void showRoot(CreatureObject* player);
	static void showSearchInput(CreatureObject* player);
	static void showTemplateList(CreatureObject* player, const String& category, const String& query, int page);
};

class WorldBuilderObjectLibraryRootSuiCallback : public SuiCallback {
	Vector<String> actions;

public:
	WorldBuilderObjectLibraryRootSuiCallback(ZoneServer* server, const Vector<String>& menuActions)
		: SuiCallback(server), actions(menuActions) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr || !suiBox->isListBox())
			return;

		if (eventIndex == 1) {
			WorldBuilderCommandUi::showMenu(player);
			return;
		}

		if (args == nullptr || args->size() < 1)
			return;

		int selectedIndex = -1;
		try {
			selectedIndex = Integer::valueOf(args->get(0).toString());
		} catch (Exception& e) {
			return;
		}

		if (selectedIndex < 0 || selectedIndex >= actions.size())
			return;

		String action = actions.get(selectedIndex);
		if (action == "@search") {
			WorldBuilderObjectLibrary::showSearchInput(player);
		} else if (action == "@all") {
			WorldBuilderObjectLibrary::showTemplateList(player, "all", "", 0);
		} else if (action == "@back") {
			WorldBuilderCommandUi::showMenu(player);
		} else {
			WorldBuilderObjectLibrary::showTemplateList(player, action, "", 0);
		}
	}
};

class WorldBuilderObjectLibraryListSuiCallback : public SuiCallback {
	String category;
	String query;
	int page;
	Vector<String> actions;

public:
	WorldBuilderObjectLibraryListSuiCallback(ZoneServer* server, const String& categoryName,
		const String& searchQuery, int pageNumber, const Vector<String>& menuActions)
		: SuiCallback(server), category(categoryName), query(searchQuery), page(pageNumber), actions(menuActions) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr || !suiBox->isListBox())
			return;

		if (eventIndex == 1) {
			WorldBuilderObjectLibrary::showRoot(player);
			return;
		}

		if (args == nullptr || args->size() < 1)
			return;

		int selectedIndex = -1;
		try {
			selectedIndex = Integer::valueOf(args->get(0).toString());
		} catch (Exception& e) {
			return;
		}

		if (selectedIndex < 0 || selectedIndex >= actions.size())
			return;

		String action = actions.get(selectedIndex);
		if (action == "@root") {
			WorldBuilderObjectLibrary::showRoot(player);
			return;
		}
		if (action == "@search") {
			WorldBuilderObjectLibrary::showSearchInput(player);
			return;
		}
		if (action == "@prev") {
			WorldBuilderObjectLibrary::showTemplateList(player, category, query, page - 1);
			return;
		}
		if (action == "@next") {
			WorldBuilderObjectLibrary::showTemplateList(player, category, query, page + 1);
			return;
		}

		String message;
		bool result = WorldBuilderManager::instance()->spawnTemplate(player, action, 3.0f, message);
		player->sendSystemMessage(String("[World Builder] ") + (result ? "" : "ERROR: ") + message);

		// Keep the developer in the same browser page so several related assets can
		// be tried quickly. The newly spawned object is selected and Undo remains
		// available through the normal World Builder workflow.
		WorldBuilderObjectLibrary::showTemplateList(player, category, query, page);
	}
};

class WorldBuilderObjectLibrarySearchSuiCallback : public SuiCallback {
public:
	WorldBuilderObjectLibrarySearchSuiCallback(ZoneServer* server) : SuiCallback(server) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr || !suiBox->isInputBox())
			return;

		if (eventIndex == 1) {
			WorldBuilderObjectLibrary::showRoot(player);
			return;
		}

		if (args == nullptr || args->size() < 1) {
			WorldBuilderObjectLibrary::showRoot(player);
			return;
		}

		String query = args->get(0).toString().trim();
		if (query.isEmpty()) {
			WorldBuilderObjectLibrary::showRoot(player);
			return;
		}

		WorldBuilderObjectLibrary::showTemplateList(player, "all", query, 0);
	}
};

inline void WorldBuilderObjectLibrary::showRoot(CreatureObject* player) {
	if (player == nullptr || player->getPlayerObject() == nullptr)
		return;

	WorldBuilderManager* manager = WorldBuilderManager::instance();
	if (manager == nullptr || !manager->hasSession(player)) {
		WorldBuilderCommandUi::sendMessage(player, "World Builder Object Library",
			"Open or create a World Builder project before browsing and spawning library objects.");
		return;
	}

	std::vector<std::string> paths;
	collectStaticTemplatePaths(paths);

	std::map<std::string, int> categoryCounts;
	for (size_t i = 0; i < paths.size(); ++i) {
		std::string category = categoryFromPath(paths[i]);
		if (category.empty())
			category = "other";
		++categoryCounts[category];
	}

	ManagedReference<SuiListBox*> box = new SuiListBox(player, SuiWindowType::NONE, SuiListBox::HANDLESINGLEBUTTON);
	box->setPromptTitle("World Builder Object Library");

	StringBuffer prompt;
	prompt << "Browse " << static_cast<int>(paths.size())
		   << " registered static templates. Categories are generated automatically from the server's object/static library. "
		   << "Selecting an object spawns it 3m in front of you. Manual template entry remains available from the main menu for advanced/non-static cases.";
	box->setPromptText(prompt.toString());
	box->setUsingObject(player);
	box->setCancelButton(true, "@cancel");
	box->setOkButton(true, "@ok");

	Vector<String> actions;
	box->addMenuItem("Search All Static Objects...", actions.size() + 1);
	actions.add("@search");

	box->addMenuItem("All Static Objects (" + String::valueOf(static_cast<int>(paths.size())) + ")", actions.size() + 1);
	actions.add("@all");

	for (std::map<std::string, int>::const_iterator it = categoryCounts.begin(); it != categoryCounts.end(); ++it) {
		std::string label = humanize(it->first) + " (" + std::to_string(it->second) + ")";
		box->addMenuItem(String(label.c_str()), actions.size() + 1);
		actions.add(String(it->first.c_str()));
	}

	box->addMenuItem("Back to World Builder", actions.size() + 1);
	actions.add("@back");

	box->setCallback(new WorldBuilderObjectLibraryRootSuiCallback(player->getZoneServer(), actions));
	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

inline void WorldBuilderObjectLibrary::showSearchInput(CreatureObject* player) {
	if (player == nullptr || player->getPlayerObject() == nullptr)
		return;

	ManagedReference<SuiInputBox*> box = new SuiInputBox(player, SuiWindowType::NONE);
	box->setPromptTitle("Search World Builder Object Library");
	box->setPromptText("Enter part of an object name or template path. Examples: rock, cave wall, imperial, tree, xwing.");
	box->setMaxInputSize(80);
	box->setUsingObject(player);
	box->setCallback(new WorldBuilderObjectLibrarySearchSuiCallback(player->getZoneServer()));
	box->setForceCloseDistance(-1);
	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

inline void WorldBuilderObjectLibrary::showTemplateList(CreatureObject* player, const String& category, const String& query, int page) {
	if (player == nullptr || player->getPlayerObject() == nullptr)
		return;

	WorldBuilderManager* manager = WorldBuilderManager::instance();
	if (manager == nullptr || !manager->hasSession(player)) {
		WorldBuilderCommandUi::sendMessage(player, "World Builder Object Library",
			"The World Builder project is no longer open.");
		return;
	}

	Vector<String> paths;
	Vector<String> labels;
	collectMatches(category, query, paths, labels);

	int total = paths.size();
	if (total == 0) {
		StringBuffer text;
		if (!query.isEmpty())
			text << "No registered static templates matched '" << query << "'.";
		else
			text << "No registered static templates were found in category '" << category << "'.";
		WorldBuilderCommandUi::sendMessage(player, "World Builder Object Library", text.toString());
		return;
	}

	int maxPage = (total - 1) / PAGE_SIZE;
	if (page < 0)
		page = 0;
	if (page > maxPage)
		page = maxPage;

	int start = page * PAGE_SIZE;
	int end = start + PAGE_SIZE;
	if (end > total)
		end = total;

	ManagedReference<SuiListBox*> box = new SuiListBox(player, SuiWindowType::NONE, SuiListBox::HANDLESINGLEBUTTON);
	String categoryLabel;
	if (category == "all")
		categoryLabel = "All Static Objects";
	else
		categoryLabel = String(humanize(std::string(category.toCharArray())).c_str());
	box->setPromptTitle(query.isEmpty() ? "Object Library - " + categoryLabel : "Object Library Search");

	StringBuffer prompt;
	if (!query.isEmpty())
		prompt << "Search: '" << query << "' | ";
	else
		prompt << "Category: " << categoryLabel << " | ";
	prompt << "Showing " << (start + 1) << "-" << end << " of " << total
		   << ". Select an object to spawn it 3m in front of you. The browser stays on this page after spawning so you can quickly try related assets.";
	box->setPromptText(prompt.toString());
	box->setUsingObject(player);
	box->setCancelButton(true, "@cancel");
	box->setOkButton(true, "@ok");

	Vector<String> actions;
	box->addMenuItem("Back to Library Categories", actions.size() + 1);
	actions.add("@root");

	if (!query.isEmpty()) {
		box->addMenuItem("Search Again...", actions.size() + 1);
		actions.add("@search");
	}

	if (page > 0) {
		box->addMenuItem("< Previous Page", actions.size() + 1);
		actions.add("@prev");
	}

	for (int i = start; i < end; ++i) {
		box->addMenuItem(labels.get(i), actions.size() + 1);
		actions.add(paths.get(i));
	}

	if (page < maxPage) {
		box->addMenuItem("Next Page >", actions.size() + 1);
		actions.add("@next");
	}

	box->setCallback(new WorldBuilderObjectLibraryListSuiCallback(player->getZoneServer(), category, query, page, actions));
	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

#endif /* WORLDBUILDEROBJECTLIBRARY_H_ */
