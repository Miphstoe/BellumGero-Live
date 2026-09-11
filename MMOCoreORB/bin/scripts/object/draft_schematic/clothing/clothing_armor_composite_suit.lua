-- Bellum Gero Composite Full-Suit Crafting
-- Exact aggregate of the nine normal Composite armor recipes on Main.

object_draft_schematic_clothing_clothing_armor_composite_suit =
	object_draft_schematic_clothing_shared_clothing_armor_composite_suit:new {

	templateType = DRAFTSCHEMATIC,

	customObjectName = "Composite Armor Suit Package",

	craftingToolTab = 2,
	complexity = 45,
	size = 1,
	factoryCrateSize = 1000,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",

	xpType = "crafting_clothing_armor",
	xp = 4100,

	assemblySkill = "armor_assembly",
	experimentingSkill = "armor_experimentation",
	customizationSkill = "armor_customization",

	customizationOptions = {2},
	customizationStringNames = {"/private/index_color_1"},
	customizationDefaults = {0},

	ingredientTemplateNames = {
		"craft_clothing_ingredients_n",
		"craft_clothing_ingredients_n",
		"craft_clothing_ingredients_n",
		"craft_clothing_ingredients_n",
		"craft_clothing_ingredients_n",
		"craft_clothing_ingredients_n",
		"craft_clothing_ingredients_n",
		"craft_clothing_ingredients_n",
		"craft_clothing_ingredients_n"
	},
	ingredientTitleNames = {
		"auxilary_coverage",
		"body",
		"liner",
		"hardware_and_attachments",
		"binding_and_reinforcement",
		"padding",
		"armor",
		"load_bearing_harness",
		"reinforcement"
	},
	ingredientSlotType = {0, 0, 0, 0, 0, 0, 1, 1, 1},

	resourceTypes = {
		"ore_intrusive",
		"fuel_petrochem_solid_known",
		"fiberplast_naboo",
		"aluminum",
		"copper_beyrllius",
		"hide_wooly",
		"object/tangible/component/armor/shared_armor_segment_composite.iff",
		"object/tangible/component/clothing/shared_synthetic_cloth.iff",
		"object/tangible/component/clothing/shared_reinforced_fiber_panels.iff"
	},

	-- Sum of all nine current individual Composite recipes:
	-- 515 ore, 515 fuel, 260 Naboo fiberplast, 300 aluminum,
	-- 220 Beyrllius copper, 210 wooly hide,
	-- 21 Composite Segments, 10 Synthetic Cloth, 9 Reinforced Fiber Panels.
	resourceQuantities = {515, 515, 260, 300, 220, 210, 21, 10, 9},
	contribution = {100, 100, 100, 100, 100, 100, 100, 100, 100},

	targetTemplate =
		"object/tangible/wearables/armor/composite/armor_composite_suit_package.iff",

	additionalTemplates = {
	}
}

ObjectTemplates:addTemplate(
	object_draft_schematic_clothing_clothing_armor_composite_suit,
	"object/draft_schematic/clothing/clothing_armor_composite_suit.iff")
