/*
 * WorldBuilderManager.cpp
 *
 * Bellum Gero World Builder
 */

#include "WorldBuilderManager.h"

#include "templates/manager/TemplateManager.h"
#include "templates/SharedObjectTemplate.h"
#include "templates/tangible/SharedStructureObjectTemplate.h"
#include "server/zone/Zone.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/scene/SceneObjectType.h"

#include <cstdio>
#include <cstring>
#include <sys/stat.h>
#include <sys/types.h>
#include <algorithm>
#include <string>
#include <vector>
#ifndef _WIN32
#include <dirent.h>
#endif
#ifdef _WIN32
#include <direct.h>
#endif


namespace {
static const char* WB_ROOT_DIR = "worldbuilder";
static const char* WB_PROJECT_DIR = "worldbuilder/projects";

bool wbPathIsDirectory(const char* path) {
	struct stat st;
	if (::stat(path, &st) != 0)
		return false;

#ifdef _WIN32
	return (st.st_mode & _S_IFDIR) != 0;
#else
	return (st.st_mode & S_IFDIR) != 0;
#endif
}

bool wbEnsureDirectory(const char* path) {
	if (wbPathIsDirectory(path))
		return true;

#ifdef _WIN32
	int result = ::_mkdir(path);
#else
	int result = ::mkdir(path, 0755);
#endif

	return result == 0 || wbPathIsDirectory(path);
}

bool wbEnsureProjectDirectory() {
	return wbEnsureDirectory(WB_ROOT_DIR) && wbEnsureDirectory(WB_PROJECT_DIR);
}

bool wbFileExists(const String& path) {
	struct stat st;
	return ::stat(path.toCharArray(), &st) == 0 && (st.st_mode & S_IFREG);
}

bool wbCopyFile(const String& sourcePath, const String& destinationPath) {
	std::FILE* source = std::fopen(sourcePath.toCharArray(), "rb");
	if (source == nullptr)
		return false;

	std::FILE* destination = std::fopen(destinationPath.toCharArray(), "wb");
	if (destination == nullptr) {
		std::fclose(source);
		return false;
	}

	char buffer[65536];
	bool copyOK = true;

	while (true) {
		size_t bytesRead = std::fread(buffer, 1, sizeof(buffer), source);

		if (bytesRead > 0 && std::fwrite(buffer, 1, bytesRead, destination) != bytesRead) {
			copyOK = false;
			break;
		}

		if (bytesRead < sizeof(buffer)) {
			if (std::ferror(source) != 0)
				copyOK = false;
			break;
		}
	}

	if (std::fclose(source) != 0)
		copyOK = false;

	if (std::fclose(destination) != 0)
		copyOK = false;

	if (!copyOK) {
		std::remove(destinationPath.toCharArray());
		return false;
	}

	return wbFileExists(destinationPath);
}

bool wbFilesEqual(const String& firstPath, const String& secondPath) {
	std::FILE* first = std::fopen(firstPath.toCharArray(), "rb");
	if (first == nullptr)
		return false;

	std::FILE* second = std::fopen(secondPath.toCharArray(), "rb");
	if (second == nullptr) {
		std::fclose(first);
		return false;
	}

	char firstBuffer[65536];
	char secondBuffer[65536];
	bool equal = true;

	while (true) {
		size_t firstRead = std::fread(firstBuffer, 1, sizeof(firstBuffer), first);
		size_t secondRead = std::fread(secondBuffer, 1, sizeof(secondBuffer), second);

		if (firstRead != secondRead || (firstRead > 0 && std::memcmp(firstBuffer, secondBuffer, firstRead) != 0)) {
			equal = false;
			break;
		}

		if (firstRead < sizeof(firstBuffer)) {
			if (std::ferror(first) != 0 || std::ferror(second) != 0)
				equal = false;
			break;
		}
	}

	std::fclose(first);
	std::fclose(second);
	return equal;
}

bool wbWriteLine(std::FILE* file, const String& line) {
	if (file == nullptr)
		return false;

	const char* data = line.toCharArray();
	size_t length = static_cast<size_t>(line.length());

	if (length > 0 && std::fwrite(data, 1, length, file) != length)
		return false;

	const char newline = '\n';
	return std::fwrite(&newline, 1, 1, file) == 1;
}

// Project-management operations validate a backup before allowing it to replace
// an active project. The project format currently requires this exact V1 header.
bool wbProjectFileHasValidHeader(const String& path) {
	std::FILE* file = std::fopen(path.toCharArray(), "rb");
	if (file == nullptr)
		return false;

	char buffer[512];
	bool valid = false;

	while (std::fgets(buffer, sizeof(buffer), file) != nullptr) {
		String line(buffer);
		line = line.trim();

		if (line.isEmpty())
			continue;

		valid = line == "BELLUM_GERO_WORLD_BUILDER 1";
		break;
	}

	std::fclose(file);
	return valid;
}
}

const float WorldBuilderManager::DEFAULT_MOVE_STEP = 0.10f;
const float WorldBuilderManager::DEFAULT_ROTATE_STEP = 5.0f;
const float WorldBuilderManager::DEFAULT_SPAWN_DISTANCE = 3.0f;

WorldBuilderObjectState::WorldBuilderObjectState() :
	localID(0), runtimeObjectID(0), x(0), z(0), y(0), qw(1), qx(0), qy(0), qz(0),
	snapshotGameObjectType(-1.0f), parentID(0) {
}

WorldBuilderProjectState::WorldBuilderProjectState() : selectedLocalID(0), nextLocalID(1) {
}

WorldBuilderSession::WorldBuilderSession() :
	moveStep(0.10f),
	rotateStep(5.0f),
	selectedLocalID(0), nextLocalID(1) {
}

WorldBuilderManager::WorldBuilderManager() {
	sessions.setNullValue(nullptr);
}

bool WorldBuilderManager::isAuthorized(CreatureObject* player) const {
	if (player == nullptr || !player->isPlayerCreature())
		return false;

	PlayerObject* ghost = player->getPlayerObject().get();
	return ghost != nullptr && ghost->getAdminLevel() >= 15;
}

Reference<WorldBuilderSession*> WorldBuilderManager::getSessionForPlayerID(uint64 playerID) {
	Locker locker(&sessionsLock);
	return sessions.get(playerID);
}

Reference<WorldBuilderSession*> WorldBuilderManager::getSessionForPlayer(CreatureObject* player) {
	if (player == nullptr)
		return nullptr;

	return getSessionForPlayerID(player->getObjectID());
}

bool WorldBuilderManager::hasSession(CreatureObject* player) {
	return getSessionForPlayer(player) != nullptr;
}

String WorldBuilderManager::sanitizeProjectName(const String& name) const {
	String input = name.trim();
	StringBuffer safe;

	for (int i = 0; i < input.length(); ++i) {
		char c = input.charAt(i);
		bool valid = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
			(c >= '0' && c <= '9') || c == '_' || c == '-';

		if (valid)
			safe << c;
		else if (c == ' ')
			safe << '_';
	}

	return safe.toString();
}

String WorldBuilderManager::getProjectFilePath(const String& safeProjectName) const {
	return "worldbuilder/projects/" + safeProjectName + ".wbp";
}

String WorldBuilderManager::getLuaExportFilePath(const String& safeProjectName) const {
	return "worldbuilder/projects/" + safeProjectName + "_export.lua";
}

String WorldBuilderManager::deriveSnapshotTemplate(const String& objectTemplate) const {
	int slash = objectTemplate.lastIndexOf("/");
	if (slash < 0)
		return objectTemplate;

	String directory = objectTemplate.subString(0, slash + 1);
	String filename = objectTemplate.subString(slash + 1);

	if (filename.beginsWith("shared_"))
		return objectTemplate;

	return directory + "shared_" + filename;
}

String WorldBuilderManager::getTemplateShortName(const String& objectTemplate) const {
	int slash = objectTemplate.lastIndexOf("/");
	String name = slash >= 0 ? objectTemplate.subString(slash + 1) : objectTemplate;

	if (name.endsWith(".iff"))
		name = name.subString(0, name.length() - 4);

	return name;
}

int WorldBuilderManager::findObjectIndexByLocalID(WorldBuilderSession* session, uint32 localID) const {
	if (session == nullptr || localID == 0)
		return -1;

	for (int i = 0; i < session->objects.size(); ++i) {
		if (session->objects.get(i).localID == localID)
			return i;
	}

	return -1;
}

int WorldBuilderManager::findObjectIndexByRuntimeID(WorldBuilderSession* session, uint64 runtimeID) const {
	if (session == nullptr || runtimeID == 0)
		return -1;

	for (int i = 0; i < session->objects.size(); ++i) {
		if (session->objects.get(i).runtimeObjectID == runtimeID)
			return i;
	}

	return -1;
}

bool WorldBuilderManager::isInGroup(WorldBuilderSession* session, uint32 localID) const {
	if (session == nullptr)
		return false;

	for (int i = 0; i < session->groupIDs.size(); ++i) {
		if (session->groupIDs.get(i) == localID)
			return true;
	}

	return false;
}

