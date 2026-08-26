/*
 * WorldBuilderExteriorBuildingLibrary.h
 *
 * Bellum Gero World Builder V1.9.7.1 structure-library browser.
 *
 * The library is generated at runtime from registered object/building/
 * SERVER templates. Only templates that pass the same structural safety
 * expectations used by World Builder (registered SharedBuilding template,
 * matching shared/client identity, and a usable portal layout with interior
 * cells) are shown. Project-generated object/building/worldbuilder/ templates
 * are intentionally excluded so published clones are not used as new sources.
 *
 * V1.9.7.1 builds this catalog once per Core3 process and checks the loaded TRE
 * index before attempting to load each portal layout. Registered templates whose
 * POB is absent are skipped silently instead of producing TreeArchive warnings.
 */

#ifndef WORLDBUILDEREXTERIORBUILDINGLIBRARY_H_
#define WORLDBUILDEREXTERIORBUILDINGLIBRARY_H_

#include "templates/manager/TemplateManager.h"
#include "templates/manager/TemplateCRCMap.h"
#include "templates/manager/DataArchiveStore.h"
#include "tre3/TreeArchive.h"
#include "templates/SharedObjectTemplate.h"
#include "templates/building/SharedBuildingObjectTemplate.h"
#include "templates/appearance/PortalLayout.h"
#include "WorldBuilderExteriorBuildingPreview.h"

#include <algorithm>
#include <cctype>
#include <map>
#include <set>
#include <string>
#include <vector>

class WorldBuilderExteriorBuildingLibraryRootSuiCallback;
class WorldBuilderExteriorBuildingLibraryListSuiCallback;
class WorldBuilderExteriorBuildingLibrarySearchSuiCallback;
class WorldBuilderExteriorBuildingLibraryActionSuiCallback;

class WorldBuilderExteriorBuildingLibrary {
private:
	static const int PAGE_SIZE = 60;

	struct ExteriorBuildingEntry {
		std::string path;
		std::string label;
		std::string category;
		int cellCount;
		bool travelReady;
	};

	static bool isTravelReady(const SharedObjectTemplate* data) {
		bool terminal=false, collector=false, shuttle=false;
		for (int i=0; data != nullptr && i<data->getChildObjectsSize(); ++i) {
			const ChildObject* child=data->getChildObject(i);
			if(child==nullptr) continue;
			String path=child->getTemplateFile();
			terminal=terminal||path=="object/tangible/terminal/terminal_travel.iff";
			collector=collector||path=="object/tangible/travel/ticket_collector/ticket_collector.iff";
			shuttle=shuttle||path=="object/creature/npc/theme_park/player_shuttle.iff"||path=="object/mobile/player_transport.iff";
		}
		return terminal&&collector&&shuttle;
	}

	enum CompatibilityResult {
		NOT_A_LIBRARY_CANDIDATE = 0,
		COMPATIBLE_EXTERIOR = 1,
		INCOMPATIBLE_EXTERIOR = 2,
		MISSING_PORTAL_ASSET = 3
	};

	struct LibraryCatalog {
		std::vector<ExteriorBuildingEntry> entries;
		int skippedMissingPortalAssets;
		int skippedIncompatibleStructures;

		LibraryCatalog() : skippedMissingPortalAssets(0), skippedIncompatibleStructures(0) {
		}
	};

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
		static const std::string prefix = "object/building/";
		if (path.compare(0, prefix.size(), prefix) != 0)
			return "";

		size_t start = prefix.size();
		size_t slash = path.find('/', start);
		if (slash == std::string::npos || slash <= start)
			return "other";

