# Bellum Gero World Builder V1.9.8 — Project Extensions

V1.9.8 adds **WBP V3 project extensions** so a World Builder project can add
interior decoration to an already-published World Builder structure without
owning or duplicating that structure.

The parent still owns exactly one permanent snapshot `BuildingObject`, one
permanent `CellObject` hierarchy, one generated shared building IFF, and one
final generated ILF. Extension projects contribute additional ILF nodes to that
parent output.

## Durable identity

Cross-project relationships never save runtime object IDs. A parent is stored as:

- parent **publish ID**
- parent **Structure local ID**
- target **Cell number**
- target **portal room name**

At runtime Core3 resolves that identity through the generated parent template:

`object/building/worldbuilder/<publish_id>/structure_<id>.iff`

The published root is matched against the active snapshot. Published CellObjects
are then resolved by their exact snapshot-authored OIDs through `ZoneServer` and
validated against the live runtime parent hierarchy. Snapshot-loaded generated
structures do not need to expose those cells through `BuildingObject::getCell()`
for the identity to be valid.

The runtime root and cell OIDs may be used while the editor is open, but are not
written into the WBP file.

## WBP V3 records

A V3 project may still contain normal `OBJECT`, `STRUCTURE`, and `INTERIOR`
records. Cross-project content adds two new records.

### EXTENDS

```text
EXTENDS <parent_publish_id> <parent_structure_local_id>
```

Example:

```text
EXTENDS droid_cave 1
```

### EXTERNAL_INTERIOR

```text
EXTERNAL_INTERIOR <local_id> <server_template> <shared_template> \
  <x> <z> <y> <qw> <qx> <qy> <qz> <snapshot_type> \
  <parent_publish_id> <parent_structure_local_id> <cell_number> <room_name>
```

Example:

```text
EXTERNAL_INTERIOR 1 object/static/structure/general/all_sign_shop_s01.iff object/static/structure/general/shared_all_sign_shop_s01.iff 1.5 0 -2 1 0 0 0 -1 droid_cave 1 2 r2
```

Every `EXTERNAL_INTERIOR` target must have a matching `EXTENDS` declaration.

## In-game authoring workflow

1. Publish and deploy the base structure project normally.
2. Create/load a second project on the same planet.
3. Target the published generated structure, or stand inside one of its cells.
4. Run `/wb structureinfo` and confirm **Published World Builder Identity: YES**.
5. Run `/wb extend` or use **Extend Published WB Structure** from the `/wb` menu.
6. Enter the desired published cell.
7. Place normal static objects through the Object Library or `/wb spawn`.
8. `/wb status` shows the object as an external interior placement.
9. `/wb extensions` lists the durable parent bindings.
10. Save/close/reload normally. Closing the extension project removes only its
    transient preview objects; it never removes the already-published parent.

To remove an unused binding:

```text
/wb unextend <publish_id> <structure_local_id>
```

World Builder refuses to remove a binding while saved external objects still
reference it.

## Positive parent ownership checks

Extension binding is intentionally stricter than the general Structure
Inspector. The structure must be a generated World Builder parent and must pass
all of the following checks:

- generated server template path matches
  `object/building/worldbuilder/<publish>/structure_<id>.iff`
- matching generated shared template exists in the active snapshot
- root OID is in the reserved `0x60000000–0x6FFFFFFF` World Builder band
- snapshot root/cell hierarchy is valid
- runtime root is the expected `BuildingObject` and template
- every published CellObject exists at its exact snapshot-authored OID
- every published CellObject belongs to the expected live runtime root
- current project is on the same planet

A normal stock cave/building cannot be bound merely because it is nearby or has
the same appearance.

## Desired-state publishing

`wb bake` loads the whole approved publish set, validates the extension graph,
and composes each parent output deterministically.

For one parent structure the final ILF order is:

