# Bellum Gero World Builder — V1 Guide

## What this solves

Bellum Gero World Builder turns the **running SWG client into the placement editor**. Instead of editing `snapshot/<planet>.ws`, rebuilding a TRE, restarting, taking screenshots, and repeating, a developer can spawn an object, nudge it, rotate it, duplicate it, test real collision, and see every adjustment immediately in the actual client.

The system intentionally separates **live editing** from **production output**:

1. **In-game preview/editing** — transient objects on the local development server.
2. **`.wbp` project file** — autosaved source-of-truth for placements.
3. **Production export** — normally a generated Lua screenplay; TRE snapshot baking is available when a world snapshot is truly required.

This separation is important. It makes experimentation fast without turning every nudge into a permanent database or TRE change.

---

# Installation

## New server files

Place these files at their listed locations:

- `WorldBuilderManager.h` → `MMOCoreORB/src/server/zone/managers/worldbuilder/WorldBuilderManager.h`
- `WorldBuilderManager.cpp` → `MMOCoreORB/src/server/zone/managers/worldbuilder/WorldBuilderManager.cpp`
- `WorldBuilderCommand.h` → `MMOCoreORB/src/server/zone/objects/creature/commands/WorldBuilderCommand.h`
- `worldbuilder.lua` → `MMOCoreORB/bin/scripts/commands/worldbuilder.lua`
- `wb.lua` → `MMOCoreORB/bin/scripts/commands/wb.lua`
- `projects_README.txt` → `MMOCoreORB/bin/worldbuilder/projects/README.txt`

Create the directory `MMOCoreORB/bin/worldbuilder/projects/` if it does not already exist. The Core3 process needs write permission to that directory.


## One-time custom TRE command registration

The server C++/Lua files are only one half of a new SWG slash command. The
shared command table in Bellum Gero's active custom TRE also needs rows for:

```text
/worldbuilder
/wb
```

V1.1 includes:

```text
patch_worldbuilder_commands.py
```

Run it against the **current** `bg_custom1.tre` that you intend to use as your
local Bellum Gero client/server TRE:

```powershell
python patch_worldbuilder_commands.py bg_custom1.tre bg_custom1_worldbuilder.tre
```

The tool never overwrites the input TRE. It updates only:

```text
datatables/command/command_table.iff
```

and preserves all other TRE records. It clones Bellum Gero's existing custom
command defaults, validates the resulting archive, and verifies that both
`worldbuilder` and `wb` rows exist.

Then deploy the **same output TRE** to both:

1. the local SWG client TRE location;
2. the local Core3/server TRE location.

Rename the deployed copy to the normal active filename (`bg_custom1.tre`) if
that is how the local setup references it.

This TRE step is a **one-time World Builder installation requirement**. Normal
live placement/editing does not rebuild or recopy the TRE between object
nudges. Future `bg_custom1.tre` revisions must retain these two command-table
rows; rerun the patcher on a newer TRE if they are ever missing.

## Two registration edits

`MMOCoreORB/src/server/zone/objects/creature/commands/commands.h`

Add:

```cpp
#include "WorldBuilderCommand.h"
```

The include can be placed with the other command headers near the `W` section.

`MMOCoreORB/bin/scripts/commands/commands.lua`

Add:

```lua
RunSlashCommandsFile("worldbuilder.lua")
RunSlashCommandsFile("wb.lua")
```

The command loader order is not important for these two standalone commands.

## Build

Build Core3 normally. No CMake change is required because the current Core3 build recursively includes `server/zone/*.cpp` and `server/zone/*.h`.

After the build, restart the local server.

---

# First-use smoke test

Log in with an admin-level character. V1 requires **admin level 15 or greater**.

Run:

```text
/wb
```

You should get the **Bellum Gero World Builder** SUI menu.

Choose **New Project** and enter:

```text
wb_smoke_test
```

The server should create:

```text
MMOCoreORB/bin/worldbuilder/projects/wb_smoke_test.wbp
```

World Builder autosaves every placement-changing action.

---

# Core workflow

## 1. Start a project

```text
/wb new droid_cave_exterior
```

A project is tied to the planet on which it was created. Travel to that planet before loading the project later.

To resume after a server restart:

```text
/wb load droid_cave_exterior
```

The saved preview objects will be respawned automatically.

## 2. Spawn an object

Use the SUI **Spawn New Template** entry, or type:

