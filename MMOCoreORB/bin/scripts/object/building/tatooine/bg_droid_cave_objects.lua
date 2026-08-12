-- Bellum Gero custom server template registration for the Lok Droid Cave.
--
-- The matching shared client template is registered in tatooine/objects.lua,
-- following the same shared-template/server-template pattern used by the stock
-- Tatooine cave templates.
--
-- Snapshot loading derives the server template by removing "shared_" from the
-- snapshot template path, so this matching non-shared server template must be
-- registered for the permanent Droid Cave snapshot object on Lok.

object_building_tatooine_cave_tatooine_droid_01 = object_building_tatooine_shared_cave_tatooine_droid_01:new {
}

ObjectTemplates:addTemplate(
	object_building_tatooine_cave_tatooine_droid_01,
	"object/building/tatooine/cave_tatooine_droid_01.iff"
)
