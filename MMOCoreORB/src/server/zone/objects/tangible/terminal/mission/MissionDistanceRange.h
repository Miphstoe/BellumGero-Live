/*
 * MissionDistanceRange.h
 *
 * Shared distance-bracket table for the "Select Missions by Distance" mission
 * terminal radial. Single source of truth for both the SUI row labels
 * (MissionTerminalImplementation) and the filter bounds used when accepting
 * missions (MissionDistanceSuiCallback).
 */

#ifndef MISSIONDISTANCERANGE_H_
#define MISSIONDISTANCERANGE_H_

struct MissionDistanceRangeEntry {
	float minDistance;
	float maxDistance;
	const char* label;
};

static const MissionDistanceRangeEntry MISSION_DISTANCE_RANGES[] = {
	{ 500.0f, 600.0f, "500 - 600 meters" },
	{ 600.0f, 700.0f, "600 - 700 meters" },
	{ 700.0f, 800.0f, "700 - 800 meters" },
	{ 800.0f, 900.0f, "800 - 900 meters" },
	{ 900.0f, 1000.0f, "900 - 1000 meters" },
};

static const int MISSION_DISTANCE_RANGE_COUNT = sizeof(MISSION_DISTANCE_RANGES) / sizeof(MISSION_DISTANCE_RANGES[0]);

/**
 * Boundary rule: the first bracket (minDistance == the lowest configured
 * bracket's minDistance, i.e. 500m) is inclusive on both ends ([500, 600]);
 * every subsequent bracket is (min, max] so a mission belongs to exactly one
 * bracket (e.g. exactly 600m falls in the 500-600 bracket, not 600-700).
 * minDistance < 0 is the sentinel for "no distance filter" (everything matches) —
 * used by the unfiltered "Accept Top 6 Missions" path.
 */
inline bool isInMissionDistanceRange(float distance, float minDistance, float maxDistance) {
	if (minDistance < 0)
		return true;

	bool inclusiveMin = (minDistance <= MISSION_DISTANCE_RANGES[0].minDistance);

	if (inclusiveMin)
		return distance >= minDistance && distance <= maxDistance;

	return distance > minDistance && distance <= maxDistance;
}

#endif /* MISSIONDISTANCERANGE_H_ */
