Bellum Gero World Builder project storage
==========================================

This directory must exist and be writable by the Core3 process.

Files ending in .wbp are autosaved World Builder projects.
Files ending in _export.lua are generated placement screenplays.

Do not treat runtime object IDs as permanent. World Builder preview objects are
transient and are respawned from the .wbp manifest whenever the project loads.

Recommended: commit useful .wbp project files to your development repository so
custom POIs/dungeons remain reproducible and editable later.
