# Core3 current live resource snapshots (Phase 4A.3)

This optional, read-only exporter publishes the current Core3 in-shift resource
set. It does not capture despawn history, modify resources, import into a website,
connect to PostgreSQL, or expose an HTTP endpoint. ResourceMap's Phase 4A.2
synchronization boundary is unchanged.

## Configuration

`bin/conf/config.lua` defines these defaults; the C++ defaults agree:

```lua
Core3.ResourceSnapshot = {
    Enabled = false,
    OutputPath = "log/resource-snapshot.json",
    IntervalSeconds = 300,
    SourceInstance = "bellum-gero-development:default",
}
```

Override this table in `bin/conf/config-local.lua` for the deployment. Settings
are read at ResourceManager initialization; changing them requires a restart.
An enabled exporter requires a non-empty path and source instance, and a positive
interval. Invalid settings leave the exporter unavailable.

Relative paths resolve against the process working directory, normally
`MMOCoreORB/bin`. Absolute paths are supported. The default uses the runtime log
directory, not a Git-tracked source directory. The parent directory must already
exist and be writable; the exporter does not create directories. Temporary and
published files are created owner-readable/writable (`0600` via `mkstemp`). Plan
the shared-directory/user/ACL arrangement before the separate importer is enabled.

The development source instance is an explicit constant, not verified production
provenance. Before production use, configure a persistent value such as
`bellum-gero-production:<database-lineage-id>`. Keep it with the persistent Core3
database lineage across restarts/restores; assign a different configured value to
an independent fork of that lineage. Never derive it from time, PID, hostname, or
a random startup value. Do not share the development default between independently
imported databases. Identity for the future importer is the tuple
`(source_system, source_instance, source_resource_id)`.

## Capture and lifetime

ResourceManager starts the exporter after ResourceSpawner initialization, database
resource loading, its existing initial shift, and survey loading. Under the
ResourceManager lock it hands the exporter an owning `Reference<ResourceSpawner*>`.
Manager detachment uses that same lock. The exporter retains this lifetime pin
until cancellation has drained the worker. It never acquires a borrowed spawner
pointer from an unlocked manager during an export.

For a capture, the exporter takes a local spawner pin, records one wall-clock UTC
cutoff, and calls only `ResourceMap::copyAllReferences()`. The registry releases its
guard before returning owning `ManagedReference<ResourceSpawn*>` values. The local
spawner pin can then be released. Each resource is examined under its own
`ReadLocker`, with no other resource locked concurrently.

ResourceSpawn gets one new `@local @read` IDL accessor,
`getSpawnAttributeCount()`. It returns `spawnAttributes.size()` without changing
persistent fields. The exporter uses this bound and the existing read accessor
`getAttributeAndValue()` to copy every actual entry, including explicit zeroes.
Existing `@read` name/type/deadline/map-key accessors use generated
`_getImplementationForRead()` access. Capture does not call modifying accessors or
`ResourceSpawn::writeJSON()`.

The plain records contain only owned standard strings, integers and standard
vectors. The local resource-reference collection and read locks are destroyed
before sorting, JSON construction, or file operations. The service's lifetime pin
does not cause further gameplay-object reads during those stages. Optional galaxy
metadata and configured build revision are copied once during initialization;
exports never query a server/zone service for them.

There is no whole-server transaction. Membership is observed once, and resources
are observed sequentially. An individual resource may change before/after its
observation. This is represented as `consistency: "interval"`.

## Schema version 1

All non-null timestamps use **integer Unix UTC seconds**, including top-level
timestamps and `lifecycle.expires_at`. Formats are never mixed.

```json
{
  "schema_version": 1,
  "source_system": "core3",
  "source_instance": "bellum-gero-production:<database-lineage-id>",
  "generated_at": 1800000002,
  "captured_at": 1800000000,
  "capture_started_at": 1800000000,
  "capture_completed_at": 1800000001,
  "consistency": "interval",
  "complete": true,
  "selection": "core3_in_shift",
  "resource_count": 1,
  "resources": [
    {
      "source_resource_id": "1234567890123456789",
      "name": "ExampleResource",
      "source_type_id": "copper_borocarbitic",
      "stats": {"CD": 800, "OQ": 0},
      "planets": ["corellia", "tatooine"],
      "spawn_map_state": "present",
      "lifecycle": {
        "spawned_at": null,
        "expires_at": 1800100000,
        "despawned_at": null
      },
      "active": true
    }
  ],
  "galaxy": {"id": 2, "name": "Bellum Gero"},
  "build": {"revision": null, "commit": null}
}
```

