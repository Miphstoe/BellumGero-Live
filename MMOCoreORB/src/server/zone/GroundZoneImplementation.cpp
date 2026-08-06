/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.
*/

#include "server/zone/GroundZone.h"

#include "server/zone/ZoneProcessServer.h"
#include "server/zone/GroundZoneContainerComponent.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/managers/planet/PlanetManager.h"
#include "server/zone/managers/creature/CreatureManager.h"
#include "server/zone/managers/components/ComponentManager.h"
#include "server/zone/packets/player/GetMapLocationsResponseMessage.h"

#include "server/zone/objects/cell/CellObject.h"
#include "server/zone/objects/region/Region.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "server/zone/objects/tangible/terminal/Terminal.h"
#include "templates/SharedObjectTemplate.h"

#include "server/zone/managers/structure/StructureManager.h"
#include "terrain/ProceduralTerrainAppearance.h"
#include "server/zone/managers/collision/NavMeshManager.h"
#include "server/zone/ActiveAreaQuadTree.h"

#include <chrono>
#include <algorithm>
#include <map>
#include <string>
#include <vector>
#include <cmath>
#include <limits>
#include <utility>
#include <tuple>


namespace {
	struct ZoneClearAggregate {
		long long objectCount = 0;
		long long lockMs = 0;
		long long destroyMs = 0;
		long long maxTotalMs = 0;
		uint64 maxObjectID = 0;
	};

	template <typename KeyType>
	void addZoneClearAggregate(
			std::map<KeyType, ZoneClearAggregate>& aggregates,
			const KeyType& key,
			uint64 objectID,
			long long lockMs,
			long long destroyMs) {
		ZoneClearAggregate& aggregate = aggregates[key];
		const long long totalMs = lockMs + destroyMs;

		aggregate.objectCount++;
		aggregate.lockMs += lockMs;
		aggregate.destroyMs += destroyMs;

		if (totalMs > aggregate.maxTotalMs) {
			aggregate.maxTotalMs = totalMs;
			aggregate.maxObjectID = objectID;
		}

	}

	struct CampObjectSnapshot {
		uint64 objectID = 0;
		uint64 parentID = 0;
		uint64 rootID = 0;
		std::string templatePath;
		std::string parentTemplate;
		std::string rootTemplate;
		bool isRebelBanner = false;
		bool isImperialBanner = false;
		bool isPavilion = false;
		bool parentIsTheater = false;
		bool rootIsTheater = false;
		float worldX = 0;
		float worldY = 0;
		float worldZ = 0;
	};

	struct CampRelationshipAggregate {
		uint64 groupID = 0;
		std::string groupTemplate;
		bool isTheater = false;
		long long totalCount = 0;
		long long rebelBannerCount = 0;
		long long imperialBannerCount = 0;
		long long pavilionCount = 0;
		float minX = std::numeric_limits<float>::max();
		float maxX = std::numeric_limits<float>::lowest();
		float minY = std::numeric_limits<float>::max();
		float maxY = std::numeric_limits<float>::lowest();
	};

	struct PavilionBannerAggregate {
		uint64 pavilionID = 0;
		uint64 parentID = 0;
		uint64 rootID = 0;
		std::string parentTemplate;
		std::string rootTemplate;
		bool parentIsTheater = false;
		bool rootIsTheater = false;
		float worldX = 0;
		float worldY = 0;
		float worldZ = 0;
		long long rebelBannerCount = 0;
		long long imperialBannerCount = 0;
		float farthestBannerDistanceSquared = 0;
	};

	void addCampRelationship(
			std::map<uint64, CampRelationshipAggregate>& aggregates,
			uint64 groupID,
			const std::string& groupTemplate,
			bool isTheater,
			const CampObjectSnapshot& snapshot) {
		if (groupID == 0)
			return;

		CampRelationshipAggregate& aggregate = aggregates[groupID];

		aggregate.groupID = groupID;

		if (aggregate.groupTemplate.empty())
			aggregate.groupTemplate = groupTemplate;

		aggregate.isTheater = aggregate.isTheater || isTheater;
		aggregate.totalCount++;

		if (snapshot.isRebelBanner)
			aggregate.rebelBannerCount++;

		if (snapshot.isImperialBanner)
			aggregate.imperialBannerCount++;

		if (snapshot.isPavilion)
			aggregate.pavilionCount++;

		aggregate.minX = std::min(aggregate.minX, snapshot.worldX);
		aggregate.maxX = std::max(aggregate.maxX, snapshot.worldX);
		aggregate.minY = std::min(aggregate.minY, snapshot.worldY);
		aggregate.maxY = std::max(aggregate.maxY, snapshot.worldY);

	}

	struct CampCoordinateAggregate {
		float worldX = 0;
		float worldY = 0;
		float worldZ = 0;
		long long rebelBannerCount = 0;
		long long imperialBannerCount = 0;
		long long pavilionCount = 0;
		std::vector<uint64> rebelSamples;
		std::vector<uint64> imperialSamples;
		std::vector<uint64> pavilionSamples;
	};

	struct RemainingObjectSnapshot {
		uint64 objectID = 0;
		uint64 parentID = 0;
		uint64 rootID = 0;
		int gameObjectType = 0;
		std::string templatePath;
		std::string parentTemplate;
		std::string rootTemplate;
		float worldX = 0;
		float worldY = 0;
		float worldZ = 0;
	};

	struct RemainingObjectAggregate {
		long long objectCount = 0;
		std::vector<uint64> sampleObjectIDs;
	};

	void addSampleObjectID(
			std::vector<uint64>& samples,
			uint64 objectID,
			int sampleLimit = 5) {
		if (static_cast<int>(samples.size()) < sampleLimit)
			samples.push_back(objectID);
	}

	void addRemainingAggregate(
			RemainingObjectAggregate& aggregate,
			uint64 objectID) {
		aggregate.objectCount++;
		addSampleObjectID(aggregate.sampleObjectIDs, objectID);
	}
}

GroundZoneImplementation::GroundZoneImplementation(ZoneProcessServer* serv, const String& name) : ZoneImplementation(serv, name) {
	areaTree = new server::zone::ActiveAreaQuadTree(-8192, -8192, 8192, 8192);
	quadTree = new server::zone::QuadTree(-8192, -8192, 8192, 8192);

	planetManager = nullptr;

	String capName = name;
	capName[0] = toupper(name[0]);

	int numThreads = ConfigManager::instance()->getInt("Core3.Zone.ThreadsDefault", 1);
	numThreads = ConfigManager::instance()->getInt("Core3.Zone.Threads" + capName, numThreads);

	setLoggingName("GroundZone " + name);

	if (numThreads != 1) {
		info(true) << "GroundZone " << capName << " using " << numThreads << " threads.";
	}

	Core::getTaskManager()->initializeCustomQueue(zoneName, numThreads, true);
}

void GroundZoneImplementation::createContainerComponent() {
	containerComponent = ComponentManager::instance()->getComponent<GroundZoneContainerComponent*>("GroundZoneContainerComponent");
}

void GroundZoneImplementation::initializePrivateData() {
	planetManager = new PlanetManager(_this.getReferenceUnsafeStaticCast(), processor);

	creatureManager = new CreatureManager(_this.getReferenceUnsafeStaticCast());
	creatureManager->deploy("CreatureManager " + zoneName);
	creatureManager->setZoneProcessor(processor);
}

void GroundZoneImplementation::finalize() {
}

void GroundZoneImplementation::initializeTransientMembers() {
	ManagedObjectImplementation::initializeTransientMembers();

	mapLocations = new MapLocationTable();

	//heightMap->load("planets/" + planetName + "/" + planetName + ".hmap");
}

void GroundZoneImplementation::startManagers() {
	planetManager->initialize();

	creatureManager->initialize();

	StructureManager::instance()->loadPlayerStructures(getZoneName());

	ObjectDatabaseManager::instance()->commitLocalTransaction();

	planetManager->start();

	managersStarted = true;
}

void GroundZoneImplementation::stopManagers() {
	info("Shutting down.. ", true);

	if (creatureManager != nullptr) {
		creatureManager->stop();
		creatureManager = nullptr;
	}

	if (planetManager != nullptr) {
		//planetManager->finalize();
		planetManager = nullptr;
	}

	processor = nullptr;
	server = nullptr;
	mapLocations = nullptr;
	objectMap = nullptr;
	quadTree = nullptr;
	areaTree = nullptr;
}

