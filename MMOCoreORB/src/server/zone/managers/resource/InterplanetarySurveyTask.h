/*
 * InterplanetrySurveyTask.h
 *
 *  Created on: 6/8/2014
 *      Author: washu
 */

#ifndef INTERPLANETARYSURVERYTASK_H_
#define INTERPLANETARYSURVERYTASK_H_

#include "server/ServerCore.h"
#include "server/zone/Zone.h"
#include "server/zone/managers/resource/ResourceManager.h"
#include "server/zone/objects/resource/ResourceSpawn.h"
#include "server/zone/managers/player/PlayerManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/waypoint/WaypointObject.h"
#include "server/chat/ChatManager.h"

// A single sampled point of a resource's concentration map. Plain POD -- kept out of the
// engine's Vector<> (which requires E to support binary (de)serialization); a fixed-size
// array is used for the hotspot list instead since there are always at most MAX_HOTSPOTS.
struct SurveyHotspotSample {
	float x = 0.f;
	float y = 0.f;
	float density = -1.f;
};

class InterplanetarySurveyTask : public Task {
	ManagedReference<InterplanetarySurvey*> surveyData;

	static const int COARSE_GRID_SIZE = 24; // planet-wide sampling resolution per candidate resource
	static const int FINE_GRID_SIZE = 10; // local refinement resolution around the winning hotspot
	static const int MAX_HOTSPOTS = 3; // best / secondary / tertiary

public:

	InterplanetarySurveyTask(InterplanetarySurvey* survey) {
		surveyData = survey;
	}

	void run() {
		ManagedReference<ResourceManager*> rmanager = ServerCore::getZoneServer()->getResourceManager();
		ManagedReference<ChatManager*> chat = ServerCore::getZoneServer()->getChatManager();

		String sender = "interplanetary survey droid";
		String planetName = surveyData->getPlanet();
		String requestedResource = surveyData->getResourceName();

		String displayPlanet = planetName;

		if (!displayPlanet.isEmpty())
			displayPlanet[0] = toupper(displayPlanet[0]);

		UnicodeString subject(String("Planetary Survey Droid: " + displayPlanet));

		Zone* zone = ServerCore::getZoneServer()->getZone(planetName);

		// Gather the candidate resource(s) to scan: either the single resource the player
		// chose, or -- if they picked "Best Match (Auto-Select)" -- every currently active
		// resource in the requested survey category on this planet.
		Vector<ManagedReference<ResourceSpawn*> > candidates;

		if (!requestedResource.isEmpty()) {
			ResourceSpawn* spawn = rmanager->getResourceSpawn(requestedResource);

			if (spawn != nullptr && spawn->inShift())
				candidates.add(spawn);
		} else {
			rmanager->getResourceListByType(candidates, surveyData->getSurveyToolType(), planetName);
		}

		if (zone == nullptr || candidates.size() == 0) {
			sendNoMatchReport(chat, sender, subject, displayPlanet);
			finish();
			return;
		}

		String zoneName = zone->getZoneName();
		float minX = zone->getMinX();
		float maxX = zone->getMaxX();
		float minY = zone->getMinY();
		float maxY = zone->getMaxY();

		// --- Resource concentration lookup happens here ---
		// For every candidate resource, sample its live concentration map (ResourceSpawn::
		// getDensityAt(), backed by the resource's per-zone simplex-noise SpawnDensityMap)
		// across a coarse grid spanning the whole planet, and track whichever resource has
		// the single strongest sample. This is the server's own active resource spawn data --
		// no GalaxyHarvester or any external source is consulted.
		ResourceSpawn* bestSpawn = nullptr;
		float bestDensity = -1.f;

		for (int c = 0; c < candidates.size(); ++c) {
			ResourceSpawn* spawn = candidates.get(c);

			float spacingX = (maxX - minX) / (COARSE_GRID_SIZE - 1);
			float spacingY = (maxY - minY) / (COARSE_GRID_SIZE - 1);

			for (int i = 0; i < COARSE_GRID_SIZE; ++i) {
				float x = minX + i * spacingX;

				for (int j = 0; j < COARSE_GRID_SIZE; ++j) {
					float y = minY + j * spacingY;
					float density = spawn->getDensityAt(zoneName, x, y);

					if (density > bestDensity) {
						bestDensity = density;
						bestSpawn = spawn;
					}
				}
			}
		}

		if (bestSpawn == nullptr || bestDensity <= 0.f) {
			sendNoMatchReport(chat, sender, subject, displayPlanet);
			finish();
			return;
		}

		// Re-scan the winning resource, this time keeping the top (up to) 3 non-overlapping
		// hotspots, then refine the best one with a finer local grid search around it.
		SurveyHotspotSample hotspots[MAX_HOTSPOTS];
		int hotspotCount = 0;

		float planetWidth = maxX - minX;
		float planetHeight = maxY - minY;
		float minSeparation = (planetWidth > planetHeight ? planetWidth : planetHeight) * 0.1f;

		scanTopHotspots(bestSpawn, zoneName, minX, maxX, minY, maxY, minSeparation, hotspots, hotspotCount);

		if (hotspotCount > 0) {
			float spacingX = (maxX - minX) / (COARSE_GRID_SIZE - 1);
			float spacingY = (maxY - minY) / (COARSE_GRID_SIZE - 1);

			refineHotspot(bestSpawn, zoneName, hotspots[0], spacingX, spacingY, minX, maxX, minY, maxY);
		}

		sendHotspotReport(chat, sender, subject, displayPlanet, bestSpawn, hotspots, hotspotCount);

		// Drop a temporary waypoint on the best hotspot for the player, if they're online.
		createHotspotWaypoint(zone, hotspots, hotspotCount);

		finish();
	}

private:

