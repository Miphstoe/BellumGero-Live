/*
 * WorldBuilderManager.h
 *
 * Bellum Gero World Builder
 * Transient, admin-only in-game scene placement editor.
 *
 * Preview objects are deliberately NOT persisted to the normal object database.
 * Project state is written to worldbuilder/projects/<project>.wbp and can later be
 * exported to Lua or baked into a TRE world snapshot with the companion tool.
 */

#ifndef WORLDBUILDERMANAGER_H_
#define WORLDBUILDERMANAGER_H_

#include "engine/engine.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/cell/CellObject.h"

enum WorldBuilderObjectKind {
	WB_OBJECT_STATIC = 0,
	WB_OBJECT_STRUCTURE = 1,
	WB_OBJECT_INTERIOR = 2,
	WB_OBJECT_EXTERIOR_BUILDING = 3
};

class WorldBuilderExtensionTarget : public Object {
public:
	String publishID;
	uint32 structureLocalID;

	WorldBuilderExtensionTarget() : structureLocalID(0) {
	}

	WorldBuilderExtensionTarget(const String& parentPublishID, uint32 parentStructureLocalID)
		: publishID(parentPublishID), structureLocalID(parentStructureLocalID) {
	}
};

class WorldBuilderTravelPointState : public Object {
public:
	uint32 buildingLocalID;
	String pointName;
	float x, z, y;
	bool interplanetaryTravelAllowed;
	bool incomingTravelAllowed;
	float landingRange;

	WorldBuilderTravelPointState() : buildingLocalID(0), x(0), z(0), y(0),
		interplanetaryTravelAllowed(true), incomingTravelAllowed(true), landingRange(3.f) {}
};

class WorldBuilderObjectState : public Object {
public:
	uint32 localID;
	uint64 runtimeObjectID;
	int objectKind;
	String objectTemplate;
	String snapshotTemplate;
	float x;
	float z;
	float y;
	float qw;
	float qx;
	float qy;
	float qz;
	float snapshotGameObjectType;
	uint64 parentID;
	uint32 structureLocalID;
	String structurePublishID;
	int cellNumber;
	String roomName;

	WorldBuilderObjectState();
};

class WorldBuilderProjectState : public Object {
public:
	Vector<WorldBuilderObjectState> objects;
	Vector<uint32> groupIDs;
	Vector<WorldBuilderTravelPointState> travelPoints;
	uint32 selectedLocalID;
	uint32 nextLocalID;

	WorldBuilderProjectState();
};

class WorldBuilderSession : public Object {
public:
	String projectName;
	String planetName;
	String lastTemplate;
	int projectVersion;
	float moveStep;
	float rotateStep;
	uint32 selectedLocalID;
	uint32 nextLocalID;
	Vector<WorldBuilderObjectState> objects;
	Vector<uint32> groupIDs;
	Vector<WorldBuilderExtensionTarget> extensionTargets;
	Vector<WorldBuilderTravelPointState> travelPoints;
	Vector<String> transientTravelPointNames;
	Vector<WorldBuilderProjectState> undoStack;
	Vector<WorldBuilderProjectState> redoStack;

	WorldBuilderSession();
};

class WorldBuilderManager : public Singleton<WorldBuilderManager>, public Object {
private:
	VectorMap<uint64, Reference<WorldBuilderSession*> > sessions;
	Mutex sessionsLock;

	static const int MAX_HISTORY_STATES = 30;
	static const float DEFAULT_MOVE_STEP;
	static const float DEFAULT_ROTATE_STEP;
	static const float DEFAULT_SPAWN_DISTANCE;

	Reference<WorldBuilderSession*> getSessionForPlayer(CreatureObject* player);
	Reference<WorldBuilderSession*> getSessionForPlayerID(uint64 playerID);

