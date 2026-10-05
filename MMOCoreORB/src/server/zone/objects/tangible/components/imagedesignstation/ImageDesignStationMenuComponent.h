#ifndef IMAGEDESIGNSTATIONMENUCOMPONENT_H_
#define IMAGEDESIGNSTATIONMENUCOMPONENT_H_

#include "server/zone/objects/tangible/components/TangibleObjectMenuComponent.h"

class ImageDesignStationDataComponent;

class ImageDesignStationMenuComponent : public TangibleObjectMenuComponent {
public:
	enum MenuIds {
		MENU_ROOT = 210,
		MENU_USE = 211,
		MENU_STATUS = 212,
		MENU_REFRESH = 213,
		MENU_DECOMMISSION = 214,
		MENU_STAT_MIGRATION = 215,
		MENU_APPLY_STAT_MIGRATION = 216
	};

	void fillObjectMenuResponse(
		SceneObject* sceneObject,
		ObjectMenuResponse* menuResponse,
		CreatureObject* player) const override;

	int handleObjectMenuSelect(
		SceneObject* sceneObject,
		CreatureObject* player,
		byte selectedID) const override;

	static bool isImageDesignStation(SceneObject* object);
	static ImageDesignStationDataComponent* getStationData(SceneObject* object);
	static bool isPlayerWithinUseRange(
		SceneObject* station, CreatureObject* player,
		bool notify = true);

	static void cancelStationStatMigration(
		CreatureObject* player,
		uint64 stationObjectId,
		bool notifyPlayer);

private:
	static bool isPlacementValid(
		SceneObject* station, String* reason = nullptr);
	static void startImageDesign(
		SceneObject* station, CreatureObject* player);
	static void startStatMigration(
		SceneObject* station, CreatureObject* player);
	static void applyStatMigration(
		SceneObject* station, CreatureObject* player);
	static bool chargeStationService(
		SceneObject* station,
		CreatureObject* player,
		ImageDesignStationDataComponent* data);
	static void sendStatus(
		SceneObject* station, CreatureObject* player);
	static void refreshOwnerSkills(
		SceneObject* station, CreatureObject* player);
	static void decommission(
		SceneObject* station, CreatureObject* player);
};

#endif
