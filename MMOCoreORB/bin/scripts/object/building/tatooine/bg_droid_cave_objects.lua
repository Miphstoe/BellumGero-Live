-- Bellum Gero custom template registration for the Lok Droid Cave.
--
-- The custom shared template is intentionally separate from the stock
-- shared_cave_tatooine_style_01.iff so Droid Cave-specific client/TRE changes
-- affect only the permanent Droid Cave snapshot object on Lok.
--
-- Snapshot loading derives the server template by removing "shared_" from the
-- snapshot template path, so the matching non-shared server template must also
-- be registered here.

object_building_tatooine_shared_cave_tatooine_droid_01 = SharedBuildingObjectTemplate:new {
	clientTemplateFileName = "object/building/tatooine/shared_cave_tatooine_droid_01.iff"
}

ObjectTemplates:addClientTemplate(
	object_building_tatooine_shared_cave_tatooine_droid_01,
	"object/building/tatooine/shared_cave_tatooine_droid_01.iff"
)

object_building_tatooine_cave_tatooine_droid_01 = object_building_tatooine_shared_cave_tatooine_droid_01:new {
}

ObjectTemplates:addTemplate(
	object_building_tatooine_cave_tatooine_droid_01,
	"object/building/tatooine/cave_tatooine_droid_01.iff"
)