```text
/wb spawn object/static/structure/general/cave_wall_tato_style_01.iff
```

It spawns approximately 3 meters in front of the character and becomes the selected World Builder object.

Specify another distance if useful:

```text
/wb spawn object/static/structure/general/cave_wall_tato_style_01.iff 8
```

After the first spawn, quickly repeat the same template with:

```text
/wb last
```

This is especially useful for rubble, walls, trees, crates, or repeated dungeon decoration.

## 3. Select objects reliably

Some static objects are awkward or impossible to target normally. World Builder does **not** depend on client targeting.

Use:

```text
/wb objects
```

The object list shows every object by a stable **World Builder local ID** such as `#17`. The selected object is marked `*`, and active group members are marked `[G]`.

Other options:

```text
/wb select 17
/wb next
/wb prev
/wb target
```

`/wb target` only works when the client object can actually be targeted. The project object list is the dependable method.

## 4. Precision movement

Set the movement increment:

```text
/wb step 0.01
```

Valid range is 0.01–25 meters.

Then nudge the selected object relative to the direction the developer character is facing:

```text
/wb f
/wb b
/wb l
/wb r
/wb u
/wb d
```

You can override the configured step for one move:

```text
/wb f 0.35
/wb u 1.5
```

Long forms also work:

```text
/wb move forward 0.25
/wb move left 2
```

World-axis movement is available when exact coordinates matter:

```text
/wb move x+ 0.1
/wb move x- 0.1
/wb move y+ 0.1
/wb move y- 0.1
```

In the SWG coordinate convention shown by World Builder, `z` is height.

## 5. Precision rotation

Set the default rotation increment:

```text
/wb rotstep 1
```

Then:

```text
/wb yaw 1
/wb yaw -1
/wb pitch 1
/wb pitch -1
/wb roll 1
/wb roll -1
```

If the degree value is omitted, the configured rotation step is used:

```text
/wb yaw
```

V1 preserves the full quaternion in the project file, so pitch and roll are not reduced to heading-only data.

## 6. Place relative to the developer

Move the selected object exactly to the developer's current location:

```text
/wb snap
```

Or place it a chosen distance in front of the developer:

```text
/wb front 5
```

These are useful when the desired placement point is easier to reach with the character than to estimate numerically.

## 7. Duplicate objects

Duplicate the selected object, preserving its exact rotation:

```text
/wb duplicate
```

The copy is offset by the current movement step so it does not occupy exactly the same position, and the new object becomes selected.

Override the forward offset:

```text
/wb duplicate 5
```

---

# Groups — the feature that avoids the rockfall problem

The cave rockfall work showed that copying an entire **proven formation** is often better than repeatedly filling individual holes. Groups are designed for exactly that case.

Select an object and add it:

```text
/wb group add
```

Repeat for every object in the formation. `[G]` appears beside group members in `/wb objects`.

Remove selected:

```text
/wb group remove
```

Clear the group:

```text
/wb group clear
```

Move every group member by the same translation:

```text
/wb group move right 5
/wb group move up 2
```

Duplicate an entire formation while preserving every member's relative position and rotation:

```text
/wb group duplicate 10
```

The copies become the new active group. You can then move the complete copied formation as one unit.

### V1 group-rotation limitation

`/wb group rotate` rotates each member's **orientation**, but V1 does not yet orbit member positions around a shared pivot. Do not use it expecting a rigid Blender-style group rotation. Rigid pivot rotation is a good V2 enhancement.

---

# Undo / Redo

```text
/wb undo
/wb redo
```

V1 keeps up to 30 project history states. Undo is intentionally robust rather than clever: it rebuilds all preview objects from the saved previous state. A large project may visibly flicker for a moment during undo/redo.

This works for object movement, rotation, spawn, delete, duplication, and group operations.

Because every mutation also autosaves, an accidental delete can normally be recovered immediately with `/wb undo`.

---

# Saving and server restarts

Every mutating operation autosaves the `.wbp` file. You can still force a save:

```text
/wb save
```

Close cleanly with:

```text
/wb close
```

Closing saves the project and removes all transient preview objects.

If Core3 restarts unexpectedly, the preview objects disappear — **that is intentional**. The `.wbp` file remains. Return to the correct planet and run:

```text
/wb load <project>
```

This avoids polluting the normal object database with unfinished development geometry.

---

# Production output: choose Lua first

