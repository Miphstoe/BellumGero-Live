object_tangible_loot_loot_schematic_loot_schem_hover_chair = object_tangible_loot_loot_schematic_shared_loot_schem_hover_chair:new {
	templateType = LOOTSCHEMATIC,
	customName = "Hover Chair Schematic",
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_artisan_engineering_04",
	targetDraftSchematic = "object/draft_schematic/vehicle/civilian/hover_chair.iff",
	targetUseCount = 1,
}

ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_loot_schem_hover_chair, "object/tangible/loot/loot_schematic/loot_schem_hover_chair.iff")