bool WorldBuilderManager::captureObjectState(WorldBuilderObjectState& state, CreatureObject* player) const {
	if (player == nullptr || state.runtimeObjectID == 0)
		return false;

	ZoneServer* zoneServer = player->getZoneServer();
	if (zoneServer == nullptr)
		return false;

	ManagedReference<SceneObject*> object = zoneServer->getObject(state.runtimeObjectID);
	if (object == nullptr)
		return false;

	state.x = object->getPositionX();
	state.z = object->getPositionZ();
	state.y = object->getPositionY();

	const Quaternion* direction = object->getDirection();
	if (direction != nullptr) {
		state.qw = direction->getW();
		state.qx = direction->getX();
		state.qy = direction->getY();
		state.qz = direction->getZ();
	}

	ManagedReference<SceneObject*> parent = object->getParent().get();
	state.parentID = parent != nullptr ? parent->getObjectID() : 0;
	return true;
}

WorldBuilderProjectState WorldBuilderManager::captureProjectState(WorldBuilderSession* session, CreatureObject* player) const {
	WorldBuilderProjectState result;
	if (session == nullptr)
		return result;

	result.selectedLocalID = session->selectedLocalID;
	result.nextLocalID = session->nextLocalID;
	result.groupIDs = session->groupIDs;

	for (int i = 0; i < session->objects.size(); ++i) {
		WorldBuilderObjectState state = session->objects.get(i);
		captureObjectState(state, player);
		state.runtimeObjectID = 0;
		result.objects.add(state);
	}

	return result;
}

void WorldBuilderManager::pushUndoState(WorldBuilderSession* session, CreatureObject* player) {
	if (session == nullptr)
		return;

	session->undoStack.add(captureProjectState(session, player));
	while (session->undoStack.size() > MAX_HISTORY_STATES)
		session->undoStack.remove(0);

	session->redoStack.removeAll();
}

ManagedReference<SceneObject*> WorldBuilderManager::spawnStateObject(CreatureObject* player, WorldBuilderObjectState& state, String& errorMessage) {
	if (player == nullptr || player->getZone() == nullptr || player->getZoneServer() == nullptr) {
		errorMessage = "World Builder could not resolve your current zone.";
		return nullptr;
	}

	Reference<SharedObjectTemplate*> sharedTemplate = TemplateManager::instance()->getTemplate(state.objectTemplate.hashCode());
	if (sharedTemplate == nullptr) {
		errorMessage = "Template is not registered server-side: " + state.objectTemplate;
		return nullptr;
	}

	SharedStructureObjectTemplate* structureTemplate = dynamic_cast<SharedStructureObjectTemplate*>(sharedTemplate.get());
	if (structureTemplate != nullptr && structureTemplate->getGameObjectType() != SceneObjectType::STATICOBJECT) {
		errorMessage = "World Builder V1 does not spawn real deed/structure objects. Use a static/template equivalent instead: " + state.objectTemplate;
		return nullptr;
	}

	ZoneServer* zoneServer = player->getZoneServer();
	ManagedReference<SceneObject*> object = zoneServer->createObject(state.objectTemplate.hashCode(), 0);

	if (object == nullptr || object->isIntangibleObject()) {
		errorMessage = "Could not create scene object from: " + state.objectTemplate;
		return nullptr;
	}

	Locker objectLocker(object, player);
	object->initializePosition(state.x, state.z, state.y);
	object->setDirection(state.qw, state.qx, state.qy, state.qz);

	if (state.parentID != 0) {
		ManagedReference<SceneObject*> parent = zoneServer->getObject(state.parentID);
		if (parent == nullptr || !parent->isCellObject()) {
			object->destroyObjectFromDatabase(true);
			errorMessage = "Saved parent/cell " + String::valueOf(state.parentID) + " is unavailable.";
			return nullptr;
		}

		parent->transferObject(object, -1);
	} else {
		player->getZone()->transferObject(object, -1, true);
	}

	object->createChildObjects();
	state.runtimeObjectID = object->getObjectID();
	return object;
}

void WorldBuilderManager::destroyRuntimeObject(CreatureObject* player, WorldBuilderObjectState& state) const {
	if (player == nullptr || state.runtimeObjectID == 0 || player->getZoneServer() == nullptr)
		return;

	ManagedReference<SceneObject*> object = player->getZoneServer()->getObject(state.runtimeObjectID);
	if (object != nullptr) {
		Locker objectLocker(object, player);
		object->destroyObjectFromWorld(true);
		object->destroyObjectFromDatabase(true);
	}

	state.runtimeObjectID = 0;
}

void WorldBuilderManager::destroyAllRuntimeObjects(WorldBuilderSession* session, CreatureObject* player) const {
	if (session == nullptr)
		return;

	for (int i = 0; i < session->objects.size(); ++i) {
		WorldBuilderObjectState& state = session->objects.elementAt(i);
		destroyRuntimeObject(player, state);
	}
}

bool WorldBuilderManager::restoreProjectState(WorldBuilderSession* session, CreatureObject* player, const WorldBuilderProjectState& state, String& message) {
	if (session == nullptr || player == nullptr)
		return false;

	destroyAllRuntimeObjects(session, player);
	session->objects.removeAll();
	session->groupIDs = state.groupIDs;
	session->selectedLocalID = state.selectedLocalID;
	session->nextLocalID = state.nextLocalID;

	for (int i = 0; i < state.objects.size(); ++i) {
		WorldBuilderObjectState objectState = state.objects.get(i);
		String error;
		ManagedReference<SceneObject*> object = spawnStateObject(player, objectState, error);

		if (object == nullptr) {
			destroyAllRuntimeObjects(session, player);
			session->objects.removeAll();
			message = "Restore failed while respawning #" + String::valueOf(objectState.localID) + ": " + error;
			return false;
		}

		session->objects.add(objectState);
	}

	if (findObjectIndexByLocalID(session, session->selectedLocalID) < 0)
		session->selectedLocalID = session->objects.size() > 0 ? session->objects.get(0).localID : 0;

	message = "Project state restored.";
	return true;
}

bool WorldBuilderManager::saveSession(WorldBuilderSession* session, CreatureObject* player, String& message, bool quiet) {
	if (session == nullptr || player == nullptr)
		return false;

	if (!wbEnsureProjectDirectory()) {
		message = "Could not create the World Builder storage directory under the Core3 bin directory.";
		return false;
	}

	for (int i = 0; i < session->objects.size(); ++i)
		captureObjectState(session->objects.elementAt(i), player);

	String path = getProjectFilePath(session->projectName);
	String tempPath = path + ".tmp";
	String backupPath = path + ".bak";

	// Always write a complete temporary file first. The live project file is
	// not touched until the new save has been fully written and closed.
	std::FILE* file = std::fopen(tempPath.toCharArray(), "wb");

	if (file == nullptr) {
		message = "Could not open World Builder temporary project file for writing: " + tempPath;
		return false;
	}

	bool writeOK = true;

	writeOK = writeOK && wbWriteLine(file, "BELLUM_GERO_WORLD_BUILDER 1");
	writeOK = writeOK && wbWriteLine(file, "PROJECT " + session->projectName);
	writeOK = writeOK && wbWriteLine(file, "PLANET " + session->planetName);
	writeOK = writeOK && wbWriteLine(file, "MOVE_STEP " + String::valueOf(session->moveStep));
	writeOK = writeOK && wbWriteLine(file, "ROTATE_STEP " + String::valueOf(session->rotateStep));
	writeOK = writeOK && wbWriteLine(file, "SELECTED " + String::valueOf(session->selectedLocalID));
	writeOK = writeOK && wbWriteLine(file, "NEXT_ID " + String::valueOf(session->nextLocalID));
	writeOK = writeOK && wbWriteLine(file, "LAST_TEMPLATE " + (session->lastTemplate.isEmpty() ? String("-") : session->lastTemplate));

	for (int i = 0; writeOK && i < session->objects.size(); ++i) {
		const WorldBuilderObjectState& state = session->objects.get(i);
		StringBuffer line;
		line << "OBJECT " << state.localID << " " << state.objectTemplate << " "
			 << (state.snapshotTemplate.isEmpty() ? deriveSnapshotTemplate(state.objectTemplate) : state.snapshotTemplate) << " "
			 << state.x << " " << state.z << " " << state.y << " "
			 << state.qw << " " << state.qx << " " << state.qy << " " << state.qz << " "
			 << state.snapshotGameObjectType << " " << state.parentID;
		writeOK = wbWriteLine(file, line.toString());
	}

	if (writeOK && session->groupIDs.size() > 0) {
		StringBuffer group;
		group << "GROUP";
		for (int i = 0; i < session->groupIDs.size(); ++i)
			group << " " << session->groupIDs.get(i);
		writeOK = wbWriteLine(file, group.toString());
	}

	if (std::fclose(file) != 0)
		writeOK = false;

	if (!writeOK || !wbFileExists(tempPath)) {
		std::remove(tempPath.toCharArray());
		message = "World Builder project save failed while writing the temporary file: " + tempPath;
		return false;
	}

	// A redundant save (including an unchanged /wb close after loading) must NOT
	// rotate .wbp.bak. Keeping the last genuinely different save makes backups
	// useful for restore instead of replacing them with an identical copy.
	if (wbFileExists(path) && wbFilesEqual(path, tempPath)) {
		std::remove(tempPath.toCharArray());

		if (!quiet) {
			if (wbFileExists(backupPath))
				message = "Project is unchanged. Active save retained and existing safety backup preserved at " + backupPath + ".";
			else
				message = "Project is unchanged. Active save retained; no backup rotation was needed.";
		}

		return true;
	}

	// Preserve the immediately previous successful save before replacing it.
	// This gives every project a simple recovery point at <project>.wbp.bak.
	if (wbFileExists(path)) {
		if (!wbCopyFile(path, backupPath)) {
			std::remove(tempPath.toCharArray());
			message = "World Builder refused to overwrite the current project because its safety backup could not be created: " + backupPath;
			return false;
		}
	}

	// On the Linux Core3 runtime, rename() atomically replaces the destination.
	// Keep a fallback for environments where replacement requires removing the
	// destination first; the .bak copy above protects the previous save.
	if (std::rename(tempPath.toCharArray(), path.toCharArray()) != 0) {
		std::remove(path.toCharArray());

		if (std::rename(tempPath.toCharArray(), path.toCharArray()) != 0) {
			if (wbFileExists(backupPath))
				wbCopyFile(backupPath, path);

			std::remove(tempPath.toCharArray());
			message = "World Builder could not promote the temporary save into the active project file: " + path;
			return false;
		}
	}

	if (!wbFileExists(path)) {
		if (wbFileExists(backupPath))
			wbCopyFile(backupPath, path);

		message = "World Builder project save verification failed for " + path;
		return false;
	}

	if (!quiet)
		message = "Saved " + String::valueOf(session->objects.size()) + " object(s) to " + path + ". Previous save: " + backupPath;

	return true;
}