void GroundZoneImplementation::clearZone() {
	Locker zonelocker(_this.getReferenceUnsafeStaticCast());

	info("clearing zone", true);

	creatureManager->unloadSpawnAreas();

	HashTable<uint64, ManagedReference<SceneObject*> > tbl;
	tbl.copyFrom(*objectMap->getMap());

	const int initialObjectCount = tbl.size();
	const bool detailedDiagnostics = (zoneName == "rori");
	const int progressInterval = detailedDiagnostics ? 1000 : 1000;
	const long long slowObjectThresholdMs = 250;
	const int aggregateOutputLimit = 20;
	const String priorityTemplate =
			"object/building/general/rori_hyperdrive_research_facility.iff";

	ManagedReference<SceneObject*> priorityObject = nullptr;
	uint64 priorityObjectID = 0;

	std::map<int, ZoneClearAggregate> typeAggregates;
	std::map<std::string, ZoneClearAggregate> templateAggregates;


	const std::string rebelBannerTemplate =
			"object/tangible/gcw/flip_banner_onpole_rebel.iff";
	const std::string imperialBannerTemplate =
			"object/tangible/gcw/flip_banner_onpole_imperial.iff";
	const std::string pavilionTemplate =
			"object/tangible/camp/camp_pavilion_s1.iff";
	const float pavilionSearchRadius = 128.0f;
	const float pavilionSearchRadiusSquared =
			pavilionSearchRadius * pavilionSearchRadius;
	const float pavilionGridSize = pavilionSearchRadius;

	std::vector<CampObjectSnapshot> campSnapshots;
	std::map<uint64, CampRelationshipAggregate> campParentAggregates;
	std::map<uint64, CampRelationshipAggregate> campRootAggregates;
	std::map<uint64, PavilionBannerAggregate> pavilionAggregates;
	std::map<std::tuple<long long, long long, long long>,
			CampCoordinateAggregate> campCoordinateAggregates;
	long long campObjectsWithoutParent = 0;
	long long campObjectsWithoutRoot = 0;
	long long bannersWithoutNearbyPavilion = 0;

	// Rori's Hyperdrive Research Facility can hold relationships with most of
	// the planet's loaded objects. Locate it in the copied shutdown table so
	// it can be detached before the normal unordered clear pass begins.
	if (detailedDiagnostics) {
		auto priorityIterator = tbl.iterator();

		while (priorityIterator.hasNext()) {
			ManagedReference<SceneObject*> candidate =
					priorityIterator.getNextValue();

			if (candidate == nullptr)
				continue;

			SharedObjectTemplate* candidateTemplate =
					candidate->getObjectTemplate();

			if (candidateTemplate == nullptr)
				continue;

			if (candidateTemplate->getFullTemplateString() ==
					priorityTemplate) {
				priorityObject = candidate;
				priorityObjectID = candidate->getObjectID();
				break;
			}
		}
	}

	// Snapshot only the three camp-related templates before any zone objects
	// are removed. This lets the shutdown log describe their relationships
	// without changing destruction order or behavior.
	if (detailedDiagnostics) {
		auto campIterator = tbl.iterator();

		while (campIterator.hasNext()) {
			ManagedReference<SceneObject*> candidate =
					campIterator.getNextValue();

			if (candidate == nullptr)
				continue;

			SharedObjectTemplate* candidateTemplate =
					candidate->getObjectTemplate();

			if (candidateTemplate == nullptr)
				continue;

			String templateString =
					candidateTemplate->getFullTemplateString();
			std::string templatePath(templateString.toCharArray());

			const bool isRebelBanner =
					templatePath == rebelBannerTemplate;
			const bool isImperialBanner =
					templatePath == imperialBannerTemplate;
			const bool isPavilion =
					templatePath == pavilionTemplate;

			if (!isRebelBanner && !isImperialBanner && !isPavilion)
				continue;

			CampObjectSnapshot snapshot;
			snapshot.objectID = candidate->getObjectID();
			snapshot.templatePath = templatePath;
			snapshot.isRebelBanner = isRebelBanner;
			snapshot.isImperialBanner = isImperialBanner;
			snapshot.isPavilion = isPavilion;
			snapshot.worldX = candidate->getWorldPositionX();
			snapshot.worldY = candidate->getWorldPositionY();
			snapshot.worldZ = candidate->getWorldPositionZ();

			ManagedReference<SceneObject*> parent =
					candidate->getParent().get();

			if (parent != nullptr) {
				snapshot.parentID = parent->getObjectID();
				snapshot.parentIsTheater = parent->isTheaterObject();

				SharedObjectTemplate* parentObjectTemplate =
						parent->getObjectTemplate();

				if (parentObjectTemplate != nullptr) {
					String parentTemplateString =
							parentObjectTemplate->
							getFullTemplateString();
					snapshot.parentTemplate =
							parentTemplateString.toCharArray();
				}
			} else {
				campObjectsWithoutParent++;
			}

			ManagedReference<SceneObject*> rootParent =
					candidate->getRootParent();

			if (rootParent != nullptr &&
					rootParent->getObjectID() !=
					candidate->getObjectID()) {
				snapshot.rootID = rootParent->getObjectID();
				snapshot.rootIsTheater =
						rootParent->isTheaterObject();

				SharedObjectTemplate* rootObjectTemplate =
						rootParent->getObjectTemplate();

				if (rootObjectTemplate != nullptr) {
					String rootTemplateString =
							rootObjectTemplate->
							getFullTemplateString();
					snapshot.rootTemplate =
							rootTemplateString.toCharArray();
				}
			} else {
				campObjectsWithoutRoot++;
			}

			const long long coordinateX =
					std::llround(snapshot.worldX * 10.0f);
			const long long coordinateY =
					std::llround(snapshot.worldY * 10.0f);
			const long long coordinateZ =
					std::llround(snapshot.worldZ * 10.0f);

			CampCoordinateAggregate& coordinateAggregate =
					campCoordinateAggregates[
							std::make_tuple(
									coordinateX,
									coordinateY,
									coordinateZ)];

			coordinateAggregate.worldX = snapshot.worldX;
			coordinateAggregate.worldY = snapshot.worldY;
			coordinateAggregate.worldZ = snapshot.worldZ;

			if (snapshot.isRebelBanner) {
				coordinateAggregate.rebelBannerCount++;
				addSampleObjectID(
						coordinateAggregate.rebelSamples,
						snapshot.objectID);
			}

			if (snapshot.isImperialBanner) {
				coordinateAggregate.imperialBannerCount++;
				addSampleObjectID(
						coordinateAggregate.imperialSamples,
						snapshot.objectID);
			}

			if (snapshot.isPavilion) {
				coordinateAggregate.pavilionCount++;
				addSampleObjectID(
						coordinateAggregate.pavilionSamples,
						snapshot.objectID);
			}

			addCampRelationship(
					campParentAggregates,
					snapshot.parentID,
					snapshot.parentTemplate,
					snapshot.parentIsTheater,
					snapshot);

			addCampRelationship(
					campRootAggregates,
					snapshot.rootID,
					snapshot.rootTemplate,
					snapshot.rootIsTheater,
					snapshot);

			if (snapshot.isPavilion) {
				PavilionBannerAggregate pavilion;
				pavilion.pavilionID = snapshot.objectID;
				pavilion.parentID = snapshot.parentID;
				pavilion.rootID = snapshot.rootID;
				pavilion.parentTemplate =
						snapshot.parentTemplate;
				pavilion.rootTemplate =
						snapshot.rootTemplate;
				pavilion.parentIsTheater =
						snapshot.parentIsTheater;
				pavilion.rootIsTheater =
						snapshot.rootIsTheater;
				pavilion.worldX = snapshot.worldX;
				pavilion.worldY = snapshot.worldY;
				pavilion.worldZ = snapshot.worldZ;

				pavilionAggregates[snapshot.objectID] = pavilion;
			}

			campSnapshots.push_back(snapshot);
		}

		std::map<std::pair<int, int>, std::vector<uint64>>
				pavilionGrid;

		for (const auto& pavilionEntry : pavilionAggregates) {
			const PavilionBannerAggregate& pavilion =
					pavilionEntry.second;
			const int gridX = static_cast<int>(
					std::floor(pavilion.worldX /
					pavilionGridSize));
			const int gridY = static_cast<int>(
					std::floor(pavilion.worldY /
					pavilionGridSize));

			pavilionGrid[std::make_pair(gridX, gridY)].
					push_back(pavilion.pavilionID);
		}

		for (const CampObjectSnapshot& snapshot : campSnapshots) {
			if (!snapshot.isRebelBanner &&
					!snapshot.isImperialBanner)
				continue;

			const int bannerGridX = static_cast<int>(
					std::floor(snapshot.worldX /
					pavilionGridSize));
			const int bannerGridY = static_cast<int>(
					std::floor(snapshot.worldY /
					pavilionGridSize));

			uint64 nearestPavilionID = 0;
			float nearestDistanceSquared =
					pavilionSearchRadiusSquared;

			for (int offsetX = -1; offsetX <= 1; ++offsetX) {
				for (int offsetY = -1; offsetY <= 1; ++offsetY) {
					auto gridIterator = pavilionGrid.find(
							std::make_pair(
									bannerGridX + offsetX,
									bannerGridY + offsetY));

					if (gridIterator == pavilionGrid.end())
						continue;

					for (uint64 pavilionID :
							gridIterator->second) {
						auto pavilionIterator =
								pavilionAggregates.find(
										pavilionID);

						if (pavilionIterator ==
								pavilionAggregates.end())
							continue;

						const PavilionBannerAggregate& pavilion =
								pavilionIterator->second;
						const float deltaX =
								snapshot.worldX -
								pavilion.worldX;
						const float deltaY =
								snapshot.worldY -
								pavilion.worldY;
						const float distanceSquared =
								deltaX * deltaX +
								deltaY * deltaY;

						if (distanceSquared <=
								nearestDistanceSquared) {
							nearestDistanceSquared =
									distanceSquared;
							nearestPavilionID =
									pavilionID;
						}
					}
				}
			}

			if (nearestPavilionID == 0) {
				bannersWithoutNearbyPavilion++;
				continue;
			}

			PavilionBannerAggregate& pavilion =
					pavilionAggregates[nearestPavilionID];

			if (snapshot.isRebelBanner)
				pavilion.rebelBannerCount++;

			if (snapshot.isImperialBanner)
				pavilion.imperialBannerCount++;

			pavilion.farthestBannerDistanceSquared =
					std::max(
							pavilion.
							farthestBannerDistanceSquared,
							nearestDistanceSquared);
		}
	}

	auto zoneStartTime = std::chrono::steady_clock::now();

	info(true) << "[ZONE-CLEAR-DIAG] zone=" << zoneName
			<< " initialObjects=" << initialObjectCount;

	zonelocker.release();

	int processedObjectCount = 0;
	int nullObjectCount = 0;
	int slowObjectCount = 0;
	bool priorityObjectProcessed = false;

	if (priorityObject != nullptr) {
		const int gameObjectType = priorityObject->getGameObjectType();

		auto lockStartTime = std::chrono::steady_clock::now();

		Locker priorityLocker(priorityObject);

		const long long lockElapsedMs =
				std::chrono::duration_cast<std::chrono::milliseconds>(
						std::chrono::steady_clock::now() -
						lockStartTime).count();

		auto destroyStartTime = std::chrono::steady_clock::now();

		priorityObject->destroyObjectFromWorld(false);

		const long long destroyElapsedMs =
				std::chrono::duration_cast<std::chrono::milliseconds>(
						std::chrono::steady_clock::now() -
						destroyStartTime).count();

		priorityLocker.release();
		priorityObjectProcessed = true;

		if (lockElapsedMs >= slowObjectThresholdMs ||
				destroyElapsedMs >= slowObjectThresholdMs) {
			slowObjectCount++;
		}

		if (detailedDiagnostics) {
			addZoneClearAggregate(
					typeAggregates,
					gameObjectType,
					priorityObjectID,
					lockElapsedMs,
					destroyElapsedMs);

			addZoneClearAggregate(
					templateAggregates,
					std::string(priorityTemplate.toCharArray()),
					priorityObjectID,
					lockElapsedMs,
					destroyElapsedMs);
		}

		info(true) << "[ZONE-CLEAR-PRIORITY] zone=" << zoneName
				<< " objectID=" << priorityObjectID
				<< " gameObjectType=" << gameObjectType
				<< " template=" << priorityTemplate
				<< " lockMs=" << lockElapsedMs
				<< " destroyMs=" << destroyElapsedMs
				<< " totalMs="
				<< (lockElapsedMs + destroyElapsedMs);
	} else if (detailedDiagnostics) {
		info(true) << "[ZONE-CLEAR-PRIORITY] zone=" << zoneName
				<< " template=" << priorityTemplate
				<< " status=not-found";
	}

	auto iterator = tbl.iterator();

	while (iterator.hasNext()) {
		ManagedReference<SceneObject*> sceno = iterator.getNextValue();

		if (sceno != nullptr) {
			const int objectIndex = processedObjectCount + 1;
			const uint64 objectID = sceno->getObjectID();

			// The priority object remains referenced by the copied table even
			// after it has been removed from the world. Count its table entry,
			// but do not destroy it a second time.
			if (!(priorityObjectProcessed &&
					objectID == priorityObjectID)) {
				auto lockStartTime =
						std::chrono::steady_clock::now();

				Locker locker(sceno);

				const long long lockElapsedMs =
						std::chrono::duration_cast<
								std::chrono::milliseconds>(
								std::chrono::steady_clock::now() -
								lockStartTime).count();

				String templatePath = "<unknown>";
				SharedObjectTemplate* objectTemplate =
						sceno->getObjectTemplate();

				if (objectTemplate != nullptr)
					templatePath =
							objectTemplate->getFullTemplateString();

				const int gameObjectType =
						sceno->getGameObjectType();

				auto destroyStartTime =
						std::chrono::steady_clock::now();

				sceno->destroyObjectFromWorld(false);

				const long long destroyElapsedMs =
						std::chrono::duration_cast<
								std::chrono::milliseconds>(
								std::chrono::steady_clock::now() -
								destroyStartTime).count();

				locker.release();

				if (detailedDiagnostics) {
					addZoneClearAggregate(
							typeAggregates,
							gameObjectType,
							objectID,
							lockElapsedMs,
							destroyElapsedMs);

					addZoneClearAggregate(
							templateAggregates,
							std::string(templatePath.toCharArray()),
							objectID,
							lockElapsedMs,
							destroyElapsedMs);
				}

				if (detailedDiagnostics &&
						(lockElapsedMs >= slowObjectThresholdMs ||
						destroyElapsedMs >=
								slowObjectThresholdMs)) {
					slowObjectCount++;

					info(true)
							<< "[ZONE-CLEAR-SLOW] zone="
							<< zoneName
							<< " index=" << objectIndex
							<< "/" << initialObjectCount
							<< " objectID=" << objectID
							<< " gameObjectType="
							<< gameObjectType
							<< " template=" << templatePath
							<< " lockMs=" << lockElapsedMs
							<< " destroyMs="
							<< destroyElapsedMs
							<< " totalMs="
							<< (lockElapsedMs +
								destroyElapsedMs);
				}
			}
		} else {
			nullObjectCount++;
		}

		processedObjectCount++;

		if ((processedObjectCount % progressInterval) == 0) {
			const long long zoneElapsedMs =
					std::chrono::duration_cast<
							std::chrono::milliseconds>(
							std::chrono::steady_clock::now() -
							zoneStartTime).count();

			info(true) << "[ZONE-CLEAR-DIAG] zone="
					<< zoneName
					<< " processed=" << processedObjectCount
					<< "/" << initialObjectCount
					<< " elapsedMs=" << zoneElapsedMs;
		}
	}

	if (detailedDiagnostics) {
		long long rebelBannerCount = 0;
		long long imperialBannerCount = 0;
		long long pavilionCount = 0;
		long long assignedBannerCount = 0;

		for (const CampObjectSnapshot& snapshot : campSnapshots) {
			if (snapshot.isRebelBanner)
				rebelBannerCount++;

			if (snapshot.isImperialBanner)
				imperialBannerCount++;

			if (snapshot.isPavilion)
				pavilionCount++;
		}

		std::vector<PavilionBannerAggregate> sortedPavilions;
		sortedPavilions.reserve(pavilionAggregates.size());

		std::map<int, int> pavilionBannerHistogram;

		for (const auto& pavilionEntry : pavilionAggregates) {
			const PavilionBannerAggregate& pavilion =
					pavilionEntry.second;
			const int bannerCount = static_cast<int>(
					pavilion.rebelBannerCount +
					pavilion.imperialBannerCount);

			assignedBannerCount += bannerCount;
			pavilionBannerHistogram[bannerCount]++;
			sortedPavilions.push_back(pavilion);
		}

		std::sort(
				sortedPavilions.begin(),
				sortedPavilions.end(),
				[](const PavilionBannerAggregate& left,
						const PavilionBannerAggregate& right) {
					const long long leftCount =
							left.rebelBannerCount +
							left.imperialBannerCount;
					const long long rightCount =
							right.rebelBannerCount +
							right.imperialBannerCount;

					return leftCount > rightCount;
				});

		info(true) << "[ZONE-CLEAR-CAMP-SUMMARY] zone="
				<< zoneName
				<< " trackedObjects=" << campSnapshots.size()
				<< " rebelBanners=" << rebelBannerCount
				<< " imperialBanners=" << imperialBannerCount
				<< " pavilions=" << pavilionCount
				<< " assignedBanners=" << assignedBannerCount
				<< " unassignedBanners="
				<< bannersWithoutNearbyPavilion
				<< " searchRadius=" << pavilionSearchRadius
				<< " objectsWithoutParent="
				<< campObjectsWithoutParent
				<< " objectsWithoutRoot="
				<< campObjectsWithoutRoot
				<< " parentGroups="
				<< campParentAggregates.size()
				<< " rootGroups="
				<< campRootAggregates.size();

		std::vector<CampCoordinateAggregate>
				sortedCoordinateAggregates;
		sortedCoordinateAggregates.reserve(
				campCoordinateAggregates.size());

		for (const auto& coordinateEntry :
				campCoordinateAggregates) {
			sortedCoordinateAggregates.push_back(
					coordinateEntry.second);
		}

		std::sort(
				sortedCoordinateAggregates.begin(),
				sortedCoordinateAggregates.end(),
				[](const CampCoordinateAggregate& left,
						const CampCoordinateAggregate& right) {
					const long long leftCount =
							left.rebelBannerCount +
							left.imperialBannerCount +
							left.pavilionCount;
					const long long rightCount =
							right.rebelBannerCount +
							right.imperialBannerCount +
							right.pavilionCount;

					return leftCount > rightCount;
				});

		info(true) << "[ZONE-CLEAR-CAMP-COORD-SUMMARY] zone="
				<< zoneName
				<< " coordinateGroups="
				<< sortedCoordinateAggregates.size()
				<< " outputLimit=20";

		const int coordinateOutputCount = std::min(
				20,
				static_cast<int>(
						sortedCoordinateAggregates.size()));

		for (int i = 0; i < coordinateOutputCount; ++i) {
			const CampCoordinateAggregate& aggregate =
					sortedCoordinateAggregates[i];
			const long long totalObjects =
					aggregate.rebelBannerCount +
					aggregate.imperialBannerCount +
					aggregate.pavilionCount;

			info(true) << "[ZONE-CLEAR-CAMP-COORD] rank="
					<< (i + 1)
					<< " x=" << aggregate.worldX
					<< " y=" << aggregate.worldY
					<< " z=" << aggregate.worldZ
					<< " totalObjects=" << totalObjects
					<< " rebelBanners="
					<< aggregate.rebelBannerCount
					<< " imperialBanners="
					<< aggregate.imperialBannerCount
					<< " pavilions="
					<< aggregate.pavilionCount
					<< " rebelSample1="
					<< (aggregate.rebelSamples.size() > 0 ?
							aggregate.rebelSamples[0] : 0)
					<< " rebelSample2="
					<< (aggregate.rebelSamples.size() > 1 ?
							aggregate.rebelSamples[1] : 0)
					<< " imperialSample1="
					<< (aggregate.imperialSamples.size() > 0 ?
							aggregate.imperialSamples[0] : 0)
					<< " imperialSample2="
					<< (aggregate.imperialSamples.size() > 1 ?
							aggregate.imperialSamples[1] : 0)
					<< " pavilionSample1="
					<< (aggregate.pavilionSamples.size() > 0 ?
							aggregate.pavilionSamples[0] : 0)
					<< " pavilionSample2="
					<< (aggregate.pavilionSamples.size() > 1 ?
							aggregate.pavilionSamples[1] : 0);
		}

		std::vector<std::pair<int, int>> sortedHistogram(
				pavilionBannerHistogram.begin(),
				pavilionBannerHistogram.end());

		std::sort(
				sortedHistogram.begin(),
				sortedHistogram.end(),
				[](const auto& left, const auto& right) {
					return left.second > right.second;
				});

		const int histogramOutputCount = std::min(
				20,
				static_cast<int>(sortedHistogram.size()));

		for (int i = 0; i < histogramOutputCount; ++i) {
			info(true) << "[ZONE-CLEAR-CAMP-HISTOGRAM] rank="
					<< (i + 1)
					<< " bannersPerPavilion="
					<< sortedHistogram[i].first
					<< " pavilionCount="
					<< sortedHistogram[i].second;
		}

		const int pavilionOutputCount = std::min(
				20,
				static_cast<int>(sortedPavilions.size()));

		for (int i = 0; i < pavilionOutputCount; ++i) {
			const PavilionBannerAggregate& pavilion =
					sortedPavilions[i];
			const long long totalBanners =
					pavilion.rebelBannerCount +
					pavilion.imperialBannerCount;

			info(true) << "[ZONE-CLEAR-CAMP-PAVILION] rank="
					<< (i + 1)
					<< " pavilionID=" << pavilion.pavilionID
					<< " x=" << pavilion.worldX
					<< " y=" << pavilion.worldY
					<< " z=" << pavilion.worldZ
					<< " rebelBanners="
					<< pavilion.rebelBannerCount
					<< " imperialBanners="
					<< pavilion.imperialBannerCount
					<< " totalBanners=" << totalBanners
					<< " farthestBannerDistance="
					<< std::sqrt(
							pavilion.
							farthestBannerDistanceSquared)
					<< " parentID=" << pavilion.parentID
					<< " parentTemplate="
					<< pavilion.parentTemplate.c_str()
					<< " parentIsTheater="
					<< (pavilion.parentIsTheater ? 1 : 0)
					<< " rootID=" << pavilion.rootID
					<< " rootTemplate="
					<< pavilion.rootTemplate.c_str()
					<< " rootIsTheater="
					<< (pavilion.rootIsTheater ? 1 : 0);
		}

		std::vector<CampRelationshipAggregate> sortedParents;
		sortedParents.reserve(campParentAggregates.size());

		for (const auto& parentEntry : campParentAggregates)
			sortedParents.push_back(parentEntry.second);

		std::sort(
				sortedParents.begin(),
				sortedParents.end(),
				[](const CampRelationshipAggregate& left,
						const CampRelationshipAggregate& right) {
					return left.totalCount > right.totalCount;
				});

		const int parentOutputCount = std::min(
				20,
				static_cast<int>(sortedParents.size()));

		for (int i = 0; i < parentOutputCount; ++i) {
			const CampRelationshipAggregate& aggregate =
					sortedParents[i];

			info(true) << "[ZONE-CLEAR-CAMP-PARENT] rank="
					<< (i + 1)
					<< " parentID=" << aggregate.groupID
					<< " parentTemplate="
					<< aggregate.groupTemplate.c_str()
					<< " parentIsTheater="
					<< (aggregate.isTheater ? 1 : 0)
					<< " totalObjects="
					<< aggregate.totalCount
					<< " rebelBanners="
					<< aggregate.rebelBannerCount
					<< " imperialBanners="
					<< aggregate.imperialBannerCount
					<< " pavilions="
					<< aggregate.pavilionCount
					<< " minX=" << aggregate.minX
					<< " maxX=" << aggregate.maxX
					<< " minY=" << aggregate.minY
					<< " maxY=" << aggregate.maxY;
		}

		std::vector<CampRelationshipAggregate> sortedRoots;
		sortedRoots.reserve(campRootAggregates.size());

		for (const auto& rootEntry : campRootAggregates)
			sortedRoots.push_back(rootEntry.second);

		std::sort(
				sortedRoots.begin(),
				sortedRoots.end(),
				[](const CampRelationshipAggregate& left,
						const CampRelationshipAggregate& right) {
					return left.totalCount > right.totalCount;
				});

		const int rootOutputCount = std::min(
				20,
				static_cast<int>(sortedRoots.size()));

		for (int i = 0; i < rootOutputCount; ++i) {
			const CampRelationshipAggregate& aggregate =
					sortedRoots[i];

			info(true) << "[ZONE-CLEAR-CAMP-ROOT] rank="
					<< (i + 1)
					<< " rootID=" << aggregate.groupID
					<< " rootTemplate="
					<< aggregate.groupTemplate.c_str()
					<< " rootIsTheater="
					<< (aggregate.isTheater ? 1 : 0)
					<< " totalObjects="
					<< aggregate.totalCount
					<< " rebelBanners="
					<< aggregate.rebelBannerCount
					<< " imperialBanners="
					<< aggregate.imperialBannerCount
					<< " pavilions="
					<< aggregate.pavilionCount
					<< " minX=" << aggregate.minX
					<< " maxX=" << aggregate.maxX
					<< " minY=" << aggregate.minY
					<< " maxY=" << aggregate.maxY;
		}

		std::vector<std::pair<int, ZoneClearAggregate>>
				sortedTypes(typeAggregates.begin(), typeAggregates.end());

		std::sort(
				sortedTypes.begin(),
				sortedTypes.end(),
				[](const auto& left, const auto& right) {
					const long long leftTotal =
							left.second.lockMs +
							left.second.destroyMs;
					const long long rightTotal =
							right.second.lockMs +
							right.second.destroyMs;

					return leftTotal > rightTotal;
				});

		info(true) << "[ZONE-CLEAR-TYPE-SUMMARY] zone=" << zoneName
				<< " entries=" << sortedTypes.size()
				<< " outputLimit=" << aggregateOutputLimit;

		const int typeOutputCount = std::min(
				aggregateOutputLimit,
				static_cast<int>(sortedTypes.size()));

		for (int i = 0; i < typeOutputCount; ++i) {
			const int gameObjectType = sortedTypes[i].first;
			const ZoneClearAggregate& aggregate =
					sortedTypes[i].second;
			const long long totalMs =
					aggregate.lockMs + aggregate.destroyMs;
			const long long averageMs =
					aggregate.objectCount > 0 ?
					totalMs / aggregate.objectCount : 0;

			info(true) << "[ZONE-CLEAR-TYPE] rank=" << (i + 1)
					<< " gameObjectType=" << gameObjectType
					<< " count=" << aggregate.objectCount
					<< " lockMs=" << aggregate.lockMs
					<< " destroyMs=" << aggregate.destroyMs
					<< " totalMs=" << totalMs
					<< " averageMs=" << averageMs
					<< " maxObjectMs="
					<< aggregate.maxTotalMs
					<< " maxObjectID="
					<< aggregate.maxObjectID;
		}

		std::vector<std::pair<std::string, ZoneClearAggregate>>
				sortedTemplates(
						templateAggregates.begin(),
						templateAggregates.end());

		std::sort(
				sortedTemplates.begin(),
				sortedTemplates.end(),
				[](const auto& left, const auto& right) {
					const long long leftTotal =
							left.second.lockMs +
							left.second.destroyMs;
					const long long rightTotal =
							right.second.lockMs +
							right.second.destroyMs;

					return leftTotal > rightTotal;
				});

		info(true) << "[ZONE-CLEAR-TEMPLATE-SUMMARY] zone="
				<< zoneName
				<< " entries=" << sortedTemplates.size()
				<< " outputLimit=" << aggregateOutputLimit;

		const int templateOutputCount = std::min(
				aggregateOutputLimit,
				static_cast<int>(sortedTemplates.size()));

		for (int i = 0; i < templateOutputCount; ++i) {
			const std::string& templatePath =
					sortedTemplates[i].first;
			const ZoneClearAggregate& aggregate =
					sortedTemplates[i].second;
			const long long totalMs =
					aggregate.lockMs + aggregate.destroyMs;
			const long long averageMs =
					aggregate.objectCount > 0 ?
					totalMs / aggregate.objectCount : 0;

			info(true) << "[ZONE-CLEAR-TEMPLATE] rank="
					<< (i + 1)
					<< " template=" << templatePath.c_str()
					<< " count=" << aggregate.objectCount
					<< " lockMs=" << aggregate.lockMs
					<< " destroyMs=" << aggregate.destroyMs
					<< " totalMs=" << totalMs
					<< " averageMs=" << averageMs
					<< " maxObjectMs="
					<< aggregate.maxTotalMs
					<< " maxObjectID="
					<< aggregate.maxObjectID;
		}
	}

	Locker zonelocker2(_this.getReferenceUnsafeStaticCast());

	HashTable<uint64, ManagedReference<SceneObject*> >
			remainingObjectTable;
	remainingObjectTable.copyFrom(*objectMap->getMap());

	const int remainingObjectCount = remainingObjectTable.size();

	if (detailedDiagnostics && remainingObjectCount > 0) {
		std::vector<RemainingObjectSnapshot> remainingSnapshots;
		std::map<int, RemainingObjectAggregate>
				remainingTypeAggregates;
		std::map<std::string, RemainingObjectAggregate>
				remainingTemplateAggregates;

		auto remainingIterator = remainingObjectTable.iterator();

		while (remainingIterator.hasNext()) {
			ManagedReference<SceneObject*> remainingObject =
					remainingIterator.getNextValue();

			if (remainingObject == nullptr)
				continue;

			RemainingObjectSnapshot snapshot;
			snapshot.objectID = remainingObject->getObjectID();
			snapshot.gameObjectType =
					remainingObject->getGameObjectType();
			snapshot.worldX =
					remainingObject->getWorldPositionX();
			snapshot.worldY =
					remainingObject->getWorldPositionY();
			snapshot.worldZ =
					remainingObject->getWorldPositionZ();

			SharedObjectTemplate* remainingTemplate =
					remainingObject->getObjectTemplate();

			if (remainingTemplate != nullptr) {
				String remainingTemplateString =
						remainingTemplate->
						getFullTemplateString();
				snapshot.templatePath =
						remainingTemplateString.toCharArray();
			} else {
				snapshot.templatePath = "<unknown>";
			}

			ManagedReference<SceneObject*> parent =
					remainingObject->getParent().get();

			if (parent != nullptr) {
				snapshot.parentID = parent->getObjectID();

				SharedObjectTemplate* parentTemplate =
						parent->getObjectTemplate();

				if (parentTemplate != nullptr) {
					String parentTemplateString =
							parentTemplate->
							getFullTemplateString();
					snapshot.parentTemplate =
							parentTemplateString.toCharArray();
				}
			}

			ManagedReference<SceneObject*> rootParent =
					remainingObject->getRootParent();

			if (rootParent != nullptr &&
					rootParent->getObjectID() !=
					remainingObject->getObjectID()) {
				snapshot.rootID =
						rootParent->getObjectID();

				SharedObjectTemplate* rootTemplate =
						rootParent->getObjectTemplate();

				if (rootTemplate != nullptr) {
					String rootTemplateString =
							rootTemplate->
							getFullTemplateString();
					snapshot.rootTemplate =
							rootTemplateString.toCharArray();
				}
			}

			addRemainingAggregate(
					remainingTypeAggregates[
							snapshot.gameObjectType],
					snapshot.objectID);

			addRemainingAggregate(
					remainingTemplateAggregates[
							snapshot.templatePath],
					snapshot.objectID);

			if (remainingSnapshots.size() < 30)
				remainingSnapshots.push_back(snapshot);
		}

		std::vector<std::pair<int, RemainingObjectAggregate>>
				sortedRemainingTypes(
						remainingTypeAggregates.begin(),
						remainingTypeAggregates.end());

		std::sort(
				sortedRemainingTypes.begin(),
				sortedRemainingTypes.end(),
				[](const auto& left, const auto& right) {
					return left.second.objectCount >
							right.second.objectCount;
				});

		info(true) << "[ZONE-CLEAR-REMAINING-TYPE-SUMMARY]"
				<< " zone=" << zoneName
				<< " entries="
				<< sortedRemainingTypes.size()
				<< " outputLimit=20";

		const int remainingTypeOutputCount = std::min(
				20,
				static_cast<int>(
						sortedRemainingTypes.size()));

		for (int i = 0; i < remainingTypeOutputCount; ++i) {
			const RemainingObjectAggregate& aggregate =
					sortedRemainingTypes[i].second;

			info(true) << "[ZONE-CLEAR-REMAINING-TYPE]"
					<< " rank=" << (i + 1)
					<< " gameObjectType="
					<< sortedRemainingTypes[i].first
					<< " count=" << aggregate.objectCount
					<< " sample1="
					<< (aggregate.sampleObjectIDs.size() > 0 ?
							aggregate.sampleObjectIDs[0] : 0)
					<< " sample2="
					<< (aggregate.sampleObjectIDs.size() > 1 ?
							aggregate.sampleObjectIDs[1] : 0)
					<< " sample3="
					<< (aggregate.sampleObjectIDs.size() > 2 ?
							aggregate.sampleObjectIDs[2] : 0);
		}

		std::vector<std::pair<std::string,
				RemainingObjectAggregate>>
				sortedRemainingTemplates(
						remainingTemplateAggregates.begin(),
						remainingTemplateAggregates.end());

		std::sort(
				sortedRemainingTemplates.begin(),
				sortedRemainingTemplates.end(),
				[](const auto& left, const auto& right) {
					return left.second.objectCount >
							right.second.objectCount;
				});

		info(true)
				<< "[ZONE-CLEAR-REMAINING-TEMPLATE-SUMMARY]"
				<< " zone=" << zoneName
				<< " entries="
				<< sortedRemainingTemplates.size()
				<< " outputLimit=20";

		const int remainingTemplateOutputCount = std::min(
				20,
				static_cast<int>(
						sortedRemainingTemplates.size()));

		for (int i = 0;
				i < remainingTemplateOutputCount;
				++i) {
			const RemainingObjectAggregate& aggregate =
					sortedRemainingTemplates[i].second;

			info(true) << "[ZONE-CLEAR-REMAINING-TEMPLATE]"
					<< " rank=" << (i + 1)
					<< " template="
					<< sortedRemainingTemplates[i].
							first.c_str()
					<< " count=" << aggregate.objectCount
					<< " sample1="
					<< (aggregate.sampleObjectIDs.size() > 0 ?
							aggregate.sampleObjectIDs[0] : 0)
					<< " sample2="
					<< (aggregate.sampleObjectIDs.size() > 1 ?
							aggregate.sampleObjectIDs[1] : 0)
					<< " sample3="
					<< (aggregate.sampleObjectIDs.size() > 2 ?
							aggregate.sampleObjectIDs[2] : 0);
		}

		for (int i = 0;
				i < static_cast<int>(remainingSnapshots.size());
				++i) {
			const RemainingObjectSnapshot& snapshot =
					remainingSnapshots[i];

			info(true) << "[ZONE-CLEAR-REMAINING-OBJECT]"
					<< " sampleIndex=" << (i + 1)
					<< " objectID=" << snapshot.objectID
					<< " gameObjectType="
					<< snapshot.gameObjectType
					<< " template="
					<< snapshot.templatePath.c_str()
					<< " x=" << snapshot.worldX
					<< " y=" << snapshot.worldY
					<< " z=" << snapshot.worldZ
					<< " parentID=" << snapshot.parentID
					<< " parentTemplate="
					<< snapshot.parentTemplate.c_str()
					<< " rootID=" << snapshot.rootID
					<< " rootTemplate="
					<< snapshot.rootTemplate.c_str();
		}
	}

	const long long totalZoneElapsedMs =
			std::chrono::duration_cast<std::chrono::milliseconds>(
					std::chrono::steady_clock::now() -
					zoneStartTime).count();

	info(true) << "[ZONE-CLEAR-DIAG] zone=" << zoneName
			<< " initialObjects=" << initialObjectCount
			<< " processedObjects=" << processedObjectCount
			<< " nullObjects=" << nullObjectCount
			<< " slowObjects=" << slowObjectCount
			<< " priorityProcessed="
			<< (priorityObjectProcessed ? 1 : 0)
			<< " remainingObjects=" << remainingObjectCount
			<< " totalElapsedMs=" << totalZoneElapsedMs;

	zoneCleared = true;

	info("zone clear", true);
}