	// Samples a resource's concentration map across the whole planet on a coarse grid,
	// keeping the (up to MAX_HOTSPOTS) strongest samples that are at least minSeparation
	// game units apart from one another (so we report distinct hotspots, not the same peak
	// sampled twice).
	void scanTopHotspots(ResourceSpawn* spawn, const String& zoneName, float minX, float maxX,
			float minY, float maxY, float minSeparation, SurveyHotspotSample* results, int& resultCount) const {

		float spacingX = (maxX - minX) / (COARSE_GRID_SIZE - 1);
		float spacingY = (maxY - minY) / (COARSE_GRID_SIZE - 1);

		for (int i = 0; i < COARSE_GRID_SIZE; ++i) {
			float x = minX + i * spacingX;

			for (int j = 0; j < COARSE_GRID_SIZE; ++j) {
				float y = minY + j * spacingY;
				float density = spawn->getDensityAt(zoneName, x, y);

				if (density <= 0.f)
					continue;

				SurveyHotspotSample sample;
				sample.x = x;
				sample.y = y;
				sample.density = density;

				insertHotspot(results, resultCount, sample, minSeparation);
			}
		}

		// Simple insertion sort of the (at most MAX_HOTSPOTS) results, descending by density.
		for (int i = 1; i < resultCount; ++i) {
			SurveyHotspotSample sample = results[i];
			int j = i - 1;

			while (j >= 0 && results[j].density < sample.density) {
				results[j + 1] = results[j];
				--j;
			}

			results[j + 1] = sample;
		}
	}

	void insertHotspot(SurveyHotspotSample* results, int& resultCount, const SurveyHotspotSample& sample, float minSeparation) const {
		for (int i = 0; i < resultCount; ++i) {
			SurveyHotspotSample& existing = results[i];

			float dx = existing.x - sample.x;
			float dy = existing.y - sample.y;

			if (Math::sqrt(dx * dx + dy * dy) < minSeparation) {
				if (sample.density > existing.density)
					existing = sample;

				return;
			}
		}

		if (resultCount < MAX_HOTSPOTS) {
			results[resultCount] = sample;
			++resultCount;
			return;
		}

		int weakestIdx = 0;

		for (int i = 1; i < resultCount; ++i) {
			if (results[i].density < results[weakestIdx].density)
				weakestIdx = i;
		}

		if (sample.density > results[weakestIdx].density)
			results[weakestIdx] = sample;
	}

