/* Copyright <SWGEmu>. See file COPYING for copying conditions. */
#pragma once

#include "ResourceSnapshotExporter.h"

// Weak ownership avoids a timer/exporter cycle. A running task promotes the
// weak reference to an owning reference for its entire invocation.
class ResourceSnapshotTask : public Task {
	WeakReference<ResourceSnapshotExporter*> exporter;
	bool timer;
	std::uint64_t generation;

public:
	ResourceSnapshotTask(ResourceSnapshotExporter* source, bool isTimer, std::uint64_t token = 0)
			: exporter(source), timer(isTimer), generation(token) {
		setCustomTaskQueue("ResourceSnapshotExporter");
		setTaskName(isTimer ? "ResourceSnapshotTimer" : "ResourceSnapshotExport");
	}

	void run() override {
		auto retained = exporter.get();
		if (retained == nullptr)
			return;
		if (timer)
			retained->onTimer(generation);
		else
			retained->runExport();
	}
};
