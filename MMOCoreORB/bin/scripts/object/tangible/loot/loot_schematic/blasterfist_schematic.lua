object_tangible_loot_loot_schematic_blasterfist_schematic = object_tangible_loot_loot_schematic_shared_blasterfist_schematic:new {
	templateType = LOOTSCHEMATIC,
    customName = "Blasterfist Schematic",
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_weaponsmith_master",
	targetDraftSchematic = "object/draft_schematic/weapon/blasterfist.iff",
	targetUseCount = 1,
}

ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_blasterfist_schematic, "object/tangible/loot/loot_schematic/blasterfist_schematic.iff")