	// Local hill-climb: re-samples a finer grid within one coarse cell's radius of the given
	// hotspot to pinpoint the peak more precisely than the planet-wide coarse pass alone.
	void refineHotspot(ResourceSpawn* spawn, const String& zoneName, SurveyHotspotSample& sample,
			float windowX, float windowY, float minX, float maxX, float minY, float maxY) const {

		float startX = sample.x - windowX;
		float startY = sample.y - windowY;
		float spacingX = (windowX * 2.f) / (FINE_GRID_SIZE - 1);
		float spacingY = (windowY * 2.f) / (FINE_GRID_SIZE - 1);

		for (int i = 0; i < FINE_GRID_SIZE; ++i) {
			float x = startX + i * spacingX;

			if (x < minX || x > maxX)
				continue;

			for (int j = 0; j < FINE_GRID_SIZE; ++j) {
				float y = startY + j * spacingY;

				if (y < minY || y > maxY)
					continue;

				float density = spawn->getDensityAt(zoneName, x, y);

				if (density > sample.density) {
					sample.density = density;
					sample.x = x;
					sample.y = y;
				}
			}
		}
	}

	void sendNoMatchReport(ChatManager* chat, const String& sender, const UnicodeString& subject, const String& displayPlanet) {
		StringBuffer body;
		body << "Incoming planetary survey report...\n\n";
		body << "\\#pcontrast3 Planet: \\#pcontrast1 " << displayPlanet << "\n\n";
		body << "No matching active resource concentrations were found on " << displayPlanet
			 << ". The requested resource may have despawned before the scan completed, or none of that type is currently spawning on this planet.\n";

		chat->sendMail(sender, subject, UnicodeString(body.toString()), surveyData->getRequestor());
	}

	void sendHotspotReport(ChatManager* chat, const String& sender, const UnicodeString& subject, const String& displayPlanet,
			ResourceSpawn* bestSpawn, const SurveyHotspotSample* hotspots, int hotspotCount) {

		StringBuffer body;
		body << "Incoming planetary survey report...\n\n";
		body << "\\#pcontrast3 Resource: \\#pcontrast1 " << bestSpawn->getName() << "\n";
		body << "\\#pcontrast3 Planet: \\#pcontrast1 " << displayPlanet << "\n\n";

		static const char* labels[MAX_HOTSPOTS] = { "Best", "Secondary", "Tertiary" };

		for (int i = 0; i < hotspotCount; ++i) {
			const SurveyHotspotSample& spot = hotspots[i];
			int percent = (int)(spot.density * 100.f + 0.5f);

			body << "\\#pcontrast3 " << labels[i] << " Hotspot: \\#pcontrast1 X: " << (int)spot.x
				 << " Y: " << (int)spot.y << " \\#pcontrast3 Concentration: \\#pcontrast1 " << percent << "%\n";
		}

		chat->sendMail(sender, subject, UnicodeString(body.toString()), surveyData->getRequestor());
	}

	// If the requesting player is currently online, drop a temporary waypoint on the best
	// hotspot so they don't have to copy the coordinates by hand.
	void createHotspotWaypoint(Zone* zone, const SurveyHotspotSample* hotspots, int hotspotCount) {
		if (hotspotCount == 0)
			return;

		ManagedReference<PlayerManager*> playerManager = ServerCore::getZoneServer()->getPlayerManager();
		ManagedReference<CreatureObject*> player = playerManager->getPlayer(surveyData->getRequestor());

		if (player == nullptr)
			return;

		ManagedReference<PlayerObject*> ghost = player->getPlayerObject();

		if (ghost == nullptr)
			return;

		const SurveyHotspotSample& best = hotspots[0];

		ManagedReference<WaypointObject*> waypoint = (ServerCore::getZoneServer()->createObject(0xc456e788, 1)).castTo<WaypointObject*>();

		if (waypoint == nullptr)
			return;

		Locker locker(waypoint);

		waypoint->setCustomObjectName(UnicodeString("Resource Hotspot"), false);
		waypoint->setPlanetCRC(zone->getZoneCRC());
		waypoint->setPosition(best.x, 0, best.y);
		waypoint->setColor(WaypointObject::COLOR_YELLOW);
		waypoint->setSpecialTypeID(WaypointObject::SPECIALTYPE_RESOURCE);
		waypoint->setActive(true);

		ghost->addWaypoint(waypoint, false, true);
	}

	void finish() {
		surveyData->setExecuted(true);

		if (surveyData->isPersistent())
			ObjectManager::instance()->destroyObjectFromDatabase(surveyData->_getObjectID());
	}

};

#endif /* INTERPLANETARYSURVERYTASK_H_ */
