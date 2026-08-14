/*
 * WorldBuilderCommand.h
 *
 * Bellum Gero World Builder command + SUI front-end.
 * Both /worldbuilder and the short /wb alias use this implementation.
 */

#ifndef WORLDBUILDERCOMMAND_H_
#define WORLDBUILDERCOMMAND_H_

#include "server/zone/managers/worldbuilder/WorldBuilderManager.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/SuiWindowType.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/inputbox/SuiInputBox.h"
#include "server/zone/objects/player/sui/messagebox/SuiMessageBox.h"

class WorldBuilderSuiCallback;
class WorldBuilderObjectListSuiCallback;
class WorldBuilderProjectListSuiCallback;
class WorldBuilderProjectManageListSuiCallback;
class WorldBuilderProjectManageSuiCallback;
class WorldBuilderProjectRenameSuiCallback;
class WorldBuilderProjectRestoreSuiCallback;
class WorldBuilderProjectDeleteSuiCallback;
class WorldBuilderInputSuiCallback;

class WorldBuilderCommandUi {
public:
	enum MainAction {
		ACTION_STATUS = 1,
		ACTION_OBJECT_LIST = 2,
		ACTION_SPAWN_TEMPLATE = 3,
		ACTION_SPAWN_LAST = 4,
		ACTION_MOVE_FORWARD = 5,
		ACTION_MOVE_BACK = 6,
		ACTION_MOVE_LEFT = 7,
		ACTION_MOVE_RIGHT = 8,
		ACTION_MOVE_UP = 9,
		ACTION_MOVE_DOWN = 10,
		ACTION_YAW_LEFT = 11,
		ACTION_YAW_RIGHT = 12,
		ACTION_PITCH_UP = 13,
		ACTION_PITCH_DOWN = 14,
		ACTION_ROLL_LEFT = 15,
		ACTION_ROLL_RIGHT = 16,
		ACTION_DUPLICATE = 17,
		ACTION_DELETE = 18,
		ACTION_GROUP_ADD = 19,
		ACTION_GROUP_REMOVE = 20,
		ACTION_GROUP_CLEAR = 21,
		ACTION_UNDO = 22,
		ACTION_REDO = 23,
		ACTION_SET_MOVE_STEP = 24,
		ACTION_SET_ROTATE_STEP = 25,
		ACTION_SAVE = 26,
		ACTION_EXPORT = 27,
		ACTION_HELP = 28,
		ACTION_CLOSE = 29,
		ACTION_NEW_PROJECT = 30,
		ACTION_LOAD_PROJECT = 31,
		ACTION_MANAGE_PROJECTS = 32,
		ACTION_OBJECT_LIBRARY = 33,
		ACTION_STRUCTURE_INSPECTOR = 34,
		ACTION_STRUCTURE_PREVIEW = 35,
		ACTION_STRUCTURE_PREVIEW_CLEAR = 36,
		ACTION_CELL_CONTEXT = 37,
		ACTION_ADD_STRUCTURE = 38,
		ACTION_STRUCTURE_LIBRARY = 39,
		ACTION_BIND_EXTENSION = 40,
		ACTION_EXTENSION_STATUS = 41,
		ACTION_ADD_EXTERIOR_BUILDING = 42,
		ACTION_TRAVEL_POINT = 43,
		ACTION_SHIP_SCENERY_LIBRARY = 44
	};

	enum ProjectManageAction {
		PROJECT_MANAGE_RENAME = 1,
		PROJECT_MANAGE_RESTORE = 2,
		PROJECT_MANAGE_DELETE_ACTIVE = 3,
		PROJECT_MANAGE_DELETE_ALL = 4,
		PROJECT_MANAGE_BACK = 5
	};

	enum InputAction {
		INPUT_NEW_PROJECT = 1,
		INPUT_LOAD_PROJECT = 2,
		INPUT_SPAWN_TEMPLATE = 3,
		INPUT_MOVE_STEP = 4,
		INPUT_ROTATE_STEP = 5,
		INPUT_STRUCTURE_PREVIEW = 6,
		INPUT_ADD_STRUCTURE = 7,
		INPUT_ADD_EXTERIOR_BUILDING = 8
	};

	static void sendMessage(CreatureObject* player, const String& title, const String& text) {
		if (player == nullptr || player->getPlayerObject() == nullptr)
			return;

		ManagedReference<SuiMessageBox*> box = new SuiMessageBox(player, SuiWindowType::NONE);
		box->setPromptTitle(title);
		box->setPromptText(text);
		box->setOkButton(true, "@ok");
		player->getPlayerObject()->addSuiBox(box);
		player->sendMessage(box->generateMessage());
	}

	static void showInput(CreatureObject* player, InputAction action, const String& title,
		const String& prompt, const String& defaultText = "");
	static void showObjectList(CreatureObject* player);
	static void showProjectList(CreatureObject* player);
	static void showProjectManagementList(CreatureObject* player);
	static void showProjectManagement(CreatureObject* player, const String& projectName);
	static void showProjectRenameInput(CreatureObject* player, const String& projectName);
	static void showProjectRestoreConfirmation(CreatureObject* player, const String& projectName);
	static void showProjectDeleteConfirmation(CreatureObject* player, const String& projectName, bool deleteBackup, int step);
	static void showMenu(CreatureObject* player);
};

#include "WorldBuilderObjectLibrary.h"
#include "WorldBuilderStructureInspector.h"
#include "WorldBuilderStructurePreview.h"
#include "WorldBuilderStructureLibrary.h"
#include "WorldBuilderExteriorBuildingLibrary.h"
#include "WorldBuilderPublishedRefresh.h"
#include "WorldBuilderTravelPointEditor.h"
#include "WorldBuilderShipSceneryLibrary.h"

class WorldBuilderObjectListSuiCallback : public SuiCallback {
public:
	WorldBuilderObjectListSuiCallback(ZoneServer* server) : SuiCallback(server) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr || !suiBox->isListBox() || eventIndex == 1 || args == nullptr || args->size() < 1)
			return;

		int selectedIndex = -1;
		try {
			selectedIndex = Integer::valueOf(args->get(0).toString());
		} catch (Exception& e) {
			return;
		}

		SuiListBox* listBox = cast<SuiListBox*>(suiBox);
		if (listBox == nullptr || selectedIndex < 0 || selectedIndex >= listBox->getMenuSize())
			return;

		uint32 localID = (uint32)listBox->getMenuObjectID(selectedIndex);
		String message;
		WorldBuilderManager::instance()->selectObject(player, localID, message);
		player->sendSystemMessage("[World Builder] " + message);
		WorldBuilderCommandUi::showMenu(player);
	}
};

