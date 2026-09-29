/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#include "ResourceMap.h"
#include "system/thread/Locker.h"
#include "system/thread/ReadLocker.h"

ResourceMap::ResourceMap() : guard("ResourceMap") {
	resourceNames.setNoDuplicateInsertPlan();
	resourceNames.setNullValue(nullptr);

	zoneResourceMap.setNoDuplicateInsertPlan();
	zoneResourceMap.setNullValue(nullptr);

	typeResourceMap.setNullValue(nullptr);
}

ResourceMap::~ResourceMap() {
	// The owner must exclude callers before destruction. A registry guard cannot
	// make an already-destroyed ResourceSpawner safe to access.
	resourceNames.removeAll();

	while (typeResourceMap.size() > 0) {
		delete typeResourceMap.get(0);
		typeResourceMap.remove(0);
	}

	while (zoneResourceMap.size() > 0) {
		delete zoneResourceMap.get(0);
		zoneResourceMap.remove(0);
	}
}

void ResourceMap::add(const Registration& registration) {
	const String registryKey = registration.registryName.toLowerCase();
	const String zoneKey = registration.spawnName.toLowerCase();

	Locker locker(&guard);

	resourceNames.put(registryKey, registration.spawn);

	// Preserve duplicate behavior: type entries append even if the global name
	// is rejected, while global and zone names reject duplicate inserts.
	auto typeMap = typeResourceMap.get(registration.finalClass);
	if (typeMap == nullptr) {
		typeMap = new ResourceReferences();
		typeResourceMap.put(registration.finalClass, typeMap);
	}
	typeMap->add(registration.spawn);

	for (int i = 0; i < registration.zones.size(); ++i) {
		const String& zoneName = registration.zones.get(i);
		if (zoneName == "")
			continue;

		auto zoneMap = zoneResourceMap.get(zoneName);
		if (zoneMap == nullptr) {
			zoneMap = new NameMap();
			zoneMap->setNoDuplicateInsertPlan();
			zoneMap->setNullValue(nullptr);
			zoneResourceMap.put(zoneName, zoneMap);
		}
		zoneMap->put(zoneKey, registration.spawn);
	}
}

void ResourceMap::detachFromZones(const String& spawnName, const Vector<String>& zones) {
	const String key = spawnName.toLowerCase();

	Locker locker(&guard);

	for (int i = 0; i < zones.size(); ++i) {
		auto zoneMap = zoneResourceMap.get(zones.get(i));
		if (zoneMap != nullptr)
			zoneMap->drop(key);
	}
}

ManagedReference<ResourceSpawn*> ResourceMap::findByName(const String& name) const {
	const String key = name.toLowerCase();
	ReadLocker locker(&guard);
	return resourceNames.get(key);
}

ResourceMap::ResourceReferences ResourceMap::copyAllReferences() const {
	ReadLocker locker(&guard);
	ResourceReferences resources;

	for (int i = 0; i < resourceNames.size(); ++i)
		resources.add(resourceNames.get(i));

	return resources;
}

ResourceMap::ResourceReferences ResourceMap::copyZoneReferences(const String& zoneName, bool* found) const {
	ReadLocker locker(&guard);
	ResourceReferences resources;
	const auto zoneMap = zoneResourceMap.get(zoneName);

	if (found != nullptr)
		*found = zoneMap != nullptr;

	if (zoneMap != nullptr) {
		for (int i = 0; i < zoneMap->size(); ++i)
			resources.add(zoneMap->get(i));
	}

	return resources;
}

ResourceMap::ResourceReferences ResourceMap::copyTypeReferences(const String& typeName, bool* found) const {
	ReadLocker locker(&guard);
	const auto typeMap = typeResourceMap.get(typeName);

	if (found != nullptr)
		*found = typeMap != nullptr;

	if (typeMap == nullptr)
		return ResourceReferences();

	return *typeMap;
}

bool ResourceMap::containsName(const String& name) const {
	const String key = name.toLowerCase();
	ReadLocker locker(&guard);
	return resourceNames.contains(key);
}

bool ResourceMap::containsType(const String& typeName) const {
	ReadLocker locker(&guard);
	return typeResourceMap.contains(typeName);
}

int ResourceMap::resourceCount() const {
	ReadLocker locker(&guard);
	return resourceNames.size();
}

float ResourceMap::getDensityAt(const String& resourceName, String zoneName, float x, float y) const {
	auto resourceSpawn = findByName(resourceName);
	return resourceSpawn->getDensityAt(zoneName, x, y);
}
