/* Copyright <SWGEmu>. See file COPYING for copying conditions. */
#include "ResourceSnapshotExporter.h"
#include "ResourceSnapshotTask.h"
#include "server/zone/managers/resource/resourcespawner/ResourceSpawner.h"
#include "engine/core/TaskManager.h"
#include "engine/util/JSONSerializationType.h"
#include "system/thread/ReadLocker.h"

#include <algorithm>
#include <chrono>
#include <ctime>
#include <exception>
#include <stdexcept>
#include <utility>

namespace {

std::uint64_t snapshotTime() {
	const auto value = std::time(nullptr);
	if (value < 0)
		throw std::runtime_error("cannot read snapshot UTC time");
	return static_cast<std::uint64_t>(value);
}

std::string ownedString(const String& value) {
	return std::string(value.toCharArray(), value.length());
}

const char* statKey(const std::string& attribute) {
	static const std::pair<const char*, const char*> mapping[] = {
		{"res_cold_resist", "CR"},
		{"res_conductivity", "CD"},
		{"res_decay_resist", "DR"},
		{"res_flavor", "FL"},
		{"res_heat_resist", "HR"},
		{"res_malleability", "MA"},
		{"res_potential_energy", "PE"},
		{"res_quality", "OQ"},
		{"res_shock_resistance", "SR"},
		{"res_toughness", "UT"}
	};
	for (const auto& entry : mapping) {
		if (attribute == entry.first)
			return entry.second;
	}
	return nullptr; // Unverified attributes are omitted, never relabeled.
}

} // namespace

ResourceSnapshotExporter::ResourceSnapshotExporter(const ResourceSnapshotSettings& config, ResourceSpawner* source)
		: Logger("ResourceSnapshotExporter"), settings(config), spawner(source) {
	setGlobalLogging(true);
}

ResourceSnapshotExporter::~ResourceSnapshotExporter() = default;

void ResourceSnapshotExporter::scheduleNextLocked(std::uint64_t delay) {
	if (stopping)
		return;
	++timerGeneration;
	timerTask = new ResourceSnapshotTask(this, true, timerGeneration);
	timerTask->schedule(delay);
}

void ResourceSnapshotExporter::start() {
	std::lock_guard<std::mutex> lock(lifecycleMutex);
	if (stopping || started)
		return;
	auto manager = Core::getTaskManager();
	if (manager->getCustomTaskQueue("ResourceSnapshotExporter") == nullptr &&
			manager->initializeCustomQueue("ResourceSnapshotExporter", 1, true) == nullptr) {
		error("could not initialize snapshot worker queue");
		return;
	}
	queueInitialized = true;
	started = true;
	// First export is asynchronous, after ResourceSpawner::start() has completed.
	scheduleNextLocked(0);
	info(true) << "enabled: path=" << settings.outputPath.c_str()
			<< " source_instance=" << settings.sourceInstance.c_str()
			<< " interval_ms=" << settings.intervalMilliseconds;
}

ResourceSnapshotRequest ResourceSnapshotExporter::requestExportLocked() {
	if (stopping || !started)
		return ResourceSnapshotRequest::Stopped;
	const auto result = control.tryBegin();
	if (result != ResourceSnapshotRequest::Accepted)
		return result;

	// A manual request replaces the pending timer. Generation invalidation also
	// makes an already-dequeued old timer harmless after this export completes.
	++timerGeneration;
	if (timerTask != nullptr) {
		timerTask->cancel();
		timerTask = nullptr;
	}
	try {
		Reference<Task*> task = new ResourceSnapshotTask(this, false);
		task->execute();
	} catch (...) {
		control.finish();
		scheduleNextLocked(settings.intervalMilliseconds);
		throw;
	}
	return ResourceSnapshotRequest::Accepted;
}

ResourceSnapshotRequest ResourceSnapshotExporter::requestExport() {
	try {
		std::lock_guard<std::mutex> lock(lifecycleMutex);
		const auto result = requestExportLocked();
		return result;
	} catch (...) {
		// This entry point may run with a player's lock held. Return a diagnostic
		// to that caller; never log/write files or perform capture on this thread.
	}
	return ResourceSnapshotRequest::Failed;
}