/*

	Object Management in Zone

*/

void GroundZoneImplementation::insert(TreeEntry* entry) {
	if (entry == nullptr)
		return;

	Locker locker(_this.getReferenceUnsafeStaticCast());

	quadTree->insert(entry);

	/*
	SceneObject* sceneO = cast<SceneObject*>(entry);

	if (sceneO != nullptr && sceneO->isPlayerCreature())
		info(true) << "Inserting player into Quadtree: " + sceneO->getDisplayedName() << " ID: " << sceneO->getObjectID();
	*/
}

void GroundZoneImplementation::remove(TreeEntry* entry) {
	Locker locker(_this.getReferenceUnsafeStaticCast());

	if (entry->isInQuadTree()) {
		quadTree->remove(entry);

		/*
		SceneObject* sceneO = cast<SceneObject*>(entry);

		if (sceneO != nullptr && sceneO->isPlayerCreature())
			info(true) << "Removing player from Quadtree: " + sceneO->getDisplayedName() << " ID: " << sceneO->getObjectID();
		*/
	}
}

void GroundZoneImplementation::update(TreeEntry* entry) {
	Locker locker(_this.getReferenceUnsafeStaticCast());

	quadTree->update(entry);

	/*
	SceneObject* sceneO = cast<SceneObject*>(entry);

	if (sceneO != nullptr && sceneO->isPlayerCreature())
		info(true) << "Inserting player into Quadtree: " + sceneO->getDisplayedName() << " ID: " << sceneO->getObjectID();
	*/
}

