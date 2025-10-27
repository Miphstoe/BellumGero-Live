object_tangible_loot_loot_schematic_punchknuckler_schematic = object_tangible_loot_loot_schematic_shared_punchknuckler_schematic:new {
	templateType = LOOTSCHEMATIC,
    customName = "Spy's Fang Schematic",
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_weaponsmith_master",
	targetDraftSchematic = "object/draft_schematic/weapon/punchknuckler.iff",
	targetUseCount = 3,
}

ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_punchknuckler_schematic, "object/tangible/loot/loot_schematic/punchknuckler_schematic.iff")