void ResourceSnapshotExporter::onTimer(std::uint64_t generation) {
	std::lock_guard<std::mutex> lock(lifecycleMutex);
	if (stopping || generation != timerGeneration)
		return;
	requestExportLocked();
}

void ResourceSnapshotExporter::stopAndWait(const char* reason) {
	bool drain = false;
	{
		std::lock_guard<std::mutex> lock(lifecycleMutex);
		if (!stopping)
			info(true) << "cancelling snapshots: " << reason;
		stopping = true;
		++timerGeneration;
		control.cancel(); // Serializes against rename; no gameplay lock is held.
		if (timerTask != nullptr) {
			timerTask->cancel();
			timerTask = nullptr;
		}
		drain = queueInitialized;
	}
	// waitForQueueToFinish drains queued work and waits for the last worker.
	// Never call this while holding manager/player/zone/spawn locks.
	if (drain)
		Core::getTaskManager()->waitForQueueToFinish("ResourceSnapshotExporter");
	{
		std::lock_guard<std::mutex> lock(lifecycleMutex);
		spawner = nullptr;
		started = false;
		queueInitialized = false; // Later manager stop must not drain a stopped task manager.
	}
}

bool ResourceSnapshotExporter::copyRecord(const ManagedReference<ResourceSpawn*>& reference,
		std::uint64_t capturedAt, ResourceSnapshotRecord& record) {
	const ResourceSpawn* spawn = reference.get();
	if (spawn == nullptr)
		throw std::runtime_error("null resource reference in registry snapshot");
	ReadLocker lock(spawn);
	const auto expiration = spawn->getDespawned();
	if (!resourceSnapshotInShift(expiration, capturedAt))
		return false;

	ResourceSnapshotRecord copied;
	copied.expiresAt = expiration;
	copied.objectID = spawn->_getObjectID(); // Const identity read; TreeEntry's legacy getter is non-const.
	copied.name = ownedString(spawn->getName());
	copied.sourceTypeID = ownedString(spawn->getType());
	const int attributeCount = spawn->getSpawnAttributeCount();
	copied.attributes.reserve(attributeCount);
	for (int i = 0; i < attributeCount; ++i) {
		String attribute;
		const int value = spawn->getAttributeAndValue(attribute, i);
		copied.attributes.push_back({ownedString(attribute), value});
	}
	const int planetCount = spawn->getSpawnMapSize();
	copied.planets.reserve(planetCount);
	for (int i = 0; i < planetCount; ++i)
		copied.planets.push_back(ownedString(spawn->getSpawnMapZone(i)));
	record = std::move(copied);
	return true;
}

bool ResourceSnapshotExporter::capture(ResourceSnapshotData& snapshot, int& candidateCount) {
	snapshot.sourceInstance = settings.sourceInstance;
	snapshot.galaxyID = settings.galaxyID;
	snapshot.galaxyName = settings.galaxyName;
	snapshot.revision = settings.revision;
	{
		Reference<ResourceSpawner*> retained;
		{
			std::lock_guard<std::mutex> lock(lifecycleMutex);
			if (stopping)
				return false;
			retained = spawner;
		}
		if (retained == nullptr || retained->getResourceMap() == nullptr)
			throw std::runtime_error("initialized resource registry unavailable");
		snapshot.captureStartedAt = snapshotTime();
		snapshot.capturedAt = snapshot.captureStartedAt; // The sole selection cutoff.
		info(true) << "capture started: cutoff=" << snapshot.capturedAt;
		auto references = retained->getResourceMap()->copyAllReferences();
		retained = nullptr;
		candidateCount = references.size();
		info(true) << "registry candidates=" << candidateCount;
		for (const auto& reference : references) {
			if (control.isCancelled())
				return false;
			ResourceSnapshotRecord record;
			if (copyRecord(reference, snapshot.capturedAt, record))
				snapshot.resources.push_back(std::move(record));
		}
	} // All local spawner/resource references and resource read locks released.
	snapshot.captureCompletedAt = snapshotTime();
	return !control.isCancelled();
}