void GroundZoneImplementation::inRange(TreeEntry* entry, float range) {
	quadTree->safeInRange(entry, range);
}

void GroundZoneImplementation::updateActiveAreas(TangibleObject* tano) {
	//Locker locker(_this.getReferenceUnsafeStaticCast());

	Locker _alocker(tano->getContainerLock());

	SortedVector<ManagedReference<ActiveArea* > > areas = *tano->getActiveAreas();

	_alocker.release();

	Vector3 worldPos = tano->getWorldPosition();

	SortedVector<ActiveArea*> entryObjects;

	Zone* managedRef = _this.getReferenceUnsafeStaticCast();

	bool readlock = !managedRef->isLockedByCurrentThread();

	managedRef->rlock(readlock);

	try {
		areaTree->getActiveAreas(worldPos.getX(), worldPos.getY(), entryObjects);

	} catch (...) {
		error("unexpeted error caught in void GroundZoneImplementation::updateActiveAreas(SceneObject* object) {");
	}

	managedRef->runlock(readlock);

	managedRef->unlock(!readlock);

	try {
		// update old ones
		for (int i = 0; i < areas.size(); ++i) {
			ManagedReference<ActiveArea*>& area = areas.getUnsafe(i);

			if (area == nullptr || area->isWorldSpawnArea())
				continue;

			if (!area->containsPoint(worldPos.getX(), worldPos.getY(), tano->getParentID())) {
				tano->dropActiveArea(area);
				area->enqueueExitEvent(tano);
			} else {
				area->notifyPositionUpdate(tano);
			}
		}

		// we update the ones in quadtree.
		for (int i = 0; i < entryObjects.size(); ++i) {
			//update in new ones
			ActiveArea* activeArea = static_cast<ActiveArea*>(entryObjects.getUnsafe(i));

			if (!tano->hasActiveArea(activeArea) && activeArea->containsPoint(worldPos.getX(), worldPos.getY(), tano->getParentID())) {
				tano->addActiveArea(activeArea);
				activeArea->enqueueEnterEvent(tano);
			}
		}

		// update Zones World Spawn Area
		if (creatureManager != nullptr) {
			auto worldArea = creatureManager->getWorldSpawnArea();

			if (worldArea != nullptr) {
				Reference<TangibleObject*> tanoStrong = tano;
				Reference<ActiveArea*> areaStrong = worldArea;

				Core::getTaskManager()->executeTask([areaStrong, tanoStrong] () {
					Locker lockerO(tanoStrong);

					if (!tanoStrong->hasActiveArea(areaStrong)) {
						tanoStrong->addActiveArea(areaStrong);
						areaStrong->notifyEnter(tanoStrong);
					} else {
						areaStrong->notifyPositionUpdate(tanoStrong);
					}
				}, "UpdateWorldActiveArea", zoneName);
			}
		}
	} catch (...) {
		error("unexpected exception caught in void GroundZoneImplementation::updateActiveAreas(SceneObject* object) {");
		managedRef->wlock(!readlock);
		throw;
	}

	managedRef->wlock(!readlock);
}