	String sanitizeProjectName(const String& name) const;
	String getProjectFilePath(const String& safeProjectName) const;
	String getLuaExportFilePath(const String& safeProjectName) const;
	String deriveSnapshotTemplate(const String& objectTemplate) const;
	String getTemplateShortName(const String& objectTemplate) const;

	int findObjectIndexByLocalID(WorldBuilderSession* session, uint32 localID) const;
	int findObjectIndexByRuntimeID(WorldBuilderSession* session, uint64 runtimeID) const;
	int findStructureIndexByRuntimeID(WorldBuilderSession* session, uint64 runtimeID) const;
	bool hasExtensionTarget(WorldBuilderSession* session, const String& publishID, uint32 structureLocalID) const;
	bool isPlayerInsideProjectStructure(WorldBuilderSession* session, CreatureObject* player, uint32* structureLocalID = nullptr) const;
	bool isInGroup(WorldBuilderSession* session, uint32 localID) const;

	bool captureObjectState(WorldBuilderSession* session, WorldBuilderObjectState& state, CreatureObject* player) const;
	bool resolvePlayerProjectInteriorContext(WorldBuilderSession* session, CreatureObject* player, WorldBuilderObjectState& state) const;
	ManagedReference<CellObject*> resolveRuntimeCell(WorldBuilderSession* session, CreatureObject* player, const WorldBuilderObjectState& state, String& errorMessage) const;
	bool validateStructureTemplate(const String& serverTemplate, String& errorMessage) const;
	bool validateExteriorBuildingTemplate(const String& serverTemplate, String& errorMessage) const;
	bool isTravelReadyTemplate(const String& serverTemplate) const;
	int findTravelPointIndex(WorldBuilderSession* session, uint32 buildingLocalID) const;
	bool registerTransientTravelPoints(WorldBuilderSession* session, CreatureObject* player, String& errorMessage);
	void unregisterTransientTravelPoints(WorldBuilderSession* session, CreatureObject* player) const;
	bool rebuildExteriorPreview(WorldBuilderSession* session, CreatureObject* player, uint32 buildingLocalID, String& errorMessage);
	bool validateExtensionReferences(WorldBuilderSession* session, String& errorMessage) const;
	WorldBuilderProjectState captureProjectState(WorldBuilderSession* session, CreatureObject* player) const;
	void pushUndoState(WorldBuilderSession* session, CreatureObject* player);
	bool restoreProjectState(WorldBuilderSession* session, CreatureObject* player, const WorldBuilderProjectState& state, String& message);

	ManagedReference<SceneObject*> spawnStateObject(WorldBuilderSession* session, CreatureObject* player, WorldBuilderObjectState& state, String& errorMessage);
	void destroyRuntimeObject(CreatureObject* player, WorldBuilderObjectState& state) const;
	void destroyAllRuntimeObjects(WorldBuilderSession* session, CreatureObject* player) const;

	bool saveSession(WorldBuilderSession* session, CreatureObject* player, String& message, bool quiet = false);
	bool loadSessionFile(const String& safeProjectName, WorldBuilderSession* session, String& message);
	void autosave(WorldBuilderSession* session, CreatureObject* player);

	bool translateObject(CreatureObject* player, WorldBuilderObjectState& state, float dx, float dz, float dy, String& message);
	bool rotateObject(CreatureObject* player, WorldBuilderObjectState& state, const String& axis, float degrees, String& message);
	bool spawnTemplateInternal(CreatureObject* player, const String& objectTemplate, float distance,
		bool terrainAware, float groundOffset, String& message);

public:
	WorldBuilderManager();

	bool isAuthorized(CreatureObject* player) const;
	bool hasSession(CreatureObject* player);

	bool createProject(CreatureObject* player, const String& projectName, String& message);
	bool loadProject(CreatureObject* player, const String& projectName, String& message);
	bool closeProject(CreatureObject* player, bool saveFirst, String& message);
	bool saveProject(CreatureObject* player, String& message);
	bool exportLua(CreatureObject* player, String& message);