std::string ResourceSnapshotExporter::serialize(ResourceSnapshotData snapshot, std::uint64_t generatedAt) {
	using JSON = nlohmann::json;
	std::sort(snapshot.resources.begin(), snapshot.resources.end(), [](const auto& a, const auto& b) {
		return a.objectID < b.objectID; // Numeric full-width OIDs, never decimal text.
	});
	JSON resources = JSON::array();
	for (auto& record : snapshot.resources) {
		std::sort(record.planets.begin(), record.planets.end());
		JSON stats = JSON::object(); // nlohmann::json's map emits stable stat keys.
		for (const auto& attribute : record.attributes) {
			const char* key = statKey(attribute.name);
			if (key != nullptr)
				stats[key] = attribute.value;
		}
		resources.push_back({
			{"source_resource_id", std::to_string(record.objectID)},
			{"name", record.name},
			{"source_type_id", record.sourceTypeID},
			{"stats", std::move(stats)},
			{"planets", record.planets},
			{"spawn_map_state", record.planets.empty() ? "empty" : "present"},
			{"lifecycle", {{"spawned_at", nullptr}, {"expires_at", record.expiresAt}, {"despawned_at", nullptr}}},
			{"active", resourceSnapshotInShift(record.expiresAt, snapshot.capturedAt)}
		});
	}
	JSON revision = snapshot.revision.empty() ? JSON(nullptr) : JSON(snapshot.revision);
	JSON document = {
		{"schema_version", 1},
		{"source_system", "core3"},
		{"source_instance", snapshot.sourceInstance},
		{"generated_at", generatedAt},
		{"captured_at", snapshot.capturedAt},
		{"capture_started_at", snapshot.captureStartedAt},
		{"capture_completed_at", snapshot.captureCompletedAt},
		{"consistency", "interval"},
		{"complete", true},
		{"selection", "core3_in_shift"},
		{"resource_count", resources.size()},
		{"resources", std::move(resources)},
		{"galaxy", {{"id", snapshot.galaxyID}, {"name", snapshot.galaxyName}}},
		{"build", {{"revision", std::move(revision)}, {"commit", nullptr}}}
	};
	return document.dump(2) + "\n";
}

void ResourceSnapshotExporter::runExport() {
	const auto startedAt = std::chrono::steady_clock::now();
	try {
		ResourceSnapshotData snapshot;
		int candidateCount = 0;
		if (capture(snapshot, candidateCount)) {
			const auto count = snapshot.resources.size();
			const auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
					std::chrono::steady_clock::now() - startedAt).count();
			info(true) << "capture completed: candidates=" << candidateCount
					<< " active=" << count << " capture_ms=" << elapsed;
			// Only owned plain data remains on the capture stack at this point.
			const std::string payload = serialize(std::move(snapshot), snapshotTime());
			ResourceSnapshotPublication publication(settings.outputPath);
			std::string failure;
			if (control.isCancelled()) {
				info("export cancelled before temporary write", true);
			} else if (!publication.prepare(payload, failure) || !publication.promote(control, failure)) {
				if (control.isCancelled())
					info(String("export cancelled: ") + failure.c_str(), true);
				else
					error(String("publication failed: ") + failure.c_str());
			} else {
				info(true) << "published " << count << " active resources to " << settings.outputPath.c_str();
			}
		} else {
			info("capture cancelled", true);
		}
	} catch (const Exception& e) {
		error("capture/publication failed: " + e.getMessage());
	} catch (const std::exception& e) {
		error(String("capture/publication failed: ") + e.what());
	} catch (...) {
		error("capture/publication failed: unknown exception");
	}

	std::lock_guard<std::mutex> lock(lifecycleMutex);
	control.finish();
	// Fixed delay after completion prevents periodic overlap and retry storms.
	if (!stopping)
		scheduleNextLocked(settings.intervalMilliseconds);
}
