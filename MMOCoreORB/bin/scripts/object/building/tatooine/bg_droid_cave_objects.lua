-- Bellum Gero custom client template registration for the Lok Droid Cave.
--
-- This template is intentionally separate from the stock
-- shared_cave_tatooine_style_01.iff so the terrain modifier affects only
-- the permanent Droid Cave snapshot object on Lok.

object_building_tatooine_shared_cave_tatooine_droid_01 = SharedBuildingObjectTemplate:new {
	clientTemplateFileName = "object/building/tatooine/shared_cave_tatooine_droid_01.iff"
}

ObjectTemplates:addClientTemplate(
	object_building_tatooine_shared_cave_tatooine_droid_01,
	"object/building/tatooine/shared_cave_tatooine_droid_01.iff"
)
