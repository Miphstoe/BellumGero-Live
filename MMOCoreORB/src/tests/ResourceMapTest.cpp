/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#include "gtest/gtest.h"
#include "server/zone/managers/resource/resourcespawner/resourcemap/ResourceMap.h"
#include "system/thread/Locker.h"
#include "system/thread/Thread.h"

#include <atomic>
#include <exception>
#include <type_traits>
#include <utility>
#include <vector>

namespace {

using References = ResourceMap::ResourceReferences;
using LegacyNameMap = VectorMap<String, ManagedReference<ResourceSpawn*>>;

static_assert(!std::is_base_of<LegacyNameMap, ResourceMap>::value,
		"ResourceMap must not expose inherited container access");
static_assert(std::is_same<decltype(std::declval<const ResourceMap&>().findByName(
		std::declval<const String&>())), ManagedReference<ResourceSpawn*>>::value,
		"Name lookup must return an owning value");
static_assert(std::is_same<decltype(std::declval<const ResourceMap&>().copyAllReferences()), References>::value,
		"Global copies must own their entries");
static_assert(std::is_same<decltype(std::declval<const ResourceMap&>().copyZoneReferences(
		std::declval<const String&>())), References>::value,
		"Zone copies must not return child containers");
static_assert(std::is_same<decltype(std::declval<const ResourceMap&>().copyTypeReferences(
		std::declval<const String&>())), References>::value,
		"Type copies must not return child containers");

ResourceMap::Registration registration(const String& name, const String& type = "metal") {
	ResourceMap::Registration result;
	result.spawn = new ResourceSpawn();
	Locker locker(result.spawn);
	result.spawn->setName(name);
	result.registryName = name;
	result.spawnName = result.spawn->getName();
	result.finalClass = type;
	result.zones.add("tatooine");
	result.zones.add("naboo");
	return result;
}

TEST(ResourceMapTest, InsertionUpdatesIndexesAndPreservesLegacyOrders) {
	ResourceMap registry;
	LegacyNameMap expectedNames;
	expectedNames.setNoDuplicateInsertPlan();
	expectedNames.setNullValue(nullptr);
	References expectedTypes;

	// Deliberately not in name order. The old global/zone maps sorted by key;
	// the old type vector simply appended.
	for (const auto& name : Vector<String>{"Zulu", "Alpha", "Mike"}) {
		auto entry = registration(name);
		registry.add(entry);
		expectedNames.put(name.toLowerCase(), entry.spawn);
		expectedTypes.add(entry.spawn);
	}

	EXPECT_EQ(3, registry.resourceCount());
	EXPECT_TRUE(registry.containsType("metal"));
	EXPECT_FALSE(registry.containsType("METAL"));
	bool found = false;
	auto global = registry.copyAllReferences();
	auto zone = registry.copyZoneReferences("tatooine", &found);
	EXPECT_TRUE(found);
	auto type = registry.copyTypeReferences("metal", &found);
	EXPECT_TRUE(found);
	ASSERT_EQ(3, global.size());
	ASSERT_EQ(3, zone.size());
	ASSERT_EQ(3, type.size());
	for (int i = 0; i < 3; ++i) {
		EXPECT_EQ(expectedNames.get(i).get(), global.get(i).get());
		EXPECT_EQ(expectedNames.get(i).get(), zone.get(i).get());
		EXPECT_EQ(expectedTypes.get(i).get(), type.get(i).get());
	}
	EXPECT_EQ(3, registry.copyZoneReferences("naboo").size());
}

TEST(ResourceMapTest, NamesAreCaseInsensitiveAndMissingIndexesAreDistinct) {
	ResourceMap registry;
	auto entry = registration("MiXeD");
	registry.add(entry);
	EXPECT_TRUE(registry.containsName("MIXED"));
	EXPECT_TRUE(registry.containsName("mixed"));
	EXPECT_EQ(entry.spawn.get(), registry.findByName("mIxEd").get());
	EXPECT_FALSE(registry.containsName("missing"));
	EXPECT_EQ(nullptr, registry.findByName("missing").get());

	bool found = true;
	EXPECT_EQ(0, registry.copyZoneReferences("missing", &found).size());
	EXPECT_FALSE(found);
	EXPECT_EQ(0, registry.copyTypeReferences("missing", &found).size());
	EXPECT_FALSE(found);
	EXPECT_EQ(0, registry.copyZoneReferences("TATOOINE", &found).size());
	EXPECT_FALSE(found); // Zone keys remain case-sensitive.
}

TEST(ResourceMapTest, DuplicatePoliciesAndSeparateGlobalZoneKeysArePreserved) {
	ResourceMap registry;
	auto first = registration("ZoneName");
	first.registryName = "GlobalName";
	registry.add(first);
	auto second = registration("ZONENAME");
	second.registryName = "GLOBALNAME";
	registry.add(second);

	EXPECT_EQ(1, registry.resourceCount());
	EXPECT_EQ(first.spawn.get(), registry.findByName("globalname").get());
	EXPECT_EQ(nullptr, registry.findByName("zonename").get());
	auto zone = registry.copyZoneReferences("tatooine");
	ASSERT_EQ(1, zone.size());
	EXPECT_EQ(first.spawn.get(), zone.get(0).get());
	auto type = registry.copyTypeReferences("metal");
	ASSERT_EQ(2, type.size());
	EXPECT_EQ(first.spawn.get(), type.get(0).get());
	EXPECT_EQ(second.spawn.get(), type.get(1).get());

	// Global rejection must not suppress the original secondary-index update.
	second.finalClass = "other_type";
	second.zones.removeAll();
	second.zones.add("corellia");
	second.zones.add("");
	registry.add(second);
	EXPECT_EQ(1, registry.resourceCount());
	EXPECT_EQ(second.spawn.get(), registry.copyTypeReferences("other_type").get(0).get());
	EXPECT_EQ(second.spawn.get(), registry.copyZoneReferences("corellia").get(0).get());
	bool found = true;
	EXPECT_EQ(0, registry.copyZoneReferences("", &found).size());
	EXPECT_FALSE(found);
}

TEST(ResourceMapTest, ZoneDetachmentRetainsHistoryTypesAndExistingCopies) {
	ResourceMap registry;
	auto entry = registration("Historical");
	registry.add(entry);
	auto before = registry.copyZoneReferences("tatooine");
	registry.detachFromZones("HISTORICAL", entry.zones);

	EXPECT_EQ(1, registry.resourceCount());
	EXPECT_EQ(entry.spawn.get(), registry.findByName("historical").get());
	EXPECT_EQ(1, registry.copyAllReferences().size());
	EXPECT_EQ(1, registry.copyTypeReferences("metal").size());
	bool found = false;
	EXPECT_EQ(0, registry.copyZoneReferences("tatooine", &found).size());
	EXPECT_TRUE(found); // Empty indexes are retained rather than becoming missing.
	EXPECT_EQ(0, registry.copyZoneReferences("naboo", &found).size());
	EXPECT_TRUE(found);
	ASSERT_EQ(1, before.size());
	EXPECT_EQ(entry.spawn.get(), before.get(0).get());
}

TEST(ResourceMapTest, CopiesAndLookupOwnReferencesBeyondRegistryLifetime) {
	References global;
	References zone;
	References type;
	ManagedReference<ResourceSpawn*> lookup;
	WeakReference<ResourceSpawn*> weak;
	{
		ResourceMap registry;
		auto entry = registration("Retained");
		weak = entry.spawn.get();
		registry.add(entry);
		global = registry.copyAllReferences();
		zone = registry.copyZoneReferences("tatooine");
		type = registry.copyTypeReferences("metal");
		lookup = registry.findByName("retained");
	}

	ASSERT_NE(nullptr, weak.get().get());
	global.removeAll();
	EXPECT_EQ(String("Retained"), zone.get(0)->getName());
	zone.removeAll();
	EXPECT_EQ(String("Retained"), type.get(0)->getName());
	type.removeAll();
	EXPECT_EQ(String("Retained"), lookup->getName());
	lookup = nullptr;
	EXPECT_EQ(nullptr, weak.get().get());
}

TEST(ResourceMapTest, ReturnedContainersAreIndependentAndRecycledInsertionNeedsNoManager) {
	ResourceMap registry;
	auto entry = registration("recycled", "mixed_metal");
	entry.zones.removeAll();
	{
		Locker resourceLocker(entry.spawn);
		registry.add(entry); // S -> R; no ResourceManager or server exists in this test.
		EXPECT_TRUE(entry.spawn->isLockedByCurrentThread());
	}
	EXPECT_EQ(entry.spawn.get(), registry.findByName("RECYCLED").get());
	auto global = registry.copyAllReferences();
	auto type = registry.copyTypeReferences("mixed_metal");
	global.removeAll();
	type.removeAll();
	EXPECT_EQ(1, registry.resourceCount());
	EXPECT_EQ(1, registry.copyTypeReferences("mixed_metal").size());
	EXPECT_EQ(0, registry.copyZoneReferences("tatooine").size());
}

class RegistryInsertionThread : public Thread {
	ResourceMap& registry;
	const std::vector<ResourceMap::Registration>& entries;
	std::atomic<bool>& startCopy;
	std::atomic<bool>& finished;

public:
	std::exception_ptr failure;

