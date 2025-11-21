object_tangible_loot_loot_schematic_cabinet_technical_schematic = object_tangible_loot_loot_schematic_shared_cabinet_technical_schematic:new {
	templateType = LOOTSCHEMATIC,
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_architect_master",
	targetDraftSchematic = "object/draft_schematic/furniture/furniture_cabinet_technical.iff",
	targetUseCount = 3,
}

ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_cabinet_technical_schematic, "object/tangible/loot/loot_schematic/cabinet_technical_schematic.iff")