For ordinary world decoration, POI dressing, rocks, props, terminals, and many custom dungeon objects, the recommended V1 production output is a screenplay.

Inside the game:

```text
/wb export
```

This creates:

```text
MMOCoreORB/bin/worldbuilder/projects/<project>_export.lua
```

The exported file contains exact `spawnSceneObject()` calls with position, parent/cell ID, and quaternion.

Move the generated screenplay to the appropriate server screenplay folder, include/register it normally, restart, and test without the World Builder project loaded.

### Why Lua is preferred when possible

- no client TRE rebuild for placement-only changes;
- exact transform is preserved;
- easy Git review/diff;
- easy removal or iteration;
- supports cell-parented placement in V1;
- avoids snapshot object-ID management.

The client must still already possess the referenced object assets/templates. World Builder cannot make a client display an asset it does not have.

---

# Advanced production output: TRE snapshot bake

The included companion program is:

```text
bellum_worldbuilder.py
```

It uses only the Python standard library.

## Validate

```powershell
python bellum_worldbuilder.py validate droid_cave_exterior.wbp
```

## Export Lua outside the server

```powershell
python bellum_worldbuilder.py export-lua droid_cave_exterior.wbp
```

## Inspect a base TRE

```powershell
python bellum_worldbuilder.py inspect-tre bg_custom1_BASE.tre --planet lok
```

## Bake a project into `snapshot/lok.ws`

```powershell
python bellum_worldbuilder.py bake-tre droid_cave_exterior.wbp `
  --base bg_custom1_BASE.tre `
  --output bg_custom1_DroidCave.tre
```

### Critical rule: always bake from a clean/known base

Do **not** use yesterday's generated World Builder TRE as today's base. Doing so would turn project output into accumulated history and could duplicate project nodes.

Keep a deliberate baseline such as:

```text
bg_custom1_BASE.tre
```

and regenerate the desired output from that baseline + the `.wbp` project.

The baker:

- validates the TRE v5 archive;
- extracts `snapshot/<planet>.ws`;
- preserves unrelated TRE records byte-for-byte at the payload level;
- appends needed OTNL template names;
- allocates new snapshot object IDs;
- infers the snapshot `gameObjectType` from an existing instance of the same shared template when possible;
- updates IFF/TRE sizes and offsets;
- rebuilds the archive to a **new file**;
- reopens and validates the finished TRE;
- writes `<output>.worldbuilder_ids.json` with the generated permanent snapshot IDs.

### TRE bake V1 limitations

TRE baking currently supports **world/top-level objects only** (`parentID = 0`). If a project contains objects inside cells, the baker refuses to guess how they should be attached. Use the Lua export for those objects in V1.

If the snapshot template has never existed in the base TRE, the baker may be unable to infer its snapshot game-object type. It will fail instead of silently guessing. For a verified special case, set the selected object's override in-game:

```text
/wb snaptype 200
```

Reset to automatic inference:

```text
/wb snaptype -1
```

Only use an override after confirming the correct value for that template.

---

# Optional one-command deploy

Copy `worldbuilder_config.example.json` to:

```text
worldbuilder_config.json
```

Edit the paths for the development machine. Example keys:

```json
{
  "base_tre": "C:/path/to/bg_custom1_BASE.tre",
  "output_tre_name": "bg_custom1.tre",
  "client_tre_dir": "C:/path/to/SWG/client",
  "server_tre_dir": "//wsl$/Ubuntu/path/to/MMOCoreORB/bin/tre"
}
```

Then:

```powershell
python bellum_worldbuilder.py build-deploy droid_cave_exterior.wbp --config worldbuilder_config.json
```

The tool builds from the configured clean base, validates the output, creates timestamped backups of destination TREs, and copies the same new TRE to both configured locations.

This is meant to eliminate the old "remember to copy it to the client, then remember to copy it to WSL" failure mode.

---

# Recommended toolbar macros

For a placement-heavy session, create SWG macros and put them on a toolbar:

```text
/wb f
/wb b
/wb l
/wb r
/wb u
/wb d
```

Rotation macros:

```text
/wb yaw 1
/wb yaw -1
/wb pitch 1
/wb pitch -1
/wb roll 1
/wb roll -1
```

A useful workflow is coarse-to-fine:

1. `/wb step 1`
2. rough placement
3. `/wb step 0.1`
4. alignment
5. `/wb step 0.01`
6. final seam/collision work

