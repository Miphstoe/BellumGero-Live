/* Copyright <SWGEmu>. See file COPYING for copying conditions. */
#include "gtest/gtest.h"
#include "server/zone/managers/resource/resourcesnapshot/ResourceSnapshotExporter.h"
#include "engine/util/JSONSerializationType.h"
#include "system/thread/Locker.h"

#include <algorithm>
#include <atomic>
#include <cstdio>
#include <cstdlib>
#include <dirent.h>
#include <fstream>
#include <iterator>
#include <limits>
#include <stdexcept>
#include <string>
#include <sys/stat.h>
#include <thread>
#include <unistd.h>
#include <utility>
#include <vector>

namespace {

using JSON = nlohmann::json;

ResourceSnapshotData sampleSnapshot() {
	ResourceSnapshotData snapshot;
	snapshot.sourceInstance = "bellum-gero-development:test-lineage";
	snapshot.capturedAt = 100;
	snapshot.captureStartedAt = 100;
	snapshot.captureCompletedAt = 102;
	snapshot.galaxyID = 2;
	snapshot.galaxyName = "Bellum Gero";
	return snapshot;
}

ResourceSnapshotRecord sampleRecord(std::uint64_t oid = 1) {
	ResourceSnapshotRecord record;
	record.objectID = oid;
	record.expiresAt = 200;
	record.name = "ActualGeneratedName";
	record.sourceTypeID = "copper_borocarbitic";
	return record;
}

JSON documentFor(ResourceSnapshotRecord record) {
	auto snapshot = sampleSnapshot();
	snapshot.resources.push_back(std::move(record));
	return JSON::parse(ResourceSnapshotExporter::serialize(snapshot, 103));
}

TEST(ResourceSnapshotTest, SelectionUsesStrictSingleExpirationCutoff) {
	ManagedReference<ResourceSpawn*> spawn = new ResourceSpawn();
	ResourceSnapshotRecord record;
	for (const std::uint64_t expiration : {99, 100, 101}) {
		{
			Locker lock(spawn.get());
			spawn->setDespawned(expiration);
		}
		EXPECT_EQ(expiration > 100, ResourceSnapshotExporter::copyRecord(spawn, 100, record));
	}
}

TEST(ResourceSnapshotTest, RecycledExpirationZeroIsExcluded) {
	ManagedReference<ResourceSpawn*> spawn = new ResourceSpawn();
	ResourceSnapshotRecord record;
	EXPECT_FALSE(ResourceSnapshotExporter::copyRecord(spawn, 100, record));
}

TEST(ResourceSnapshotTest, ActiveResourceWithEmptySpawnMapsRemainsIncluded) {
	ManagedReference<ResourceSpawn*> spawn = new ResourceSpawn();
	{
		Locker lock(spawn.get());
		spawn->setDespawned(200);
		spawn->setName("GeneratedName");
		spawn->setType("copper_borocarbitic");
	}
	ResourceSnapshotRecord record;
	ASSERT_TRUE(ResourceSnapshotExporter::copyRecord(spawn, 100, record));
	EXPECT_EQ("GeneratedName", record.name);
	EXPECT_EQ("copper_borocarbitic", record.sourceTypeID);
	const auto document = documentFor(record);
	EXPECT_EQ(1, document.at("resource_count").get<int>());
	const auto& resource = document.at("resources").at(0);
	EXPECT_TRUE(resource.at("active").get<bool>());
	EXPECT_EQ(JSON::array(), resource.at("planets"));
	EXPECT_EQ("empty", resource.at("spawn_map_state").get<std::string>());
}

TEST(ResourceSnapshotTest, FullWidthOIDIsAnExactDecimalString) {
	ManagedReference<ResourceSpawn*> spawn = new ResourceSpawn();
	{
		Locker lock(spawn.get());
		spawn->_setObjectID(std::numeric_limits<std::uint64_t>::max());
		spawn->setDespawned(200);
	}
	ResourceSnapshotRecord record;
	ASSERT_TRUE(ResourceSnapshotExporter::copyRecord(spawn, 100, record));
	const auto document = documentFor(record);
	const auto& oid = document.at("resources").at(0).at("source_resource_id");
	ASSERT_TRUE(oid.is_string());
	EXPECT_EQ("18446744073709551615", oid.get<std::string>());
}

TEST(ResourceSnapshotTest, StoredAttributesBeyondTwelveAreInspectedAndMissingZeroRemainDistinct) {
	ManagedReference<ResourceSpawn*> spawn = new ResourceSpawn();
	{
		Locker lock(spawn.get());
		spawn->setDespawned(200);
		// These unknown keys sort before the verified keys in spawnAttributes.
		for (int i = 0; i < 16; ++i)
			spawn->addAttribute("a_unknown_" + String::valueOf(i), i);
		spawn->addAttribute("res_quality", 0);
		spawn->addAttribute("res_conductivity", 800);
		spawn->addAttribute("res_entangle_resist", 900); // Unverified, must be omitted.
	}
	ResourceSnapshotRecord record;
	ASSERT_TRUE(ResourceSnapshotExporter::copyRecord(spawn, 100, record));
	ASSERT_EQ(19u, record.attributes.size());
	const auto document = documentFor(record);
	const auto& stats = document.at("resources").at(0).at("stats");
	EXPECT_EQ(0, stats.at("OQ").get<int>());
	EXPECT_EQ(800, stats.at("CD").get<int>());
	EXPECT_EQ(0u, stats.count("CR"));
	EXPECT_EQ(0u, stats.count("ER"));
	EXPECT_EQ(2u, stats.size());
}

TEST(ResourceSnapshotTest, OnlyTheTenVerifiedMappingsAreEmitted) {
	auto record = sampleRecord();
	record.attributes = {
		{"res_cold_resist", 1}, {"res_conductivity", 2}, {"res_decay_resist", 3},
		{"res_flavor", 4}, {"res_heat_resist", 5}, {"res_malleability", 6},
		{"res_potential_energy", 7}, {"res_quality", 8}, {"res_shock_resistance", 9},
		{"res_toughness", 10}, {"ER", 999}, {"unknown", 123}
	};
	const auto document = documentFor(record);
	const JSON expected = {{"CR", 1}, {"CD", 2}, {"DR", 3}, {"FL", 4}, {"HR", 5},
			{"MA", 6}, {"PE", 7}, {"OQ", 8}, {"SR", 9}, {"UT", 10}};
	EXPECT_EQ(expected, document.at("resources").at(0).at("stats"));
}

TEST(ResourceSnapshotTest, NumericResourceAndPlanetOrderingAreDeterministic) {
	auto snapshot = sampleSnapshot();
	for (const std::uint64_t oid : {10, 2, 9}) {
		auto record = sampleRecord(oid);
		record.planets = {"tatooine", "corellia", "naboo"};
		snapshot.resources.push_back(std::move(record));
	}
	const auto first = ResourceSnapshotExporter::serialize(snapshot, 103);
	EXPECT_EQ(first, ResourceSnapshotExporter::serialize(snapshot, 103));
	std::reverse(snapshot.resources.begin(), snapshot.resources.end());
	for (auto& record : snapshot.resources)
		std::reverse(record.planets.begin(), record.planets.end());
	EXPECT_EQ(first, ResourceSnapshotExporter::serialize(snapshot, 103));
	const auto document = JSON::parse(first);
	const auto& resources = document.at("resources");
	EXPECT_EQ("2", resources.at(0).at("source_resource_id").get<std::string>());
	EXPECT_EQ("9", resources.at(1).at("source_resource_id").get<std::string>());
	EXPECT_EQ("10", resources.at(2).at("source_resource_id").get<std::string>());
	EXPECT_EQ(JSON({"corellia", "naboo", "tatooine"}), resources.at(0).at("planets"));
	EXPECT_EQ("present", resources.at(0).at("spawn_map_state").get<std::string>());
}

TEST(ResourceSnapshotTest, SchemaUsesIntervalMetadataUnixSecondsAndNullUnknownLifecycle) {
	const auto document = documentFor(sampleRecord());
	EXPECT_EQ(1, document.at("schema_version").get<int>());
	EXPECT_EQ("core3", document.at("source_system").get<std::string>());
	EXPECT_EQ("bellum-gero-development:test-lineage", document.at("source_instance").get<std::string>());
	EXPECT_EQ("interval", document.at("consistency").get<std::string>());
	EXPECT_EQ("core3_in_shift", document.at("selection").get<std::string>());
	EXPECT_TRUE(document.at("complete").get<bool>());
	EXPECT_EQ(100, document.at("captured_at").get<int>());
	EXPECT_EQ(100, document.at("capture_started_at").get<int>());
	EXPECT_EQ(102, document.at("capture_completed_at").get<int>());
	EXPECT_EQ(103, document.at("generated_at").get<int>());
	const auto& lifecycle = document.at("resources").at(0).at("lifecycle");
	EXPECT_TRUE(lifecycle.at("spawned_at").is_null());
	EXPECT_TRUE(lifecycle.at("despawned_at").is_null());
	EXPECT_EQ(200, lifecycle.at("expires_at").get<int>());
	EXPECT_TRUE(document.at("build").at("commit").is_null());
	EXPECT_TRUE(document.at("build").at("revision").is_null());
}

TEST(ResourceSnapshotTest, JSONEscapingPreservesActualNamesAndTypeSlugs) {
	auto record = sampleRecord();
	record.name = "Generated \"name\"\\\n\t";
	record.sourceTypeID = "raw_slug\\\"";
	const auto document = documentFor(record);
	EXPECT_EQ(record.name, document.at("resources").at(0).at("name").get<std::string>());
	EXPECT_EQ(record.sourceTypeID, document.at("resources").at(0).at("source_type_id").get<std::string>());
}

TEST(ResourceSnapshotTest, ConcurrentRequestsAdmitOnlyOneOperationUntilItFinishes) {
	ResourceSnapshotControl control;
	std::atomic<int> accepted(0);
	std::vector<std::thread> callers;
	for (int i = 0; i < 16; ++i) {
		callers.emplace_back([&]() {
			if (control.tryBegin() == ResourceSnapshotRequest::Accepted)
				++accepted;
		});
	}
	for (auto& caller : callers)
		caller.join();
	EXPECT_EQ(1, accepted.load());
	EXPECT_EQ(ResourceSnapshotRequest::AlreadyRunning, control.tryBegin());
	control.finish();
	EXPECT_EQ(ResourceSnapshotRequest::Accepted, control.tryBegin());
	control.cancel();
	control.finish();
	EXPECT_EQ(ResourceSnapshotRequest::Stopped, control.tryBegin());
}

class ResourceSnapshotPublicationTest : public ::testing::Test {
protected:
	std::string directory;
	std::string path;