bool WorldBuilderManager::loadSessionFile(const String& safeProjectName, WorldBuilderSession* session, String& message) {
	if (session == nullptr)
		return false;

	if (!wbEnsureProjectDirectory()) {
		message = "Could not access the World Builder storage directory under the Core3 bin directory.";
		return false;
	}

	String path = getProjectFilePath(safeProjectName);

	// Use the same libc filesystem API for loading that saveSession() uses for
	// writing. Core3's engine File/FileReader abstraction can resolve relative
	// paths differently from std::fopen() in the runtime container, which made
	// a just-saved .wbp file appear missing immediately after /wb close.
	if (!wbFileExists(path)) {
		message = "Project file not found: " + path;
		return false;
	}

	std::FILE* file = std::fopen(path.toCharArray(), "rb");
	if (file == nullptr) {
		message = "Could not open World Builder project file for reading: " + path;
		return false;
	}

	char buffer[8192];
	bool validHeader = false;
	bool parseOK = true;

	while (std::fgets(buffer, sizeof(buffer), file) != nullptr) {
		String line(buffer);
		line = line.trim();

		if (line.isEmpty())
			continue;

		StringTokenizer tokenizer(line);
		String type;
		tokenizer.getStringToken(type);

		if (type == "BELLUM_GERO_WORLD_BUILDER") {
			int version = tokenizer.hasMoreTokens() ? tokenizer.getIntToken() : 0;
			if (version != 1) {
				message = "Unsupported World Builder project version: " + String::valueOf(version);
				parseOK = false;
				break;
			}
			validHeader = true;
		} else if (type == "PROJECT") {
			if (tokenizer.hasMoreTokens())
				tokenizer.getStringToken(session->projectName);
		} else if (type == "PLANET") {
			if (tokenizer.hasMoreTokens())
				tokenizer.getStringToken(session->planetName);
		} else if (type == "MOVE_STEP") {
			if (tokenizer.hasMoreTokens())
				session->moveStep = tokenizer.getFloatToken();
		} else if (type == "ROTATE_STEP") {
			if (tokenizer.hasMoreTokens())
				session->rotateStep = tokenizer.getFloatToken();
		} else if (type == "SELECTED") {
			if (tokenizer.hasMoreTokens())
				session->selectedLocalID = tokenizer.getIntToken();
		} else if (type == "NEXT_ID") {
			if (tokenizer.hasMoreTokens())
				session->nextLocalID = tokenizer.getIntToken();
		} else if (type == "LAST_TEMPLATE") {
			if (tokenizer.hasMoreTokens()) {
				String value;
				tokenizer.getStringToken(value);
				if (value != "-")
					session->lastTemplate = value;
			}
		} else if (type == "OBJECT") {
			WorldBuilderObjectState state;

			if (!tokenizer.hasMoreTokens())
				continue;

			state.localID = tokenizer.getIntToken();
			tokenizer.getStringToken(state.objectTemplate);
			tokenizer.getStringToken(state.snapshotTemplate);
			state.x = tokenizer.getFloatToken();
			state.z = tokenizer.getFloatToken();
			state.y = tokenizer.getFloatToken();
			state.qw = tokenizer.getFloatToken();
			state.qx = tokenizer.getFloatToken();
			state.qy = tokenizer.getFloatToken();
			state.qz = tokenizer.getFloatToken();
			state.snapshotGameObjectType = tokenizer.getFloatToken();

			String parentToken;
			tokenizer.getStringToken(parentToken);
			state.parentID = UnsignedLong::valueOf(parentToken);
			state.runtimeObjectID = 0;

			session->objects.add(state);
		} else if (type == "GROUP") {
			while (tokenizer.hasMoreTokens())
				session->groupIDs.add(tokenizer.getIntToken());
		}
	}

	if (std::ferror(file) != 0) {
		message = "Error while reading World Builder project file: " + path;
		parseOK = false;
	}

	std::fclose(file);

	if (!parseOK)
		return false;

	if (!validHeader) {
		message = "Invalid World Builder project header in " + path;
		return false;
	}

	// The filename selected by the admin is authoritative. This keeps a safely
	// renamed project tied to its new filename even if an older PROJECT line is
	// still present inside a historical backup. The next save rewrites the line.
	session->projectName = safeProjectName;

	return true;
}

void WorldBuilderManager::autosave(WorldBuilderSession* session, CreatureObject* player) {
	String ignored;
	if (!saveSession(session, player, ignored, true) && player != nullptr)
		player->sendSystemMessage("[World Builder] Warning: autosave failed. Use /wb save and check the server console/path permissions.");
}

bool WorldBuilderManager::createProject(CreatureObject* player, const String& projectName, String& message) {
	if (!isAuthorized(player)) {
		message = "World Builder requires admin level 15.";
		return false;
	}

	if (hasSession(player)) {
		message = "Close the current World Builder project first (/wb close).";
		return false;
	}

	String safeName = sanitizeProjectName(projectName);
	if (safeName.isEmpty()) {
		message = "Project name must contain letters or numbers.";
		return false;
	}

	if (!wbEnsureProjectDirectory()) {
		message = "Could not access the World Builder storage directory under the Core3 bin directory.";
		return false;
	}

	String existingPath = getProjectFilePath(safeName);
	String existingBackupPath = existingPath + ".bak";
	String existingTempPath = existingPath + ".tmp";
	String existingRestoreBackupTemp = existingPath + ".restore.backup.tmp";
	String existingRestoreCurrentTemp = existingPath + ".restore.current.tmp";
	if (wbFileExists(existingPath) || wbFileExists(existingBackupPath) || wbFileExists(existingTempPath) ||
		wbFileExists(existingRestoreBackupTemp) || wbFileExists(existingRestoreCurrentTemp)) {
		message = "Project '" + safeName + "' already exists or has safety/recovery data. New Project is blocked from reusing that name. Use Load/Manage Saved Projects, inspect any recovery temp files, or choose a different name.";
		return false;
	}

	Zone* zone = player->getZone();
	if (zone == nullptr) {
		message = "You must be in a ground zone to start a World Builder project.";
		return false;
	}

	Reference<WorldBuilderSession*> session = new WorldBuilderSession();
	session->projectName = safeName;
	session->planetName = zone->getZoneName();

	{
		Locker locker(&sessionsLock);
		sessions.put(player->getObjectID(), session);
	}

	if (!saveSession(session, player, message, false)) {
		Locker locker(&sessionsLock);
		sessions.drop(player->getObjectID());
		message = "Could not create World Builder project: " + message;
		return false;
	}

	message = "World Builder project '" + safeName + "' created on " + session->planetName + ". Autosave is active.";
	return true;
}

bool WorldBuilderManager::loadProject(CreatureObject* player, const String& projectName, String& message) {
	if (!isAuthorized(player)) {
		message = "World Builder requires admin level 15.";
		return false;
	}

	if (hasSession(player)) {
		message = "Close the current World Builder project first (/wb close).";
		return false;
	}

	String safeName = sanitizeProjectName(projectName);
	Reference<WorldBuilderSession*> session = new WorldBuilderSession();
	if (!loadSessionFile(safeName, session, message))
		return false;

	if (player->getZone() == nullptr || player->getZone()->getZoneName() != session->planetName) {
		message = "Project is on '" + session->planetName + "'. Travel there before loading it.";
		return false;
	}

	for (int i = 0; i < session->objects.size(); ++i) {
		String error;
		if (spawnStateObject(player, session->objects.elementAt(i), error) == nullptr) {
			destroyAllRuntimeObjects(session, player);
			message = "Project load aborted at object #" + String::valueOf(session->objects.get(i).localID) + ": " + error;
			return false;
		}
	}

	if (findObjectIndexByLocalID(session, session->selectedLocalID) < 0)
		session->selectedLocalID = session->objects.size() > 0 ? session->objects.get(0).localID : 0;

	{
		Locker locker(&sessionsLock);
		sessions.put(player->getObjectID(), session);
	}

	message = "Loaded World Builder project '" + session->projectName + "' with " + String::valueOf(session->objects.size()) + " object(s).";
	return true;
}

