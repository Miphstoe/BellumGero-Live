object_tangible_loot_loot_schematic_loot_schem_snowspeeder = object_tangible_loot_loot_schematic_shared_loot_schem_snowspeeder:new {
	templateType = LOOTSCHEMATIC,
	customName = "T-47 Snowspeeder Schematic",
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_artisan_engineering_04",
	targetDraftSchematic = "object/draft_schematic/vehicle/civilian/snowspeeder.iff",
	targetUseCount = 1,
}

ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_loot_schem_snowspeeder, "object/tangible/loot/loot_schematic/loot_schem_snowspeeder.iff")
