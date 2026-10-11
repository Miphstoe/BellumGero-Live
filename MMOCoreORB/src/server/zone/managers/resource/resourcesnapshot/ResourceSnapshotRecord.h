/* Copyright <SWGEmu>. See file COPYING for copying conditions. */
#pragma once

#include <cstdint>
#include <string>
#include <vector>

// Owned observation data only. Ordinary containers impose no Engine3 persistence
// requirements on these transient structs. All timestamps are Unix UTC seconds.
struct ResourceSnapshotAttribute {
	std::string name;
	int value = 0;
};

struct ResourceSnapshotRecord {
	std::uint64_t objectID = 0;
	std::uint64_t expiresAt = 0;
	std::string name;
	std::string sourceTypeID;
	std::vector<ResourceSnapshotAttribute> attributes;
	std::vector<std::string> planets;
};

struct ResourceSnapshotData {
	std::string sourceInstance;
	std::uint64_t capturedAt = 0;
	std::uint64_t captureStartedAt = 0;
	std::uint64_t captureCompletedAt = 0;
	int galaxyID = 0;
	std::string galaxyName;
	std::string revision;
	std::vector<ResourceSnapshotRecord> resources;
};

inline bool resourceSnapshotInShift(std::uint64_t expiresAt, std::uint64_t capturedAt) {
	return expiresAt > capturedAt;
}