		return path.substr(start, slash - start);
	}

	static String deriveSharedTemplate(const String& serverTemplate) {
		int slash = serverTemplate.lastIndexOf("/");
		if (slash < 0)
			return serverTemplate;

		String directory = serverTemplate.subString(0, slash + 1);
		String filename = serverTemplate.subString(slash + 1);
		if (filename.beginsWith("shared_"))
			return serverTemplate;

		return directory + "shared_" + filename;
	}

	static bool archiveContainsFile(const String& path) {
		if (path.isEmpty())
			return false;

		DataArchiveStore* archiveStore = DataArchiveStore::instance();
		if (archiveStore == nullptr)
			return false;

		const TreeArchive* archive = archiveStore->getTreeArchive();
		if (archive == nullptr)
			return false;

		int slash = path.lastIndexOf("/");
		if (slash <= 0 || slash >= path.length() - 1)
			return false;

		String directory = path.subString(0, slash);
		String fileName = path.subString(slash + 1, path.length());
		const TreeDirectory* treeDirectory = archive->getTreeDirectory(directory);

		return treeDirectory != nullptr && treeDirectory->find(fileName) >= 0;
	}

	static CompatibilityResult inspectCompatibleTemplate(const std::string& path, int& cellCount) {
		cellCount = 0;

		static const std::string prefix = "object/building/";
		static const std::string generatedPrefix = "object/building/worldbuilder/";

		if (path.compare(0, prefix.size(), prefix) != 0)
			return NOT_A_LIBRARY_CANDIDATE;
		if (path.compare(0, generatedPrefix.size(), generatedPrefix) == 0)
			return NOT_A_LIBRARY_CANDIDATE;
		if (path.size() < 4 || path.substr(path.size() - 4) != ".iff")
			return NOT_A_LIBRARY_CANDIDATE;

		size_t slash = path.find_last_of('/');
		std::string filename = slash == std::string::npos ? path : path.substr(slash + 1);
		if (filename.compare(0, 7, "shared_") == 0)
			return NOT_A_LIBRARY_CANDIDATE;

		TemplateManager* templateManager = TemplateManager::instance();
		if (templateManager == nullptr)
			return INCOMPATIBLE_EXTERIOR;

		String serverTemplate(path.c_str());
		Reference<SharedObjectTemplate*> templateData = templateManager->getTemplate(serverTemplate.hashCode());
		if (templateData == nullptr || !templateData->isSharedBuildingObjectTemplate())
			return NOT_A_LIBRARY_CANDIDATE;

		SharedBuildingObjectTemplate* buildingTemplate = static_cast<SharedBuildingObjectTemplate*>(templateData.get());
		if (buildingTemplate == nullptr)
			return INCOMPATIBLE_EXTERIOR;

		String registeredPath = buildingTemplate->getFullTemplateString();
		if (!registeredPath.isEmpty() && registeredPath != serverTemplate)
			return INCOMPATIBLE_EXTERIOR;

		String expectedShared = deriveSharedTemplate(serverTemplate);
		String clientTemplate = buildingTemplate->getClientTemplateFileName();
		if (!clientTemplate.isEmpty() && clientTemplate != expectedShared)
			return INCOMPATIBLE_EXTERIOR;

		const PortalLayout* portalLayout = buildingTemplate->getPortalLayout();
		if (portalLayout != nullptr && portalLayout->getCellTotalNumber() > 0)
			return INCOMPATIBLE_EXTERIOR;
		return COMPATIBLE_EXTERIOR;
	}

	static std::string displayNameFromPath(const std::string& path, int cellCount, bool includeCategory) {
		size_t slash = path.find_last_of('/');
		std::string fileName = slash == std::string::npos ? path : path.substr(slash + 1);
		if (fileName.size() > 4 && fileName.substr(fileName.size() - 4) == ".iff")
			fileName.erase(fileName.size() - 4);

		std::string label = humanize(fileName);

		static const std::string prefix = "object/building/";
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

		label += "  | Cell-less";
		return label;
	}

	static LibraryCatalog buildCatalog() {
		LibraryCatalog catalog;

		TemplateManager* templateManager = TemplateManager::instance();
		if (templateManager == nullptr)
			return catalog;

		TemplateCRCMap& crcMap = templateManager->getTemplateCRCMap();
		auto iterator = crcMap.iterator();
		std::set<std::string> seenPaths;

		while (iterator.hasNext()) {
			uint32 crc = iterator.getNextKey();
			const String& templateFile = templateManager->getTemplateFile(crc);
			if (templateFile.isEmpty())
				continue;

			std::string path(templateFile.toCharArray());
			if (seenPaths.find(path) != seenPaths.end())
				continue;
			seenPaths.insert(path);

			int cellCount = 0;
			CompatibilityResult result = inspectCompatibleTemplate(path, cellCount);
			if (result == MISSING_PORTAL_ASSET) {
				++catalog.skippedMissingPortalAssets;
				continue;
			}
			if (result == INCOMPATIBLE_EXTERIOR) {
				++catalog.skippedIncompatibleStructures;
				continue;
			}
			if (result != COMPATIBLE_EXTERIOR)
				continue;

			ExteriorBuildingEntry entry;
			entry.path = path;
			entry.category = categoryFromPath(path);
			if (entry.category.empty())
				entry.category = "other";
			entry.cellCount = cellCount;
			Reference<SharedObjectTemplate*> registered = TemplateManager::instance()->getTemplate(String(path.c_str()).hashCode());
			entry.travelReady = isTravelReady(registered);
			entry.label = displayNameFromPath(path, cellCount, true);
			if (entry.travelReady) entry.label += "  [Travel Ready]";
			catalog.entries.push_back(entry);
		}

		std::sort(catalog.entries.begin(), catalog.entries.end(), [](const ExteriorBuildingEntry& a, const ExteriorBuildingEntry& b) {
			if (a.label == b.label)
				return a.path < b.path;
			return a.label < b.label;
		});

		return catalog;
	}

	static const LibraryCatalog& getCatalog() {
		// Core3's object-template registry and TRE set are stable for the life of a
		// process. Build once, then make every category/search/action view read-only.
		static const LibraryCatalog catalog = buildCatalog();
		return catalog;
	}

	static const ExteriorBuildingEntry* findCatalogEntry(const String& templatePath) {
		std::string wanted(templatePath.toCharArray());
		const std::vector<ExteriorBuildingEntry>& entries = getCatalog().entries;

		for (size_t i = 0; i < entries.size(); ++i) {
			if (entries[i].path == wanted)
				return &entries[i];
		}

		return nullptr;
	}


	static void collectMatches(const String& category, const String& query,
		Vector<String>& templatePaths, Vector<String>& labels) {
		templatePaths.removeAll();
		labels.removeAll();

		const std::vector<ExteriorBuildingEntry>& entries = getCatalog().entries;

		std::string categoryFilter = toLower(std::string(category.toCharArray()));
		std::string queryFilter = toLower(std::string(query.toCharArray()));
		bool includeCategoryInLabel = categoryFilter.empty() || categoryFilter == "all";

		std::vector<std::pair<std::string, std::string> > matches;
		for (size_t i = 0; i < entries.size(); ++i) {
			const ExteriorBuildingEntry& entry = entries[i];
			if (!categoryFilter.empty() && categoryFilter != "all" && toLower(entry.category) != categoryFilter)
				continue;

			std::string label = displayNameFromPath(entry.path, entry.cellCount, includeCategoryInLabel);
			if (entry.travelReady) label += "  [Travel Ready]";
			if (!queryFilter.empty()) {
				std::string searchable = toLower(entry.path + " " + label + " " + entry.category);
				if (searchable.find(queryFilter) == std::string::npos)
					continue;
			}

			matches.push_back(std::make_pair(label, entry.path));
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

	static int getCellCount(const String& templatePath) {
		const ExteriorBuildingEntry* entry = findCatalogEntry(templatePath);
		return entry == nullptr ? 0 : entry->cellCount;
	}

	static String displayNameForTemplate(const String& templatePath) {
		const ExteriorBuildingEntry* entry = findCatalogEntry(templatePath);
		if (entry == nullptr)
			return templatePath;
		return String(entry->label.c_str());
	}

public:
	static void showRoot(CreatureObject* player);
	static void showSearchInput(CreatureObject* player);
	static void showTemplateList(CreatureObject* player, const String& category, const String& query, int page);
	static void showStructureActions(CreatureObject* player, const String& templatePath,
		const String& category, const String& query, int page);
};

class WorldBuilderExteriorBuildingLibraryRootSuiCallback : public SuiCallback {
	Vector<String> actions;

public:
	WorldBuilderExteriorBuildingLibraryRootSuiCallback(ZoneServer* server, const Vector<String>& menuActions)
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
			WorldBuilderExteriorBuildingLibrary::showSearchInput(player);
		} else if (action == "@all") {
			WorldBuilderExteriorBuildingLibrary::showTemplateList(player, "all", "", 0);
		} else if (action == "@back") {
			WorldBuilderCommandUi::showMenu(player);
		} else {
			WorldBuilderExteriorBuildingLibrary::showTemplateList(player, action, "", 0);
		}
	}
};