bool WorldBuilderManager::renameSavedProject(CreatureObject* player, const String& projectName, const String& newProjectName, String& message) {
	if (!isAuthorized(player)) {
		message = "World Builder requires admin level 15.";
		return false;
	}

	if (hasSession(player)) {
		message = "Close the current World Builder project before managing saved project files.";
		return false;
	}

	if (!wbEnsureProjectDirectory()) {
		message = "Could not access the World Builder storage directory under the Core3 bin directory.";
		return false;
	}

	String oldName = sanitizeProjectName(projectName);
	String newName = sanitizeProjectName(newProjectName);

	if (oldName.isEmpty() || newName.isEmpty()) {
		message = "Project name must contain letters or numbers.";
		return false;
	}

	if (oldName == newName) {
		message = "Project is already named '" + newName + "'.";
		return true;
	}

	String oldPath = getProjectFilePath(oldName);
	String oldBackupPath = oldPath + ".bak";
	String newPath = getProjectFilePath(newName);
	String newBackupPath = newPath + ".bak";
	String newTempPath = newPath + ".tmp";
	String newRestoreBackupTemp = newPath + ".restore.backup.tmp";
	String newRestoreCurrentTemp = newPath + ".restore.current.tmp";

	bool hasActive = wbFileExists(oldPath);
	bool hasBackup = wbFileExists(oldBackupPath);

	if (!hasActive && !hasBackup) {
		message = "Saved project '" + oldName + "' was not found.";
		return false;
	}

	// Rename follows the same no-overwrite rule as New Project, and also refuses
	// a stale target .tmp so an interrupted save can never be hidden/replaced.
	if (wbFileExists(newPath) || wbFileExists(newBackupPath) || wbFileExists(newTempPath) ||
		wbFileExists(newRestoreBackupTemp) || wbFileExists(newRestoreCurrentTemp)) {
		message = "Cannot rename to '" + newName + "' because that project name already has saved, temporary, or recovery World Builder data.";
		return false;
	}

	bool activeMoved = false;

	if (hasActive) {
		if (std::rename(oldPath.toCharArray(), newPath.toCharArray()) != 0) {
			message = "Could not rename active project file from " + oldPath + " to " + newPath + ".";
			return false;
		}

		activeMoved = true;
	}

	if (hasBackup) {
		if (std::rename(oldBackupPath.toCharArray(), newBackupPath.toCharArray()) != 0) {
			if (activeMoved && std::rename(newPath.toCharArray(), oldPath.toCharArray()) != 0) {
				message = "Backup rename failed, and World Builder could not roll the active filename back automatically. No project contents were intentionally deleted; inspect worldbuilder/projects before continuing.";
				return false;
			}

			message = "Could not rename the project safety backup. The rename was cancelled and the original project name was retained.";
			return false;
		}
	}

	if ((hasActive && !wbFileExists(newPath)) || (hasBackup && !wbFileExists(newBackupPath))) {
		message = "Project rename verification failed. Inspect worldbuilder/projects before continuing.";
		return false;
	}

	message = "Renamed saved World Builder project '" + oldName + "' to '" + newName + "'.";
	if (hasBackup)
		message += " Its .wbp.bak safety backup was renamed with it.";

	return true;
}

bool WorldBuilderManager::restoreProjectBackup(CreatureObject* player, const String& projectName, String& message) {
	if (!isAuthorized(player)) {
		message = "World Builder requires admin level 15.";
		return false;
	}

	if (hasSession(player)) {
		message = "Close the current World Builder project before restoring a saved backup.";
		return false;
	}

	if (!wbEnsureProjectDirectory()) {
		message = "Could not access the World Builder storage directory under the Core3 bin directory.";
		return false;
	}

	String safeName = sanitizeProjectName(projectName);
	if (safeName.isEmpty()) {
		message = "Invalid project name.";
		return false;
	}

	String path = getProjectFilePath(safeName);
	String backupPath = path + ".bak";
	String restoreTargetTemp = path + ".restore.backup.tmp";
	String restoreCurrentTemp = path + ".restore.current.tmp";

	if (!wbFileExists(backupPath)) {
		message = "No safety backup exists for project '" + safeName + "'.";
		return false;
	}

	if (!wbProjectFileHasValidHeader(backupPath)) {
		message = "Backup restore refused because " + backupPath + " does not contain a valid World Builder V1 project header.";
		return false;
	}

	// Never overwrite recovery files left by an interrupted restore. Their
	// presence may be the only surviving copy of one side of a previous swap.
	if (wbFileExists(restoreTargetTemp) || wbFileExists(restoreCurrentTemp)) {
		message = "Backup restore refused because recovery temp files already exist for '" + safeName + "'. Inspect " + restoreTargetTemp + " and " + restoreCurrentTemp + " before retrying.";
		return false;
	}

	if (!wbCopyFile(backupPath, restoreTargetTemp) || !wbProjectFileHasValidHeader(restoreTargetTemp)) {
		std::remove(restoreTargetTemp.toCharArray());
		message = "Could not create and verify a temporary restore copy of " + backupPath + ". The active project was not changed.";
		return false;
	}

	bool hasActive = wbFileExists(path);

	if (!hasActive) {
		// Backup-only recovery: create a new active copy but intentionally retain
		// the original .bak as an additional safety copy.
		if (!wbCopyFile(restoreTargetTemp, path) || !wbProjectFileHasValidHeader(path)) {
			std::remove(restoreTargetTemp.toCharArray());
			message = "Could not restore backup-only project '" + safeName + "'. The original .bak file was retained.";
			return false;
		}

		std::remove(restoreTargetTemp.toCharArray());
		message = "Restored backup-only project '" + safeName + "' to an active .wbp file. The .wbp.bak copy was retained.";
		return true;
	}

	// When both files exist, keep recoverable copies of BOTH versions until the
	// full swap is complete. A successful restore makes the old backup active and
	// turns the previously-active project into the new .bak, so Restore can be
	// used again to swap back if needed.
	if (!wbCopyFile(path, restoreCurrentTemp)) {
		std::remove(restoreTargetTemp.toCharArray());
		message = "Could not preserve the current active project before restore. Nothing was changed.";
		return false;
	}

	if (!wbCopyFile(restoreTargetTemp, path) || !wbProjectFileHasValidHeader(path)) {
		// Restore the old active project from its protected temporary copy. Only
		// remove that recovery copy after the rollback has been verified.
		bool rollbackOK = wbCopyFile(restoreCurrentTemp, path) && wbProjectFileHasValidHeader(path);
		std::remove(restoreTargetTemp.toCharArray());

		if (rollbackOK) {
			std::remove(restoreCurrentTemp.toCharArray());
			message = "Backup restore failed while promoting the backup. The original active project was restored successfully.";
		} else {
			message = "Backup restore failed and the active-file rollback could not be verified. Recovery copy retained at " + restoreCurrentTemp + ". The original .wbp.bak was not intentionally deleted.";
		}

		return false;
	}

	if (!wbCopyFile(restoreCurrentTemp, backupPath)) {
		// Both project versions still survive: the restored version is active and
		// the previous active version remains in restoreCurrentTemp. Leave that temp
		// in place rather than deleting the only preserved copy.
		std::remove(restoreTargetTemp.toCharArray());
		message = "The backup became active, but World Builder could not rotate the previous active project into .wbp.bak. Recovery copy retained at " + restoreCurrentTemp + ". Inspect it before further saves.";
		return false;
	}

	std::remove(restoreTargetTemp.toCharArray());
	std::remove(restoreCurrentTemp.toCharArray());

	message = "Restored the safety backup for project '" + safeName + "'. The previously-active project is now its .wbp.bak recovery point. The backup is preserved across unchanged saves/closes; the next save/autosave that actually changes project data will rotate .wbp.bak again.";
	return true;
}

