object_tangible_loot_loot_schematic_carbine_e5_schematic = object_tangible_loot_loot_schematic_shared_carbine_e5_schematic:new {
	templateType = LOOTSCHEMATIC,
    customName = "E-5 Carbine Schematic",
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_weaponsmith_master",
	targetDraftSchematic = "object/draft_schematic/weapon/carbine_e5.iff",
	targetUseCount = 3,
}

ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_carbine_e5_schematic, "object/tangible/loot/loot_schematic/carbine_e5_schematic.iff")