The only active-selection predicate is `despawned > captured_at`. Core3's persisted
`despawned` is the expiration deadline. Equality, expiration before the cutoff,
and recycled expiration zero are excluded. No pool, zone-index, registry-membership,
`spawned`, or planet-map condition establishes activity independently.

An active resource with zero map keys remains included with `planets: []` and
`spawn_map_state: "empty"`. Planet strings come exclusively from actual
`spawnMaps` keys through `getSpawnMapZone()`. No fixed planet list is used.

Resource identity is the exact decimal string of the full unsigned 64-bit object
ID. Name is the actual generated spawn name, and type is the raw resource-tree
slug from `getType()`. Neither is a container display name. Resources sort by
numeric OID; planets sort by string; JSON/stat object keys use nlohmann's stable
map ordering. Identical owned input and generation timestamps serialize identically.

Only actually present verified crafting attributes are mapped:

| Core3 attribute | Snapshot stat |
| --- | --- |
| res_cold_resist | CR |
| res_conductivity | CD |
| res_decay_resist | DR |
| res_flavor | FL |
| res_heat_resist | HR |
| res_malleability | MA |
| res_potential_energy | PE |
| res_quality | OQ |
| res_shock_resistance | SR |
| res_toughness | UT |

Missing attributes are omitted; explicit zeroes are retained. Inspection is not
limited to twelve entries. Unknown attributes remain plain internal capture data
and are omitted from the external contract. No ER mapping is invented.
`spawned_at` and `despawned_at` are JSON null because creation and historical
despawn time are not established. The exporter never infers original duration.

`captured_at` equals the capture start time and is the single selection cutoff.
`capture_completed_at` is recorded after reference/field copying ends.
`generated_at` is recorded when JSON generation begins after capture. Metadata
uses the actual system clock; clock adjustments can affect interval timestamps.
Duration diagnostics use the monotonic clock.

`build.revision` is the already configured `Core3.Revision`, or null if absent.
`build.commit` is always null because no verified commit identifier is supplied.
There is no Git invocation during export.

## Scheduling, manual requests and shutdown

The repository-native task manager supplies a dedicated
`ResourceSnapshotExporter` queue with one worker. The first capture is scheduled
asynchronously at initialization. Each completed or failed operation schedules
the next timer after `IntervalSeconds`; this is a fixed delay, not a two-hour
resource-shift dependency. Export never invokes `shiftResources()`.

`/resource export` is a narrow subcommand of the existing resource admin command.
It requests the same worker operation and immediately reports accepted,
already queued/running, disabled/stopping, or failed admission. It performs no
capture, file work, JSON construction, or worker wait on the player thread.
Existing command dispatch/permissions are unchanged. A manual request supersedes
the pending periodic timer. Timer generation tokens invalidate stale callbacks.

An admission gate covers queued work through final publication, so concurrent
requests admit one operation. Weak task-to-exporter ownership avoids timer cycles;
running tasks acquire an owning exporter reference. Cancellation and final rename
share a separate gate. Once cancellation linearizes, no subsequent promotion is
allowed. If rename already owns the gate, it completes before cancellation
linearizes. There is one publication path; older captures cannot publish after
newer ones within this exporter instance.

ServerCore explicitly cancels/drains exports immediately after setting shutdown
state, before zone clearing and task-manager shutdown. ResourceManager also stops
the exporter before detaching the spawner. No worker wait occurs inside the
manager's lock. Stop is idempotent; the later manager stop does not wait on a
task manager that has already shut down. Capture cancellation is checked between
resources, before file writing, and under the final promotion gate.

Diagnostics record capture start/end, candidate/active counts, monotonic capture
duration, publication success/failure, and cancellation reason. Manual admission
and already-running diagnostics are returned to the requesting administrator.
Resources are not logged individually.

## Publication guarantees