bool WorldBuilderManager::deleteSavedProject(CreatureObject* player, const String& projectName, bool deleteBackup, String& message) {
	if (!isAuthorized(player)) {
		message = "World Builder requires admin level 15.";
		return false;
	}

	if (hasSession(player)) {
		message = "Close the current World Builder project before deleting saved project files.";
		return false;
	}

	if (!wbEnsureProjectDirectory()) {
		message = "Could not access the World Builder storage directory under the Core3 bin directory.";
		return false;
	}

	String safeName = sanitizeProjectName(projectName);
	if (safeName.isEmpty()) {
		message = "Invalid project name.";
		return false;
	}

	String path = getProjectFilePath(safeName);
	String backupPath = path + ".bak";
	bool hasActive = wbFileExists(path);
	bool hasBackup = wbFileExists(backupPath);

	if (!hasActive && !hasBackup) {
		message = "Saved project '" + safeName + "' was not found.";
		return false;
	}

	if (!deleteBackup && !hasActive) {
		message = "Project '" + safeName + "' only has a safety backup. Use Restore Backup or choose the permanent backup-delete action.";
		return false;
	}

	// Delete the active file first. If that fails, the backup is never touched.
	// If backup deletion later fails, the remaining .bak is still recoverable and
	// remains visible in Manage Saved Projects as a Backup Only entry.
	if (hasActive && std::remove(path.toCharArray()) != 0) {
		message = "Could not delete active project file: " + path + ". The backup was not touched.";
		return false;
	}

	if (deleteBackup && hasBackup) {
		if (std::remove(backupPath.toCharArray()) != 0) {
			message = hasActive ?
				"The active project was deleted, but its safety backup could not be removed. The backup remains recoverable at " + backupPath + "." :
				"The backup-only project could not be deleted. It remains recoverable at " + backupPath + ".";
			return false;
		}
	}

	if (deleteBackup) {
		message = "Permanently deleted saved World Builder project data for '" + safeName + "' (.wbp and .wbp.bak where present).";
	} else if (hasBackup) {
		message = "Deleted the active .wbp for project '" + safeName + "' and retained its .wbp.bak safety backup. It can be restored from Manage Saved Projects.";
	} else {
		message = "Deleted saved World Builder project '" + safeName + "'. No .wbp.bak safety backup existed.";
	}

	return true;
}

void WorldBuilderManager::getSavedProjectStatus(const String& projectName, bool& hasActiveProject, bool& hasBackup) {
	hasActiveProject = false;
	hasBackup = false;

	String safeName = sanitizeProjectName(projectName);
	if (safeName.isEmpty() || !wbEnsureProjectDirectory())
		return;

	String path = getProjectFilePath(safeName);
	hasActiveProject = wbFileExists(path);
	hasBackup = wbFileExists(path + ".bak");
}

bool WorldBuilderManager::closeProject(CreatureObject* player, bool saveFirst, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr) {
		message = "No World Builder project is open.";
		return false;
	}

	if (saveFirst) {
		String saveMessage;
		if (!saveSession(session, player, saveMessage, false)) {
			message = "Close cancelled because the project could not be saved.";
			return false;
		}
	}

	destroyAllRuntimeObjects(session, player);
	{
		Locker locker(&sessionsLock);
		sessions.drop(player->getObjectID());
	}

	message = "World Builder project closed and preview objects removed.";
	return true;
}

bool WorldBuilderManager::saveProject(CreatureObject* player, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr) {
		message = "No World Builder project is open.";
		return false;
	}

	return saveSession(session, player, message, false);
}

bool WorldBuilderManager::exportLua(CreatureObject* player, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr) {
		message = "No World Builder project is open.";
		return false;
	}

	String saveMessage;
	if (!saveSession(session, player, saveMessage, true)) {
		message = "Could not save the project before export: " + saveMessage;
		return false;
	}

	if (!wbEnsureProjectDirectory()) {
		message = "Could not access the World Builder storage directory for Lua export.";
		return false;
	}

	String path = getLuaExportFilePath(session->projectName);
	std::FILE* file = std::fopen(path.toCharArray(), "wb");

	if (file == nullptr) {
		message = "Could not open Lua export file for writing: " + path;
		return false;
	}

	bool writeOK = true;
	String className = "WorldBuilder_" + session->projectName;

	writeOK = writeOK && wbWriteLine(file, "-- Generated by Bellum Gero World Builder");
	writeOK = writeOK && wbWriteLine(file, "-- Project: " + session->projectName + " | Planet: " + session->planetName);
	writeOK = writeOK && wbWriteLine(file, "-- Regenerate from the .wbp project instead of hand-editing whenever possible.");
	writeOK = writeOK && wbWriteLine(file, "");
	writeOK = writeOK && wbWriteLine(file, className + " = ScreenPlay:new {");
	writeOK = writeOK && wbWriteLine(file, "\tnumberOfActs = 1,");
	writeOK = writeOK && wbWriteLine(file, "\tscreenplayName = \"" + className + "\",");
	writeOK = writeOK && wbWriteLine(file, "}");
	writeOK = writeOK && wbWriteLine(file, "");
	writeOK = writeOK && wbWriteLine(file, "registerScreenPlay(\"" + className + "\", true)");
	writeOK = writeOK && wbWriteLine(file, "");
	writeOK = writeOK && wbWriteLine(file, "function " + className + ":start()");
	writeOK = writeOK && wbWriteLine(file, "\tif not isZoneEnabled(\"" + session->planetName + "\") then");
	writeOK = writeOK && wbWriteLine(file, "\t\treturn");
	writeOK = writeOK && wbWriteLine(file, "\tend");
	writeOK = writeOK && wbWriteLine(file, "");

	for (int i = 0; writeOK && i < session->objects.size(); ++i) {
		const WorldBuilderObjectState& state = session->objects.get(i);
		StringBuffer spawn;
		spawn << "\tspawnSceneObject(\"" << session->planetName << "\", \"" << state.objectTemplate << "\", "
			  << state.x << ", " << state.z << ", " << state.y << ", " << state.parentID << ", "
			  << state.qw << ", " << state.qx << ", " << state.qy << ", " << state.qz << ") -- WB #" << state.localID;
		writeOK = wbWriteLine(file, spawn.toString());
	}

	writeOK = writeOK && wbWriteLine(file, "end");

	if (std::fclose(file) != 0)
		writeOK = false;

	if (!writeOK || !wbFileExists(path)) {
		std::remove(path.toCharArray());
		message = "Lua export failed; no valid export file was written to " + path;
		return false;
	}

	message = "Exported Lua placement screenplay to " + path + ". This is the recommended production format for ordinary decoration/static objects.";
	return true;
}

bool WorldBuilderManager::spawnTemplate(CreatureObject* player, const String& objectTemplate, float distance, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr) {
		message = "Open or create a World Builder project first.";
		return false;
	}

	if (player->getZone() == nullptr || player->getZone()->getZoneName() != session->planetName) {
		message = "You are not on the project planet.";
		return false;
	}

	String templatePath = objectTemplate.trim();
	if (templatePath.isEmpty()) {
		message = "Specify a server object template path.";
		return false;
	}

	if (distance <= 0.0f)
		distance = DEFAULT_SPAWN_DISTANCE;
	if (distance > 100.0f)
		distance = 100.0f;

	pushUndoState(session, player);

	WorldBuilderObjectState state;
	state.localID = session->nextLocalID++;
	state.objectTemplate = templatePath;
	state.snapshotTemplate = deriveSnapshotTemplate(templatePath);

	float heading = player->getDirectionAngle();
	float radians = Math::deg2rad(heading);
	state.x = player->getPositionX() + (distance * sin(radians));
	state.y = player->getPositionY() + (distance * cos(radians));
	state.z = player->getPositionZ();

	ManagedReference<SceneObject*> parent = player->getParent().get();
	state.parentID = parent != nullptr && parent->isCellObject() ? parent->getObjectID() : 0;

	String error;
	ManagedReference<SceneObject*> object = spawnStateObject(player, state, error);
	if (object == nullptr) {
		if (session->undoStack.size() > 0)
			session->undoStack.remove(session->undoStack.size() - 1);
		--session->nextLocalID;
		message = error;
		return false;
	}

	if (heading != 0.0f) {
		Locker objectLocker(object, player);
		object->rotate(heading);
		object->incrementMovementCounter();
		if (state.parentID != 0)
			object->teleport(state.x, state.z, state.y, state.parentID);
		else
			object->teleport(state.x, state.z, state.y);
		captureObjectState(state, player);
	}

	session->objects.add(state);
	session->selectedLocalID = state.localID;
	session->lastTemplate = templatePath;
	autosave(session, player);

	message = "Spawned and selected WB #" + String::valueOf(state.localID) + " " + getTemplateShortName(templatePath) + ".";
	return true;
}

bool WorldBuilderManager::spawnLastTemplate(CreatureObject* player, float distance, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr || session->lastTemplate.isEmpty()) {
		message = "No last template is available yet.";
		return false;
	}

	return spawnTemplate(player, session->lastTemplate, distance, message);
}

bool WorldBuilderManager::selectTarget(CreatureObject* player, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr) {
		message = "No World Builder project is open.";
		return false;
	}

	uint64 targetID = player->getTargetID();
	int index = findObjectIndexByRuntimeID(session, targetID);
	if (index < 0) {
		message = "Your target is not part of the current World Builder project. Use /wb objects for static objects that cannot be targeted.";
		return false;
	}

	session->selectedLocalID = session->objects.get(index).localID;
	autosave(session, player);
	message = "Selected WB #" + String::valueOf(session->selectedLocalID) + " " + getTemplateShortName(session->objects.get(index).objectTemplate) + ".";
	return true;
}

