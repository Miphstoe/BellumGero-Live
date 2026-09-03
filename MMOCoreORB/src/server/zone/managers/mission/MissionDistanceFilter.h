/*
 * MissionDistanceFilter.h
 *
 * Per-player "Filter Missions by Distance" state for mission terminal generation
 * (see MissionTerminalImplementation.cpp, radial ID 117, and
 * MissionManagerImplementation::randomizeGeneralTerminalMissions /
 * randomizeFactionTerminalMissions, the only two dispatchers reachable from a
 * terminal that exposes the radial).
 *
 * The filter is a display filter, not an accept action: when active, mission
 * generation only leaves matching missions populated in the player's mission_bag,
 * so everything downstream (the client's terminal list, manual acceptance, and the
 * separate "Accept Top 6 Missions" feature) sees only the filtered pool for free.
 */

#ifndef MISSIONDISTANCEFILTER_H_
#define MISSIONDISTANCEFILTER_H_

#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/mission/MissionObject.h"
#include "server/zone/objects/tangible/terminal/mission/MissionTerminal.h"
#include "server/zone/objects/tangible/terminal/mission/MissionDistanceRange.h"
#include "server/zone/Zone.h"
#include "engine/util/u3d/Coordinate.h"
#include "system/lang/Float.h"

static const String MISSION_DISTANCE_FILTER_SCREENPLAY = "mission_distance_filter";
static const int MAX_DISTANCE_FILTER_ATTEMPTS = 5;

struct MissionDistanceFilterState {
	bool enabled = false;
	float minDistance = -1.0f;
	float maxDistance = -1.0f;
};

inline MissionDistanceFilterState readMissionDistanceFilter(CreatureObject* player) {
	MissionDistanceFilterState state;

	PlayerObject* ghost = player->getPlayerObject();
	if (ghost == nullptr)
		return state;

	if (ghost->getScreenPlayData(MISSION_DISTANCE_FILTER_SCREENPLAY, "enabled") != "1")
		return state;

	state.enabled = true;
	state.minDistance = Float::valueOf(ghost->getScreenPlayData(MISSION_DISTANCE_FILTER_SCREENPLAY, "minDistance"));
	state.maxDistance = Float::valueOf(ghost->getScreenPlayData(MISSION_DISTANCE_FILTER_SCREENPLAY, "maxDistance"));

	return state;
}

inline void writeMissionDistanceFilter(CreatureObject* player, const MissionDistanceFilterState& state) {
	PlayerObject* ghost = player->getPlayerObject();
	if (ghost == nullptr)
		return;

	ghost->setScreenPlayData(MISSION_DISTANCE_FILTER_SCREENPLAY, "enabled", state.enabled ? "1" : "0");
	ghost->setScreenPlayData(MISSION_DISTANCE_FILTER_SCREENPLAY, "minDistance", String::valueOf(state.minDistance));
	ghost->setScreenPlayData(MISSION_DISTANCE_FILTER_SCREENPLAY, "maxDistance", String::valueOf(state.maxDistance));
}

/**
 * Origin = the mission terminal itself; destination = the mission's own
 * startPosition/startPlanet (already populated by every generator reachable from
 * the two filtered dispatchers). Off-planet or otherwise unresolvable destinations
 * never count as a match - they're excluded, not treated as 0m.
 */
inline bool missionMatchesDistanceFilter(MissionTerminal* missionTerminal, MissionObject* mission, const MissionDistanceFilterState& filter) {
	if (!filter.enabled)
		return true;

	Zone* zone = missionTerminal->getZone();
	if (zone == nullptr || mission->getStartPlanet() != zone->getZoneName())
		return false;

	Coordinate missionPosition;
	missionPosition.setPosition(mission->getStartPositionX(), 0.0f, mission->getStartPositionY());

	float distance = missionTerminal->getDistanceTo(&missionPosition);

	return isInMissionDistanceRange(distance, filter.minDistance, filter.maxDistance);
}

/**
 * Runs generator() once when no filter is active (zero behavior change, zero
 * overhead). When a filter is active, retries up to MAX_DISTANCE_FILTER_ATTEMPTS
 * times, clearing typeCRC before each retry so a partially-failed attempt can't be
 * mistaken for a kept mission (see MissionManagerImplementation.cpp - every generic
 * generator only sets typeCRC as its final statement on success). If no attempt
 * matches within the budget, the slot is explicitly hidden (typeCRC 0) rather than
 * showing an out-of-range mission - the same "empty slot" state already used today
 * whenever a bag has more capacity than active mission types (e.g. bounty terminals).
 */
template<typename GeneratorFunc>
inline void generateMissionRespectingDistanceFilter(MissionTerminal* missionTerminal, MissionObject* mission, const MissionDistanceFilterState& filter, GeneratorFunc&& generator) {
	int attempts = filter.enabled ? MAX_DISTANCE_FILTER_ATTEMPTS : 1;

	for (int attempt = 0; attempt < attempts; ++attempt) {
		if (attempt > 0)
			mission->setTypeCRC(0);

		generator();

		if (mission->getTypeCRC() == 0)
			continue;

		if (missionMatchesDistanceFilter(missionTerminal, mission, filter))
			return;
	}

	// Only the "generated something, but it didn't match" case needs an explicit hide -
	// if the final attempt produced nothing at all (typeCRC still 0), the slot is
	// already empty and its stale position data shouldn't be evaluated.
	if (filter.enabled && mission->getTypeCRC() != 0 && !missionMatchesDistanceFilter(missionTerminal, mission, filter))
		mission->setTypeCRC(0, true);
}

#endif /* MISSIONDISTANCEFILTER_H_ */
