object_tangible_loot_loot_schematic_cabinet_plain_schematic = object_tangible_loot_loot_schematic_shared_cabinet_plain_schematic:new {
	templateType = LOOTSCHEMATIC,
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_architect_master",
	targetDraftSchematic = "object/draft_schematic/furniture/furniture_cabinet_plain.iff",
	targetUseCount = 3,
}

ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_cabinet_plain_schematic, "object/tangible/loot/loot_schematic/cabinet_plain_schematic.iff")