class WorldBuilderProjectListSuiCallback : public SuiCallback {
	Vector<String> projectNames;

public:
	WorldBuilderProjectListSuiCallback(ZoneServer* server, const Vector<String>& names)
		: SuiCallback(server), projectNames(names) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr || !suiBox->isListBox() || eventIndex == 1 || args == nullptr || args->size() < 1)
			return;

		int selectedIndex = -1;
		try {
			selectedIndex = Integer::valueOf(args->get(0).toString());
		} catch (Exception& e) {
			return;
		}

		if (selectedIndex < 0 || selectedIndex >= projectNames.size())
			return;

		String message;
		bool result = WorldBuilderManager::instance()->loadProject(player, projectNames.get(selectedIndex), message);
		player->sendSystemMessage(String("[World Builder] ") + (result ? "" : "ERROR: ") + message);

		if (result)
			WorldBuilderCommandUi::showMenu(player);
		else
			WorldBuilderCommandUi::showProjectList(player);
	}
};

class WorldBuilderProjectManageListSuiCallback : public SuiCallback {
	Vector<String> projectNames;

public:
	WorldBuilderProjectManageListSuiCallback(ZoneServer* server, const Vector<String>& names)
		: SuiCallback(server), projectNames(names) {
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

		if (selectedIndex < 0 || selectedIndex >= projectNames.size())
			return;

		WorldBuilderCommandUi::showProjectManagement(player, projectNames.get(selectedIndex));
	}
};

class WorldBuilderProjectManageSuiCallback : public SuiCallback {
	String projectName;

public:
	WorldBuilderProjectManageSuiCallback(ZoneServer* server, const String& name)
		: SuiCallback(server), projectName(name) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr || !suiBox->isListBox())
			return;

		if (eventIndex == 1) {
			WorldBuilderCommandUi::showProjectManagementList(player);
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

		SuiListBox* listBox = cast<SuiListBox*>(suiBox);
		if (listBox == nullptr || selectedIndex < 0 || selectedIndex >= listBox->getMenuSize())
			return;

		uint64 action = listBox->getMenuObjectID(selectedIndex);

		switch (action) {
		case WorldBuilderCommandUi::PROJECT_MANAGE_RENAME:
			WorldBuilderCommandUi::showProjectRenameInput(player, projectName);
			break;
		case WorldBuilderCommandUi::PROJECT_MANAGE_RESTORE:
			WorldBuilderCommandUi::showProjectRestoreConfirmation(player, projectName);
			break;
		case WorldBuilderCommandUi::PROJECT_MANAGE_DELETE_ACTIVE:
			WorldBuilderCommandUi::showProjectDeleteConfirmation(player, projectName, false, 1);
			break;
		case WorldBuilderCommandUi::PROJECT_MANAGE_DELETE_ALL:
			WorldBuilderCommandUi::showProjectDeleteConfirmation(player, projectName, true, 1);
			break;
		case WorldBuilderCommandUi::PROJECT_MANAGE_BACK:
			WorldBuilderCommandUi::showProjectManagementList(player);
			break;
		default:
			return;
		}
	}
};

class WorldBuilderProjectRenameSuiCallback : public SuiCallback {
	String projectName;

public:
	WorldBuilderProjectRenameSuiCallback(ZoneServer* server, const String& name)
		: SuiCallback(server), projectName(name) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr || !suiBox->isInputBox())
			return;

		if (eventIndex == 1) {
			WorldBuilderCommandUi::showProjectManagement(player, projectName);
			return;
		}

		if (args == nullptr || args->size() < 1)
			return;

		String newName = args->get(0).toString().trim();
		if (newName.isEmpty()) {
			WorldBuilderCommandUi::showProjectManagement(player, projectName);
			return;
		}

		String message;
		bool result = WorldBuilderManager::instance()->renameSavedProject(player, projectName, newName, message);
		player->sendSystemMessage(String("[World Builder] ") + (result ? "" : "ERROR: ") + message);

		if (result)
			WorldBuilderCommandUi::showProjectManagementList(player);
		else
			WorldBuilderCommandUi::showProjectManagement(player, projectName);
	}
};

class WorldBuilderProjectRestoreSuiCallback : public SuiCallback {
	String projectName;

public:
	WorldBuilderProjectRestoreSuiCallback(ZoneServer* server, const String& name)
		: SuiCallback(server), projectName(name) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr || !suiBox->isMessageBox())
			return;

		if (eventIndex == 1) {
			WorldBuilderCommandUi::showProjectManagement(player, projectName);
			return;
		}

		String message;
		bool result = WorldBuilderManager::instance()->restoreProjectBackup(player, projectName, message);
		player->sendSystemMessage(String("[World Builder] ") + (result ? "" : "ERROR: ") + message);
		WorldBuilderCommandUi::showProjectManagement(player, projectName);
	}
};

class WorldBuilderProjectDeleteSuiCallback : public SuiCallback {
	String projectName;
	bool deleteBackup;
	int confirmationStep;

public:
	WorldBuilderProjectDeleteSuiCallback(ZoneServer* server, const String& name, bool removeBackup, int step)
		: SuiCallback(server), projectName(name), deleteBackup(removeBackup), confirmationStep(step) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr || !suiBox->isMessageBox())
			return;

		if (eventIndex == 1) {
			WorldBuilderCommandUi::showProjectManagement(player, projectName);
			return;
		}

		if (confirmationStep < 2) {
			WorldBuilderCommandUi::showProjectDeleteConfirmation(player, projectName, deleteBackup, 2);
			return;
		}

		String message;
		bool result = WorldBuilderManager::instance()->deleteSavedProject(player, projectName, deleteBackup, message);
		player->sendSystemMessage(String("[World Builder] ") + (result ? "" : "ERROR: ") + message);

		bool hasActive = false;
		bool hasBackup = false;
		WorldBuilderManager::instance()->getSavedProjectStatus(projectName, hasActive, hasBackup);

		if (hasActive || hasBackup)
			WorldBuilderCommandUi::showProjectManagement(player, projectName);
		else
			WorldBuilderCommandUi::showProjectManagementList(player);
	}
};

class WorldBuilderInputSuiCallback : public SuiCallback {
	int inputAction;

public:
	WorldBuilderInputSuiCallback(ZoneServer* server, int action) : SuiCallback(server), inputAction(action) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr || !suiBox->isInputBox() || eventIndex == 1 || args == nullptr || args->size() < 1)
			return;

		String input = args->get(0).toString().trim();
		if (input.isEmpty())
			return;

		WorldBuilderManager* manager = WorldBuilderManager::instance();
		String message;
		bool result = false;

		try {
			switch (inputAction) {
			case WorldBuilderCommandUi::INPUT_NEW_PROJECT:
				result = manager->createProject(player, input, message);
				break;
			case WorldBuilderCommandUi::INPUT_LOAD_PROJECT:
				result = manager->loadProject(player, input, message);
				break;
			case WorldBuilderCommandUi::INPUT_SPAWN_TEMPLATE:
				result = manager->spawnTemplate(player, input, 3.0f, message);
				break;
			case WorldBuilderCommandUi::INPUT_MOVE_STEP:
				result = manager->setMoveStep(player, Float::valueOf(input), message);
				break;
			case WorldBuilderCommandUi::INPUT_ROTATE_STEP:
				result = manager->setRotateStep(player, Float::valueOf(input), message);
				break;
			case WorldBuilderCommandUi::INPUT_STRUCTURE_PREVIEW:
				result = WorldBuilderStructurePreview::spawn(player, input, 12.0f, message);
				break;
			case WorldBuilderCommandUi::INPUT_ADD_STRUCTURE:
				result = manager->addStructure(player, input, 15.0f, message);
				break;
			case WorldBuilderCommandUi::INPUT_ADD_EXTERIOR_BUILDING:
				result = manager->addExteriorBuilding(player, input, 15.0f, message);
				break;
			default:
				return;
			}
		} catch (Exception& e) {
			message = "Invalid value.";
		}

		player->sendSystemMessage(String("[World Builder] ") + (result ? "" : "ERROR: ") + message);
		WorldBuilderCommandUi::showMenu(player);
	}
};

