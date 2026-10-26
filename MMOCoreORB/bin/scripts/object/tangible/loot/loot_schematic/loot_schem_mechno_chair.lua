object_tangible_loot_loot_schematic_loot_schem_mechno_chair = object_tangible_loot_loot_schematic_shared_loot_schem_mechno_chair:new {
	templateType = LOOTSCHEMATIC,
	customName = "Mechno-Chair Schematic",
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_artisan_engineering_04",
	targetDraftSchematic = "object/draft_schematic/vehicle/civilian/mechno_chair.iff",
	targetUseCount = 1,
}

ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_loot_schem_mechno_chair, "object/tangible/loot/loot_schematic/loot_schem_mechno_chair.iff")