	bool renameSavedProject(CreatureObject* player, const String& projectName, const String& newProjectName, String& message);
	bool restoreProjectBackup(CreatureObject* player, const String& projectName, String& message);
	bool deleteSavedProject(CreatureObject* player, const String& projectName, bool deleteBackup, String& message);
	void getSavedProjectStatus(const String& projectName, bool& hasActiveProject, bool& hasBackup);

	bool bindPublishedStructure(CreatureObject* player, String& message);
	bool unbindPublishedStructure(CreatureObject* player, const String& publishID, uint32 structureLocalID, String& message);
	String getExtensionStatus(CreatureObject* player);

	bool spawnTemplate(CreatureObject* player, const String& objectTemplate, float distance, String& message);
	bool spawnShipScenery(CreatureObject* player, const String& objectTemplate, float distance, float groundOffset, String& message);
	bool addStructure(CreatureObject* player, const String& structureTemplate, float distance, String& message);
	bool addExteriorBuilding(CreatureObject* player, const String& structureTemplate, float distance, String& message);
	bool selectedExteriorTravelReady(CreatureObject* player, uint32& buildingLocalID, String& templatePath, String& message);
	bool getSelectedTravelPoint(CreatureObject* player, WorldBuilderTravelPointState& point, bool& exists, String& message);
	bool setSelectedTravelPointName(CreatureObject* player, const String& name, String& message);
	bool setSelectedTravelPointArrival(CreatureObject* player, String& message);
	bool toggleSelectedTravelPointIncoming(CreatureObject* player, String& message);
	bool toggleSelectedTravelPointInterplanetary(CreatureObject* player, String& message);
	bool setSelectedTravelPointLandingRange(CreatureObject* player, float range, String& message);
	bool removeSelectedTravelPoint(CreatureObject* player, String& message);
	bool spawnLastTemplate(CreatureObject* player, float distance, String& message);
	bool selectTarget(CreatureObject* player, String& message);
	bool selectObject(CreatureObject* player, uint32 localID, String& message);
	bool selectRelative(CreatureObject* player, int delta, String& message);

	bool moveSelected(CreatureObject* player, const String& direction, float amount, String& message);
	bool rotateSelected(CreatureObject* player, const String& axis, float degrees, String& message);
	bool snapSelectedToPlayer(CreatureObject* player, String& message);
	bool putSelectedInFront(CreatureObject* player, float distance, String& message);
	bool duplicateSelected(CreatureObject* player, float forwardOffset, String& message);
	bool deleteSelected(CreatureObject* player, String& message);

	bool groupAddSelected(CreatureObject* player, String& message);
	bool groupRemoveSelected(CreatureObject* player, String& message);
	bool groupClear(CreatureObject* player, String& message);
	bool groupMove(CreatureObject* player, const String& direction, float amount, String& message);
	bool groupRotate(CreatureObject* player, const String& axis, float degrees, String& message);
	bool groupDuplicate(CreatureObject* player, float forwardOffset, String& message);

	bool undo(CreatureObject* player, String& message);
	bool redo(CreatureObject* player, String& message);

	bool setMoveStep(CreatureObject* player, float step, String& message);
	bool setRotateStep(CreatureObject* player, float step, String& message);
	bool setSnapshotGameObjectType(CreatureObject* player, float gameObjectType, String& message);

	float getMoveStep(CreatureObject* player);
	float getRotateStep(CreatureObject* player);
	String getLastTemplate(CreatureObject* player);
	String getStatus(CreatureObject* player);
	String getHelp(CreatureObject* player) const;

	void getSavedProjects(Vector<String>& projectNames);
	void getManagedProjects(Vector<String>& projectNames, Vector<String>& labels);
	void getObjectMenu(CreatureObject* player, Vector<String>& labels, Vector<uint64>& localIDs);
};

#endif /* WORLDBUILDERMANAGER_H_ */