bool WorldBuilderManager::selectObject(CreatureObject* player, uint32 localID, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr) {
		message = "No World Builder project is open.";
		return false;
	}

	int index = findObjectIndexByLocalID(session, localID);
	if (index < 0) {
		message = "World Builder object #" + String::valueOf(localID) + " does not exist.";
		return false;
	}

	session->selectedLocalID = localID;
	autosave(session, player);
	WorldBuilderObjectState state = session->objects.get(index);
	captureObjectState(state, player);
	StringBuffer status;
	status << "Selected WB #" << localID << " " << getTemplateShortName(state.objectTemplate)
		   << " | x=" << state.x << " z=" << state.z << " y=" << state.y;
	message = status.toString();
	return true;
}

bool WorldBuilderManager::selectRelative(CreatureObject* player, int delta, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr || session->objects.size() == 0) {
		message = "No World Builder objects are available.";
		return false;
	}

	int currentIndex = findObjectIndexByLocalID(session, session->selectedLocalID);
	if (currentIndex < 0)
		currentIndex = 0;
	else {
		currentIndex += delta;
		while (currentIndex < 0)
			currentIndex += session->objects.size();
		currentIndex %= session->objects.size();
	}

	return selectObject(player, session->objects.get(currentIndex).localID, message);
}

bool WorldBuilderManager::translateObject(CreatureObject* player, WorldBuilderObjectState& state, float dx, float dz, float dy, String& message) {
	if (player == nullptr || player->getZoneServer() == nullptr)
		return false;

	ManagedReference<SceneObject*> object = player->getZoneServer()->getObject(state.runtimeObjectID);
	if (object == nullptr) {
		message = "Selected preview object is missing. Reload the project.";
		return false;
	}

	float x = object->getPositionX() + dx;
	float z = object->getPositionZ() + dz;
	float y = object->getPositionY() + dy;

	Locker objectLocker(object, player);
	object->incrementMovementCounter();
	ManagedReference<SceneObject*> parent = object->getParent().get();
	if (parent != nullptr)
		object->teleport(x, z, y, parent->getObjectID());
	else
		object->teleport(x, z, y);

	state.x = x;
	state.z = z;
	state.y = y;
	return true;
}

bool WorldBuilderManager::moveSelected(CreatureObject* player, const String& direction, float amount, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr) {
		message = "No World Builder project is open.";
		return false;
	}

	int index = findObjectIndexByLocalID(session, session->selectedLocalID);
	if (index < 0) {
		message = "Select a World Builder object first.";
		return false;
	}

	if (amount <= 0.0f)
		amount = session->moveStep;
	if (amount > 100.0f)
		amount = 100.0f;

	String dir = direction.toLowerCase();
	float dx = 0.0f, dz = 0.0f, dy = 0.0f;
	float radians = Math::deg2rad(player->getDirectionAngle());

	if (dir == "forward" || dir == "f") {
		dx = amount * sin(radians);
		dy = amount * cos(radians);
	} else if (dir == "back" || dir == "backward" || dir == "b") {
		dx = -amount * sin(radians);
		dy = -amount * cos(radians);
	} else if (dir == "left" || dir == "l") {
		dx = -amount * cos(radians);
		dy = amount * sin(radians);
	} else if (dir == "right" || dir == "r") {
		dx = amount * cos(radians);
		dy = -amount * sin(radians);
	} else if (dir == "up" || dir == "u") {
		dz = amount;
	} else if (dir == "down" || dir == "d") {
		dz = -amount;
	} else if (dir == "x+") {
		dx = amount;
	} else if (dir == "x-") {
		dx = -amount;
	} else if (dir == "y+") {
		dy = amount;
	} else if (dir == "y-") {
		dy = -amount;
	} else {
		message = "Move direction: forward/back/left/right/up/down/x+/x-/y+/y-.";
		return false;
	}

	pushUndoState(session, player);
	if (!translateObject(player, session->objects.elementAt(index), dx, dz, dy, message)) {
		session->undoStack.remove(session->undoStack.size() - 1);
		return false;
	}

	autosave(session, player);
	WorldBuilderObjectState& state = session->objects.elementAt(index);
	StringBuffer result;
	result << "WB #" << state.localID << " moved " << dir << " " << amount
		   << " | x=" << state.x << " z=" << state.z << " y=" << state.y;
	message = result.toString();
	return true;
}

bool WorldBuilderManager::rotateObject(CreatureObject* player, WorldBuilderObjectState& state, const String& axis, float degrees, String& message) {
	if (player == nullptr || player->getZoneServer() == nullptr)
		return false;

	ManagedReference<SceneObject*> object = player->getZoneServer()->getObject(state.runtimeObjectID);
	if (object == nullptr) {
		message = "Selected preview object is missing. Reload the project.";
		return false;
	}

	String normalizedAxis = axis.toLowerCase();
	Locker objectLocker(object, player);
	if (normalizedAxis == "yaw" || normalizedAxis == "y")
		object->rotate(degrees);
	else if (normalizedAxis == "pitch" || normalizedAxis == "p")
		object->rotatePitch(degrees);
	else if (normalizedAxis == "roll" || normalizedAxis == "r")
		object->rotateRoll(degrees);
	else {
		message = "Rotation axis must be yaw, pitch, or roll.";
		return false;
	}

	object->incrementMovementCounter();
	ManagedReference<SceneObject*> parent = object->getParent().get();
	if (parent != nullptr)
		object->teleport(object->getPositionX(), object->getPositionZ(), object->getPositionY(), parent->getObjectID());
	else
		object->teleport(object->getPositionX(), object->getPositionZ(), object->getPositionY());

	captureObjectState(state, player);
	return true;
}

bool WorldBuilderManager::rotateSelected(CreatureObject* player, const String& axis, float degrees, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr) {
		message = "No World Builder project is open.";
		return false;
	}

	int index = findObjectIndexByLocalID(session, session->selectedLocalID);
	if (index < 0) {
		message = "Select a World Builder object first.";
		return false;
	}

	if (degrees == 0.0f)
		degrees = session->rotateStep;
	if (degrees < -180.0f || degrees > 180.0f) {
		message = "Rotation per command must be between -180 and 180 degrees.";
		return false;
	}

	pushUndoState(session, player);
	if (!rotateObject(player, session->objects.elementAt(index), axis, degrees, message)) {
		session->undoStack.remove(session->undoStack.size() - 1);
		return false;
	}

	autosave(session, player);
	message = "Rotated WB #" + String::valueOf(session->selectedLocalID) + " " + axis.toLowerCase() + " " + String::valueOf(degrees) + " degrees.";
	return true;
}

bool WorldBuilderManager::snapSelectedToPlayer(CreatureObject* player, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr)
		return false;

	int index = findObjectIndexByLocalID(session, session->selectedLocalID);
	if (index < 0) {
		message = "Select a World Builder object first.";
		return false;
	}

	WorldBuilderObjectState& state = session->objects.elementAt(index);
	if (state.parentID != 0) {
		ManagedReference<SceneObject*> playerParent = player->getParent().get();
		if (playerParent == nullptr || playerParent->getObjectID() != state.parentID) {
			message = "For cell objects, stand in the same cell before using snap.";
			return false;
		}
	}

	pushUndoState(session, player);
	float dx = player->getPositionX() - state.x;
	float dz = player->getPositionZ() - state.z;
	float dy = player->getPositionY() - state.y;
	if (!translateObject(player, state, dx, dz, dy, message)) {
		session->undoStack.remove(session->undoStack.size() - 1);
		return false;
	}

	autosave(session, player);
	message = "Snapped WB #" + String::valueOf(state.localID) + " to your position.";
	return true;
}

bool WorldBuilderManager::putSelectedInFront(CreatureObject* player, float distance, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr)
		return false;

	int index = findObjectIndexByLocalID(session, session->selectedLocalID);
	if (index < 0) {
		message = "Select a World Builder object first.";
		return false;
	}

	if (distance <= 0.0f)
		distance = DEFAULT_SPAWN_DISTANCE;

	WorldBuilderObjectState& state = session->objects.elementAt(index);
	float radians = Math::deg2rad(player->getDirectionAngle());
	float targetX = player->getPositionX() + distance * sin(radians);
	float targetY = player->getPositionY() + distance * cos(radians);
	float targetZ = player->getPositionZ();

	pushUndoState(session, player);
	if (!translateObject(player, state, targetX - state.x, targetZ - state.z, targetY - state.y, message)) {
		session->undoStack.remove(session->undoStack.size() - 1);
		return false;
	}

	autosave(session, player);
	message = "Moved WB #" + String::valueOf(state.localID) + " " + String::valueOf(distance) + "m in front of you.";
	return true;
}