void GroundZoneImplementation::addSceneObject(SceneObject* object) {
	ManagedReference<SceneObject*> old = objectMap->put(object->getObjectID(), object);

	//Civic and commercial structures map registration will be handled by their city
	if (object->isStructureObject()) {
		StructureObject* structure = cast<StructureObject*>(object);
		if (structure->isCivicStructure() || structure->isCommercialStructure()) {
			return;
		}
	//Same thing for player city bank/mission terminals
	} else if (object->isTerminal()) {
		Terminal* terminal = cast<Terminal*>(object);
		ManagedReference<SceneObject*> controlledObject = terminal->getControlledObject();
		if (controlledObject != nullptr && controlledObject->isStructureObject()) {
			StructureObject* structure = controlledObject.castTo<StructureObject*>();
			if (structure->isCivicStructure())
				return;
		}
	} else if (old == nullptr && object->isAiAgent()) {
		spawnedAiAgents.increment();
	}

	registerObjectWithPlanetaryMap(object);
}

void GroundZoneImplementation::dropSceneObject(SceneObject* object)  {
	ManagedReference<SceneObject*> oldObject = objectMap->remove(object->getObjectID());

	unregisterObjectWithPlanetaryMap(object);

	if (oldObject != nullptr && oldObject->isAiAgent()) {
		spawnedAiAgents.decrement();
	}
}

