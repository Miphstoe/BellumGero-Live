/* Copyright <SWGEmu>. See file COPYING for copying conditions. */
#pragma once

#include "ResourceSnapshotRecord.h"
#include "ResourceSnapshotPublication.h"
#include "engine/core/Task.h"
#include "engine/log/Logger.h"
#include "server/zone/objects/resource/ResourceSpawn.h"

class ResourceSpawner;

struct ResourceSnapshotSettings {
	std::string outputPath;
	std::string sourceInstance;
	std::uint64_t intervalMilliseconds = 300000;
	int galaxyID = 0;
	std::string galaxyName;
	std::string revision;
};

class ResourceSnapshotExporter : public Object, public Logger {
	const ResourceSnapshotSettings settings;
	// Pinned during initialized manager handoff under the manager lock. Released
	// after cancellation/drain, before manager detachment and zone teardown.
	Reference<ResourceSpawner*> spawner;
	std::mutex lifecycleMutex;
	ResourceSnapshotControl control;
	Reference<Task*> timerTask;
	std::uint64_t timerGeneration = 0;
	bool started = false;
	bool queueInitialized = false;
	bool stopping = false;

public:
	ResourceSnapshotExporter(const ResourceSnapshotSettings& config, ResourceSpawner* source);
	~ResourceSnapshotExporter() override;
	void start();
	ResourceSnapshotRequest requestExport();
	// Called without gameplay locks, before task-manager shutdown.
	void stopAndWait(const char* reason);

	// Shared by production capture and focused source-field tests. This acquires
	// exactly one read lock and invokes only read accessors, never writeJSON().
	static bool copyRecord(const ManagedReference<ResourceSpawn*>& reference,
			std::uint64_t capturedAt, ResourceSnapshotRecord& record);
	static std::string serialize(ResourceSnapshotData snapshot, std::uint64_t generatedAt);

private:
	ResourceSnapshotRequest requestExportLocked();
	void scheduleNextLocked(std::uint64_t delay);
	void onTimer(std::uint64_t generation);
	void runExport();
	bool capture(ResourceSnapshotData& snapshot, int& candidateCount);

	friend class ResourceSnapshotTask;
};