bool WorldBuilderManager::duplicateSelected(CreatureObject* player, float forwardOffset, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr)
		return false;

	int index = findObjectIndexByLocalID(session, session->selectedLocalID);
	if (index < 0) {
		message = "Select a World Builder object first.";
		return false;
	}

	pushUndoState(session, player);
	WorldBuilderObjectState source = session->objects.get(index);
	captureObjectState(source, player);
	WorldBuilderObjectState copy = source;
	copy.localID = session->nextLocalID++;
	copy.runtimeObjectID = 0;

	if (forwardOffset == 0.0f)
		forwardOffset = session->moveStep;
	float radians = Math::deg2rad(player->getDirectionAngle());
	copy.x += forwardOffset * sin(radians);
	copy.y += forwardOffset * cos(radians);

	String error;
	if (spawnStateObject(player, copy, error) == nullptr) {
		session->undoStack.remove(session->undoStack.size() - 1);
		--session->nextLocalID;
		message = error;
		return false;
	}

	session->objects.add(copy);
	session->selectedLocalID = copy.localID;
	session->lastTemplate = copy.objectTemplate;
	autosave(session, player);
	message = "Duplicated to WB #" + String::valueOf(copy.localID) + " and selected the copy.";
	return true;
}

bool WorldBuilderManager::deleteSelected(CreatureObject* player, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr)
		return false;

	int index = findObjectIndexByLocalID(session, session->selectedLocalID);
	if (index < 0) {
		message = "Select a World Builder object first.";
		return false;
	}

	pushUndoState(session, player);
	uint32 deletedID = session->objects.get(index).localID;
	destroyRuntimeObject(player, session->objects.elementAt(index));
	session->objects.remove(index);

	for (int i = session->groupIDs.size() - 1; i >= 0; --i) {
		if (session->groupIDs.get(i) == deletedID)
			session->groupIDs.remove(i);
	}

	if (session->objects.size() > 0) {
		int newIndex = index;
		if (newIndex >= session->objects.size())
			newIndex = session->objects.size() - 1;
		session->selectedLocalID = session->objects.get(newIndex).localID;
	} else {
		session->selectedLocalID = 0;
	}

	autosave(session, player);
	message = "Deleted WB #" + String::valueOf(deletedID) + ". Use /wb undo if that was accidental.";
	return true;
}

bool WorldBuilderManager::groupAddSelected(CreatureObject* player, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr)
		return false;

	if (findObjectIndexByLocalID(session, session->selectedLocalID) < 0) {
		message = "Select a World Builder object first.";
		return false;
	}

	if (isInGroup(session, session->selectedLocalID)) {
		message = "WB #" + String::valueOf(session->selectedLocalID) + " is already in the active group.";
		return true;
	}

	session->groupIDs.add(session->selectedLocalID);
	autosave(session, player);
	message = "Added WB #" + String::valueOf(session->selectedLocalID) + " to group (" + String::valueOf(session->groupIDs.size()) + " object(s)).";
	return true;
}

bool WorldBuilderManager::groupRemoveSelected(CreatureObject* player, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr)
		return false;

	for (int i = 0; i < session->groupIDs.size(); ++i) {
		if (session->groupIDs.get(i) == session->selectedLocalID) {
			session->groupIDs.remove(i);
			autosave(session, player);
			message = "Removed WB #" + String::valueOf(session->selectedLocalID) + " from the active group.";
			return true;
		}
	}

	message = "Selected object is not in the active group.";
	return true;
}

bool WorldBuilderManager::groupClear(CreatureObject* player, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr)
		return false;

	session->groupIDs.removeAll();
	autosave(session, player);
	message = "Active World Builder group cleared.";
	return true;
}

bool WorldBuilderManager::groupMove(CreatureObject* player, const String& direction, float amount, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr || session->groupIDs.size() == 0) {
		message = "The active World Builder group is empty.";
		return false;
	}

	if (amount <= 0.0f)
		amount = session->moveStep;

	String dir = direction.toLowerCase();
	float dx = 0.0f, dz = 0.0f, dy = 0.0f;
	float radians = Math::deg2rad(player->getDirectionAngle());
	if (dir == "forward" || dir == "f") { dx = amount * sin(radians); dy = amount * cos(radians); }
	else if (dir == "back" || dir == "b") { dx = -amount * sin(radians); dy = -amount * cos(radians); }
	else if (dir == "left" || dir == "l") { dx = -amount * cos(radians); dy = amount * sin(radians); }
	else if (dir == "right" || dir == "r") { dx = amount * cos(radians); dy = -amount * sin(radians); }
	else if (dir == "up" || dir == "u") dz = amount;
	else if (dir == "down" || dir == "d") dz = -amount;
	else { message = "Group move direction: forward/back/left/right/up/down."; return false; }

	pushUndoState(session, player);
	for (int i = 0; i < session->groupIDs.size(); ++i) {
		int index = findObjectIndexByLocalID(session, session->groupIDs.get(i));
		if (index < 0)
			continue;
		String ignored;
		if (!translateObject(player, session->objects.elementAt(index), dx, dz, dy, ignored)) {
			WorldBuilderProjectState before = session->undoStack.get(session->undoStack.size() - 1);
			session->undoStack.remove(session->undoStack.size() - 1);
			String restoreMessage;
			restoreProjectState(session, player, before, restoreMessage);
			message = "Group move failed and was rolled back.";
			return false;
		}
	}

	autosave(session, player);
	message = "Moved group of " + String::valueOf(session->groupIDs.size()) + " object(s) " + dir + " " + String::valueOf(amount) + ".";
	return true;
}

bool WorldBuilderManager::groupRotate(CreatureObject* player, const String& axis, float degrees, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr || session->groupIDs.size() == 0) {
		message = "The active World Builder group is empty.";
		return false;
	}

	if (degrees == 0.0f)
		degrees = session->rotateStep;

	pushUndoState(session, player);
	for (int i = 0; i < session->groupIDs.size(); ++i) {
		int index = findObjectIndexByLocalID(session, session->groupIDs.get(i));
		if (index < 0)
			continue;
		String ignored;
		if (!rotateObject(player, session->objects.elementAt(index), axis, degrees, ignored)) {
			WorldBuilderProjectState before = session->undoStack.get(session->undoStack.size() - 1);
			session->undoStack.remove(session->undoStack.size() - 1);
			String restoreMessage;
			restoreProjectState(session, player, before, restoreMessage);
			message = "Group rotation failed and was rolled back.";
			return false;
		}
	}

	autosave(session, player);
	message = "Rotated orientations for group of " + String::valueOf(session->groupIDs.size()) + " object(s). (V1 does not orbit positions around a pivot yet.)";
	return true;
}

bool WorldBuilderManager::groupDuplicate(CreatureObject* player, float forwardOffset, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr || session->groupIDs.size() == 0) {
		message = "The active World Builder group is empty.";
		return false;
	}

	if (forwardOffset == 0.0f)
		forwardOffset = 1.0f;

	pushUndoState(session, player);
	Vector<uint32> newGroup;
	float radians = Math::deg2rad(player->getDirectionAngle());
	float dx = forwardOffset * sin(radians);
	float dy = forwardOffset * cos(radians);

	Vector<uint32> sourceGroup = session->groupIDs;
	for (int i = 0; i < sourceGroup.size(); ++i) {
		int index = findObjectIndexByLocalID(session, sourceGroup.get(i));
		if (index < 0)
			continue;

		WorldBuilderObjectState copy = session->objects.get(index);
		captureObjectState(copy, player);
		copy.localID = session->nextLocalID++;
		copy.runtimeObjectID = 0;
		copy.x += dx;
		copy.y += dy;

		String error;
		if (spawnStateObject(player, copy, error) == nullptr) {
			WorldBuilderProjectState before = session->undoStack.get(session->undoStack.size() - 1);
			session->undoStack.remove(session->undoStack.size() - 1);
			String restoreMessage;
			restoreProjectState(session, player, before, restoreMessage);
			message = "Group duplicate failed and was rolled back: " + error;
			return false;
		}

		session->objects.add(copy);
		newGroup.add(copy.localID);
	}

	session->groupIDs = newGroup;
	if (newGroup.size() > 0)
		session->selectedLocalID = newGroup.get(0);
	autosave(session, player);
	message = "Duplicated group as " + String::valueOf(newGroup.size()) + " new object(s), offset " + String::valueOf(forwardOffset) + "m. The copies are now the active group.";
	return true;
}

bool WorldBuilderManager::undo(CreatureObject* player, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr || session->undoStack.size() == 0) {
		message = "Nothing to undo.";
		return false;
	}

	WorldBuilderProjectState current = captureProjectState(session, player);
	WorldBuilderProjectState target = session->undoStack.get(session->undoStack.size() - 1);
	session->undoStack.remove(session->undoStack.size() - 1);

	if (!restoreProjectState(session, player, target, message)) {
		session->undoStack.add(target);
		return false;
	}

	session->redoStack.add(current);
	while (session->redoStack.size() > MAX_HISTORY_STATES)
		session->redoStack.remove(0);
	autosave(session, player);
	message = "Undo complete. Preview objects were rebuilt from the previous project state.";
	return true;
}

bool WorldBuilderManager::redo(CreatureObject* player, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr || session->redoStack.size() == 0) {
		message = "Nothing to redo.";
		return false;
	}

	WorldBuilderProjectState current = captureProjectState(session, player);
	WorldBuilderProjectState target = session->redoStack.get(session->redoStack.size() - 1);
	session->redoStack.remove(session->redoStack.size() - 1);

	if (!restoreProjectState(session, player, target, message)) {
		session->redoStack.add(target);
		return false;
	}

	session->undoStack.add(current);
	while (session->undoStack.size() > MAX_HISTORY_STATES)
		session->undoStack.remove(0);
	autosave(session, player);
	message = "Redo complete.";
	return true;
}

