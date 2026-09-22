# Delete a placed item

After rebuilding and restarting Core3, a GM with god mode and the existing
`object` ability can stand in the item's room and run:

```text
/object delete 281475097841892
```

Alternatively, target the item and run `/object delete`. The confirmation shows
the item's name, object ID, parent ID and template. Choose Delete to permanently
remove that item from the world and database, or Cancel to leave it alone.
No pickup radial, inventory transfer, client patch or new command grant is needed.

The command supports empty tangible items placed directly in a structure cell,
including a spawned `object/tangible/jedi/force_shrine_stone.iff`. Stand within
32 meters in the same room. It rejects structures, creatures, ships, vehicles,
vendors, control devices, built-in structure children, and objects with contents,
slotted objects or child objects. It does not remove a spawn definition.

Confirmation stays bound to the original object ID, even if the GM changes targets.
Permissions, location and item eligibility are checked again on confirmation;
an item moved to a different parent requires a new confirmation. Deletion uses
the normal world-removal API and a nonrecursive database deletion, with transaction
and GM logging. The parent structure is not deleted.

## Validation

The edited headers passed a syntax-only compilation of CommandConfigManager3.cpp
using an existing Debian Core3 compiler configuration and generated headers.
No live deletion, full server build or restart was performed.

Before deployment, exercise on a disposable test structure:

- Spawn a shrine in a room. Open confirmation by target and by explicit ID;
  check that Cancel preserves it and Delete removes it without changing the room.
- Change targets while confirmation is open; only the originally confirmed item
  should be deleted. Move the item to another parent or revoke GM access before
  accepting; deletion should be rejected.
- Try a player, building, populated container, built-in terminal, nonexistent ID,
  zero, negative ID, overflowing ID and extra arguments; none should be deleted.
- Save and restart the test server; confirm the deleted shrine stays gone and
  the structure and its other items remain.
