object_tangible_loot_hoth_painting_schematic_hoth_battle = object_tangible_loot_hoth_shared_painting_schematic_hoth_battle:new {
	templateType = LOOTSCHEMATIC,
	customName = "Painting Schematic: First Strike on Hoth",
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_architect_production_03",
	targetDraftSchematic = "object/draft_schematic/furniture/hoth/painting_hoth_battle.iff",
	targetUseCount = 2
}

ObjectTemplates:addTemplate(object_tangible_loot_hoth_painting_schematic_hoth_battle, "object/tangible/loot/hoth/painting_schematic_hoth_battle.iff")
