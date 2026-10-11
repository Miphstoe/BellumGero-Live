/* Copyright <SWGEmu>. See file COPYING for copying conditions. */
#include "ResourceSnapshotPublication.h"

#include <cerrno>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <unistd.h>

ResourceSnapshotRequest ResourceSnapshotControl::tryBegin() {
	std::lock_guard<std::mutex> lock(mutex);
	if (stopping)
		return ResourceSnapshotRequest::Stopped;
	if (inFlight)
		return ResourceSnapshotRequest::AlreadyRunning;
	inFlight = true;
	return ResourceSnapshotRequest::Accepted;
}

void ResourceSnapshotControl::finish() {
	std::lock_guard<std::mutex> lock(mutex);
	inFlight = false;
}

void ResourceSnapshotControl::cancel() {
	std::lock_guard<std::mutex> lock(mutex);
	stopping = true;
}

bool ResourceSnapshotControl::isCancelled() const {
	std::lock_guard<std::mutex> lock(mutex);
	return stopping;
}

ResourceSnapshotPublication::~ResourceSnapshotPublication() {
	if (!temporaryPath.empty())
		::unlink(temporaryPath.c_str()); // Only the unique file created by this object.
}

bool ResourceSnapshotPublication::prepare(const std::string& payload, std::string& error) {
	if (!temporaryPath.empty() || prepared) {
		error = "temporary snapshot already prepared";
		return false;
	}

	// Allocate the name before acquiring the descriptor. C++17 supplies mutable
	// string storage, so mkstemp can fill the suffix without a later allocation.
	temporaryPath = destination + ".tmp.XXXXXX";
	const int fd = ::mkstemp(temporaryPath.data());
	if (fd == -1) {
		const int savedError = errno;
		temporaryPath.clear(); // No owned file exists; never unlink a failed pattern.
		error = "open temporary snapshot: " + std::string(std::strerror(savedError));
		return false;
	}

	FILE* file = ::fdopen(fd, "wb");
	if (file == nullptr) {
		const int savedError = errno;
		::close(fd);
		error = "open temporary stream: " + std::string(std::strerror(savedError));
		return false;
	}

	const bool written = std::fwrite(payload.data(), 1, payload.size(), file) == payload.size();
	const bool streamOK = std::ferror(file) == 0;
	const bool flushed = std::fflush(file) == 0;
	// Always close, even on write/flush failure. Never promote an uncertain write.
	const bool closed = std::fclose(file) == 0;
	if (!written || !streamOK || !flushed || !closed) {
		error = "temporary snapshot write/flush/close failed";
		return false;
	}
	prepared = true;
	return true;
}

bool ResourceSnapshotPublication::promote(ResourceSnapshotControl& control, std::string& error) {
	std::lock_guard<std::mutex> lock(control.mutex);
	if (control.stopping) {
		error = "cancelled before snapshot promotion";
		return false;
	}
	if (!prepared) {
		error = "temporary snapshot was not completely written";
		return false;
	}
	if (std::rename(temporaryPath.c_str(), destination.c_str()) != 0) {
		error = "atomic snapshot replacement: " + std::string(std::strerror(errno));
		return false;
	}
	temporaryPath.clear();
	prepared = false;
	return true;
}