	RegistryInsertionThread(ResourceMap& map, const std::vector<ResourceMap::Registration>& data,
			std::atomic<bool>& start, std::atomic<bool>& done)
		: Thread("ResourceMapTestWriter"), registry(map), entries(data), startCopy(start), finished(done) {
		setJoinable();
	}

	void run() override {
		try {
			while (!startCopy.load())
				Thread::yield();
			for (const auto& entry : entries) {
				registry.add(entry);
				Thread::yield();
			}
		} catch (...) {
			failure = std::current_exception();
		}
		finished.store(true);
	}
};

TEST(ResourceMapTest, ConcurrentInsertionAndReferenceCopy) {
	ResourceMap registry;
	std::vector<ResourceMap::Registration> entries;
	LegacyNameMap expected;
	expected.setNoDuplicateInsertPlan();
	expected.setNullValue(nullptr);
	const int count = 256;
	for (int i = count - 1; i >= 0; --i) {
		auto entry = registration("resource_" + String::valueOf(i));
		expected.put(entry.registryName, entry.spawn);
		entries.push_back(entry);
	}

	std::atomic<bool> start(false);
	std::atomic<bool> finished(false);
	RegistryInsertionThread writer(registry, entries, start, finished);
	writer.start();
	start.store(true);
	int scans = 0;
	do {
		auto resources = registry.copyAllReferences();
		EXPECT_LE(resources.size(), count);
		int previous = -1;
		for (int i = 0; i < resources.size(); ++i) {
			const auto spawn = resources.get(i);
			EXPECT_NE(nullptr, spawn.get());
			const int position = expected.find(spawn->getName());
			EXPECT_GT(position, previous);
			previous = position;
			EXPECT_EQ(spawn.get(), registry.findByName(spawn->getName()).get());
		}
		registry.copyZoneReferences("tatooine");
		registry.copyTypeReferences("metal");
		registry.containsName("resource_0");
		registry.resourceCount();
		++scans;
		Thread::yield();
	} while (!finished.load() || scans < count);
	writer.join();
	ASSERT_FALSE(static_cast<bool>(writer.failure));
	EXPECT_EQ(count, registry.resourceCount());
	EXPECT_EQ(count, registry.copyZoneReferences("tatooine").size());
	auto types = registry.copyTypeReferences("metal");
	ASSERT_EQ(count, types.size());
	for (int i = 0; i < count; ++i)
		EXPECT_EQ(entries[i].spawn.get(), types.get(i).get());
}

} // namespace