JSON is completely generated in memory first. `mkstemp` creates a unique adjacent
temporary file on the destination filesystem. `fwrite`, stream error state,
`fflush`, and `fclose` must all succeed before publication. POSIX `rename` then
atomically replaces the destination on the Linux deployment. The old destination
is never unlinked first. Failed capture, serialization, write, cancellation, or
rename leaves the previous snapshot intact. The current published file is not
opened for writing.

RAII cleanup unlinks only this operation's owned temporary path after ordinary
failure/cancellation. A process crash can leave temporary files; no broad directory
cleanup is performed. Visibility is atomic (complete old/new JSON); fsync-level
crash durability is **not** provided. The design assumes one configured Core3
exporter process owns a destination. Multiple independently running Core3
processes must use different paths; there is no cross-process publication lock.

## Compilation and focused tests (operator steps; not performed by this change)

Do not edit `src/autogen`. ResourceManager and ResourceSpawn IDL changes require
the normal IDLC/CMake generated-code workflow. Reconfigure CMake because the source
globs must discover the new exporter/publication `.cpp` files and test source.
Keep `BUILD_IDL=ON`; tests need `COMPILE_TESTS=ON` (the existing default).

For the existing container/build directory:

```sh
docker exec docker-swgemu-1 cmake -S /build/MMOCoreORB -B /build/MMOCoreORB/build/unix -DBUILD_IDL=ON -DCOMPILE_TESTS=ON
docker exec docker-swgemu-1 cmake --build /build/MMOCoreORB/build/unix --target core3 --parallel 2
docker exec docker-swgemu-1 sh -c 'cd /build/MMOCoreORB/bin && ./core3 runUnitTests --gtest_filter="ResourceMapTest.*:ResourceSnapshotTest.*:ResourceSnapshotPublicationTest.*"'
```

The first command refreshes configuration without compilation. The second
regenerates IDL and builds; choose parallelism appropriate to available memory.
The third is a focused test-mode Core3 invocation and should be run in your normal
isolated test environment. This implementation pass does not execute any of them.

Fourteen focused snapshot/publication tests cover strict cutoff boundaries,
recycled-zero exclusion, active empty maps, exact full-width decimal OID strings,
actual attribute enumeration beyond twelve, missing/zero/normal stats, all ten
verified mappings and no ER, numeric resource and string planet ordering,
determinism, JSON escaping, metadata/lifecycle nulls, single-flight admission,
atomic replacement, failed temporary-file creation, and cancellation after a
successful write but before promotion. There are no timing-dependent sleeps.

The file-failure test uses a valid maximum-length published filename whose
temporary suffix exceeds the filesystem filename limit. It reliably tests failure
without relying on permissions that root may bypass. Actual disk-full, short-write,
flush-error and close-error injection are not unit-tested; their return paths are
checked in production and should be exercised in deployment validation.

## Runtime validation

1. Build/regenerate and run the focused tests, including the seven ResourceMap
   regression tests. Confirm the default disabled configuration writes no file
   and `/resource export` reports disabled.
2. Configure a stable development lineage and a writable dedicated destination.
   Start normally; confirm the initial asynchronous snapshot and subsequent
   periodic snapshots without forcing a resource shift.
3. Parse JSON and check schema, integer UTC timestamps, count, numeric OID ordering,
   string IDs, verified stats, actual map keys, and interval metadata. Confirm
   active empty-map resources remain included when such a fixture exists.
4. Request `/resource export` repeatedly during an operation. Confirm one operation
   is admitted and already-running requests are reported. Check the next scheduled
   operation occurs after completion plus the configured delay.
5. Exercise failure on an isolated test output filesystem (unwritable parent,
   exhausted space/quota, or failed replacement). Keep a known valid published
   snapshot and confirm failures preserve its content and log a concise reason.
6. Repeatedly parse the destination while exports replace it; readers must see
   complete valid old/new JSON, including with concurrent resource activity.
7. Initiate normal and fast shutdown during capture/write. Confirm cancellation
   and worker drain before zone clearing, no promotion after cancellation, and no
   deadlock. Check ordinary failures/cancellations leave no owned temporary files.
8. Restart with the same database lineage and verify source identity stays stable.

Remaining verification includes IDLC regeneration/compiler compatibility, actual
task-manager shutdown behavior under load, deployment filesystem permissions,
short/failed-write behavior, and read-lock interaction with live resource activity.
No compilation or runtime claims are made from static inspection alone.
