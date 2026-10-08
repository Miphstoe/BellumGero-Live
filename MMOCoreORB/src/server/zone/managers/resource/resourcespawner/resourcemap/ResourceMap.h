/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef RESOURCEMAP_H_
#define RESOURCEMAP_H_

#include "server/zone/objects/resource/ResourceSpawn.h"
#include "system/thread/ReadWriteLock.h"

/**
 * Registry of all resource spawns, including historical and recycled resources.
 * The same guard protects the name registry and its type and zone indexes.
 * Callers must keep the owning ResourceSpawner alive while accessing this registry.
 */
class ResourceMap {
public:
	using ResourceReferences = Vector<ManagedReference<ResourceSpawn*>>;

	/**
	 * Prepare these values under the ResourceSpawn lock before calling add().
	 * registryName and spawnName remain separate to preserve the original global
	 * and zone key semantics. ResourceMap never inspects the resource under guard.
	 */
	struct Registration {
		String registryName;
		String spawnName;
		String finalClass;
		Vector<String> zones;
		ManagedReference<ResourceSpawn*> spawn;
	};

private:
	using NameMap = VectorMap<String, ManagedReference<ResourceSpawn*>>;

	NameMap resourceNames;
	VectorMap<String, NameMap*> zoneResourceMap;
	VectorMap<String, ResourceReferences*> typeResourceMap;

	// Final lock in every scope: no gameplay locks, resource inspection,
	// callbacks, UI construction or I/O while this guard is held.
	mutable ReadWriteLock guard;

public:
	ResourceMap();
	~ResourceMap();

	ResourceMap(const ResourceMap&) = delete;
	ResourceMap& operator=(const ResourceMap&) = delete;

	void add(const Registration& registration);

	// Inputs are copied under the ResourceSpawn lock. The historical name entry
	// and type index are deliberately retained, including empty zone indexes.
	void detachFromZones(const String& spawnName, const Vector<String>& zones);

	ManagedReference<ResourceSpawn*> findByName(const String& name) const;
	ResourceReferences copyAllReferences() const;

	// Copies follow the existing name-key order (zones) and append order (types).
	// found distinguishes a missing index from an existing but empty index.
	ResourceReferences copyZoneReferences(const String& zoneName, bool* found = nullptr) const;
	ResourceReferences copyTypeReferences(const String& typeName, bool* found = nullptr) const;

	bool containsName(const String& name) const;
	bool containsType(const String& typeName) const;
	int resourceCount() const;

	// Copy the owning reference and release the registry guard before querying
	// density. Retains the existing caller precondition: the name exists.
	float getDensityAt(const String& resourceName, String zoneName, float x, float y) const;
};

#endif /* RESOURCEMAP_H_ */
