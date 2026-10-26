object_tangible_loot_loot_schematic_loot_schem_senate_pod = object_tangible_loot_loot_schematic_shared_loot_schem_senate_pod:new {
	templateType = LOOTSCHEMATIC,
	customName = "Senate Pod Schematic",
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_artisan_engineering_04",
	targetDraftSchematic = "object/draft_schematic/vehicle/civilian/senate_pod.iff",
	targetUseCount = 1,
}

ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_loot_schem_senate_pod, "object/tangible/loot/loot_schematic/loot_schem_senate_pod.iff")
