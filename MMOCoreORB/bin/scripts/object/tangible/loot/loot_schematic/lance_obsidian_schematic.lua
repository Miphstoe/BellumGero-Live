object_tangible_loot_loot_schematic_lance_obsidian_schematic = object_tangible_loot_loot_schematic_shared_lance_obsidian_schematic:new {
	templateType = LOOTSCHEMATIC,
    customName = "Obsidian Lance Schematic",
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_weaponsmith_master",
	targetDraftSchematic = "object/draft_schematic/weapon/lance_obsidian.iff",
	targetUseCount = 3,
}

ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_lance_obsidian_schematic, "object/tangible/loot/loot_schematic/lance_obsidian_schematic.iff")
