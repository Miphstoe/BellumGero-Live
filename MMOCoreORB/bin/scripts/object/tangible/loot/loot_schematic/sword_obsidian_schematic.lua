object_tangible_loot_loot_schematic_sword_obsidian_schematic = object_tangible_loot_loot_schematic_shared_sword_obsidian_schematic:new {
	templateType = LOOTSCHEMATIC,
    customName = "Obsidian Sword Schematic",
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_weaponsmith_master",
	targetDraftSchematic = "object/draft_schematic/weapon/sword_obsidian.iff",
	targetUseCount = 3,
}

ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_sword_obsidian_schematic, "object/tangible/loot/loot_schematic/sword_obsidian_schematic.iff")