1. canonical lower-TRE source ILF nodes
2. parent project's normal `INTERIOR` records (existing V2 order)
3. extension contributors ordered by canonical publish ID
4. within each contributor, `EXTERNAL_INTERIOR` local ID order

So multiple extension projects still produce **one** final parent ILF:

`interiorlayout/worldbuilder/<parent_publish_id>/structure_<id>.ilf`

Pure extension projects do not create duplicate parent roots, cells, or
structural snapshot OIDs.

## Safety validation

Candidate generation fails if any extension relationship becomes unsafe or
ambiguous, including:

- parent project missing/disabled
- parent and child on different planets
- target Structure local ID missing
- dependency cycle
- target cell removed/out of range
- saved room name no longer exactly matches the portal room
- parent source structural assets cannot be resolved

Removing a parent from the publish set while dependents remain also fails and
`wb remove` rolls the publish-set edit back.

## OID stability

The existing structural OID registry is unchanged. Parent root/cell keys remain:

```text
<parent>/structure/<id>
<parent>/structure/<id>/cell/<cell>
```

`EXTERNAL_INTERIOR` records allocate no snapshot OIDs. Adding/removing extension
decoration therefore does not change the parent root or cell identity.

## Refresh behavior

When extension content changes the final ILF of an already-deployed parent, the
**parent structure owner** becomes refresh-required.

Example:

```text
/wb refreshpublished droid_cave
/wb refreshpublished droid_cave confirm
```

Do not refresh the pure extension project. Several changed extensions that all
feed the same parent still require the parent refresh only once.

Close any open extension editing projects first so their transient preview objects are removed from the parent cells; the existing refresh precheck deliberately requires those cells to be empty.

After all required refresh confirmations pass:

1. perform a normal Core3 shutdown
2. deploy the validated candidate (`wb deploy refreshed` in the operator CLI)
3. cold-start Core3

V1.9.8 keeps the existing audited `refreshpublished` persistence-clearing
model: only the exact validated World Builder root/CellObject database records
are cleared, and the live runtime objects remain until normal shutdown.

The refresh precheck was updated for snapshot-published structures. Core3 can
load the correct snapshot CellObjects without populating the BuildingObject's
internal `cells` map, so refresh validation now treats the active snapshot OIDs
as authoritative. It still requires the exact runtime CellObject type, reserved
OID range, expected parent root, empty cells, expected template, and safe root
contents before any database mutation. The confirm path performs a second
mutation-free validation before clearing persistence.


## End-to-end validation completed

V1.9.8 was validated on a published Lok V2 cave with a separate V3 extension
project:

- published parent identity resolved successfully after a cold start
- V3 `/wb extend` bound the permanent parent without duplicating its structure
- an external interior object saved, closed, and reloaded in the permanent cell
- baking the extension changed the parent ILF while allocating no new structural OIDs
- refresh targeted the parent project, not the pure extension project
- root and all CellObject OIDs survived the refreshed deployment unchanged
- the extension decoration became permanent through the parent's generated ILF
- removing the extension removed only its contribution and preserved structural OIDs
- removing a parent with an enabled dependent extension was rejected transactionally
- removing both disposable test projects retired their structural OIDs without recycling them

## Candidate freshness

V1.9.8 adds one more deployment guard: the current enabled publish IDs and every
approved WBP SHA-256 must still match the validated candidate manifest. If a WBP
or publish-set membership changes after `wb bake`, deployment refuses and asks
for a new bake.

Existing canonical snapshot/shared-IFF/portal/ILF dependency hash checks remain
active as well.

## Compatibility

- WBP V1 parsing/publishing behavior is preserved.
- WBP V2 parsing/publishing behavior is preserved.
- Existing V1/V2 project fingerprints remain unchanged unless their effective
  output receives V3 extension contributions.
- No database schema migration is required.
- No hand-authored client/TRE asset is required; the normal generated
  `bg_worldbuilder.tre` remains the client/server output.
