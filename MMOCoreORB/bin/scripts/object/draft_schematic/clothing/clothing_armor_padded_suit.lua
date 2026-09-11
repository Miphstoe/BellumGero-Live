-- Bellum Gero Padded Full-Suit Crafting
-- Quantities are the exact aggregate of the ten current Padded armor recipes.

object_draft_schematic_clothing_clothing_armor_padded_suit =
	object_draft_schematic_clothing_shared_clothing_armor_padded_suit:new {

	templateType = DRAFTSCHEMATIC,

	customObjectName = "Padded Armor Suit Package",

	craftingToolTab = 2,
	complexity = 40,
	size = 1,
	factoryCrateSize = 1000,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",

	xpType = "crafting_clothing_armor",
	xp = 3740,

	assemblySkill = "armor_assembly",
	experimentingSkill = "armor_experimentation",
	customizationSkill = "armor_customization",

	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},

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
		"hide_leathery_lok",
		"hide_scaley",
		"fiberplast_corellia",
		"metal",
		"petrochem_inert_polymer",
		"hide_wooly",
		"object/tangible/component/armor/shared_armor_segment_padded.iff",
		"object/tangible/component/clothing/shared_synthetic_cloth.iff",
		"object/tangible/component/clothing/shared_reinforced_fiber_panels.iff"
	},
	resourceQuantities = {525, 525, 265, 305, 223, 212, 22, 11, 10},
	contribution = {100, 100, 100, 100, 100, 100, 100, 100, 100},

	targetTemplate = "object/tangible/wearables/armor/padded/armor_padded_suit_package.iff",

	additionalTemplates = {
	}
}

ObjectTemplates:addTemplate(
	object_draft_schematic_clothing_clothing_armor_padded_suit,
	"object/draft_schematic/clothing/clothing_armor_padded_suit.iff")