class WorldBuilderSuiCallback : public SuiCallback {
public:
	WorldBuilderSuiCallback(ZoneServer* server) : SuiCallback(server) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (player == nullptr || suiBox == nullptr || !suiBox->isListBox() || eventIndex == 1 || args == nullptr || args->size() < 1)
			return;

		int selectedIndex = -1;
		try {
			selectedIndex = Integer::valueOf(args->get(0).toString());
		} catch (Exception& e) {
			return;
		}

		SuiListBox* listBox = cast<SuiListBox*>(suiBox);
		if (listBox == nullptr || selectedIndex < 0 || selectedIndex >= listBox->getMenuSize())
			return;

		uint64 action = listBox->getMenuObjectID(selectedIndex);
		WorldBuilderManager* manager = WorldBuilderManager::instance();
		String message;
		bool result = true;
		bool reopen = true;
		float moveStep = manager->getMoveStep(player);
		float rotateStep = manager->getRotateStep(player);

		switch (action) {
		case WorldBuilderCommandUi::ACTION_NEW_PROJECT:
			WorldBuilderCommandUi::showInput(player, WorldBuilderCommandUi::INPUT_NEW_PROJECT,
				"New World Builder Project", "Enter a short project name (letters, numbers, _ and -):");
			reopen = false;
			break;
		case WorldBuilderCommandUi::ACTION_LOAD_PROJECT:
			WorldBuilderCommandUi::showProjectList(player);
			reopen = false;
			break;
		case WorldBuilderCommandUi::ACTION_MANAGE_PROJECTS:
			WorldBuilderCommandUi::showProjectManagementList(player);
			reopen = false;
			break;
		case WorldBuilderCommandUi::ACTION_STATUS:
			WorldBuilderCommandUi::sendMessage(player, "World Builder Status", manager->getStatus(player));
			reopen = false;
			break;
		case WorldBuilderCommandUi::ACTION_OBJECT_LIST:
			WorldBuilderCommandUi::showObjectList(player);
			reopen = false;
			break;
		case WorldBuilderCommandUi::ACTION_OBJECT_LIBRARY:
			WorldBuilderObjectLibrary::showRoot(player);
			reopen = false;
			break;
		case WorldBuilderCommandUi::ACTION_SHIP_SCENERY_LIBRARY:
			WorldBuilderShipSceneryLibrary::showRoot(player);
			reopen = false;
			break;
		case WorldBuilderCommandUi::ACTION_STRUCTURE_LIBRARY:
			WorldBuilderStructureLibrary::showRoot(player);
			reopen = false;
			break;
		case WorldBuilderCommandUi::ACTION_STRUCTURE_INSPECTOR:
			WorldBuilderStructureInspector::show(player);
			reopen = false;
			break;
		case WorldBuilderCommandUi::ACTION_BIND_EXTENSION:
			result = manager->bindPublishedStructure(player, message);
			break;
		case WorldBuilderCommandUi::ACTION_EXTENSION_STATUS:
			WorldBuilderCommandUi::sendMessage(player, "World Builder Extension Targets", manager->getExtensionStatus(player));
			reopen = false;
			break;
		case WorldBuilderCommandUi::ACTION_ADD_STRUCTURE:
			WorldBuilderCommandUi::showInput(player, WorldBuilderCommandUi::INPUT_ADD_STRUCTURE,
				"Add Structure to World Builder Project",
				"Enter a registered SERVER building/cave template. The structure will be saved to this project and initially face toward you:",
				"object/building/tatooine/cave_tatooine_style_01.iff");
			reopen = false;
			break;
		case WorldBuilderCommandUi::ACTION_ADD_EXTERIOR_BUILDING:
			WorldBuilderExteriorBuildingLibrary::showRoot(player);
			reopen = false;
			break;
		case WorldBuilderCommandUi::ACTION_TRAVEL_POINT:
			WorldBuilderTravelPointEditor::show(player); reopen = false; break;
		case WorldBuilderCommandUi::ACTION_STRUCTURE_PREVIEW:
			WorldBuilderCommandUi::showInput(player, WorldBuilderCommandUi::INPUT_STRUCTURE_PREVIEW,
				"World Builder Structure Preview",
				"Enter a registered SERVER building/cave template path. This preview is transient and is not saved to the project yet:",
				"object/building/tatooine/cave_tatooine_style_01.iff");
			reopen = false;
			break;
		case WorldBuilderCommandUi::ACTION_STRUCTURE_PREVIEW_CLEAR:
			result = WorldBuilderStructurePreview::clear(player, message);
			break;
		case WorldBuilderCommandUi::ACTION_CELL_CONTEXT:
			WorldBuilderCommandUi::sendMessage(player, "World Builder Cell Context", WorldBuilderStructurePreview::getCellContext(player));
			reopen = false;
			break;
		case WorldBuilderCommandUi::ACTION_SPAWN_TEMPLATE:
			WorldBuilderCommandUi::showInput(player, WorldBuilderCommandUi::INPUT_SPAWN_TEMPLATE,
				"Spawn World Builder Object", "Enter a registered server object template path:", manager->getLastTemplate(player));
			reopen = false;
			break;
		case WorldBuilderCommandUi::ACTION_SPAWN_LAST:
			result = manager->spawnLastTemplate(player, 3.0f, message);
			break;
		case WorldBuilderCommandUi::ACTION_MOVE_FORWARD: result = manager->moveSelected(player, "forward", moveStep, message); break;
		case WorldBuilderCommandUi::ACTION_MOVE_BACK: result = manager->moveSelected(player, "back", moveStep, message); break;
		case WorldBuilderCommandUi::ACTION_MOVE_LEFT: result = manager->moveSelected(player, "left", moveStep, message); break;
		case WorldBuilderCommandUi::ACTION_MOVE_RIGHT: result = manager->moveSelected(player, "right", moveStep, message); break;
		case WorldBuilderCommandUi::ACTION_MOVE_UP: result = manager->moveSelected(player, "up", moveStep, message); break;
		case WorldBuilderCommandUi::ACTION_MOVE_DOWN: result = manager->moveSelected(player, "down", moveStep, message); break;
		case WorldBuilderCommandUi::ACTION_YAW_LEFT: result = manager->rotateSelected(player, "yaw", -rotateStep, message); break;
		case WorldBuilderCommandUi::ACTION_YAW_RIGHT: result = manager->rotateSelected(player, "yaw", rotateStep, message); break;
		case WorldBuilderCommandUi::ACTION_PITCH_UP: result = manager->rotateSelected(player, "pitch", rotateStep, message); break;
		case WorldBuilderCommandUi::ACTION_PITCH_DOWN: result = manager->rotateSelected(player, "pitch", -rotateStep, message); break;
		case WorldBuilderCommandUi::ACTION_ROLL_LEFT: result = manager->rotateSelected(player, "roll", -rotateStep, message); break;
		case WorldBuilderCommandUi::ACTION_ROLL_RIGHT: result = manager->rotateSelected(player, "roll", rotateStep, message); break;
		case WorldBuilderCommandUi::ACTION_DUPLICATE: result = manager->duplicateSelected(player, moveStep, message); break;
		case WorldBuilderCommandUi::ACTION_DELETE: result = manager->deleteSelected(player, message); break;
		case WorldBuilderCommandUi::ACTION_GROUP_ADD: result = manager->groupAddSelected(player, message); break;
		case WorldBuilderCommandUi::ACTION_GROUP_REMOVE: result = manager->groupRemoveSelected(player, message); break;
		case WorldBuilderCommandUi::ACTION_GROUP_CLEAR: result = manager->groupClear(player, message); break;
		case WorldBuilderCommandUi::ACTION_UNDO: result = manager->undo(player, message); break;
		case WorldBuilderCommandUi::ACTION_REDO: result = manager->redo(player, message); break;
		case WorldBuilderCommandUi::ACTION_SET_MOVE_STEP:
			WorldBuilderCommandUi::showInput(player, WorldBuilderCommandUi::INPUT_MOVE_STEP,
				"World Builder Move Step", "Enter movement step in meters (0.01 - 25):", String::valueOf(moveStep));
			reopen = false;
			break;
		case WorldBuilderCommandUi::ACTION_SET_ROTATE_STEP:
			WorldBuilderCommandUi::showInput(player, WorldBuilderCommandUi::INPUT_ROTATE_STEP,
				"World Builder Rotate Step", "Enter rotation step in degrees (0.1 - 90):", String::valueOf(rotateStep));
			reopen = false;
			break;
		case WorldBuilderCommandUi::ACTION_SAVE: result = manager->saveProject(player, message); break;
		case WorldBuilderCommandUi::ACTION_EXPORT: result = manager->exportLua(player, message); break;
		case WorldBuilderCommandUi::ACTION_HELP:
			WorldBuilderCommandUi::sendMessage(player, "World Builder Help", manager->getHelp(player));
			reopen = false;
			break;
		case WorldBuilderCommandUi::ACTION_CLOSE:
			result = manager->closeProject(player, true, message);
			reopen = false;
			break;
		default:
			return;
		}

