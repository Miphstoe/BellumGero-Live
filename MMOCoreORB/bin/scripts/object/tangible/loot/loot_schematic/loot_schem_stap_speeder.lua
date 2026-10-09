object_tangible_loot_loot_schematic_loot_schem_stap_speeder = object_tangible_loot_loot_schematic_shared_loot_schem_stap_speeder:new {
	templateType = LOOTSCHEMATIC,
	customName = "STAP Schematic",
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_artisan_engineering_04",
	targetDraftSchematic = "object/draft_schematic/vehicle/civilian/stap_speeder.iff",
	targetUseCount = 1,
}

ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_loot_schem_stap_speeder, "object/tangible/loot/loot_schematic/loot_schem_stap_speeder.iff")