bool WorldBuilderManager::setMoveStep(CreatureObject* player, float step, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr)
		return false;

	if (step < 0.01f || step > 25.0f) {
		message = "Move step must be between 0.01 and 25 meters.";
		return false;
	}

	session->moveStep = step;
	autosave(session, player);
	message = "World Builder move step set to " + String::valueOf(step) + "m.";
	return true;
}

bool WorldBuilderManager::setRotateStep(CreatureObject* player, float step, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr)
		return false;

	if (step < 0.1f || step > 90.0f) {
		message = "Rotate step must be between 0.1 and 90 degrees.";
		return false;
	}

	session->rotateStep = step;
	autosave(session, player);
	message = "World Builder rotate step set to " + String::valueOf(step) + " degrees.";
	return true;
}

bool WorldBuilderManager::setSnapshotGameObjectType(CreatureObject* player, float gameObjectType, String& message) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr)
		return false;

	int index = findObjectIndexByLocalID(session, session->selectedLocalID);
	if (index < 0) {
		message = "Select a World Builder object first.";
		return false;
	}

	if (gameObjectType < -1.0f || gameObjectType > 100000.0f) {
		message = "Snapshot game-object type override must be -1 (auto) or a non-negative value.";
		return false;
	}

	session->objects.elementAt(index).snapshotGameObjectType = gameObjectType;
	autosave(session, player);
	message = gameObjectType < 0.0f ? "Snapshot type override cleared (auto-infer on TRE bake)." : "Snapshot type override set to " + String::valueOf(gameObjectType) + ".";
	return true;
}

float WorldBuilderManager::getMoveStep(CreatureObject* player) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	return session != nullptr ? session->moveStep : DEFAULT_MOVE_STEP;
}

float WorldBuilderManager::getRotateStep(CreatureObject* player) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	return session != nullptr ? session->rotateStep : DEFAULT_ROTATE_STEP;
}

String WorldBuilderManager::getLastTemplate(CreatureObject* player) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	return session != nullptr ? session->lastTemplate : "";
}

String WorldBuilderManager::getStatus(CreatureObject* player) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr)
		return "No World Builder project is open. Use /wb to create or browse saved projects.";

	StringBuffer status;
	status << "Project: " << session->projectName << " [" << session->planetName << "]\n";
	status << "Objects: " << session->objects.size() << " | Group: " << session->groupIDs.size() << "\n";
	status << "Move Step: " << session->moveStep << "m | Rotate Step: " << session->rotateStep << " deg\n";

	int index = findObjectIndexByLocalID(session, session->selectedLocalID);
	if (index >= 0) {
		WorldBuilderObjectState state = session->objects.get(index);
		captureObjectState(state, player);
		status << "Selected: WB #" << state.localID << " " << getTemplateShortName(state.objectTemplate) << "\n";
		status << "x=" << state.x << " z=" << state.z << " y=" << state.y << " | parent=" << state.parentID << "\n";
		status << "quat=" << state.qw << "," << state.qx << "," << state.qy << "," << state.qz << "\n";
		status << "Snapshot Type: " << (state.snapshotGameObjectType < 0.0f ? String("AUTO") : String::valueOf(state.snapshotGameObjectType));
	} else {
		status << "Selected: none";
	}

	return status.toString();
}

String WorldBuilderManager::getHelp(CreatureObject* player) const {
	StringBuffer help;
	help << "Bellum Gero World Builder (admin-only)\n\n";
	help << "PROJECT\n";
	help << "/wb new <name> | /wb projects | /wb load <name> | /wb save | /wb close\n";
	help << "/wb export - Generate a Lua placement screenplay\n\n";
	help << "OBJECTS\n";
	help << "/wb spawn <object/template.iff> [distance]\n";
	help << "/wb last [distance] - Spawn the last template again\n";
	help << "/wb objects - Open the project object list\n";
	help << "/wb select <id> | /wb target | /wb next | /wb prev\n";
	help << "/wb duplicate [forwardOffset] | /wb delete\n";
	help << "/wb snap - Move selected object to your position\n";
	help << "/wb front [distance] - Put selected object in front of you\n\n";
	help << "PRECISION MOVEMENT\n";
	help << "/wb step 0.01 (valid 0.01-25m)\n";
	help << "/wb f|b|l|r|u|d [meters]\n";
	help << "/wb move forward|back|left|right|up|down [meters]\n\n";
	help << "ROTATION\n";
	help << "/wb rotstep 1\n";
	help << "/wb yaw|pitch|roll <degrees> (omit degrees to use step)\n\n";
	help << "GROUPS (for copying formations)\n";
	help << "/wb group add|remove|clear\n";
	help << "/wb group move <direction> [meters]\n";
	help << "/wb group rotate <axis> [degrees]\n";
	help << "/wb group duplicate [forwardOffset]\n\n";
	help << "PROJECT BROWSER / MANAGEMENT\n";
	help << "/wb projects - Browse saved .wbp projects and load one from SUI\n";
	help << "/wb manage - Rename, restore backups, or safely delete saved projects\n";
	help << "New Project and Rename never overwrite an existing .wbp or .wbp.bak name.\n";
	help << "Delete requires two confirmations; backup-only projects stay visible for recovery.\n\n";
	help << "SAFETY\n";
	help << "/wb undo | /wb redo. Every mutation autosaves. Preview objects vanish when the project is closed/server restarts; load the project to rebuild them.";
	return help.toString();
}

void WorldBuilderManager::getSavedProjects(Vector<String>& projectNames) {
	projectNames.removeAll();

	if (!wbEnsureProjectDirectory())
		return;

#ifndef _WIN32
	DIR* directory = ::opendir(WB_PROJECT_DIR);
	if (directory == nullptr)
		return;

	std::vector<std::string> names;
	struct dirent* entry = nullptr;

	while ((entry = ::readdir(directory)) != nullptr) {
		std::string fileName(entry->d_name);

		if (fileName.size() <= 4)
			continue;

		// Only expose active project files. Ignore .bak, .tmp, Lua exports,
		// README files, and any other content in the project directory.
		if (fileName.compare(fileName.size() - 4, 4, ".wbp") != 0)
			continue;

		std::string projectName = fileName.substr(0, fileName.size() - 4);
		if (!projectName.empty())
			names.push_back(projectName);
	}

	::closedir(directory);
	std::sort(names.begin(), names.end());

	for (size_t i = 0; i < names.size(); ++i)
		projectNames.add(String(names[i].c_str()));
#endif
}

void WorldBuilderManager::getManagedProjects(Vector<String>& projectNames, Vector<String>& labels) {
	projectNames.removeAll();
	labels.removeAll();

	if (!wbEnsureProjectDirectory())
		return;

#ifndef _WIN32
	DIR* directory = ::opendir(WB_PROJECT_DIR);
	if (directory == nullptr)
		return;

	std::vector<std::string> names;
	struct dirent* entry = nullptr;

	while ((entry = ::readdir(directory)) != nullptr) {
		std::string fileName(entry->d_name);
		std::string projectName;

		if (fileName.size() > 4 && fileName.compare(fileName.size() - 4, 4, ".wbp") == 0) {
			projectName = fileName.substr(0, fileName.size() - 4);
		} else if (fileName.size() > 8 && fileName.compare(fileName.size() - 8, 8, ".wbp.bak") == 0) {
			projectName = fileName.substr(0, fileName.size() - 8);
		} else {
			continue;
		}

		if (!projectName.empty() && std::find(names.begin(), names.end(), projectName) == names.end())
			names.push_back(projectName);
	}

	::closedir(directory);
	std::sort(names.begin(), names.end());

	for (size_t i = 0; i < names.size(); ++i) {
		String name(names[i].c_str());
		String path = getProjectFilePath(name);
		bool active = wbFileExists(path);
		bool backup = wbFileExists(path + ".bak");

		if (!active && !backup)
			continue;

		StringBuffer label;
		label << name;

		if (active && backup)
			label << " [Backup Available]";
		else if (!active && backup)
			label << " [Backup Only - Restore Available]";
		else
			label << " [No Backup]";

		projectNames.add(name);
		labels.add(label.toString());
	}
#endif
}

void WorldBuilderManager::getObjectMenu(CreatureObject* player, Vector<String>& labels, Vector<uint64>& localIDs) {
	Reference<WorldBuilderSession*> session = getSessionForPlayer(player);
	if (session == nullptr)
		return;

	for (int i = 0; i < session->objects.size(); ++i) {
		WorldBuilderObjectState state = session->objects.get(i);
		captureObjectState(state, player);
		StringBuffer label;
		label << (state.localID == session->selectedLocalID ? "* " : "  ")
			  << "#" << state.localID << " " << getTemplateShortName(state.objectTemplate)
			  << " | " << state.x << ", " << state.z << ", " << state.y;
		if (isInGroup(session, state.localID))
			label << " [G]";
		labels.add(label.toString());
		localIDs.add(state.localID);
	}
}