/*

	Object Tracking

*/

int GroundZoneImplementation::getInRangeSolidObjects(float x, float z, float y, float range, SortedVector<ManagedReference<TreeEntry*> >* objects, bool readLockZone) {
	objects->setNoDuplicateInsertPlan();

	bool readlock = readLockZone && !_this.getReferenceUnsafeStaticCast()->isLockedByCurrentThread();

	try {
		_this.getReferenceUnsafeStaticCast()->rlock(readlock);

		quadTree->inRange(x, y, range, *objects);

		_this.getReferenceUnsafeStaticCast()->runlock(readlock);
	} catch (...) {
		_this.getReferenceUnsafeStaticCast()->runlock(readlock);
	}

	if (objects->size() > 0) {
		for (int i = objects->size() - 1; i >= 0; i--) {
			SceneObject* sceno = static_cast<SceneObject*>(objects->getUnsafe(i).get());

			if (sceno == nullptr || sceno->getParentID() != 0) {
				objects->remove(i);
				continue;
			}

			if (sceno->isCreatureObject() || sceno->isLairObject()) {
				objects->remove(i);
				continue;
			}

			if (sceno->getGameObjectType() == SceneObjectType::LIGHTOBJECT) {
				objects->remove(i);
				continue;
			}

			SharedObjectTemplate *shot = sceno->getObjectTemplate();

			if (shot == nullptr) {
				objects->remove(i);
				continue;
			}

			if (!shot->getCollisionMaterialFlags() || !shot->getCollisionMaterialBlockFlags() || !shot->isNavUpdatesEnabled()) {
				objects->remove(i);
				continue;
			}
		}
	}
	return objects->size();
}

