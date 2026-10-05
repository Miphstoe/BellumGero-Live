object_tangible_loot_loot_schematic_loot_schem_hover_bird = object_tangible_loot_loot_schematic_shared_loot_schem_hover_bird:new {
	templateType = LOOTSCHEMATIC,
	customName = "Hover Bird Schematic",
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_artisan_engineering_04",
	targetDraftSchematic = "object/draft_schematic/vehicle/civilian/hover_bird.iff",
	targetUseCount = 1,
}

ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_loot_schem_hover_bird, "object/tangible/loot/loot_schematic/loot_schem_hover_bird.iff")