	void SetUp() override {
		char name[] = "/tmp/core3-resource-snapshot-XXXXXX";
		const char* created = ::mkdtemp(name);
		ASSERT_NE(nullptr, created);
		directory = created;
		path = directory + "/snapshot.json";
	}

	void TearDown() override {
		if (directory.empty())
			return;
		DIR* contents = ::opendir(directory.c_str());
		if (contents != nullptr) {
			while (auto entry = ::readdir(contents)) {
				const std::string name = entry->d_name;
				if (name != "." && name != "..")
					::unlink((directory + "/" + name).c_str());
			}
			::closedir(contents);
		}
		::rmdir(directory.c_str());
	}

	void writePrevious() {
		std::ofstream file(path);
		file << "{\"previous\":true}\n";
		file.close();
		ASSERT_FALSE(file.fail());
	}

	std::string readPublished() {
		std::ifstream file(path);
		return std::string(std::istreambuf_iterator<char>(file), std::istreambuf_iterator<char>());
	}
};

TEST_F(ResourceSnapshotPublicationTest, CompleteWriteAtomicallyReplacesPreviousFile) {
	writePrevious();
	ResourceSnapshotControl control;
	ASSERT_EQ(ResourceSnapshotRequest::Accepted, control.tryBegin());
	ResourceSnapshotPublication publication(path);
	std::string error;
	ASSERT_TRUE(publication.prepare("{\"new\":true}\n", error)) << error;
	EXPECT_EQ("{\"previous\":true}\n", readPublished());
	ASSERT_TRUE(publication.promote(control, error)) << error;
	EXPECT_EQ("{\"new\":true}\n", readPublished());
}

TEST_F(ResourceSnapshotPublicationTest, FailedTemporaryCreationPreservesPreviousSnapshot) {
	// A valid maximum-length destination filename exists, but its appended
	// unique temporary suffix cannot be created. No permissions/timing tricks.
	const long limit = ::pathconf(directory.c_str(), _PC_NAME_MAX);
	if (limit <= 0 || limit > 4096)
		GTEST_SKIP() << "filesystem has no practical finite filename limit";
	path = directory + "/" + std::string(static_cast<std::size_t>(limit), 's');
	writePrevious();
	ResourceSnapshotControl control;
	ASSERT_EQ(ResourceSnapshotRequest::Accepted, control.tryBegin());
	ResourceSnapshotPublication publication(path);
	std::string error;
	EXPECT_FALSE(publication.prepare("{\"new\":true}\n", error));
	EXPECT_FALSE(publication.promote(control, error));
	EXPECT_EQ("{\"previous\":true}\n", readPublished());
}

TEST_F(ResourceSnapshotPublicationTest, CancellationAfterWriteBeforePromotionPreservesPreviousSnapshot) {
	writePrevious();
	ResourceSnapshotControl control;
	ASSERT_EQ(ResourceSnapshotRequest::Accepted, control.tryBegin());
	ResourceSnapshotPublication publication(path);
	std::string error;
	ASSERT_TRUE(publication.prepare("{\"new\":true}\n", error)) << error;
	control.cancel();
	EXPECT_FALSE(publication.promote(control, error));
	EXPECT_EQ("{\"previous\":true}\n", readPublished());
}

TEST_F(ResourceSnapshotPublicationTest, CancelledPublicationRemovesItsOwnedTemporaryFile) {
	writePrevious();
	ResourceSnapshotControl control;
	ASSERT_EQ(ResourceSnapshotRequest::Accepted, control.tryBegin());
	{
		ResourceSnapshotPublication publication(path);
		std::string error;
		ASSERT_TRUE(publication.prepare("{\"new\":true}\n", error)) << error;
		control.cancel();
		EXPECT_FALSE(publication.promote(control, error));
	}
	DIR* contents = ::opendir(directory.c_str());
	ASSERT_NE(nullptr, contents);
	int temporaryCount = 0;
	while (auto entry = ::readdir(contents)) {
		if (std::string(entry->d_name).find(".tmp.") != std::string::npos)
			++temporaryCount;
	}
	::closedir(contents);
	EXPECT_EQ(0, temporaryCount);
	EXPECT_EQ("{\"previous\":true}\n", readPublished());
}

} // namespace