int GroundZoneImplementation::getInRangeObjects(float x, float z, float y, float range, SortedVector<ManagedReference<TreeEntry*> >* objects, bool readLockZone, bool includeBuildingObjects) {
	objects->setNoDuplicateInsertPlan();

	bool readlock = readLockZone && !_this.getReferenceUnsafeStaticCast()->isLockedByCurrentThread();

	try {
		_this.getReferenceUnsafeStaticCast()->rlock(readlock);

		quadTree->inRange(x, y, range, *objects);

		_this.getReferenceUnsafeStaticCast()->runlock(readlock);
	} catch (...) {
		_this.getReferenceUnsafeStaticCast()->runlock(readlock);
	}

	if (includeBuildingObjects) {
		Vector<ManagedReference<TreeEntry*> > buildingObjects;

		for (int i = 0; i < objects->size(); ++i) {
			SceneObject* sceneObject = static_cast<SceneObject*>(objects->getUnsafe(i).get());
			BuildingObject* building = sceneObject->asBuildingObject();

			if (building != nullptr) {
				for (int j = 1; j <= building->getMapCellSize(); ++j) {
					CellObject* cell = building->getCell(j);

					if (cell != nullptr && cell->isContainerLoaded()) {
						try {
							ReadLocker rlocker(cell->getContainerLock());

							for (int h = 0; h < cell->getContainerObjectsSize(); ++h) {
								Reference<SceneObject*> obj = cell->getContainerObject(h);

								if (obj != nullptr)
									buildingObjects.emplace(std::move(obj));
							}

						} catch (...) {
						}
					}
				}
			} else if (sceneObject->isVehicleObject() || sceneObject->isMount()) {
				Reference<SceneObject*> rider = sceneObject->getSlottedObject("rider");

				if (rider != nullptr)
					buildingObjects.emplace(std::move(rider));
			}
		}

		//_this.getReferenceUnsafeStaticCast()->runlock(readlock);

		for (int i = 0; i < buildingObjects.size(); ++i)
			objects->put(std::move(buildingObjects.getUnsafe(i)));
	}

	return objects->size();
}

int GroundZoneImplementation::getInRangeObjects(float x, float z, float y, float range, InRangeObjectsVector* objects, bool readLockZone, bool includeBuildingObjects) {
	objects->setNoDuplicateInsertPlan();

	bool readlock = readLockZone && !_this.getReferenceUnsafeStaticCast()->isLockedByCurrentThread();

	try {
		_this.getReferenceUnsafeStaticCast()->rlock(readlock);

		quadTree->inRange(x, y, range, *objects);

		_this.getReferenceUnsafeStaticCast()->runlock(readlock);
	} catch (...) {
		_this.getReferenceUnsafeStaticCast()->runlock(readlock);
	}

	if (includeBuildingObjects) {
		Vector<TreeEntry*> buildingObjects;

		for (int i = 0; i < objects->size(); ++i) {
			SceneObject* sceneObject = static_cast<SceneObject*>(objects->getUnsafe(i));

			BuildingObject* building = sceneObject->asBuildingObject();

			if (building != nullptr) {
				for (int j = 1; j <= building->getMapCellSize(); ++j) {
					CellObject* cell = building->getCell(j);

					if (cell != nullptr && cell->isContainerLoaded()) {
						try {
							ReadLocker rlocker(cell->getContainerLock());

							for (int h = 0; h < cell->getContainerObjectsSize(); ++h) {
								Reference<SceneObject*> obj = cell->getContainerObject(h);

								if (obj != nullptr)
									buildingObjects.add(obj.get());
							}

						} catch (Exception& e) {
							warning("exception in Zone::GetInRangeObjects: " + e.getMessage());
						}
					}
				}
			} else if (sceneObject->isVehicleObject() || sceneObject->isMount()) {
				Reference<SceneObject*> rider = sceneObject->getSlottedObject("rider");

				if (rider != nullptr)
					buildingObjects.add(rider.get());
			}
		}

		for (int i = 0; i < buildingObjects.size(); ++i)
			objects->put(buildingObjects.getUnsafe(i));
	}

	return objects->size();
}

int GroundZoneImplementation::getInRangePlayers(float x, float z, float y, float range, SortedVector<ManagedReference<TreeEntry*> >* players) {
	Reference<SortedVector<ManagedReference<TreeEntry*> >*> closeObjects = new SortedVector<ManagedReference<TreeEntry*> >();

	getInRangeObjects(x, 0, y, range, closeObjects, true);

	for (int i = 0; i < closeObjects->size(); ++i) {
		SceneObject* object = cast<SceneObject*>(closeObjects->get(i).get());

		if (object == nullptr || !object->isPlayerCreature())
			continue;

		CreatureObject* player = object->asCreatureObject();

		if (player == nullptr || player->isInvisible())
			continue;

		players->emplace(object);
	}

	return players->size();
}

int GroundZoneImplementation::getInRangeActiveAreas(float x, float z, float y, SortedVector<ManagedReference<ActiveArea*> >* objects, bool readLockZone) {
	objects->setNoDuplicateInsertPlan();

	bool readlock = readLockZone && !_this.getReferenceUnsafeStaticCast()->isLockedByCurrentThread();

	Zone* thisZone = _this.getReferenceUnsafeStaticCast();

	try {
		thisZone->rlock(readlock);

		areaTree->getActiveAreas(x, y, *objects);

		thisZone->runlock(readlock);
	} catch (...) {
		thisZone->runlock(readlock);

		throw;
	}

	return objects->size();
}

int GroundZoneImplementation::getInRangeActiveAreas(float x, float z, float y, ActiveAreasVector* objects, bool readLockZone) {
	objects->setNoDuplicateInsertPlan();

	bool readlock = readLockZone && !_this.getReferenceUnsafeStaticCast()->isLockedByCurrentThread();

	Zone* thisZone = _this.getReferenceUnsafeStaticCast();

	try {
		thisZone->rlock(readlock);

		areaTree->getActiveAreas(x, y, *objects);

		thisZone->runlock(readlock);
	} catch (...) {
		thisZone->runlock(readlock);

		throw;
	}

	return objects->size();
}

/*

	Quadtree

*/

float GroundZoneImplementation::getHeight(float x, float y) {
	if (planetManager != nullptr) {
		TerrainManager* manager = planetManager->getTerrainManager();

		if (manager != nullptr)
			return manager->getHeight(x, y);
	}

	return 0;
}

float GroundZoneImplementation::getHeightNoCache(float x, float y) {
	if (planetManager != nullptr) {
		TerrainManager* manager = planetManager->getTerrainManager();

		if (manager != nullptr) {
			ProceduralTerrainAppearance *appearance = manager->getProceduralTerrainAppearance();
			if (appearance != nullptr)
				return appearance->getHeight(x, y);
		}
	}

	return 0;
}