		if (!message.isEmpty())
			player->sendSystemMessage(String("[World Builder] ") + (result ? "" : "ERROR: ") + message);

		if (reopen)
			WorldBuilderCommandUi::showMenu(player);
	}
};

inline void WorldBuilderCommandUi::showInput(CreatureObject* player, InputAction action, const String& title,
	const String& prompt, const String& defaultText) {
	if (player == nullptr || player->getPlayerObject() == nullptr)
		return;

	ManagedReference<SuiInputBox*> box = new SuiInputBox(player, SuiWindowType::NONE);
	box->setPromptTitle(title);
	box->setPromptText(prompt);
	box->setMaxInputSize(action == INPUT_SPAWN_TEMPLATE ? 220 : 48);
	if (!defaultText.isEmpty())
		box->setDefaultInput(defaultText);
	box->setUsingObject(player);
	box->setCallback(new WorldBuilderInputSuiCallback(player->getZoneServer(), action));
	box->setForceCloseDistance(-1);
	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

inline void WorldBuilderCommandUi::showObjectList(CreatureObject* player) {
	if (player == nullptr || player->getPlayerObject() == nullptr)
		return;

	Vector<String> labels;
	Vector<uint64> localIDs;
	WorldBuilderManager::instance()->getObjectMenu(player, labels, localIDs);

	ManagedReference<SuiListBox*> box = new SuiListBox(player, SuiWindowType::NONE, SuiListBox::HANDLESINGLEBUTTON);
	box->setPromptTitle("World Builder Objects");
	box->setPromptText(labels.size() == 0 ? "No objects yet. Spawn one from the main World Builder menu." :
		"Select an object. * is selected; [G] is in the active group.");
	box->setUsingObject(player);
	box->setCancelButton(true, "@cancel");
	box->setOkButton(true, "@ok");
	box->setCallback(new WorldBuilderObjectListSuiCallback(player->getZoneServer()));

	for (int i = 0; i < labels.size(); ++i)
		box->addMenuItem(labels.get(i), localIDs.get(i));

	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

inline void WorldBuilderCommandUi::showProjectList(CreatureObject* player) {
	if (player == nullptr || player->getPlayerObject() == nullptr)
		return;

	Vector<String> projectNames;
	WorldBuilderManager::instance()->getSavedProjects(projectNames);

	if (projectNames.size() == 0) {
		WorldBuilderCommandUi::sendMessage(player, "Saved World Builder Projects",
			"No saved .wbp projects were found in worldbuilder/projects.\n\nCreate one with New Project or /wb new <name>.");
		return;
	}

	ManagedReference<SuiListBox*> box = new SuiListBox(player, SuiWindowType::NONE, SuiListBox::HANDLESINGLEBUTTON);
	box->setPromptTitle("Load Saved World Builder Project");
	box->setPromptText("Select a saved project to load. New Project will not overwrite names shown here.");
	box->setUsingObject(player);
	box->setCancelButton(true, "@cancel");
	box->setOkButton(true, "@ok");
	box->setCallback(new WorldBuilderProjectListSuiCallback(player->getZoneServer(), projectNames));

	for (int i = 0; i < projectNames.size(); ++i)
		box->addMenuItem(projectNames.get(i), i + 1);

	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

inline void WorldBuilderCommandUi::showProjectManagementList(CreatureObject* player) {
	if (player == nullptr || player->getPlayerObject() == nullptr)
		return;

	WorldBuilderManager* manager = WorldBuilderManager::instance();
	if (manager->hasSession(player)) {
		WorldBuilderCommandUi::sendMessage(player, "Manage Saved World Builder Projects",
			"Close the current World Builder project before renaming, restoring, or deleting saved project files.");
		return;
	}

	Vector<String> projectNames;
	Vector<String> labels;
	manager->getManagedProjects(projectNames, labels);

	if (projectNames.size() == 0) {
		WorldBuilderCommandUi::sendMessage(player, "Manage Saved World Builder Projects",
			"No active .wbp projects or .wbp.bak safety backups were found in worldbuilder/projects.");
		return;
	}

	ManagedReference<SuiListBox*> box = new SuiListBox(player, SuiWindowType::NONE, SuiListBox::HANDLESINGLEBUTTON);
	box->setPromptTitle("Manage Saved World Builder Projects");
	box->setPromptText("Select a project to manage. Backup-only entries are intentionally shown so they can be restored instead of being stranded.");
	box->setUsingObject(player);
	box->setCancelButton(true, "@cancel");
	box->setOkButton(true, "@ok");
	box->setCallback(new WorldBuilderProjectManageListSuiCallback(player->getZoneServer(), projectNames));

	for (int i = 0; i < labels.size(); ++i)
		box->addMenuItem(labels.get(i), i + 1);

	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

inline void WorldBuilderCommandUi::showProjectManagement(CreatureObject* player, const String& projectName) {
	if (player == nullptr || player->getPlayerObject() == nullptr)
		return;

	WorldBuilderManager* manager = WorldBuilderManager::instance();
	if (manager->hasSession(player)) {
		WorldBuilderCommandUi::sendMessage(player, "Manage Saved World Builder Projects",
			"Close the current World Builder project before managing saved project files.");
		return;
	}

	bool hasActive = false;
	bool hasBackup = false;
	manager->getSavedProjectStatus(projectName, hasActive, hasBackup);

	if (!hasActive && !hasBackup) {
		player->sendSystemMessage("[World Builder] Saved project files are no longer present for '" + projectName + "'.");
		WorldBuilderCommandUi::showProjectManagementList(player);
		return;
	}

	ManagedReference<SuiListBox*> box = new SuiListBox(player, SuiWindowType::NONE, SuiListBox::HANDLESINGLEBUTTON);
	box->setPromptTitle("Manage Project: " + projectName);

	StringBuffer prompt;
	prompt << "Active .wbp: " << (hasActive ? "YES" : "NO")
		   << "\nSafety .wbp.bak: " << (hasBackup ? "YES" : "NO") << "\n\n";

	if (hasActive && hasBackup)
		prompt << "Restore Backup makes the backup active and moves the current active version into .wbp.bak. An unchanged save/close preserves it; the next save/autosave that actually changes project data will rotate it again.";
	else if (!hasActive && hasBackup)
		prompt << "This is a backup-only project. Restore Backup will recreate the active .wbp while retaining the .bak copy.";
	else
		prompt << "This project currently has no safety backup. Delete will therefore remove its only saved project file.";

	box->setPromptText(prompt.toString());
	box->setUsingObject(player);
	box->setCancelButton(true, "@cancel");
	box->setOkButton(true, "@ok");
	box->setCallback(new WorldBuilderProjectManageSuiCallback(player->getZoneServer(), projectName));

	box->addMenuItem(hasActive ? "Rename Project..." : "Rename Backup...", PROJECT_MANAGE_RENAME);

	if (hasBackup)
		box->addMenuItem(hasActive ? "Restore Backup (Swap Versions)..." : "Restore Backup to Active Project...", PROJECT_MANAGE_RESTORE);

	if (hasActive) {
		if (hasBackup)
			box->addMenuItem("Delete Active Project (KEEP Backup)...", PROJECT_MANAGE_DELETE_ACTIVE);
		else
			box->addMenuItem("Delete Project (NO Backup)...", PROJECT_MANAGE_DELETE_ACTIVE);
	}

	if (hasBackup)
		box->addMenuItem(hasActive ? "Permanently Delete Project + Backup..." : "Permanently Delete Backup...", PROJECT_MANAGE_DELETE_ALL);

	box->addMenuItem("Back to Saved Projects", PROJECT_MANAGE_BACK);

	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

inline void WorldBuilderCommandUi::showProjectRenameInput(CreatureObject* player, const String& projectName) {
	if (player == nullptr || player->getPlayerObject() == nullptr)
		return;

	ManagedReference<SuiInputBox*> box = new SuiInputBox(player, SuiWindowType::NONE);
	box->setPromptTitle("Rename World Builder Project");
	box->setPromptText("Rename '" + projectName + "'. Enter a new project name. Rename never overwrites an existing .wbp, .wbp.bak, or pending save name.");
	box->setMaxInputSize(48);
	box->setDefaultInput(projectName);
	box->setUsingObject(player);
	box->setCallback(new WorldBuilderProjectRenameSuiCallback(player->getZoneServer(), projectName));
	box->setForceCloseDistance(-1);
	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

inline void WorldBuilderCommandUi::showProjectRestoreConfirmation(CreatureObject* player, const String& projectName) {
	if (player == nullptr || player->getPlayerObject() == nullptr)
		return;

	bool hasActive = false;
	bool hasBackup = false;
	WorldBuilderManager::instance()->getSavedProjectStatus(projectName, hasActive, hasBackup);

	if (!hasBackup) {
		player->sendSystemMessage("[World Builder] ERROR: No .wbp.bak safety backup exists for '" + projectName + "'.");
		WorldBuilderCommandUi::showProjectManagement(player, projectName);
		return;
	}

	ManagedReference<SuiMessageBox*> box = new SuiMessageBox(player, SuiWindowType::NONE);
	box->setPromptTitle("Restore World Builder Backup");

	if (hasActive) {
		box->setPromptText("Restore the .wbp.bak for '" + projectName + "'?\n\nThe backup will become the active .wbp. The current active project will become the new .wbp.bak recovery point. An unchanged close preserves that recovery point; a later save/autosave that changes project data will rotate .wbp.bak again.");
	} else {
		box->setPromptText("Restore backup-only project '" + projectName + "'?\n\nA new active .wbp will be created from the .wbp.bak. The original backup will also be retained.");
	}

	box->setUsingObject(player);
	box->setCancelButton(true, "@cancel");
	box->setOkButton(true, "@ok");
	box->setCallback(new WorldBuilderProjectRestoreSuiCallback(player->getZoneServer(), projectName));
	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

inline void WorldBuilderCommandUi::showProjectDeleteConfirmation(CreatureObject* player, const String& projectName, bool deleteBackup, int step) {
	if (player == nullptr || player->getPlayerObject() == nullptr)
		return;

	bool hasActive = false;
	bool hasBackup = false;
	WorldBuilderManager::instance()->getSavedProjectStatus(projectName, hasActive, hasBackup);

	if (!hasActive && !hasBackup) {
		WorldBuilderCommandUi::showProjectManagementList(player);
		return;
	}

	ManagedReference<SuiMessageBox*> box = new SuiMessageBox(player, SuiWindowType::NONE);
	box->setPromptTitle(step >= 2 ? "FINAL Delete Confirmation (2 of 2)" : "Delete Confirmation (1 of 2)");

	StringBuffer prompt;
	if (step >= 2)
		prompt << "FINAL CONFIRMATION\n\n";

	if (deleteBackup) {
		if (hasActive && hasBackup) {
			prompt << "Permanently delete project '" << projectName << "'?\n\nBOTH the active .wbp and its .wbp.bak safety backup will be deleted. This cannot be restored through World Builder.";
		} else if (hasBackup) {
			prompt << "Permanently delete the only remaining .wbp.bak for project '" << projectName << "'?\n\nThis removes the recovery copy and cannot be restored through World Builder.";
		} else {
			prompt << "Permanently delete project '" << projectName << "'?\n\nNo .wbp.bak exists, so the active .wbp is the only saved copy.";
		}
	} else {
		if (hasBackup) {
			prompt << "Delete the active .wbp for project '" << projectName << "'?\n\nThe .wbp.bak safety backup WILL BE KEPT and will remain visible as a Backup Only project that can be restored later.";
		} else {
			prompt << "Delete project '" << projectName << "'?\n\nWARNING: No .wbp.bak exists. This will remove the only saved World Builder project file.";
		}
	}

	if (step < 2)
		prompt << "\n\nYou will be asked to confirm one more time before anything is deleted.";
	else
		prompt << "\n\nPress OK only if you intend to perform this deletion now.";

	box->setPromptText(prompt.toString());
	box->setUsingObject(player);
	box->setCancelButton(true, "@cancel");
	box->setOkButton(true, "@ok");
	box->setCallback(new WorldBuilderProjectDeleteSuiCallback(player->getZoneServer(), projectName, deleteBackup, step));
	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

inline void WorldBuilderCommandUi::showMenu(CreatureObject* player) {
	if (player == nullptr || player->getPlayerObject() == nullptr)
		return;

	WorldBuilderManager* manager = WorldBuilderManager::instance();
	ManagedReference<SuiListBox*> box = new SuiListBox(player, SuiWindowType::NONE, SuiListBox::HANDLESINGLEBUTTON);
	box->setPromptTitle("Bellum Gero World Builder");
	box->setUsingObject(player);
	box->setCancelButton(true, "@cancel");
	box->setOkButton(true, "@ok");
	box->setCallback(new WorldBuilderSuiCallback(player->getZoneServer()));

	if (!manager->hasSession(player)) {
		box->setPromptText("No project is open. Projects autosave under worldbuilder/projects. New Project never overwrites an existing saved name.");
		box->addMenuItem("New Project (Never Overwrites)", ACTION_NEW_PROJECT);
		box->addMenuItem("Load Saved Project...", ACTION_LOAD_PROJECT);
		box->addMenuItem("Manage Saved Projects...", ACTION_MANAGE_PROJECTS);
		box->addMenuItem("Structure Inspector (Target / Current Interior)...", ACTION_STRUCTURE_INSPECTOR);
		box->addMenuItem("Structure Preview / Test...", ACTION_STRUCTURE_PREVIEW);
		box->addMenuItem("Current Cell Context", ACTION_CELL_CONTEXT);
		box->addMenuItem("Clear Structure Preview", ACTION_STRUCTURE_PREVIEW_CLEAR);
		box->addMenuItem("Help / Command List", ACTION_HELP);
	} else {
		StringBuffer prompt;
		prompt << manager->getStatus(player) << "\n\nCommon actions are below. For fastest placement, put /wb f, /wb b, /wb l, /wb r, /wb u, /wb d and rotation commands into toolbar macros.";
		box->setPromptText(prompt.toString());

		box->addMenuItem("Object List / Select", ACTION_OBJECT_LIST);
		box->addMenuItem("Object Library / Browse Templates...", ACTION_OBJECT_LIBRARY);
		box->addMenuItem("Ship Scenery Library / Static Ships...", ACTION_SHIP_SCENERY_LIBRARY);
		box->addMenuItem("Structure Library / Browse Buildings & Caves...", ACTION_STRUCTURE_LIBRARY);
		box->addMenuItem("Add Structure to Project...", ACTION_ADD_STRUCTURE);
		box->addMenuItem("Exterior Building Library / Cell-less Buildings...", ACTION_ADD_EXTERIOR_BUILDING);
		box->addMenuItem("Travel Point / Selected Shuttleport...", ACTION_TRAVEL_POINT);
		box->addMenuItem("Structure Inspector (Target / Current Interior)...", ACTION_STRUCTURE_INSPECTOR);
		box->addMenuItem("Extend Published WB Structure (Target / Current Interior)", ACTION_BIND_EXTENSION);
		box->addMenuItem("Extension Targets / Status...", ACTION_EXTENSION_STATUS);
		box->addMenuItem("Structure Preview / Test...", ACTION_STRUCTURE_PREVIEW);
		box->addMenuItem("Current Cell Context", ACTION_CELL_CONTEXT);
		box->addMenuItem("Clear Structure Preview", ACTION_STRUCTURE_PREVIEW_CLEAR);
		box->addMenuItem("Spawn New Template... (Manual / Advanced)", ACTION_SPAWN_TEMPLATE);
		box->addMenuItem("Spawn Last Template Again", ACTION_SPAWN_LAST);
		box->addMenuItem("Move Forward [step]", ACTION_MOVE_FORWARD);
		box->addMenuItem("Move Back [step]", ACTION_MOVE_BACK);
		box->addMenuItem("Move Left [step]", ACTION_MOVE_LEFT);
		box->addMenuItem("Move Right [step]", ACTION_MOVE_RIGHT);
		box->addMenuItem("Move Up [step]", ACTION_MOVE_UP);
		box->addMenuItem("Move Down [step]", ACTION_MOVE_DOWN);
		box->addMenuItem("Yaw Left [rot step]", ACTION_YAW_LEFT);
		box->addMenuItem("Yaw Right [rot step]", ACTION_YAW_RIGHT);
		box->addMenuItem("Pitch Up [rot step]", ACTION_PITCH_UP);
		box->addMenuItem("Pitch Down [rot step]", ACTION_PITCH_DOWN);
		box->addMenuItem("Roll Left [rot step]", ACTION_ROLL_LEFT);
		box->addMenuItem("Roll Right [rot step]", ACTION_ROLL_RIGHT);
		box->addMenuItem("Duplicate Selected", ACTION_DUPLICATE);
		box->addMenuItem("Delete Selected (Undo Available)", ACTION_DELETE);
		box->addMenuItem("Add Selected to Group", ACTION_GROUP_ADD);
		box->addMenuItem("Remove Selected from Group", ACTION_GROUP_REMOVE);
		box->addMenuItem("Clear Group", ACTION_GROUP_CLEAR);
		box->addMenuItem("Undo", ACTION_UNDO);
		box->addMenuItem("Redo", ACTION_REDO);
		box->addMenuItem("Change Move Step...", ACTION_SET_MOVE_STEP);
		box->addMenuItem("Change Rotate Step...", ACTION_SET_ROTATE_STEP);
		box->addMenuItem("Project Status", ACTION_STATUS);
		box->addMenuItem("Save Now", ACTION_SAVE);
		box->addMenuItem("Export Lua Screenplay", ACTION_EXPORT);
		box->addMenuItem("Help / Full Command List", ACTION_HELP);
		box->addMenuItem("Save + Close Project", ACTION_CLOSE);
	}

	player->getPlayerObject()->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

class WorldBuilderCommand : public QueueCommand {
public:
	WorldBuilderCommand(const String& name, ZoneProcessServer* server) : QueueCommand(name, server) {
	}

	int doQueueCommand(CreatureObject* player, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(player))
			return INVALIDSTATE;
		if (!checkInvalidLocomotions(player))
			return INVALIDLOCOMOTION;

		WorldBuilderManager* manager = WorldBuilderManager::instance();
		if (player == nullptr || manager == nullptr || !manager->isAuthorized(player)) {
			if (player != nullptr)
				player->sendSystemMessage("World Builder requires admin level 15.");
			return GENERALERROR;
		}

		String raw = arguments.toString().trim();
		if (raw.isEmpty()) {
			WorldBuilderCommandUi::showMenu(player);
			return SUCCESS;
		}

		StringTokenizer tokenizer(raw);
		String action;
		tokenizer.getStringToken(action);
		action = action.toLowerCase();

		String message;
		bool result = false;

		try {
			if (action == "menu") {
				WorldBuilderCommandUi::showMenu(player);
				return SUCCESS;
			} else if (action == "new") {
				if (!tokenizer.hasMoreTokens()) {
					WorldBuilderCommandUi::showInput(player, WorldBuilderCommandUi::INPUT_NEW_PROJECT,
						"New World Builder Project", "Enter a project name:");
					return SUCCESS;
				}
				String name; tokenizer.getStringToken(name);
				result = manager->createProject(player, name, message);
			} else if (action == "load") {
				if (!tokenizer.hasMoreTokens()) {
					WorldBuilderCommandUi::showProjectList(player);
					return SUCCESS;
				}
				String name; tokenizer.getStringToken(name);
				result = manager->loadProject(player, name, message);
			} else if (action == "projects" || action == "projectlist") {
				WorldBuilderCommandUi::showProjectList(player);
				return SUCCESS;
			} else if (action == "manage" || action == "manageprojects") {
				WorldBuilderCommandUi::showProjectManagementList(player);
				return SUCCESS;
			} else if (action == "library" || action == "assets" || action == "browse") {
				WorldBuilderObjectLibrary::showRoot(player);
				return SUCCESS;
			} else if (action == "ships" || action == "shipscenery") {
				WorldBuilderShipSceneryLibrary::showRoot(player);
				return SUCCESS;
			} else if (action == "structures" || action == "structurelibrary" || action == "buildings") {
				WorldBuilderStructureLibrary::showRoot(player);
				return SUCCESS;
			} else if (action == "exterior" || action == "exteriorbuildings") {
				WorldBuilderExteriorBuildingLibrary::showRoot(player);
				return SUCCESS;
			} else if (action == "travel") {
				WorldBuilderTravelPointEditor::show(player);
				return SUCCESS;
			} else if (action == "structureinfo" || action == "structure" || action == "inspectstructure") {
				WorldBuilderStructureInspector::show(player);
				return SUCCESS;
			} else if (action == "extend" || action == "bindextension" || action == "extendpublished") {
				result = manager->bindPublishedStructure(player, message);
			} else if (action == "extensions" || action == "extensionstatus") {
				WorldBuilderCommandUi::sendMessage(player, "World Builder Extension Targets", manager->getExtensionStatus(player));
				return SUCCESS;
			} else if (action == "unextend" || action == "unbindextension") {
				if (!tokenizer.hasMoreTokens()) {
					message = "Usage: /wb unextend <publish_id> <structure_local_id>";
				} else {
					String publishID; tokenizer.getStringToken(publishID);
					if (!tokenizer.hasMoreTokens())
						message = "Usage: /wb unextend <publish_id> <structure_local_id>";
					else
						result = manager->unbindPublishedStructure(player, publishID, tokenizer.getIntToken(), message);
				}
			} else if (action == "addstructure" || action == "placestructure") {
				if (!tokenizer.hasMoreTokens()) {
					WorldBuilderCommandUi::showInput(player, WorldBuilderCommandUi::INPUT_ADD_STRUCTURE,
						"Add Structure to World Builder Project",
						"Enter a registered SERVER building/cave template. It will be saved to the active project and initially face toward you:",
						"object/building/tatooine/cave_tatooine_style_01.iff");
					return SUCCESS;
				}
				String structureTemplate; tokenizer.getStringToken(structureTemplate);
				float distance = tokenizer.hasMoreTokens() ? tokenizer.getFloatToken() : 15.0f;
				result = manager->addStructure(player, structureTemplate, distance, message);
			} else if (action == "addexterior") {
				if (!tokenizer.hasMoreTokens()) {
					message = "Usage: /wb addexterior <server_template> [distance]";
				} else {
					String exteriorTemplate; tokenizer.getStringToken(exteriorTemplate);
					float distance = tokenizer.hasMoreTokens() ? tokenizer.getFloatToken() : 15.0f;
					result = manager->addExteriorBuilding(player, exteriorTemplate, distance, message);
				}
			} else if (action == "structurepreview" || action == "previewstructure") {
				if (!tokenizer.hasMoreTokens()) {
					WorldBuilderCommandUi::showInput(player, WorldBuilderCommandUi::INPUT_STRUCTURE_PREVIEW,
						"World Builder Structure Preview",
						"Enter a registered SERVER building/cave template path. This preview is transient and is not saved to the project yet:",
						"object/building/tatooine/cave_tatooine_style_01.iff");
					return SUCCESS;
				}
				String structureTemplate; tokenizer.getStringToken(structureTemplate);
				float distance = tokenizer.hasMoreTokens() ? tokenizer.getFloatToken() : 12.0f;
				result = WorldBuilderStructurePreview::spawn(player, structureTemplate, distance, message);
			} else if (action == "structureclear" || action == "clearstructure") {
				result = WorldBuilderStructurePreview::clear(player, message);
			} else if (action == "cellinfo" || action == "cellcontext") {
				WorldBuilderCommandUi::sendMessage(player, "World Builder Cell Context", WorldBuilderStructurePreview::getCellContext(player));
				return SUCCESS;
			} else if (action == "refreshpublished" || action == "preparerepublish" || action == "refreshpublish") {
				if (!tokenizer.hasMoreTokens()) {
					WorldBuilderCommandUi::sendMessage(player, "World Builder Published Refresh",
						"Usage: /wb refreshpublished <project> [confirm]\n\nRun without confirm first for the mandatory safety dry-run.");
					return SUCCESS;
				}

				String projectName;
				tokenizer.getStringToken(projectName);
				bool confirmRefresh = false;

				if (tokenizer.hasMoreTokens()) {
					String confirmation;
					tokenizer.getStringToken(confirmation);
					confirmation = confirmation.toLowerCase();

					if (confirmation != "confirm") {
						WorldBuilderCommandUi::sendMessage(player, "World Builder Published Refresh",
							"The only accepted second argument is 'confirm'. Run the command without it first for a dry-run.");
						return SUCCESS;
					}

					confirmRefresh = true;
				}

				String refreshMessage;
				bool refreshResult = WorldBuilderPublishedRefresh::run(player, projectName, confirmRefresh, refreshMessage);
				WorldBuilderCommandUi::sendMessage(player, "World Builder Published Refresh", refreshMessage);
				return refreshResult ? SUCCESS : INVALIDPARAMETERS;
			} else if (action == "save") {
				result = manager->saveProject(player, message);
			} else if (action == "close") {
				result = manager->closeProject(player, true, message);
			} else if (action == "export") {
				result = manager->exportLua(player, message);
			} else if (action == "spawn") {
				if (!tokenizer.hasMoreTokens()) {
					WorldBuilderCommandUi::showInput(player, WorldBuilderCommandUi::INPUT_SPAWN_TEMPLATE,
						"Spawn World Builder Object", "Enter a registered server object template path:", manager->getLastTemplate(player));
					return SUCCESS;
				}
				String objectTemplate; tokenizer.getStringToken(objectTemplate);
				float distance = tokenizer.hasMoreTokens() ? tokenizer.getFloatToken() : 3.0f;
				result = manager->spawnTemplate(player, objectTemplate, distance, message);
			} else if (action == "last") {
				float distance = tokenizer.hasMoreTokens() ? tokenizer.getFloatToken() : 3.0f;
				result = manager->spawnLastTemplate(player, distance, message);
			} else if (action == "objects" || action == "list") {
				WorldBuilderCommandUi::showObjectList(player);
				return SUCCESS;
			} else if (action == "target") {
				result = manager->selectTarget(player, message);
			} else if (action == "select") {
				if (!tokenizer.hasMoreTokens()) { message = "Usage: /wb select <localID>"; }
				else result = manager->selectObject(player, tokenizer.getIntToken(), message);
			} else if (action == "next") {
				result = manager->selectRelative(player, 1, message);
			} else if (action == "prev" || action == "previous") {
				result = manager->selectRelative(player, -1, message);
			} else if (action == "move") {
				if (!tokenizer.hasMoreTokens()) { message = "Usage: /wb move <direction> [meters]"; }
				else {
					String direction; tokenizer.getStringToken(direction);
					float amount = tokenizer.hasMoreTokens() ? tokenizer.getFloatToken() : 0.0f;
					result = manager->moveSelected(player, direction, amount, message);
				}
			} else if (action == "f" || action == "b" || action == "l" || action == "r" || action == "u" || action == "d") {
				float amount = tokenizer.hasMoreTokens() ? tokenizer.getFloatToken() : 0.0f;
				result = manager->moveSelected(player, action, amount, message);
			} else if (action == "yaw" || action == "pitch" || action == "roll") {
				float degrees = tokenizer.hasMoreTokens() ? tokenizer.getFloatToken() : 0.0f;
				result = manager->rotateSelected(player, action, degrees, message);
			} else if (action == "step") {
				if (!tokenizer.hasMoreTokens()) message = "Usage: /wb step <meters>";
				else result = manager->setMoveStep(player, tokenizer.getFloatToken(), message);
			} else if (action == "rotstep") {
				if (!tokenizer.hasMoreTokens()) message = "Usage: /wb rotstep <degrees>";
				else result = manager->setRotateStep(player, tokenizer.getFloatToken(), message);
			} else if (action == "snap") {
				result = manager->snapSelectedToPlayer(player, message);
			} else if (action == "front") {
				float distance = tokenizer.hasMoreTokens() ? tokenizer.getFloatToken() : 3.0f;
				result = manager->putSelectedInFront(player, distance, message);
			} else if (action == "duplicate" || action == "clone") {
				float offset = tokenizer.hasMoreTokens() ? tokenizer.getFloatToken() : 0.0f;
				result = manager->duplicateSelected(player, offset, message);
			} else if (action == "delete" || action == "remove") {
				result = manager->deleteSelected(player, message);
			} else if (action == "undo") {
				result = manager->undo(player, message);
			} else if (action == "redo") {
				result = manager->redo(player, message);
			} else if (action == "snaptype") {
				if (!tokenizer.hasMoreTokens()) message = "Usage: /wb snaptype <value|-1 for auto>";
				else result = manager->setSnapshotGameObjectType(player, tokenizer.getFloatToken(), message);
			} else if (action == "group") {
				if (!tokenizer.hasMoreTokens()) {
					message = "Usage: /wb group add|remove|clear|move|rotate|duplicate ...";
				} else {
					String groupAction; tokenizer.getStringToken(groupAction); groupAction = groupAction.toLowerCase();
					if (groupAction == "add") result = manager->groupAddSelected(player, message);
					else if (groupAction == "remove") result = manager->groupRemoveSelected(player, message);
					else if (groupAction == "clear") result = manager->groupClear(player, message);
					else if (groupAction == "move") {
						if (!tokenizer.hasMoreTokens()) message = "Usage: /wb group move <direction> [meters]";
						else {
							String direction; tokenizer.getStringToken(direction);
							float amount = tokenizer.hasMoreTokens() ? tokenizer.getFloatToken() : 0.0f;
							result = manager->groupMove(player, direction, amount, message);
						}
					} else if (groupAction == "rotate") {
						if (!tokenizer.hasMoreTokens()) message = "Usage: /wb group rotate <yaw|pitch|roll> [degrees]";
						else {
							String axis; tokenizer.getStringToken(axis);
							float degrees = tokenizer.hasMoreTokens() ? tokenizer.getFloatToken() : 0.0f;
							result = manager->groupRotate(player, axis, degrees, message);
						}
					} else if (groupAction == "duplicate" || groupAction == "clone") {
						float offset = tokenizer.hasMoreTokens() ? tokenizer.getFloatToken() : 1.0f;
						result = manager->groupDuplicate(player, offset, message);
					} else message = "Unknown group action.";
				}
			} else if (action == "status" || action == "info") {
				WorldBuilderCommandUi::sendMessage(player, "World Builder Status", manager->getStatus(player));
				return SUCCESS;
			} else if (action == "help" || action == "?") {
				WorldBuilderCommandUi::sendMessage(player, "World Builder Help", manager->getHelp(player));
				return SUCCESS;
			} else {
				message = "Unknown World Builder action. Use /wb help.";
			}
		} catch (Exception& e) {
			message = "Invalid command parameters. Use /wb help.";
			result = false;
		}

		player->sendSystemMessage(String("[World Builder] ") + (result ? "" : "ERROR: ") + message);
		return result ? SUCCESS : INVALIDPARAMETERS;
	}
};

// Short alias. The Lua command registry instantiates WbCommand for /wb.
class WbCommand : public WorldBuilderCommand {
public:
	WbCommand(const String& name, ZoneProcessServer* server) : WorldBuilderCommand(name, server) {
	}
};

#endif /* WORLDBUILDERCOMMAND_H_ */