class WorldBuilderExteriorBuildingLibraryListSuiCallback : public SuiCallback {
	String category;
	String query;
	int page;
	Vector<String> actions;

public:
	WorldBuilderExteriorBuildingLibraryListSuiCallback(ZoneServer* server, const String& categoryName,
		const String& searchQuery, int pageNumber, const Vector<String>& menuActions)
		: SuiCallback(server), category(categoryName), query(searchQuery), page(pageNumber), actions(menuActions) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr || !suiBox->isListBox())
			return;

		if (eventIndex == 1) {
			WorldBuilderExteriorBuildingLibrary::showRoot(player);
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
			WorldBuilderExteriorBuildingLibrary::showRoot(player);
			return;
		}
		if (action == "@search") {
			WorldBuilderExteriorBuildingLibrary::showSearchInput(player);
			return;
		}
		if (action == "@prev") {
			WorldBuilderExteriorBuildingLibrary::showTemplateList(player, category, query, page - 1);
			return;
		}
		if (action == "@next") {
			WorldBuilderExteriorBuildingLibrary::showTemplateList(player, category, query, page + 1);
			return;
		}

		WorldBuilderExteriorBuildingLibrary::showStructureActions(player, action, category, query, page);
	}
};

class WorldBuilderExteriorBuildingLibrarySearchSuiCallback : public SuiCallback {
public:
	WorldBuilderExteriorBuildingLibrarySearchSuiCallback(ZoneServer* server) : SuiCallback(server) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr || !suiBox->isInputBox())
			return;

		if (eventIndex == 1) {
			WorldBuilderExteriorBuildingLibrary::showRoot(player);
			return;
		}

		if (args == nullptr || args->size() < 1) {
			WorldBuilderExteriorBuildingLibrary::showRoot(player);
			return;
		}

		String query = args->get(0).toString().trim();
		if (query.isEmpty()) {
			WorldBuilderExteriorBuildingLibrary::showRoot(player);
			return;
		}

		WorldBuilderExteriorBuildingLibrary::showTemplateList(player, "all", query, 0);
	}
};