Reference<SceneObject*> GroundZoneImplementation::getNearestPlanetaryObject(SceneObject* object, const String& mapCategory, const String& mapSubCategory) {
	Reference<SceneObject*> planetaryObject = nullptr;

#ifndef WITH_STM
	ReadLocker rlocker(mapLocations);
#endif

	// info(true) << "getNearestPlanetaryObject - To: " << object->getDisplayedName() << " MapCategory: " << mapCategory << " SubCategory: " << mapSubCategory;

	const SortedVector<MapLocationEntry>& sortedVector = mapLocations->getLocation(mapCategory);

	Vector3 objectPos = object->getWorldPosition();
	int distanceCheck = 16000 * 16000;

	// info(true) << "Sub Category: " << mapSubCategory;

	for (int i = 0; i < sortedVector.size(); ++i) {
		SceneObject* sceneO = sortedVector.getUnsafe(i).getObject();

		if (sceneO == nullptr)
			continue;

		const String subCategory = sceneO->getPlanetMapSubCategoryName();

		// info(true) << " Checking against Object Sub Category: " << subCategory;

		if (!mapSubCategory.isEmpty() && !subCategory.isEmpty() && !subCategory.contains(mapSubCategory))
			continue;

		float objDistanceSq = objectPos.squaredDistanceTo(sceneO->getWorldPosition());

		// info(true) << "Map Object Distance = " << objDistanceSq << " Checking against: " << distanceCheck;

		if (objDistanceSq < distanceCheck) {
			// Set object as our current closest planetary object of that type
			planetaryObject = sceneO;

			// Update the distance to check against
			distanceCheck = objDistanceSq;
		}
	}

	return planetaryObject;
}

int GroundZoneImplementation::getInRangeNavMeshes(float x, float y, SortedVector<ManagedReference<NavArea*> >* objects, bool readlock) {
	objects->setNoDuplicateInsertPlan();

	Zone* thisZone = _this.getReferenceUnsafeStaticCast();

	SortedVector<ActiveArea*> entryObjects;

	ReadLocker rlocker(thisZone);

	areaTree->getActiveAreas(x, y, entryObjects);

	for (int i = 0; i < entryObjects.size(); ++i) {
		ActiveArea* area = static_cast<ActiveArea*>(entryObjects.getUnsafe(i));
		NavArea* obj = area->asNavArea();

		if (obj && obj->isNavMeshLoaded()) {
			objects->put(obj);
		}
	}

	return objects->size();
}

SortedVector<ManagedReference<SceneObject*> > GroundZoneImplementation::getPlanetaryObjectList(const String& mapCategory) {
	SortedVector<ManagedReference<SceneObject*> > retVector;
	retVector.setNoDuplicateInsertPlan();

#ifndef WITH_STM
	ReadLocker rlocker(mapLocations);
#endif

	const SortedVector<MapLocationEntry>& entryVector = mapLocations->getLocation(mapCategory);

	for (int i = 0; i < entryVector.size(); ++i) {
		const MapLocationEntry& entry = entryVector.getUnsafe(i);
		retVector.put(entry.getObject());
	}

	return retVector;
}

void GroundZoneImplementation::registerObjectWithPlanetaryMap(SceneObject* object) {
#ifndef WITH_STM
	Locker locker(mapLocations);
#endif
	mapLocations->transferObject(object);

	// If the object is a valid location for entertainer missions then add it
	// to the planet's mission map.
	if (objectIsValidPlanetaryMapPerformanceLocation(object)) {
		PlanetManager* planetManager = getPlanetManager();
		if (planetManager != nullptr) {
			planetManager->addPerformanceLocation(object);
		}
	}
}

void GroundZoneImplementation::unregisterObjectWithPlanetaryMap(SceneObject* object) {
#ifndef WITH_STM
	Locker locker(mapLocations);
#endif
	mapLocations->dropObject(object);

	// If the object is a valid location for entertainer missions then remove it
	// from the planet's mission map.
	if (objectIsValidPlanetaryMapPerformanceLocation(object)) {
		PlanetManager* planetManager = getPlanetManager();
		if (planetManager != nullptr) {
			planetManager->removePerformanceLocation(object);
		}
	}
}

bool GroundZoneImplementation::objectIsValidPlanetaryMapPerformanceLocation(SceneObject* object) {
	BuildingObject* building = object->asBuildingObject();
	if (building == nullptr) {
		return false;
	}

	bool hasPerformanceLocationCategory = false;

	const PlanetMapCategory* planetMapCategory = object->getPlanetMapCategory();
	if (planetMapCategory != nullptr) {
		String category = planetMapCategory->getName();

		if (category == "cantina" || category == "hotel") {
			hasPerformanceLocationCategory = true;
		}
	}

	if (!hasPerformanceLocationCategory) {
		const PlanetMapSubCategory* planetMapSubCategory = object->getPlanetMapSubCategory();

		if (planetMapCategory != nullptr) {
			String subCategory = planetMapSubCategory->getName();

			if (subCategory == "guild_theater") {
				hasPerformanceLocationCategory = true;
			}
		}
	}

	if (hasPerformanceLocationCategory) {
		if (building->isPublicStructure()) {
			return true;
		}
	}

	return false;
}

bool GroundZoneImplementation::isObjectRegisteredWithPlanetaryMap(SceneObject* object) {
#ifndef WITH_STM
	Locker locker(mapLocations);
#endif
	return mapLocations->containsObject(object);
}

void GroundZoneImplementation::updatePlanetaryMapIcon(SceneObject* object, byte icon) {
#ifndef WITH_STM
	Locker locker(mapLocations);
#endif
	mapLocations->updateObjectsIcon(object, icon);
}

void GroundZoneImplementation::sendMapLocationsTo(CreatureObject* player) {
	GetMapLocationsResponseMessage* gmlr = new GetMapLocationsResponseMessage(zoneName, mapLocations, player);
	player->sendMessage(gmlr);
}

float GroundZoneImplementation::getMinX() {
	return planetManager->getTerrainManager()->getMin();
}

float GroundZoneImplementation::getMaxX() {
	return planetManager->getTerrainManager()->getMax();
}

float GroundZoneImplementation::getMinY() {
	return planetManager->getTerrainManager()->getMin();
}

float GroundZoneImplementation::getMaxY() {
	return planetManager->getTerrainManager()->getMax();
}

void GroundZoneImplementation::updateCityRegions() {
	bool log = cityRegionUpdateVector.size() > 0;
	info("scheduling updates for " + String::valueOf(cityRegionUpdateVector.size()) + " cities", log);

	bool forceRebuild = server->shouldDeleteNavAreas();

	for (int i = 0; i < cityRegionUpdateVector.size(); ++i) {
		CityRegion* city = cityRegionUpdateVector.get(i);

		Locker locker(city);

		Time* nextUpdateTime = city->getNextUpdateTime();
		int seconds = -1 * round(nextUpdateTime->miliDifference() / 1000.f);

		if (seconds < 0) //If the update occurred in the past, force an immediate update.
			seconds = 0;

		city->setRadius(city->getRadius());
		city->setLoaded();

		city->cleanupCitizens();
		//city->cleanupDuplicateCityStructures();

		city->rescheduleUpdateEvent(seconds);

		if (city->hasAssessmentPending()) {
			Time* nextAssessmentTime = city->getNextAssessmentTime();
			int seconds2 = -1 * round(nextAssessmentTime->miliDifference() / 1000.f);

			if (seconds2 < 0)
				seconds2 = 0;

			city->scheduleCitizenAssessment(seconds2);
		}

		city->createNavMesh(NavMeshManager::MeshQueue, forceRebuild);

		if (!city->isRegistered())
			continue;

		if (city->getRegionsCount() == 0)
			continue;

		Region* region = city->getRegion(0);

		unregisterObjectWithPlanetaryMap(region);
		registerObjectWithPlanetaryMap(region);

		for(int i = 0; i < city->getStructuresCount(); i++){
			ManagedReference<StructureObject*> structure = city->getCivicStructure(i);
			unregisterObjectWithPlanetaryMap(structure);
			registerObjectWithPlanetaryMap(structure);
		}

		for(int i = 0; i < city->getCommercialStructuresCount(); i++){
			ManagedReference<StructureObject*> structure = city->getCommercialStructure(i);
			unregisterObjectWithPlanetaryMap(structure);
			registerObjectWithPlanetaryMap(structure);
		}
	}

	cityRegionUpdateVector.removeAll();
}

/*

	Shared Functions

*/

bool GroundZoneImplementation::isWithinBoundaries(const Vector3& position) {
	//Remove 1/16th of the size to match client limits. NOTE: it has not been verified to work like this in the client.
	//Normal zone size is 8192, 1/16th of that is 512 resulting in 7680 as the boundary value.
	float maxX = getMaxX() * 15 / 16;
	float minX = getMinX() * 15 / 16;
	float maxY = getMaxY() * 15 / 16;
	float minY = getMinY() * 15 / 16;

	if (maxX >= position.getX() && minX <= position.getX() &&
			maxY >= position.getY() && minY <= position.getY()) {
		return true;
	} else {
		return false;
	}
}

float GroundZoneImplementation::getBoundingRadius() {
	return planetManager->getTerrainManager()->getMax();
}

GroundZone* GroundZoneImplementation::asGroundZone() {
	return _this.getReferenceUnsafeStaticCast();
}

GroundZone* GroundZone::asGroundZone() {
	return this;
}