Likewise, use `15`, `5`, then `1` degree rotation increments.

---

# Collision workflow

World Builder shows the **real client geometry and real server collision behavior**, but V1 does not draw a collision wireframe.

For assets with irregular collision — exactly like the large cave-wall rocks — test them physically:

1. place the visual object;
2. exit movement/selection mode mentally and run into every edge;
3. jump and strafe diagonally;
4. check both high and low edges;
5. if the model's collision is unreliable, build a hidden collision core from smaller dependable objects;
6. group the proven formation so it can be duplicated as a unit.

The important difference from the old process is that all of this testing now happens **without rebuilding the TRE between nudges**.

---

# Safety / pain points V1 already addresses

## Static objects cannot always be targeted
Use `/wb objects` and stable local IDs. Do not depend on normal client targeting.

## Tiny coordinate changes are painful
Movement goes down to 0.01m and rotation to 0.1 degrees.

## A working formation needs to be copied, not recreated
Use groups and `group duplicate`.

## Accidental delete/move
Use undo/redo; mutations autosave.

## Server crash / developer forgets to save
The `.wbp` manifest autosaves after every mutation.

## Runtime object IDs change after restart
They are not the project identity. World Builder local IDs are stable; runtime OIDs are deliberately regenerated.

## Repeated TRE baking can duplicate content
The companion tool requires an explicit clean base and refuses to overwrite it in place.

## A template has unknown snapshot metadata
The TRE baker fails safely instead of guessing.

## Client asset is missing
The editor cannot solve a missing-client-asset problem. Add the asset/TRE first, then use World Builder for placement.

## Multiple developers edit the same project simultaneously
V1 does not implement file locking or merge resolution. Use **one active editor per project file**. Separate developers should use separate project names and merge/export intentionally.

---

# Features deliberately left for V2+

These are good future improvements, but were kept out of the first implementation to reduce risk:

- rigid group rotation around a chosen pivot;
- visual selection marker/gizmo;
- collision wireframe/debug rendering;
- snap-to-terrain / surface-normal alignment;
- multi-select directly from one SUI window;
- template browser/search instead of entering template paths;
- saved prefab library ("9-rock cave wall", camp kit, barricade, etc.);
- project locking / multi-developer collaboration;
- editing pre-existing snapshot objects directly;
- terrain heightmap editing;
- POB portal/cell topology editing;
- live baking/hot-reload of TRE files.

The `.wbp` format is versioned from the start specifically so these can be added without throwing away V1 projects.

---

# Practical test plan for the first server build

Before step 1, confirm the patched World Builder `bg_custom1.tre` is installed in both the local client and local server TRE locations.

1. Build Core3 and restart the local server.
2. Log in as an admin-level-15+ character on Lok.
3. `/wb new wb_smoke_test`.
4. Spawn `object/static/structure/general/cave_wall_tato_style_01.iff`.
5. Verify it appears instantly in front of the character.
6. `/wb step 0.01` and verify `/wb f`, `/wb l`, `/wb u` visibly move it by tiny amounts.
7. Test yaw, pitch, and roll.
8. `/wb duplicate 5`; confirm the copy has identical orientation and becomes selected.
9. Open `/wb objects`; select the first object even if the static object cannot be normally targeted.
10. Add both objects to the group; `/wb group duplicate 10`; verify the copied pair retains exact spacing.
11. `/wb undo`; verify the duplicated group disappears and the prior project state is restored.
12. `/wb redo`; verify it returns.
13. `/wb save`; inspect `bin/worldbuilder/projects/wb_smoke_test.wbp`.
14. `/wb close`; confirm all preview objects disappear.
15. `/wb load wb_smoke_test`; confirm the same placements return.
16. Restart Core3; confirm preview objects are gone until `/wb load wb_smoke_test`.
17. `/wb export`; run the generated Lua screenplay in a test screenplay location and confirm placement matches without World Builder loaded.
18. Separately test `bellum_worldbuilder.py validate` and `export-lua`.
19. Only after those pass, test `bake-tre` against a **copy/clean baseline TRE**, never the only production TRE.
20. Start the client/server with the baked test TRE and verify the permanent snapshot objects match the live World Builder layout.

If any step fails, stop there rather than moving on to TRE deployment. The live editor and project-save path should be rock solid before treating the baker as production tooling.