class WorldBuilderExteriorBuildingLibraryActionSuiCallback : public SuiCallback {
	String templatePath;
	String category;
	String query;
	int page;
	Vector<String> actions;

public:
	WorldBuilderExteriorBuildingLibraryActionSuiCallback(ZoneServer* server, const String& selectedTemplate,
		const String& categoryName, const String& searchQuery, int pageNumber, const Vector<String>& menuActions)
		: SuiCallback(server), templatePath(selectedTemplate), category(categoryName), query(searchQuery),
		  page(pageNumber), actions(menuActions) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr || !suiBox->isListBox())
			return;

		if (eventIndex == 1) {
			WorldBuilderExteriorBuildingLibrary::showTemplateList(player, category, query, page);
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
		if (action == "@back") {
			WorldBuilderExteriorBuildingLibrary::showTemplateList(player, category, query, page);
			return;
		}

		String message;
		bool result = false;

		if (action == "@preview") {
			result = WorldBuilderExteriorBuildingPreview::spawn(player, templatePath, 15.0f, message);
			player->sendSystemMessage(String("[World Builder] ") + (result ? "" : "ERROR: ") + message);
			WorldBuilderExteriorBuildingLibrary::showStructureActions(player, templatePath, category, query, page);
			return;
		}

		if (action == "@clear") {
			result = WorldBuilderExteriorBuildingPreview::clear(player, message);
			player->sendSystemMessage(String("[World Builder] ") + (result ? "" : "ERROR: ") + message);
			WorldBuilderExteriorBuildingLibrary::showStructureActions(player, templatePath, category, query, page);
			return;
		}

		if (action == "@add") {
			// If the developer is outdoors, remove any transient preview first so
			// the saved project structure does not spawn directly on top of it.
			// If the developer is still inside a preview/building, leave it intact;
			// addStructure() will safely require them to step outdoors first.
			if (player->getParentID() == 0) {
				String ignored;
				WorldBuilderExteriorBuildingPreview::clear(player, ignored);
			}

			result = WorldBuilderManager::instance()->addExteriorBuilding(player, templatePath, 15.0f, message);
			player->sendSystemMessage(String("[World Builder] ") + (result ? "" : "ERROR: ") + message);
			if (result)
				WorldBuilderCommandUi::showMenu(player);
			else
				WorldBuilderExteriorBuildingLibrary::showStructureActions(player, templatePath, category, query, page);
		}
	}
};

