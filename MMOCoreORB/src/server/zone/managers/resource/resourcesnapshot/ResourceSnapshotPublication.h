/* Copyright <SWGEmu>. See file COPYING for copying conditions. */
#pragma once

#include <mutex>
#include <string>

enum class ResourceSnapshotRequest {
	Accepted,
	AlreadyRunning,
	Stopped,
	Failed
};

// Admission covers queued work, capture, serialization and publication. The
// same gate linearizes cancellation against the final rename, not disk writes.
class ResourceSnapshotControl {
	mutable std::mutex mutex;
	bool stopping = false;
	bool inFlight = false;

public:
	ResourceSnapshotRequest tryBegin();
	void finish();
	void cancel();
	bool isCancelled() const;

private:
	friend class ResourceSnapshotPublication;
};

// Linux same-filesystem replacement. This guarantees atomic visibility, not
// fsync-level crash durability. Only this class promotes the published file.
class ResourceSnapshotPublication {
	std::string destination;
	std::string temporaryPath;
	bool prepared = false;

public:
	explicit ResourceSnapshotPublication(const std::string& path) : destination(path) {}
	~ResourceSnapshotPublication();
	ResourceSnapshotPublication(const ResourceSnapshotPublication&) = delete;
	ResourceSnapshotPublication& operator=(const ResourceSnapshotPublication&) = delete;

	bool prepare(const std::string& payload, std::string& error);
	bool promote(ResourceSnapshotControl& control, std::string& error);
};