inline void WorldBuilderExteriorBuildingLibrary::showRoot(CreatureObject* player) {
	if (player == nullptr || player->getPlayerObject() == nullptr)
		return;

	WorldBuilderManager* manager = WorldBuilderManager::instance();
	if (manager == nullptr || !manager->hasSession(player)) {
		WorldBuilderCommandUi::sendMessage(player, "World Builder Exterior Building Library",
			"Open or create a World Builder project before browsing structures.");
		return;
	}

	const LibraryCatalog& catalog = getCatalog();
	const std::vector<ExteriorBuildingEntry>& entries = catalog.entries;

	std::map<std::string, int> categoryCounts;
	for (size_t i = 0; i < entries.size(); ++i)
		++categoryCounts[entries[i].category];

	ManagedReference<SuiListBox*> box = new SuiListBox(player, SuiWindowType::NONE, SuiListBox::HANDLESINGLEBUTTON);
	box->setPromptTitle("World Builder Exterior Building Library");

	StringBuffer prompt;
	prompt << "Compatible Structures: " << static_cast<int>(entries.size())
		   << " | Missing portal assets skipped: " << catalog.skippedMissingPortalAssets
		   << " | Other incompatible skipped: " << catalog.skippedIncompatibleStructures
		   << "\n\nOnly registered building/cave SERVER templates with a matching shared/client identity and a usable portal layout with interior cells are shown. "
		   << "The catalog is built once per server process; missing POB candidates are filtered before Core3 tries to load them. "
		   << "Select a structure to Preview it transiently or Add it to the active project.";
	box->setPromptText(prompt.toString());
	box->setUsingObject(player);
	box->setCancelButton(true, "@cancel");
	box->setOkButton(true, "@ok");

	Vector<String> actions;
	box->addMenuItem("Search All Structures...", actions.size() + 1);
	actions.add("@search");

	box->addMenuItem("All Compatible Structures (" + String::valueOf(static_cast<int>(entries.size())) + ")", actions.size() + 1);
	actions.add("@all");

	for (std::map<std::string, int>::const_iterator it = categoryCounts.begin(); it != categoryCounts.end(); ++it) {
		std::string label = humanize(it->first) + " (" + std::to_string(it->second) + ")";
		box->addMenuItem(String(label.c_str()), actions.size() + 1);
		actions.add(String(it->first.c_str()));
	}

	box->addMenuItem("Back to World Builder", actions.size() + 1);
	actions.add("@back");

	box->setCallback(new WorldBuilderExteriorBuildingLibraryRootSuiCallback(player->getZoneServer(), actions));
	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

inline void WorldBuilderExteriorBuildingLibrary::showSearchInput(CreatureObject* player) {
	if (player == nullptr || player->getPlayerObject() == nullptr)
		return;

	ManagedReference<SuiInputBox*> box = new SuiInputBox(player, SuiWindowType::NONE);
	box->setPromptTitle("Search World Builder Exterior Building Library");
	box->setPromptText("Enter part of a structure name or template path. Examples: cave, tatooine, bunker, cantina, guild, imperial.");
	box->setMaxInputSize(80);
	box->setUsingObject(player);
	box->setCallback(new WorldBuilderExteriorBuildingLibrarySearchSuiCallback(player->getZoneServer()));
	box->setForceCloseDistance(-1);
	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

inline void WorldBuilderExteriorBuildingLibrary::showTemplateList(CreatureObject* player, const String& category, const String& query, int page) {
	if (player == nullptr || player->getPlayerObject() == nullptr)
		return;

	WorldBuilderManager* manager = WorldBuilderManager::instance();
	if (manager == nullptr || !manager->hasSession(player)) {
		WorldBuilderCommandUi::sendMessage(player, "World Builder Exterior Building Library",
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
			text << "No compatible registered structures matched '" << query << "'.";
		else
			text << "No compatible registered structures were found in category '" << category << "'.";
		WorldBuilderCommandUi::sendMessage(player, "World Builder Exterior Building Library", text.toString());
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
		categoryLabel = "All Structures";
	else
		categoryLabel = String(humanize(std::string(category.toCharArray())).c_str());
	box->setPromptTitle(query.isEmpty() ? "Exterior Building Library - " + categoryLabel : "Exterior Building Library Search");

	StringBuffer prompt;
	if (!query.isEmpty())
		prompt << "Search: '" << query << "' | ";
	else
		prompt << "Category: " << categoryLabel << " | ";
	prompt << "Showing " << (start + 1) << "-" << end << " of " << total
		   << ". Select a structure to see its full SERVER template and choose Preview or Add to Project.";
	box->setPromptText(prompt.toString());
	box->setUsingObject(player);
	box->setCancelButton(true, "@cancel");
	box->setOkButton(true, "@ok");

	Vector<String> actions;
	box->addMenuItem("Back to Structure Categories", actions.size() + 1);
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

	box->setCallback(new WorldBuilderExteriorBuildingLibraryListSuiCallback(player->getZoneServer(), category, query, page, actions));
	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

inline void WorldBuilderExteriorBuildingLibrary::showStructureActions(CreatureObject* player, const String& templatePath,
	const String& category, const String& query, int page) {
	if (player == nullptr || player->getPlayerObject() == nullptr)
		return;

	WorldBuilderManager* manager = WorldBuilderManager::instance();
	if (manager == nullptr || !manager->hasSession(player)) {
		WorldBuilderCommandUi::sendMessage(player, "World Builder Exterior Building Library",
			"The World Builder project is no longer open.");
		return;
	}

	int cellCount = getCellCount(templatePath);
	if (cellCount != 0) {
		WorldBuilderCommandUi::sendMessage(player, "World Builder Exterior Building Library",
			"This structure no longer passes the compatibility checks. It may have changed or its template registration may be incomplete.");
		return;
	}

	ManagedReference<SuiListBox*> box = new SuiListBox(player, SuiWindowType::NONE, SuiListBox::HANDLESINGLEBUTTON);
	box->setPromptTitle("Exterior Building: " + displayNameForTemplate(templatePath));

	StringBuffer prompt;
	prompt << "SERVER template:\n" << templatePath
		   << "\n\nInterior cells: 0"
		   << "\n\nPreview creates a transient test BuildingObject and does NOT modify the .wbp. "
		   << "Add to Project creates the real STRUCTURE record 15m in front of you, initially facing toward you, and autosaves the project. "
		   << "When you are outdoors, Add automatically clears the transient preview first.";
	box->setPromptText(prompt.toString());
	box->setUsingObject(player);
	box->setCancelButton(true, "@cancel");
	box->setOkButton(true, "@ok");

	Vector<String> actions;
	box->addMenuItem("Preview Exterior Building (Transient, 15m Ahead)", actions.size() + 1);
	actions.add("@preview");
	box->addMenuItem("Clear Exterior Preview", actions.size() + 1);
	actions.add("@clear");
	box->addMenuItem("Add Exterior Building to Active Project (15m Ahead)", actions.size() + 1);
	actions.add("@add");
	box->addMenuItem("Back to Exterior Building List", actions.size() + 1);
	actions.add("@back");

	box->setCallback(new WorldBuilderExteriorBuildingLibraryActionSuiCallback(player->getZoneServer(), templatePath,
		category, query, page, actions));
	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

#endif /* WORLDBUILDEREXTERIORBUILDINGLIBRARY_H_ */
